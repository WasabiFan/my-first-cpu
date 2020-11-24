// `include "common.sv"
`include "isa.sv"

import isa_types::*;

`timescale 1 ns / 1 ns

module ram (clock, addr, wwidth, wenable, wdata, rdata);
   input logic clock, wenable;
   input logic [XLEN-1:0] addr;
   input write_width_t wwidth;
   input logic [XLEN-1:0] wdata;
   output logic [XLEN-1:0] rdata;

   logic [1:0] addr_offset;
   always_ff @(posedge clock) begin
      addr_offset <= addr[1:0];
   end

   logic [7:0] word_addr;
   assign word_addr = addr[9:2];

   logic [XLEN-1:0] effective_wdata, effective_rdata;
   logic [3:0] be;
   always_comb begin
      case (wwidth)
         write_byte:     be = 4'b0001 << addr[1:0];
         write_halfword: be = 4'b0011 << addr[1:0];
         write_word:     be = 4'b1111;
      endcase

      // TODO: This leaks the alignment details, since unset bits are now 0 instead of X
      effective_wdata = (wdata << (addr[1:0] * 8));

      // Since this is providing output, we must ensure that it isn't affected by input
      // changes after the read occurs.
      rdata = effective_rdata >> (addr_offset * 8);
   end

   internal_ram ram (
      word_addr,
      be,
      clock,
      effective_wdata,
      wenable,
      effective_rdata
   );
endmodule

module ram_testbench();
	logic clk;

	logic mem_wenable;
   logic [XLEN-1:0] mem_addr;
   logic [XLEN-1:0] mem_wdata, mem_rdata;
   write_width_t mem_wwidth;
	ram mem(clk, mem_addr, mem_wwidth, mem_wenable, mem_wdata, mem_rdata);

	// Set up the clock
	parameter CLOCK_PERIOD=100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end

	initial begin
      mem_wenable <= 0;
      // Word-aligned write, full word
		@(posedge clk); mem_wenable <= 1; mem_addr <= 32'h10; mem_wwidth <= write_word; mem_wdata <= 32'h87654321;
		@(posedge clk); mem_wenable <= 0;
		@(posedge clk);
		@(posedge clk);

      // Word-aligned write, half word
		@(posedge clk); mem_wenable <= 1; mem_addr <= 32'h14; mem_wwidth <= write_halfword;
		@(posedge clk); mem_wenable <= 0;
		@(posedge clk);
		@(posedge clk);

      // Word-aligned write, single byte
		@(posedge clk); mem_wenable <= 1; mem_addr <= 32'h18; mem_wwidth <= write_byte;
		@(posedge clk); mem_wenable <= 0;
		@(posedge clk);
		@(posedge clk);

      // Halfword-aligned write, upper, half word
		@(posedge clk); mem_wenable <= 1; mem_addr <= 32'h1e; mem_wwidth <= write_halfword;
		@(posedge clk); mem_wenable <= 0;
		@(posedge clk);
		@(posedge clk);

      // Halfword-aligned write, upper, half word, overwritting upper halfword from first write
		@(posedge clk); mem_wenable <= 1; mem_addr <= 32'h12; mem_wwidth <= write_halfword; mem_wdata <= 32'hFEDC;
		@(posedge clk); mem_wenable <= 0;
		@(posedge clk);
		@(posedge clk);                   mem_addr <= 32'h10;
		@(posedge clk);
		@(posedge clk);

      // Byte-aligned write, second of four, single byte, overwriting upper byte of first halfword
		@(posedge clk); mem_wenable <= 1; mem_addr <= 32'h11; mem_wwidth <= write_byte; mem_wdata <= 32'hBA;
		@(posedge clk); mem_wenable <= 0;
		@(posedge clk);
		@(posedge clk);                   mem_addr <= 32'h10;
		@(posedge clk);
		@(posedge clk);

		$stop; // End the simulation
	end
endmodule