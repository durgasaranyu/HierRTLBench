`timescale 1ns/1ps
// M12: 8-point fixed-point FFT integration top (Cooley-Tukey DIT, Q1.15)
// Purely combinational: stage1 → stage23, output in bit-reversed order.
module fft8_integration (
    input  signed [127:0] xre_flat, xim_flat,
    output signed [127:0] Xre_flat, Xim_flat
);
    wire signed [127:0] s1re, s1im;

    fft_stage1  u_s1  (
        .xre_flat(xre_flat), .xim_flat(xim_flat),
        .s1re_flat(s1re),    .s1im_flat(s1im)
    );
    fft_stage23 u_s23 (
        .s1re_flat(s1re),    .s1im_flat(s1im),
        .s3re_flat(Xre_flat),.s3im_flat(Xim_flat)
    );
endmodule
