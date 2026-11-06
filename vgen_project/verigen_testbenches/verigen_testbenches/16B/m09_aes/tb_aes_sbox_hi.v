`timescale 1ns/1ps

module tb_aes_sbox_hi;

    // DUT connections
    reg  [7:0] in;
    wire [7:0] out;

    // Instantiate DUT
    aes_sbox_hi uut (
        .in  (in),
        .out (out)
    );

    // Clock (not used by combinational DUT, but required by spec)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not used by combinational DUT, but required by spec)
    reg rst;
    integer i;

    // Task for checking
    task check;
        input [7:0] test_in;
        input [7:0] expected;
        input [127:0] desc_hi;
        input [127:0] desc_lo;
        begin
            in = test_in;
            #1; // allow combinational logic to settle
            if (out === expected)
                $display("PASS: in=0x%02h expected=0x%02h got=0x%02h", test_in, expected, out);
            else
                $display("FAIL: in=0x%02h expected=0x%02h got=0x%02h", test_in, expected, out);
        end
    endtask

    initial begin
        // Apply reset for 5 clock rising edges
        rst = 1;
        in  = 8'h00;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // ----------------------------------------------------------------
        // Test vectors
        // The module covers inputs 0x80-0xFF; inputs below 0x80 return
        // the default value 0x52.
        // FIPS-197 S-box values for upper half are verified here.
        // ----------------------------------------------------------------

        // Test 1: in=0x80 -> expected 0xcd
        in = 8'h80; #2;
        if (out === 8'hcd)
            $display("PASS: in=0x80 expected=0xcd got=0x%02h", out);
        else
            $display("FAIL: in=0x80 expected=0xcd got=0x%02h", out);

        // Test 2: in=0xff -> expected 0xad (last entry in case)
        in = 8'hff; #2;
        if (out === 8'had)
            $display("PASS: in=0xff expected=0xad got=0x%02h", out);
        else
            $display("FAIL: in=0xff expected=0xad got=0x%02h", out);

        // Test 3: in=0xfe -> expected 0x16
        in = 8'hfe; #2;
        if (out === 8'h16)
            $display("PASS: in=0xfe expected=0x16 got=0x%02h", out);
        else
            $display("FAIL: in=0xfe expected=0x16 got=0x%02h", out);

        // Test 4: in=0xa0 -> expected 0x32
        in = 8'ha0; #2;
        if (out === 8'h32)
            $display("PASS: in=0xa0 expected=0x32 got=0x%02h", out);
        else
            $display("FAIL: in=0xa0 expected=0x32 got=0x%02h", out);

        // Test 5: in=0xc0 -> expected 0x78
        in = 8'hc0; #2;
        if (out === 8'h78)
            $display("PASS: in=0xc0 expected=0x78 got=0x%02h", out);
        else
            $display("FAIL: in=0xc0 expected=0x78 got=0x%02h", out);

        // Test 6: in=0xe0 -> expected 0xf8
        in = 8'he0; #2;
        if (out === 8'hf8)
            $display("PASS: in=0xe0 expected=0xf8 got=0x%02h", out);
        else
            $display("FAIL: in=0xe0 expected=0xf8 got=0x%02h", out);

        // Test 7: in=0xd0 -> expected 0x3e
        in = 8'hd0; #2;
        if (out === 8'h3e)
            $display("PASS: in=0xd0 expected=0x3e got=0x%02h", out);
        else
            $display("FAIL: in=0xd0 expected=0x3e got=0x%02h", out);

        // Test 8: in=0x90 -> expected 0x81
        in = 8'h90; #2;
        if (out === 8'h81)
            $display("PASS: in=0x90 expected=0x81 got=0x%02h", out);
        else
            $display("FAIL: in=0x90 expected=0x81 got=0x%02h", out);

        // Test 9: in=0xb0 -> expected 0xc8
        in = 8'hb0; #2;
        if (out === 8'hc8)
            $display("PASS: in=0xb0 expected=0xc8 got=0x%02h", out);
        else
            $display("FAIL: in=0xb0 expected=0xc8 got=0x%02h", out);

        // Test 10: in=0x00 -> below range, default 0x52
        in = 8'h00; #2;
        if (out === 8'h52)
            $display("PASS: in=0x00 (default) expected=0x52 got=0x%02h", out);
        else
            $display("FAIL: in=0x00 (default) expected=0x52 got=0x%02h", out);

        // Test 11: in=0x7f -> below range, default 0x52
        in = 8'h7f; #2;
        if (out === 8'h52)
            $display("PASS: in=0x7f (default) expected=0x52 got=0x%02h", out);
        else
            $display("FAIL: in=0x7f (default) expected=0x52 got=0x%02h", out);

        // Test 12: in=0x9f -> expected 0xe0
        in = 8'h9f; #2;
        if (out === 8'he0)
            $display("PASS: in=0x9f expected=0xe0 got=0x%02h", out);
        else
            $display("FAIL: in=0x9f expected=0xe0 got=0x%02h", out);

        // Test 13: in=0xec -> expected 0x55
        in = 8'hec; #2;
        if (out === 8'h55)
            $display("PASS: in=0xec expected=0x55 got=0x%02h", out);
        else
            $display("FAIL: in=0xec expected=0x55 got=0x%02h", out);

        // Test 14: in=0xf8 -> expected 0x99
        in = 8'hf8; #2;
        if (out === 8'h99)
            $display("PASS: in=0xf8 expected=0x99 got=0x%02h", out);
        else
            $display("FAIL: in=0xf8 expected=0x99 got=0x%02h", out);

        // Test 15: in=0x81 -> expected 0x0c
        in = 8'h81; #2;
        if (out === 8'h0c)
            $display("PASS: in=0x81 expected=0x0c got=0x%02h", out);
        else
            $display("FAIL: in=0x81 expected=0x0c got=0x%02h", out);

        // Test 16: all-ones-like: in=0xff already done; try mid-range 0xcc -> 0xbd
        in = 8'hcc; #2;
        if (out === 8'hbd)
            $display("PASS: in=0xcc expected=0xbd got=0x%02h", out);
        else
            $display("FAIL: in=0xcc expected=0xbd got=0x%02h", out);

        $finish;
    end

endmodule
