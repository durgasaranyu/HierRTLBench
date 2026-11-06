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

    // Task: wait for rising edge and allow outputs to settle
    task wait_clk;
        begin
            @(posedge clk);
            #1; // small delay for output settling
        end
    endtask

    integer i;
    integer pass_count;
    integer fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize inputs
        rst = 1;
        req = 4'b0000;

        // Assert reset for exactly 5 clock rising edges
        repeat(5) @(posedge clk);
        #1;

        // Check reset clears grant
        if (grant === 4'b0000) begin
            $display("PASS: Reset clears grant to 0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Reset should clear grant to 0, got %b", grant);
            fail_count = fail_count + 1;
        end

        // Deassert reset
        rst = 0;
        @(posedge clk); #1;

        // Test 1: req = 0, grant should remain 0
        req = 4'b0000;
        @(posedge clk); #1;
        if (grant === 4'b0000) begin
            $display("PASS: grant=0 when req=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: grant should be 0 when req=0, got %b", grant);
            fail_count = fail_count + 1;
        end

        // Test 2: req = 4'b0001, grant should rotate left (shift left by 1)
        // After one clock with req=0001: next_grant = {req[2:0],1'b0} = 4'b0010
        req = 4'b0001;
        @(posedge clk); #1;
        if (grant === 4'b0010) begin
            $display("PASS: req=0001 gives grant=0010 (left rotation)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: req=0001 expected grant=0010, got %b", grant);
            fail_count = fail_count + 1;
        end

        // Test 3: req = 4'b0010, grant should become 4'b0100
        req = 4'b0010;
        @(posedge clk); #1;
        if (grant === 4'b0100) begin
            $display("PASS: req=0010 gives grant=0100 (left rotation)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: req=0010 expected grant=0100, got %b", grant);
            fail_count = fail_count + 1;
        end

        // Test 4: req = 4'b0100, grant should become 4'b1000
        req = 4'b0100;
        @(posedge clk); #1;
        if (grant === 4'b1000) begin
            $display("PASS: req=0100 gives grant=1000 (left rotation)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: req=0100 expected grant=1000, got %b", grant);
            fail_count = fail_count + 1;
        end

        // Test 5: req = 4'b1000, grant should become 4'b0000 (MSB shifts out, LSB=0)
        req = 4'b1000;
        @(posedge clk); #1;
        if (grant === 4'b0000) begin
            $display("PASS: req=1000 gives grant=0000 (MSB shifts out, wraps to 0)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: req=1000 expected grant=0000, got %b", grant);
            fail_count = fail_count + 1;
        end

        // Test 6: All-ones request - starvation test, verify rotation through all bits
        // Since req=1111, next_grant = {req[2:0],1'b0} = {1'b1,1'b1,1'b1,1'b0} = 4'b1110
        req = 4'b1111;
        @(posedge clk); #1;
        if (grant === 4'b1110) begin
            $display("PASS: req=1111, first rotation gives grant=1110");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: req=1111 expected grant=1110, got %b", grant);
            fail_count = fail_count + 1;
        end

        // Continue starvation test: grant should keep rotating left
        @(posedge clk); #1;
        if (grant === 4'b1100) begin
            $display("PASS: req=1111, second rotation gives grant=1100");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: req=1111 expected grant=1100 (2nd), got %b", grant);
            fail_count = fail_count + 1;
        end

        @(posedge clk); #1;
        if (grant === 4'b1000) begin
            $display("PASS: req=1111, third rotation gives grant=1000");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: req=1111 expected grant=1000 (3rd), got %b", grant);
            fail_count = fail_count + 1;
        end

        @(posedge clk); #1;
        if (grant === 4'b0000) begin
            $display("PASS: req=1111, fourth rotation gives grant=0000");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: req=1111 expected grant=0000 (4th), got %b", grant);
            fail_count = fail_count + 1;
        end

        // Test 7: mid-operation reset
        req = 4'b0101;
        @(posedge clk); #1;
        // Apply reset in the middle of operation
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        if (grant === 4'b0000) begin
            $display("PASS: Mid-operation reset clears grant to 0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Mid-operation reset expected grant=0, got %b", grant);
            fail_count = fail_count + 1;
        end
        rst = 0;

        // Test 8: All-zeros input after reset, grant stays 0
        req = 4'b0000;
        @(posedge clk); #1;
        if (grant === 4'b0000) begin
            $display("PASS: grant stays 0 when req=0 after reset");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: grant should stay 0, got %b", grant);
            fail_count = fail_count + 1;
        end

        // Test 9: Partial request - only bit 2 set
        req = 4'b0100;
        @(posedge clk); #1;
        if (grant === 4'b1000) begin
            $display("PASS: req=0100 gives grant=1000");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: req=0100 expected grant=1000, got %b", grant);
            fail_count = fail_count + 1;
        end

        // Test 10: req goes to 0 after partial request, grant should hold
        req = 4'b0000;
        @(posedge clk); #1;
        if (grant === 4'b1000) begin
            $display("PASS: grant holds when req=0 (was 1000)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: grant should hold at 1000, got %b", grant);
            fail_count = fail_count + 1;
        end

        // Summary
        $display("-----------------------------------");
        $display("Test Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("-----------------------------------");

        $finish;
    end

endmodule
