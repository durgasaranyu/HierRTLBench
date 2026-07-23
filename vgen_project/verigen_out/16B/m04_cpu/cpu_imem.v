// Instruction memory: 256x32-bit words, initialized to 0. Async read by addr[9:2].
module cpu_imem (
    input  [31:0] addr,
    output [31:0] instr
);
    reg [31:0] mem [0:255];
    always @(*) begin
        instr = mem[addr[9:2]];
    end

endmodule
