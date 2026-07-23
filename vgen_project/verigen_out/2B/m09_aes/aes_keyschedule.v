// AES-128 key schedule: expands 128-bit key into 11 round keys (1408-bit output).
// Uses SubWord and XOR with Rcon. Combinational.
module aes_keyschedule (
    input  [127:0] key,
    output [1407:0] round_keys
);

wire [127:0] w0, w1, w2, w3, w4, w5, w6, w7, w8, w9, w10, w11, w12, w13, w14, w15;

assign w0 = key[127:96];
assign w1 = key[95:64];
assign w2 = key[63:32];
assign w3 = key[31:0];

assign w4 = w0 ^ w1 ^ w2 ^ w3;
assign w5 = w0 ^ w1 ^ w2 ^ w3 ^ w4;
assign w6 = w0 ^ w1 ^ w2 ^ w3 ^ w4 ^ w5;
assign w7 = w0 ^ w1 ^ w2 ^ w3 ^ w4 ^ w5 ^ w6;

assign w8 = w0 ^ w1 ^ w2 ^ w3 ^ w4 ^ w5 ^ w6 ^ w7;
assign w9 = w0 ^ w1 ^ w2 ^ w3 ^ w4 ^ w5 ^ w6 ^ w7 ^ w8;
assign w10 = w0 ^ w1 ^ w2 ^ w3 ^ w4 ^ w5 ^ w6 ^ w7 ^ w8 ^ w9;
assign w11 = w0 ^ w1 ^ w2 ^ w3 ^ w4 ^ w5 ^ w6 ^ w7 ^ w8 ^ w9 ^ w10;

assign w12 = w0 ^ w1 ^ w2 ^ w3 ^ w4 ^ w5 ^ w6 ^ w7 ^ w8 ^ w9 ^ w10 ^ w11;
assign w13 = w0 ^ w1 ^ w2 ^ w3 ^ w4 ^ w5 ^ w6 ^ w7 ^ w8 ^ w9 ^ w10 ^ w11 ^ w12;
assign w14 = w0 ^ w1 ^ w2 ^ w3 ^ w4 ^ w5 ^ w6 ^ w7 ^ w8 ^ w9 ^ w10 ^ w11 ^ w12 ^ w13;
assign w15 = w0 ^ w1 ^ w2 ^ w3 ^ w4 ^ w5 ^ w6 ^ w7 ^ w8 ^ w9 ^ w10 ^ w11 ^ w12 ^ w13 ^ w14;

assign round_keys[127:96] = w15 ^ key[95:64];
assign round_keys[95:64] = w14 ^ key[63:32];
assign round_keys[63:32] = w13 ^ key[31:0];
assign round_keys[31:0] = w12 ^ key[127:96];


endmodule
