// Data memory: 256x32-bit words. Synchronous write on mem_we. Asynchronous read.
module cpu_dmem (
    input        clk,
    input [31:0] addr, wdata,
    input        mem_we,
    output [31:0] rdata
);
    reg [31:0] dmem [255:0];
    initial $readmemh ( "dmem_ini.mem", dmem );
    always @(posedge clk) begin
        // Write
        if (mem_we)
            dmem[addr[31:2]] <= wdata;
    end
    assign rdata = dmem[addr[31:2]];

endmodule
