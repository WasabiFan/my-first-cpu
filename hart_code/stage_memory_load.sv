`include "isa.sv"

import isa_types::*;

module stage_memory_load(clock, reset, enable, i_effective_addr, mem_rdata, is_complete, mem_ctrl, loaded_value);
	input logic clock, reset, enable;
	input logic [XLEN-1:0] i_effective_addr;
	input logic [XLEN-1:0] mem_rdata;
	output logic is_complete;
	output mem_control_t mem_ctrl;
	output logic [XLEN-1:0] loaded_value;

	logic [1:0] remaining_read_cycles, next_remaining_read_cycles;

	logic read_complete;
	assign read_complete = remaining_read_cycles == 0;

	assign is_complete = enable && read_complete;

	assign mem_ctrl.wenable = '0;
	assign mem_ctrl.addr = i_effective_addr;

	always_comb begin
		if (enable) next_remaining_read_cycles = remaining_read_cycles - 2'b1;
		else        next_remaining_read_cycles = mem_read_latency;
	end

	always_ff @(posedge clock) begin
		if (reset) begin
			remaining_read_cycles <= mem_read_latency;
		end else begin
			if (is_complete) begin
				loaded_value <= mem_rdata;
			end
			remaining_read_cycles <= next_remaining_read_cycles;
		end
	end
endmodule

module stage_memory_load_testbench();
	logic clk, reset;
	logic enable;
	logic [XLEN-1:0] instr_addr;
	logic [XLEN-1:0] mem_rdata;

	mem_control_t mem_ctrl;
	logic is_complete;
	logic [XLEN-1:0] loaded_value;

	stage_memory_load dut (clk, reset, enable, instr_addr, mem_rdata, is_complete, mem_ctrl, loaded_value);

	// Set up the clock
	parameter CLOCK_PERIOD=100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end

	initial begin
		@(posedge clk); reset <= 1;                             enable <= 0;
		@(posedge clk); reset <= 0; instr_addr <= 32'hCAFEBABE;              mem_rdata <= 32'h00000000;
		// Confirm it does nothing
		@(posedge clk);
		@(posedge clk);

		// Enable and read a value
		@(posedge clk);             instr_addr <= 32'hDEADBEEF; enable <= 1;
		@(posedge clk);
		@(posedge clk);                                                      mem_rdata <= 32'hAB12CD34;
		// After read should have finished, disable and validate the outputs hold
		@(posedge clk);                                         enable <= 0;
		@(posedge clk);
		@(posedge clk);

		// Perform another read
		@(posedge clk);             instr_addr <= 32'hCAFED00D; enable <= 1;
		@(posedge clk);
		@(posedge clk);                                                      mem_rdata <= 32'hEF56AB78;
		// After read should have finished, disable and validate the outputs hold
		@(posedge clk);                                         enable <= 0;
		@(posedge clk);
		@(posedge clk);

		$stop; // End the simulation
	end
endmodule
