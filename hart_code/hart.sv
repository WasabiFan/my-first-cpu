`include "common.sv"

typedef enum { UNKNOWN, OP_IMM } opcode_t;

typedef logic [4:0] rv_reg_t;

`define FUNCT3_ADDI 3'b000


module hart(clock, reset);
    input logic clock, reset;
    state_t current_state;

    logic [ILEN-1:0] instr_bits;
    assign instr_bits = {
        current_state.ram[current_state.pc+3],
        current_state.ram[current_state.pc+2],
        current_state.ram[current_state.pc+1],
        current_state.ram[current_state.pc]
    };

    logic [6:0] field_opcode;
    assign field_opcode = instr_bits[6:0];

    opcode_t opcode;

    rv_reg_t rs1, rs2, rd;
    assign rd = instr_bits[11:7];
    assign rs1 = instr_bits[19:15];
    assign rs2 = instr_bits[20:14];

    logic [2:0] funct3;
    logic [6:0] funct7;
    assign funct3 = instr_bits[14:12];
    assign funct7 = instr_bits[31:25];

    logic [XLEN-1:0] i_imm_input;
    logic [XLEN-1:0] rd_out_val;

    always_comb begin
        // field_opcode[1:0] are always 11
        case (field_opcode[6:2])
            5'b00100: opcode = OP_IMM;
            default: opcode = UNKNOWN;
        endcase

        case (opcode)
            OP_IMM: begin
                i_imm_input = { {(XLEN-12){instr_bits[31]}}, instr_bits[31:20] };
                case (funct3)
                    `FUNCT3_ADDI: rd_out_val = i_imm_input + current_state.xregs[rs1];
                    default: rd_out_val = 'x;
                endcase
            end
        endcase
    end

    always_ff @(posedge clock) begin
        if (reset) begin
            // TODO: having stuff start at address 0 is definitely bad
            current_state.ram[3:0] = {
                8'h00, 8'h50, 8'h07, 8'h93 // li a5,5
            };
            current_state.ram[7:4] = {
                8'h00, 8'h17, 8'h87, 8'h93 // addi a5,a5,1
            };
            current_state.pc = 0;
            current_state.xregs[0] = 0;
        end else begin
            case (opcode)
                OP_IMM: begin
                    if (rd)
                        current_state.xregs[rd] = rd_out_val;
                end
            endcase
            current_state.pc += 4;
        end
    end
endmodule



module hart_testbench();
	logic clk, reset;

	hart dut (clk, reset);
    
	// Set up the clock
	parameter CLOCK_PERIOD=100;
	initial begin
    	clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk;
	end

	// Set up the inputs to the design. Each line is a clock cycle.
	initial begin
		@(posedge clk); reset <= 1;
		@(posedge clk); reset <= 0;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		$stop; // End the simulation
	end
endmodule
