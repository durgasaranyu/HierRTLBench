`timescale 1ns/1ps

module tb_uart_tx_top;

    // Parameters
    parameter CLK_FREQ  = 50000000;
    parameter BAUD_RATE = 115200;

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

    // Task: wait N rising edges
    task wait_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    // Variables for checking
    integer test_num;
    reg pass;

    initial begin
        // Initialise inputs
        rst      = 1;
        tx_start = 0;
        tx_data  = 8'h00;
        test_num = 0;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;

        // Allow a couple of cycles to settle
        wait_cycles(2);

        // -----------------------------------------------------------
        // TEST 1: After reset, tx and busy should be 0 (quiescent)
        // -----------------------------------------------------------
        wait_cycles(2);
        pass = (tx === 1'b0) && (busy === 1'b0);
        if (pass)
            $display("PASS: Test 1 - After reset tx=0 and busy=0");
        else
            $display("FAIL: Test 1 - After reset tx=%b busy=%b (expected 0,0)", tx, busy);

        // -----------------------------------------------------------
        // TEST 2: No tx_start pulse => tx and busy remain 0
        // -----------------------------------------------------------
        tx_start = 0;
        tx_data  = 8'hAA;
        wait_cycles(5);
        pass = (tx === 1'b0) && (busy === 1'b0);
        if (pass)
            $display("PASS: Test 2 - No tx_start, tx=0, busy=0");
        else
            $display("FAIL: Test 2 - No tx_start, tx=%b busy=%b", tx, busy);

        // -----------------------------------------------------------
        // TEST 3: Single cycle tx_start pulse with data 0x55
        //         After enough pipeline delays, tx and busy should
        //         reflect the pipeline behaviour
        // -----------------------------------------------------------
        tx_data  = 8'h55;
        tx_start = 1;
        @(posedge clk);
        tx_start = 0;

        // Wait for pipeline to propagate (several cycles)
        wait_cycles(3);
        // busy_s_s is 10 cycles after tx_start_s; tx_s is a few cycles
        // Just check that eventually busy deasserts after tx_start=0
        wait_cycles(15);
        pass = (busy === 1'b0);
        if (pass)
            $display("PASS: Test 3 - busy deasserted after single-cycle pulse (data=0x55)");
        else
            $display("FAIL: Test 3 - busy still %b after pulse cleared (data=0x55)", busy);

        // -----------------------------------------------------------
        // TEST 4: All-zero data, single cycle tx_start
        // -----------------------------------------------------------
        tx_data  = 8'h00;
        tx_start = 1;
        @(posedge clk);
        tx_start = 0;
        wait_cycles(15);
        pass = (busy === 1'b0);
        if (pass)
            $display("PASS: Test 4 - busy deasserted after pulse (data=0x00)");
        else
            $display("FAIL: Test 4 - busy=%b after pulse (data=0x00)", busy);

        // -----------------------------------------------------------
        // TEST 5: All-ones data 0xFF, single cycle tx_start
        // -----------------------------------------------------------
        tx_data  = 8'hFF;
        tx_start = 1;
        @(posedge clk);
        tx_start = 0;
        wait_cycles(15);
        pass = (busy === 1'b0);
        if (pass)
            $display("PASS: Test 5 - busy deasserted after pulse (data=0xFF)");
        else
            $display("FAIL: Test 5 - busy=%b after pulse (data=0xFF)", busy);

        // -----------------------------------------------------------
        // TEST 6: During the tx_start pulse, busy goes HIGH
        //         (pipeline driven from tx_start_s chain)
        // -----------------------------------------------------------
        tx_data  = 8'hA5;
        tx_start = 1;
        // Wait a few cycles for pipeline to propagate to busy
        wait_cycles(5);
        pass = (busy === 1'b1);
        if (pass)
            $display("PASS: Test 6 - busy asserts while tx_start held high (data=0xA5)");
        else
            $display("FAIL: Test 6 - busy=%b while tx_start=1 (data=0xA5)", busy);
        tx_start = 0;
        wait_cycles(15);

        // -----------------------------------------------------------
        // TEST 7: tx follows tx_start_s_r (pipeline): hold tx_start
        //         and check tx asserts
        // -----------------------------------------------------------
        tx_data  = 8'h3C;
        tx_start = 1;
        wait_cycles(5);
        pass = (tx === 1'b1);
        if (pass)
            $display("PASS: Test 7 - tx asserts while tx_start held high (data=0x3C)");
        else
            $display("FAIL: Test 7 - tx=%b while tx_start=1 (data=0x3C)", tx);
        tx_start = 0;
        wait_cycles(15);

        // -----------------------------------------------------------
        // TEST 8: After tx_start deasserts, tx returns LOW
        // -----------------------------------------------------------
        tx_data  = 8'hB7;
        tx_start = 1;
        @(posedge clk);
        tx_start = 0;
        wait_cycles(15);
        pass = (tx === 1'b0);
        if (pass)
            $display("PASS: Test 8 - tx deasserts after tx_start pulse removed (data=0xB7)");
        else
            $display("FAIL: Test 8 - tx=%b after tx_start cleared (data=0xB7)", tx);

        // -----------------------------------------------------------
        // TEST 9: Reset during active transmission clears outputs
        // -----------------------------------------------------------
        tx_data  = 8'hDE;
        tx_start = 1;
        wait_cycles(5);
        // Apply reset
        rst = 1;
        wait_cycles(5);
        rst = 0;
        wait_cycles(3);
        pass = (tx === 1'b0) && (busy === 1'b0);
        if (pass)
            $display("PASS: Test 9 - Reset clears tx and busy during transmission");
        else
            $display("FAIL: Test 9 - After mid-tx reset tx=%b busy=%b", tx, busy);
        tx_start = 0;
        wait_cycles(5);

        // -----------------------------------------------------------
        // TEST 10: Back-to-back start pulses (max value 0xFF then 0x00)
        // -----------------------------------------------------------
        tx_data  = 8'hFF;
        tx_start = 1;
        @(posedge clk);
        tx_data  = 8'h00;
        @(posedge clk);
        tx_start = 0;
        wait_cycles(15);
        pass = (busy === 1'b0);
        if (pass)
            $display("PASS: Test 10 - Back-to-back pulses, busy deasserts (0xFF->0x00)");
        else
            $display("FAIL: Test 10 - busy=%b after back-to-back pulses", busy);

        // Final settling
        wait_cycles(10);

        $finish;
    end

endmodule
