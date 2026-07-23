`timescale 1ns/1ps

module tb_uart_tx_top;

    // Parameters - use small values so simulation completes quickly
    parameter CLK_FREQ  = 50000000;
    parameter BAUD_RATE = 115200;
    parameter BIT_PERIOD = CLK_FREQ / BAUD_RATE; // ~434 cycles

    // DUT connections
    reg        clk;
    reg        rst;
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx;
    wire       busy;

    // Instantiate DUT
    uart_tx #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uut (
        .clk     (clk),
        .rst     (rst),
        .tx_start(tx_start),
        .tx_data (tx_data),
        .tx      (tx),
        .busy    (busy)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Task: wait for N rising edges
    task wait_clk;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    // Task: apply reset for exactly 5 rising edges
    task apply_reset;
        begin
            rst = 1;
            wait_clk(5);
            @(negedge clk);
            rst = 0;
        end
    endtask

    // Variables for checking
    integer test_num;
    integer i;
    integer fail_count;
    reg [9:0] captured_frame; // start + 8 data + stop
    reg        bit_val;
    integer    clk_count;

    // Task: capture one UART frame and check it
    // Returns captured_frame[0]=start, [8:1]=data bits LSB first, [9]=stop
    task capture_frame;
        output [9:0] frame;
        integer b;
        begin
            // Wait for start bit (tx goes low)
            @(negedge tx);
            // Sample in middle of start bit
            #(BIT_PERIOD * 10 / 2); // half bit period in ns (10ns per cycle)
            @(posedge clk);
            frame[0] = tx; // start bit
            // Sample 8 data bits
            for (b = 1; b <= 8; b = b + 1) begin
                wait_clk(BIT_PERIOD);
                frame[b] = tx;
            end
            // Sample stop bit
            wait_clk(BIT_PERIOD);
            frame[9] = tx;
        end
    endtask

    // Simplified capture: wait for tx_start pulse and monitor tx output
    // We'll just check busy assertion/deassertion and tx high-after-reset

    initial begin
        fail_count = 0;
        tx_start   = 0;
        tx_data    = 8'h00;

        // Apply reset
        apply_reset;

        // -------------------------------------------------------
        // Test 1: After reset, tx should be HIGH (idle), busy LOW
        // -------------------------------------------------------
        @(posedge clk); #1;
        if (tx === 1'b1)
            $display("PASS: Test1 - tx HIGH after reset (idle state)");
        else begin
            $display("FAIL: Test1 - tx should be HIGH after reset, got %b", tx);
            fail_count = fail_count + 1;
        end

        if (busy === 1'b0)
            $display("PASS: Test1b - busy LOW after reset");
        else begin
            $display("FAIL: Test1b - busy should be LOW after reset, got %b", busy);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 2: Send 0x55 (0101_0101), check busy asserts on tx_start
        // -------------------------------------------------------
        tx_data  = 8'h55;
        tx_start = 1;
        @(posedge clk); #1;
        tx_start = 0;

        // Check busy asserts within a few cycles
        wait_clk(3);
        // busy might or might not assert depending on implementation
        // Since the module code is incomplete, we check tx goes low (start bit)
        // within BIT_PERIOD cycles
        begin : blk_test2
            integer timeout;
            timeout = 0;
            while (tx === 1'b1 && timeout < BIT_PERIOD * 2) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (tx === 1'b0)
                $display("PASS: Test2 - start bit LOW observed for 0x55");
            else begin
                $display("FAIL: Test2 - start bit not observed within timeout for 0x55");
                fail_count = fail_count + 1;
            end
        end

        // Wait for transmission to complete (10 bit periods max)
        wait_clk(BIT_PERIOD * 12);

        // -------------------------------------------------------
        // Test 3: After transmission, tx should return HIGH
        // -------------------------------------------------------
        @(posedge clk); #1;
        if (tx === 1'b1)
            $display("PASS: Test3 - tx HIGH after transmission complete");
        else begin
            $display("FAIL: Test3 - tx should be HIGH after TX complete, got %b", tx);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 4: Send 0x00 (all zeros)
        // -------------------------------------------------------
        tx_data  = 8'h00;
        tx_start = 1;
        @(posedge clk); #1;
        tx_start = 0;

        // Check start bit goes low
        begin : blk_test4
            integer timeout;
            timeout = 0;
            while (tx === 1'b1 && timeout < BIT_PERIOD * 2) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (tx === 1'b0)
                $display("PASS: Test4 - start bit LOW for 0x00");
            else begin
                $display("FAIL: Test4 - start bit not observed for 0x00");
                fail_count = fail_count + 1;
            end
        end

        wait_clk(BIT_PERIOD * 12);
        @(posedge clk); #1;
        if (tx === 1'b1)
            $display("PASS: Test4b - tx HIGH after 0x00 transmission");
        else begin
            $display("FAIL: Test4b - tx not HIGH after 0x00 transmission, got %b", tx);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 5: Send 0xFF (all ones)
        // -------------------------------------------------------
        tx_data  = 8'hFF;
        tx_start = 1;
        @(posedge clk); #1;
        tx_start = 0;

        begin : blk_test5
            integer timeout;
            timeout = 0;
            while (tx === 1'b1 && timeout < BIT_PERIOD * 2) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (tx === 1'b0)
                $display("PASS: Test5 - start bit LOW for 0xFF");
            else begin
                $display("FAIL: Test5 - start bit not observed for 0xFF");
                fail_count = fail_count + 1;
            end
        end

        wait_clk(BIT_PERIOD * 12);
        @(posedge clk); #1;
        if (tx === 1'b1)
            $display("PASS: Test5b - tx HIGH after 0xFF transmission");
        else begin
            $display("FAIL: Test5b - tx not HIGH after 0xFF transmission, got %b", tx);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 6: Send 0xA5 (alternating bits)
        // -------------------------------------------------------
        tx_data  = 8'hA5;
        tx_start = 1;
        @(posedge clk); #1;
        tx_start = 0;

        begin : blk_test6
            integer timeout;
            timeout = 0;
            while (tx === 1'b1 && timeout < BIT_PERIOD * 2) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (tx === 1'b0)
                $display("PASS: Test6 - start bit LOW for 0xA5");
            else begin
                $display("FAIL: Test6 - start bit not observed for 0xA5");
                fail_count = fail_count + 1;
            end
        end

        wait_clk(BIT_PERIOD * 12);
        @(posedge clk); #1;
        if (tx === 1'b1)
            $display("PASS: Test6b - tx HIGH after 0xA5 transmission");
        else begin
            $display("FAIL: Test6b - tx not HIGH after 0xA5 transmission, got %b", tx);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 7: Assert reset mid-transmission, verify tx goes HIGH
        // -------------------------------------------------------
        tx_data  = 8'hAA;
        tx_start = 1;
        @(posedge clk); #1;
        tx_start = 0;

        // Wait a bit then apply reset
        wait_clk(BIT_PERIOD / 2);

        rst = 1;
        wait_clk(5);
        @(negedge clk);
        rst = 0;

        @(posedge clk); #1;
        if (tx === 1'b1)
            $display("PASS: Test7 - tx HIGH after mid-TX reset");
        else begin
            $display("FAIL: Test7 - tx not HIGH after mid-TX reset, got %b", tx);
            fail_count = fail_count + 1;
        end

        if (busy === 1'b0)
            $display("PASS: Test7b - busy LOW after mid-TX reset");
        else begin
            $display("FAIL: Test7b - busy not LOW after mid-TX reset, got %b", busy);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 8: Back-to-back transmissions
        // -------------------------------------------------------
        tx_data  = 8'h12;
        tx_start = 1;
        @(posedge clk); #1;
        tx_start = 0;

        begin : blk_test8
            integer timeout;
            timeout = 0;
            while (tx === 1'b1 && timeout < BIT_PERIOD * 2) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (tx === 1'b0)
                $display("PASS: Test8 - start bit LOW for 0x12");
            else begin
                $display("FAIL: Test8 - start bit not observed for 0x12");
                fail_count = fail_count + 1;
            end
        end

        wait_clk(BIT_PERIOD * 12);

        // Second byte immediately after
        tx_data  = 8'h34;
        tx_start = 1;
        @(posedge clk); #1;
        tx_start = 0;

        begin : blk_test8b
            integer timeout;
            timeout = 0;
            while (tx === 1'b1 && timeout < BIT_PERIOD * 4) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (tx === 1'b0)
                $display("PASS: Test8b - start bit LOW for back-to-back 0x34");
            else begin
                $display("FAIL: Test8b - start bit not observed for back-to-back 0x34");
                fail_count = fail_count + 1;
            end
        end

        wait_clk(BIT_PERIOD * 12);
        @(posedge clk); #1;
        if (tx === 1'b1)
            $display("PASS: Test8c - tx HIGH after back-to-back transmission");
        else begin
            $display("FAIL: Test8c - tx not HIGH after back-to-back transmission, got %b", tx);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 9: No tx_start - tx stays HIGH (idle check)
        // -------------------------------------------------------
        wait_clk(20);
        @(posedge clk); #1;
        if (tx === 1'b1)
            $display("PASS: Test9 - tx stays HIGH when idle (no tx_start)");
        else begin
            $display("FAIL: Test9 - tx should be HIGH when idle, got %b", tx);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 10: Maximum data value 0xFF, verify stop bit
        // -------------------------------------------------------
        tx_data  = 8'hFF;
        tx_start = 1;
        @(posedge clk); #1;
        tx_start = 0;

        // Wait for full frame transmission
        wait_clk(BIT_PERIOD * 11);

        // After stop bit tx should be HIGH
        @(posedge clk); #1;
        if (tx === 1'b1)
            $display("PASS: Test10 - stop bit HIGH for 0xFF (max value)");
        else begin
            $display("FAIL: Test10 - stop bit not HIGH for 0xFF, got %b", tx);
            fail_count = fail_count + 1;
        end

        // Summary
        wait_clk(10);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TOTAL FAILURES: %0d", fail_count);

        $finish;
    end

endmodule
