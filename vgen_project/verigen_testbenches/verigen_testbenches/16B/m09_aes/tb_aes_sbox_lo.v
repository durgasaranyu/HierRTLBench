`timescale 1ns/1ps

module tb_aes_sbox_lo;

    // DUT connections
    reg  [7:0] in;
    wire [7:0] out;

    // Instantiate DUT
    aes_sbox_lo uut (
        .in  (in),
        .out (out)
    );

    // Clock (not strictly needed for combinational, but required by rules)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset signal (not used by DUT, but required by rules)
    reg rst;

    integer fail_count;

    // Task to check a single sbox entry
    task check_sbox;
        input [7:0] test_in;
        input [7:0] expected;
        input [63:0] desc_val; // use a number to identify
        begin
            in = test_in;
            #2; // small combinational delay
            if (out === expected) begin
                $display("PASS: sbox[8'h%02x] = 8'h%02x (expected 8'h%02x)", test_in, out, expected);
            end else begin
                $display("FAIL: sbox[8'h%02x] = 8'h%02x (expected 8'h%02x)", test_in, out, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        fail_count = 0;
        rst = 1;
        in  = 8'h00;

        // Assert reset for 5 rising edges
        repeat (5) @(posedge clk);
        rst = 0;

        // Wait a bit after reset
        @(posedge clk);
        #1;

        // -----------------------------------------------------------
        // Test vector 1: sbox[0x00] = 0x63 (standard AES spec)
        // -----------------------------------------------------------
        check_sbox(8'h00, 8'h63, 1);

        // -----------------------------------------------------------
        // Test vector 2: sbox[0x01] = 0x7c
        // -----------------------------------------------------------
        check_sbox(8'h01, 8'h7c, 2);

        // -----------------------------------------------------------
        // Test vector 3: sbox[0x53] = 0xed
        // -----------------------------------------------------------
        check_sbox(8'h53, 8'hed, 3);

        // -----------------------------------------------------------
        // Test vector 4: sbox[0x7f] = 0xd2 (last entry in lower half)
        // -----------------------------------------------------------
        check_sbox(8'h7f, 8'hd2, 4);

        // -----------------------------------------------------------
        // Test vector 5: sbox[0x0f] = 0x76
        // -----------------------------------------------------------
        check_sbox(8'h0f, 8'h76, 5);

        // -----------------------------------------------------------
        // Test vector 6: sbox[0x50] = 0x53
        // -----------------------------------------------------------
        check_sbox(8'h50, 8'h53, 6);

        // -----------------------------------------------------------
        // Test vector 7: sbox[0x52] = 0x00 (output is all zeros)
        // -----------------------------------------------------------
        check_sbox(8'h52, 8'h00, 7);

        // -----------------------------------------------------------
        // Test vector 8: sbox[0x7d] = 0xff (output is all ones)
        // -----------------------------------------------------------
        check_sbox(8'h7d, 8'hff, 8);

        // -----------------------------------------------------------
        // Test vector 9: sbox[0x10] = 0xca
        // -----------------------------------------------------------
        check_sbox(8'h10, 8'hca, 9);

        // -----------------------------------------------------------
        // Test vector 10: sbox[0x63] = 0xfb
        // -----------------------------------------------------------
        check_sbox(8'h63, 8'hfb, 10);

        // -----------------------------------------------------------
        // Test vector 11: sbox[0x40] = 0x09
        // -----------------------------------------------------------
        check_sbox(8'h40, 8'h09, 11);

        // -----------------------------------------------------------
        // Test vector 12: sbox[0x20] = 0xb7
        // -----------------------------------------------------------
        check_sbox(8'h20, 8'hb7, 12);

        // -----------------------------------------------------------
        // Summary
        // -----------------------------------------------------------
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TOTAL FAILURES: %0d", fail_count);

        $finish;
    end

endmodule
