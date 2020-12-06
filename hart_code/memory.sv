// `include "common.sv"
`include "isa.sv"

import isa_types::*;

`timescale 1 ns / 1 ns

// Memory map:
//   0x0000 through 0x07ff: ROM
//   0x0800 through 0x0bff: RAM
//   0x1000 through 0x17ff: memory-mapped input peripherals (max. length, likely smaller)
//   0x1800 through 0x1fff: memory-mapped output peripherals (max. length, likely smaller)
module memory #( parameter INPUT_PERIPH_LEN, OUTPUT_PERIPH_LEN) (clock, ctrl, rdata, input_peripherals_mem, output_peripherals_mem);
   input logic clock;
   input mem_control_t ctrl;
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
      if      (ctrl.addr < RAM_START)           address_target = target_rom;
      else if (ctrl.addr < INPUT_PERIPH_START)  address_target = target_ram;
      else if (ctrl.addr < OUTPUT_PERIPH_START) address_target = target_input_peripheral;
      else                                 address_target = target_output_peripheral;
   end

   logic [XLEN-1:0] rom_addr, ram_addr;

   assign rom_addr = ctrl.addr;
   assign ram_addr = ctrl.addr - RAM_START;

   logic [XLEN-1:0] ram_rdata, rom_rdata;

   // Read controller
   always_comb begin
      case (address_target)
         target_rom:              rdata = rom_rdata;
         target_ram:              rdata = ram_rdata;
         target_input_peripheral: rdata = {
            input_peripherals_mem[ctrl.addr - INPUT_PERIPH_START + 3],
            input_peripherals_mem[ctrl.addr - INPUT_PERIPH_START + 2],
            input_peripherals_mem[ctrl.addr - INPUT_PERIPH_START + 1],
            input_peripherals_mem[ctrl.addr - INPUT_PERIPH_START + 0]
         };
         target_output_peripheral: rdata = 'X;
      endcase
   end

   // Write controller
   logic ram_wenable;
   assign ram_wenable = (address_target == target_ram) & ctrl.wenable;
   always_ff @(posedge clock) begin
      if (ctrl.wenable && address_target == target_output_peripheral) begin
         output_peripherals_mem[ctrl.addr - OUTPUT_PERIPH_START] <= ctrl.wdata[7:0];

         if (ctrl.wwidth == write_halfword || ctrl.wwidth == write_word)
            output_peripherals_mem[ctrl.addr - OUTPUT_PERIPH_START + 1] <= ctrl.wdata[15:8];

         if (ctrl.wwidth == write_word) begin
            output_peripherals_mem[ctrl.addr - OUTPUT_PERIPH_START + 2] <= ctrl.wdata[23:16];
            output_peripherals_mem[ctrl.addr - OUTPUT_PERIPH_START + 3] <= ctrl.wdata[31:24];
         end
      end
   end

   rom rom (
      clock,
      rom_addr,
      rom_rdata
   );

   ram ram (
      clock,
      ram_addr,
      ctrl.wwidth,
      ram_wenable,
      ctrl.wdata,
      ram_rdata
   );
endmodule

module memory_testbench();
	logic clk;

	logic mem_wenable;
   logic [XLEN-1:0] mem_addr;
   logic [XLEN-1:0] mem_wdata, mem_rdata;
   write_width_t mem_wwidth;
   
   logic [7:0] input_peripherals_mem [31:0];
   logic [7:0] output_peripherals_mem [31:0];

   mem_control_t mem_ctrl;
	memory #( .INPUT_PERIPH_LEN('h20), .OUTPUT_PERIPH_LEN('h20) ) mem (clk, mem_ctrl, mem_rdata, input_peripherals_mem, output_peripherals_mem);

   assign mem_ctrl.addr = mem_addr;
   assign mem_ctrl.wenable = mem_wenable;
   assign mem_ctrl.wdata = mem_wdata;
   assign mem_ctrl.wwidth = mem_wwidth;

   assign input_peripherals_mem[3] = 'hDE;
   assign input_peripherals_mem[2] = 'hAD;
   assign input_peripherals_mem[1] = 'hBE;
   assign input_peripherals_mem[0] = 'hEF;
   
   assign input_peripherals_mem[28 + 3] = 'hC0;
   assign input_peripherals_mem[28 + 2] = 'h01;
   assign input_peripherals_mem[28 + 1] = 'hD0;
   assign input_peripherals_mem[28 + 0] = 'h0D;

	// Set up the clock
	parameter CLOCK_PERIOD=100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end

	initial begin
      mem_wenable <= 0;
      // Normal write to the first word of the RAM section
		@(posedge clk); mem_wenable <= 1; mem_addr <= 32'h800; mem_wwidth <= write_word; mem_wdata <= 32'h87654321;
		@(posedge clk); mem_wenable <= 0;
		@(posedge clk);
		@(posedge clk);

      // Normal write to the last word of the RAM section
		@(posedge clk); mem_wenable <= 1; mem_addr <= 32'hbfc; mem_wwidth <= write_word; mem_wdata <= 32'hABCDEFAB;
		@(posedge clk); mem_wenable <= 0;
		@(posedge clk);
		@(posedge clk);

      // Normal write to the first word of the output peripherals section
		@(posedge clk); mem_wenable <= 1; mem_addr <= 32'h1800; mem_wwidth <= write_word; mem_wdata <= 32'hFEDCBA98;
		@(posedge clk); mem_wenable <= 0;
		@(posedge clk);
		@(posedge clk);

      // Normal write to the last word of the output peripherals section
		@(posedge clk); mem_wenable <= 1; mem_addr <= 32'h181c; mem_wwidth <= write_word; mem_wdata <= 32'h12345678;
		@(posedge clk); mem_wenable <= 0;
		@(posedge clk);
		@(posedge clk);

      // Read the first word of the ROM section
		@(posedge clk);                   mem_addr <= 32'h000;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

      // Read the last word of the ROM section
		@(posedge clk);                   mem_addr <= 32'h7fc;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

      // Read back the first word of the RAM section
		@(posedge clk);                   mem_addr <= 32'h800;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

      // Read back the last word of the RAM section
		@(posedge clk);                   mem_addr <= 32'hbfc;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

      // Read the first word of the input peripherals section
		@(posedge clk);                   mem_addr <= 32'h1000;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

      // Read the last word of the input peripherals section
		@(posedge clk);                   mem_addr <= 32'h101c;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

      // Read back the first word of the out peripherals section
		@(posedge clk);                   mem_addr <= 32'h1800;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

      // Read back the last word of the out peripherals section
		@(posedge clk);                   mem_addr <= 32'h181c;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		$stop; // End the simulation
	end
endmodule