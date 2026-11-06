`timescale 1ns/1ps

module tb_m03_uart_integration;

// Parameters - use small values to make simulation fast
parameter CLK_FREQ  = 50000000;
parameter BAUD_RATE = 115200;
parameter CLK_PERIOD = 10; // 10 ns => 100 MHz for sim purposes

// Baud period in clock cycles (at 50 MHz / 115200)
// For simulation with CLK_FREQ=50000000, BAUD_RATE=115200:
// cycles_per_bit = 50000000/115200 = ~434
parameter CYCLES_PER_BIT = CLK_FREQ / BAUD_RATE; // 434

// DUT ports
reg        clk;
reg        rst;
reg        tx_start;
reg  [7:0] tx_data;
wire       tx;
wire       busy;

// Instantiate DUT
uart_tx #(
    .CLK_FREQ  (CLK_FREQ),
    .BAUD_RATE (BAUD_RATE)
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

// Captured bitstream storage
reg [9:0] captured_bits; // start + 8 data + stop
integer   bit_idx;
integer   sample_time;
integer   i;
integer   fail_count;
integer   pass_count;

reg start_bit_ok;
reg data_bits_ok;
reg stop_bit_ok;
reg busy_low_ok;

// Task: wait for N rising edges
task wait_cycles;
    input integer n;
    integer k;
    begin
        for (k = 0; k < n; k = k + 1)
            @(posedge clk);
    end
endtask

// Task: sample tx in the middle of each bit period
// We sample at CYCLES_PER_BIT/2 into each bit period
task sample_bit;
    output reg samp;
    begin
        // Wait half a baud period
        wait_cycles(CYCLES_PER_BIT / 2);
        samp = tx;
        // Wait remaining half period to reach next bit boundary
        wait_cycles(CYCLES_PER_BIT - CYCLES_PER_BIT / 2);
    end
endtask

initial begin
    // Initialise
    tx_start  = 0;
    tx_data   = 8'h00;
    fail_count = 0;
    pass_count = 0;

    // Assert synchronous reset for exactly 5 rising edges
    rst = 1;
    @(posedge clk); // 1
    @(posedge clk); // 2
    @(posedge clk); // 3
    @(posedge clk); // 4
    @(posedge clk); // 5
    @(negedge clk); // deassert between edges to make it synchronous
    rst = 0;

    // Wait a few cycles after reset
    wait_cycles(10);

    // -------------------------------------------------------
    // TEST 1: Transmit 0x55 (01010101), verify full frame
    // -------------------------------------------------------
    tx_data  = 8'h55;
    tx_start = 1;
    @(posedge clk);
    tx_start = 0;

    // Wait for tx to go LOW (start bit) - poll with timeout
    begin : wait_start
        integer timeout;
        timeout = 0;
        while (tx !== 1'b0 && timeout < 10000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (timeout >= 10000) begin
            $display("FAIL: Timeout waiting for start bit");
            fail_count = fail_count + 1;
            disable wait_start;
        end
    end

    // Now sample in the middle of the start bit
    // We just detected falling edge; wait half baud to reach centre
    wait_cycles(CYCLES_PER_BIT / 2);
    captured_bits[0] = tx; // start bit sample

    // Sample 8 data bits
    for (i = 1; i <= 8; i = i + 1) begin
        wait_cycles(CYCLES_PER_BIT);
        captured_bits[i] = tx;
    end

    // Sample stop bit
    wait_cycles(CYCLES_PER_BIT);
    captured_bits[9] = tx;

    // -------------------------------------------------------
    // Check start bit = 0
    // -------------------------------------------------------
    if (captured_bits[0] === 1'b0) begin
        $display("PASS: Start bit is LOW");
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL: Start bit expected LOW, got %b", captured_bits[0]);
        fail_count = fail_count + 1;
    end

    // -------------------------------------------------------
    // Check 8 data bits LSB-first for 0x55 = 8'b01010101
    // LSB-first order: bit0=1, bit1=0, bit2=1, bit3=0, bit4=1, bit5=0, bit6=1, bit7=0
    // captured_bits[1..8]
    // -------------------------------------------------------
    data_bits_ok = 1'b1;
    for (i = 0; i < 8; i = i + 1) begin
        if (captured_bits[i+1] !== tx_data[i]) begin
            data_bits_ok = 1'b0;
            $display("FAIL: Data bit %0d expected %b got %b", i, tx_data[i], captured_bits[i+1]);
        end
    end
    if (data_bits_ok) begin
        $display("PASS: All 8 data bits correct (0x55 LSB-first)");
        pass_count = pass_count + 1;
    end else begin
        fail_count = fail_count + 1;
    end

    // -------------------------------------------------------
    // Check stop bit = 1
    // -------------------------------------------------------
    if (captured_bits[9] === 1'b1) begin
        $display("PASS: Stop bit is HIGH");
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL: Stop bit expected HIGH, got %b", captured_bits[9]);
        fail_count = fail_count + 1;
    end

    // -------------------------------------------------------
    // Wait for stop bit to complete, then check busy goes LOW
    // -------------------------------------------------------
    // We're at the middle of the stop bit; wait another half + some extra
    wait_cycles(CYCLES_PER_BIT / 2 + CYCLES_PER_BIT * 2);

    if (busy === 1'b0) begin
        $display("PASS: busy went LOW after full frame");
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL: busy still HIGH after frame should be complete");
        fail_count = fail_count + 1;
    end

    // -------------------------------------------------------
    // TEST 2: Verify tx is IDLE HIGH after transmission
    // -------------------------------------------------------
    if (tx === 1'b1) begin
        $display("PASS: tx is HIGH (idle) after frame");
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL: tx should be HIGH (idle) after frame, got %b", tx);
        fail_count = fail_count + 1;
    end

    // -------------------------------------------------------
    // TEST 3: Verify reset clears busy and tx remains defined
    // -------------------------------------------------------
    rst = 1;
    wait_cycles(5);
    rst = 0;
    wait_cycles(5);

    if (busy === 1'b0) begin
        $display("PASS: busy is LOW after reset");
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL: busy should be LOW after reset, got %b", busy);
        fail_count = fail_count + 1;
    end

    // -------------------------------------------------------
    // Summary
    // -------------------------------------------------------
    $display("-----------------------------------");
    $display("Integration test complete: %0d PASS, %0d FAIL", pass_count, fail_count);
    if (fail_count == 0)
        $display("ALL TESTS PASSED");
    else
        $display("SOME TESTS FAILED");
    $display("-----------------------------------");

    $finish;
end

endmodule
