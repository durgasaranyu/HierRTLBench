// N-bit logical shift-left by 1. carry_out = a[N-1], result = a << 1.
module alu_shift #(parameter N = 8) (
    input  [N-1:0] a,
    output [N-1:0] result,
    output         carry_out
);
    assign carry_out = a[N-1];
    assign result = a << 1;

endmodule
