// RISC-V MEM stage. 256x32 data memory. Sync write on mem_write. Async read.
module rv_mem_stage (
    input        clk,
    input [31:0] alu_result, rs2_data,
    input        mem_write, mem_read,
    output [31:0] read_data
);
    reg [31:0] mem [255:0];
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            mem[i] = 0;
        end
    end
    always @(posedge clk) begin
        if (mem_write) begin
            mem[rs2_data] <= alu_result;
        end
    end
    assign read_data = mem[rs2_data];

endmodule
