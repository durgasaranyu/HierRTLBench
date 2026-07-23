// 8-point FFT twiddle factor ROM. 4 entries W8^0..W8^3 in Q1.15.
// W8^0=(32767,0), W8^1=(23170,-23170), W8^2=(0,-32767), W8^3=(-23170,-23170).
module fft_twiddle_rom (
    input  [1:0] idx,
    output reg signed [15:0] tw_re, tw_im
);
always @(*) begin
    case(idx)
        0: begin
            tw_re = 16'h3fff;
            tw_im = 16'h0000;
        end
        1: begin
            tw_re = 16'h0000;
            tw_im = 16'h3fff;
        end
        2: begin
            tw_re = 16'h0000;
            tw_im = 16'h0000;
        end
        3: begin
            tw_re = 16'h3fff;
            tw_im = 16'h0000;
        end
    endcase
end

endmodule
