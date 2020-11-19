module hart_demo (CLOCK_50, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, LEDR, SW);
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

   hart cpu(CLOCK_50, KEY[0]);
endmodule

// module hart_demo_testbench();
// 	logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
// 	logic [9:0] LEDR;
// 	logic [3:0] KEY;
// 	logic [9:0] SW;

// 	// instantiate device under test
// 	lab2 dut (.HEX0, .HEX1, .HEX2, .HEX3, .HEX4, .HEX5, .KEY, .LEDR, .SW);

// 	// test input sequence - try all combinations of inputs
// 	integer i;
// 	initial begin
// 		SW[9] = 1'b0;
// 		SW[8] = 1'b0;
// 		for(i = 0; i <256; i++) begin
// 			SW[7:0] = i; #10;
// 		end
// 	end
// endmodule  // lab2_testbench
