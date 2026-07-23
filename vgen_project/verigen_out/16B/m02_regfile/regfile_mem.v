// 32x32 register array. Synchronous reset zeroes all registers. x0 always reads 0.
module regfile_mem (
    input         clk, rst,
    input  [4:0]  rs1, rs2, rd,
    input  [31:0] wdata,
    input         we,
    output [31:0] rdata1, rdata2
);
    reg [31:0] regs [0:31];
    assign rdata1 = regs[rs1];
    assign rdata2 = regs[rs2];
    always @(posedge clk) begin
        if (we) begin
            regs[rd] <= wdata;
        end
    end

endmodule
