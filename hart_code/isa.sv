`define SIGEXT(VALUE, FROM, TO) { {(TO-FROM){VALUE[FROM-1]}}, VALUE[FROM-1:0] }
`define ZEXT(VALUE, FROM, TO) { {(TO-FROM){1'b0}}, VALUE[FROM-1:0] }

`define OPCODE_LUI     5'b01101

`define OPCODE_JAL     5'b11011
`define OPCODE_JALR    5'b11001
// JALR does use I encoding and thus has a funct3 (0), but shares opcode with no other
// instructions.

`define OPCODE_OP_IMM  5'b00100
`define FUNCT3_ADDI    3'b000
// Omitted: SLTI{U}
`define FUNCT3_XORI    3'b100
`define FUNCT3_ORI     3'b110
`define FUNCT3_ANDI    3'b111

`define OPCODE_OP      5'b01100
`define FUNCT3_ADD_SUB 3'b000
// Omitted: SLL, SLT, SLTU
`define FUNCT3_XOR     3'b100
// Omitted: SRL, SRA
`define FUNCT3_OR      3'b110
`define FUNCT3_AND     3'b111
`define FUNCT7_ADD     7'b0000000
`define FUNCT7_SUB     7'b0100000

`define OPCODE_BRANCH  5'b11000
`define FUNCT3_BEQ     3'b000
`define FUNCT3_BNE     3'b001
// Omitted: BLT, BGE, BLTU, BGEU

`define OPCODE_LOAD    5'b00000
`define FUNCT3_LB      3'b000
`define FUNCT3_LH      3'b001
`define FUNCT3_LW      3'b010
`define FUNCT3_LBU     3'b100
`define FUNCT3_LHU     3'b101

`define OPCODE_STORE   5'b01000
`define FUNCT3_SB      3'b000
`define FUNCT3_SH      3'b001
`define FUNCT3_SW      3'b010
