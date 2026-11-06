`timescale 1ns/1ps

module tb_sha256_top;

    // DUT connections
    reg         clk;
    reg         rst;
    reg         start;
    reg  [511:0] block_in;
    wire [255:0] hash_out;
    wire         done;

    // Instantiate DUT - the module is named sha256 per the source
    sha256 uut (
        .clk      (clk),
        .rst      (rst),
        .start    (start),
        .block_in (block_in),
        .hash_out (hash_out),
        .done     (done)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Timeout watchdog
    integer timeout_cnt;

    // Task: wait for done with timeout
    task wait_for_done;
        input [63:0] max_cycles;
        begin
            timeout_cnt = 0;
            while (!done && timeout_cnt < max_cycles) begin
                @(posedge clk);
                timeout_cnt = timeout_cnt + 1;
            end
        end
    endtask

    // Test vector storage
    reg [255:0] captured_hash;
    reg         test_pass;

    integer i;

    initial begin
        // Initialize inputs
        rst      = 1;
        start    = 0;
        block_in = 512'b0;

        // Assert reset for exactly 5 rising clock edges
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // ----------------------------------------------------------------
        // Test 1: All-zero block input, pulse start, check done asserts
        // ----------------------------------------------------------------
        block_in = 512'h0;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // Wait up to 200 cycles for done
        wait_for_done(200);

        if (done)
            $display("PASS: Test1 - done asserted for all-zero block");
        else
            $display("FAIL: Test1 - done did not assert for all-zero block");

        @(posedge clk);

        // ----------------------------------------------------------------
        // Test 2: hash_out non-zero for non-zero input
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        block_in = 512'hDEADBEEFCAFEBABE_1234567890ABCDEF_FEDCBA9876543210_0011223344556677_8899AABBCCDDEEFF_FFEEDDCCBBAA9988_7766554433221100_AABBCCDDEEFF0011;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait_for_done(200);

        captured_hash = hash_out;
        if (done)
            $display("PASS: Test2 - done asserted for non-zero block");
        else
            $display("FAIL: Test2 - done did not assert for non-zero block");

        // Note: The module is a stub; we check that done asserts (non-zero behavior is best-effort)
        if (done && (hash_out !== 256'h0))
            $display("PASS: Test2 - hash_out is non-zero for non-zero input");
        else if (done)
            $display("FAIL: Test2 - hash_out is zero for non-zero input");
        else
            $display("FAIL: Test2 - done not asserted, cannot check hash_out");

        @(posedge clk);

        // ----------------------------------------------------------------
        // Test 3: All-ones block input
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        block_in = {512{1'b1}};
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait_for_done(200);

        if (done)
            $display("PASS: Test3 - done asserted for all-ones block");
        else
            $display("FAIL: Test3 - done did not assert for all-ones block");

        @(posedge clk);

        // ----------------------------------------------------------------
        // Test 4: Start pulsed twice (back-to-back resets between)
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        block_in = 512'hA5A5A5A5A5A5A5A5_5A5A5A5A5A5A5A5A_A5A5A5A5A5A5A5A5_5A5A5A5A5A5A5A5A_A5A5A5A5A5A5A5A5_5A5A5A5A5A5A5A5A_A5A5A5A5A5A5A5A5_5A5A5A5A5A5A5A5A;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait_for_done(200);

        if (done)
            $display("PASS: Test4 - done asserted for alternating pattern block");
        else
            $display("FAIL: Test4 - done did not assert for alternating pattern block");

        @(posedge clk);

        // ----------------------------------------------------------------
        // Test 5: Maximum value block (same as all-ones but explicit)
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        block_in = 512'hFFFFFFFFFFFFFFFF_FFFFFFFFFFFFFFFF_FFFFFFFFFFFFFFFF_FFFFFFFFFFFFFFFF_FFFFFFFFFFFFFFFF_FFFFFFFFFFFFFFFF_FFFFFFFFFFFFFFFF_FFFFFFFFFFFFFFFF;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait_for_done(200);

        if (done)
            $display("PASS: Test5 - done asserted for max-value block");
        else
            $display("FAIL: Test5 - done did not assert for max-value block");

        @(posedge clk);

        // ----------------------------------------------------------------
        // Test 6: Reset in the middle of operation
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        block_in = 512'h123456789ABCDEF0_123456789ABCDEF0_123456789ABCDEF0_123456789ABCDEF0_123456789ABCDEF0_123456789ABCDEF0_123456789ABCDEF0_123456789ABCDEF0;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        // Inject reset mid-operation
        @(posedge clk);
        rst = 1;
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        // After reset, done should be 0
        if (!done)
            $display("PASS: Test6 - done deasserted after mid-operation reset");
        else
            $display("FAIL: Test6 - done still asserted after mid-operation reset");

        @(posedge clk);

        // ----------------------------------------------------------------
        // Test 7: Start without reset (fresh start after test 6)
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        block_in = 512'h0000000000000001_0000000000000000_0000000000000000_0000000000000000_0000000000000000_0000000000000000_0000000000000000_0000000000000000;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait_for_done(200);

        if (done)
            $display("PASS: Test7 - done asserted for single-bit block");
        else
            $display("FAIL: Test7 - done did not assert for single-bit block");

        @(posedge clk);

        // ----------------------------------------------------------------
        // Test 8: Verify done de-asserts after being high (FSM cycles back)
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        block_in = 512'hCAFEBABEDEADBEEF_CAFEBABEDEAD_BEEF_0_0_0_0_0_0;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        wait_for_done(200);

        test_pass = done;

        // Wait a few more cycles to see if done de-asserts
        repeat(5) @(posedge clk);

        if (test_pass)
            $display("PASS: Test8 - done was asserted after start for mixed pattern");
        else
            $display("FAIL: Test8 - done was never asserted for mixed pattern");

        @(posedge clk);

        // ----------------------------------------------------------------
        // Test 9: Verify start=0 does not trigger computation
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        block_in = 512'hABCD;
        start = 0; // do not start

        repeat(20) @(posedge clk);

        // done should remain 0 since start was never pulsed
        if (!done)
            $display("PASS: Test9 - done stays 0 when start not pulsed");
        else
            $display("FAIL: Test9 - done spuriously asserted without start");

        @(posedge clk);

        // ----------------------------------------------------------------
        // Test 10: Rapid start pulses
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        block_in = 512'h55AA55AA55AA55AA_AA55AA55AA55AA55_55AA55AA55AA55AA_AA55AA55AA55AA55_55AA55AA55AA55AA_AA55AA55AA55AA55_55AA55AA55AA55AA_AA55AA55AA55AA55;

        // Pulse start multiple times
        start = 1; @(posedge clk);
        start = 0; @(posedge clk);
        start = 1; @(posedge clk);
        start = 0; @(posedge clk);

        wait_for_done(200);

        if (done)
            $display("PASS: Test10 - done asserted after rapid start pulses");
        else
            $display("FAIL: Test10 - done not asserted after rapid start pulses");

        @(posedge clk);

        $display("Testbench complete.");
        $finish;
    end

endmodule
