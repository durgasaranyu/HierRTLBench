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
    reg [N-1:0] expected_result;
    reg         expected_carry;

    integer pass_count;
    integer fail_count;

    // Note: This module is purely combinational (no clock/reset).
    // We will still follow the testbench structure requirements.

    // Clock (required by template, module is combinational)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset signal (required by template, module has no reset port)
    reg rst;
    initial rst = 0;

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Assert synchronous reset for 5 rising edges (structural requirement)
        rst = 1;
        @(posedge clk); // 1
        @(posedge clk); // 2
        @(posedge clk); // 3
        @(posedge clk); // 4
        @(posedge clk); // 5
        rst = 0;
        #2; // small settle time

        // -------------------------------------------------------
        // Test 1: All-zero input
        // -------------------------------------------------------
        a = 8'b0000_0000;
        #10;
        expected_result = 8'b0000_0000;
        expected_carry  = 1'b0;
        if (result === expected_result && carry_out === expected_carry) begin
            $display("PASS: SHL all-zeros: a=0x%02h, result=0x%02h, carry=%b", a, result, carry_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: SHL all-zeros: a=0x%02h, result=0x%02h (exp 0x%02h), carry=%b (exp %b)",
                     a, result, expected_result, carry_out, expected_carry);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 2: All-ones input (carry_out=1, result=0xFE)
        // -------------------------------------------------------
        a = 8'b1111_1111;
        #10;
        expected_result = 8'b1111_1110;
        expected_carry  = 1'b1;
        if (result === expected_result && carry_out === expected_carry) begin
            $display("PASS: SHL all-ones: a=0x%02h, result=0x%02h, carry=%b", a, result, carry_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: SHL all-ones: a=0x%02h, result=0x%02h (exp 0x%02h), carry=%b (exp %b)",
                     a, result, expected_result, carry_out, expected_carry);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 3: MSB=1, rest zero (carry=1, result=0)
        // -------------------------------------------------------
        a = 8'b1000_0000;
        #10;
        expected_result = 8'b0000_0000;
        expected_carry  = 1'b1;
        if (result === expected_result && carry_out === expected_carry) begin
            $display("PASS: SHL MSB-only: a=0x%02h, result=0x%02h, carry=%b", a, result, carry_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: SHL MSB-only: a=0x%02h, result=0x%02h (exp 0x%02h), carry=%b (exp %b)",
                     a, result, expected_result, carry_out, expected_carry);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 4: LSB=1 only (carry=0, result=0x02)
        // -------------------------------------------------------
        a = 8'b0000_0001;
        #10;
        expected_result = 8'b0000_0010;
        expected_carry  = 1'b0;
        if (result === expected_result && carry_out === expected_carry) begin
            $display("PASS: SHL LSB-only: a=0x%02h, result=0x%02h, carry=%b", a, result, carry_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: SHL LSB-only: a=0x%02h, result=0x%02h (exp 0x%02h), carry=%b (exp %b)",
                     a, result, expected_result, carry_out, expected_carry);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 5: Typical value 0xA5 (1010_0101)
        // -------------------------------------------------------
        a = 8'hA5; // 1010_0101
        #10;
        expected_result = 8'h4A; // 0100_1010
        expected_carry  = 1'b1;
        if (result === expected_result && carry_out === expected_carry) begin
            $display("PASS: SHL 0xA5: a=0x%02h, result=0x%02h, carry=%b", a, result, carry_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: SHL 0xA5: a=0x%02h, result=0x%02h (exp 0x%02h), carry=%b (exp %b)",
                     a, result, expected_result, carry_out, expected_carry);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 6: Value 0x55 (0101_0101) - no carry
        // -------------------------------------------------------
        a = 8'h55; // 0101_0101
        #10;
        expected_result = 8'hAA; // 1010_1010
        expected_carry  = 1'b0;
        if (result === expected_result && carry_out === expected_carry) begin
            $display("PASS: SHL 0x55: a=0x%02h, result=0x%02h, carry=%b", a, result, carry_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: SHL 0x55: a=0x%02h, result=0x%02h (exp 0x%02h), carry=%b (exp %b)",
                     a, result, expected_result, carry_out, expected_carry);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 7: Maximum value 0xFF (same as all-ones check, but verify zero_flag concept)
        //         result = 0xFE, carry=1, result!=0 so no zero condition
        // -------------------------------------------------------
        a = 8'hFF;
        #10;
        expected_result = 8'hFE;
        expected_carry  = 1'b1;
        if (result === expected_result && carry_out === expected_carry) begin
            $display("PASS: SHL max 0xFF: a=0x%02h, result=0x%02h, carry=%b", a, result, carry_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: SHL max 0xFF: a=0x%02h, result=0x%02h (exp 0x%02h), carry=%b (exp %b)",
                     a, result, expected_result, carry_out, expected_carry);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 8: Zero result check (a=0x80 -> result=0, carry=1)
        //         Verifying zero flag would be (result==0)
        // -------------------------------------------------------
        a = 8'h80;
        #10;
        expected_result = 8'h00;
        expected_carry  = 1'b1;
        if (result === expected_result && carry_out === expected_carry && (result == 8'h00)) begin
            $display("PASS: SHL zero-result (0x80): a=0x%02h, result=0x%02h, carry=%b, zero=%b",
                     a, result, carry_out, (result == 8'h00));
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: SHL zero-result (0x80): a=0x%02h, result=0x%02h (exp 0x%02h), carry=%b (exp %b)",
                     a, result, expected_result, carry_out, expected_carry);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 9: Typical mid-range value 0x3C (0011_1100)
        // -------------------------------------------------------
        a = 8'h3C; // 0011_1100
        #10;
        expected_result = 8'h78; // 0111_1000
        expected_carry  = 1'b0;
        if (result === expected_result && carry_out === expected_carry) begin
            $display("PASS: SHL 0x3C: a=0x%02h, result=0x%02h, carry=%b", a, result, carry_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: SHL 0x3C: a=0x%02h, result=0x%02h (exp 0x%02h), carry=%b (exp %b)",
                     a, result, expected_result, carry_out, expected_carry);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 10: Value 0xC0 (1100_0000) - carry=1, result=0x80
        // -------------------------------------------------------
        a = 8'hC0; // 1100_0000
        #10;
        expected_result = 8'h80; // 1000_0000
        expected_carry  = 1'b1;
        if (result === expected_result && carry_out === expected_carry) begin
            $display("PASS: SHL 0xC0: a=0x%02h, result=0x%02h, carry=%b", a, result, carry_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: SHL 0xC0: a=0x%02h, result=0x%02h (exp 0x%02h), carry=%b (exp %b)",
                     a, result, expected_result, carry_out, expected_carry);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        #10;
        $display("--------------------------------------------------");
        $display("Simulation complete: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("--------------------------------------------------");

        $finish;
    end

endmodule
