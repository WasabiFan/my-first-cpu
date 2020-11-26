module seg7_hex (bcd, leds);
   input  logic [3:0] bcd;
   output logic [6:0] leds;

   logic [6:0] leds_inv;
   assign leds = ~leds_inv;

   always_comb
      case (bcd)
         //          Light: 6543210
         4'b0000: leds_inv = 7'b0111111; // 0
         4'b0001: leds_inv = 7'b0000110; // 1
         4'b0010: leds_inv = 7'b1011011; // 2
         4'b0011: leds_inv = 7'b1001111; // 3
         4'b0100: leds_inv = 7'b1100110; // 4
         4'b0101: leds_inv = 7'b1101101; // 5
         4'b0110: leds_inv = 7'b1111101; // 6
         4'b0111: leds_inv = 7'b0000111; // 7
         4'b1000: leds_inv = 7'b1111111; // 8
         4'b1001: leds_inv = 7'b1101111; // 9
         4'b1010: leds_inv = 7'b1110111; // A
         4'b1011: leds_inv = 7'b1111100; // b
         4'b1100: leds_inv = 7'b0111001; // C
         4'b1101: leds_inv = 7'b1011110; // D
         4'b1110: leds_inv = 7'b1111001; // E
         4'b1111: leds_inv = 7'b1110001; // F
         default: leds_inv = 7'bX;
      endcase
endmodule
