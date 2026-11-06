`timescale 1ns/1ps

module tb_baud_gen;

    // Parameters - use small values for simulation speed
    parameter CLK_FREQ  = 50000000;
    parameter BAUD_RATE = 115200;
    parameter CLK_PER_BIT = CLK_FREQ / BAUD_RATE; // ~434

    // DUT connections
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

    // Counters / helpers
    integer i;
    integer tick_count;
    integer cycle_count;
    integer first_tick_cycle;
    integer second_tick_cycle;
    integer measured_period;
    reg found_first;
    reg found_second;
    reg test_passed;

    // Task: wait for N rising edges
    task wait_cycles;
        input integer n;
        integer j;
        begin
            for (j = 0; j < n; j = j + 1)
                @(posedge clk);
        end
    endtask

    // -----------------------------------------------------------------------
    // Main test sequence
    // -----------------------------------------------------------------------
    initial begin
        // ------------------------------------------------------------------
        // 1. Assert reset for exactly 5 rising edges
        // ------------------------------------------------------------------
        rst = 1;
        wait_cycles(5);
        @(negedge clk);  // release between edges
        rst = 0;

        // ------------------------------------------------------------------
        // TEST 1: tick must be HIGH immediately after reset (counter==0)
        // ------------------------------------------------------------------
        // After rst deasserted, on the very first posedge counter==0 so tick==1
        @(posedge clk); // one more edge, counter was 0 before this edge
        // Actually: rst deasserted, counter=0, tick=1 combinatorially
        // Check tick right after deassertion (before any clock)
        #1; // small delay to let combinatorial settle
        if (tick === 1'b1)
            $display("PASS: tick HIGH immediately after reset (counter==0)");
        else
            $display("FAIL: tick not HIGH immediately after reset (counter==0), tick=%b", tick);

        // ------------------------------------------------------------------
        // TEST 2: tick goes LOW one cycle after reset release
        // ------------------------------------------------------------------
        @(posedge clk); // counter increments to 1
        #1;
        if (tick === 1'b0)
            $display("PASS: tick LOW when counter==1 (not zero)");
        else
            $display("FAIL: tick should be LOW when counter>0, tick=%b", tick);

        // ------------------------------------------------------------------
        // TEST 3: Measure tick period = CLK_PER_BIT cycles
        // The counter wraps at CLK_PER_BIT-1 back to 0, producing a tick.
        // We need to wait for two consecutive ticks and measure the gap.
        // ------------------------------------------------------------------
        // We are currently at counter==1 (just incremented).
        // Wait for next tick (counter wraps to 0).
        found_first  = 0;
        found_second = 0;
        first_tick_cycle  = 0;
        second_tick_cycle = 0;
        cycle_count = 0;

        // Poll for first tick after reset tick
        // Since we already consumed 2 cycles (counter=0,1), wait for counter to wrap
        begin : TICK_MEASURE
            forever begin
                @(posedge clk);
                #1;
                cycle_count = cycle_count + 1;
                if (tick === 1'b1) begin
                    if (!found_first) begin
                        first_tick_cycle = cycle_count;
                        found_first = 1;
                    end else if (!found_second) begin
                        second_tick_cycle = cycle_count;
                        found_second = 1;
                        disable TICK_MEASURE;
                    end
                end
                if (cycle_count > CLK_PER_BIT * 3) begin
                    $display("FAIL: Timeout waiting for two ticks");
                    disable TICK_MEASURE;
                end
            end
        end

        measured_period = second_tick_cycle - first_tick_cycle;
        if (measured_period === CLK_PER_BIT)
            $display("PASS: tick period = %0d cycles (expected %0d)", measured_period, CLK_PER_BIT);
        else
            $display("FAIL: tick period = %0d cycles (expected %0d)", measured_period, CLK_PER_BIT);

        // ------------------------------------------------------------------
        // TEST 4: Assert reset mid-operation, tick must go HIGH immediately
        // ------------------------------------------------------------------
        // Advance a few cycles so counter != 0
        wait_cycles(10);
        @(negedge clk);
        rst = 1;
        @(posedge clk);
        #1;
        if (tick === 1'b1)
            $display("PASS: tick HIGH immediately upon reset assertion (counter reset to 0)");
        else
            $display("FAIL: tick not HIGH during reset, tick=%b", tick);

        // ------------------------------------------------------------------
        // TEST 5: tick remains HIGH while reset is asserted (counter stuck 0)
        // ------------------------------------------------------------------
        wait_cycles(3);
        #1;
        if (tick === 1'b1)
            $display("PASS: tick stays HIGH while reset held (counter stays 0)");
        else
            $display("FAIL: tick should stay HIGH while reset held, tick=%b", tick);

        // ------------------------------------------------------------------
        // TEST 6: After reset deasserted again, tick goes LOW next cycle
        // ------------------------------------------------------------------
        @(negedge clk);
        rst = 0;
        @(posedge clk); // counter -> 1
        #1;
        if (tick === 1'b0)
            $display("PASS: tick goes LOW one cycle after reset release");
        else
            $display("FAIL: tick should be LOW after first cycle post-reset, tick=%b", tick);

        // ------------------------------------------------------------------
        // TEST 7: Multiple tick periods - verify 3 consecutive periods
        // ------------------------------------------------------------------
        begin : MULTI_TICK
            integer prev_tick_cycle;
            integer cur_cycle;
            integer tick_seen;
            integer periods_ok;
            reg     period_fail;

            prev_tick_cycle = 0;
            cur_cycle       = 0;
            tick_seen       = 0;
            periods_ok      = 0;
            period_fail     = 0;

            // Wait for first tick (counter wraps)
            forever begin
                @(posedge clk);
                #1;
                cur_cycle = cur_cycle + 1;
                if (tick === 1'b1) begin
                    tick_seen = tick_seen + 1;
                    if (tick_seen == 1) begin
                        prev_tick_cycle = cur_cycle;
                    end else begin
                        measured_period = cur_cycle - prev_tick_cycle;
                        if (measured_period !== CLK_PER_BIT)
                            period_fail = 1;
                        else
                            periods_ok = periods_ok + 1;
                        prev_tick_cycle = cur_cycle;
                        if (tick_seen == 4)
                            disable MULTI_TICK;
                    end
                end
                if (cur_cycle > CLK_PER_BIT * 6) begin
                    $display("FAIL: Timeout in multi-tick period test");
                    disable MULTI_TICK;
                end
            end

            if (!period_fail && periods_ok == 3)
                $display("PASS: 3 consecutive tick periods all = %0d cycles", CLK_PER_BIT);
            else
                $display("FAIL: Not all tick periods matched expected=%0d", CLK_PER_BIT);
        end

        // ------------------------------------------------------------------
        // TEST 8: tick is exactly one cycle wide (pulse width check)
        // ------------------------------------------------------------------
        begin : PULSE_WIDTH
            integer pw_cycle;
            integer tick_on;
            integer tick_off;
            reg     pw_found;

            pw_cycle = 0;
            tick_on  = 0;
            tick_off = 0;
            pw_found = 0;

            forever begin
                @(posedge clk);
                #1;
                pw_cycle = pw_cycle + 1;
                if (tick === 1'b1 && !pw_found) begin
                    tick_on  = pw_cycle;
                    pw_found = 1;
                end else if (tick === 1'b0 && pw_found && tick_off == 0) begin
                    tick_off = pw_cycle;
                    disable PULSE_WIDTH;
                end
                if (pw_cycle > CLK_PER_BIT * 2) begin
                    $display("FAIL: Timeout in pulse width test");
                    disable PULSE_WIDTH;
                end
            end

            if ((tick_off - tick_on) === 1)
                $display("PASS: tick pulse width = 1 cycle (single-cycle tick)");
            else
                $display("FAIL: tick pulse width = %0d cycles (expected 1)", tick_off - tick_on);
        end

        // ------------------------------------------------------------------
        // TEST 9: All-zero scenario - reset keeps counter at 0, tick=1
        // ------------------------------------------------------------------
        rst = 1;
        wait_cycles(2);
        #1;
        if (tick === 1'b1)
            $display("PASS: tick=1 while rst=1 (counter stays at zero)");
        else
            $display("FAIL: tick should be 1 while rst=1, got tick=%b", tick);
        rst = 0;

        // ------------------------------------------------------------------
        // TEST 10: Verify tick count over an extended window
        // Count ticks over CLK_PER_BIT * 10 cycles and expect exactly 10
        // ------------------------------------------------------------------
        begin : TICK_COUNT_TEST
            integer tc_cycles;
            integer tc_ticks;

            tc_cycles = 0;
            tc_ticks  = 0;

            // Wait for first tick to synchronize
            forever begin
                @(posedge clk);
                #1;
                if (tick === 1'b1)
                    disable TICK_COUNT_TEST;
                if (tc_cycles > CLK_PER_BIT * 2) begin
                    $display("FAIL: Could not sync for tick count test");
                    disable TICK_COUNT_TEST;
                end
                tc_cycles = tc_cycles + 1;
            end
        end

        begin : COUNTING_TICKS
            integer cnt_cyc;
            integer cnt_tck;

            cnt_cyc = 0;
            cnt_tck = 0;

            // We just saw a tick; count the next CLK_PER_BIT*10 cycles
            repeat (CLK_PER_BIT * 10) begin
                @(posedge clk);
                #1;
                cnt_cyc = cnt_cyc + 1;
                if (tick === 1'b1)
                    cnt_tck = cnt_tck + 1;
            end

            // Expect exactly 10 ticks in CLK_PER_BIT*10 cycles
            if (cnt_tck === 10)
                $display("PASS: exactly 10 ticks in %0d cycles", CLK_PER_BIT * 10);
            else
                $display("FAIL: got %0d ticks in %0d cycles (expected 10)", cnt_tck, CLK_PER_BIT * 10);
        end

        // ------------------------------------------------------------------
        // Done
        // ------------------------------------------------------------------
        $display("Testbench complete.");
        $finish;
    end

endmodule
