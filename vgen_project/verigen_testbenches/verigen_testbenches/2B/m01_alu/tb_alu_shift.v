`timescale 1ns/1ps

module tb_alu_shift;

    // Parameters
    parameter N = 8;

    // DUT connections
    reg  [N-1:0] a;
    wire [N-1:0] result;
    wire         carry_out;

    // Instantiate DUT
    alu_shift #(.N(N)) uut (
        .a(a),
        .result(result),
        .carry_out(carry_out)
    );

    // Expected values
    reg [N-1:0] exp_result;
    reg         exp_carry;

    // Clock and reset (included for completeness per requirements,
    // though alu_shift is combinational)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Synchronous reset applied for 5 rising edges then deasserted
    integer i;
    initial begin
        rst = 1;
        for (i = 0; i < 5; i = i + 1) begin
            @(posedge clk);
        end
        rst = 0;
    end

    // Test procedure
    integer fail_count;

    initial begin
        fail_count = 0;
        a = 0;

        // Wait for reset to complete (5 rising edges)
        @(posedge clk); // 1
        @(posedge clk); // 2
        @(posedge clk); // 3
        @(posedge clk); // 4
        @(posedge clk); // 5
        @(posedge clk); // one more after deassertion

        // -----------------------------------------------------------------
        // Test 1: All-zero input
        // SHL(0) => result=0, carry=0
        // -----------------------------------------------------------------
        a = 8'b0000_0000;
        #2;
        exp_result = 8'b0000_0000;
        exp_carry  = 1'b0;
        if (result === exp_result && carry_out === exp_carry)
            $display("PASS: SHL(0x00) => result=0x00, carry=0");
        else begin
            $display("FAIL: SHL(0x00) => result=%0h (exp %0h), carry=%b (exp %b)",
                     result, exp_result, carry_out, exp_carry);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 2: All-ones input (0xFF)
        // SHL(0xFF) => result=0xFE, carry=1
        // -----------------------------------------------------------------
        @(posedge clk);
        a = 8'b1111_1111;
        #2;
        exp_result = 8'b1111_1110;
        exp_carry  = 1'b1;
        if (result === exp_result && carry_out === exp_carry)
            $display("PASS: SHL(0xFF) => result=0xFE, carry=1");
        else begin
            $display("FAIL: SHL(0xFF) => result=%0h (exp %0h), carry=%b (exp %b)",
                     result, exp_result, carry_out, exp_carry);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 3: MSB=1, rest=0 => result=0 (zero result), carry=1
        // -----------------------------------------------------------------
        @(posedge clk);
        a = 8'b1000_0000;
        #2;
        exp_result = 8'b0000_0000;
        exp_carry  = 1'b1;
        if (result === exp_result && carry_out === exp_carry)
            $display("PASS: SHL(0x80) => result=0x00 (zero result), carry=1");
        else begin
            $display("FAIL: SHL(0x80) => result=%0h (exp %0h), carry=%b (exp %b)",
                     result, exp_result, carry_out, exp_carry);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 4: MSB=0, LSB=1 => no carry, result shifts
        // SHL(0x01) => result=0x02, carry=0
        // -----------------------------------------------------------------
        @(posedge clk);
        a = 8'b0000_0001;
        #2;
        exp_result = 8'b0000_0010;
        exp_carry  = 1'b0;
        if (result === exp_result && carry_out === exp_carry)
            $display("PASS: SHL(0x01) => result=0x02, carry=0");
        else begin
            $display("FAIL: SHL(0x01) => result=%0h (exp %0h), carry=%b (exp %b)",
                     result, exp_result, carry_out, exp_carry);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 5: Typical value 0xA5 (1010_0101)
        // SHL(0xA5) => 0x4A (0100_1010), carry=1 (MSB was 1)
        // -----------------------------------------------------------------
        @(posedge clk);
        a = 8'b1010_0101;
        #2;
        exp_result = 8'b0100_1010;
        exp_carry  = 1'b1;
        if (result === exp_result && carry_out === exp_carry)
            $display("PASS: SHL(0xA5) => result=0x4A, carry=1");
        else begin
            $display("FAIL: SHL(0xA5) => result=%0h (exp %0h), carry=%b (exp %b)",
                     result, exp_result, carry_out, exp_carry);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 6: Value 0x55 (0101_0101), MSB=0
        // SHL(0x55) => 0xAA (1010_1010), carry=0
        // -----------------------------------------------------------------
        @(posedge clk);
        a = 8'b0101_0101;
        #2;
        exp_result = 8'b1010_1010;
        exp_carry  = 1'b0;
        if (result === exp_result && carry_out === exp_carry)
            $display("PASS: SHL(0x55) => result=0xAA, carry=0");
        else begin
            $display("FAIL: SHL(0x55) => result=%0h (exp %0h), carry=%b (exp %b)",
                     result, exp_result, carry_out, exp_carry);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 7: Value 0x3C (0011_1100)
        // SHL(0x3C) => 0x78 (0111_1000), carry=0
        // -----------------------------------------------------------------
        @(posedge clk);
        a = 8'b0011_1100;
        #2;
        exp_result = 8'b0111_1000;
        exp_carry  = 1'b0;
        if (result === exp_result && carry_out === exp_carry)
            $display("PASS: SHL(0x3C) => result=0x78, carry=0");
        else begin
            $display("FAIL: SHL(0x3C) => result=%0h (exp %0h), carry=%b (exp %b)",
                     result, exp_result, carry_out, exp_carry);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 8: Maximum value 0xFE (1111_1110)
        // SHL(0xFE) => 0xFC (1111_1100), carry=1
        // -----------------------------------------------------------------
        @(posedge clk);
        a = 8'b1111_1110;
        #2;
        exp_result = 8'b1111_1100;
        exp_carry  = 1'b1;
        if (result === exp_result && carry_out === exp_carry)
            $display("PASS: SHL(0xFE) => result=0xFC, carry=1");
        else begin
            $display("FAIL: SHL(0xFE) => result=%0h (exp %0h), carry=%b (exp %b)",
                     result, exp_result, carry_out, exp_carry);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 9: Value 0x7F (0111_1111), MSB=0
        // SHL(0x7F) => 0xFE (1111_1110), carry=0
        // -----------------------------------------------------------------
        @(posedge clk);
        a = 8'b0111_1111;
        #2;
        exp_result = 8'b1111_1110;
        exp_carry  = 1'b0;
        if (result === exp_result && carry_out === exp_carry)
            $display("PASS: SHL(0x7F) => result=0xFE, carry=0");
        else begin
            $display("FAIL: SHL(0x7F) => result=%0h (exp %0h), carry=%b (exp %b)",
                     result, exp_result, carry_out, exp_carry);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Summary
        // -----------------------------------------------------------------
        @(posedge clk);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TOTAL FAILURES: %0d", fail_count);

        $finish;
    end

endmodule
