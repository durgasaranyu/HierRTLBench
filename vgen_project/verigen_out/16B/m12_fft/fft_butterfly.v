// Single Cooley-Tukey DIT butterfly. Q1.15 complex arithmetic.
// out_hi = in_hi + tw*in_lo, out_lo = in_hi - tw*in_lo. Truncates to 16-bit.
module fft_butterfly (
    input  signed [15:0] re_hi, im_hi, re_lo, im_lo, tw_re, tw_im,
    output signed [15:0] out_re_hi, out_im_hi, out_re_lo, out_im_lo
);
    // out_re_hi = in_re_hi + tw*in_re_lo, out_im_hi = in_im_hi - tw*in_im_lo
    // out_re_lo = in_re_lo + tw*in_im_lo, out_im_lo = in_im_lo - tw*in_re_lo
    //
    // out_re_hi = in_re_hi + tw*in_re_lo + tw*in_im_lo,
    // out_im_hi = in_im_hi - tw*in_re_lo + tw*in_im_lo
    // out_re_lo = in_re_lo - tw*in_re_lo + tw*in_im_lo,
    // out_im_lo = in_im_lo - tw*in_im_lo + tw*in_re_lo
    //
    // out_re_hi = in_re_hi + tw*in_re_lo + tw*in_im_lo,
    // out_im_hi = in_im_hi - tw*in_re_lo + tw*in_im_lo
    // out_re_lo = in_re_lo - tw*in_re_lo + tw*in_im_lo,
    // out_im_lo = in_im_lo - tw*in_im_lo + tw*in_re_lo
    //
    // out_re_hi = in_re_hi + tw*in_re_lo + tw*in_im_lo,
    // out_im_hi = in_im_hi - tw*in_re_lo + tw*in_im_lo
    // out_re_lo = in_re_lo - tw*in_re_lo + tw*in_im_lo,
    // out_im_lo = in_im_lo - tw*in_im_lo + tw*in_re_lo
    //
    // out_re_hi = in_re_hi + tw*in_re_lo + tw*in_im_lo,
    // out_im_hi = in_im_hi - tw*in_re_lo + tw*in_im_lo
    // out_re_lo = in_re_lo - tw*in_re_lo + tw*in_im_lo,
    // out_im_lo = in_im_lo - tw*in_im_lo + tw*in_re_lo
    //
    // out_re_hi = in_re_hi + tw*in_re_lo + tw*in_im_lo,
    // out_im_hi = in_im_hi - tw*in_re_lo + tw*in_im_lo
    // out_re_lo = in_re_lo - tw*in_re_lo + tw*in_im_lo,
    // out_im_lo = in_im_lo - tw*in_im_lo + tw*in_re_lo
    //
    // out_re_hi = in_re_hi + tw*in_re_lo + tw*in_im_lo,
    // out_im_hi = in_im_hi - tw*in_re_lo + tw*in_im_lo
    // out_re_lo = in_re_lo - tw*in_re_lo + tw*in_im_lo,
    // out_im_lo = in_im_lo - tw*in_im_lo + tw*in_re_lo
    //
    // out_re_hi = in_re_hi + tw*in_re_lo + tw*in_im_lo,
    // out_im_hi = in_im_hi - tw*in_re_lo + tw*in_im_lo
    // out_re_lo = in_re_lo - tw*in_re_lo + tw*in_im_lo,
    // out_im_lo = in_im_lo - tw*in_im_lo + tw*in_re_lo
    //
    // out_re_hi = in_re_hi + tw*in_re_lo + tw*in_im_lo,
    // out_im_hi = in_im_hi - tw*in_re_lo + tw*in_im_lo
    // out_re_lo = in_re_lo - tw*in_re_lo + tw*in_im_lo,
    // out_im_lo = in_im_lo - tw*in_im_lo + tw*in_re_lo
    //
    // out_re_hi = in_re_hi + tw*in_re_lo + tw*in_im_lo,
    // out_im_hi = in_im_hi - tw*in_re_lo + tw*in_im_lo
    // out_re_lo = in_re_lo - tw*in_re_lo + tw*in_im_lo,
    // out_im_lo = in_im_lo - tw*in_im_lo + tw*in_re_lo
    //
    // out_re_hi = in_re_hi + tw*in_re_lo + tw*in_im_lo,
    // out_im_hi = in_im_hi - tw*in_re_lo + tw*in_im_lo
    // out_re_lo = in_re_lo - tw*in_re_lo + tw*in_im_lo,
    // out_im_lo = in_im_lo - tw*in_im_lo + tw*in_re_lo
    //
    // out_re_hi = in_re_hi + tw*in_re_lo + tw*in_im_lo,
    // out_im_hi = in_im_hi - tw*in_re_lo + tw*in_im_lo
    // out_re_lo = in_re_lo - tw*in_re_lo + tw*in_im_lo,
    // out_im_lo = in_im_lo - tw*in_im_lo + tw*in_re_lo
    //
    // out_re_hi = in_re_hi + tw*in_re_lo + tw*in_im_lo,
    // out_im_hi = in_im_hi - tw*in_re_lo + tw*in_im_lo
    // out_re_lo = in_re_lo - tw*in_re_lo + tw*in_im_lo,
    // out_im_lo = in_im_lo - tw*in_im_lo + tw*in_re_lo
    //
    // out_re_hi = in_re_hi + tw*in_re_lo + tw*in_im_lo,
    // out_im_hi = in_im_hi - tw*in_re_lo + tw*in_im_lo
    // out_re_lo = in_re_lo - tw*in_re_lo + tw*in_im_lo,
    // out_im_lo = in_im_lo - tw*in_im_lo + tw*in_re_lo
    //
    // out_re_hi = in_re_hi + tw*in_re_lo + tw*in_im_lo,
    // out_im_hi = in_im_hi - tw*in_re_lo + tw*in_im_lo
    // out_re_lo = in_re_lo - tw*in_re_lo + tw*in_im_lo,
    // out_im_lo = in_im_lo - tw*in_im_lo + tw*in_re_lo
    //
    // out_re_hi = in_re_hi + tw*in_re_lo + tw*in_im_lo,
    // out_im_hi = in_im_hi - tw*in_re_lo + tw*in_im_lo
    // out_re_lo = in_re_lo - tw*
endmodule
