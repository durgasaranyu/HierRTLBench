`timescale 1ns/1ps

module tb_cache_top;

    // DUT I/O
    reg         clk, rst, cpu_req, cpu_we;
    reg  [31:0] cpu_addr, cpu_wdata;
    wire [31:0] cpu_rdata;
    wire        stall;
    wire [31:0] mem_addr;
    reg  [31:0] mem_rdata;
    wire        mem_req;

    // Instantiate DUT
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

    // Clock
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

    // Internal array access (direct-mapped, 16 sets, write-through)
    // The module uses: index = addr[5:2] (4 bits => 16 sets)
    //                  tag   = addr[31:6] (26 bits)
    // We cannot directly force internal arrays through the interface
    // so we rely on observable outputs.

    integer pass_count, fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;

        // ----------------------------------------------------------------
        // RESET: assert for exactly 5 rising edges
        // ----------------------------------------------------------------
        rst      = 1;
        cpu_req  = 0;
        cpu_we   = 0;
        cpu_addr = 32'h0000_0000;
        cpu_wdata= 32'h0000_0000;
        mem_rdata= 32'h0000_0000;

        wait_cycles(5);
        @(posedge clk);
        rst = 0;
        @(posedge clk); // settle

        // ================================================================
        // TEST 1: Valid bits reset on rst — after reset, any read should miss
        // ================================================================
        cpu_addr = 32'hABCD_EF04; // some address
        cpu_req  = 1;
        cpu_we   = 0;
        mem_rdata= 32'hDEAD_BEEF;
        @(negedge clk); // sample outputs
        // After reset, no valid entries => should see stall or mem_req
        // If either stall is asserted OR mem_req is asserted, it is a miss (valid bits cleared)
        if (stall === 1'b1 || mem_req === 1'b1) begin
            $display("PASS: After reset, read is a miss (stall=%0b, mem_req=%0b)", stall, mem_req);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After reset, expected miss but got hit");
            fail_count = fail_count + 1;
        end
        cpu_req = 0;
        wait_cycles(2);

        // ================================================================
        // TEST 2: Read miss — uncached address, mem_req should assert, stall high
        // ================================================================
        rst = 1;
        wait_cycles(5);
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        cpu_addr  = 32'h0000_0100; // index=4, tag=0x4
        cpu_req   = 1;
        cpu_we    = 0;
        mem_rdata = 32'h1234_5678;
        @(negedge clk);
        if (mem_req === 1'b1 || stall === 1'b1) begin
            $display("PASS: Read miss detected (mem_req=%0b, stall=%0b)", mem_req, stall);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Read miss not detected (mem_req=%0b, stall=%0b)", mem_req, stall);
            fail_count = fail_count + 1;
        end
        cpu_req = 0;
        wait_cycles(2);

        // ================================================================
        // TEST 3: All-zero address read miss
        // ================================================================
        rst = 1;
        wait_cycles(5);
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        cpu_addr  = 32'h0000_0000;
        cpu_req   = 1;
        cpu_we    = 0;
        mem_rdata = 32'h0000_0000;
        @(negedge clk);
        if (mem_req === 1'b1 || stall === 1'b1) begin
            $display("PASS: All-zero address read miss (mem_req=%0b, stall=%0b)", mem_req, stall);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: All-zero address: expected miss");
            fail_count = fail_count + 1;
        end
        cpu_req = 0;
        wait_cycles(2);

        // ================================================================
        // TEST 4: All-ones address read miss
        // ================================================================
        rst = 1;
        wait_cycles(5);
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        cpu_addr  = 32'hFFFF_FFFF;
        cpu_req   = 1;
        cpu_we    = 0;
        mem_rdata = 32'hFFFF_FFFF;
        @(negedge clk);
        if (mem_req === 1'b1 || stall === 1'b1) begin
            $display("PASS: All-ones address read miss (mem_req=%0b, stall=%0b)", mem_req, stall);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: All-ones address: expected miss");
            fail_count = fail_count + 1;
        end
        cpu_req = 0;
        wait_cycles(2);

        // ================================================================
        // TEST 5: Write request — cpu_we=1, mem_we (write-through) — check mem_req
        // ================================================================
        rst = 1;
        wait_cycles(5);
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        cpu_addr  = 32'h0000_0200;
        cpu_wdata = 32'hCAFE_BABE;
        cpu_req   = 1;
        cpu_we    = 1;
        mem_rdata = 32'h0000_0000;
        @(negedge clk);
        // Write-through: mem_req should be asserted on a write
        if (mem_req === 1'b1 || mem_addr === cpu_addr) begin
            $display("PASS: Write-through: mem_req=%0b, mem_addr=%0h", mem_req, mem_addr);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Write-through not observed (mem_req=%0b)", mem_req);
            fail_count = fail_count + 1;
        end
        cpu_req = 0;
        cpu_we  = 0;
        wait_cycles(2);

        // ================================================================
        // TEST 6: Write to all-zero address (edge case)
        // ================================================================
        rst = 1;
        wait_cycles(5);
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        cpu_addr  = 32'h0000_0000;
        cpu_wdata = 32'hFFFF_FFFF;
        cpu_req   = 1;
        cpu_we    = 1;
        mem_rdata = 32'h0000_0000;
        @(negedge clk);
        if (mem_req === 1'b1 || stall === 1'b1) begin
            $display("PASS: Write zero-addr: mem_req=%0b, stall=%0b", mem_req, stall);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Write zero-addr: no mem activity");
            fail_count = fail_count + 1;
        end
        cpu_req = 0;
        cpu_we  = 0;
        wait_cycles(2);

        // ================================================================
        // TEST 7: No request — outputs should be quiet (stall=0 when no request)
        // ================================================================
        rst = 1;
        wait_cycles(5);
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        cpu_req   = 0;
        cpu_we    = 0;
        cpu_addr  = 32'h0000_0000;
        cpu_wdata = 32'h0000_0000;
        mem_rdata = 32'h0000_0000;
        @(negedge clk);
        // When no request, stall should not be asserted
        if (stall === 1'b0) begin
            $display("PASS: No request: stall=0 as expected");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: No request but stall=%0b", stall);
            fail_count = fail_count + 1;
        end
        wait_cycles(2);

        // ================================================================
        // TEST 8: Read miss followed by mem_rdata — simulate fill response
        // ================================================================
        rst = 1;
        wait_cycles(5);
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        cpu_addr  = 32'h0000_0044; // index=1, tag=0x1
        cpu_req   = 1;
        cpu_we    = 0;
        mem_rdata = 32'hA5A5_A5A5;
        @(negedge clk);
        // On miss, stall or mem_req should be high
        if (stall === 1'b1 || mem_req === 1'b1) begin
            $display("PASS: Miss cycle: stall=%0b mem_req=%0b", stall, mem_req);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Expected miss on address 0x44");
            fail_count = fail_count + 1;
        end
        // Provide mem data for one more cycle
        @(posedge clk);
        @(negedge clk);
        cpu_req = 0;
        wait_cycles(2);

        // ================================================================
        // TEST 9: Maximum address read miss
        // ================================================================
        rst = 1;
        wait_cycles(5);
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        cpu_addr  = 32'hFFFF_FFFC;
        cpu_req   = 1;
        cpu_we    = 0;
        mem_rdata = 32'hFFFF_FFFF;
        @(negedge clk);
        if (mem_req === 1'b1 || stall === 1'b1) begin
            $display("PASS: Max address read miss (mem_req=%0b, stall=%0b)", mem_req, stall);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Max address: expected miss");
            fail_count = fail_count + 1;
        end
        cpu_req = 0;
        wait_cycles(2);

        // ================================================================
        // TEST 10: Reset during active request — stall should clear after reset
        // ================================================================
        @(posedge clk);
        cpu_addr = 32'h0000_0080;
        cpu_req  = 1;
        cpu_we   = 0;
        @(posedge clk);
        rst = 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        cpu_req = 0;
        @(posedge clk);
        @(negedge clk);
        if (stall === 1'b0) begin
            $display("PASS: After reset during request, stall cleared");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After reset, stall still asserted=%0b", stall);
            fail_count = fail_count + 1;
        end

        wait_cycles(2);

        // ================================================================
        // Summary
        // ================================================================
        $display("===================================");
        $display("RESULTS: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("===================================");

        $finish;
    end

endmodule
