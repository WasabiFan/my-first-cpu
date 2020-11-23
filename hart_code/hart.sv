// `include "common.sv"
`include "isa.sv"

`timescale 1 ns / 1 ns

import isa_types::*;

module hart(clock, reset, reg_state);
	input logic clock, reset;
	output state_t reg_state;

	localparam static_data_max_addr = 35;

	logic is_resetting;
	logic [XLEN-1:0] reset_addr;
	assign is_resetting = reset_addr <= static_data_max_addr;

	enum logic {
		STAGE_INSTRUCTION_FETCH
	} stage;

	logic [ILEN-1:0] instr_bits;

	opcode_t opcode;
	rv_reg_t rs1, rs2, rd;
	logic [2:0] funct3;
	logic [6:0] funct7;
	logic [XLEN-1:0] i_imm_input, s_imm_input;
	instruction_decoder instr_decoder (instr_bits, opcode, rs1, rs2, rd, funct3, funct7, i_imm_input, s_imm_input);

	logic mem_wenable;
   logic [XLEN-1:0] mem_addr;
   logic [XLEN-1:0] mem_wdata, mem_rdata;
   write_width_t mem_wwidth;
	memory mem(clock, mem_addr, mem_wwidth, mem_wenable, mem_wdata, mem_rdata);

	assign mem_wenable = 1;
	assign mem_addr = 0;
	assign mem_wdata = 12345;
	assign mem_wwidth = write_word;

	// memory controller
	// always_comb begin
	// 	case (stage)
	// 		STAGE_INSTRUCTION_FETCH: begin
	// 			mem_addr = reg_state.pc;
	// 		end
	// 	endcase
	// end

	// memory write controller
	// always_comb begin
	// 	mem_wenable = 0;
	// 	mem_waddr = 'X;
	// 	mem_wwidth = write_byte; // don't care
	// 	mem_wdata = 'X;
	// 	if (is_resetting) begin
	// 		mem_wenable = 1;
	// 		mem_waddr = reset_addr;
	// 		mem_wwidth = write_byte;
	// 		case (reset_addr)
	// 			32'h00:  mem_wdata = 32'h12345678;
	// 			default: mem_wdata = 32'h00000000;
	// 		endcase
	// 	end
	// end

	// logic [XLEN-1:0] i_effective_addr, s_effective_addr;
	// assign i_effective_addr = i_imm_input + reg_state.xregs[rs1];
	// assign s_effective_addr = s_imm_input + reg_state.xregs[rs1];

	// logic [XLEN-1:0] store_val;
	// logic [XLEN-1:0] rd_out_val;

	// logic [15:0] lh_input_raw_val;
	// // TODO: hack to get around Quartus' inability to handle concatenation as an expression
	// assign lh_input_raw_val = { reg_state.ram[i_effective_addr+1], reg_state.ram[i_effective_addr] };

	// always_comb begin
	// 	rd_out_val = 'x;
	// 	store_val = 'x;
	// 	case (opcode)
	// 		OP_IMM: begin
	// 			case (funct3)
	// 				`FUNCT3_ADDI: rd_out_val = i_imm_input + reg_state.xregs[rs1];
	// 				default: rd_out_val = 'x;
	// 			endcase
	// 		end
	// 		OP_LOAD: begin
	// 			case (funct3)
	// 				`FUNCT3_LB: rd_out_val = `SIGEXT(  reg_state.ram[i_effective_addr], 8, XLEN);
	// 				`FUNCT3_LH: rd_out_val = `SIGEXT(lh_input_raw_val, 16, XLEN);
	// 				`FUNCT3_LW: rd_out_val = { reg_state.ram[i_effective_addr+3], reg_state.ram[i_effective_addr+2], reg_state.ram[i_effective_addr+1], reg_state.ram[i_effective_addr]};
	// 				default: rd_out_val = 'x;
	// 			endcase
	// 		end
	// 		OP_STORE: begin
	// 			store_val = reg_state.xregs[rs2];
	// 		end
	// 		OP_UNKNOWN: begin /* Do nothing */ end
	// 	endcase
	// end

	always_ff @(posedge clock) begin
		if (reset) begin
			reset_addr = 0;
			reg_state.pc = 0;
			reg_state.xregs[0] = 0;


			// // TODO: having stuff start at address 0 is definitely bad
			// // 00500793                li      a5,5
			// // 00178793                addi    a5,a5,1
			// // fff78793                addi    a5,a5,-1
			// reg_state.ram[3:0] = '{
			// 		8'h00, 8'h50, 8'h07, 8'h93 // li a5,5
			// };
			// reg_state.ram[7:4] = '{
			// 		8'h00, 8'h17, 8'h87, 8'h93 // addi a5,a5,1
			// };
			// reg_state.ram[11:8] = '{
			// 		8'hff, 8'hf7, 8'h87, 8'h93 // addi a5,a5,-1
			// };

			// // 06000793                li      a5,96
			// // 00a00713                li      a4,10
			// // 00e7a023                sw      a4,0(a5)
			// reg_state.ram[15:12] = '{
			// 		8'h06, 8'h00, 8'h07, 8'h93 // li a5,96
			// };
			// reg_state.ram[19:16] = '{
			// 		8'h00, 8'ha0, 8'h07, 8'h13 // li a4,10
			// };
			// reg_state.ram[23:20] = '{
			// 		8'h00, 8'he7, 8'ha0, 8'h23 // sw a4,0(a5)
			// };

			// // 0007a703                lw      a4,0(a5)
			// // 00170713                addi    a4,a4,1
			// // 00e7a023                sw      a4,0(a5)
			// reg_state.ram[27:24] = '{
			// 		8'h00, 8'h07, 8'ha7, 8'h03 // lw a4,0(a5)
			// };
			// reg_state.ram[31:28] = '{
			// 		8'h00, 8'h17, 8'h07, 8'h13 // addi a4,a4,1
			// };
			// reg_state.ram[35:32] = '{
			// 		8'h00, 8'he7, 8'ha0, 8'h23 // sw a4,0(a5)
			// };
		end else begin
			// case (opcode)
			// 		OP_IMM, OP_LOAD: begin
			// 			if (rd)
			// 				reg_state.xregs[rd] = rd_out_val;
			// 		end
			// 		OP_STORE: begin
			// 			case (funct3)
			// 				`FUNCT3_SB: reg_state.ram[s_effective_addr] = store_val[7:0];
			// 				`FUNCT3_SH: { reg_state.ram[s_effective_addr+1], reg_state.ram[s_effective_addr] } = store_val[15:0];
			// 				`FUNCT3_SW: { reg_state.ram[s_effective_addr+3], reg_state.ram[s_effective_addr+2], reg_state.ram[s_effective_addr+1], reg_state.ram[s_effective_addr]} = store_val[31:0];
			// 			endcase
			// 		end
			// 		OP_UNKNOWN: begin /* Do nothing */ end
			// endcase
			reg_state.pc += 4;
		end
	end
endmodule



module hart_testbench();
	logic clk, reset;

	state_t reg_state;
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
