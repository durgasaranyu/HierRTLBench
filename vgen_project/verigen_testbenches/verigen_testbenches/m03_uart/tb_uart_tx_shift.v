`timescale 1ns/1ps

// Define required macros for the uart_tx_shift module
`define UartParityType 2'b00
`define UartWidth 8
`define UartShift 8
`define UartParityType_defaultEncoding_NONE 2'b00
`define UartParityType_defaultEncoding_ODD  2'b01
`define UartParityType_defaultEncoding_EVEN 2'b10
`define UartParityState_defaultEncoding_IDLE  4'b0000
`define UartParityState_defaultEncoding_START 4'b0001
`define UartParityState_defaultEncoding_STOP  4'b0010
`define UartParityState_defaultEncoding_ODD   4'b0011
`define UartParityState_defaultEncoding_EVEN  4'b0100
`define UartCtrlTxState_defaultEncoding_IDLE   4'b0000
`define UartCtrlTxState_defaultEncoding_START  4'b0001
`define UartCtrlTxState_defaultEncoding_DATA   4'b0010
`define UartCtrlTxState_defaultEncoding_PARITY 4'b0011
`define UartCtrlTxState_defaultEncoding_STOP   4'b0100

module tb_uart_tx_shift;

    // Clock and reset
    reg clk;
    reg rst;

    // DUT inputs
    reg        load;
    reg        shift_en;
    reg [7:0]  data;

    // DUT outputs
    wire       serial_out;
    wire       empty;

    // Instantiate DUT
    uart_tx_shift uut (
        .clk       (clk),
        .rst       (rst),
        .load      (load),
        .shift_en  (shift_en),
        .data      (data),
        .serial_out(serial_out),
        .empty     (empty)
    );

    // Clock generation: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Task: apply one clock cycle
    task tick;
        begin
            @(posedge clk);
            #1; // small delay after posedge for output sampling
        end
    endtask

    integer i;
    integer pass_count;
    integer fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize inputs
        rst      = 1;
        load     = 0;
        shift_en = 0;
        data     = 8'h00;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        #1;

        // Deassert reset
        rst = 0;
        @(posedge clk); #1;

        // ---------------------------------------------------------------
        // Test 1: After reset, empty should be 1 (bit_counter == 0)
        // ---------------------------------------------------------------
        if (empty === 1'b1) begin
            $display("PASS: After reset, empty is asserted (bit_counter==0)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After reset, empty should be 1, got %b", empty);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 2: serial_out reflects data[0] with all-zero input
        // ---------------------------------------------------------------
        data     = 8'h00;
        load     = 0;
        shift_en = 0;
        @(posedge clk); #1;
        if (serial_out === 1'b0) begin
            $display("PASS: serial_out is 0 when data=0x00");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: serial_out should be 0 when data=0x00, got %b", serial_out);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 3: serial_out reflects data[0] with all-ones input
        // ---------------------------------------------------------------
        data     = 8'hFF;
        load     = 0;
        shift_en = 0;
        @(posedge clk); #1;
        if (serial_out === 1'b1) begin
            $display("PASS: serial_out is 1 when data=0xFF");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: serial_out should be 1 when data=0xFF, got %b", serial_out);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 4: Load a byte (0xA5 = 1010_0101), serial_out = data[0] = 1
        // empty should still be 1 immediately after load pulse (bit_counter reset to 0)
        // ---------------------------------------------------------------
        data     = 8'hA5;
        load     = 1;
        @(posedge clk); #1;
        load     = 0;
        // After load posedge: bit_counter set to 0 => empty = 1
        if (empty === 1'b1) begin
            $display("PASS: After load, empty is 1 (bit_counter reset to 0)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After load, empty should be 1, got %b", empty);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 5: serial_out = data[0] of current data (0xA5, bit0 = 1)
        // serial_out is combinationally assigned as data[0] from the input port
        // ---------------------------------------------------------------
        data = 8'hA5;
        @(posedge clk); #1;
        if (serial_out === 1'b1) begin
            $display("PASS: serial_out=data[0]=1 for data=0xA5");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: serial_out should be 1 for data=0xA5, got %b", serial_out);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 6: After shift_en pulses, bit_counter increments, empty goes 0
        // ---------------------------------------------------------------
        // Load 0x55 first
        rst      = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        data     = 8'h55;
        load     = 1;
        @(posedge clk); #1;
        load     = 0;

        // Apply one shift_en pulse
        shift_en = 1;
        @(posedge clk); #1;
        shift_en = 0;
        // Now bit_counter should be 1 => empty = 0
        if (empty === 1'b0) begin
            $display("PASS: After 1 shift_en, empty is 0 (bit_counter=1)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After 1 shift_en, empty should be 0, got %b", empty);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 7: After 8 shift_en pulses (bit_counter wraps to 0), empty = 1
        //         Note: bit_counter is 8-bit, after 8 increments from 0 it's 8 (not 0).
        //         Actually after 256 it wraps. Let's check 255 more pulses to wrap,
        //         but more practical: after load, bit_counter=0, one more load resets.
        //         Instead check bit_counter != 0 after 7 more pulses (total 8 pulses).
        // ---------------------------------------------------------------
        // We already did 1 pulse, do 7 more = 8 total
        for (i = 0; i < 7; i = i + 1) begin
            shift_en = 1;
            @(posedge clk); #1;
            shift_en = 0;
            @(posedge clk); #1;
        end
        // bit_counter should now be 8 (not 0), so empty = 0
        // empty = (bit_counter == 0)
        if (empty === 1'b0) begin
            $display("PASS: After 8 shift_en pulses, bit_counter=8, empty=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After 8 shift_en pulses, expected empty=0, got %b", empty);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 8: serial_out changes with data input (LSB first - combinational)
        // data=0x01 => bit0=1
        // ---------------------------------------------------------------
        data = 8'h01;
        @(posedge clk); #1;
        if (serial_out === 1'b1) begin
            $display("PASS: serial_out=1 for data=0x01 (LSB=1)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: serial_out should be 1 for data=0x01, got %b", serial_out);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 9: serial_out=0 for data=0xFE (bit0=0)
        // ---------------------------------------------------------------
        data = 8'hFE;
        @(posedge clk); #1;
        if (serial_out === 1'b0) begin
            $display("PASS: serial_out=0 for data=0xFE (LSB=0)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: serial_out should be 0 for data=0xFE, got %b", serial_out);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 10: Reset during operation clears bit_counter => empty = 1
        // ---------------------------------------------------------------
        shift_en = 1;
        @(posedge clk); #1;
        shift_en = 0;
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;
        if (empty === 1'b1) begin
            $display("PASS: After mid-operation reset, empty=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After mid-operation reset, empty should be 1, got %b", empty);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 11: Load with maximum value 0xFF, serial_out=data[0]=1
        // ---------------------------------------------------------------
        data = 8'hFF;
        load = 1;
        @(posedge clk); #1;
        load = 0;
        if (serial_out === 1'b1 && empty === 1'b1) begin
            $display("PASS: Load 0xFF: serial_out=1, empty=1 after load");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Load 0xFF: expected serial_out=1 empty=1, got serial_out=%b empty=%b",
                     serial_out, empty);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 12: Load 0x00, serial_out=data[0]=0
        // ---------------------------------------------------------------
        data = 8'h00;
        load = 1;
        @(posedge clk); #1;
        load = 0;
        if (serial_out === 1'b0 && empty === 1'b1) begin
            $display("PASS: Load 0x00: serial_out=0, empty=1 after load");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Load 0x00: expected serial_out=0 empty=1, got serial_out=%b empty=%b",
                     serial_out, empty);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Summary
        // ---------------------------------------------------------------
        $display("-----------------------------");
        $display("Tests completed: PASS=%0d, FAIL=%0d", pass_count, fail_count);
        $display("-----------------------------");

        $finish;
    end

endmodule
