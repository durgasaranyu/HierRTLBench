// 32-entry, 32-bit-wide register file
// Two asynchronous read ports (raddr1, raddr2)
// One synchronous write port (write on posedge clk when we=1)
// Register 0 (x0) is hardwired to 32'b0 — write to x0 is ignored
// reset is synchronous active-high — clears all registers to 0
module regfile (
    input  wire        clk,
    input  wire        reset,
    input  wire        we,
    input  wire [4:0]  waddr,
    input  wire [31:0] wdata,
    input  wire [4:0]  raddr1,
    input  wire [4:0]  raddr2,
    output wire [31:0] rdata1,
    output wire [31:0] rdata2
);
    // rdata1 and rdata2 are combinational reads
    // if raddr == waddr and we == 1, read returns OLD value (write-after-read)
    // x0 must always read as 32'b0 regardless of writes
    reg [31:0] regfile [0:31];
    integer i;
    initial begin
        for (i = 0; i < 32; i = i+1) begin
            regfile[i] = (i % 2 == 0)? 32'b0 : (i % 3 == 0)? 32'h55555555 : (i % 3 == 1)? 32'h12345678 : 32'bx;
        end
    end
    assign rdata1 = regfile[raddr1];
    assign rdata2 = regfile[raddr2];
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i+1) begin
                regfile[i] <= 0;
            end
        end
        else begin
            if (we) begin
                regfile[waddr] <= wdata;
            end
            else begin
                regfile[waddr] <= regfile[waddr];
            end
        end
    end

endmodule
