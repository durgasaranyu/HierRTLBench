`timescale 1ns/1ps

module tb_alu_top;

    // Parameters
    parameter N = 8;

    // DUT connections
    reg            clk;
    reg            rst;
    reg  [N-1:0]   a;
    reg  [N-1:0]   b;
    reg  [2:0]     op;
    wire [N-1:0]   result;
    wire           zero_flag;
    wire           carry_flag;

    // Instantiate DUT - the module is named "alu" in the file
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

    // Task to apply inputs and clock one cycle
    task apply_and_check;
        input [N-1:0]   in_a;
        input [N-1:0]   in_b;
        input [2:0]      in_op;
        input [N-1:0]   exp_result;
        input            exp_zero;
        input            exp_carry;
        input [63:0]     test_num;
        input [200*8-1:0] desc;
        begin
            a   = in_a;
            b   = in_b;
            op  = in_op;
            @(posedge clk); #1;
            // Check result
            if (result === exp_result && zero_flag === exp_zero && carry_flag === exp_carry) begin
                $display("PASS: Test %0d - %0s", test_num, desc);
            end else begin
                $display("FAIL: Test %0d - %0s | Expected result=%0h zero=%0b carry=%0b | Got result=%0h zero=%0b carry=%0b",
                    test_num, desc,
                    exp_result, exp_zero, exp_carry,
                    result, zero_flag, carry_flag);
            end
        end
    endtask

    // Variables for expected results
    reg [8:0]  add_full;
    reg [N-1:0] exp_res;
    reg         exp_zero;
    reg         exp_carry;

    integer i;

    initial begin
        // Initialize
        rst = 1;
        a   = 0;
        b   = 0;
        op  = 0;

        // Assert reset for 5 rising edges
        repeat(5) @(posedge clk);
        #1;
        rst = 0;

        // Wait one more cycle after reset deassert
        @(posedge clk); #1;

        // -------------------------------------------------------
        // After reset: outputs should be 0
        // We just deasserted reset; on next posedge outputs cleared
        // Check reset cleared outputs
        if (result === 8'h00 && zero_flag === 1'b0 && carry_flag === 1'b0) begin
            $display("PASS: Reset clears all outputs (result=0, zero_flag=0, carry_flag=0)");
        end else begin
            $display("FAIL: Reset clears all outputs | Got result=%0h zero=%0b carry=%0b",
                result, zero_flag, carry_flag);
        end

        // -------------------------------------------------------
        // Test 1: ADD normal case - 3 + 5 = 8, no carry, not zero
        // op=000 (ADD)
        // After the clock edge, result should be registered
        a = 8'd3; b = 8'd5; op = 3'b000;
        @(posedge clk); #1;
        // Expected: result=8, zero=0, carry=0
        exp_res   = 8'd8;
        exp_zero  = 1'b0;
        exp_carry = 1'b0;
        if (result === exp_res && zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test 1 - ADD 3+5=8, no carry, not zero");
        else
            $display("FAIL: Test 1 - ADD 3+5=8 | Expected result=%0h zero=%0b carry=%0b | Got result=%0h zero=%0b carry=%0b",
                exp_res, exp_zero, exp_carry, result, zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 2: ADD overflow - 255 + 1 = 0 with carry, zero_flag=1
        a = 8'd255; b = 8'd1; op = 3'b000;
        @(posedge clk); #1;
        exp_res   = 8'd0;
        exp_zero  = 1'b1;
        exp_carry = 1'b1;
        if (result === exp_res && zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test 2 - ADD 255+1 overflow, result=0, carry=1, zero=1");
        else
            $display("FAIL: Test 2 - ADD 255+1 overflow | Expected result=%0h zero=%0b carry=%0b | Got result=%0h zero=%0b carry=%0b",
                exp_res, exp_zero, exp_carry, result, zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 3: SUB normal case - 10 - 3 = 7
        a = 8'd10; b = 8'd3; op = 3'b001;
        @(posedge clk); #1;
        exp_res   = 8'd7;
        exp_zero  = 1'b0;
        exp_carry = 1'b0;
        if (result === exp_res && zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test 3 - SUB 10-3=7, no carry, not zero");
        else
            $display("FAIL: Test 3 - SUB 10-3=7 | Expected result=%0h zero=%0b carry=%0b | Got result=%0h zero=%0b carry=%0b",
                exp_res, exp_zero, exp_carry, result, zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 4: SUB yielding zero - 5 - 5 = 0, zero_flag=1
        a = 8'd5; b = 8'd5; op = 3'b001;
        @(posedge clk); #1;
        exp_res   = 8'd0;
        exp_zero  = 1'b1;
        exp_carry = 1'b0;
        if (result === exp_res && zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test 4 - SUB 5-5=0, zero_flag=1");
        else
            $display("FAIL: Test 4 - SUB 5-5=0 | Expected result=%0h zero=%0b carry=%0b | Got result=%0h zero=%0b carry=%0b",
                exp_res, exp_zero, exp_carry, result, zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 5: AND normal case - 0xAA & 0x0F = 0x0A
        a = 8'hAA; b = 8'h0F; op = 3'b010;
        @(posedge clk); #1;
        exp_res   = 8'h0A;
        exp_zero  = 1'b0;
        exp_carry = 1'b0;
        if (result === exp_res && zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test 5 - AND 0xAA & 0x0F = 0x0A");
        else
            $display("FAIL: Test 5 - AND 0xAA & 0x0F | Expected result=%0h zero=%0b carry=%0b | Got result=%0h zero=%0b carry=%0b",
                exp_res, exp_zero, exp_carry, result, zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 6: AND all-zero result - 0xAA & 0x55 = 0x00, zero_flag=1
        a = 8'hAA; b = 8'h55; op = 3'b010;
        @(posedge clk); #1;
        exp_res   = 8'h00;
        exp_zero  = 1'b1;
        exp_carry = 1'b0;
        if (result === exp_res && zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test 6 - AND 0xAA & 0x55 = 0x00, zero_flag=1");
        else
            $display("FAIL: Test 6 - AND 0xAA & 0x55 | Expected result=%0h zero=%0b carry=%0b | Got result=%0h zero=%0b carry=%0b",
                exp_res, exp_zero, exp_carry, result, zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 7: OR - 0x0F | 0xF0 = 0xFF
        a = 8'h0F; b = 8'hF0; op = 3'b011;
        @(posedge clk); #1;
        exp_res   = 8'hFF;
        exp_zero  = 1'b0;
        exp_carry = 1'b0;
        if (result === exp_res && zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test 7 - OR 0x0F | 0xF0 = 0xFF");
        else
            $display("FAIL: Test 7 - OR 0x0F | 0xF0 | Expected result=%0h zero=%0b carry=%0b | Got result=%0h zero=%0b carry=%0b",
                exp_res, exp_zero, exp_carry, result, zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 8: OR all-zero inputs -> zero_flag=1
        a = 8'h00; b = 8'h00; op = 3'b011;
        @(posedge clk); #1;
        exp_res   = 8'h00;
        exp_zero  = 1'b1;
        exp_carry = 1'b0;
        if (result === exp_res && zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test 8 - OR 0x00 | 0x00 = 0x00, zero_flag=1");
        else
            $display("FAIL: Test 8 - OR 0x00 | 0x00 | Expected result=%0h zero=%0b carry=%0b | Got result=%0h zero=%0b carry=%0b",
                exp_res, exp_zero, exp_carry, result, zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 9: XOR normal - 0xFF ^ 0x0F = 0xF0
        a = 8'hFF; b = 8'h0F; op = 3'b100;
        @(posedge clk); #1;
        exp_res   = 8'hF0;
        exp_zero  = 1'b0;
        exp_carry = 1'b0;
        if (result === exp_res && zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test 9 - XOR 0xFF ^ 0x0F = 0xF0");
        else
            $display("FAIL: Test 9 - XOR 0xFF ^ 0x0F | Expected result=%0h zero=%0b carry=%0b | Got result=%0h zero=%0b carry=%0b",
                exp_res, exp_zero, exp_carry, result, zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 10: XOR same values -> zero result, zero_flag=1
        a = 8'hAB; b = 8'hAB; op = 3'b100;
        @(posedge clk); #1;
        exp_res   = 8'h00;
        exp_zero  = 1'b1;
        exp_carry = 1'b0;
        if (result === exp_res && zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test 10 - XOR 0xAB ^ 0xAB = 0x00, zero_flag=1");
        else
            $display("FAIL: Test 10 - XOR 0xAB ^ 0xAB | Expected result=%0h zero=%0b carry=%0b | Got result=%0h zero=%0b carry=%0b",
                exp_res, exp_zero, exp_carry, result, zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 11: SHL - 0x01 << 1 = 0x02, MSB was 0, carry=0
        a = 8'h01; b = 8'h00; op = 3'b101;
        @(posedge clk); #1;
        exp_res   = 8'h02;
        exp_zero  = 1'b0;
        exp_carry = 1'b0;
        if (result === exp_res && zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test 11 - SHL 0x01 = 0x02, carry=0");
        else
            $display("FAIL: Test 11 - SHL 0x01 | Expected result=%0h zero=%0b carry=%0b | Got result=%0h zero=%0b carry=%0b",
                exp_res, exp_zero, exp_carry, result, zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 12: SHL - 0x80 << 1 = 0x00, MSB was 1, carry=1, zero=1
        a = 8'h80; b = 8'h00; op = 3'b101;
        @(posedge clk); #1;
        exp_res   = 8'h00;
        exp_zero  = 1'b1;
        exp_carry = 1'b1;
        if (result === exp_res && zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test 12 - SHL 0x80 = 0x00, carry=1, zero=1");
        else
            $display("FAIL: Test 12 - SHL 0x80 | Expected result=%0h zero=%0b carry=%0b | Got result=%0h zero=%0b carry=%0b",
                exp_res, exp_zero, exp_carry, result, zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 13: SHL - 0xFF << 1 = 0xFE, carry=1
        a = 8'hFF; b = 8'h00; op = 3'b101;
        @(posedge clk); #1;
        exp_res   = 8'hFE;
        exp_zero  = 1'b0;
        exp_carry = 1'b1;
        if (result === exp_res && zero_flag === exp_zero && carry_flag === exp_carry)
            $display("PASS: Test 13 - SHL 0xFF = 0xFE, carry=1");
        else
            $display("FAIL: Test 13 - SHL 0xFF | Expected result=%0h zero=%0b carry=%0b | Got result=%
