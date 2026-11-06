`timescale 1ns/1ps

module tb_cpu_alu;

    // DUT connections
    reg  [31:0] a, b;
    reg  [1:0]  op;
    wire [31:0] result;
    wire        zero;

    // Clock (not strictly needed for combinational, but required by general rules)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Synchronous reset placeholder (module has no reset, but rule requires it)
    reg rst;

    // Instantiate DUT
    cpu_alu uut (
        .a      (a),
        .b      (b),
        .op     (op),
        .result (result),
        .zero   (zero)
    );

    // Expected result holder
    reg [31:0] exp_result;
    reg        exp_zero;

    integer fail_count;

    // Task to check results
    task check;
        input [63:0] test_id;
        input [255:0] desc;
        input [31:0] exp_r;
        input        exp_z;
        begin
            #1; // small settle time
            if (result === exp_r && zero === exp_z) begin
                $display("PASS: Test %0d - %s | result=%0d zero=%0b",
                         test_id, desc, result, zero);
            end else begin
                $display("FAIL: Test %0d - %s | expected result=%0d zero=%0b, got result=%0d zero=%0b",
                         test_id, desc, exp_r, exp_z, result, zero);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        fail_count = 0;

        // Assert reset for 5 clock rising edges (module has no reset pin, but rule mandates)
        rst = 1;
        a = 0; b = 0; op = 2'b00;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // ------------------------------------------------------------------
        // Test 1: ADD - normal operation
        // ------------------------------------------------------------------
        @(posedge clk);
        a = 32'd15; b = 32'd10; op = 2'b00;
        check(1, "ADD 15+10=25", 32'd25, 1'b0);

        // ------------------------------------------------------------------
        // Test 2: ADD - all-zero inputs (zero flag)
        // ------------------------------------------------------------------
        @(posedge clk);
        a = 32'd0; b = 32'd0; op = 2'b00;
        check(2, "ADD 0+0=0 zero=1", 32'd0, 1'b1);

        // ------------------------------------------------------------------
        // Test 3: SUB - normal operation
        // ------------------------------------------------------------------
        @(posedge clk);
        a = 32'd100; b = 32'd55; op = 2'b01;
        check(3, "SUB 100-55=45", 32'd45, 1'b0);

        // ------------------------------------------------------------------
        // Test 4: SUB - equal operands (zero flag, like BEQ rs1==rs2)
        // ------------------------------------------------------------------
        @(posedge clk);
        a = 32'd42; b = 32'd42; op = 2'b01;
        check(4, "SUB 42-42=0 zero=1 BEQ branch", 32'd0, 1'b1);

        // ------------------------------------------------------------------
        // Test 5: AND - normal operation (simulating address computation / mask)
        // ------------------------------------------------------------------
        @(posedge clk);
        a = 32'hFFFF_FFFF; b = 32'h0000_00FF; op = 2'b10;
        check(5, "AND 0xFFFFFFFF & 0xFF = 0xFF", 32'h0000_00FF, 1'b0);

        // ------------------------------------------------------------------
        // Test 6: AND - all-ones inputs (verifies maximum-value path)
        // ------------------------------------------------------------------
        @(posedge clk);
        a = 32'hFFFF_FFFF; b = 32'hFFFF_FFFF; op = 2'b10;
        check(6, "AND all-ones = all-ones", 32'hFFFF_FFFF, 1'b0);

        // ------------------------------------------------------------------
        // Test 7: OR - simulating LW/SW address generation (base + offset)
        // ------------------------------------------------------------------
        @(posedge clk);
        a = 32'h0000_1000; b = 32'h0000_0004; op = 2'b11;
        check(7, "OR 0x1000 | 0x4 = 0x1004", 32'h0000_1004, 1'b0);

        // ------------------------------------------------------------------
        // Test 8: OR - all-zero inputs
        // ------------------------------------------------------------------
        @(posedge clk);
        a = 32'd0; b = 32'd0; op = 2'b11;
        check(8, "OR 0|0=0 zero=1", 32'd0, 1'b1);

        // ------------------------------------------------------------------
        // Test 9: ADD - maximum value (overflow wrap-around)
        // ------------------------------------------------------------------
        @(posedge clk);
        a = 32'hFFFF_FFFF; b = 32'd1; op = 2'b00;
        check(9, "ADD 0xFFFFFFFF+1=0 overflow zero=1", 32'd0, 1'b1);

        // ------------------------------------------------------------------
        // Test 10: SUB - result non-zero, negative (two's complement)
        // ------------------------------------------------------------------
        @(posedge clk);
        a = 32'd5; b = 32'd10; op = 2'b01;
        check(10, "SUB 5-10=0xFFFFFFFB non-zero", 32'hFFFF_FFFB, 1'b0);

        // ------------------------------------------------------------------
        // Test 11: ADD simulating SW effective address (base 0x100, offset 8)
        // ------------------------------------------------------------------
        @(posedge clk);
        a = 32'h0000_0100; b = 32'h0000_0008; op = 2'b00;
        check(11, "ADD SW addr 0x100+8=0x108", 32'h0000_0108, 1'b0);

        // ------------------------------------------------------------------
        // Test 12: ADD simulating LW effective address (base 0x200, offset 4)
        // ------------------------------------------------------------------
        @(posedge clk);
        a = 32'h0000_0200; b = 32'h0000_0004; op = 2'b00;
        check(12, "ADD LW addr 0x200+4=0x204", 32'h0000_0204, 1'b0);

        // ------------------------------------------------------------------
        // Summary
        // ------------------------------------------------------------------
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
