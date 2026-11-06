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

    // Clock (not strictly needed for combinational, but required by testbench rules)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset signal (not used by DUT but required)
    reg rst;
    integer i;

    // Task to check expected output
    task check;
        input [7:0] test_in;
        input [7:0] expected;
        input [63:0] desc_val; // just carry in val for display
        begin
            in = test_in;
            #1; // allow combinational to settle
            if (out === expected)
                $display("PASS: sbox[8'h%02h] = 8'h%02h (expected 8'h%02h)", test_in, out, expected);
            else
                $display("FAIL: sbox[8'h%02h] = 8'h%02h (expected 8'h%02h)", test_in, out, expected);
        end
    endtask

    initial begin
        // Assert reset for 5 rising edges
        rst = 1;
        in  = 8'h00;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // ------------------------------------------------------------------
        // Test vector 1: sbox[0x00] = 0x63 (specified requirement)
        // ------------------------------------------------------------------
        check(8'h00, 8'h63, 0);

        // ------------------------------------------------------------------
        // Test vector 2: sbox[0x53] = 0xed (specified requirement)
        // ------------------------------------------------------------------
        check(8'h53, 8'hed, 0);

        // ------------------------------------------------------------------
        // Test vector 3: sbox[0x01] = 0x7c (typical low value)
        // ------------------------------------------------------------------
        check(8'h01, 8'h7c, 0);

        // ------------------------------------------------------------------
        // Test vector 4: sbox[0x0f] = 0x76 (edge of first nibble group)
        // ------------------------------------------------------------------
        check(8'h0f, 8'h76, 0);

        // ------------------------------------------------------------------
        // Test vector 5: sbox[0x52] = 0x00 (output is zero - edge case)
        // ------------------------------------------------------------------
        check(8'h52, 8'h00, 0);

        // ------------------------------------------------------------------
        // Test vector 6: sbox[0x7f] = 0xd2 (maximum lower-half index)
        // ------------------------------------------------------------------
        check(8'h7f, 8'hd2, 0);

        // ------------------------------------------------------------------
        // Test vector 7: sbox[0x7d] = 0xff (output all-ones - edge case)
        // ------------------------------------------------------------------
        check(8'h7d, 8'hff, 0);

        // ------------------------------------------------------------------
        // Test vector 8: sbox[0x63] = 0xfb (middle of lower half)
        // ------------------------------------------------------------------
        check(8'h63, 8'hfb, 0);

        // ------------------------------------------------------------------
        // Test vector 9: sbox[0x50] = 0x53 (known value)
        // ------------------------------------------------------------------
        check(8'h50, 8'h53, 0);

        // ------------------------------------------------------------------
        // Test vector 10: sbox[0x1f] = 0xc0 (near boundary of first quarter)
        // ------------------------------------------------------------------
        check(8'h1f, 8'hc0, 0);

        // ------------------------------------------------------------------
        // Test vector 11: sbox[0x40] = 0x09
        // ------------------------------------------------------------------
        check(8'h40, 8'h09, 0);

        // ------------------------------------------------------------------
        // Test vector 12: sbox[0x6a] = 0x02
        // ------------------------------------------------------------------
        check(8'h6a, 8'h02, 0);

        // ------------------------------------------------------------------
        // Test vector 13: sbox[0x3a] = 0x80 (output MSB set)
        // ------------------------------------------------------------------
        check(8'h3a, 8'h80, 0);

        // ------------------------------------------------------------------
        // Test vector 14: sbox[0x2a] = 0xe5
        // ------------------------------------------------------------------
        check(8'h2a, 8'he5, 0);

        // ------------------------------------------------------------------
        // Test vector 15: sbox[0x04] = 0xf2 (all-ones-ish output nibble)
        // ------------------------------------------------------------------
        check(8'h04, 8'hf2, 0);

        // ------------------------------------------------------------------
        // Walk through a range to do bulk verification (entries 0x00-0x7f)
        // Using a loop but NOT generate - just runtime loop
        // ------------------------------------------------------------------
        begin : bulk_check
            reg [7:0] expected_rom [0:127];
            integer j;
            // Load known-good FIPS-197 lower sbox values
            expected_rom[8'h00] = 8'h63; expected_rom[8'h01] = 8'h7c; expected_rom[8'h02] = 8'h77; expected_rom[8'h03] = 8'h7b;
            expected_rom[8'h04] = 8'hf2; expected_rom[8'h05] = 8'h6b; expected_rom[8'h06] = 8'h6f; expected_rom[8'h07] = 8'hc5;
            expected_rom[8'h08] = 8'h30; expected_rom[8'h09] = 8'h01; expected_rom[8'h0a] = 8'h67; expected_rom[8'h0b] = 8'h2b;
            expected_rom[8'h0c] = 8'hfe; expected_rom[8'h0d] = 8'hd7; expected_rom[8'h0e] = 8'hab; expected_rom[8'h0f] = 8'h76;
            expected_rom[8'h10] = 8'hca; expected_rom[8'h11] = 8'h82; expected_rom[8'h12] = 8'hc9; expected_rom[8'h13] = 8'h7d;
            expected_rom[8'h14] = 8'hfa; expected_rom[8'h15] = 8'h59; expected_rom[8'h16] = 8'h47; expected_rom[8'h17] = 8'hf0;
            expected_rom[8'h18] = 8'had; expected_rom[8'h19] = 8'hd4; expected_rom[8'h1a] = 8'ha2; expected_rom[8'h1b] = 8'haf;
            expected_rom[8'h1c] = 8'h9c; expected_rom[8'h1d] = 8'ha4; expected_rom[8'h1e] = 8'h72; expected_rom[8'h1f] = 8'hc0;
            expected_rom[8'h20] = 8'hb7; expected_rom[8'h21] = 8'hfd; expected_rom[8'h22] = 8'h93; expected_rom[8'h23] = 8'h26;
            expected_rom[8'h24] = 8'h36; expected_rom[8'h25] = 8'h3f; expected_rom[8'h26] = 8'hf7; expected_rom[8'h27] = 8'hcc;
            expected_rom[8'h28] = 8'h34; expected_rom[8'h29] = 8'ha5; expected_rom[8'h2a] = 8'he5; expected_rom[8'h2b] = 8'hf1;
            expected_rom[8'h2c] = 8'h71; expected_rom[8'h2d] = 8'hd8; expected_rom[8'h2e] = 8'h31; expected_rom[8'h2f] = 8'h15;
            expected_rom[8'h30] = 8'h04; expected_rom[8'h31] = 8'hc7; expected_rom[8'h32] = 8'h23; expected_rom[8'h33] = 8'hc3;
            expected_rom[8'h34] = 8'h18; expected_rom[8'h35] = 8'h96; expected_rom[8'h36] = 8'h05; expected_rom[8'h37] = 8'h9a;
            expected_rom[8'h38] = 8'h07; expected_rom[8'h39] = 8'h12; expected_rom[8'h3a] = 8'h80; expected_rom[8'h3b] = 8'he2;
            expected_rom[8'h3c] = 8'heb; expected_rom[8'h3d] = 8'h27; expected_rom[8'h3e] = 8'hb2; expected_rom[8'h3f] = 8'h75;
            expected_rom[8'h40] = 8'h09; expected_rom[8'h41] = 8'h83; expected_rom[8'h42] = 8'h2c; expected_rom[8'h43] = 8'h1a;
            expected_rom[8'h44] = 8'h1b; expected_rom[8'h45] = 8'h6e; expected_rom[8'h46] = 8'h5a; expected_rom[8'h47] = 8'ha0;
            expected_rom[8'h48] = 8'h52; expected_rom[8'h49] = 8'h3b; expected_rom[8'h4a] = 8'hd6; expected_rom[8'h4b] = 8'hb3;
            expected_rom[8'h4c] = 8'h29; expected_rom[8'h4d] = 8'he3; expected_rom[8'h4e] = 8'h2f; expected_rom[8'h4f] = 8'h84;
            expected_rom[8'h50] = 8'h53; expected_rom[8'h51] = 8'hd1; expected_rom[8'h52] = 8'h00; expected_rom[8'h53] = 8'hed;
            expected_rom[8'h54] = 8'h20; expected_rom[8'h55] = 8'hfc; expected_rom[8'h56] = 8'hb1; expected_rom[8'h57] = 8'h5b;
            expected_rom[8'h58] = 8'h6a; expected_rom[8'h59] = 8'hcb; expected_rom[8'h5a] = 8'hbe; expected_rom[8'h5b] = 8'h39;
            expected_rom[8'h5c] = 8'h4a; expected_rom[8'h5d] = 8'h4c; expected_rom[8'h5e] = 8'h58; expected_rom[8'h5f] = 8'hcf;
            expected_rom[8'h60] = 8'hd0; expected_rom[8'h61] = 8'hef; expected_rom[8'h62] = 8'haa; expected_rom[8'h63] = 8'hfb;
            expected_rom[8'h64] = 8'h43; expected_rom[8'h65] = 8'h4d; expected_rom[8'h66] = 8'h33; expected_rom[8'h67] = 8'h85;
            expected_rom[8'h68] = 8'h45; expected_rom[8'h69] = 8'hf9; expected_rom[8'h6a] = 8'h02; expected_rom[8'h6b] = 8'h7f;
            expected_rom[8'h6c] = 8'h50; expected_rom[8'h6d] = 8'h3c; expected_rom[8'h6e] = 8'h9f; expected_rom[8'h6f] = 8'ha8;
            expected_rom[8'h70] = 8'h51; expected_rom[8'h71] = 8'ha3; expected_rom[8'h72] = 8'h40; expected_rom[8'h73] = 8'h8f;
            expected_rom[8'h74] = 8'h92; expected_rom[8'h75] = 8'h9d; expected_rom[8'h76] = 8'h38; expected_rom[8'h77] = 8'hf5;
            expected_rom[8'h78] = 8'hbc; expected_rom[8'h79] = 8'hb6; expected_rom[8'h7a] = 8'hda; expected_rom[8'h7b] = 8'h21;
            expected_rom[8'h7c] = 8'h10; expected_rom[8'h7d] = 8'hff; expected_rom[8'h7e] = 8'hf3; expected_rom[8'h7f] = 8'hd2;

            for (j = 0; j < 128; j = j + 1) begin
                in = j[7:0];
                #1;
                if (out === expected_rom[j])
                    $display("PASS: bulk sbox[8'h%02h] = 8'h%02h", j[7:0], out);
                else
                    $display("FAIL: bulk sbox[8'h%02h] = 8'h%02h (expected 8'h%02h)", j[7:0], out, expected_rom[j]);
            end
        end

        $finish;
    end

endmodule
