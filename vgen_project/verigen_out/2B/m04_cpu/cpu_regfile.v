// RISC CPU register file. 32x32-bit. Async read rs1,rs2. Sync write on we. x0=0.
module cpu_regfile (
    input        clk,
    input [4:0]  rs1, rs2, rd,
    input [31:0] wdata,
    input        we,
    output [31:0] rdata1, rdata2
);
    reg [31:0] regs [31:0];
    always @(posedge clk) begin
        if (we) regs[rd] <= wdata;
        rdata1 <= regs[rs1];
        rdata2 <= regs[rs2];
    end

endmodule
