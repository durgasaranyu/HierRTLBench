// 32x32 register array. Synchronous reset zeroes all registers. x0 always reads 0.
module regfile_mem (
    input         clk, rst,
    input  [4:0]  rs1, rs2, rd,
    input  [31:0] wdata,
    input         we,
    output [31:0] rdata1, rdata2
);
    reg [31:0] regs [0:31];
    always @(posedge clk)
        if (rst)
            regs[0] <= 32'b0;
        else if (we)
            regs[rd] <= wdata;
    assign rdata1 = regs[rs1];
    assign rdata2 = regs[rs2];

endmodule
