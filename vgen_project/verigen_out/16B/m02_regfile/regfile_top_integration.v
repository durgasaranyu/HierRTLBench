`timescale 1ns/1ps
// M02: 32-entry register file integration top
// Wraps regfile_mem. Dual async read, single sync write. x0 hardwired 0.
module regfile_integration (
    input         clk, rst,
    input  [4:0]  rs1, rs2, rd,
    input  [31:0] wdata,
    input         we,
    output [31:0] rdata1, rdata2
);
    regfile_mem u_mem (
        .clk(clk), .rst(rst),
        .rs1(rs1), .rs2(rs2), .rd(rd),
        .wdata(wdata), .we(we),
        .rdata1(rdata1), .rdata2(rdata2)
    );
endmodule
