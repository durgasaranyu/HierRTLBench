`timescale 1ns/1ps

`define PRECISION_ROW 4
`define PRECISION_COL 4
`define PRECISION_MEM 8
`define PRECISION_DIV 8

module tb_mat_row;

    // Clock and reset
    reg clk;
    reg rst;
    reg start;
    reg [255:0] row_a_flat;
    reg [255:0] col_b_flat;
    wire [31:0] result;
    wire done;

    // Instantiate DUT
    mat_row uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .row_a_flat(row_a_flat),
        .col_b_flat(col_b_flat),
        .result(result),
        .done(done)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Variables
    integer i;
    integer timeout;
    reg [31:0] expected;
    reg test_failed;

    // Task: apply reset for 5 rising edges
    task apply_reset;
        integer j;
        begin
            rst = 1;
            start = 0;
            for (j = 0; j < 5; j = j + 1) begin
                @(posedge clk);
            end
            @(negedge clk);
            rst = 0;
        end
    endtask

    // Task: run dot product and check result
    // Waits up to 40 cycles for done
    task run_dot_product;
        input [255:0] ra;
        input [255:0] cb;
        input [31:0] exp;
        input [255:0] desc_unused; // not used in $display directly
        begin
            row_a_flat = ra;
            col_b_flat = cb;
            @(negedge clk);
            start = 1;
            @(negedge clk);
            start = 0;
            // Wait for done or timeout
            timeout = 0;
            while (!done && timeout < 40) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            // Small delay to sample outputs
            #1;
            if (done && result == exp) begin
                $display("PASS: dot product result=%0d expected=%0d", result, exp);
            end else if (!done) begin
                $display("FAIL: done never asserted (timeout). result=%0d expected=%0d", result, exp);
            end else begin
                $display("FAIL: result=%0d expected=%0d", result, exp);
            end
        end
    endtask

    // Helper function to build flat vector from 16 16-bit elements
    // element 0 in bits [15:0], element 15 in bits [255:240]
    function [255:0] build_flat;
        input [15:0] e0,e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12,e13,e14,e15;
        begin
            build_flat = {e15,e14,e13,e12,e11,e10,e9,e8,e7,e6,e5,e4,e3,e2,e1,e0};
        end
    endfunction

    // Compute expected dot product for [1..16] dot [1..16]
    // sum = 1+4+9+16+25+36+49+64+81+100+121+144+169+196+225+256 = 1496
    // actually sum of i^2 for i=1..16 = 16*17*33/6 = 1496

    initial begin
        test_failed = 0;

        // Initialize
        rst = 0;
        start = 0;
        row_a_flat = 0;
        col_b_flat = 0;

        // Apply reset
        apply_reset;

        // ------------------------------------------------------------------
        // Test 1: All zeros dot all zeros = 0
        // ------------------------------------------------------------------
        $display("--- Test 1: All zeros ---");
        apply_reset;
        run_dot_product(
            256'h0,
            256'h0,
            32'd0,
            256'h0
        );

        // ------------------------------------------------------------------
        // Test 2: [1,2,3,...,16] dot [1,2,3,...,16] = 1496
        // ------------------------------------------------------------------
        $display("--- Test 2: [1..16] dot [1..16] = 1496 ---");
        apply_reset;
        run_dot_product(
            build_flat(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16),
            build_flat(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16),
            32'd1496,
            256'h0
        );

        // ------------------------------------------------------------------
        // Test 3: All ones dot all ones = 16
        // ------------------------------------------------------------------
        $display("--- Test 3: All ones dot all ones = 16 ---");
        apply_reset;
        run_dot_product(
            build_flat(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
            build_flat(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
            32'd16,
            256'h0
        );

        // ------------------------------------------------------------------
        // Test 4: Unit vector e0 dot [1..16] = 1
        // ------------------------------------------------------------------
        $display("--- Test 4: e0 dot [1..16] = 1 ---");
        apply_reset;
        run_dot_product(
            build_flat(1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
            build_flat(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16),
            32'd1,
            256'h0
        );

        // ------------------------------------------------------------------
        // Test 5: Unit vector e15 dot [1..16] = 16
        // ------------------------------------------------------------------
        $display("--- Test 5: e15 dot [1..16] = 16 ---");
        apply_reset;
        run_dot_product(
            build_flat(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1),
            build_flat(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16),
            32'd16,
            256'h0
        );

        // ------------------------------------------------------------------
        // Test 6: All element = 2, dot all element = 3 = 16*6 = 96
        // ------------------------------------------------------------------
        $display("--- Test 6: all 2 dot all 3 = 96 ---");
        apply_reset;
        run_dot_product(
            build_flat(2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2),
            build_flat(3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3),
            32'd96,
            256'h0
        );

        // ------------------------------------------------------------------
        // Test 7: Max small values — each element = 255, dot product = 16*255*255 = 1040400
        // ------------------------------------------------------------------
        $display("--- Test 7: all 255 dot all 255 = 1040400 ---");
        apply_reset;
        run_dot_product(
            build_flat(255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255),
            build_flat(255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255),
            32'd1040400,
            256'h0
        );

        // ------------------------------------------------------------------
        // Test 8: Alternating 0 and 1 in row_a, all ones in col_b
        // row_a = [1,0,1,0,...] (8 ones at even positions), col_b = all 1 => result = 8
        // ------------------------------------------------------------------
        $display("--- Test 8: alternating 1,0 dot all 1 = 8 ---");
        apply_reset;
        run_dot_product(
            build_flat(1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0),
            build_flat(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1),
            32'd8,
            256'h0
        );

        // ------------------------------------------------------------------
        // Test 9: Verify done signal asserts after ~16 cycles
        // Use [1..16] dot [1..16] again, check timing
        // ------------------------------------------------------------------
        $display("--- Test 9: verify done timing for [1..16] dot [1..16] ---");
        apply_reset;
        row_a_flat = build_flat(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16);
        col_b_flat = build_flat(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16);
        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;
        timeout = 0;
        while (!done && timeout < 40) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        #1;
        if (!done) begin
            $display("FAIL: Test 9 done never asserted");
        end else if (result == 32'd1496) begin
            $display("PASS: Test 9 done asserted after %0d cycles, result=%0d", timeout, result);
        end else begin
            $display("FAIL: Test 9 result=%0d expected=1496", result);
        end

        // ------------------------------------------------------------------
        // Test 10: Re-run after done to verify restart works
        // ------------------------------------------------------------------
        $display("--- Test 10: restart after done ---");
        @(negedge clk);
        row_a_flat = build_flat(1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
        col_b_flat = build_flat(5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
        start = 1;
        @(negedge clk);
        start = 0;
        timeout = 0;
        while (!done && timeout < 40) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        #1;
        if (done && result == 32'd5) begin
            $display("PASS: Test 10 restart result=%0d expected=5", result);
        end else if (!done) begin
            $display("FAIL: Test 10 done never asserted");
        end else begin
            $display("FAIL: Test 10 result=%0d expected=5", result);
        end

        $display("--- Testbench complete ---");
        $finish;
    end

endmodule
