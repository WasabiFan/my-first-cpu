// `include "common.sv"
`include "isa.sv"

import isa_types::*;

`timescale 1 ns / 1 ns

// Memory map:
//   0x0000 through 0x07ff: ROM
//   0x0800 through 0x0bff: RAM
//   0x1000 through 0x17ff: memory-mapped input peripherals (max. length, likely smaller)
//   0x1800 through 0x1fff: memory-mapped output peripherals (max. length, likely smaller)
module memory #( parameter INPUT_PERIPH_LEN, OUTPUT_PERIPH_LEN) (clock, addr, wwidth, wenable, wdata, rdata, input_peripherals_mem, output_peripherals_mem);
   input logic clock, wenable;
   input logic [XLEN-1:0] addr;
   input write_width_t wwidth;
   input logic [XLEN-1:0] wdata;
   input logic [7:0] input_peripherals_mem [INPUT_PERIPH_LEN-1:0];
   output logic [7:0] output_peripherals_mem [OUTPUT_PERIPH_LEN-1:0];
   output logic [XLEN-1:0] rdata;

   localparam RAM_START           = 32'h0800;
   localparam INPUT_PERIPH_START  = 32'h1000;
   localparam OUTPUT_PERIPH_START = 32'h1800;

   enum logic [1:0] {
      target_rom,
      target_ram,
      target_input_peripheral,
      target_output_peripheral
   } address_target;

   always_comb begin
      if      (addr < RAM_START)           address_target = target_rom;
      else if (addr < INPUT_PERIPH_START)  address_target = target_ram;
      else if (addr < OUTPUT_PERIPH_START) address_target = target_input_peripheral;
      else                                 address_target = target_output_peripheral;
   end

   logic [XLEN-1:0] rom_addr, ram_addr;

   assign rom_addr = addr;
   assign ram_addr = addr - RAM_START;

   logic [XLEN-1:0] ram_rdata, rom_rdata;

   // Read controller
   always_comb begin
      case (address_target)
         target_rom:              rdata = rom_rdata;
         target_ram:              rdata = ram_rdata;
         target_input_peripheral: rdata = {
            input_peripherals_mem[addr - INPUT_PERIPH_START + 3],
            input_peripherals_mem[addr - INPUT_PERIPH_START + 2],
            input_peripherals_mem[addr - INPUT_PERIPH_START + 1],
            input_peripherals_mem[addr - INPUT_PERIPH_START + 0]
         };
         target_output_peripheral: rdata = 'X;
      endcase
   end

   // Write controller
   logic ram_wenable;
   assign ram_wenable = (address_target == target_ram) & wenable;
   always_ff @(posedge clock) begin
      if (wenable && address_target == target_output_peripheral) begin
         output_peripherals_mem[addr - OUTPUT_PERIPH_START] <= wdata[7:0];

         if (wwidth == write_halfword)
            output_peripherals_mem[addr - OUTPUT_PERIPH_START + 1] <= wdata[15:8];

         if (wwidth == write_halfword || wwidth == write_word) begin
            output_peripherals_mem[addr - OUTPUT_PERIPH_START + 2] <= wdata[23:16];
            output_peripherals_mem[addr - OUTPUT_PERIPH_START + 3] <= wdata[31:24];
         end
      end
   end

   internal_rom rom (
      // Addresses are word-oriented; for ROM, we just don't support non-word-aligned reads.
      rom_addr[10:2],
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
