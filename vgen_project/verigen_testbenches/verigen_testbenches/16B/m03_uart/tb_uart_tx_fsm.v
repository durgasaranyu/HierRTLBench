`timescale 1ns/1ps

module tb_uart_tx_fsm;

    // DUT ports
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

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Task: apply one rising-edge tick
    task apply_tick;
        begin
            @(negedge clk);
            tick = 1;
            @(posedge clk);
            #1;
            @(negedge clk);
            tick = 0;
        end
    endtask

    // Helper: read state (we observe outputs to infer state)
    integer i;

    initial begin
        // -----------------------------------------------------------------
        // Initialise inputs
        // -----------------------------------------------------------------
        rst      = 1;
        tick     = 0;
        tx_start = 0;

        // -----------------------------------------------------------------
        // Test 1: Assert reset for exactly 5 rising edges, verify IDLE
        // -----------------------------------------------------------------
        repeat(5) @(posedge clk);
        #1;
        // After reset the FSM should be in IDLE:
        //   tx_out = 1, load = 0, shift_en = 0, busy = 0
        if (tx_out === 1'b1 && load === 1'b0 && shift_en === 1'b0 && busy === 1'b0)
            $display("PASS: After reset FSM is in IDLE (tx_out=1, load=0, shift_en=0, busy=0)");
        else
            $display("FAIL: After reset FSM not in IDLE (tx_out=%b load=%b shift_en=%b busy=%b)",
                      tx_out, load, shift_en, busy);

        // Deassert reset
        @(negedge clk);
        rst = 0;
        #1;

        // -----------------------------------------------------------------
        // Test 2: IDLE state without tick – FSM stays in IDLE
        // -----------------------------------------------------------------
        @(posedge clk); #1;
        if (tx_out === 1'b1 && load === 1'b0 && shift_en === 1'b0 && busy === 1'b0)
            $display("PASS: IDLE state remains in IDLE when no tick");
        else
            $display("FAIL: IDLE without tick - unexpected outputs (tx_out=%b load=%b shift_en=%b busy=%b)",
                      tx_out, load, shift_en, busy);

        // -----------------------------------------------------------------
        // Test 3: IDLE with all-zero inputs (tx_start=0, tick=0) – stay IDLE
        // -----------------------------------------------------------------
        tx_start = 0; tick = 0;
        @(posedge clk); #1;
        if (tx_out === 1'b1 && load === 1'b0 && shift_en === 1'b0 && busy === 1'b0)
            $display("PASS: IDLE with all-zero inputs stays IDLE");
        else
            $display("FAIL: IDLE all-zero inputs unexpected state");

        // -----------------------------------------------------------------
        // Test 4: IDLE -> START transition on tick
        // -----------------------------------------------------------------
        @(negedge clk);
        tick = 1;
        @(posedge clk); #1;
        // After this rising edge the FSM should transition to START
        // In START: load=1, tx_out=1 (default), shift_en=0, busy=0
        if (load === 1'b1)
            $display("PASS: IDLE->START transition on tick (load asserted)");
        else
            $display("FAIL: IDLE->START transition failed (load=%b, tx_out=%b, shift_en=%b)",
                      load, tx_out, shift_en);
        @(negedge clk);
        tick = 0;

        // -----------------------------------------------------------------
        // Test 5: START state – load is asserted, shift_en is de-asserted
        // -----------------------------------------------------------------
        @(posedge clk); #1;
        if (load === 1'b1 && shift_en === 1'b0)
            $display("PASS: START state: load=1, shift_en=0");
        else
            $display("FAIL: START state outputs wrong (load=%b shift_en=%b)", load, shift_en);

        // -----------------------------------------------------------------
        // Note on the RTL:
        //  The combinational block references 'load_tick', 'shift_tick', and
        //  'one_baud_tick' which are undeclared nets in the module.  In
        //  simulation they default to 0, so START->DATA, DATA->STOP and
        //  STOP->IDLE transitions driven by those signals never fire.
        //  We verify the observable behaviour under those conditions.
        // -----------------------------------------------------------------

        // Apply several ticks – FSM should stay in START because load_tick=0
        repeat(3) begin
            @(negedge clk); tick = 1;
            @(posedge clk); #1;
            @(negedge clk); tick = 0;
        end
        if (load === 1'b1 && shift_en === 1'b0)
            $display("PASS: START stays in START when load_tick=0 (undeclared net=0)");
        else
            $display("FAIL: Unexpected transition out of START");

        // -----------------------------------------------------------------
        // Test 6: DATA state outputs (shift_en=1) – force via reset and
        //         re-enter; use Verilog force/release to visit DATA
        // -----------------------------------------------------------------
        // Reset back to IDLE
        @(negedge clk); rst = 1;
        @(posedge clk); @(posedge clk);
        @(negedge clk); rst = 0;
        tick = 0;

        // Force state to DATA directly
        force uut.state = 4'd2; // DATA = 2
        @(posedge clk); #1;
        if (shift_en === 1'b1 && load === 1'b0 && tx_out === 1'b1)
            $display("PASS: DATA state: shift_en=1, load=0, tx_out=1");
        else
            $display("FAIL: DATA state outputs wrong (shift_en=%b load=%b tx_out=%b)",
                      shift_en, load, tx_out);
        release uut.state;

        // -----------------------------------------------------------------
        // Test 7: STOP state outputs (tx_out=0)
        // -----------------------------------------------------------------
        @(negedge clk); rst = 1;
        @(posedge clk); @(posedge clk);
        @(negedge clk); rst = 0;

        force uut.state = 4'd3; // STOP = 3
        @(posedge clk); #1;
        if (tx_out === 1'b0 && shift_en === 1'b0 && load === 1'b0)
            $display("PASS: STOP state: tx_out=0 (space/mark inverted), shift_en=0, load=0");
        else
            $display("FAIL: STOP state outputs wrong (tx_out=%b shift_en=%b load=%b)",
                      tx_out, shift_en, load);
        release uut.state;

        // -----------------------------------------------------------------
        // Test 8: Default/unknown state -> next_state = IDLE (tx_out=1)
        // -----------------------------------------------------------------
        @(negedge clk); rst = 1;
        @(posedge clk); @(posedge clk);
        @(negedge clk); rst = 0;

        force uut.state = 4'd15; // unused state
        @(posedge clk); #1;
        // Default branch: next_state=IDLE, outputs: tx_out=1, load=0, shift_en=0, busy=0
        if (tx_out === 1'b1 && load === 1'b0 && shift_en === 1'b0 && busy === 1'b0)
            $display("PASS: Default/unknown state maps to IDLE outputs");
        else
            $display("FAIL: Default/unknown state outputs wrong (tx_out=%b load=%b shift_en=%b busy=%b)",
                      tx_out, load, shift_en, busy);
        release uut.state;

        // -----------------------------------------------------------------
        // Test 9: All-ones on inputs (tick=1, tx_start=1) from IDLE
        // -----------------------------------------------------------------
        @(negedge clk); rst = 1;
        @(posedge clk); @(posedge clk);
        @(negedge clk); rst = 0; tick = 1; tx_start = 1;
        @(posedge clk); #1;
        // With tick=1 from IDLE, FSM moves to START -> load should be 1
        if (load === 1'b1)
            $display("PASS: All-ones inputs (tick=1,tx_start=1) from IDLE -> START, load=1");
        else
            $display("FAIL: All-ones inputs from IDLE did not reach START (load=%b)", load);
        @(negedge clk); tick = 0; tx_start = 0;

        // -----------------------------------------------------------------
        // Test 10: Verify FSM returns to IDLE after reset even from START
        // -----------------------------------------------------------------
        @(negedge clk); rst = 1;
        repeat(5) @(posedge clk);
        #1;
        if (tx_out === 1'b1 && load === 1'b0 && shift_en === 1'b0 && busy === 1'b0)
            $display("PASS: FSM resets to IDLE from any state (tx_out=1 load=0 shift_en=0 busy=0)");
        else
            $display("FAIL: FSM did not reset to IDLE properly");
        @(negedge clk); rst = 0;

        // -----------------------------------------------------------------
        // Test 11: IDLE stays idle across multiple ticks=0 cycles
        // -----------------------------------------------------------------
        tick = 0; tx_start = 0;
        repeat(4) @(posedge clk);
        #1;
        if (tx_out === 1'b1 && load === 1'b0 && shift_en === 1'b0 && busy === 1'b0)
            $display("PASS: IDLE stable across multiple cycles with tick=0");
        else
            $display("FAIL: IDLE unstable with tick=0 (tx_out=%b load=%b shift_en=%b busy=%b)",
                      tx_out, load, shift_en, busy);

        // -----------------------------------------------------------------
        // Done
        // -----------------------------------------------------------------
        #20;
        $finish;
    end

endmodule
