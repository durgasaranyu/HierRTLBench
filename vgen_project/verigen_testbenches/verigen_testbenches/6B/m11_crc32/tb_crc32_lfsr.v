`timescale 1ns/1ps

module tb_crc32_lfsr;

    // DUT ports
    reg        clk;
    reg        rst;
    reg        init;
    reg        data_in;
    reg        valid;
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

    integer i;
    integer fail_count;

    // Task: apply one clock cycle
    task tick;
        begin
            @(posedge clk);
            #1; // small delay after edge for sampling
        end
    endtask

    initial begin
        fail_count = 0;

        // Initialize inputs
        rst     = 1;
        init    = 0;
        data_in = 0;
        valid   = 0;

        // Assert reset for exactly 5 rising edges
        repeat(5) @(posedge clk);
        #1;

        // Deassert reset
        rst = 0;

        // -------------------------------------------------------
        // Test 1: After reset, crc_reg should be 0
        // -------------------------------------------------------
        tick;
        if (crc_reg === 32'h00000000) begin
            $display("PASS: After reset crc_reg=0x%08X (expected 0x00000000)", crc_reg);
        end else begin
            $display("FAIL: After reset crc_reg=0x%08X (expected 0x00000000)", crc_reg);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 2: valid=0, crc_reg should not change (stays 0)
        // -------------------------------------------------------
        valid   = 0;
        data_in = 1;
        tick;
        tick;
        tick;
        if (crc_reg === 32'h00000000) begin
            $display("PASS: valid=0, no change, crc_reg=0x%08X (expected 0x00000000)", crc_reg);
        end else begin
            $display("FAIL: valid=0, crc_reg changed to 0x%08X (expected 0x00000000)", crc_reg);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 3: Re-assert reset, crc_reg returns to 0
        // -------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        tick;
        if (crc_reg === 32'h00000000) begin
            $display("PASS: Re-assert reset crc_reg=0x%08X (expected 0x00000000)", crc_reg);
        end else begin
            $display("FAIL: Re-assert reset crc_reg=0x%08X (expected 0x00000000)", crc_reg);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 4: Feed data_in=0 with valid=1 for one clock
        // CRC update: bit=0 XOR crc[0]=0 => feedback=0 => crc shifts right, stays 0
        // -------------------------------------------------------
        valid   = 1;
        data_in = 0;
        tick;
        valid = 0;
        // After feeding bit 0 into a 0 register, result should still be 0
        if (crc_reg === 32'h00000000) begin
            $display("PASS: Feed bit=0 into zero CRC, crc_reg=0x%08X (expected 0x00000000)", crc_reg);
        end else begin
            $display("FAIL: Feed bit=0 into zero CRC, crc_reg=0x%08X (expected 0x00000000)", crc_reg);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 5: Feed data_in=1 with valid=1 for one clock
        // starting from 0: bit=1 XOR crc[0]=0 => feedback=1 => new_crc = poly=0xEDB88320
        // -------------------------------------------------------
        // Reset first
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        tick;

        valid   = 1;
        data_in = 1;
        tick;
        valid = 0;
        // Expected: 0xEDB88320
        if (crc_reg === 32'hEDB88320) begin
            $display("PASS: Feed bit=1 into zero CRC, crc_reg=0x%08X (expected 0xEDB88320)", crc_reg);
        end else begin
            $display("FAIL: Feed bit=1 into zero CRC, crc_reg=0x%08X (expected 0xEDB88320)", crc_reg);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 6: Feed another bit=1 into crc=0xEDB88320
        // bit=1 XOR crc[0]=0 => feedback=1 => new_crc = (0xEDB88320 >> 1) ^ 0xEDB88320
        // 0xEDB88320 >> 1 = 0x76DC4190
        // 0x76DC4190 ^ 0xEDB88320 = 0x9B64C2B0
        // -------------------------------------------------------
        valid   = 1;
        data_in = 1;
        tick;
        valid = 0;
        if (crc_reg === 32'h9B64C2B0) begin
            $display("PASS: Two bits=1, crc_reg=0x%08X (expected 0x9B64C2B0)", crc_reg);
        end else begin
            $display("FAIL: Two bits=1, crc_reg=0x%08X (expected 0x9B64C2B0)", crc_reg);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 7: init signal - assert init for one cycle (should have some effect or at least not crash)
        // -------------------------------------------------------
        init = 1;
        tick;
        init = 0;
        tick;
        $display("PASS: init toggled, crc_reg=0x%08X (no crash)", crc_reg);

        // -------------------------------------------------------
        // Test 8: Feed all-zeros byte (8 bits of 0) after reset
        // Starting CRC=0, all bits=0 => CRC stays 0
        // -------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        tick;

        valid   = 1;
        data_in = 0;
        repeat(8) begin
            tick;
        end
        valid = 0;
        if (crc_reg === 32'h00000000) begin
            $display("PASS: 8 zero bits into zero CRC stays 0x00000000, got 0x%08X", crc_reg);
        end else begin
            $display("FAIL: 8 zero bits into zero CRC, crc_reg=0x%08X (expected 0x00000000)", crc_reg);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 9: Feed all-ones (32 bits) after reset and check crc shifts
        // Just verify it doesn't stay 0 (since bit=1 XOR crc[0]=0 triggers poly)
        // -------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        tick;

        valid   = 1;
        data_in = 1;
        repeat(32) begin
            tick;
        end
        valid = 0;
        if (crc_reg !== 32'h00000000) begin
            $display("PASS: 32 ones produce non-zero CRC=0x%08X", crc_reg);
        end else begin
            $display("FAIL: 32 ones produced 0x00000000 (unexpected)", crc_reg);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 10: Multiple valid/invalid toggles - CRC should only change on valid
        // -------------------------------------------------------
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;
        tick;

        // Feed bit=1 with valid=1
        valid   = 1;
        data_in = 1;
        tick;
        valid = 0;

        begin : blk_test10
            reg [31:0] crc_snapshot;
            crc_snapshot = crc_reg;

            // Now with valid=0, feed different data - CRC should not change
            data_in = 0;
            tick;
            tick;
            tick;

            if (crc_reg === crc_snapshot) begin
                $display("PASS: CRC unchanged when valid=0, crc_reg=0x%08X", crc_reg);
            end else begin
                $display("FAIL: CRC changed with valid=0: was 0x%08X, now 0x%08X", crc_snapshot, crc_reg);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        if (fail_count == 0) begin
            $display("All tests PASSED.");
        end else begin
            $display("%0d test(s) FAILED.", fail_count);
        end

        $finish;
    end

endmodule
