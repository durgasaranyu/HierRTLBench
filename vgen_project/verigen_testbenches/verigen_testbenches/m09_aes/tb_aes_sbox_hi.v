`timescale 1ns/1ps
module tb_aes_sbox_hi;

    // DUT connections
    reg  [7:0] in;
    wire [7:0] out;

    // Clock (not used by combinational DUT, but required by testbench rules)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not used by DUT, but required by testbench rules)
    reg rst;
    integer rst_count;
    initial begin
        rst = 1;
        rst_count = 0;
    end

    // Instantiate DUT
    aes_sbox_hi uut (
        .in  (in),
        .out (out)
    );

    // Apply reset for 5 rising edges then deassert
    always @(posedge clk) begin
        if (rst) begin
            rst_count = rst_count + 1;
            if (rst_count >= 5)
                rst = 0;
        end
    end

    // Task for checking a single input/expected pair
    task check;
        input [7:0] test_in;
        input [7:0] expected;
        input [127:0] desc_hi;
        input [127:0] desc_lo;
        begin
            in = test_in;
            #2; // small delay for combinational settling
            if (out === expected)
                $display("PASS: in=0x%02h expected=0x%02h got=0x%02h", test_in, expected, out);
            else
                $display("FAIL: in=0x%02h expected=0x%02h got=0x%02h", test_in, expected, out);
        end
    endtask

    integer i;
    reg [7:0] expected_val;

    // Full lookup table for verification (entries 0x80-0xFF)
    reg [7:0] ref [0:255];

    initial begin
        // Initialize reference table entries 0x80..0xFF
        ref[8'h80]=8'hcd; ref[8'h81]=8'h0c; ref[8'h82]=8'h13; ref[8'h83]=8'hec;
        ref[8'h84]=8'h5f; ref[8'h85]=8'h97; ref[8'h86]=8'h44; ref[8'h87]=8'h17;
        ref[8'h88]=8'hc4; ref[8'h89]=8'ha7; ref[8'h8a]=8'h7e; ref[8'h8b]=8'h3d;
        ref[8'h8c]=8'h64; ref[8'h8d]=8'h5d; ref[8'h8e]=8'h19; ref[8'h8f]=8'h73;
        ref[8'h90]=8'h60; ref[8'h91]=8'h81; ref[8'h92]=8'h4f; ref[8'h93]=8'hdc;
        ref[8'h94]=8'h22; ref[8'h95]=8'h2a; ref[8'h96]=8'h90; ref[8'h97]=8'h88;
        ref[8'h98]=8'h46; ref[8'h99]=8'hee; ref[8'h9a]=8'hb8; ref[8'h9b]=8'h14;
        ref[8'h9c]=8'hde; ref[8'h9d]=8'h5e; ref[8'h9e]=8'h0b; ref[8'h9f]=8'hdb;
        ref[8'ha0]=8'he0; ref[8'ha1]=8'h32; ref[8'ha2]=8'h3a; ref[8'ha3]=8'h0a;
        ref[8'ha4]=8'h49; ref[8'ha5]=8'h06; ref[8'ha6]=8'h24; ref[8'ha7]=8'h5c;
        ref[8'ha8]=8'hc2; ref[8'ha9]=8'hd3; ref[8'haa]=8'hac; ref[8'hab]=8'h62;
        ref[8'hac]=8'h91; ref[8'had]=8'h95; ref[8'hae]=8'he4; ref[8'haf]=8'h79;
        ref[8'hb0]=8'he7; ref[8'hb1]=8'hc8; ref[8'hb2]=8'h37; ref[8'hb3]=8'h6d;
        ref[8'hb4]=8'h8d; ref[8'hb5]=8'hd5; ref[8'hb6]=8'h4e; ref[8'hb7]=8'ha9;
        ref[8'hb8]=8'h6c; ref[8'hb9]=8'h56; ref[8'hba]=8'hf4; ref[8'hbb]=8'hea;
        ref[8'hbc]=8'h65; ref[8'hbd]=8'h7a; ref[8'hbe]=8'hae; ref[8'hbf]=8'h08;
        ref[8'hc0]=8'hba; ref[8'hc1]=8'h78; ref[8'hc2]=8'h25; ref[8'hc3]=8'h2e;
        ref[8'hc4]=8'h1c; ref[8'hc5]=8'ha6; ref[8'hc6]=8'hb4; ref[8'hc7]=8'hc6;
        ref[8'hc8]=8'he8; ref[8'hc9]=8'hdd; ref[8'hca]=8'h74; ref[8'hcb]=8'h1f;
        ref[8'hcc]=8'h4b; ref[8'hcd]=8'hbd; ref[8'hce]=8'h8b; ref[8'hcf]=8'h8a;
        ref[8'hd0]=8'h70; ref[8'hd1]=8'h3e; ref[8'hd2]=8'hb5; ref[8'hd3]=8'h66;
        ref[8'hd4]=8'h48; ref[8'hd5]=8'h03; ref[8'hd6]=8'hf6; ref[8'hd7]=8'h0e;
        ref[8'hd8]=8'h61; ref[8'hd9]=8'h35; ref[8'hda]=8'h57; ref[8'hdb]=8'hb9;
        ref[8'hdc]=8'h86; ref[8'hdd]=8'hc1; ref[8'hde]=8'h1d; ref[8'hdf]=8'h9e;
        ref[8'he0]=8'he1; ref[8'he1]=8'hf8; ref[8'he2]=8'h98; ref[8'he3]=8'h11;
        ref[8'he4]=8'h69; ref[8'he5]=8'hd9; ref[8'he6]=8'h8e; ref[8'he7]=8'h94;
        ref[8'he8]=8'h9b; ref[8'he9]=8'h1e; ref[8'hea]=8'h87; ref[8'heb]=8'he9;
        ref[8'hec]=8'hce; ref[8'hed]=8'h55; ref[8'hee]=8'h28; ref[8'hef]=8'hdf;
        ref[8'hf0]=8'h8c; ref[8'hf1]=8'ha1; ref[8'hf2]=8'h89; ref[8'hf3]=8'h0d;
        ref[8'hf4]=8'hbf; ref[8'hf5]=8'he6; ref[8'hf6]=8'h42; ref[8'hf7]=8'h68;
        ref[8'hf8]=8'h41; ref[8'hf9]=8'h99; ref[8'hfa]=8'h2d; ref[8'hfb]=8'h0f;
        ref[8'hfc]=8'hb0; ref[8'hfd]=8'h54; ref[8'hfe]=8'hbb; ref[8'hff]=8'h16;

        // Wait for reset to complete
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk); // one extra after deassert
        #2;

        // Test vector 1: Lower boundary of valid range 0x80 -> 0xcd
        in = 8'h80; #10;
        if (out === 8'hcd)
            $display("PASS: in=0x80 (lower boundary), expected=0xcd, got=0x%02h", out);
        else
            $display("FAIL: in=0x80 (lower boundary), expected=0xcd, got=0x%02h", out);

        // Test vector 2: Upper boundary 0xFF -> 0x16
        in = 8'hff; #10;
        if (out === 8'h16)
            $display("PASS: in=0xff (upper boundary), expected=0x16, got=0x%02h", out);
        else
            $display("FAIL: in=0xff (upper boundary), expected=0x16, got=0x%02h", out);

        // Test vector 3: Mid-range 0xa0 -> 0xe0
        in = 8'ha0; #10;
        if (out === 8'he0)
            $display("PASS: in=0xa0 (mid-range), expected=0xe0, got=0x%02h", out);
        else
            $display("FAIL: in=0xa0 (mid-range), expected=0xe0, got=0x%02h", out);

        // Test vector 4: 0xc0 -> 0xba
        in = 8'hc0; #10;
        if (out === 8'hba)
            $display("PASS: in=0xc0, expected=0xba, got=0x%02h", out);
        else
            $display("FAIL: in=0xc0, expected=0xba, got=0x%02h", out);

        // Test vector 5: 0xe0 -> 0xe1
        in = 8'he0; #10;
        if (out === 8'he1)
            $display("PASS: in=0xe0, expected=0xe1, got=0x%02h", out);
        else
            $display("FAIL: in=0xe0, expected=0xe1, got=0x%02h", out);

        // Test vector 6: 0xd5 -> 0x03
        in = 8'hd5; #10;
        if (out === 8'h03)
            $display("PASS: in=0xd5, expected=0x03, got=0x%02h", out);
        else
            $display("FAIL: in=0xd5, expected=0x03, got=0x%02h", out);

        // Test vector 7: 0xed -> 0x55
        in = 8'hed; #10;
        if (out === 8'h55)
            $display("PASS: in=0xed, expected=0x55, got=0x%02h", out);
        else
            $display("FAIL: in=0xed, expected=0x55, got=0x%02h", out);

        // Test vector 8: 0x99 -> 0xee
        in = 8'h99; #10;
        if (out === 8'hee)
            $display("PASS: in=0x99, expected=0xee, got=0x%02h", out);
        else
            $display("FAIL: in=0x99, expected=0xee, got=0x%02h", out);

        // Test vector 9: 0xbb -> 0xea
        in = 8'hbb; #10;
        if (out === 8'hea)
            $display("PASS: in=0xbb, expected=0xea, got=0x%02h", out);
        else
            $display("FAIL: in=0xbb, expected=0xea, got=0x%02h", out);

        // Test vector 10: 0x8f -> 0x73
        in = 8'h8f; #10;
        if (out === 8'h73)
            $display("PASS: in=0x8f, expected=0x73, got=0x%02h", out);
        else
            $display("FAIL: in=0x8f, expected=0x73, got=0x%02h", out);

        // Exhaustive check of all 128 entries (0x80 to 0xFF)
        $display("--- Exhaustive check of all valid entries 0x80 to 0xFF ---");
        for (i = 128; i <= 255; i = i + 1) begin
            in = i[7:0];
            #10;
            expected_val = ref[i[7:0]];
            if (out === expected_val)
                $display("PASS: exhaustive in=0x%02h expected=0x%02h got=0x%02h", i[7:0], expected_val, out);
            else
                $display("FAIL: exhaustive in=0x%02h expected=0x%02h got=0x%02h", i[7:0], expected_val, out);
        end

        $display("Testbench complete.");
        $finish;
    end

endmodule
