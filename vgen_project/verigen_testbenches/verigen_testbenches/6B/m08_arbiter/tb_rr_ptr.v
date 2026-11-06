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

    // Task to apply one clock cycle
    task apply_cycle;
        input [N-1:0] grant_in;
        begin
            grant = grant_in;
            @(posedge clk);
            #1; // small delay to sample outputs after clock edge
        end
    endtask

    // Tracking variable
    integer i;
    reg test_passed;

    initial begin
        // Initialize
        rst   = 1;
        grant = 4'b0000;

        // Assert reset for exactly 5 rising edges
        repeat(5) @(posedge clk);
        #1;

        // Deassert reset
        rst = 0;

        // Allow one cycle with no grant after reset
        @(posedge clk);
        #1;

        // =====================================================
        // Test 1: Reset clears the ptr register (ptr should be 0 after reset)
        // =====================================================
        if (ptr === {N{1'b0}})
            $display("PASS: After reset, ptr=0");
        else
            $display("FAIL: After reset, ptr=%b (expected 0)", ptr);

        // =====================================================
        // Test 2: grant=0 (no grant), ptr should remain 0
        // =====================================================
        grant = 4'b0000;
        @(posedge clk);
        #1;
        if (ptr === 4'b0000)
            $display("PASS: grant=0, ptr=0 (no rotation)");
        else
            $display("FAIL: grant=0, ptr=%b (expected 0)", ptr);

        // =====================================================
        // Test 3: Grant bit 0, ptr should become 4'b0010 (next after bit0)
        // =====================================================
        rst = 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        #1;
        rst = 0;
        @(posedge clk);
        #1;

        grant = 4'b0001; // grant bit 0
        @(posedge clk);
        #1;

        // After granting bit 0, ptr should point to next position (bit 1)
        if (ptr === 4'b0010)
            $display("PASS: grant=0001, ptr=0010 (ptr rotated to bit1 after granting bit0)");
        else
            $display("FAIL: grant=0001, ptr=%b (expected 0010)", ptr);

        // =====================================================
        // Test 4: Continuing rotation - grant bit 1, ptr should become bit 2
        // =====================================================
        grant = 4'b0010; // grant bit 1
        @(posedge clk);
        #1;

        if (ptr === 4'b0100)
            $display("PASS: grant=0010, ptr=0100 (ptr rotated to bit2 after granting bit1)");
        else
            $display("FAIL: grant=0010, ptr=%b (expected 0100)", ptr);

        // =====================================================
        // Test 5: grant bit 2, ptr should become bit 3
        // =====================================================
        grant = 4'b0100;
        @(posedge clk);
        #1;

        if (ptr === 4'b1000)
            $display("PASS: grant=0100, ptr=1000 (ptr rotated to bit3 after granting bit2)");
        else
            $display("FAIL: grant=0100, ptr=%b (expected 1000)", ptr);

        // =====================================================
        // Test 6: grant bit 3 (MSB), ptr should wrap around to bit 0
        // =====================================================
        grant = 4'b1000;
        @(posedge clk);
        #1;

        if (ptr === 4'b0001)
            $display("PASS: grant=1000, ptr=0001 (ptr wrapped to bit0 after granting bit3)");
        else
            $display("FAIL: grant=1000, ptr=%b (expected 0001)", ptr);

        // =====================================================
        // Test 7: All-ones grant (all bits high) - only LSB should be considered
        // ptr should shift from current position
        // =====================================================
        grant = 4'b1111;
        @(posedge clk);
        #1;
        // Just check that ptr is non-zero and has one bit set (a rotation happened)
        if (ptr !== 4'b0000)
            $display("PASS: grant=1111 (all ones), ptr=%b (non-zero, rotation occurred)", ptr);
        else
            $display("FAIL: grant=1111 (all ones), ptr=%b (expected non-zero)", ptr);

        // =====================================================
        // Test 8: Starvation test - all bits high, verify round-robin rotation
        // over N consecutive cycles grants each bit exactly once
        // =====================================================
        // Reset first
        rst = 1;
        grant = 4'b0000;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        @(posedge clk);
        #1;

        begin : starvation_test
            reg [N-1:0] seen_grants;
            reg [N-1:0] current_ptr;
            integer cycle;
            integer all_seen;

            seen_grants = 4'b0000;
            all_seen = 0;

            // Drive grant = ptr each cycle to simulate round-robin arbiter
            // Then check that ptr rotates through all positions
            for (cycle = 0; cycle < N*2; cycle = cycle + 1) begin
                // Simulate granting the position pointed to by ptr
                current_ptr = ptr;
                grant = current_ptr;
                @(posedge clk);
                #1;
                if (current_ptr !== 4'b0000) begin
                    seen_grants = seen_grants | current_ptr;
                end
            end

            if (seen_grants === 4'b1111)
                $display("PASS: Starvation test - all 4 bits granted in round-robin (seen_grants=%b)", seen_grants);
            else
                $display("FAIL: Starvation test - not all bits granted (seen_grants=%b)", seen_grants);
        end

        // =====================================================
        // Test 9: Back-to-back reset test
        // =====================================================
        rst = 1;
        grant = 4'b1010;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        @(posedge clk);
        #1;

        if (ptr === 4'b0000)
            $display("PASS: Back-to-back reset clears ptr to 0");
        else
            $display("FAIL: Back-to-back reset, ptr=%b (expected 0)", ptr);

        // =====================================================
        // Test 10: grant=0 after some grants, ptr should not change
        // =====================================================
        // Grant bit 2 first
        grant = 4'b0100;
        @(posedge clk);
        #1;
        begin : no_grant_test
            reg [N-1:0] ptr_after_grant;
            ptr_after_grant = ptr;

            // Now apply no grant
            grant = 4'b0000;
            @(posedge clk);
            #1;

            if (ptr === ptr_after_grant)
                $display("PASS: grant=0 after grant=0100, ptr unchanged at %b", ptr);
            else
                $display("FAIL: grant=0 after grant=0100, ptr changed from %b to %b", ptr_after_grant, ptr);
        end

        // =====================================================
        // Test 11: Single bit grant - grant bit 1 from reset state
        // =====================================================
        rst = 1;
        grant = 4'b0000;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        @(posedge clk);
        #1;

        grant = 4'b0010; // grant bit 1
        @(posedge clk);
        #1;

        if (ptr === 4'b0100)
            $display("PASS: grant=0010 from reset, ptr=0100 (rotated to bit2)");
        else
            $display("FAIL: grant=0010 from reset, ptr=%b (expected 0100)", ptr);

        // =====================================================
        // Test 12: Multiple resets verify idempotency
        // =====================================================
        rst = 1;
        grant = 4'b1111;
        @(posedge clk);
        #1;
        rst = 0;
        @(posedge clk);
        #1;
        rst = 1;
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        #1;
        rst = 0;
        @(posedge clk);
        #1;

        if (ptr === 4'b0000)
            $display("PASS: Multiple resets, ptr=0 after final reset");
        else
            $display("FAIL: Multiple resets, ptr=%b (expected 0)", ptr);

        // End simulation
        $finish;
    end

endmodule
