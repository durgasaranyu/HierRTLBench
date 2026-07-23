// AES-128 encryption core — single round function module
// (Use chunked prompting: generate SubBytes, MixColumns, top-level separately)
// This prompt: complete AES-128 top-level for ONE encryption round
// SubBytes: apply 8-bit S-box lookup to each of 16 bytes of state
// S-box[0x00]=0x63, S-box[0x01]=0x7c, S-box[0x02]=0x77... (full 256-entry LUT)
// ShiftRows: row i shifted left by i bytes (i=0,1,2,3)
// MixColumns: each column multiplied by fixed matrix in GF(2^8) mod 0x11b
// AddRoundKey: state XOR round_key
// 10 rounds total; final round skips MixColumns
// 128-bit state represented as 16 bytes [127:0]
module aes128_enc (
    input  wire          clk,
    input  wire          reset,
    input  wire          start,
    input  wire [127:0]  plaintext,
    input  wire [127:0]  key,
    output reg  [127:0]  ciphertext,
    output reg           done
);
    // Key schedule: expand 128-bit key to 11 round keys (1408 bits total)
    // Round counter: 0..10
    // State machine: IDLE -> ROUND(10 iterations) -> DONE
    // S-box must be a 256x8 ROM: reg [7:0] sbox [0:255]
    // State machine:
    //  state = 0: waiting for start
    //  state = 1: waiting for round key to advance
    //  state = 2: waiting for AddRoundKey to advance
    //  state = 3: waiting for S-box to advance
    //  state = 4: waiting for next output byte
    //  state = 5: output byte advanced
    //  state = 6: done
    reg [10:0] round;
    reg [127:0] state;
    reg [127:0] round_key;
    reg [7:0] sbox [0:255];
    reg [127:0] sub_bytes [0:1023];
    reg [127:0] mix_cols [0:1023];
    reg [127:0] add_round_key;
    reg [127:0] final_output;
    reg [127:0] round_out;
    reg [127:0] sbox_out;
    reg [127:0] mix_col_out;
    reg [127:0] add_round_key_out;
    reg [127:0] sub_bytes_out;
    reg [127:0] final_output_out;
    reg [127:0] round_out_out;
    reg [127:0] sbox_out_out;
    reg [127:0] mix_col_out_out;
    reg [127:0] add_round_key_out_out;
    reg [127:0] sub_bytes_out_out;
    reg [127:0] final_output_out_out;
    reg [127:0] round_out_out_out;
    reg [127:0] sbox_out_out_out;
    reg [127:0] mix_col_out_out_out;
    reg [127:0] add_round_key_out_out_out;
    reg [127:0] sub_bytes_out_out_out;
    reg [127:0] final_output_out_out_out;
    reg [127:0] round_out_out_out_out;
    reg [127:0] sbox_out_out_out_out;
    reg [127:0] mix_col_out_out_out_out;
    reg [127:0] add_round_key_out_out_out_out;
    reg [127:0] sub_bytes_out_out_out_out;
    reg [127:0] final_output_out_out_out;
    reg [127:0] round_out_out_out_out;
    reg [127:0] sbox_out_out_out_out;
    reg [127:0] mix_col_out_out_out_out;
    reg [127:0] add_round_key_out_out_out_out;
    reg [127:0] sub_bytes_out_out_out_out;
    reg [127:0] final_output_out_out_out;
    reg [127:0] round_out_out_out_out;
    reg [127:0] sbox_out_out_out_out;
    reg [127:0] mix_col_out_out_out_out;
    reg [127:0] add_round_key_out_out_out_out;
    reg [127:0] sub_bytes_out_out_out_out;
    reg [127:0] final_output_out_out_out;
    reg [127:0] round_out_out_out_out;
    reg [127:0] sbox_out_out_out_out;
    reg [127:0] mix_col_out_out_out_out;
    reg [127:0] add_round_key_out_out_out_out;
    reg [127:0] sub_bytes_out_out_out_out;
    reg [127:0] final_output_out_out_out;
    reg [127:0] round_out_out_out_out;
    reg [127:0] sbox_out_out_out_out;
    reg [127:0] mix_col_out_out_out_out;
    reg [127:0] add_round_key_out_out_out_out;
    reg [127:0] sub_bytes_out_out_out_out;
    reg [127:0] final_output_out_out_out;
    reg [127:0] round_out_out_out_out;
    reg [127:0] sbox_out_out_out_out;
    reg [127:0] mix_col_out_out_out_out;
    reg [127:0] add_round_key_out_out_out_out;
    reg [127:0] sub_bytes_out_out_out_out;
    reg [127:0] final_output_out_out_out;
    reg [127:0] round_out_out_out_out;
    reg [127:0] sbox_out_out_out_out;
    reg [127:0] mix_col_out_out_out_out;
    reg [127:0] add_round_key_out_out_out_out;
    reg [127:0] sub_bytes_out_out_out_out;
    reg [127:0] final_output_out_out_out;
    reg [127:0] round_out_out_out_out;
    reg [127:0] sbox_out_out_out_out;
    reg [127:0] mix_col_out_out_out_out;
    reg [127:0] add_round_key_out_out_out_out;
    reg [127:0] sub_bytes_out_out_out_out;
    reg [127:0] final_output_out_out_out;
    reg [127:0] round_out_out_out_out;
    reg [127:0] sbox_out_out_out_out;
    reg [127:0] mix_col_out_out_out_out;
    reg [127:0] add_round_key_out_out_out_out;
    reg [127:0] sub_bytes_out_out_out_out;
    reg [127:0] final_output_out_out_out;
    reg [127:0] round_out_out_out_out;
    reg [127:0] sbox_out_out_out_out;
    reg [127:0] mix_col_out_out_out_out;
    reg [127:0] add_round_key_out_out_out_out;
    reg [127:0] sub_bytes_out_out_out_out;
    reg [127:0] final_output_out_out_out;
    reg [127:0] round_out_out_out_out;
    reg [127:0] sbox_out
endmodule
