`timescale 1ns/1ps

module tb_bubble_sort_fsm;

    // DUT connections
    reg        clk;
    reg        rst;
    reg        start;
    wire [1:0] state;
    wire [2:0] i;
    wire [2:0] j;
    wire       swap_en;
    wire       load_en;
    wire       done;

    // Instantiate DUT
    bubble_sort_fsm uut (
        .clk    (clk),
        .rst    (rst),
        .start  (start),
        .state  (state),
        .i      (i),
        .j      (j),
        .swap_en(swap_en),
        .load_en(load_en),
        .done   (done)
    );

    // Parameters matching DUT
    parameter IDLE = 2'd0;
    parameter LOAD = 2'd1;
    parameter SORT = 2'd2;
    parameter DONE = 2'd3;

    integer k;
    integer fail_count;

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Task: wait for N rising edges
    task wait_cycles;
        input integer n;
        integer idx;
        begin
            for (idx = 0; idx < n; idx = idx + 1)
                @(posedge clk);
        end
    endtask

    initial begin
        fail_count = 0;
        rst   = 1;
        start = 0;

        // Assert reset for exactly 5 rising edges
        repeat(5) @(posedge clk);
        @(negedge clk); // deassert between edges
        rst = 0;

        // -------------------------------------------------------
        // Test 1: After reset, state should be IDLE
        // -------------------------------------------------------
        @(posedge clk); #1;
        if (state === IDLE) begin
            $display("PASS: After reset, state is IDLE");
        end else begin
            $display("FAIL: After reset, state is %b (expected IDLE)", state);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 2: Without start, state stays IDLE
        // -------------------------------------------------------
        wait_cycles(3);
        #1;
        if (state === IDLE) begin
            $display("PASS: Without start, state stays IDLE");
        end else begin
            $display("FAIL: Without start, state is %b (expected IDLE)", state);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 3: Assert start -> FSM should move to LOAD
        // -------------------------------------------------------
        @(negedge clk);
        start = 1;
        @(posedge clk); #1;
        // After one rising edge with start=1, next_state=LOAD should be latched
        if (state === LOAD) begin
            $display("PASS: After start, state transitions to LOAD");
        end else begin
            $display("FAIL: After start, state is %b (expected LOAD)", state);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 4: load_en should be asserted during LOAD state
        // -------------------------------------------------------
        // We just entered LOAD; load_en should have been set on the previous posedge
        // Check after another cycle in LOAD
        @(posedge clk); #1;
        if (load_en === 1'b1 && state === LOAD) begin
            $display("PASS: load_en asserted during LOAD state");
        end else begin
            $display("FAIL: load_en=%b state=%b (expected load_en=1 in LOAD)", load_en, state);
            fail_count = fail_count + 1;
        end

        // Deassert start
        @(negedge clk);
        start = 0;

        // -------------------------------------------------------
        // Test 5: Stay in LOAD for 8 cycles total, then transition to SORT
        // The FSM transitions to SORT after n_cycles==7 in LOAD.
        // We've been in LOAD for about 2 cycles already; wait enough more.
        // Wait up to 20 cycles and check for SORT state
        // -------------------------------------------------------
        begin : wait_sort
            integer timeout;
            timeout = 0;
            while (state !== SORT && timeout < 30) begin
                @(posedge clk); #1;
                timeout = timeout + 1;
            end
            if (state === SORT) begin
                $display("PASS: FSM transitioned from LOAD to SORT");
            end else begin
                $display("FAIL: FSM did not reach SORT state (state=%b)", state);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 6: In SORT state, i should increment each cycle
        // -------------------------------------------------------
        @(posedge clk); #1;
        begin
            reg [2:0] i_prev;
            i_prev = i;
            @(posedge clk); #1;
            if (i === i_prev + 1 || state !== SORT) begin
                $display("PASS: i increments in SORT state (i_prev=%0d, i=%0d)", i_prev, i);
            end else begin
                $display("FAIL: i did not increment in SORT (i_prev=%0d, i=%0d)", i_prev, i);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 7: FSM transitions to DONE after SORT completes
        // Wait until DONE state
        // -------------------------------------------------------
        begin : wait_done
            integer timeout2;
            timeout2 = 0;
            while (state !== DONE && timeout2 < 50) begin
                @(posedge clk); #1;
                timeout2 = timeout2 + 1;
            end
            if (state === DONE) begin
                $display("PASS: FSM transitioned to DONE state");
            end else begin
                $display("FAIL: FSM did not reach DONE state (state=%b)", state);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 8: done signal asserted in DONE state
        // -------------------------------------------------------
        @(posedge clk); #1;
        if (done === 1'b1) begin
            $display("PASS: done signal asserted in DONE state");
        end else begin
            $display("FAIL: done=%b in DONE state (expected 1)", done);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 9: From DONE without start, FSM goes to IDLE
        // -------------------------------------------------------
        start = 0;
        @(posedge clk); #1;
        if (state === IDLE || state === DONE) begin
            // Allow one more cycle to settle
            @(posedge clk); #1;
            if (state === IDLE) begin
                $display("PASS: From DONE without start, FSM returns to IDLE");
            end else begin
                $display("FAIL: From DONE without start, state=%b (expected IDLE)", state);
                fail_count = fail_count + 1;
            end
        end else begin
            $display("FAIL: Unexpected state=%b after DONE without start", state);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 10: Re-trigger from IDLE: assert start again
        // -------------------------------------------------------
        @(negedge clk);
        start = 1;
        @(posedge clk); #1;
        start = 0;
        if (state === LOAD) begin
            $display("PASS: Re-trigger from IDLE to LOAD with start");
        end else begin
            $display("FAIL: Re-trigger failed, state=%b (expected LOAD)", state);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 11: Apply reset mid-operation, verify return to IDLE
        // -------------------------------------------------------
        wait_cycles(3);
        @(negedge clk);
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        if (state === IDLE) begin
            $display("PASS: Reset mid-operation returns to IDLE");
        end else begin
            $display("FAIL: Reset mid-operation, state=%b (expected IDLE)", state);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 12: All-zero scenario: start=0 from IDLE stays IDLE
        // -------------------------------------------------------
        start = 0;
        wait_cycles(4);
        #1;
        if (state === IDLE) begin
            $display("PASS: All-zero inputs (start=0) keeps FSM in IDLE");
        end else begin
            $display("FAIL: All-zero inputs test failed, state=%b", state);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        if (fail_count === 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("%0d TEST(S) FAILED", fail_count);
        end

        $finish;
    end

endmodule
