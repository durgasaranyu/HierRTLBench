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

    // No clock needed for purely combinational DUT,
    // but requirements ask for clock/reset infrastructure.
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Reset counter (not used by DUT but satisfies requirement)
    integer rst_count;
    initial begin
        rst = 1;
        rst_count = 0;
        // Hold reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        rst = 0;
    end

    // Test task
    task apply_and_check;
        input [N-1:0] test_a;
        input [N-1:0] expected_result;
        input         expected_carry;
        input [127:0] description;
        begin
            a = test_a;
            #2; // small delay for combinational settling
            exp_result = expected_result;
            exp_carry  = expected_carry;
            if (result === exp_result && carry_out === exp_carry) begin
                $display("PASS: %s | a=%b result=%b carry=%b",
                         description, test_a, result, carry_out);
            end else begin
                $display("FAIL: %s | a=%b | got result=%b carry=%b | expected result=%b carry=%b",
                         description, test_a, result, carry_out, exp_result, exp_carry);
            end
        end
    endtask

    integer i;

    initial begin
        // Wait for reset to finish
        a = 0;
        @(negedge rst); // wait until reset deasserts
        @(posedge clk); #1;

        // Test 1: All zeros input -> result=0, carry=0, zero_flag concept applies
        apply_and_check(8'h00, 8'h00, 1'b0, "SHL all-zeros");

        // Test 2: All ones input -> result=0xFE, carry=1
        apply_and_check(8'hFF, 8'hFE, 1'b1, "SHL all-ones");

        // Test 3: MSB=1, rest 0 -> result=0, carry=1
        apply_and_check(8'h80, 8'h00, 1'b1, "SHL MSB=1 others=0 carry=1 result=0");

        // Test 4: LSB=1, rest 0 -> result=2, carry=0
        apply_and_check(8'h01, 8'h02, 1'b0, "SHL LSB=1 others=0");

        // Test 5: Typical value 0x55 (01010101) -> 0xAA (10101010), carry=0
        apply_and_check(8'h55, 8'hAA, 1'b0, "SHL 0x55->0xAA no carry");

        // Test 6: Typical value 0xAA (10101010) -> 0x54 (01010100), carry=1
        apply_and_check(8'hAA, 8'h54, 1'b1, "SHL 0xAA->0x54 carry=1");

        // Test 7: 0x40 (01000000) -> 0x80 (10000000), carry=0
        apply_and_check(8'h40, 8'h80, 1'b0, "SHL 0x40->0x80 no carry");

        // Test 8: 0xC0 (11000000) -> 0x80 (10000000), carry=1
        apply_and_check(8'hC0, 8'h80, 1'b1, "SHL 0xC0->0x80 carry=1");

        // Test 9: 0x7F (01111111) -> 0xFE (11111110), carry=0
        apply_and_check(8'h7F, 8'hFE, 1'b0, "SHL 0x7F->0xFE no carry");

        // Test 10: 0xFF same as test 2, with max value double-check
        apply_and_check(8'hFF, 8'hFE, 1'b1, "SHL max-value 0xFF carry=1");

        // Test 11: Verify zero result when MSB=1 only: 0x80 -> result=0 (zero flag would be set)
        // Already covered in test 3; do another: 0x40 -> 0x80 (not zero)
        apply_and_check(8'h02, 8'h04, 1'b0, "SHL 0x02->0x04 normal");

        // Test 12: ADD/SUB/AND/OR/XOR are not present in this DUT (it only does SHL)
        // Test all 1s in upper nibble only: 0xF0 -> 0xE0, carry=1
        apply_and_check(8'hF0, 8'hE0, 1'b1, "SHL 0xF0->0xE0 carry=1");

        $display("All tests complete.");
        $finish;
    end

endmodule
