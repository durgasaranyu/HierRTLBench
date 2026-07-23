// Dot product of a 16-element row vector with a 16-element column vector.
// 16-bit unsigned elements. 32-bit accumulator. Takes 16 cycles after start.
module mat_row (
    input         clk, rst, start,
    input  [255:0] row_a_flat,
    input  [255:0] col_b_flat,
    output [31:0]  result,
    output         done
);
    reg [15:0]    row_a [0:15];
    reg [15:0]    col_b [0:15];
    reg [31:0]    result_sum;
    reg [15:0]    temp;
    reg           done_sum;
    integer       i;
    // Unflatten input vectors.
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            row_a[i] = row_a_flat[16*i+:16];
            col_b[i] = col_b_flat[16*i+:16];
        end
    end
    // Main calculation.
    always @(posedge clk) begin
        if (rst) begin
            result_sum <= 0;
            done_sum <= 1'b1;
        end else begin
            if (start) begin
                result_sum <= 0;
                done_sum <= 1'b0;
                for (i = 0; i < 16; i = i + 1) begin
                    temp = row_a[i] * col_b[i];
                    result_sum <= result_sum + temp;
                end
                done_sum <= 1'b1;
            end else begin
                done_sum <= 1'b0;
            end
        end
    end
    assign result = result_sum;
    assign done = done_sum;

endmodule
