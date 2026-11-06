`timescale 1ns/1ps

module tb_alu_flags;

    // Parameters
    parameter N = 8;

    // DUT inputs/outputs
    reg  [N-1:0] result;
    reg          carry_in;
    wire         zero_flag;
    wire         carry_flag;

    // Clock and reset (not used by this combinational module, but required by spec)
    reg clk;
    reg rst;

    // Instantiate DUT
    alu_flags #(.N(N)) uut (
        .result    (result),
        .carry_in  (carry_in),
        .zero_flag (zero_flag),
        .carry_flag(carry_flag)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Synchronous reset for 5 clock rising edges
    initial begin
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
    end

    // Expected values
    reg exp_zero;
    reg exp_carry;

    // Test procedure
    integer fail_count;

    initial begin
        fail_count = 0;

        // Wait for reset to deassert
        @(negedge rst);
        @(posedge clk); #1;

        // -----------------------------------------------------------------------
        // Test 1: ADD result = 0 (zero flag expected), carry_in = 0
        // result == 0 => zero_flag = 1
        // carry_flag = (result[7] == carry_in) | (result[7] == 1) = (0==0)|(0==1) = 1|0 = 1
        // -----------------------------------------------------------------------
        result   = 8'h00;
        carry_in = 1'b0;
        #2;
        exp_zero  = 1'b1;
        exp_carry = 1'b1; // (0==0) = 1
        if (zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test1 ADD result=0x00 carry_in=0 => zero=%b carry=%b", zero_flag, carry_flag);
        else begin
            $display("FAIL: Test1 ADD result=0x00 carry_in=0 => zero=%b(exp %b) carry=%b(exp %b)",
                     zero_flag, exp_zero, carry_flag, exp_carry);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------------
        // Test 2: ADD overflow - result MSB = 1, carry_in = 1 (ADD overflow scenario)
        // result = 8'hFF, carry_in = 1
        // zero_flag = 0 (result != 0)
        // carry_flag = (1==1)|(1==1) = 1
        // -----------------------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'hFF;
        carry_in = 1'b1;
        #2;
        exp_zero  = 1'b0;
        exp_carry = 1'b1;
        if (zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test2 ADD overflow result=0xFF carry_in=1 => zero=%b carry=%b", zero_flag, carry_flag);
        else begin
            $display("FAIL: Test2 ADD overflow result=0xFF carry_in=1 => zero=%b(exp %b) carry=%b(exp %b)",
                     zero_flag, exp_zero, carry_flag, exp_carry);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------------
        // Test 3: SUB result = 8'h05, carry_in = 0
        // zero_flag = 0
        // carry_flag = (result[7]==0)|(result[7]==1) = 0|0 = 0
        // -----------------------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'h05;
        carry_in = 1'b0;
        #2;
        exp_zero  = 1'b0;
        exp_carry = 1'b0;
        if (zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test3 SUB result=0x05 carry_in=0 => zero=%b carry=%b", zero_flag, carry_flag);
        else begin
            $display("FAIL: Test3 SUB result=0x05 carry_in=0 => zero=%b(exp %b) carry=%b(exp %b)",
                     zero_flag, exp_zero, carry_flag, exp_carry);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------------
        // Test 4: AND result = 8'h00, carry_in = 1
        // zero_flag = 1
        // carry_flag = (0==1)|(0==1) = 0|0 = 0
        // -----------------------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'h00;
        carry_in = 1'b1;
        #2;
        exp_zero  = 1'b1;
        exp_carry = 1'b0;
        if (zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test4 AND result=0x00 carry_in=1 => zero=%b carry=%b", zero_flag, carry_flag);
        else begin
            $display("FAIL: Test4 AND result=0x00 carry_in=1 => zero=%b(exp %b) carry=%b(exp %b)",
                     zero_flag, exp_zero, carry_flag, exp_carry);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------------
        // Test 5: OR result = 8'hAA, carry_in = 0
        // zero_flag = 0
        // carry_flag = (1==0)|(1==1) = 0|1 = 1 (MSB of 0xAA is 1)
        // -----------------------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'hAA;
        carry_in = 1'b0;
        #2;
        exp_zero  = 1'b0;
        exp_carry = 1'b1;
        if (zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test5 OR result=0xAA carry_in=0 => zero=%b carry=%b", zero_flag, carry_flag);
        else begin
            $display("FAIL: Test5 OR result=0xAA carry_in=0 => zero=%b(exp %b) carry=%b(exp %b)",
                     zero_flag, exp_zero, carry_flag, exp_carry);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------------
        // Test 6: XOR result = 8'h55, carry_in = 1
        // zero_flag = 0
        // carry_flag = (0==1)|(0==1) = 0|0 = 0 (MSB of 0x55 is 0)
        // -----------------------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'h55;
        carry_in = 1'b1;
        #2;
        exp_zero  = 1'b0;
        exp_carry = 1'b0;
        if (zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test6 XOR result=0x55 carry_in=1 => zero=%b carry=%b", zero_flag, carry_flag);
        else begin
            $display("FAIL: Test6 XOR result=0x55 carry_in=1 => zero=%b(exp %b) carry=%b(exp %b)",
                     zero_flag, exp_zero, carry_flag, exp_carry);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------------
        // Test 7: SHL MSB was 1 => result MSB=1, carry_in = 1 (indicating MSB was 1 before shift)
        // result = 8'h82 (MSB=1), carry_in = 1
        // zero_flag = 0
        // carry_flag = (1==1)|(1==1) = 1
        // -----------------------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'h82;
        carry_in = 1'b1;
        #2;
        exp_zero  = 1'b0;
        exp_carry = 1'b1;
        if (zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test7 SHL result=0x82 carry_in=1 => zero=%b carry=%b", zero_flag, carry_flag);
        else begin
            $display("FAIL: Test7 SHL result=0x82 carry_in=1 => zero=%b(exp %b) carry=%b(exp %b)",
                     zero_flag, exp_zero, carry_flag, exp_carry);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------------
        // Test 8: SHL result when MSB was 0, carry_in = 0
        // result = 8'h04 (MSB=0), carry_in = 0
        // zero_flag = 0
        // carry_flag = (0==0)|(0==1) = 1|0 = 1
        // -----------------------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'h04;
        carry_in = 1'b0;
        #2;
        exp_zero  = 1'b0;
        exp_carry = 1'b1; // (result[7]==carry_in) = (0==0) = 1
        if (zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test8 SHL result=0x04 carry_in=0 => zero=%b carry=%b", zero_flag, carry_flag);
        else begin
            $display("FAIL: Test8 SHL result=0x04 carry_in=0 => zero=%b(exp %b) carry=%b(exp %b)",
                     zero_flag, exp_zero, carry_flag, exp_carry);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------------
        // Test 9: All-ones result, carry_in = 0
        // result = 8'hFF, carry_in = 0
        // zero_flag = 0
        // carry_flag = (1==0)|(1==1) = 0|1 = 1
        // -----------------------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'hFF;
        carry_in = 1'b0;
        #2;
        exp_zero  = 1'b0;
        exp_carry = 1'b1;
        if (zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test9 all-ones result=0xFF carry_in=0 => zero=%b carry=%b", zero_flag, carry_flag);
        else begin
            $display("FAIL: Test9 all-ones result=0xFF carry_in=0 => zero=%b(exp %b) carry=%b(exp %b)",
                     zero_flag, exp_zero, carry_flag, exp_carry);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------------
        // Test 10: Max value result = 8'h7F, carry_in = 1
        // zero_flag = 0
        // carry_flag = (0==1)|(0==1) = 0|0 = 0
        // -----------------------------------------------------------------------
        @(posedge clk); #1;
        result   = 8'h7F;
        carry_in = 1'b1;
        #2;
        exp_zero  = 1'b0;
        exp_carry = 1'b0;
        if (zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test10 max result=0x7F carry_in=1 => zero=%b carry=%b", zero_flag, carry_flag);
        else begin
            $display("FAIL: Test10 max result=0x7F carry_in=1 => zero=%b(exp %b) carry=%b(exp %b)",
                     zero_flag, exp_zero, carry_flag, exp_carry);
            fail_count = fail_count + 1;
        end

        // Summary
        @(posedge clk); #1;
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
