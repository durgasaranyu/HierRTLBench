`timescale 1ns/1ps

module tb_m03_uart_integration;

// Parameters - use small values for simulation speed
parameter CLK_FREQ  = 50000000;
parameter BAUD_RATE = 115200;
parameter BAUD_DIV  = CLK_FREQ / BAUD_RATE; // ~434 clocks per bit

// DUT connections
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
reg [9:0] captured_bits;   // start + 8 data + stop
integer   bit_index;
integer   fail_count;
integer   i;

// Task: wait for N rising edges
task wait_cycles;
    input integer n;
    integer k;
    begin
        for (k = 0; k < n; k = k + 1)
            @(posedge clk);
    end
endtask

// Task: sample tx after half a baud period from now
task sample_bit;
    output reg sampled;
    integer half_baud;
    begin
        half_baud = BAUD_DIV / 2;
        wait_cycles(half_baud);
        sampled = tx;
        // advance to near end of bit period
        wait_cycles(BAUD_DIV - half_baud);
    end
endtask

//----------------------------------------------------------------------
// Main test
//----------------------------------------------------------------------
initial begin
    fail_count = 0;
    tx_start   = 0;
    tx_data    = 8'h00;

    // Apply synchronous reset for exactly 5 rising edges
    rst = 1;
    @(posedge clk); // 1
    @(posedge clk); // 2
    @(posedge clk); // 3
    @(posedge clk); // 4
    @(posedge clk); // 5
    @(negedge clk);
    rst = 0;

    // Short idle after reset
    wait_cycles(10);

    // Verify tx is idle HIGH after reset
    @(posedge clk);
    if (tx === 1'b1)
        $display("PASS: tx idle HIGH after reset");
    else begin
        $display("FAIL: tx not idle HIGH after reset (tx=%b)", tx);
        fail_count = fail_count + 1;
    end

    // Verify busy is LOW after reset
    if (busy === 1'b0)
        $display("PASS: busy LOW after reset");
    else begin
        $display("FAIL: busy not LOW after reset (busy=%b)", busy);
        fail_count = fail_count + 1;
    end

    //------------------------------------------------------------------
    // Transmit 0x55 = 8'b0101_0101
    // UART 8-N-1: start bit(0), D0 D1 D2 D3 D4 D5 D6 D7, stop bit(1)
    // 0x55 LSB-first: 1,0,1,0,1,0,1,0
    //------------------------------------------------------------------
    tx_data  = 8'h55;
    tx_start = 1;
    @(posedge clk);
    tx_start = 0;

    // The module latches tx_start and begins transmission.
    // We wait a small number of cycles then start sampling bits.
    // Give the FSM a few cycles to assert the start bit
    wait_cycles(4);

    // Sample start bit
    // Position ourselves at the middle of the start bit
    // The baud counter starts at 0 and counts up to BAUD_DIV.
    // After tx_start, the module sets busy. The start bit (tx=0) appears
    // after the baud_tick logic processes it.
    // We'll sample from the beginning of transmission; wait half baud
    wait_cycles(BAUD_DIV/2 - 4); // adjust for the 4 cycles already waited

    captured_bits[0] = tx; // start bit sample

    // Now sample 8 data bits, each BAUD_DIV clocks apart
    for (i = 1; i <= 8; i = i + 1) begin
        wait_cycles(BAUD_DIV);
        captured_bits[i] = tx;
    end

    // Sample stop bit
    wait_cycles(BAUD_DIV);
    captured_bits[9] = tx;

    // Wait for busy to deassert
    wait_cycles(BAUD_DIV * 2);

    //------------------------------------------------------------------
    // Verify start bit = 0
    //------------------------------------------------------------------
    if (captured_bits[0] === 1'b0)
        $display("PASS: Start bit is LOW");
    else begin
        $display("FAIL: Start bit should be LOW, got %b", captured_bits[0]);
        fail_count = fail_count + 1;
    end

    //------------------------------------------------------------------
    // Verify 8 data bits for 0x55 (LSB first: 1,0,1,0,1,0,1,0)
    //------------------------------------------------------------------
    begin : check_data
        reg [7:0] expected;
        reg       ok;
        integer   b;
        expected = 8'h55;
        ok = 1;
        for (b = 0; b < 8; b = b + 1) begin
            if (captured_bits[b+1] !== expected[b]) begin
                ok = 0;
                $display("FAIL: Data bit %0d expected %b got %b",
                         b, expected[b], captured_bits[b+1]);
                fail_count = fail_count + 1;
            end
        end
        if (ok)
            $display("PASS: All 8 data bits match 0x55 (LSB-first)");
    end

    //------------------------------------------------------------------
    // Verify stop bit = 1
    //------------------------------------------------------------------
    if (captured_bits[9] === 1'b1)
        $display("PASS: Stop bit is HIGH");
    else begin
        $display("FAIL: Stop bit should be HIGH, got %b", captured_bits[9]);
        fail_count = fail_count + 1;
    end

    //------------------------------------------------------------------
    // Verify busy goes LOW after frame (it may already be low)
    //------------------------------------------------------------------
    if (busy === 1'b0)
        $display("PASS: busy deasserted after full frame");
    else begin
        // wait more
        wait_cycles(BAUD_DIV * 4);
        if (busy === 1'b0)
            $display("PASS: busy deasserted after full frame (delayed)");
        else begin
            $display("FAIL: busy still HIGH after full frame");
            fail_count = fail_count + 1;
        end
    end

    //------------------------------------------------------------------
    // Verify tx returns to idle HIGH
    //------------------------------------------------------------------
    if (tx === 1'b1)
        $display("PASS: tx returns to idle HIGH after frame");
    else begin
        $display("FAIL: tx not idle HIGH after frame (tx=%b)", tx);
        fail_count = fail_count + 1;
    end

    //------------------------------------------------------------------
    // Summary
    //------------------------------------------------------------------
    if (fail_count == 0)
        $display("PASS: All integration tests passed");
    else
        $display("FAIL: %0d test(s) failed", fail_count);

    $finish;
end

// Timeout watchdog
initial begin
    #500000000; // 500ms
    $display("FAIL: Simulation timeout");
    $finish;
end

endmodule
