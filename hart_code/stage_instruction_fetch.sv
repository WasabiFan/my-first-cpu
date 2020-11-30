`include "isa.sv"

import isa_types::*;

module stage_instruction_fetch(clock, reset, enable, pc, mem_rdata, is_complete, mem_ctrl, instr_bits, is_next_instruction_load);
	input logic clock, reset, enable;
	input logic [XLEN-1:0] pc;
	input logic [XLEN-1:0] mem_rdata;
	output mem_control_t mem_ctrl;
	output logic is_complete;
	output logic [ILEN-1:0] instr_bits;
	output logic is_next_instruction_load;

	logic [1:0] remaining_read_cycles, next_remaining_read_cycles;
	logic is_halted, next_is_halted;

	logic read_complete;
	assign read_complete = remaining_read_cycles == 0;

	// Opcode computed from the current memory output, rather than the captured instr_bits.
	// Used to inform state transitions out of the instruction fetch stage (before we've
	// put the instruction word through our instr_bits latch).
	opcode_t speculative_opcode;
	assign speculative_opcode = extract_opcode(mem_rdata);
	assign next_is_halted = is_halted || (enable && read_complete && speculative_opcode == OPCODE_UNKNOWN);

	assign is_complete = enable && read_complete && ~is_halted && ~next_is_halted;

	assign mem_ctrl.wenable = '0;
	assign mem_ctrl.addr = pc;

	assign is_next_instruction_load = speculative_opcode == OPCODE_LOAD;

	always_comb begin
		if (enable) next_remaining_read_cycles = remaining_read_cycles - 2'b1;
		else        next_remaining_read_cycles = mem_read_latency;
	end

	always_ff @(posedge clock) begin
		if (reset) begin
			is_halted <= 0;
			remaining_read_cycles <= mem_read_latency;
		end else begin
			if (is_complete) begin
				instr_bits <= mem_rdata;
			end
			is_halted <= next_is_halted;
			remaining_read_cycles <= next_remaining_read_cycles;
		end
	end
endmodule

module stage_instruction_fetch_testbench();
	logic clk, reset;
	logic enable;
	logic [XLEN-1:0] pc;
	logic [XLEN-1:0] mem_rdata;

	mem_control_t mem_ctrl;
	logic is_complete;
	logic [ILEN-1:0] instr_bits;
	logic is_next_instruction_load;

	stage_instruction_fetch dut (clk, reset, enable, pc, mem_rdata, is_complete, mem_ctrl, instr_bits, is_next_instruction_load);

	// Set up the clock
	parameter CLOCK_PERIOD=100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end

	initial begin
		@(posedge clk); reset <= 1;                     enable <= 0;
		@(posedge clk); reset <= 0; pc <= 32'hCAFEBABE;              mem_rdata <= 32'h00000000;
		// Confirm it does nothing
		@(posedge clk);
		@(posedge clk);

		// Try normal operation with an ADD (not LOAD)
		@(posedge clk);             pc <= 32'hDEADBEEF; enable <= 1;
		@(posedge clk);
		@(posedge clk);                                              mem_rdata <= 32'hfff78793;
		// After read should have finished, disable and validate the outputs hold
		@(posedge clk);                                 enable <= 0;
		@(posedge clk);
		@(posedge clk);

		// Re-enable with a new instruction, this time a LOAD
		@(posedge clk);             pc <= 32'hCAFED00D; enable <= 1;
		@(posedge clk);
		@(posedge clk);                                              mem_rdata <= 32'h00072603;
		// After read should have finished, disable and validate the outputs hold
		// is_next_instruction_load should now be 1
		@(posedge clk);                                 enable <= 0;
		@(posedge clk);
		@(posedge clk);

		// Try again with an unknown instruction and confirm it's "stuck" (never complete)
		@(posedge clk);             pc <= 32'hDEADBEEF; enable <= 1;
		@(posedge clk);
		@(posedge clk);                                              mem_rdata <= 32'h00000000;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);                                 enable <= 0;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		// Reset and provide the same inputs as the first phase; confirm it still works
		@(posedge clk); reset <= 1;
		@(posedge clk); reset <= 0;
		// Confirm it does nothing
		@(posedge clk);
		@(posedge clk);

		// Try normal operation with an ADD (not LOAD)
		@(posedge clk);             pc <= 32'hDEADBEEF; enable <= 1;
		@(posedge clk);
		@(posedge clk);                                              mem_rdata <= 32'hfff78793;
		@(posedge clk);
		@(posedge clk);

		$stop; // End the simulation
	end
endmodule
