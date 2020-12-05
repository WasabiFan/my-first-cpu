// `include "common.sv"
`include "isa.sv"

import isa_types::*;

`timescale 1 ns / 1 ns

module rom (clock, addr, rdata);
   input logic clock;
   input logic [XLEN-1:0] addr;
   output logic [XLEN-1:0] rdata;

   logic [1:0] addr_offset;
   always_ff @(posedge clock) begin
      addr_offset <= addr[1:0];
   end

   logic [8:0] word_addr;
   assign word_addr = addr[10:2];

   logic [XLEN-1:0] effective_rdata;
   always_comb begin
      // Since this is providing output, we must ensure that it isn't affected by input
      // changes (to addr) after the read occurs.
      rdata = effective_rdata >> (addr_offset * 8);
   end

   internal_rom rom (
      word_addr,
      clock,
      effective_rdata
   );
endmodule
