// AES-128 encryption core top. 10-round FSM. start pulses encryption.
// done asserts when ciphertext is ready.
module aes128 (
    input         clk, rst, start,
    input  [127:0] plaintext, key,
    output [127:0] ciphertext,
    output         done
);
    // constant declaration
    localparam AES128_KEY_128_BITS = "yb7a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babcbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddeddde0e1e2e3e4e5e6e7e8e9eaebecedeeefefefe;
    localparam AES128_ROUNDS = 10;
    // round state
    reg [7 : 0] round;
    // control state
    reg [4 : 0] state;
    // round key
    reg [127 : 0] key_r [0 : AES128_ROUNDS-1];
    // round input
    reg [127 : 0] in_r [0 : AES128_ROUNDS-1];
    // round output
    reg [127 : 0] out_r [0 : AES128_ROUNDS-1];
    // done
    reg done_r;
    // fsm
    reg [3 : 0] count;
    // round
    reg [127 : 0] in_block;
    // key
    reg [127 : 0] key;
    // key schedule
    reg [127 : 0] key_r_out;
    // subbytes
    reg [127 : 0] sbox_r_out;
    // addroundkey
    reg [127 : 0] addroundkey_in;
    // addroundkey
    reg [127 : 0] addroundkey_out;
    // mux
    reg [127 : 0] mux_out;
    // mux
    reg [127 : 0] mux_out_r;
    // mux
    reg [127 : 0] mux_out_r_1;
    // mux
    reg [127 : 0] mux_out_r_2;
    // mux
    reg [127 : 0] mux_out_r_3;
    // mux
    reg [127 : 0] mux_out_r_4;
    // mux
    reg [127 : 0] mux_out_r_5;
    // mux
    reg [127 : 0] mux_out_r_6;
    // mux
    reg [127 : 0] mux_out_r_7;
    // mux
    reg [127 : 0] mux_out_r_8;
    // mux
    reg [127 : 0] mux_out_r_9;
    // mux
    reg [127 : 0] mux_out_r_10;
    // mux
    reg [127 : 0] mux_out_r_11;
    // mux
    reg [127 : 0] mux_out_r_12;
    // mux
    reg [127 : 0] mux_out_r_13;
    // mux
    reg [127 : 0] mux_out_r_14;
    // mux
    reg [127 : 0] mux_out_r_15;
    // mux
    reg [127 : 0] mux_out_r_16;
    // mux
    reg [127 : 0] mux_out_r_17;
    // mux
    reg [127 : 0] mux_out_r_18;
    // mux
    reg [127 : 0] mux_out_r_19;
    // mux
    reg [127 : 0] mux_out_r_20;
    // mux
    reg [127 : 0] mux_out_r_21;
    // mux
    reg [127 : 0] mux_out_r_22;
    // mux
    reg [127 : 0] mux_out_r_23;
    // mux
    reg [127 : 0] mux_out_r_24;
    // mux
    reg [127 : 0] mux_out_r_25;
    // mux
    reg [127 : 0] mux_out_r_26;
    // mux
    reg [127 : 0] mux_out_r_27;
    // mux
    reg [127 : 0] mux_out_r_28;
    // mux
    reg [127 : 0] mux_out_r_29;
    // mux
    reg [127 : 0] mux_out_r_30;
    // mux
    reg [127 : 0] mux_out_r_31;
    // mux
    reg [127 : 0] mux_out_r_32;
    // mux
    reg [127 : 0] mux_out_r_33;
    // mux
    reg [127 : 0] mux_out_r_34;
    // mux
    reg [127 : 0] mux_out_r_35;
    // mux
    reg [127 : 0] mux_out_r_36;
    // mux
    reg [127 : 0] mux_out_r_37;
    // mux
    reg [127 : 0] mux_out_r_38;
    // mux
    reg [127 : 0] mux_out_r_39;
    // mux
    reg [127 : 0] mux_out_r_40;
    // mux
    reg [127 : 0] mux_out_r_41;
    // mux
    reg [127 : 0] mux_out_r_42;
    // mux
    reg [127 : 0] mux_out_r_43;
    // mux
    reg [127 : 0] mux_out_r_44;
    // mux
    reg [127 : 0] mux_out_r_45;
    // mux
    reg [127 : 0] mux_out_r_46;
    // mux
    reg [127 : 0] mux_out_r_47;
    // mux
    reg [127 : 0] mux_out_r_48;
    // mux
    reg [127 : 0] mux_out_r_49;
    // mux
    reg [127 : 0] mux_out_r_50;
    // mux
    reg [127 : 0] mux_out_r_51;
    // mux
    reg [127 : 0] mux_out_r_52;
    // mux
    reg [127 : 0] mux_out_r_53;
    // mux
    reg [127 : 0] mux_out_r_54;
    // mux
    reg [127 : 0] mux_out_r_55;
    // mux
    reg [127 : 0] mux_out_r_56;
    // mux
    reg [127 : 0] mux_out_r_57;
    // mux
    reg [127 : 0] mux_out_r_58;
    // mux
    reg [127 : 0] mux_out_r_59;
    // mux
    reg [127 : 0] mux_out_r_60;
    // mux
    reg [127 : 0] mux_out_r_61;
    // mux
    reg [127 : 0] mux_out_r_62;
    // mux
    reg [127 : 0] mux_out_r_63;
    // mux
    reg [127 : 0] mux_out_r_64;
    // mux
    reg [127 : 0] mux_out_r_65;
    // mux
    reg [127 : 0] mux_out_r_66;
    // mux
    reg [127 : 0] mux_out_r_67;
    // mux
    reg [127 : 0] mux_out_r_68;
    // mux
    reg [127 : 0] mux_out_r_69;
    // mux
    reg [127 : 0] mux_out_r_70;

endmodule
