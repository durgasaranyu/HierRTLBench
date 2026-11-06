`timescale 1ns/1ps

module tb_cache_ctrl;

    // DUT ports
    reg  clk, rst, cpu_req, mem_ack, hit, cpu_we;
    wire we_tag, we_data, mem_req, mem_we, stall;

    // Instantiate DUT
    cache_ctrl uut (
        .clk    (clk),
        .rst    (rst),
        .cpu_req(cpu_req),
        .mem_ack(mem_ack),
        .hit    (hit),
        .cpu_we (cpu_we),
        .we_tag (we_tag),
        .we_data(we_data),
        .mem_req(mem_req),
        .mem_we (mem_we),
        .stall  (stall)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Task: wait N rising edges
    task wait_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    integer fail_count;

    initial begin
        fail_count = 0;

        // ------------------------------------------------------------
        // 1. Reset: assert for exactly 5 rising edges
        // ------------------------------------------------------------
        rst     = 1;
        cpu_req = 0;
        mem_ack = 0;
        hit     = 0;
        cpu_we  = 0;

        wait_cycles(5);
        @(posedge clk);  // 6th edge – deassert
        rst = 0;

        // Give one idle cycle to settle
        @(posedge clk);

        // ------------------------------------------------------------
        // Test 1: After reset, stall must be low when no request
        // ------------------------------------------------------------
        cpu_req = 0; hit = 0; cpu_we = 0; mem_ack = 0;
        @(posedge clk); #1;
        if (stall === 1'b0)
            $display("PASS: After reset, stall=0 with no cpu_req");
        else begin
            $display("FAIL: After reset, stall=%b expected 0", stall);
            fail_count = fail_count + 1;
        end

        // ------------------------------------------------------------
        // Test 2: Read HIT – cpu_req=1, hit=1, cpu_we=0
        //         Expect: stall=0 (or goes low after compare), mem_req=0
        // ------------------------------------------------------------
        cpu_req = 1; hit = 1; cpu_we = 0; mem_ack = 0;
        @(posedge clk); #1;
        // On a hit the FSM should not assert mem_req and stall should be 0
        if (mem_req === 1'b0)
            $display("PASS: Read hit - mem_req=0");
        else begin
            $display("FAIL: Read hit - mem_req=%b expected 0", mem_req);
            fail_count = fail_count + 1;
        end
        if (stall === 1'b0)
            $display("PASS: Read hit - stall=0");
        else begin
            $display("FAIL: Read hit - stall=%b expected 0", stall);
            fail_count = fail_count + 1;
        end

        // ------------------------------------------------------------
        // Test 3: Read MISS – cpu_req=1, hit=0, cpu_we=0
        //         Expect: mem_req=1, stall=1
        // ------------------------------------------------------------
        cpu_req = 1; hit = 0; cpu_we = 0; mem_ack = 0;
        @(posedge clk); #1;
        if (mem_req === 1'b1)
            $display("PASS: Read miss - mem_req=1");
        else begin
            $display("FAIL: Read miss - mem_req=%b expected 1", mem_req);
            fail_count = fail_count + 1;
        end
        if (stall === 1'b1)
            $display("PASS: Read miss - stall=1");
        else begin
            $display("FAIL: Read miss - stall=%b expected 1", stall);
            fail_count = fail_count + 1;
        end

        // ------------------------------------------------------------
        // Test 4: mem_ack asserted during miss – FSM should complete fetch
        // ------------------------------------------------------------
        mem_ack = 1;
        @(posedge clk); #1;
        // After ack the FSM writes tag/data
        if (we_tag === 1'b1 || we_data === 1'b1)
            $display("PASS: Miss with mem_ack - we_tag or we_data asserted");
        else begin
            $display("FAIL: Miss with mem_ack - we_tag=%b we_data=%b, expected at least one high",
                     we_tag, we_data);
            fail_count = fail_count + 1;
        end
        mem_ack = 0;

        // Return to idle
        cpu_req = 0; hit = 0;
        @(posedge clk); #1;

        // ------------------------------------------------------------
        // Test 5: Write (write-through) – cpu_req=1, cpu_we=1, hit=1
        //         Expect: mem_we=1
        // ------------------------------------------------------------
        cpu_req = 1; cpu_we = 1; hit = 1; mem_ack = 0;
        @(posedge clk); #1;
        if (mem_we === 1'b1)
            $display("PASS: Write-through write - mem_we=1");
        else begin
            $display("FAIL: Write-through write - mem_we=%b expected 1", mem_we);
            fail_count = fail_count + 1;
        end
        cpu_we = 0;

        // Return to idle
        cpu_req = 0; hit = 0;
        @(posedge clk); #1;

        // ------------------------------------------------------------
        // Test 6: Write miss – cpu_req=1, cpu_we=1, hit=0
        //         Expect: mem_req=1, stall=1
        // ------------------------------------------------------------
        cpu_req = 1; cpu_we = 1; hit = 0; mem_ack = 0;
        @(posedge clk); #1;
        if (stall === 1'b1)
            $display("PASS: Write miss - stall=1");
        else begin
            $display("FAIL: Write miss - stall=%b expected 1", stall);
            fail_count = fail_count + 1;
        end
        cpu_we = 0; cpu_req = 0; hit = 0; mem_ack = 0;
        wait_cycles(2);

        // ------------------------------------------------------------
        // Test 7: All-zero inputs (no request) – stall must remain 0
        // ------------------------------------------------------------
        cpu_req = 0; cpu_we = 0; hit = 0; mem_ack = 0; rst = 0;
        @(posedge clk); #1;
        if (stall === 1'b0)
            $display("PASS: All-zero inputs - stall=0");
        else begin
            $display("FAIL: All-zero inputs - stall=%b expected 0", stall);
            fail_count = fail_count + 1;
        end
        if (mem_req === 1'b0)
            $display("PASS: All-zero inputs - mem_req=0");
        else begin
            $display("FAIL: All-zero inputs - mem_req=%b expected 0", mem_req);
            fail_count = fail_count + 1;
        end

        // ------------------------------------------------------------
        // Test 8: Synchronous reset clears stall/mem_req
        //         Put FSM in a stall state first, then reset
        // ------------------------------------------------------------
        cpu_req = 1; hit = 0; cpu_we = 0; mem_ack = 0;
        @(posedge clk); #1;  // enter miss/stall state

        // Now assert reset
        rst = 1;
        @(posedge clk); #1;
        if (stall === 1'b0)
            $display("PASS: Reset during stall - stall cleared to 0");
        else begin
            $display("FAIL: Reset during stall - stall=%b expected 0", stall);
            fail_count = fail_count + 1;
        end
        if (mem_req === 1'b0)
            $display("PASS: Reset during stall - mem_req cleared to 0");
        else begin
            $display("FAIL: Reset during stall - mem_req=%b expected 0", mem_req);
            fail_count = fail_count + 1;
        end
        rst = 0; cpu_req = 0;

        // ------------------------------------------------------------
        // Test 9: All-ones inputs with reset low
        //         cpu_req=1, hit=1, cpu_we=1, mem_ack=1
        // ------------------------------------------------------------
        wait_cycles(2);
        cpu_req = 1; hit = 1; cpu_we = 1; mem_ack = 1;
        @(posedge clk); #1;
        // Write-through: mem_we should be 1, stall 0
        if (mem_we === 1'b1)
            $display("PASS: All-ones inputs write-through - mem_we=1");
        else begin
            $display("FAIL: All-ones inputs write-through - mem_we=%b expected 1", mem_we);
            fail_count = fail_count + 1;
        end

        // ------------------------------------------------------------
        // Summary
        // ------------------------------------------------------------
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
