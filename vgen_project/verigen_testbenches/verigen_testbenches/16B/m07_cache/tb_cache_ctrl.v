`timescale 1ns/1ps

module tb_cache_ctrl;

    // DUT ports
    reg  clk, rst, cpu_req, mem_ack, hit, cpu_we;
    wire we_tag, we_data, mem_req, mem_we, stall;

    // Instantiate DUT
    cache_ctrl uut (
        .clk     (clk),
        .rst     (rst),
        .cpu_req (cpu_req),
        .mem_ack (mem_ack),
        .hit     (hit),
        .cpu_we  (cpu_we),
        .we_tag  (we_tag),
        .we_data (we_data),
        .mem_req (mem_req),
        .mem_we  (mem_we),
        .stall   (stall)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    integer fail_count;

    // Task to apply inputs and wait one clock, then check outputs
    task apply_and_check;
        input        t_cpu_req;
        input        t_mem_ack;
        input        t_hit;
        input        t_cpu_we;
        input        exp_we_tag;
        input        exp_we_data;
        input        exp_mem_req;
        input        exp_mem_we;
        input        exp_stall;
        input [63:0] desc_code; // not used for printing, just a marker
        begin
            cpu_req = t_cpu_req;
            mem_ack = t_mem_ack;
            hit     = t_hit;
            cpu_we  = t_cpu_we;
            // Wait for combinational outputs to settle after clock edge
            #1;
        end
    endtask

    // Helper: check combinational outputs right now
    task check_outputs;
        input        exp_we_tag;
        input        exp_we_data;
        input        exp_mem_req;
        input        exp_mem_we;
        input        exp_stall;
        input [127:0] test_name;
        begin
            if (we_tag  === exp_we_tag  &&
                we_data === exp_we_data &&
                mem_req === exp_mem_req &&
                mem_we  === exp_mem_we  &&
                stall   === exp_stall) begin
                $display("PASS: %s", test_name);
            end else begin
                $display("FAIL: %s  we_tag=%b(exp%b) we_data=%b(exp%b) mem_req=%b(exp%b) mem_we=%b(exp%b) stall=%b(exp%b)",
                    test_name,
                    we_tag,  exp_we_tag,
                    we_data, exp_we_data,
                    mem_req, exp_mem_req,
                    mem_we,  exp_mem_we,
                    stall,   exp_stall);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        fail_count = 0;

        // Initialise inputs
        cpu_req = 0;
        mem_ack = 0;
        hit     = 0;
        cpu_we  = 0;

        // ----------------------------------------------------------------
        // Assert synchronous reset for exactly 5 rising edges
        // ----------------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1; // settle after 5th rising edge

        // After reset, state should be IDLE, no cpu_req -> all outputs 0
        check_outputs(0,0,0,0,0,"Reset: IDLE, no cpu_req, all outputs 0");

        rst = 0;

        // ----------------------------------------------------------------
        // TEST 1: IDLE, no request – all outputs should be 0
        // ----------------------------------------------------------------
        @(posedge clk); #1;
        cpu_req = 0; hit = 0; cpu_we = 0; mem_ack = 0;
        #1;
        check_outputs(0,0,0,0,0,"IDLE no cpu_req: all outputs 0");

        // ----------------------------------------------------------------
        // TEST 2: IDLE + cpu_req (read) – stall, mem_req, we_tag asserted;
        //         we_data=0 (read), mem_we=0
        // ----------------------------------------------------------------
        @(posedge clk); #1;
        cpu_req = 1; cpu_we = 0; hit = 0; mem_ack = 0;
        #1;
        // State is still IDLE (transitions happen on next posedge)
        check_outputs(1,0,1,0,1,"IDLE + cpu_req (read): stall mem_req we_tag set");

        // ----------------------------------------------------------------
        // TEST 3: IDLE + cpu_req + cpu_we (write-through)
        //         we_data should follow cpu_we
        // ----------------------------------------------------------------
        // Stay in IDLE for this check – reset to IDLE again
        rst = 1;
        @(posedge clk); @(posedge clk); @(posedge clk); @(posedge clk); @(posedge clk);
        #1;
        rst = 0;

        @(posedge clk); #1;
        cpu_req = 1; cpu_we = 1; hit = 0; mem_ack = 0;
        #1;
        check_outputs(1,1,1,0,1,"IDLE + cpu_req + cpu_we: we_data=1 stall=1");

        // ----------------------------------------------------------------
        // TEST 4: Transition IDLE -> FETCH (cpu_req=1)
        //         In FETCH state outputs should all be 0
        // ----------------------------------------------------------------
        // cpu_req=1, so on next posedge we go to FETCH
        @(posedge clk); #1; // now in FETCH
        cpu_req = 1; cpu_we = 0; hit = 0; mem_ack = 0;
        #1;
        check_outputs(0,0,0,0,0,"FETCH state: all outputs 0");

        // ----------------------------------------------------------------
        // TEST 5: FETCH with hit=0 stays in FETCH (miss path / read miss)
        //         Still all outputs 0
        // ----------------------------------------------------------------
        @(posedge clk); #1; // stays in FETCH (hit=0)
        cpu_req = 0; hit = 0;
        #1;
        check_outputs(0,0,0,0,0,"FETCH hit=0 (read miss): all outputs 0, stays FETCH");

        // ----------------------------------------------------------------
        // TEST 6: FETCH with hit=1 -> transition to COMPARE
        //         In COMPARE state outputs should all be 0
        // ----------------------------------------------------------------
        hit = 1;
        @(posedge clk); #1; // now in COMPARE
        cpu_req = 0; cpu_we = 0;
        #1;
        check_outputs(0,0,0,0,0,"COMPARE state: all outputs 0");

        // ----------------------------------------------------------------
        // TEST 7: COMPARE with hit=1 -> WRITE_BACK
        //         WRITE_BACK outputs all 0
        // ----------------------------------------------------------------
        hit = 1;
        @(posedge clk); #1; // now in WRITE_BACK
        cpu_req = 0;
        #1;
        check_outputs(0,0,0,0,0,"WRITE_BACK state: all outputs 0");

        // ----------------------------------------------------------------
        // TEST 8: WRITE_BACK with cpu_req=1 -> next state FETCH
        //         While still in WRITE_BACK, outputs 0
        // ----------------------------------------------------------------
        cpu_req = 1; cpu_we = 0; hit = 0;
        #1;
        check_outputs(0,0,0,0,0,"WRITE_BACK + cpu_req=1: outputs still 0 this cycle");

        @(posedge clk); #1; // now in FETCH
        cpu_req = 0; hit = 0;
        #1;
        check_outputs(0,0,0,0,0,"After WRITE_BACK->FETCH transition: FETCH outputs 0");

        // ----------------------------------------------------------------
        // TEST 9: COMPARE with hit=0 -> back to IDLE
        // ----------------------------------------------------------------
        // Need to get back to COMPARE:  IDLE->FETCH->COMPARE
        // Reset first
        rst = 1;
        @(posedge clk); @(posedge clk); @(posedge clk); @(posedge clk); @(posedge clk);
        #1;
        rst = 0;

        // IDLE with cpu_req -> FETCH
        cpu_req = 1; cpu_we = 0; hit = 0;
        @(posedge clk); #1; // FETCH

        // FETCH with hit=1 -> COMPARE
        hit = 1;
        @(posedge clk); #1; // COMPARE

        // COMPARE with hit=0 -> IDLE
        hit = 0; cpu_req = 0;
        #1;
        check_outputs(0,0,0,0,0,"COMPARE hit=0: all outputs 0 (miss path to IDLE)");

        @(posedge clk); #1; // now in IDLE
        cpu_req = 0; hit = 0;
        #1;
        check_outputs(0,0,0,0,0,"After COMPARE miss -> IDLE: idle outputs 0");

        // ----------------------------------------------------------------
        // TEST 10: All-zero inputs in IDLE
        // ----------------------------------------------------------------
        @(posedge clk); #1;
        cpu_req = 0; cpu_we = 0; hit = 0; mem_ack = 0;
        #1;
        check_outputs(0,0,0,0,0,"All-zero inputs in IDLE");

        // ----------------------------------------------------------------
        // TEST 11: Reset while in FETCH – should return to IDLE
        // ----------------------------------------------------------------
        cpu_req = 1; hit = 0;
        @(posedge clk); #1; // -> FETCH

        rst = 1;
        @(posedge clk); #1; // forced to IDLE by rst
        cpu_req = 0;
        #1;
        check_outputs(0,0,0,0,0,"Reset in FETCH -> IDLE: valid reset to IDLE");
        rst = 0;

        // ----------------------------------------------------------------
        // Report summary
        // ----------------------------------------------------------------
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
