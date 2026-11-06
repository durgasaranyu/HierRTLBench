`timescale 1ns/1ps

module tb_sha256_top;

    // DUT connections
    reg         clk;
    reg         rst;
    reg         start;
    reg [511:0] block_in;
    wire [255:0] hash_out;
    wire         done;

    // Instantiate DUT
    sha256 uut (
        .clk      (clk),
        .rst      (rst),
        .start    (start),
        .block_in (block_in),
        .hash_out (hash_out),
        .done     (done)
    );

    // Clock generation: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    integer i;
    integer timeout;

    // Task: apply reset for exactly 5 rising edges
    task apply_reset;
        integer cnt;
        begin
            rst   = 1;
            start = 0;
            block_in = 512'b0;
            // Wait 5 rising edges
            for (cnt = 0; cnt < 5; cnt = cnt + 1)
                @(posedge clk);
            @(negedge clk);
            rst = 0;
        end
    endtask

    // Task: pulse start for one clock cycle and wait for done with timeout
    task run_and_wait;
        input [511:0] blk;
        output        timed_out;
        begin
            block_in = blk;
            @(negedge clk);
            start = 1;
            @(posedge clk);
            @(negedge clk);
            start = 0;
            timed_out = 0;
            timeout = 0;
            while (!done && timeout < 5000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (timeout >= 5000)
                timed_out = 1;
            else
                timed_out = 0;
        end
    endtask

    reg timed_out;
    reg [255:0] hash_snapshot;

    initial begin
        // Initialise signals
        rst      = 1;
        start    = 0;
        block_in = 512'b0;

        // Apply synchronous reset for 5 rising edges
        apply_reset;

        // ----------------------------------------------------------------
        // Test 1: done should NOT be asserted right after reset (no start)
        // ----------------------------------------------------------------
        @(negedge clk);
        if (done === 1'b0)
            $display("PASS: done is deasserted after reset (no start)");
        else
            $display("FAIL: done should be deasserted after reset (no start)");

        // ----------------------------------------------------------------
        // Test 2: All-zero block input - done asserts after start
        // ----------------------------------------------------------------
        apply_reset;
        run_and_wait(512'h0, timed_out);
        if (!timed_out)
            $display("PASS: done asserted for all-zero block (no timeout)");
        else
            $display("FAIL: done did not assert for all-zero block (timeout)");

        // ----------------------------------------------------------------
        // Test 3: All-zero block - hash_out non-zero
        //         (SHA-256 of all-zero bits is non-zero)
        // ----------------------------------------------------------------
        hash_snapshot = hash_out;
        if (hash_snapshot !== 256'b0)
            $display("PASS: hash_out is non-zero for all-zero block");
        else
            $display("FAIL: hash_out is zero for all-zero block (unexpected)");

        // ----------------------------------------------------------------
        // Test 4: All-ones block input - done asserts after start
        // ----------------------------------------------------------------
        apply_reset;
        run_and_wait({512{1'b1}}, timed_out);
        if (!timed_out)
            $display("PASS: done asserted for all-ones block (no timeout)");
        else
            $display("FAIL: done did not assert for all-ones block (timeout)");

        // ----------------------------------------------------------------
        // Test 5: All-ones block - hash_out non-zero
        // ----------------------------------------------------------------
        hash_snapshot = hash_out;
        if (hash_snapshot !== 256'b0)
            $display("PASS: hash_out is non-zero for all-ones block");
        else
            $display("FAIL: hash_out is zero for all-ones block (unexpected)");

        // ----------------------------------------------------------------
        // Test 6: Typical SHA-256 padding for empty message
        //   "abc" message block (standard test vector)
        //   block = 0x61626380 followed by zeros and bit-length 24
        // ----------------------------------------------------------------
        apply_reset;
        run_and_wait(
            {32'h61626380, 224'h0, 64'h0000000000000018},
            timed_out
        );
        if (!timed_out)
            $display("PASS: done asserted for abc padded block (no timeout)");
        else
            $display("FAIL: done did not assert for abc padded block (timeout)");

        hash_snapshot = hash_out;
        if (hash_snapshot !== 256'b0)
            $display("PASS: hash_out is non-zero for abc padded block");
        else
            $display("FAIL: hash_out is zero for abc padded block");

        // ----------------------------------------------------------------
        // Test 7: Two consecutive computations - check done pulses again
        //         Use a different block (alternating pattern)
        // ----------------------------------------------------------------
        apply_reset;
        run_and_wait(512'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA, timed_out);
        if (!timed_out)
            $display("PASS: done asserted for alternating-A block (no timeout)");
        else
            $display("FAIL: done did not assert for alternating-A block (timeout)");

        hash_snapshot = hash_out;
        if (hash_snapshot !== 256'b0)
            $display("PASS: hash_out non-zero for alternating-A block");
        else
            $display("FAIL: hash_out zero for alternating-A block");

        // ----------------------------------------------------------------
        // Test 8: Second consecutive computation without intermediate reset
        //         Use 0x5555... pattern
        // ----------------------------------------------------------------
        run_and_wait(512'h55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555, timed_out);
        if (!timed_out)
            $display("PASS: done asserted for 0x55 block second run (no timeout)");
        else
            $display("FAIL: done did not assert for 0x55 block second run (timeout)");

        hash_snapshot = hash_out;
        if (hash_snapshot !== 256'b0)
            $display("PASS: hash_out non-zero for 0x55 block second run");
        else
            $display("FAIL: hash_out zero for 0x55 block second run");

        // ----------------------------------------------------------------
        // Test 9: Max value block (same as all-ones but explicit check of
        //         done de-assertion before start)
        // ----------------------------------------------------------------
        apply_reset;
        @(negedge clk);
        if (done === 1'b0)
            $display("PASS: done deasserted after reset before start");
        else
            $display("FAIL: done should be deasserted after reset before start");

        run_and_wait({512{1'b1}}, timed_out);
        if (!timed_out)
            $display("PASS: done asserted for max-value block (no timeout)");
        else
            $display("FAIL: done did not assert for max-value block (timeout)");

        // ----------------------------------------------------------------
        // Test 10: Reset while computation might be running (robustness)
        // ----------------------------------------------------------------
        // Trigger a new computation then immediately reset
        block_in = 512'hDEADBEEFCAFEBABEDEADBEEFCAFEBABEDEADBEEFCAFEBABEDEADBEEFCAFEBABEDEADBEEFCAFEBABEDEADBEEFCAFEBABEDEADBEEFCAFEBABEDEADBEEFCAFEBABE;
        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;
        // Apply reset after just 2 clocks
        @(posedge clk);
        @(posedge clk);
        apply_reset;
        // Now run a clean computation
        run_and_wait(512'h123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0, timed_out);
        if (!timed_out)
            $display("PASS: done asserted after reset-during-computation recovery");
        else
            $display("FAIL: done did not assert after reset-during-computation recovery");

        hash_snapshot = hash_out;
        if (hash_snapshot !== 256'b0)
            $display("PASS: hash_out non-zero after reset-during-computation recovery");
        else
            $display("FAIL: hash_out zero after reset-during-computation recovery");

        // ----------------------------------------------------------------
        // Finish
        // ----------------------------------------------------------------
        #20;
        $finish;
    end

endmodule
