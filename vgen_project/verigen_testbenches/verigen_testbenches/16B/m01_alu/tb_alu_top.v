`timescale 1ns/1ps

module tb_alu_top;

    // Parameters
    parameter N = 8;

    // DUT connections
    reg             clk;
    reg             rst;
    reg  [N-1:0]    a;
    reg  [N-1:0]    b;
    reg  [2:0]      op;
    wire [N-1:0]    result;
    wire            zero_flag;
    wire            carry_flag;

    // Instantiate DUT
    alu #(.N(N)) uut (
        .clk       (clk),
        .rst       (rst),
        .a         (a),
        .b         (b),
        .op        (op),
        .result    (result),
        .zero_flag (zero_flag),
        .carry_flag(carry_flag)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Task: apply inputs and wait one clock, then check
    task apply_and_check;
        input [N-1:0]   t_a;
        input [N-1:0]   t_b;
        input [2:0]     t_op;
        input [N-1:0]   exp_result;
        input           exp_zero;
        input           exp_carry;
        input [63:0]    desc_code; // used as an ID
        begin
            a  = t_a;
            b  = t_b;
            op = t_op;
            @(posedge clk);
            #1; // small delay after clock edge for output to settle
        end
    endtask

    integer fail_count;

    // Expected computation helpers
    reg [N:0]   add_full;
    reg [N-1:0] exp_res;
    reg         exp_zero_f;
    reg         exp_carry_f;

    initial begin
        fail_count = 0;

        // Initialize
        rst = 1;
        a   = 0;
        b   = 0;
        op  = 3'b000;

        // Assert reset for 5 rising edges
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        #1;

        // Check reset state
        if (result === {N{1'b0}} && zero_flag === 1'b0 && carry_flag === 1'b0) begin
            $display("PASS: Synchronous reset clears all outputs");
        end else begin
            $display("FAIL: Synchronous reset clears all outputs (result=%0h, zero=%b, carry=%b)",
                     result, zero_flag, carry_flag);
            fail_count = fail_count + 1;
        end

        // Deassert reset
        rst = 0;

        // -----------------------------------------------------------------
        // Test 1: ADD normal  5 + 3 = 8, no carry, not zero
        // -----------------------------------------------------------------
        a  = 8'd5;
        b  = 8'd3;
        op = 3'b000; // ADD
        @(posedge clk); #1;
        exp_res   = 8'd8;
        exp_zero_f  = 1'b0;
        exp_carry_f = 1'b0;
        if (result === exp_res && zero_flag === exp_zero_f && carry_flag === exp_carry_f)
            $display("PASS: ADD 5+3=8, no carry, not zero");
        else begin
            $display("FAIL: ADD 5+3 (result=%0h, zero=%b, carry=%b)", result, zero_flag, carry_flag);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 2: ADD with overflow  255 + 1 = 0, carry=1, zero=1
        // -----------------------------------------------------------------
        a  = 8'd255;
        b  = 8'd1;
        op = 3'b000; // ADD
        @(posedge clk); #1;
        exp_res   = 8'd0;
        exp_zero_f  = 1'b1;
        exp_carry_f = 1'b1;
        if (result === exp_res && zero_flag === exp_zero_f && carry_flag === exp_carry_f)
            $display("PASS: ADD 255+1 overflow carry=1 zero=1");
        else begin
            $display("FAIL: ADD 255+1 (result=%0h, zero=%b, carry=%b)", result, zero_flag, carry_flag);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 3: SUB  10 - 3 = 7, no carry, not zero
        // -----------------------------------------------------------------
        a  = 8'd10;
        b  = 8'd3;
        op = 3'b001; // SUB
        @(posedge clk); #1;
        exp_res   = 8'd7;
        exp_zero_f  = 1'b0;
        exp_carry_f = 1'b0;
        if (result === exp_res && zero_flag === exp_zero_f)
            $display("PASS: SUB 10-3=7, not zero");
        else begin
            $display("FAIL: SUB 10-3 (result=%0h, zero=%b, carry=%b)", result, zero_flag, carry_flag);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 4: AND  0xAA & 0x55 = 0x00, zero flag=1
        // -----------------------------------------------------------------
        a  = 8'hAA;
        b  = 8'h55;
        op = 3'b010; // AND
        @(posedge clk); #1;
        exp_res   = 8'h00;
        exp_zero_f  = 1'b1;
        if (result === exp_res && zero_flag === exp_zero_f)
            $display("PASS: AND 0xAA & 0x55 = 0x00, zero=1");
        else begin
            $display("FAIL: AND 0xAA & 0x55 (result=%0h, zero=%b)", result, zero_flag);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 5: OR  0xAA | 0x55 = 0xFF, zero=0
        // -----------------------------------------------------------------
        a  = 8'hAA;
        b  = 8'h55;
        op = 3'b011; // OR
        @(posedge clk); #1;
        exp_res   = 8'hFF;
        exp_zero_f  = 1'b0;
        if (result === exp_res && zero_flag === exp_zero_f)
            $display("PASS: OR 0xAA | 0x55 = 0xFF, zero=0");
        else begin
            $display("FAIL: OR 0xAA | 0x55 (result=%0h, zero=%b)", result, zero_flag);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 6: XOR  0xFF ^ 0xFF = 0x00, zero=1
        // -----------------------------------------------------------------
        a  = 8'hFF;
        b  = 8'hFF;
        op = 3'b100; // XOR
        @(posedge clk); #1;
        exp_res   = 8'h00;
        exp_zero_f  = 1'b1;
        if (result === exp_res && zero_flag === exp_zero_f)
            $display("PASS: XOR 0xFF ^ 0xFF = 0x00, zero=1");
        else begin
            $display("FAIL: XOR 0xFF ^ 0xFF (result=%0h, zero=%b)", result, zero_flag);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 7: SHL  0x81 << 1 = 0x02, carry=1 (MSB was 1), zero=0
        // -----------------------------------------------------------------
        a  = 8'h81;
        b  = 8'h00; // b not used for SHL
        op = 3'b101; // SHL
        @(posedge clk); #1;
        exp_res   = 8'h02;
        exp_zero_f  = 1'b0;
        exp_carry_f = 1'b1;
        if (result === exp_res && zero_flag === exp_zero_f && carry_flag === exp_carry_f)
            $display("PASS: SHL 0x81 -> 0x02, carry=1, zero=0");
        else begin
            $display("FAIL: SHL 0x81 (result=%0h, zero=%b, carry=%b)", result, zero_flag, carry_flag);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 8: SHL  0x40 << 1 = 0x80, carry=0, zero=0
        // -----------------------------------------------------------------
        a  = 8'h40;
        b  = 8'h00;
        op = 3'b101; // SHL
        @(posedge clk); #1;
        exp_res   = 8'h80;
        exp_zero_f  = 1'b0;
        exp_carry_f = 1'b0;
        if (result === exp_res && zero_flag === exp_zero_f && carry_flag === exp_carry_f)
            $display("PASS: SHL 0x40 -> 0x80, carry=0, zero=0");
        else begin
            $display("FAIL: SHL 0x40 (result=%0h, zero=%b, carry=%b)", result, zero_flag, carry_flag);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 9: All-zero inputs, ADD 0+0=0, zero=1, carry=0
        // -----------------------------------------------------------------
        a  = 8'h00;
        b  = 8'h00;
        op = 3'b000; // ADD
        @(posedge clk); #1;
        exp_res   = 8'h00;
        exp_zero_f  = 1'b1;
        exp_carry_f = 1'b0;
        if (result === exp_res && zero_flag === exp_zero_f && carry_flag === exp_carry_f)
            $display("PASS: ADD 0+0=0, zero=1, carry=0");
        else begin
            $display("FAIL: ADD 0+0 (result=%0h, zero=%b, carry=%b)", result, zero_flag, carry_flag);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 10: All-ones inputs, AND 0xFF & 0xFF = 0xFF, zero=0
        // -----------------------------------------------------------------
        a  = 8'hFF;
        b  = 8'hFF;
        op = 3'b010; // AND
        @(posedge clk); #1;
        exp_res   = 8'hFF;
        exp_zero_f  = 1'b0;
        if (result === exp_res && zero_flag === exp_zero_f)
            $display("PASS: AND 0xFF & 0xFF = 0xFF, zero=0");
        else begin
            $display("FAIL: AND 0xFF & 0xFF (result=%0h, zero=%b)", result, zero_flag);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 11: SUB a==b => 0, zero=1
        // -----------------------------------------------------------------
        a  = 8'hAB;
        b  = 8'hAB;
        op = 3'b001; // SUB
        @(posedge clk); #1;
        exp_res   = 8'h00;
        exp_zero_f  = 1'b1;
        if (result === exp_res && zero_flag === exp_zero_f)
            $display("PASS: SUB 0xAB - 0xAB = 0, zero=1");
        else begin
            $display("FAIL: SUB 0xAB - 0xAB (result=%0h, zero=%b)", result, zero_flag);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 12: XOR normal  0xA5 ^ 0x5A = 0xFF, zero=0
        // -----------------------------------------------------------------
        a  = 8'hA5;
        b  = 8'h5A;
        op = 3'b100; // XOR
        @(posedge clk); #1;
        exp_res   = 8'hFF;
        exp_zero_f  = 1'b0;
        if (result === exp_res && zero_flag === exp_zero_f)
            $display("PASS: XOR 0xA5 ^ 0x5A = 0xFF, zero=0");
        else begin
            $display("FAIL: XOR 0xA5 ^ 0x5A (result=%0h, zero=%b)", result, zero_flag);
            fail_count = fail_count + 1;
        end

        // -----------------------------------------------------------------
        // Test 13: Re-assert reset mid-operation, verify outputs cleared
        // -----------------------------------------------------------------
        a  = 8'hAA;
        b  = 8'h55;
        op = 3'b011; // OR
        rst = 1;
        @(posedge clk); #1;
        if (result === {N{1'b0}} && zero_flag === 1'b0 && carry_flag === 1'b0)
            $display("PASS: Mid-operation reset clears outputs");
        else begin
            $display("FAIL: Mid-operation reset (result=%0h, zero=%b, carry=%b)", result, zero_flag, carry_flag);
            fail_count = fail_count + 1;
        end
        rst = 0;

        // -----------------------------------------------------------------
        // Final summary
        // -----------------------------------------------------------------
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TOTAL FAILURES: %0d", fail_count);

        $finish;
    end

endmodule
