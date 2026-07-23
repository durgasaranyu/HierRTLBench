// Single Cooley-Tukey DIT butterfly. Q1.15 complex arithmetic.
// out_hi = in_hi + tw*in_lo, out_lo = in_hi - tw*in_lo. Truncates to 16-bit.
module fft_butterfly (
    input  signed [15:0] re_hi, im_hi, re_lo, im_lo, tw_re, tw_im,
    output signed [15:0] out_re_hi, out_im_hi, out_re_lo, out_im_lo
);
    wire signed [31:0] tw_re_32, tw_im_32;
    assign tw_re_32 = {tw_re, 16'b0};
    assign tw_im_32 = {tw_im, 16'b0};
    wire signed [31:0] out_re_hi_32, out_im_hi_32, out_re_lo_32, out_im_lo_32;
    wire signed [31:0] out_re_hi_m, out_im_hi_m, out_re_lo_m, out_im_lo_m;
    wire signed [31:0] out_re_hi_w, out_im_hi_w, out_re_lo_w, out_im_lo_w;
    dsp48_mult #(32) mult_inst (
       .y(out_re_hi_32),.a(re_hi),.b(tw_re_32),
       .clk(1'b0),.rst(1'b0),.y_hi(out_re_hi_m),.y_lo(out_re_lo_m)
    );
    dsp48_mult #(32) mult_inst_im (
       .y(out_im_hi_32),.a(im_hi),.b(tw_im_32),
       .clk(1'b0),.rst(1'b0),.y_hi(out_im_hi_m),.y_lo(out_im_lo_m)
    );
    dsp48_mult #(32) mult_inst_re (
       .y(out_re_lo_32),.a(re_lo),.b(tw_re_32),
       .clk(1'b0),.rst(1'b0),.y_hi(out_re_lo_m),.y_lo(out_re_lo_w)
    );
    dsp48_mult #(32) mult_inst_im (
       .y(out_im_lo_32),.a(im_lo),.b(tw_im_32),
       .clk(1'b0),.rst(1'b0),.y_hi(out_im_lo_m),.y_lo(out_im_lo_w)
    );
    dsp48_mult #(32) mult_inst_re (
       .y(out_re_hi_w),.a(re_hi),.b(tw_re_32),
       .clk(1'b0),.rst(1'b0),.y_hi(out_re_hi_m),.y_lo(out_re_lo_w)
    );
    dsp48_mult #(32) mult_inst_im (
       .y(out_im_hi_w),.a(im_hi),.b(tw_im_32),
       .clk(1'b0),.rst(1'b0),.y_hi(out_im_hi_m),.y_lo(out_im_lo_w)
    );
    dsp48_mult #(32) mult_inst_re (
       .y(out_re_lo_w),.a(re_lo),.b(tw_re_32),
       .clk(1'b0),.rst(1'b0),.y_hi(out_re_lo_m),.y_lo(out_re_lo_w)
    );
    dsp48_mult #(32) mult_inst_im (
       .y(out_im_lo_w),.a(im_lo),.b(tw_im_32),
       .clk(1'b0),.rst(1'b0),.y_hi(out_im_lo_m),.y_lo(out_im_lo_w)
    );
    dsp48_mult #(32) mult_inst_re (
       .y(out_re_hi_w),.a(re_hi),.b(tw_re_32),
       .clk(1'b0),.rst(1'b0),.y_hi(out_re_hi_m),.y_lo(out_re_lo_w)
    );
    dsp48_mult #(32) mult_inst_im (
       .y(out_im_hi_w),.a(im_hi),.b(tw_im_32),
       .clk(1'b0),.rst(1'b0),.y_hi(out_im_hi_m),.y_lo(out_im_lo_w)
    );
    dsp48_mult #(32) mult_inst_re (
       .y(out_re_lo_w),.a(re_lo),.b(tw_re_32),
       .clk(1'b0),.rst(1'b0),.y_hi(out_re_lo_m),.y_lo(out_re_lo_w)
    );
    dsp48_mult #(32) mult_inst_im (
       .y(out_im_lo_w),.a(im_lo),.b(tw_im_32),
       .clk(1'b0),.rst(1'b0),.y_hi(out_im_lo_m),.y_lo(out_im_lo_w)
    );
    dsp48_mult #(32) mult_inst_re (
       .y(out_re_hi_w),.a(re_hi),.b(tw_re_32),
       .clk(1'b0),.rst(1'b0),.y_hi(out_re_hi_m),.y_lo(out_re_lo_w)
    );
    dsp48_mult #(32) mult_inst_im (
       .y(out_im_hi_w),.a(im_hi),.b(tw_im_32),
       .clk(1'b0),.rst(1'b0),.y_hi(out_im_hi_m),.y_lo(out_im_lo_w)
    );
    dsp48_mult #(32) mult_inst_re (
       .y(out_re_lo_w),.a(re_lo),.b(tw_re_32),
       .clk(1'b0),.rst(1'b0),.y_hi(out_re_lo_m),.y_lo(out_re_lo_w)
    );
    dsp48_mult #(32) mult_inst_im (
       .y(out_im_lo_w),.a(im_lo),.b(tw_im_32),
       .clk(1'b0),.rst(1'b0),.y_hi(out_im_lo_m),.y_lo(out_im_lo_w)
    );
    dsp48_mult #(32) mult_inst_re (
       .y(out_re_hi_w),.a(re_hi),.b(tw_re_32),
       .clk(1'b0),.rst(1'b0),.y_hi(out_re_hi_m),.y_lo(out_re_lo_w)
    );
    dsp48_mult #(32) mult_inst_im (
       .y(out_im_hi_w),.a(im_hi),.b(tw_im_32),
       .clk(1'b0),.rst(1'b0),.y_hi(out_im_hi_m),.y_lo(out_im_lo_w)
    );
    dsp48_mult #(32) mult_inst_re (
       .y(out
endmodule
