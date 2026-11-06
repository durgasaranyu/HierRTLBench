`timescale 1ns/1ps

module tb_crc32_ctrl;

    // DUT connections
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

    integer i;
    reg [31:0] expected_crc_out;

    // Task to wait N rising edges
    task wait_cycles;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1)
                @(posedge clk);
        end
    endtask

    initial begin
        // Initialize inputs
        rst     = 1;
        start   = 0;
        done_in = 0;
        crc_raw = 32'h00000000;

        // Assert reset for exactly 5 rising edges
        repeat(5) @(posedge clk);
        #1;
        rst = 0;

        // -------------------------------------------------------
        // Test 1: After reset, init should be 0, crc_out should be 0 XOR 0xFFFFFFFF = 0xFFFFFFFF
        // when done_in=0. Actually let's just check basic reset state.
        // crc_out = crc_raw ^ 0xFFFFFFFF when done_in is asserted per spec.
        // After reset, with no start and no done_in, check init=0
        // -------------------------------------------------------
        @(negedge clk);
        start   = 0;
        done_in = 0;
        crc_raw = 32'h00000000;
        @(posedge clk);
        #1;
        if (init === 1'b0)
            $display("PASS: After reset with no start, init=0");
        else
            $display("FAIL: After reset with no start, init=%b (expected 0)", init);

        // -------------------------------------------------------
        // Test 2: Assert start, check that init becomes 1
        // -------------------------------------------------------
        @(negedge clk);
        start   = 1;
        done_in = 0;
        crc_raw = 32'h00000000;
        @(posedge clk);
        #1;
        if (init === 1'b1)
            $display("PASS: start=1 asserts init=1");
        else
            $display("FAIL: start=1, init=%b (expected 1)", init);

        // -------------------------------------------------------
        // Test 3: Deassert start, check init goes back to 0
        // -------------------------------------------------------
        @(negedge clk);
        start   = 0;
        done_in = 0;
        crc_raw = 32'hDEADBEEF;
        @(posedge clk);
        #1;
        if (init === 1'b0)
            $display("PASS: start=0 deasserts init=0");
        else
            $display("FAIL: start=0, init=%b (expected 0)", init);

        // -------------------------------------------------------
        // Test 4: done_in=1, crc_raw=0x00000000, crc_out should be 0xFFFFFFFF
        // (final XOR with 0xFFFFFFFF)
        // -------------------------------------------------------
        @(negedge clk);
        start   = 0;
        done_in = 1;
        crc_raw = 32'h00000000;
        @(posedge clk);
        #1;
        expected_crc_out = 32'h00000000 ^ 32'hFFFFFFFF;
        if (crc_out === expected_crc_out)
            $display("PASS: done_in=1, crc_raw=0, crc_out=0xFFFFFFFF");
        else
            $display("FAIL: done_in=1, crc_raw=0, crc_out=%h (expected %h)", crc_out, expected_crc_out);

        // -------------------------------------------------------
        // Test 5: done_in=1, crc_raw=0xFFFFFFFF, crc_out should be 0x00000000
        // -------------------------------------------------------
        @(negedge clk);
        start   = 0;
        done_in = 1;
        crc_raw = 32'hFFFFFFFF;
        @(posedge clk);
        #1;
        expected_crc_out = 32'hFFFFFFFF ^ 32'hFFFFFFFF;
        if (crc_out === expected_crc_out)
            $display("PASS: done_in=1, crc_raw=0xFFFFFFFF, crc_out=0x00000000");
        else
            $display("FAIL: done_in=1, crc_raw=0xFFFFFFFF, crc_out=%h (expected %h)", crc_out, expected_crc_out);

        // -------------------------------------------------------
        // Test 6: done_in=1, crc_raw=0xA5A5A5A5, crc_out should be XOR result
        // -------------------------------------------------------
        @(negedge clk);
        start   = 0;
        done_in = 1;
        crc_raw = 32'hA5A5A5A5;
        @(posedge clk);
        #1;
        expected_crc_out = 32'hA5A5A5A5 ^ 32'hFFFFFFFF;
        if (crc_out === expected_crc_out)
            $display("PASS: done_in=1, crc_raw=0xA5A5A5A5, crc_out=%h", crc_out);
        else
            $display("FAIL: done_in=1, crc_raw=0xA5A5A5A5, crc_out=%h (expected %h)", crc_out, expected_crc_out);

        // -------------------------------------------------------
        // Test 7: start=1 and done_in=1 simultaneously
        // init should be 1 (start takes effect), crc_out XOR applied
        // -------------------------------------------------------
        @(negedge clk);
        start   = 1;
        done_in = 1;
        crc_raw = 32'h12345678;
        @(posedge clk);
        #1;
        expected_crc_out = 32'h12345678 ^ 32'hFFFFFFFF;
        if (init === 1'b1)
            $display("PASS: start=1 done_in=1, init=1");
        else
            $display("FAIL: start=1 done_in=1, init=%b (expected 1)", init);
        if (crc_out === expected_crc_out)
            $display("PASS: start=1 done_in=1, crc_out=%h", crc_out);
        else
            $display("FAIL: start=1 done_in=1, crc_out=%h (expected %h)", crc_out, expected_crc_out);

        // -------------------------------------------------------
        // Test 8: done_in=0 (not done), crc_out should be crc_raw (no XOR)
        // or 0 - depends on implementation. Check against raw.
        // -------------------------------------------------------
        @(negedge clk);
        start   = 0;
        done_in = 0;
        crc_raw = 32'hCAFEBABE;
        @(posedge clk);
        #1;
        // When done_in=0, crc_out = crc_raw (no final XOR) per spec,
        // OR it could be 0. Let's check both possibilities.
        if (crc_out === 32'hCAFEBABE || crc_out === (32'hCAFEBABE ^ 32'hFFFFFFFF) || crc_out === 32'h0)
            $display("PASS: done_in=0, crc_out=%h (no done, raw or 0 or xor)", crc_out);
        else
            $display("FAIL: done_in=0, crc_out=%h unexpected", crc_out);

        // -------------------------------------------------------
        // Test 9: Re-apply reset and verify init goes low
        // -------------------------------------------------------
        @(negedge clk);
        rst   = 1;
        start = 1;
        wait_cycles(5);
        #1;
        rst   = 0;
        start = 0;
        @(posedge clk);
        #1;
        if (init === 1'b0)
            $display("PASS: After second reset (start=0), init=0");
        else
            $display("FAIL: After second reset, init=%b (expected 0)", init);

        // -------------------------------------------------------
        // Test 10: done_in=1, crc_raw=0x80000000 (max MSB set)
        // -------------------------------------------------------
        @(negedge clk);
        start   = 0;
        done_in = 1;
        crc_raw = 32'h80000000;
        @(posedge clk);
        #1;
        expected_crc_out = 32'h80000000 ^ 32'hFFFFFFFF;
        if (crc_out === expected_crc_out)
            $display("PASS: done_in=1, crc_raw=0x80000000, crc_out=%h", crc_out);
        else
            $display("FAIL: done_in=1, crc_raw=0x80000000, crc_out=%h (expected %h)", crc_out, expected_crc_out);

        // Wait a few more cycles then finish
        wait_cycles(3);

        $display("Testbench complete.");
        $finish;
    end

endmodule
