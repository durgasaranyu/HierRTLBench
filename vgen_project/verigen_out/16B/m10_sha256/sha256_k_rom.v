// SHA-256 K constants ROM: 64 x 32-bit cube-root-derived primes. Combinational.
// K[0]=32'h428a2f98, K[1]=32'h71374491, K[2]=32'hb5c0fbcf, K[3]=32'he9b5dba5...
module sha256_k_rom (
    input  [5:0]  idx,
    output reg [31:0] k
);
    always @(*) case (idx)
        0:  k = 32'h428a2f98;
        1:  k = 32'h71374491;
        2:  k = 32'hb5c0fbcf;
        3:  k = 32'he9b5dba5;
        4:  k = 32'h3956c25b;
        5:  k = 32'h59f111f1;
        6:  k = 32'h923f82a4;
        7:  k = 32'hab1c5ed5;
        8:  k = 32'hd807aa98;
        9:  k = 32'h12835b01;
        10: k = 32'h243185be;
        11: k = 32'h550c7dc3;
        12: k = 32'h72be5d74;
        13: k = 32'h80deb1fe;
        14: k = 32'h9bdc06a7;
        15: k = 32'hc19bf174;
        16: k = 32'he49b69c1;
        17: k = 32'hefbe4786;
        18: k = 32'h0fc19dc6;
        19: k = 32'h240ca1cc;
        20: k = 32'h2de92c6f;
        21: k = 32'h4a7484aa;
        22: k = 32'h5cb0a9dc;
        23: k = 32'h76f988da;
        24: k = 32'h983e5152;
        25: k = 32'ha831c66d;
        26: k = 32'hb00327c8;
        27: k = 32'hbf597fc7;
        28: k = 32'hc6e00bf3;
        29: k = 32'hd5a79147;
        30: k = 32'h06ca6351;
        31: k = 32'h14292967;
        32: k = 32'h27b70a85;
        33: k = 32'h2e1b2138;
        34: k = 32'h4d2c6dfc;
        35: k = 32'h53380d13;
        36: k = 32'h650a7354;
        37: k = 32'h766a0abb;
        38: k = 32'h81c2c92e;
        39: k = 32'h92722c85;
        40: k = 32'ha2bfe8a1;
        41: k = 32'ha81a664b;
        42: k = 32'hc24b8b70;
        43: k = 32'hc76c51a3;
        44: k = 32'hd192e819;
        45: k = 32'hd6990624;
        46: k = 32'hf40e3585;
        47: k = 32'h106aa070;
        48: k = 32'h19a4c116;
        49: k = 32'h1e376c08;
        50: k = 32'h2748774c;
        51: k = 32'h34b0bcb5;
        52: k = 32'h391c0cb3;
        53: k = 32'h4ed8aa4a;
        54: k = 32'h5b9cca4f;
        55: k = 32'h682e6ff3;
        56: k = 32'h748f82ee;
        57: k = 32'h78a5636f;
        58: k = 32'h84c87814;
        59: k = 32'h8cc70208;
        60: k = 32'h90befffa;
        61: k = 32'ha4506ceb;
        62: k = 32'hbef9a3f7;
        63: k = 32'hc67178f2;
    endcase

endmodule
