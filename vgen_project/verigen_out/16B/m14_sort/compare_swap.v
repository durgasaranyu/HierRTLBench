// Compare-and-swap: outputs larger value to hi port, smaller to lo. Combinational.
module compare_swap (
    input  [7:0] a, b,
    output [7:0] hi, lo
);
    assign hi = (a > b)? a : b;
    assign lo = (a > b)? b : a;

endmodule
