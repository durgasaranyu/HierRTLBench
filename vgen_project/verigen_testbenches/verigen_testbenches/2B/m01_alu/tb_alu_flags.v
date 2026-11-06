`timescale 1ns/1ps

module tb_alu_flags;

    // Parameters
    parameter N = 8;

    // DUT connections
    reg  [N-1:0] result;
    reg          carry_in;
    wire         zero_flag;
    wire         carry_flag;

    // Clock and reset (not used by DUT but required by general requirements)
    reg clk;
    reg rst;

    // Instantiate DUT
    alu_flags #(.N(N)) uut (
        .result   (result),
        .carry_in (carry_in),
        .zero_flag(zero_flag),
        .carry_flag(carry_flag)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset sequence (synchronous, 5 rising edges)
    initial begin
        rst = 1;
        repeat(5) @(posedge clk);
        @(negedge clk);
        rst = 0;
    end

    // Expected outputs
    reg exp_zero;
    reg exp_carry;

    // Helper task
    task check;
        input [63:0] test_num;
        input [8*64-1:0] desc;
        begin
            #1; // small delay for combinational settling
            if (zero_flag === exp_zero && carry_flag === exp_carry)
                $display("PASS: Test %0d - %s | result=%b carry_in=%b zero_flag=%b carry_flag=%b",
                         test_num, desc, result, carry_in, zero_flag, carry_flag);
            else
                $display("FAIL: Test %0d - %s | result=%b carry_in=%b | Expected zero=%b carry=%b Got zero=%b carry=%b",
                         test_num, desc, result, carry_in, exp_zero, exp_carry, zero_flag, carry_flag);
        end
    endtask

    integer i;

    initial begin
        // Wait for reset to complete
        @(negedge rst);
        @(negedge clk);

        // -------------------------------------------------------
        // Test 1: All-zero result, carry_in=0
        // zero_flag=1, carry_flag = 0 | (result[7] & ~zero_flag) = 0|(0&0) = 0
        result   = 8'b0000_0000;
        carry_in = 1'b0;
        exp_zero  = 1'b1;
        exp_carry = 1'b0;
        check(1, "All-zero result, carry_in=0");

        // Test 2: All-zero result, carry_in=1
        // zero_flag=1, carry_flag = 1 | (0 & 0) = 1
        result   = 8'b0000_0000;
        carry_in = 1'b1;
        exp_zero  = 1'b1;
        exp_carry = 1'b1;
        check(2, "All-zero result, carry_in=1");

        // Test 3: All-ones result, carry_in=0
        // zero_flag=0, carry_flag = 0 | (1 & 1) = 1
        result   = 8'b1111_1111;
        carry_in = 1'b0;
        exp_zero  = 1'b0;
        exp_carry = 1'b1;
        check(3, "All-ones result (ADD overflow/SHL MSB=1), carry_in=0");

        // Test 4: All-ones result, carry_in=1
        // zero_flag=0, carry_flag = 1 | (1&1) = 1
        result   = 8'b1111_1111;
        carry_in = 1'b1;
        exp_zero  = 1'b0;
        exp_carry = 1'b1;
        check(4, "All-ones result, carry_in=1");

        // Test 5: Non-zero result with MSB=0, carry_in=0 (e.g., ADD result = 0x05)
        // zero_flag=0, carry_flag = 0 | (0 & 1) = 0
        result   = 8'h05;
        carry_in = 1'b0;
        exp_zero  = 1'b0;
        exp_carry = 1'b0;
        check(5, "Normal ADD result 0x05, no carry");

        // Test 6: Non-zero result with MSB=0, carry_in=1 (ADD overflow carry only)
        // zero_flag=0, carry_flag = 1 | (0 & 1) = 1
        result   = 8'h05;
        carry_in = 1'b1;
        exp_zero  = 1'b0;
        exp_carry = 1'b1;
        check(6, "Normal result 0x05 with carry_in=1 (ADD overflow)");

        // Test 7: MSB=1 non-zero result, carry_in=0 (simulates SHL with MSB=1 in result)
        // result[7]=1, zero_flag=0 => carry_flag=0|(1&1)=1
        result   = 8'b1000_0001;
        carry_in = 1'b0;
        exp_zero  = 1'b0;
        exp_carry = 1'b1;
        check(7, "MSB=1 non-zero result (SHL MSB set), carry_in=0");

        // Test 8: SUB result = 0 (SUB with equal operands) carry_in=0
        result   = 8'h00;
        carry_in = 1'b0;
        exp_zero  = 1'b1;
        exp_carry = 1'b0;
        check(8, "SUB result=0 (equal operands), zero_flag asserted");

        // Test 9: AND result = 0 carry_in=0
        result   = 8'h00;
        carry_in = 1'b0;
        exp_zero  = 1'b1;
        exp_carry = 1'b0;
        check(9, "AND result=0, zero_flag asserted");

        // Test 10: OR result = 0xFF carry_in=0
        result   = 8'hFF;
        carry_in = 1'b0;
        exp_zero  = 1'b0;
        exp_carry = 1'b1;
        check(10, "OR result=0xFF, carry_flag from MSB");

        // Test 11: XOR result non-zero, MSB=0, carry_in=0
        result   = 8'h3C;
        carry_in = 1'b0;
        exp_zero  = 1'b0;
        exp_carry = 1'b0;
        check(11, "XOR result=0x3C, no flags");

        // Test 12: SHL result = 0 (all shifted out), carry_in=1 (MSB was 1 before shift)
        result   = 8'h00;
        carry_in = 1'b1;
        exp_zero  = 1'b1;
        exp_carry = 1'b1;
        check(12, "SHL result=0 zero_flag=1, carry_in=1 carry_flag=1");

        // Test 13: Maximum value 0x7F (MSB=0), no carry
        result   = 8'h7F;
        carry_in = 1'b0;
        exp_zero  = 1'b0;
        exp_carry = 1'b0;
        check(13, "Max positive 0x7F, MSB=0, no carry");

        // Test 14: Reset-like check — after applying zero inputs verify flags
        result   = {N{1'b0}};
        carry_in = 1'b0;
        exp_zero  = 1'b1;
        exp_carry = 1'b0;
        check(14, "Reset/clear outputs: zero result, no carry");

        @(posedge clk);
        $display("All tests complete.");
        $finish;
    end

endmodule
