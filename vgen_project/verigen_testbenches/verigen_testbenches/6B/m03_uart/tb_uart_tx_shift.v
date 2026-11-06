`timescale 1ns/1ps

// Define the macros needed by the DUT
`define UartParityType 2'b00
`define UartWidth 8
`define UartShift 8
`define UartParityType_defaultEncoding_NONE 2'b00
`define UartParityType_defaultEncoding_ODD  2'b01
`define UartParityType_defaultEncoding_EVEN 2'b10
`define UartParityState_defaultEncoding_IDLE  4'd0
`define UartParityState_defaultEncoding_START 4'd1
`define UartParityState_defaultEncoding_STOP  4'd2
`define UartParityState_defaultEncoding_ODD   4'd3
`define UartParityState_defaultEncoding_EVEN  4'd4
`define UartCtrlTxState_defaultEncoding_IDLE   4'd0
`define UartCtrlTxState_defaultEncoding_START  4'd1
`define UartCtrlTxState_defaultEncoding_DATA   4'd2
`define UartCtrlTxState_defaultEncoding_PARITY 4'd3
`define UartCtrlTxState_defaultEncoding_STOP   4'd4

module tb_uart_tx_shift;

    // DUT signals
    reg        clk;
    reg        rst;
    reg        load;
    reg        shift_en;
    reg  [7:0] data;
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

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    integer i;
    integer pass_count;
    integer fail_count;

    // Task to apply one clock cycle
    task tick;
        begin
            @(posedge clk);
            #1; // small delay after posedge for signal sampling
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize inputs
        rst      = 1;
        load     = 0;
        shift_en = 0;
        data     = 8'h00;

        // Assert reset for exactly 5 clock rising edges
        @(posedge clk); // 1
        @(posedge clk); // 2
        @(posedge clk); // 3
        @(posedge clk); // 4
        @(posedge clk); // 5
        #1;
        rst = 0;

        // --- Test 1: After reset, empty should be asserted (bit_counter == 0) ---
        tick;
        if (empty === 1'b1) begin
            $display("PASS: After reset, empty is asserted");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After reset, empty should be asserted, got %b", empty);
            fail_count = fail_count + 1;
        end

        // --- Test 2: serial_out reflects data[0] with all-zero input ---
        data     = 8'h00;
        load     = 0;
        shift_en = 0;
        tick;
        if (serial_out === 1'b0) begin
            $display("PASS: serial_out is 0 when data=0x00");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: serial_out should be 0 when data=0x00, got %b", serial_out);
            fail_count = fail_count + 1;
        end

        // --- Test 3: serial_out reflects data[0] with all-ones input ---
        data     = 8'hFF;
        load     = 0;
        shift_en = 0;
        tick;
        if (serial_out === 1'b1) begin
            $display("PASS: serial_out is 1 when data=0xFF");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: serial_out should be 1 when data=0xFF, got %b", serial_out);
            fail_count = fail_count + 1;
        end

        // --- Test 4: Load data 0xA5, check serial_out = data[0] = 1 ---
        data     = 8'hA5; // 1010_0101, LSB=1
        load     = 1;
        shift_en = 0;
        @(posedge clk); #1;
        load     = 0;
        // serial_out = data[0] which is the current 'data' input = 8'hA5[0] = 1
        // However, serial_out is assigned as data[0] combinatorially
        // So we check serial_out now with data still at 8'hA5
        if (serial_out === 1'b1) begin
            $display("PASS: After load 0xA5, serial_out=data[0]=1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After load 0xA5, serial_out=data[0] should be 1, got %b", serial_out);
            fail_count = fail_count + 1;
        end

        // --- Test 5: After load, empty should be asserted (bit_counter reset to 0) ---
        tick;
        if (empty === 1'b1) begin
            $display("PASS: After load, empty is asserted (bit_counter=0)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After load, empty should be asserted, got %b", empty);
            fail_count = fail_count + 1;
        end

        // --- Test 6: After one shift_en pulse, bit_counter increments, empty deasserts ---
        data     = 8'hA5;
        shift_en = 1;
        @(posedge clk); #1;
        shift_en = 0;
        tick;
        if (empty === 1'b0) begin
            $display("PASS: After 1 shift, empty deasserted (bit_counter=1)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After 1 shift, empty should be deasserted, got %b", empty);
            fail_count = fail_count + 1;
        end

        // --- Test 7: Verify serial_out = data[0] for data=0x01 (LSB=1) ---
        data     = 8'h01;
        shift_en = 0;
        load     = 0;
        tick;
        if (serial_out === 1'b1) begin
            $display("PASS: serial_out=1 for data=0x01 (LSB=1)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: serial_out should be 1 for data=0x01, got %b", serial_out);
            fail_count = fail_count + 1;
        end

        // --- Test 8: Verify serial_out = data[0] for data=0x02 (LSB=0) ---
        data     = 8'h02;
        shift_en = 0;
        load     = 0;
        tick;
        if (serial_out === 1'b0) begin
            $display("PASS: serial_out=0 for data=0x02 (LSB=0)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: serial_out should be 0 for data=0x02, got %b", serial_out);
            fail_count = fail_count + 1;
        end

        // --- Test 9: Apply reset mid-operation, verify bit_counter resets and empty asserts ---
        // First do some shifts
        data     = 8'hAB;
        load     = 1;
        @(posedge clk); #1;
        load     = 0;
        shift_en = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        shift_en = 0;
        // Now apply reset
        rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;
        tick;
        if (empty === 1'b1) begin
            $display("PASS: After mid-operation reset, empty re-asserted");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After mid-operation reset, empty should be asserted, got %b", empty);
            fail_count = fail_count + 1;
        end

        // --- Test 10: Max value 0xFF, serial_out = 1 ---
        data     = 8'hFF;
        load     = 1;
        @(posedge clk); #1;
        load     = 0;
        tick;
        if (serial_out === 1'b1) begin
            $display("PASS: serial_out=1 for max data=0xFF");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: serial_out should be 1 for data=0xFF, got %b", serial_out);
            fail_count = fail_count + 1;
        end

        // --- Test 11: Verify empty asserts after reset from shift state ---
        rst = 1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 0;
        data     = 8'h55;
        load     = 1;
        @(posedge clk); #1;
        load     = 0;
        // Shift 8 times
        shift_en = 1;
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge clk); #1;
        end
        shift_en = 0;
        tick;
        // bit_counter should be 8 now, empty = (bit_counter == 0) = 0
        if (empty === 1'b0) begin
            $display("PASS: After 8 shifts, empty is deasserted (bit_counter=8)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After 8 shifts, empty should be deasserted, got %b", empty);
            fail_count = fail_count + 1;
        end

        // --- Test 12: Reload after shifts, empty re-asserts ---
        data     = 8'h3C;
        load     = 1;
        @(posedge clk); #1;
        load     = 0;
        tick;
        if (empty === 1'b1) begin
            $display("PASS: After reload, empty re-asserted");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After reload, empty should be asserted, got %b", empty);
            fail_count = fail_count + 1;
        end

        // Summary
        $display("--- Test Summary: %0d passed, %0d failed ---", pass_count, fail_count);

        $finish;
    end

endmodule
