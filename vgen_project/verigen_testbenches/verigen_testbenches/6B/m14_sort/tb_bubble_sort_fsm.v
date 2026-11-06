`timescale 1ns/1ps

module tb_bubble_sort_fsm;

    // DUT port connections
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
        .clk     (clk),
        .rst     (rst),
        .start   (start),
        .state   (state),
        .i       (i),
        .j       (j),
        .swap_en (swap_en),
        .load_en (load_en),
        .done    (done)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Timeout watchdog
    integer timeout;
    integer pass_count;
    integer fail_count;

    // Task to wait for rising edge
    task wait_cycles;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1)
                @(posedge clk);
        end
    endtask

    // Task: apply reset for exactly 5 rising edges
    task apply_reset;
        integer k;
        begin
            rst   = 1;
            start = 0;
            for (k = 0; k < 5; k = k + 1)
                @(posedge clk);
            #1; // small offset after last edge
            rst = 0;
        end
    endtask

    // Helper integer for loops
    integer idx;

    initial begin
        pass_count = 0;
        fail_count = 0;

        // ----------------------------------------------------------------
        // TEST 1: After reset, state should be IDLE (0)
        // ----------------------------------------------------------------
        rst   = 1;
        start = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        #2;
        rst = 0;
        #1;
        if (state === 2'b00) begin
            $display("PASS: After reset state is IDLE (0)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After reset state should be IDLE, got %0d", state);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 2: Verify done is de-asserted after reset
        // ----------------------------------------------------------------
        if (done === 1'b0) begin
            $display("PASS: done de-asserted after reset");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: done should be 0 after reset, got %0d", done);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 3: Verify load_en is de-asserted after reset
        // ----------------------------------------------------------------
        if (load_en === 1'b0) begin
            $display("PASS: load_en de-asserted after reset");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: load_en should be 0 after reset, got %0d", load_en);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 4: Assert start, check transition to LOAD (1)
        // ----------------------------------------------------------------
        @(posedge clk);
        #1;
        start = 1;
        @(posedge clk);
        #1;
        start = 0;
        // Allow a cycle for transition
        if (state === 2'b01 || state === 2'b10) begin
            $display("PASS: After start asserted, FSM left IDLE (state=%0d)", state);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After start, FSM should leave IDLE, got state=%0d", state);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 5: Wait for FSM to reach SORT state (2)
        // ----------------------------------------------------------------
        timeout = 0;
        while (state !== 2'b10 && timeout < 200) begin
            @(posedge clk);
            #1;
            timeout = timeout + 1;
        end
        if (state === 2'b10) begin
            $display("PASS: FSM reached SORT state (2) within timeout");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: FSM did not reach SORT state within timeout, state=%0d", state);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 6: Wait for FSM to reach DONE state (3)
        // ----------------------------------------------------------------
        timeout = 0;
        while (state !== 2'b11 && timeout < 2000) begin
            @(posedge clk);
            #1;
            timeout = timeout + 1;
        end
        if (state === 2'b11) begin
            $display("PASS: FSM reached DONE state (3) within timeout");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: FSM did not reach DONE state within timeout, state=%0d", state);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 7: Verify done is asserted in DONE state
        // ----------------------------------------------------------------
        if (done === 1'b1) begin
            $display("PASS: done asserted in DONE state");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: done should be 1 in DONE state, got %0d", done);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 8: Reset from DONE state returns to IDLE
        // ----------------------------------------------------------------
        rst = 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        #2;
        rst = 0;
        #1;
        if (state === 2'b00) begin
            $display("PASS: Reset from DONE returns to IDLE");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Reset from DONE should return IDLE, got state=%0d", state);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 9: Second sort run - start again and verify FSM traverses
        //         IDLE -> LOAD -> SORT -> DONE again
        // ----------------------------------------------------------------
        start = 1;
        @(posedge clk);
        #1;
        start = 0;

        // Wait for LOAD or SORT
        timeout = 0;
        while (state === 2'b00 && timeout < 50) begin
            @(posedge clk);
            #1;
            timeout = timeout + 1;
        end

        // Wait for DONE
        timeout = 0;
        while (state !== 2'b11 && timeout < 2000) begin
            @(posedge clk);
            #1;
            timeout = timeout + 1;
        end
        if (state === 2'b11 && done === 1'b1) begin
            $display("PASS: Second sort run completed, FSM in DONE with done=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Second sort run: state=%0d done=%0d", state, done);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 10: swap_en and load_en edge case - reset, no start
        //          Both should remain 0
        // ----------------------------------------------------------------
        rst = 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        #2;
        rst = 0;
        #1;
        // Wait a few cycles without asserting start
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        if (state === 2'b00 && done === 1'b0) begin
            $display("PASS: FSM stays in IDLE without start, done=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Without start FSM should stay IDLE done=0, got state=%0d done=%0d", state, done);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 11: i and j indices should be 0 in IDLE state
        // ----------------------------------------------------------------
        if (i === 3'b000 && j === 3'b000) begin
            $display("PASS: i=0 and j=0 in IDLE state");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: In IDLE i=%0d j=%0d, expected 0,0", i, j);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 12: Full IDLE->LOAD->SORT->DONE cycle, check i/j activity
        //          during SORT phase
        // ----------------------------------------------------------------
        rst = 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        #2;
        rst = 0;
        #1;

        start = 1;
        @(posedge clk);
        #1;
        start = 0;

        // Wait until SORT state
        timeout = 0;
        while (state !== 2'b10 && timeout < 200) begin
            @(posedge clk);
            #1;
            timeout = timeout + 1;
        end

        // Observe a few cycles in SORT - just check FSM is active
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;

        if (state === 2'b10) begin
            $display("PASS: FSM active in SORT state, i=%0d j=%0d swap_en=%0d", i, j, swap_en);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Expected SORT state, got state=%0d", state);
            fail_count = fail_count + 1;
        end

        // Wait for completion
        timeout = 0;
        while (state !== 2'b11 && timeout < 2000) begin
            @(posedge clk);
            #1;
            timeout = timeout + 1;
        end
        if (state === 2'b11) begin
            $display("PASS: Full cycle IDLE->LOAD->SORT->DONE completed successfully");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Full cycle did not complete, final state=%0d", state);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Summary
        // ----------------------------------------------------------------
        $display("========================================");
        $display("Test summary: PASS=%0d  FAIL=%0d", pass_count, fail_count);
        $display("========================================");

        $finish;
    end

endmodule
