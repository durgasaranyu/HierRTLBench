`timescale 1ns/1ps

module tb_ctrl_top;

    // DUT inputs
    reg [6:0] opcode;
    reg [2:0] phase;

    // DUT outputs
    wire pc_write;
    wire ir_write;
    wire reg_write;
    wire mem_write;
    wire alu_src_a;
    wire alu_src_b;
    wire mem_to_reg;
    wire pc_source;

    // Clock and reset (not used by combinational DUT, but required by spec)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    ctrl_top uut (
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

    // Reset sequence: assert for 5 rising edges
    integer i;
    initial begin
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
    end

    // Declare test variables
    reg test_pass;

    initial begin
        // Wait for reset to deassert
        @(negedge rst);
        #2; // Small settle time

        // ---------------------------------------------------------------
        // Test 1: Undefined opcode (7'h00), phase 0 - expect all zeros
        // ---------------------------------------------------------------
        opcode = 7'h00;
        phase  = 3'd0;
        #10;
        test_pass = (pc_write === 1'b0) && (ir_write === 1'b0) &&
                    (reg_write === 1'b0) && (mem_write === 1'b0);
        if (test_pass)
            $display("PASS: undefined opcode=7'h00, phase=0: all outputs zero");
        else
            $display("FAIL: undefined opcode=7'h00, phase=0: expected all zeros, got pc_write=%b ir_write=%b reg_write=%b mem_write=%b",
                     pc_write, ir_write, reg_write, mem_write);

        // ---------------------------------------------------------------
        // Test 2: opcode 7'h33 (R-type), phase 0 - expect default/zero
        // ---------------------------------------------------------------
        opcode = 7'h33;
        phase  = 3'd0;
        #10;
        test_pass = (pc_write === 1'b0) && (ir_write === 1'b0) &&
                    (reg_write === 1'b0) && (mem_write === 1'b0);
        if (test_pass)
            $display("PASS: opcode=7'h33 (R-type), phase=0: outputs as expected");
        else
            $display("FAIL: opcode=7'h33 (R-type), phase=0: pc_write=%b ir_write=%b reg_write=%b mem_write=%b",
                     pc_write, ir_write, reg_write, mem_write);

        // ---------------------------------------------------------------
        // Test 3: opcode 7'h33 (R-type), phase 1 - pc_write should be 1
        // ---------------------------------------------------------------
        opcode = 7'h33;
        phase  = 3'd1;
        #10;
        test_pass = (pc_write === 1'b1) && (ir_write === 1'b0) &&
                    (reg_write === 1'b0) && (mem_write === 1'b0);
        if (test_pass)
            $display("PASS: opcode=7'h33 (R-type), phase=1: pc_write=1, others=0");
        else
            $display("FAIL: opcode=7'h33 (R-type), phase=1: pc_write=%b ir_write=%b reg_write=%b mem_write=%b",
                     pc_write, ir_write, reg_write, mem_write);

        // ---------------------------------------------------------------
        // Test 4: opcode 7'h13 (I-type), phase 2 - ir_write should be 1
        // ---------------------------------------------------------------
        opcode = 7'h13;
        phase  = 3'd2;
        #10;
        test_pass = (pc_write === 1'b0) && (ir_write === 1'b1) &&
                    (reg_write === 1'b0) && (mem_write === 1'b0);
        if (test_pass)
            $display("PASS: opcode=7'h13 (I-type), phase=2: ir_write=1, others=0");
        else
            $display("FAIL: opcode=7'h13 (I-type), phase=2: pc_write=%b ir_write=%b reg_write=%b mem_write=%b",
                     pc_write, ir_write, reg_write, mem_write);

        // ---------------------------------------------------------------
        // Test 5: opcode 7'h03 (load), phase 3 - reg_write should be 1
        // ---------------------------------------------------------------
        opcode = 7'h03;
        phase  = 3'd3;
        #10;
        test_pass = (pc_write === 1'b0) && (ir_write === 1'b0) &&
                    (reg_write === 1'b1) && (mem_write === 1'b0);
        if (test_pass)
            $display("PASS: opcode=7'h03 (load), phase=3: reg_write=1, others=0");
        else
            $display("FAIL: opcode=7'h03 (load), phase=3: pc_write=%b ir_write=%b reg_write=%b mem_write=%b",
                     pc_write, ir_write, reg_write, mem_write);

        // ---------------------------------------------------------------
        // Test 6: opcode 7'h23 (store), phase 4 - mem_write should be 1
        // ---------------------------------------------------------------
        opcode = 7'h23;
        phase  = 3'd4;
        #10;
        test_pass = (pc_write === 1'b0) && (ir_write === 1'b0) &&
                    (reg_write === 1'b0) && (mem_write === 1'b1);
        if (test_pass)
            $display("PASS: opcode=7'h23 (store), phase=4: mem_write=1, others=0");
        else
            $display("FAIL: opcode=7'h23 (store), phase=4: pc_write=%b ir_write=%b reg_write=%b mem_write=%b",
                     pc_write, ir_write, reg_write, mem_write);

        // ---------------------------------------------------------------
        // Test 7: opcode 7'h63 (branch), phase 1 - pc_write should be 1
        // ---------------------------------------------------------------
        opcode = 7'h63;
        phase  = 3'd1;
        #10;
        test_pass = (pc_write === 1'b1) && (ir_write === 1'b0) &&
                    (reg_write === 1'b0) && (mem_write === 1'b0);
        if (test_pass)
            $display("PASS: opcode=7'h63 (branch), phase=1: pc_write=1, others=0");
        else
            $display("FAIL: opcode=7'h63 (branch), phase=1: pc_write=%b ir_write=%b reg_write=%b mem_write=%b",
                     pc_write, ir_write, reg_write, mem_write);

        // ---------------------------------------------------------------
        // Test 8: All-ones opcode (7'h7F), all-ones phase (3'b111) - default/undefined
        // ---------------------------------------------------------------
        opcode = 7'h7F;
        phase  = 3'b111;
        #10;
        test_pass = (pc_write === 1'b0) && (ir_write === 1'b0) &&
                    (reg_write === 1'b0) && (mem_write === 1'b0);
        if (test_pass)
            $display("PASS: opcode=7'h7F (all-ones), phase=7 (undefined): all outputs zero");
        else
            $display("FAIL: opcode=7'h7F (all-ones), phase=7 (undefined): pc_write=%b ir_write=%b reg_write=%b mem_write=%b",
                     pc_write, ir_write, reg_write, mem_write);

        // ---------------------------------------------------------------
        // Test 9: opcode 7'h33 (R-type), phase 2 - ir_write should be 1
        // ---------------------------------------------------------------
        opcode = 7'h33;
        phase  = 3'd2;
        #10;
        test_pass = (pc_write === 1'b0) && (ir_write === 1'b1) &&
                    (reg_write === 1'b0) && (mem_write === 1'b0);
        if (test_pass)
            $display("PASS: opcode=7'h33 (R-type), phase=2: ir_write=1, others=0");
        else
            $display("FAIL: opcode=7'h33 (R-type), phase=2: pc_write=%b ir_write=%b reg_write=%b mem_write=%b",
                     pc_write, ir_write, reg_write, mem_write);

        // ---------------------------------------------------------------
        // Test 10: opcode 7'h63 (branch), phase 3 - reg_write should be 1
        // ---------------------------------------------------------------
        opcode = 7'h63;
        phase  = 3'd3;
        #10;
        test_pass = (pc_write === 1'b0) && (ir_write === 1'b0) &&
                    (reg_write === 1'b1) && (mem_write === 1'b0);
        if (test_pass)
            $display("PASS: opcode=7'h63 (branch), phase=3: reg_write=1, others=0");
        else
            $display("FAIL: opcode=7'h63 (branch), phase=3: pc_write=%b ir_write=%b reg_write=%b mem_write=%b",
                     pc_write, ir_write, reg_write, mem_write);

        // ---------------------------------------------------------------
        // Test 11: opcode 7'h03 (load), phase 4 - mem_write should be 1
        // ---------------------------------------------------------------
        opcode = 7'h03;
        phase  = 3'd4;
        #10;
        test_pass = (pc_write === 1'b0) && (ir_write === 1'b0) &&
                    (reg_write === 1'b0) && (mem_write === 1'b1);
        if (test_pass)
            $display("PASS: opcode=7'h03 (load), phase=4: mem_write=1, others=0");
        else
            $display("FAIL: opcode=7'h03 (load), phase=4: pc_write=%b ir_write=%b reg_write=%b mem_write=%b",
                     pc_write, ir_write, reg_write, mem_write);

        // ---------------------------------------------------------------
        // Test 12: pc_write only asserts in phase 1 - verify phase 0, 2, 3, 4 give pc_write=0
        // ---------------------------------------------------------------
        opcode = 7'h13;
        begin
            // phase 0
            phase = 3'd0; #10;
            test_pass = (pc_write === 1'b0);
            // phase 2
            phase = 3'd2; #10;
            test_pass = test_pass && (pc_write === 1'b0);
            // phase 3
            phase = 3'd3; #10;
            test_pass = test_pass && (pc_write === 1'b0);
            // phase 4
            phase = 3'd4; #10;
            test_pass = test_pass && (pc_write === 1'b0);
            // phase 1 should give pc_write=1
            phase = 3'd1; #10;
            test_pass = test_pass && (pc_write === 1'b1);
        end
        if (test_pass)
            $display("PASS: opcode=7'h13: pc_write=1 only in phase=1, 0 in all other phases");
        else
            $display("FAIL: opcode=7'h13: pc_write assertion check failed across phases");

        // ---------------------------------------------------------------
        // Test 13: All-zero inputs (opcode=0, phase=0)
        // ---------------------------------------------------------------
        opcode = 7'h00;
        phase  = 3'd0;
        #10;
        test_pass = (pc_write === 1'b0) && (ir_write === 1'b0) &&
                    (reg_write === 1'b0) && (mem_write === 1'b0);
        if (test_pass)
            $display("PASS: all-zero inputs: all outputs zero");
        else
            $display("FAIL: all-zero inputs: pc_write=%b ir_write=%b reg_write=%b mem_write=%b",
                     pc_write, ir_write, reg_write, mem_write);

        $finish;
    end

endmodule
