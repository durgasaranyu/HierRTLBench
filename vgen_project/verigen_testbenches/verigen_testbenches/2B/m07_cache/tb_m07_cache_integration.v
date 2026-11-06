`timescale 1ns/1ps

module tb_m07_cache_integration;

    // -------------------------------------------------------
    // DUT connections
    // -------------------------------------------------------
    reg         clk, rst;
    reg         cpu_req, cpu_we;
    reg  [31:0] cpu_addr, cpu_wdata;
    wire [31:0] cpu_rdata;
    wire        stall;
    wire [31:0] mem_addr;
    reg  [31:0] mem_rdata;
    wire        mem_req;

    // -------------------------------------------------------
    // Instantiate DUT (top-level module is named "cache")
    // -------------------------------------------------------
    cache uut (
        .clk      (clk),
        .rst      (rst),
        .cpu_req  (cpu_req),
        .cpu_we   (cpu_we),
        .cpu_addr (cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata),
        .stall    (stall),
        .mem_addr (mem_addr),
        .mem_rdata(mem_rdata),
        .mem_req  (mem_req)
    );

    // -------------------------------------------------------
    // Clock
    // -------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------
    // Timeout watchdog
    // -------------------------------------------------------
    integer timeout;
    integer pass_count, fail_count;

    // -------------------------------------------------------
    // Task: wait for rising edge
    // -------------------------------------------------------
    task wait_clk;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    // -------------------------------------------------------
    // Main test sequence
    // -------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;

        // --------------------------------------------------
        // Initialise inputs
        // --------------------------------------------------
        rst      = 1;
        cpu_req  = 0;
        cpu_we   = 0;
        cpu_addr = 32'h0000_0000;
        cpu_wdata= 32'h0000_0000;
        mem_rdata= 32'hDEAD_BEEF;

        // --------------------------------------------------
        // Assert reset for exactly 5 rising edges
        // --------------------------------------------------
        repeat (5) @(posedge clk);
        @(posedge clk); // one extra edge then deassert
        rst = 0;
        @(negedge clk); // settle after negedge

        // ==================================================
        // TEST 1: Cold miss – stall asserted, mem_req raised
        // ==================================================
        // Present a read request to a cold address
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'hA000_0010;   // tag = upper bits, index = 4, offset = 0
        cpu_wdata= 32'h0;
        mem_rdata= 32'hCAFE_BABE;

        // After the first clock edge the cache should stall
        @(posedge clk); #1;

        timeout = 0;
        while (!stall && timeout < 20) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (stall) begin
            $display("PASS: Cold-miss stall asserted for address 0xA0000010");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Cold-miss stall NOT asserted for address 0xA0000010");
            fail_count = fail_count + 1;
        end

        // ==================================================
        // TEST 2: mem_req raised on cold miss
        // ==================================================
        if (mem_req) begin
            $display("PASS: mem_req raised on cold miss");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: mem_req NOT raised on cold miss");
            fail_count = fail_count + 1;
        end

        // ==================================================
        // TEST 3: mem_addr matches requested address (word aligned)
        // ==================================================
        if (mem_addr == (cpu_addr & 32'hFFFF_FFFC)) begin
            $display("PASS: mem_addr correct = 0x%08X", mem_addr);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: mem_addr = 0x%08X expected 0x%08X",
                      mem_addr, cpu_addr & 32'hFFFF_FFFC);
            fail_count = fail_count + 1;
        end

        // ==================================================
        // TEST 4: Provide mem_rdata and wait for stall to clear
        // ==================================================
        mem_rdata = 32'hCAFE_BABE;

        timeout = 0;
        @(posedge clk); #1;
        while (stall && timeout < 30) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (!stall) begin
            $display("PASS: Stall cleared after fill (timeout=%0d)", timeout);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Stall did NOT clear after fill");
            fail_count = fail_count + 1;
        end

        // ==================================================
        // TEST 5: cpu_rdata should equal mem_rdata after fill
        // ==================================================
        if (cpu_rdata === 32'hCAFE_BABE) begin
            $display("PASS: cpu_rdata = 0x%08X after fill", cpu_rdata);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: cpu_rdata = 0x%08X expected 0xCAFEBABE", cpu_rdata);
            fail_count = fail_count + 1;
        end

        // ==================================================
        // TEST 6: Second access to same address – cache HIT
        //         stall should NOT be asserted
        // ==================================================
        @(negedge clk);
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'hA000_0010;   // same address
        mem_rdata= 32'hDEAD_DEAD;   // change mem_rdata so we can verify no new fill

        @(posedge clk); #1;

        if (!stall) begin
            $display("PASS: No stall on cache hit (same address)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Stall asserted on cache hit (same address)");
            fail_count = fail_count + 1;
        end

        // ==================================================
        // TEST 7: mem_req NOT raised on hit
        // ==================================================
        if (!mem_req) begin
            $display("PASS: mem_req NOT raised on cache hit");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: mem_req raised unexpectedly on cache hit");
            fail_count = fail_count + 1;
        end

        // ==================================================
        // TEST 8: cpu_rdata still valid (filled data, not new mem_rdata)
        // ==================================================
        if (cpu_rdata === 32'hCAFE_BABE) begin
            $display("PASS: cpu_rdata = 0x%08X (hit returns cached data)", cpu_rdata);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: cpu_rdata = 0x%08X on hit (expected 0xCAFEBABE)", cpu_rdata);
            fail_count = fail_count + 1;
        end

        // ==================================================
        // TEST 9: Write request (write-through) – no stall expected on hit
        // ==================================================
        @(negedge clk);
        cpu_req  = 1;
        cpu_we   = 1;
        cpu_addr = 32'hA000_0010;
        cpu_wdata= 32'h1234_5678;

        @(posedge clk); #1;

        if (!stall) begin
            $display("PASS: No stall on write-hit");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Stall asserted on write-hit");
            fail_count = fail_count + 1;
        end

        // ==================================================
        // TEST 10: Different index – another cold miss
        // ==================================================
        @(negedge clk);
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'hB000_0020;   // different tag & index
        mem_rdata= 32'h1111_2222;

        @(posedge clk); #1;

        timeout = 0;
        while (!stall && timeout < 20) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (stall) begin
            $display("PASS: Stall on second cold-miss address 0xB0000020");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: No stall on second cold-miss address 0xB0000020");
            fail_count = fail_count + 1;
        end

        // Wait for fill to complete
        timeout = 0;
        @(posedge clk); #1;
        while (stall && timeout < 30) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (!stall) begin
            $display("PASS: Stall cleared for second cold-miss fill");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Stall did NOT clear for second cold-miss fill");
            fail_count = fail_count + 1;
        end

        // ==================================================
        // TEST 11: Deassert cpu_req – no spurious mem_req
        // ==================================================
        @(negedge clk);
        cpu_req  = 0;
        cpu_we   = 0;

        @(posedge clk); #1;

        if (!mem_req) begin
            $display("PASS: mem_req low when cpu_req deasserted");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: mem_req high when cpu_req deasserted");
            fail_count = fail_count + 1;
        end

        // ==================================================
        // TEST 12: Reset clears valid bits – re-miss after rst
        // ==================================================
        @(negedge clk);
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
        @(negedge clk);

        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'hA000_0010;   // was cached before reset
        mem_rdata= 32'hBEEF_CAFE;

        @(posedge clk); #1;

        timeout = 0;
        while (!stall && timeout < 20) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (stall) begin
            $display("PASS: Stall on re-request after reset (valid cleared)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: No stall after reset – valid bit not cleared");
            fail_count = fail_count + 1;
        end

        // Wait for fill
        timeout = 0;
        @(posedge clk); #1;
        while (stall && timeout < 30) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        // ==================================================
        // Summary
        // ==================================================
        $display("--------------------------------------");
        $display("Integration test complete: %0d PASS, %0d FAIL",
                  pass_count, fail_count);
        $display("--------------------------------------");

        $finish;
    end

endmodule
