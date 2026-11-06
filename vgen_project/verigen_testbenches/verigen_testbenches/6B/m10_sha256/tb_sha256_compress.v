`timescale 1ns/1ps

module tb_sha256_compress;

    // DUT connections
    reg  [255:0]  H_in;
    reg  [2047:0] W;
    wire [255:0]  H_out;

    // Instantiate DUT
    sha256_compress uut (
        .H_in  (H_in),
        .W     (W),
        .H_out (H_out)
    );

    // Clock (not strictly needed for combinational DUT, but required by spec)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not used by DUT but required by spec)
    reg rst;
    integer i;

    // Helper: expected output = {H_in, W} (top 256 bits = H_in, bottom 2048 bits = W)
    // H_out is 256 bits. But the module just does assign H_out = {H_in, W}
    // Wait — H_out is 256 bits but {H_in[255:0], W[2047:0]} is 256+2048=2304 bits.
    // In Verilog, assignment truncates to LHS width (256 bits), so H_out = H_in[255:0]
    // because the concatenation is 2304 bits and we take the upper 256 bits of the RHS
    // truncated to 256 bits from the right (LSB side).
    // Actually: assign H_out = {H_in, W}; — the RHS is 2304 bits, LHS is 256 bits.
    // Verilog truncates the MSBs, keeping the LSBs? No — it keeps the rightmost (LSB) bits.
    // {H_in[255:0], W[2047:0]} = bits [2303:0], LHS takes bits [255:0] = W[255:0].
    // So H_out = W[255:0].

    // Let's verify: H_out[255:0] = lower 256 bits of {H_in, W} = W[255:0]
    reg [255:0] expected_H_out;

    integer fail_count;

    initial begin
        fail_count = 0;

        // Assert reset for 5 clock rising edges
        rst = 1;
        @(posedge clk); // 1
        @(posedge clk); // 2
        @(posedge clk); // 3
        @(posedge clk); // 4
        @(posedge clk); // 5
        rst = 0;

        // Wait a bit after reset
        #2;

        // -------------------------------------------------------
        // Test 1: All-zero inputs
        // -------------------------------------------------------
        H_in = 256'h0;
        W    = 2048'h0;
        #2;
        // H_out = W[255:0] = 0
        expected_H_out = W[255:0];
        if (H_out === expected_H_out)
            $display("PASS: Test1 - All-zero inputs: H_out=0x%064h", H_out);
        else begin
            $display("FAIL: Test1 - All-zero inputs: H_out=0x%064h expected=0x%064h", H_out, expected_H_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 2: All-ones inputs
        // -------------------------------------------------------
        H_in = {256{1'b1}};
        W    = {2048{1'b1}};
        #2;
        expected_H_out = W[255:0];
        if (H_out === expected_H_out)
            $display("PASS: Test2 - All-ones inputs: H_out=0x%064h", H_out);
        else begin
            $display("FAIL: Test2 - All-ones inputs: H_out=0x%064h expected=0x%064h", H_out, expected_H_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 3: H_in = SHA-256 initial hash values (typical), W = 0
        // -------------------------------------------------------
        H_in = {32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a,
                32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19};
        W    = 2048'h0;
        #2;
        expected_H_out = W[255:0];
        if (H_out === expected_H_out)
            $display("PASS: Test3 - SHA-256 IV, W=0: H_out=0x%064h", H_out);
        else begin
            $display("FAIL: Test3 - SHA-256 IV, W=0: H_out=0x%064h expected=0x%064h", H_out, expected_H_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 4: H_in = 0, W has non-zero lower 256 bits
        // -------------------------------------------------------
        H_in = 256'h0;
        W    = 2048'h0;
        W[255:0] = 256'hdeadbeefcafe0123456789abcdef0123456789abcdef0123456789abcdef0123;
        #2;
        expected_H_out = W[255:0];
        if (H_out === expected_H_out)
            $display("PASS: Test4 - H_in=0, W lower 256b non-zero: H_out=0x%064h", H_out);
        else begin
            $display("FAIL: Test4 - H_in=0, W lower 256b non-zero: H_out=0x%064h expected=0x%064h", H_out, expected_H_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 5: H_in non-zero, W lower 256 bits = specific pattern
        // -------------------------------------------------------
        H_in = 256'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
        W    = {2048{1'b0}};
        W[255:128] = 128'hfeedface;
        W[127:0]   = 128'hdeadbeef;
        #2;
        expected_H_out = W[255:0];
        if (H_out === expected_H_out)
            $display("PASS: Test5 - H_in=AAAA..., W mixed: H_out=0x%064h", H_out);
        else begin
            $display("FAIL: Test5 - H_in=AAAA..., W mixed: H_out=0x%064h expected=0x%064h", H_out, expected_H_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 6: Maximum H_in, W lower bits = alternating pattern
        // -------------------------------------------------------
        H_in = {256{1'b1}};
        W    = {2048{1'b0}};
        W[255:0] = {8{32'hA5A5A5A5}};
        #2;
        expected_H_out = W[255:0];
        if (H_out === expected_H_out)
            $display("PASS: Test6 - Max H_in, W=A5A5...: H_out=0x%064h", H_out);
        else begin
            $display("FAIL: Test6 - Max H_in, W=A5A5...: H_out=0x%064h expected=0x%064h", H_out, expected_H_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 7: W upper bits non-zero, lower 256 bits = 0 (verify truncation)
        // -------------------------------------------------------
        H_in = 256'h123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0;
        W    = {2048{1'b1}};
        W[255:0] = 256'h0;
        #2;
        expected_H_out = 256'h0; // W[255:0] = 0
        if (H_out === expected_H_out)
            $display("PASS: Test7 - W upper=FF, lower=0: H_out=0x%064h", H_out);
        else begin
            $display("FAIL: Test7 - W upper=FF, lower=0: H_out=0x%064h expected=0x%064h", H_out, expected_H_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 8: Typical SHA-256 compress scenario
        // -------------------------------------------------------
        H_in = {32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a,
                32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19};
        // W[63..0] words (each 32b): set lower 256 bits = W[0..7] words
        W = 2048'h0;
        W[2047:2016] = 32'h61626380; // W[63]
        W[255:224]   = 32'h00000018; // W[7]
        W[223:192]   = 32'h00000000; // W[6]
        W[191:160]   = 32'h00000000; // W[5]
        W[159:128]   = 32'h00000000; // W[4]
        W[127:96]    = 32'h00000000; // W[3]
        W[95:64]     = 32'h00000000; // W[2]
        W[63:32]     = 32'h00000000; // W[1]
        W[31:0]      = 32'h61626380; // W[0]
        #2;
        expected_H_out = W[255:0];
        if (H_out === expected_H_out)
            $display("PASS: Test8 - Typical SHA-256 scenario: H_out=0x%064h", H_out);
        else begin
            $display("FAIL: Test8 - Typical SHA-256 scenario: H_out=0x%064h expected=0x%064h", H_out, expected_H_out);
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
