`timescale 1ns/1ps

module tb_compare_swap;

    // DUT connections
    reg  [7:0] a, b;
    wire [7:0] hi, lo;

    // Instantiate DUT
    compare_swap uut (
        .a(a),
        .b(b),
        .hi(hi),
        .lo(lo)
    );

    // Clock (not used by combinational DUT, but required by spec)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not used by combinational DUT, but required by spec)
    reg rst;
    integer i;

    // Task for checking
    task check;
        input [7:0] in_a;
        input [7:0] in_b;
        input [7:0] exp_hi;
        input [7:0] exp_lo;
        input [63:0] desc0;
        input [63:0] desc1;
        begin
            #1; // small delay for combinational settle
            if (hi === exp_hi && lo === exp_lo)
                $display("PASS: a=%0d b=%0d => hi=%0d lo=%0d", in_a, in_b, hi, lo);
            else
                $display("FAIL: a=%0d b=%0d => hi=%0d (exp %0d) lo=%0d (exp %0d)",
                         in_a, in_b, hi, exp_hi, lo, exp_lo);
        end
    endtask

    initial begin
        // Apply reset for 5 rising edges
        rst = 1;
        a = 0; b = 0;
        repeat(5) @(posedge clk);
        rst = 0;
        @(negedge clk);

        // Test 1: a > b (normal operation)
        a = 8'd100; b = 8'd50;
        #2;
        if (hi === 8'd100 && lo === 8'd50)
            $display("PASS: a=100 b=50 => hi=100 lo=50");
        else
            $display("FAIL: a=100 b=50 => hi=%0d lo=%0d (exp hi=100 lo=50)", hi, lo);

        // Test 2: a < b (swap needed)
        a = 8'd30; b = 8'd90;
        #2;
        if (hi === 8'd90 && lo === 8'd30)
            $display("PASS: a=30 b=90 => hi=90 lo=30");
        else
            $display("FAIL: a=30 b=90 => hi=%0d lo=%0d (exp hi=90 lo=30)", hi, lo);

        // Test 3: equal values
        a = 8'd77; b = 8'd77;
        #2;
        if (hi === 8'd77 && lo === 8'd77)
            $display("PASS: a=77 b=77 => hi=77 lo=77 (equal)");
        else
            $display("FAIL: a=77 b=77 => hi=%0d lo=%0d (exp hi=77 lo=77)", hi, lo);

        // Test 4: all zeros
        a = 8'd0; b = 8'd0;
        #2;
        if (hi === 8'd0 && lo === 8'd0)
            $display("PASS: a=0 b=0 => hi=0 lo=0 (all zeros)");
        else
            $display("FAIL: a=0 b=0 => hi=%0d lo=%0d (exp hi=0 lo=0)", hi, lo);

        // Test 5: all ones (max values)
        a = 8'hFF; b = 8'hFF;
        #2;
        if (hi === 8'hFF && lo === 8'hFF)
            $display("PASS: a=255 b=255 => hi=255 lo=255 (all ones)");
        else
            $display("FAIL: a=255 b=255 => hi=%0d lo=%0d (exp hi=255 lo=255)", hi, lo);

        // Test 6: a=0, b=255 (max vs min)
        a = 8'd0; b = 8'hFF;
        #2;
        if (hi === 8'hFF && lo === 8'd0)
            $display("PASS: a=0 b=255 => hi=255 lo=0 (min/max)");
        else
            $display("FAIL: a=0 b=255 => hi=%0d lo=%0d (exp hi=255 lo=0)", hi, lo);

        // Test 7: a=255, b=0 (max vs min, reversed)
        a = 8'hFF; b = 8'd0;
        #2;
        if (hi === 8'hFF && lo === 8'd0)
            $display("PASS: a=255 b=0 => hi=255 lo=0 (max/min reversed)");
        else
            $display("FAIL: a=255 b=0 => hi=%0d lo=%0d (exp hi=255 lo=0)", hi, lo);

        // Test 8: a=1, b=2 (small values)
        a = 8'd1; b = 8'd2;
        #2;
        if (hi === 8'd2 && lo === 8'd1)
            $display("PASS: a=1 b=2 => hi=2 lo=1 (small values)");
        else
            $display("FAIL: a=1 b=2 => hi=%0d lo=%0d (exp hi=2 lo=1)", hi, lo);

        // Test 9: a=128, b=127 (near-midpoint)
        a = 8'd128; b = 8'd127;
        #2;
        if (hi === 8'd128 && lo === 8'd127)
            $display("PASS: a=128 b=127 => hi=128 lo=127 (near-midpoint)");
        else
            $display("FAIL: a=128 b=127 => hi=%0d lo=%0d (exp hi=128 lo=127)", hi, lo);

        // Test 10: a=127, b=128 (near-midpoint, reversed)
        a = 8'd127; b = 8'd128;
        #2;
        if (hi === 8'd128 && lo === 8'd127)
            $display("PASS: a=127 b=128 => hi=128 lo=127 (near-midpoint reversed)");
        else
            $display("FAIL: a=127 b=128 => hi=%0d lo=%0d (exp hi=128 lo=127)", hi, lo);

        $finish;
    end

endmodule
