`timescale 1ns/1ps

module tb_baud_gen;

    // Parameters - use small values so simulation is fast
    parameter CLK_FREQ  = 50000000;
    parameter BAUD_RATE = 115200;
    parameter CLK_PER_BIT = CLK_FREQ / BAUD_RATE; // 434

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

    // Helper integers
    integer i;
    integer tick_count;
    integer cycle_count;
    integer first_tick_cycle;
    integer second_tick_cycle;
    integer period;
    integer fail_count;

    // Task: wait for N rising edges
    task wait_clk;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1)
                @(posedge clk);
        end
    endtask

    // -----------------------------------------------------------------------
    initial begin
        fail_count = 0;
        rst = 1;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        #1; // just past the edge
        rst = 0;

        // ===================================================================
        // TEST 1: After reset, tick should be HIGH on the very first cycle
        //         because counter resets to 0 and tick = (counter==0).
        // ===================================================================
        @(posedge clk); #1;
        // After first posedge post-reset, counter was 0 at reset, then
        // increments to 1, but tick is combinational: (counter==0).
        // At the posedge where rst goes low, counter becomes 0 (reset),
        // so tick should be HIGH right after reset.
        // Let's check tick right after releasing reset (before the next edge).
        rst = 0;
        // Re-do: release reset and check immediately
        @(negedge clk); // settle
        if (tick === 1'b1)
            $display("PASS: Tick is HIGH immediately after reset (counter==0)");
        else begin
            $display("FAIL: Tick should be HIGH immediately after reset, got %b", tick);
            fail_count = fail_count + 1;
        end

        // ===================================================================
        // TEST 2: Tick should go LOW on the next clock cycle
        //         (counter increments to 1 after reset)
        // ===================================================================
        @(posedge clk); #1;
        if (tick === 1'b0)
            $display("PASS: Tick goes LOW after first clock cycle post-reset");
        else begin
            $display("FAIL: Tick should be LOW one cycle after reset, got %b", tick);
            fail_count = fail_count + 1;
        end

        // ===================================================================
        // TEST 3: Verify tick period = CLK_PER_BIT cycles
        //         Measure cycles between two consecutive ticks.
        // ===================================================================
        // Wait for the next tick
        cycle_count = 0;
        first_tick_cycle = -1;
        second_tick_cycle = -1;

        // Scan for first tick
        for (i = 0; i < CLK_PER_BIT + 10; i = i + 1) begin
            @(posedge clk); #1;
            cycle_count = cycle_count + 1;
            if (tick === 1'b1 && first_tick_cycle < 0)
                first_tick_cycle = cycle_count;
        end

        // Continue scanning for second tick
        for (i = 0; i < CLK_PER_BIT + 10; i = i + 1) begin
            @(posedge clk); #1;
            cycle_count = cycle_count + 1;
            if (tick === 1'b1 && first_tick_cycle >= 0 && second_tick_cycle < 0)
                second_tick_cycle = cycle_count;
        end

        if (first_tick_cycle >= 0 && second_tick_cycle >= 0) begin
            period = second_tick_cycle - first_tick_cycle;
            if (period == CLK_PER_BIT)
                $display("PASS: Tick period = %0d cycles (expected %0d)", period, CLK_PER_BIT);
            else begin
                $display("FAIL: Tick period = %0d cycles (expected %0d)", period, CLK_PER_BIT);
                fail_count = fail_count + 1;
            end
        end else begin
            $display("FAIL: Could not detect two consecutive ticks");
            fail_count = fail_count + 1;
        end

        // ===================================================================
        // TEST 4: Apply reset mid-operation, tick goes high again
        // ===================================================================
        // Advance a few cycles, then reset
        wait_clk(50);
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        // Check tick is HIGH right after reset
        @(negedge clk);
        if (tick === 1'b1)
            $display("PASS: Tick is HIGH after mid-operation reset");
        else begin
            $display("FAIL: Tick should be HIGH after mid-operation reset, got %b", tick);
            fail_count = fail_count + 1;
        end

        // ===================================================================
        // TEST 5: Hold reset for multiple cycles, check tick stays HIGH
        //         while rst=1 (counter stays 0)
        // ===================================================================
        rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        // tick should remain HIGH because counter is held at 0
        if (tick === 1'b1)
            $display("PASS: Tick stays HIGH while reset is asserted (counter==0)");
        else begin
            $display("FAIL: Tick should stay HIGH during reset, got %b", tick);
            fail_count = fail_count + 1;
        end
        rst = 0;

        // ===================================================================
        // TEST 6: Count total ticks over exactly 3 * CLK_PER_BIT cycles
        //         Expect exactly 3 ticks (one per period).
        // ===================================================================
        // Re-sync: wait for first tick
        @(posedge clk); #1;
        // Wait until tick fires
        begin : wait_first
            integer w;
            for (w = 0; w < CLK_PER_BIT + 5; w = w + 1) begin
                if (tick === 1'b1) disable wait_first;
                @(posedge clk); #1;
            end
        end

        // Now count ticks over 3 periods
        tick_count = 0;
        for (i = 0; i < 3 * CLK_PER_BIT; i = i + 1) begin
            @(posedge clk); #1;
            if (tick === 1'b1)
                tick_count = tick_count + 1;
        end

        if (tick_count == 3)
            $display("PASS: Counted %0d ticks over 3*CLK_PER_BIT cycles (expected 3)", tick_count);
        else begin
            $display("FAIL: Counted %0d ticks over 3*CLK_PER_BIT cycles (expected 3)", tick_count);
            fail_count = fail_count + 1;
        end

        // ===================================================================
        // TEST 7: All-zero check - after reset counter=0, tick=1 (combo)
        //         Verify tick is single-cycle pulse (LOW on cycle after tick)
        // ===================================================================
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        // Tick is high right now (counter==0 combinationally)
        @(posedge clk); #1;
        // After one more clock, counter becomes 1, tick should be 0
        if (tick === 1'b0)
            $display("PASS: Tick is single-cycle pulse (LOW one cycle after tick)");
        else begin
            $display("FAIL: Tick should be LOW one cycle after the tick pulse, got %b", tick);
            fail_count = fail_count + 1;
        end

        // ===================================================================
        // TEST 8: Verify tick stays LOW for CLK_PER_BIT-1 cycles after pulse
        // ===================================================================
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        // Skip the initial tick (counter==0 right now)
        @(posedge clk); #1; // counter goes to 1, tick=0
        tick_count = 0;
        for (i = 0; i < CLK_PER_BIT - 2; i = i + 1) begin
            @(posedge clk); #1;
            if (tick === 1'b1)
                tick_count = tick_count + 1;
        end
        if (tick_count == 0)
            $display("PASS: Tick remains LOW for CLK_PER_BIT-1 cycles between pulses");
        else begin
            $display("FAIL: Tick fired %0d unexpected times in the middle of a period", tick_count);
            fail_count = fail_count + 1;
        end

        // ===================================================================
        // TEST 9: Verify the tick fires at exactly CLK_PER_BIT boundary
        // ===================================================================
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        // counter is 0 now, tick is HIGH. Now wait CLK_PER_BIT more cycles.
        // After CLK_PER_BIT clocks the counter wraps back to 0.
        for (i = 0; i < CLK_PER_BIT - 1; i = i + 1)
            @(posedge clk);
        // On this edge counter goes to CLK_PER_BIT-1, then resets to 0
        @(posedge clk); #1;
        // Now counter should be 0 again, tick HIGH
        if (tick === 1'b1)
            $display("PASS: Tick fires again at CLK_PER_BIT cycle boundary");
        else begin
            $display("FAIL: Tick did not fire at CLK_PER_BIT cycle boundary, got %b", tick);
            fail_count = fail_count + 1;
        end

        // ===================================================================
        // Summary
        // ===================================================================
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
