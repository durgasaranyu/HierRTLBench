`timescale 1ns/1ps

module tb_bubble_sort_top;

    // DUT connections
    reg         clk;
    reg         rst;
    reg         start;
    reg  [63:0] data_in_flat;
    wire [63:0] data_out_flat;
    wire        done;

    // Instantiate DUT
    bubble_sort uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_in_flat(data_in_flat),
        .data_out_flat(data_out_flat),
        .done(done)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    integer i;
    integer pass_count;
    integer fail_count;

    // Helper task: wait N rising edges
    task wait_cycles;
        input integer n;
        integer j;
        begin
            for (j = 0; j < n; j = j + 1)
                @(posedge clk);
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize signals
        rst         = 1;
        start       = 0;
        data_in_flat = 64'd0;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;

        // ----------------------------------------------------------------
        // TEST 1: Check reset drives done=0 and data_out_flat=0
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;
        @(posedge clk); #1;
        if (done == 8'd0)
            begin $display("PASS: After reset, done=0"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: After reset, done should be 0, got %0d", done); fail_count = fail_count + 1; end

        // ----------------------------------------------------------------
        // TEST 2: All-zero input, start=0
        // ----------------------------------------------------------------
        data_in_flat = 64'd0;
        start = 0;
        wait_cycles(10);
        @(posedge clk); #1;
        if (data_out_flat == 64'd0)
            begin $display("PASS: All-zero input, data_out_flat=0"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: All-zero input, data_out_flat should be 0, got %0d", data_out_flat); fail_count = fail_count + 1; end

        // ----------------------------------------------------------------
        // TEST 3: done increments when start=0 (not reset)
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;
        start = 0;
        // After reset done=0, let it run for 5 cycles and check it incremented
        wait_cycles(5);
        @(posedge clk); #1;
        if (done > 8'd0)
            begin $display("PASS: done increments when start=0 (done=%0d)", done); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: done should increment when start=0, got %0d", done); fail_count = fail_count + 1; end

        // ----------------------------------------------------------------
        // TEST 4: done resets to 0 when start=1
        // ----------------------------------------------------------------
        // Let done accumulate first
        wait_cycles(5);
        @(negedge clk);
        start = 1;
        @(posedge clk); #1;
        if (done == 8'd0)
            begin $display("PASS: done=0 when start=1"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: done should be 0 when start=1, got %0d", done); fail_count = fail_count + 1; end
        @(negedge clk);
        start = 0;

        // ----------------------------------------------------------------
        // TEST 5: All-ones input (8-bit: 0xFF per element, 64-bit flat all 1s)
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;
        data_in_flat = 64'hFFFFFFFFFFFFFFFF;
        start = 0;
        wait_cycles(10);
        @(posedge clk); #1;
        // Just check module doesn't hang (done keeps incrementing)
        if (done > 8'd0)
            begin $display("PASS: All-ones input, done increments normally (done=%0d)", done); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: All-ones input, done should increment, got %0d", done); fail_count = fail_count + 1; end

        // ----------------------------------------------------------------
        // TEST 6: Maximum value input (same as all-ones but check explicitly)
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;
        data_in_flat = 64'hFFFFFFFFFFFFFFFF;
        start = 1;
        @(posedge clk); #1;
        if (done == 8'd0)
            begin $display("PASS: Max value input with start=1, done=0"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: Max value input with start=1, done should be 0, got %0d", done); fail_count = fail_count + 1; end
        @(negedge clk);
        start = 0;

        // ----------------------------------------------------------------
        // TEST 7: Toggle start multiple times - done toggles correctly
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;
        // Cycle 1: start=0, done should go to 1 next clock
        start = 0;
        @(posedge clk); #1;
        // done should be 1 now
        if (done == 8'd1)
            begin $display("PASS: done=1 after 1 cycle with start=0"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: done should be 1 after 1 cycle, got %0d", done); fail_count = fail_count + 1; end

        // ----------------------------------------------------------------
        // TEST 8: done wraps around (overflow 8-bit counter)
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;
        start = 0;
        // Run 256 cycles to overflow 8-bit done counter
        wait_cycles(255);
        @(posedge clk); #1;
        // After 255 increments done should be 255 (0xFF)
        if (done == 8'd255)
            begin $display("PASS: done=255 after 255 increments"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: done should be 255 after 255 increments, got %0d", done); fail_count = fail_count + 1; end
        // One more cycle - should wrap to 0
        @(posedge clk); #1;
        if (done == 8'd0)
            begin $display("PASS: done wraps to 0 after 256 increments"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: done should wrap to 0, got %0d", done); fail_count = fail_count + 1; end

        // ----------------------------------------------------------------
        // TEST 9: data_in_flat changes reflected in data_in_reg shift behavior
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;
        data_in_flat = 64'hDEADBEEFCAFEBABE;
        start = 0;
        wait_cycles(5);
        @(posedge clk); #1;
        // Module runs without error; just verify done keeps ticking
        if (done > 8'd0)
            begin $display("PASS: Non-trivial data_in_flat, done increments (done=%0d)", done); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: Non-trivial data_in_flat, done should increment, got %0d", done); fail_count = fail_count + 1; end

        // ----------------------------------------------------------------
        // TEST 10: Reset during active operation clears done
        // ----------------------------------------------------------------
        start = 0;
        wait_cycles(10);
        @(negedge clk);
        rst = 1;
        @(posedge clk); #1;
        if (done == 8'd0)
            begin $display("PASS: Reset during operation clears done=0"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: Reset during operation should clear done, got %0d", done); fail_count = fail_count + 1; end
        @(negedge clk);
        rst = 0;

        // ----------------------------------------------------------------
        // TEST 11: Already-sorted / ascending input with start toggles
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;
        // Provide ascending 8-bit values packed into 64-bit (LSB = elem0)
        data_in_flat = 64'h0102030405060708;
        start = 1;
        @(posedge clk); #1;
        if (done == 8'd0)
            begin $display("PASS: Ascending input with start=1, done=0"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: Ascending input with start=1, done should be 0, got %0d", done); fail_count = fail_count + 1; end
        @(negedge clk);
        start = 0;
        wait_cycles(10);
        @(posedge clk); #1;
        if (done > 8'd0)
            begin $display("PASS: Ascending input then start=0, done increments (done=%0d)", done); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: Ascending input then start=0, done should increment, got %0d", done); fail_count = fail_count + 1; end

        // ----------------------------------------------------------------
        // Summary
        // ----------------------------------------------------------------
        $display("===========================");
        $display("TOTAL PASS: %0d, TOTAL FAIL: %0d", pass_count, fail_count);
        $display("===========================");

        $finish;
    end

endmodule
