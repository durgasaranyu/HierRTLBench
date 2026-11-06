`timescale 1ns/1ps

module tb_sha256_msg_sched;

    // DUT connections
    reg  [511:0]  block_in;
    wire [2047:0] W;

    // Instantiate DUT
    sha256_msg_sched uut (
        .block_in(block_in),
        .W(W)
    );

    // Clock and reset (not used by combinational DUT, but required by spec)
    reg clk;
    reg rst;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset for exactly 5 rising edges
    integer i;
    initial begin
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
    end

    // Helper: extract W[t] from packed 2048-bit bus
    // W is packed: W[2047:2016] = W[0], W[2015:1984] = W[1], ..., W[31:0] = W[63]
    function [31:0] get_W;
        input [2047:0] W_bus;
        input integer  t;
        begin
            get_W = W_bus[2047 - t*32 -: 32];
        end
    endfunction

    // SHA-256 sigma0: ROTR7 ^ ROTR18 ^ SHR3
    function [31:0] sigma0;
        input [31:0] x;
        begin
            sigma0 = ({x[6:0], x[31:7]}) ^ ({x[17:0], x[31:18]}) ^ (x >> 3);
        end
    endfunction

    // SHA-256 sigma1: ROTR17 ^ ROTR19 ^ SHR10
    function [31:0] sigma1;
        input [31:0] x;
        begin
            sigma1 = ({x[16:0], x[31:17]}) ^ ({x[18:0], x[31:19]}) ^ (x >> 10);
        end
    endfunction

    // Compute expected W schedule from a 512-bit block
    task compute_expected_W;
        input  [511:0] blk;
        output [2047:0] W_exp;
        reg [31:0] w [0:63];
        integer t;
        begin
            // W[0..15] from block_in (big-endian 32-bit words)
            // block_in[511:480] = W[0], block_in[479:448] = W[1], ...
            for (t = 0; t < 16; t = t + 1) begin
                w[t] = blk[511 - t*32 -: 32];
            end
            for (t = 16; t < 64; t = t + 1) begin
                w[t] = sigma1(w[t-2]) + w[t-7] + sigma0(w[t-15]) + w[t-16];
            end
            // Pack into 2048-bit bus
            for (t = 0; t < 64; t = t + 1) begin
                W_exp[2047 - t*32 -: 32] = w[t];
            end
        end
    endtask

    reg [2047:0] W_expected;
    integer      fail_count;
    integer      t;
    reg          test_pass;

    initial begin
        fail_count = 0;
        block_in = 512'd0;
        #2; // small settling time after reset de-assertion

        // Wait for reset to finish
        @(negedge rst);
        #2;

        // -------------------------------------------------------
        // Test 1: All-zero input
        // -------------------------------------------------------
        block_in = 512'h0;
        #10;
        compute_expected_W(block_in, W_expected);
        test_pass = 1;
        for (t = 0; t < 64; t = t + 1) begin
            if (get_W(W, t) !== get_W(W_expected, t)) begin
                test_pass = 0;
            end
        end
        if (test_pass)
            $display("PASS: All-zero input W schedule");
        else begin
            $display("FAIL: All-zero input W schedule");
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 2: All-ones input
        // -------------------------------------------------------
        block_in = {512{1'b1}};
        #10;
        compute_expected_W(block_in, W_expected);
        test_pass = 1;
        for (t = 0; t < 64; t = t + 1) begin
            if (get_W(W, t) !== get_W(W_expected, t)) begin
                test_pass = 0;
            end
        end
        if (test_pass)
            $display("PASS: All-ones input W schedule");
        else begin
            $display("FAIL: All-ones input W schedule");
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 3: Single bit set (MSB)
        // -------------------------------------------------------
        block_in = 512'h1 << 511;
        #10;
        compute_expected_W(block_in, W_expected);
        test_pass = 1;
        for (t = 0; t < 64; t = t + 1) begin
            if (get_W(W, t) !== get_W(W_expected, t)) begin
                test_pass = 0;
            end
        end
        if (test_pass)
            $display("PASS: MSB-only input W schedule");
        else begin
            $display("FAIL: MSB-only input W schedule");
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 4: Single bit set (LSB)
        // -------------------------------------------------------
        block_in = 512'h1;
        #10;
        compute_expected_W(block_in, W_expected);
        test_pass = 1;
        for (t = 0; t < 64; t = t + 1) begin
            if (get_W(W, t) !== get_W(W_expected, t)) begin
                test_pass = 0;
            end
        end
        if (test_pass)
            $display("PASS: LSB-only input W schedule");
        else begin
            $display("FAIL: LSB-only input W schedule");
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 5: SHA-256 standard first block for "abc"
        // "abc" padded: 0x61626380 00000000 ... 00000018
        // -------------------------------------------------------
        block_in = 512'h6162638000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000_0018;
        // Build properly
        block_in = 512'd0;
        block_in[511:480] = 32'h61626380;
        block_in[31:0]    = 32'h00000018;
        #10;
        compute_expected_W(block_in, W_expected);
        test_pass = 1;
        for (t = 0; t < 64; t = t + 1) begin
            if (get_W(W, t) !== get_W(W_expected, t)) begin
                test_pass = 0;
            end
        end
        if (test_pass)
            $display("PASS: SHA-256 'abc' message block W schedule");
        else begin
            $display("FAIL: SHA-256 'abc' message block W schedule");
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 6: W[0..15] directly verified for known block
        // -------------------------------------------------------
        block_in = 512'd0;
        block_in[511:480] = 32'hDEADBEEF;
        block_in[479:448] = 32'hCAFEBABE;
        block_in[447:416] = 32'h01234567;
        block_in[415:384] = 32'h89ABCDEF;
        #10;
        // Check W[0] = block[511:480]
        test_pass = 1;
        if (get_W(W, 0) !== 32'hDEADBEEF) test_pass = 0;
        if (get_W(W, 1) !== 32'hCAFEBABE) test_pass = 0;
        if (get_W(W, 2) !== 32'h01234567) test_pass = 0;
        if (get_W(W, 3) !== 32'h89ABCDEF) test_pass = 0;
        if (test_pass)
            $display("PASS: W[0..3] match block_in words directly");
        else begin
            $display("FAIL: W[0..3] do not match block_in words");
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 7: Full schedule verification with arbitrary pattern
        // -------------------------------------------------------
        block_in[511:480] = 32'hDEADBEEF;
        block_in[479:448] = 32'hCAFEBABE;
        block_in[447:416] = 32'h01234567;
        block_in[415:384] = 32'h89ABCDEF;
        block_in[383:352] = 32'hFEDCBA98;
        block_in[351:320] = 32'h76543210;
        block_in[319:288] = 32'hA5A5A5A5;
        block_in[287:256] = 32'h5A5A5A5A;
        block_in[255:224] = 32'hFFFF0000;
        block_in[223:192] = 32'h0000FFFF;
        block_in[191:160] = 32'h12345678;
        block_in[159:128] = 32'h87654321;
        block_in[127:96]  = 32'hABCDABCD;
        block_in[95:64]   = 32'hDCBADCBA;
        block_in[63:32]   = 32'h11223344;
        block_in[31:0]    = 32'h44332211;
        #10;
        compute_expected_W(block_in, W_expected);
        test_pass = 1;
        for (t = 0; t < 64; t = t + 1) begin
            if (get_W(W, t) !== get_W(W_expected, t)) begin
                test_pass = 0;
            end
        end
        if (test_pass)
            $display("PASS: Arbitrary pattern full W schedule");
        else begin
            $display("FAIL: Arbitrary pattern full W schedule");
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 8: Alternating 0xAAAA/0x5555 pattern
        // -------------------------------------------------------
        begin : test8_block
            integer k;
            for (k = 0; k < 16; k = k + 1) begin
                if (k[0] == 0)
                    block_in[511 - k*32 -: 32] = 32'hAAAAAAAA;
                else
                    block_in[511 - k*32 -: 32] = 32'h55555555;
            end
        end
        #10;
        compute_expected_W(block_in, W_expected);
        test_pass = 1;
        for (t = 0; t < 64; t = t + 1) begin
            if (get_W(W, t) !== get_W(W_expected, t)) begin
                test_pass = 0;
            end
        end
        if (test_pass)
            $display("PASS: Alternating 0xAAAA/0x5555 W schedule");
        else begin
            $display("FAIL: Alternating 0xAAAA/0x5555 W schedule");
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 9: Verify W[16] computed correctly
        // W[16] = sigma1(W[14]) + W[9] + sigma0(W[1]) + W[0]
        // -------------------------------------------------------
        block_in = 512'd0;
        block_in[511:480] = 32'h00000001; // W[0]
        block_in[479:448] = 32'h00000002; // W[1]
        block_in[447:416] = 32'h00000003; // W[2]
        block_in[415:384] = 32'h00000004; // W[3]
        block_in[383:352] = 32'h00000005; // W[4]
        block_in[351:320] = 32'h00000006; // W[5]
        block_in[319:288] = 32'h00000007; // W[6]
        block_in[287:256] = 32'h00000008; // W[7]
        block_in[255:224] = 32'h00000009; // W[8]
        block_in[223:192] = 32'h0000000A; // W[9]
        block_in[191:160] = 32'h0000000B; // W[10]
        block_in[159:128] = 32'h0000000C; // W[11]
        block_in[127:96]  = 32'h0000000D; // W[12]
        block_in[95:64]   = 32'h0000000E; // W[13]
        block_in[63:32]   = 32'h0000000F; // W[14]
        block_in[31:0]    = 32'h00000010; // W[15]
        #10;
        begin : test9_block
            reg [31:0] w16_exp;
            w16_exp = sigma1(32'h0000000F) + 32'h0000000A + sigma0(32'h00000002) + 32'h00000001;
            if (get_W(W, 16) === w16_exp)
                $display("PASS: W[16] computed correctly");
            else begin
                $display("FAIL: W[16] expected %h, got %h", w16_exp, get_W(W, 16));
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 10: Verify W[63] for all-ones input
        // -------------------------------------------------------
        block_in = {512{1'b1}};
        #10;
        compute_expected_W(block_in, W_expected);
        if (get_W(W, 63) === get_W(W_expected, 63))
            $display("PASS: W[63] for all-ones input");
        else begin
            $display("FAIL: W[63] for all-ones input: expected %h, got %h",
                     get_W(W_expected, 63), get_W(W, 63));
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
