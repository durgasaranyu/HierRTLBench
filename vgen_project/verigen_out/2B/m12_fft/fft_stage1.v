// FFT stage 1: 4 butterflies on pairs (0,4),(1,5),(2,6),(3,7). Twiddle W8^0.
// Inputs/outputs are 8 Q1.15 complex samples as flat buses.
module fft_stage1 (
    input  signed [127:0] xre_flat, xim_flat,
    output signed [127:0] s1re_flat, s1im_flat
);

wire signed [63:0] w0_re, w0_im, w1_re, w1_im, w2_re, w2_im, w3_re, w3_im;
wire signed [63:0] w4_re, w4_im, w5_re, w5_im, w6_re, w6_im, w7_re, w7_im;
wire signed [63:0] w8_re, w8_im, w9_re, w9_im, w10_re, w10_im, w11_re, w11_im;
wire signed [63:0] w12_re, w12_im, w13_re, w13_im, w14_re, w14_im, w15_re, w15_im;

wire signed [63:0] s1_re, s1_im, s2_re, s2_im, s3_re, s3_im, s4_re, s4_im;
wire signed [63:0] s5_re, s5_im, s6_re, s6_im, s7_re, s7_im, s8_re, s8_im;
wire signed [63:0] s9_re, s9_im, s10_re, s10_im, s11_re, s11_im, s12_re, s12_im;
wire signed [63:0] s13_re, s13_im, s14_re, s14_im, s15_re, s15_im;

wire signed [63:0] s1_re_w, s1_im_w, s2_re_w, s2_im_w, s3_re_w, s3_im_w, s4_re_w, s4_im_w;
wire signed [63:0] s5_re_w, s5_im_w, s6_re_w, s6_im_w, s7_re_w, s7_im_w, s8_re_w, s8_im_w;
wire signed [63:0] s9_re_w, s9_im_w, s10_re_w, s10_im_w, s11_re_w, s11_im_w, s12_re_w, s12_im_w;
wire signed [63:0] s13_re_w, s13_im_w, s14_re_w, s14_im_w, s15_re_w, s15_im_w;

wire signed [63:0] s1_re_w1, s1_im_w1, s2_re_w1, s2_im_w1, s3_re_w1, s3_im_w1, s4_re_w1, s4_im_w1;
wire signed [63:0] s5_re_w1, s5_im_w1, s6_re_w1, s6_im_w1, s7_re_w1, s7_im_w1, s8_re_w1, s8_im_w1;
wire signed [63:0] s9_re_w1, s9_im_w1, s10_re_w1, s10_im_w1, s11_re_w1, s11_im_w1, s12_re_w1, s12_im_w1;
wire signed [63:0] s13_re_w1, s13_im_w1, s14_re_w1, s14_im_w1, s15_re_w1, s15_im_w1;

wire signed [63:0] s1_re_w2, s1_im_w2, s2_re_w2, s2_im_w2, s3_re_w2, s3_im_w2, s4_re_w2, s4_im_w2;
wire signed [63:0] s5_re_w2, s5_im_w2, s6_re_w2, s6_im_w2, s7_re_w2, s7_im_w2, s8_re_w2, s8_im_w2;
wire signed [63:0] s9_re_w2, s9_im_w2, s10_re_w2, s10_im_w2, s11_re_w2, s11_im_w2, s12_re_w2, s12_im_w2;
wire signed [63:0] s13_re_w2, s13_im_w2, s14_re_w2, s14_im_w2, s15_re_w2, s15_im_w2;

wire signed [63:0] s1_re_w3, s1_im_w3, s2_re_w3, s2_im_w3, s3_re_w3, s3_im_w3, s4_re_w3, s4_im_w3;
wire signed [63:0] s5_re_w3, s5_im_w3, s6_re_w3, s6_im_w3, s7_re_w3, s7_im_w3, s8_re_w3, s8_im_w3;
wire signed [63:0] s9_re_w3, s9_im_w3, s10_re_w3, s10_im_w3, s11_re_w3, s11_im_w3, s12_re_w3, s12_im_w3;
wire signed [63:0] s13_re_w3, s13_im_w3, s14_re_w3, s14_im_w3, s15_re_w3, s15_im_w3;

wire signed [63:0] s1_re_w4, s1_im_w4, s2_re_w4, s2_im_w4, s3_re_w4, s3_im_w4, s4_re_w4, s4_im_w4;
wire signed [63:0] s5_re_w4, s5_im_w4, s6_re_w4, s6_im_w4, s7_re_w4, s7_im_w4, s8_re_w4, s8_im_w4;
wire signed [63:0] s9_re_w4, s9_im_w4, s10_re_w4, s10_im_w4, s11_re_w4, s11_im_w4, s12_re_w4, s12_im_w4;
wire signed [63:0] s13_re_w4, s13_im_w4, s14_re_w4, s14_im_w4, s15_re_w4, s15_im_w4;

wire signed [63:0] s1_re_w5, s1_im_w5, s2_re_w5, s2_im_w5, s3_re_w5, s3_im_w5, s4_re_w5, s4_im_w5;
wire signed [63:0] s5_re_w5, s5_im_w5, s6_re_w5, s6_im_w5, s7_re_w5, s7_im_w5, s8_re_w5, s8_im_w5;
wire signed [63:0] s9_re_w5, s9_im_w5, s10_re_w5, s10_im_w5, s11_re_w5, s11_im_w5, s12_re_w5, s12_im_w5;
wire signed [63:0] s13_re_w
endmodule
