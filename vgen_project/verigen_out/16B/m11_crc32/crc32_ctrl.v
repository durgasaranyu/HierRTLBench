// CRC-32 controller. Init LFSR to 0xFFFFFFFF on start. Final XOR 0xFFFFFFFF on done.
module crc32_ctrl (
    input         clk, rst, start, done_in,
    input  [31:0] crc_raw,
    output reg    init,
    output [31:0] crc_out
);
reg [31:0] crc_reg;
reg [31:0] crc_out;
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        crc_reg <= 32'hFFFFFFFF;
        init <= 1'b1;
    end else begin
        if (init) begin
            crc_reg <= crc_raw;
            init <= 1'b0;
        end else if (start) begin
            crc_reg <= crc_reg << 1;
            crc_reg[0] <= crc_reg[31];
        end else if (done_in) begin
            crc_out <= crc_reg;
        end
    end
end

endmodule
