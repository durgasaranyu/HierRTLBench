`timescale 1ns/1ps

module tb_compare_swap;

    // DUT connections
    reg  [7:0] a, b;
    wire [7:0] hi, lo;

    // Clock (not needed for combinational, but required by general rules)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not needed for combinational, but required by general rules)
    reg rst;
    integer rst_count;

    // Instantiate DUT
    compare_swap uut (
        .a(a),
        .b(b),
        .hi(hi),
        .lo(lo)
    );

    // Task for checking results
    task check;
        input [7:0] a_in, b_in;
        input [7:0] exp_hi, exp_lo;
        input [63:0] test_num;
        begin
            #1; // small delay for combinational settling
            if (hi === exp_hi && lo === exp_lo) begin
                $display("PASS: Test %0d a=%0d b=%0d => hi=%0d lo=%0d", test_num, a_in, b_in, hi, lo);
            end else begin
                $display("FAIL: Test %0d a=%0d b=%0d => hi=%0d(exp %0d) lo=%0d(exp %0d)",
                         test_num, a_in, b_in, hi, exp_hi, lo, exp_lo);
            end
        end
    endtask

    initial begin
        // Assert reset for 5 rising edges
        rst = 1;
        a = 0; b = 0;
        rst_count = 0;
        repeat(5) @(posedge clk);
        rst = 0;

        // Test 1: Normal case a > b
        @(negedge clk);
        a = 8'd100; b = 8'd50;
        check(a, b, 8'd100, 8'd50, 1);

        // Test 2: Normal case a < b
        @(negedge clk);
        a = 8'd30; b = 8'd200;
        check(a, b, 8'd200, 8'd30, 2);

        // Test 3: Equal values
        @(negedge clk);
        a = 8'd77; b = 8'd77;
        check(a, b, 8'd77, 8'd77, 3);

        // Test 4: All zeros
        @(negedge clk);
        a = 8'd0; b = 8'd0;
        check(a, b, 8'd0, 8'd0, 4);

        // Test 5: All ones (maximum value)
        @(negedge clk);
        a = 8'hFF; b = 8'hFF;
        check(a, b, 8'hFF, 8'hFF, 5);

        // Test 6: a = max, b = 0
        @(negedge clk);
        a = 8'hFF; b = 8'd0;
        check(a, b, 8'hFF, 8'd0, 6);

        // Test 7: a = 0, b = max
        @(negedge clk);
        a = 8'd0; b = 8'hFF;
        check(a, b, 8'hFF, 8'd0, 7);

        // Test 8: a = 1, b = 2 (small values, a < b)
        @(negedge clk);
        a = 8'd1; b = 8'd2;
        check(a, b, 8'd2, 8'd1, 8);

        // Test 9: a = 128, b = 127 (a > b by 1)
        @(negedge clk);
        a = 8'd128; b = 8'd127;
        check(a, b, 8'd128, 8'd127, 9);

        // Test 10: a = 127, b = 128 (a < b by 1)
        @(negedge clk);
        a = 8'd127; b = 8'd128;
        check(a, b, 8'd128, 8'd127, 10);

        // Test 11: a = 255, b = 1
        @(negedge clk);
        a = 8'd255; b = 8'd1;
        check(a, b, 8'd255, 8'd1, 11);

        // Test 12: a = 1, b = 255
        @(negedge clk);
        a = 8'd1; b = 8'd255;
        check(a, b, 8'd255, 8'd1, 12);

        $finish;
    end

endmodule
