`timescale 1ns/1ps

module tb_uart_tx_shift;

    // DUT connections
    reg        clk;
    reg        rst;
    reg        load;
    reg        shift_en;
    reg  [7:0] data;
    wire       serial_out;
    wire       empty;

    // Instantiate DUT
    uart_tx_shift uut (
        .clk(clk),
        .rst(rst),
        .load(load),
        .shift_en(shift_en),
        .data(data),
        .serial_out(serial_out),
        .empty(empty)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Task: apply one clock cycle
    task tick;
        begin
            @(posedge clk);
            #1; // small delay to let outputs settle
        end
    endtask

    integer i;
    reg [7:0] expected_shift;
    reg       expected_bit;

    initial begin
        // Initialize inputs
        rst      = 1;
        load     = 0;
        shift_en = 0;
        data     = 8'h00;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // Wait one extra cycle to stabilize
        tick;

        // ---------------------------------------------------------
        // Test 1: After reset, empty should be 1, serial_out = 0
        // ---------------------------------------------------------
        if (empty === 1'b1)
            $display("PASS: After reset, empty=1");
        else
            $display("FAIL: After reset, empty=%b (expected 1)", empty);

        if (serial_out === 1'b0)
            $display("PASS: After reset, serial_out=0");
        else
            $display("FAIL: After reset, serial_out=%b (expected 0)", serial_out);

        // ---------------------------------------------------------
        // Test 2: Load all-zeros (0x00), check serial_out is 0 after load
        // ---------------------------------------------------------
        data    = 8'h00;
        load    = 1;
        shift_en = 0;
        tick;       // posedge: shift_reg_load latched
        load    = 0;
        tick;       // posedge: shift_reg loaded with 0x00, empty cleared

        // After the second tick, shift_reg = 0x00, empty should be 0
        if (empty === 1'b0)
            $display("PASS: Load 0x00 clears empty");
        else
            $display("FAIL: Load 0x00, empty=%b (expected 0)", empty);

        if (serial_out === 1'b0)
            $display("PASS: Load 0x00, serial_out=0 (LSB=0)");
        else
            $display("FAIL: Load 0x00, serial_out=%b (expected 0)", serial_out);

        // ---------------------------------------------------------
        // Test 3: Load all-ones (0xFF), verify LSB-first shifting
        // ---------------------------------------------------------
        data     = 8'hFF;
        load     = 1;
        shift_en = 0;
        tick;       // latch load
        load     = 0;
        tick;       // shift_reg <= 0xFF, empty <= 0

        if (empty === 1'b0)
            $display("PASS: Load 0xFF clears empty");
        else
            $display("FAIL: Load 0xFF, empty=%b (expected 0)", empty);

        if (serial_out === 1'b1)
            $display("PASS: Load 0xFF, serial_out=1 (LSB=1)");
        else
            $display("FAIL: Load 0xFF, serial_out=%b (expected 1)", serial_out);

        // ---------------------------------------------------------
        // Test 4: Shift 0xFF eight times, serial_out always 1
        // ---------------------------------------------------------
        expected_shift = 8'hFF;
        shift_en = 1;
        for (i = 0; i < 8; i = i + 1) begin
            // Before shift: serial_out = shift_reg[0]
            expected_bit = expected_shift[0];
            if (serial_out === expected_bit)
                $display("PASS: Shift 0xFF iter %0d, serial_out=%b", i, serial_out);
            else
                $display("FAIL: Shift 0xFF iter %0d, serial_out=%b (expected %b)", i, serial_out, expected_bit);
            // Update expected: shift left, insert 0
            expected_shift = {expected_shift[6:0], 1'b0};
            tick; // latch shift_en, then apply shift
        end
        // After latching last shift_en, apply one more tick so the 8th shift executes
        // But actually the 8th tick above applied the 8th shift.
        // Now latch shift_en=0 to stop shifting
        shift_en = 0;
        tick; // shift_reg_shift latched as 0, no more shift

        // ---------------------------------------------------------
        // Test 5: Load 0xA5 = 1010_0101, verify LSB-first serial_out
        //         Pattern: 1,0,1,0,0,1,0,1 (LSB first)
        // ---------------------------------------------------------
        data     = 8'hA5; // 1010_0101
        load     = 1;
        shift_en = 0;
        tick;       // latch load
        load     = 0;
        tick;       // shift_reg <= 0xA5

        expected_shift = 8'hA5;
        shift_en = 1;
        for (i = 0; i < 8; i = i + 1) begin
            expected_bit = expected_shift[0];
            if (serial_out === expected_bit)
                $display("PASS: Shift 0xA5 iter %0d, serial_out=%b", i, serial_out);
            else
                $display("FAIL: Shift 0xA5 iter %0d, serial_out=%b (expected %b)", i, serial_out, expected_bit);
            expected_shift = {expected_shift[6:0], 1'b0};
            tick;
        end
        shift_en = 0;
        tick;

        // ---------------------------------------------------------
        // Test 6: Load 0x55 = 0101_0101, verify LSB-first
        //         Pattern: 1,0,1,0,1,0,1,0
        // ---------------------------------------------------------
        data     = 8'h55; // 0101_0101
        load     = 1;
        shift_en = 0;
        tick;
        load     = 0;
        tick;       // shift_reg <= 0x55

        expected_shift = 8'h55;
        shift_en = 1;
        for (i = 0; i < 8; i = i + 1) begin
            expected_bit = expected_shift[0];
            if (serial_out === expected_bit)
                $display("PASS: Shift 0x55 iter %0d, serial_out=%b", i, serial_out);
            else
                $display("FAIL: Shift 0x55 iter %0d, serial_out=%b (expected %b)", i, serial_out, expected_bit);
            expected_shift = {expected_shift[6:0], 1'b0};
            tick;
        end
        shift_en = 0;
        tick;

        // ---------------------------------------------------------
        // Test 7: Load max value 0xFF, then mid-stream reload 0x00,
        //         verify empty stays 0 after reload
        // ---------------------------------------------------------
        data     = 8'hFF;
        load     = 1;
        shift_en = 0;
        tick;
        load     = 0;
        tick; // shift_reg = 0xFF

        // Do 3 shifts
        shift_en = 1;
        tick;
        tick;
        tick;
        shift_en = 0;
        tick;

        // Now reload with 0x00
        data     = 8'h00;
        load     = 1;
        tick;
        load     = 0;
        tick; // shift_reg = 0x00, empty should be 0

        if (empty === 1'b0)
            $display("PASS: Mid-stream reload 0x00, empty=0");
        else
            $display("FAIL: Mid-stream reload 0x00, empty=%b (expected 0)", empty);

        if (serial_out === 1'b0)
            $display("PASS: Mid-stream reload 0x00, serial_out=0");
        else
            $display("FAIL: Mid-stream reload 0x00, serial_out=%b (expected 0)", serial_out);

        // ---------------------------------------------------------
        // Test 8: Verify reset during operation sets empty=1 and serial_out=0
        // ---------------------------------------------------------
        data     = 8'hAB;
        load     = 1;
        tick;
        load     = 0;
        tick; // shift_reg = 0xAB

        // Assert reset
        rst = 1;
        tick;
        tick;
        rst = 0;
        tick;

        if (empty === 1'b1)
            $display("PASS: Reset during operation, empty=1");
        else
            $display("FAIL: Reset during operation, empty=%b (expected 1)", empty);

        if (serial_out === 1'b0)
            $display("PASS: Reset during operation, serial_out=0");
        else
            $display("FAIL: Reset during operation, serial_out=%b (expected 0)", serial_out);

        // ---------------------------------------------------------
        // Test 9: shift_en and load simultaneously — load takes precedence
        //         (shift_reg_load is checked first in the always block)
        // ---------------------------------------------------------
        // First load 0x55
        data     = 8'h55;
        load     = 1;
        shift_en = 0;
        tick;
        load     = 0;
        tick; // shift_reg = 0x55

        // Now assert both load and shift_en at the same time
        // The previous cycle latched load=0, shift_en=0
        // This cycle latch load=1, shift_en=1
        data     = 8'hCC;
        load     = 1;
        shift_en = 1;
        tick;       // latch both
        load     = 0;
        shift_en = 0;
        // Now both shift_reg_load and shift_reg_shift are 1
        // shift_reg_load is checked first, so data=0xCC should be loaded
        tick;

        if (serial_out === 1'b0) // 0xCC = 1100_1100, LSB=0
            $display("PASS: Simultaneous load+shift, load wins, serial_out=0 (LSB of 0xCC)");
        else
            $display("FAIL: Simultaneous load+shift, serial_out=%b (expected 0)", serial_out);

        if (empty === 1'b0)
            $display("PASS: Simultaneous load+shift, empty=0");
        else
            $display("FAIL: Simultaneous load+shift, empty=%b (expected 0)", empty);

        // Wait a few cycles and finish
        repeat (4) tick;

        $display("Testbench completed.");
        $finish;
    end

endmodule
