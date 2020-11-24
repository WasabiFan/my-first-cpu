// `include "common.sv"
`include "isa.sv"

import isa_types::*;

`timescale 1 ns / 1 ns

// Memory map:
//   0x000 through 0x7ff: ROM
//   0x800 through 0xbff: RAM.
module memory (clock, addr, wwidth, wenable, wdata, rdata);
   input logic clock, wenable;
   input logic [XLEN-1:0] addr;
   input write_width_t wwidth;
   input logic [XLEN-1:0] wdata;
   output logic [XLEN-1:0] rdata;

   localparam RAM_START = 32'h800;

   logic is_rom;
   assign is_rom = addr < RAM_START;

   logic [XLEN-1:0] rom_addr, ram_addr;

   assign rom_addr = addr;
   assign ram_addr = addr - RAM_START;

   logic ram_wenable;
   logic [XLEN-1:0] ram_rdata, rom_rdata;

   assign ram_wenable = ~is_rom & wenable;
   always_comb begin
      if (is_rom) rdata = rom_rdata;
      else        rdata = ram_rdata;
   end

   internal_rom rom (
      rom_addr,
      clock,
      rom_rdata
   );

   ram ram (
      clock,
      ram_addr,
      wwidth,
      ram_wenable,
      wdata,
      ram_rdata
   );
endmodule
