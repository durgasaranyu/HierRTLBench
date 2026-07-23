// 16x16 matrix multiplier top. 16-bit unsigned inputs A,B. 32-bit output C=A*B.
// Pipelined: computes one row of C per 16 cycles. done when all 16 rows complete.
module matrix_mult (
    input         clk, rst, start,
    input  [4095:0] A_flat, B_flat,
    output [8191:0] C_flat,
    output          done
);
    reg [15:0] A [0:15];
    reg [15:0] B [0:15];
    reg [31:0] C [0:15];
    reg [15:0] temp;
    integer i, j, k;
    reg [15:0] A_temp;
    reg [15:0] B_temp;
    reg [31:0] C_temp;
    reg [15:0] sum;
    reg [15:0] C_temp_in;
    reg done_row;
    assign C_temp_in = C_temp;
    always @(posedge clk) begin
        if (rst) begin
            i <= 0;
            j <= 0;
            k <= 0;
            A[0] <= 0;
            B[0] <= 0;
            C[0] <= 0;
        end
        else begin
            if (start) begin
                // Load A and B
                A[0] <= A_temp;
                B[0] <= B_temp;
                C_temp <= 0;
                i <= 1;
                j <= 1;
                k <= 1;
            end
            else if (i < 16) begin
                if (j < 16) begin
                    // Compute next value of C
                    C_temp[31:16] <= sum;
                    if (k == 1) begin
                        // If we are on the last iteration, store the result
                        C[i] <= C_temp;
                        j <= j + 1;
                        k <= 0;
                    end
                    else begin
                        k <= k + 1;
                        sum <= add(A[i], B[j], C_temp[15:0]);
                        // If we are more than one away from the last iteration,
                        // store the intermediate result
                        if (k > 1) begin
                            C_temp[15:0] <= sum;
                        end
                    end
                end
                else begin
                    j <= 0;
                    k <= 0;
                    // Load the next row of the matrix
                    if (i == 1) begin
                        A_temp <= A_flat;
                        B_temp <= B_flat;
                    end
                    else begin
                        A_temp <= A[i - 1];
                        B_temp <= B[i - 1];
                    end
                    i <= i + 1;
                    C_temp[31:16] <= 0;
                end
            end
        end
    end
    assign C_flat = C;
    assign done = (i == 16)? 1 : 0;

endmodule
