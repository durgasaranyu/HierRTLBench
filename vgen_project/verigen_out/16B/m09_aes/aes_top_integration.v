`timescale 1ns/1ps
// M09: AES-128 encryption integration top
// 10-round FSM. All round submodules are purely combinational.
// INIT: state = plaintext XOR rk[0]
// ROUND 1-9: sub → shift → mix → addroundkey
// FINAL (round 10): sub → shift → addroundkey (no mix)
module aes128_integration (
    input          clk, rst, start,
    input  [127:0] plaintext, key,
    output reg [127:0] ciphertext,
    output reg         done
);
    localparam IDLE=3'd0, INIT=3'd1, ROUND=3'd2, FINAL=3'd3, DONE_ST=3'd4;
    reg [2:0] state;
    reg [3:0] round;        // 1..9 for ROUND, 10 for FINAL

    // Key schedule: combinational, 11x128-bit round keys packed as 1408 bits
    wire [1407:0] rk_all;
    aes_keyschedule u_ks (.key(key), .round_keys(rk_all));

    wire [127:0] cur_rk = rk_all[128*round +: 128];

    // State register (updated each FSM clock)
    reg [127:0] aes_st;

    // Round pipeline (combinational, fed from aes_st)
    wire [127:0] sb_out, sr_out, mc_out;
    wire [127:0] ark_round, ark_final, ark_init;

    aes_subbytes    u_sb  (.state_in(aes_st),    .state_out(sb_out));
    aes_shiftrows   u_sr  (.state_in(sb_out),    .state_out(sr_out));
    aes_mixcolumns  u_mc  (.state_in(sr_out),    .state_out(mc_out));

    // Rounds 1-9: addroundkey after mix
    aes_addroundkey u_ark_r (.state_in(mc_out),   .round_key(cur_rk), .state_out(ark_round));
    // Round 10 (final): addroundkey after shift (no mix)
    aes_addroundkey u_ark_f (.state_in(sr_out),   .round_key(cur_rk), .state_out(ark_final));
    // Initial round: plaintext XOR rk[0]
    aes_addroundkey u_ark_i (.state_in(plaintext), .round_key(rk_all[127:0]), .state_out(ark_init));

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE; round <= 4'd0; done <= 0;
            aes_st <= 0; ciphertext <= 0;
        end else begin
            done <= 0;
            case (state)
                IDLE:    if (start) state <= INIT;
                INIT: begin
                    aes_st <= ark_init;
                    round  <= 4'd1;
                    state  <= ROUND;
                end
                ROUND: begin
                    aes_st <= ark_round;         // sub+shift+mix+addroundkey
                    if (round == 4'd9) begin
                        round <= 4'd10;
                        state <= FINAL;
                    end else
                        round <= round + 4'd1;
                end
                FINAL: begin
                    aes_st     <= ark_final;     // sub+shift+addroundkey
                    ciphertext <= ark_final;
                    done       <= 1'b1;
                    state      <= DONE_ST;
                end
                DONE_ST: state <= IDLE;
            endcase
        end
    end
endmodule
