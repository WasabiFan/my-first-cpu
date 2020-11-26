`include "isa.sv"

package isa_types;
    parameter XLEN = 32;
    parameter ILEN = 32;

    // one register is x0
    parameter num_regs = 32;

    typedef logic [4:0] rv_reg_t;

    typedef enum {
        OPCODE_UNKNOWN,
        OPCODE_LUI,
        OPCODE_JAL,
        OPCODE_JALR,
        OPCODE_OP_IMM,
        OPCODE_OP,
        OPCODE_BRANCH,
        OPCODE_LOAD,
        OPCODE_STORE
    } opcode_t;

    typedef struct {
        logic [XLEN-1:0] pc;
        logic [XLEN-1:0] xregs [num_regs-1:0];
    } reg_state_t;

    typedef enum {
        write_byte,
        write_halfword,
        write_word
    } write_width_t;

    function opcode_t extract_opcode;
        input logic [XLEN-1:0] instr_bits;
        opcode_t opcode;

        // field_opcode[1:0] are always 11
        case (instr_bits[6:2])
            `OPCODE_LUI:    opcode = OPCODE_LUI;
            `OPCODE_JAL:    opcode = OPCODE_JAL;
            `OPCODE_JALR:   opcode = OPCODE_JALR;
            `OPCODE_OP_IMM: opcode = OPCODE_OP_IMM;
            `OPCODE_OP:     opcode = OPCODE_OP;
            `OPCODE_BRANCH: opcode = OPCODE_BRANCH;
            `OPCODE_LOAD:   opcode = OPCODE_LOAD;
            `OPCODE_STORE:  opcode = OPCODE_STORE;
            default:        opcode = OPCODE_UNKNOWN;
        endcase

        return opcode;
    endfunction
endpackage
