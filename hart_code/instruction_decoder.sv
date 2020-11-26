// `include "common.sv"
`include "isa.sv"

import isa_types::*;

module instruction_decoder (instr_bits, opcode, rs1, rs2, rd, funct3, funct7, i_imm_input, s_imm_input, u_imm_input, j_imm_input, b_imm_input);
	input logic [ILEN-1:0] instr_bits;
	output opcode_t opcode;
	output rv_reg_t rs1, rs2, rd;
	output logic [2:0] funct3;
	output logic [6:0] funct7;
	output logic [XLEN-1:0] i_imm_input, s_imm_input, u_imm_input, j_imm_input, b_imm_input;

	assign opcode = extract_opcode(instr_bits);

	assign rd = instr_bits[11:7];
	assign rs1 = instr_bits[19:15];
	assign rs2 = instr_bits[23:20];

	assign funct3 = instr_bits[14:12];
	assign funct7 = instr_bits[31:25];

	logic [11:0] i_imm_raw, s_imm_raw;
	logic [12:0] b_imm_raw;
	logic [21:0] j_imm_raw;
	assign i_imm_raw = instr_bits[31:20];
	assign s_imm_raw = { instr_bits[31:25], instr_bits[11:7] };
	assign j_imm_raw = { instr_bits[31], instr_bits[19:12], instr_bits[20], instr_bits[30:25], instr_bits[24:21], 1'b0 };
	assign b_imm_raw = { instr_bits[31], instr_bits[7], instr_bits[30:25], instr_bits[11:8], 1'b0 };

	assign i_imm_input = `SIGEXT(i_imm_raw, 12, XLEN);
	assign s_imm_input = `SIGEXT(s_imm_raw, 12, XLEN);
	assign u_imm_input = { instr_bits[31:12], 12'b0 };
	assign j_imm_input = `SIGEXT(j_imm_raw, 20, XLEN);
	assign b_imm_input = `SIGEXT(b_imm_raw, 12, XLEN);
endmodule
