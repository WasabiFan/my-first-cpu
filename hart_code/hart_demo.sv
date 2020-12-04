`include "isa.sv"

`timescale 1 ns / 1 ns

import isa_types::*;

module hart_demo (CLOCK_50, GPIO_1, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, LEDR, SW);
	output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output logic [9:0] LEDR;
	output logic [35:0] GPIO_1;
	input  logic [3:0] KEY;
	input  logic [9:0] SW;
	input  logic CLOCK_50;

	// Default values, turns off the HEX displays
	// assign HEX0 = 7'b1111111;
	// assign HEX1 = 7'b1111111;
	// assign HEX2 = 7'b1111111;
	assign HEX3 = 7'b1111111;
	assign HEX4 = 7'b1111111;
	assign HEX5 = 7'b1111111;

   logic [7:0] input_peripherals_mem ['h20-1:0];
   logic [7:0] output_peripherals_mem ['h50-1:0];

	logic reset, reset_pin, clock;
	assign reset_pin = SW[9];
	assign clock = CLOCK_50;
	
	always_ff @(posedge clock) begin
		reset <= reset_pin;
	end

   reg_state_t reg_state;
   hart #( .OUTPUT_PERIPH_LEN('h50) ) cpu (clock, reset, reg_state, input_peripherals_mem, output_peripherals_mem);

	// Render current instruction on 7-segment displays
	seg7_hex pc0 (reg_state.pc[3:0], HEX0);
	seg7_hex pc1 (reg_state.pc[7:4], HEX1);
	seg7_hex pc2 (reg_state.pc[11:8], HEX2);

	// Start addresses for each peripheral.
	// Inputs are mapped starting at 0x1000, outputs at 0x1800.
	localparam IN_SW_START            = 32'h0;  // 10 bytes, one per switch
	localparam IN_KEY_START           = 32'h10;  // 4 bytes, one per key
	localparam OUT_LEDR_START         = 32'h0;  // 10 bytes, one per LED
	localparam OUT_LEDMAT_RED_START   = 32'h10; // 32 bytes, one per 8 LEDs
	localparam OUT_LEDMAT_GREEN_START = 32'h30; // 32 bytes, one per 8 LEDs

	localparam PIXEL_MATRIX_NUM_BYTES = 32;

	logic [15:0][15:0] matrix_red, matrix_green;

	LEDDriver #( .FREQDIV(14) ) matrix (
		GPIO_1,
		matrix_red,
		matrix_green,
		1'b1,
		clock,
		reset
	);

	genvar i;
	generate
		// Map LEDs to output addresses
		for (i = 0; i < 10; i++) begin : io_assign_led
			assign LEDR[i] = output_peripherals_mem[OUT_LEDR_START+i] != 0;
		end

		// Map red and green matrix pixels
		for (i = 0; i < PIXEL_MATRIX_NUM_BYTES/2; i++) begin : io_assign_matrix
			assign matrix_red[i] = {
				output_peripherals_mem[OUT_LEDMAT_RED_START + i * 2 + 1],
				output_peripherals_mem[OUT_LEDMAT_RED_START + i * 2    ]
			};
			assign matrix_green[i] = {
				output_peripherals_mem[OUT_LEDMAT_GREEN_START + i * 2 + 1],
				output_peripherals_mem[OUT_LEDMAT_GREEN_START + i * 2    ]
			};
		end
	endgenerate

	generate
		// Map switches to input addresses
		for (i = 0; i < 10; i++) begin : io_assign_sw
			// SW9 is reset, so that shouldn't be used in code, but it's here anyway.
			always_ff @(posedge clock) begin
				input_peripherals_mem[IN_SW_START+i] <= SW[i];
			end
		end

		// Map keys
		for (i = 0; i < 4; i++) begin : io_asign_key
			always_ff @(posedge clock) begin
				input_peripherals_mem[IN_KEY_START+i] <= KEY[i] == 0;
			end
		end
	endgenerate
endmodule

module hart_demo_testbench();
	logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	logic [9:0] LEDR;
	logic [3:0] KEY;
	logic [9:0] SW;
	logic CLOCK_50;
	logic [35:0] GPIO_1;
   logic clk;

	hart_demo dut (.CLOCK_50(clk), .GPIO_1, .HEX0, .HEX1, .HEX2, .HEX3, .HEX4, .HEX5, .KEY, .LEDR, .SW);

   assign CLOCK_50 = clk;

	// Set up the clock
	parameter CLOCK_PERIOD=100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end

	initial begin
		KEY[0] = 1;
		KEY[1] = 1;
		KEY[2] = 1;
		KEY[3] = 1;

		@(posedge clk); SW[9] <= 1;
		@(posedge clk); SW[9] <= 0;

		repeat (50) begin
			repeat(400) begin
				@(posedge clk);
			end
		end

		$stop; // End the simulation
	end
endmodule
