// FFT stages 2 and 3 combined. Stage2: pairs (0,2),(1,3),(4,6),(5,7).
// Stage3: pairs (0,1),(2,3),(4,5),(6,7) with respective twiddles.
module fft_stage23 (
    input  signed [127:0] s1re_flat, s1im_flat,
    output signed [127:0] s3re_flat, s3im_flat
);
    // rename input
    wire signed [63:0] s1r, s1i, s2r, s2i, s3r, s3i;
    assign s1r = s1re_flat[127:64];
    assign s1i = s1re_flat[63:0];
    assign s2r = s1re_flat[127:64];
    assign s2i = s1re_flat[63:0];
    assign s3r = s1re_flat[127:64];
    assign s3i = s1re_flat[63:0];
    // FFT1
    fft_bits fft1(.clk(clk),.rst_n(rst_n),.s1r(s1r),.s1i(s1i),
                 .s2r(s2r),.s2i(s2i),.s3r(s3r),.s3i(s3i));
    // FFT2
    fft_bits fft2(.clk(clk),.rst_n(rst_n),.s1r(s2r),.s1i(s2i),
                 .s2r(s3r),.s2i(s3i),.s3r(s3r),.s3i(s3i));
    // FFT3
    fft_bits fft3(.clk(clk),.rst_n(rst_n),.s1r(s3r),.s1i(s3i),
                 .s2r(s3r),.s2i(s3i),.s3r(s3re_flat),.s3i(s3im_flat));

endmodule
