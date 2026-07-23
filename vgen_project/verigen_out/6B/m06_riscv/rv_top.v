// 5-stage pipelined RISC-V CPU top. Hazard detection, forwarding unit.
// Supports: ADD/SUB/AND/OR/ADDI/LW/SW/BEQ.
module riscv_pipeline (
    input clk, rst
);
    // Instruction memory for the processor
    reg [31:0] inst_mem [0:127];
    // Instruction memory for the instruction register
    reg [31:0] inst_reg [0:31];
    // Instruction register
    reg [31:0] inst_reg_nxt [0:31];
    // Control signals
    reg [5:0] inst_reg_nxt_2 [0:31];
    reg [3:0] inst_reg_nxt_3 [0:31];
    reg [1:0] inst_reg_nxt_4 [0:31];
    reg [4:0] inst_reg_nxt_5 [0:31];
    reg [4:0] inst_reg_nxt_6 [0:31];
    reg [4:0] inst_reg_nxt_7 [0:31];
    reg [4:0] inst_reg_nxt_8 [0:31];
    reg [4:0] inst_reg_nxt_9 [0:31];
    reg [4:0] inst_reg_nxt_10 [0:31];
    reg [4:0] inst_reg_nxt_11 [0:31];
    reg [4:0] inst_reg_nxt_12 [0:31];
    reg [4:0] inst_reg_nxt_13 [0:31];
    reg [4:0] inst_reg_nxt_14 [0:31];
    reg [4:0] inst_reg_nxt_15 [0:31];
    reg [4:0] inst_reg_nxt_16 [0:31];
    reg [4:0] inst_reg_nxt_17 [0:31];
    reg [4:0] inst_reg_nxt_18 [0:31];
    reg [4:0] inst_reg_nxt_19 [0:31];
    reg [4:0] inst_reg_nxt_20 [0:31];
    reg [4:0] inst_reg_nxt_21 [0:31];
    reg [4:0] inst_reg_nxt_22 [0:31];
    reg [4:0] inst_reg_nxt_23 [0:31];
    reg [4:0] inst_reg_nxt_24 [0:31];
    reg [4:0] inst_reg_nxt_25 [0:31];
    reg [4:0] inst_reg_nxt_26 [0:31];
    reg [4:0] inst_reg_nxt_27 [0:31];
    reg [4:0] inst_reg_nxt_28 [0:31];
    reg [4:0] inst_reg_nxt_29 [0:31];
    reg [4:0] inst_reg_nxt_30 [0:31];
    reg [4:0] inst_reg_nxt_31 [0:31];
    // Pipeline registers
    reg [31:0] inst_reg [0:31];
    reg [31:0] inst_reg_nxt [0:31];
    reg [5:0] inst_reg_nxt_2 [0:31];
    reg [3:0] inst_reg_nxt_3 [0:31];
    reg [1:0] inst_reg_nxt_4 [0:31];
    reg [4:0] inst_reg_nxt_5 [0:31];
    reg [4:0] inst_reg_nxt_6 [0:31];
    reg [4:0] inst_reg_nxt_7 [0:31];
    reg [4:0] inst_reg_nxt_8 [0:31];
    reg [4:0] inst_reg_nxt_9 [0:31];
    reg [4:0] inst_reg_nxt_10 [0:31];
    reg [4:0] inst_reg_nxt_11 [0:31];
    reg [4:0] inst_reg_nxt_12 [0:31];
    reg [4:0] inst_reg_nxt_13 [0:31];
    reg [4:0] inst_reg_nxt_14 [0:31];
    reg [4:0] inst_reg_nxt_15 [0:31];
    reg [4:0] inst_reg_nxt_16 [0:31];
    reg [4:0] inst_reg_nxt_17 [0:31];
    reg [4:0] inst_reg_nxt_18 [0:31];
    reg [4:0] inst_reg_nxt_19 [0:31];
    reg [4:0] inst_reg_nxt_20 [0:31];
    reg [4:0] inst_reg_nxt_21 [0:31];
    reg [4:0] inst_reg_nxt_22 [0:31];
    reg [4:0] inst_reg_nxt_23 [0:31];
    reg [4:0] inst_reg_nxt_24 [0:31];
    reg [4:0] inst_reg_nxt_25 [0:31];
    reg [4:0] inst_reg_nxt_26 [0:31];
    reg [4:0] inst_reg_nxt_27 [0:31];
    reg [4:0] inst_reg_nxt_28 [0:31];
    reg [4:0] inst_reg_nxt_29 [0:31];
    reg [4:0] inst_reg_nxt_30 [0:31];
    reg [4:0] inst_reg_nxt_31 [0:31];
    // Pipeline registers
    reg [31:0] inst_reg [0:31];
    reg [5:0] inst_reg_2 [0:31];
    reg [3:0] inst_reg_3 [0:31];
    reg [1:0] inst_reg_4 [0:31];
    reg [4:0] inst_reg_5 [0:31];
    reg [4:0] inst_reg_6 [0:31];
    reg [4:0] inst_reg_7 [0:31];
    reg [4:0] inst_reg_8 [0:31];
    reg [4:0] inst_reg_9 [0:31];
    reg [4:0] inst_reg_10 [0:31];
    reg [4:0] inst_reg_11 [0:31];
    reg [4:0] inst_reg_12 [0:31];
    reg [4:0] inst_reg_13 [0:31];
    reg [4:0] inst_reg_14 [0:31];
    reg [4:0] inst_reg_15 [0:31];
    reg [4:0] inst_reg_16 [0:31];
    reg [4:0] inst_reg_17 [0:31];
    reg [4:0] inst_reg_18 [0:31];
    reg [4:0] inst_reg_19 [0:31];
    reg [4:0] inst_reg_20 [0:31];
    reg [4:0] inst_reg_21 [0:31];
    reg [4:0] inst_reg_22 [0:31];
    reg [4:0] inst_reg_23 [0:31];
    reg [4:0] inst_reg_24 [0:31];
    reg [4:0] inst_reg_25 [0:31];
    reg [4:0] inst_reg_26 [0:31];
    reg [4:0] inst_reg_27 [0:31];
    reg [4:0] inst_reg_28 [0:31];
    reg [4:0] inst_reg_29 [0:31];
    reg [4:0] inst_reg_30 [0:31];
    reg [4:0] inst_reg_31 [0:31];
    // Pipeline registers
    reg [31:0] inst_reg [0:31];
    reg [5:0] inst_reg_2 [0:31];
    reg [3:
endmodule
