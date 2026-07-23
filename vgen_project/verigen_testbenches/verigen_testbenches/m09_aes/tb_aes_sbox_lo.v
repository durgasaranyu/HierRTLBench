`timescale 1ns/1ps
module tb_aes_sbox_lo;

    // DUT connections
    reg  [7:0] in;
    wire [7:0] out;

    // Clock (not needed by combinational DUT, but required by testbench rules)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not needed by combinational DUT, but required by testbench rules)
    reg rst;
    initial rst = 1;

    // Instantiate DUT
    aes_sbox_lo uut (
        .in  (in),
        .out (out)
    );

    // Release reset after 5 rising edges
    integer i;
    initial begin
        rst = 1;
        in  = 8'h00;
        // Wait for 5 rising edges
        repeat (5) @(posedge clk);
        rst = 0;

        // Allow combinational to settle
        #2;

        // -------------------------------------------------------
        // Test 1: in = 0x00, expect 0x63
        // -------------------------------------------------------
        in = 8'h00;
        #10;
        if (out === 8'h63)
            $display("PASS: sbox[0x00] = 0x63");
        else
            $display("FAIL: sbox[0x00] expected 0x63, got 0x%02h", out);

        // -------------------------------------------------------
        // Test 2: in = 0x53, expect 0xED
        // -------------------------------------------------------
        in = 8'h53;
        #10;
        if (out === 8'hed)
            $display("PASS: sbox[0x53] = 0xED");
        else
            $display("FAIL: sbox[0x53] expected 0xED, got 0x%02h", out);

        // -------------------------------------------------------
        // Test 3: in = 0x7F, expect 0xD2 (last entry in lower half)
        // -------------------------------------------------------
        in = 8'h7f;
        #10;
        if (out === 8'hd2)
            $display("PASS: sbox[0x7F] = 0xD2");
        else
            $display("FAIL: sbox[0x7F] expected 0xD2, got 0x%02h", out);

        // -------------------------------------------------------
        // Test 4: in = 0x01, expect 0x7C
        // -------------------------------------------------------
        in = 8'h01;
        #10;
        if (out === 8'h7c)
            $display("PASS: sbox[0x01] = 0x7C");
        else
            $display("FAIL: sbox[0x01] expected 0x7C, got 0x%02h", out);

        // -------------------------------------------------------
        // Test 5: in = 0x0F, expect 0x76
        // -------------------------------------------------------
        in = 8'h0f;
        #10;
        if (out === 8'h76)
            $display("PASS: sbox[0x0F] = 0x76");
        else
            $display("FAIL: sbox[0x0F] expected 0x76, got 0x%02h", out);

        // -------------------------------------------------------
        // Test 6: in = 0x52, expect 0x00 (sbox output = 0)
        // -------------------------------------------------------
        in = 8'h52;
        #10;
        if (out === 8'h00)
            $display("PASS: sbox[0x52] = 0x00");
        else
            $display("FAIL: sbox[0x52] expected 0x00, got 0x%02h", out);

        // -------------------------------------------------------
        // Test 7: in = 0x7D, expect 0xFF (sbox output = all ones)
        // -------------------------------------------------------
        in = 8'h7d;
        #10;
        if (out === 8'hff)
            $display("PASS: sbox[0x7D] = 0xFF");
        else
            $display("FAIL: sbox[0x7D] expected 0xFF, got 0x%02h", out);

        // -------------------------------------------------------
        // Test 8: in = 0x80, expect 0xCD (first entry in upper half)
        // -------------------------------------------------------
        in = 8'h80;
        #10;
        if (out === 8'hcd)
            $display("PASS: sbox[0x80] = 0xCD");
        else
            $display("FAIL: sbox[0x80] expected 0xCD, got 0x%02h", out);

        // -------------------------------------------------------
        // Test 9: in = 0x63, expect 0xFB (mid-range value)
        // -------------------------------------------------------
        in = 8'h63;
        #10;
        if (out === 8'hfb)
            $display("PASS: sbox[0x63] = 0xFB");
        else
            $display("FAIL: sbox[0x63] expected 0xFB, got 0x%02h", out);

        // -------------------------------------------------------
        // Test 10: Sweep all lower-half entries against expected values
        // -------------------------------------------------------
        begin : sweep_lower
            reg [7:0] expected [0:127];
            expected[8'h00] = 8'h63; expected[8'h01] = 8'h7c; expected[8'h02] = 8'h77; expected[8'h03] = 8'h7b;
            expected[8'h04] = 8'hf2; expected[8'h05] = 8'h6b; expected[8'h06] = 8'h6f; expected[8'h07] = 8'hc5;
            expected[8'h08] = 8'h30; expected[8'h09] = 8'h01; expected[8'h0a] = 8'h67; expected[8'h0b] = 8'h2b;
            expected[8'h0c] = 8'hfe; expected[8'h0d] = 8'hd7; expected[8'h0e] = 8'hab; expected[8'h0f] = 8'h76;
            expected[8'h10] = 8'hca; expected[8'h11] = 8'h82; expected[8'h12] = 8'hc9; expected[8'h13] = 8'h7d;
            expected[8'h14] = 8'hfa; expected[8'h15] = 8'h59; expected[8'h16] = 8'h47; expected[8'h17] = 8'hf0;
            expected[8'h18] = 8'had; expected[8'h19] = 8'hd4; expected[8'h1a] = 8'ha2; expected[8'h1b] = 8'haf;
            expected[8'h1c] = 8'h9c; expected[8'h1d] = 8'ha4; expected[8'h1e] = 8'h72; expected[8'h1f] = 8'hc0;
            expected[8'h20] = 8'hb7; expected[8'h21] = 8'hfd; expected[8'h22] = 8'h93; expected[8'h23] = 8'h26;
            expected[8'h24] = 8'h36; expected[8'h25] = 8'h3f; expected[8'h26] = 8'hf7; expected[8'h27] = 8'hcc;
            expected[8'h28] = 8'h34; expected[8'h29] = 8'ha5; expected[8'h2a] = 8'he5; expected[8'h2b] = 8'hf1;
            expected[8'h2c] = 8'h71; expected[8'h2d] = 8'hd8; expected[8'h2e] = 8'h31; expected[8'h2f] = 8'h15;
            expected[8'h30] = 8'h04; expected[8'h31] = 8'hc7; expected[8'h32] = 8'h23; expected[8'h33] = 8'hc3;
            expected[8'h34] = 8'h18; expected[8'h35] = 8'h96; expected[8'h36] = 8'h05; expected[8'h37] = 8'h9a;
            expected[8'h38] = 8'h07; expected[8'h39] = 8'h12; expected[8'h3a] = 8'h80; expected[8'h3b] = 8'he2;
            expected[8'h3c] = 8'heb; expected[8'h3d] = 8'h27; expected[8'h3e] = 8'hb2; expected[8'h3f] = 8'h75;
            expected[8'h40] = 8'h09; expected[8'h41] = 8'h83; expected[8'h42] = 8'h2c; expected[8'h43] = 8'h1a;
            expected[8'h44] = 8'h1b; expected[8'h45] = 8'h6e; expected[8'h46] = 8'h5a; expected[8'h47] = 8'ha0;
            expected[8'h48] = 8'h52; expected[8'h49] = 8'h3b; expected[8'h4a] = 8'hd6; expected[8'h4b] = 8'hb3;
            expected[8'h4c] = 8'h29; expected[8'h4d] = 8'he3; expected[8'h4e] = 8'h2f; expected[8'h4f] = 8'h84;
            expected[8'h50] = 8'h53; expected[8'h51] = 8'hd1; expected[8'h52] = 8'h00; expected[8'h53] = 8'hed;
            expected[8'h54] = 8'h20; expected[8'h55] = 8'hfc; expected[8'h56] = 8'hb1; expected[8'h57] = 8'h5b;
            expected[8'h58] = 8'h6a; expected[8'h59] = 8'hcb; expected[8'h5a] = 8'hbe; expected[8'h5b] = 8'h39;
            expected[8'h5c] = 8'h4a; expected[8'h5d] = 8'h4c; expected[8'h5e] = 8'h58; expected[8'h5f] = 8'hcf;
            expected[8'h60] = 8'hd0; expected[8'h61] = 8'hef; expected[8'h62] = 8'haa; expected[8'h63] = 8'hfb;
            expected[8'h64] = 8'h43; expected[8'h65] = 8'h4d; expected[8'h66] = 8'h33; expected[8'h67] = 8'h85;
            expected[8'h68] = 8'h45; expected[8'h69] = 8'hf9; expected[8'h6a] = 8'h02; expected[8'h6b] = 8'h7f;
            expected[8'h6c] = 8'h50; expected[8'h6d] = 8'h3c; expected[8'h6e] = 8'h9f; expected[8'h6f] = 8'ha8;
            expected[8'h70] = 8'h51; expected[8'h71] = 8'ha3; expected[8'h72] = 8'h40; expected[8'h73] = 8'h8f;
            expected[8'h74] = 8'h92; expected[8'h75] = 8'h9d; expected[8'h76] = 8'h38; expected[8'h77] = 8'hf5;
            expected[8'h78] = 8'hbc; expected[8'h79] = 8'hb6; expected[8'h7a] = 8'hda; expected[8'h7b] = 8'h21;
            expected[8'h7c] = 8'h10; expected[8'h7d] = 8'hff; expected[8'h7e] = 8'hf3; expected[8'h7f] = 8'hd2;

            for (i = 0; i < 128; i = i + 1) begin
                in = i[7:0];
                #10;
                if (out !== expected[i]) begin
                    $display("FAIL: sbox[0x%02h] expected 0x%02h, got 0x%02h", in, expected[i], out);
                end
            end
            $display("PASS: Full lower-half sweep (0x00-0x7F) completed");
        end

        $finish;
    end

endmodule
