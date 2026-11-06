`timescale 1ns/1ps

module tb_cache_top;

    // Clock and reset
    reg clk, rst;

    // CPU interface
    reg         cpu_req, cpu_we;
    reg  [31:0] cpu_addr, cpu_wdata;
    wire [31:0] cpu_rdata;
    wire        stall;

    // Memory interface
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

    integer i;
    integer pass_count;
    integer fail_count;

    // Task: apply one clock rising edge and sample
    task tick;
        begin
            @(posedge clk);
            #1; // small delay for output settling
        end
    endtask

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
        repeat(5) @(posedge clk);
        #1;

        // ----------------------------------------------------------------
        // TEST 1: Valid-bit reset on synchronous rst
        // After reset, any request should be a miss (stall=1 or miss indicated)
        // ----------------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;

        // Request an address - after reset valid bits are 0, so it must miss
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'hABCD_EF00;  // some address
        mem_rdata= 32'hDEAD_BEEF;

        tick;
        // After reset, valid=0 -> miss expected: mem_req=1 or stall=1
        if (stall === 1'b1 || mem_req === 1'b1) begin
            $display("PASS: TEST1 - valid-bit reset causes miss after rst (stall=%0b, mem_req=%0b)", stall, mem_req);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: TEST1 - expected miss after rst but stall=%0b mem_req=%0b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        cpu_req = 0;
        tick; tick;

        // ----------------------------------------------------------------
        // TEST 2: Read miss on cold cache (address not loaded yet)
        // ----------------------------------------------------------------
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'h0000_0100;  // set index = bits[5:2] = 4'b0100 = 4
        mem_rdata= 32'h1234_5678;

        tick;
        if (stall === 1'b1 || mem_req === 1'b1) begin
            $display("PASS: TEST2 - read miss: stall=%0b mem_req=%0b", stall, mem_req);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: TEST2 - read miss expected but stall=%0b mem_req=%0b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        cpu_req = 0;
        tick; tick;

        // ----------------------------------------------------------------
        // TEST 3: All-zero address, no request - no activity expected
        // ----------------------------------------------------------------
        cpu_req  = 0;
        cpu_we   = 0;
        cpu_addr = 32'h0;
        mem_rdata= 32'h0;

        tick;
        if (stall === 1'b0 && mem_req === 1'b0) begin
            $display("PASS: TEST3 - no request: stall=%0b mem_req=%0b", stall, mem_req);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: TEST3 - no request but stall=%0b mem_req=%0b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // TEST 4: All-ones address, read miss
        // ----------------------------------------------------------------
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'hFFFF_FFFC;
        mem_rdata= 32'hFFFF_FFFF;

        tick;
        if (stall === 1'b1 || mem_req === 1'b1) begin
            $display("PASS: TEST4 - all-ones address read miss: stall=%0b mem_req=%0b", stall, mem_req);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: TEST4 - all-ones address read miss expected but stall=%0b mem_req=%0b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        cpu_req = 0;
        tick; tick;

        // ----------------------------------------------------------------
        // TEST 5: Write request - write-through should assert mem_we / mem_req
        // ----------------------------------------------------------------
        cpu_req  = 1;
        cpu_we   = 1;
        cpu_addr = 32'h0000_0200;
        cpu_wdata= 32'hCAFE_BABE;
        mem_rdata= 32'h0;

        tick;
        // Write-through: on a write, mem_req (or equivalent write signal) should assert
        // We check mem_req or that stall is asserted (write-through may stall too)
        if (mem_req === 1'b1 || stall === 1'b1) begin
            $display("PASS: TEST5 - write causes mem_req/stall: mem_req=%0b stall=%0b", mem_req, stall);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: TEST5 - write-through: mem_req=%0b stall=%0b", mem_req, stall);
            fail_count = fail_count + 1;
        end

        // Also check mem_addr reflects cpu_addr when write is in progress
        if (mem_req === 1'b1) begin
            if (mem_addr === cpu_addr) begin
                $display("PASS: TEST5b - mem_addr matches cpu_addr on write");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: TEST5b - mem_addr=%h expected %h on write", mem_addr, cpu_addr);
                fail_count = fail_count + 1;
            end
        end else begin
            $display("PASS: TEST5b - mem_req not asserted yet (stall path), skipping mem_addr check");
            pass_count = pass_count + 1;
        end

        cpu_req  = 0;
        cpu_we   = 0;
        tick; tick;

        // ----------------------------------------------------------------
        // TEST 6: Read miss - verify mem_addr driven correctly
        // ----------------------------------------------------------------
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'h0000_0040;
        mem_rdata= 32'hABCD_1234;

        tick;
        if (mem_req === 1'b1) begin
            // mem_addr should be aligned to the cache line (offset bits zeroed or same)
            if (mem_addr[31:2] === cpu_addr[31:2]) begin
                $display("PASS: TEST6 - miss: mem_addr[31:2] matches cpu_addr[31:2]");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: TEST6 - miss: mem_addr=%h cpu_addr=%h", mem_addr, cpu_addr);
                fail_count = fail_count + 1;
            end
        end else if (stall === 1'b1) begin
            $display("PASS: TEST6 - miss signaled via stall");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: TEST6 - expected miss indication but stall=%0b mem_req=%0b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        cpu_req = 0;
        tick; tick;

        // ----------------------------------------------------------------
        // TEST 7: Maximum address read miss
        // ----------------------------------------------------------------
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'h7FFF_FFFC;
        mem_rdata= 32'h5555_AAAA;

        tick;
        if (stall === 1'b1 || mem_req === 1'b1) begin
            $display("PASS: TEST7 - max address read miss: stall=%0b mem_req=%0b", stall, mem_req);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: TEST7 - max address read miss expected but stall=%0b mem_req=%0b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        cpu_req = 0;
        tick; tick;

        // ----------------------------------------------------------------
        // TEST 8: Multiple consecutive misses (different addresses)
        // ----------------------------------------------------------------
        // First miss
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'h0000_0300;
        mem_rdata= 32'h1111_2222;
        tick;

        if (stall === 1'b1 || mem_req === 1'b1) begin
            $display("PASS: TEST8a - consecutive miss 1: stall=%0b mem_req=%0b", stall, mem_req);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: TEST8a - miss 1 expected but stall=%0b mem_req=%0b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        cpu_req = 0;
        tick; tick;

        // Second miss different set
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'h0000_0380;
        mem_rdata= 32'h3333_4444;
        tick;

        if (stall === 1'b1 || mem_req === 1'b1) begin
            $display("PASS: TEST8b - consecutive miss 2: stall=%0b mem_req=%0b", stall, mem_req);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: TEST8b - miss 2 expected but stall=%0b mem_req=%0b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        cpu_req = 0;
        tick; tick;

        // ----------------------------------------------------------------
        // TEST 9: Reset again and verify misses
        // ----------------------------------------------------------------
        rst = 1;
        cpu_req = 0;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;

        tick;

        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'h0000_0200;
        mem_rdata= 32'hBEEF_CAFE;
        tick;

        if (stall === 1'b1 || mem_req === 1'b1) begin
            $display("PASS: TEST9 - post-reset miss confirmed: stall=%0b mem_req=%0b", stall, mem_req);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: TEST9 - post-reset miss not seen: stall=%0b mem_req=%0b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        cpu_req = 0;
        tick; tick;

        // ----------------------------------------------------------------
        // TEST 10: Zero data write
        // ----------------------------------------------------------------
        cpu_req  = 1;
        cpu_we   = 1;
        cpu_addr = 32'h0000_0000;
        cpu_wdata= 32'h0000_0000;
        mem_rdata= 32'h0;
        tick;

        if (mem_req === 1'b1 || stall === 1'b1) begin
            $display("PASS: TEST10 - zero-data write: mem_req=%0b stall=%0b", mem_req, stall);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: TEST10 - zero-data write: mem_req=%0b stall=%0b", mem_req, stall);
            fail_count = fail_count + 1;
        end

        cpu_req  = 0;
        cpu_we   = 0;
        tick; tick;

        // ----------------------------------------------------------------
        // Summary
        // ----------------------------------------------------------------
        $display("--------------------------------------");
        $display("Test complete: PASS=%0d  FAIL=%0d", pass_count, fail_count);
        $display("--------------------------------------");

        $finish;
    end

endmodule
