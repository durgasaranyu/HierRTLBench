// SHA-256 K constants ROM: 64 x 32-bit cube-root-derived primes. Combinational.
// K[0]=32'h428a2f98, K[1]=32'h71374491, K[2]=32'hb5c0fbcf, K[3]=32'he9b5dba5...
module sha256_k_rom (
    input  [5:0]  idx,
    output reg [31:0] k
);
    always @(*) case (idx)
        6'h00: k = 32'h428a2f98;
        6'h01: k = 32'h71374491;
        6'h02: k = 32'hb5c0fbcf;
        6'h03: k = 32'he9b5dba5;
        6'h04: k = 32'h3956c25b;
        6'h05: k = 32'h59f111f1;
        6'h06: k = 32'h923f82a4;
        6'h07: k = 32'hab1c5ed5;
        6'h08: k = 32'hd807aa98;
        6'h09: k = 32'h12835b01;
        6'h0A: k = 32'h243185be;
        6'h0B: k = 32'h550c7dc3;
        6'h0C: k = 32'h72be5d74;
        6'h0D: k = 32'h80deb1fe;
        6'h0E: k = 32'h9bdc06a7;
        6'h0F: k = 32'hc19bf174;
        6'h10: k = 32'he49b69c1;
        6'h11: k = 32'hefbe4786;
        6'h12: k = 32'h0fc19dc6;
        6'h13: k = 32'h240ca1cc;
        6'h14: k = 32'h2de92c6f;
        6'h15: k = 32'h4a7484aa;
        6'h16: k = 32'h5cb0a9dc;
        6'h17: k = 32'h76f988da;
        6'h18: k = 32'h983e5152;
        6'h19: k = 32'ha831c66d;
        6'h1A: k = 32'hb00327c8;
        6'h1B: k = 32'hbf597fc7;
        6'h1C: k = 32'hc6e00bf3;
        6'h1D: k = 32'hd5a79147;
        6'h1E: k = 32'h06ca6351;
        6'h1F: k = 32'h14292967;
        6'h20: k = 32'h27b70a85;
        6'h21: k = 32'h2e1b2138;
        6'h22: k = 32'h4d2c6dfc;
        6'h23: k = 32'h53380d13;
        6'h24: k = 32'h650a7354;
        6'h25: k = 32'h766a0abb;
        6'h26: k = 32'h81c2c92e;
        6'h27: k = 32'h92722c85;
        6'h28: k = 32'ha2bfe8a1;
        6'h29: k = 32'ha81a664b;
        6'h2A: k = 32'hc24b8b70;
        6'h2B: k = 32'hc76c51a3;
        6'h2C: k = 32'hd192e819;
        6'h2D: k = 32'hd6990624;
        6'h2E: k = 32'hf40e3585;
        6'h2F: k = 32'h106aa070;
        6'h30: k = 32'h19a4c116;
        6'h31: k = 32'h1e376c08;
        6'h32: k = 32'h2748774c;
        6'h33: k = 32'h34b0bcb5;
        6'h34: k = 32'h391c0cb3;
        6'h35: k = 32'h4ed8aa4a;
        6'h36: k = 32'h5b9cca4f;
        6'h37: k = 32'h682e6ff3;
        6'h38: k = 32'h748f82ee;
        6'h39: k = 32'h78a5636f;
        6'h3A: k = 32'h84c87814;
        6'h3B: k = 32'h8cc70208;
        6'h3C: k = 32'h90befffa;
        6'h3D: k = 32'ha4506ceb;
        6'h3E: k = 32'hbef9a3f7;
        6'h3F: k = 32'hc67178f2;
    endcase

endmodule
