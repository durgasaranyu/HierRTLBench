`timescale 1ns/1ps

module tb_crc32_lfsr;

    // DUT connections
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

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    integer i;
    integer pass_count;
    integer fail_count;

    // Task: apply one rising edge and wait
    task tick;
        begin
            @(posedge clk);
            #1; // small settling delay
        end
    endtask

    // Task: apply reset for exactly 5 rising edges
    task apply_reset;
        integer k;
        begin
            rst = 1;
            for (k = 0; k < 5; k = k + 1) begin
                @(posedge clk);
            end
            #1;
            rst = 0;
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize inputs
        rst     = 0;
        init    = 0;
        data_in = 0;
        valid   = 0;

        // ---------------------------------------------------------------
        // TEST 1: Reset sets crc_reg to 0
        // ---------------------------------------------------------------
        apply_reset;

        if (crc_reg === 32'h0000_0000) begin
            $display("PASS: After reset, crc_reg = 0x%08h", crc_reg);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After reset, crc_reg = 0x%08h (expected 0x00000000)", crc_reg);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // TEST 2: valid=0, no data — crc_reg should remain 0
        // ---------------------------------------------------------------
        rst     = 0;
        init    = 0;
        data_in = 1;
        valid   = 0;
        tick;
        tick;
        tick;

        if (crc_reg === 32'h0000_0000) begin
            $display("PASS: valid=0, crc_reg unchanged at 0x%08h", crc_reg);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: valid=0, crc_reg changed to 0x%08h (expected 0x00000000)", crc_reg);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // TEST 3: Feed a single '1' bit with valid=1 (crc starts at 0)
        // CRC-32 LFSR with poly 0xEDB88320, starting from 0:
        // input bit = 0 XOR crc[0] = 0 XOR 0 = 0 -> no tap XOR, shift right
        // For data_in=1: feedback = crc[0] XOR data_in = 0 XOR 1 = 1
        // new crc = poly XOR (crc>>1) = 0xEDB88320 XOR 0 = 0xEDB88320
        // ---------------------------------------------------------------
        apply_reset;

        data_in = 1'b1;
        valid   = 1'b1;
        init    = 0;
        tick;
        valid = 0;

        // After 1 bit '1' input into zero CRC:
        // feedback = crc[0] ^ data_in = 0^1 = 1
        // new_crc = 0xEDB88320 ^ (0 >> 1) = 0xEDB88320
        if (crc_reg === 32'hEDB88320) begin
            $display("PASS: After 1 bit '1', crc_reg = 0x%08h", crc_reg);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After 1 bit '1', crc_reg = 0x%08h (expected 0xEDB88320)", crc_reg);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // TEST 4: Feed a single '0' bit with valid=1 (crc starts at 0)
        // feedback = 0^0 = 0, new crc = 0>>1 = 0
        // ---------------------------------------------------------------
        apply_reset;

        data_in = 1'b0;
        valid   = 1'b1;
        init    = 0;
        tick;
        valid = 0;

        if (crc_reg === 32'h0000_0000) begin
            $display("PASS: After 1 bit '0', crc_reg = 0x%08h", crc_reg);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After 1 bit '0', crc_reg = 0x%08h (expected 0x00000000)", crc_reg);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // TEST 5: Feed two '1' bits consecutively
        // After bit1=1: crc = 0xEDB88320
        // After bit2=1: feedback = crc[0]^1 = 0^1 = 1
        //   new_crc = 0xEDB88320 ^ (0xEDB88320>>1) = 0xEDB88320 ^ 0x76DC4190 = 0x9B64C2B0
        // ---------------------------------------------------------------
        apply_reset;

        data_in = 1'b1;
        valid   = 1'b1;
        init    = 0;
        tick;
        // crc should now be 0xEDB88320
        data_in = 1'b1;
        tick;
        valid = 0;

        // 0xEDB88320 ^ 0x76DC4190 = 0x9B64C2B0
        if (crc_reg === 32'h9B64C2B0) begin
            $display("PASS: After 2 bits '1','1', crc_reg = 0x%08h", crc_reg);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After 2 bits '1','1', crc_reg = 0x%08h (expected 0x9B64C2B0)", crc_reg);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // TEST 6: Feed '1' then '0'
        // After bit1=1: crc = 0xEDB88320
        // After bit2=0: feedback = crc[0]^0 = 0^0 = 0 (since EDB88320[0]=0)
        //   new_crc = 0xEDB88320 >> 1 = 0x76DC4190
        // ---------------------------------------------------------------
        apply_reset;

        data_in = 1'b1;
        valid   = 1'b1;
        init    = 0;
        tick;
        data_in = 1'b0;
        tick;
        valid = 0;

        if (crc_reg === 32'h76DC4190) begin
            $display("PASS: After bits '1','0', crc_reg = 0x%08h", crc_reg);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After bits '1','0', crc_reg = 0x%08h (expected 0x76DC4190)", crc_reg);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // TEST 7: init signal asserted — check that crc_reg goes to 0
        // ---------------------------------------------------------------
        // First feed some data to make crc non-zero
        apply_reset;
        data_in = 1'b1;
        valid   = 1'b1;
        tick;
        valid = 0;
        // Now assert init
        init = 1;
        tick;
        init = 0;
        tick;

        if (crc_reg === 32'h0000_0000) begin
            $display("PASS: After init, crc_reg = 0x%08h", crc_reg);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After init, crc_reg = 0x%08h (expected 0x00000000)", crc_reg);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // TEST 8: All-ones sequence — feed 8 '1' bits and verify non-zero
        // (Just verify it's different from reset state, demonstrating computation)
        // ---------------------------------------------------------------
        apply_reset;

        valid   = 1'b1;
        data_in = 1'b1;
        init    = 0;
        for (i = 0; i < 8; i = i + 1) begin
            tick;
        end
        valid = 0;

        if (crc_reg !== 32'h0000_0000) begin
            $display("PASS: After 8 ones, crc_reg = 0x%08h (non-zero)", crc_reg);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After 8 ones, crc_reg = 0x00000000 (unexpectedly zero)", crc_reg);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // TEST 9: All-zeros sequence — crc_reg stays 0 after 8 zero bits
        // ---------------------------------------------------------------
        apply_reset;

        valid   = 1'b1;
        data_in = 1'b0;
        init    = 0;
        for (i = 0; i < 8; i = i + 1) begin
            tick;
        end
        valid = 0;

        if (crc_reg === 32'h0000_0000) begin
            $display("PASS: After 8 zeros, crc_reg = 0x%08h (still zero)", crc_reg);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: After 8 zeros, crc_reg = 0x%08h (expected 0x00000000)", crc_reg);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // TEST 10: Reset mid-operation
        // ---------------------------------------------------------------
        apply_reset;

        data_in = 1'b1;
        valid   = 1'b1;
        tick;
        tick;
        // Now apply reset mid-stream
        rst = 1;
        tick;
        rst = 0;
        #1;

        if (crc_reg === 32'h0000_0000) begin
            $display("PASS: Mid-operation reset, crc_reg = 0x%08h", crc_reg);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Mid-operation reset, crc_reg = 0x%08h (expected 0x00000000)", crc_reg);
            fail_count = fail_count + 1;
        end

        valid = 0;

        // ---------------------------------------------------------------
        // Summary
        // ---------------------------------------------------------------
        $display("-----------------------------------");
        $display("Tests complete: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("-----------------------------------");

        $finish;
    end

endmodule
