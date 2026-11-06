`timescale 1ns/1ps

module tb_sha256_compress;

    // SHA-256 constants K[0..63]
    reg [31:0] K [0:63];

    // DUT ports
    reg  [255:0]  H_in;
    reg  [2047:0] W;
    wire [255:0]  H_out;

    // Instantiate DUT
    sha256_compress uut (
        .H_in  (H_in),
        .W     (W),
        .H_out (H_out)
    );

    // Clock (not used by combinational DUT but required by rules)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset signal (required by rules; not connected to combinational DUT)
    reg rst;

    // Reference model task variables
    integer i;

    // SHA-256 K constants
    task init_K;
    begin
        K[0]  = 32'h428a2f98; K[1]  = 32'h71374491; K[2]  = 32'hb5c0fbcf; K[3]  = 32'he9b5dba5;
        K[4]  = 32'h3956c25b; K[5]  = 32'h59f111f1; K[6]  = 32'h923f82a4; K[7]  = 32'hab1c5ed5;
        K[8]  = 32'hd807aa98; K[9]  = 32'h12835b01; K[10] = 32'h243185be; K[11] = 32'h550c7dc3;
        K[12] = 32'h72be5d74; K[13] = 32'h80deb1fe; K[14] = 32'h9bdc06a7; K[15] = 32'hc19bf174;
        K[16] = 32'he49b69c1; K[17] = 32'hefbe4786; K[18] = 32'h0fc19dc6; K[19] = 32'h240ca1cc;
        K[20] = 32'h2de92c6f; K[21] = 32'h4a7484aa; K[22] = 32'h5cb0a9dc; K[23] = 32'h76f988da;
        K[24] = 32'h983e5152; K[25] = 32'ha831c66d; K[26] = 32'hb00327c8; K[27] = 32'hbf597fc7;
        K[28] = 32'hc6e00bf3; K[29] = 32'hd5a79147; K[30] = 32'h06ca6351; K[31] = 32'h14292967;
        K[32] = 32'h27b70a85; K[33] = 32'h2e1b2138; K[34] = 32'h4d2c6dfc; K[35] = 32'h53380d13;
        K[36] = 32'h650a7354; K[37] = 32'h766a0abb; K[38] = 32'h81c2c92e; K[39] = 32'h92722c85;
        K[40] = 32'ha2bfe8a1; K[41] = 32'ha81a664b; K[42] = 32'hc24b8b70; K[43] = 32'hc76c51a3;
        K[44] = 32'hd192e819; K[45] = 32'hd6990624; K[46] = 32'hf40e3585; K[47] = 32'h106aa070;
        K[48] = 32'h19a4c116; K[49] = 32'h1e376c08; K[50] = 32'h2748774c; K[51] = 32'h34b0bcb5;
        K[52] = 32'h391c0cb3; K[53] = 32'h4ed8aa4a; K[54] = 32'h5b9cca4f; K[55] = 32'h682e6ff3;
        K[56] = 32'h748f82ee; K[57] = 32'h78a5636f; K[58] = 32'h84c87814; K[59] = 32'h8cc70208;
        K[60] = 32'h90befffa; K[61] = 32'ha4506ceb; K[62] = 32'hbef9a3f7; K[63] = 32'hc67178f2;
    end
    endtask

    // Reference compression function
    reg [31:0] ra, rb, rc, rd, re, rf, rg, rh;
    reg [31:0] rW [0:63];
    reg [255:0] ref_H_out;
    reg [31:0] T1, T2, S1, S0, ch_v, maj_v;

    function [31:0] rotr;
        input [31:0] x;
        input [4:0]  n;
        begin
            rotr = (x >> n) | (x << (32-n));
        end
    endfunction

    task compute_ref;
        input [255:0]  Hin;
        input [2047:0] Win;
        output [255:0] Hout;
        integer j;
        begin
            // Unpack H_in: H[0]=bits[255:224], ..., H[7]=bits[31:0]
            ra = Hin[255:224];
            rb = Hin[223:192];
            rc = Hin[191:160];
            rd = Hin[159:128];
            re = Hin[127:96];
            rf = Hin[95:64];
            rg = Hin[63:32];
            rh = Hin[31:0];

            // Unpack W: W[0]=bits[2047:2016], ..., W[63]=bits[31:0]
            for (j = 0; j < 64; j = j+1) begin
                rW[j] = Win[2047 - j*32 -: 32];
            end

            // 64 rounds
            for (j = 0; j < 64; j = j+1) begin
                S1    = rotr(re,6) ^ rotr(re,11) ^ rotr(re,25);
                ch_v  = (re & rf) ^ (~re & rg);
                T1    = rh + S1 + ch_v + K[j] + rW[j];
                S0    = rotr(ra,2) ^ rotr(ra,13) ^ rotr(ra,22);
                maj_v = (ra & rb) ^ (ra & rc) ^ (rb & rc);
                T2    = S0 + maj_v;
                rh = rg;
                rg = rf;
                rf = re;
                re = rd + T1;
                rd = rc;
                rc = rb;
                rb = ra;
                ra = T1 + T2;
            end

            // Add back H_in
            Hout[255:224] = Hin[255:224] + ra;
            Hout[223:192] = Hin[223:192] + rb;
            Hout[191:160] = Hin[191:160] + rc;
            Hout[159:128] = Hin[159:128] + rd;
            Hout[127:96]  = Hin[127:96]  + re;
            Hout[95:64]   = Hin[95:64]   + rf;
            Hout[63:32]   = Hin[63:32]   + rg;
            Hout[31:0]    = Hin[31:0]    + rh;
        end
    endtask

    integer pass_count;
    integer fail_count;

    // Test vector checking
    task check;
        input [255:0] expected;
        input [255:0] got;
        input [127:0] desc; // 16 chars max for simplicity
        begin
            if (expected === got) begin
                $display("PASS: %s", desc);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %s  expected=%h got=%h", desc, expected, got);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Also check H_out is non-zero
    task check_nonzero;
        input [255:0] got;
        input [127:0] desc;
        begin
            if (got !== 256'h0) begin
                $display("PASS: %s (non-zero output)", desc);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %s (output is zero)", desc);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // SHA-256 initial hash values (standard IV)
    parameter [255:0] SHA256_IV = {
        32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a,
        32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19
    };

    initial begin
        init_K;
        pass_count = 0;
        fail_count = 0;

        // Reset sequence (5 rising edges with rst=1)
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // ------------------------------------------------------------------
        // Test 1: All-zero H_in and W
        // ------------------------------------------------------------------
        H_in = 256'h0;
        W    = 2048'h0;
        #1; // let combinational settle
        compute_ref(H_in, W, ref_H_out);
        check(ref_H_out, H_out, "All-zero H_in+W");

        // ------------------------------------------------------------------
        // Test 2: All-ones H_in and W
        // ------------------------------------------------------------------
        H_in = {256{1'b1}};
        W    = {2048{1'b1}};
        #1;
        compute_ref(H_in, W, ref_H_out);
        check(ref_H_out, H_out, "All-ones H_in+W");

        // ------------------------------------------------------------------
        // Test 3: SHA-256 standard IV, all-zero W
        // ------------------------------------------------------------------
        H_in = SHA256_IV;
        W    = 2048'h0;
        #1;
        compute_ref(H_in, W, ref_H_out);
        check(ref_H_out, H_out, "SHA256 IV zero W");

        // ------------------------------------------------------------------
        // Test 4: SHA-256 standard IV, W[0]=1, rest zero
        // ------------------------------------------------------------------
        H_in = SHA256_IV;
        W    = 2048'h0;
        W[2047:2016] = 32'h00000001; // W[0] = 1
        #1;
        compute_ref(H_in, W, ref_H_out);
        check(ref_H_out, H_out, "SHA256 IV W0=1");

        // ------------------------------------------------------------------
        // Test 5: Standard SHA-256 first block (message = "abc" padded)
        // W[0]="abc" padded as 0x61626380, W[1..13]=0, W[14]=0, W[15]=24
        // ------------------------------------------------------------------
        H_in = SHA256_IV;
        W    = 2048'h0;
        W[2047:2016] = 32'h61626380; // W[0]
        W[2047-15*32 -: 32] = 32'h00000018; // W[15] = 24 bits
        #1;
        compute_ref(H_in, W, ref_H_out);
        check(ref_H_out, H_out, "SHA256 abc block");
        // Also verify non-zero
        check_nonzero(H_out, "abc block nonzero");

        // ------------------------------------------------------------------
        // Test 6: Random-looking H_in and W (max value test)
        // ------------------------------------------------------------------
        H_in = {32'hdeadbeef, 32'hcafebabe, 32'h12345678, 32'h9abcdef0,
                32'hfedcba98, 32'h76543210, 32'h0f0f0f0f, 32'hf0f0f0f0};
        // Fill W with incrementing pattern
        begin : fill_w
            integer k;
            for (k = 0; k < 64; k = k+1) begin
                W[2047 - k*32 -: 32] = k * 32'h01234567 + 32'habcdef01;
            end
        end
        #1;
        compute_ref(H_in, W, ref_H_out);
        check(ref_H_out, H_out, "Random H_in+W");

        // ------------------------------------------------------------------
        // Test 7: H_in = max (all F), W = alternating 55/AA pattern
        // ------------------------------------------------------------------
        H_in = {256{1'b1}};
        begin : fill_w2
            integer k;
            for (k = 0; k < 64; k = k+1) begin
                if (k[0])
                    W[2047 - k*32 -: 32] = 32'haaaaaaaa;
                else
                    W[2047 - k*32 -: 32] = 32'h55555555;
            end
        end
        #1;
        compute_ref(H_in, W, ref_H_out);
        check(ref_H_out, H_out, "MaxH alt W pattern");

        // ------------------------------------------------------------------
        // Test 8: H_in = 0, W = K constants (all 64 K values)
        // ------------------------------------------------------------------
        H_in = 256'h0;
        begin : fill_w3
            integer k;
            for (k = 0; k < 64; k = k+1) begin
                W[2047 - k*32 -: 32] = K[k];
            end
        end
        #1;
        compute_ref(H_in, W, ref_H_out);
        check(ref_H_out, H_out, "Zero H_in W=K");

        // ------------------------------------------------------------------
        // Test 9: H_in = SHA256_IV, W = all K constants
        // ------------------------------------------------------------------
        H_in = SHA256_IV;
        begin : fill_w4
            integer k;
            for (k = 0; k < 64; k = k+1) begin
                W[2047 - k*32 -: 32] = K[k];
            end
        end
        #1;
        compute_ref(H_in, W, ref_H_out);
        check(ref_H_out, H_out, "IV H_in W=K");
        check_nonzero(H_out, "IV H_in W=K nonzero");

        // ------------------------------------------------------------------
        // Test 10: Single bit set in H_in, zero W
        // ------------------------------------------------------------------
        H_in = 256'h1; // LSB of H[7]
        W    = 2048'h0;
        #1;
        compute_ref(H_in, W, ref_H_out);
        check(ref_H_out, H_out, "Single bit H_in
