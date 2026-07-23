// 32-entry register file. Dual async read ports, single sync write. x0 hardwired 0.
module regfile (
    input         clk, rst,
    input  [4:0]  rs1, rs2, rd,
    input  [31:0] wdata,
    input         we,
    output [31:0] rdata1, rdata2
);
    reg [31:0] regfile [31:0];
    integer i;
    initial begin
        for (i=0; i<32; i=i+1) begin
            regfile[i] = (i % 2 == 0) ? 0 : 32'hdeadbeef;
        end
    end
    always @(posedge clk) begin
        if (rst) begin
            for (i=0; i<32; i=i+1) begin
                regfile[i] <= 0;
            end
        end
        else begin
            if (we)
                regfile[rd] <= wdata;
            else
                rdata1 <= regfile[rs1];
            rdata2 <= regfile[rs2];
        end
    end
endmodule
`timescale 1ns/1ps

module tb_reg32;
    reg clk, rst;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] wdata;
    reg we;
    wire [31:0] rdata1, rdata2;
    reg_32 reg32(clk, rst, rs1, rs2, rd, wdata, we, rdata1, rdata2);
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
        $monitor("clk=%b, rst=%b, rs1=%b, rs2=%b, rd=%b, wdata=%b, we=%b, rdata1=%b, rdata2=%b", clk, rst, rs1, rs2, rd, wdata, we, rdata1, rdata2);
        clk = 0;
        rst = 0;
        rs1 = 5'b00001;
        rs2 = 5'b00010;
        rd = 5'b00011;
        wdata = 32'h12345678;
        we = 1;
        #
endmodule
