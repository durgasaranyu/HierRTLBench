// SHA-256 hash core
// Message schedule: W[0..15] from input block; W[i] = sigma1(W[i-2]) + W[i-7]
//                   + sigma0(W[i-15]) + W[i-16]  for i=16..63
// sigma0(x) = ROTR(x,7)  XOR ROTR(x,18) XOR SHR(x,3)
// sigma1(x) = ROTR(x,17) XOR ROTR(x,19) XOR SHR(x,10)
// Compression: 64 rounds using working vars a,b,c,d,e,f,g,h
// T1 = h + Sigma1(e) + Ch(e,f,g) + K[i] + W[i]
// T2 = Sigma0(a) + Maj(a,b,c)
// Sigma0(x)=ROTR(x,2)^ROTR(x,13)^ROTR(x,22)
// Sigma1(x)=ROTR(x,6)^ROTR(x,11)^ROTR(x,25)
// Ch(e,f,g)=(e&f)^(~e&g)   Maj(a,b,c)=(a&b)^(a&c)^(b&c)
// Initial hash values H0..H7 (first 32 bits of fractional parts of sqrt of primes)
// K constants: first 32 bits of fractional parts of cube roots of first 64 primes
// All additions are mod 2^32
module sha256 (
    input  wire          clk,
    input  wire          reset,
    input  wire          start,
    input  wire [511:0]  block_in,   // one 512-bit message block
    output reg  [255:0]  hash_out,
    output reg           done
);
    // Registers: W[63:0][31:0], K[63:0][31:0] (ROM), a..h, round counter
    reg [31:0]  W_0 [63:0];
    reg [31:0]  W_1 [63:0];
    reg [31:0]  W_2 [63:0];
    reg [31:0]  W_3 [63:0];
    reg [31:0]  W_4 [63:0];
    reg [31:0]  W_5 [63:0];
    reg [31:0]  W_6 [63:0];
    reg [31:0]  W_7 [63:0];
    reg [31:0]  W_8 [63:0];
    reg [31:0]  W_9 [63:0];
    reg [31:0]  W_10 [63:0];
    reg [31:0]  W_11 [63:0];
    reg [31:0]  W_12 [63:0];
    reg [31:0]  W_13 [63:0];
    reg [31:0]  W_14 [63:0];
    reg [31:0]  W_15 [63:0];
    reg [31:0]  W_16 [63:0];
    reg [31:0]  W_17 [63:0];
    reg [31:0]  W_18 [63:0];
    reg [31:0]  W_19 [63:0];
    reg [31:0]  W_20 [63:0];
    reg [31:0]  W_21 [63:0];
    reg [31:0]  W_22 [63:0];
    reg [31:0]  W_23 [63:0];
    reg [31:0]  W_24 [63:0];
    reg [31:0]  W_25 [63:0];
    reg [31:0]  W_26 [63:0];
    reg [31:0]  W_27 [63:0];
    reg [31:0]  W_28 [63:0];
    reg [31:0]  W_29 [63:0];
    reg [31:0]  W_30 [63:0];
    reg [31:0]  W_31 [63:0];
    reg [31:0]  W_32 [63:0];
    reg [31:0]  W_33 [63:0];
    reg [31:0]  W_34 [63:0];
    reg [31:0]  W_35 [63:0];
    reg [31:0]  W_36 [63:0];
    reg [31:0]  W_37 [63:0];
    reg [31:0]  W_38 [63:0];
    reg [31:0]  W_39 [63:0];
    reg [31:0]  W_40 [63:0];
    reg [31:0]  W_41 [63:0];
    reg [31:0]  W_42 [63:0];
    reg [31:0]  W_43 [63:0];
    reg [31:0]  W_44 [63:0];
    reg [31:0]  W_45 [63:0];
    reg [31:0]  W_46 [63:0];
    reg [31:0]  W_47 [63:0];
    reg [31:0]  W_48 [63:0];
    reg [31:0]  W_49 [63:0];
    reg [31:0]  W_50 [63:0];
    reg [31:0]  W_51 [63:0];
    reg [31:0]  W_52 [63:0];
    reg [31:0]  W_53 [63:0];
    reg [31:0]  W_54 [63:0];
    reg [31:0]  W_55 [63:0];
    reg [31:0]  W_56 [63:0];
    reg [31:0]  W_57 [63:0];
    reg [31:0]  W_58 [63:0];
    reg [31:0]  W_59 [63:0];
    reg [31:0]  W_60 [63:0];
    reg [31:0]  W_61 [63:0];
    reg [31:0]  W_62 [63:0];
    reg [31:0]  W_63 [63:0];
    reg [31:0]  W_64 [63:0];
    reg [31:0]  W_65 [63:0];
    reg [31:0]  W_66 [63:0];
    reg [31:0]  W_67 [63:0];
    reg [31:0]  W_68 [63:0];
    reg [31:0]  W_69 [63:0];
    reg [31:0]  W_70 [63:0];
    reg [31:0]  W_71 [63:0];
    reg [31:0]  W_72 [63:0];
    reg [31:0]  W_73 [63:0];
    reg [31:0]  W_74 [63:0];
    reg [31:0]  W_75 [63:0];
    reg [31:0]  W_76 [63:0];
    reg [31:0]  W_77 [63:0];
    reg [31:0]  W_78 [63:0];
    reg [31:0]  W_79 [63:0];
    reg [31:0]  W_80 [63:0];
    reg [31:0]  W_81 [63:0];
    reg [31:0]  W_82 [63:0];
    reg [31:0]  W_83 [63:0];
    reg [31:0]  W_84 [63:0];
    reg [31:0]  W_85 [63:0];
    reg [31:0]  W_86 [63:0];
    reg [31:0]  W_87 [63:0];
    reg [31:0]  W_88 [63:0];
    reg [31:0]  W_89 [63:0];
    reg [31:0]  W_90 [63:0];
    
endmodule
