`timescale 1ns/1ps

module tb_sha256_k_rom;

    // DUT connections
    reg  [5:0]  idx;
    wire [31:0] k;

    // Clock (not strictly needed for combinational, but required by rules)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not strictly needed, but required by rules)
    reg rst;
    integer i;

    // Instantiate DUT
    sha256_k_rom uut (
        .idx(idx),
        .k(k)
    );

    // Expected K constants
    reg [31:0] expected_k [0:63];

    initial begin
        // Initialize expected K values
        expected_k[6'h00] = 32'h428a2f98;
        expected_k[6'h01] = 32'h71374491;
        expected_k[6'h02] = 32'hb5c0fbcf;
        expected_k[6'h03] = 32'he9b5dba5;
        expected_k[6'h04] = 32'h3956c25b;
        expected_k[6'h05] = 32'h59f111f1;
        expected_k[6'h06] = 32'h923f82a4;
        expected_k[6'h07] = 32'hab1c5ed5;
        expected_k[6'h08] = 32'hd807aa98;
        expected_k[6'h09] = 32'h12835b01;
        expected_k[6'h0A] = 32'h243185be;
        expected_k[6'h0B] = 32'h550c7dc3;
        expected_k[6'h0C] = 32'h72be5d74;
        expected_k[6'h0D] = 32'h80deb1fe;
        expected_k[6'h0E] = 32'h9bdc06a7;
        expected_k[6'h0F] = 32'hc19bf174;
        expected_k[6'h10] = 32'he49b69c1;
        expected_k[6'h11] = 32'hefbe4786;
        expected_k[6'h12] = 32'h0fc19dc6;
        expected_k[6'h13] = 32'h240ca1cc;
        expected_k[6'h14] = 32'h2de92c6f;
        expected_k[6'h15] = 32'h4a7484aa;
        expected_k[6'h16] = 32'h5cb0a9dc;
        expected_k[6'h17] = 32'h76f988da;
        expected_k[6'h18] = 32'h983e5152;
        expected_k[6'h19] = 32'ha831c66d;
        expected_k[6'h1A] = 32'hb00327c8;
        expected_k[6'h1B] = 32'hbf597fc7;
        expected_k[6'h1C] = 32'hc6e00bf3;
        expected_k[6'h1D] = 32'hd5a79147;
        expected_k[6'h1E] = 32'h06ca6351;
        expected_k[6'h1F] = 32'h14292967;
        expected_k[6'h20] = 32'h27b70a85;
        expected_k[6'h21] = 32'h2e1b2138;
        expected_k[6'h22] = 32'h4d2c6dfc;
        expected_k[6'h23] = 32'h53380d13;
        expected_k[6'h24] = 32'h650a7354;
        expected_k[6'h25] = 32'h766a0abb;
        expected_k[6'h26] = 32'h81c2c92e;
        expected_k[6'h27] = 32'h92722c85;
        expected_k[6'h28] = 32'ha2bfe8a1;
        expected_k[6'h29] = 32'ha81a664b;
        expected_k[6'h2A] = 32'hc24b8b70;
        expected_k[6'h2B] = 32'hc76c51a3;
        expected_k[6'h2C] = 32'hd192e819;
        expected_k[6'h2D] = 32'hd6990624;
        expected_k[6'h2E] = 32'hf40e3585;
        expected_k[6'h2F] = 32'h106aa070;
        expected_k[6'h30] = 32'h19a4c116;
        expected_k[6'h31] = 32'h1e376c08;
        expected_k[6'h32] = 32'h2748774c;
        expected_k[6'h33] = 32'h34b0bcb5;
        expected_k[6'h34] = 32'h391c0cb3;
        expected_k[6'h35] = 32'h4ed8aa4a;
        expected_k[6'h36] = 32'h5b9cca4f;
        expected_k[6'h37] = 32'h682e6ff3;
        expected_k[6'h38] = 32'h748f82ee;
        expected_k[6'h39] = 32'h78a5636f;
        expected_k[6'h3A] = 32'h84c87814;
        expected_k[6'h3B] = 32'h8cc70208;
        expected_k[6'h3C] = 32'h90befffa;
        expected_k[6'h3D] = 32'ha4506ceb;
        expected_k[6'h3E] = 32'hbef9a3f7;
        expected_k[6'h3F] = 32'hc67178f2;
    end

    // Task for checking a single index
    task check_k;
        input [5:0] test_idx;
        input [31:0] exp_val;
        input [63:0] desc_num; // used for display
        begin
            idx = test_idx;
            #2; // small combinational delay
            if (k === exp_val)
                $display("PASS: K[%0d] = 32'h%08h", test_idx, k);
            else
                $display("FAIL: K[%0d] expected 32'h%08h, got 32'h%08h", test_idx, exp_val, k);
        end
    endtask

    integer fail_count;

    initial begin
        // Initialize
        idx = 0;
        rst = 1;
        fail_count = 0;

        // Assert reset for 5 clock rising edges
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        // Wait one more clock after reset
        @(posedge clk);
        #1;

        // Test vector 1: K[0] = 32'h428a2f98 (required check)
        idx = 6'h00;
        #2;
        if (k === 32'h428a2f98)
            $display("PASS: K[0] = 32'h428a2f98");
        else begin
            $display("FAIL: K[0] expected 32'h428a2f98, got 32'h%08h", k);
            fail_count = fail_count + 1;
        end

        // Test vector 2: K[1] = 32'h71374491 (required check)
        idx = 6'h01;
        #2;
        if (k === 32'h71374491)
            $display("PASS: K[1] = 32'h71374491");
        else begin
            $display("FAIL: K[1] expected 32'h71374491, got 32'h%08h", k);
            fail_count = fail_count + 1;
        end

        // Test vector 3: K[63] = 32'hc67178f2 (required check)
        idx = 6'h3F;
        #2;
        if (k === 32'hc67178f2)
            $display("PASS: K[63] = 32'hc67178f2");
        else begin
            $display("FAIL: K[63] expected 32'hc67178f2, got 32'h%08h", k);
            fail_count = fail_count + 1;
        end

        // Test vector 4: K[2] = 32'hb5c0fbcf (normal operation)
        idx = 6'h02;
        #2;
        if (k === 32'hb5c0fbcf)
            $display("PASS: K[2] = 32'hb5c0fbcf");
        else begin
            $display("FAIL: K[2] expected 32'hb5c0fbcf, got 32'h%08h", k);
            fail_count = fail_count + 1;
        end

        // Test vector 5: K[15] = 32'hc19bf174 (mid-range)
        idx = 6'h0F;
        #2;
        if (k === 32'hc19bf174)
            $display("PASS: K[15] = 32'hc19bf174");
        else begin
            $display("FAIL: K[15] expected 32'hc19bf174, got 32'h%08h", k);
            fail_count = fail_count + 1;
        end

        // Test vector 6: K[31] = 32'h14292967 (mid-range boundary)
        idx = 6'h1F;
        #2;
        if (k === 32'h14292967)
            $display("PASS: K[31] = 32'h14292967");
        else begin
            $display("FAIL: K[31] expected 32'h14292967, got 32'h%08h", k);
            fail_count = fail_count + 1;
        end

        // Test vector 7: K[32] = 32'h27b70a85 (upper half start)
        idx = 6'h20;
        #2;
        if (k === 32'h27b70a85)
            $display("PASS: K[32] = 32'h27b70a85");
        else begin
            $display("FAIL: K[32] expected 32'h27b70a85, got 32'h%08h", k);
            fail_count = fail_count + 1;
        end

        // Test vector 8: K[48] = 32'h748f82ee (near end)
        idx = 6'h38;
        #2;
        if (k === 32'h748f82ee)
            $display("PASS: K[56] = 32'h748f82ee");
        else begin
            $display("FAIL: K[56] expected 32'h748f82ee, got 32'h%08h", k);
            fail_count = fail_count + 1;
        end

        // Additional: sweep all 64 entries exhaustively
        $display("--- Exhaustive sweep of all 64 K constants ---");
        for (i = 0; i < 64; i = i + 1) begin
            idx = i[5:0];
            #2;
            if (k === expected_k[i[5:0]]) begin
                $display("PASS: K[%0d] = 32'h%08h", i, k);
            end else begin
                $display("FAIL: K[%0d] expected 32'h%08h, got 32'h%08h", i, expected_k[i[5:0]], k);
                fail_count = fail_count + 1;
            end
        end

        // Summary
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED: %0d failure(s)", fail_count);

        $finish;
    end

endmodule
