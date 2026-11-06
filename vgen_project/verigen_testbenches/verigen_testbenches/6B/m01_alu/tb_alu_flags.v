`timescale 1ns / 1ps

module tb_alu_flags;

    // DUT connections
    reg  [7:0] result;
    reg        carry_in;
    wire       zero_flag;
    wire       carry_flag;

    // Clock and reset (included for completeness per requirements,
    // though this combinational module does not use them)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    alu_flags #(.N(8)) uut (
        .result(result),
        .carry_in(carry_in),
        .zero_flag(zero_flag),
        .carry_flag(carry_flag)
    );

    // Reset sequence: assert for 5 rising edges, then deassert
    integer i;
    initial begin
        rst = 1;
        result   = 8'h00;
        carry_in = 0;
        // Wait 5 rising edges
        for (i = 0; i < 5; i = i + 1) begin
            @(posedge clk);
        end
        rst = 0;

        // -------------------------------------------------------
        // Test 1: All-zero result, carry_in=0
        // Expect: zero_flag=1, carry_flag=0
        // -------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'h00;
        carry_in = 1'b0;
        #2;
        if (zero_flag === 1'b1 && carry_flag === 1'b0)
            $display("PASS: Test1 - zero result, no carry: zero_flag=1, carry_flag=0");
        else
            $display("FAIL: Test1 - zero result, no carry: zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 2: All-zero result, carry_in=1
        // Expect: zero_flag=1, carry_flag=1
        // -------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'h00;
        carry_in = 1'b1;
        #2;
        if (zero_flag === 1'b1 && carry_flag === 1'b1)
            $display("PASS: Test2 - zero result, carry_in=1: zero_flag=1, carry_flag=1");
        else
            $display("FAIL: Test2 - zero result, carry_in=1: zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 3: Non-zero result (ADD typical), carry_in=0
        // result = 8'h05 (ADD of two values, no overflow)
        // Expect: zero_flag=0, carry_flag=0
        // -------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'h05;
        carry_in = 1'b0;
        #2;
        if (zero_flag === 1'b0 && carry_flag === 1'b0)
            $display("PASS: Test3 - ADD normal (result=5, no carry): zero_flag=0, carry_flag=0");
        else
            $display("FAIL: Test3 - ADD normal (result=5, no carry): zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 4: ADD overflow - result wraps to non-zero, carry_in=1
        // Simulates 0xFF + 0x01 = 0x00 with carry
        // result = 8'h00, carry_in=1
        // Expect: zero_flag=1, carry_flag=1
        // -------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'h00;
        carry_in = 1'b1;
        #2;
        if (zero_flag === 1'b1 && carry_flag === 1'b1)
            $display("PASS: Test4 - ADD overflow (result=0, carry=1): zero_flag=1, carry_flag=1");
        else
            $display("FAIL: Test4 - ADD overflow (result=0, carry=1): zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 5: SUB result non-zero, no borrow
        // result = 8'h03 (e.g. 5 - 2), carry_in=0
        // Expect: zero_flag=0, carry_flag=0
        // -------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'h03;
        carry_in = 1'b0;
        #2;
        if (zero_flag === 1'b0 && carry_flag === 1'b0)
            $display("PASS: Test5 - SUB normal (result=3, no borrow): zero_flag=0, carry_flag=0");
        else
            $display("FAIL: Test5 - SUB normal (result=3, no borrow): zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 6: AND result zero
        // e.g. 0xAA AND 0x55 = 0x00, carry_in=0
        // Expect: zero_flag=1, carry_flag=0
        // -------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'h00;  // AND result
        carry_in = 1'b0;
        #2;
        if (zero_flag === 1'b1 && carry_flag === 1'b0)
            $display("PASS: Test6 - AND zero result: zero_flag=1, carry_flag=0");
        else
            $display("FAIL: Test6 - AND zero result: zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 7: SHL - MSB was 1 so carry_in=1, result non-zero
        // e.g. SHL 0x81 = 0x02, carry=1
        // result = 8'h02, carry_in=1
        // Expect: zero_flag=0, carry_flag=1
        // -------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'h02;
        carry_in = 1'b1;
        #2;
        if (zero_flag === 1'b0 && carry_flag === 1'b1)
            $display("PASS: Test7 - SHL MSB=1 (result=2, carry=1): zero_flag=0, carry_flag=1");
        else
            $display("FAIL: Test7 - SHL MSB=1 (result=2, carry=1): zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 8: All-ones result (OR/XOR), carry_in=0
        // result = 8'hFF, carry_in=0
        // Expect: zero_flag=0, carry_flag=0
        // -------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'hFF;
        carry_in = 1'b0;
        #2;
        if (zero_flag === 1'b0 && carry_flag === 1'b0)
            $display("PASS: Test8 - OR all-ones (result=FF, no carry): zero_flag=0, carry_flag=0");
        else
            $display("FAIL: Test8 - OR all-ones (result=FF, no carry): zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 9: XOR same operands -> result=0, carry_in=0
        // Expect: zero_flag=1, carry_flag=0
        // -------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'h00;
        carry_in = 1'b0;
        #2;
        if (zero_flag === 1'b1 && carry_flag === 1'b0)
            $display("PASS: Test9 - XOR same operands (result=0, no carry): zero_flag=1, carry_flag=0");
        else
            $display("FAIL: Test9 - XOR same operands (result=0, no carry): zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 10: SHL MSB=0, result non-zero, carry_in=0
        // e.g. SHL 0x41 = 0x82, carry=0
        // result=8'h82, carry_in=0
        // Expect: zero_flag=0, carry_flag=0
        // -------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'h82;
        carry_in = 1'b0;
        #2;
        if (zero_flag === 1'b0 && carry_flag === 1'b0)
            $display("PASS: Test10 - SHL MSB=0 (result=82, no carry): zero_flag=0, carry_flag=0");
        else
            $display("FAIL: Test10 - SHL MSB=0 (result=82, no carry): zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 11: Maximum value result with carry
        // result=8'hFF, carry_in=1
        // Expect: zero_flag=0, carry_flag=1
        // -------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'hFF;
        carry_in = 1'b1;
        #2;
        if (zero_flag === 1'b0 && carry_flag === 1'b1)
            $display("PASS: Test11 - Max result with carry: zero_flag=0, carry_flag=1");
        else
            $display("FAIL: Test11 - Max result with carry: zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 12: Verify reset behavior (combinational, inputs set to 0)
        // After driving result=0, carry_in=0 flags should reflect zero
        // -------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'h00;
        carry_in = 1'b0;
        rst      = 1;
        @(posedge clk); #1;
        rst = 0;
        #2;
        if (zero_flag === 1'b1 && carry_flag === 1'b0)
            $display("PASS: Test12 - After reset with zero inputs: zero_flag=1, carry_flag=0");
        else
            $display("FAIL: Test12 - After reset with zero inputs: zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        $finish;
    end

endmodule
