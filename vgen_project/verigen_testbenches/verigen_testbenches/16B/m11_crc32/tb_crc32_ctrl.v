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

    integer pass_count;
    integer fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize inputs
        rst     = 1;
        start   = 0;
        done_in = 0;
        crc_raw = 32'h00000000;

        // Assert reset: rst active-low, so drive rst=0 for 5 rising edges
        rst = 0;
        wait_cycles(5);

        // -------------------------------------------------------
        // Test 1: After reset (rst=0 / active-low), crc_reg should
        // be 0xFFFFFFFF and init should be 1
        // -------------------------------------------------------
        // At this point rst=0 (active-low reset held), check init
        // The always block fires on negedge rst, so on the very first
        // negedge rst the values are set.
        // After 5 cycles with rst=0, sample on falling edge of clk
        #1; // small delay after last posedge
        if (init === 1'b1) begin
            $display("PASS: Test1 - init=1 during reset");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test1 - init should be 1 during reset, got %b", init);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 2: Deassert reset (rst=1), on next posedge init should
        // latch crc_raw into crc_reg and clear init
        // crc_raw = 0, so crc_reg becomes 0, init becomes 0
        // -------------------------------------------------------
        crc_raw = 32'hDEADBEEF;
        rst = 1;
        @(posedge clk); #1;
        // After one cycle with rst=1, if init was 1, crc_reg=crc_raw, init=0
        if (init === 1'b0) begin
            $display("PASS: Test2 - init cleared after first cycle post-reset");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test2 - init should be 0 after first cycle, got %b", init);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 3: start=1, crc_reg should rotate left (ROL)
        // crc_reg was loaded with 0xDEADBEEF
        // After one start cycle: expected = ROL(0xDEADBEEF, 1) = 0xBD5B7DDF
        // Then done_in=1 to latch crc_out
        // -------------------------------------------------------
        start   = 1;
        done_in = 0;
        @(posedge clk); #1;
        start   = 0;
        done_in = 1;
        @(posedge clk); #1;
        done_in = 0;
        // crc_out should now be ROL(0xDEADBEEF,1) = 0xBD5B7DDF
        if (crc_out === 32'hBD5B7DDF) begin
            $display("PASS: Test3 - ROL of 0xDEADBEEF = 0xBD5B7DDF, crc_out=0x%08X", crc_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test3 - expected crc_out=0xBD5B7DDF, got 0x%08X", crc_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 4: Reset again, load all-zeros crc_raw
        // init should assert, crc_raw=0 loads after deassert
        // -------------------------------------------------------
        rst     = 0;
        start   = 0;
        done_in = 0;
        crc_raw = 32'h00000000;
        wait_cycles(5);
        #1;
        if (init === 1'b1) begin
            $display("PASS: Test4 - init=1 on reset with all-zero crc_raw");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test4 - init should be 1 during reset, got %b", init);
            fail_count = fail_count + 1;
        end
        rst = 1;
        @(posedge clk); #1;
        if (init === 1'b0) begin
            $display("PASS: Test4b - init cleared after loading all-zero crc_raw");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test4b - init should be 0, got %b", init);
            fail_count = fail_count + 1;
        end

        // done_in to latch (crc_reg = 0 loaded)
        done_in = 1;
        @(posedge clk); #1;
        done_in = 0;
        if (crc_out === 32'h00000000) begin
            $display("PASS: Test4c - crc_out=0x00000000 after loading zeros");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test4c - expected 0x00000000, got 0x%08X", crc_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 5: Reset, load all-ones crc_raw = 0xFFFFFFFF
        // ROL(0xFFFFFFFF, 1) = 0xFFFFFFFF
        // -------------------------------------------------------
        rst     = 0;
        crc_raw = 32'hFFFFFFFF;
        start   = 0;
        done_in = 0;
        wait_cycles(5);
        rst = 1;
        @(posedge clk); #1; // init clears, crc_reg = 0xFFFFFFFF
        start = 1;
        @(posedge clk); #1;
        start = 0;
        done_in = 1;
        @(posedge clk); #1;
        done_in = 0;
        if (crc_out === 32'hFFFFFFFF) begin
            $display("PASS: Test5 - ROL(0xFFFFFFFF)=0xFFFFFFFF, crc_out=0x%08X", crc_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test5 - expected 0xFFFFFFFF, got 0x%08X", crc_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 6: Reset, load 0x80000000, ROL once -> 0x00000001
        // -------------------------------------------------------
        rst     = 0;
        crc_raw = 32'h80000000;
        start   = 0;
        done_in = 0;
        wait_cycles(5);
        rst = 1;
        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;
        done_in = 1;
        @(posedge clk); #1;
        done_in = 0;
        if (crc_out === 32'h00000001) begin
            $display("PASS: Test6 - ROL(0x80000000)=0x00000001, crc_out=0x%08X", crc_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test6 - expected 0x00000001, got 0x%08X", crc_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 7: Reset, load 0x00000001, ROL once -> 0x00000002
        // -------------------------------------------------------
        rst     = 0;
        crc_raw = 32'h00000001;
        start   = 0;
        done_in = 0;
        wait_cycles(5);
        rst = 1;
        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;
        done_in = 1;
        @(posedge clk); #1;
        done_in = 0;
        if (crc_out === 32'h00000002) begin
            $display("PASS: Test7 - ROL(0x00000001)=0x00000002, crc_out=0x%08X", crc_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test7 - expected 0x00000002, got 0x%08X", crc_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 8: Multiple ROL cycles
        // Reset, load 0x12345678
        // ROL 1: 0x2468ACF0
        // ROL 2: 0x48D159E0
        // ROL 3: 0x91A2B3C0
        // done_in after 3 rotations
        // -------------------------------------------------------
        rst     = 0;
        crc_raw = 32'h12345678;
        start   = 0;
        done_in = 0;
        wait_cycles(5);
        rst = 1;
        @(posedge clk); #1; // loads crc_raw, clears init
        // 3 start pulses
        start = 1;
        @(posedge clk); #1; // ROL1 -> 0x2468ACF0
        @(posedge clk); #1; // ROL2 -> 0x48D159E0
        @(posedge clk); #1; // ROL3 -> 0x91A2B3C0
        start = 0;
        done_in = 1;
        @(posedge clk); #1;
        done_in = 0;
        if (crc_out === 32'h91A2B3C0) begin
            $display("PASS: Test8 - 3x ROL(0x12345678)=0x91A2B3C0, crc_out=0x%08X", crc_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test8 - expected 0x91A2B3C0, got 0x%08X", crc_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 9: Verify done_in=0 does NOT update crc_out
        // Reset, load 0xCAFEBABE, assert start once (ROL -> result)
        // Do NOT assert done_in; crc_out should remain from previous test
        // -------------------------------------------------------
        rst     = 0;
        crc_raw = 32'hCAFEBABE;
        start   = 0;
        done_in = 0;
        wait_cycles(5);
        rst = 1;
        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;
        // No done_in - crc_out should still be 0x91A2B3C0
        @(posedge clk); #1;
        if (crc_out === 32'h91A2B3C0) begin
            $display("PASS: Test9 - crc_out unchanged without done_in (still 0x91A2B3C0)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test9 - crc_out changed unexpectedly to 0x%08X", crc_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        $display("---------------------------------------------");
        $display("Tests complete: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("---------------------------------------------");

        $finish;
    end

endmodule
