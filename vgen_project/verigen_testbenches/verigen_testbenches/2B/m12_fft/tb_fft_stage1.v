`timescale 1ns/1ps

module tb_fft_stage1;

// Parameters
parameter WIDTH = 16;
parameter N = 8;

// DUT ports
reg  signed [127:0] xre_flat;
reg  signed [127:0] xim_flat;
wire signed [127:0] s1re_flat;
wire signed [127:0] s1im_flat;

// Clock and reset (module is combinational, but required by rules)
reg clk;
reg rst;

initial clk = 0;
always #5 clk = ~clk;

// Instantiate DUT
fft_stage1 uut (
    .xre_flat(xre_flat),
    .xim_flat(xim_flat),
    .s1re_flat(s1re_flat),
    .s1im_flat(s1im_flat)
);

// Helper tasks and functions
// Extract 16-bit signed sample k from a 128-bit flat bus
function signed [15:0] get_sample;
    input [127:0] bus;
    input integer k;
    begin
        get_sample = bus[k*16 +: 16];
    end
endfunction

// Build a 128-bit bus from 8 signed 16-bit values
// We'll do it inline in the test body

// Signed arithmetic helpers
function signed [15:0] s16;
    input [15:0] v;
    begin
        s16 = v;
    end
endfunction

// -------------------------------------------------------
// Reset
// -------------------------------------------------------
integer i;
integer pass_count;
integer fail_count;

// Intermediate expected values
reg signed [15:0] xre [0:7];
reg signed [15:0] xim [0:7];
reg signed [15:0] exp_re [0:7];
reg signed [15:0] exp_im [0:7];
reg signed [15:0] got_re [0:7];
reg signed [15:0] got_im [0:7];

// Build flat bus from arrays
reg [127:0] tmp_re_flat, tmp_im_flat;

integer k;

// For the butterfly at stage1: twiddle W8^0 = (32767, 0) / 32767 ≈ 1+0j
// out_hi[i] = in[i]  + in[i+4]
// out_lo[i] = in[i]  - in[i+4]   (for pairs (0,4),(1,5),(2,6),(3,7))
// But due to Q1.15 fixed-point arithmetic with twiddle multiplication:
// tw_re=32767, tw_im=0 → twiddle ≈ 1
// butterfly: 
//   out_hi_re = in_hi_re + (tw_re*in_lo_re - tw_im*in_lo_im)>>15
//   out_hi_im = in_hi_im + (tw_re*in_lo_im + tw_im*in_lo_re)>>15
//   out_lo_re = in_hi_re - (tw_re*in_lo_re - tw_im*in_lo_im)>>15
//   out_lo_im = in_hi_im - (tw_re*in_lo_im + tw_im*in_lo_re)>>15
// With tw_re=32767, tw_im=0:
//   tw*in_lo ≈ in_lo * 32767/32768 ≈ in_lo (close but not exact)
// The module description says twiddle W8^0, so for simplicity we compute:
//   tw_mult_re = (32767 * in_lo_re) >>> 15
//   tw_mult_im = (32767 * in_lo_im) >>> 15

task compute_expected;
    input signed [15:0] hi_re_in, hi_im_in, lo_re_in, lo_im_in;
    output signed [15:0] hi_re_out, hi_im_out, lo_re_out, lo_im_out;
    reg signed [31:0] tw_re_val, tw_im_val;
    reg signed [31:0] mult_re, mult_im;
    begin
        tw_re_val = 32767;
        tw_im_val = 0;
        // tw * lo = (tw_re*lo_re - tw_im*lo_im) + j*(tw_re*lo_im + tw_im*lo_re)
        mult_re = ((tw_re_val * lo_re_in) - (tw_im_val * lo_im_in)) >>> 15;
        mult_im = ((tw_re_val * lo_im_in) + (tw_im_val * lo_re_in)) >>> 15;
        hi_re_out = hi_re_in + mult_re[15:0];
        hi_im_out = hi_im_in + mult_im[15:0];
        lo_re_out = hi_re_in - mult_re[15:0];
        lo_im_out = hi_im_in - mult_im[15:0];
    end
endtask

// We need to be careful: the actual module implementation is truncated in the
// problem statement. Based on the description, it does 4 butterflies on pairs
// (0,4),(1,5),(2,6),(3,7) with twiddle W8^0.
// Outputs: positions 0..3 get "hi" of each butterfly, positions 4..7 get "lo"

task check_outputs;
    input [127:0] desc_len; // not used
    input [63:0] test_num;
    input [255:0] desc;
    reg signed [15:0] e_re, e_im, g_re, g_im;
    integer fail_local;
    begin
        fail_local = 0;
        for (k = 0; k < 8; k = k+1) begin
            g_re = s1re_flat[k*16 +: 16];
            g_im = s1im_flat[k*16 +: 16];
            if (k < 4) begin
                e_re = exp_re[k];
                e_im = exp_im[k];
            end else begin
                e_re = exp_re[k];
                e_im = exp_im[k];
            end
            if (g_re !== e_re || g_im !== e_im) begin
                fail_local = fail_local + 1;
                $display("  Mismatch at sample %0d: got (%0d,%0d) expected (%0d,%0d)",
                         k, g_re, g_im, e_re, e_im);
            end
        end
        if (fail_local == 0) begin
            $display("PASS: Test %0d - %s", test_num, desc);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test %0d - %s", test_num, desc);
            fail_count = fail_count + 1;
        end
    end
endtask

reg signed [31:0] mre, mim;

initial begin
    pass_count = 0;
    fail_count = 0;
    rst = 1;
    xre_flat = 0;
    xim_flat = 0;

    // Hold reset for 5 rising edges
    repeat(5) @(posedge clk);
    rst = 0;
    @(posedge clk);

    // -------------------------------------------------------
    // Test 1: All zeros
    // -------------------------------------------------------
    for (k = 0; k < 8; k = k+1) begin
        xre[k] = 0;
        xim[k] = 0;
    end
    tmp_re_flat = 0;
    tmp_im_flat = 0;
    for (k = 0; k < 8; k = k+1) begin
        tmp_re_flat[k*16 +: 16] = xre[k];
        tmp_im_flat[k*16 +: 16] = xim[k];
    end
    xre_flat = tmp_re_flat;
    xim_flat = tmp_im_flat;
    // All zero inputs => all zero outputs
    for (k = 0; k < 4; k = k+1) begin
        compute_expected(xre[k], xim[k], xre[k+4], xim[k+4],
                        exp_re[k], exp_im[k], exp_re[k+4], exp_im[k+4]);
    end
    #1;
    check_outputs(0, 1, "All zeros input");

    // -------------------------------------------------------
    // Test 2: DC input - x[0]=100, rest 0 (real only)
    // -------------------------------------------------------
    for (k = 0; k < 8; k = k+1) begin
        xre[k] = 0;
        xim[k] = 0;
    end
    xre[0] = 100;
    tmp_re_flat = 0;
    tmp_im_flat = 0;
    for (k = 0; k < 8; k = k+1) begin
        tmp_re_flat[k*16 +: 16] = xre[k];
        tmp_im_flat[k*16 +: 16] = xim[k];
    end
    xre_flat = tmp_re_flat;
    xim_flat = tmp_im_flat;
    for (k = 0; k < 4; k = k+1) begin
        compute_expected(xre[k], xim[k], xre[k+4], xim[k+4],
                        exp_re[k], exp_im[k], exp_re[k+4], exp_im[k+4]);
    end
    #1;
    check_outputs(0, 2, "DC input x[0]=100 rest zero");

    // -------------------------------------------------------
    // Test 3: Pair (0,4) both equal: x[0]=500, x[4]=500
    // -------------------------------------------------------
    for (k = 0; k < 8; k = k+1) begin
        xre[k] = 0;
        xim[k] = 0;
    end
    xre[0] = 500;
    xre[4] = 500;
    tmp_re_flat = 0;
    tmp_im_flat = 0;
    for (k = 0; k < 8; k = k+1) begin
        tmp_re_flat[k*16 +: 16] = xre[k];
        tmp_im_flat[k*16 +: 16] = xim[k];
    end
    xre_flat = tmp_re_flat;
    xim_flat = tmp_im_flat;
    for (k = 0; k < 4; k = k+1) begin
        compute_expected(xre[k], xim[k], xre[k+4], xim[k+4],
                        exp_re[k], exp_im[k], exp_re[k+4], exp_im[k+4]);
    end
    #1;
    check_outputs(0, 3, "Pair (0,4) both = 500");

    // -------------------------------------------------------
    // Test 4: Pair (1,5): x[1]=300, x[5]=-300
    // -------------------------------------------------------
    for (k = 0; k < 8; k = k+1) begin
        xre[k] = 0;
        xim[k] = 0;
    end
    xre[1] = 300;
    xre[5] = -300;
    tmp_re_flat = 0;
    tmp_im_flat = 0;
    for (k = 0; k < 8; k = k+1) begin
        tmp_re_flat[k*16 +: 16] = xre[k];
        tmp_im_flat[k*16 +: 16] = xim[k];
    end
    xre_flat = tmp_re_flat;
    xim_flat = tmp_im_flat;
    for (k = 0; k < 4; k = k+1) begin
        compute_expected(xre[k], xim[k], xre[k+4], xim[k+4],
                        exp_re[k], exp_im[k], exp_re[k+4], exp_im[k+4]);
    end
    #1;
    check_outputs(0, 4, "Pair (1,5): x[1]=300 x[5]=-300");

    // -------------------------------------------------------
    // Test 5: Complex inputs across all pairs
    // -------------------------------------------------------
    for (k = 0; k < 8; k = k+1) begin
        xre[k] = 0;
        xim[k] = 0;
    end
    xre[0] = 1000;  xim[0] = 200;
    xre[1] = -500;  xim[1] = 300;
    xre[2] = 750;   xim[2] = -100;
    xre[3] = -200;  xim[3] = 400;
    xre[4] = 800;   xim[4] = -150;
    xre[5] = 600;   xim[5] = 100;
    xre[6] = -300;  xim[6] = 500;
    xre[7] = 450;   xim[7] = -250;
    tmp_re_flat = 0;
    tmp_im_flat = 0;
    for (k = 0; k < 8; k = k+1) begin
        tmp_re_flat[k*16 +: 16] = xre[k];
        tmp_im_flat[k*16 +: 16] = xim[k];
    end
    xre_flat = tmp_re_flat;
    xim_flat = tmp_im_flat;
    for (k = 0; k < 4; k = k+1) begin
        compute_expected(xre[k], xim[k], xre[k+4], xim[k+4],
                        exp_re[k], exp_im[k], exp_re[k+4], exp_im[k+4]);
    end
    #1;
    check_outputs(0, 5, "Complex mixed inputs");

    // -------------------------------------------------------
    // Test 6: All-ones (max positive 16-bit signed = 32767)
    // -------------------------------------------------------
    for (k = 0; k < 8; k = k+1) begin
        xre[k] = 16'h7FFF;
        xim[k] = 16'h7FFF;
    end
    tmp_re_flat = 0;
    tmp_im_flat = 0;
    for (k = 0; k < 8; k = k+1) begin
        tmp_re_flat[k*16 +: 16] = xre[k];
        tmp_im_flat[k*16 +: 16] = xim[k];
    end
    xre_flat = tmp_re_flat;
    xim_flat = tmp_im_flat;
    for (k = 0; k < 4; k = k+1) begin
        compute_expected(xre[k], xim[k], xre[k+4], xim[k+4],
                        exp_re[k], exp_im[k], exp_re[k+4], exp_im[k+4]);
    end
    #1;
    check_outputs(0, 6, "All samples = 32767");

    // -------------------------------------------------------
    // Test 7: All minimum (most negative = -32768)
    // -------------------------------------------------------
    for (k = 0; k < 8; k = k+1) begin
        xre[k] = 16'h8000; // -32768
        xim[k] = 16'h8000;
    end
    tmp_re_flat = 0;
