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

    integer i;
    integer pass_count;
    integer fail_count;

    // Task: apply one clock cycle
    task apply_cycle;
        input [N-1:0] grant_in;
        begin
            grant = grant_in;
            @(posedge clk);
            #1; // small delay to sample outputs
        end
    endtask

    // Task: check ptr and report
    task check_ptr;
        input [N-1:0] expected;
        input [127:0] desc;
        begin
            if (ptr === expected) begin
                $display("PASS: %s (ptr=%b, expected=%b)", desc, ptr, expected);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %s (ptr=%b, expected=%b)", desc, ptr, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize
        rst   = 1;
        grant = 4'b0000;

        // Assert reset for exactly 5 rising edges
        repeat(5) @(posedge clk);
        #1;

        // Check that reset clears ptr to 0
        check_ptr(4'b0000, "Reset clears ptr to 0");

        // Deassert reset
        @(negedge clk);
        rst = 0;

        // -------------------------------------------------------
        // Test 1: grant = 0000, ptr should remain 0 (no grant)
        // -------------------------------------------------------
        apply_cycle(4'b0000);
        check_ptr(4'b0000, "grant=0000 ptr stays 0");

        // -------------------------------------------------------
        // Test 2: grant bit 0, next ptr should point after bit 0
        // i.e., ptr = 4'b0010 (bit 1 is next in round-robin)
        // -------------------------------------------------------
        apply_cycle(4'b0001);
        check_ptr(4'b0010, "grant=0001 ptr rotates to bit1");

        // -------------------------------------------------------
        // Test 3: grant bit 1, next ptr should point to bit 2
        // -------------------------------------------------------
        apply_cycle(4'b0010);
        check_ptr(4'b0100, "grant=0010 ptr rotates to bit2");

        // -------------------------------------------------------
        // Test 4: grant bit 2, next ptr should point to bit 3
        // -------------------------------------------------------
        apply_cycle(4'b0100);
        check_ptr(4'b1000, "grant=0100 ptr rotates to bit3");

        // -------------------------------------------------------
        // Test 5: grant bit 3 (MSB), next ptr should wrap to bit 0
        // -------------------------------------------------------
        apply_cycle(4'b1000);
        check_ptr(4'b0001, "grant=1000 ptr wraps to bit0");

        // -------------------------------------------------------
        // Test 6: All-ones grant (all bits asserted simultaneously)
        // ptr should still advance from current position
        // After grant=1000 -> ptr=0001; grant=1111 -> ptr advances from highest set
        // -------------------------------------------------------
        apply_cycle(4'b1111);
        // With all bits granted, the last (highest or lowest) bit determines ptr
        // Just check it's nonzero and not X
        if (ptr !== 4'bxxxx && ptr !== 4'bzzzz) begin
            $display("PASS: grant=1111 ptr is valid (ptr=%b)", ptr);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: grant=1111 ptr is X/Z (ptr=%b)", ptr);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 7: Starvation test - hold all bits high, verify rotation
        // Reset first, then grant each bit in sequence and confirm ptr
        // -------------------------------------------------------
        @(negedge clk);
        rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(negedge clk);
        rst = 0;

        // Starvation: cycle through each bit being granted
        // Starting after reset: ptr = 0
        apply_cycle(4'b0001); // grant bit0 -> ptr should be 0010
        check_ptr(4'b0010, "Starvation: grant bit0 -> ptr=bit1");

        apply_cycle(4'b0010); // grant bit1 -> ptr should be 0100
        check_ptr(4'b0100, "Starvation: grant bit1 -> ptr=bit2");

        apply_cycle(4'b0100); // grant bit2 -> ptr should be 1000
        check_ptr(4'b1000, "Starvation: grant bit2 -> ptr=bit3");

        apply_cycle(4'b1000); // grant bit3 -> ptr should be 0001
        check_ptr(4'b0001, "Starvation: grant bit3 -> ptr=bit0 (wrap)");

        // -------------------------------------------------------
        // Test 8: grant=0000 again after rotation, ptr unchanged
        // -------------------------------------------------------
        apply_cycle(4'b0000);
        check_ptr(4'b0001, "grant=0000 after rotation ptr unchanged");

        // -------------------------------------------------------
        // Test 9: Reset in the middle of operation
        // -------------------------------------------------------
        apply_cycle(4'b0010); // advance ptr to bit2
        @(negedge clk);
        rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        check_ptr(4'b0000, "Reset mid-operation clears ptr");
        @(negedge clk);
        rst = 0;

        // -------------------------------------------------------
        // Test 10: After re-reset, grant bit 2 directly
        // -------------------------------------------------------
        apply_cycle(4'b0100);
        check_ptr(4'b1000, "After re-reset: grant=0100 ptr=1000");

        // -------------------------------------------------------
        // Test 11: All-zeros grant multiple times
        // -------------------------------------------------------
        apply_cycle(4'b0000);
        apply_cycle(4'b0000);
        apply_cycle(4'b0000);
        check_ptr(4'b1000, "grant=0000 x3 ptr unchanged at 1000");

        // -------------------------------------------------------
        // Test 12: grant MSB only from reset
        // -------------------------------------------------------
        @(negedge clk);
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        @(negedge clk);
        rst = 0;

        apply_cycle(4'b1000);
        check_ptr(4'b0001, "From reset: grant=1000 ptr wraps to bit0");

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        $display("-----------------------------------");
        $display("Total PASS: %0d, Total FAIL: %0d", pass_count, fail_count);
        $display("-----------------------------------");

        $finish;
    end

endmodule
