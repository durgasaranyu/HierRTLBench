`timescale 1ns/1ps
// M04: Multi-cycle Harvard RISC CPU integration top
// Wires cpu_control <-> cpu_datapath.
// Control signals flow control→datapath; status signals flow datapath→control.
module multicycle_cpu_integration (
    input clk, rst
);
    // control → datapath
    wire        pc_write, ir_write, reg_write, mem_write;
    wire        alu_src_a, alu_src_b, mem_to_reg, pc_source;
    wire [1:0]  alu_op;
    // datapath → control
    wire [6:0]  opcode;
    wire [2:0]  funct3;
    wire        zero;

    cpu_control u_ctrl (
        .clk(clk), .rst(rst),
        .opcode(opcode), .funct3(funct3), .zero(zero),
        .pc_write(pc_write), .ir_write(ir_write),
        .reg_write(reg_write), .mem_write(mem_write),
        .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
        .mem_to_reg(mem_to_reg), .pc_source(pc_source),
        .alu_op(alu_op)
    );

    cpu_datapath u_dp (
        .clk(clk), .rst(rst),
        .pc_write(pc_write), .ir_write(ir_write),
        .reg_write(reg_write), .mem_write(mem_write),
        .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
        .mem_to_reg(mem_to_reg), .pc_source(pc_source),
        .alu_op(alu_op),
        .opcode(opcode), .funct3(funct3), .zero(zero)
    );
endmodule
