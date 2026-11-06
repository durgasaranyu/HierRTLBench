`timescale 1ns/1ps

module tb_alu_logic;

    // Parameters
    parameter N = 8;

    // DUT connections
    reg  [N-1:0] a, b;
    reg  [1:0]   sel;
    wire [N-1:0] result;

    // Clock and reset (not used by DUT, but required by testbench rules)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Synchronous reset for 5 clock edges (not used by DUT but required)
    initial begin
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
    end

    // Instantiate DUT
    alu_logic #(.N(N)) uut (
        .a(a),
        .b(b),
        .sel(sel),
        .result(result)
    );

    // Expected result register
    reg [N-1:0] expected;
    integer fail_count;

    // Task to check result
    task check;
        input [N-1:0] exp;
        input [63:0]  test_num;
        input [127:0] desc;
        begin
            #1; // small delay for combinational settling
            if (result === exp) begin
                $display("PASS: Test %0d - %s | a=%h b=%h sel=%b result=%h (expected %h)",
                         test_num, desc, a, b, sel, result, exp);
            end else begin
                $display("FAIL: Test %0d - %s | a=%h b=%h sel=%b result=%h (expected %h)",
                         test_num, desc, a, b, sel, result, exp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        fail_count = 0;

        // Wait for reset to complete
        @(posedge clk); // wait for 1 extra cycle after reset

        // Note: The DUT as written has a peculiar implementation:
        // result = {sel==2'b00? a : b, sel==2'b01? a : b}
        // This concatenates two N-bit values into a 2N-bit value,
        // but result is only N-bit, so upper N bits are taken.
        // result[N-1:0] = upper N bits of concatenation = (sel==2'b00? a : b)
        // Actually in Verilog, the concatenation {X, Y} where X and Y are N-bit
        // gives 2N bits, and when assigned to N-bit result, the LOWER N bits are kept.
        // So result = (sel==2'b01? a : b)
        //
        // Let's verify this interpretation:
        // For sel=2'b00: result = (sel==2'b01? a : b) = b
        // For sel=2'b01: result = (sel==2'b01? a : b) = a
        // For sel=2'b10: result = (sel==2'b01? a : b) = b
        // For sel=2'b11: result = (sel==2'b01? a : b) = b

        // Test 1: sel=00 (should give b based on implementation analysis)
        @(posedge clk);
        a = 8'hAA; b = 8'h55; sel = 2'b00;
        #2;
        expected = b; // lower N bits of concat = second element = (sel==01?a:b) = b since sel!=01
        check(expected, 1, "sel=00 normal");

        // Test 2: sel=01 (should give a)
        @(posedge clk);
        a = 8'hAA; b = 8'h55; sel = 2'b01;
        #2;
        expected = a; // (sel==01?a:b) = a
        check(expected, 2, "sel=01 normal");

        // Test 3: sel=10 (should give b)
        @(posedge clk);
        a = 8'hAA; b = 8'h55; sel = 2'b10;
        #2;
        expected = b;
        check(expected, 3, "sel=10 normal");

        // Test 4: sel=11 (should give b)
        @(posedge clk);
        a = 8'hAA; b = 8'h55; sel = 2'b11;
        #2;
        expected = b;
        check(expected, 4, "sel=11 normal");

        // Test 5: All zeros
        @(posedge clk);
        a = 8'h00; b = 8'h00; sel = 2'b00;
        #2;
        expected = 8'h00;
        check(expected, 5, "sel=00 all zeros");

        // Test 6: All ones
        @(posedge clk);
        a = 8'hFF; b = 8'hFF; sel = 2'b01;
        #2;
        expected = 8'hFF;
        check(expected, 6, "sel=01 all ones");

        // Test 7: a=FF, b=00, sel=00 -> result=b=00
        @(posedge clk);
        a = 8'hFF; b = 8'h00; sel = 2'b00;
        #2;
        expected = 8'h00;
        check(expected, 7, "sel=00 a=FF b=00");

        // Test 8: a=00, b=FF, sel=01 -> result=a=00
        @(posedge clk);
        a = 8'h00; b = 8'hFF; sel = 2'b01;
        #2;
        expected = 8'h00;
        check(expected, 8, "sel=01 a=00 b=FF");

        // Test 9: a=5A, b=A5, sel=10 -> result=b=A5
        @(posedge clk);
        a = 8'h5A; b = 8'hA5; sel = 2'b10;
        #2;
        expected = 8'hA5;
        check(expected, 9, "sel=10 complement values");

        // Test 10: a=12, b=34, sel=11 -> result=b=34
        @(posedge clk);
        a = 8'h12; b = 8'h34; sel = 2'b11;
        #2;
        expected = 8'h34;
        check(expected, 10, "sel=11 misc values");

        // Summary
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
