// AES MixColumns: GF(2^8) matrix multiply on each of 4 columns. Combinational.
module aes_mixcolumns (
    input  [127:0] state_in,
    output [127:0] state_out
);

wire [31:0] w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15;

assign w0 = state_in[127:96];
assign w1 = state_in[95:64];
assign w2 = state_in[63:32];
assign w3 = state_in[31:0];

assign w10 = w0[31:24] ^ w1[23:16] ^ w2[15:8] ^ w3[7:0];
assign w11 = w0[23:16] ^ w1[15:8] ^ w2[7:0];
assign w12 = w0[15:8] ^ w1[7:0];
assign w13 = w0[7:0];

assign w20 = w10[31:24] ^ w11[23:16] ^ w2[15:8] ^ w3[7:0];
assign w21 = w10[23:16] ^ w11[15:8] ^ w2[7:0];
assign w22 = w10[15:8] ^ w11[7:0];
assign w23 = w10[7:0];

assign w30 = w20[31:24] ^ w21[23:16] ^ w2[15:8] ^ w3[7:0];
assign w31 = w20[23:16] ^ w21[15:8] ^ w2[7:0];
assign w32 = w20[15:8] ^ w21[7:0];
assign w33 = w20[7:0];

assign w40 = w30[31:24] ^ w31[23:16] ^ w2[15:8] ^ w3[7:0];
assign w41 = w30[23:16] ^ w31[15:8] ^ w2[7:0];
assign w42 = w30[15:8] ^ w31[7:0];
assign w43 = w30[7:0];

assign w50 = w40[31:24] ^ w41[23:16] ^ w2[15:8] ^ w3[7:0];
assign w51 = w40[23:16] ^ w41[15:8] ^ w2[7:0];
assign w52 = w40[15:8] ^ w41[7:0];
assign w53 = w40[7:0];

assign w60 = w50[31:24] ^ w51[23:16] ^ w2[15:8] ^ w3[7:0];
assign w61 = w50[23:16] ^ w51[15:8] ^ w2[7:0];
assign w62 = w50[15:8] ^ w51[7:0];
assign w63 = w50[7:0];

assign state_out[127:96] = {w63, w62, w61, w60, w59, w58, w57, w56, w55, w54, w53, w52, w51, w50, w49, w48, w47, w46, w45, w44, w43, w42, w41, w40, w39, w38, w37, w36, w35, w34, w33, w32, w31, w30, w29, w28, w27, w26, w25, w24, w23, w22, w21, w20, w19, w18, w17, w16, w15, w14, w13, w12, w11, w10};


endmodule
