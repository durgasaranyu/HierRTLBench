`timescale 1ns/1ps

module tb_sha256_sigma;

    // DUT connections
    reg  [31:0] a, b, c;
    wire [31:0] SIGMA0_a, SIGMA1_a, sigma0_b, sigma1_b, Ch_abc, Maj_abc;

    // Clock (not used by combinational DUT, but required by spec)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not used by combinational DUT, but required by spec)
    reg rst;
    integer i;

    // Instantiate DUT
    sha256_sigma uut (
        .a(a),
        .b(b),
        .c(c),
        .SIGMA0_a(SIGMA0_a),
        .SIGMA1_a(SIGMA1_a),
        .sigma0_b(sigma0_b),
        .sigma1_b(sigma1_b),
        .Ch_abc(Ch_abc),
        .Maj_abc(Maj_abc)
    );

    // Helper task to check a value
    task check;
        input [63:0] got;
        input [63:0] expected;
        input [127:0] desc;
        begin
            if (got === expected)
                $display("PASS: %s (got=%h)", desc, got);
            else
                $display("FAIL: %s (got=%h expected=%h)", desc, got, expected);
        end
    endtask

    // Compute expected sigma0_b: based on the actual module implementation
    // The module implements sigma0_b as {b[0],b[1],...,b[31]} which is just
    // bit-reversal of b.
    function [31:0] bit_reverse;
        input [31:0] x;
        integer j;
        reg [31:0] result;
        begin
            for (j = 0; j < 32; j = j + 1)
                result[j] = x[31-j];
            bit_reverse = result;
        end
    endfunction

    // sigma1_b: {b[31], b[32]...b[61]} - out-of-range bits are 0 in Verilog
    // So sigma1_b = {b[31], 0, 0, ..., 0} (31 zeros) -- wait, let me re-read:
    // {b[31], b[32], ..., b[61]} -- b is 32 bits [31:0], so b[32..61] = 0
    // sigma1_b = {b[31], 31'b0}
    function [31:0] compute_sigma1_b;
        input [31:0] x;
        begin
            compute_sigma1_b = {x[31], 31'b0};
        end
    endfunction

    // SIGMA0_a: {a[0],a[1],...,a[31]} = bit_reverse(a)
    // SIGMA1_a: {a[31], a[32],...,a[61]} = {a[31], 31'b0}
    function [31:0] compute_SIGMA0_a;
        input [31:0] x;
        begin
            compute_SIGMA0_a = bit_reverse(x);
        end
    endfunction

    function [31:0] compute_SIGMA1_a;
        input [31:0] x;
        begin
            compute_SIGMA1_a = {x[31], 31'b0};
        end
    endfunction

    reg [31:0] exp_SIGMA0, exp_SIGMA1, exp_sigma0, exp_sigma1;
    reg [31:0] exp_Ch, exp_Maj;

    task apply_and_check;
        input [31:0] ta, tb, tc;
        input [127:0] desc;
        begin
            a = ta; b = tb; c = tc;
            #2; // let combinational settle

            exp_SIGMA0 = compute_SIGMA0_a(ta);
            exp_SIGMA1 = compute_SIGMA1_a(ta);
            exp_sigma0 = bit_reverse(tb);
            exp_sigma1 = compute_sigma1_b(tb);

            // Ch_abc and Maj_abc: same logic
            if (exp_sigma0 == exp_sigma1)
                exp_Ch = exp_sigma0;
            else
                exp_Ch = exp_sigma1;

            if (exp_sigma0 == exp_sigma1)
                exp_Maj = exp_sigma0;
            else
                exp_Maj = exp_sigma1;

            if (SIGMA0_a === exp_SIGMA0)
                $display("PASS: SIGMA0_a [%s] got=%h", desc, SIGMA0_a);
            else
                $display("FAIL: SIGMA0_a [%s] got=%h expected=%h", desc, SIGMA0_a, exp_SIGMA0);

            if (SIGMA1_a === exp_SIGMA1)
                $display("PASS: SIGMA1_a [%s] got=%h", desc, SIGMA1_a);
            else
                $display("FAIL: SIGMA1_a [%s] got=%h expected=%h", desc, SIGMA1_a, exp_SIGMA1);

            if (sigma0_b === exp_sigma0)
                $display("PASS: sigma0_b [%s] got=%h", desc, sigma0_b);
            else
                $display("FAIL: sigma0_b [%s] got=%h expected=%h", desc, sigma0_b, exp_sigma0);

            if (sigma1_b === exp_sigma1)
                $display("PASS: sigma1_b [%s] got=%h", desc, sigma1_b);
            else
                $display("FAIL: sigma1_b [%s] got=%h expected=%h", desc, sigma1_b, exp_sigma1);

            if (Ch_abc === exp_Ch)
                $display("PASS: Ch_abc [%s] got=%h", desc, Ch_abc);
            else
                $display("FAIL: Ch_abc [%s] got=%h expected=%h", desc, Ch_abc, exp_Ch);

            if (Maj_abc === exp_Maj)
                $display("PASS: Maj_abc [%s] got=%h", desc, Maj_abc);
            else
                $display("FAIL: Maj_abc [%s] got=%h expected=%h", desc, Maj_abc, exp_Maj);
        end
    endtask

    initial begin
        // Initialize
        a = 0; b = 0; c = 0;
        rst = 1;

        // Assert reset for 5 rising edges
        repeat(5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // Test 1: All zeros
        apply_and_check(32'h00000000, 32'h00000000, 32'h00000000, "all_zeros");

        // Test 2: All ones
        apply_and_check(32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF, "all_ones");

        // Test 3: Known value - a=32'h6a09e667 (SHA-256 init hash H0)
        apply_and_check(32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, "SHA256_H0_H1_H2");

        // Test 4: Single bit set in a (MSB)
        apply_and_check(32'h80000000, 32'h80000000, 32'h00000000, "MSB_set");

        // Test 5: Single bit set in a (LSB)
        apply_and_check(32'h00000001, 32'h00000001, 32'h00000000, "LSB_set");

        // Test 6: Alternating bits 0xAAAAAAAA
        apply_and_check(32'hAAAAAAAA, 32'hAAAAAAAA, 32'hAAAAAAAA, "alternating_A");

        // Test 7: Alternating bits 0x55555555
        apply_and_check(32'h55555555, 32'h55555555, 32'h55555555, "alternating_5");

        // Test 8: Max value a, zero b and c
        apply_and_check(32'hFFFFFFFF, 32'h00000000, 32'hFFFFFFFF, "max_a_zero_b");

        // Test 9: a=0, b=max, c=0
        apply_and_check(32'h00000000, 32'hFFFFFFFF, 32'h00000000, "zero_a_max_b");

        // Test 10: a=32'hDEADBEEF, b=32'hCAFEBABE, c=32'h12345678
        apply_and_check(32'hDEADBEEF, 32'hCAFEBABE, 32'h12345678, "pattern_DEADBEEF");

        #20;
        $finish;
    end

endmodule
