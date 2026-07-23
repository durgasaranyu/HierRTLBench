// AES SubBytes: applies S-box to each of 16 bytes in 128-bit state.
module aes_subbytes (
    input  [127:0] state_in,
    output [127:0] state_out
);
    assign state_out = subbytes(state_in);

endmodule
