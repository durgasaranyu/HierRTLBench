`timescale 1ns/1ps

module tb_sha256_sigma;

    // DUT inputs
    reg  [31:0] a, b, c;

    // DUT outputs
    wire [31:0] SIGMA0_a, SIGMA1_a, sigma0_b, sigma1_b, Ch_abc, Maj_abc;

    // Clock (not used by DUT but required by testbench rules)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not used by DUT but required by testbench rules)
    reg rst;
    integer i;

    // Instantiate DUT
    sha256_sigma uut (
        .a       (a),
        .b       (b),
        .c       (c),
        .SIGMA0_a(SIGMA0_a),
        .SIGMA1_a(SIGMA1_a),
        .sigma0_b(sigma0_b),
        .sigma1_b(sigma1_b),
        .Ch_abc  (Ch_abc),
        .Maj_abc (Maj_abc)
    );

    // Task to check and report
    task check;
        input [31:0] got;
        input [31:0] exp;
        input [255:0] desc;
        begin
            if (got === exp)
                $display("PASS: %s got=%08h exp=%08h", desc, got, exp);
            else
                $display("FAIL: %s got=%08h exp=%08h", desc, got, exp);
        end
    endtask

    // Helper function equivalents computed inline
    reg [31:0] exp_SIGMA0_a;
    reg [31:0] exp_SIGMA1_a;
    reg [31:0] exp_sigma0_b;
    reg [31:0] exp_sigma1_b;
    reg [31:0] exp_Ch_abc;
    reg [31:0] exp_Maj_abc;

    // Reset sequence (5 rising edges)
    initial begin
        rst = 1;
        a = 0; b = 0; c = 0;
        repeat (5) @(posedge clk);
        rst = 0;

        // ---------------------------------------------------------------
        // Test 1: All zeros
        // ---------------------------------------------------------------
        a = 32'h0000_0000; b = 32'h0000_0000; c = 32'h0000_0000;
        #1;
        exp_SIGMA0_a = {a[31:24], b[31:24], c[31:24]};
        exp_SIGMA1_a = {a[23:16], b[23:16], c[23:16]};
        exp_sigma0_b = {a[15:8],  b[15:8],  c[15:8]};
        exp_sigma1_b = {a[7:0],   b[7:0],   c[7:0]};
        exp_Ch_abc   = exp_SIGMA0_a + exp_SIGMA1_a;
        exp_Maj_abc  = exp_SIGMA0_a * exp_SIGMA1_a;
        check(SIGMA0_a, exp_SIGMA0_a, "T1 SIGMA0_a all-zeros");
        check(SIGMA1_a, exp_SIGMA1_a, "T1 SIGMA1_a all-zeros");
        check(sigma0_b, exp_sigma0_b, "T1 sigma0_b all-zeros");
        check(sigma1_b, exp_sigma1_b, "T1 sigma1_b all-zeros");
        check(Ch_abc,   exp_Ch_abc,   "T1 Ch_abc   all-zeros");
        check(Maj_abc,  exp_Maj_abc,  "T1 Maj_abc  all-zeros");

        // ---------------------------------------------------------------
        // Test 2: All ones
        // ---------------------------------------------------------------
        @(posedge clk);
        a = 32'hFFFF_FFFF; b = 32'hFFFF_FFFF; c = 32'hFFFF_FFFF;
        #1;
        exp_SIGMA0_a = {a[31:24], b[31:24], c[31:24]};
        exp_SIGMA1_a = {a[23:16], b[23:16], c[23:16]};
        exp_sigma0_b = {a[15:8],  b[15:8],  c[15:8]};
        exp_sigma1_b = {a[7:0],   b[7:0],   c[7:0]};
        exp_Ch_abc   = exp_SIGMA0_a + exp_SIGMA1_a;
        exp_Maj_abc  = exp_SIGMA0_a * exp_SIGMA1_a;
        check(SIGMA0_a, exp_SIGMA0_a, "T2 SIGMA0_a all-ones");
        check(SIGMA1_a, exp_SIGMA1_a, "T2 SIGMA1_a all-ones");
        check(sigma0_b, exp_sigma0_b, "T2 sigma0_b all-ones");
        check(sigma1_b, exp_sigma1_b, "T2 sigma1_b all-ones");
        check(Ch_abc,   exp_Ch_abc,   "T2 Ch_abc   all-ones");
        check(Maj_abc,  exp_Maj_abc,  "T2 Maj_abc  all-ones");

        // ---------------------------------------------------------------
        // Test 3: Typical values - known pattern
        // ---------------------------------------------------------------
        @(posedge clk);
        a = 32'hABCD_EF01; b = 32'h1234_5678; c = 32'h9ABC_DEF0;
        #1;
        exp_SIGMA0_a = {a[31:24], b[31:24], c[31:24]};
        exp_SIGMA1_a = {a[23:16], b[23:16], c[23:16]};
        exp_sigma0_b = {a[15:8],  b[15:8],  c[15:8]};
        exp_sigma1_b = {a[7:0],   b[7:0],   c[7:0]};
        exp_Ch_abc   = exp_SIGMA0_a + exp_SIGMA1_a;
        exp_Maj_abc  = exp_SIGMA0_a * exp_SIGMA1_a;
        check(SIGMA0_a, exp_SIGMA0_a, "T3 SIGMA0_a typical");
        check(SIGMA1_a, exp_SIGMA1_a, "T3 SIGMA1_a typical");
        check(sigma0_b, exp_sigma0_b, "T3 sigma0_b typical");
        check(sigma1_b, exp_sigma1_b, "T3 sigma1_b typical");
        check(Ch_abc,   exp_Ch_abc,   "T3 Ch_abc   typical");
        check(Maj_abc,  exp_Maj_abc,  "T3 Maj_abc  typical");

        // ---------------------------------------------------------------
        // Test 4: a=0, b=max, c=mid
        // ---------------------------------------------------------------
        @(posedge clk);
        a = 32'h0000_0000; b = 32'hFFFF_FFFF; c = 32'h8080_8080;
        #1;
        exp_SIGMA0_a = {a[31:24], b[31:24], c[31:24]};
        exp_SIGMA1_a = {a[23:16], b[23:16], c[23:16]};
        exp_sigma0_b = {a[15:8],  b[15:8],  c[15:8]};
        exp_sigma1_b = {a[7:0],   b[7:0],   c[7:0]};
        exp_Ch_abc   = exp_SIGMA0_a + exp_SIGMA1_a;
        exp_Maj_abc  = exp_SIGMA0_a * exp_SIGMA1_a;
        check(SIGMA0_a, exp_SIGMA0_a, "T4 SIGMA0_a a=0 b=max c=mid");
        check(SIGMA1_a, exp_SIGMA1_a, "T4 SIGMA1_a a=0 b=max c=mid");
        check(sigma0_b, exp_sigma0_b, "T4 sigma0_b a=0 b=max c=mid");
        check(sigma1_b, exp_sigma1_b, "T4 sigma1_b a=0 b=max c=mid");
        check(Ch_abc,   exp_Ch_abc,   "T4 Ch_abc   a=0 b=max c=mid");
        check(Maj_abc,  exp_Maj_abc,  "T4 Maj_abc  a=0 b=max c=mid");

        // ---------------------------------------------------------------
        // Test 5: a=max, b=0, c=0
        // ---------------------------------------------------------------
        @(posedge clk);
        a = 32'hFFFF_FFFF; b = 32'h0000_0000; c = 32'h0000_0000;
        #1;
        exp_SIGMA0_a = {a[31:24], b[31:24], c[31:24]};
        exp_SIGMA1_a = {a[23:16], b[23:16], c[23:16]};
        exp_sigma0_b = {a[15:8],  b[15:8],  c[15:8]};
        exp_sigma1_b = {a[7:0],   b[7:0],   c[7:0]};
        exp_Ch_abc   = exp_SIGMA0_a + exp_SIGMA1_a;
        exp_Maj_abc  = exp_SIGMA0_a * exp_SIGMA1_a;
        check(SIGMA0_a, exp_SIGMA0_a, "T5 SIGMA0_a a=max b=0 c=0");
        check(SIGMA1_a, exp_SIGMA1_a, "T5 SIGMA1_a a=max b=0 c=0");
        check(sigma0_b, exp_sigma0_b, "T5 sigma0_b a=max b=0 c=0");
        check(sigma1_b, exp_sigma1_b, "T5 sigma1_b a=max b=0 c=0");
        check(Ch_abc,   exp_Ch_abc,   "T5 Ch_abc   a=max b=0 c=0");
        check(Maj_abc,  exp_Maj_abc,  "T5 Maj_abc  a=max b=0 c=0");

        // ---------------------------------------------------------------
        // Test 6: Alternating bit pattern
        // ---------------------------------------------------------------
        @(posedge clk);
        a = 32'hAAAA_AAAA; b = 32'h5555_5555; c = 32'hAAAA_5555;
        #1;
        exp_SIGMA0_a = {a[31:24], b[31:24], c[31:24]};
        exp_SIGMA1_a = {a[23:16], b[23:16], c[23:16]};
        exp_sigma0_b = {a[15:8],  b[15:8],  c[15:8]};
        exp_sigma1_b = {a[7:0],   b[7:0],   c[7:0]};
        exp_Ch_abc   = exp_SIGMA0_a + exp_SIGMA1_a;
        exp_Maj_abc  = exp_SIGMA0_a * exp_SIGMA1_a;
        check(SIGMA0_a, exp_SIGMA0_a, "T6 SIGMA0_a alternating");
        check(SIGMA1_a, exp_SIGMA1_a, "T6 SIGMA1_a alternating");
        check(sigma0_b, exp_sigma0_b, "T6 sigma0_b alternating");
        check(sigma1_b, exp_sigma1_b, "T6 sigma1_b alternating");
        check(Ch_abc,   exp_Ch_abc,   "T6 Ch_abc   alternating");
        check(Maj_abc,  exp_Maj_abc,  "T6 Maj_abc  alternating");

        // ---------------------------------------------------------------
        // Test 7: SHA-256 initial hash values for a,b,c
        // ---------------------------------------------------------------
        @(posedge clk);
        a = 32'h6a09e667; b = 32'hbb67ae85; c = 32'h3c6ef372;
        #1;
        exp_SIGMA0_a = {a[31:24], b[31:24], c[31:24]};
        exp_SIGMA1_a = {a[23:16], b[23:16], c[23:16]};
        exp_sigma0_b = {a[15:8],  b[15:8],  c[15:8]};
        exp_sigma1_b = {a[7:0],   b[7:0],   c[7:0]};
        exp_Ch_abc   = exp_SIGMA0_a + exp_SIGMA1_a;
        exp_Maj_abc  = exp_SIGMA0_a * exp_SIGMA1_a;
        check(SIGMA0_a, exp_SIGMA0_a, "T7 SIGMA0_a SHA256-IVs");
        check(SIGMA1_a, exp_SIGMA1_a, "T7 SIGMA1_a SHA256-IVs");
        check(sigma0_b, exp_sigma0_b, "T7 sigma0_b SHA256-IVs");
        check(sigma1_b, exp_sigma1_b, "T7 sigma1_b SHA256-IVs");
        check(Ch_abc,   exp_Ch_abc,   "T7 Ch_abc   SHA256-IVs");
        check(Maj_abc,  exp_Maj_abc,  "T7 Maj_abc  SHA256-IVs");

        // ---------------------------------------------------------------
        // Test 8: Single bit set in each input
        // ---------------------------------------------------------------
        @(posedge clk);
        a = 32'h8000_0000; b = 32'h0000_0001; c = 32'h0100_0000;
        #1;
        exp_SIGMA0_a = {a[31:24], b[31:24], c[31:24]};
        exp_SIGMA1_a = {a[23:16], b[23:16], c[23:16]};
        exp_sigma0_b = {a[15:8],  b[15:8],  c[15:8]};
        exp_sigma1_b = {a[7:0],   b[7:0],   c[7:0]};
        exp_Ch_abc   = exp_SIGMA0_a + exp_SIGMA1_a;
        exp_Maj_abc  = exp_SIGMA0_a * exp_SIGMA1_a;
        check(SIGMA0_a, exp_SIGMA0_a, "T8 SIGMA0_a single-bits");
        check(SIGMA1_a, exp_SIGMA1_a, "T8 SIGMA1_a single-bits");
        check(sigma0_b, exp_sigma0_b, "T8 sigma0_b single-bits");
        check(sigma1_b, exp_sigma1_b, "T8 sigma1_b single-bits");
        check(Ch_abc,   exp_Ch_abc,   "T8 Ch_abc   single-bits");
        check(Maj_abc,  exp_Maj_abc,  "T8 Maj_abc  single-bits");

        // ---------------------------------------------------------------
        // Test 9: Overflow in Ch_abc (addition wr
