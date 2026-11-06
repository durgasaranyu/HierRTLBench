// Testbench for alu_addsub
`timescale 1ns/1ps

module tb_alu_addsub;

    // Parameters
    parameter N = 8;

    // DUT connections
    reg  [N-1:0] a, b;
    reg          op;
    wire [N-1:0] result;
    wire         carry_out;

    // Clock and reset (not used by DUT but required by spec)
    reg clk;
    reg rst;

    // Expected values
    reg [N:0]   expected_full;
    reg [N-1:0] expected_result;
    reg         expected_carry;

    // Instantiate DUT
    alu_addsub #(.N(N)) uut (
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .carry_out(carry_out)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset sequence (synchronous style, though DUT has no reset)
    initial begin
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
    end

    integer fail_count;

    initial begin
        fail_count = 0;

        // Wait for reset to deassert
        @(negedge rst);
        @(posedge clk); #1;

        //------------------------------------------------------------------
        // Test 1: ADD - Normal operation (no overflow)
        // a=10, b=20, op=0 => result=30, carry=0
        //------------------------------------------------------------------
        a = 8'd10; b = 8'd20; op = 1'b0;
        @(posedge clk); #1;
        expected_full   = {1'b0, 8'd10} + {1'b0, 8'd20};
        expected_result = expected_full[N-1:0];
        expected_carry  = expected_full[N];
        if (result === expected_result && carry_out === expected_carry)
            $display("PASS: ADD normal (10+20=30, carry=0)");
        else begin
            $display("FAIL: ADD normal (10+20) got result=%0d carry=%0b, expected result=%0d carry=%0b",
                     result, carry_out, expected_result, expected_carry);
            fail_count = fail_count + 1;
        end

        //------------------------------------------------------------------
        // Test 2: ADD - Overflow (carry_out = 1)
        // a=200, b=100, op=0 => 300 overflows 8-bit => carry=1
        //------------------------------------------------------------------
        a = 8'd200; b = 8'd100; op = 1'b0;
        @(posedge clk); #1;
        expected_full   = {1'b0, 8'd200} + {1'b0, 8'd100};
        expected_result = expected_full[N-1:0];
        expected_carry  = expected_full[N];
        if (result === expected_result && carry_out === expected_carry)
            $display("PASS: ADD overflow (200+100, carry=1)");
        else begin
            $display("FAIL: ADD overflow (200+100) got result=%0d carry=%0b, expected result=%0d carry=%0b",
                     result, carry_out, expected_result, expected_carry);
            fail_count = fail_count + 1;
        end

        //------------------------------------------------------------------
        // Test 3: SUB - Normal operation (no borrow)
        // a=50, b=20, op=1 => result=30, carry=0
        //------------------------------------------------------------------
        a = 8'd50; b = 8'd20; op = 1'b1;
        @(posedge clk); #1;
        expected_full   = {1'b0, 8'd50} - {1'b0, 8'd20};
        expected_result = expected_full[N-1:0];
        expected_carry  = expected_full[N];
        if (result === expected_result && carry_out === expected_carry)
            $display("PASS: SUB normal (50-20=30, carry=0)");
        else begin
            $display("FAIL: SUB normal (50-20) got result=%0d carry=%0b, expected result=%0d carry=%0b",
                     result, carry_out, expected_result, expected_carry);
            fail_count = fail_count + 1;
        end

        //------------------------------------------------------------------
        // Test 4: SUB - Borrow (a < b)
        // a=10, b=20, op=1 => borrow => carry_out=1
        //------------------------------------------------------------------
        a = 8'd10; b = 8'd20; op = 1'b1;
        @(posedge clk); #1;
        expected_full   = {1'b0, 8'd10} - {1'b0, 8'd20};
        expected_result = expected_full[N-1:0];
        expected_carry  = expected_full[N];
        if (result === expected_result && carry_out === expected_carry)
            $display("PASS: SUB borrow (10-20, carry=1)");
        else begin
            $display("FAIL: SUB borrow (10-20) got result=%0d carry=%0b, expected result=%0d carry=%0b",
                     result, carry_out, expected_result, expected_carry);
            fail_count = fail_count + 1;
        end

        //------------------------------------------------------------------
        // Test 5: ADD - All zeros
        // a=0, b=0, op=0 => result=0, carry=0, zero_flag implied (result==0)
        //------------------------------------------------------------------
        a = 8'd0; b = 8'd0; op = 1'b0;
        @(posedge clk); #1;
        expected_full   = {1'b0, 8'd0} + {1'b0, 8'd0};
        expected_result = expected_full[N-1:0];
        expected_carry  = expected_full[N];
        if (result === expected_result && carry_out === expected_carry && result === 8'd0)
            $display("PASS: ADD all-zeros (0+0=0, carry=0, zero_flag implied)");
        else begin
            $display("FAIL: ADD all-zeros (0+0) got result=%0d carry=%0b, expected result=%0d carry=%0b",
                     result, carry_out, expected_result, expected_carry);
            fail_count = fail_count + 1;
        end

        //------------------------------------------------------------------
        // Test 6: ADD - All ones (max + max)
        // a=255, b=255, op=0 => 510 => result=254, carry=1
        //------------------------------------------------------------------
        a = 8'hFF; b = 8'hFF; op = 1'b0;
        @(posedge clk); #1;
        expected_full   = {1'b0, 8'hFF} + {1'b0, 8'hFF};
        expected_result = expected_full[N-1:0];
        expected_carry  = expected_full[N];
        if (result === expected_result && carry_out === expected_carry)
            $display("PASS: ADD all-ones (255+255=510, carry=1, result=254)");
        else begin
            $display("FAIL: ADD all-ones (255+255) got result=%0d carry=%0b, expected result=%0d carry=%0b",
                     result, carry_out, expected_result, expected_carry);
            fail_count = fail_count + 1;
        end

        //------------------------------------------------------------------
        // Test 7: SUB - Result exactly zero (zero_flag case)
        // a=42, b=42, op=1 => result=0, carry=0
        //------------------------------------------------------------------
        a = 8'd42; b = 8'd42; op = 1'b1;
        @(posedge clk); #1;
        expected_full   = {1'b0, 8'd42} - {1'b0, 8'd42};
        expected_result = expected_full[N-1:0];
        expected_carry  = expected_full[N];
        if (result === expected_result && carry_out === expected_carry && result === 8'd0)
            $display("PASS: SUB zero result (42-42=0, carry=0, zero_flag implied)");
        else begin
            $display("FAIL: SUB zero result (42-42) got result=%0d carry=%0b, expected result=%0d carry=%0b",
                     result, carry_out, expected_result, expected_carry);
            fail_count = fail_count + 1;
        end

        //------------------------------------------------------------------
        // Test 8: ADD - Max value + 1 (255+1 => result=0, carry=1, zero_flag)
        //------------------------------------------------------------------
        a = 8'hFF; b = 8'd1; op = 1'b0;
        @(posedge clk); #1;
        expected_full   = {1'b0, 8'hFF} + {1'b0, 8'd1};
        expected_result = expected_full[N-1:0];
        expected_carry  = expected_full[N];
        if (result === expected_result && carry_out === expected_carry && result === 8'd0)
            $display("PASS: ADD max+1 (255+1=0, carry=1, zero_flag implied)");
        else begin
            $display("FAIL: ADD max+1 (255+1) got result=%0d carry=%0b, expected result=%0d carry=%0b",
                     result, carry_out, expected_result, expected_carry);
            fail_count = fail_count + 1;
        end

        //------------------------------------------------------------------
        // Test 9: SUB - Max - Max (255-255 => 0, carry=0, zero_flag)
        //------------------------------------------------------------------
        a = 8'hFF; b = 8'hFF; op = 1'b1;
        @(posedge clk); #1;
        expected_full   = {1'b0, 8'hFF} - {1'b0, 8'hFF};
        expected_result = expected_full[N-1:0];
        expected_carry  = expected_full[N];
        if (result === expected_result && carry_out === expected_carry && result === 8'd0)
            $display("PASS: SUB max-max (255-255=0, carry=0, zero_flag implied)");
        else begin
            $display("FAIL: SUB max-max (255-255) got result=%0d carry=%0b, expected result=%0d carry=%0b",
                     result, carry_out, expected_result, expected_carry);
            fail_count = fail_count + 1;
        end

        //------------------------------------------------------------------
        // Test 10: ADD - Typical mid-range values
        // a=128, b=127, op=0 => 255, carry=0
        //------------------------------------------------------------------
        a = 8'd128; b = 8'd127; op = 1'b0;
        @(posedge clk); #1;
        expected_full   = {1'b0, 8'd128} + {1'b0, 8'd127};
        expected_result = expected_full[N-1:0];
        expected_carry  = expected_full[N];
        if (result === expected_result && carry_out === expected_carry)
            $display("PASS: ADD mid-range (128+127=255, carry=0)");
        else begin
            $display("FAIL: ADD mid-range (128+127) got result=%0d carry=%0b, expected result=%0d carry=%0b",
                     result, carry_out, expected_result, expected_carry);
            fail_count = fail_count + 1;
        end

        //------------------------------------------------------------------
        // Test 11: SUB - a=0, b=1, borrow
        // a=0, b=1, op=1 => result=255, carry=1
        //------------------------------------------------------------------
        a = 8'd0; b = 8'd1; op = 1'b1;
        @(posedge clk); #1;
        expected_full   = {1'b0, 8'd0} - {1'b0, 8'd1};
        expected_result = expected_full[N-1:0];
        expected_carry  = expected_full[N];
        if (result === expected_result && carry_out === expected_carry)
            $display("PASS: SUB borrow (0-1=255, carry=1)");
        else begin
            $display("FAIL: SUB borrow (0-1) got result=%0d carry=%0b, expected result=%0d carry=%0b",
                     result, carry_out, expected_result, expected_carry);
            fail_count = fail_count + 1;
        end

        //------------------------------------------------------------------
        // Test 12: ADD - a=1, b=0
        //------------------------------------------------------------------
        a = 8'd1; b = 8'd0; op = 1'b0;
        @(posedge clk); #1;
        expected_full   = {1'b0, 8'd1} + {1'b0, 8'd0};
        expected_result = expected_full[N-1:0];
        expected_carry  = expected_full[N];
        if (result === expected_result && carry_out === expected_carry)
            $display("PASS: ADD one+zero (1+0=1, carry=0)");
        else begin
            $display("FAIL: ADD one+zero (1+0) got result=%0d carry=%0b, expected result=%0d carry=%0b",
                     result, carry_out, expected_result, expected_carry);
            fail_count = fail_count + 1;
        end

        //------------------------------------------------------------------
        // Summary
        //------------------------------------------------------------------
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
