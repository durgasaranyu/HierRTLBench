`timescale 1ns/1ps

module tb_m11_crc32_integration;

    // DUT connections
    reg         clk;
    reg         rst;
    reg         start;
    reg         data_in;
    reg         valid;
    wire [31:0] crc_out;
    wire        ready;

    // Instantiate DUT
    crc32 uut (
        .clk     (clk),
        .rst     (rst),
        .start   (start),
        .data_in (data_in),
        .valid   (valid),
        .crc_out (crc_out),
        .ready   (ready)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // CRC-32 IEEE 802.3 reference calculation (software model)
    // reflected poly 0xEDB88320, init=0xFFFFFFFF, final XOR=0xFFFFFFFF
    function [31:0] crc32_byte;
        input [7:0] byte_in;
        input [31:0] crc_in;
        integer i;
        reg [31:0] crc;
        reg        b;
        begin
            crc = crc_in;
            for (i = 0; i < 8; i = i + 1) begin
                b = crc[0] ^ byte_in[i];
                crc = crc >> 1;
                if (b)
                    crc = crc ^ 32'hEDB88320;
            end
            crc32_byte = crc;
        end
    endfunction

    // Variables
    integer     i;
    integer     timeout;
    reg [31:0]  expected_crc;
    reg [7:0]   test_byte;
    reg         test_passed;

    initial begin
        // Initialize signals
        rst     = 1;
        start   = 0;
        data_in = 0;
        valid   = 0;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;

        // ----------------------------------------------------------------
        // TEST 1: Feed 0x41 ('A') bit-serially (LSB first), verify CRC-32
        // ----------------------------------------------------------------
        test_byte    = 8'h41;
        // CRC-32 of single byte 'A' (0x41):
        // init=0xFFFFFFFF, process 0x41, final XOR 0xFFFFFFFF
        expected_crc = crc32_byte(test_byte, 32'hFFFFFFFF) ^ 32'hFFFFFFFF;

        $display("Expected CRC-32 for byte 0x41: 0x%08X", expected_crc);

        // Wait a couple of cycles after reset
        @(negedge clk);
        @(negedge clk);

        // Assert start for one cycle
        start = 1;
        valid = 0;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        // Feed 8 bits, LSB first
        for (i = 0; i < 8; i = i + 1) begin
            data_in = test_byte[i];
            valid   = 1;
            @(posedge clk);
            @(negedge clk);
        end
        valid   = 0;
        data_in = 0;

        // Wait for ready with timeout
        timeout = 0;
        test_passed = 0;
        while (timeout < 200) begin
            @(posedge clk);
            if (ready) begin
                // Sample crc_out
                #1; // small delay to allow output to settle
                if (crc_out === expected_crc) begin
                    $display("PASS: CRC-32 of 0x41 = 0x%08X (expected 0x%08X)", crc_out, expected_crc);
                end else begin
                    $display("FAIL: CRC-32 of 0x41 = 0x%08X (expected 0x%08X)", crc_out, expected_crc);
                end
                test_passed = 1;
                timeout = 200; // break
            end
            timeout = timeout + 1;
        end

        if (!test_passed) begin
            $display("FAIL: ready never asserted for byte 0x41 within timeout");
        end

        // Wait a few cycles
        repeat (5) @(posedge clk);

        // ----------------------------------------------------------------
        // TEST 2: Reset and feed 0x00, verify known CRC
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;
        @(negedge clk);
        @(negedge clk);

        test_byte    = 8'h00;
        expected_crc = crc32_byte(test_byte, 32'hFFFFFFFF) ^ 32'hFFFFFFFF;

        $display("Expected CRC-32 for byte 0x00: 0x%08X", expected_crc);

        start = 1;
        valid = 0;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        for (i = 0; i < 8; i = i + 1) begin
            data_in = test_byte[i];
            valid   = 1;
            @(posedge clk);
            @(negedge clk);
        end
        valid   = 0;
        data_in = 0;

        timeout     = 0;
        test_passed = 0;
        while (timeout < 200) begin
            @(posedge clk);
            if (ready) begin
                #1;
                if (crc_out === expected_crc) begin
                    $display("PASS: CRC-32 of 0x00 = 0x%08X (expected 0x%08X)", crc_out, expected_crc);
                end else begin
                    $display("FAIL: CRC-32 of 0x00 = 0x%08X (expected 0x%08X)", crc_out, expected_crc);
                end
                test_passed = 1;
                timeout = 200;
            end
            timeout = timeout + 1;
        end

        if (!test_passed) begin
            $display("FAIL: ready never asserted for byte 0x00 within timeout");
        end

        repeat (5) @(posedge clk);

        // ----------------------------------------------------------------
        // TEST 3: Reset and feed 0xFF
        // ----------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;
        @(negedge clk);
        @(negedge clk);

        test_byte    = 8'hFF;
        expected_crc = crc32_byte(test_byte, 32'hFFFFFFFF) ^ 32'hFFFFFFFF;

        $display("Expected CRC-32 for byte 0xFF: 0x%08X", expected_crc);

        start = 1;
        valid = 0;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        for (i = 0; i < 8; i = i + 1) begin
            data_in = test_byte[i];
            valid   = 1;
            @(posedge clk);
            @(negedge clk);
        end
        valid   = 0;
        data_in = 0;

        timeout     = 0;
        test_passed = 0;
        while (timeout < 200) begin
            @(posedge clk);
            if (ready) begin
                #1;
                if (crc_out === expected_crc) begin
                    $display("PASS: CRC-32 of 0xFF = 0x%08X (expected 0x%08X)", crc_out, expected_crc);
                end else begin
                    $display("FAIL: CRC-32 of 0xFF = 0x%08X (expected 0x%08X)", crc_out, expected_crc);
                end
                test_passed = 1;
                timeout = 200;
            end
            timeout = timeout + 1;
        end

        if (!test_passed) begin
            $display("FAIL: ready never asserted for byte 0xFF within timeout");
        end

        repeat (10) @(posedge clk);
        $finish;
    end

endmodule
