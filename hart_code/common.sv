package isa_types;
    parameter XLEN = 32;
    parameter ILEN = 32;

    // one register is x0
    parameter num_regs = 32;

    typedef logic [4:0] rv_reg_t;

    typedef enum { OP_UNKNOWN, OP_IMM, OP_LOAD, OP_STORE } opcode_t;

    typedef struct {
        logic [XLEN-1:0] pc;
        logic [XLEN-1:0] xregs [num_regs-1:0];
    } state_t;

    typedef enum {
        write_byte,
        write_halfword,
        write_word
    } write_width_t;
endpackage;
