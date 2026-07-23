// 32-entry register file. Dual async read ports, single sync write. x0 hardwired 0.
module regfile (
    input         clk, rst,
    input  [4:0]  rs1, rs2, rd,
    input  [31:0] wdata,
    input         we,
    output [31:0] rdata1, rdata2
);
    reg [31:0] regs [31:0];
    always @(posedge clk)
        if (rst)
            regs[0] <= 32'h0;
        else if (we)
            regs[rd] <= wdata;
    assign rdata1 = regs[rs1];
    assign rdata2 = regs[rs2];

endmodule
