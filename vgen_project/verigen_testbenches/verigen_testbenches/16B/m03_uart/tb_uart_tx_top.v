`timescale 1ns/1ps

module tb_uart_tx_top;

    // ---------------------------------------------------------------
    // Parameters – use very small divisor so simulation is fast
    // ---------------------------------------------------------------
    parameter CLK_FREQ  = 50000000;
    parameter BAUD_RATE = 115200;
    localparam BAUD_DIV = CLK_FREQ / BAUD_RATE; // ~434

    // ---------------------------------------------------------------
    // DUT signals
    // ---------------------------------------------------------------
    reg        clk;
    reg        rst;
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx;
    wire       busy;

    // ---------------------------------------------------------------
    // DUT instantiation
    // ---------------------------------------------------------------
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

    // ---------------------------------------------------------------
    // Clock generation – 10 ns period
    // ---------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // ---------------------------------------------------------------
    // Helper integer / task variables
    // ---------------------------------------------------------------
    integer i;
    integer pass_cnt;
    integer fail_cnt;

    // ---------------------------------------------------------------
    // Task: wait for N rising edges
    // ---------------------------------------------------------------
    task wait_cycles;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1)
                @(posedge clk);
        end
    endtask

    // ---------------------------------------------------------------
    // Task: pulse tx_start for one clock with given data, then release
    // ---------------------------------------------------------------
    task send_byte;
        input [7:0] data;
        begin
            @(negedge clk);      // drive on falling edge
            tx_data  = data;
            tx_start = 1;
            @(posedge clk);      // one rising edge sees start
            @(negedge clk);
            tx_start = 0;
        end
    endtask

    // ---------------------------------------------------------------
    // Main test
    // ---------------------------------------------------------------
    initial begin
        pass_cnt = 0;
        fail_cnt = 0;

        // ---- Initialise inputs ----
        rst      = 1;
        tx_start = 0;
        tx_data  = 8'h00;

        // ---- Assert reset for exactly 5 rising edges ----
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;

        // ==============================================================
        // TEST 1: After reset tx should be HIGH (idle), busy = 0
        // ==============================================================
        @(posedge clk); #1;
        if (tx === 1'b1 && busy === 1'b0) begin
            $display("PASS: T1 – After reset tx=1 (idle), busy=0");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("FAIL: T1 – After reset tx=%b busy=%b (expected tx=1 busy=0)", tx, busy);
            fail_cnt = fail_cnt + 1;
        end

        // ==============================================================
        // TEST 2: tx_start asserted → busy becomes 1
        // ==============================================================
        @(negedge clk);
        tx_data  = 8'hA5;
        tx_start = 1;
        @(posedge clk); #1;
        if (busy === 1'b1) begin
            $display("PASS: T2 – tx_start asserted, busy=1");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("FAIL: T2 – tx_start asserted but busy=%b (expected 1)", busy);
            fail_cnt = fail_cnt + 1;
        end
        @(negedge clk);
        tx_start = 0;

        // ==============================================================
        // TEST 3: tx line goes LOW (start bit) after tx_start
        // Wait a couple of baud periods for the START bit to appear
        // ==============================================================
        // The DUT drives tx_r<=0 in the else branch; wait enough cycles
        wait_cycles(BAUD_DIV * 2);
        if (tx === 1'b0) begin
            $display("PASS: T3 – Start bit: tx=0");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("FAIL: T3 – Expected start bit LOW, got tx=%b", tx);
            fail_cnt = fail_cnt + 1;
        end

        // ==============================================================
        // TEST 4: busy deasserts eventually (after stop bit region)
        // ==============================================================
        // Wait up to 15 baud periods for busy to go low
        begin : wait_busy_low
            integer timeout;
            timeout = 0;
            while (busy === 1'b1 && timeout < BAUD_DIV * 15) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
        end
        if (busy === 1'b0) begin
            $display("PASS: T4 – busy deasserted after transmission");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("FAIL: T4 – busy still high after %0d cycles", BAUD_DIV * 15);
            fail_cnt = fail_cnt + 1;
        end

        // ==============================================================
        // TEST 5: tx returns HIGH (idle / stop) after busy deasserts
        // ==============================================================
        if (tx === 1'b1) begin
            $display("PASS: T5 – tx=1 (idle/stop) after busy deasserts");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("FAIL: T5 – tx=%b after busy deasserted (expected 1)", tx);
            fail_cnt = fail_cnt + 1;
        end

        // ==============================================================
        // TEST 6: All-zero data (0x00)
        // ==============================================================
        wait_cycles(5);
        send_byte(8'h00);
        @(posedge clk); #1;
        if (busy === 1'b1) begin
            $display("PASS: T6 – tx_start with 0x00 sets busy=1");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("FAIL: T6 – tx_start with 0x00, busy=%b (expected 1)", busy);
            fail_cnt = fail_cnt + 1;
        end
        // wait for idle
        begin : wait_busy_low2
            integer timeout2;
            timeout2 = 0;
            while (busy === 1'b1 && timeout2 < BAUD_DIV * 15) begin
                @(posedge clk);
                timeout2 = timeout2 + 1;
            end
        end

        // ==============================================================
        // TEST 7: All-ones data (0xFF)
        // ==============================================================
        wait_cycles(5);
        send_byte(8'hFF);
        @(posedge clk); #1;
        if (busy === 1'b1) begin
            $display("PASS: T7 – tx_start with 0xFF sets busy=1");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("FAIL: T7 – tx_start with 0xFF, busy=%b (expected 1)", busy);
            fail_cnt = fail_cnt + 1;
        end
        begin : wait_busy_low3
            integer timeout3;
            timeout3 = 0;
            while (busy === 1'b1 && timeout3 < BAUD_DIV * 15) begin
                @(posedge clk);
                timeout3 = timeout3 + 1;
            end
        end

        // ==============================================================
        // TEST 8: Second tx_start while idle (normal re-trigger)
        // ==============================================================
        wait_cycles(5);
        send_byte(8'h55);
        @(posedge clk); #1;
        if (busy === 1'b1) begin
            $display("PASS: T8 – Re-trigger with 0x55, busy=1");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("FAIL: T8 – Re-trigger with 0x55, busy=%b (expected 1)", busy);
            fail_cnt = fail_cnt + 1;
        end
        begin : wait_busy_low4
            integer timeout4;
            timeout4 = 0;
            while (busy === 1'b1 && timeout4 < BAUD_DIV * 15) begin
                @(posedge clk);
                timeout4 = timeout4 + 1;
            end
        end

        // ==============================================================
        // TEST 9: Reset mid-transmission clears busy
        // ==============================================================
        wait_cycles(3);
        send_byte(8'hAA);
        wait_cycles(2);           // mid-way through
        @(negedge clk); rst = 1;
        repeat (5) @(posedge clk);
        @(negedge clk); rst = 0;
        @(posedge clk); #1;
        if (tx === 1'b1 && busy === 1'b0) begin
            $display("PASS: T9 – Mid-tx reset clears busy, tx=1");
            pass_cnt = pass_cnt + 1;
        end else begin
            $display("FAIL: T9 – After mid-tx reset: tx=%b busy=%b (expected tx=1 busy=0)", tx, busy);
            fail_cnt = fail_cnt + 1;
        end

        // ==============================================================
        // Summary
        // ==============================================================
        $display("--------------------------------------");
        $display("Results: %0d PASS, %0d FAIL", pass_cnt, fail_cnt);
        $display("--------------------------------------");

        $finish;
    end

endmodule
