// RISC-V MEM stage. 256x32 data memory. Sync write on mem_write. Async read.
module rv_mem_stage (
    input        clk,
    input [31:0] alu_result, rs2_data,
    input        mem_write, mem_read,
    output [31:0] read_data
);
    reg [31:0] mem [0:255];
    assign read_data = mem[alu_result];
    always @(posedge clk) begin
        if (mem_write) mem[alu_result] <= rs2_data;
    end

endmodule
