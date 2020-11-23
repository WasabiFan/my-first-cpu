// `include "common.sv"
`include "isa.sv"

import isa_types::*;

module memory #( parameter LOG_MEM_SIZE_WORDS = 14 ) (clock, waddr, raddr, wwidth, wenable, wdata, rdata);
   input logic clock, wenable;
   input logic [XLEN-1:0] waddr, raddr;
   input write_width_t wwidth;
   input logic [XLEN-1:0] wdata;
   output logic [XLEN-1:0] rdata;

   logic [3:0] be;

   always_comb begin
      case (wwidth)
         write_byte:     be = 4'b0001;
         write_halfword: be = 4'b0011;
         write_word:     be = 4'b1111;
      endcase
   end

   byte_enabled_simple_dual_port_ram #(.ADDR_WIDTH(LOG_MEM_SIZE_WORDS)) ram (
      waddr[LOG_MEM_SIZE_WORDS-1:0],
      raddr[LOG_MEM_SIZE_WORDS-1:0],
      be,
      wdata,
      wenable, clock,
      rdata
   );
endmodule