`include "isa.sv"

import isa_types::*;

`timescale 1 ns / 1 ns

module stage_writeback(
		enable,
		reg_state,
		load_val,
		curr_instr,
		is_complete,
		mem_ctrl,
		rd_out_val, rd_out_enable,
		jump_target_addr, jump_enable
	);
	input logic enable;
	input reg_state_t reg_state;
	input logic [XLEN-1:0] load_val;
	input decoded_instruction_t curr_instr;
	output logic is_complete;
	output mem_control_t mem_ctrl;
	output logic rd_out_enable, jump_enable;
	output logic [XLEN-1:0] rd_out_val, jump_target_addr;

	logic [XLEN-1:0] store_val;
	logic store_enable;

	instruction_compute compute (
		reg_state, load_val,
		curr_instr,
		store_val, store_enable,
		rd_out_val, rd_out_enable,
		jump_target_addr, jump_enable
	);

	assign is_complete = enable;

	logic [XLEN-1:0] s_effective_addr;
	assign s_effective_addr = curr_instr.s_imm_input + reg_state.xregs[curr_instr.rs1];

	// Memory controller (write-only)
	always_comb begin
		if (enable && store_enable) begin
			mem_ctrl.addr = s_effective_addr;
			mem_ctrl.wenable = 1'b1;
			mem_ctrl.wdata = store_val;
			case (curr_instr.funct3)
				`FUNCT3_SB: mem_ctrl.wwidth = write_byte;
				`FUNCT3_SH: mem_ctrl.wwidth = write_halfword;
				`FUNCT3_SW: mem_ctrl.wwidth = write_word;
				default:    mem_ctrl.wwidth = write_byte; // don't care
			endcase
		end else begin
			mem_ctrl.wenable = 1'b0;
			mem_ctrl.addr = 'X;
			mem_ctrl.wdata = 'X;
			mem_ctrl.wwidth = write_byte; // don't care
		end
	end
endmodule

module stage_writeback_testbench();
	logic enable;
	reg_state_t reg_state;
	logic [XLEN-1:0] load_val;
	decoded_instruction_t curr_instr;

	logic is_complete;
	mem_control_t mem_ctrl;
	logic rd_out_enable, jump_enable;
	logic [XLEN-1:0] rd_out_val, jump_target_addr;

	stage_writeback dut (
		enable,
		reg_state,
		load_val,
		curr_instr,
		is_complete,
		mem_ctrl,
		rd_out_val,
		rd_out_enable,
		jump_target_addr,
		jump_enable
	);

	localparam delay = 10;

	initial begin
		enable <= 1'b0; reg_state.xregs[1] <= 'h100; reg_state.xregs[2] <= 7; curr_instr.opcode <= OPCODE_OP_IMM; #delay;
		enable <= 1'b1; #delay;
		enable <= 1'b0; #delay;
		enable <= 1'b1; curr_instr.opcode <= OPCODE_STORE; curr_instr.rs1 <= 1; curr_instr.rs2 <= 2; curr_instr.funct3 <= 3'b000; curr_instr.s_imm_input <= 'h10; #delay;
		enable <= 1'b0; #delay;
	end
endmodule
