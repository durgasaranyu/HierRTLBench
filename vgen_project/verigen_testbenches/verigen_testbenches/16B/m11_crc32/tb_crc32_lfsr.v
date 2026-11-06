`timescale 1ns/1ps

module tb_crc32_lfsr;

    // DUT signals
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

    // Task to apply one rising edge
    task tick;
        begin
            @(posedge clk);
            #1; // small delay after edge for sampling
        end
    endtask

    integer i;
    reg [7:0] byte_val;
    reg [31:0] crc_after_reset;
    reg [31:0] crc_after_init;
    reg [31:0] prev_crc;
    reg [31:0] crc_zero_seq;
    reg [31:0] crc_ones_seq;

    initial begin
        // Initialize inputs
        rst     = 0;
        init    = 0;
        data_in = 0;
        valid   = 0;

        // Assert reset for exactly 5 rising edges
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // -------------------------------------------------------
        // Test 1: After reset, crc_reg should be 0
        // -------------------------------------------------------
        #1;
        if (crc_reg === 32'h0)
            $display("PASS: After reset crc_reg=0");
        else
            $display("FAIL: After reset crc_reg=%h (expected 0)", crc_reg);

        // -------------------------------------------------------
        // Test 2: Assert init for one cycle, crc_reg should remain 0
        // -------------------------------------------------------
        init  = 1;
        valid = 0;
        data_in = 0;
        @(posedge clk); #1;
        init = 0;
        if (crc_reg === 32'h0)
            $display("PASS: After init pulse crc_reg=0");
        else
            $display("FAIL: After init pulse crc_reg=%h (expected 0)", crc_reg);

        // -------------------------------------------------------
        // Test 3: No valid - crc_reg should not change
        // -------------------------------------------------------
        prev_crc = crc_reg;
        valid   = 0;
        data_in = 1;
        repeat (4) @(posedge clk);
        #1;
        if (crc_reg === prev_crc)
            $display("PASS: crc_reg stable when valid=0");
        else
            $display("FAIL: crc_reg changed when valid=0: was %h now %h", prev_crc, crc_reg);

        // -------------------------------------------------------
        // Test 4: Feed single '0' bit with valid=1
        //   CRC32 LFSR: input bit XOR crc[0], if result=1 shift and XOR poly, else just shift
        //   Starting from 0: bit_in=0, xor_bit=0, just shift -> crc stays 0
        // -------------------------------------------------------
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        // one more tick to settle
        @(posedge clk); #1;

        data_in = 0;
        valid   = 1;
        @(posedge clk); #1;
        valid = 0;
        // After feeding bit=0 into crc=0: bit XOR crc[0] = 0 XOR 0 = 0 => shift right, no XOR
        // result should still be 0
        if (crc_reg === 32'h0)
            $display("PASS: Feed bit=0 into crc=0 gives crc=0");
        else
            $display("FAIL: Feed bit=0 into crc=0 gives crc=%h (expected 0)", crc_reg);

        // -------------------------------------------------------
        // Test 5: Feed single '1' bit with valid=1 into crc=0
        //   bit XOR crc[0] = 1 XOR 0 = 1 => shift right then XOR with poly 0xEDB88320
        //   next_crc = (0 >> 1) XOR 0xEDB88320 = 0xEDB88320
        // -------------------------------------------------------
        // Reset first
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        data_in = 1;
        valid   = 1;
        @(posedge clk); #1;
        valid = 0;

        if (crc_reg === 32'hEDB88320)
            $display("PASS: Feed bit=1 into crc=0 gives crc=EDB88320");
        else
            $display("FAIL: Feed bit=1 into crc=0 gives crc=%h (expected EDB88320)", crc_reg);

        // -------------------------------------------------------
        // Test 6: Feed two '1' bits from reset
        //   After first bit=1: crc = 0xEDB88320
        //   Second bit=1: bit XOR crc[0] = 1 XOR 0 = 1 => shift right then XOR poly
        //   0xEDB88320 >> 1 = 0x76DC4190, XOR 0xEDB88320 = 0x76DC4190 ^ 0xEDB88320
        //   = 0x9B4041B0
        // -------------------------------------------------------
        // reset
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        data_in = 1;
        valid   = 1;
        @(posedge clk); #1;
        // second bit
        data_in = 1;
        valid   = 1;
        @(posedge clk); #1;
        valid = 0;

        if (crc_reg === (32'h76DC4190 ^ 32'hEDB88320))
            $display("PASS: Feed two bit=1 gives expected CRC");
        else
            $display("FAIL: Feed two bit=1 gives crc=%h (expected %h)", crc_reg, (32'h76DC4190 ^ 32'hEDB88320));

        // -------------------------------------------------------
        // Test 7: All-zero input sequence (8 bits of 0)
        //   Starting from crc=0, all bits are 0 => crc stays 0
        // -------------------------------------------------------
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        data_in = 0;
        valid   = 1;
        repeat(8) @(posedge clk);
        #1;
        valid = 0;

        if (crc_reg === 32'h0)
            $display("PASS: All-zero 8-bit input gives crc=0");
        else
            $display("FAIL: All-zero 8-bit input gives crc=%h (expected 0)", crc_reg);

        // -------------------------------------------------------
        // Test 8: All-ones sequence - feed 32 bits of 1
        //   Compute expected value using bit-serial LFSR model
        // -------------------------------------------------------
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        begin : ones_seq_test
            reg [31:0] expected_crc;
            integer j;
            expected_crc = 32'h0;
            for (j = 0; j < 32; j = j + 1) begin
                if ((1'b1 ^ expected_crc[0]) == 1'b1)
                    expected_crc = (expected_crc >> 1) ^ 32'hEDB88320;
                else
                    expected_crc = expected_crc >> 1;
            end

            data_in = 1;
            valid   = 1;
            repeat(32) @(posedge clk);
            #1;
            valid = 0;

            if (crc_reg === expected_crc)
                $display("PASS: All-ones 32-bit input gives expected CRC=%h", expected_crc);
            else
                $display("FAIL: All-ones 32-bit input gives crc=%h (expected %h)", crc_reg, expected_crc);
        end

        // -------------------------------------------------------
        // Test 9: Verify init during operation resets crc
        // -------------------------------------------------------
        // Feed some bits first
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        data_in = 1;
        valid   = 1;
        repeat(4) @(posedge clk);
        #1;
        valid = 0;

        // Now assert init to reset crc
        init = 1;
        valid = 0;
        @(posedge clk); #1;
        init = 0;

        if (crc_reg === 32'h0)
            $display("PASS: init during operation resets crc_reg to 0");
        else
            $display("FAIL: init during operation gives crc_reg=%h (expected 0)", crc_reg);

        // -------------------------------------------------------
        // Test 10: Alternating bits 1,0,1,0,1,0,1,0 - compute expected
        // -------------------------------------------------------
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        begin : alt_bits_test
            reg [31:0] expected_crc2;
            reg [7:0] pattern;
            integer k;
            expected_crc2 = 32'h0;
            pattern = 8'b10101010;
            for (k = 7; k >= 0; k = k - 1) begin
                if ((pattern[k] ^ expected_crc2[0]) == 1'b1)
                    expected_crc2 = (expected_crc2 >> 1) ^ 32'hEDB88320;
                else
                    expected_crc2 = expected_crc2 >> 1;
            end

            // Feed alternating bits MSB first: 1,0,1,0,1,0,1,0
            for (k = 7; k >= 0; k = k - 1) begin
                data_in = pattern[k];
                valid   = 1;
                @(posedge clk);
            end
            #1;
            valid = 0;

            if (crc_reg === expected_crc2)
                $display("PASS: Alternating bits 10101010 gives expected CRC=%h", expected_crc2);
            else
                $display("FAIL: Alternating bits gives crc=%h (expected %h)", crc_reg, expected_crc2);
        end

        // -------------------------------------------------------
        // Test 11: Simultaneous rst and valid - rst should dominate
        // -------------------------------------------------------
        // First feed some bits to get non-zero crc
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        data_in = 1;
        valid   = 1;
        repeat(3) @(posedge clk);
        #1;
        valid = 0;

        // Now assert rst with valid simultaneously
        rst     = 1;
        valid   = 1;
        data_in = 1;
        @(posedge clk); #1;

        if (crc_reg === 32'h0)
            $display("PASS: rst dominates valid - crc_reg=0");
        else
            $display("FAIL: rst with valid gives crc_reg=%h (expected 0)", crc_reg);
        rst   = 0;
        valid = 0;

        // -------------------------------------------------------
        // Wait a few extra cycles then finish
        // -------------------------------------------------------
        repeat(5) @(posedge clk);

        $finish;
    end

endmodule
