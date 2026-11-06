`timescale 1ns/1ps

module tb_sha256_msg_sched;

    // DUT connections
    reg  [511:0]  block_in;
    wire [2047:0] W;

    // Clock (not used by combinational DUT, but required by general requirements)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    sha256_msg_sched uut (
        .block_in(block_in),
        .W(W)
    );

    // Helper function: extract W[i] from packed bus
    // W is 2048 bits: W[0] at bits [2047:2016], W[1] at [2015:1984], ...
    // W[i] at bits [2047 - 32*i : 2016 - 32*i]
    // We'll use inline expressions in tasks

    // Sigma0: ROTR7 ^ ROTR18 ^ SHR3
    function [31:0] sigma0;
        input [31:0] x;
        begin
            sigma0 = ({x[6:0], x[31:7]}) ^ ({x[17:0], x[31:18]}) ^ (x >> 3);
        end
    endfunction

    // Sigma1: ROTR17 ^ ROTR19 ^ SHR10
    function [31:0] sigma1;
        input [31:0] x;
        begin
            sigma1 = ({x[16:0], x[31:17]}) ^ ({x[18:0], x[31:19]}) ^ (x >> 10);
        end
    endfunction

    // Compute expected W array (64 words) from block_in
    // Returns packed 2048-bit value
    // We'll do this in a task using a local array

    integer i;
    reg [31:0] exp_W [0:63];
    reg [31:0] got_W [0:63];
    integer fail_count;

    // Task to compute expected W
    task compute_expected_W;
        input [511:0] blk;
        integer j;
        begin
            // W[0..15] from block (big-endian: W[0] = blk[511:480])
            for (j = 0; j < 16; j = j + 1) begin
                exp_W[j] = blk[511 - 32*j -: 32];
            end
            for (j = 16; j < 64; j = j + 1) begin
                exp_W[j] = sigma1(exp_W[j-2]) + exp_W[j-7] + sigma0(exp_W[j-15]) + exp_W[j-16];
            end
        end
    endtask

    // Task to extract got_W from DUT output
    task extract_got_W;
        integer j;
        begin
            for (j = 0; j < 64; j = j + 1) begin
                got_W[j] = W[2047 - 32*j -: 32];
            end
        end
    endtask

    // Task to check all 64 words
    task check_W;
        input [127:0] test_name; // use as string label (just a wide reg for display)
        integer j;
        reg failed;
        begin
            failed = 0;
            for (j = 0; j < 64; j = j + 1) begin
                if (got_W[j] !== exp_W[j]) begin
                    failed = 1;
                    $display("FAIL: %s W[%0d] expected=%h got=%h", test_name, j, exp_W[j], got_W[j]);
                end
            end
            if (!failed)
                $display("PASS: %s", test_name);
        end
    endtask

    // Apply reset for 5 rising edges (even though DUT is combinational)
    task apply_reset;
        integer k;
        begin
            rst = 1;
            for (k = 0; k < 5; k = k + 1) begin
                @(posedge clk);
            end
            rst = 0;
        end
    endtask

    initial begin
        fail_count = 0;
        block_in = 512'h0;
        rst = 0;

        // Assert reset for 5 rising edges
        apply_reset;

        // Give some settling time
        #2;

        // ----------------------------------------------------------------
        // Test 1: All-zero input
        // ----------------------------------------------------------------
        block_in = 512'h0;
        #10;
        compute_expected_W(block_in);
        extract_got_W;
        check_W("All-zero input");

        // ----------------------------------------------------------------
        // Test 2: All-ones input
        // ----------------------------------------------------------------
        block_in = {512{1'b1}};
        #10;
        compute_expected_W(block_in);
        extract_got_W;
        check_W("All-ones input");

        // ----------------------------------------------------------------
        // Test 3: Known SHA-256 test vector - "abc" padded block
        // SHA-256 of "abc": block = 61626380 00000000 ... 00000018
        // ----------------------------------------------------------------
        block_in = 512'h6162638000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000_0018;
        // Reconstruct correctly:
        block_in = 512'h61626380_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000018;
        #10;
        compute_expected_W(block_in);
        extract_got_W;
        check_W("SHA-256 abc padded block");

        // ----------------------------------------------------------------
        // Test 4: Single bit set in W[0]
        // ----------------------------------------------------------------
        block_in = 512'h0;
        block_in[511] = 1'b1; // W[0] = 32'h80000000
        #10;
        compute_expected_W(block_in);
        extract_got_W;
        check_W("Single MSB in W[0]");

        // ----------------------------------------------------------------
        // Test 5: Single bit set in W[15]
        // ----------------------------------------------------------------
        block_in = 512'h0;
        block_in[0] = 1'b1; // W[15] = 32'h00000001
        #10;
        compute_expected_W(block_in);
        extract_got_W;
        check_W("Single LSB in W[15]");

        // ----------------------------------------------------------------
        // Test 6: Alternating pattern
        // ----------------------------------------------------------------
        block_in = 512'hAAAAAAAA_55555555_AAAAAAAA_55555555_AAAAAAAA_55555555_AAAAAAAA_55555555_AAAAAAAA_55555555_AAAAAAAA_55555555_AAAAAAAA_55555555_AAAAAAAA_55555555;
        #10;
        compute_expected_W(block_in);
        extract_got_W;
        check_W("Alternating AAAA5555 pattern");

        // ----------------------------------------------------------------
        // Test 7: Incrementing words
        // ----------------------------------------------------------------
        block_in = {32'h00000001, 32'h00000002, 32'h00000003, 32'h00000004,
                    32'h00000005, 32'h00000006, 32'h00000007, 32'h00000008,
                    32'h00000009, 32'h0000000A, 32'h0000000B, 32'h0000000C,
                    32'h0000000D, 32'h0000000E, 32'h0000000F, 32'h00000010};
        #10;
        compute_expected_W(block_in);
        extract_got_W;
        check_W("Incrementing words 1..16");

        // ----------------------------------------------------------------
        // Test 8: Maximum value words (0xFFFFFFFF)
        // ----------------------------------------------------------------
        block_in = {16{32'hFFFFFFFF}};
        #10;
        compute_expected_W(block_in);
        extract_got_W;
        check_W("Max value 0xFFFFFFFF all words");

        // ----------------------------------------------------------------
        // Test 9: Mixed pattern - typical message
        // ----------------------------------------------------------------
        block_in = {32'hDEADBEEF, 32'hCAFEBABE, 32'h12345678, 32'h9ABCDEF0,
                    32'hFEDCBA98, 32'h76543210, 32'h0F0F0F0F, 32'hF0F0F0F0,
                    32'h01234567, 32'h89ABCDEF, 32'hFEDCBA98, 32'h76543210,
                    32'hAAAA5555, 32'h5555AAAA, 32'h12481248, 32'h84218421};
        #10;
        compute_expected_W(block_in);
        extract_got_W;
        check_W("Mixed pattern typical message");

        // ----------------------------------------------------------------
        // Test 10: Only W[1] non-zero
        // ----------------------------------------------------------------
        block_in = 512'h0;
        block_in[479:448] = 32'hA5A5A5A5; // W[1]
        #10;
        compute_expected_W(block_in);
        extract_got_W;
        check_W("Only W[1] non-zero A5A5A5A5");

        $finish;
    end

endmodule
