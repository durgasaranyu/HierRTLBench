// 8-point FFT twiddle factor ROM. 4 entries W8^0..W8^3 in Q1.15.
// W8^0=(32767,0), W8^1=(23170,-23170), W8^2=(0,-32767), W8^3=(-23170,-23170).
module fft_twiddle_rom (
    input  [1:0] idx,
    output reg signed [15:0] tw_re, tw_im
);
always @(*) begin
    case (idx)
        2'b00: begin
            tw_re = 16'h3f4f;
            tw_im = 16'h0000;
        end
        2'b01: begin
            tw_re = 16'h3f4f;
            tw_im = 16'h0000;
        end
        2'b10: begin
            tw_re = 16'h0000;
            tw_im = 16'h3f4f;
        end
        2'b11: begin
            tw_re = 16'h0000;
            tw_im = 16'h3f4f;
        end
    endcase
end

endmodule
