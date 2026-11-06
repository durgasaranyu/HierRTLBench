`timescale 1ns/1ps

module tb_sha256_top;

    // DUT connections
    reg         clk;
    reg         rst;
    reg         start;
    reg  [511:0] block_in;
    wire [255:0] hash_out;
    wire         done;

    // Instantiate DUT
    sha256 uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .block_in(block_in),
        .hash_out(hash_out),
        .done(done)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    integer i;
    integer pass_count;
    integer fail_count;
    integer timeout;

    // Task: wait for done or timeout
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

    // Task: apply reset for 5 rising edges
    task apply_reset;
        begin
            rst = 1;
            start = 0;
            block_in = 512'b0;
            repeat(5) @(posedge clk);
            @(negedge clk);
            rst = 0;
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize signals
        clk      = 0;
        rst      = 0;
        start    = 0;
        block_in = 512'b0;

        // Apply reset for exactly 5 rising edges
        apply_reset;

        // Wait a couple cycles after reset
        repeat(2) @(posedge clk);

        //------------------------------------------------------------
        // Test 1: done should NOT be asserted immediately after reset
        //------------------------------------------------------------
        @(negedge clk);
        if (done === 1'b0) begin
            $display("PASS: After reset, done is deasserted");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After reset, done should be 0 but got %b", done);
            fail_count = fail_count + 1;
        end

        //------------------------------------------------------------
        // Test 2: All-zero block input, pulse start
        //------------------------------------------------------------
        @(negedge clk);
        block_in = 512'h0;
        start    = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        // Wait for done
        wait_for_done(2000);

        if (done === 1'b1) begin
            $display("PASS: done asserted for all-zero block input");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: done not asserted within timeout for all-zero block");
            fail_count = fail_count + 1;
        end

        // Check hash_out non-zero (for zero block, SHA-256 still produces non-zero)
        // Note: actual SHA-256 of all-zeros is well-defined; we just check non-zero here
        if (hash_out !== 256'h0) begin
            $display("PASS: hash_out is non-zero for all-zero block");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: hash_out is zero for all-zero block (unexpected)");
            fail_count = fail_count + 1;
        end

        // Re-apply reset before next test
        apply_reset;
        repeat(2) @(posedge clk);

        //------------------------------------------------------------
        // Test 3: All-ones block input
        //------------------------------------------------------------
        @(negedge clk);
        block_in = {512{1'b1}};
        start    = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        wait_for_done(2000);

        if (done === 1'b1) begin
            $display("PASS: done asserted for all-ones block input");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: done not asserted within timeout for all-ones block");
            fail_count = fail_count + 1;
        end

        if (hash_out !== 256'h0) begin
            $display("PASS: hash_out is non-zero for all-ones block");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: hash_out is zero for all-ones block (unexpected)");
            fail_count = fail_count + 1;
        end

        apply_reset;
        repeat(2) @(posedge clk);

        //------------------------------------------------------------
        // Test 4: Typical SHA-256 padding block (message "abc" padded)
        // Standard SHA-256 padding for "abc" (24 bits) in a 512-bit block
        //------------------------------------------------------------
        @(negedge clk);
        // "abc" = 0x61626380 followed by zeros and length=24
        block_in = {32'h61626380, 224'h0, 32'h0, 192'h0, 64'h18};
        start    = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        wait_for_done(2000);

        if (done === 1'b1) begin
            $display("PASS: done asserted for 'abc' padded block");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: done not asserted within timeout for 'abc' padded block");
            fail_count = fail_count + 1;
        end

        if (hash_out !== 256'h0) begin
            $display("PASS: hash_out is non-zero for 'abc' block");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: hash_out is zero for 'abc' block (unexpected)");
            fail_count = fail_count + 1;
        end

        apply_reset;
        repeat(2) @(posedge clk);

        //------------------------------------------------------------
        // Test 5: Maximum-value block (alternating pattern)
        //------------------------------------------------------------
        @(negedge clk);
        block_in = {16{32'hDEADBEEF}};
        start    = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        wait_for_done(2000);

        if (done === 1'b1) begin
            $display("PASS: done asserted for DEADBEEF pattern block");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: done not asserted within timeout for DEADBEEF pattern");
            fail_count = fail_count + 1;
        end

        apply_reset;
        repeat(2) @(posedge clk);

        //------------------------------------------------------------
        // Test 6: Start pulse width check — only 1 cycle start pulse
        //------------------------------------------------------------
        @(negedge clk);
        block_in = {16{32'hA5A5A5A5}};
        start    = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        // done should not be asserted immediately
        if (done === 1'b0) begin
            $display("PASS: done not immediately set after start");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: done immediately set after start (might be ok if done from prev)");
            // Not necessarily a failure if pipeline
            fail_count = fail_count + 1;
        end

        wait_for_done(2000);

        if (done === 1'b1) begin
            $display("PASS: done asserted after 1-cycle start pulse");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: done not asserted after 1-cycle start pulse");
            fail_count = fail_count + 1;
        end

        apply_reset;
        repeat(2) @(posedge clk);

        //------------------------------------------------------------
        // Test 7: Two consecutive computations
        //------------------------------------------------------------
        @(negedge clk);
        block_in = {16{32'h12345678}};
        start    = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        wait_for_done(2000);

        if (done === 1'b1) begin
            $display("PASS: First of consecutive computations done");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: First of consecutive computations timed out");
            fail_count = fail_count + 1;
        end

        // Apply reset between computations
        apply_reset;
        repeat(2) @(posedge clk);

        @(negedge clk);
        block_in = {16{32'h9ABCDEF0}};
        start    = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        wait_for_done(2000);

        if (done === 1'b1) begin
            $display("PASS: Second of consecutive computations done");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Second of consecutive computations timed out");
            fail_count = fail_count + 1;
        end

        apply_reset;
        repeat(2) @(posedge clk);

        //------------------------------------------------------------
        // Test 8: hash_out stable after done
        //------------------------------------------------------------
        @(negedge clk);
        block_in = {16{32'hFEDCBA98}};
        start    = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        wait_for_done(2000);

        if (done === 1'b1) begin
            begin : check_stable
                reg [255:0] hash_snapshot;
                hash_snapshot = hash_out;
                @(posedge clk);
                @(posedge clk);
                if (hash_out === hash_snapshot) begin
                    $display("PASS: hash_out stable after done asserted");
                    pass_count = pass_count + 1;
                end else begin
                    $display("FAIL: hash_out changed after done (was %h, now %h)", hash_snapshot, hash_out);
                    fail_count = fail_count + 1;
                end
            end
        end else begin
            $display("FAIL: done not asserted, cannot check hash_out stability");
            fail_count = fail_count + 1;
        end

        //------------------------------------------------------------
        // Test 9: done deasserts after reset
        //------------------------------------------------------------
        apply_reset;
        @(negedge clk);

        if (done === 1'b0) begin
            $display("PASS: done deasserted after reset");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: done still asserted after reset");
            fail_count = fail_count + 1;
        end

        //------------------------------------------------------------
        // Test 10: block_in with single bit set
        //------------------------------------------------------------
        apply_reset;
        repeat(2) @(posedge clk);

        @(negedge clk);
        block_in = 512'h1;
        start    = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        wait_for_done(2000);

        if (done === 1'b1) begin
            $display("PASS: done asserted for single-bit block input");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: done not asserted for single-bit block input");
            fail_count = fail_count + 1;
        end

        //------------------------------------------------------------
        // Summary
        //------------------------------------------------------------
        $display("=======================");
        $display("TOTAL PASS: %0d", pass_count);
        $display("TOTAL FAIL: %0d", fail_count);
        $display("=======================");

        $finish;
    end

endmodule
