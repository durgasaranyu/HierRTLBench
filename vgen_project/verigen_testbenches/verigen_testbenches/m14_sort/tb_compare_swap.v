`timescale 1ns/1ps

module tb_compare_swap;

    // DUT connections
    reg  [7:0] a;
    reg  [7:0] b;
    wire [7:0] hi;
    wire [7:0] lo;

    // Instantiate DUT
    compare_swap uut (
        .a(a),
        .b(b),
        .hi(hi),
        .lo(lo)
    );

    // Clock (not strictly needed for combinational, but required by spec)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not used by this combinational module, but required by spec)
    reg rst;
    integer rst_count;

    // Task to check one test vector
    task check;
        input [7:0] in_a;
        input [7:0] in_b;
        input [7:0] exp_hi;
        input [7:0] exp_lo;
        input [63:0] test_num;
        begin
            a = in_a;
            b = in_b;
            #2; // let combinational settle
            if (hi === exp_hi && lo === exp_lo) begin
                $display("PASS: Test %0d a=%0d b=%0d => hi=%0d lo=%0d", test_num, in_a, in_b, hi, lo);
            end else begin
                $display("FAIL: Test %0d a=%0d b=%0d => hi=%0d (exp %0d) lo=%0d (exp %0d)",
                         test_num, in_a, in_b, hi, exp_hi, lo, exp_lo);
            end
        end
    endtask

    initial begin
        // Initialize
        a   = 8'h00;
        b   = 8'h00;
        rst = 1;

        // Assert reset for exactly 5 rising edges
        rst_count = 0;
        @(posedge clk); rst_count = rst_count + 1;
        @(posedge clk); rst_count = rst_count + 1;
        @(posedge clk); rst_count = rst_count + 1;
        @(posedge clk); rst_count = rst_count + 1;
        @(posedge clk); rst_count = rst_count + 1;
        rst = 0;

        // Wait a bit after reset
        #3;

        // Test 1: a > b (normal operation)
        check(8'd100, 8'd50,  8'd100, 8'd50,  1);

        // Test 2: a < b (normal operation)
        check(8'd30,  8'd80,  8'd80,  8'd30,  2);

        // Test 3: a == b (equal values)
        check(8'd42,  8'd42,  8'd42,  8'd42,  3);

        // Test 4: a = 0, b = 0 (all-zero inputs)
        check(8'd0,   8'd0,   8'd0,   8'd0,   4);

        // Test 5: a = 255, b = 255 (all-ones / max equal)
        check(8'hFF,  8'hFF,  8'hFF,  8'hFF,  5);

        // Test 6: a = 255, b = 0 (maximum difference, a>b)
        check(8'hFF,  8'h00,  8'hFF,  8'h00,  6);

        // Test 7: a = 0, b = 255 (maximum difference, b>a)
        check(8'h00,  8'hFF,  8'hFF,  8'h00,  7);

        // Test 8: a = 1, b = 2 (small adjacent values)
        check(8'd1,   8'd2,   8'd2,   8'd1,   8);

        // Test 9: a = 128, b = 127 (near midpoint, a>b)
        check(8'd128, 8'd127, 8'd128, 8'd127, 9);

        // Test 10: a = 127, b = 128 (near midpoint, b>a)
        check(8'd127, 8'd128, 8'd128, 8'd127, 10);

        // Test 11: a = 255, b = 1
        check(8'hFF,  8'h01,  8'hFF,  8'h01,  11);

        // Test 12: a = 1, b = 255
        check(8'h01,  8'hFF,  8'hFF,  8'h01,  12);

        $finish;
    end

endmodule
