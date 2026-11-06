`timescale 1ns/1ps

module tb_aes_top;

    // DUT I/O
    reg         clk;
    reg         rst;
    reg         start;
    reg  [127:0] plaintext;
    reg  [127:0] key;
    wire [127:0] ciphertext;
    wire         done;

    // Instantiate DUT
    aes128 uut (
        .clk       (clk),
        .rst       (rst),
        .start     (start),
        .plaintext (plaintext),
        .key       (key),
        .ciphertext(ciphertext),
        .done      (done)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Timeout counter
    integer timeout;
    integer pass_count;
    integer fail_count;

    // Task: wait for done with timeout
    task wait_for_done;
        input [31:0] max_cycles;
        begin
            timeout = 0;
            while (!done && timeout < max_cycles) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
        end
    endtask

    // Task: apply reset
    task apply_reset;
        integer i;
        begin
            rst = 1;
            start = 0;
            for (i = 0; i < 5; i = i + 1)
                @(posedge clk);
            rst = 0;
            @(negedge clk);
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize
        rst       = 1;
        start     = 0;
        plaintext = 128'h0;
        key       = 128'h0;

        // Apply reset for exactly 5 rising edges
        apply_reset;

        // ----------------------------------------------------------------
        // Test 1: All-zero plaintext and key, check done asserts
        // ----------------------------------------------------------------
        plaintext = 128'h00000000000000000000000000000000;
        key       = 128'h00000000000000000000000000000000;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait_for_done(500);

        if (done) begin
            $display("PASS: Test1 - done asserts for all-zero plaintext/key");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test1 - done did not assert for all-zero plaintext/key");
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 2: All-zero plaintext/key ciphertext is non-zero
        // ----------------------------------------------------------------
        if (ciphertext !== 128'h0) begin
            $display("PASS: Test2 - ciphertext non-zero for all-zero inputs");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test2 - ciphertext is zero for all-zero inputs (suspicious)");
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Reset between tests
        // ----------------------------------------------------------------
        apply_reset;

        // ----------------------------------------------------------------
        // Test 3: All-ones plaintext and key
        // ----------------------------------------------------------------
        plaintext = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        key       = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait_for_done(500);

        if (done) begin
            $display("PASS: Test3 - done asserts for all-ones plaintext/key");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test3 - done did not assert for all-ones plaintext/key");
            fail_count = fail_count + 1;
        end

        // Test 4: All-ones ciphertext non-zero
        if (ciphertext !== 128'h0) begin
            $display("PASS: Test4 - ciphertext non-zero for all-ones inputs");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test4 - ciphertext is zero for all-ones inputs");
            fail_count = fail_count + 1;
        end

        apply_reset;

        // ----------------------------------------------------------------
        // Test 5: Known NIST AES-128 test vector
        // Plaintext:  00112233445566778899aabbccddeeff
        // Key:        000102030405060708090a0b0c0d0e0f
        // Ciphertext: 69c4e0d86a7b04300d8a8b41b570f07f  (known answer)
        // ----------------------------------------------------------------
        plaintext = 128'h00112233445566778899aabbccddeeff;
        key       = 128'h000102030405060708090a0b0c0d0e0f;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait_for_done(500);

        if (done) begin
            $display("PASS: Test5 - done asserts for NIST vector");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test5 - done did not assert for NIST vector");
            fail_count = fail_count + 1;
        end

        // Test 6: Check NIST known answer
        if (ciphertext === 128'h69c4e0d86a7b04300d8a8b41b570f07f) begin
            $display("PASS: Test6 - NIST AES-128 ciphertext correct");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test6 - NIST AES-128 ciphertext incorrect, got %h", ciphertext);
            fail_count = fail_count + 1;
        end

        apply_reset;

        // ----------------------------------------------------------------
        // Test 7: Max-value plaintext, zero key
        // ----------------------------------------------------------------
        plaintext = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        key       = 128'h00000000000000000000000000000000;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait_for_done(500);

        if (done) begin
            $display("PASS: Test7 - done asserts for max plaintext, zero key");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test7 - done did not assert for max plaintext, zero key");
            fail_count = fail_count + 1;
        end

        // Non-zero ciphertext
        if (ciphertext !== 128'h0) begin
            $display("PASS: Test7b - ciphertext non-zero for max plaintext, zero key");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test7b - ciphertext zero for max plaintext, zero key");
            fail_count = fail_count + 1;
        end

        apply_reset;

        // ----------------------------------------------------------------
        // Test 8: Different results for different keys (same plaintext)
        // ----------------------------------------------------------------
        reg [127:0] ct_a, ct_b;

        plaintext = 128'hdeadbeefcafebabe0123456789abcdef;
        key       = 128'h0f1e2d3c4b5a69788796a5b4c3d2e1f0;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        wait_for_done(500);
        ct_a = ciphertext;

        if (done) begin
            $display("PASS: Test8a - done asserts for custom vector A");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test8a - done did not assert for custom vector A");
            fail_count = fail_count + 1;
        end

        apply_reset;

        plaintext = 128'hdeadbeefcafebabe0123456789abcdef;
        key       = 128'h1f2e3d4c5b6a79889786a5b4c3d2e1f0;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        wait_for_done(500);
        ct_b = ciphertext;

        if (done) begin
            $display("PASS: Test8b - done asserts for custom vector B");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test8b - done did not assert for custom vector B");
            fail_count = fail_count + 1;
        end

        if (ct_a !== ct_b) begin
            $display("PASS: Test8c - different keys produce different ciphertexts");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test8c - different keys produced same ciphertext");
            fail_count = fail_count + 1;
        end

        apply_reset;

        // ----------------------------------------------------------------
        // Test 9: start=0 after reset, done should not assert
        // ----------------------------------------------------------------
        plaintext = 128'h12345678;
        key       = 128'h87654321;
        // Don't pulse start
        repeat(20) @(posedge clk);

        if (!done) begin
            $display("PASS: Test9 - done does not assert without start");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test9 - done asserted without start");
            fail_count = fail_count + 1;
        end

        apply_reset;

        // ----------------------------------------------------------------
        // Test 10: back-to-back encryption (second start after first done)
        // ----------------------------------------------------------------
        plaintext = 128'haabbccddeeff00112233445566778899;
        key       = 128'h00ff00ff00ff00ff00ff00ff00ff00ff;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        wait_for_done(500);

        if (done) begin
            $display("PASS: Test10a - first encryption done in back-to-back test");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test10a - first encryption not done in back-to-back test");
            fail_count = fail_count + 1;
        end

        // Second encryption
        apply_reset;
        plaintext = 128'h11223344556677889900aabbccddeeff;
        key       = 128'hff00ff00ff00ff00ff00ff00ff00ff00;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        wait_for_done(500);

        if (done) begin
            $display("PASS: Test10b - second encryption done in back-to-back test");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test10b - second encryption not done in back-to-back test");
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Summary
        // ----------------------------------------------------------------
        $display("=== Test Summary: %0d PASS, %0d FAIL ===", pass_count, fail_count);

        $finish;
    end

endmodule
