// N-bit bitwise logic. sel=0 AND, sel=1 OR, sel=2 XOR.
module alu_logic #(parameter N = 8) (
    input  [N-1:0] a, b,
    input  [1:0]   sel,
    output [N-1:0] result
);
    // sel=0 AND, sel=1 OR, sel=2 XOR
    // result = sel0? (sel1? a : b) : (sel1? b : a)
    assign result = {sel == 2'b00? a : b, sel == 2'b01? a : b};

endmodule
