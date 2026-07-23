`timescale 1ns / 1ps

module tb_alu_flags;

    // DUT connections
    reg  [7:0] result;
    reg        carry_in;
    wire       zero_flag;
    wire       carry_flag;

    // Clock and reset (not used by combinational DUT, but required by testbench spec)
    reg clk;
    reg rst;

    // DUT instantiation
    alu_flags #(.N(8)) uut (
        .result(result),
        .carry_in(carry_in),
        .zero_flag(zero_flag),
        .carry_flag(carry_flag)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset for exactly 5 rising edges
    integer i;
    initial begin
        rst = 1;
        for (i = 0; i < 5; i = i + 1)
            @(posedge clk);
        rst = 0;
    end

    // Test vectors
    initial begin
        // Wait for reset to complete
        @(posedge clk); // edge 1
        @(posedge clk); // edge 2
        @(posedge clk); // edge 3
        @(posedge clk); // edge 4
        @(posedge clk); // edge 5
        @(posedge clk); // one more after deassertion

        // -------------------------------------------------------
        // Test 1: result=0, carry_in=0 → zero_flag=1, carry_flag=0
        // -------------------------------------------------------
        result   = 8'h00;
        carry_in = 1'b0;
        #2;
        if (zero_flag === 1'b1 && carry_flag === 1'b0)
            $display("PASS: Test 1 - result=0, carry_in=0: zero_flag=1, carry_flag=0");
        else
            $display("FAIL: Test 1 - result=0, carry_in=0: zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 2: result=0, carry_in=1 → zero_flag=1, carry_flag=1
        // -------------------------------------------------------
        result   = 8'h00;
        carry_in = 1'b1;
        #2;
        if (zero_flag === 1'b1 && carry_flag === 1'b1)
            $display("PASS: Test 2 - result=0, carry_in=1: zero_flag=1, carry_flag=1");
        else
            $display("FAIL: Test 2 - result=0, carry_in=1: zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 3: result=0xFF (all-ones), carry_in=0 → zero_flag=0, carry_flag=0
        // -------------------------------------------------------
        result   = 8'hFF;
        carry_in = 1'b0;
        #2;
        if (zero_flag === 1'b0 && carry_flag === 1'b0)
            $display("PASS: Test 3 - result=0xFF, carry_in=0: zero_flag=0, carry_flag=0");
        else
            $display("FAIL: Test 3 - result=0xFF, carry_in=0: zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 4: result=0xFF (all-ones), carry_in=1 → zero_flag=0, carry_flag=1
        //         (Simulates ADD overflow: 0xFF+1 wraps → carry=1, result=0 but here result=0xFF to test non-zero)
        // -------------------------------------------------------
        result   = 8'hFF;
        carry_in = 1'b1;
        #2;
        if (zero_flag === 1'b0 && carry_flag === 1'b1)
            $display("PASS: Test 4 - result=0xFF, carry_in=1: zero_flag=0, carry_flag=1");
        else
            $display("FAIL: Test 4 - result=0xFF, carry_in=1: zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 5: ADD overflow result=0x00 with carry=1 (0xFF+1)
        //         → zero_flag=1, carry_flag=1
        // -------------------------------------------------------
        result   = 8'h00;
        carry_in = 1'b1;
        #2;
        if (zero_flag === 1'b1 && carry_flag === 1'b1)
            $display("PASS: Test 5 - ADD overflow (result=0, carry=1): zero_flag=1, carry_flag=1");
        else
            $display("FAIL: Test 5 - ADD overflow (result=0, carry=1): zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 6: SHL with MSB=1 → carry_in=1 (carry out of MSB), result=non-zero
        //         Simulate: 0x81 << 1 = 0x02, carry=1
        // -------------------------------------------------------
        result   = 8'h02;
        carry_in = 1'b1;
        #2;
        if (zero_flag === 1'b0 && carry_flag === 1'b1)
            $display("PASS: Test 6 - SHL MSB=1 (result=0x02, carry=1): zero_flag=0, carry_flag=1");
        else
            $display("FAIL: Test 6 - SHL MSB=1 (result=0x02, carry=1): zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 7: SHL with MSB=0 → carry_in=0, result=non-zero
        //         Simulate: 0x01 << 1 = 0x02, carry=0
        // -------------------------------------------------------
        result   = 8'h02;
        carry_in = 1'b0;
        #2;
        if (zero_flag === 1'b0 && carry_flag === 1'b0)
            $display("PASS: Test 7 - SHL MSB=0 (result=0x02, carry=0): zero_flag=0, carry_flag=0");
        else
            $display("FAIL: Test 7 - SHL MSB=0 (result=0x02, carry=0): zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 8: AND/OR/XOR typical non-zero result, carry_in=0
        //         Simulate: 0xAB AND 0xCD = 0x89 (non-zero), carry=0
        // -------------------------------------------------------
        result   = 8'h89;
        carry_in = 1'b0;
        #2;
        if (zero_flag === 1'b0 && carry_flag === 1'b0)
            $display("PASS: Test 8 - AND result=0x89, carry=0: zero_flag=0, carry_flag=0");
        else
            $display("FAIL: Test 8 - AND result=0x89, carry=0: zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 9: XOR same operands → result=0, carry=0 → zero_flag=1
        // -------------------------------------------------------
        result   = 8'h00;
        carry_in = 1'b0;
        #2;
        if (zero_flag === 1'b1 && carry_flag === 1'b0)
            $display("PASS: Test 9 - XOR same ops (result=0, carry=0): zero_flag=1, carry_flag=0");
        else
            $display("FAIL: Test 9 - XOR same ops (result=0, carry=0): zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 10: Maximum value SUB non-zero result, carry=0
        //          Simulate: 0xFF - 0x01 = 0xFE, carry=0
        // -------------------------------------------------------
        result   = 8'hFE;
        carry_in = 1'b0;
        #2;
        if (zero_flag === 1'b0 && carry_flag === 1'b0)
            $display("PASS: Test 10 - SUB result=0xFE, carry=0: zero_flag=0, carry_flag=0");
        else
            $display("FAIL: Test 10 - SUB result=0xFE, carry=0: zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        // -------------------------------------------------------
        // Test 11: Verify combinational reset-like behavior:
        //          set all to 0 → zero=1, carry=0 (mirrors reset clear)
        // -------------------------------------------------------
        result   = 8'h00;
        carry_in = 1'b0;
        #2;
        if (zero_flag === 1'b1 && carry_flag === 1'b0)
            $display("PASS: Test 11 - All-zero inputs: zero_flag=1, carry_flag=0");
        else
            $display("FAIL: Test 11 - All-zero inputs: zero_flag=%b, carry_flag=%b", zero_flag, carry_flag);

        #10;
        $finish;
    end

endmodule
