// 32-bit ALU. op: 0=ADD, 1=SUB, 2=AND, 3=OR. Combinational result and zero flag.
module cpu_alu (
    input  [31:0] a, b,
    input  [1:0]  op,
    output [31:0] result,
    output        zero
);
    reg [31:0] res;
    assign result = res;
    assign zero = (res == 0) ? 1 : 0;
    always @ (*) begin
        case (op)
            2'b00:  res = a + b;             // addition
            2'b01:  res = a - b;             // subtraction (A - B)
            2'b10:  {res[31:0], 1'b0} = a & b; // AND
            2'b11:  {res[31:0], 1'b0} = a | b; // OR
            default: res = 32'h0000_0000;
        endcase
    end
endmodule
`timescale 1ns/1ns

module cpu_tb ();
    reg  clk, reset;
    wire [31:0] iaddr, idata;
    wire [31:0] daddr, drdata, dwdata;
    wire [3:0] we;
    wire [31:0] x31, pc;
    reg [29:0] count;
    // Instantiate design under test
    // Dummy inputs
    assign iaddr = count;
    assign idata = 0;
    assign daddr = count;
    assign drdata = 0;
    assign dwdata = 0;
    assign we = 0;
    // Dummy outputs
    assign x31 = 0;
    assign pc = 0;
    // Set up clock
    always #5 clk = ~clk;
    // Set up reset
    initial begin
        reset = 1;
        #
endmodule
