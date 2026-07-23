// GF(2^8) helpers: xtime=a*2 mod x^8+x^4+x^3+x+1. x3_a = xtime(a) XOR a.
module aes_gf_mul (
    input  [7:0] a,
    output [7:0] xtime_a, x3_a
);
    assign xtime_a = {a[6:0], a[7] ^ a[0]};
    assign x3_a = xtime_a ^ {xtime_a[6:0], xtime_a[7]};

endmodule
