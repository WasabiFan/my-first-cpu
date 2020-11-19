`include "common.sv"

typedef enum { UNKNOWN, OP_IMM, OP_LOAD, OP_STORE } opcode_t;

typedef logic [4:0] rv_reg_t;

`define SIGEXT(VALUE, FROM, TO) { {(TO-FROM){VALUE[FROM-1]}}, VALUE }
`define ZEXT(VALUE, FROM, TO) { (TO-FROM)'b0, VALUE }

`define OPCODE_OP_IMM 5'b00100
`define FUNCT3_ADDI   3'b000

`define OPCODE_LOAD   5'b00000
`define FUNCT3_LB     3'b000
`define FUNCT3_LH     3'b001
`define FUNCT3_LW     3'b010
// Omitted: LBU, LHU

`define OPCODE_STORE  5'b01000
`define FUNCT3_SB     3'b000
`define FUNCT3_SH     3'b001
`define FUNCT3_SW     3'b010

module hart(clock, reset);
	input logic clock, reset;
	state_t current_state;

	logic [ILEN-1:0] instr_bits;
	assign instr_bits = {
		current_state.ram[current_state.pc+3],
		current_state.ram[current_state.pc+2],
		current_state.ram[current_state.pc+1],
		current_state.ram[current_state.pc]
	};

	logic [6:0] field_opcode;
	assign field_opcode = instr_bits[6:0];

	opcode_t opcode;

	rv_reg_t rs1, rs2, rd;
	assign rd = instr_bits[11:7];
	assign rs1 = instr_bits[19:15];
	assign rs2 = instr_bits[23:20];

	logic [2:0] funct3;
	logic [6:0] funct7;
	assign funct3 = instr_bits[14:12];
	assign funct7 = instr_bits[31:25];

	logic [XLEN-1:0] i_imm_input, s_imm_input, i_effective_addr, s_effective_addr;
	logic [XLEN-1:0] rd_out_val;

	logic [11:0] i_imm_raw, s_imm_raw;
	assign i_imm_raw = instr_bits[31:20];
	assign s_imm_raw = { instr_bits[31:25], instr_bits[11:7] };

	assign i_imm_input = `SIGEXT(i_imm_raw, 12, XLEN);
	assign s_imm_input = `SIGEXT(s_imm_raw, 12, XLEN);
	
	assign i_effective_addr = i_imm_input + current_state.xregs[rs1];
	assign s_effective_addr = s_imm_input + current_state.xregs[rs1];

	logic [XLEN-1:0] store_val;

	logic [15:0] lh_input_raw_val;

	always_comb begin
		// field_opcode[1:0] are always 11
		case (field_opcode[6:2])
			`OPCODE_OP_IMM: opcode = OP_IMM;
			`OPCODE_LOAD: opcode = OP_LOAD;
			`OPCODE_STORE: opcode = OP_STORE;
			default: opcode = UNKNOWN;
		endcase

		case (opcode)
			OP_IMM: begin
				case (funct3)
					`FUNCT3_ADDI: rd_out_val = i_imm_input + current_state.xregs[rs1];
					default: rd_out_val = 'x;
				endcase
			end
			OP_LOAD: begin
				// TODO: hack to get around Quartus' inability to handle concatenation as an expression
				lh_input_raw_val = { current_state.ram[i_effective_addr+1], current_state.ram[i_effective_addr] };
				case (funct3)
					`FUNCT3_LB: rd_out_val = `SIGEXT(  current_state.ram[i_effective_addr], 8, XLEN);
					`FUNCT3_LH: rd_out_val = `SIGEXT(lh_input_raw_val, 16, XLEN);
					`FUNCT3_LW: rd_out_val = { current_state.ram[i_effective_addr+3], current_state.ram[i_effective_addr+2], current_state.ram[i_effective_addr+1], current_state.ram[i_effective_addr]};
					default: rd_out_val = 'x;
				endcase
			end
			OP_STORE: begin
				store_val = current_state.xregs[rs2];
			end
		endcase
	end

	always_ff @(posedge clock) begin
		if (reset) begin
			// TODO: having stuff start at address 0 is definitely bad
			// 00500793                li      a5,5
			// 00178793                addi    a5,a5,1
			// fff78793                addi    a5,a5,-1
			current_state.ram[3:0] = {
					8'h00, 8'h50, 8'h07, 8'h93 // li a5,5
			};
			current_state.ram[7:4] = {
					8'h00, 8'h17, 8'h87, 8'h93 // addi a5,a5,1
			};
			current_state.ram[11:8] = {
					8'hff, 8'hf7, 8'h87, 8'h93 // addi a5,a5,-1
			};

			// 06000793                li      a5,96
			// 00a00713                li      a4,10
			// 00e7a023                sw      a4,0(a5)
			current_state.ram[15:12] = {
					8'h06, 8'h00, 8'h07, 8'h93 // li a5,96
			};
			current_state.ram[19:16] = {
					8'h00, 8'ha0, 8'h07, 8'h13 // li a4,10
			};
			current_state.ram[23:20] = {
					8'h00, 8'he7, 8'ha0, 8'h23 // sw a4,0(a5)
			};

			// 0007a703                lw      a4,0(a5)
			// 00170713                addi    a4,a4,1
			// 00e7a023                sw      a4,0(a5)
			current_state.ram[27:24] = {
					8'h00, 8'h07, 8'ha7, 8'h03 // lw a4,0(a5)
			};
			current_state.ram[31:28] = {
					8'h00, 8'h17, 8'h07, 8'h13 // addi a4,a4,1
			};
			current_state.ram[35:32] = {
					8'h00, 8'he7, 8'ha0, 8'h23 // sw a4,0(a5)
			};
			current_state.pc = 0;
			current_state.xregs[0] = 0;
		end else begin
			case (opcode)
					OP_IMM, OP_LOAD: begin
						if (rd)
							current_state.xregs[rd] = rd_out_val;
					end
					OP_STORE: begin
						case (funct3)
							`FUNCT3_SB: current_state.ram[s_effective_addr] = store_val[7:0];
							`FUNCT3_SH: { current_state.ram[s_effective_addr+1], current_state.ram[s_effective_addr] } = store_val[15:0];
							`FUNCT3_SW: { current_state.ram[s_effective_addr+3], current_state.ram[s_effective_addr+2], current_state.ram[s_effective_addr+1], current_state.ram[s_effective_addr]} = store_val[31:0];
						endcase
					end
			endcase
			current_state.pc += 4;
		end
	end
endmodule



module hart_testbench();
	logic clk, reset;

	hart dut (clk, reset);

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

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		@(posedge clk);

		$stop; // End the simulation
	end
endmodule
