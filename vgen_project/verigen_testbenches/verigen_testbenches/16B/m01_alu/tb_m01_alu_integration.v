`timescale 1ns/1ps
module tb_m01_alu_integration;

    // Parameters
    parameter N = 8;

    // DUT inputs
    reg             clk;
    reg             rst;
    reg  [N-1:0]    a;
    reg  [N-1:0]    b;
    reg  [2:0]      op;

    // DUT outputs
    wire [N-1:0]    result;
    wire            zero_flag;
    wire            carry_flag;

    // Instantiate the DUT
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

    // Task: apply inputs and wait for next rising edge, then check
    // We use a simple check mechanism after the clock edge

    integer failed;
    integer passed;

    // Expected values
    reg [N-1:0] exp_result;
    reg         exp_zero;
    reg         exp_carry;

    // Task to apply one operation and check one clock later
    task apply_and_check;
        input [N-1:0]  t_a;
        input [N-1:0]  t_b;
        input [2:0]    t_op;
        input [N-1:0]  t_exp_result;
        input          t_exp_zero;
        input          t_exp_carry;
        input [127:0]  t_desc; // not used directly but for reference
        begin
            @(negedge clk);
            a   = t_a;
            b   = t_b;
            op  = t_op;
            @(posedge clk);
            #1; // small delay after clock edge to sample registered outputs
            if (result === t_exp_result && zero_flag === t_exp_zero && carry_flag === t_exp_carry) begin
                $display("PASS: op=%b a=%h b=%h => result=%h zero=%b carry=%b",
                    t_op, t_a, t_b, result, zero_flag, carry_flag);
                passed = passed + 1;
            end else begin
                $display("FAIL: op=%b a=%h b=%h => result=%h (exp %h) zero=%b (exp %b) carry=%b (exp %b)",
                    t_op, t_a, t_b, result, t_exp_result, zero_flag, t_exp_zero, carry_flag, t_exp_carry);
                failed = failed + 1;
            end
        end
    endtask

    // Compute expected values in combinational logic style
    reg [N:0] add_result_wide;
    reg [N:0] sub_result_wide;

    initial begin
        failed = 0;
        passed = 0;

        // Initialize inputs
        a   = 0;
        b   = 0;
        op  = 0;
        rst = 1;

        // Assert synchronous reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // ------------------------------------------------------------------
        // Test 1: ADD - simple addition, no carry
        // op = 3'b000, a=8'h05, b=8'h03 => result=8'h08, zero=0, carry=0
        // ------------------------------------------------------------------
        @(negedge clk);
        a = 8'h05; b = 8'h03; op = 3'b000;
        @(posedge clk); #1;
        begin
            add_result_wide = {1'b0, 8'h05} + {1'b0, 8'h03};
            exp_result = add_result_wide[N-1:0];
            exp_carry  = add_result_wide[N];
            exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
            if (result === exp_result && zero_flag === exp_zero && carry_flag === exp_carry)
                $display("PASS: ADD 0x05+0x03 = 0x%02h zero=%b carry=%b", result, zero_flag, carry_flag);
            else begin
                $display("FAIL: ADD 0x05+0x03 expected result=0x%02h got 0x%02h zero=%b(exp%b) carry=%b(exp%b)",
                    exp_result, result, zero_flag, exp_zero, carry_flag, exp_carry);
                failed = failed + 1;
            end
        end

        // ------------------------------------------------------------------
        // Test 2: ADD with carry out
        // a=8'hFF, b=8'h01 => result=8'h00, zero=1, carry=1
        // ------------------------------------------------------------------
        @(negedge clk);
        a = 8'hFF; b = 8'h01; op = 3'b000;
        @(posedge clk); #1;
        begin
            add_result_wide = {1'b0, 8'hFF} + {1'b0, 8'h01};
            exp_result = add_result_wide[N-1:0];
            exp_carry  = add_result_wide[N];
            exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
            if (result === exp_result && zero_flag === exp_zero && carry_flag === exp_carry)
                $display("PASS: ADD 0xFF+0x01 = 0x%02h zero=%b carry=%b", result, zero_flag, carry_flag);
            else begin
                $display("FAIL: ADD 0xFF+0x01 expected result=0x%02h got 0x%02h zero=%b(exp%b) carry=%b(exp%b)",
                    exp_result, result, zero_flag, exp_zero, carry_flag, exp_carry);
                failed = failed + 1;
            end
        end

        // ------------------------------------------------------------------
        // Test 3: ADD producing zero without carry
        // a=8'h00, b=8'h00 => result=8'h00, zero=1, carry=0
        // ------------------------------------------------------------------
        @(negedge clk);
        a = 8'h00; b = 8'h00; op = 3'b000;
        @(posedge clk); #1;
        begin
            add_result_wide = {1'b0, 8'h00} + {1'b0, 8'h00};
            exp_result = add_result_wide[N-1:0];
            exp_carry  = add_result_wide[N];
            exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
            if (result === exp_result && zero_flag === exp_zero && carry_flag === exp_carry)
                $display("PASS: ADD 0x00+0x00 = 0x%02h zero=%b carry=%b", result, zero_flag, carry_flag);
            else begin
                $display("FAIL: ADD 0x00+0x00 expected result=0x%02h got 0x%02h zero=%b(exp%b) carry=%b(exp%b)",
                    exp_result, result, zero_flag, exp_zero, carry_flag, exp_carry);
                failed = failed + 1;
            end
        end

        // ------------------------------------------------------------------
        // Test 4: SUB - simple subtraction, no borrow
        // op = 3'b001, a=8'h0A, b=8'h03 => result=8'h07, zero=0, carry=0
        // (carry=borrow: 0 means no borrow => carry=0 or carry=1 depending on convention)
        // Standard convention: carry_out of (a + ~b + 1), so carry=1 means no borrow
        // ------------------------------------------------------------------
        @(negedge clk);
        a = 8'h0A; b = 8'h03; op = 3'b001;
        @(posedge clk); #1;
        begin
            sub_result_wide = {1'b0, 8'h0A} + {1'b0, (~8'h03)} + 9'b1;
            exp_result = sub_result_wide[N-1:0];
            exp_carry  = sub_result_wide[N];
            exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
            if (result === exp_result && zero_flag === exp_zero && carry_flag === exp_carry)
                $display("PASS: SUB 0x0A-0x03 = 0x%02h zero=%b carry=%b", result, zero_flag, carry_flag);
            else begin
                $display("FAIL: SUB 0x0A-0x03 expected result=0x%02h got 0x%02h zero=%b(exp%b) carry=%b(exp%b)",
                    exp_result, result, zero_flag, exp_zero, carry_flag, exp_carry);
                failed = failed + 1;
            end
        end

        // ------------------------------------------------------------------
        // Test 5: SUB producing zero
        // a=8'h05, b=8'h05 => result=8'h00, zero=1
        // ------------------------------------------------------------------
        @(negedge clk);
        a = 8'h05; b = 8'h05; op = 3'b001;
        @(posedge clk); #1;
        begin
            sub_result_wide = {1'b0, 8'h05} + {1'b0, (~8'h05)} + 9'b1;
            exp_result = sub_result_wide[N-1:0];
            exp_carry  = sub_result_wide[N];
            exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
            if (result === exp_result && zero_flag === exp_zero && carry_flag === exp_carry)
                $display("PASS: SUB 0x05-0x05 = 0x%02h zero=%b carry=%b", result, zero_flag, carry_flag);
            else begin
                $display("FAIL: SUB 0x05-0x05 expected result=0x%02h got 0x%02h zero=%b(exp%b) carry=%b(exp%b)",
                    exp_result, result, zero_flag, exp_zero, carry_flag, exp_carry);
                failed = failed + 1;
            end
        end

        // ------------------------------------------------------------------
        // Test 6: SUB with borrow (a < b)
        // a=8'h03, b=8'h05 => result=8'hFE, zero=0, carry=0 (borrow)
        // ------------------------------------------------------------------
        @(negedge clk);
        a = 8'h03; b = 8'h05; op = 3'b001;
        @(posedge clk); #1;
        begin
            sub_result_wide = {1'b0, 8'h03} + {1'b0, (~8'h05)} + 9'b1;
            exp_result = sub_result_wide[N-1:0];
            exp_carry  = sub_result_wide[N];
            exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
            if (result === exp_result && zero_flag === exp_zero && carry_flag === exp_carry)
                $display("PASS: SUB 0x03-0x05 = 0x%02h zero=%b carry=%b", result, zero_flag, carry_flag);
            else begin
                $display("FAIL: SUB 0x03-0x05 expected result=0x%02h got 0x%02h zero=%b(exp%b) carry=%b(exp%b)",
                    exp_result, result, zero_flag, exp_zero, carry_flag, exp_carry);
                failed = failed + 1;
            end
        end

        // ------------------------------------------------------------------
        // Test 7: AND
        // op = 3'b010, a=8'hF0, b=8'hAA => result=8'hA0, zero=0, carry=0
        // ------------------------------------------------------------------
        @(negedge clk);
        a = 8'hF0; b = 8'hAA; op = 3'b010;
        @(posedge clk); #1;
        begin
            exp_result = 8'hF0 & 8'hAA;
            exp_carry  = 1'b0;
            exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
            if (result === exp_result && zero_flag === exp_zero && carry_flag === exp_carry)
                $display("PASS: AND 0xF0&0xAA = 0x%02h zero=%b carry=%b", result, zero_flag, carry_flag);
            else begin
                $display("FAIL: AND 0xF0&0xAA expected result=0x%02h got 0x%02h zero=%b(exp%b) carry=%b(exp%b)",
                    exp_result, result, zero_flag, exp_zero, carry_flag, exp_carry);
                failed = failed + 1;
            end
        end

        // ------------------------------------------------------------------
        // Test 8: AND producing zero
        // a=8'hF0, b=8'h0F => result=8'h00, zero=1, carry=0
        // ------------------------------------------------------------------
        @(negedge clk);
        a = 8'hF0; b = 8'h0F; op = 3'b010;
        @(posedge clk); #1;
        begin
            exp_result = 8'hF0 & 8'h0F;
            exp_carry  = 1'b0;
            exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
            if (result === exp_result && zero_flag === exp_zero && carry_flag === exp_carry)
                $display("PASS: AND 0xF0&0x0F = 0x%02h zero=%b carry=%b", result, zero_flag, carry_flag);
            else begin
                $display("FAIL: AND 0xF0&0x0F expected result=0x%02h got 0x%02h zero=%b(exp%b) carry=%b(exp%b)",
                    exp_result, result, zero_flag, exp_zero, carry_flag, exp_carry);
                failed = failed + 1;
            end
        end

        // ------------------------------------------------------------------
        // Test 9: OR
        // op = 3'b011, a=8'hF0, b=8'h0F => result=8'hFF, zero=0, carry=0
        // ------------------------------------------------------------------
        @(negedge clk);
        a = 8'hF0; b = 8'h0F; op = 3'b011;
        @(posedge clk); #1;
        begin
            exp_result = 8'hF0 | 8'h0F;
            exp_carry  = 1'b0;
            exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
            if (result === exp_result && zero_flag === exp_zero && carry_flag === exp_carry)
                $display("PASS: OR 0xF0|0x0F = 0x%02h zero=%b carry=%b", result, zero_flag, carry_flag);
            else begin
                $display("FAIL: OR 0xF0|0x0F expected result=0x%02h got 0x%02h
