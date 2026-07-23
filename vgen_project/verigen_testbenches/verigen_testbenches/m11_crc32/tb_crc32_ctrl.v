`timescale 1ns/1ps

module tb_crc32_ctrl;

    // DUT ports
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

    // Task: wait N rising edges
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
        start    = 0;
        done_in  = 0;
        crc_raw  = 32'h0;
        test_num   = 0;
        pass_count = 0;
        fail_count = 0;

        // Assert reset for exactly 5 rising edges
        @(posedge clk); // 1
        @(posedge clk); // 2
        @(posedge clk); // 3
        @(posedge clk); // 4
        @(posedge clk); // 5
        @(negedge clk); // deassert between edges
        rst = 0;
        @(posedge clk);
        #1; // small delay after edge for output sampling

        // ----------------------------------------------------------------
        // Test 1: After reset, start=0, done_in=0, crc_raw=0
        //         init should be 0 (no start), crc_out = crc_raw ^ 0xFFFFFFFF only when done
        // ----------------------------------------------------------------
        test_num = 1;
        start   = 0;
        done_in = 0;
        crc_raw = 32'h0;
        @(posedge clk); #1;
        // When not started and not done, init=0
        if (init === 1'b0) begin
            $display("PASS: Test %0d - After reset, no start => init=0", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test %0d - After reset, no start => init should be 0, got %b", test_num, init);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 2: Assert start, check init asserts
        // ----------------------------------------------------------------
        test_num = 2;
        start   = 1;
        done_in = 0;
        crc_raw = 32'h0;
        @(posedge clk); #1;
        if (init === 1'b1) begin
            $display("PASS: Test %0d - start=1 => init=1", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test %0d - start=1 => init should be 1, got %b", test_num, init);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 3: Deassert start, init should go back to 0
        // ----------------------------------------------------------------
        test_num = 3;
        start   = 0;
        done_in = 0;
        crc_raw = 32'h0;
        @(posedge clk); #1;
        if (init === 1'b0) begin
            $display("PASS: Test %0d - start=0 => init=0", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test %0d - start=0 => init should be 0, got %b", test_num, init);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 4: done_in=1, crc_raw=0x00000000 => crc_out should be 0xFFFFFFFF
        // ----------------------------------------------------------------
        test_num = 4;
        start   = 0;
        done_in = 1;
        crc_raw = 32'h00000000;
        @(posedge clk); #1;
        if (crc_out === 32'hFFFFFFFF) begin
            $display("PASS: Test %0d - done_in=1, crc_raw=0 => crc_out=0xFFFFFFFF", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test %0d - done_in=1, crc_raw=0 => crc_out should be 0xFFFFFFFF, got 0x%08X", test_num, crc_out);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 5: done_in=1, crc_raw=0xFFFFFFFF => crc_out should be 0x00000000
        // ----------------------------------------------------------------
        test_num = 5;
        start   = 0;
        done_in = 1;
        crc_raw = 32'hFFFFFFFF;
        @(posedge clk); #1;
        if (crc_out === 32'h00000000) begin
            $display("PASS: Test %0d - done_in=1, crc_raw=0xFFFFFFFF => crc_out=0x00000000", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test %0d - done_in=1, crc_raw=0xFFFFFFFF => crc_out should be 0x00000000, got 0x%08X", test_num, crc_out);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 6: done_in=1, crc_raw=0xDEADBEEF => crc_out should be 0x21524110
        // ----------------------------------------------------------------
        test_num = 6;
        start   = 0;
        done_in = 1;
        crc_raw = 32'hDEADBEEF;
        @(posedge clk); #1;
        if (crc_out === (32'hDEADBEEF ^ 32'hFFFFFFFF)) begin
            $display("PASS: Test %0d - done_in=1, crc_raw=0xDEADBEEF => crc_out=0x%08X", test_num, crc_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test %0d - done_in=1, crc_raw=0xDEADBEEF => expected 0x%08X, got 0x%08X",
                     test_num, (32'hDEADBEEF ^ 32'hFFFFFFFF), crc_out);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 7: done_in=0, crc_raw=0xDEADBEEF => crc_out should be crc_raw (no XOR)
        //         When done_in=0, crc_out should pass through crc_raw unchanged
        // ----------------------------------------------------------------
        test_num = 7;
        start   = 0;
        done_in = 0;
        crc_raw = 32'hDEADBEEF;
        @(posedge clk); #1;
        if (crc_out === 32'hDEADBEEF) begin
            $display("PASS: Test %0d - done_in=0, crc_raw=0xDEADBEEF => crc_out=crc_raw (no XOR)", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test %0d - done_in=0, crc_raw=0xDEADBEEF => expected 0xDEADBEEF, got 0x%08X", test_num, crc_out);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 8: start=1 then done_in=1 in same cycle
        //         init should assert, and crc_out should XOR
        // ----------------------------------------------------------------
        test_num = 8;
        start   = 1;
        done_in = 1;
        crc_raw = 32'hA5A5A5A5;
        @(posedge clk); #1;
        // init should be 1 due to start
        if (init === 1'b1) begin
            $display("PASS: Test %0d - start=1 simultaneously => init=1", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test %0d - start=1 simultaneously => init should be 1, got %b", test_num, init);
            fail_count = fail_count + 1;
        end
        // crc_out should be XOR'd since done_in=1
        if (crc_out === (32'hA5A5A5A5 ^ 32'hFFFFFFFF)) begin
            $display("PASS: Test %0d - start=1, done_in=1, crc_raw=0xA5A5A5A5 => crc_out=0x%08X", test_num, crc_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test %0d - start=1, done_in=1 => expected 0x%08X, got 0x%08X",
                     test_num, (32'hA5A5A5A5 ^ 32'hFFFFFFFF), crc_out);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 9: Reset again, verify init=0 after reset
        // ----------------------------------------------------------------
        test_num = 9;
        start   = 0;
        done_in = 0;
        crc_raw = 32'h12345678;
        rst = 1;
        @(posedge clk); // 1
        @(posedge clk); // 2
        @(posedge clk); // 3
        @(posedge clk); // 4
        @(posedge clk); // 5
        @(negedge clk);
        rst = 0;
        @(posedge clk); #1;
        if (init === 1'b0) begin
            $display("PASS: Test %0d - After second reset => init=0", test_num);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test %0d - After second reset => init should be 0, got %b", test_num, init);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 10: done_in=1 with crc_raw=0x12345678 => crc_out=0xEDCBA987
        // ----------------------------------------------------------------
        test_num = 10;
        start   = 0;
        done_in = 1;
        crc_raw = 32'h12345678;
        @(posedge clk); #1;
        if (crc_out === (32'h12345678 ^ 32'hFFFFFFFF)) begin
            $display("PASS: Test %0d - done_in=1, crc_raw=0x12345678 => crc_out=0x%08X", test_num, crc_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test %0d - done_in=1, crc_raw=0x12345678 => expected 0x%08X, got 0x%08X",
                     test_num, (32'h12345678 ^ 32'hFFFFFFFF), crc_out);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Summary
        // ----------------------------------------------------------------
        $display("--------------------------------------------");
        $display("Test Summary: %0d passed, %0d failed out of %0d tests",
                 pass_count, fail_count, pass_count + fail_count);
        $display("--------------------------------------------");

        $finish;
    end

endmodule
