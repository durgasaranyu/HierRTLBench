`timescale 1ns/1ps
// M13: 16x16 matrix multiply integration top
// 16 mat_row instances run in parallel (one per row of A).
// A column counter sequences through columns 0..15 of B.
// Each column takes 16 cycles. Total wall time = 16*16 = 256 cycles.
// C[i][j] = A_row_i · B_col_j  stored at C_flat[32*(16*i+j) +: 32].
// Row-major storage: A_flat[256*i +: 256] = row i of A (16x 16-bit elements).
//                    B_flat[32*(16*r+c) +: 32] = B[r][c]
module matrix_mult_integration (
    input          clk, rst, start,
    input  [4095:0] A_flat, B_flat,
    output reg [8191:0] C_flat,
    output             done
);
    // ── Column extraction helper ──────────────────────────────────────────────
    // col_j_flat[16*r +: 16] = B[r][col] for r=0..15, packed as 256-bit vector
    // B stores 32-bit elements; take lower 16 bits as the unsigned value
    function [255:0] get_col;
        input [4095:0] B;
        input [3:0]    col;
        integer r;
        begin
            for (r = 0; r < 16; r = r+1)
                get_col[16*r +: 16] = B[32*(16*r + col) +: 16];
        end
    endfunction

    // ── Sequencer ─────────────────────────────────────────────────────────────
    reg [3:0]  col;
    reg        row_start;
    reg [1:0]  seq;
    localparam S_IDLE=2'd0, S_KICK=2'd1, S_WAIT=2'd2, S_DONE=2'd3;

    wire [255:0] col_b_flat = get_col(B_flat, col);

    // ── 16 mat_row instances ──────────────────────────────────────────────────
    genvar gi;
    wire [31:0] rres [0:15];
    wire [15:0] rdone;

    generate
        for (gi = 0; gi < 16; gi = gi+1) begin : ROWS
            mat_row u_r (
                .clk(clk), .rst(rst),
                .start(row_start),
                .row_a_flat(A_flat[256*gi +: 256]),
                .col_b_flat(col_b_flat),
                .result(rres[gi]),
                .done(rdone[gi])
            );
        end
    endgenerate

    // ── Collect results ───────────────────────────────────────────────────────
    integer ri;
    always @(posedge clk) begin
        if (rdone[0]) begin   // all 16 rows finish simultaneously
            for (ri = 0; ri < 16; ri = ri+1)
                C_flat[32*(16*ri + col) +: 32] <= rres[ri];
        end
    end

    // ── FSM ───────────────────────────────────────────────────────────────────
    always @(posedge clk) begin
        if (rst) begin
            seq <= S_IDLE; col <= 0; row_start <= 0;
        end else begin
            row_start <= 0;
            case (seq)
                S_IDLE: if (start) begin col <= 0; seq <= S_KICK; end
                S_KICK: begin row_start <= 1; seq <= S_WAIT; end
                S_WAIT: if (rdone[0]) begin
                    if (col == 4'd15) seq <= S_DONE;
                    else begin col <= col + 1; seq <= S_KICK; end
                end
                S_DONE: seq <= S_IDLE;
            endcase
        end
    end

    assign done = (seq == S_DONE);
endmodule
