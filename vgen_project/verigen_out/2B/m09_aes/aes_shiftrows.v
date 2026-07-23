// AES ShiftRows: row0 no-shift, row1 left-1, row2 left-2, row3 left-3.
// State is column-major: byte[127:120]=col0/row0... byte[7:0]=col3/row3.
module aes_shiftrows (
    input  [127:0] state_in,
    output [127:0] state_out
);

wire [127:0] sbox_result;

sbox sbox_0(.state_in(state_in[127:120]),.state_out(sbox_result[127:120]));
sbox sbox_1(.state_in(state_in[119:112]),.state_out(sbox_result[119:112]));
sbox sbox_2(.state_in(state_in[111:104]),.state_out(sbox_result[111:104]));
sbox sbox_3(.state_in(state_in[103:96]),.state_out(sbox_result[103:96]));
sbox sbox_4(.state_in(state_in[95:88]),.state_out(sbox_result[95:88]));
sbox sbox_5(.state_in(state_in[87:80]),.state_out(sbox_result[87:80]));
sbox sbox_6(.state_in(state_in[79:72]),.state_out(sbox_result[79:72]));
sbox sbox_7(.state_in(state_in[71:64]),.state_out(sbox_result[71:64]));
sbox sbox_8(.state_in(state_in[63:56]),.state_out(sbox_result[63:56]));
sbox sbox_9(.state_in(state_in[55:48]),.state_out(sbox_result[55:48]));
sbox sbox_10(.state_in(state_in[47:40]),.state_out(sbox_result[47:40]));
sbox sbox_11(.state_in(state_in[39:32]),.state_out(sbox_result[39:32]));
sbox sbox_12(.state_in(state_in[31:24]),.state_out(sbox_result[31:24]));
sbox sbox_13(.state_in(state_in[23:16]),.state_out(sbox_result[23:16]));
sbox sbox_14(.state_in(state_in[15:8]),.state_out(sbox_result[15:8]));
sbox sbox_15(.state_in(state_in[7:0]),.state_out(sbox_result[7:0]));

assign state_out[127:120] = sbox_result[127:120];
assign state_out[119:112] = sbox_result[119:112];
assign state_out[111:104] = sbox_result[111:104];
assign state_out[103:96] = sbox_result[103:96];
assign state_out[95:88] = sbox_result[95:88];
assign state_out[87:80] = sbox_result[87:80];
assign state_out[79:72] = sbox_result[79:72];
assign state_out[71:64] = sbox_result[71:64];
assign state_out[63:56] = sbox_result[63:56];
assign state_out[55:48] = sbox_result[55:48];
assign state_out[47:40] = sbox_result[47:40];
assign state_out[39:32] = sbox_result[39:32];
assign state_out[31:24] = sbox_result[31:24];
assign state_out[23:16] = sbox_result[23:16];
assign state_out[15:8] = sbox_result[15:8];
assign state_out[7:0] = sbox_result[7:0];


endmodule
