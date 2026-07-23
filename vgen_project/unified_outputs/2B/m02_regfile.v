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
    // if we=0, read returns NEW value (write-before-read)
    // if reset, all registers are set to 0
    reg [31:0] registers [31:0];
    // synchronous read
    // if we=1, read returns NEW value (write-before-read)
    // if reset, all registers are set to 0
    // if we=0, read returns OLD value (write-after-read)
    // if reset, all registers are set to 0
    always @(posedge clk)
        if (reset)
            registers[0] <= 32'b0;
        else if (we && (raddr1 == waddr))
            registers[0] <= wdata;
        else if (we && (raddr2 == waddr))
            registers[1] <= wdata;
    // asynchronous write
    // if we=1, write returns NEW value (write-after-write)
    // if reset, all registers are set to 0
    always @(posedge clk)
        if (reset)
            registers[0] <= 32'b0;
        else if (we && (raddr1 == waddr))
            registers[0] <= wdata;
    // read
    // if we=1, read returns NEW value (write-after-read)
    // if reset, all registers are set to 0
    always @(posedge clk)
        if (reset)
            registers[1] <= 32'b0;
        else if (we && (raddr2 == waddr))
            registers[1] <= wdata;
    // output
    // if we=1, read returns NEW value (write-after-read)
    // if reset, all registers are set to 0
    assign rdata1 = (raddr1 == 5'b0)? 32'b0 : registers[raddr1];
    assign rdata2 = (raddr2 == 5'b0)? 32'b0 : registers[raddr2];

endmodule
