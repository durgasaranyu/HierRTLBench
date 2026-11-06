`timescale 1ns/1ps
module tb_aes_sbox_lo;

    // DUT connections
    reg  [7:0] in;
    wire [7:0] out;

    // Clock (not used by combinational DUT, but required by rules)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not used by combinational DUT, but required by rules)
    reg rst;
    integer i;

    // Instantiate DUT
    aes_sbox_lo uut (
        .in  (in),
        .out (out)
    );

    // Task for checking
    task check;
        input [7:0] input_val;
        input [7:0] expected;
        input [63:0] desc_unused; // unused, descriptions inline
        begin
            in = input_val;
            #1; // wait for combinational logic
            if (out === expected)
                $display("PASS: in=8'h%02h, out=8'h%02h (expected 8'h%02h)", input_val, out, expected);
            else
                $display("FAIL: in=8'h%02h, out=8'h%02h (expected 8'h%02h)", input_val, out, expected);
        end
    endtask

    initial begin
        rst = 1;
        in  = 8'h00;

        // Assert reset for 5 rising edges
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        // Small delay after reset
        #2;

        // Test vector 1: sbox[0x00] = 0x63 (all-zero input)
        in = 8'h00; #2;
        if (out === 8'h63)
            $display("PASS: sbox[0x00]=0x%02h (expected 0x63)", out);
        else
            $display("FAIL: sbox[0x00]=0x%02h (expected 0x63)", out);

        // Test vector 2: sbox[0x01] = 0x7c
        in = 8'h01; #2;
        if (out === 8'h7c)
            $display("PASS: sbox[0x01]=0x%02h (expected 0x7c)", out);
        else
            $display("FAIL: sbox[0x01]=0x%02h (expected 0x7c)", out);

        // Test vector 3: sbox[0x53] = 0xed
        in = 8'h53; #2;
        if (out === 8'hed)
            $display("PASS: sbox[0x53]=0x%02h (expected 0xed)", out);
        else
            $display("FAIL: sbox[0x53]=0x%02h (expected 0xed)", out);

        // Test vector 4: sbox[0x7f] = 0xd2 (upper boundary of lo half)
        in = 8'h7f; #2;
        if (out === 8'hd2)
            $display("PASS: sbox[0x7f]=0x%02h (expected 0xd2)", out);
        else
            $display("FAIL: sbox[0x7f]=0x%02h (expected 0xd2)", out);

        // Test vector 5: sbox[0x52] = 0x00 (output is zero - edge case)
        in = 8'h52; #2;
        if (out === 8'h00)
            $display("PASS: sbox[0x52]=0x%02h (expected 0x00)", out);
        else
            $display("FAIL: sbox[0x52]=0x%02h (expected 0x00)", out);

        // Test vector 6: sbox[0x7d] = 0xff (output is all-ones - edge case)
        in = 8'h7d; #2;
        if (out === 8'hff)
            $display("PASS: sbox[0x7d]=0x%02h (expected 0xff)", out);
        else
            $display("FAIL: sbox[0x7d]=0x%02h (expected 0xff)", out);

        // Test vector 7: sbox[0x0f] = 0x76
        in = 8'h0f; #2;
        if (out === 8'h76)
            $display("PASS: sbox[0x0f]=0x%02h (expected 0x76)", out);
        else
            $display("FAIL: sbox[0x0f]=0x%02h (expected 0x76)", out);

        // Test vector 8: sbox[0x40] = 0x09
        in = 8'h40; #2;
        if (out === 8'h09)
            $display("PASS: sbox[0x40]=0x%02h (expected 0x09)", out);
        else
            $display("FAIL: sbox[0x40]=0x%02h (expected 0x09)", out);

        // Test vector 9: sbox[0x63] = 0xfb (mid-range value)
        in = 8'h63; #2;
        if (out === 8'hfb)
            $display("PASS: sbox[0x63]=0x%02h (expected 0xfb)", out);
        else
            $display("FAIL: sbox[0x63]=0x%02h (expected 0xfb)", out);

        // Test vector 10: sbox[0x10] = 0xca
        in = 8'h10; #2;
        if (out === 8'hca)
            $display("PASS: sbox[0x10]=0x%02h (expected 0xca)", out);
        else
            $display("FAIL: sbox[0x10]=0x%02h (expected 0xca)", out);

        // Test vector 11: sbox[0x2a] = 0xe5
        in = 8'h2a; #2;
        if (out === 8'he5)
            $display("PASS: sbox[0x2a]=0x%02h (expected 0xe5)", out);
        else
            $display("FAIL: sbox[0x2a]=0x%02h (expected 0xe5)", out);

        // Test vector 12: sbox[0x50] = 0x53
        in = 8'h50; #2;
        if (out === 8'h53)
            $display("PASS: sbox[0x50]=0x%02h (expected 0x53)", out);
        else
            $display("FAIL: sbox[0x50]=0x%02h (expected 0x53)", out);

        // Exhaustive check of all 128 entries in the lower half
        begin : exhaustive_check
            reg [7:0] expected_val;
            reg pass_all;
            integer fail_count;
            // Reference table for 0x00..0x7F
            reg [7:0] ref [0:127];

            ref[8'h00] = 8'h63; ref[8'h01] = 8'h7c; ref[8'h02] = 8'h77; ref[8'h03] = 8'h7b;
            ref[8'h04] = 8'hf2; ref[8'h05] = 8'h6b; ref[8'h06] = 8'h6f; ref[8'h07] = 8'hc5;
            ref[8'h08] = 8'h30; ref[8'h09] = 8'h01; ref[8'h0a] = 8'h67; ref[8'h0b] = 8'h2b;
            ref[8'h0c] = 8'hfe; ref[8'h0d] = 8'hd7; ref[8'h0e] = 8'hab; ref[8'h0f] = 8'h76;
            ref[8'h10] = 8'hca; ref[8'h11] = 8'h82; ref[8'h12] = 8'hc9; ref[8'h13] = 8'h7d;
            ref[8'h14] = 8'hfa; ref[8'h15] = 8'h59; ref[8'h16] = 8'h47; ref[8'h17] = 8'hf0;
            ref[8'h18] = 8'had; ref[8'h19] = 8'hd4; ref[8'h1a] = 8'ha2; ref[8'h1b] = 8'haf;
            ref[8'h1c] = 8'h9c; ref[8'h1d] = 8'ha4; ref[8'h1e] = 8'h72; ref[8'h1f] = 8'hc0;
            ref[8'h20] = 8'hb7; ref[8'h21] = 8'hfd; ref[8'h22] = 8'h93; ref[8'h23] = 8'h26;
            ref[8'h24] = 8'h36; ref[8'h25] = 8'h3f; ref[8'h26] = 8'hf7; ref[8'h27] = 8'hcc;
            ref[8'h28] = 8'h34; ref[8'h29] = 8'ha5; ref[8'h2a] = 8'he5; ref[8'h2b] = 8'hf1;
            ref[8'h2c] = 8'h71; ref[8'h2d] = 8'hd8; ref[8'h2e] = 8'h31; ref[8'h2f] = 8'h15;
            ref[8'h30] = 8'h04; ref[8'h31] = 8'hc7; ref[8'h32] = 8'h23; ref[8'h33] = 8'hc3;
            ref[8'h34] = 8'h18; ref[8'h35] = 8'h96; ref[8'h36] = 8'h05; ref[8'h37] = 8'h9a;
            ref[8'h38] = 8'h07; ref[8'h39] = 8'h12; ref[8'h3a] = 8'h80; ref[8'h3b] = 8'he2;
            ref[8'h3c] = 8'heb; ref[8'h3d] = 8'h27; ref[8'h3e] = 8'hb2; ref[8'h3f] = 8'h75;
            ref[8'h40] = 8'h09; ref[8'h41] = 8'h83; ref[8'h42] = 8'h2c; ref[8'h43] = 8'h1a;
            ref[8'h44] = 8'h1b; ref[8'h45] = 8'h6e; ref[8'h46] = 8'h5a; ref[8'h47] = 8'ha0;
            ref[8'h48] = 8'h52; ref[8'h49] = 8'h3b; ref[8'h4a] = 8'hd6; ref[8'h4b] = 8'hb3;
            ref[8'h4c] = 8'h29; ref[8'h4d] = 8'he3; ref[8'h4e] = 8'h2f; ref[8'h4f] = 8'h84;
            ref[8'h50] = 8'h53; ref[8'h51] = 8'hd1; ref[8'h52] = 8'h00; ref[8'h53] = 8'hed;
            ref[8'h54] = 8'h20; ref[8'h55] = 8'hfc; ref[8'h56] = 8'hb1; ref[8'h57] = 8'h5b;
            ref[8'h58] = 8'h6a; ref[8'h59] = 8'hcb; ref[8'h5a] = 8'hbe; ref[8'h5b] = 8'h39;
            ref[8'h5c] = 8'h4a; ref[8'h5d] = 8'h4c; ref[8'h5e] = 8'h58; ref[8'h5f] = 8'hcf;
            ref[8'h60] = 8'hd0; ref[8'h61] = 8'hef; ref[8'h62] = 8'haa; ref[8'h63] = 8'hfb;
            ref[8'h64] = 8'h43; ref[8'h65] = 8'h4d; ref[8'h66] = 8'h33; ref[8'h67] = 8'h85;
            ref[8'h68] = 8'h45; ref[8'h69] = 8'hf9; ref[8'h6a] = 8'h02; ref[8'h6b] = 8'h7f;
            ref[8'h6c] = 8'h50; ref[8'h6d] = 8'h3c; ref[8'h6e] = 8'h9f; ref[8'h6f] = 8'ha8;
            ref[8'h70] = 8'h51; ref[8'h71] = 8'ha3; ref[8'h72] = 8'h40; ref[8'h73] = 8'h8f;
            ref[8'h74] = 8'h92; ref[8'h75] = 8'h9d; ref[8'h76] = 8'h38; ref[8'h77] = 8'hf5;
            ref[8'h78] = 8'hbc; ref[8'h79] = 8'hb6; ref[8'h7a] = 8'hda; ref[8'h7b] = 8'h21;
            ref[8'h7c] = 8'h10; ref[8'h7d] = 8'hff; ref[8'h7e] = 8'hf3; ref[8'h7f] = 8'hd2;

            fail_count = 0;
            for (i = 0; i < 128; i = i + 1) begin
                in = i[7:0];
                #2;
                if (out !== ref[i[7:0]]) begin
                    $display("FAIL: exhaustive: sbox[0x%02h]=0x%02h (expected 0x%02h)", i[7:0], out, ref[i[7:0]]);
                    fail_count = fail_count + 1;
                end
            end
            if (fail_count == 0)
                $display("PASS: exhaustive check of all 128 lower-half S-box entries");
            else
                $display("FAIL: exhaustive check: %0d entries mismatched", fail_count);
        end

        $finish;
    end

endmodule
