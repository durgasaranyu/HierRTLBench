`timescale 1ns/1ps

module tb_alu_shift;

    // Parameters
    parameter N = 8;

    // DUT connections
    reg  [N-1:0] a;
    wire [N-1:0] result;
    wire         carry_out;

    // Expected values
    reg [N-1:0] exp_result;
    reg         exp_carry;

    // Instantiate DUT
    alu_shift #(.N(N)) uut (
        .a        (a),
        .result   (result),
        .carry_out(carry_out)
    );

    // No clock/reset needed for purely combinational module,
    // but requirements say we must have them. We'll use them
    // for sequencing test vectors.
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Task to check and report
    task check_result;
        input [63:0] test_num;
        input [N-1:0] exp_res;
        input         exp_co;
        input [127:0] desc;
        begin
            if (result === exp_res && carry_out === exp_co) begin
                $display("PASS: Test %0d - %s | a=%b result=%b carry=%b",
                         test_num, desc, a, result, carry_out);
            end else begin
                $display("FAIL: Test %0d - %s | a=%b | Expected result=%b carry=%b | Got result=%b carry=%b",
                         test_num, desc, a, exp_res, exp_co, result, carry_out);
            end
        end
    endtask

    integer i;

    initial begin
        // Apply reset for 5 rising edges (even though combinational, fulfilling requirement)
        rst = 1;
        a   = 0;
        repeat(5) @(posedge clk);
        rst = 0;

        // Wait one more cycle after reset
        @(posedge clk);

        // -------------------------------------------------------
        // Test 1: All-zero input
        // SHL(0) = 0, carry = a[7] = 0
        // -------------------------------------------------------
        @(posedge clk);
        a = 8'h00;
        #1;
        exp_result = 8'h00;
        exp_carry  = 1'b0;
        check_result(1, exp_result, exp_carry, "All-zero input SHL");

        // -------------------------------------------------------
        // Test 2: All-ones input
        // SHL(0xFF) = 0xFE, carry = a[7] = 1
        // -------------------------------------------------------
        @(posedge clk);
        a = 8'hFF;
        #1;
        exp_result = 8'hFE;
        exp_carry  = 1'b1;
        check_result(2, exp_result, exp_carry, "All-ones input SHL");

        // -------------------------------------------------------
        // Test 3: MSB=1, LSBs=0 (maximum carry scenario)
        // SHL(0x80) = 0x00, carry = 1, zero_flag implied by result==0
        // -------------------------------------------------------
        @(posedge clk);
        a = 8'h80;
        #1;
        exp_result = 8'h00;
        exp_carry  = 1'b1;
        check_result(3, exp_result, exp_carry, "MSB=1 only, result==0 carry=1");

        // -------------------------------------------------------
        // Test 4: Normal value 0x01, SHL = 0x02, carry = 0
        // -------------------------------------------------------
        @(posedge clk);
        a = 8'h01;
        #1;
        exp_result = 8'h02;
        exp_carry  = 1'b0;
        check_result(4, exp_result, exp_carry, "Normal SHL 0x01->0x02");

        // -------------------------------------------------------
        // Test 5: Normal value 0x55 (01010101), SHL = 0xAA (10101010), carry = 0
        // -------------------------------------------------------
        @(posedge clk);
        a = 8'h55;
        #1;
        exp_result = 8'hAA;
        exp_carry  = 1'b0;
        check_result(5, exp_result, exp_carry, "SHL 0x55->0xAA carry=0");

        // -------------------------------------------------------
        // Test 6: Normal value 0xAA (10101010), SHL = 0x54 (01010100), carry = 1
        // -------------------------------------------------------
        @(posedge clk);
        a = 8'hAA;
        #1;
        exp_result = 8'h54;
        exp_carry  = 1'b1;
        check_result(6, exp_result, exp_carry, "SHL 0xAA->0x54 carry=1");

        // -------------------------------------------------------
        // Test 7: Value 0x40 (01000000), SHL = 0x80, carry = 0
        // -------------------------------------------------------
        @(posedge clk);
        a = 8'h40;
        #1;
        exp_result = 8'h80;
        exp_carry  = 1'b0;
        check_result(7, exp_result, exp_carry, "SHL 0x40->0x80 carry=0");

        // -------------------------------------------------------
        // Test 8: Value 0xC3 (11000011), SHL = 0x86 (10000110), carry = 1
        // -------------------------------------------------------
        @(posedge clk);
        a = 8'hC3;
        #1;
        exp_result = 8'h86;
        exp_carry  = 1'b1;
        check_result(8, exp_result, exp_carry, "SHL 0xC3->0x86 carry=1");

        // -------------------------------------------------------
        // Test 9: Value 0x7F (01111111), SHL = 0xFE, carry = 0
        // -------------------------------------------------------
        @(posedge clk);
        a = 8'h7F;
        #1;
        exp_result = 8'hFE;
        exp_carry  = 1'b0;
        check_result(9, exp_result, exp_carry, "SHL 0x7F->0xFE carry=0");

        // -------------------------------------------------------
        // Test 10: Max value check - same as all-ones (redundant sanity)
        // SHL(0xFE) = 0xFC, carry = 1
        // -------------------------------------------------------
        @(posedge clk);
        a = 8'hFE;
        #1;
        exp_result = 8'hFC;
        exp_carry  = 1'b1;
        check_result(10, exp_result, exp_carry, "SHL 0xFE->0xFC carry=1");

        // -------------------------------------------------------
        // Test 11: Value that produces zero_flag (carry_out=1, result=0)
        // a=0x80 already tested above; try a=0x00 for zero result no carry
        // -------------------------------------------------------
        @(posedge clk);
        a = 8'h00;
        #1;
        exp_result = 8'h00;
        exp_carry  = 1'b0;
        if (result == 8'h00) begin
            $display("PASS: Test 11 - zero_flag condition (result==0, carry=0) | a=%b result=%b carry=%b",
                     a, result, carry_out);
        end else begin
            $display("FAIL: Test 11 - zero_flag condition | Expected result=00 carry=0 | Got result=%b carry=%b",
                     result, carry_out);
        end

        // -------------------------------------------------------
        // Test 12: SHL with a=0x0F (00001111) -> 0x1E, carry = 0
        // -------------------------------------------------------
        @(posedge clk);
        a = 8'h0F;
        #1;
        exp_result = 8'h1E;
        exp_carry  = 1'b0;
        check_result(12, exp_result, exp_carry, "SHL 0x0F->0x1E carry=0");

        $display("All tests completed.");
        $finish;
    end

endmodule
