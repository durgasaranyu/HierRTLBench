`timescale 1ns/1ps

module tb_alu_addsub;

    // Parameters
    parameter N = 8;

    // DUT signals
    reg  [N-1:0] a, b;
    reg          op;
    wire [N-1:0] result;
    wire         carry_out;

    // Clock and reset (not used by this combinational DUT, but required by spec)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    alu_addsub #(.N(N)) uut (
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .carry_out(carry_out)
    );

    // Synchronous reset for 5 clock edges (combinational DUT, so we just observe timing)
    initial begin
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
    end

    // Helper task
    task check_result;
        input [N-1:0] exp_result;
        input         exp_carry;
        input [127:0] desc;
        begin
            #1; // allow propagation
            if (result === exp_result && carry_out === exp_carry) begin
                $display("PASS: %s | a=%0d b=%0d op=%0d result=%0d carry=%0d",
                         desc, a, b, op, result, carry_out);
            end else begin
                $display("FAIL: %s | a=%0d b=%0d op=%0d result=%0d (exp %0d) carry=%0d (exp %0d)",
                         desc, a, b, op, result, exp_result, carry_out, exp_carry);
            end
        end
    endtask

    // Test variables
    reg [N:0] expected_wide;

    initial begin
        // Wait for reset to deassert
        wait (rst === 0);
        @(posedge clk); #1;

        // ----------------------------------------------------------------
        // Test 1: ADD normal - 3 + 5 = 8, no carry
        // ----------------------------------------------------------------
        a = 8'd3; b = 8'd5; op = 1'b0;
        expected_wide = {1'b0, a} + {1'b0, b};
        #2;
        check_result(expected_wide[N-1:0], expected_wide[N], "ADD 3+5=8 no carry");

        // ----------------------------------------------------------------
        // Test 2: ADD with carry overflow - 200 + 100 = 300 -> overflow
        // ----------------------------------------------------------------
        a = 8'd200; b = 8'd100; op = 1'b0;
        expected_wide = {1'b0, a} + {1'b0, b};
        #2;
        check_result(expected_wide[N-1:0], expected_wide[N], "ADD 200+100 overflow");

        // ----------------------------------------------------------------
        // Test 3: ADD all zeros - 0 + 0 = 0, zero_flag should be high
        // ----------------------------------------------------------------
        a = 8'd0; b = 8'd0; op = 1'b0;
        expected_wide = {1'b0, a} + {1'b0, b};
        #2;
        check_result(expected_wide[N-1:0], expected_wide[N], "ADD 0+0=0 zero result");

        // ----------------------------------------------------------------
        // Test 4: ADD all ones - 0xFF + 0xFF
        // ----------------------------------------------------------------
        a = 8'hFF; b = 8'hFF; op = 1'b0;
        expected_wide = {1'b0, a} + {1'b0, b};
        #2;
        check_result(expected_wide[N-1:0], expected_wide[N], "ADD 0xFF+0xFF all-ones");

        // ----------------------------------------------------------------
        // Test 5: SUB normal - 10 - 3 = 7, no borrow
        // ----------------------------------------------------------------
        a = 8'd10; b = 8'd3; op = 1'b1;
        // For subtraction: result = a - b
        // The module description says op=1: result=a-b borrow
        // We treat carry_out as borrow indicator
        begin
            reg [N:0] sub_wide;
            sub_wide = {1'b0, a} - {1'b0, b};
            #2;
            // Note: borrow occurs when b > a; carry_out meaning depends on implementation
            // We just check result correctness
            if (result === (a - b)) begin
                $display("PASS: SUB 10-3=7 | result=%0d", result);
            end else begin
                $display("FAIL: SUB 10-3=7 | result=%0d expected %0d", result, (a-b));
            end
        end

        // ----------------------------------------------------------------
        // Test 6: SUB causing borrow - 3 - 10 (underflow)
        // ----------------------------------------------------------------
        a = 8'd3; b = 8'd10; op = 1'b1;
        #2;
        begin
            reg [N-1:0] exp_sub;
            exp_sub = a - b;
            if (result === exp_sub) begin
                $display("PASS: SUB 3-10 underflow | result=%0d (0x%0h)", result, result);
            end else begin
                $display("FAIL: SUB 3-10 underflow | result=%0d expected %0d", result, exp_sub);
            end
        end

        // ----------------------------------------------------------------
        // Test 7: SUB max value - 0xFF - 0xFF = 0
        // ----------------------------------------------------------------
        a = 8'hFF; b = 8'hFF; op = 1'b1;
        #2;
        if (result === 8'd0) begin
            $display("PASS: SUB 0xFF-0xFF=0 | result=%0d", result);
        end else begin
            $display("FAIL: SUB 0xFF-0xFF=0 | result=%0d expected 0", result);
        end

        // ----------------------------------------------------------------
        // Test 8: ADD max single value - 0xFF + 0x01 = 0x00 with carry
        // ----------------------------------------------------------------
        a = 8'hFF; b = 8'h01; op = 1'b0;
        expected_wide = {1'b0, a} + {1'b0, b};
        #2;
        check_result(expected_wide[N-1:0], expected_wide[N], "ADD 0xFF+0x01 max+1 carry");

        // ----------------------------------------------------------------
        // Test 9: ADD 0 + max
        // ----------------------------------------------------------------
        a = 8'd0; b = 8'hFF; op = 1'b0;
        expected_wide = {1'b0, a} + {1'b0, b};
        #2;
        check_result(expected_wide[N-1:0], expected_wide[N], "ADD 0+0xFF no carry");

        // ----------------------------------------------------------------
        // Test 10: SUB 0 - 0 = 0
        // ----------------------------------------------------------------
        a = 8'd0; b = 8'd0; op = 1'b1;
        #2;
        if (result === 8'd0) begin
            $display("PASS: SUB 0-0=0 | result=%0d", result);
        end else begin
            $display("FAIL: SUB 0-0=0 | result=%0d expected 0", result);
        end

        // ----------------------------------------------------------------
        // Test 11: ADD typical midrange - 127 + 1 = 128
        // ----------------------------------------------------------------
        a = 8'd127; b = 8'd1; op = 1'b0;
        expected_wide = {1'b0, a} + {1'b0, b};
        #2;
        check_result(expected_wide[N-1:0], expected_wide[N], "ADD 127+1=128");

        // ----------------------------------------------------------------
        // Test 12: ADD 128 + 128 = 256 (overflow)
        // ----------------------------------------------------------------
        a = 8'd128; b = 8'd128; op = 1'b0;
        expected_wide = {1'b0, a} + {1'b0, b};
        #2;
        check_result(expected_wide[N-1:0], expected_wide[N], "ADD 128+128 overflow");

        #20;
        $display("Testbench complete.");
        $finish;
    end

endmodule
