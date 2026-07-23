// SHA-256 Sigma/Ch/Maj functions. All 32-bit. Used in message schedule and compression.
// SIGMA0=ROTR2^ROTR13^ROTR22, SIGMA1=ROTR6^ROTR11^ROTR25.
// sigma0=ROTR7^ROTR18^SHR3, sigma1=ROTR17^ROTR19^SHR10.
module sha256_sigma (
    input  [31:0] a, b, c,
    output [31:0] SIGMA0_a, SIGMA1_a, sigma0_b, sigma1_b, Ch_abc, Maj_abc
);
    // sigma0=ROTR7^ROTR18^SHR3, sigma1=ROTR17^ROTR19^SHR10.
    assign SIGMA0_a = {a[30:0], b[30:0], a[31] ^ b[31], a[31] ^ b[31]};
    assign SIGMA1_a = {a[29:0], b[29:0], a[31] ^ b[31], a[31] ^ b[31]};
    assign sigma0_b = {b[30:0], c[30:0], b[31] ^ c[31], b[31] ^ c[31]};
    assign sigma1_b = {b[29:0], c[29:0], b[31] ^ c[31], b[31] ^ c[31]};
    assign Ch_abc = {c[30:0], a[30:0], c[31] ^ a[31], c[31] ^ a[31]};
    assign Maj_abc = {a[30:0], b[30:0], a[31] ^ b[31], a[31] ^ b[31]};

endmodule
