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
    reg [31:0] w0_reg;
    reg [31:0] w2_reg;
    reg [31:0] w1_reg;
    reg [31:0] w3_reg;
    always @(posedge clk) begin
        w0_reg <= w0;
        w2_reg <= w2;
        w1_reg <= w1;
        w3_reg <= w3;
    end
    // Butterfly 0
    reg [31:0] a0_reg;
    reg [31:0] b0_reg;
    always @(posedge clk) begin
        a0_reg <= x0;
        b0_reg <= y0;
    end
    // Butterfly 1
    reg [31:0] a1_reg;
    reg [31:0] b1_reg;
    always @(posedge clk) begin
        a1_reg <= x1;
        b1_reg <= y1;
    end
    // Butterfly 2
    reg [31:0] a2_reg;
    reg [31:0] b2_reg;
    always @(posedge clk) begin
        a2_reg <= x2;
        b2_reg <= y2;
    end
    // Butterfly 3
    reg [31:0] a3_reg;
    reg [31:0] b3_reg;
    always @(posedge clk) begin
        a3_reg <= x3;
        b3_reg <= y3;
    end
    // Butterfly 4
    reg [31:0] a4_reg;
    reg [31:0] b4_reg;
    always @(posedge clk) begin
        a4_reg <= x4;
        b4_reg <= y4;
    end
    // Butterfly 5
    reg [31:0] a5_reg;
    reg [31:0] b5_reg;
    always @(posedge clk) begin
        a5_reg <= x5;
        b5_reg <= y5;
    end
    // Butterfly 6
    reg [31:0] a6_reg;
    reg [31:0] b6_reg;
    always @(posedge clk) begin
        a6_reg <= x6;
        b6_reg <= y6;
    end
    // Butterfly 7
    reg [31:0] a7_reg;
    reg [31:0] b7_reg;
    always @(posedge clk) begin
        a7_reg <= x7;
        b7_reg <= y7;
    end
    // Butterfly 8
    reg [31:0] a8_reg;
    reg [31:0] b8_reg;
    always @(posedge clk) begin
        a8_reg <= x8;
        b8_reg <= y8;
    end
    // Butterfly 9
    reg [31:0] a9_reg;
    reg [31:0] b9_reg;
    always @(posedge clk) begin
        a9_reg <= x9;
        b9_reg <= y9;
    end
    // Butterfly 10
    reg [31:0] a10_reg;
    reg [31:0] b10_reg;
    always @(posedge clk) begin
        a10_reg <= x10;
        b10_reg <= y10;
    end
    // Butterfly 11
    reg [31:0] a11_reg;
    reg [31:0] b11_reg;
    always @(posedge clk) begin
        a11_reg <= x11;
        b11_reg <= y11;
    end
    // Butterfly 12
    reg [31:0] a12_reg;
    reg [31:0] b12_reg;
    always @(posedge clk) begin
        a12_reg <= x12;
        b12_reg <= y12;
    end
    // Butterfly 13
    reg [31:0] a13_reg;
    reg [31:0] b13_reg;
    always @(posedge clk) begin
        a13_reg <= x13;
        b13_reg <= y13;
    end
    // Butterfly 14
    reg [31:0] a14_reg;
    reg [31:0] b14_reg;
    always @(posedge clk) begin
        a14_reg <= x14;
        b14_reg <= y14;
    end
    // Butterfly 15
    reg [31:0] a15_reg;
    reg [31:0] b15_reg;
    always @(posedge clk) begin
        a15_reg <= x15;
        b15_reg <= y15;
    end
    // Butterfly 16
    reg [31:0] a16_reg;
    reg [31:0] b16_reg;
    always @(posedge clk) begin
        a16_reg <= x16;
        b16_reg <= y16;
    end
    // Butterfly 17
    reg [31:0] a17_reg;
    reg [31:0] b17_reg;
    always @(posedge clk) begin
        a17_reg <= x17;
        b17_reg <= y17;
    end
    // Butterfly 18
    reg [31:0] a18_reg;
    reg [31:0] b18_reg;
    always @(posedge clk) begin
        a18_reg <= x18;
        b18_reg <= y18;
    end
    // Butterfly 19
    reg [31:0] a19_reg;
    reg [31:0] b19_reg;
    always @(posedge clk) begin
        a19_reg <= x19;
        b19_reg <= y19;
    end
    // Butterfly 20
    reg [31:0] a20_reg;
    reg [31:0] b20_reg;
    always @(posedge clk) begin
        a20_reg <= x20;
        b20_reg <= y20;
    end
    // Butterfly 21
    reg [31:0] a21_reg;
    reg [31:0] b21_reg;
    always @(posedge clk) begin
        a21_reg <= x21;
        b21_reg <= y21;
    end
    // Butterfly 22
    reg [31:0] a22_reg;
    reg [31:0] b22_reg;
    always @(posedge clk) begin
        a22_reg <= x22;
        b22_reg <= y22
endmodule
