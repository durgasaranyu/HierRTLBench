// RISC-V EX stage. ALU with forwarding muxes. Computes branch target = pc + imm.
// alu_op: 00=ADD, 01=SUB, 10=AND, 11=OR.
module rv_ex_stage (
    input [31:0] rs1_data, rs2_data, imm_ext, pc,
    input [31:0] fwd_ex_mem, fwd_mem_wb,
    input [1:0]  forward_a, forward_b,
    input        alu_src,
    input [1:0]  alu_op,
    output [31:0] alu_result, branch_target,
    output        zero
);
    reg [31:0] reg1, reg2, reg3, reg4;
    wire [31:0] alu_result_d, branch_target_d, reg3_d, reg4_d;
    wire [31:0] reg1_d, reg2_d, reg4_d_shifted, pc_d,
                  branch_target_d_shifted, branch_target_d_extended;
    wire [31:0] reg1_data_d, reg2_data_d, reg3_data_d, reg4_data_d;
    wire [31:0] imm_d, pc_d_extended;
    wire [31:0] alu_result_d_shifted, alu_result_d_extended;
    wire        zero_d;
    assign branch_target_d = {26'b0, branch_target[31:2]};
    assign branch_target_d_shifted = {26'b0, branch_target_d[31:2]};
    assign branch_target_d_extended = {26'b0, branch_target_d[31:2]};
    assign reg1_d = reg1;
    assign reg2_d = reg2;
    assign reg3_d = reg3;
    assign reg4_d = reg4;
    assign reg1_data_d = reg1_data;
    assign reg2_data_d = reg2_data;
    assign reg3_data_d = reg3_data;
    assign reg4_data_d = reg4_data;
    assign imm_d = imm;
    assign pc_d = pc;
    assign pc_d_extended = pc_d + imm_d;
    assign reg1_d_shifted = reg1_d << 2;
    assign reg2_d_shifted = reg2_d << 2;
    assign reg3_d_shifted = reg3_d << 2;
    assign reg4_d_shifted = reg4_d << 2;
    assign reg1_data_d_shifted = reg1_data_d << 2;
    assign reg2_data_d_shifted = reg2_data_d << 2;
    assign reg3_data_d_shifted = reg3_data_d << 2;
    assign reg4_data_d_shifted = reg4_data_d << 2;
    assign alu_result_d_shifted = alu_result_d << 2;
    assign alu_result_d_extended = {alu_result_d[31:2], 2'b0};
    assign alu_result_d_shifted_plus_imm_d = alu_result_d_shifted + imm_d;
    assign alu_result_d_extended_plus_imm_d = {alu_result_d_extended[31:2], 2'b0} + imm_d;
    assign zero_d = !(|alu_result_d_shifted_plus_imm_d);
    assign reg1_d_shifted_plus_imm_d = reg1_d_shifted + imm_d;
    assign reg2_d_shifted_plus_imm_d = reg2_d_shifted + imm_d;
    assign reg3_d_shifted_plus_imm_d = reg3_d_shifted + imm_d;
    assign reg4_d_shifted_plus_imm_d = reg4_d_shifted + imm_d;
    assign reg1_data_d_shifted_plus_imm_d = reg1_data_d_shifted + imm_d;
    assign reg2_data_d_shifted_plus_imm_d = reg2_data_d_shifted + imm_d;
    assign reg3_data_d_shifted_plus_imm_d = reg3_data_d_shifted + imm_d;
    assign reg4_data_d_shifted_plus_imm_d = reg4_data_d_shifted + imm_d;
    assign branch_target_d_shifted_plus_imm_d = branch_target_d_shifted + imm_d;
    assign branch_target_d_extended_plus_imm_d = {branch_target_d_extended[31:2], 2'b0} + imm_d;
    assign reg1_d_shifted_plus_imm_d = reg1_d_shifted + imm_d;
    assign reg2_d_shifted_plus_imm_d = reg2_d_shifted + imm_d;
    assign reg3_d_shifted_plus_imm_d = reg3_d_shifted + imm_d;
    assign reg4_d_shifted_plus_imm_d = reg4_d_shifted + imm_d;
    assign reg1_data_d_shifted_plus_imm_d = reg1_data_d_shifted + imm_d;
    assign reg2_data_d_shifted_plus_imm_d = reg2_data_d_shifted + imm_d;
    assign reg3_data_d_shifted_plus_imm_d = reg3_data_d_shifted + imm_d;
    assign reg4_data_d_shifted_plus_imm_d = reg4_data_d_shifted + imm_d;
    assign reg1_d_shifted_plus_imm_d = reg1_d_shifted + imm_d;
    assign reg2_d_shifted_plus_imm_d = reg2_d_shifted + imm_d;
    assign reg3_d_shifted_plus_imm_d = reg3_d_shifted + imm_d;
    assign reg4_d_shifted_plus_imm_d = reg4_d_shifted + imm_d;
    assign reg1_data_d_shifted_plus_imm_d = reg1_data_d_shifted + imm_d;
    assign reg2_data_d_shifted_plus_imm_d = reg2_data_d_shifted + imm_d;
    assign reg3_data_d_shifted_plus_imm_d = reg3_data_d_shifted + imm_d;
    assign reg4_data_d_shifted_plus_imm_d = reg4_data_d_shifted + imm_d;
    assign reg1_d_shifted_plus_imm_d = reg1_d_shifted + imm_d;
    assign reg2_d_shifted_plus_imm_d = reg2_d_shifted + imm_d;
    assign reg3_d_shifted_plus_imm_d = reg3_d_shifted + imm_d;
    assign reg4_d_shifted_plus_imm_d = reg4_d_shifted + imm_d;
    assign reg1_data_d_shifted_plus_imm_d = reg1_data_d_shifted + imm_d;
    assign reg2_data_d_shifted_plus_imm_d = reg2_data_d_shifted + imm_d;
    assign reg3_data_d_shifted_plus_imm_d = reg3_data_d_shifted + imm_d;
    assign reg4_data_d_shifted_plus_imm_d = reg4_data_d_shifted + imm_d;
    assign reg1_d_shifted_plus_imm_d = reg1_d_
endmodule
