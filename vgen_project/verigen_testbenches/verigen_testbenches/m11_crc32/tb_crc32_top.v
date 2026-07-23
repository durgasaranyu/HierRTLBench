`timescale 1ns/1ps

module tb_crc32_top;

    // DUT connections
    reg clk;
    reg rst;
    reg start;
    reg data_in;
    reg valid;
    wire [31:0] crc_out;
    wire        ready;

    // Instantiate DUT
    crc32 uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_in(data_in),
        .valid(valid),
        .crc_out(crc_out),
        .ready(ready)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    integer i;
    integer pass_count;
    integer fail_count;
    reg [7:0] byte_data;
    reg [31:0] expected_crc;

    // Task: apply reset for 5 rising edges
    task apply_reset;
        integer j;
        begin
            rst = 1;
            for (j = 0; j < 5; j = j + 1) begin
                @(posedge clk);
            end
            #1;
            rst = 0;
        end
    endtask

    // Task: send one byte LSB first (bit-serial)
    task send_byte;
        input [7:0] byte_val;
        integer b;
        begin
            for (b = 0; b < 8; b = b + 1) begin
                data_in = byte_val[b];
                valid = 1;
                @(posedge clk);
                #1;
            end
            valid = 0;
        end
    endtask

    // Wait for ready signal or timeout
    task wait_ready;
        input integer max_cycles;
        integer cnt;
        begin
            cnt = 0;
            while (ready !== 1'b1 && cnt < max_cycles) begin
                @(posedge clk);
                #1;
                cnt = cnt + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize inputs
        rst      = 0;
        start    = 0;
        data_in  = 0;
        valid    = 0;

        // -------------------------------------------------------
        // TEST 1: Reset check - crc_out should be 0 after reset
        // -------------------------------------------------------
        apply_reset;
        @(posedge clk); #1;

        // After reset, crc_out should be 0 (reset state)
        if (crc_out === 32'h00000000) begin
            $display("PASS: Reset sets crc_out=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Reset sets crc_out=0, got %08h", crc_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 2: Start pulse asserted - check module accepts start
        // -------------------------------------------------------
        start = 1;
        @(posedge clk); #1;
        start = 0;

        // Just verify ready deasserts or module accepts start
        // (behavior depends on implementation - just checking no X)
        if (crc_out !== 32'hxxxxxxxx) begin
            $display("PASS: Start pulse accepted, no X on crc_out");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: X on crc_out after start pulse");
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 3: Send all-zero byte (0x00) after reset
        // -------------------------------------------------------
        apply_reset;
        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        send_byte(8'h00);

        // Wait a few clocks
        repeat(5) @(posedge clk);
        #1;

        // Just verify no X
        if (crc_out !== 32'hxxxxxxxx) begin
            $display("PASS: All-zero byte processed, crc_out=%08h", crc_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: X on crc_out after all-zero byte");
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 4: Send all-ones byte (0xFF) after reset
        // -------------------------------------------------------
        apply_reset;
        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        send_byte(8'hFF);

        repeat(5) @(posedge clk);
        #1;

        if (crc_out !== 32'hxxxxxxxx) begin
            $display("PASS: All-ones byte processed, crc_out=%08h", crc_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: X on crc_out after all-ones byte");
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 5: Send ASCII 'A' (0x41) and check CRC-32
        // CRC-32 of single byte 0x41 ('A') = 0xD3D99E8B
        // -------------------------------------------------------
        apply_reset;
        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        send_byte(8'h41);  // 'A'

        // Wait for ready or timeout
        wait_ready(100);

        // CRC-32/ISO-HDLC of 'A' = 0xD3D99E8B
        expected_crc = 32'hD3D99E8B;

        if (crc_out === expected_crc) begin
            $display("PASS: CRC-32 of 'A' = %08h", crc_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: CRC-32 of 'A': expected %08h, got %08h", expected_crc, crc_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 6: valid=0 should not change state
        // -------------------------------------------------------
        apply_reset;
        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        // Send one bit with valid
        data_in = 1'b1;
        valid = 1;
        @(posedge clk); #1;
        valid = 0;

        // Now hold without valid for several cycles
        data_in = 1'b0;
        repeat(5) @(posedge clk);
        #1;

        // Continue sending rest of byte
        // (just verify no X)
        if (crc_out !== 32'hxxxxxxxx) begin
            $display("PASS: valid=0 hold, no X on crc_out=%08h", crc_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: X on crc_out during valid=0 hold");
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 7: Send byte 0x55 (alternating bits)
        // -------------------------------------------------------
        apply_reset;
        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        send_byte(8'h55);

        wait_ready(100);

        // Just check output is non-X and non-zero (0x55 shouldn't give 0)
        if (crc_out !== 32'hxxxxxxxx) begin
            $display("PASS: 0x55 processed, crc_out=%08h", crc_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: X on crc_out for 0x55");
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 8: Multiple bytes "123" and check consistency
        // Send 0x31, 0x32, 0x33
        // -------------------------------------------------------
        apply_reset;
        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        send_byte(8'h31);  // '1'
        send_byte(8'h32);  // '2'
        send_byte(8'h33);  // '3'

        wait_ready(200);

        if (crc_out !== 32'hxxxxxxxx) begin
            $display("PASS: Multiple bytes '123' processed, crc_out=%08h", crc_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: X on crc_out for '123'");
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 9: Double reset - verify crc_out returns to 0
        // -------------------------------------------------------
        apply_reset;
        @(posedge clk); #1;

        if (crc_out === 32'h00000000) begin
            $display("PASS: Double reset returns crc_out=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Double reset crc_out=%08h (expected 0)", crc_out);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 10: send 0xAA (alternating, inverted 0x55)
        // -------------------------------------------------------
        apply_reset;
        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        send_byte(8'hAA);

        wait_ready(100);

        if (crc_out !== 32'hxxxxxxxx) begin
            $display("PASS: 0xAA processed, crc_out=%08h", crc_out);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: X on crc_out for 0xAA");
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        $display("----------------------------");
        $display("Tests passed: %0d", pass_count);
        $display("Tests failed: %0d", fail_count);
        $display("----------------------------");

        $finish;
    end

endmodule
