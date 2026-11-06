`timescale 1ns/1ps

module tb_cache_top;

    // Clock and reset
    reg clk, rst;

    // CPU-side inputs
    reg         cpu_req;
    reg         cpu_we;
    reg  [31:0] cpu_addr;
    reg  [31:0] cpu_wdata;

    // CPU-side outputs
    wire [31:0] cpu_rdata;
    wire        stall;

    // Memory-side
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

    // Task: apply one cycle
    task apply_cycle;
        begin
            @(posedge clk);
            #1; // small delay after posedge to sample outputs
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
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // ---------------------------------------------------------------
        // TEST 1: After reset, valid bits should be cleared.
        // A read request to any address should result in a miss (stall=1, mem_req=1)
        // ---------------------------------------------------------------
        @(negedge clk);
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'hA0000004; // index=1, tag=...
        cpu_wdata= 32'h0;
        mem_rdata= 32'hDEADBEEF;
        apply_cycle;

        if (stall === 1'b1 || mem_req === 1'b1) begin
            $display("PASS: Test1 - After reset, read miss causes stall/mem_req");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test1 - After reset expected stall or mem_req high, got stall=%b mem_req=%b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        // De-assert request
        cpu_req = 0;
        apply_cycle;

        // ---------------------------------------------------------------
        // TEST 2: All-zero address read miss check
        // ---------------------------------------------------------------
        @(negedge clk);
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'h00000000;
        cpu_wdata= 32'h0;
        mem_rdata= 32'hCAFEBABE;
        apply_cycle;

        if (stall === 1'b1 || mem_req === 1'b1) begin
            $display("PASS: Test2 - All-zero address read miss");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test2 - All-zero address read miss expected stall/mem_req, got stall=%b mem_req=%b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        cpu_req = 0;
        apply_cycle;

        // ---------------------------------------------------------------
        // TEST 3: All-ones address read miss check
        // ---------------------------------------------------------------
        @(negedge clk);
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'hFFFFFFFC;
        cpu_wdata= 32'h0;
        mem_rdata= 32'hFFFFFFFF;
        apply_cycle;

        if (stall === 1'b1 || mem_req === 1'b1) begin
            $display("PASS: Test3 - All-ones address read miss");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test3 - All-ones address expected stall/mem_req, got stall=%b mem_req=%b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        cpu_req = 0;
        apply_cycle;

        // ---------------------------------------------------------------
        // TEST 4: Write request — cpu_we=1, expect mem_req or stall or mem_we behavior
        //         (write-through: any write should propagate to memory)
        // ---------------------------------------------------------------
        @(negedge clk);
        cpu_req  = 1;
        cpu_we   = 1;
        cpu_addr = 32'h00000008;
        cpu_wdata= 32'h12345678;
        mem_rdata= 32'h0;
        apply_cycle;

        // For write-through: either mem_req asserts or stall asserts indicating write-through
        if (mem_req === 1'b1 || stall === 1'b1) begin
            $display("PASS: Test4 - Write causes mem_req or stall (write-through)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test4 - Write expected mem_req or stall, got stall=%b mem_req=%b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        cpu_req  = 0;
        cpu_we   = 0;
        apply_cycle;

        // ---------------------------------------------------------------
        // TEST 5: No request (cpu_req=0) — no stall, no mem_req
        // ---------------------------------------------------------------
        @(negedge clk);
        cpu_req  = 0;
        cpu_we   = 0;
        cpu_addr = 32'h00000010;
        cpu_wdata= 32'h0;
        mem_rdata= 32'h0;
        apply_cycle;

        if (stall === 1'b0 && mem_req === 1'b0) begin
            $display("PASS: Test5 - No request gives no stall and no mem_req");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test5 - No request, expected stall=0 mem_req=0, got stall=%b mem_req=%b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // TEST 6: Read miss on maximum index (index=15)
        // Address: index bits [5:2] = 4'b1111, so addr[5:2]=4'hF
        // addr = {tag, 4'hF, 2'b00} = 32'h000000_3C (tag=0, index=15, offset=0)
        // ---------------------------------------------------------------
        @(negedge clk);
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'h0000003C; // index=15, tag=0
        cpu_wdata= 32'h0;
        mem_rdata= 32'hAABBCCDD;
        apply_cycle;

        if (stall === 1'b1 || mem_req === 1'b1) begin
            $display("PASS: Test6 - Max index (15) read miss");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test6 - Max index read miss expected stall/mem_req, got stall=%b mem_req=%b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        cpu_req = 0;
        apply_cycle;

        // ---------------------------------------------------------------
        // TEST 7: Re-assert reset, verify that valid bits clear (miss after reset)
        // ---------------------------------------------------------------
        @(negedge clk);
        rst = 1;
        cpu_req = 0;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;
        @(negedge clk);

        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'hA0000004;
        cpu_wdata= 32'h0;
        mem_rdata= 32'h11223344;
        apply_cycle;

        if (stall === 1'b1 || mem_req === 1'b1) begin
            $display("PASS: Test7 - After second reset, valid bits cleared (miss)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test7 - After second reset expected miss, got stall=%b mem_req=%b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        cpu_req = 0;
        apply_cycle;

        // ---------------------------------------------------------------
        // TEST 8: Write to index=0 with all-ones data
        // ---------------------------------------------------------------
        @(negedge clk);
        cpu_req  = 1;
        cpu_we   = 1;
        cpu_addr = 32'hFFFFFF00; // index=0, tag=all-ones
        cpu_wdata= 32'hFFFFFFFF;
        mem_rdata= 32'h0;
        apply_cycle;

        if (mem_req === 1'b1 || stall === 1'b1) begin
            $display("PASS: Test8 - Write all-ones data causes mem_req or stall");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test8 - Write all-ones expected mem_req/stall, got stall=%b mem_req=%b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        cpu_req  = 0;
        cpu_we   = 0;
        apply_cycle;

        // ---------------------------------------------------------------
        // TEST 9: Multiple cycles with no request — stable outputs
        // ---------------------------------------------------------------
        @(negedge clk);
        cpu_req  = 0;
        cpu_we   = 0;
        cpu_addr = 32'h0;
        cpu_wdata= 32'h0;
        repeat (3) begin
            apply_cycle;
        end

        if (stall === 1'b0 && mem_req === 1'b0) begin
            $display("PASS: Test9 - Stable no-request: stall=0, mem_req=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test9 - Stable no-request, got stall=%b mem_req=%b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // TEST 10: Read miss on index=0, tag=1 (non-zero tag)
        // ---------------------------------------------------------------
        @(negedge clk);
        cpu_req  = 1;
        cpu_we   = 0;
        cpu_addr = 32'h00000040; // tag=1, index=0, offset=0
        cpu_wdata= 32'h0;
        mem_rdata= 32'h55AA55AA;
        apply_cycle;

        if (stall === 1'b1 || mem_req === 1'b1) begin
            $display("PASS: Test10 - Non-zero tag read miss");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test10 - Non-zero tag expected miss, got stall=%b mem_req=%b", stall, mem_req);
            fail_count = fail_count + 1;
        end

        cpu_req = 0;
        apply_cycle;

        // Summary
        $display("--------------------------------------------------");
        $display("Results: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("--------------------------------------------------");

        $finish;
    end

endmodule
