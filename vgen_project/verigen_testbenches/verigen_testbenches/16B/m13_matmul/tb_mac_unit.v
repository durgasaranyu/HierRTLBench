`timescale 1ns/1ps

module tb_mac_unit;

    // DUT port declarations
    reg         clk, rst, clear, en;
    reg  [15:0] a, b;
    wire [31:0] acc;

    // Instantiate DUT
    mac_unit uut (
        .clk   (clk),
        .rst   (rst),
        .clear (clear),
        .en    (en),
        .a     (a),
        .b     (b),
        .acc   (acc)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Expected accumulator value tracked in testbench
    reg [31:0] expected;
    integer    fail_count;

    // Task: apply one accumulate cycle
    task apply_mac;
        input [15:0] ta, tb_val;
        input        tc, te;      // clear, en
        begin
            a     = ta;
            b     = tb_val;
            clear = tc;
            en    = te;
            @(posedge clk);
            #1; // small delay to let output settle after clock edge
        end
    endtask

    initial begin
        fail_count = 0;
        // Initialize inputs
        rst   = 0;
        clear = 0;
        en    = 0;
        a     = 0;
        b     = 0;

        // Assert reset for exactly 5 rising edges
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // After reset, acc must be 0
        expected = 32'd0;
        if (acc === expected)
            $display("PASS: acc=0 after reset");
        else begin
            $display("FAIL: acc after reset. Expected %0d, Got %0d", expected, acc);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 1: clear resets accumulator
        // First accumulate something
        apply_mac(16'd10, 16'd10, 1'b0, 1'b1); // acc = 0 + 100 = 100
        apply_mac(16'd0,  16'd0,  1'b1, 1'b0); // clear
        #1;
        expected = 32'd0;
        if (acc === expected)
            $display("PASS: Test1 - clear resets acc to 0");
        else begin
            $display("FAIL: Test1 - clear. Expected %0d, Got %0d", expected, acc);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 2: Normal accumulation - 3 values
        // acc = 3*4 + 5*6 + 7*8 = 12 + 30 + 56 = 98
        apply_mac(16'd3, 16'd4, 1'b0, 1'b1); // acc = 12
        apply_mac(16'd5, 16'd6, 1'b0, 1'b1); // acc = 12+30 = 42
        apply_mac(16'd7, 16'd8, 1'b0, 1'b1); // acc = 42+56 = 98
        expected = 32'd98;
        if (acc === expected)
            $display("PASS: Test2 - normal accumulation of 3 values = 98");
        else begin
            $display("FAIL: Test2 - normal accumulation. Expected %0d, Got %0d", expected, acc);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 3: en=0 does not accumulate
        apply_mac(16'd100, 16'd100, 1'b0, 1'b0); // acc should stay 98
        expected = 32'd98;
        if (acc === expected)
            $display("PASS: Test3 - en=0 does not change acc");
        else begin
            $display("FAIL: Test3 - en=0. Expected %0d, Got %0d", expected, acc);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 4: All-zero inputs - accumulate 0*0
        apply_mac(16'd0, 16'd0, 1'b1, 1'b0); // clear first
        apply_mac(16'd0, 16'd0, 1'b0, 1'b1); // acc = 0 + 0 = 0
        expected = 32'd0;
        if (acc === expected)
            $display("PASS: Test4 - all-zero inputs accumulate to 0");
        else begin
            $display("FAIL: Test4 - all-zero. Expected %0d, Got %0d", expected, acc);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 5: All-ones inputs (maximum 16-bit value) single accumulate
        apply_mac(16'd0,      16'd0,      1'b1, 1'b0); // clear
        apply_mac(16'hFFFF,   16'hFFFF,   1'b0, 1'b1); // acc = 65535*65535
        expected = 32'd65535 * 32'd65535; // = 4294836225
        if (acc === expected)
            $display("PASS: Test5 - all-ones inputs: acc = %0d", acc);
        else begin
            $display("FAIL: Test5 - all-ones. Expected %0d, Got %0d", expected, acc);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 6: Accumulate sum of products for 3 distinct pairs
        // 2*3 + 4*5 + 6*7 = 6 + 20 + 42 = 68
        apply_mac(16'd0, 16'd0, 1'b1, 1'b0); // clear
        apply_mac(16'd2, 16'd3, 1'b0, 1'b1); // acc = 6
        apply_mac(16'd4, 16'd5, 1'b0, 1'b1); // acc = 26
        apply_mac(16'd6, 16'd7, 1'b0, 1'b1); // acc = 68
        expected = 32'd68;
        if (acc === expected)
            $display("PASS: Test6 - 3 distinct product accumulation = 68");
        else begin
            $display("FAIL: Test6 - 3 products. Expected %0d, Got %0d", expected, acc);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 7: Accumulate more values and then clear and reaccumulate
        apply_mac(16'd10, 16'd20, 1'b0, 1'b1); // acc = 68 + 200 = 268
        apply_mac(16'd0,  16'd0,  1'b1, 1'b0); // clear -> acc = 0
        apply_mac(16'd15, 16'd15, 1'b0, 1'b1); // acc = 225
        expected = 32'd225;
        if (acc === expected)
            $display("PASS: Test7 - clear then reaccumulate = 225");
        else begin
            $display("FAIL: Test7 - clear then reaccumulate. Expected %0d, Got %0d", expected, acc);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 8: Synchronous reset during operation
        apply_mac(16'd100, 16'd100, 1'b0, 1'b1); // acc = 225 + 10000 = 10225
        // Now assert rst synchronously for 2 cycles
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        expected = 32'd0;
        if (acc === expected)
            $display("PASS: Test8 - rst clears acc to 0 during operation");
        else begin
            $display("FAIL: Test8 - rst during operation. Expected %0d, Got %0d", expected, acc);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 9: Accumulate three values after reset - verify sum of products
        // 1*1 + 2*2 + 3*3 = 1 + 4 + 9 = 14
        apply_mac(16'd1, 16'd1, 1'b0, 1'b1); // acc = 1
        apply_mac(16'd2, 16'd2, 1'b0, 1'b1); // acc = 5
        apply_mac(16'd3, 16'd3, 1'b0, 1'b1); // acc = 14
        expected = 32'd14;
        if (acc === expected)
            $display("PASS: Test9 - accumulate 1*1+2*2+3*3 = 14");
        else begin
            $display("FAIL: Test9 - sum of squares. Expected %0d, Got %0d", expected, acc);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Final summary
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
