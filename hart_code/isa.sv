`define SIGEXT(VALUE, FROM, TO) { {(TO-FROM){VALUE[FROM-1]}}, VALUE[FROM-1:0] }
`define ZEXT(VALUE, FROM, TO) { {(TO-FROM){1'b0}}, VALUE[FROM-1:0] }

`define OPCODE_LUI     7'b0110111

`define OPCODE_JAL     7'b1101111
`define OPCODE_JALR    7'b1100111
// JALR does use "I" encoding and thus has a funct3 (0), but shares opcode with no other
// instructions.

`define OPCODE_OP_IMM  7'b0010011
`define FUNCT3_ADDI    3'b000
`define FUNCT3_SLTI    3'b010
`define FUNCT3_SLTIU   3'b011
`define FUNCT3_XORI    3'b100
`define FUNCT3_ORI     3'b110
`define FUNCT3_ANDI    3'b111
`define FUNCT3_SLLI    3'b001
`define FUNCT3_SRLI_SRAI 3'b101

`define OPCODE_OP      7'b0110011
`define FUNCT3_ADD_SUB 3'b000
`define FUNCT3_SLL     3'b001
`define FUNCT3_SLT     3'b010
`define FUNCT3_SLTU    3'b011
`define FUNCT3_XOR     3'b100
// Omitted: SRL, SRA
`define FUNCT3_OR      3'b110
`define FUNCT3_AND     3'b111
`define FUNCT7_ADD     7'b0000000
`define FUNCT7_SUB     7'b0100000

`define OPCODE_BRANCH  7'b1100011
`define FUNCT3_BEQ     3'b000
`define FUNCT3_BNE     3'b001
// Omitted: BLT, BGE, BLTU, BGEU

`define OPCODE_LOAD    7'b0000011
`define FUNCT3_LB      3'b000
`define FUNCT3_LH      3'b001
`define FUNCT3_LW      3'b010
`define FUNCT3_LBU     3'b100
`define FUNCT3_LHU     3'b101

`define OPCODE_STORE   7'b0100011
`define FUNCT3_SB      3'b000
`define FUNCT3_SH      3'b001
`define FUNCT3_SW      3'b010
