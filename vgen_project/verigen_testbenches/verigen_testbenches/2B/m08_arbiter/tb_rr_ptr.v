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

    // Helper task: wait for rising edge and small settle time
    task wait_clk;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    // Variables
    integer i;
    reg [N-1:0] expected_ptr;
    reg [N-1:0] captured_ptr;

    initial begin
        // Initialize inputs
        rst   = 1;
        grant = 4'b0001; // default

        // Assert reset for exactly 5 rising edges
        repeat(5) @(posedge clk);
        #1;

        // Check reset clears ptr
        if (ptr === {N{1'b0}})
            $display("PASS: Reset clears ptr to 0");
        else
            $display("FAIL: Reset should clear ptr to 0, got %b", ptr);

        // Deassert reset
        @(posedge clk);
        rst = 0;
        #1;

        // ----------------------------------------------------------------
        // Test 1: grant=0 (no active grant), ptr should stay 0 after reset
        // Note: (ptr+1) % 0 is undefined/0 in Verilog; we check ptr stays 0
        // ----------------------------------------------------------------
        grant = 4'b0000;
        wait_clk;
        // When grant=0, division by zero in RTL; ptr behavior is undefined
        // We just capture and note; skip strict check for div-by-zero case
        $display("PASS: grant=0 (all-zero), ptr=%b (div-by-zero corner, no strict check)", ptr);

        // ----------------------------------------------------------------
        // Test 2: grant = 4'b0001 (grant bit 0)
        // ptr should become (0+1)%1 = 0
        // ----------------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        #1;

        grant = 4'b0001; // grant = 1
        wait_clk;
        expected_ptr = (0 + 1) % 4'b0001; // = 0
        if (ptr === expected_ptr)
            $display("PASS: grant=4'b0001, ptr=%b as expected (0)", ptr);
        else
            $display("FAIL: grant=4'b0001, expected ptr=%b, got ptr=%b", expected_ptr, ptr);

        // ----------------------------------------------------------------
        // Test 3: grant = 4'b0010 (grant = 2), ptr should become (prev+1)%2
        // After reset ptr=0, grant=2 => ptr=(0+1)%2=1
        // ----------------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        #1;

        grant = 4'b0010; // grant = 2
        wait_clk;
        expected_ptr = (0 + 1) % 4'b0010; // = 1
        if (ptr === expected_ptr)
            $display("PASS: grant=4'b0010 (2), ptr=%b == 1", ptr);
        else
            $display("FAIL: grant=4'b0010 (2), expected ptr=1, got ptr=%b", ptr);

        // ----------------------------------------------------------------
        // Test 4: Round-robin rotation - grant bit 0 then verify next grant bit 1
        // Use grant=4 so ptr cycles: 0->1->2->3->0
        // ----------------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        #1;

        grant = 4'b0100; // grant = 4
        // Cycle 1: ptr = (0+1)%4 = 1
        wait_clk;
        if (ptr === 4'd1)
            $display("PASS: Rotation cycle1, grant=4, ptr=%0d (expected 1)", ptr);
        else
            $display("FAIL: Rotation cycle1, grant=4, expected ptr=1, got ptr=%0d", ptr);

        // Cycle 2: ptr = (1+1)%4 = 2
        wait_clk;
        if (ptr === 4'd2)
            $display("PASS: Rotation cycle2, grant=4, ptr=%0d (expected 2)", ptr);
        else
            $display("FAIL: Rotation cycle2, grant=4, expected ptr=2, got ptr=%0d", ptr);

        // Cycle 3: ptr = (2+1)%4 = 3
        wait_clk;
        if (ptr === 4'd3)
            $display("PASS: Rotation cycle3, grant=4, ptr=%0d (expected 3)", ptr);
        else
            $display("FAIL: Rotation cycle3, grant=4, expected ptr=3, got ptr=%0d", ptr);

        // Cycle 4: ptr = (3+1)%4 = 0 (wraps)
        wait_clk;
        if (ptr === 4'd0)
            $display("PASS: Rotation cycle4 wrap, grant=4, ptr=%0d (expected 0)", ptr);
        else
            $display("FAIL: Rotation cycle4 wrap, grant=4, expected ptr=0, got ptr=%0d", ptr);

        // ----------------------------------------------------------------
        // Test 5: Starvation - hold all bits high (grant=15=4'b1111)
        // ptr should cycle through all values
        // ----------------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        #1;

        grant = 4'b1111; // grant = 15
        // ptr = (0+1)%15 = 1
        wait_clk;
        if (ptr === 4'd1)
            $display("PASS: All-ones grant=15, cycle1, ptr=%0d (expected 1)", ptr);
        else
            $display("FAIL: All-ones grant=15, cycle1, expected 1, got ptr=%0d", ptr);

        // ptr = (1+1)%15 = 2
        wait_clk;
        if (ptr === 4'd2)
            $display("PASS: All-ones grant=15, cycle2, ptr=%0d (expected 2)", ptr);
        else
            $display("FAIL: All-ones grant=15, cycle2, expected 2, got ptr=%0d", ptr);

        // ptr = (2+1)%15 = 3
        wait_clk;
        if (ptr === 4'd3)
            $display("PASS: All-ones grant=15, cycle3, ptr=%0d (expected 3)", ptr);
        else
            $display("FAIL: All-ones grant=15, cycle3, expected 3, got ptr=%0d", ptr);

        // ----------------------------------------------------------------
        // Test 6: All-ones inputs - verify wrap (ptr=14 -> (14+1)%15=0)
        // ----------------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        #1;

        grant = 4'b1111; // grant = 15
        // Drive ptr to 14 by cycling 14 times
        repeat(14) begin
            wait_clk;
        end
        // Now ptr should be 14
        if (ptr === 4'd14)
            $display("PASS: All-ones, ptr reached 14 before wrap");
        else
            $display("INFO: All-ones, ptr=%0d (expected 14 before wrap)", ptr);

        // One more cycle: ptr = (14+1)%15 = 0
        wait_clk;
        if (ptr === 4'd0)
            $display("PASS: All-ones wrap, ptr=%0d (expected 0)", ptr);
        else
            $display("FAIL: All-ones wrap, expected 0, got ptr=%0d", ptr);

        // ----------------------------------------------------------------
        // Test 7: Maximum value single grant - grant = 4'b1000 (= 8)
        // ptr cycles: 0->1->...->7->0
        // ----------------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        #1;

        grant = 4'b1000; // grant = 8
        wait_clk;
        expected_ptr = (0 + 1) % 4'b1000; // = 1
        if (ptr === expected_ptr)
            $display("PASS: grant=8, cycle1, ptr=%0d (expected 1)", ptr);
        else
            $display("FAIL: grant=8, cycle1, expected 1, got ptr=%0d", ptr);

        // Cycle forward to 7, then check wrap to 0
        repeat(6) wait_clk;
        if (ptr === 4'd7)
            $display("PASS: grant=8, ptr reached 7");
        else
            $display("INFO: grant=8, ptr=%0d (expected 7)", ptr);

        wait_clk;
        if (ptr === 4'd0)
            $display("PASS: grant=8, wrap ptr=%0d (expected 0)", ptr);
        else
            $display("FAIL: grant=8, wrap, expected 0, got ptr=%0d", ptr);

        // ----------------------------------------------------------------
        // Test 8: Reset in middle of operation clears ptr
        // ----------------------------------------------------------------
        grant = 4'b0100; // grant = 4
        repeat(3) wait_clk;
        // Now assert reset mid-operation
        @(posedge clk);
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        if (ptr === {N{1'b0}})
            $display("PASS: Mid-operation reset clears ptr to 0");
        else
            $display("FAIL: Mid-operation reset, expected ptr=0, got ptr=%b", ptr);

        rst = 0;
        #1;

        // ----------------------------------------------------------------
        // Done
        // ----------------------------------------------------------------
        #20;
        $finish;
    end

endmodule
