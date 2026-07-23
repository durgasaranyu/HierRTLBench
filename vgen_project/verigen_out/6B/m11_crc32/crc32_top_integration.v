`timescale 1ns/1ps
// M11: CRC-32 IEEE 802.3 integration top (bit-serial)
// done_in to ctrl: falling edge of valid (end of data stream).
module crc32_integration (
    input         clk, rst, start, data_in, valid,
    output [31:0] crc_out,
    output        ready
);
    wire init;
    wire [31:0] crc_reg;

    crc32_lfsr u_lfsr (
        .clk(clk), .rst(rst),
        .init(init), .data_in(data_in), .valid(valid),
        .crc_reg(crc_reg)
    );

    // Detect falling edge of valid → pulse done_in
    reg valid_d;
    always @(posedge clk) valid_d <= rst ? 1'b0 : valid;
    wire done_in = valid_d & ~valid;

    crc32_ctrl u_ctrl (
        .clk(clk), .rst(rst),
        .start(start), .done_in(done_in),
        .crc_raw(crc_reg),
        .init(init), .crc_out(crc_out)
    );

    // ready: asserts one cycle after done_in
    reg ready_r;
    always @(posedge clk) ready_r <= rst ? 1'b0 : done_in;
    assign ready = ready_r;
endmodule
