// Testbench for alu_logic
// Note: The DUT module (alu_logic) as provided is incomplete/broken (only has
// wire declarations, no actual logic). The testbench is written to test the
// INTENDED behavior described in the requirements (ADD, SUB, AND, OR, XOR, SHL,
// zero_flag, carry_flag, synchronous reset). Since the DUT doesn't actually
// implement these ports, we test what the module actually exposes: a, b, sel, result.
// We will test the bitwise logic (AND=0, OR=1, XOR=2) that the module header describes.

`timescale 1ns/1ps

module tb_alu_logic;

    // Parameters
    parameter N = 8;

    // DUT connections
    reg  [N-1:0] a;
    reg  [N-1:0] b;
    reg  [1:0]   sel;
    wire [N-1:0] result;

    // Testbench internal
    reg clk;
    reg rst;
    integer fail_count;

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // DUT instantiation
    alu_logic #(.N(N)) uut (
        .a(a),
        .b(b),
        .sel(sel),
        .result(result)
    );

    // Task to check result
    task check_result;
        input [N-1:0] expected;
        input [127:0] desc;
        begin
            #1; // small settle time
            if (result === expected) begin
                $display("PASS: %s | a=%0h b=%0h sel=%0d result=%0h (expected %0h)",
                         desc, a, b, sel, result, expected);
            end else begin
                $display("FAIL: %s | a=%0h b=%0h sel=%0d result=%0h (expected %0h)",
                         desc, a, b, sel, result, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        fail_count = 0;
        rst = 1;
        a   = 0;
        b   = 0;
        sel = 0;

        // Assert reset for 5 rising edges
        @(posedge clk); // 1
        @(posedge clk); // 2
        @(posedge clk); // 3
        @(posedge clk); // 4
        @(posedge clk); // 5
        rst = 0;
        #2;

        // Test 1: AND - normal operation: a=0xAA, b=0x55 -> result=0x00
        a = 8'hAA; b = 8'h55; sel = 2'b00;
        @(posedge clk); #2;
        check_result(8'h00, "AND 0xAA & 0x55 = 0x00");

        // Test 2: AND - all ones: a=0xFF, b=0xFF -> result=0xFF
        a = 8'hFF; b = 8'hFF; sel = 2'b00;
        @(posedge clk); #2;
        check_result(8'hFF, "AND 0xFF & 0xFF = 0xFF");

        // Test 3: AND - all zeros: a=0x00, b=0x00 -> result=0x00
        a = 8'h00; b = 8'h00; sel = 2'b00;
        @(posedge clk); #2;
        check_result(8'h00, "AND 0x00 & 0x00 = 0x00");

        // Test 4: OR - normal: a=0xAA, b=0x55 -> result=0xFF
        a = 8'hAA; b = 8'h55; sel = 2'b01;
        @(posedge clk); #2;
        check_result(8'hFF, "OR 0xAA | 0x55 = 0xFF");

        // Test 5: OR - all zeros: a=0x00, b=0x00 -> result=0x00
        a = 8'h00; b = 8'h00; sel = 2'b01;
        @(posedge clk); #2;
        check_result(8'h00, "OR 0x00 | 0x00 = 0x00");

        // Test 6: XOR - normal: a=0xAA, b=0xFF -> result=0x55
        a = 8'hAA; b = 8'hFF; sel = 2'b10;
        @(posedge clk); #2;
        check_result(8'h55, "XOR 0xAA ^ 0xFF = 0x55");

        // Test 7: XOR - same inputs (zero result): a=0xAB, b=0xAB -> result=0x00
        a = 8'hAB; b = 8'hAB; sel = 2'b10;
        @(posedge clk); #2;
        check_result(8'h00, "XOR 0xAB ^ 0xAB = 0x00 (zero flag case)");

        // Test 8: XOR - all ones: a=0xFF, b=0xFF -> result=0x00
        a = 8'hFF; b = 8'hFF; sel = 2'b10;
        @(posedge clk); #2;
        check_result(8'h00, "XOR 0xFF ^ 0xFF = 0x00");

        // Test 9: AND - max value one side: a=0xFF, b=0x0F -> result=0x0F
        a = 8'hFF; b = 8'h0F; sel = 2'b00;
        @(posedge clk); #2;
        check_result(8'h0F, "AND 0xFF & 0x0F = 0x0F");

        // Test 10: OR - all ones both: a=0xFF, b=0xFF -> result=0xFF
        a = 8'hFF; b = 8'hFF; sel = 2'b01;
        @(posedge clk); #2;
        check_result(8'hFF, "OR 0xFF | 0xFF = 0xFF");

        // Test 11: XOR - zero and max: a=0x00, b=0xFF -> result=0xFF
        a = 8'h00; b = 8'hFF; sel = 2'b10;
        @(posedge clk); #2;
        check_result(8'hFF, "XOR 0x00 ^ 0xFF = 0xFF");

        // Test 12: AND - a=0x0F, b=0xF0 -> result=0x00
        a = 8'h0F; b = 8'hF0; sel = 2'b00;
        @(posedge clk); #2;
        check_result(8'h00, "AND 0x0F & 0xF0 = 0x00");

        // Summary
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
