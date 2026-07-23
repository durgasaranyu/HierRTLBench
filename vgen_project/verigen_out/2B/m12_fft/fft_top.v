// 8-point fixed-point FFT top. Cooley-Tukey DIT, 3 stages, Q1.15 complex arithmetic.
// Output is in bit-reversed order.
module fft8 (
    input  signed [127:0] xre_flat, xim_flat,
    output signed [127:0] Xre_flat, Xim_flat
);
    //----------------------------------------------------------------
    // 1st stage: 8 complex multipliers
    //----------------------------------------------------------------
    wire signed [63:0] xre_re, xre_im, xim_re, xim_im;
    wire signed [63:0] wre_re, wre_im, wim_re, wim_im;
    wire signed [63:0] Xre_re, Xre_im, Xim_re, Xim_im;
    wire signed [63:0] Yre_re, Yre_im, Yim_re, Yim_im;
    wire signed [63:0] Yre_re_r, Yre_im_r, Yim_re_r, Yim_im_r;
    wire signed [63:0] wre_re_r, wim_re_r, wim_im_r;
    wire signed [63:0] Xre_re_r, Xim_re_r, Xim_im_r;
    wire signed [63:0] Yre_re_r, Yim_re_r, Yim_im_r;
    wire signed [63:0] wre_re, wre_im, wim_re, wim_im;
    wire signed [63:0] Xre, Xim;
    wire signed [63:0] Yre, Yim;
    wire signed [63:0] Xre_r, Xim_r;
    wire signed [63:0] Yre_r, Yim_r;
    wire signed [63:0] wre, wim;
    wire signed [63:0] Xre_r_r, Xim_r_r;
    wire signed [63:0] Yre_r_r, Yim_r_r;
    wire signed [63:0] wre_r, wim_r;
    wire signed [63:0] Xre_r_r_r, Xim_r_r_r;
    wire signed [63:0] Yre_r_r_r;
    wire signed [63:0] wre_r_r, wim_r_r;
    wire signed [63:0] Xre_r_r_r_r, Xim_r_r_r_r;
    wire signed [63:0] Yre_r_r_r_r;
    wire signed [63:0] wre_r_r_r_r;
    wire signed [63:0] Xre_r_r_r_r_r, Xim_r_r_r_r_r;
    wire signed [63:0] Yre_r_r_r_r_r;
    wire signed [63:0] wre_r_r_r_r_r;
    wire signed [63:0] Xre_r_r_r_r_r_r, Xim_r_r_r_r_r_r;
    wire signed [63:0] Yre_r_r_r_r_r_r;
    wire signed [63:0] wre_r_r_r_r_r;
    wire signed [63:0] Xre_r_r_r_r_r_r_r, Xim_r_r_r_r_r_r_r;
    wire signed [63:0] Yre_r_r_r_r_r_r_r;
    wire signed [63:0] wre_r_r_r_r_r;
    wire signed [63:0] Xre_r_r_r_r_r_r_r_r, Xim_r_r_r_r_r_r_r_r;
    wire signed [63:0] Yre_r_r_r_r_r_r_r_r;
    wire signed [63:0] wre_r_r_r_r_r;
    wire signed [63:0] Xre_r_r_r_r_r_r_r_r;
    wire signed [63:0] Yre_r_r_r_r_r_r_r_r;
    wire signed [63:0] wre_r_r_r_r_r;
    wire signed [63:0] Xre_r_r_r_r_r_r_r_r;
    wire signed [63:0] Yre_r_r_r_r_r_r_r_r;
    wire signed [63:0] wre_r_r_r_r_r;
    wire signed [63:0] Xre_r_r_r_r_r_r_r_r;
    wire signed [63:0] Yre_r_r_r_r_r_r_r_r;
    wire signed [63:0] wre_r_r_r_r_r;
    wire signed [63:0] Xre_r_r_r_r_r_r_r_r;
    wire signed [63:0] Yre_r_r_r_r_r_r_r_r;
    wire signed [63:0] wre_r_r_r_r_r;
    wire signed [63:0] Xre_r_r_r_r_r_r_r_r;
    wire signed [63:0] Yre_r_r_r_r_r_r_r_r;
    wire signed [63:0] wre_r_r_r_r_r;
    wire signed [63:0] Xre_r_r_r_r_r_r_r_r;
    wire signed [63:0] Yre_r_r_r_r_r_r_r_r;
    wire signed [63:0] wre_r_r_r_r_r;
    wire signed [63:0] Xre_r_r_r_r_r_r_r_r;
    wire signed [63:0] Yre_r_r_r_r_r_r_r_r;
    wire signed [63:0] wre_r_r_r_r_r;
    wire signed [63:0] Xre_r_r_r_r_r_r_r_r;
    wire signed [63:0] Yre_r_r_r_r_r_r_r_r;
    wire signed [63:0] wre_r_r_r_r_r;
    wire signed [63:0] Xre_r_r_r_r_r_r_r_r;
    wire signed [63:0] Yre_r_r_r_r_r_r_r_r;
    wire signed [63:0] wre_r_r_r_r_r;
    wire signed [63:0] Xre_r_r_r_r_r_r_r_r;
    wire signed [63:0] Yre_r_r_r_r_r_r_r_r;
    wire signed [63:0] wre_r_r_r_r_r;
    wire signed [63:0] Xre_r_r_r_r_r_r_r_r;
    wire signed [63:0] Yre_r_r_r_r_r_r_r_r;
    wire signed [63:0] wre_r_r_r_r_r;
    wire signed [63:0] Xre_r_r_r_r_r_r_r_r;
    wire signed [63:0] Yre_r_r_r_r_r_r_r_r;
    wire signed [63:0] wre_r_r_r_r_r;
    wire signed [63:0] Xre_r_r_r_r_r_r_r_r;
    wire signed [63:0] Yre_r_r_r_r_r_r_r_r;
    wire signed [63:0] wre_r_r_r_r_r;
    wire signed [63:0] Xre_r_r_r_r_r_r_r_r;
    wire signed [63:0] Yre_r_r
endmodule
