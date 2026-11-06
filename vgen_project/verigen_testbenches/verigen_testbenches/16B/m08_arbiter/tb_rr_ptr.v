`timescale 1ns/1ps

module tb_rr_ptr;

    // Parameters
    parameter N = 4;

    // DUT connections
    reg            clk;
    reg            rst;
    reg  [N-1:0]   grant;
    wire [N-1:0]   ptr;

    // Instantiate DUT
    rr_ptr #(.N(N)) uut (
        .clk   (clk),
        .rst   (rst),
        .grant (grant),
        .ptr   (ptr)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Task to apply one cycle and check
    task apply_and_check;
        input [N-1:0] grant_in;
        input [N-1:0] expected_ptr;
        input [63:0]  desc_num;
        begin
            grant = grant_in;
            @(posedge clk);
            #1; // small delay after posedge to let output settle
            if (ptr === expected_ptr)
                $display("PASS: Test %0d - grant=%b, ptr=%b (expected %b)", desc_num, grant_in, ptr, expected_ptr);
            else
                $display("FAIL: Test %0d - grant=%b, ptr=%b (expected %b)", desc_num, grant_in, ptr, expected_ptr);
        end
    endtask

    integer i;

    initial begin
        // Initialize
        rst   = 1;
        grant = 0;

        // Assert reset for exactly 5 rising edges
        repeat(5) @(posedge clk);
        #1;

        // Check reset clears ptr to 0
        if (ptr === {N{1'b0}})
            $display("PASS: Reset - ptr cleared to 0 (ptr=%b)", ptr);
        else
            $display("FAIL: Reset - ptr should be 0 but got ptr=%b", ptr);

        // Deassert reset
        rst = 0;
        @(negedge clk);

        // ---------------------------------------------------------------
        // Test 1: grant=0, ptr should stay at 0 (no grant, no change)
        // After reset ptr=0, grant=0 -> ptr stays 0
        // We check ptr BEFORE next posedge by sampling after a negedge
        grant = 4'b0000;
        @(posedge clk);
        #1;
        if (ptr === 4'b0000)
            $display("PASS: Test 1 - grant=0, ptr stays 0 (ptr=%b)", ptr);
        else
            $display("FAIL: Test 1 - grant=0, ptr should stay 0, got ptr=%b", ptr);

        // ---------------------------------------------------------------
        // Test 2: grant bit 0 -> ptr should advance to 1
        // ptr=0, grant=0001 -> ptr becomes (0+1)%4 = 1
        grant = 4'b0001;
        @(posedge clk);
        #1;
        if (ptr === 4'b0001)
            $display("PASS: Test 2 - grant=0001, ptr advanced to 1 (ptr=%b)", ptr);
        else
            $display("FAIL: Test 2 - grant=0001, ptr should be 1, got ptr=%b", ptr);

        // ---------------------------------------------------------------
        // Test 3: grant bit 1 -> ptr should advance to 2 (verify rotation from 1)
        // ptr=1, grant=0010 -> ptr becomes (1+1)%4 = 2
        grant = 4'b0010;
        @(posedge clk);
        #1;
        if (ptr === 4'b0010)
            $display("PASS: Test 3 - grant=0010, ptr advanced to 2 (ptr=%b)", ptr);
        else
            $display("FAIL: Test 3 - grant=0010, ptr should be 2, got ptr=%b", ptr);

        // ---------------------------------------------------------------
        // Test 4: grant bit 2 -> ptr should advance to 3
        // ptr=2, grant=0100 -> ptr becomes (2+1)%4 = 3
        grant = 4'b0100;
        @(posedge clk);
        #1;
        if (ptr === 4'b0011)
            $display("PASS: Test 4 - grant=0100, ptr advanced to 3 (ptr=%b)", ptr);
        else
            $display("FAIL: Test 4 - grant=0100, ptr should be 3, got ptr=%b", ptr);

        // ---------------------------------------------------------------
        // Test 5: grant bit 3 -> ptr should wrap to 0 (rollover test)
        // ptr=3, grant=1000 -> ptr becomes (3+1)%4 = 0
        grant = 4'b1000;
        @(posedge clk);
        #1;
        if (ptr === 4'b0000)
            $display("PASS: Test 5 - grant=1000, ptr wraps to 0 (ptr=%b)", ptr);
        else
            $display("FAIL: Test 5 - grant=1000, ptr should wrap to 0, got ptr=%b", ptr);

        // ---------------------------------------------------------------
        // Test 6: All-ones grant (starvation test: hold all bits high, verify full rotation)
        // ptr=0, grant=1111 -> ptr cycles through 1,2,3,0
        // Cycle 1: ptr=0 -> grant=1111 -> ptr becomes 1
        grant = 4'b1111;
        @(posedge clk);
        #1;
        if (ptr === 4'b0001)
            $display("PASS: Test 6a - all-ones grant, ptr=1 (ptr=%b)", ptr);
        else
            $display("FAIL: Test 6a - all-ones grant, ptr should be 1, got ptr=%b", ptr);

        // Cycle 2: ptr=1 -> grant=1111 -> ptr becomes 2
        @(posedge clk);
        #1;
        if (ptr === 4'b0010)
            $display("PASS: Test 6b - all-ones grant, ptr=2 (ptr=%b)", ptr);
        else
            $display("FAIL: Test 6b - all-ones grant, ptr should be 2, got ptr=%b", ptr);

        // Cycle 3: ptr=2 -> grant=1111 -> ptr becomes 3
        @(posedge clk);
        #1;
        if (ptr === 4'b0011)
            $display("PASS: Test 6c - all-ones grant, ptr=3 (ptr=%b)", ptr);
        else
            $display("FAIL: Test 6c - all-ones grant, ptr should be 3, got ptr=%b", ptr);

        // Cycle 4: ptr=3 -> grant=1111 -> ptr becomes 0 (full rotation complete)
        @(posedge clk);
        #1;
        if (ptr === 4'b0000)
            $display("PASS: Test 6d - all-ones grant, ptr=0 wrap (ptr=%b, full rotation verified)", ptr);
        else
            $display("FAIL: Test 6d - all-ones grant, ptr should be 0, got ptr=%b", ptr);

        // ---------------------------------------------------------------
        // Test 7: Reset in the middle of operation, verify ptr clears
        grant = 4'b0000;
        rst   = 1;
        @(posedge clk);
        #1;
        if (ptr === 4'b0000)
            $display("PASS: Test 7 - mid-operation reset, ptr=0 (ptr=%b)", ptr);
        else
            $display("FAIL: Test 7 - mid-operation reset, ptr should be 0, got ptr=%b", ptr);

        rst = 0;
        @(posedge clk);
        #1;

        // ---------------------------------------------------------------
        // Test 8: Grant=0 after reset, ensure no spurious increment
        // ptr=0, grant=0000 for 3 cycles, ptr should stay 0
        grant = 4'b0000;
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;
        @(posedge clk);
        #1;
        if (ptr === 4'b0000)
            $display("PASS: Test 8 - grant=0 for 3 cycles, ptr stays 0 (ptr=%b)", ptr);
        else
            $display("FAIL: Test 8 - grant=0, ptr should stay 0, got ptr=%b", ptr);

        // ---------------------------------------------------------------
        // Test 9: Single grant then no grant - ptr advances then holds
        // ptr=0, grant=0001 -> ptr=1; then grant=0, ptr stays 1
        grant = 4'b0001;
        @(posedge clk);
        #1;
        grant = 4'b0000;
        @(posedge clk);
        #1;
        if (ptr === 4'b0001)
            $display("PASS: Test 9 - grant then no grant, ptr holds at 1 (ptr=%b)", ptr);
        else
            $display("FAIL: Test 9 - after grant then no grant, ptr should be 1, got ptr=%b", ptr);

        // ---------------------------------------------------------------
        // Test 10: Alternate grant bits to verify independent rotation
        // ptr=1, grant=0010 -> ptr=2; grant=0100 -> ptr=3; grant=0001 -> ptr=0
        grant = 4'b0010;
        @(posedge clk);
        #1;
        if (ptr === 4'b0010)
            $display("PASS: Test 10a - grant=0010, ptr=2 (ptr=%b)", ptr);
        else
            $display("FAIL: Test 10a - grant=0010, ptr should be 2, got ptr=%b", ptr);

        grant = 4'b0100;
        @(posedge clk);
        #1;
        if (ptr === 4'b0011)
            $display("PASS: Test 10b - grant=0100, ptr=3 (ptr=%b)", ptr);
        else
            $display("FAIL: Test 10b - grant=0100, ptr should be 3, got ptr=%b", ptr);

        grant = 4'b0001;
        @(posedge clk);
        #1;
        if (ptr === 4'b0000)
            $display("PASS: Test 10c - grant=0001 from ptr=3, ptr wraps to 0 (ptr=%b)", ptr);
        else
            $display("FAIL: Test 10c - grant=0001 from ptr=3, ptr should wrap to 0, got ptr=%b", ptr);

        // Done
        $display("All tests complete.");
        $finish;
    end

endmodule
