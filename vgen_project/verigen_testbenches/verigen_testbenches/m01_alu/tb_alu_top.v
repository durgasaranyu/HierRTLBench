`timescale 1ns/1ps

module tb_alu_top;

    // Parameters
    parameter N = 8;

    // DUT connections
    reg              clk;
    reg              rst;
    reg  [N-1:0]     a;
    reg  [N-1:0]     b;
    reg  [2:0]       op;
    wire [N-1:0]     result;
    wire             zero_flag;
    wire             carry_flag;

    // Instantiate DUT - note module name is "alu" per the source
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

    // Task to apply inputs, clock one cycle, and sample outputs
    task apply_and_clock;
        input [N-1:0] in_a;
        input [N-1:0] in_b;
        input [2:0]   in_op;
        begin
            a  = in_a;
            b  = in_b;
            op = in_op;
            @(posedge clk);
            #1; // small delay to sample registered outputs
        end
    endtask

    // Expected computation helpers
    reg [N-1:0]  exp_result;
    reg          exp_zero;
    reg          exp_carry;
    reg [N:0]    add_wide;
    reg [N:0]    sub_wide;
    reg [N-1:0]  shl_wide;

    integer test_num;

    initial begin
        // Initialize inputs
        a   = 0;
        b   = 0;
        op  = 0;
        rst = 1;

        // Assert reset for exactly 5 rising edges
        repeat(5) @(posedge clk);
        #1;
        rst = 0;

        // After reset, outputs should be 0
        if (result === 8'h00 && zero_flag === 1'b0 && carry_flag === 1'b0) begin
            $display("PASS: Synchronous reset clears all outputs");
        end else begin
            $display("FAIL: Synchronous reset clears all outputs (result=%0h zf=%0b cf=%0b)", result, zero_flag, carry_flag);
        end

        //------------------------------------------------------------------
        // Test 1: ADD - normal operation: 3 + 5 = 8
        //------------------------------------------------------------------
        apply_and_clock(8'd3, 8'd5, 3'b000);
        add_wide   = {1'b0, 8'd3} + {1'b0, 8'd5};
        exp_result = add_wide[N-1:0];
        exp_carry  = add_wide[N];
        exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
        if (result === exp_result) begin
            $display("PASS: ADD normal 3+5=8 result=%0d", result);
        end else begin
            $display("FAIL: ADD normal 3+5=8 result=%0d expected=%0d", result, exp_result);
        end

        //------------------------------------------------------------------
        // Test 2: ADD - all-zero inputs: 0 + 0 = 0, zero_flag should be 1
        //------------------------------------------------------------------
        apply_and_clock(8'd0, 8'd0, 3'b000);
        add_wide   = {1'b0, 8'd0} + {1'b0, 8'd0};
        exp_result = add_wide[N-1:0];
        exp_carry  = add_wide[N];
        exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
        if (result === exp_result && zero_flag === exp_zero) begin
            $display("PASS: ADD zero inputs (0+0=0) zero_flag=%0b", zero_flag);
        end else begin
            $display("FAIL: ADD zero inputs result=%0d zero_flag=%0b expected_result=%0d expected_zero=%0b",
                     result, zero_flag, exp_result, exp_zero);
        end

        //------------------------------------------------------------------
        // Test 3: ADD - overflow: 255 + 1 = 256 -> carry_flag=1, result=0
        //------------------------------------------------------------------
        apply_and_clock(8'd255, 8'd1, 3'b000);
        add_wide   = {1'b0, 8'd255} + {1'b0, 8'd1};
        exp_result = add_wide[N-1:0];
        exp_carry  = add_wide[N];
        exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
        if (result === exp_result && carry_flag === exp_carry && zero_flag === exp_zero) begin
            $display("PASS: ADD overflow 255+1 result=%0d carry=%0b zero=%0b", result, carry_flag, zero_flag);
        end else begin
            $display("FAIL: ADD overflow 255+1 result=%0d(exp %0d) carry=%0b(exp %0b) zero=%0b(exp %0b)",
                     result, exp_result, carry_flag, exp_carry, zero_flag, exp_zero);
        end

        //------------------------------------------------------------------
        // Test 4: SUB - normal: 10 - 3 = 7
        //------------------------------------------------------------------
        apply_and_clock(8'd10, 8'd3, 3'b001);
        exp_result = 8'd10 - 8'd3;
        exp_carry  = (8'd10 < 8'd3) ? 1'b1 : 1'b0;
        exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
        if (result === exp_result) begin
            $display("PASS: SUB normal 10-3=7 result=%0d", result);
        end else begin
            $display("FAIL: SUB normal 10-3=7 result=%0d expected=%0d", result, exp_result);
        end

        //------------------------------------------------------------------
        // Test 5: AND - all-ones: 0xFF & 0xAA = 0xAA
        //------------------------------------------------------------------
        apply_and_clock(8'hFF, 8'hAA, 3'b010);
        exp_result = 8'hFF & 8'hAA;
        exp_carry  = 1'b0;
        exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
        if (result === exp_result) begin
            $display("PASS: AND 0xFF&0xAA=0xAA result=0x%0h", result);
        end else begin
            $display("FAIL: AND 0xFF&0xAA result=0x%0h expected=0x%0h", result, exp_result);
        end

        //------------------------------------------------------------------
        // Test 6: OR - normal: 0x0F | 0xF0 = 0xFF
        //------------------------------------------------------------------
        apply_and_clock(8'h0F, 8'hF0, 3'b011);
        exp_result = 8'h0F | 8'hF0;
        exp_carry  = 1'b0;
        exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
        if (result === exp_result) begin
            $display("PASS: OR 0x0F|0xF0=0xFF result=0x%0h", result);
        end else begin
            $display("FAIL: OR 0x0F|0xF0 result=0x%0h expected=0x%0h", result, exp_result);
        end

        //------------------------------------------------------------------
        // Test 7: XOR - same values produce zero: 0xAA ^ 0xAA = 0
        //------------------------------------------------------------------
        apply_and_clock(8'hAA, 8'hAA, 3'b100);
        exp_result = 8'hAA ^ 8'hAA;
        exp_carry  = 1'b0;
        exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
        if (result === exp_result && zero_flag === exp_zero) begin
            $display("PASS: XOR same values 0xAA^0xAA=0 zero_flag=%0b", zero_flag);
        end else begin
            $display("FAIL: XOR same values result=0x%0h(exp 0x%0h) zero_flag=%0b(exp %0b)",
                     result, exp_result, zero_flag, exp_zero);
        end

        //------------------------------------------------------------------
        // Test 8: SHL - normal: 0x01 << 1 = 0x02, carry=0 (MSB was 0)
        //------------------------------------------------------------------
        apply_and_clock(8'h01, 8'h00, 3'b101);
        exp_carry  = 1'b0; // MSB of a was 0
        exp_result = 8'h01 << 1;
        exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
        if (result === exp_result) begin
            $display("PASS: SHL normal 0x01<<1=0x02 result=0x%0h carry=%0b", result, carry_flag);
        end else begin
            $display("FAIL: SHL normal 0x01<<1 result=0x%0h expected=0x%0h", result, exp_result);
        end

        //------------------------------------------------------------------
        // Test 9: SHL - MSB=1: 0x80 << 1 = 0x00, carry=1, zero=1
        //------------------------------------------------------------------
        apply_and_clock(8'h80, 8'h00, 3'b101);
        exp_carry  = 1'b1; // MSB of a was 1
        exp_result = 8'h80 << 1; // = 0x00
        exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
        if (result === exp_result && carry_flag === exp_carry) begin
            $display("PASS: SHL MSB=1 0x80<<1=0x00 carry=%0b zero=%0b", carry_flag, zero_flag);
        end else begin
            $display("FAIL: SHL MSB=1 0x80<<1 result=0x%0h(exp 0x%0h) carry=%0b(exp %0b)",
                     result, exp_result, carry_flag, exp_carry);
        end

        //------------------------------------------------------------------
        // Test 10: SUB producing zero: 5 - 5 = 0, zero_flag=1
        //------------------------------------------------------------------
        apply_and_clock(8'd5, 8'd5, 3'b001);
        exp_result = 8'd0;
        exp_carry  = 1'b0;
        exp_zero   = 1'b1;
        if (result === exp_result && zero_flag === exp_zero) begin
            $display("PASS: SUB 5-5=0 zero_flag=%0b", zero_flag);
        end else begin
            $display("FAIL: SUB 5-5=0 result=%0d zero_flag=%0b expected_result=0 expected_zero=1",
                     result, zero_flag);
        end

        //------------------------------------------------------------------
        // Test 11: XOR normal: 0xF0 ^ 0x0F = 0xFF
        //------------------------------------------------------------------
        apply_and_clock(8'hF0, 8'h0F, 3'b100);
        exp_result = 8'hF0 ^ 8'h0F;
        exp_carry  = 1'b0;
        exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
        if (result === exp_result) begin
            $display("PASS: XOR 0xF0^0x0F=0xFF result=0x%0h", result);
        end else begin
            $display("FAIL: XOR 0xF0^0x0F result=0x%0h expected=0x%0h", result, exp_result);
        end

        //------------------------------------------------------------------
        // Test 12: AND producing zero: 0xAA & 0x55 = 0, zero_flag=1
        //------------------------------------------------------------------
        apply_and_clock(8'hAA, 8'h55, 3'b010);
        exp_result = 8'hAA & 8'h55;
        exp_carry  = 1'b0;
        exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
        if (result === exp_result && zero_flag === exp_zero) begin
            $display("PASS: AND 0xAA&0x55=0 zero_flag=%0b", zero_flag);
        end else begin
            $display("FAIL: AND 0xAA&0x55 result=0x%0h(exp 0x%0h) zero_flag=%0b(exp %0b)",
                     result, exp_result, zero_flag, exp_zero);
        end

        //------------------------------------------------------------------
        // Test 13: Verify reset again mid-simulation
        //------------------------------------------------------------------
        rst = 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        #1;
        if (result === 8'h00 && zero_flag === 1'b0 && carry_flag === 1'b0) begin
            $display("PASS: Mid-simulation reset clears all outputs");
        end else begin
            $display("FAIL: Mid-simulation reset: result=%0h zf=%0b cf=%0b", result, zero_flag, carry_flag);
        end
        rst = 0;

        //------------------------------------------------------------------
        // Test 14: ADD max values 0xFF + 0xFF
        //------------------------------------------------------------------
        apply_and_clock(8'hFF, 8'hFF, 3'b000);
        add_wide   = {1'b0, 8'hFF} + {1'b0, 8'hFF};
        exp_result = add_wide[N-1:0];
        exp_carry  = add_wide[N];
        exp_zero   = (exp_result == 0) ? 1'b1 : 1'b0;
        if (result === exp_result && carry_flag === exp_carry) begin
            $display("PASS: ADD max 0xFF+0xFF result=0x%0h carry=%0b", result, carry_flag);
        end else begin
            $display("FAIL: ADD max 0xFF+0xFF result=0x%0h(exp 0x%0h) carry=%0b(exp %0b)",
                     result, exp_result, carry_flag, exp_carry);
        end

        $finish;
    end

endmodule
