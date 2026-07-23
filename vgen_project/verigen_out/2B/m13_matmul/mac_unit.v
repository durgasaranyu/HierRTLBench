// Multiply-accumulate unit. 16-bit unsigned a,b. 32-bit accumulation.
// clear resets acc. en enables accumulation of a*b.
module mac_unit (
    input         clk, rst, clear, en,
    input  [15:0] a, b,
    output reg [31:0] acc
);
    reg [15:0] a_reg;
    reg [15:0] b_reg;
    reg [15:0] acc_reg;
    reg [31:0] acc_temp;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            acc_reg <= 0;
            acc_temp <= 0;
        end else begin
            if (clear) begin
                acc_reg <= 0;
                acc_temp <= 0;
            end else if (en) begin
                acc_reg <= acc_temp;
                acc_temp <= a_reg * b_reg;
            end
        end
    end
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            a_reg <= 0;
            b_reg <= 0;
        end else begin
            if (clear) begin
                a_reg <= 0;
                b_reg <= 0;
            end else begin
                a_reg <= a;
                b_reg <= b;
            end
        end
    end
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            acc <= 0;
        end else begin
            if (clear) begin
                acc <= 0;
            end else begin
                acc <= acc_reg;
            end
        end
    end

endmodule
