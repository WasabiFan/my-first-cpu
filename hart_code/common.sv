
parameter XLEN = 32;
parameter ILEN = 32;
parameter total_memory = 1024 * 1024;
// one register is x0
parameter num_regs = 32;


typedef struct {
    logic [XLEN-1:0] pc;
    logic [XLEN-1:0] xregs [num_regs-1:0];
    logic [7:0] ram [total_memory-1:0];
} state_t;
