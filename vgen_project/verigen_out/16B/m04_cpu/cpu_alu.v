// 32-bit ALU. op: 0=ADD, 1=SUB, 2=AND, 3=OR. Combinational result and zero flag.
module cpu_alu (
    input  [31:0] a, b,
    input  [1:0]  op,
    output [31:0] result,
    output        zero
);
    reg [31:0] result;
    always @(a, b, op) begin
        case (op)
            2'b00: result <= a + b;
            2'b01: result <= a - b;
            2'b10: result <= a & b;
            2'b11: result <= a | b;
        endcase
        zero <= result == 0;
    end

endmodule
