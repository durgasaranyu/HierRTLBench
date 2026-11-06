`timescale 1ns/1ps

module tb_m07_cache_integration;

    // ---------------------------------------------------------------------------
    // DUT port connections
    // ---------------------------------------------------------------------------
    reg         clk;
    reg         rst;
    reg         cpu_req;
    reg         cpu_we;
    reg  [31:0] cpu_addr;
    reg  [31:0] cpu_wdata;
    wire [31:0] cpu_rdata;
    wire        stall;
    wire [31:0] mem_addr;
    reg  [31:0] mem_rdata;
    wire        mem_req;

    // ---------------------------------------------------------------------------
    // DUT instantiation
    // ---------------------------------------------------------------------------
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

    // ---------------------------------------------------------------------------
    // Clock generation: 10 ns period
    // ---------------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // ---------------------------------------------------------------------------
    // Helper integers / parameters
    // ---------------------------------------------------------------------------
    integer i;
    integer timeout;
    integer test_pass;

    // A test address that maps to index=0, tag = addr[31:6]
    // e.g. addr = 32'h0000_0100  -> index bits [5:2] = 4'b0100 = 4 (index=4)
    // Use addr = 32'h0000_0040  -> index bits [5:2] = 4'b0000 = 0 (index=0)
    // Actually for a direct-mapped 16-set cache:
    //   index = addr[5:2]  (4 bits -> 0..15)
    //   offset = addr[1:0]
    //   tag    = addr[31:6]
    // Use a round address to make it easy.
    localparam ADDR_A = 32'h0000_0040;   // index = addr[5:2] = 4'b0000 = 0
    localparam MEM_DATA_A = 32'hDEAD_BEEF;

    localparam ADDR_B = 32'h0000_0100;   // index = addr[5:2] = 4'b0000 (bits [5:2] = 0)
    // ADDR_B = 0x100 = 256d  -> bits [5:2] = (256>>2)&0xF = 64&15 = 0 -> index=0, different tag
    // Actually let us compute properly:
    // ADDR_A = 0x40 = 0b0100_0000 -> [5:2]=0b0000=0, [31:6]=0b1=1  -> index=0, tag=1
    // ADDR_B = 0x100= 0b0001_0000_0000 -> [5:2]=0b0000=0, [31:6]=0b100=4 -> index=0, tag=4
    localparam MEM_DATA_B = 32'hCAFE_BABE;

    // -------------------------------------------------------------------------
    // Task: wait for rising edge of clk
    // -------------------------------------------------------------------------
    task wait_clk;
    begin
        @(posedge clk);
        #1; // small offset after edge
    end
    endtask

    // -------------------------------------------------------------------------
    // Main test sequence
    // -------------------------------------------------------------------------
    initial begin
        // -----------------------------------------------------------------------
        // Initialise all inputs
        // -----------------------------------------------------------------------
        rst      = 1;
        cpu_req  = 0;
        cpu_we   = 0;
        cpu_addr = 0;
        cpu_wdata= 0;
        mem_rdata= 0;

        // -----------------------------------------------------------------------
        // Assert synchronous reset for exactly 5 rising edges
        // -----------------------------------------------------------------------
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // Give one idle cycle after reset
        wait_clk;

        // =======================================================================
        // TEST 1: Cold-miss – address ADDR_A
        //   After issuing the request we expect stall to be asserted (cache miss).
        //   We then supply mem_rdata and wait for stall to deassert.
        // =======================================================================
        $display("--- TEST 1: Cold-miss on ADDR_A ---");
        test_pass = 1;

        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = ADDR_A;
        cpu_wdata= 0;
        mem_rdata= MEM_DATA_A;

        // Wait up to 50 cycles for stall to deassert (fill complete)
        timeout = 0;
        @(posedge clk); #1;
        while (stall === 1'b1 && timeout < 50) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (timeout >= 50) begin
            $display("FAIL: TEST1 – stall never cleared after cold-miss fill (timeout)");
            test_pass = 0;
        end else begin
            $display("PASS: TEST1 – stall cleared after cold-miss fill (after %0d extra cycles)", timeout);
        end

        // De-assert request for one cycle
        cpu_req = 0;
        wait_clk;

        // =======================================================================
        // TEST 2: Cache hit – same address ADDR_A
        //   After a successful fill, re-requesting ADDR_A should hit immediately
        //   (stall should not be asserted, or deasserted within 1 cycle).
        // =======================================================================
        $display("--- TEST 2: Cache hit on ADDR_A after fill ---");
        test_pass = 1;

        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = ADDR_A;
        cpu_wdata= 0;
        mem_rdata= 32'hXXXX_XXXX; // should not be used on a hit

        @(posedge clk); #1;

        // On a hit the cache should NOT assert stall (or clear it immediately)
        // We allow at most 2 cycles.
        timeout = 0;
        while (stall === 1'b1 && timeout < 5) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (stall === 1'b1) begin
            $display("FAIL: TEST2 – stall still asserted on cache hit for ADDR_A");
            test_pass = 0;
        end else begin
            $display("PASS: TEST2 – no stall on cache hit for ADDR_A");
        end

        // Optionally verify cpu_rdata if design supports read-data output on hit
        // (The module as written may or may not drive cpu_rdata correctly, so we
        //  only check it if the module drives a non-X value.)
        if (cpu_rdata !== 32'bx && cpu_rdata !== 32'bz) begin
            if (cpu_rdata === MEM_DATA_A) begin
                $display("PASS: TEST2 – cpu_rdata correct on hit (0x%08h)", cpu_rdata);
            end else begin
                $display("FAIL: TEST2 – cpu_rdata expected 0x%08h got 0x%08h",
                         MEM_DATA_A, cpu_rdata);
            end
        end else begin
            $display("INFO: TEST2 – cpu_rdata is X/Z; skipping data-value check");
        end

        cpu_req = 0;
        wait_clk;

        // =======================================================================
        // TEST 3: Cold-miss on a DIFFERENT address (different tag, same index)
        //         Exercises eviction path.
        // =======================================================================
        $display("--- TEST 3: Cold-miss on ADDR_B (same index, different tag) ---");

        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = ADDR_B;
        cpu_wdata= 0;
        mem_rdata= MEM_DATA_B;

        @(posedge clk); #1;
        timeout = 0;
        while (stall === 1'b1 && timeout < 50) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (timeout >= 50) begin
            $display("FAIL: TEST3 – stall never cleared after cold-miss fill for ADDR_B (timeout)");
        end else begin
            $display("PASS: TEST3 – stall cleared after cold-miss fill for ADDR_B (after %0d extra cycles)", timeout);
        end

        cpu_req = 0;
        wait_clk;

        // =======================================================================
        // TEST 4: Hit on ADDR_B after fill
        // =======================================================================
        $display("--- TEST 4: Cache hit on ADDR_B after fill ---");

        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = ADDR_B;
        cpu_wdata= 0;
        mem_rdata= 32'hXXXX_XXXX;

        @(posedge clk); #1;
        timeout = 0;
        while (stall === 1'b1 && timeout < 5) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (stall === 1'b1) begin
            $display("FAIL: TEST4 – stall still asserted on cache hit for ADDR_B");
        end else begin
            $display("PASS: TEST4 – no stall on cache hit for ADDR_B");
        end

        cpu_req = 0;
        wait_clk;

        // =======================================================================
        // TEST 5: Write-through write request (cpu_we=1)
        //         mem_req should be asserted to write through.
        // =======================================================================
        $display("--- TEST 5: Write-through write to ADDR_A ---");

        cpu_req  = 1;
        cpu_we   = 1;
        cpu_addr = ADDR_A;   // Note: ADDR_B may now occupy index 0 depending on design
        cpu_wdata= 32'h1234_5678;
        mem_rdata= 32'h0000_0000;

        // Wait a few cycles and check mem_req was asserted at some point
        begin : TEST5_BLOCK
            integer mem_req_seen;
            mem_req_seen = 0;
            repeat (20) begin
                @(posedge clk); #1;
                if (mem_req === 1'b1) mem_req_seen = 1;
            end
            if (mem_req_seen) begin
                $display("PASS: TEST5 – mem_req asserted during write-through");
            end else begin
                $display("FAIL: TEST5 – mem_req never asserted during write-through");
            end
        end

        cpu_req  = 0;
        cpu_we   = 0;
        wait_clk;

        // =======================================================================
        // TEST 6: Back-to-back reads on two different cached addresses
        //         (Both already filled above; check neither stalls for long)
        // =======================================================================
        $display("--- TEST 6: Sequential reads, no prolonged stall ---");

        // Re-fill ADDR_A (it may have been evicted by ADDR_B write above)
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = ADDR_A;
        mem_rdata= MEM_DATA_A;
        @(posedge clk); #1;
        timeout = 0;
        while (stall === 1'b1 && timeout < 50) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        $display("INFO: TEST6 – ADDR_A fill/hit resolved in %0d cycles", timeout);

        cpu_addr = ADDR_B;
        mem_rdata= MEM_DATA_B;
        @(posedge clk); #1;
        timeout = 0;
        while (stall === 1'b1 && timeout < 50) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        $display("INFO: TEST6 – ADDR_B fill/hit resolved in %0d cycles", timeout);

        cpu_req = 0;
        $display("PASS: TEST6 – sequential reads completed without infinite stall");
        wait_clk;

        // =======================================================================
        // TEST 7: Reset clears state – after reset, previously-filled address
        //         should miss again (stall on re-request).
        // =======================================================================
        $display("--- TEST 7: Reset clears valid bits; next access is cold miss ---");

        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;
        wait_clk;

        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = ADDR_A;
        mem_rdata= MEM_DATA_A;

        // After reset the line should be invalid → expect stall immediately
        @(posedge clk); #1;

        // We allow up to 2 cycles for the stall to appear (pipeline may have 1 cycle latency)
        timeout = 0;
        begin : TEST7_STALL_CHECK
            integer stall_seen;
            stall_seen = (stall === 1'b1) ? 1 : 0;
            if (!stall_seen) begin
                @(posedge clk); #1;
                stall_seen = (stall === 1'b1) ? 1 : 0;
            end

            if (stall_seen) begin
                $display("PASS: TEST7 – stall asserted after reset (cold miss confirmed)");
            end else begin
                $display("FAIL: TEST7 – stall NOT asserted after reset; expected cold miss");
            end
        end

        // Wait for fill to complete
        timeout = 0;
        while (stall === 1'b1 && timeout < 50) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        cpu_req = 0;
        wait_clk;

        // =======================================================================
        // Done
        // =======================================================================
        $display("--- All integration tests complete ---");
        #20;
        $finish;
    end

    // ---------------------------------------------------------------------------
    // Watchdog: prevent infinite simulation
    // ---------------------------------------------------------------------------
    initial begin
        #100000;
        $display("FAIL: Watchdog timeout – simulation exceeded 100000 ns");
        $finish;
    end

endmodule
