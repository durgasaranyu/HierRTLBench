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
    // EX stage
    wire [31:0] alu_result_ex;
    wire        branch_ex;
    wire        alu_zero_ex;
    rv_alu_stage alu_stage (
       .rs1_data(rs1_data),
       .rs2_data(rs2_data),
       .imm_ext(imm_ext),
       .pc(pc),
       .fwd_ex_mem(fwd_ex_mem),
       .fwd_mem_wb(fwd_mem_wb),
       .forward_a(forward_a),
       .forward_b(forward_b),
       .alu_src(alu_src),
       .alu_op(alu_op),
       .alu_result(alu_result_ex),
       .branch_ex(branch_ex),
       .alu_zero_ex(alu_zero_ex)
    );
    // EX stage
    wire [31:0] alu_result_ex_mux;
    wire        branch_ex_mux;
    mux2 #(32) alu_result_ex_mux_inst (
       .i0(alu_result_ex),
       .i1(branch_ex),
       .sel(alu_zero_ex),
       .o(alu_result_ex_mux)
    );
    // EX stage
    wire [31:0] branch_target_ex;
    wire        branch_ex_mux;
    mux2 #(32) branch_target_ex_mux_inst (
       .i0(branch_target),
       .i1(branch_ex_mux),
       .sel(alu_zero_ex),
       .o(branch_target_ex_mux)
    );
    // EX stage
    wire [31:0] alu_result_ex_mux_wb;
    wire        branch_ex_mux_wb;
    mux2 #(32) alu_result_ex_mux_wb_inst (
       .i0(alu_result_ex_mux),
       .i1(branch_ex_mux_wb),
       .sel(alu_zero_ex),
       .o(alu_result_ex_mux_wb)
    );
    // EX stage
    wire [31:0] alu_result_ex_wb;
    wire        branch_ex_mux_wb;
    mux2 #(32) alu_result_ex_wb_inst (
       .i0(alu_result_ex_mux_wb),
       .i1(branch_ex_mux_wb),
       .sel(alu_zero_ex),
       .o(alu_result_ex_wb)
    );
    // EX stage
    wire [31:0] alu_result_ex_mux_wb_mux;
    wire        branch_ex_mux_wb_mux;
    mux2 #(32) alu_result_ex_wb_mux_inst (
       .i0(alu_result_ex_wb),
       .i1(branch_ex_mux_wb_mux),
       .sel(alu_zero_ex),
       .o(alu_result_ex_wb_mux)
    );
    // EX stage
    wire [31:0] alu_result_ex_mux_wb_mux_mux;
    wire        branch_ex_mux_wb_mux;
    mux2 #(32) alu_result_ex_mux_wb_mux_mux_inst (
       .i0(alu_result_ex_wb_mux),
       .i1(branch_ex_mux_wb_mux),
       .sel(alu_zero_ex),
       .o(alu_result_ex_mux_wb_mux)
    );
    // EX stage
    wire [31:0] alu_result_ex_mux_wb_mux_mux_mux;
    wire        branch_ex_mux_wb_mux;
    mux2 #(32) alu_result_ex_mux_wb_mux_mux_mux_inst (
       .i0(alu_result_ex_mux_wb_mux),
       .i1(branch_ex_mux_wb_mux),
       .sel(alu_zero_ex),
       .o(alu_result_ex_mux_wb_mux_mux)
    );
    // EX stage
    wire [31:0] alu_result_ex_mux_wb_mux_mux_mux_mux;
    wire        branch_ex_mux_wb_mux;
    mux2 #(32) alu_result_ex_mux_wb_mux_mux_mux_mux_inst (
       .i0(alu_result_ex_mux_wb_mux),
       .i1(branch_ex_mux_wb_mux),
       .sel(alu_zero_ex),
       .o(alu_result_ex_mux_wb_mux_mux)
    );
    // EX stage
    wire [31:0] alu_result_ex_mux_wb_mux_mux_mux_mux_mux;
    wire        branch_ex_mux_wb_mux;
    mux2 #(32) alu_result_ex_mux_wb_mux_mux_mux_mux_mux_inst (
       .i0(alu_result_ex_mux_wb_mux),
       .i1(branch_ex_mux_wb_mux),
       .sel(alu_zero_ex),
       .o(alu_result_ex_mux_wb_mux_mux)
    );
    // EX stage
    wire [31:0] alu_result_ex_mux_wb_mux_mux_mux_mux_mux_mux;
    wire        branch_ex_mux_wb_mux;
    mux2 #(32) alu_result_ex_mux_wb_mux_mux_mux_mux_mux_mux_inst (
       .i0(alu_result_ex_mux_wb_mux),
       .i1(branch_ex_mux_wb_mux),
       .sel(alu_zero_ex),
       .o(alu_result_ex_mux_wb_mux_mux)
    );
    // EX stage
    wire [31:0] alu_result_ex_mux_wb_mux_mux_mux_mux_mux_mux_mux;
    wire        branch_ex_mux_wb_mux;
    mux2 #(32) alu_result_ex_mux_wb_mux_mux_mux_mux_mux_mux_mux_inst (
       .i0(alu_result_ex_mux_wb_mux),
       .i1(branch_ex_mux_wb_mux),
       .sel(alu_zero_ex),
       .o(alu_result_ex_mux_wb_mux_mux)
    );
    // EX stage
    wire [31:0] alu_result_ex_mux_wb_mux_mux_mux_mux_mux_mux_
endmodule
