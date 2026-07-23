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
    // Column counter drives which column of B is being processed
    reg  [15:0] A_row_count;
    reg  [15:0] B_column_count;
    reg  [15:0] row_count;
    reg  [15:0] column_count;
    reg  [15:0] column_count_limit;
    reg  [15:0] B_column_count_limit;
    reg  [15:0] B_row_count;
    reg  [15:0] B_row_count_limit;
    reg  [15:0] row_count_limit;
    reg  [15:0] column_count_inc;
    reg  [15:0] column_count_dec;
    reg  [15:0] B_column_count_inc;
    reg  [15:0] B_column_count_dec;
    reg  [15:0] B_row_count_inc;
    reg  [15:0] B_row_count_dec;
    reg  [15:0] row_count_inc;
    reg  [15:0] row_count_dec;
    reg  [15:0] valid_count;
    reg  [15:0] valid_count_limit;
    reg  [15:0] valid_count_inc;
    reg  [15:0] valid_count_dec;
    reg  [15:0] A_column_count;
    reg  [15:0] B_column_count;
    reg  [15:0] B_column_count_limit_hit;
    reg  [15:0] B_row_count_limit_hit;
    reg  [15:0] row_count_limit_hit;
    reg  [15:0] column_count_limit_hit;
    reg  [15:0] valid_limit_hit;
    reg  [15:0] valid_count_limit_hit;
    reg  [15:0] A_column_count_limit_hit;
    reg  [15:0] B_row_count_limit_hit;
    reg  [15:0] row_count_limit_hit;
    reg  [15:0] column_count_limit_hit;
    reg  [15:0] valid_limit_hit;
    reg  [15:0] valid_count_limit_hit;
    reg  [15:0] A_column_count_limit_hit;
    reg  [15:0] B_row_count_limit_hit;
    reg  [15:0] row_count_limit_hit;
    reg  [15:0] column_count_limit_hit;
    reg  [15:0] valid_limit_hit;
    reg  [15:0] valid_count_limit_hit;
    reg  [15:0] A_column_count_limit_hit;
    reg  [15:0] B_row_count_limit_hit;
    reg  [15:0] row_count_limit_hit;
    reg  [15:0] column_count_limit_hit;
    reg  [15:0] valid_limit_hit;
    reg  [15:0] valid_count_limit_hit;
    reg  [15:0] A_column_count_limit_hit;
    reg  [15:0] B_row_count_limit_hit;
    reg  [15:0] row_count_limit_hit;
    reg  [15:0] column_count_limit_hit;
    reg  [15:0] valid_limit_hit;
    reg  [15:0] valid_count_limit_hit;
    reg  [15:0] A_column_count_limit_hit;
    reg  [15:0] B_row_count_limit_hit;
    reg  [15:0] row_count_limit_hit;
    reg  [15:0] column_count_limit_hit;
    reg  [15:0] valid_limit_hit;
    reg  [15:0] valid_count_limit_hit;
    reg  [15:0] A_column_count_limit_hit;
    reg  [15:0] B_row_count_limit_hit;
    reg  [15:0] row_count_limit_hit;
    reg  [15:0] column_count_limit_hit;
    reg  [15:0] valid_limit_hit;
    reg  [15:0] valid_count_limit_hit;
    reg  [15:0] A_column_count_limit_hit;
    reg  [15:0] B_row_count_limit_hit;
    reg  [15:0] row_count_limit_hit;
    reg  [15:0] column_count_limit_hit;
    reg  [15:0] valid_limit_hit;
    reg  [15:0] valid_count_limit_hit;
    reg  [15:0] A_column_count_limit_hit;
    reg  [15:0] B_row_count_limit_hit;
    reg  [15:0] row_count_limit_hit;
    reg  [15:0] column_count_limit_hit;
    reg  [15:0] valid_limit_hit;
    reg  [15:0] valid_count_limit_hit;
    reg  [15:0] A_column_count_limit_hit;
    reg  [15:0] B_row_count_limit_hit;
    reg  [15:0] row_count_limit_hit;
    reg  [15:0] column_count_limit_hit;
    reg  [15:0] valid_limit_hit;
    reg  [15:0] valid_count_limit_hit;
    reg  [15:0] A_column_count_limit_hit;
    reg  [15:0] B_row_count_limit_hit;
    reg  [15:0] row_count_limit_hit;
    reg  [15:0] column_count_limit_hit;
    reg  [15:0] valid_limit_hit;
    reg  [15:0] valid_count_limit_hit;
    reg  [15:0] A_column_count_limit_hit;
    reg  [15:0] B_row_count_limit_hit;
    reg  [15:0] row_count_limit_hit;
    reg  [15:0] column_count_limit_hit;
    reg  [15:0] valid_limit_hit;
    reg  [15:0] valid_count_limit_hit;
    reg  [15:0] A_column_count_limit_hit;
    reg  [15:0] B_row_count_limit_hit;
    reg  [15:0] row_count_limit_hit;
    reg  [15:0] column_count_limit_hit;
    reg  [15:0] valid_limit_hit;
    reg  [15:0] valid_count_limit_hit;
    reg  [15:0] A_column_count_limit_hit;

endmodule
