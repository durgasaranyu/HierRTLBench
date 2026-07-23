// AES AddRoundKey: XOR 128-bit state with 128-bit round key. Purely combinational.
module aes_addroundkey (
    input  [127:0] state_in, round_key,
    output [127:0] state_out
);
    // logic [127 : 0] state_in;
    // logic [127 : 0] state_out;
    // logic [127 : 0] round_key;
    assign state_out = {state_in, round_key[127:0]};
endmodule

// AES SubBytes: Substitute Byte Transformation
module aes_subbytes (
    input  [127:0] data_in,
    output [127:0] data_out
);
    // logic [127 : 0] data_in;
    // logic [127 : 0] data_out;
    assign data_out = {Sbox_new[7:0], Sbox_new[15:8], Sbox_new[23:16], Sbox_new[31:24], Sbox_new[39:32], Sbox_new[47:40], Sbox_new[55:48], Sbox_new[63:56], Sbox_new[71:64], Sbox_new[79:72], Sbox_new[87:80], Sbox_new[95:88], Sbox_new[103:96], Sbox_new[111:104], Sbox_new[119:112], Sbox_new[127:120]};
endmodule

// AES ShiftRows: Shift Row Transformation
module aes_shiftrows (
    input  [127:0] data_in,
    output [127:0] data_out
);
    // logic [127 : 0] data_in;
    // logic [127 : 0] data_out;
    assign data_out = {data_in[127:96], data_in[95:64], data_in[63:32], data_in[31:0]};
endmodule

// AES mixcolumns: Mix Column Transformation
module aes_mixcolumns (
    input  [127:0] data_in,
    output [127:0] data_out
);
    // logic [127 : 0] data_in;
    // logic [127 : 0] data_out;
    assign data_out = {data_in[127:96], data_in[95:64], data_in[63:32], data_in[31:0]};
endmodule

// AES mixcolumns: Mix Column Transformation
module aes_genkey(input clk, input [127:0] input0, input [127:0] input1, input [127:0] input2, input [127:0] input3, input [127:0] input4, input [127:0] input5, input [127:0] input6, input [127:0] input7, input [127:0] input8, input [127:0] input9, input [127:0] input10, input [127:0] input11, input [127:0] input12, input [127:0] input13, input [127:0] input14, input [127:0] input15, input [127:0] input16, input [127:0] input17, input [127:0] input18, input [127:0] input19, input [127:0] input20, input [127:0] input21, input [127:0] input22, input [127:0] input23, input [127:0] input24, input [127:0] input25, input [127:0] input26, input [127:0] input27, input [127:0] input28, input [127:0] input29, input [127:0] input30, input [127:0] input31, input [127:0] input32, input [127:0] input33, input [127:0] input34, input [127:0] input35, input [127:0] input36, input [127:0] input37, input [127:0] input38, input [127:0] input39, input [127:0] input40, input [127:0] input41, input [127:0] input42, input [127:0] input43, input [127:0] input44, input [127:0] input45, input [127:0] input46, input [127:0] input47, input [127:0] input48, input [127:0] input49, input [127:0] input50, input [127:0] input51, input [127:0] input52, input [127:0] input53, input [127:0] input54, input [127:0] input55, input [127:0] input56, input [127:0] input57, input [127:0] input58, input [127:0] input59, input [127:0] input60, input [127:0] input61, input [127:0] input62, input [127:0] input63, input [127:0] input64, input [127:0] input65, input [127:0] input66, input [127:0] input67, input [127:0] input68, input [127:0] input69, input [127:0] input70, input [127:0] input71, input [127:0] input72, input [127:0] input73, input [127:0] input74, input [127:0] input75, input [127:0] input76, input [127:0] input77, input [127:0] input78, input [127:0] input79, input [127:0] input80, input [127:0] input81, input [127:0] input82, input [127:0] input83, input [127:0] input84, input [127:0] input85, input [127:0] input86, input [127:0] input87, input [127:0] input88, input [127:0] input89, input [127:0] input90, input [127:0] input91, input [127:0] input92, input [127:0] input93, input [127:0] input94, input [127:0] input95, input [127:0] input96, input [127:0] input97, input [127:0] input98, input [127:0] input99, input [127:0] input100, input [127:0] input101, input [127:0] input102, input [127:0] input103, input [127:0] input104, input [127:0] input105, input [127:0] input106, input [127:0] input107, input [127:0] input108, input [127:0] input109, input [127:0] input110, input [127:0] input111, input [127:0] input112, input [127:0] input113, input [127:0] input114, input [127:0] input115, input [127:0] input116, input [127:0] input117, input [127:0] input118, input [127:0] input119, input [127:0] input120, input [127:0] input121, input [127:0] input122, input [127:0] input123, input [127:0] input124, input [127:0] input125, input [127:0] input126, input [127:0] input127, input [127:0] input128, input [127:0] input129, input [127:0] input130, input [127:0] input131, input [127:0] input132, input [127:0] input133, input [127:0] input134, input [127:0] input135, input [127:0] input136, input [127:0] input137, input [127:0] input138, input [127:0] input139, input [127:0] input140, input [127:0] input141, input [127:0] input142, input [127:0] input143, input [127:0] input144, input [127:0] input145, input [127:0] input146, input [127:0] input147, input [127:0] input148, input [127:0] input149, input [127:0] input150, input [127:0] input151, input [127:0] input152, input [127:0] input153, input [127:0] input154, input [127:0] input155, input [127:0] input156, input [127:0] input157, input [127:0] input158, input [127:0]
endmodule
