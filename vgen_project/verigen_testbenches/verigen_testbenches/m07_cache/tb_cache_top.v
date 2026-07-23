`timescale 1ns/1ps

module tb_cache_top;

    // Clock and reset
    reg clk;
    reg rst;

    // CPU interface
    reg         cpu_req;
    reg         cpu_we;
    reg  [31:0] cpu_addr;
    reg  [31:0] cpu_wdata;

    // Memory interface (driven by testbench as memory model)
    reg  [31:0] mem_rdata;

    // DUT outputs
    wire [31:0] cpu_rdata;
    wire        stall;
    wire [31:0] mem_addr;
    wire        mem_req;
    wire        mem_we;

    // Instantiate DUT
    // Note: mem_we is not in the module port list as shown, but we try to connect anyway
    // The module as given has: clk, rst, cpu_req, cpu_we, cpu_addr, cpu_wdata,
    //                          cpu_rdata, stall, mem_addr, mem_rdata, mem_req
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

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Helper task: wait N rising edges
    task wait_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    integer test_num;
    integer pass_count;
    integer fail_count;

    initial begin
        // Initialize
        rst      = 1;
        cpu_req  = 0;
        cpu_we   = 0;
        cpu_addr = 32'h0000_0000;
        cpu_wdata= 32'h0000_0000;
        mem_rdata= 32'h0000_0000;
        test_num  = 0;
        pass_count= 0;
        fail_count= 0;

        // Assert reset for exactly 5 rising edges
        @(posedge clk); // 1
        @(posedge clk); // 2
        @(posedge clk); // 3
        @(posedge clk); // 4
        @(posedge clk); // 5
        @(negedge clk);
        rst = 0;

        // Small settling time
        #2;

        //------------------------------------------------------------
        // TEST 1: Valid-bit reset — after reset, any request should miss
        //         (stall should be asserted or mem_req should be high)
        //------------------------------------------------------------
        test_num = 1;
        cpu_addr  = 32'hAABBCC04; // arbitrary address
        cpu_req   = 1;
        cpu_we    = 0;
        mem_rdata = 32'hDEAD_BEEF;
        @(posedge clk);
        #1;
        // After reset all valids are 0, so this must be a miss
        if (stall === 1'b1 || mem_req === 1'b1) begin
            $display("PASS: Test1 - valid-bit reset, read miss after rst (stall=%b mem_req=%b)", stall, mem_req);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test1 - expected stall or mem_req after reset, got stall=%b mem_req=%b", stall, mem_req);
            fail_count = fail_count + 1;
        end
        cpu_req = 0;
        wait_cycles(2);

        //------------------------------------------------------------
        // TEST 2: Read miss — uncached address, expect mem_req asserted
        //------------------------------------------------------------
        test_num = 2;
        cpu_addr  = 32'h0000_0010;
        cpu_req   = 1;
        cpu_we    = 0;
        mem_rdata = 32'h1234_5678;
        @(posedge clk);
        #1;
        if (mem_req === 1'b1) begin
            $display("PASS: Test2 - read miss, mem_req=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test2 - read miss expected mem_req=1, got mem_req=%b", mem_req);
            fail_count = fail_count + 1;
        end

        if (stall === 1'b1) begin
            $display("PASS: Test2b - read miss stall=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test2b - read miss expected stall=1, got stall=%b", stall);
            fail_count = fail_count + 1;
        end
        cpu_req = 0;
        wait_cycles(3);

        //------------------------------------------------------------
        // TEST 3: All-zero inputs
        //------------------------------------------------------------
        test_num = 3;
        cpu_addr  = 32'h0000_0000;
        cpu_req   = 1;
        cpu_we    = 0;
        mem_rdata = 32'h0000_0000;
        @(posedge clk);
        #1;
        // Check mem_addr is correct (should equal cpu_addr with offset cleared or same)
        // Just verify no X on outputs
        if (mem_req === 1'bx || stall === 1'bx) begin
            $display("FAIL: Test3 - all-zero addr produced X outputs (stall=%b mem_req=%b)", stall, mem_req);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS: Test3 - all-zero addr, outputs not X (stall=%b mem_req=%b)", stall, mem_req);
            pass_count = pass_count + 1;
        end
        cpu_req = 0;
        wait_cycles(2);

        //------------------------------------------------------------
        // TEST 4: All-ones inputs
        //------------------------------------------------------------
        test_num = 4;
        cpu_addr  = 32'hFFFF_FFFC;
        cpu_req   = 1;
        cpu_we    = 0;
        mem_rdata = 32'hFFFF_FFFF;
        @(posedge clk);
        #1;
        if (mem_req === 1'bx || stall === 1'bx) begin
            $display("FAIL: Test4 - all-ones addr produced X outputs");
            fail_count = fail_count + 1;
        end else begin
            $display("PASS: Test4 - all-ones addr, outputs not X (stall=%b mem_req=%b)", stall, mem_req);
            pass_count = pass_count + 1;
        end
        cpu_req = 0;
        wait_cycles(2);

        //------------------------------------------------------------
        // TEST 5: Write request — cpu_we=1, expect mem_req (write-through)
        //------------------------------------------------------------
        test_num = 5;
        cpu_addr  = 32'h0000_0020;
        cpu_wdata = 32'hCAFEBABE;
        cpu_req   = 1;
        cpu_we    = 1;
        mem_rdata = 32'h0000_0000;
        @(posedge clk);
        #1;
        // Write-through: mem_req should assert on write
        if (mem_req === 1'b1) begin
            $display("PASS: Test5 - write causes mem_req=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test5 - write expected mem_req=1, got mem_req=%b", mem_req);
            fail_count = fail_count + 1;
        end
        cpu_req = 0;
        cpu_we  = 0;
        wait_cycles(3);

        //------------------------------------------------------------
        // TEST 6: No request (cpu_req=0) — stall and mem_req should be low
        //------------------------------------------------------------
        test_num = 6;
        cpu_req  = 0;
        cpu_we   = 0;
        cpu_addr = 32'h0000_0040;
        @(posedge clk);
        #1;
        if (stall === 1'b0 && mem_req === 1'b0) begin
            $display("PASS: Test6 - no cpu_req, stall=0 mem_req=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test6 - no cpu_req expected stall=0 mem_req=0, got stall=%b mem_req=%b", stall, mem_req);
            fail_count = fail_count + 1;
        end
        wait_cycles(1);

        //------------------------------------------------------------
        // TEST 7: Read miss then simulate fill, check mem_addr alignment
        //------------------------------------------------------------
        test_num = 7;
        cpu_addr  = 32'h0000_0050;
        cpu_req   = 1;
        cpu_we    = 0;
        mem_rdata = 32'hABCD_1234;
        @(posedge clk);
        #1;
        // mem_addr should be aligned (lower 2 bits zero)
        if ((mem_addr[1:0] === 2'b00) || (mem_req === 1'b0)) begin
            $display("PASS: Test7 - read miss mem_addr aligned or no req (mem_addr=%h mem_req=%b)", mem_addr, mem_req);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test7 - mem_addr not aligned: %h", mem_addr);
            fail_count = fail_count + 1;
        end
        cpu_req = 0;
        wait_cycles(2);

        //------------------------------------------------------------
        // TEST 8: Maximum value address (max 32-bit)
        //------------------------------------------------------------
        test_num = 8;
        cpu_addr  = 32'hFFFF_FFFF;
        cpu_req   = 1;
        cpu_we    = 0;
        mem_rdata = 32'hFFFF_FFFF;
        @(posedge clk);
        #1;
        if (mem_req === 1'bx || stall === 1'bx || cpu_rdata === 32'bx) begin
            // X is acceptable only for mem_req/stall if module is incomplete
            $display("FAIL: Test8 - max address produced X on critical outputs");
            fail_count = fail_count + 1;
        end else begin
            $display("PASS: Test8 - max address handled without X (stall=%b mem_req=%b)", stall, mem_req);
            pass_count = pass_count + 1;
        end
        cpu_req = 0;
        wait_cycles(2);

        //------------------------------------------------------------
        // TEST 9: Reset during operation — valid bits cleared
        //------------------------------------------------------------
        test_num = 9;
        // Perform a request then reset
        cpu_addr  = 32'h0000_0060;
        cpu_req   = 1;
        cpu_we    = 0;
        mem_rdata = 32'h5A5A_5A5A;
        @(posedge clk);
        #1;

        // Now apply reset
        rst = 1;
        cpu_req = 0;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        rst = 0;
        #2;

        // After reset, same address should miss again
        cpu_addr = 32'h0000_0060;
        cpu_req  = 1;
        cpu_we   = 0;
        @(posedge clk);
        #1;
        if (stall === 1'b1 || mem_req === 1'b1) begin
            $display("PASS: Test9 - after re-reset, address misses again (stall=%b mem_req=%b)", stall, mem_req);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test9 - expected miss after re-reset, stall=%b mem_req=%b", stall, mem_req);
            fail_count = fail_count + 1;
        end
        cpu_req = 0;
        wait_cycles(2);

        //------------------------------------------------------------
        // TEST 10: Write with all-zero data
        //------------------------------------------------------------
        test_num = 10;
        cpu_addr  = 32'h0000_0080;
        cpu_wdata = 32'h0000_0000;
        cpu_req   = 1;
        cpu_we    = 1;
        mem_rdata = 32'h0;
        @(posedge clk);
        #1;
        if (mem_req === 1'bx) begin
            $display("FAIL: Test10 - write zero data produced X on mem_req");
            fail_count = fail_count + 1;
        end else begin
            $display("PASS: Test10 - write zero data, mem_req=%b stall=%b", mem_req, stall);
            pass_count = pass_count + 1;
        end
        cpu_req = 0;
        cpu_we  = 0;
        wait_cycles(2);

        //------------------------------------------------------------
        // Summary
        //------------------------------------------------------------
        $display("============================================");
        $display("Testbench complete: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("============================================");

        $finish;
    end

endmodule
