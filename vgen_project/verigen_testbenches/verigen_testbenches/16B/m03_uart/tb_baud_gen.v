`timescale 1ns/1ps

module tb_baud_gen;

    // Parameters for DUT (small values for fast simulation)
    parameter CLK_FREQ  = 50;
    parameter BAUD_RATE = 5;
    // Expected period in cycles
    parameter EXPECTED_PERIOD = CLK_FREQ / BAUD_RATE; // = 10

    // DUT ports
    reg  clk;
    reg  rst;
    wire tick;

    // Instantiate DUT
    baud_gen #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uut (
        .clk (clk),
        .rst (rst),
        .tick(tick)
    );

    // Clock generation: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Helpers
    integer tick_count;
    integer cycle_count;
    integer i;
    integer pass_count;
    integer fail_count;
    integer measured_period;
    integer last_tick_cycle;
    integer current_cycle;

    // Task: count rising edges of clk
    // We'll use a free-running cycle counter
    integer free_cycle;
    always @(posedge clk) begin
        free_cycle = free_cycle + 1;
    end

    initial begin
        // Init
        rst        = 1;
        free_cycle = 0;
        pass_count = 0;
        fail_count = 0;

        // -------------------------------------------------------
        // Reset for exactly 5 rising edges
        // -------------------------------------------------------
        repeat(5) @(posedge clk);
        rst = 0;

        // -------------------------------------------------------
        // Test 1: During reset, tick must be 0
        // -------------------------------------------------------
        rst = 1;
        @(posedge clk); // one extra cycle in reset
        if (tick === 1'b0) begin
            $display("PASS: During reset tick is 0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: During reset tick is not 0 (got %b)", tick);
            fail_count = fail_count + 1;
        end
        // release reset
        repeat(4) @(posedge clk);
        rst = 0;

        // -------------------------------------------------------
        // Test 2: Verify first tick arrives exactly EXPECTED_PERIOD
        //         cycles after reset deasserts
        // -------------------------------------------------------
        // Wait until we see the tick, count cycles
        cycle_count = 0;
        // reset the counter reference
        @(posedge clk); // first cycle after reset
        cycle_count = 1;
        while (tick !== 1'b1 && cycle_count < (EXPECTED_PERIOD * 3)) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end

        if (cycle_count == EXPECTED_PERIOD) begin
            $display("PASS: First tick arrived at cycle %0d (expected %0d)", cycle_count, EXPECTED_PERIOD);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: First tick arrived at cycle %0d (expected %0d)", cycle_count, EXPECTED_PERIOD);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 3: Tick is only 1 cycle wide (single-cycle pulse)
        // -------------------------------------------------------
        @(posedge clk);
        if (tick === 1'b0) begin
            $display("PASS: Tick is single-cycle wide (deasserted next cycle)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Tick is still high after one cycle (expected 0, got %b)", tick);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 4: Measure period between consecutive ticks (tick 2 and 3)
        // -------------------------------------------------------
        // Wait for next tick
        cycle_count = 0;
        while (tick !== 1'b1 && cycle_count < (EXPECTED_PERIOD * 3)) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end
        // Now at tick 2; record and wait for tick 3
        last_tick_cycle = free_cycle;
        cycle_count = 0;
        @(posedge clk); cycle_count = 1;
        while (tick !== 1'b1 && cycle_count < (EXPECTED_PERIOD * 3)) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end
        measured_period = cycle_count;

        if (measured_period == EXPECTED_PERIOD) begin
            $display("PASS: Tick period = %0d cycles (expected %0d)", measured_period, EXPECTED_PERIOD);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Tick period = %0d cycles (expected %0d)", measured_period, EXPECTED_PERIOD);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 5: Count exactly 5 ticks and verify regularity
        // -------------------------------------------------------
        tick_count = 0;
        for (i = 0; i < 5 * EXPECTED_PERIOD + 5; i = i + 1) begin
            @(posedge clk);
            if (tick === 1'b1)
                tick_count = tick_count + 1;
        end
        if (tick_count == 5) begin
            $display("PASS: Exactly 5 ticks counted in %0d cycles", 5*EXPECTED_PERIOD+5);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Expected 5 ticks, got %0d", tick_count);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 6: Reset mid-operation resets counter (tick stops, restarts)
        // -------------------------------------------------------
        // Wait a few cycles into a period, then assert reset
        repeat(3) @(posedge clk);
        rst = 1;
        @(posedge clk);
        if (tick === 1'b0) begin
            $display("PASS: Tick cleared immediately when reset asserted mid-period");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Tick not cleared when reset asserted mid-period (got %b)", tick);
            fail_count = fail_count + 1;
        end

        // After reset release, first tick should come after exactly EXPECTED_PERIOD cycles
        repeat(2) @(posedge clk);
        rst = 0;
        cycle_count = 0;
        @(posedge clk); cycle_count = 1;
        while (tick !== 1'b1 && cycle_count < (EXPECTED_PERIOD * 3)) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end
        if (cycle_count == EXPECTED_PERIOD) begin
            $display("PASS: After mid-period reset, first tick at cycle %0d", cycle_count);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After mid-period reset, first tick at cycle %0d (expected %0d)", cycle_count, EXPECTED_PERIOD);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 7: All-ones check — counter should never exceed EXPECTED_PERIOD-1
        //         We do this by watching 20 consecutive tick periods and
        //         confirming no two consecutive ticks are closer than EXPECTED_PERIOD
        // -------------------------------------------------------
        begin : blk_test7
            integer t;
            integer min_period;
            integer last_free;
            integer cur_period;

            min_period = 9999;
            last_free  = -1;
            t = 0;

            // observe 6 ticks
            while (t < 6) begin
                @(posedge clk);
                if (tick === 1'b1) begin
                    if (last_free >= 0) begin
                        cur_period = free_cycle - last_free;
                        if (cur_period < min_period)
                            min_period = cur_period;
                    end
                    last_free = free_cycle;
                    t = t + 1;
                end
            end

            if (min_period == EXPECTED_PERIOD) begin
                $display("PASS: Minimum tick period across 6 ticks = %0d (correct)", min_period);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Minimum tick period = %0d (expected %0d)", min_period, EXPECTED_PERIOD);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 8: All-zero input — with rst=1 tick stays 0, then normal after rst=0
        // -------------------------------------------------------
        rst = 1;
        repeat(EXPECTED_PERIOD * 2) @(posedge clk);
        tick_count = 0;
        // Count ticks during reset (should be 0)
        // We already checked above; re-verify
        if (tick === 1'b0) begin
            $display("PASS: All-zeros/reset state: tick=0 after extended reset");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: All-zeros/reset state: tick unexpectedly high during reset");
            fail_count = fail_count + 1;
        end
        rst = 0;

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        $display("--------------------------------------------------");
        $display("Simulation complete: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("--------------------------------------------------");

        $finish;
    end

endmodule
