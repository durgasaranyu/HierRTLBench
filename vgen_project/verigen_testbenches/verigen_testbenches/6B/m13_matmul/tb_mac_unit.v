`timescale 1ns/1ps

module tb_mac_unit;

    // DUT I/O
    reg         clk;
    reg         rst;
    reg         clear;
    reg         en;
    reg  [15:0] a;
    reg  [15:0] b;
    wire [31:0] acc;

    // Instantiate the DUT
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

    // Task: apply one accumulate cycle
    task apply_mac;
        input [15:0] ta;
        input [15:0] tb;
        begin
            a  = ta;
            b  = tb;
            en = 1;
            @(posedge clk); #1;
            en = 0;
        end
    endtask

    // Expected accumulator tracking
    reg [31:0] expected;
    integer    fail_count;

    initial begin
        fail_count = 0;

        // Initialise inputs
        rst   = 0;
        clear = 0;
        en    = 0;
        a     = 0;
        b     = 0;

        // Assert reset for 5 rising edges
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // ----------------------------------------------------------------
        // TEST 1: After reset, acc should be 0
        // ----------------------------------------------------------------
        if (acc === 32'd0)
            $display("PASS: After reset acc=0");
        else begin
            $display("FAIL: After reset acc=%0d (expected 0)", acc);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 2: Clear with en=0 keeps acc at 0
        // ----------------------------------------------------------------
        clear = 1;
        @(posedge clk); #1;
        clear = 0;
        if (acc === 32'd0)
            $display("PASS: Clear from zero keeps acc=0");
        else begin
            $display("FAIL: Clear from zero acc=%0d (expected 0)", acc);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 3: Accumulate 3 typical values and verify sum-of-products
        //         acc should hold LAST product (module stores a*b, not sum)
        //         Per module: acc_r <= a*b  (not +=)
        //         After each en pulse, acc = current a*b
        // ----------------------------------------------------------------
        // Accumulate first value: 3 * 4 = 12
        apply_mac(16'd3, 16'd4);
        expected = 32'd12;
        if (acc === expected)
            $display("PASS: First accumulate 3*4=12, acc=%0d", acc);
        else begin
            $display("FAIL: First accumulate 3*4=12, acc=%0d (expected %0d)", acc, expected);
            fail_count = fail_count + 1;
        end

        // Accumulate second value: 5 * 6 = 30
        apply_mac(16'd5, 16'd6);
        expected = 32'd30;
        if (acc === expected)
            $display("PASS: Second accumulate 5*6=30, acc=%0d", acc);
        else begin
            $display("FAIL: Second accumulate 5*6=30, acc=%0d (expected %0d)", acc, expected);
            fail_count = fail_count + 1;
        end

        // Accumulate third value: 7 * 8 = 56
        apply_mac(16'd7, 16'd8);
        expected = 32'd56;
        if (acc === expected)
            $display("PASS: Third accumulate 7*8=56, acc=%0d", acc);
        else begin
            $display("FAIL: Third accumulate 7*8=56, acc=%0d (expected %0d)", acc, expected);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 4: Clear resets acc to 0
        // ----------------------------------------------------------------
        clear = 1;
        @(posedge clk); #1;
        clear = 0;
        if (acc === 32'd0)
            $display("PASS: Clear after accumulation, acc=0");
        else begin
            $display("FAIL: Clear after accumulation acc=%0d (expected 0)", acc);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 5: All-zero inputs — en=1 with a=0, b=0
        // ----------------------------------------------------------------
        apply_mac(16'd0, 16'd0);
        expected = 32'd0;
        if (acc === expected)
            $display("PASS: All-zero inputs 0*0=0, acc=%0d", acc);
        else begin
            $display("FAIL: All-zero inputs acc=%0d (expected 0)", acc);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 6: Maximum inputs — a=0xFFFF, b=0xFFFF
        //         0xFFFF * 0xFFFF = 0xFFFE0001
        // ----------------------------------------------------------------
        apply_mac(16'hFFFF, 16'hFFFF);
        expected = 32'hFFFE0001;
        if (acc === expected)
            $display("PASS: Max inputs 0xFFFF*0xFFFF=0xFFFE0001, acc=%08h", acc);
        else begin
            $display("FAIL: Max inputs acc=%08h (expected %08h)", acc, expected);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 7: en=0, inputs change — acc should NOT update
        // ----------------------------------------------------------------
        en = 0;
        a  = 16'd100;
        b  = 16'd200;
        @(posedge clk); #1;
        // acc should still hold 0xFFFE0001 from previous test
        expected = 32'hFFFE0001;
        if (acc === expected)
            $display("PASS: en=0 holds acc unchanged, acc=%08h", acc);
        else begin
            $display("FAIL: en=0 should hold acc, acc=%08h (expected %08h)", acc, expected);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 8: Synchronous reset overrides en and clear
        // ----------------------------------------------------------------
        en  = 1;
        a   = 16'd50;
        b   = 16'd50;
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        en  = 0;
        if (acc === 32'd0)
            $display("PASS: Synchronous rst overrides en, acc=0");
        else begin
            $display("FAIL: Synchronous rst acc=%0d (expected 0)", acc);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 9: Normal operation after reset — 10 * 20 = 200
        // ----------------------------------------------------------------
        apply_mac(16'd10, 16'd20);
        expected = 32'd200;
        if (acc === expected)
            $display("PASS: After rst, 10*20=200, acc=%0d", acc);
        else begin
            $display("FAIL: After rst, 10*20=%0d (expected %0d)", acc, expected);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 10: Verify clear takes priority over en when both asserted
        // ----------------------------------------------------------------
        clear = 1;
        en    = 1;
        a     = 16'd999;
        b     = 16'd999;
        @(posedge clk); #1;
        clear = 0;
        en    = 0;
        // clear takes priority over en in the module (clear checked first)
        if (acc === 32'd0)
            $display("PASS: clear overrides en, acc=0");
        else begin
            $display("FAIL: clear overrides en, acc=%0d (expected 0)", acc);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Summary
        // ----------------------------------------------------------------
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
