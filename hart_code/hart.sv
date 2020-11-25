// `include "common.sv"
`include "isa.sv"

`timescale 1 ns / 1 ns

import isa_types::*;

module hart(clock, reset, reg_state);
	input logic clock, reset;
	output reg_state_t reg_state;

	// Address of first byte which _isn't_ valid on the stack; used to initialize sp.
	// The program will begin by allocating space, so this should never be accessed.
	localparam STACK_START = 32'hc00;
	// TODO: having stuff start at address 0 is definitely bad
	localparam RESET_VECTOR = 32'h0;
	localparam READ_CYCLE_LATENCY = 2'd2;

	logic [1:0] remaining_read_cycles, next_remaining_read_cycles;
	enum logic [1:0] {
		STAGE_INSTRUCTION_FETCH, // Read next instruction from memory
		STAGE_LOAD,					 // Instruction-specific memory reads (LOAD opcode only)
		STAGE_WRITEBACK          // Write results to registers or memory
	} stage, next_stage;

	// Memory (ROM and RAM)
	logic mem_wenable;
   logic [XLEN-1:0] mem_addr;
   logic [XLEN-1:0] mem_wdata, mem_rdata;
   write_width_t mem_wwidth;
	memory mem(clock, mem_addr, mem_wwidth, mem_wenable, mem_wdata, mem_rdata);

	// the bit pattern of the current instruction
	logic [ILEN-1:0] instr_bits;

	// Instruction decoder
	opcode_t opcode;
	rv_reg_t rs1, rs2, rd;
	logic [2:0] funct3;
	logic [6:0] funct7;
	logic [XLEN-1:0] i_imm_input, s_imm_input, u_imm_input, j_imm_input;
	instruction_decoder instr_decoder (instr_bits, opcode, rs1, rs2, rd, funct3, funct7, i_imm_input, s_imm_input, u_imm_input, j_imm_input);

	// Computed addresses for memory instructions
	logic [XLEN-1:0] i_effective_addr, s_effective_addr;
	assign i_effective_addr = i_imm_input + reg_state.xregs[rs1];
	assign s_effective_addr = s_imm_input + reg_state.xregs[rs1];

	// store_val: Value to be stored in RAM upon conclusion of writeback stage (STORE opcode only)
	// load_val: Value which was read from memory upon conclusion of load stage (LOAD opcode only)
	// 	load_val is not strictly necessary; we could use the memory output without a latch.
	logic [XLEN-1:0] store_val, load_val;

	// memory controller
	always_comb begin
		mem_wenable = 1'b0;
		mem_addr = 'X;
		mem_wdata = 'X;
		mem_wwidth = write_byte; // don't cate

		case (stage)
			STAGE_INSTRUCTION_FETCH: begin
				mem_addr = reg_state.pc;
			end
			STAGE_LOAD: begin
				// In theory, it should be impossible to get into the "load" stage unless the
				// opcode was LOAD, but... better safe than thoroughly confused.
				case (opcode)
					OPCODE_LOAD: mem_addr = i_effective_addr;
					default:     mem_addr = 'X;
				endcase
			end
			STAGE_WRITEBACK: begin
				case (opcode)
					OPCODE_STORE: begin
						mem_addr = s_effective_addr;
						mem_wenable = 1'b1;
						mem_wdata = store_val;
						case (funct3)
							`FUNCT3_SB: mem_wwidth = write_byte;
							`FUNCT3_SH: mem_wwidth = write_halfword;
							`FUNCT3_SW: mem_wwidth = write_word;
							default:    mem_wwidth = write_byte; // don't care
						endcase
					end
				endcase
			end
		endcase
	end

	// Value to be stored in register rd upon conclusion of writeback stage (LOAD, OP_IMM)
	logic [XLEN-1:0] rd_out_val;

	logic is_jumping;
	logic [XLEN-1:0] jump_target;

	// Computation for writeback
	always_comb begin
		rd_out_val = 'x;
		store_val = 'x;

		is_jumping = 1'b0;
		jump_target = 'x;

		case (opcode)
			OPCODE_OP_IMM: case (funct3)
				`FUNCT3_ADDI: rd_out_val = i_imm_input + reg_state.xregs[rs1];
				default: rd_out_val = 'x;
			endcase

			OPCODE_OP: begin
				case (funct3)
					`FUNCT3_ADD_SUB: case (funct7)
						`FUNCT7_ADD: rd_out_val = reg_state.xregs[rs1] + reg_state.xregs[rs2];
						`FUNCT7_SUB: rd_out_val = reg_state.xregs[rs1] - reg_state.xregs[rs2];
						default:     rd_out_val = 'X;
					endcase
					default: rd_out_val = 'X;
				endcase
			end

			OPCODE_JAL: begin
				rd_out_val = reg_state.pc + 4;
				is_jumping = 1'b1;
				jump_target = reg_state.pc + j_imm_input;
			end

			OPCODE_JALR: begin
				rd_out_val = reg_state.pc + 4;
				is_jumping = 1'b1;
				jump_target = { i_effective_addr[31:1], 1'b0 };
			end

			OPCODE_LUI: rd_out_val = u_imm_input;

			OPCODE_LOAD: case (funct3)
				`FUNCT3_LB: rd_out_val = `SIGEXT( load_val, 8, XLEN);
				`FUNCT3_LH: rd_out_val = `SIGEXT( load_val, 16, XLEN);
				`FUNCT3_LW: rd_out_val = load_val;
				default:    rd_out_val = 'X;
			endcase

			OPCODE_STORE: begin
				store_val = reg_state.xregs[rs2];
			end
			OPCODE_UNKNOWN: begin /* Do nothing */ end
		endcase
	end

	// opcode computed from the current memory output, rather than the captured instr_bits
	opcode_t speculative_opcode;
	assign speculative_opcode = extract_opcode(mem_rdata);

	// Stage progression logic (computes next values of state parameters)
	logic [XLEN-1:0] next_pc;
	always_comb begin
		next_pc = reg_state.pc;
		case (stage)
			STAGE_INSTRUCTION_FETCH: begin
				if (remaining_read_cycles) begin
					next_stage = STAGE_INSTRUCTION_FETCH;
					next_remaining_read_cycles = remaining_read_cycles - 2'd1;
				end else begin
					case (speculative_opcode)
						// If the next instruction is an unknown opcode, stall in this state
						// forever (in essence, halt)
						OPCODE_UNKNOWN: next_stage = STAGE_INSTRUCTION_FETCH;
						// LOAD instructions have an extra stage
						OPCODE_LOAD:    next_stage = STAGE_LOAD;
						// Every non-LOAD goes straight to the final stage
						default:        next_stage = STAGE_WRITEBACK;
					endcase
					next_remaining_read_cycles = READ_CYCLE_LATENCY;
				end
			end
			STAGE_LOAD: begin
				if (remaining_read_cycles) next_stage = STAGE_LOAD;
				else                       next_stage = STAGE_WRITEBACK;
				next_remaining_read_cycles = remaining_read_cycles - 2'd1;
			end
			STAGE_WRITEBACK: begin
				next_stage = STAGE_INSTRUCTION_FETCH;
				if (is_jumping) next_pc = jump_target;
				else            next_pc = reg_state.pc + 4;
				next_remaining_read_cycles = READ_CYCLE_LATENCY;
			end
		endcase
	end

	// Clock trigger: captures outputs from current stage, applies transitions as needed
	always_ff @(posedge clock) begin
		if (reset) begin
			stage <= STAGE_INSTRUCTION_FETCH;
			remaining_read_cycles <= READ_CYCLE_LATENCY;
			reg_state.pc <= RESET_VECTOR;
			reg_state.xregs[0] <= 0;
			reg_state.xregs[2] <= STACK_START; // sp
		end else begin
			case (stage)
				STAGE_INSTRUCTION_FETCH: begin
					if (remaining_read_cycles == 0)
						instr_bits <= mem_rdata;
				end
				STAGE_LOAD: begin
					if (remaining_read_cycles == 0)
						load_val <= mem_rdata;
				end
				STAGE_WRITEBACK: begin
					case (opcode)
							OPCODE_OP_IMM, OPCODE_OP,
							OPCODE_JAL, OPCODE_JALR,
							OPCODE_LUI, OPCODE_LOAD: begin
								if (rd) // "if" prevents writing to x0
									reg_state.xregs[rd] <= rd_out_val;
							end
							OPCODE_STORE: begin /* Do nothing */ end
							OPCODE_UNKNOWN: begin /* Do nothing */ end
					endcase
				end
			endcase
			stage <= next_stage;
			reg_state.pc <= next_pc;
			remaining_read_cycles <= next_remaining_read_cycles;
		end
	end
endmodule

module hart_testbench();
	logic clk, reset;

	reg_state_t reg_state;
	hart dut (clk, reset, reg_state);

	// Set up the clock
	parameter CLOCK_PERIOD=100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end

	// Set up the inputs to the design. Each line is a clock cycle.
	initial begin
		@(posedge clk); reset <= 1;
		@(posedge clk); reset <= 0;

		repeat (140) begin
			@(posedge clk);
		end

		$stop; // End the simulation
	end
endmodule
