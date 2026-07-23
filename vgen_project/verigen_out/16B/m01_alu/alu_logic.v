// N-bit bitwise logic. sel=0 AND, sel=1 OR, sel=2 XOR.
module alu_logic #(parameter N = 8) (
    input  [N-1:0] a, b,
    input  [1:0]   sel,
    output [N-1:0] result
);
    assign result = sel[1]? ( sel[0]? b : a ) : ( sel[0]? a : b );

endmodule
