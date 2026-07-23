`timescale 1ns/1ps
// M05: Hardwired control integration top
// Muxes ctrl_phase01 (phases 0-1) and ctrl_phase234 (phases 2-4).
module hardwired_ctrl_integration (
    input  [6:0] opcode,
    input  [2:0] phase,
    output       pc_write, ir_write, reg_write, mem_write,
    output       alu_src_a, alu_src_b, mem_to_reg, pc_source
);
    wire p01_pcw,  p01_irw,  p01_rgw,  p01_mew;
    wire p01_sa,   p01_sb,   p01_m2r,  p01_pcs;
    wire p234_pcw, p234_irw, p234_rgw, p234_mew;
    wire p234_sa,  p234_sb,  p234_m2r, p234_pcs;

    ctrl_phase01 u_p01 (
        .opcode(opcode), .phase(phase),
        .pc_write(p01_pcw), .ir_write(p01_irw),
        .reg_write(p01_rgw), .mem_write(p01_mew),
        .alu_src_a(p01_sa), .alu_src_b(p01_sb),
        .mem_to_reg(p01_m2r), .pc_source(p01_pcs)
    );

    ctrl_phase234 u_p234 (
        .opcode(opcode), .phase(phase),
        .pc_write(p234_pcw), .ir_write(p234_irw),
        .reg_write(p234_rgw), .mem_write(p234_mew),
        .alu_src_a(p234_sa), .alu_src_b(p234_sb),
        .mem_to_reg(p234_m2r), .pc_source(p234_pcs)
    );

    wire use01 = (phase <= 3'd1);
    assign pc_write  = use01 ? p01_pcw  : p234_pcw;
    assign ir_write  = use01 ? p01_irw  : p234_irw;
    assign reg_write = use01 ? p01_rgw  : p234_rgw;
    assign mem_write = use01 ? p01_mew  : p234_mew;
    assign alu_src_a = use01 ? p01_sa   : p234_sa;
    assign alu_src_b = use01 ? p01_sb   : p234_sb;
    assign mem_to_reg= use01 ? p01_m2r  : p234_m2r;
    assign pc_source = use01 ? p01_pcs  : p234_pcs;
endmodule
