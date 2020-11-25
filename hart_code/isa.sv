`define SIGEXT(VALUE, FROM, TO) { {(TO-FROM){VALUE[FROM-1]}}, VALUE[FROM-1:0] }
`define ZEXT(VALUE, FROM, TO) { (TO-FROM)'b0, VALUE }

`define OPCODE_LUI     5'b01101

`define OPCODE_JAL     5'b11011
`define OPCODE_JALR    5'b11001
// JALR does use I encoding and thus has a funct3 (0), but shares opcode with no other
// instructions.

`define OPCODE_OP_IMM  5'b00100
`define FUNCT3_ADDI    3'b000

`define OPCODE_OP      5'b01100
`define FUNCT3_ADD_SUB 3'b000
`define FUNCT7_ADD     7'b0000000
`define FUNCT7_SUB     7'b0100000

`define OPCODE_LOAD    5'b00000
`define FUNCT3_LB      3'b000
`define FUNCT3_LH      3'b001
`define FUNCT3_LW      3'b010
// Omitted: LBU, LHU

`define OPCODE_STORE   5'b01000
`define FUNCT3_SB      3'b000
`define FUNCT3_SH      3'b001
`define FUNCT3_SW      3'b010