// Parameterized N-bit adder-subtractor. op=0: result=a+b carry_out. op=1: result=a-b borrow.
module alu_addsub #(parameter N = 8) (
    input  [N-1:0] a, b,
    input          op,
    output [N-1:0] result,
    output         carry_out
);
    assign carry_in = 1'b0;
    assign {carry_out, result} = (op == 0)? a + b : a - b;

endmodule
