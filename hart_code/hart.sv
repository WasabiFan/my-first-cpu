`include "isa.sv"

`timescale 1 ns / 1 ns

import isa_types::*;

module hart #( parameter INPUT_PERIPH_LEN = 'h20, OUTPUT_PERIPH_LEN = 'h20 ) (clock, reset, reg_state, input_peripherals_mem, output_peripherals_mem);
	input logic clock, reset;
   input logic [7:0] input_peripherals_mem [INPUT_PERIPH_LEN-1:0];
	output reg_state_t reg_state;
   output logic [7:0] output_peripherals_mem [OUTPUT_PERIPH_LEN-1:0];

	// Address of first byte which _isn't_ valid on the stack; used to initialize sp.
	// The program will begin by allocating space, so this should never be accessed.
	localparam STACK_START = 32'hc00;
	// TODO: having stuff start at address 0 is definitely bad
	localparam RESET_VECTOR = 32'h0;

	enum logic [1:0] {
		STAGE_INSTRUCTION_FETCH, // Read next instruction from memory
		STAGE_LOAD,					 // Instruction-specific memory reads (LOAD opcode only)
		STAGE_WRITEBACK          // Write results to registers or memory
	} stage, next_stage;

	// Memory (ROM and RAM, plus memory-mapped peripherals)
	mem_control_t mem_ctrl;
   logic [XLEN-1:0] mem_rdata;
	memory #(.INPUT_PERIPH_LEN(INPUT_PERIPH_LEN), .OUTPUT_PERIPH_LEN(OUTPUT_PERIPH_LEN)) mem (
		clock,
		mem_ctrl,
		mem_rdata,
		input_peripherals_mem, output_peripherals_mem
	);

	// the bit pattern of the current instruction
	logic [ILEN-1:0] instr_bits;

	// Instruction decoder
	decoded_instruction_t curr_instr;
	instruction_decoder instr_decoder (
		instr_bits,
		curr_instr
	);


	logic instruction_fetch_is_complete, instruction_fetch_is_next_instruction_load;
	mem_control_t instruction_fetch_mem_control;
	stage_instruction_fetch instr_fetch_stage (
		clock,
		reset,
		stage == STAGE_INSTRUCTION_FETCH,
		reg_state.pc,
		mem_rdata,
		instruction_fetch_is_complete,
		instruction_fetch_mem_control,
		instr_bits,
		instruction_fetch_is_next_instruction_load
	);

	// Computed addresses for memory instructions (I-type)
	logic [XLEN-1:0] i_effective_addr;
	assign i_effective_addr = curr_instr.i_imm_input + reg_state.xregs[curr_instr.rs1];

	// load_val: Value which was read from memory upon conclusion of load stage (LOAD opcode only)
	// 	load_val is not strictly necessary; we could use the memory output without a latch.
	logic [XLEN-1:0] load_val;
	logic memory_load_is_complete;
	mem_control_t memory_load_mem_control;
	stage_memory_load memory_load_stage (
		clock,
		reset,
		stage == STAGE_LOAD,
		i_effective_addr,
		mem_rdata,
		memory_load_is_complete,
		memory_load_mem_control,
		load_val
	);

	// Value to be stored in RAM upon conclusion of writeback stage (if store_enable is high, i.e. STORE opcode only)
	logic [XLEN-1:0] store_val;
	// Value to be stored in register rd upon conclusion of writeback stage (if rd_out_enable is high)
	logic [XLEN-1:0] rd_out_val;
	// Address to jump to at the conclusion of the writeback stage (if jump_enable is high)
	logic [XLEN-1:0] jump_target_addr;
	logic store_enable, rd_out_enable, jump_enable;
	logic writeback_is_complete;
	mem_control_t writeback_mem_control;
	stage_writeback writeback_stage (
		stage == STAGE_WRITEBACK,
		reg_state,
		load_val,
		curr_instr,
		writeback_is_complete,
		writeback_mem_control,
		rd_out_val, rd_out_enable,
		jump_target_addr, jump_enable
	);

	// memory controller
	always_comb case (stage)
		STAGE_INSTRUCTION_FETCH: mem_ctrl = instruction_fetch_mem_control;
		STAGE_LOAD:              mem_ctrl = memory_load_mem_control;
		STAGE_WRITEBACK:         mem_ctrl = writeback_mem_control;
	endcase

	// Stage progression logic (computes next values of state parameters)
	logic [XLEN-1:0] next_pc;
	always_comb begin
		next_pc = reg_state.pc;
		case (stage)
			STAGE_INSTRUCTION_FETCH: begin
				if (instruction_fetch_is_complete) begin
					// LOAD instructions have an extra stage
					if (instruction_fetch_is_next_instruction_load) next_stage = STAGE_LOAD;
					// Every non-LOAD goes straight to the final stage
					else                                            next_stage = STAGE_WRITEBACK;
				end else begin
					next_stage = STAGE_INSTRUCTION_FETCH;
				end
			end
			STAGE_LOAD: begin
				if (memory_load_is_complete) next_stage = STAGE_WRITEBACK;
				else                         next_stage = STAGE_LOAD;
			end
			STAGE_WRITEBACK: begin
				next_stage = STAGE_INSTRUCTION_FETCH;
				if (jump_enable) next_pc = jump_target_addr;
				else             next_pc = reg_state.pc + 4;
			end
		endcase
	end

	// Clock trigger: captures outputs from current stage, applies transitions as needed
	always_ff @(posedge clock) begin
		if (reset) begin
			stage <= STAGE_INSTRUCTION_FETCH;
			reg_state.pc <= RESET_VECTOR;
			reg_state.xregs[0] <= 0;
			reg_state.xregs[2] <= STACK_START; // sp
		end else begin
			case (stage)
				STAGE_INSTRUCTION_FETCH: begin /* do nothing */ end
				STAGE_LOAD: begin /* do nothing */ end
				STAGE_WRITEBACK: begin
					if (rd_out_enable) begin
						// avoid writing to x0
						if (curr_instr.rd)
							reg_state.xregs[curr_instr.rd] <= rd_out_val;
					end
				end
			endcase
			stage <= next_stage;
			reg_state.pc <= next_pc;
		end
	end
endmodule

module hart_testbench();
	logic clk, reset;

   logic [7:0] input_peripherals_mem ['h20-1:0];
   logic [7:0] output_peripherals_mem ['h20-1:0];

	reg_state_t reg_state;
	hart dut (clk, reset, reg_state, input_peripherals_mem, output_peripherals_mem);

	// Set up the clock
	parameter CLOCK_PERIOD=100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end

	initial begin
		@(posedge clk); reset <= 1;
		@(posedge clk); reset <= 0;
		input_peripherals_mem[0] = 8'b1;

		repeat (50) begin
			input_peripherals_mem[0] = input_peripherals_mem[0] == 0;
			repeat(20) begin
				@(posedge clk);
			end
		end

		$stop; // End the simulation
	end
endmodule
