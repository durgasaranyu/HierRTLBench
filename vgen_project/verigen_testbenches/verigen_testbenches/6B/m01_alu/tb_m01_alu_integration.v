`timescale 1ns/1ps

module tb_m01_alu_integration;

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

    // Task to apply one operation and check result after rising edge
    task apply_and_check;
        input [N-1:0]   ta, tb;
        input [2:0]     top;
        input [N-1:0]   exp_result;
        input           exp_zero;
        input           exp_carry;
        input [63:0]    test_id; // used just for display
        input [8*64-1:0] desc;
        begin
            @(negedge clk);
            a  = ta;
            b  = tb;
            op = top;
            @(posedge clk);
            #1; // small delta after rising edge for registered outputs to update
            if (result === exp_result && zero_flag === exp_zero && carry_flag === exp_carry)
                $display("PASS: %s", desc);
            else
                $display("FAIL: %s | got result=%0h zf=%0b cf=%0b | exp result=%0h zf=%0b cf=%0b",
                         desc, result, zero_flag, carry_flag,
                         exp_result, exp_zero, exp_carry);
        end
    endtask

    // Compute expected values in pure combinational logic
    // We replicate the ALU behaviour here for checking
    // ADD: result = a + b, carry = carry out bit N, zero = (result==0)
    // SUB: result = a - b, carry = borrow (a < b), zero = (result==0)
    // AND, OR, XOR: logical ops, carry=0, zero = (result==0)
    // SHL: result = a << 1, carry = a[N-1], zero = (result==0)

    integer i;
    reg [N:0]   tmp_add;
    reg [N:0]   tmp_sub;
    reg [N-1:0] exp_r;
    reg         exp_z, exp_c;

    // Helper function - compute expected outputs
    task compute_expected;
        input [N-1:0] ta, tb;
        input [2:0]   top;
        output [N-1:0] er;
        output         ez, ec;
        reg [N:0] wide;
        begin
            case (top)
                3'b000: begin // ADD
                    wide = {1'b0, ta} + {1'b0, tb};
                    er = wide[N-1:0];
                    ec = wide[N];
                    ez = (er == 0) ? 1'b1 : 1'b0;
                end
                3'b001: begin // SUB
                    wide = {1'b0, ta} - {1'b0, tb};
                    er = wide[N-1:0];
                    ec = (ta < tb) ? 1'b1 : 1'b0;
                    ez = (er == 0) ? 1'b1 : 1'b0;
                end
                3'b010: begin // AND
                    er = ta & tb;
                    ec = 1'b0;
                    ez = (er == 0) ? 1'b1 : 1'b0;
                end
                3'b011: begin // OR
                    er = ta | tb;
                    ec = 1'b0;
                    ez = (er == 0) ? 1'b1 : 1'b0;
                end
                3'b100: begin // XOR
                    er = ta ^ tb;
                    ec = 1'b0;
                    ez = (er == 0) ? 1'b1 : 1'b0;
                end
                3'b101: begin // SHL
                    er = ta << 1;
                    ec = ta[N-1];
                    ez = (er == 0) ? 1'b1 : 1'b0;
                end
                default: begin
                    er = 8'hxx;
                    ec = 1'bx;
                    ez = 1'bx;
                end
            endcase
        end
    endtask

    // Main test
    initial begin
        // Initialise
        rst = 1;
        a   = 0;
        b   = 0;
        op  = 3'b000;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;

        // Allow one cycle after reset deassertion
        @(posedge clk);
        #1;

        // ----------------------------------------------------------------
        // After reset: outputs should be 0
        // ----------------------------------------------------------------
        if (result === 8'h00 && zero_flag === 1'b0 && carry_flag === 1'b0)
            $display("PASS: Reset state - result=0 flags=0");
        else
            $display("FAIL: Reset state - got result=%0h zf=%0b cf=%0b", result, zero_flag, carry_flag);

        // ----------------------------------------------------------------
        // Test ADD operations
        // ----------------------------------------------------------------
        // 1) Simple addition: 5 + 3 = 8, no carry, no zero
        compute_expected(8'd5, 8'd3, 3'b000, exp_r, exp_z, exp_c);
        apply_and_check(8'd5, 8'd3, 3'b000, exp_r, exp_z, exp_c, 1, "ADD 5+3=8 no carry no zero");

        // 2) Addition with carry: 255 + 1 = 0 with carry, zero set
        compute_expected(8'd255, 8'd1, 3'b000, exp_r, exp_z, exp_c);
        apply_and_check(8'd255, 8'd1, 3'b000, exp_r, exp_z, exp_c, 2, "ADD 255+1 carry+zero");

        // 3) Addition zero result without carry overflow: 0 + 0 = 0, zero set
        compute_expected(8'd0, 8'd0, 3'b000, exp_r, exp_z, exp_c);
        apply_and_check(8'd0, 8'd0, 3'b000, exp_r, exp_z, exp_c, 3, "ADD 0+0=0 zero set");

        // 4) Addition large: 128 + 127 = 255, no carry
        compute_expected(8'd128, 8'd127, 3'b000, exp_r, exp_z, exp_c);
        apply_and_check(8'd128, 8'd127, 3'b000, exp_r, exp_z, exp_c, 4, "ADD 128+127=255 no carry");

        // ----------------------------------------------------------------
        // Test SUB operations
        // ----------------------------------------------------------------
        // 5) Simple subtraction: 10 - 3 = 7, no borrow
        compute_expected(8'd10, 8'd3, 3'b001, exp_r, exp_z, exp_c);
        apply_and_check(8'd10, 8'd3, 3'b001, exp_r, exp_z, exp_c, 5, "SUB 10-3=7 no borrow");

        // 6) Subtraction equal: 5 - 5 = 0, zero set
        compute_expected(8'd5, 8'd5, 3'b001, exp_r, exp_z, exp_c);
        apply_and_check(8'd5, 8'd5, 3'b001, exp_r, exp_z, exp_c, 6, "SUB 5-5=0 zero set");

        // 7) Subtraction with borrow: 3 - 5 = borrow
        compute_expected(8'd3, 8'd5, 3'b001, exp_r, exp_z, exp_c);
        apply_and_check(8'd3, 8'd5, 3'b001, exp_r, exp_z, exp_c, 7, "SUB 3-5 borrow");

        // 8) Subtraction: 255 - 0 = 255
        compute_expected(8'd255, 8'd0, 3'b001, exp_r, exp_z, exp_c);
        apply_and_check(8'd255, 8'd0, 3'b001, exp_r, exp_z, exp_c, 8, "SUB 255-0=255");

        // ----------------------------------------------------------------
        // Test AND operations
        // ----------------------------------------------------------------
        // 9) AND: 0xAA & 0x55 = 0x00, zero
        compute_expected(8'hAA, 8'h55, 3'b010, exp_r, exp_z, exp_c);
        apply_and_check(8'hAA, 8'h55, 3'b010, exp_r, exp_z, exp_c, 9, "AND 0xAA&0x55=0 zero");

        // 10) AND: 0xFF & 0xF0 = 0xF0
        compute_expected(8'hFF, 8'hF0, 3'b010, exp_r, exp_z, exp_c);
        apply_and_check(8'hFF, 8'hF0, 3'b010, exp_r, exp_z, exp_c, 10, "AND 0xFF&0xF0=0xF0");

        // 11) AND: 0x0F & 0x0F = 0x0F
        compute_expected(8'h0F, 8'h0F, 3'b010, exp_r, exp_z, exp_c);
        apply_and_check(8'h0F, 8'h0F, 3'b010, exp_r, exp_z, exp_c, 11, "AND 0x0F&0x0F=0x0F");

        // ----------------------------------------------------------------
        // Test OR operations
        // ----------------------------------------------------------------
        // 12) OR: 0xAA | 0x55 = 0xFF
        compute_expected(8'hAA, 8'h55, 3'b011, exp_r, exp_z, exp_c);
        apply_and_check(8'hAA, 8'h55, 3'b011, exp_r, exp_z, exp_c, 12, "OR 0xAA|0x55=0xFF");

        // 13) OR: 0x00 | 0x00 = 0x00, zero
        compute_expected(8'h00, 8'h00, 3'b011, exp_r, exp_z, exp_c);
        apply_and_check(8'h00, 8'h00, 3'b011, exp_r, exp_z, exp_c, 13, "OR 0x00|0x00=0 zero");

        // 14) OR: 0xA5 | 0x5A = 0xFF
        compute_expected(8'hA5, 8'h5A, 3'b011, exp_r, exp_z, exp_c);
        apply_and_check(8'hA5, 8'h5A, 3'b011, exp_r, exp_z, exp_c, 14, "OR 0xA5|0x5A=0xFF");

        // ----------------------------------------------------------------
        // Test XOR operations
        // ----------------------------------------------------------------
        // 15) XOR: 0xFF ^ 0xFF = 0x00, zero
        compute_expected(8'hFF, 8'hFF, 3'b100, exp_r, exp_z, exp_c);
        apply_and_check(8'hFF, 8'hFF, 3'b100, exp_r, exp_z, exp_c, 15, "XOR 0xFF^0xFF=0 zero");

        // 16) XOR: 0xAA ^ 0x55 = 0xFF
        compute_expected(8'hAA, 8'h55, 3'b100, exp_r, exp_z, exp_c);
        apply_and_check(8'hAA, 8'h55, 3'b100, exp_r, exp_z, exp_c, 16, "XOR 0xAA^0x55=0xFF");

        // 17) XOR: 0x00 ^ 0xFF = 0xFF
        compute_expected(8'h00, 8'hFF, 3'b100, exp_r, exp_z, exp_c);
        apply_and_check(8'h00, 8'hFF, 3'b100, exp_r, exp_z, exp_c, 17, "XOR 0x00^0xFF=0xFF");

        // ----------------------------------------------------------------
        // Test SHL operations
        // ----------------------------------------------------------------
        // 18) SHL: 0x01 << 1 = 0x02, no carry, no zero
        compute_expected(8'h01, 8'h00, 3'b101, exp_r, exp_z, exp_c);
        apply_and_check(8'h01, 8'h00, 3'b101, exp_r, exp_z, exp_c, 18, "SHL 0x01<<1=0x02");

        // 19) SHL: 0x80 << 1 = 0x00, carry set, zero set
        compute_expected(8'h80, 8'h00, 3'b101, exp_r, exp_z, exp_c);
        apply_and_check(8'h80, 8'h00, 3'b101, exp_r, exp_z, exp_c, 19, "SHL 0x80<<1=0 carry+zero");

        // 20) SHL: 0xAA << 1 = 0x54, carry set (MSB was 1)
        compute_expected(8'hAA, 8'h00, 3'b101, exp_r, exp_z, exp_c);
        apply_and_check(8'hAA, 8'h00, 3'b101, exp_r, exp_z, exp_c, 20, "SHL 0xAA<<1 carry set");

        // 21) SHL: 0x55 << 1 = 0xAA, no carry
        compute_expected(8'h55, 8'h00, 3'b101, exp_r, exp_z, exp_c);
        apply_and_check(8'h55, 8'h00, 3'b101, exp_r, exp_z, exp_c, 21, "SHL 0x55<<1=0xAA no carry");

        // 22) SHL: 0x00 << 1 = 0x00, no carry, zero
        compute_expected(8'h00, 8'h00, 3'b101, exp_r, exp_z, exp_c);
        apply_and_check(8'h00, 8'h00, 3'b101, exp_r, exp_z, exp_c, 22, "SHL 0x
