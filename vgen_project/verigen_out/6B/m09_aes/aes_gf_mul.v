// GF(2^8) helpers: xtime=a*2 mod x^8+x^4+x^3+x+1. x3_a = xtime(a) XOR a.
module aes_gf_mul (
    input  [7:0] a,
    output [7:0] xtime_a, x3_a
);
    assign xtime_a = a ^ aes_xtime;
    assign x3_a = xtime(a) ^ a;
endmodule

// GF(2^8) multiplier: xtime=a*2 mod x^8+x^4+x^3+x+1. x3_a = xtime(a) XOR a.
module aes_gf_mul_8 (
    input  [7:0] a,
    output [7:0] xtime_8, x3_8
);
    assign xtime_8 = a ^ aes_xtime;
    assign x3_8 = xtime(a) ^ a;
endmodule

// GF(2^8) multiplier: xtime=a*2 mod x^8+x^4+x^3+x+1. x3_8 = xtime(a) XOR a.
module aes_gf_mul_9 (
    input  [7:0] a,
    output [7:0] xtime_9, x3_9
);
    assign xtime_9 = a ^ aes_xtime;
    assign x3_9 = xtime(a) ^ a;
endmodule

// GF(2^8) multiplier: xtime=a*2 mod x^8+x^4+x^3+x+1. x3_9 = xtime(a) XOR a.
module aes_gf_mul_b (
    input  [7:0] a,
    output [7:0] xtime_b, x3_b
);
    assign xtime_b = a ^ aes_xtime;
    assign x3_b = xtime(a) ^ a;
endmodule

// GF(2^8) multiplier: xtime=a*2 mod x^8+x^4+x^3+x+1. x3_b = xtime(a) XOR a.
module aes_gf_mul_c (
    input  [7:0] a,
    output [7:0] xtime_c, x3_c
);
    assign xtime_c = a ^ aes_xtime;
    assign x3_c = xtime(a) ^ a;
endmodule

// GF(2^8) multiplier: xtime=a*2 mod x^8+x^4+x^3+x+1. x3_c = xtime(a) XOR a.
module aes_gf_mul_d (
    input  [7:0] a,
    output [7:0] xtime_d, x3_d
);
    assign xtime_d = a ^ aes_xtime;
    assign x3_d = xtime(a) ^ a;
endmodule

// GF(2^8) multiplier: xtime=a*2 mod x^8+x^4+x^3+x+1. x3_d = xtime(a) XOR a.
module aes_gf_mul_e (
    input  [7:0] a,
    output [7:0] xtime_e, x3_e
);
    assign xtime_e = a ^ aes_xtime;
    assign x3_e = xtime(a) ^ a;
endmodule

// GF(2^8) multiplier: xtime=a*2 mod x^8+x^4+x^3+x+1. x3_e = xtime(a) XOR a.
module aes_gf_mul_f (
    input  [7:0] a,
    output [7:0] xtime_f, x3_f
);
    assign xtime_f = a ^ aes_xtime;
    assign x3_f = xtime(a) ^ a;
endmodule

// GF(2^8) multiplier: xtime=a*2 mod x^8+x^4+x^3+x+1. x3_f = xtime(a) XOR a.
module aes_gf_mul_8 (
    input  [7:0] a,
    output [7:0] xtime_8, x3_8
);
    assign xtime_8 = a ^ aes_xtime;
    assign x3_8 = xtime(a) ^ a;
endmodule

// GF(2^8) multiplier: xtime=a*2 mod x^8+x^4+x^3+x+1. x3_8 = xtime(a) XOR a.
module aes_gf_mul_9 (
    input  [7:0] a,
    output [7:0] xtime_9, x3_9
);
    assign xtime_9 = a ^ aes_xtime;
    assign x3_9 = xtime(a) ^ a;
endmodule

// GF(2^8) multiplier: xtime=a*2 mod x^8+x^4+x^3+x+1. x3_9 = xtime(a) XOR a.
module aes_mul_8 (
    input  [127:0] a,
    output [127:0] x3
);
    wire [7:0] xtime_8;
    wire [7:0] x3_8;
    aes_gf_mul_8 step1(.a(a[127:96]), .x3(xtime_8));
    assign x3_8 = xtime_8 ^ a[95:64];
    assign x3 = {x3_8, a[127:96]};
endmodule

// GF(2^8) multiplier: xtime=a*2 mod x^8+x^4+x^3+x+1. x3_9 = xtime(a) XOR a.
module aes_mul_9 (
    input  [127:0] a,
    output [127:0] x3
);
    wire [7:0] xtime_9;
    wire [7:0] x3_9;
    aes_gf_mul_9 step1(.a(a[127:96]), .x3(xtime_9));
    assign x3_9 = xtime_9 ^ a[95:64];
    assign x3 = {x3_9, a[127:96]};
endmodule

// GF(2^8) multiplier: xtime=a*2 mod x^8+x^4+x^3+x+1. x3_9 = xtime(a) XOR a.
module aes_mul_b (
    input  [7:0] a,
    output [7:0] x3
);
    wire [7:0] xtime_b;
    wire [7:0] x3_b;
    aes_gf_mul_b step1(.a(a), .x3(xtime_b));
    assign x3_b = xtime_b ^ a;
    assign x3 = {x3_b[7:0], a[7:0]};
endmodule

// GF(2^8) multiplier: xtime=a*2 mod x^8+x^4+x^3+x+1. x3_9 = xtime(a) XOR a.
module aes_mul_c (
    input  [7:0] a,
    output [7:0] x3
);
    wire [7:0] xtime_c;
    wire [7:0] x3_c;
    aes_gf_mul_c step1(.a(a), .x3(xtime_c));
    assign x3_c = xtime_c ^ a;
    assign x3 = {x
endmodule
