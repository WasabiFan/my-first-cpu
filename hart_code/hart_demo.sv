module hart_demo (CLOCK_50, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, LEDR, SW);
	output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output logic [9:0] LEDR;
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
   logic [7:0] output_peripherals_mem ['h20-1:0];

   reg_state_t reg_state;
   hart cpu (CLOCK_50, ~KEY[0], reg_state, input_peripherals_mem, output_peripherals_mem);

	seg7_hex pc0 (reg_state.pc[3:0], HEX0);
	seg7_hex pc1 (reg_state.pc[7:4], HEX1);
	seg7_hex pc2 (reg_state.pc[11:8], HEX2);

	genvar i;
	generate
		// Map switches to input addresses starting at 0x1000
		// Map LEDs to output addresses starting at 0x1800
		for (i = 0; i < 10; i++) begin : io_assign
			assign input_peripherals_mem[i] = SW[i];
			assign LEDR[i] = output_peripherals_mem[i] != 0;
		end
	endgenerate
endmodule
