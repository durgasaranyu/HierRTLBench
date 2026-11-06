`timescale 1ns/1ps

module tb_baud_gen;

    // Parameters - use small values for fast simulation
    parameter CLK_FREQ  = 50000000;
    parameter BAUD_RATE = 115200;
    parameter PERIOD    = CLK_FREQ / BAUD_RATE; // ~434

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

    // Internal variables
    integer i;
    integer tick_count;
    integer cycle_count;
    integer first_tick_cycle;
    integer second_tick_cycle;
    integer measured_period;
    reg test_passed;

    // Task: wait for N rising edges
    task wait_clocks;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1)
                @(posedge clk);
        end
    endtask

    initial begin
        // Initialise
        rst = 1;
        tick_count  = 0;
        cycle_count = 0;
        test_passed = 1;

        // ----------------------------------------------------------------
        // TEST 1: Assert synchronous reset for exactly 5 rising edges
        // During reset counter must be 0, so tick must be 0 (since PERIOD-1 != 0)
        // ----------------------------------------------------------------
        @(posedge clk); #1;
        if (tick !== 1'b0) begin
            $display("FAIL: Reset cycle 1 - tick should be 0 during reset");
            test_passed = 0;
        end
        @(posedge clk); #1;
        if (tick !== 1'b0) begin
            $display("FAIL: Reset cycle 2 - tick should be 0 during reset");
            test_passed = 0;
        end
        @(posedge clk); #1;
        if (tick !== 1'b0) begin
            $display("FAIL: Reset cycle 3 - tick should be 0 during reset");
            test_passed = 0;
        end
        @(posedge clk); #1;
        if (tick !== 1'b0) begin
            $display("FAIL: Reset cycle 4 - tick should be 0 during reset");
            test_passed = 0;
        end
        @(posedge clk); #1;
        if (tick !== 1'b0) begin
            $display("FAIL: Reset cycle 5 - tick should be 0 during reset");
            test_passed = 0;
        end

        if (test_passed)
            $display("PASS: tick is 0 throughout reset (5 cycles)");

        // Deassert reset
        rst = 0;

        // ----------------------------------------------------------------
        // TEST 2: Measure period of first tick after reset release
        // Tick should appear at counter == PERIOD-1, i.e., PERIOD cycles after reset
        // ----------------------------------------------------------------
        first_tick_cycle = -1;
        for (i = 0; i < PERIOD + 5; i = i + 1) begin
            @(posedge clk); #1;
            if (tick === 1'b1 && first_tick_cycle < 0)
                first_tick_cycle = i;
        end

        // After reset, counter starts at 0 and tick fires when counter==PERIOD-1
        // That takes PERIOD clock cycles (cycles 0..PERIOD-1)
        if (first_tick_cycle == PERIOD - 1) begin
            $display("PASS: First tick at cycle %0d after reset release (expected %0d)",
                     first_tick_cycle, PERIOD - 1);
        end else begin
            $display("FAIL: First tick at cycle %0d after reset release (expected %0d)",
                     first_tick_cycle, PERIOD - 1);
        end

        // ----------------------------------------------------------------
        // TEST 3: Measure period between consecutive ticks
        // ----------------------------------------------------------------
        // Wait for next tick
        second_tick_cycle = -1;
        for (i = 0; i < PERIOD + 5; i = i + 1) begin
            @(posedge clk); #1;
            if (tick === 1'b1 && second_tick_cycle < 0)
                second_tick_cycle = i;
        end

        measured_period = second_tick_cycle + 1; // +1 because arrays 0-indexed
        if (measured_period == PERIOD) begin
            $display("PASS: Tick period is %0d cycles (expected %0d)",
                     measured_period, PERIOD);
        end else begin
            $display("FAIL: Tick period is %0d cycles (expected %0d)",
                     measured_period, PERIOD);
        end

        // ----------------------------------------------------------------
        // TEST 4: Tick is asserted for exactly 1 cycle
        // ----------------------------------------------------------------
        // We are just after a tick - counter is now 0
        // Count how many consecutive cycles tick stays high
        tick_count = 0;
        // Check right after we just got a tick
        // Re-measure: wait for the next tick and count how long it's high
        // First wait until tick goes high
        @(posedge clk); #1; // step one more
        // Now wait for tick
        begin : TICK_PULSE_CHECK
            reg found_tick;
            integer pulse_len;
            found_tick = 0;
            pulse_len  = 0;
            for (i = 0; i < PERIOD + 5; i = i + 1) begin
                if (!found_tick) begin
                    @(posedge clk); #1;
                    if (tick === 1'b1) begin
                        found_tick = 1;
                        pulse_len  = 1;
                    end
                end else begin
                    @(posedge clk); #1;
                    if (tick === 1'b1)
                        pulse_len = pulse_len + 1;
                    else
                        i = PERIOD + 10; // break
                end
            end
            if (found_tick && pulse_len == 1)
                $display("PASS: Tick pulse width is exactly 1 clock cycle");
            else
                $display("FAIL: Tick pulse width is %0d clock cycles (expected 1)", pulse_len);
        end

        // ----------------------------------------------------------------
        // TEST 5: Re-assert reset mid-count, verify tick suppressed & restarts
        // ----------------------------------------------------------------
        // Wait a few cycles into the period then reset
        wait_clocks(10);
        rst = 1;
        @(posedge clk); #1;
        if (tick !== 1'b0)
            $display("FAIL: Tick not suppressed immediately after mid-count reset")
        else
            $display("PASS: Tick suppressed immediately on mid-count reset");
        wait_clocks(3);
        rst = 0;

        // ----------------------------------------------------------------
        // TEST 6: After mid-count reset, first tick must still come after PERIOD cycles
        // ----------------------------------------------------------------
        first_tick_cycle = -1;
        for (i = 0; i < PERIOD + 5; i = i + 1) begin
            @(posedge clk); #1;
            if (tick === 1'b1 && first_tick_cycle < 0)
                first_tick_cycle = i;
        end

        if (first_tick_cycle == PERIOD - 1)
            $display("PASS: After mid-count reset, first tick again at cycle %0d (expected %0d)",
                     first_tick_cycle, PERIOD - 1)
        else
            $display("FAIL: After mid-count reset, first tick at cycle %0d (expected %0d)",
                     first_tick_cycle, PERIOD - 1);

        // ----------------------------------------------------------------
        // TEST 7: Multiple consecutive tick periods are all equal to PERIOD
        // ----------------------------------------------------------------
        begin : MULTI_PERIOD_CHECK
            integer errors;
            integer prev_cycle;
            integer cur_period;
            errors     = 0;
            prev_cycle = 0;
            // We just got a tick; measure next 4 periods
            for (i = 0; i < 4; i = i + 1) begin
                cur_period = 0;
                begin : WAIT_NEXT_TICK
                    integer j;
                    for (j = 0; j < PERIOD + 5; j = j + 1) begin
                        @(posedge clk); #1;
                        cur_period = cur_period + 1;
                        if (tick === 1'b1)
                            j = PERIOD + 10; // break
                    end
                end
                if (cur_period !== PERIOD)
                    errors = errors + 1;
            end
            if (errors == 0)
                $display("PASS: 4 consecutive tick periods all equal %0d cycles", PERIOD)
            else
                $display("FAIL: %0d of 4 consecutive tick periods were wrong (expected %0d cycles each)",
                         errors, PERIOD);
        end

        // ----------------------------------------------------------------
        // TEST 8: All-zeros scenario — hold rst=1 for many cycles, tick stays 0
        // ----------------------------------------------------------------
        rst = 1;
        test_passed = 1;
        for (i = 0; i < 20; i = i + 1) begin
            @(posedge clk); #1;
            if (tick !== 1'b0)
                test_passed = 0;
        end
        if (test_passed)
            $display("PASS: tick remains 0 for 20 cycles while rst=1 (all-zeros counter)")
        else
            $display("FAIL: tick unexpectedly asserted while rst=1");
        rst = 0;

        // ----------------------------------------------------------------
        // Done
        // ----------------------------------------------------------------
        $display("Testbench complete.");
        $finish;
    end

endmodule
