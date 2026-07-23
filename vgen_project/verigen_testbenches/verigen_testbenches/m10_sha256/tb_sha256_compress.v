`timescale 1ns/1ps

module tb_sha256_compress;

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

    // Clock (not strictly needed for combinational DUT, but required by spec)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset signal (required by spec, even though DUT is combinational)
    reg rst;
    integer i;

    // Expected output helper
    reg [255:0] expected_out;

    // Test pass/fail counter
    integer pass_count;
    integer fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst = 1;

        // Assert reset for exactly 5 rising clock edges
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        @(negedge clk);

        // -------------------------------------------------------
        // Test 1: All-zero inputs
        // -------------------------------------------------------
        H_in = 256'h0;
        W    = 2048'h0;
        #2;
        // H_out = {H_in, W} => upper 256 bits of {256'h0, 2048'h0}
        // assign H_out = {H_in, W} but H_out is 256-bit wide
        // {H_in[255:0], W[2047:0]} is 2304 bits; Verilog truncates to 256 lsb
        // Actually {H_in, W} where H_in=256b and W=2048b => 2304b, truncated to 256b => lower 256 bits = W[255:0]
        expected_out = W[255:0];
        if (H_out === expected_out) begin
            $display("PASS: All-zero inputs => H_out = %h", H_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: All-zero inputs => H_out = %h, expected = %h", H_out, expected_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 2: All-ones inputs
        // -------------------------------------------------------
        H_in = {256{1'b1}};
        W    = {2048{1'b1}};
        #2;
        expected_out = W[255:0]; // lower 256 bits of concatenation
        if (H_out === expected_out) begin
            $display("PASS: All-ones inputs => H_out = %h", H_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: All-ones inputs => H_out = %h, expected = %h", H_out, expected_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 3: H_in = all-ones, W = all-zeros
        // -------------------------------------------------------
        H_in = {256{1'b1}};
        W    = 2048'h0;
        #2;
        expected_out = W[255:0];
        if (H_out === expected_out) begin
            $display("PASS: H_in=all-ones W=all-zeros => H_out = %h", H_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: H_in=all-ones W=all-zeros => H_out = %h, expected = %h", H_out, expected_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 4: H_in = all-zeros, W = all-ones
        // -------------------------------------------------------
        H_in = 256'h0;
        W    = {2048{1'b1}};
        #2;
        expected_out = W[255:0];
        if (H_out === expected_out) begin
            $display("PASS: H_in=all-zeros W=all-ones => H_out = %h", H_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: H_in=all-zeros W=all-ones => H_out = %h, expected = %h", H_out, expected_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 5: SHA-256 initial hash values in H_in, known W pattern
        // -------------------------------------------------------
        H_in = 256'h6a09e667bb67ae853c6ef372a54ff53a510e527f9b05688c1f83d9ab5be0cd19;
        W    = 2048'hdeadbeef_cafebabe_12345678_deadbeef_cafebabe_12345678_deadbeef_cafebabe_12345678_deadbeef_cafebabe_12345678_deadbeef_cafebabe_12345678_deadbeef_cafebabe_12345678_deadbeef_cafebabe_12345678_deadbeef_cafebabe_12345678_deadbeef_cafebabe_12345678_deadbeef_cafebabe_12345678_deadbeef_cafebabe_12345678_deadbeef_cafebabe_12345678_deadbeef_cafebabe_12345678_deadbeef_cafebabe_12345678_deadbeef_cafebabe_12345678_deadbeef_cafebabe_12345678;
        #2;
        expected_out = W[255:0];
        if (H_out === expected_out) begin
            $display("PASS: SHA-256 init H + patterned W => H_out = %h", H_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: SHA-256 init H + patterned W => H_out = %h, expected = %h", H_out, expected_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 6: W[255:0] = known value, H_in arbitrary
        // -------------------------------------------------------
        H_in = 256'hAABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899;
        W    = 2048'h0;
        W[255:0] = 256'hDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF;
        #2;
        expected_out = 256'hDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF;
        if (H_out === expected_out) begin
            $display("PASS: W[255:0]=DEADBEEF pattern => H_out = %h", H_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: W[255:0]=DEADBEEF pattern => H_out = %h, expected = %h", H_out, expected_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 7: Maximum-value inputs (same as all-ones, verify again with explicit max)
        // -------------------------------------------------------
        H_in = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        W    = {2048{1'b1}};
        #2;
        expected_out = {256{1'b1}};
        if (H_out === expected_out) begin
            $display("PASS: Maximum-value inputs => H_out = %h", H_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Maximum-value inputs => H_out = %h, expected = %h", H_out, expected_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 8: Alternating pattern in W lower 256 bits
        // -------------------------------------------------------
        H_in = 256'h0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF;
        W    = 2048'h0;
        W[255:0] = 256'hA5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5;
        #2;
        expected_out = 256'hA5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5;
        if (H_out === expected_out) begin
            $display("PASS: Alternating 0xA5 pattern in W[255:0] => H_out = %h", H_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Alternating 0xA5 pattern in W[255:0] => H_out = %h, expected = %h", H_out, expected_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 9: Single bit set in W[0]
        // -------------------------------------------------------
        H_in = 256'h0;
        W    = 2048'h0;
        W[0] = 1'b1;
        #2;
        expected_out = 256'h1; // W[255:0] = 256'h1
        if (H_out === expected_out) begin
            $display("PASS: Single bit W[0]=1 => H_out = %h", H_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Single bit W[0]=1 => H_out = %h, expected = %h", H_out, expected_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 10: Single bit set in W[255]
        // -------------------------------------------------------
        H_in = 256'h0;
        W    = 2048'h0;
        W[255] = 1'b1;
        #2;
        expected_out = 256'h8000000000000000000000000000000000000000000000000000000000000000;
        if (H_out === expected_out) begin
            $display("PASS: Single bit W[255]=1 => H_out = %h", H_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Single bit W[255]=1 => H_out = %h, expected = %h", H_out, expected_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        $display("------------------------------------------");
        $display("Tests complete: %0d passed, %0d failed", pass_count, fail_count);
        $display("------------------------------------------");

        $finish;
    end

endmodule
