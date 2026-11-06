`timescale 1ns/1ps

module tb_compare_swap;

    // DUT connections
    reg  [7:0] a, b;
    wire [7:0] hi, lo;

    // Clock (not strictly needed for combinational, but required by rules)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not strictly needed, but required by rules)
    reg rst;
    integer i;

    // Instantiate DUT
    compare_swap uut (
        .a(a),
        .b(b),
        .hi(hi),
        .lo(lo)
    );

    // Task to check results
    task check;
        input [7:0] ta, tb;
        input [7:0] exp_hi, exp_lo;
        input [63:0] test_num;
        begin
            a = ta;
            b = tb;
            #2; // small propagation delay
            if (hi === exp_hi && lo === exp_lo)
                $display("PASS: Test %0d: a=%0d b=%0d => hi=%0d lo=%0d", test_num, ta, tb, hi, lo);
            else
                $display("FAIL: Test %0d: a=%0d b=%0d => hi=%0d (exp %0d) lo=%0d (exp %0d)", test_num, ta, tb, hi, exp_hi, lo, exp_lo);
        end
    endtask

    initial begin
        // Assert reset for 5 rising edges
        rst = 1;
        a   = 0;
        b   = 0;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // Test 1: Normal case, a > b
        check(8'd100, 8'd50, 8'd100, 8'd50, 1);

        // Test 2: Normal case, b > a
        check(8'd30, 8'd200, 8'd200, 8'd30, 2);

        // Test 3: Equal values
        check(8'd77, 8'd77, 8'd77, 8'd77, 3);

        // Test 4: All zeros
        check(8'd0, 8'd0, 8'd0, 8'd0, 4);

        // Test 5: All ones (max value 255 vs max value 255)
        check(8'd255, 8'd255, 8'd255, 8'd255, 5);

        // Test 6: a = max, b = 0
        check(8'd255, 8'd0, 8'd255, 8'd0, 6);

        // Test 7: a = 0, b = max
        check(8'd0, 8'd255, 8'd255, 8'd0, 7);

        // Test 8: a = 1, b = 0 (adjacent values)
        check(8'd1, 8'd0, 8'd1, 8'd0, 8);

        // Test 9: a = 0, b = 1 (adjacent values, reversed)
        check(8'd0, 8'd1, 8'd1, 8'd0, 9);

        // Test 10: a = 128, b = 127 (mid-range boundary)
        check(8'd128, 8'd127, 8'd128, 8'd127, 10);

        // Test 11: a = 127, b = 128 (mid-range boundary, reversed)
        check(8'd127, 8'd128, 8'd128, 8'd127, 11);

        // Test 12: a = 254, b = 255
        check(8'd254, 8'd255, 8'd255, 8'd254, 12);

        $finish;
    end

endmodule
