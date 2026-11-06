`timescale 1ns/1ns

module tb_cpu_alu;

    // DUT connections
    reg  [31:0] a, b;
    reg  [1:0]  op;
    wire [31:0] result;
    wire        zero;

    // Clock (required by general requirements even if DUT is combinational)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Synchronous reset signal (required by general requirements)
    reg rst;

    // Instantiate DUT
    cpu_alu uut (
        .a      (a),
        .b      (b),
        .op     (op),
        .result (result),
        .zero   (zero)
    );

    // Task for checking results
    task check;
        input [31:0] expected_result;
        input        expected_zero;
        input [63:0] desc_val; // not used for string, just a placeholder
        begin
            // Checking is done inline after task call
        end
    endtask

    integer fail_count;

    initial begin
        fail_count = 0;
        a   = 0;
        b   = 0;
        op  = 0;
        rst = 1;

        // Assert reset for 5 rising clock edges
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        // Allow one cycle after reset deassertion
        @(posedge clk);
        #1; // small delay for combinational settling

        // -------------------------------------------------------------------
        // Test 1: ADD - Normal operation: 5 + 3 = 8
        // -------------------------------------------------------------------
        a  = 32'd5;
        b  = 32'd3;
        op = 2'b00;
        #1;
        if (result === 32'd8 && zero === 1'b0) begin
            $display("PASS: ADD 5+3=8, zero=0");
        end else begin
            $display("FAIL: ADD 5+3 expected result=8 zero=0, got result=%0d zero=%0b", result, zero);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------------------
        // Test 2: ADD - All-zero inputs: 0 + 0 = 0, zero flag = 1
        // -------------------------------------------------------------------
        a  = 32'd0;
        b  = 32'd0;
        op = 2'b00;
        #1;
        if (result === 32'd0 && zero === 1'b1) begin
            $display("PASS: ADD 0+0=0, zero=1");
        end else begin
            $display("FAIL: ADD 0+0 expected result=0 zero=1, got result=%0d zero=%0b", result, zero);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------------------
        // Test 3: ADD - All-ones (max value): 0xFFFFFFFF + 1 = 0 (overflow), zero=1
        // -------------------------------------------------------------------
        a  = 32'hFFFFFFFF;
        b  = 32'd1;
        op = 2'b00;
        #1;
        if (result === 32'd0 && zero === 1'b1) begin
            $display("PASS: ADD 0xFFFFFFFF+1=0 (overflow), zero=1");
        end else begin
            $display("FAIL: ADD 0xFFFFFFFF+1 expected result=0 zero=1, got result=%0h zero=%0b", result, zero);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------------------
        // Test 4: SUB - Normal operation: 10 - 4 = 6
        // -------------------------------------------------------------------
        a  = 32'd10;
        b  = 32'd4;
        op = 2'b01;
        #1;
        if (result === 32'd6 && zero === 1'b0) begin
            $display("PASS: SUB 10-4=6, zero=0");
        end else begin
            $display("FAIL: SUB 10-4 expected result=6 zero=0, got result=%0d zero=%0b", result, zero);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------------------
        // Test 5: SUB - rs1==rs2 (BEQ condition): 7 - 7 = 0, zero=1
        // -------------------------------------------------------------------
        a  = 32'd7;
        b  = 32'd7;
        op = 2'b01;
        #1;
        if (result === 32'd0 && zero === 1'b1) begin
            $display("PASS: SUB 7-7=0 (BEQ: rs1==rs2), zero=1");
        end else begin
            $display("FAIL: SUB 7-7 (BEQ) expected result=0 zero=1, got result=%0d zero=%0b", result, zero);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------------------
        // Test 6: AND - Normal operation: 0xF0F0F0F0 & 0x0F0F0F0F = 0
        // -------------------------------------------------------------------
        a  = 32'hF0F0F0F0;
        b  = 32'h0F0F0F0F;
        op = 2'b10;
        #1;
        if (result === 32'h00000000 && zero === 1'b1) begin
            $display("PASS: AND 0xF0F0F0F0 & 0x0F0F0F0F = 0, zero=1");
        end else begin
            $display("FAIL: AND 0xF0F0F0F0 & 0x0F0F0F0F expected 0 zero=1, got result=%0h zero=%0b", result, zero);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------------------
        // Test 7: AND - All-ones: 0xFFFFFFFF & 0xFFFFFFFF = 0xFFFFFFFF
        // -------------------------------------------------------------------
        a  = 32'hFFFFFFFF;
        b  = 32'hFFFFFFFF;
        op = 2'b10;
        #1;
        if (result === 32'hFFFFFFFF && zero === 1'b0) begin
            $display("PASS: AND 0xFFFFFFFF & 0xFFFFFFFF = 0xFFFFFFFF, zero=0");
        end else begin
            $display("FAIL: AND 0xFFFFFFFF & 0xFFFFFFFF expected 0xFFFFFFFF zero=0, got result=%0h zero=%0b", result, zero);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------------------
        // Test 8: OR - Normal operation: 0xA0A0A0A0 | 0x0B0B0B0B = 0xABABABAB
        // -------------------------------------------------------------------
        a  = 32'hA0A0A0A0;
        b  = 32'h0B0B0B0B;
        op = 2'b11;
        #1;
        if (result === 32'hABABABAB && zero === 1'b0) begin
            $display("PASS: OR 0xA0A0A0A0 | 0x0B0B0B0B = 0xABABABAB, zero=0");
        end else begin
            $display("FAIL: OR 0xA0A0A0A0 | 0x0B0B0B0B expected 0xABABABAB zero=0, got result=%0h zero=%0b", result, zero);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------------------
        // Test 9: ADD - LW-style: base + offset address computation: 0x100 + 4 = 0x104
        // -------------------------------------------------------------------
        a  = 32'h00000100;
        b  = 32'h00000004;
        op = 2'b00;
        #1;
        if (result === 32'h00000104 && zero === 1'b0) begin
            $display("PASS: ADD (LW addr) 0x100+4=0x104, zero=0");
        end else begin
            $display("FAIL: ADD (LW addr) 0x100+4 expected 0x104 zero=0, got result=%0h zero=%0b", result, zero);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------------------
        // Test 10: ADD - SW-style: base + offset address computation: 0x200 + 8 = 0x208
        // -------------------------------------------------------------------
        a  = 32'h00000200;
        b  = 32'h00000008;
        op = 2'b00;
        #1;
        if (result === 32'h00000208 && zero === 1'b0) begin
            $display("PASS: ADD (SW addr) 0x200+8=0x208, zero=0");
        end else begin
            $display("FAIL: ADD (SW addr) 0x200+8 expected 0x208 zero=0, got result=%0h zero=%0b", result, zero);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------------------
        // Test 11: SUB - BEQ with rs1 != rs2: 5 - 3 = 2, zero=0 (no branch)
        // -------------------------------------------------------------------
        a  = 32'd5;
        b  = 32'd3;
        op = 2'b01;
        #1;
        if (result === 32'd2 && zero === 1'b0) begin
            $display("PASS: SUB (BEQ no-branch) 5-3=2, zero=0");
        end else begin
            $display("FAIL: SUB (BEQ no-branch) 5-3 expected result=2 zero=0, got result=%0d zero=%0b", result, zero);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------------------
        // Test 12: OR - All-zero inputs: 0 | 0 = 0, zero=1
        // -------------------------------------------------------------------
        a  = 32'd0;
        b  = 32'd0;
        op = 2'b11;
        #1;
        if (result === 32'd0 && zero === 1'b1) begin
            $display("PASS: OR 0|0=0, zero=1");
        end else begin
            $display("FAIL: OR 0|0 expected result=0 zero=1, got result=%0h zero=%0b", result, zero);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------------------
        // Summary
        // -------------------------------------------------------------------
        if (fail_count == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("%0d TEST(S) FAILED", fail_count);
        end

        $finish;
    end

endmodule
