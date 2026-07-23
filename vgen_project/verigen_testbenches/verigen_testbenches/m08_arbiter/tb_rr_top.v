`timescale 1ns/1ps

module tb_rr_top;

    // Parameters
    parameter N = 4;

    // DUT connections
    reg         clk;
    reg         rst;
    reg  [N-1:0] req;
    wire [N-1:0] grant;

    // Instantiate DUT
    round_robin_arbiter #(.N(N)) uut (
        .clk   (clk),
        .rst   (rst),
        .req   (req),
        .grant (grant)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Helper: wait n rising edges
    task wait_cycles;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1)
                @(posedge clk);
        end
    endtask

    // Test tracking
    integer test_num;
    integer pass_count;
    integer fail_count;

    // Grant capture variables
    reg [N-1:0] captured_grant;
    integer     cycle;
    integer     grants_seen;
    reg [N-1:0] grant_mask;

    initial begin
        // Initialise
        rst       = 1;
        req       = 4'b0000;
        test_num  = 0;
        pass_count = 0;
        fail_count = 0;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;

        // ----------------------------------------------------------------
        // Test 1: After reset, grant should be 0 when req=0
        // ----------------------------------------------------------------
        @(negedge clk);
        req = 4'b0000;
        @(posedge clk); #1;
        if (grant === 4'b0000) begin
            $display("PASS: Test1 - grant=0 when req=0 after reset");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test1 - grant=0 when req=0 after reset, got %b", grant);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 2: Single request bit 0 gets granted
        // ----------------------------------------------------------------
        @(negedge clk);
        req = 4'b0001;
        @(posedge clk); #1;
        @(posedge clk); #1;
        captured_grant = grant;
        if (captured_grant[0] === 1'b1) begin
            $display("PASS: Test2 - single req[0] is granted");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test2 - single req[0] not granted, grant=%b", captured_grant);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 3: Single request bit 1 gets granted
        // ----------------------------------------------------------------
        @(negedge clk);
        req = 4'b0010;
        @(posedge clk); #1;
        @(posedge clk); #1;
        captured_grant = grant;
        if (captured_grant[1] === 1'b1) begin
            $display("PASS: Test3 - single req[1] is granted");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test3 - single req[1] not granted, grant=%b", captured_grant);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 4: All requests high - starvation test, all bits granted in rotation
        // ----------------------------------------------------------------
        @(negedge clk);
        req = 4'b1111;
        grant_mask = 4'b0000;
        // Run for enough cycles to see all 4 bits granted
        for (cycle = 0; cycle < 16; cycle = cycle + 1) begin
            @(posedge clk); #1;
            grant_mask = grant_mask | grant;
        end
        if (grant_mask === 4'b1111) begin
            $display("PASS: Test4 - all-ones req, all bits granted in rotation (grant_mask=%b)", grant_mask);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test4 - not all bits granted in rotation (grant_mask=%b)", grant_mask);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 5: Reset clears grant register
        // ----------------------------------------------------------------
        @(negedge clk);
        req = 4'b1111;
        @(posedge clk); #1;
        // Now assert reset
        rst = 1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;
        req = 4'b0000;
        @(posedge clk); #1;
        captured_grant = grant;
        if (captured_grant === 4'b0000) begin
            $display("PASS: Test5 - reset clears grant register");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test5 - reset did not clear grant, grant=%b", captured_grant);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 6: After reset release with req=0, grant stays 0
        // ----------------------------------------------------------------
        @(negedge clk);
        req = 4'b0000;
        repeat (4) @(posedge clk);
        #1;
        captured_grant = grant;
        if (captured_grant === 4'b0000) begin
            $display("PASS: Test6 - grant stays 0 with req=0 after reset");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test6 - grant not 0 with req=0, grant=%b", captured_grant);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 7: Only bit 3 requested
        // ----------------------------------------------------------------
        @(negedge clk);
        req = 4'b1000;
        @(posedge clk); #1;
        @(posedge clk); #1;
        captured_grant = grant;
        if (captured_grant[3] === 1'b1) begin
            $display("PASS: Test7 - single req[3] is granted");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test7 - single req[3] not granted, grant=%b", captured_grant);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 8: Two bits requested - both should be granted over time
        // ----------------------------------------------------------------
        @(negedge clk);
        req = 4'b0101; // bits 0 and 2
        grant_mask = 4'b0000;
        for (cycle = 0; cycle < 12; cycle = cycle + 1) begin
            @(posedge clk); #1;
            grant_mask = grant_mask | grant;
        end
        // At minimum, the requested bits (0 and 2) should both appear
        if ((grant_mask & 4'b0101) === 4'b0101) begin
            $display("PASS: Test8 - req bits 0,2: both granted over time (grant_mask=%b)", grant_mask);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test8 - req bits 0,2: not both granted (grant_mask=%b)", grant_mask);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 9: Rotation order - bit 0 granted, then bit 1 should follow
        // ----------------------------------------------------------------
        // Reset first for clean state
        @(negedge clk);
        rst = 1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;
        req = 4'b0011; // bits 0 and 1
        grant_mask = 4'b0000;
        // collect grants over several cycles
        for (cycle = 0; cycle < 10; cycle = cycle + 1) begin
            @(posedge clk); #1;
            grant_mask = grant_mask | grant;
        end
        if ((grant_mask & 4'b0011) === 4'b0011) begin
            $display("PASS: Test9 - rotation: both bit0 and bit1 granted (grant_mask=%b)", grant_mask);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test9 - rotation: not both bit0 and bit1 granted (grant_mask=%b)", grant_mask);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 10: All-ones input extended starvation check - no bit starved
        // ----------------------------------------------------------------
        @(negedge clk);
        rst = 1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;
        req = 4'b1111;
        grant_mask = 4'b0000;
        grants_seen = 0;
        for (cycle = 0; cycle < 20; cycle = cycle + 1) begin
            @(posedge clk); #1;
            grant_mask = grant_mask | grant;
        end
        if (grant_mask === 4'b1111) begin
            $display("PASS: Test10 - no starvation, all 4 bits granted (grant_mask=%b)", grant_mask);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test10 - starvation detected (grant_mask=%b)", grant_mask);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Summary
        // ----------------------------------------------------------------
        $display("-------------------------------");
        $display("Tests complete: PASS=%0d, FAIL=%0d", pass_count, fail_count);
        $display("-------------------------------");

        $finish;
    end

endmodule
