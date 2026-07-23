// RISC CPU register file. 32x32-bit. Async read rs1,rs2. Sync write on we. x0=0.
module cpu_regfile (
    input        clk,
    input [4:0]  rs1, rs2, rd,
    input [31:0] wdata,
    input        we,
    output [31:0] rdata1, rdata2
);
    reg [31:0] regfile [31:0];
    assign rdata1 = regfile[rs1];
    assign rdata2 = regfile[rs2];
    always @ (posedge clk) begin
        if (we) regfile[rd] <= wdata;
    end

endmodule
