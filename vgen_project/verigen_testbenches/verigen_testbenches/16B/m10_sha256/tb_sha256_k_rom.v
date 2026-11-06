`timescale 1ns/1ps

module tb_sha256_k_rom;

    // DUT connections
    reg  [5:0]  idx;
    wire [31:0] k;

    // Clock (not used by combinational DUT, but required by spec)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not used by combinational DUT, but required by spec)
    reg rst;
    integer i;

    // Instantiate DUT
    sha256_k_rom uut (
        .idx(idx),
        .k(k)
    );

    // Expected values array
    reg [31:0] expected [0:63];

    initial begin
        // Initialize expected K constants
        expected[0]  = 32'h428a2f98;
        expected[1]  = 32'h71374491;
        expected[2]  = 32'hb5c0fbcf;
        expected[3]  = 32'he9b5dba5;
        expected[4]  = 32'h3956c25b;
        expected[5]  = 32'h59f111f1;
        expected[6]  = 32'h923f82a4;
        expected[7]  = 32'hab1c5ed5;
        expected[8]  = 32'hd807aa98;
        expected[9]  = 32'h12835b01;
        expected[10] = 32'h243185be;
        expected[11] = 32'h550c7dc3;
        expected[12] = 32'h72be5d74;
        expected[13] = 32'h80deb1fe;
        expected[14] = 32'h9bdc06a7;
        expected[15] = 32'hc19bf174;
        expected[16] = 32'he49b69c1;
        expected[17] = 32'hefbe4786;
        expected[18] = 32'h0fc19dc6;
        expected[19] = 32'h240ca1cc;
        expected[20] = 32'h2de92c6f;
        expected[21] = 32'h4a7484aa;
        expected[22] = 32'h5cb0a9dc;
        expected[23] = 32'h76f988da;
        expected[24] = 32'h983e5152;
        expected[25] = 32'ha831c66d;
        expected[26] = 32'hb00327c8;
        expected[27] = 32'hbf597fc7;
        expected[28] = 32'hc6e00bf3;
        expected[29] = 32'hd5a79147;
        expected[30] = 32'h06ca6351;
        expected[31] = 32'h14292967;
        expected[32] = 32'h27b70a85;
        expected[33] = 32'h2e1b2138;
        expected[34] = 32'h4d2c6dfc;
        expected[35] = 32'h53380d13;
        expected[36] = 32'h650a7354;
        expected[37] = 32'h766a0abb;
        expected[38] = 32'h81c2c92e;
        expected[39] = 32'h92722c85;
        expected[40] = 32'ha2bfe8a1;
        expected[41] = 32'ha81a664b;
        expected[42] = 32'hc24b8b70;
        expected[43] = 32'hc76c51a3;
        expected[44] = 32'hd192e819;
        expected[45] = 32'hd6990624;
        expected[46] = 32'hf40e3585;
        expected[47] = 32'h106aa070;
        expected[48] = 32'h19a4c116;
        expected[49] = 32'h1e376c08;
        expected[50] = 32'h2748774c;
        expected[51] = 32'h34b0bcb5;
        expected[52] = 32'h391c0cb3;
        expected[53] = 32'h4ed8aa4a;
        expected[54] = 32'h5b9cca4f;
        expected[55] = 32'h682e6ff3;
        expected[56] = 32'h748f82ee;
        expected[57] = 32'h78a5636f;
        expected[58] = 32'h84c87814;
        expected[59] = 32'h8cc70208;
        expected[60] = 32'h90befffa;
        expected[61] = 32'ha4506ceb;
        expected[62] = 32'hbef9a3f7;
        expected[63] = 32'hc67178f2;

        // Assert reset for 5 rising edges
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
        @(negedge clk);

        // -------------------------------------------------------
        // Test vector 1: K[0] = 32'h428a2f98
        // -------------------------------------------------------
        idx = 6'd0;
        #2;
        if (k === 32'h428a2f98)
            $display("PASS: K[0] = 0x%08h (expected 0x428a2f98)", k);
        else
            $display("FAIL: K[0] = 0x%08h (expected 0x428a2f98)", k);

        // -------------------------------------------------------
        // Test vector 2: K[1] = 32'h71374491
        // -------------------------------------------------------
        idx = 6'd1;
        #2;
        if (k === 32'h71374491)
            $display("PASS: K[1] = 0x%08h (expected 0x71374491)", k);
        else
            $display("FAIL: K[1] = 0x%08h (expected 0x71374491)", k);

        // -------------------------------------------------------
        // Test vector 3: K[63] = 32'hc67178f2 (last entry)
        // -------------------------------------------------------
        idx = 6'd63;
        #2;
        if (k === 32'hc67178f2)
            $display("PASS: K[63] = 0x%08h (expected 0xc67178f2)", k);
        else
            $display("FAIL: K[63] = 0x%08h (expected 0xc67178f2)", k);

        // -------------------------------------------------------
        // Test vector 4: K[31] = 32'h14292967 (mid-point)
        // -------------------------------------------------------
        idx = 6'd31;
        #2;
        if (k === 32'h14292967)
            $display("PASS: K[31] = 0x%08h (expected 0x14292967)", k);
        else
            $display("FAIL: K[31] = 0x%08h (expected 0x14292967)", k);

        // -------------------------------------------------------
        // Test vector 5: K[32] = 32'h27b70a85 (upper half boundary)
        // -------------------------------------------------------
        idx = 6'd32;
        #2;
        if (k === 32'h27b70a85)
            $display("PASS: K[32] = 0x%08h (expected 0x27b70a85)", k);
        else
            $display("FAIL: K[32] = 0x%08h (expected 0x27b70a85)", k);

        // -------------------------------------------------------
        // Test vector 6: K[15] = 32'hc19bf174
        // -------------------------------------------------------
        idx = 6'd15;
        #2;
        if (k === 32'hc19bf174)
            $display("PASS: K[15] = 0x%08h (expected 0xc19bf174)", k);
        else
            $display("FAIL: K[15] = 0x%08h (expected 0xc19bf174)", k);

        // -------------------------------------------------------
        // Test vector 7: K[47] = 32'h106aa070
        // -------------------------------------------------------
        idx = 6'd47;
        #2;
        if (k === 32'h106aa070)
            $display("PASS: K[47] = 0x%08h (expected 0x106aa070)", k);
        else
            $display("FAIL: K[47] = 0x%08h (expected 0x106aa070)", k);

        // -------------------------------------------------------
        // Test vector 8: K[62] = 32'hbef9a3f7 (second to last)
        // -------------------------------------------------------
        idx = 6'd62;
        #2;
        if (k === 32'hbef9a3f7)
            $display("PASS: K[62] = 0x%08h (expected 0xbef9a3f7)", k);
        else
            $display("FAIL: K[62] = 0x%08h (expected 0xbef9a3f7)", k);

        // -------------------------------------------------------
        // Exhaustive sweep of all 64 entries
        // -------------------------------------------------------
        for (i = 0; i < 64; i = i + 1) begin
            idx = i[5:0];
            #2;
            if (k === expected[i])
                $display("PASS: K[%0d] = 0x%08h", i, k);
            else
                $display("FAIL: K[%0d] = 0x%08h (expected 0x%08h)", i, k, expected[i]);
        end

        $finish;
    end

endmodule
