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

    // Task for checking and reporting
    task check;
        input [127:0] desc_unused; // placeholder, use $display directly
        input exp_pc_write;
        input exp_ir_write;
        input exp_reg_write;
        input exp_mem_write;
        input [63:0] test_id;
        begin
            // We'll do checking inline
        end
    endtask

    integer pass_count;
    integer fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Wait for reset to complete
        @(posedge clk); // wait one clock after reset starts
        repeat (5) @(posedge clk);
        #2; // small delay after last rising edge

        // ============================================================
        // Test 1: opcode=7'h33 (R-type), phase=3'd0 (fetch/default)
        // Expected: pc_write=0, ir_write=0, reg_write=0, mem_write=0
        // ============================================================
        opcode = 7'h33; phase = 3'd0;
        #10;
        if (pc_write===1'b0 && ir_write===1'b0 && reg_write===1'b0 && mem_write===1'b0) begin
            $display("PASS: opcode=7'h33, phase=0 => all-zero outputs (default/fetch)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: opcode=7'h33, phase=0 => pc_write=%b ir_write=%b reg_write=%b mem_write=%b (expected 0,0,0,0)",
                pc_write, ir_write, reg_write, mem_write);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // Test 2: opcode=7'h33 (R-type), phase=3'd1
        // Expected: pc_write=1, ir_write=0, reg_write=0, mem_write=0
        // ============================================================
        opcode = 7'h33; phase = 3'd1;
        #10;
        if (pc_write===1'b1 && ir_write===1'b0 && reg_write===1'b0 && mem_write===1'b0) begin
            $display("PASS: opcode=7'h33, phase=1 => pc_write asserts");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: opcode=7'h33, phase=1 => pc_write=%b ir_write=%b reg_write=%b mem_write=%b (expected 1,0,0,0)",
                pc_write, ir_write, reg_write, mem_write);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // Test 3: opcode=7'h33 (R-type), phase=3'd2
        // Expected: pc_write=0, ir_write=1, reg_write=0, mem_write=0
        // ============================================================
        opcode = 7'h33; phase = 3'd2;
        #10;
        if (pc_write===1'b0 && ir_write===1'b1 && reg_write===1'b0 && mem_write===1'b0) begin
            $display("PASS: opcode=7'h33, phase=2 => ir_write asserts");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: opcode=7'h33, phase=2 => pc_write=%b ir_write=%b reg_write=%b mem_write=%b (expected 0,1,0,0)",
                pc_write, ir_write, reg_write, mem_write);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // Test 4: opcode=7'h33 (R-type), phase=3'd3
        // Expected: pc_write=0, ir_write=0, reg_write=1, mem_write=0
        // ============================================================
        opcode = 7'h33; phase = 3'd3;
        #10;
        if (pc_write===1'b0 && ir_write===1'b0 && reg_write===1'b1 && mem_write===1'b0) begin
            $display("PASS: opcode=7'h33, phase=3 => reg_write asserts");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: opcode=7'h33, phase=3 => pc_write=%b ir_write=%b reg_write=%b mem_write=%b (expected 0,0,1,0)",
                pc_write, ir_write, reg_write, mem_write);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // Test 5: opcode=7'h23 (Store), phase=3'd4
        // Expected: pc_write=0, ir_write=0, reg_write=0, mem_write=1
        // ============================================================
        opcode = 7'h23; phase = 3'd4;
        #10;
        if (pc_write===1'b0 && ir_write===1'b0 && reg_write===1'b0 && mem_write===1'b1) begin
            $display("PASS: opcode=7'h23, phase=4 => mem_write asserts");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: opcode=7'h23, phase=4 => pc_write=%b ir_write=%b reg_write=%b mem_write=%b (expected 0,0,0,1)",
                pc_write, ir_write, reg_write, mem_write);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // Test 6: opcode=7'h13 (I-type ALU), phase=3'd1
        // Expected: pc_write=1 (phase 1 always sets pc_write)
        // ============================================================
        opcode = 7'h13; phase = 3'd1;
        #10;
        if (pc_write===1'b1) begin
            $display("PASS: opcode=7'h13, phase=1 => pc_write=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: opcode=7'h13, phase=1 => pc_write=%b (expected 1)", pc_write);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // Test 7: opcode=7'h03 (Load), phase=3'd2
        // Expected: ir_write=1 (phase 2)
        // ============================================================
        opcode = 7'h03; phase = 3'd2;
        #10;
        if (ir_write===1'b1 && pc_write===1'b0) begin
            $display("PASS: opcode=7'h03, phase=2 => ir_write=1, pc_write=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: opcode=7'h03, phase=2 => pc_write=%b ir_write=%b (expected 0,1)",
                pc_write, ir_write);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // Test 8: opcode=7'h63 (Branch), phase=3'd3
        // Expected: reg_write=1 (phase 3), pc_write=0, mem_write=0
        // ============================================================
        opcode = 7'h63; phase = 3'd3;
        #10;
        if (reg_write===1'b1 && pc_write===1'b0 && mem_write===1'b0) begin
            $display("PASS: opcode=7'h63, phase=3 => reg_write=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: opcode=7'h63, phase=3 => pc_write=%b reg_write=%b mem_write=%b (expected 0,1,0)",
                pc_write, reg_write, mem_write);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // Test 9: undefined opcode (all zeros), phase=3'd0 (default)
        // Expected: all outputs = 0
        // ============================================================
        opcode = 7'h00; phase = 3'd0;
        #10;
        if (pc_write===1'b0 && ir_write===1'b0 && reg_write===1'b0 && mem_write===1'b0) begin
            $display("PASS: opcode=7'h00, phase=0 => all-zero outputs");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: opcode=7'h00, phase=0 => pc_write=%b ir_write=%b reg_write=%b mem_write=%b (expected 0,0,0,0)",
                pc_write, ir_write, reg_write, mem_write);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // Test 10: all-ones opcode (7'h7f), phase=3'd7 (undefined)
        // Expected: default => all zero
        // ============================================================
        opcode = 7'h7f; phase = 3'd7;
        #10;
        if (pc_write===1'b0 && ir_write===1'b0 && reg_write===1'b0 && mem_write===1'b0) begin
            $display("PASS: opcode=7'h7f, phase=7 (undefined) => all-zero outputs");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: opcode=7'h7f, phase=7 => pc_write=%b ir_write=%b reg_write=%b mem_write=%b (expected 0,0,0,0)",
                pc_write, ir_write, reg_write, mem_write);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // Test 11: pc_write only in phase=1, not in phase=2,3,4
        // opcode=7'h03, phase=4
        // Expected: mem_write=1, pc_write=0
        // ============================================================
        opcode = 7'h03; phase = 3'd4;
        #10;
        if (pc_write===1'b0 && mem_write===1'b1) begin
            $display("PASS: opcode=7'h03, phase=4 => pc_write=0 (not asserted), mem_write=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: opcode=7'h03, phase=4 => pc_write=%b mem_write=%b (expected 0,1)",
                pc_write, mem_write);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // Test 12: opcode=7'h63 (Branch), phase=3'd1
        // pc_write should assert regardless of opcode in phase 1
        // ============================================================
        opcode = 7'h63; phase = 3'd1;
        #10;
        if (pc_write===1'b1 && ir_write===1'b0 && reg_write===1'b0 && mem_write===1'b0) begin
            $display("PASS: opcode=7'h63, phase=1 => pc_write=1 (only pc_write)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: opcode=7'h63, phase=1 => pc_write=%b ir_write=%b reg_write=%b mem_write=%b (expected 1,0,0,0)",
                pc_write, ir_write, reg_write, mem_write);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // Test 13: opcode=7'h13, phase=3'd4 => mem_write=1
        // ============================================================
        opcode = 7'h13; phase = 3'd4;
        #10;
        if (mem_write===1'b1 && pc_write===1'b0 && reg_write===1'b0) begin
            $display("PASS: opcode=7'h13, phase=4 => mem_write=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: opcode=7'h13, phase=4 => pc_write=%b reg_write=%b mem_write=%b (expected 0,0,1)",
                pc_write, reg_write, mem_write);
            fail_count = fail_count + 1;
        end

        // ============================================================
        // Test 14: opcode=7'h23, phase=3'd3 => reg_write=1
        // ============================================================
        opcode = 7'h23; phase = 3'd3;
        #10;
        if (reg_write===1'b1 && pc_write===1'b0 && mem_write===1'b0) begin
            $display("PASS: opcode=7'h23, phase=3 => reg_write=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: opcode=7'h23, phase=3 => pc_write=%b reg_write=%b mem_write=%b (expected 0,1,0)",
                pc_write, reg_write, mem_write);
            fail_count = fail_count + 1;
        end

        // Summary
        $display("==============================");
        $display("Results: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("==============================");

        $finish;
    end

endmodule
