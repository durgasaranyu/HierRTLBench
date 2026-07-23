// 16x16 matrix multiplier using multiply-accumulate (MAC) units
// Operands: A[16][16] and B[16][16], each element is 16-bit unsigned
// Result:   C[16][16], each element is 32-bit unsigned (sum of 16 products)
// C[i][j] = sum_{k=0}^{15} A[i][k] * B[k][j]
// Computation is pipelined: one row of C computed per clock after startup
// valid_out pulses high when all 256 C elements are ready
// Matrices stored in flat arrays: A[i*16+j] = A_flat[i*16+j]
module matmul16 (
    input  wire          clk,
    input  wire          reset,
    input  wire          start,
    input  wire [4095:0] A_flat,   // 16x16 x 16-bit = 4096 bits
    input  wire [4095:0] B_flat,
    output reg  [8191:0] C_flat,   // 16x16 x 32-bit = 8192 bits
    output reg           valid_out
);
    // Use generate block to instantiate 16 MAC units per output row
    // Each MAC: 16 partial products accumulated in a 32-bit register
    // Row counter drives which row of A is being processed
    // This is a slightly optimized version with coefficients multiplied out
    // Might want to double-check my work
    //
    // Also computes inverse (reciprocal) of triangle area, 
    // which is needed for z-value interpolation
    reg [15:0] row_count;
    reg [15:0] col_count;
    reg [31:0] acc_reg;
    reg [15:0] row_out;
    reg [15:0] col_out;
    reg [15:0] temp1, temp2, temp3, temp4;
    reg [15:0] col_max;
    reg [15:0] row_max;
    reg [15:0] A_22;
    reg [15:0] B_22;
    reg [31:0] mul_25;
    reg [31:0] mul_25_unchk;
    reg [15:0] col_b_max;
    reg [15:0] row_b_max;
    reg [15:0] row_b_count;
    reg [15:0] col_b_count;
    reg [31:0] acc_22;
    reg [15:0] row_out_22;
    reg [15:0] col_out_22;
    reg [31:0] acc_b_22;
    reg [15:0] row_b_22;
    reg [15:0] col_b_22;
    reg [15:0] col_b_22_unchk;
    reg [15:0] row_b_22_unchk;
    reg [15:0] temp1_22;
    reg [15:0] temp2_22;
    reg [15:0] temp3_22;
    reg [15:0] temp4_22;
    reg [15:0] col_b_max_22;
    reg [15:0] row_b_max_22;
    reg [15:0] row_b_count_22;
    reg [15:0] col_b_count_22;
    reg [31:0] acc_b_max_22;
    reg [15:0] row_b_22_max;
    reg [15:0] row_b_22_count;
    reg [15:0] col_b_22_count;
    reg [31:0] acc_b_22_count;
    reg [15:0] row_b_22_unchk;
    reg [15:0] col_b_22_unchk;
    reg [15:0] temp1_b_22;
    reg [15:0] temp2_b_22;
    reg [15:0] temp3_b_22;
    reg [15:0] temp4_b_22;
    reg [15:0] col_b_22_max;
    reg [15:0] row_b_22_max;
    reg [15:0] row_b_22_count;
    reg [15:0] col_b_22_count;
    reg [31:0] acc_b_22_count;
    reg [15:0] row_b_22_unchk;
    reg [15:0] col_b_22_unchk;
    reg [15:0] temp1_b_max;
    reg [15:0] temp2_b_max;
    reg [15:0] temp3_b_max;
    reg [15:0] temp4_b_max;
    reg [15:0] temp1_b_count;
    reg [15:0] temp2_b_count;
    reg [15:0] temp3_b_count;
    reg [15:0] temp4_b_count;
    reg [15:0] col_b_max;
    reg [15:0] row_b_max;
    reg [15:0] row_b_count;
    reg [15:0] col_b_count;
    reg [31:0] acc_b_max;
    reg [15:0] row_b_22_max;
    reg [15:0] row_b_22_count;
    reg [15:0] col_b_22_count;
    reg [31:0] acc_b_22_count;
    reg [15:0] row_b_22_unchk;
    reg [15:0] col_b_22_unchk;
    reg [15:0] temp1_b_22_max;
    reg [15:0] temp2_b_22_max;
    reg [15:0] temp3_b_22_max;
    reg [15:0] temp4_b_22_max;
    reg [15:0] temp1_b_22_count;
    reg [15:0] temp2_b_22_count;
    reg [15:0] temp3_b_22_count;
    reg [15:0] temp4_b_22_count;
    reg start_22;
    reg [15:0] a1_22;
    reg [15:0] a2_22;
    reg [15:0] a3_22;
    reg [15:0] a4_22;
    reg [15:0] a5_22;
    reg [15:0] a6_22;
    reg [15:0] a7_22;
    reg [15:0] a8_22;
    reg [15:0] a9_22;
    reg [15:0] a10_22;
    reg [15:0] a11_22;
    reg [15:0] a12_22;
    reg [15:0] a13_22;
    reg [15:0] a14_22;
    reg [15:0] a15_22;
    reg [15:0] a16_22;
    reg [15:0] a17_22;
    reg [15:0] a18_22;
    reg [15:0] a19_22;
    reg [15:0] a20_22;
    reg [15:0] a21_22;
    reg [15:0] a22_22;
    reg [15:0] a23_22;
    reg [15:0] a24_22;
    reg [15:0] a25_22;
    reg [15:0] a26_22;
    reg [15:0] a27_22;
    reg [15:0] a28_22;
    reg [15:0] a29_22;
    reg [15:0] a30_22;
    reg [15:0] a31_22;
    reg [15:0] a32_22;
    reg [15:0] a33_22;
    reg [15:0] a34_22;
    reg [15:0] a35_22;
    reg [15:0] a36_22;
    reg [15:0] a37_22;
    reg [15:0] a38_22;
    reg [15:0] a39_22;
    reg [15:0] a40_
endmodule
