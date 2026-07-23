// AES AddRoundKey: XOR 128-bit state with 128-bit round key. Purely combinational.
module aes_addroundkey (
    input  [127:0] state_in, round_key,
    output [127:0] state_out
);
    assign state_out = state_in ^ round_key;
    //assign state_out = state_in;

endmodule
