`timescale 1ns/1ps

module tb_sha256_compress;

    // DUT ports
    reg  [255:0]  H_in;
    reg  [2047:0] W;
    wire [255:0]  H_out;

    // Clock (required by general requirements even though DUT is combinational)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (required by general requirements)
    reg rst;
    integer i;

    // Instantiate DUT
    sha256_compress uut (
        .H_in  (H_in),
        .W     (W),
        .H_out (H_out)
    );

    // SHA-256 K constants (first few and last)
    // K[0] = 32'h428a2f98, K[1] = 32'h71374491, K[63] = 32'hc67178f2
    // SHA-256 initial hash values
    // H0=6a09e667 H1=bb67ae85 H2=3c6ef372 H3=a54ff53a
    // H4=510e527f H5=9b05688c H6=1f83d9ab H7=5be0cd19

    // K constants array for reference
    reg [31:0] K [0:63];
    initial begin
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

    // Task: compute one round of SHA-256 compression in software
    // We'll use a simple reference model for testing
    // Since the module is purely combinational, we just drive inputs and check outputs

    // Reference model functions
    function [31:0] rotr;
        input [31:0] x;
        input [4:0]  n;
        begin
            rotr = (x >> n) | (x << (32 - n));
        end
    endfunction

    function [31:0] ch;
        input [31:0] e, f, g;
        begin
            ch = (e & f) ^ (~e & g);
        end
    endfunction

    function [31:0] maj;
        input [31:0] a, b, c;
        begin
            maj = (a & b) ^ (a & c) ^ (b & c);
        end
    endfunction

    function [31:0] sigma0;
        input [31:0] a;
        begin
            sigma0 = rotr(a,2) ^ rotr(a,13) ^ rotr(a,22);
        end
    endfunction

    function [31:0] sigma1;
        input [31:0] e;
        begin
            sigma1 = rotr(e,6) ^ rotr(e,11) ^ rotr(e,25);
        end
    endfunction

    // Reference compression function
    task ref_compress;
        input  [255:0]  H_in_r;
        input  [2047:0] W_r;
        output [255:0]  H_out_r;
        reg [31:0] a, b, c, d, e, f, g, h;
        reg [31:0] T1, T2;
        reg [31:0] w [0:63];
        integer j;
        begin
            // Extract H_in (big-endian: H[0] at bits[255:224])
            a = H_in_r[255:224];
            b = H_in_r[223:192];
            c = H_in_r[191:160];
            d = H_in_r[159:128];
            e = H_in_r[127:96];
            f = H_in_r[95:64];
            g = H_in_r[63:32];
            h = H_in_r[31:0];

            // Extract W (W[0] at bits[2047:2016])
            for (j = 0; j < 64; j = j + 1) begin
                w[j] = W_r[2047 - j*32 -: 32];
            end

            // 64 rounds
            for (j = 0; j < 64; j = j + 1) begin
                T1 = h + sigma1(e) + ch(e,f,g) + K[j] + w[j];
                T2 = sigma0(a) + maj(a,b,c);
                h = g;
                g = f;
                f = e;
                e = d + T1;
                d = c;
                c = b;
                b = a;
                a = T1 + T2;
            end

            H_out_r[255:224] = H_in_r[255:224] + a;
            H_out_r[223:192] = H_in_r[223:192] + b;
            H_out_r[191:160] = H_in_r[191:160] + c;
            H_out_r[159:128] = H_in_r[159:128] + d;
            H_out_r[127:96]  = H_in_r[127:96]  + e;
            H_out_r[95:64]   = H_in_r[95:64]   + f;
            H_out_r[63:32]   = H_in_r[63:32]   + g;
            H_out_r[31:0]    = H_in_r[31:0]    + h;
        end
    endtask

    reg [255:0] expected;
    integer test_num;

    // Reset task (5 rising edges)
    task do_reset;
        integer k;
        begin
            rst = 1;
            for (k = 0; k < 5; k = k + 1) begin
                @(posedge clk);
            end
            rst = 0;
            @(posedge clk);
        end
    endtask

    initial begin
        rst = 0;
        H_in = 0;
        W    = 0;
        test_num = 0;

        // Apply reset
        do_reset;

        // Wait a bit after reset
        #2;

        // ---------------------------------------------------------------
        // Test 1: All-zero inputs
        // ---------------------------------------------------------------
        H_in = 256'h0;
        W    = 2048'h0;
        #10;
        ref_compress(H_in, W, expected);
        if (H_out === expected)
            $display("PASS: Test 1 - All-zero H_in and W");
        else
            $display("FAIL: Test 1 - All-zero H_in and W (got %h, expected %h)", H_out, expected);

        // ---------------------------------------------------------------
        // Test 2: SHA-256 initial hash values, all-zero W
        // ---------------------------------------------------------------
        H_in = {32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a,
                32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19};
        W    = 2048'h0;
        #10;
        ref_compress(H_in, W, expected);
        if (H_out === expected)
            $display("PASS: Test 2 - SHA-256 IV with zero W");
        else
            $display("FAIL: Test 2 - SHA-256 IV with zero W (got %h, expected %h)", H_out, expected);

        // ---------------------------------------------------------------
        // Test 3: All-ones inputs
        // ---------------------------------------------------------------
        H_in = {256{1'b1}};
        W    = {2048{1'b1}};
        #10;
        ref_compress(H_in, W, expected);
        if (H_out === expected)
            $display("PASS: Test 3 - All-ones H_in and W");
        else
            $display("FAIL: Test 3 - All-ones H_in and W (got %h, expected %h)", H_out, expected);

        // ---------------------------------------------------------------
        // Test 4: SHA-256 IV with W[0]=1, rest zero (typical "abc" first word partial)
        // ---------------------------------------------------------------
        H_in = {32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a,
                32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19};
        W    = 2048'h0;
        W[2047:2016] = 32'h00000001; // W[0] = 1
        #10;
        ref_compress(H_in, W, expected);
        if (H_out === expected)
            $display("PASS: Test 4 - SHA-256 IV with W[0]=1");
        else
            $display("FAIL: Test 4 - SHA-256 IV with W[0]=1 (got %h, expected %h)", H_out, expected);

        // ---------------------------------------------------------------
        // Test 5: Known SHA-256 "abc" message schedule W values
        // W[0]=0x61626380, W[1..13]=0, W[14]=0, W[15]=0x00000018, W[16..63] expanded
        // For simplicity, just set W[0]=0x61626380, W[15]=0x18
        // ---------------------------------------------------------------
        H_in = {32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a,
                32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19};
        W    = 2048'h0;
        W[2047:2016] = 32'h61626380; // W[0]
        W[2047-15*32 -: 32] = 32'h00000018; // W[15]
        #10;
        ref_compress(H_in, W, expected);
        if (H_out === expected)
            $display("PASS: Test 5 - SHA-256 abc partial message schedule");
        else
            $display("FAIL: Test 5 - SHA-256 abc partial message schedule (got %h, expected %h)", H_out, expected);

        // ---------------------------------------------------------------
        // Test 6: Alternating bit pattern H_in, zero W
        // ---------------------------------------------------------------
        H_in = {8{32'hAAAAAAAA}};
        W    = 2048'h0;
        #10;
        ref_compress(H_in, W, expected);
        if (H_out === expected)
            $display("PASS: Test 6 - Alternating 0xAAAA H_in, zero W");
        else
            $display("FAIL: Test 6 - Alternating 0xAAAA H_in, zero W (got %h, expected %h)", H_out, expected);

        // ---------------------------------------------------------------
        // Test 7: Zero H_in, alternating W
        // ---------------------------------------------------------------
        H_in = 256'h0;
        W    = {64{32'h55555555}};
        #10;
        ref_compress(H_in, W, expected);
        if (H_out === expected)
            $display("PASS: Test 7 - Zero H_in, alternating 0x5555 W");
        else
            $display("FAIL: Test 7 - Zero H_in, alternating 0x5555 W (got %h, expected %h)", H_out, expected);

        // ---------------------------------------------------------------
        // Test 8: Maximum value H_in = 0xFFFF...FF (32-bit fields), W = increasing
        // ---------------------------------------------------------------
        H_in = {8{32'hFFFFFFFF}};
        // W[i] = i for i=0..63
        begin : gen_w_block
            integer idx;
            for (idx = 0; idx < 64; idx = idx + 1) begin
                W[2047 - idx*32 -: 32] = idx;
            end
        end
