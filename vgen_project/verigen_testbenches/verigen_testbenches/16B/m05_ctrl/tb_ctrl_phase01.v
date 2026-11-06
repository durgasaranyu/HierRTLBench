`timescale 1ns/1ps
module tb_ctrl_phase01;

    // DUT connections
    reg  [6:0] opcode;
    reg  [2:0] phase;
    wire       pc_write, ir_write, reg_write, mem_write;
    wire       alu_src_a, alu_src_b, mem_to_reg, pc_source;

    // Clock and reset (not used by combinational DUT but required by testbench spec)
    reg clk, rst;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset for 5 rising edges
    integer i;
    initial begin
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
    end

    // Instantiate DUT
    ctrl_phase01 uut (
        .opcode    (opcode),
        .phase     (phase),
        .pc_write  (pc_write),
        .ir_write  (ir_write),
        .reg_write (reg_write),
        .mem_write (mem_write),
        .alu_src_a (alu_src_a),
        .alu_src_b (alu_src_b),
        .mem_to_reg(mem_to_reg),
        .pc_source (pc_source)
    );

    // Task to check outputs
    task check;
        input [6:0] op;
        input [2:0] ph;
        input exp_pc_write, exp_ir_write, exp_reg_write, exp_mem_write;
        input exp_alu_src_a, exp_alu_src_b, exp_mem_to_reg, exp_pc_source;
        input [127:0] desc; // use integer index instead
        input [31:0]  desc_idx;
        begin
            opcode = op;
            phase  = ph;
            #2; // let combinational settle
            if (pc_write    == exp_pc_write    &&
                ir_write    == exp_ir_write    &&
                reg_write   == exp_reg_write   &&
                mem_write   == exp_mem_write   &&
                alu_src_a   == exp_alu_src_a   &&
                alu_src_b   == exp_alu_src_b   &&
                mem_to_reg  == exp_mem_to_reg  &&
                pc_source   == exp_pc_source)
                $display("PASS: Test %0d opcode=%07b phase=%0d", desc_idx, op, ph);
            else begin
                $display("FAIL: Test %0d opcode=%07b phase=%0d | got pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b | exp pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                    desc_idx, op, ph,
                    pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source,
                    exp_pc_write, exp_ir_write, exp_reg_write, exp_mem_write, exp_alu_src_a, exp_alu_src_b, exp_mem_to_reg, exp_pc_source);
            end
        end
    endtask

    // The DUT always sets pc_write=1 for any phase value (all 8 are handled and all set pc_write=1).
    // For phase=0: opcode 7'b0000000 sets pc_source=1 (special case)
    // For phase=1..7: opcode 7'b0100001 sets pc_source=1 (special case)
    // Opcodes from the module-specific requirements: 7'h33=7'b0110011, 7'h13=7'b0010011, 7'h03=7'b0000011, 7'h23=7'b0100011, 7'h63=7'b1100011

    integer test_idx;

    initial begin
        opcode = 7'b0;
        phase  = 3'b0;
        // Wait for reset deassertion
        @(negedge rst);
        @(posedge clk); #1;

        // Test 1: opcode=7'h33 (0110011), phase=0 => pc_write=1, alu_src_b=1, others=0
        check(7'b0110011, 3'b000, 1,0,0,0, 0,1,0,0, 128'd0, 1);

        // Test 2: opcode=7'h33 (0110011), phase=1 => pc_write=1, alu_src_b=1
        check(7'b0110011, 3'b001, 1,0,0,0, 0,1,0,0, 128'd0, 2);

        // Test 3: opcode=7'h13 (0010011), phase=0 => pc_write=1, no special => pc_write=1, all others=0
        // 7'h13 = 7'b0010011, not matching any special case => only pc_write=1
        check(7'b0010011, 3'b000, 1,0,0,0, 0,0,0,0, 128'd0, 3);

        // Test 4: opcode=7'h03 (0000011), phase=2 => pc_write=1, mem_write=1
        check(7'b0000011, 3'b010, 1,0,0,1, 0,0,0,0, 128'd0, 4);

        // Test 5: opcode=7'h23 (0100011), phase=3 => pc_write=1, alu_src_a=1
        check(7'b0100011, 3'b011, 1,0,0,0, 1,0,0,0, 128'd0, 5);

        // Test 6: opcode=7'h63 (1100011), phase=4 => pc_write=1, ir_write=1
        check(7'b1100011, 3'b100, 1,1,0,0, 0,0,0,0, 128'd0, 6);

        // Test 7: all-zero opcode (7'b0000000), phase=0 => pc_write=1, pc_source=1
        check(7'b0000000, 3'b000, 1,0,0,0, 0,0,0,1, 128'd0, 7);

        // Test 8: all-zero opcode (7'b0000000), phase=1 => 7'b0000000 not matching 7'b0100001 => pc_write=1 only
        check(7'b0000000, 3'b001, 1,0,0,0, 0,0,0,0, 128'd0, 8);

        // Test 9: all-ones opcode (7'b1111111), phase=0 => no special match => pc_write=1, others=0
        check(7'b1111111, 3'b000, 1,0,0,0, 0,0,0,0, 128'd0, 9);

        // Test 10: all-ones opcode, phase=7 => pc_write=1, others=0
        check(7'b1111111, 3'b111, 1,0,0,0, 0,0,0,0, 128'd0, 10);

        // Test 11: opcode=7'b1101111 (JAL), phase=0 => pc_write=1, reg_write=1
        check(7'b1101111, 3'b000, 1,0,1,0, 0,0,0,0, 128'd0, 11);

        // Test 12: opcode=7'b1100010, phase=2 => pc_write=1, mem_to_reg=1
        check(7'b1100010, 3'b010, 1,0,0,0, 0,0,1,0, 128'd0, 12);

        // Test 13: opcode=7'b0100001, phase=1 => pc_write=1, pc_source=1
        check(7'b0100001, 3'b001, 1,0,0,0, 0,0,0,1, 128'd0, 13);

        // Test 14: opcode=7'b0100001, phase=0 => no match (phase 0 uses 7'b0000000 for pc_source) => pc_write=1 only
        check(7'b0100001, 3'b000, 1,0,0,0, 0,0,0,0, 128'd0, 14);

        // Test 15: opcode=7'h63 (1100011), phase=0 => pc_write=1, ir_write=1
        check(7'b1100011, 3'b000, 1,1,0,0, 0,0,0,0, 128'd0, 15);

        // Test 16: opcode=7'h03, phase=0 => pc_write=1, mem_write=1
        check(7'b0000011, 3'b000, 1,0,0,1, 0,0,0,0, 128'd0, 16);

        // Test 17: opcode=7'h23, phase=0 => pc_write=1, alu_src_a=1
        check(7'b0100011, 3'b000, 1,0,0,0, 1,0,0,0, 128'd0, 17);

        // Test 18: opcode=7'h13 (0010011), phase=4 => pc_write=1, others=0
        check(7'b0010011, 3'b100, 1,0,0,0, 0,0,0,0, 128'd0, 18);

        // Test 19: undefined opcode 7'b1010101, phase=0 => pc_write=1, all others=0
        check(7'b1010101, 3'b000, 1,0,0,0, 0,0,0,0, 128'd0, 19);

        // Test 20: opcode=7'b0110011, phase=4 => pc_write=1, alu_src_b=1
        check(7'b0110011, 3'b100, 1,0,0,0, 0,1,0,0, 128'd0, 20);

        $finish;
    end

endmodule
