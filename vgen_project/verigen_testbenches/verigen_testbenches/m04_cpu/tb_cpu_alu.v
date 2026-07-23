`timescale 1ns/1ns

module tb_cpu_alu;

    // DUT connections
    reg  [31:0] a, b;
    reg  [1:0]  op;
    wire [31:0] result;
    wire        zero;

    // Clock (required by general requirements, even if DUT is combinational)
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

    // Task to apply reset for 5 rising edges
    integer i;
    initial begin
        rst = 1;
        a   = 0;
        b   = 0;
        op  = 0;
        // Hold reset for 5 rising edges
        repeat (5) @(posedge clk);
        rst = 0;

        // Small delay after reset
        #2;

        // ---------------------------------------------------------------
        // Test 1: ADD normal operation - 5 + 3 = 8
        // ---------------------------------------------------------------
        a  = 32'd5;
        b  = 32'd3;
        op = 2'b00;
        #1; // combinational, wait for settle
        if (result === 32'd8 && zero === 1'b0)
            $display("PASS: ADD 5+3=8, zero=0");
        else
            $display("FAIL: ADD 5+3=8, zero=0 | result=%0d zero=%0b", result, zero);

        // ---------------------------------------------------------------
        // Test 2: ADD all-zero inputs
        // ---------------------------------------------------------------
        a  = 32'd0;
        b  = 32'd0;
        op = 2'b00;
        #1;
        if (result === 32'd0 && zero === 1'b1)
            $display("PASS: ADD 0+0=0, zero=1");
        else
            $display("FAIL: ADD 0+0=0, zero=1 | result=%0d zero=%0b", result, zero);

        // ---------------------------------------------------------------
        // Test 3: ADD maximum value (overflow wraps around)
        // ---------------------------------------------------------------
        a  = 32'hFFFFFFFF;
        b  = 32'd1;
        op = 2'b00;
        #1;
        if (result === 32'd0 && zero === 1'b1)
            $display("PASS: ADD 0xFFFFFFFF+1=0 (overflow), zero=1");
        else
            $display("FAIL: ADD 0xFFFFFFFF+1 | result=%0h zero=%0b", result, zero);

        // ---------------------------------------------------------------
        // Test 4: SUB normal operation - 10 - 4 = 6
        // ---------------------------------------------------------------
        a  = 32'd10;
        b  = 32'd4;
        op = 2'b01;
        #1;
        if (result === 32'd6 && zero === 1'b0)
            $display("PASS: SUB 10-4=6, zero=0");
        else
            $display("FAIL: SUB 10-4=6, zero=0 | result=%0d zero=%0b", result, zero);

        // ---------------------------------------------------------------
        // Test 5: SUB equal values -> zero flag (BEQ-like check: rs1==rs2)
        // ---------------------------------------------------------------
        a  = 32'd42;
        b  = 32'd42;
        op = 2'b01;
        #1;
        if (result === 32'd0 && zero === 1'b1)
            $display("PASS: SUB 42-42=0 (BEQ: rs1==rs2), zero=1");
        else
            $display("FAIL: SUB 42-42=0 (BEQ: rs1==rs2) | result=%0d zero=%0b", result, zero);

        // ---------------------------------------------------------------
        // Test 6: AND normal operation
        // ---------------------------------------------------------------
        a  = 32'hFF00FF00;
        b  = 32'h0F0F0F0F;
        op = 2'b10;
        #1;
        // AND result: 0x0F000F00
        if (result === (32'hFF00FF00 & 32'h0F0F0F0F))
            $display("PASS: AND 0xFF00FF00 & 0x0F0F0F0F = 0x%0h", result);
        else
            $display("FAIL: AND 0xFF00FF00 & 0x0F0F0F0F | result=0x%0h", result);

        // ---------------------------------------------------------------
        // Test 7: OR normal operation
        // ---------------------------------------------------------------
        a  = 32'hAA00AA00;
        b  = 32'h0055BB55;
        op = 2'b11;
        #1;
        if (result === (32'hAA00AA00 | 32'h0055BB55))
            $display("PASS: OR 0xAA00AA00 | 0x0055BB55 = 0x%0h", result);
        else
            $display("FAIL: OR 0xAA00AA00 | 0x0055BB55 | result=0x%0h", result);

        // ---------------------------------------------------------------
        // Test 8: ADD - LW address computation (base + offset)
        // Simulates: LW rd, offset(rs1) -> ALU computes base+offset
        // ---------------------------------------------------------------
        a  = 32'h00001000; // base address (e.g., memory base)
        b  = 32'd8;        // offset
        op = 2'b00;
        #1;
        if (result === 32'h00001008 && zero === 1'b0)
            $display("PASS: LW address computation: base+offset=0x%0h", result);
        else
            $display("FAIL: LW address computation | result=0x%0h zero=%0b", result, zero);

        // ---------------------------------------------------------------
        // Test 9: ADD - SW address computation (base + offset)
        // Simulates: SW rs2, offset(rs1) -> ALU computes store address
        // ---------------------------------------------------------------
        a  = 32'h00002000; // base register value
        b  = 32'd16;       // offset
        op = 2'b00;
        #1;
        if (result === 32'h00002010 && zero === 1'b0)
            $display("PASS: SW address computation: base+offset=0x%0h", result);
        else
            $display("FAIL: SW address computation | result=0x%0h zero=%0b", result, zero);

        // ---------------------------------------------------------------
        // Test 10: SUB all-ones inputs -> result non-zero
        // ---------------------------------------------------------------
        a  = 32'hFFFFFFFF;
        b  = 32'hFFFFFFFF;
        op = 2'b01;
        #1;
        if (result === 32'd0 && zero === 1'b1)
            $display("PASS: SUB all-ones: 0xFFFFFFFF-0xFFFFFFFF=0, zero=1");
        else
            $display("FAIL: SUB all-ones | result=0x%0h zero=%0b", result, zero);

        // ---------------------------------------------------------------
        // Test 11: OR all-ones inputs
        // ---------------------------------------------------------------
        a  = 32'hFFFFFFFF;
        b  = 32'hFFFFFFFF;
        op = 2'b11;
        #1;
        if (result === 32'hFFFFFFFF && zero === 1'b0)
            $display("PASS: OR all-ones = 0xFFFFFFFF, zero=0");
        else
            $display("FAIL: OR all-ones | result=0x%0h zero=%0b", result, zero);

        // ---------------------------------------------------------------
        // Test 12: AND all-ones inputs
        // ---------------------------------------------------------------
        a  = 32'hFFFFFFFF;
        b  = 32'hFFFFFFFF;
        op = 2'b10;
        #1;
        if (result === 32'hFFFFFFFF && zero === 1'b0)
            $display("PASS: AND all-ones = 0xFFFFFFFF, zero=0");
        else
            $display("FAIL: AND all-ones | result=0x%0h zero=%0b", result, zero);

        // Wait a couple of clocks before finishing
        @(posedge clk);
        @(posedge clk);

        $finish;
    end

endmodule
