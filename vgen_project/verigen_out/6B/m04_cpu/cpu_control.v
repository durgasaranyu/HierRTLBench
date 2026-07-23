// Multi-cycle RISC control FSM. States IF=0,ID=1,EX=2,MEM=3,WB=4.
// Opcodes: ADD/SUB=7'h33, ADDI=7'h13, LW=7'h03, SW=7'h23, BEQ=7'h63.
module cpu_control (
    input       clk, rst,
    input [6:0] opcode,
    input [2:0] funct3,
    input       zero,
    output reg  pc_write, ir_write, reg_write, mem_write,
    output reg  alu_src_a, alu_src_b, mem_to_reg, pc_source,
    output reg [1:0] alu_op
);
    reg [2:0] state;
    reg [2:0] next_state;
    // State machine
    always @(*)
        case (state)
            3'b000: begin
                next_state = 3'b001;
                pc_write = 1'b0;
                ir_write = 1'b0;
                reg_write = 1'b0;
                mem_write = 1'b0;
                alu_src_a = 1'b0;
                alu_src_b = 2'b00;
                mem_to_reg = 1'b0;
                alu_op = 2'b10;
            end
            3'b001: begin
                next_state = 3'b010;
                pc_write = 1'b1;
                ir_write = 1'b0;
                reg_write = 1'b0;
                mem_write = 1'b0;
                alu_src_a = 1'b0;
                alu_src_b = 2'b00;
                mem_to_reg = 1'b0;
                alu_op = 2'b10;
            end
            3'b010: begin
                next_state = 3'b011;
                pc_write = 1'b0;
                ir_write = 1'b0;
                reg_write = 1'b1;
                mem_write = 1'b0;
                alu_src_a = 1'b0;
                alu_src_b = 2'b00;
                mem_to_reg = 1'b0;
                alu_op = 2'b10;
            end
            3'b011: begin
                next_state = 3'b100;
                pc_write = 1'b0;
                ir_write = 1'b0;
                reg_write = 1'b1;
                mem_write = 1'b0;
                alu_src_a = 1'b0;
                alu_src_b = 2'b00;
                mem_to_reg = 1'b0;
                alu_op = 2'b10;
            end
            3'b100: begin
                next_state = 3'b000;
                pc_write = 1'b0;
                ir_write = 1'b0;
                reg_write = 1'b0;
                mem_write = 1'b1;
                alu_src_a = 1'b0;
                alu_src_b = 2'b00;
                mem_to_reg = 1'b0;
                alu_op = 2'b10;
            end
            3'b101: begin
                next_state = 3'b000;
                pc_write = 1'b0;
                ir_write = 1'b0;
                reg_write = 1'b0;
                mem_write = 1'b1;
                alu_src_a = 1'b0;
                alu_src_b = 2'b00;
                mem_to_reg = 1'b0;
                alu_op = 2'b10;
            end
            3'b110: begin
                next_state = 3'b000;
                pc_write = 1'b0;
                ir_write = 1'b0;
                reg_write = 1'b0;
                mem_write = 1'b1;
                alu_src_a = 1'b0;
                alu_src_b = 2'b00;
                mem_to_reg = 1'b0;
                alu_op = 2'b10;
            end
            3'b111: begin
                next_state = 3'b000;
                pc_write = 1'b0;
                ir_write = 1'b0;
                reg_write = 1'b0;
                mem_write = 1'b1;
                alu_src_a = 1'b0;
                alu_src_b = 2'b00;
                mem_to_reg = 1'b0;
                alu_op = 2'b10;
            end
            default: next_state = 3'b000;
        endcase
    
    always @(posedge clk)
        if(rst)
            state = 3'b000;
    	else
            state = next_state;
endmodule
`timescale 1ns / 1ps

module tb_cpu_control;

    reg clk;
    reg rst;
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg zero;
    wire pc_write, ir_write, reg_write, mem_write;
    wire [1:0] alu_src_a, alu_src_b;
    wire [2:0] alu_op;

    cpu_control uut (
        .clk(clk),
        .rst(rst),
        .opcode(opcode),
        .funct3(funct3),
        .zero(zero),
        .pc_write(pc_write),
        .ir_write(ir_write),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .alu_op(alu_op)
    );

    initial
    begin
        $dumpfile("tb_cpu_control.vcd");
        $dumpvars(0, tb_cpu_control);
        $monitor("opcode: %b, funct3: %b, zero: %b, pc_write: %b, ir_write: %b, reg_write: %b, mem_write: %b, alu_src_a: %b, alu_src_b: %b, alu_op: %b", opcode, funct3, zero, pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, alu_op);
        clk = 0;
        forever
            #
endmodule
