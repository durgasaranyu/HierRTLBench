`timescale 1ns/1ps

module tb_m11_crc32_integration;

    // DUT port declarations
    reg        clk;
    reg        rst;
    reg        start;
    reg        data_in;
    reg        valid;
    wire [31:0] crc_out;
    wire        ready;

    // Instantiate the DUT
    crc32 uut (
        .clk     (clk),
        .rst     (rst),
        .start   (start),
        .data_in (data_in),
        .valid   (valid),
        .crc_out (crc_out),
        .ready   (ready)
    );

    // Clock generation: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Task: wait for rising edge
    task wait_clk;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    // Reference CRC-32 computation (software model)
    // IEEE 802.3, poly 0xEDB88320, init 0xFFFFFFFF, final XOR 0xFFFFFFFF
    function [31:0] compute_crc32;
        input [7:0] byte_in;
        integer     i;
        reg [31:0]  crc;
        reg         feedback;
        begin
            crc = 32'hFFFFFFFF;
            for (i = 0; i < 8; i = i + 1) begin
                feedback = crc[0] ^ byte_in[i];
                crc = crc >> 1;
                if (feedback)
                    crc = crc ^ 32'hEDB88320;
            end
            compute_crc32 = crc ^ 32'hFFFFFFFF;
        end
    endfunction

    integer    bit_idx;
    integer    timeout;
    reg [31:0] expected_crc;
    reg [7:0]  test_byte;

    initial begin
        // Initialise
        rst     = 1;
        start   = 0;
        data_in = 0;
        valid   = 0;

        // Assert synchronous reset for exactly 5 rising edges
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;

        // Deassert reset
        rst = 0;
        @(posedge clk); #1;

        // ------------------------------------------------------------------
        // Test 1: Feed 0x41 ('A') LSB-first and verify CRC-32
        // ------------------------------------------------------------------
        test_byte    = 8'h41;
        expected_crc = compute_crc32(test_byte);

        // Assert start for one cycle
        start = 1;
        valid = 0;
        @(posedge clk); #1;
        start = 0;

        // Feed 8 bits, LSB first, one bit per clock
        for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
            data_in = test_byte[bit_idx];
            valid   = 1;
            @(posedge clk); #1;
        end
        valid   = 0;
        data_in = 0;

        // Wait for ready, with timeout
        timeout = 0;
        while (!ready && timeout < 200) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (timeout >= 200) begin
            $display("FAIL: Test1 - ready never asserted for byte 0x41");
        end else if (crc_out === expected_crc) begin
            $display("PASS: Test1 - CRC-32 of 0x41 ('A') = 0x%08h", crc_out);
        end else begin
            $display("FAIL: Test1 - CRC-32 of 0x41 ('A'): got 0x%08h, expected 0x%08h",
                     crc_out, expected_crc);
        end

        // ------------------------------------------------------------------
        // Test 2: Reset again and feed 0x00, verify result
        // ------------------------------------------------------------------
        rst   = 1;
        start = 0;
        valid = 0;
        data_in = 0;
        repeat(5) @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        test_byte    = 8'h00;
        expected_crc = compute_crc32(test_byte);

        start = 1;
        valid = 0;
        @(posedge clk); #1;
        start = 0;

        for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
            data_in = test_byte[bit_idx];
            valid   = 1;
            @(posedge clk); #1;
        end
        valid   = 0;
        data_in = 0;

        timeout = 0;
        while (!ready && timeout < 200) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (timeout >= 200) begin
            $display("FAIL: Test2 - ready never asserted for byte 0x00");
        end else if (crc_out === expected_crc) begin
            $display("PASS: Test2 - CRC-32 of 0x00 = 0x%08h", crc_out);
        end else begin
            $display("FAIL: Test2 - CRC-32 of 0x00: got 0x%08h, expected 0x%08h",
                     crc_out, expected_crc);
        end

        // ------------------------------------------------------------------
        // Test 3: Reset again and feed 0xFF, verify result
        // ------------------------------------------------------------------
        rst   = 1;
        start = 0;
        valid = 0;
        data_in = 0;
        repeat(5) @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        test_byte    = 8'hFF;
        expected_crc = compute_crc32(test_byte);

        start = 1;
        valid = 0;
        @(posedge clk); #1;
        start = 0;

        for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
            data_in = test_byte[bit_idx];
            valid   = 1;
            @(posedge clk); #1;
        end
        valid   = 0;
        data_in = 0;

        timeout = 0;
        while (!ready && timeout < 200) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (timeout >= 200) begin
            $display("FAIL: Test3 - ready never asserted for byte 0xFF");
        end else if (crc_out === expected_crc) begin
            $display("PASS: Test3 - CRC-32 of 0xFF = 0x%08h", crc_out);
        end else begin
            $display("FAIL: Test3 - CRC-32 of 0xFF: got 0x%08h, expected 0x%08h",
                     crc_out, expected_crc);
        end

        // ------------------------------------------------------------------
        // Test 4: Reset again and feed 0x55, verify result
        // ------------------------------------------------------------------
        rst   = 1;
        start = 0;
        valid = 0;
        data_in = 0;
        repeat(5) @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        test_byte    = 8'h55;
        expected_crc = compute_crc32(test_byte);

        start = 1;
        valid = 0;
        @(posedge clk); #1;
        start = 0;

        for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
            data_in = test_byte[bit_idx];
            valid   = 1;
            @(posedge clk); #1;
        end
        valid   = 0;
        data_in = 0;

        timeout = 0;
        while (!ready && timeout < 200) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end

        if (timeout >= 200) begin
            $display("FAIL: Test4 - ready never asserted for byte 0x55");
        end else if (crc_out === expected_crc) begin
            $display("PASS: Test4 - CRC-32 of 0x55 = 0x%08h", crc_out);
        end else begin
            $display("FAIL: Test4 - CRC-32 of 0x55: got 0x%08h, expected 0x%08h",
                     crc_out, expected_crc);
        end

        // Small pause then finish
        repeat(10) @(posedge clk);
        $finish;
    end

endmodule
