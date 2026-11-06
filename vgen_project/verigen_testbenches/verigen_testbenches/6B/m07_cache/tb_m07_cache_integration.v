`timescale 1ns/1ps
// Testbench for cache_top integration: miss->fill->hit sequence
module tb_m07_cache_integration;

    // DUT ports
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

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Timeout watchdog
    integer timeout_cnt;

    // Test variables
    integer i;
    integer pass_count;
    integer fail_count;
    reg test_passed;

    // Task: wait for stall to deassert with timeout
    task wait_for_stall_clear;
        input integer max_cycles;
        output reg timed_out;
        integer cnt;
        begin
            timed_out = 0;
            cnt = 0;
            while (stall && cnt < max_cycles) begin
                @(posedge clk);
                #1;
                cnt = cnt + 1;
            end
            if (cnt >= max_cycles) begin
                timed_out = 1;
            end
        end
    endtask

    // Task: apply mem_rdata when mem_req is seen (simple memory model)
    // We run this inline in the test sequence

    reg timed_out;

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize inputs
        rst      = 1;
        cpu_req  = 0;
        cpu_we   = 0;
        cpu_addr = 32'h0;
        cpu_wdata= 32'h0;
        mem_rdata= 32'h0;

        // Assert reset for exactly 5 rising edges
        @(posedge clk); // 1
        @(posedge clk); // 2
        @(posedge clk); // 3
        @(posedge clk); // 4
        @(posedge clk); // 5
        @(negedge clk);
        rst = 0;
        @(posedge clk);
        #1;

        // ----------------------------------------------------------------
        // TEST 1: Cold miss on address 0x00000010
        // ----------------------------------------------------------------
        cpu_addr  = 32'h00000010;
        cpu_wdata = 32'h0;
        cpu_we    = 0;
        cpu_req   = 1;
        mem_rdata = 32'hDEADBEEF;

        @(posedge clk); #1;

        // Expect stall asserted (miss)
        if (stall === 1'b1) begin
            $display("PASS: Cold miss on 0x00000010 causes stall");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Cold miss on 0x00000010 should cause stall, stall=%b", stall);
            fail_count = fail_count + 1;
        end

        // Wait for mem_req, provide data, wait for stall to clear
        // Give the cache up to 20 cycles to issue mem_req and complete fill
        begin : MISS1_WAIT
            integer cnt;
            cnt = 0;
            while (stall === 1'b1 && cnt < 30) begin
                // Keep providing mem_rdata whenever mem_req is high
                if (mem_req === 1'b1) begin
                    mem_rdata = 32'hDEADBEEF;
                end
                @(posedge clk); #1;
                cnt = cnt + 1;
            end
            timed_out = (cnt >= 30);
        end

        if (!timed_out && stall === 1'b0) begin
            $display("PASS: Stall clears after cache fill for 0x00000010");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Stall did not clear after fill for 0x00000010 (timed_out=%0d, stall=%b)", timed_out, stall);
            fail_count = fail_count + 1;
        end

        // Check cpu_rdata after stall clears
        if (cpu_rdata === 32'hDEADBEEF) begin
            $display("PASS: cpu_rdata=0xDEADBEEF after fill");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: cpu_rdata=0x%08X after fill, expected 0xDEADBEEF", cpu_rdata);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 2: Hit on same address 0x00000010 (no stall expected)
        // ----------------------------------------------------------------
        // Keep cpu_req asserted, same address
        @(posedge clk); #1;

        // On the next cycle after fill, requesting same address should hit
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'h00000010;

        @(posedge clk); #1;

        if (stall === 1'b0) begin
            $display("PASS: Cache hit on 0x00000010 - no stall");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Cache should hit on 0x00000010 (already filled), stall=%b", stall);
            fail_count = fail_count + 1;
        end

        if (cpu_rdata === 32'hDEADBEEF) begin
            $display("PASS: cpu_rdata=0xDEADBEEF on hit");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: cpu_rdata=0x%08X on hit, expected 0xDEADBEEF", cpu_rdata);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 3: Cold miss on a different address 0x00000020
        // ----------------------------------------------------------------
        cpu_addr  = 32'h00000020;
        cpu_wdata = 32'h0;
        cpu_we    = 0;
        cpu_req   = 1;
        mem_rdata = 32'hCAFEBABE;

        @(posedge clk); #1;

        // Expect stall
        if (stall === 1'b1) begin
            $display("PASS: Cold miss on 0x00000020 causes stall");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Cold miss on 0x00000020 should cause stall, stall=%b", stall);
            fail_count = fail_count + 1;
        end

        begin : MISS2_WAIT
            integer cnt;
            cnt = 0;
            while (stall === 1'b1 && cnt < 30) begin
                if (mem_req === 1'b1) begin
                    mem_rdata = 32'hCAFEBABE;
                end
                @(posedge clk); #1;
                cnt = cnt + 1;
            end
            timed_out = (cnt >= 30);
        end

        if (!timed_out && stall === 1'b0) begin
            $display("PASS: Stall clears after fill for 0x00000020");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Stall did not clear after fill for 0x00000020");
            fail_count = fail_count + 1;
        end

        if (cpu_rdata === 32'hCAFEBABE) begin
            $display("PASS: cpu_rdata=0xCAFEBABE after fill of 0x00000020");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: cpu_rdata=0x%08X after fill, expected 0xCAFEBABE", cpu_rdata);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 4: Second hit on address 0x00000020
        // ----------------------------------------------------------------
        @(posedge clk); #1;
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'h00000020;

        @(posedge clk); #1;

        if (stall === 1'b0) begin
            $display("PASS: Cache hit on 0x00000020 - no stall");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Cache should hit on 0x00000020, stall=%b", stall);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 5: No request (cpu_req=0) should not stall
        // ----------------------------------------------------------------
        cpu_req  = 0;
        cpu_addr = 32'h00000010;
        @(posedge clk); #1;

        if (stall === 1'b0) begin
            $display("PASS: No stall when cpu_req=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Unexpected stall when cpu_req=0, stall=%b", stall);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 6: Re-hit on 0x00000010 after no-request cycle
        // ----------------------------------------------------------------
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'h00000010;
        @(posedge clk); #1;

        if (stall === 1'b0) begin
            $display("PASS: Re-hit on 0x00000010 after idle - no stall");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Re-hit on 0x00000010 after idle caused stall=%b", stall);
            fail_count = fail_count + 1;
        end

        if (cpu_rdata === 32'hDEADBEEF) begin
            $display("PASS: cpu_rdata=0xDEADBEEF on re-hit of 0x00000010");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: cpu_rdata=0x%08X on re-hit, expected 0xDEADBEEF", cpu_rdata);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 7: Write (cpu_we=1) to cached address - write-through
        // ----------------------------------------------------------------
        cpu_req   = 1;
        cpu_we    = 1;
        cpu_addr  = 32'h00000010;
        cpu_wdata = 32'h12345678;
        @(posedge clk); #1;

        // Write-through: may or may not stall depending on implementation
        // Just check that it eventually completes
        if (stall === 1'b1) begin
            // Wait for write to complete
            begin : WRITE_WAIT
                integer cnt;
                cnt = 0;
                while (stall === 1'b1 && cnt < 30) begin
                    if (mem_req === 1'b1) begin
                        mem_rdata = 32'h12345678;
                    end
                    @(posedge clk); #1;
                    cnt = cnt + 1;
                end
                timed_out = (cnt >= 30);
            end
            if (!timed_out) begin
                $display("PASS: Write-through to 0x00000010 completed (had stall)");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Write-through to 0x00000010 timed out");
                fail_count = fail_count + 1;
            end
        end else begin
            $display("PASS: Write to 0x00000010 completed without stall");
            pass_count = pass_count + 1;
        end

        cpu_we  = 0;
        cpu_req = 0;

        // ----------------------------------------------------------------
        // TEST 8: Miss on a new address in the same set (set conflict)
        //         Address 0x00000110 maps to same index as 0x00000010
        //         (bits [5:2] = 4'h4 for both if index = addr[5:2])
        // ----------------------------------------------------------------
        // Direct-mapped: index = addr[5:2], so 0x00000010->index=4, 0x00000110->index=4 same set
        @(posedge clk); #1;

        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'h00000110; // same index, different tag
        mem_rdata = 32'hABCD1234;

        @(posedge clk); #1;

        // Should be a miss (different tag)
        if (stall === 1'b1) begin
            $display("PASS: Cold miss on 0x00000110 (same set, different tag) causes stall");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Expected miss-stall on 0x00000110, stall=%b", stall);
            fail_count = fail_count + 1;
        end

        begin : MISS3_WAIT
            integer cnt;
            cnt = 0;
            while (stall === 1'b1 && cnt < 30) begin
                if (mem_req === 1'b1) begin
                    mem_rdata = 32'hABCD1234;
                end
                @(posedge clk); #1;
                cnt = cnt + 1;
            end
            timed_out = (cnt >= 30);
        end

        if (!timed_out && stall === 1'b0) begin
            $display("PASS: Stall clears after fill for 0x00000110");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Stall did not clear after fill for 0x00000110");
            fail_count = fail_count + 1;
        end

        if (cpu_rdata === 32'hABCD1234) begin
            $display("PASS: cpu_rdata=0xABCD1234 after fill of 0x00000110");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: cpu_rdata=0x%08X, expected 0xABCD1234", cpu_rdata);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Summary
        // ----------------------------------------------------------------
        #20;
        $display("========================================");
        $display("Integration Test Summary: PASS=%0d FAIL=%0d", pass_count, fail_count);
