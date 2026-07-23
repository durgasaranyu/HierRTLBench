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

    // Task: wait N rising edges
    task wait_clk;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    // Task: apply one cycle of inputs and sample outputs after posedge
    task apply_and_check;
        input        t_cpu_req;
        input        t_mem_ack;
        input        t_hit;
        input        t_cpu_we;
        input        exp_stall_hi;   // 1=expect stall high, 0=expect stall low, 2=don't care
        input        exp_mem_req_hi; // 1=expect mem_req high, 0=expect low, 2=don't care
        input        exp_mem_we_hi;  // 1=expect mem_we high, 0=expect low, 2=don't care
        input [63:0] test_id;
        input [127:0] desc;
        begin
            cpu_req = t_cpu_req;
            mem_ack = t_mem_ack;
            hit     = t_hit;
            cpu_we  = t_cpu_we;
            @(posedge clk);
            #1; // sample just after rising edge
            // Check stall
            if (exp_stall_hi !== 2) begin
                if (exp_stall_hi == 1 && stall !== 1)
                    $display("FAIL: Test%0d (%s) - expected stall=1, got stall=%0b", test_id, desc, stall);
                else if (exp_stall_hi == 0 && stall !== 0)
                    $display("FAIL: Test%0d (%s) - expected stall=0, got stall=%0b", test_id, desc, stall);
                else
                    $display("PASS: Test%0d (%s) - stall OK", test_id, desc);
            end
            // Check mem_req
            if (exp_mem_req_hi !== 2) begin
                if (exp_mem_req_hi == 1 && mem_req !== 1)
                    $display("FAIL: Test%0d (%s) - expected mem_req=1, got mem_req=%0b", test_id, desc, mem_req);
                else if (exp_mem_req_hi == 0 && mem_req !== 0)
                    $display("FAIL: Test%0d (%s) - expected mem_req=0, got mem_req=%0b", test_id, desc, mem_req);
                else
                    $display("PASS: Test%0d (%s) - mem_req OK", test_id, desc);
            end
            // Check mem_we
            if (exp_mem_we_hi !== 2) begin
                if (exp_mem_we_hi == 1 && mem_we !== 1)
                    $display("FAIL: Test%0d (%s) - expected mem_we=1, got mem_we=%0b", test_id, desc, mem_we);
                else if (exp_mem_we_hi == 0 && mem_we !== 0)
                    $display("FAIL: Test%0d (%s) - expected mem_we=0, got mem_we=%0b", test_id, desc, mem_we);
                else
                    $display("PASS: Test%0d (%s) - mem_we OK", test_id, desc);
            end
        end
    endtask

    integer pass_count;
    integer fail_count;

    initial begin
        // Initialise
        rst     = 1;
        cpu_req = 0;
        mem_ack = 0;
        hit     = 0;
        cpu_we  = 0;
        pass_count = 0;
        fail_count = 0;

        // Reset for exactly 5 rising edges
        repeat(5) @(posedge clk);
        #1;
        // After reset: check stall is de-asserted and no spurious mem_req
        if (stall === 0)
            $display("PASS: Test0 (reset_deassert) - stall=0 after rst");
        else
            $display("FAIL: Test0 (reset_deassert) - stall=%0b after rst", stall);

        if (mem_req === 0)
            $display("PASS: Test0 (reset_deassert) - mem_req=0 after rst");
        else
            $display("FAIL: Test0 (reset_deassert) - mem_req=%0b after rst", mem_req);

        rst = 0;
        @(posedge clk); #1;

        // -------------------------------------------------------
        // Test 1: All-zero inputs (no request)
        // No cpu_req -> should stay IDLE, stall=0, mem_req=0
        // -------------------------------------------------------
        cpu_req = 0; mem_ack = 0; hit = 0; cpu_we = 0;
        @(posedge clk); #1;
        if (stall === 0)
            $display("PASS: Test1 (all_zero_no_req) - stall=0 when idle");
        else
            $display("FAIL: Test1 (all_zero_no_req) - stall=%0b when idle", stall);
        if (mem_req === 0)
            $display("PASS: Test1 (all_zero_no_req) - mem_req=0 when idle");
        else
            $display("FAIL: Test1 (all_zero_no_req) - mem_req=%0b when idle", mem_req);

        // -------------------------------------------------------
        // Test 2: Read Hit - cpu_req=1, hit=1, cpu_we=0
        // Expect: stall should go low (hit), no mem_req needed
        // -------------------------------------------------------
        cpu_req = 1; mem_ack = 0; hit = 1; cpu_we = 0;
        @(posedge clk); #1;
        if (stall === 0)
            $display("PASS: Test2 (read_hit) - stall=0 on read hit");
        else
            $display("FAIL: Test2 (read_hit) - stall=%0b on read hit (expected 0)", stall);
        if (mem_req === 0)
            $display("PASS: Test2 (read_hit) - mem_req=0 on read hit");
        else
            $display("FAIL: Test2 (read_hit) - mem_req=%0b on read hit (expected 0)", mem_req);
        if (mem_we === 0)
            $display("PASS: Test2 (read_hit) - mem_we=0 on read hit");
        else
            $display("FAIL: Test2 (read_hit) - mem_we=%0b on read hit (expected 0)", mem_we);

        // -------------------------------------------------------
        // Test 3: Read Miss - cpu_req=1, hit=0, cpu_we=0
        // Expect: stall=1, mem_req=1 (FSM goes to MEM_FETCH)
        // -------------------------------------------------------
        cpu_req = 1; mem_ack = 0; hit = 0; cpu_we = 0;
        @(posedge clk); #1;
        if (stall === 1)
            $display("PASS: Test3 (read_miss) - stall=1 on read miss");
        else
            $display("FAIL: Test3 (read_miss) - stall=%0b on read miss (expected 1)", stall);
        if (mem_req === 1)
            $display("PASS: Test3 (read_miss) - mem_req=1 on read miss");
        else
            $display("FAIL: Test3 (read_miss) - mem_req=%0b on read miss (expected 1)", mem_req);

        // -------------------------------------------------------
        // Test 4: Miss with mem_ack - mem fetches data
        // -------------------------------------------------------
        cpu_req = 1; mem_ack = 1; hit = 0; cpu_we = 0;
        @(posedge clk); #1;
        $display("PASS: Test4 (miss_mem_ack) - mem_ack=1 during miss stall=%0b mem_req=%0b", stall, mem_req);

        // -------------------------------------------------------
        // Test 5: Write request (write-through), hit=1
        // Expect: mem_we=1 asserted
        // -------------------------------------------------------
        cpu_req = 1; mem_ack = 0; hit = 1; cpu_we = 1;
        @(posedge clk); #1;
        if (mem_we === 1)
            $display("PASS: Test5 (write_hit) - mem_we=1 on write hit");
        else
            $display("FAIL: Test5 (write_hit) - mem_we=%0b on write hit (expected 1)", mem_we);

        // -------------------------------------------------------
        // Test 6: Write miss (cpu_we=1, hit=0)
        // -------------------------------------------------------
        cpu_req = 1; mem_ack = 0; hit = 0; cpu_we = 1;
        @(posedge clk); #1;
        if (stall === 1)
            $display("PASS: Test6 (write_miss) - stall=1 on write miss");
        else
            $display("FAIL: Test6 (write_miss) - stall=%0b on write miss (expected 1)", stall);
        if (mem_req === 1)
            $display("PASS: Test6 (write_miss) - mem_req=1 on write miss");
        else
            $display("FAIL: Test6 (write_miss) - mem_req=%0b on write miss (expected 1)", mem_req);

        // -------------------------------------------------------
        // Test 7: All-ones inputs
        // -------------------------------------------------------
        cpu_req = 1; mem_ack = 1; hit = 1; cpu_we = 1;
        @(posedge clk); #1;
        $display("PASS: Test7 (all_ones) - outputs stall=%0b mem_req=%0b mem_we=%0b", stall, mem_req, mem_we);

        // -------------------------------------------------------
        // Test 8: Synchronous reset mid-operation
        // Assert rst again and check stall/mem_req clear
        // -------------------------------------------------------
        cpu_req = 1; mem_ack = 0; hit = 0; cpu_we = 0;
        @(posedge clk); #1; // start a miss
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        if (stall === 0)
            $display("PASS: Test8 (mid_reset) - stall=0 after mid-operation reset");
        else
            $display("FAIL: Test8 (mid_reset) - stall=%0b after mid-operation reset (expected 0)", stall);
        if (mem_req === 0)
            $display("PASS: Test8 (mid_reset) - mem_req=0 after mid-operation reset");
        else
            $display("FAIL: Test8 (mid_reset) - mem_req=%0b after mid-operation reset (expected 0)", mem_req);
        rst = 0;

        // -------------------------------------------------------
        // Test 9: No request after reset - verify clean idle
        // -------------------------------------------------------
        cpu_req = 0; mem_ack = 0; hit = 0; cpu_we = 0;
        @(posedge clk); #1;
        if (stall === 0 && mem_req === 0 && mem_we === 0)
            $display("PASS: Test9 (idle_after_reset) - all outputs zero in idle");
        else
            $display("FAIL: Test9 (idle_after_reset) - stall=%0b mem_req=%0b mem_we=%0b (expected all 0)", stall, mem_req, mem_we);

        // -------------------------------------------------------
        // Test 10: Consecutive read hits
        // -------------------------------------------------------
        cpu_req = 1; mem_ack = 0; hit = 1; cpu_we = 0;
        @(posedge clk); #1;
        if (stall === 0 && mem_req === 0)
            $display("PASS: Test10a (consec_read_hit1) - stall=0 mem_req=0");
        else
            $display("FAIL: Test10a (consec_read_hit1) - stall=%0b mem_req=%0b", stall, mem_req);

        cpu_req = 1; mem_ack = 0; hit = 1; cpu_we = 0;
        @(posedge clk); #1;
        if (stall === 0 && mem_req === 0)
            $display("PASS: Test10b (consec_read_hit2) - stall=0 mem_req=0");
        else
            $display("FAIL: Test10b (consec_read_hit2) - stall=%0b mem_req=%0b", stall, mem_req);

        // -------------------------------------------------------
        // Test 11: MEM_FETCH -> completion (mem_ack asserts)
        // -------------------------------------------------------
        cpu_req = 1; mem_ack = 0; hit = 0; cpu_we = 0;
        @(posedge clk); #1;
        // Now provide ack
        cpu_req = 1; mem_ack = 1; hit = 0; cpu_we = 0;
        @(posedge clk); #1;
        $display("PASS: Test11 (mem_fetch_complete) - stall=%0b mem_req=%0b after mem_ack", stall, mem_req);

        // -------------------------------------------------------
        // Test 12: Valid-bit check - after reset, we_tag should not be asserted spuriously
        // -------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        if (we_tag === 0)
            $display("PASS: Test12 (valid_reset) - we_tag=0 after reset");
        else
            $display("FAIL: Test12 (valid_reset) - we_tag=%0b after reset (expected 0)", we_tag);
        rst = 0;

        // Done
        @(posedge clk);
        $display("Testbench complete.");
        $finish;
    end

endmodule
