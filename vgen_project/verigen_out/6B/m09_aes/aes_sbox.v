// AES full S-box: routes to lo (in[7]==0) or hi (in[7]==1) sub-LUT.
module aes_sbox (
    input  [7:0] in,
    output [7:0] out
);
    // input [7 : 0] in;
    // output [7 : 0] out;
    assign out[0] = sbox[in[7:1]][in[0]];
    assign out[1] = sbox[in[3:4]][in[1]];
    assign out[2] = sbox[in[5:6]][in[2]];
    assign out[3] = sbox[in[0:3]][in[3]];
    assign out[4] = sbox[in[2:5]][in[4]];
    assign out[5] = sbox[in[4:5]][in[5]];
    assign out[6] = sbox[in[6:7]][in[6]];
    assign out[7] = 0;
endmodule

module aes_sbox_dec(
    input  [7:0] in,
    output [7:0] out
);
    // input [7 : 0] in;
    // output [7 : 0] out;
    assign out[0] = sbox_dec[in[3:0]][in[7:4]];
    assign out[1] = sbox_dec[in[7:4]][in[3:0]];
    assign out[2] = sbox_dec[in[5:0]][in[7:6]];
    assign out[3] = sbox_dec[in[7:6]][in[5:0]];
    assign out[4] = sbox_dec[in[6:0]][in[7:7]];
    assign out[5] = sbox_dec[in[7:7]][in[6:0]];
    assign out[6] = sbox_dec[in[6:0]][in[7:7]];
    assign out[7] = 0;
endmodule

module aes_sbox_enc(
    input  [7:0] in,
    output [7:0] out
);
    // input [7 : 0] in;
    // output [7 : 0] out;
    assign out[0] = sbox_enc[in[3:0]][in[7:4]];
    assign out[1] = sbox_enc[in[3:0]][in[3:0]];
    assign out[2] = sbox_enc[in[5:0]][in[7:6]];
    assign out[3] = sbox_enc[in[5:0]][in[5:0]];
    assign out[4] = sbox_enc[in[6:0]][in[7:7]];
    assign out[5] = sbox_enc[in[6:0]][in[6:0]];
    assign out[6] = sbox_enc[in[7:7]][in[6:0]];
    assign out[7] = 0;
endmodule

module aes_sbox_dec(
    input  [7:0] in,
    output [7:0] out
);
    // input [7 : 0] in;
    // output [7 : 0] out;
    assign out[0] = sbox_dec[in[3:0]][in[7:4]];
    assign out[1] = sbox_dec[in[3:0]][in[3:0]];
    assign out[2] = sbox_dec[in[5:0]][in[7:6]];
    assign out[3] = sbox_dec[in[5:0]][in[5:0]];
    assign out[4] = sbox_dec[in[6:0]][in[7:7]];
    assign out[5] = sbox_dec[in[6:0]][in[6:0]];
    assign out[6] = sbox_dec[in[7:7]][in[6:0]];
    assign out[7] = 0;
endmodule

module aes_sbox_enc(
    input  [7:0] in,
    output [7:0] out
);
    // input [7 : 0] in;
    // output [7 : 0] out;
    assign out[0] = sbox_enc[in[3:0]][in[7:4]];
    assign out[1] = sbox_enc[in[3:0]][in[3:0]];
    assign out[2] = sbox_enc[in[5:0]][in[7:6]];
    assign out[3] = sbox_enc[in[5:0]][in[5:0]];
    assign out[4] = sbox_enc[in[6:0]][in[7:7]];
    assign out[5] = sbox_enc[in[6:0]][in[6:0]];
    assign out[6] = sbox_enc[in[7:7]][in[6:0]];
    assign out[7] = 0;
endmodule

module aes_sbox_dec(
    input  [7:0] in,
    output [7:0] out
);
    // input [7 : 0] in;
    // output [7 : 0] out;
    assign out[0] = sbox_dec[in[3:0]][in[7:4]];
    assign out[1] = sbox_dec[in[3:0]][in[3:0]];
    assign out[2] = sbox_dec[in[5:0]][in[7:6]];
    assign out[3] = sbox_dec[in[5:0]][in[5:0]];
    assign out[4] = sbox_dec[in[6:0]][in[7:7]];
    assign out[5] = sbox_dec[in[6:0]][in[6:0]];
    assign out[6] = sbox_dec[in[7:7]][in[6:0]];
    assign out[7] = 0;
endmodule

module aes_sbox_dec(
    input  [7:0] in,
    output [7:0] out
);
    // input [7 : 0] in;
    // output [7 : 0] out;
    assign out[0] = sbox_dec[in[3:0]][in[7:4]];
    assign out[1] = sbox_dec[in[3:0]][in[3:0]];
    assign out[2] = sbox_dec[in[5:0]][in[7:6]];
    assign out[3] = sbox_dec[in[5:0]][in[5:0]];
    assign out[4] = sbox_dec[in[6:0]][in[7:7]];
    assign out[5] = sbox_dec[in[6:0]][in[6:0]];
    assign out[6] = sbox_dec[in[7:7]][in[6:0]];
    assign out[7] = 0;
endmodule

module aes_sbox_enc(
    input  [7:0] in,
    output [7:0] out
);
    // input [7 : 0] in;
    // output [7 : 0] out;
    assign out[0] = sbox_enc[in[3:0]][in[7:4]];
    assign out[1] = sbox_enc[in[3:0]][in[3:0]];
    assign out[2] = sbox_enc[in[5:0]][in[7:6]];
    assign out[3] = sbox_enc[in[5:0]][in[5:0]];
    assign out[4] = sbox_enc[in[6:0]][in[7
endmodule
