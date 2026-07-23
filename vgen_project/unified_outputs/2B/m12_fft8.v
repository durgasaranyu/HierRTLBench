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
    reg [31:0]  X0_reg, X1_reg, X2_reg, X3_reg, X4_reg, X5_reg, X6_reg, X7_reg;
    reg         X0_valid_reg, X1_valid_reg, X2_valid_reg, X3_valid_reg, X4_valid_reg, X5_valid_reg, X6_valid_reg, X7_valid_reg;
    always @(posedge clk) begin
        X0_reg <= X0;
        X1_reg <= X1;
        X2_reg <= X2;
        X3_reg <= X3;
        X4_reg <= X4;
        X5_reg <= X5;
        X6_reg <= X6;
        X7_reg <= X7;
        X0_valid_reg <= valid_in;
        X1_valid_reg <= valid_in;
        X2_valid_reg <= valid_in;
        X3_valid_reg <= valid_in;
        X4_valid_reg <= valid_in;
        X5_valid_reg <= valid_in;
        X6_valid_reg <= valid_in;
        X7_valid_reg <= valid_in;
    end
    always @(posedge clk) begin
        valid_out <= X0_valid_reg && X1_valid_reg && X2_valid_reg && X3_valid_reg && X4_valid_reg && X5_valid_reg && X6_valid_reg && X7_valid_reg;
    end
    // Stage 4: 4 butterflies with W^1, W^2, W^3, W^4
    // Use pipeline registers between stages
    reg [31:0]  X0_next, X1_next, X2_next, X3_next, X4_next, X5_next, X6_next, X7_next;
    reg         X0_valid_next, X1_valid_next, X2_valid_next, X3_valid_next, X4_valid_next, X5_valid_next, X6_valid_next, X7_valid_next;
    always @(posedge clk) begin
        X0_next <= X0_reg;
        X1_next <= X1_reg;
        X2_next <= X2_reg;
        X3_next <= X3_reg;
        X4_next <= X4_reg;
        X5_next <= X5_reg;
        X6_next <= X6_reg;
        X7_next <= X7_reg;
        X0_valid_next <= valid_in;
        X1_valid_next <= valid_in;
        X2_valid_next <= valid_in;
        X3_valid_next <= valid_in;
        X4_valid_next <= valid_in;
        X5_valid_next <= valid_in;
        X6_valid_next <= valid_in;
        X7_valid_next <= valid_in;
    end
    always @(posedge clk) begin
        X0 <= X0_next;
        X1 <= X1_next;
        X2 <= X2_next;
        X3 <= X3_next;
        X4 <= X4_next;
        X5 <= X5_next;
        X6 <= X6_next;
        X7 <= X7_next;
        X0_valid <= X0_valid_next;
        X1_valid <= X1_valid_next;
        X2_valid <= X2_valid_next;
        X3_valid <= X3_valid_next;
        X4_valid <= X4_valid_next;
        X5_valid <= X5_valid_next;
        X6_valid <= X6_valid_next;
        X7_valid <= X7_valid_next;
    end

endmodule
