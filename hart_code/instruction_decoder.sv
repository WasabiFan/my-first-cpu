// `include "common.sv"
`include "isa.sv"

import isa_types::*;

module instruction_decoder (instr_bits, opcode, rs1, rs2, rd, funct3, funct7, i_imm_input, s_imm_input);
	input logic [ILEN-1:0] instr_bits;
	output opcode_t opcode;
	output rv_reg_t rs1, rs2, rd;
	output logic [2:0] funct3;
	output logic [6:0] funct7;
	output logic [XLEN-1:0] i_imm_input, s_imm_input;

	logic [6:0] field_opcode;
	assign field_opcode = instr_bits[6:0];

	always_comb begin
		// field_opcode[1:0] are always 11
		case (field_opcode[6:2])
			`OPCODE_OP_IMM: opcode = OPCODE_OP_IMM;
			`OPCODE_OP:     opcode = OPCODE_OP;
			`OPCODE_LOAD:   opcode = OPCODE_LOAD;
			`OPCODE_STORE:  opcode = OPCODE_STORE;
			default:        opcode = OPCODE_UNKNOWN;
		endcase
	end

	assign rd = instr_bits[11:7];
	assign rs1 = instr_bits[19:15];
	assign rs2 = instr_bits[23:20];

	assign funct3 = instr_bits[14:12];
	assign funct7 = instr_bits[31:25];

	logic [11:0] i_imm_raw, s_imm_raw;
	assign i_imm_raw = instr_bits[31:20];
	assign s_imm_raw = { instr_bits[31:25], instr_bits[11:7] };

	assign i_imm_input = `SIGEXT(i_imm_raw, 12, XLEN);
	assign s_imm_input = `SIGEXT(s_imm_raw, 12, XLEN);
endmodule