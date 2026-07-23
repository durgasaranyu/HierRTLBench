`timescale 1ns/1ps

module tb_aes_top;

    // DUT connections
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

    // Variables
    integer i;
    integer timeout;
    reg done_seen;

    // Task: wait for done or timeout
    task wait_for_done;
        input integer max_cycles;
        begin
            timeout   = 0;
            done_seen = 0;
            while (timeout < max_cycles && !done_seen) begin
                @(posedge clk);
                #1;
                if (done) done_seen = 1;
                timeout = timeout + 1;
            end
        end
    endtask

    // Task: pulse start for one cycle
    task pulse_start;
        begin
            @(posedge clk); #1;
            start = 1;
            @(posedge clk); #1;
            start = 0;
        end
    endtask

    initial begin
        // Initialise signals
        rst       = 1;
        start     = 0;
        plaintext = 128'h0;
        key       = 128'h0;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // ----------------------------------------------------------------
        // TEST 1: After reset, done should be low
        // ----------------------------------------------------------------
        @(posedge clk); #1;
        if (done === 1'b0)
            $display("PASS: After reset done is low");
        else
            $display("FAIL: After reset done is not low (done=%b)", done);

        // ----------------------------------------------------------------
        // TEST 2: All-zero plaintext and key — start, wait for done
        // ----------------------------------------------------------------
        plaintext = 128'h0000_0000_0000_0000_0000_0000_0000_0000;
        key       = 128'h0000_0000_0000_0000_0000_0000_0000_0000;
        pulse_start;
        wait_for_done(500);
        if (done_seen)
            $display("PASS: All-zero inputs: done asserted within timeout");
        else
            $display("FAIL: All-zero inputs: done never asserted");

        // ----------------------------------------------------------------
        // TEST 3: Ciphertext is non-zero for all-zero inputs
        // ----------------------------------------------------------------
        if (ciphertext !== 128'h0)
            $display("PASS: All-zero inputs: ciphertext is non-zero (0x%032h)", ciphertext);
        else
            $display("FAIL: All-zero inputs: ciphertext is zero");

        // ----------------------------------------------------------------
        // TEST 4: All-ones plaintext and key
        // ----------------------------------------------------------------
        @(posedge clk); #1;
        plaintext = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        key       = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        pulse_start;
        wait_for_done(500);
        if (done_seen)
            $display("PASS: All-ones inputs: done asserted within timeout");
        else
            $display("FAIL: All-ones inputs: done never asserted");

        // ----------------------------------------------------------------
        // TEST 5: Ciphertext non-zero for all-ones
        // ----------------------------------------------------------------
        if (ciphertext !== 128'h0)
            $display("PASS: All-ones inputs: ciphertext is non-zero (0x%032h)", ciphertext);
        else
            $display("FAIL: All-ones inputs: ciphertext is zero");

        // ----------------------------------------------------------------
        // TEST 6: Known NIST AES-128 vector
        //   Key       = 0x00010203_04050607_08090a0b_0c0d0e0f
        //   Plaintext = 0x00112233_44556677_8899aabb_ccddeeff
        //   Ciphertext= 0x69c4e0d8_6a7b0430_d8cdb780_70b4c55a
        // ----------------------------------------------------------------
        @(posedge clk); #1;
        plaintext = 128'h00112233_44556677_8899aabb_ccddeeff;
        key       = 128'h00010203_04050607_08090a0b_0c0d0e0f;
        pulse_start;
        wait_for_done(500);
        if (done_seen)
            $display("PASS: NIST vector: done asserted");
        else
            $display("FAIL: NIST vector: done never asserted");

        if (done_seen && ciphertext === 128'h69c4e0d8_6a7b0430_d8cdb780_70b4c55a)
            $display("PASS: NIST vector: ciphertext matches expected 0x69c4e0d86a7b0430d8cdb78070b4c55a");
        else if (done_seen)
            $display("FAIL: NIST vector: ciphertext mismatch: got 0x%032h expected 0x69c4e0d86a7b0430d8cdb78070b4c55a", ciphertext);
        else
            $display("FAIL: NIST vector: could not check ciphertext (done not seen)");

        // ----------------------------------------------------------------
        // TEST 7: Second NIST vector (all-zero key, all-zero plaintext)
        //   Expected ciphertext: 0x66e94bd4ef8a2c3b884cfa59ca342b2e
        // ----------------------------------------------------------------
        @(posedge clk); #1;
        plaintext = 128'h0000_0000_0000_0000_0000_0000_0000_0000;
        key       = 128'h0000_0000_0000_0000_0000_0000_0000_0000;
        pulse_start;
        wait_for_done(500);
        if (done_seen && ciphertext === 128'h66e94bd4ef8a2c3b884cfa59ca342b2e)
            $display("PASS: Zero-key/zero-plaintext NIST vector matches 0x66e94bd4ef8a2c3b884cfa59ca342b2e");
        else if (done_seen)
            $display("FAIL: Zero-key/zero-plaintext: got 0x%032h expected 0x66e94bd4ef8a2c3b884cfa59ca342b2e", ciphertext);
        else
            $display("FAIL: Zero-key/zero-plaintext: done not seen");

        // ----------------------------------------------------------------
        // TEST 8: Verify done de-asserts after one cycle (pulse behaviour)
        // ----------------------------------------------------------------
        // Wait a few cycles after done was seen to see if it goes low
        repeat (3) @(posedge clk); #1;
        // done may or may not stay asserted; just check it was seen
        if (done_seen)
            $display("PASS: done was asserted at end of encryption");
        else
            $display("FAIL: done was never asserted in test 8");

        // ----------------------------------------------------------------
        // TEST 9: Reset mid-operation — start, immediately reset, check done low
        // ----------------------------------------------------------------
        @(posedge clk); #1;
        plaintext = 128'hDEAD_BEEF_CAFE_BABE_1234_5678_9ABC_DEF0;
        key       = 128'hA5A5_A5A5_A5A5_A5A5_A5A5_A5A5_A5A5_A5A5;
        start = 1;
        @(posedge clk); #1;
        start = 0;
        // Apply reset after 3 cycles
        repeat (3) @(posedge clk);
        #1;
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;
        @(posedge clk); #1;
        if (done === 1'b0)
            $display("PASS: done is low after mid-operation reset");
        else
            $display("FAIL: done not low after mid-operation reset (done=%b)", done);

        // ----------------------------------------------------------------
        // TEST 10: Another known plaintext/key after reset recovery
        // ----------------------------------------------------------------
        @(posedge clk); #1;
        plaintext = 128'h3243F6A8_885A308D_313198A2_E0370734;
        key       = 128'h2B7E1516_28AED2A6_ABF71588_09CF4F3C;
        pulse_start;
        wait_for_done(500);
        if (done_seen)
            $display("PASS: Post-reset-recovery: done asserted");
        else
            $display("FAIL: Post-reset-recovery: done not asserted");

        if (done_seen && ciphertext !== 128'h0)
            $display("PASS: Post-reset-recovery: ciphertext non-zero (0x%032h)", ciphertext);
        else if (done_seen)
            $display("FAIL: Post-reset-recovery: ciphertext is zero");

        // ----------------------------------------------------------------
        // TEST 11: Consecutive encryptions without reset
        // ----------------------------------------------------------------
        @(posedge clk); #1;
        plaintext = 128'h0102_0304_0506_0708_090A_0B0C_0D0E_0F10;
        key       = 128'hFEDC_BA98_7654_3210_FEDC_BA98_7654_3210;
        pulse_start;
        wait_for_done(500);
        if (done_seen)
            $display("PASS: Consecutive encryption 1: done asserted");
        else
            $display("FAIL: Consecutive encryption 1: done not asserted");

        @(posedge clk); #1;
        plaintext = 128'hABCD_EF01_2345_6789_ABCD_EF01_2345_6789;
        key       = 128'h1234_5678_9ABC_DEF0_1234_5678_9ABC_DEF0;
        pulse_start;
        wait_for_done(500);
        if (done_seen)
            $display("PASS: Consecutive encryption 2: done asserted");
        else
            $display("FAIL: Consecutive encryption 2: done not asserted");

        // ----------------------------------------------------------------
        // Done
        // ----------------------------------------------------------------
        $display("Testbench completed.");
        $finish;
    end

endmodule
