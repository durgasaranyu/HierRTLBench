`timescale 1ns/1ps

module tb_alu_logic;

    // Parameters
    parameter N = 8;

    // DUT connections
    reg  [N-1:0] a, b;
    reg  [1:0]   sel;
    wire [N-1:0] result;

    // Instantiate DUT
    alu_logic #(.N(N)) uut (
        .a(a),
        .b(b),
        .sel(sel),
        .result(result)
    );

    // Clock and reset (not used by this module, but required per testbench rules)
    reg clk, rst;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset assertion for exactly 5 rising edges
    integer i;
    initial begin
        rst = 1;
        for (i = 0; i < 5; i = i + 1)
            @(posedge clk);
        rst = 0;
    end

    // Expected result register
    reg [N-1:0] expected;

    // Delay for combinational settling
    task apply_and_check;
        input [N-1:0] in_a, in_b;
        input [1:0]   in_sel;
        input [N-1:0] exp_result;
        input [63:0]  test_num;
        begin
            a   = in_a;
            b   = in_b;
            sel = in_sel;
            #2; // wait for combinational logic
            if (result === exp_result)
                $display("PASS: Test %0d a=%0h b=%0h sel=%0b result=%0h", test_num, in_a, in_b, in_sel, result);
            else
                $display("FAIL: Test %0d a=%0h b=%0h sel=%0b result=%0h (expected %0h)", test_num, in_a, in_b, in_sel, result, exp_result);
        end
    endtask

    initial begin
        // Wait for reset deassertion
        @(negedge rst);
        #3;

        // The module logic:
        // sel=00: result = b  (sel[1]=0, sel[0]=0 => b)
        // sel=01: result = a  (sel[1]=0, sel[0]=1 => a)
        // sel=10: result = a  (sel[1]=1, sel[0]=0 => a)
        // sel=11: result = b  (sel[1]=1, sel[0]=1 => b)

        // Test 1: sel=00 => result = b, typical values
        apply_and_check(8'hAA, 8'h55, 2'b00, 8'h55, 1);

        // Test 2: sel=01 => result = a, typical values
        apply_and_check(8'hAA, 8'h55, 2'b01, 8'hAA, 2);

        // Test 3: sel=10 => result = a, typical values
        apply_and_check(8'hAA, 8'h55, 2'b10, 8'hAA, 3);

        // Test 4: sel=11 => result = b, typical values
        apply_and_check(8'hAA, 8'h55, 2'b11, 8'h55, 4);

        // Test 5: All-zero inputs, sel=00 => result = 0
        apply_and_check(8'h00, 8'h00, 2'b00, 8'h00, 5);

        // Test 6: All-ones inputs, sel=01 => result = a = 0xFF
        apply_and_check(8'hFF, 8'hFF, 2'b01, 8'hFF, 6);

        // Test 7: All-ones inputs, sel=11 => result = b = 0xFF
        apply_and_check(8'hFF, 8'hFF, 2'b11, 8'hFF, 7);

        // Test 8: All-zero a, nonzero b, sel=10 => result = a = 0x00
        apply_and_check(8'h00, 8'hAB, 2'b10, 8'h00, 8);

        // Test 9: All-zero b, nonzero a, sel=00 => result = b = 0x00
        apply_and_check(8'hAB, 8'h00, 2'b00, 8'h00, 9);

        // Test 10: Max value a=0xFF, b=0x00, sel=01 => result = a = 0xFF
        apply_and_check(8'hFF, 8'h00, 2'b01, 8'hFF, 10);

        // Test 11: Max value a=0xFF, b=0x00, sel=11 => result = b = 0x00
        apply_and_check(8'hFF, 8'h00, 2'b11, 8'h00, 11);

        // Test 12: Arbitrary values, sel=10 => result = a
        apply_and_check(8'h3C, 8'hC3, 2'b10, 8'h3C, 12);

        $finish;
    end

endmodule
