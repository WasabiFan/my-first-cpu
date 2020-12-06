// `include "common.sv"
`include "isa.sv"

import isa_types::*;

module instruction_decoder (instr_bits, decoded_instruction);
	input logic [ILEN-1:0] instr_bits;
	output decoded_instruction_t decoded_instruction;

	assign decoded_instruction.opcode = extract_opcode(instr_bits);

	assign decoded_instruction.rd = instr_bits[11:7];
	assign decoded_instruction.rs1 = instr_bits[19:15];
	assign decoded_instruction.rs2 = instr_bits[24:20];

	assign decoded_instruction.funct3 = instr_bits[14:12];
	assign decoded_instruction.funct7 = instr_bits[31:25];

	logic [11:0] i_imm_raw, s_imm_raw;
	logic [12:0] b_imm_raw;
	logic [21:0] j_imm_raw;
	assign i_imm_raw = instr_bits[31:20];
	assign s_imm_raw = { instr_bits[31:25], instr_bits[11:7] };
	assign j_imm_raw = { instr_bits[31], instr_bits[19:12], instr_bits[20], instr_bits[30:25], instr_bits[24:21], 1'b0 };
	assign b_imm_raw = { instr_bits[31], instr_bits[7], instr_bits[30:25], instr_bits[11:8], 1'b0 };

	assign decoded_instruction.i_imm_input = `SIGEXT(i_imm_raw, 12, XLEN);
	assign decoded_instruction.s_imm_input = `SIGEXT(s_imm_raw, 12, XLEN);
	assign decoded_instruction.u_imm_input = { instr_bits[31:12], 12'b0 };
	assign decoded_instruction.j_imm_input = `SIGEXT(j_imm_raw, 20, XLEN);
	assign decoded_instruction.b_imm_input = `SIGEXT(b_imm_raw, 12, XLEN);
endmodule

module instruction_decoder_testbench ();
	logic [ILEN-1:0] instr_bits;
	decoded_instruction_t decoded_instruction;

	instruction_decoder dut (instr_bits, decoded_instruction);

	localparam delay = 10;

	initial begin
		// 010cc783 lbu a5,16(s9)
		// LOAD, I-type, rs1 25, rd 15, funct3 100, immediate 16
		instr_bits <= 32'h010cc783; #delay;
		// 02912a23 sw s1,52(sp)
		// STORE, S-type, rs1 2, rs2 9, immediate 52
		instr_bits <= 32'h02912a23; #delay;
		// fc010113 addi sp,sp,-64
		// OP_IMM, I-type, rs1 2, rd 2, funct3 000, immediate -64
		instr_bits <= 32'hfc010113; #delay;
		// 84: fed79ce3 bne a5,a3,7c
		// BRANCH, B-type, rs1 15, rs2 13, funct3 001, immediate -8
		instr_bits <= 32'hfed79ce3; #delay;
		// 00001717 auipc a4,0x1
		// AUIPC, U-type, rd 14, immediate 0x1000
		instr_bits <= 32'h00001717; #delay;
		// 00001cb7 lui s9,0x1
		// LUI, U-type, rd 25, immediate 0x1000
		instr_bits <= 32'h00001cb7; #delay;
	end
endmodule