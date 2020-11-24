`include "isa.sv"

import isa_types::*;

module memory_demo (CLOCK_50, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, LEDR, SW);
	output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output logic [9:0] LEDR;
	input  logic [3:0] KEY;
	input  logic [9:0] SW;
	input  logic CLOCK_50;

	// Default values, turns off the HEX displays
	assign HEX0 = 7'b1111111;
	assign HEX1 = 7'b1111111;
	assign HEX2 = 7'b1111111;
	assign HEX3 = 7'b1111111;
	assign HEX4 = 7'b1111111;
	assign HEX5 = 7'b1111111;

	logic [31:0] big_counter;
	always_ff @(posedge CLOCK_50) begin
		if (~KEY[1]) big_counter = 0;
		else         big_counter += 1;
	end

	logic mem_wenable;
   logic [XLEN-1:0] mem_addr;
   logic [XLEN-1:0] mem_wdata, mem_rdata;
   write_width_t mem_wwidth;
	memory mem(CLOCK_50, mem_addr, mem_wwidth, mem_wenable, mem_wdata, mem_rdata);

	assign LEDR[9] = ~KEY[1];
	assign LEDR[8] = ~KEY[0];

	assign mem_wenable = ~KEY[0];
	assign mem_wwidth = write_byte;
	assign mem_addr = SW[9:0];
	assign mem_wdata = big_counter[23:16];

   assign LEDR[7:0] = mem_rdata[7:0];
endmodule
