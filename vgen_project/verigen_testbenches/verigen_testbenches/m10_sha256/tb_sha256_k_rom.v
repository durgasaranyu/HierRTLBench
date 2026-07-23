`timescale 1ns/1ps

module tb_sha256_k_rom;

    // DUT connections
    reg  [5:0]  idx;
    wire [31:0] k;

    // Clock (not really needed for combinational, but required by spec)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not really needed for combinational, but required by spec)
    reg rst;
    integer i;
    integer fail_count;

    // Instantiate DUT
    sha256_k_rom uut (
        .idx(idx),
        .k(k)
    );

    // Task for checking
    task check;
        input [5:0]  test_idx;
        input [31:0] expected;
        input [63:0] desc_num; // just use index as identifier
        begin
            idx = test_idx;
            #1; // small delay for combinational logic to settle
            if (k === expected) begin
                $display("PASS: K[%0d] = 32'h%08x", test_idx, k);
            end else begin
                $display("FAIL: K[%0d] expected 32'h%08x got 32'h%08x", test_idx, expected, k);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        fail_count = 0;
        rst = 1;
        idx = 0;

        // Assert reset for 5 rising edges
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        // Wait one more cycle after reset deassertion
        @(posedge clk);

        // Test vector 1: K[0] = 32'h428a2f98
        check(6'h00, 32'h428a2f98, 0);

        // Test vector 2: K[1] = 32'h71374491
        check(6'h01, 32'h71374491, 1);

        // Test vector 3: K[2] = 32'hb5c0fbcf
        check(6'h02, 32'hb5c0fbcf, 2);

        // Test vector 4: K[63] = 32'hc67178f2 (index 0x3F)
        check(6'h3F, 32'hc67178f2, 63);

        // Test vector 5: K[4] = 32'h3956c25b
        check(6'h04, 32'h3956c25b, 4);

        // Test vector 6: K[15] = 32'hc19bf174 (0x0F)
        check(6'h0F, 32'hc19bf174, 15);

        // Test vector 7: K[32] = 32'h27b70a85 (0x20)
        check(6'h20, 32'h27b70a85, 32);

        // Test vector 8: K[48] = 32'h748f82ee (0x38)
        check(6'h38, 32'h748f82ee, 48);

        // Test vector 9: K[3] = 32'he9b5dba5
        check(6'h03, 32'he9b5dba5, 3);

        // Test vector 10: K[16] = 32'he49b69c1 (0x10)
        check(6'h10, 32'he49b69c1, 16);

        // Test vector 11: K[31] = 32'h14292967 (0x1F)
        check(6'h1F, 32'h14292967, 31);

        // Test vector 12: K[62] = 32'hbef9a3f7 (0x3E)
        check(6'h3E, 32'hbef9a3f7, 62);

        // Summary
        if (fail_count == 0) begin
            $display("PASS: All tests passed.");
        end else begin
            $display("FAIL: %0d test(s) failed.", fail_count);
        end

        $finish;
    end

endmodule
