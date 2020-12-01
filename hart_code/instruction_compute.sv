`include "isa.sv"

`timescale 1 ns / 1 ns

import isa_types::*;

module instruction_compute (
		reg_state, load_val,
		curr_instr,
		store_val, store_enable,
		rd_out_val, rd_out_enable,
		jump_target_addr, jump_enable,
	);
	input reg_state_t reg_state;
	input logic [XLEN-1:0] load_val;
	input decoded_instruction_t curr_instr;

	output logic store_enable, rd_out_enable, jump_enable;
	output logic [XLEN-1:0] store_val, rd_out_val, jump_target_addr;

	logic [XLEN-1:0] i_effective_addr;
	assign i_effective_addr = curr_instr.i_imm_input + reg_state.xregs[curr_instr.rs1];

	always_comb begin
		rd_out_val = 'x;
		store_val = 'x;
		jump_target_addr = 'x;

		store_enable = 1'b0;
		rd_out_enable = 1'b0;
		jump_enable = 1'b0;

		case (curr_instr.opcode)
			OPCODE_OP_IMM: begin
				rd_out_enable = 1'b1;
				case (curr_instr.funct3)
					`FUNCT3_ADDI: rd_out_val = curr_instr.i_imm_input + reg_state.xregs[curr_instr.rs1];
					`FUNCT3_XORI: rd_out_val = curr_instr.i_imm_input ^ reg_state.xregs[curr_instr.rs1];
					`FUNCT3_ORI:  rd_out_val = curr_instr.i_imm_input | reg_state.xregs[curr_instr.rs1];
					`FUNCT3_ANDI: rd_out_val = curr_instr.i_imm_input & reg_state.xregs[curr_instr.rs1];
					default: rd_out_val = 'x;
				endcase
			end

			OPCODE_OP: begin
				rd_out_enable = 1'b1;
				case (curr_instr.funct3)
					`FUNCT3_ADD_SUB: case (curr_instr.funct7)
						`FUNCT7_ADD: rd_out_val = reg_state.xregs[curr_instr.rs1] + reg_state.xregs[curr_instr.rs2];
						`FUNCT7_SUB: rd_out_val = reg_state.xregs[curr_instr.rs1] - reg_state.xregs[curr_instr.rs2];
						default:     rd_out_val = 'X;
					endcase
					`FUNCT3_XOR:    rd_out_val = reg_state.xregs[curr_instr.rs1] ^ reg_state.xregs[curr_instr.rs2];
					`FUNCT3_OR:     rd_out_val = reg_state.xregs[curr_instr.rs1] | reg_state.xregs[curr_instr.rs2];
					`FUNCT3_AND:    rd_out_val = reg_state.xregs[curr_instr.rs1] & reg_state.xregs[curr_instr.rs2];
					default: rd_out_val = 'X;
				endcase
			end

			OPCODE_JAL: begin
				rd_out_enable = 1'b1;
				jump_enable = 1'b1;

				rd_out_val = reg_state.pc + 4;
				jump_target_addr = reg_state.pc + curr_instr.j_imm_input;
			end

			OPCODE_JALR: begin
				rd_out_enable = 1'b1;
				jump_enable = 1'b1;

				rd_out_val = reg_state.pc + 4;
				jump_target_addr = { i_effective_addr[31:1], 1'b0 };
			end

			OPCODE_BRANCH: begin
				case (curr_instr.funct3)
					`FUNCT3_BEQ: jump_enable = reg_state.xregs[curr_instr.rs1] == reg_state.xregs[curr_instr.rs2];
					`FUNCT3_BNE: jump_enable = reg_state.xregs[curr_instr.rs1] != reg_state.xregs[curr_instr.rs2];
					default:     jump_enable = 1'b0;
				endcase
				jump_target_addr = reg_state.pc + curr_instr.b_imm_input;
			end

			OPCODE_LUI: begin
				rd_out_enable = 1'b1;
				rd_out_val = curr_instr.u_imm_input;
			end

			OPCODE_LOAD: begin
				rd_out_enable = 1'b1;
				case (curr_instr.funct3)
					`FUNCT3_LB:  rd_out_val = `SIGEXT( load_val, 8, XLEN);
					`FUNCT3_LBU: rd_out_val =   `ZEXT( load_val, 8, XLEN);
					`FUNCT3_LH:  rd_out_val = `SIGEXT( load_val, 16, XLEN);
					`FUNCT3_LHU: rd_out_val =   `ZEXT( load_val, 16, XLEN);
					`FUNCT3_LW:  rd_out_val =          load_val;
					default:     rd_out_val = 'X;
				endcase
			end

			OPCODE_STORE: begin
				store_enable = 1'b1;
				store_val = reg_state.xregs[curr_instr.rs2];
			end
			OPCODE_UNKNOWN: begin /* Do nothing */ end
		endcase
	end
endmodule

module instruction_compute_testbench();
   reg_state_t reg_state;
	logic [XLEN-1:0] load_val, store_val, rd_out_val, jump_target_addr;
	logic store_enable, rd_out_enable, jump_enable;
	decoded_instruction_t instr;

	opcode_t opcode;
	rv_reg_t rs1, rs2, rd;
	logic [2:0] funct3;
	logic [6:0] funct7;
	logic [XLEN-1:0] i_imm, u_imm, j_imm, b_imm;

	assign instr.opcode = opcode;
	assign instr.rs1 = rs1;
	assign instr.rs2 = rs2;
	assign instr.rd = rd;
	assign instr.funct3 = funct3;
	assign instr.funct7 = funct7;
	assign instr.i_imm_input = i_imm;
	assign instr.j_imm_input = j_imm;
	assign instr.b_imm_input = b_imm;
	assign instr.u_imm_input = u_imm;

	logic [XLEN-1:0] x4, x8;
	assign reg_state.xregs[4] = x4;
	assign reg_state.xregs[8] = x8;

	instruction_compute dut (
		reg_state, load_val,
		instr,
		store_val, store_enable,
		rd_out_val, rd_out_enable,
		jump_target_addr, jump_enable
	);

   parameter delay = 10;

	initial begin
		rs1 <= 4; rs2 <= 8; reg_state.pc <= 32'h100;
		opcode <= OPCODE_OP_IMM; funct3 <= `FUNCT3_ADDI;                           x4 <= 10;          i_imm <= 32'd5; #delay;
		opcode <= OPCODE_OP;     funct3 <= `FUNCT3_ADD_SUB; funct7 <= `FUNCT7_ADD; x4 <= 11; x8 <= 6; i_imm <= 'X;    #delay;
		opcode <= OPCODE_JAL;    j_imm <= 32'hA8;                                                                     #delay;
		opcode <= OPCODE_JALR;   i_imm <= 32'hA8;                                  x4 <= 32'h300;                     #delay;
		opcode <= OPCODE_BRANCH; b_imm <= 32'hA8;           funct3 <= `FUNCT3_BEQ; x4 <= 15; x8 <= 12;                #(delay/2);
		opcode <= OPCODE_BRANCH; b_imm <= 32'hA8;           funct3 <= `FUNCT3_BEQ; x4 <= 15; x8 <= 15;                #(delay/2);
		opcode <= OPCODE_LUI;    u_imm <= 32'h8000;                                                                   #delay;
		opcode <= OPCODE_LOAD;   funct3 <= `FUNCT3_LB;                             load_val <= 32'hFA8;               #delay;
		opcode <= OPCODE_LOAD;   funct3 <= `FUNCT3_LBU;                            load_val <= 32'hCA8;               #delay;
		opcode <= OPCODE_STORE;                                                    x8 <= 15;                          #delay;
	end
endmodule
