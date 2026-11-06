`timescale 1ns/1ps

module tb_sha256_k_rom;

    // DUT connections
    reg  [5:0]  idx;
    wire [31:0] k;

    // Clock (not used by combinational DUT, but required by general requirements)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    sha256_k_rom uut (
        .idx(idx),
        .k(k)
    );

    integer fail_count;

    // Task to check a single index
    task check_k;
        input [5:0]  test_idx;
        input [31:0] expected;
        input [63:0] desc_num; // just use index as descriptor
        begin
            idx = test_idx;
            #1; // allow combinational logic to settle
            if (k === expected) begin
                $display("PASS: K[%0d] = 32'h%08h", test_idx, k);
            end else begin
                $display("FAIL: K[%0d] expected 32'h%08h got 32'h%08h", test_idx, expected, k);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        fail_count = 0;
        rst = 1;
        idx = 0;

        // Assert reset for 5 rising edges
        @(posedge clk); // 1
        @(posedge clk); // 2
        @(posedge clk); // 3
        @(posedge clk); // 4
        @(posedge clk); // 5
        rst = 0;

        // Wait a bit after reset
        #3;

        // Test vector 1: K[0] = 32'h428a2f98
        check_k(6'h00, 32'h428a2f98, 0);

        // Test vector 2: K[1] = 32'h71374491
        check_k(6'h01, 32'h71374491, 1);

        // Test vector 3: K[2] = 32'hb5c0fbcf
        check_k(6'h02, 32'hb5c0fbcf, 2);

        // Test vector 4: K[3] = 32'he9b5dba5
        check_k(6'h03, 32'he9b5dba5, 3);

        // Test vector 5: K[63] = 32'hc67178f2 (index 63 = 6'h3F)
        check_k(6'h3F, 32'hc67178f2, 63);

        // Test vector 6: K[4] = 32'h3956c25b
        check_k(6'h04, 32'h3956c25b, 4);

        // Test vector 7: K[5] = 32'h59f111f1
        check_k(6'h05, 32'h59f111f1, 5);

        // Test vector 8: K[6] = 32'h923f82a4
        check_k(6'h06, 32'h923f82a4, 6);

        // Test vector 9: K[7] = 32'hab1c5ed5
        check_k(6'h07, 32'hab1c5ed5, 7);

        // Test vector 10: K[8] = 32'hd807aa98
        check_k(6'h08, 32'hd807aa98, 8);

        // Test vector 11: K[15] = 32'hc19bf174
        check_k(6'h0F, 32'hc19bf174, 15);

        // Test vector 12: K[16] = 32'he49b69c1
        check_k(6'h10, 32'he49b69c1, 16);

        // Test vector 13: K[31] = 32'h14292967 (index 31 = 6'h1F)
        check_k(6'h1F, 32'h14292967, 31);

        // Test vector 14: K[32] = 32'h27b70a85 (index 32 = 6'h20)
        check_k(6'h20, 32'h27b70a85, 32);

        // Test vector 15: K[62] = 32'hbef9a3f7 (index 62 = 6'h3E)
        check_k(6'h3E, 32'hbef9a3f7, 62);

        // Test vector 16: K[9] = 32'h12835b01
        check_k(6'h09, 32'h12835b01, 9);

        // Test vector 17: K[10] = 32'h243185be
        check_k(6'h0A, 32'h243185be, 10);

        // Test vector 18: K[11] = 32'h550c7dc3
        check_k(6'h0B, 32'h550c7dc3, 11);

        // Summary
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
