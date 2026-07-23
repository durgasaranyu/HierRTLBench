// 8-point fixed-point FFT pipeline using Cooley-Tukey DIT (decimation-in-time)
// 3 butterfly stages; bit-reversal permutation on input
// Fixed-point representation: 16-bit signed (Q1.15 format)
// Complex number: {real[15:0], imag[15:0]} packed as 32-bit word
// Twiddle factors W_8^k = e^(-j*2*pi*k/8):
//   W^0 = ( 1.000,  0.000) = (16'h7FFF, 16'h0000)
//   W^1 = ( 0.707, -0.707) = (16'h5A82, 16'hA57E)
//   W^2 = ( 0.000, -1.000) = (16'h0000, 16'h8001)
//   W^3 = (-0.707, -0.707) = (16'hA57E, 16'hA57E)
// Butterfly: A' = A + W*B;  B' = A - W*B
// Pipeline: one stage per clock; output valid 3 cycles after input
module fft8 (
    input  wire        clk,
    input  wire        reset,
    input  wire        valid_in,
    input  wire [31:0] x0, x1, x2, x3, x4, x5, x6, x7,  // bit-reversed order
    output reg  [31:0] X0, X1, X2, X3, X4, X5, X6, X7,
    output reg         valid_out
);
    // Stage 1: 4 butterflies with W^0 only
    // Stage 2: 4 butterflies with W^0, W^2
    // Stage 3: 4 butterflies with W^0, W^1, W^2, W^3
    // Use pipeline registers between stages
    reg [31:0] W0, W2;
    reg [31:0] W1, W3;
    reg [31:0] X0_r, X1_r, X2_r, X3_r;
    reg [31:0] X4_r, X5_r, X6_r, X7_r;
    reg [31:0] t0, t1, t2, t3, t4, t5, t6, t7;
    always @(posedge clk) begin
        if (reset) begin
            W0 <= 0;
            W1 <= 0;
            W2 <= 0;
            W3 <= 0;
        end else begin
            W0 <= W0_r;
            W1 <= W1_r;
            W2 <= W2_r;
            W3 <= W3_r;
        end
    end
    always @(posedge clk) begin
        if (reset) begin
            X0 <= 0;
            X1 <= 0;
            X2 <= 0;
            X3 <= 0;
            X4 <= 0;
            X5 <= 0;
            X6 <= 0;
            X7 <= 0;
        end else begin
            X0 <= X0_r;
            X1 <= X1_r;
            X2 <= X2_r;
            X3 <= X3_r;
            X4 <= X4_r;
            X5 <= X5_r;
            X6 <= X6_r;
            X7 <= X7_r;
        end
    end
    always @(posedge clk) begin
        if (reset) begin
            valid_out <= 0;
        end else begin
            valid_out <= valid_in;
        end
    end
    always @(*) begin
        W0_r  = W0;
        W1_r  = W1;
        W2_r  = W2;
        W3_r  = W3;
        X0_r  = X0;
        X1_r  = X1;
        X2_r  = X2;
        X3_r  = X3;
        X4_r  = X4;
        X5_r  = X5;
        X6_r  = X6;
        X7_r  = X7;
        // Input to Stage 1
        t0    = X0 + X4;
        t1    = X1 + X5;
        t2    = X2 + X6;
        t3    = X3 + X7;
        // Input to Stage 2
        t4    = t0 + t2;
        t5    = t1 + t3;
        // Input to Stage 3
        t6    = t4 + t5;
        t7    = t0 - t2;
        t8    = t1 - t3;
        // Outputs of Stage 1
        X0    = t4 + t5;
        X1    = t6 + t7;
        X2    = t6 - t7;
        X3    = t8 + t3;
        // Outputs of Stage 2
        X4    = t0 - t2;
        X5    = t1 - t3;
        X6    = t4 - t5;
        X7    = t8 - t3;
        // Outputs of Stage 3
        X8    = t6 + t7;
        X9    = t8 - t3;
        X10   = t8 - t7;
        X11   = t6 - t7;
        X12   = t4 - t5;
        X13   = t4 + t5;
        X14   = t2 + t3;
        X15   = t2 - t3;
    end

endmodule
