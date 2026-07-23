// Multiply-accumulate unit. 16-bit unsigned a,b. 32-bit accumulation.
// clear resets acc. en enables accumulation of a*b.
module mac_unit (
    input         clk, rst, clear, en,
    input  [15:0] a, b,
    output reg [31:0] acc
);
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            acc <= 0;
        end
        else if (clear) begin
            acc <= 0;
        end
        else if (en) begin
            acc <= acc + a * b;
        end
    end

endmodule
