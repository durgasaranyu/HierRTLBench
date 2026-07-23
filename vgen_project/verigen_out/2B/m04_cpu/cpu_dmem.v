// Data memory: 256x32-bit words. Synchronous write on mem_we. Asynchronous read.
module cpu_dmem (
    input        clk,
    input [31:0] addr, wdata,
    input        mem_we,
    output [31:0] rdata
);
    reg [31:0] dmem [0:255];
    always @(posedge clk)
        if (mem_we)
            dmem[addr[11:2]] <= wdata;
    assign rdata = dmem[addr[11:2]];

endmodule
