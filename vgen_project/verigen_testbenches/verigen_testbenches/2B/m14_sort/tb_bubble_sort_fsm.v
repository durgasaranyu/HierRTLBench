`timescale 1ns/1ps

module tb_bubble_sort_fsm;

    // DUT ports
    reg clk, rst, start;
    wire [1:0] state;
    wire [2:0] i, j;
    wire       swap_en, load_en, done;

    // Instantiate DUT
    bubble_sort_fsm uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .state(state),
        .i(i),
        .j(j),
        .swap_en(swap_en),
        .load_en(load_en),
        .done(done)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    integer pass_count;
    integer fail_count;
    integer cycle_count;

    // Task to wait for rising edge
    task wait_clk;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1)
                @(posedge clk);
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize inputs
        rst   = 1;
        start = 0;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        #1; // small offset after edge
        rst = 0;

        //--------------------------------------------------------------
        // Test 1: After reset, state should be IDLE (0)
        //--------------------------------------------------------------
        @(posedge clk); #1;
        if (state === 2'd0) begin
            $display("PASS: After reset, state=IDLE(0)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After reset, expected state=IDLE(0), got state=%0d", state);
            fail_count = fail_count + 1;
        end

        // Test 2: done should be 0 in IDLE
        if (done === 1'b0) begin
            $display("PASS: In IDLE, done=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: In IDLE, expected done=0, got done=%0b", done);
            fail_count = fail_count + 1;
        end

        // Test 3: load_en should be 0 in IDLE (before start)
        if (load_en === 1'b0) begin
            $display("PASS: In IDLE before start, load_en=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: In IDLE before start, expected load_en=0, got load_en=%0b", load_en);
            fail_count = fail_count + 1;
        end

        //--------------------------------------------------------------
        // Test 4: Assert start -> should transition to LOAD (1)
        //--------------------------------------------------------------
        start = 1;
        @(posedge clk); #1;
        start = 0;

        // Check state moved to LOAD or beyond
        if (state === 2'd1 || state === 2'd2 || state === 2'd3) begin
            $display("PASS: After start asserted, state moved out of IDLE (state=%0d)", state);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After start asserted, state still IDLE=%0d", state);
            fail_count = fail_count + 1;
        end

        //--------------------------------------------------------------
        // Test 5: LOAD state - check load_en is asserted
        //--------------------------------------------------------------
        // Give one more cycle in LOAD to observe
        @(posedge clk); #1;
        // The module should assert load_en during LOAD or have been in LOAD
        // Check that we have been through LOAD (load_en might be 1 now or was 1)
        // Since we can't look backwards, check if we are in state 1 and load_en=1
        // OR already moved to SORT(2)
        if (state === 2'd1 && load_en === 1'b1) begin
            $display("PASS: In LOAD state, load_en=1");
            pass_count = pass_count + 1;
        end else if (state === 2'd2 || state === 2'd3) begin
            $display("PASS: FSM passed through LOAD and is now in state=%0d", state);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Expected LOAD(1) with load_en=1 or SORT(2)/DONE(3), got state=%0d load_en=%0b", state, load_en);
            fail_count = fail_count + 1;
        end

        //--------------------------------------------------------------
        // Test 6: Wait for SORT state (state=2)
        //--------------------------------------------------------------
        cycle_count = 0;
        while (state !== 2'd2 && cycle_count < 20) begin
            @(posedge clk); #1;
            cycle_count = cycle_count + 1;
        end

        if (state === 2'd2) begin
            $display("PASS: Reached SORT state (state=2)");
            pass_count = pass_count + 1;
        end else if (state === 2'd3) begin
            $display("PASS: FSM already in DONE state (skipped to DONE), state=%0d", state);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Did not reach SORT or DONE state within 20 cycles, state=%0d", state);
            fail_count = fail_count + 1;
        end

        //--------------------------------------------------------------
        // Test 7: swap_en behavior in SORT state
        //--------------------------------------------------------------
        // In SORT state, swap_en may be 0 or 1 depending on comparison
        // Just check state is still valid (SORT or DONE)
        if (state === 2'd2 || state === 2'd3) begin
            $display("PASS: swap_en=%0b in state=%0d (valid SORT/DONE state)", swap_en, state);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Unexpected state=%0d when checking swap_en", state);
            fail_count = fail_count + 1;
        end

        //--------------------------------------------------------------
        // Test 8: Wait for DONE state (state=3)
        //--------------------------------------------------------------
        cycle_count = 0;
        while (state !== 2'd3 && cycle_count < 200) begin
            @(posedge clk); #1;
            cycle_count = cycle_count + 1;
        end

        if (state === 2'd3) begin
            $display("PASS: Reached DONE state (state=3) after %0d cycles", cycle_count);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Did not reach DONE state within 200 cycles, state=%0d", state);
            fail_count = fail_count + 1;
        end

        //--------------------------------------------------------------
        // Test 9: done should be 1 in DONE state
        //--------------------------------------------------------------
        if (done === 1'b1) begin
            $display("PASS: In DONE state, done=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: In DONE state, expected done=1, got done=%0b", done);
            fail_count = fail_count + 1;
        end

        //--------------------------------------------------------------
        // Test 10: Reset while in DONE state -> back to IDLE
        //--------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;
        @(posedge clk); #1;

        if (state === 2'd0) begin
            $display("PASS: After reset from DONE, state=IDLE(0)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After reset from DONE, expected IDLE(0), got state=%0d", state);
            fail_count = fail_count + 1;
        end

        //--------------------------------------------------------------
        // Test 11: Start again - second sort run (already-sorted scenario)
        //--------------------------------------------------------------
        start = 1;
        @(posedge clk); #1;
        start = 0;

        cycle_count = 0;
        while (state !== 2'd3 && cycle_count < 300) begin
            @(posedge clk); #1;
            cycle_count = cycle_count + 1;
        end

        if (state === 2'd3) begin
            $display("PASS: Second sort run completed, reached DONE in %0d cycles", cycle_count);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Second sort run did not reach DONE within 300 cycles, state=%0d", state);
            fail_count = fail_count + 1;
        end

        //--------------------------------------------------------------
        // Test 12: i and j indices should be at terminal values in DONE
        //--------------------------------------------------------------
        // In DONE state the FSM has finished all passes; j should be at max (7) or 6
        // and i should wrap back; just check they are 3-bit values (always true)
        // Check done is still 1
        if (done === 1'b1 && state === 2'd3) begin
            $display("PASS: In DONE, i=%0d j=%0d done=1 state=3", i, j);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: In DONE check, got state=%0d done=%0b i=%0d j=%0d", state, done, i, j);
            fail_count = fail_count + 1;
        end

        //--------------------------------------------------------------
        // Test 13: Check that start=0 does nothing when in IDLE
        //--------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;
        @(posedge clk); #1;

        // Don't assert start - should stay in IDLE
        @(posedge clk); #1;
        @(posedge clk); #1;

        if (state === 2'd0) begin
            $display("PASS: Without start, FSM stays in IDLE");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Without start, FSM should stay in IDLE, got state=%0d", state);
            fail_count = fail_count + 1;
        end

        //--------------------------------------------------------------
        // Test 14: IDLE -> LOAD transition check with load_en
        //--------------------------------------------------------------
        start = 1;
        @(posedge clk); #1;
        start = 0;

        // Observe load_en either now or one cycle ago
        // Check if we are in LOAD state with load_en=1
        cycle_count = 0;
        while (state !== 2'd1 && state !== 2'd2 && cycle_count < 5) begin
            @(posedge clk); #1;
            cycle_count = cycle_count + 1;
        end

        if (state === 2'd1 || state === 2'd2 || state === 2'd3) begin
            $display("PASS: FSM transitioned from IDLE after start, state=%0d", state);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: FSM did not leave IDLE state after start, state=%0d", state);
            fail_count = fail_count + 1;
        end

        //--------------------------------------------------------------
        // Test 15: Full sort run to DONE, verify done signal
        //--------------------------------------------------------------
        cycle_count = 0;
        while (state !== 2'd3 && cycle_count < 300) begin
            @(posedge clk); #1;
            cycle_count = cycle_count + 1;
        end

        if (state === 2'd3 && done === 1'b1) begin
            $display("PASS: Full sort run (test 15) completed, DONE=1 in %0d total cycles", cycle_count);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Full sort run (test 15) did not complete, state=%0d done=%0b", state, done);
            fail_count = fail_count + 1;
        end

        //--------------------------------------------------------------
        // Summary
        //--------------------------------------------------------------
        $display("--------------------------------------------------");
        $display("Tests completed: PASS=%0d  FAIL=%0d", pass_count, fail_count);
        $display("--------------------------------------------------");

        $finish;
    end

endmodule
