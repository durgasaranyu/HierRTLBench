`timescale 1ns/1ps

module tb_crc32_lfsr;

    // DUT ports
    reg         clk;
    reg         rst;
    reg         init;
    reg         data_in;
    reg         valid;
    wire [31:0] crc_reg;

    // Instantiate DUT
    crc32_lfsr uut (
        .clk     (clk),
        .rst     (rst),
        .init    (init),
        .data_in (data_in),
        .valid   (valid),
        .crc_reg (crc_reg)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Task: apply one rising-edge clock
    task tick;
        begin
            @(posedge clk);
            #1; // small delay after edge for output sampling
        end
    endtask

    integer i;
    reg [31:0] expected_crc;
    reg [7:0]  byte_val;
    reg        bit_val;

    // Reference CRC-32 LFSR function (reflected poly 0xEDB88320)
    // Process one bit at a time
    function [31:0] crc32_bit;
        input [31:0] crc_in_f;
        input        din;
        reg feedback;
        reg [31:0] crc_next;
        begin
            feedback  = crc_in_f[0] ^ din;
            crc_next  = crc_in_f >> 1;
            if (feedback) begin
                crc_next = crc_next ^ 32'hEDB88320;
            end
            crc32_bit = crc_next;
        end
    endfunction

    initial begin
        // Initialise
        rst      = 0;
        init     = 0;
        data_in  = 0;
        valid    = 0;

        // -------------------------------------------------------
        // TEST 1: Assert synchronous reset for 5 rising edges
        // -------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        if (crc_reg === 32'h0)
            $display("PASS: reset sets crc_reg to 0");
        else
            $display("FAIL: reset sets crc_reg to 0 (got %h)", crc_reg);

        // Deassert reset
        @(negedge clk);
        rst = 0;

        // -------------------------------------------------------
        // TEST 2: After reset deasserted, no valid – state stays 0
        // -------------------------------------------------------
        valid   = 0;
        data_in = 0;
        tick;
        tick;
        if (crc_reg === 32'h0)
            $display("PASS: crc_reg stays 0 when valid=0 after reset");
        else
            $display("FAIL: crc_reg should stay 0 when valid=0 (got %h)", crc_reg);

        // -------------------------------------------------------
        // TEST 3: Feed a single '0' bit with valid=1
        //         Expected: crc32_bit(0, 0) = 0 >> 1 = 0 (no feedback)
        // -------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        @(negedge clk);
        rst = 0;

        expected_crc = 32'h0;
        data_in = 0;
        valid   = 1;
        @(posedge clk); #1;
        valid = 0;
        expected_crc = crc32_bit(32'h0, 1'b0);
        if (crc_reg === expected_crc)
            $display("PASS: single '0' bit (crc_reg=%h)", crc_reg);
        else
            $display("FAIL: single '0' bit (got %h, expected %h)", crc_reg, expected_crc);

        // -------------------------------------------------------
        // TEST 4: Feed a single '1' bit starting from 0
        //         Expected: crc32_bit(0, 1) = 0xEDB88320
        // -------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        @(negedge clk);
        rst = 0;

        data_in = 1;
        valid   = 1;
        @(posedge clk); #1;
        valid = 0;
        expected_crc = crc32_bit(32'h0, 1'b1);
        if (crc_reg === expected_crc)
            $display("PASS: single '1' bit (crc_reg=%h, expected %h)", crc_reg, expected_crc);
        else
            $display("FAIL: single '1' bit (got %h, expected %h)", crc_reg, expected_crc);

        // -------------------------------------------------------
        // TEST 5: Feed 8 bits of 0x41 ('A'), LSB first
        //         Verify state after each bit matches reference
        // -------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        @(negedge clk);
        rst = 0;

        expected_crc = 32'h0;
        byte_val     = 8'h41;
        valid        = 1;
        for (i = 0; i < 8; i = i + 1) begin
            bit_val      = byte_val[i];
            data_in      = bit_val;
            expected_crc = crc32_bit(expected_crc, bit_val);
            @(posedge clk); #1;
        end
        valid = 0;
        if (crc_reg === expected_crc)
            $display("PASS: 8 bits of 'A' (0x41) processed correctly (crc_reg=%h)", crc_reg);
        else
            $display("FAIL: 8 bits of 'A' (got %h, expected %h)", crc_reg, expected_crc);

        // -------------------------------------------------------
        // TEST 6: All-zero byte (0x00) – 8 bits of 0
        // -------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        @(negedge clk);
        rst = 0;

        expected_crc = 32'h0;
        byte_val     = 8'h00;
        valid        = 1;
        for (i = 0; i < 8; i = i + 1) begin
            bit_val      = byte_val[i];
            data_in      = bit_val;
            expected_crc = crc32_bit(expected_crc, bit_val);
            @(posedge clk); #1;
        end
        valid = 0;
        if (crc_reg === expected_crc)
            $display("PASS: 8 bits of all-zero byte (crc_reg=%h)", crc_reg);
        else
            $display("FAIL: all-zero byte (got %h, expected %h)", crc_reg, expected_crc);

        // -------------------------------------------------------
        // TEST 7: All-ones byte (0xFF) – 8 bits of 1
        // -------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        @(negedge clk);
        rst = 0;

        expected_crc = 32'h0;
        byte_val     = 8'hFF;
        valid        = 1;
        for (i = 0; i < 8; i = i + 1) begin
            bit_val      = byte_val[i];
            data_in      = bit_val;
            expected_crc = crc32_bit(expected_crc, bit_val);
            @(posedge clk); #1;
        end
        valid = 0;
        if (crc_reg === expected_crc)
            $display("PASS: 8 bits of all-ones byte (crc_reg=%h)", crc_reg);
        else
            $display("FAIL: all-ones byte (got %h, expected %h)", crc_reg, expected_crc);

        // -------------------------------------------------------
        // TEST 8: valid toggling – only advances on valid=1
        // -------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        @(negedge clk);
        rst = 0;

        // Feed bit=1 with valid=1
        data_in = 1;
        valid   = 1;
        @(posedge clk); #1;
        valid   = 0;
        // Now hold for 3 cycles – state must not change
        begin : hold_check
            reg [31:0] snap;
            snap = crc_reg;
            @(posedge clk); #1;
            @(posedge clk); #1;
            @(posedge clk); #1;
            if (crc_reg === snap)
                $display("PASS: crc_reg unchanged during valid=0 hold");
            else
                $display("FAIL: crc_reg changed during valid=0 hold (was %h, now %h)", snap, crc_reg);
        end

        // -------------------------------------------------------
        // TEST 9: init signal resets crc_reg to 0 mid-stream
        // -------------------------------------------------------
        // State is currently non-zero; assert init for one cycle
        data_in = 0;
        valid   = 0;
        init    = 1;
        @(posedge clk); #1;
        init = 0;
        if (crc_reg === 32'h0)
            $display("PASS: init resets crc_reg to 0");
        else
            $display("FAIL: init should reset crc_reg to 0 (got %h)", crc_reg);

        // -------------------------------------------------------
        // TEST 10: Multi-byte sequence – 'A','B' (0x41, 0x42), check consistency
        // -------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        @(negedge clk);
        rst = 0;

        expected_crc = 32'h0;
        valid        = 1;
        // Byte 'A' = 0x41
        byte_val = 8'h41;
        for (i = 0; i < 8; i = i + 1) begin
            bit_val      = byte_val[i];
            data_in      = bit_val;
            expected_crc = crc32_bit(expected_crc, bit_val);
            @(posedge clk); #1;
        end
        // Byte 'B' = 0x42
        byte_val = 8'h42;
        for (i = 0; i < 8; i = i + 1) begin
            bit_val      = byte_val[i];
            data_in      = bit_val;
            expected_crc = crc32_bit(expected_crc, bit_val);
            @(posedge clk); #1;
        end
        valid = 0;
        if (crc_reg === expected_crc)
            $display("PASS: two-byte sequence 'AB' (crc_reg=%h)", crc_reg);
        else
            $display("FAIL: two-byte sequence 'AB' (got %h, expected %h)", crc_reg, expected_crc);

        // -------------------------------------------------------
        // Wrap up
        // -------------------------------------------------------
        #20;
        $finish;
    end

endmodule
