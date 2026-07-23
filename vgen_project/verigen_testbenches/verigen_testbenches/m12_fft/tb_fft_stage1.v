`timescale 1ns/1ps

module tb_fft_stage1;

    // DUT connections
    reg  signed [127:0] xre_flat;
    reg  signed [127:0] xim_flat;
    wire signed [127:0] s1re_flat;
    wire signed [127:0] s1im_flat;

    // Instantiate DUT
    fft_stage1 uut (
        .xre_flat(xre_flat),
        .xim_flat(xim_flat),
        .s1re_flat(s1re_flat),
        .s1im_flat(s1im_flat)
    );

    // Clock generation (not strictly needed for combinational module, but required by spec)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not a port, but satisfy spec requirement)
    reg rst;
    integer rst_count;
    initial begin
        rst = 1;
        rst_count = 0;
    end

    // Helper integers and task variables
    integer i;
    reg signed [15:0] in_re [0:7];
    reg signed [15:0] in_im [0:7];
    reg signed [15:0] exp_re [0:7];
    reg signed [15:0] exp_im [0:7];
    reg signed [15:0] got_re [0:7];
    reg signed [15:0] got_im [0:7];
    reg pass;
    integer fail_count;

    // Build flat buses from arrays
    task build_flat;
        integer b;
        begin
            for (b = 0; b < 8; b = b + 1) begin
                xre_flat[b*16 +: 16] = in_re[b];
                xim_flat[b*16 +: 16] = in_im[b];
            end
        end
    endtask

    // Read flat outputs into arrays
    task read_flat;
        integer b;
        begin
            for (b = 0; b < 8; b = b + 1) begin
                got_re[b] = s1re_flat[b*16 +: 16];
                got_im[b] = s1im_flat[b*16 +: 16];
            end
        end
    endtask

    // Check results
    task check_result;
        input [255:0] desc; // use as identifier (just print pass/fail)
        integer b;
        begin
            pass = 1;
            for (b = 0; b < 8; b = b + 1) begin
                if (got_re[b] !== exp_re[b]) pass = 0;
                if (got_im[b] !== exp_im[b]) pass = 0;
            end
            if (pass)
                $display("PASS: %s", desc);
            else begin
                $display("FAIL: %s", desc);
                for (b = 0; b < 8; b = b + 1) begin
                    $display("  [%0d] got_re=%0d exp_re=%0d  got_im=%0d exp_im=%0d",
                             b, got_re[b], exp_re[b], got_im[b], exp_im[b]);
                end
                fail_count = fail_count + 1;
            end
        end
    endtask

    // The module performs 4 butterflies with W8^0 (twiddle = 1+0j):
    // For pairs (0,4),(1,5),(2,6),(3,7):
    //   out_hi = in_hi + in_lo
    //   out_lo = in_hi - in_lo
    // (twiddle multiplication by 1 is identity)
    // Note: The module description says twiddle W8^0, so tw_re=32767, tw_im=0
    // twiddle*in_lo = in_lo (scaled by 32767/32768 ≈ 1, we treat as exact 1 for Q1.15)
    // The butterfly: out_hi = in_hi + tw*in_lo, out_lo = in_hi - tw*in_lo
    // With tw_re=32767, tw_im=0: tw*x = (32767*x_re)/32768 + j*(32767*x_im)/32768
    // But since the module is given (and may have duplicated declarations causing issues),
    // we test what the module actually produces as a combinational function.
    // We will compute expected values assuming ideal W^0 butterfly (add/subtract):

    task compute_expected_w0_butterfly;
        // Pairs: (0,4),(1,5),(2,6),(3,7)
        // twiddle applied to lo element (index 4,5,6,7)
        // For W^0: twiddle_re=32767, twiddle_im=0
        // twiddle_mult_re = (tw_re * lo_re - tw_im * lo_im) >> 15
        //                 = (32767 * lo_re) >> 15  ≈ lo_re (for most values)
        // twiddle_mult_im = (tw_re * lo_im + tw_im * lo_re) >> 15
        //                 = (32767 * lo_im) >> 15  ≈ lo_im
        // out_hi_re = hi_re + twiddle_mult_re
        // out_hi_im = hi_im + twiddle_mult_im
        // out_lo_re = hi_re - twiddle_mult_re
        // out_lo_im = hi_im - twiddle_mult_im
        // We use the approximation that 32767*x >> 15 = x (loses 1 LSB for large x)
        // For simplicity and robustness, we use the exact formula.
        integer p;
        reg signed [31:0] tw_re_val, tw_im_val;
        reg signed [31:0] lo_re_32, lo_im_32;
        reg signed [15:0] tm_re, tm_im;
        begin
            tw_re_val = 32767;
            tw_im_val = 0;
            for (p = 0; p < 4; p = p + 1) begin
                lo_re_32 = in_re[p+4];
                lo_im_32 = in_im[p+4];
                // twiddle multiply
                tm_re = (tw_re_val * lo_re_32 - tw_im_val * lo_im_32) >>> 15;
                tm_im = (tw_re_val * lo_im_32 + tw_im_val * lo_re_32) >>> 15;
                // butterfly
                exp_re[p]   = in_re[p] + tm_re;
                exp_im[p]   = in_im[p] + tm_im;
                exp_re[p+4] = in_re[p] - tm_re;
                exp_im[p+4] = in_im[p] - tm_im;
            end
        end
    endtask

    initial begin
        fail_count = 0;

        // Assert reset for 5 rising edges
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // -------------------------------------------------------
        // Test 1: All-zero inputs
        // -------------------------------------------------------
        for (i = 0; i < 8; i = i + 1) begin
            in_re[i] = 16'sd0;
            in_im[i] = 16'sd0;
        end
        build_flat;
        #2;
        read_flat;
        compute_expected_w0_butterfly;
        check_result("All-zero inputs");

        // -------------------------------------------------------
        // Test 2: DC input x[0]=1, rest zero (real)
        // -------------------------------------------------------
        for (i = 0; i < 8; i = i + 1) begin
            in_re[i] = 16'sd0;
            in_im[i] = 16'sd0;
        end
        in_re[0] = 16'sd1;
        build_flat;
        #2;
        read_flat;
        compute_expected_w0_butterfly;
        check_result("DC input x[0]=1 rest zero");

        // -------------------------------------------------------
        // Test 3: W^0 case - hi=100, lo=50, im=0
        // -------------------------------------------------------
        for (i = 0; i < 8; i = i + 1) begin
            in_re[i] = 16'sd0;
            in_im[i] = 16'sd0;
        end
        in_re[0] = 16'sd100;
        in_re[4] = 16'sd50;
        build_flat;
        #2;
        read_flat;
        compute_expected_w0_butterfly;
        check_result("W^0: hi_re=100 lo_re=50");

        // -------------------------------------------------------
        // Test 4: All-ones inputs (all 16'hFFFF = -1 signed)
        // -------------------------------------------------------
        for (i = 0; i < 8; i = i + 1) begin
            in_re[i] = -16'sd1;
            in_im[i] = -16'sd1;
        end
        build_flat;
        #2;
        read_flat;
        compute_expected_w0_butterfly;
        check_result("All-ones (all -1 signed) inputs");

        // -------------------------------------------------------
        // Test 5: Maximum positive value Q1.15 = 32767
        // -------------------------------------------------------
        for (i = 0; i < 8; i = i + 1) begin
            in_re[i] = 16'sd32767;
            in_im[i] = 16'sd0;
        end
        build_flat;
        #2;
        read_flat;
        compute_expected_w0_butterfly;
        check_result("Max positive real inputs 32767");

        // -------------------------------------------------------
        // Test 6: Maximum negative value Q1.15 = -32768
        // -------------------------------------------------------
        for (i = 0; i < 8; i = i + 1) begin
            in_re[i] = -16'sd32768;
            in_im[i] = 16'sd0;
        end
        build_flat;
        #2;
        read_flat;
        compute_expected_w0_butterfly;
        check_result("Max negative real inputs -32768");

        // -------------------------------------------------------
        // Test 7: Mixed real/imaginary values
        // -------------------------------------------------------
        in_re[0] = 16'sd1000;  in_im[0] = 16'sd500;
        in_re[1] = 16'sd200;   in_im[1] = 16'sd300;
        in_re[2] = -16'sd100;  in_im[2] = 16'sd400;
        in_re[3] = 16'sd0;     in_im[3] = -16'sd600;
        in_re[4] = 16'sd800;   in_im[4] = 16'sd100;
        in_re[5] = -16'sd200;  in_im[5] = 16'sd700;
        in_re[6] = 16'sd300;   in_im[6] = -16'sd300;
        in_re[7] = 16'sd100;   in_im[7] = 16'sd200;
        build_flat;
        #2;
        read_flat;
        compute_expected_w0_butterfly;
        check_result("Mixed real/imaginary values");

        // -------------------------------------------------------
        // Test 8: Alternating positive/negative
        // -------------------------------------------------------
        in_re[0] = 16'sd10000;  in_im[0] = 16'sd0;
        in_re[1] = -16'sd10000; in_im[1] = 16'sd0;
        in_re[2] = 16'sd5000;   in_im[2] = -16'sd5000;
        in_re[3] = -16'sd5000;  in_im[3] = 16'sd5000;
        in_re[4] = 16'sd10000;  in_im[4] = 16'sd0;
        in_re[5] = -16'sd10000; in_im[5] = 16'sd0;
        in_re[6] = 16'sd5000;   in_im[6] = -16'sd5000;
        in_re[7] = -16'sd5000;  in_im[7] = 16'sd5000;
        build_flat;
        #2;
        read_flat;
        compute_expected_w0_butterfly;
        check_result("Alternating positive/negative");

        // -------------------------------------------------------
        // Test 9: Single non-zero imaginary component
        // -------------------------------------------------------
        for (i = 0; i < 8; i = i + 1) begin
            in_re[i] = 16'sd0;
            in_im[i] = 16'sd0;
        end
        in_im[3] = 16'sd1000;
        in_im[7] = 16'sd500;
        build_flat;
        #2;
        read_flat;
        compute_expected_w0_butterfly;
        check_result("Single non-zero imaginary only");

        // -------------------------------------------------------
        // Test 10: Impulse on index 4 only
        // -------------------------------------------------------
        for (i = 0; i < 8; i = i + 1) begin
            in_re[i] = 16'sd0;
            in_im[i] = 16'sd0;
        end
        in_re[4] = 16'sd16384;
        build_flat;
        #2;
        read_flat;
        compute_expected_w0_butterfly;
        check_result("Impulse on index 4 only");

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
