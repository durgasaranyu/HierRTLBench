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
    reg [31:0] a, b, c, d, e, f, g, h, W[0][31:0], K[0][31:0];
    reg [4:0]  rounds;
    reg [31:0] block_512[0:31];  // initial block
    reg [31:0] block_512_new[0:31];
    reg [31:0] block_512_1, block_512_2, block_512_3, block_512_4, block_512_5, block_512_6, block_512_7, block_512_8, block_512_9, block_512_10, block_512_11, block_512_12, block_512_13, block_512_14, block_512_15, block_512_16, block_512_17, block_512_18, block_512_19, block_512_20, block_512_21, block_512_22, block_512_23, block_512_24, block_512_25, block_512_26, block_512_27, block_512_28, block_512_29, block_512_30, block_512_31;
    reg [31:0] block_512_new_1, block_512_new_2, block_512_new_3, block_512_new_4, block_512_new_5, block_512_new_6, block_512_new_7, block_512_new_8, block_512_new_9, block_512_new_10, block_512_new_11, block_512_new_12, block_512_new_13, block_512_new_14, block_512_new_15, block_512_new_16, block_512_new_17, block_512_new_18, block_512_new_19, block_512_new_20, block_512_new_21, block_512_new_22, block_512_new_23, block_512_new_24, block_512_new_25, block_512_new_26, block_512_new_27, block_512_new_28, block_512_new_29, block_512_new_30, block_512_new_31;
    reg [31:0] block_512_1_new, block_512_2_new, block_512_3_new, block_512_4_new, block_512_5_new, block_512_6_new, block_512_7_new, block_512_8_new, block_512_9_new, block_512_10_new, block_512_11_new, block_512_12_new, block_512_13_new, block_512_14_new, block_512_15_new, block_512_16_new, block_512_17_new, block_512_18_new, block_512_19_new, block_512_20_new, block_512_21_new, block_512_22_new, block_512_23_new, block_512_24_new, block_512_25_new, block_512_26_new, block_512_27_new, block_512_28_new, block_512_29_new, block_512_30_new, block_512_31_new;
    reg [31:0] block_512_1_old, block_512_2_old, block_512_3_old, block_512_4_old, block_512_5_old, block_512_6_old, block_512_7_old, block_512_8_old, block_512_9_old, block_512_10_old, block_512_11_old, block_512_12_old, block_512_13_old, block_512_14_old, block_512_15_old, block_512_16_old, block_512_17_old, block_512_18_old, block_512_19_old, block_512_20_old, block_512_21_old, block_512_22_old, block_512_23_old, block_512_24_old, block_512_25_old, block_512_26_old, block_512_27_old, block_512_28_old, block_512_29_old, block_512_30_old, block_512_31_old;
    reg [31:0] block_512_1_new_1, block_512_2_new_1, block_512_3_new_1, block_512_4_new_1, block_512_5_new_1, block_512_6_new_1, block_512_7_new_1, block_512_8_new_1, block_512_9_new_1, block_512_10_new_1, block_512_11_new_1, block_512_12_new_1, block_512_13_new_1, block_512_14_new_1, block_512_15_new_1, block_512_16_new_1, block_512_17_new_1, block_512_18_new_1, block_512_19_new_1, block_512_20_new_1, block_512_21_new_1, block_512_22_new_1, block_512_23_new_1, block_512_24_new_1, block_512_25_new_1, block_512_26_new_1, block_512_27_new_1, block_512_28_new_1, block_512_29_new_1, block_512_30_new_1, block_512_31_new_1;
    reg [31:0] block_512_1_new_2, block_512_2_new_2, block_512_3_new_2, block_512_4_new_2, block_512_5_new_2, block_512_6_new_2, block_512_7_new_2, block_512_8_new_2, block_512_9_new_2, block_512_10_new_2, block_512_11_new_2, block_512_12_new_2, block_512_13_new_2, block_512_14_new_2, block_512_15_new_2, block_512_16_new_2, block_512_17_new_2, block
endmodule
