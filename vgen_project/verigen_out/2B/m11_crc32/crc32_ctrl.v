// CRC-32 controller. Init LFSR to 0xFFFFFFFF on start. Final XOR 0xFFFFFFFF on done.
module crc32_ctrl (
    input         clk, rst, start, done_in,
    input  [31:0] crc_raw,
    output reg    init,
    output [31:0] crc_out
);
    reg [31:0] crc_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc_reg <= 32'hFFFFFFFF;
            init   <= 1'b1;
        end else begin
            if (start) begin
                crc_reg <= 32'hFFFFFFFF;
                init   <= 1'b1;
            end else if (done_in) begin
                crc_reg <= crc_raw;
                init   <= 1'b0;
            end
        end
    end
    assign crc_out = crc_reg;

endmodule
