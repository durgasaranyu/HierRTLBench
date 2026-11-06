`timescale 1ns/1ps

module tb_crc32_ctrl;

    // DUT port connections
    reg         clk;
    reg         rst;
    reg         start;
    reg         done_in;
    reg  [31:0] crc_raw;
    wire        init;
    wire [31:0] crc_out;

    // Instantiate DUT
    crc32_ctrl uut (
        .clk     (clk),
        .rst     (rst),
        .start   (start),
        .done_in (done_in),
        .crc_raw (crc_raw),
        .init    (init),
        .crc_out (crc_out)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Task to apply one rising-edge tick
    task tick;
        begin
            @(posedge clk);
            #1; // small delay after edge to sample outputs
        end
    endtask

    integer i;

    initial begin
        // Initialize inputs
        rst     = 1;
        start   = 0;
        done_in = 0;
        crc_raw = 32'h00000000;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        #1;

        // After reset: crc_reg should be 0xFFFFFFFF, init should be 1
        if (crc_out === 32'hFFFFFFFF && init === 1'b1)
            $display("PASS: After reset crc_out=0xFFFFFFFF and init=1");
        else
            $display("FAIL: After reset expected crc_out=0xFFFFFFFF init=1, got crc_out=%h init=%b", crc_out, init);

        // Deassert reset
        @(negedge clk);
        rst = 0;
        @(posedge clk); #1;

        // Test 1: Idle state - no start, no done_in, outputs should remain from reset
        if (crc_out === 32'hFFFFFFFF && init === 1'b1)
            $display("PASS: Idle - crc_out=0xFFFFFFFF and init=1 unchanged");
        else
            $display("FAIL: Idle - expected crc_out=0xFFFFFFFF init=1, got crc_out=%h init=%b", crc_out, init);

        // Test 2: Assert start - should keep crc_reg=0xFFFFFFFF, init=1
        @(negedge clk);
        start = 1;
        @(posedge clk); #1;
        if (crc_out === 32'hFFFFFFFF && init === 1'b1)
            $display("PASS: start asserted - crc_out=0xFFFFFFFF and init=1");
        else
            $display("FAIL: start asserted - expected crc_out=0xFFFFFFFF init=1, got crc_out=%h init=%b", crc_out, init);

        // Test 3: De-assert start, assert done_in with a typical CRC value
        @(negedge clk);
        start   = 0;
        done_in = 1;
        crc_raw = 32'hDEADBEEF;
        @(posedge clk); #1;
        // crc_reg should now be 0xDEADBEEF, init should be 0
        if (crc_out === 32'hDEADBEEF && init === 1'b0)
            $display("PASS: done_in - crc_out=0xDEADBEEF and init=0");
        else
            $display("FAIL: done_in - expected crc_out=0xDEADBEEF init=0, got crc_out=%h init=%b", crc_out, init);

        // Test 4: De-assert done_in, value should hold
        @(negedge clk);
        done_in = 0;
        crc_raw = 32'h00000000;
        @(posedge clk); #1;
        if (crc_out === 32'hDEADBEEF && init === 1'b0)
            $display("PASS: done_in de-asserted - crc_out=0xDEADBEEF held and init=0");
        else
            $display("FAIL: done_in de-asserted - expected crc_out=0xDEADBEEF init=0, got crc_out=%h init=%b", crc_out, init);

        // Test 5: start again, should reload to 0xFFFFFFFF and init=1
        @(negedge clk);
        start = 1;
        @(posedge clk); #1;
        if (crc_out === 32'hFFFFFFFF && init === 1'b1)
            $display("PASS: restart - crc_out=0xFFFFFFFF and init=1");
        else
            $display("FAIL: restart - expected crc_out=0xFFFFFFFF init=1, got crc_out=%h init=%b", crc_out, init);

        @(negedge clk);
        start = 0;

        // Test 6: done_in with all-zero crc_raw
        @(negedge clk);
        done_in = 1;
        crc_raw = 32'h00000000;
        @(posedge clk); #1;
        if (crc_out === 32'h00000000 && init === 1'b0)
            $display("PASS: done_in all-zeros - crc_out=0x00000000 and init=0");
        else
            $display("FAIL: done_in all-zeros - expected crc_out=0x00000000 init=0, got crc_out=%h init=%b", crc_out, init);

        // Test 7: done_in with all-ones crc_raw (0xFFFFFFFF)
        @(negedge clk);
        done_in = 1;
        crc_raw = 32'hFFFFFFFF;
        @(posedge clk); #1;
        if (crc_out === 32'hFFFFFFFF && init === 1'b0)
            $display("PASS: done_in all-ones - crc_out=0xFFFFFFFF and init=0");
        else
            $display("FAIL: done_in all-ones - expected crc_out=0xFFFFFFFF init=0, got crc_out=%h init=%b", crc_out, init);

        @(negedge clk);
        done_in = 0;

        // Test 8: Synchronous reset (re-apply rst for 5 cycles)
        @(negedge clk);
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        if (crc_out === 32'hFFFFFFFF && init === 1'b1)
            $display("PASS: Second reset - crc_out=0xFFFFFFFF and init=1");
        else
            $display("FAIL: Second reset - expected crc_out=0xFFFFFFFF init=1, got crc_out=%h init=%b", crc_out, init);
        @(negedge clk);
        rst = 0;

        // Test 9: start and done_in simultaneously - start takes priority per else-if chain
        // According to code: start has priority over done_in (else-if), so start wins
        @(negedge clk);
        start   = 1;
        done_in = 1;
        crc_raw = 32'hCAFEBABE;
        @(posedge clk); #1;
        // start is checked first, so crc_reg=0xFFFFFFFF, init=1
        if (crc_out === 32'hFFFFFFFF && init === 1'b1)
            $display("PASS: start+done_in simultaneous - start priority: crc_out=0xFFFFFFFF init=1");
        else
            $display("FAIL: start+done_in simultaneous - expected crc_out=0xFFFFFFFF init=1, got crc_out=%h init=%b", crc_out, init);

        @(negedge clk);
        start   = 0;
        done_in = 0;

        // Test 10: Maximum value crc_raw with done_in
        @(negedge clk);
        done_in = 1;
        crc_raw = 32'hFFFFFFFE;
        @(posedge clk); #1;
        if (crc_out === 32'hFFFFFFFE && init === 1'b0)
            $display("PASS: max-minus-one crc_raw - crc_out=0xFFFFFFFE init=0");
        else
            $display("FAIL: max-minus-one crc_raw - expected crc_out=0xFFFFFFFE init=0, got crc_out=%h init=%b", crc_out, init);

        @(negedge clk);
        done_in = 0;

        // Allow a few more cycles before finishing
        repeat (3) @(posedge clk);

        $display("Testbench completed.");
        $finish;
    end

endmodule
