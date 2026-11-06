`timescale 1ns/1ps

module tb_cache_ctrl;

    // DUT inputs (reg)
    reg clk;
    reg rst;
    reg cpu_req;
    reg mem_ack;
    reg hit;
    reg cpu_we;

    // DUT outputs (wire)
    wire we_tag;
    wire we_data;
    wire mem_req;
    wire mem_we;
    wire stall;

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

    integer fail_count;

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Task: wait for N rising edges
    task wait_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    // Task: check a condition
    task check;
        input        cond;
        input [255:0] desc;
        begin
            if (cond)
                $display("PASS: %s", desc);
            else begin
                $display("FAIL: %s", desc);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        fail_count = 0;

        // Initialise inputs
        rst     = 1;
        cpu_req = 0;
        cpu_we  = 0;
        mem_ack = 0;
        hit     = 0;

        // -------------------------------------------------------
        // Assert synchronous reset for exactly 5 rising edges
        // -------------------------------------------------------
        repeat (5) @(posedge clk);
        #1; // sample just after the 5th rising edge

        // -------------------------------------------------------
        // Test 1: After reset, outputs should be de-asserted
        // -------------------------------------------------------
        check((stall   === 1'b0), "Reset: stall=0");
        check((we_tag  === 1'b0), "Reset: we_tag=0");
        check((we_data === 1'b0), "Reset: we_data=0");

        // Deassert reset
        rst = 0;
        @(posedge clk); #1;

        // -------------------------------------------------------
        // Test 2: No request, no write-enable – outputs stay low
        // -------------------------------------------------------
        cpu_req = 0;
        cpu_we  = 0;
        hit     = 0;
        @(posedge clk); #1;
        check((stall   === 1'b0), "Idle: stall=0 when no req/we");
        check((we_tag  === 1'b0), "Idle: we_tag=0 when no req/we");
        check((we_data === 1'b0), "Idle: we_data=0 when no req/we");

        // -------------------------------------------------------
        // Test 3: Read hit – cpu_req=1, hit=1
        //         Expect stall asserted (next cycle), we_tag asserted
        // -------------------------------------------------------
        cpu_req = 1;
        cpu_we  = 0;
        hit     = 1;
        @(posedge clk); #1;   // rising edge latches inputs
        // After this edge: stall should follow (cpu_req==1)
        check((stall  === 1'b1), "Read hit: stall=1 when cpu_req=1");
        check((we_tag === 1'b1), "Read hit: we_tag=1 when cpu_req=1");

        // -------------------------------------------------------
        // Test 4: Lower cpu_req, check we_data asserts (write back phase)
        // -------------------------------------------------------
        // According to the FSM logic: when cpu_req de-asserts but cpu_we
        // was set internally, we_data becomes 1
        cpu_req = 0;
        hit     = 0;
        @(posedge clk); #1;
        // cpu_we was set to 1 internally on last cycle; now we_data should be 1
        check((we_data === 1'b1), "Post-req: we_data=1 during cpu_we phase");
        check((stall   === 1'b1), "Post-req: stall=1 during cpu_we phase");

        // Wait one more cycle for cpu_we to clear
        @(posedge clk); #1;
        check((stall   === 1'b0), "After cpu_we clears: stall=0");
        check((we_data === 1'b0), "After cpu_we clears: we_data=0");
        check((we_tag  === 1'b0), "After cpu_we clears: we_tag=0");

        // -------------------------------------------------------
        // Test 5: Read miss – cpu_req=1, hit=0
        //         Stall should assert; mem_req behaviour observed
        // -------------------------------------------------------
        cpu_req = 1;
        cpu_we  = 0;
        hit     = 0;
        mem_ack = 0;
        @(posedge clk); #1;
        check((stall  === 1'b1), "Read miss: stall=1 when cpu_req=1 hit=0");
        check((we_tag === 1'b1), "Read miss: we_tag=1 when cpu_req=1");

        // -------------------------------------------------------
        // Test 6: mem_ack asserted during miss – DUT sees mem_ack=1
        // -------------------------------------------------------
        cpu_req = 0;
        mem_ack = 1;
        hit     = 0;
        @(posedge clk); #1;
        // stall should still be 1 (cpu_we internally set)
        check((stall === 1'b1), "Mem ack: stall=1 (cpu_we phase)");
        mem_ack = 0;

        @(posedge clk); #1;
        check((stall === 1'b0), "After mem ack handled: stall=0");

        // -------------------------------------------------------
        // Test 7: Write request – cpu_req=1, cpu_we=1 (write-through)
        // -------------------------------------------------------
        cpu_req = 1;
        cpu_we  = 1;
        hit     = 1;
        @(posedge clk); #1;
        check((stall  === 1'b1), "Write: stall=1 when cpu_req=1 cpu_we=1");
        check((we_tag === 1'b1), "Write: we_tag=1 when cpu_req=1");

        cpu_req = 0;
        cpu_we  = 0;
        @(posedge clk); #1;
        // cpu_we internal was 1 → we_data=1, stall=1
        check((we_data === 1'b1), "Write-through: we_data=1 after req");
        check((stall   === 1'b1), "Write-through: stall=1 during we_data");

        @(posedge clk); #1;
        check((stall   === 1'b0), "Write-through done: stall=0");

        // -------------------------------------------------------
        // Test 8: All-zeros – no activity at all
        // -------------------------------------------------------
        cpu_req = 0;
        cpu_we  = 0;
        hit     = 0;
        mem_ack = 0;
        @(posedge clk); #1;
        check((stall   === 1'b0), "All-zero: stall=0");
        check((we_tag  === 1'b0), "All-zero: we_tag=0");
        check((we_data === 1'b0), "All-zero: we_data=0");

        // -------------------------------------------------------
        // Test 9: Synchronous reset clears outputs mid-stream
        // -------------------------------------------------------
        cpu_req = 1;
        hit     = 1;
        @(posedge clk); #1;
        // Now assert reset
        rst = 1;
        @(posedge clk); #1;
        check((stall   === 1'b0), "Mid-stream reset: stall=0");
        check((we_tag  === 1'b0), "Mid-stream reset: we_tag=0");
        check((we_data === 1'b0), "Mid-stream reset: we_data=0");
        rst = 0;
        cpu_req = 0;
        hit     = 0;

        // -------------------------------------------------------
        // Test 10: All-ones inputs except rst
        // -------------------------------------------------------
        cpu_req = 1;
        cpu_we  = 1;
        hit     = 1;
        mem_ack = 1;
        @(posedge clk); #1;
        check((stall === 1'b1), "All-ones (no rst): stall=1 with cpu_req=1");

        cpu_req = 0;
        cpu_we  = 0;
        mem_ack = 0;
        hit     = 0;
        @(posedge clk); #1;
        @(posedge clk); #1;

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
