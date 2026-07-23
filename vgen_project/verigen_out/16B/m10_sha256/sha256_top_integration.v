`timescale 1ns/1ps
// M10: SHA-256 integration top — single 512-bit block
// sha256_msg_sched and sha256_compress are both purely combinational,
// so the FSM advances one state per clock cycle.
// FSM: IDLE -> SCHEDULE -> COMPRESS -> DONE
module sha256_integration (
    input          clk, rst, start,
    input  [511:0] block_in,
    output reg [255:0] hash_out,
    output reg         done
);
    // SHA-256 initial hash values (FIPS 180-4 §5.3.3)
    localparam [255:0] H_INIT = {
        32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a,
        32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19
    };

    localparam IDLE=2'd0, SCHEDULE=2'd1, COMPRESS=2'd2, DONE_ST=2'd3;
    reg [1:0] state;

    // Both submodules are purely combinational
    wire [2047:0] W;
    wire [255:0]  H_out;

    sha256_msg_sched u_sched (.block_in(block_in), .W(W));
    // For single-block hashing H_in = H_INIT.
    // For multi-block extend this to pass previous hash_out as H_in.
    sha256_compress  u_comp  (.H_in(H_INIT), .W(W), .H_out(H_out));

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE; done <= 0; hash_out <= 0;
        end else begin
            done <= 0;
            case (state)
                IDLE:     if (start) state <= SCHEDULE;
                SCHEDULE:            state <= COMPRESS;
                COMPRESS: begin
                    hash_out <= H_out;
                    done     <= 1'b1;
                    state    <= DONE_ST;
                end
                DONE_ST: state <= IDLE;
            endcase
        end
    end
endmodule
