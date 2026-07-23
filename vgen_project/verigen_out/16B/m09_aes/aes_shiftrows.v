// AES ShiftRows: row0 no-shift, row1 left-1, row2 left-2, row3 left-3.
// State is column-major: byte[127:120]=col0/row0... byte[7:0]=col3/row3.
module aes_shiftrows (
    input  [127:0] state_in,
    output [127:0] state_out
);
    // ShiftRows: Shift the bytes in each column to the left by 1, 2, or 3
    // bits, and concatenate the result into the new state.
    // See https://cs.ucsb.edu/~koc/cs290g/docs/w01/aes_prim.pdf
    assign state_out = {
        state_in[127:120] ^ {state_in[124:0] << 1, state_in[124:0] >> 1},
        state_in[119:112] ^ {state_in[120:1] << 2, state_in[120:1] >> 2},
        state_in[111:104] ^ {state_in[112:2] << 3, state_in[112:2] >> 3},
        state_in[103:96] ^ {state_in[104:3] << 4, state_in[104:3] >> 4},
        state_in[95:88] ^ {state_in[96:4] << 5, state_in[96:4] >> 5},
        state_in[87:80] ^ {state_in[88:5] << 6, state_in[88:5] >> 6},
        state_in[79:72] ^ {state_in[80:6] << 7, state_in[80:6] >> 7},
        state_in[71:64] ^ {state_in[72:7] << 8, state_in[72:7] >> 8},
        state_in[63:56] ^ {state_in[64:8] << 9, state_in[64:8] >> 9},
        state_in[55:48] ^ {state_in[56:9] << 10, state_in[56:9] >> 10},
        state_in[47:40] ^ {state_in[48:10] << 11, state_in[48:10] >> 11},
        state_in[39:32] ^ {state_in[40:11] << 12, state_in[40:11] >> 12},
        state_in[31:24] ^ {state_in[32:12] << 13, state_in[32:12] >> 13},
        state_in[23:16] ^ {state_in[24:13] << 14, state_in[24:13] >> 14},
        state_in[15:8] ^ {state_in[16:14] << 15, state_in[16:14] >> 15},
        state_in[7:0] ^ {state_in[8:15] << 16, state_in[8:15] >> 16}
    };

endmodule
