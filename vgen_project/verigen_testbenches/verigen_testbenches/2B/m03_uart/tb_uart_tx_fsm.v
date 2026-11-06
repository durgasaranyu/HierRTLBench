`timescale 1ns/1ps

module tb_uart_tx_fsm;

    // DUT port connections
    reg  clk, rst, tick, tx_start;
    wire load, shift_en, tx_out, busy;

    // Instantiate DUT
    uart_tx_fsm uut (
        .clk      (clk),
        .rst      (rst),
        .tick     (tick),
        .tx_start (tx_start),
        .load     (load),
        .shift_en (shift_en),
        .tx_out   (tx_out),
        .busy     (busy)
    );

    // 10 ns clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Helper integer
    integer i;
    integer fail_count;

    // State encoding (mirrors DUT)
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    // Task: apply one rising-edge clock step
    task tick_clock;
        begin
            @(posedge clk);
            #1; // small delta to read outputs after clock edge
        end
    endtask

    initial begin
        fail_count = 0;
        tick       = 0;
        tx_start   = 0;

        // ----------------------------------------------------------------
        // Assert synchronous reset for exactly 5 rising edges
        // ----------------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;

        // ----------------------------------------------------------------
        // TEST 1: After reset, FSM is in IDLE
        // load=0, shift_en=0, tx_out=0 (idle high-Z line is 0 per code)
        // busy not driven but FSM outputs should reflect IDLE
        // ----------------------------------------------------------------
        @(negedge clk); // check in stable region
        if (load === 1'b0 && shift_en === 1'b0 && tx_out === 1'b0) begin
            $display("PASS: TEST1 - After reset, IDLE state: load=0 shift_en=0 tx_out=0");
        end else begin
            $display("FAIL: TEST1 - After reset state check. load=%b shift_en=%b tx_out=%b", load, shift_en, tx_out);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 2: In IDLE with tx_start=0, FSM stays in IDLE
        // ----------------------------------------------------------------
        tx_start = 0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        if (load === 1'b0 && shift_en === 1'b0 && tx_out === 1'b0) begin
            $display("PASS: TEST2 - Stays in IDLE when tx_start=0");
        end else begin
            $display("FAIL: TEST2 - Expected IDLE outputs. load=%b shift_en=%b tx_out=%b", load, shift_en, tx_out);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 3: Assert tx_start, FSM should move to START state
        // In START: load=1, tx_out=1
        // bit_count after reset = 0, so it transitions immediately to DATA
        // We need to catch the START state in the same cycle tx_start is seen
        // ----------------------------------------------------------------
        tx_start = 1;
        @(posedge clk); #1;  // Next state after IDLE+tx_start=1 -> START latched
        tx_start = 0;        // de-assert after one clock
        // Now state should be START (or already DATA if bit_count==0 immediately)
        // Since bit_count wraps (was 0, so still 0 going in), START->DATA in same transition
        // Let's just check that load was asserted (START state) or shift_en (DATA)
        if (load === 1'b1 || shift_en === 1'b1) begin
            $display("PASS: TEST3 - tx_start caused transition out of IDLE (load=%b shift_en=%b)", load, shift_en);
        end else begin
            $display("FAIL: TEST3 - tx_start did not cause transition. load=%b shift_en=%b tx_out=%b", load, shift_en, tx_out);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Full reset before next test sequence
        // ----------------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        @(negedge clk);

        // ----------------------------------------------------------------
        // TEST 4: Full FSM walk: IDLE -> START -> DATA -> STOP -> IDLE
        // Since bit_count resets to 0 and decrements each clock, the FSM
        // will transition through states based on bit_count == 0 condition.
        // ----------------------------------------------------------------

        // --- IDLE check ---
        if (load === 1'b0 && shift_en === 1'b0 && tx_out === 1'b0) begin
            $display("PASS: TEST4a - IDLE state verified after second reset");
        end else begin
            $display("FAIL: TEST4a - IDLE check failed. load=%b shift_en=%b tx_out=%b", load, shift_en, tx_out);
            fail_count = fail_count + 1;
        end

        // Trigger START transition
        tx_start = 1;
        @(posedge clk); #1;
        tx_start = 0;

        // --- START check: load=1, tx_out=1 ---
        if (load === 1'b1 && tx_out === 1'b1) begin
            $display("PASS: TEST4b - START state: load=1 tx_out=1");
        end else begin
            $display("FAIL: TEST4b - START check. load=%b tx_out=%b shift_en=%b", load, tx_out, shift_en);
            fail_count = fail_count + 1;
        end

        // Step one more clock - should move to DATA (bit_count==0 so START->DATA)
        @(posedge clk); #1;
        // --- DATA check: shift_en=1, load=0 ---
        if (shift_en === 1'b1 && load === 1'b0) begin
            $display("PASS: TEST4c - DATA state: shift_en=1 load=0");
        end else begin
            $display("FAIL: TEST4c - DATA check. shift_en=%b load=%b", shift_en, load);
            fail_count = fail_count + 1;
        end

        // Step one more clock - should move to STOP (bit_count==0)
        @(posedge clk); #1;
        // --- STOP check: load=0, shift_en=0, tx_out=0 ---
        if (load === 1'b0 && shift_en === 1'b0 && tx_out === 1'b0) begin
            $display("PASS: TEST4d - STOP state: load=0 shift_en=0 tx_out=0");
        end else begin
            $display("FAIL: TEST4d - STOP check. load=%b shift_en=%b tx_out=%b", load, shift_en, tx_out);
            fail_count = fail_count + 1;
        end

        // Step one more clock - should return to IDLE
        @(posedge clk); #1;
        if (load === 1'b0 && shift_en === 1'b0 && tx_out === 1'b0) begin
            $display("PASS: TEST4e - Back to IDLE after STOP");
        end else begin
            $display("FAIL: TEST4e - Return to IDLE failed. load=%b shift_en=%b tx_out=%b", load, shift_en, tx_out);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 5: Multiple tx_start pulses - FSM should re-enter START each time
        // ----------------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1; rst = 0;
        @(negedge clk);

        repeat (3) begin : multi_start_loop
            tx_start = 1;
            @(posedge clk); #1;
            tx_start = 0;
            // should be in START
            @(posedge clk); #1; // DATA
            @(posedge clk); #1; // STOP
            @(posedge clk); #1; // IDLE
        end
        if (load === 1'b0 && shift_en === 1'b0) begin
            $display("PASS: TEST5 - Repeated tx_start cycles return to IDLE correctly");
        end else begin
            $display("FAIL: TEST5 - After repeated cycles. load=%b shift_en=%b", load, shift_en);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 6: All-zero input scenario - tick=0, tx_start=0 in IDLE
        // FSM must stay in IDLE indefinitely
        // ----------------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1; rst = 0;
        tick     = 0;
        tx_start = 0;
        repeat(10) @(posedge clk);
        #1;
        if (load === 1'b0 && shift_en === 1'b0 && tx_out === 1'b0) begin
            $display("PASS: TEST6 - All-zero inputs: FSM stays in IDLE");
        end else begin
            $display("FAIL: TEST6 - All-zero inputs. load=%b shift_en=%b tx_out=%b", load, shift_en, tx_out);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 7: tick=1 in IDLE with tx_start=0 - no state change
        // ----------------------------------------------------------------
        tick = 1;
        tx_start = 0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        if (load === 1'b0 && shift_en === 1'b0 && tx_out === 1'b0) begin
            $display("PASS: TEST7 - tick=1 alone in IDLE doesn't cause state change");
        end else begin
            $display("FAIL: TEST7 - tick=1 changed state. load=%b shift_en=%b tx_out=%b", load, shift_en, tx_out);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 8: tx_start and tick simultaneously
        // ----------------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1; rst = 0;
        tick     = 1;
        tx_start = 1;
        @(posedge clk); #1;
        tx_start = 0;
        tick     = 0;
        // Should be in START: load=1, tx_out=1
        if (load === 1'b1 && tx_out === 1'b1) begin
            $display("PASS: TEST8 - tick=1 and tx_start=1 simultaneously: enters START correctly");
        end else begin
            $display("FAIL: TEST8 - Simultaneous tick+tx_start. load=%b tx_out=%b", load, tx_out);
            fail_count = fail_count + 1;
        end

        // Complete the cycle cleanly
        @(posedge clk); #1; // DATA
        @(posedge clk); #1; // STOP
        @(posedge clk); #1; // IDLE

        // ----------------------------------------------------------------
        // TEST 9: Reset in mid-operation (STOP state) forces back to IDLE
        // ----------------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1; rst = 0;

        tx_start = 1;
        @(posedge clk); #1;
        tx_start = 0;
        @(posedge clk); #1; // DATA
        @(posedge clk); #1; // STOP - now apply reset mid-STOP
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;
        if (load === 1'b0 && shift_en === 1'b0 && tx_out === 1'b0) begin
            $display("PASS: TEST9 - Mid-operation reset returns FSM to IDLE");
        end else begin
            $display("FAIL: TEST9 - Mid-operation reset failed. load=%b shift_en=%b tx_out=%b", load, shift_en, tx_out);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 10: Maximum value scenario - all-ones would be tx_start=1 held
        // FSM should only leave IDLE once and then cycle through
        // ----------------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1; rst = 0;

        // Hold tx_start high - FSM enters START, then DATA, STOP, and when
        // it returns to IDLE with tx_start=1, it immediately goes to START again
        tx_start = 1;
        tick     = 1;
        @(posedge clk); #1; // IDLE -> START
        if (load === 1'b1) begin
            $display("PASS: TEST10a - tx_start=1 held: FSM in START (load=1)");
        end else begin
            $display("FAIL: TEST10a - tx_start=1 held: Expected START. load=%b", load);
            fail_count = fail_count + 1;
        end
        @(posedge clk); #1; // START -> DATA
        @(posedge clk); #1; // DATA -> STOP
        @(posedge clk); #1; // STOP -> IDLE, but tx_start still 1 -> START
        // Because tx_start=1 and we returned to IDLE, combinatorially next_state=START
        // so at next posedge we should be in START again
        @(posedge clk); #1; // Should be in START again
        if (load === 1'b1 && tx_out === 1'b1) begin
            $display("PASS: TEST10b - After full cycle with tx_start held, re-enters START");
        end else begin
            $display("FAIL: TEST10b - Re-entry to START failed. load=%b tx_out=%b", load, tx_out);
            fail_count = fail_count + 1;
        end
        tx_start = 0;
        tick     = 0;

        // Wait a few clocks and finish
        repeat(5) @(posedge clk);

        // ----------------------------------------------------------------
        // Summary
        // ----------------------------------------------------------------
        if (fail_count == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("%0d TEST(S) FAILED", fail_count);
        end

        $finish;
    end

endmodule
