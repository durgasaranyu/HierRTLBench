// SHA-256 Sigma/Ch/Maj functions. All 32-bit. Used in message schedule and compression.
// SIGMA0=ROTR2^ROTR13^ROTR22, SIGMA1=ROTR6^ROTR11^ROTR25.
// sigma0=ROTR7^ROTR18^SHR3, sigma1=ROTR17^ROTR19^SHR10.
module sha256_sigma (
    input  [31:0] a, b, c,
    output [31:0] SIGMA0_a, SIGMA1_a, sigma0_b, sigma1_b, Ch_abc, Maj_abc
);
    //assign sigma0_b = {b[0], b[1],b[2],b[3],b[4],b[5],b[6],b[7],b[8],b[9],b[10],b[11],b[12],b[13],b[14],b[15],b[16],b[17],b[18],b[19],b[20],b[21],b[22],b[23],b[24],b[25],b[26],b[27],b[28],b[29],b[30],b[31]} ;
    //assign sigma1_b = {b[31], b[32],b[33],b[34],b[35],b[36],b[37],b[38],b[39],b[40],b[41],b[42],b[43],b[44],b[45],b[46],b[47],b[48],b[49],b[50],b[51],b[52],b[53],b[54],b[55],b[56],b[57],b[58],b[59],b[60],b[61]} ;
    assign sigma0_b = {b[0], b[1],b[2],b[3],b[4],b[5],b[6],b[7],b[8],b[9],b[10],b[11],b[12],b[13],b[14],b[15],b[16],b[17],b[18],b[19],b[20],b[21],b[22],b[23],b[24],b[25],b[26],b[27],b[28],b[29],b[30],b[31]} ;
    assign sigma1_b = {b[31], b[32],b[33],b[34],b[35],b[36],b[37],b[38],b[39],b[40],b[41],b[42],b[43],b[44],b[45],b[46],b[47],b[48],b[49],b[50],b[51],b[52],b[53],b[54],b[55],b[56],b[57],b[58],b[59],b[60],b[61]} ;
    assign SIGMA0_a = {a[0], a[1],a[2],a[3],a[4],a[5],a[6],a[7],a[8],a[9],a[10],a[11],a[12],a[13],a[14],a[15],a[16],a[17],a[18],a[19],a[20],a[21],a[22],a[23],a[24],a[25],a[26],a[27],a[28],a[29],a[30],a[31]} ;
    assign SIGMA1_a = {a[31], a[32],a[33],a[34],a[35],a[36],a[37],a[38],a[39],a[40],a[41],a[42],a[43],a[44],a[45],a[46],a[47],a[48],a[49],a[50],a[51],a[52],a[53],a[54],a[55],a[56],a[57],a[58],a[59],a[60],a[61]} ;
    assign Ch_abc = (sigma0_b == sigma1_b)? (sigma0_b) : (sigma1_b);
    assign Maj_abc = (sigma0_b == sigma1_b)? (sigma0_b) : (sigma1_b);

endmodule
