`timescale 1ns/1ps

module tb_m03_uart_integration;

    // Parameters - use small values to speed up simulation
    parameter CLK_FREQ  = 50000000;
    parameter BAUD_RATE = 115200;
    parameter CLK_PERIOD = 10; // ns
    // Baud period in ns
    parameter BAUD_PERIOD_NS = (1000000000 / BAUD_RATE); // ~8680 ns

    // DUT connections
    reg        clk;
    reg        rst;
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx;
    wire       busy;

    // Instantiate DUT
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uut (
        .clk      (clk),
        .rst      (rst),
        .tx_start (tx_start),
        .tx_data  (tx_data),
        .tx       (tx),
        .busy     (busy)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Variables
    integer i;
    integer fail_count;
    reg [9:0] captured_frame; // start + 8 data + stop
    reg       sample_ok;
    integer   bit_errors;
    real      sample_time;
    integer   timeout;
    reg       test_failed;

    // Task: wait for rising edge of clk
    task wait_clk;
        begin
            @(posedge clk);
            #1; // small offset past edge
        end
    endtask

    // Task: sample a UART bit by waiting half a baud period after bit start
    // We sample in the middle of the baud period

    initial begin
        fail_count = 0;
        tx_start   = 0;
        tx_data    = 8'h00;
        rst        = 1;

        // Assert reset for exactly 5 rising clock edges
        repeat(5) @(posedge clk);
        @(posedge clk); // deassert after 5th edge
        rst = 0;

        // Wait a few clocks after reset
        repeat(5) @(posedge clk);

        // -----------------------------------------------------------
        // TEST 1: After reset, tx should be HIGH (idle), busy LOW
        // -----------------------------------------------------------
        #1;
        if (tx !== 1'b1) begin
            $display("FAIL: After reset tx should be HIGH (idle), got %b", tx);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS: After reset tx is HIGH (idle)");
        end

        if (busy !== 1'b0) begin
            $display("FAIL: After reset busy should be LOW, got %b", busy);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS: After reset busy is LOW");
        end

        // -----------------------------------------------------------
        // TEST 2: Transmit 0x55 and capture bitstream
        // -----------------------------------------------------------
        tx_data  = 8'h55;
        tx_start = 1'b1;
        @(posedge clk);
        #1;
        tx_start = 1'b0;

        // Wait for busy to go high (transmission started)
        timeout = 0;
        while (busy !== 1'b1 && timeout < 1000) begin
            @(posedge clk);
            #1;
            timeout = timeout + 1;
        end

        if (busy !== 1'b1) begin
            $display("FAIL: busy did not assert after tx_start");
            fail_count = fail_count + 1;
        end else begin
            $display("PASS: busy asserted after tx_start");
        end

        // -----------------------------------------------------------
        // TEST 3: Verify start bit is LOW
        // Sample in the middle of the start bit baud period
        // -----------------------------------------------------------
        // Wait half a baud period to sample the start bit
        #(BAUD_PERIOD_NS / 2);

        if (tx !== 1'b0) begin
            $display("FAIL: Start bit should be LOW, got %b", tx);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS: Start bit is LOW");
        end

        // Capture start bit
        captured_frame[0] = tx; // should be 0

        // -----------------------------------------------------------
        // TEST 4: Capture 8 data bits (LSB first)
        // Each bit is one baud period wide; we already waited half baud
        // so now wait full baud between samples
        // -----------------------------------------------------------
        bit_errors = 0;
        begin : capture_data_bits
            integer b;
            for (b = 0; b < 8; b = b + 1) begin
                // Wait one full baud period to reach middle of next bit
                #(BAUD_PERIOD_NS);
                captured_frame[1+b] = tx;
            end
        end

        // -----------------------------------------------------------
        // TEST 5: Capture stop bit
        // -----------------------------------------------------------
        #(BAUD_PERIOD_NS);
        captured_frame[9] = tx; // stop bit

        // Verify start bit
        if (captured_frame[0] !== 1'b0) begin
            $display("FAIL: Start bit should be 0, got %b", captured_frame[0]);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS: Start bit correctly 0");
        end

        // Verify 8 data bits LSB-first for 0x55 = 8'b01010101
        // LSB first: bit0=1, bit1=0, bit2=1, bit3=0, bit4=1, bit5=0, bit6=1, bit7=0
        test_failed = 0;
        begin : check_data
            integer b;
            reg expected_bit;
            for (b = 0; b < 8; b = b + 1) begin
                expected_bit = 8'h55[b]; // LSB first
                if (captured_frame[1+b] !== expected_bit) begin
                    $display("FAIL: Data bit %0d should be %b, got %b",
                             b, expected_bit, captured_frame[1+b]);
                    fail_count  = fail_count + 1;
                    test_failed = 1;
                end
            end
        end
        if (!test_failed) begin
            $display("PASS: All 8 data bits correct for 0x55 (LSB first)");
        end

        // Verify stop bit
        if (captured_frame[9] !== 1'b1) begin
            $display("FAIL: Stop bit should be 1, got %b", captured_frame[9]);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS: Stop bit correctly 1");
        end

        // -----------------------------------------------------------
        // TEST 6: busy goes LOW after full frame
        // -----------------------------------------------------------
        // Wait a couple more baud periods for the frame to fully complete
        #(BAUD_PERIOD_NS * 3);

        timeout = 0;
        while (busy !== 1'b0 && timeout < 5000) begin
            @(posedge clk);
            #1;
            timeout = timeout + 1;
        end

        if (busy !== 1'b0) begin
            $display("FAIL: busy did not go LOW after full frame transmission");
            fail_count = fail_count + 1;
        end else begin
            $display("PASS: busy went LOW after full frame transmission");
        end

        // -----------------------------------------------------------
        // TEST 7: tx returns to HIGH (idle) after transmission
        // -----------------------------------------------------------
        if (tx !== 1'b1) begin
            $display("FAIL: tx should return to HIGH (idle) after transmission, got %b", tx);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS: tx returned to HIGH (idle) after transmission");
        end

        // -----------------------------------------------------------
        // Summary
        // -----------------------------------------------------------
        if (fail_count == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("SOME TESTS FAILED: %0d failure(s)", fail_count);
        end

        $finish;
    end

    // Timeout watchdog
    initial begin
        #(BAUD_PERIOD_NS * 30);
        $display("FAIL: Simulation timeout - design may be hung");
        $finish;
    end

endmodule
