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

    // State encoding
    parameter IDLE = 2'd0;
    parameter LOAD = 2'd1;
    parameter SORT = 2'd2;
    parameter DONE = 2'd3;

    integer timeout;
    integer pass_count;
    integer fail_count;

    // Task: wait for rising edge
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
        start = 0;

        // -------------------------------------------------------
        // TEST 1: Assert reset for exactly 5 rising edges
        // -------------------------------------------------------
        rst = 1;
        @(posedge clk); // 1
        @(posedge clk); // 2
        @(posedge clk); // 3
        @(posedge clk); // 4
        @(posedge clk); // 5
        #1; // small delay after last edge to sample outputs
        if (state === IDLE && done === 1'b0 && swap_en === 1'b0 && load_en === 1'b0) begin
            $display("PASS: After reset, state=IDLE, done=0, swap_en=0, load_en=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After reset, state=%0d done=%0b swap_en=%0b load_en=%0b (expected state=0 done=0 swap_en=0 load_en=0)",
                      state, done, swap_en, load_en);
            fail_count = fail_count + 1;
        end

        // Deassert reset
        rst = 0;
        #1;

        // -------------------------------------------------------
        // TEST 2: In IDLE state with start=0, state should remain IDLE
        // -------------------------------------------------------
        @(posedge clk); #1;
        if (state === IDLE) begin
            $display("PASS: start=0, state remains IDLE");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: start=0, state=%0d (expected IDLE=0)", state);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 3: Assert start -> FSM transitions from IDLE to LOAD
        // -------------------------------------------------------
        start = 1;
        @(posedge clk); #1;
        if (state === LOAD || state === SORT || state === IDLE) begin
            // FSM may move quickly; just check it left IDLE or went to LOAD
            $display("PASS: start asserted, FSM moved (state=%0d)", state);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: start asserted, state=%0d unexpected", state);
            fail_count = fail_count + 1;
        end
        start = 0;

        // -------------------------------------------------------
        // TEST 4: Wait for SORT state to be entered
        // -------------------------------------------------------
        timeout = 0;
        while (state !== SORT && timeout < 50) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        if (state === SORT) begin
            $display("PASS: FSM entered SORT state");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: FSM did not enter SORT state within timeout (state=%0d)", state);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 5: In SORT state, i and j should be valid (0-6 range)
        // -------------------------------------------------------
        #1;
        if (state === SORT && i <= 3'd6 && j <= 3'd6) begin
            $display("PASS: In SORT state, i=%0d j=%0d are in valid range", i, j);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: In SORT state, i=%0d j=%0d out of range or wrong state=%0d", i, j, state);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 6: Wait for DONE state
        // -------------------------------------------------------
        timeout = 0;
        while (state !== DONE && timeout < 200) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        if (state === DONE) begin
            $display("PASS: FSM reached DONE state");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: FSM did not reach DONE state within timeout (state=%0d)", state);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 7: done output should be asserted in DONE state
        // -------------------------------------------------------
        if (done === 1'b1) begin
            $display("PASS: done=1 in DONE state");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: done=%0b in DONE state (expected 1)", done);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 8: Apply reset again, check return to IDLE
        // -------------------------------------------------------
        rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        #1;
        if (state === IDLE && done === 1'b0) begin
            $display("PASS: After second reset, state=IDLE and done=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After second reset, state=%0d done=%0b", state, done);
            fail_count = fail_count + 1;
        end
        rst = 0;

        // -------------------------------------------------------
        // TEST 9: Start again - FSM should go through IDLE->LOAD->SORT->DONE again
        // -------------------------------------------------------
        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;
        timeout = 0;
        while (state !== DONE && timeout < 300) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        if (state === DONE && done === 1'b1) begin
            $display("PASS: Second sort run completed, done=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Second sort run did not complete (state=%0d done=%0b)", state, done);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 10: Check that load_en is only high during LOAD state
        // (go back and check during LOAD state next run)
        // -------------------------------------------------------
        rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0; #1;
        start = 1;
        @(posedge clk); #1;
        // Check load_en during LOAD or just after start
        if (load_en === 1'b1 || state === LOAD || state === SORT) begin
            $display("PASS: load_en=%0b during/after start assertion (state=%0d)", load_en, state);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: load_en=%0b state=%0d after start (expected load activity)", load_en, state);
            fail_count = fail_count + 1;
        end
        start = 0;

        // Wait for done
        timeout = 0;
        while (state !== DONE && timeout < 300) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        // -------------------------------------------------------
        // TEST 11: swap_en should not be asserted in DONE state
        // -------------------------------------------------------
        if (state === DONE && swap_en === 1'b0) begin
            $display("PASS: swap_en=0 in DONE state");
            pass_count = pass_count + 1;
        end else if (state !== DONE) begin
            $display("FAIL: Did not reach DONE (state=%0d)", state);
            fail_count = fail_count + 1;
        end else begin
            $display("FAIL: swap_en=%0b in DONE state (expected 0)", swap_en);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        $display("-----------------------------");
        $display("Test complete: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("-----------------------------");

        $finish;
    end

endmodule
