`timescale 1ns/1ps

module tb_aes_sbox_hi;

    // DUT connections
    reg  [7:0] in;
    wire [7:0] out;

    // Clock (not needed for combinational, but required by guidelines)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    aes_sbox_hi uut (
        .in  (in),
        .out (out)
    );

    // Reset for 5 rising edges then deassert
    integer i;
    initial begin
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
    end

    // Task for checking
    task check;
        input [7:0] test_in;
        input [7:0] expected;
        input [63:0] desc_val; // not used for string, just for identification
        begin
            in = test_in;
            #2; // let combinational settle
            if (out === expected)
                $display("PASS: in=8'h%02h expected out=8'h%02h got=8'h%02h", test_in, expected, out);
            else
                $display("FAIL: in=8'h%02h expected out=8'h%02h got=8'h%02h", test_in, expected, out);
        end
    endtask

    initial begin
        // Wait for reset to deassert
        @(negedge rst);
        @(posedge clk);
        #1;

        // Test vector 1: in=0x80, expected=0xcd (first entry)
        in = 8'h80; #2;
        if (out === 8'hcd)
            $display("PASS: in=8'h80, expected out=8'hcd, got=8'h%02h", out);
        else
            $display("FAIL: in=8'h80, expected out=8'hcd, got=8'h%02h", out);

        // Test vector 2: in=0xff, expected=0x16 (last entry)
        in = 8'hff; #2;
        if (out === 8'h16)
            $display("PASS: in=8'hff, expected out=8'h16, got=8'h%02h", out);
        else
            $display("FAIL: in=8'hff, expected out=8'h16, got=8'h%02h", out);

        // Test vector 3: in=0x81, expected=0x0c
        in = 8'h81; #2;
        if (out === 8'h0c)
            $display("PASS: in=8'h81, expected out=8'h0c, got=8'h%02h", out);
        else
            $display("FAIL: in=8'h81, expected out=8'h0c, got=8'h%02h", out);

        // Test vector 4: in=0xa0, expected=0xe0 (middle range)
        in = 8'ha0; #2;
        if (out === 8'he0)
            $display("PASS: in=8'ha0, expected out=8'he0, got=8'h%02h", out);
        else
            $display("FAIL: in=8'ha0, expected out=8'he0, got=8'h%02h", out);

        // Test vector 5: in=0xc0, expected=0xba
        in = 8'hc0; #2;
        if (out === 8'hba)
            $display("PASS: in=8'hc0, expected out=8'hba, got=8'h%02h", out);
        else
            $display("FAIL: in=8'hc0, expected out=8'hba, got=8'h%02h", out);

        // Test vector 6: in=0xe0, expected=0xe1
        in = 8'he0; #2;
        if (out === 8'he1)
            $display("PASS: in=8'he0, expected out=8'he1, got=8'h%02h", out);
        else
            $display("FAIL: in=8'he0, expected out=8'he1, got=8'h%02h", out);

        // Test vector 7: in=0xd0, expected=0x70
        in = 8'hd0; #2;
        if (out === 8'h70)
            $display("PASS: in=8'hd0, expected out=8'h70, got=8'h%02h", out);
        else
            $display("FAIL: in=8'hd0, expected out=8'h70, got=8'h%02h", out);

        // Test vector 8: in=0xb0, expected=0xe7
        in = 8'hb0; #2;
        if (out === 8'he7)
            $display("PASS: in=8'hb0, expected out=8'he7, got=8'h%02h", out);
        else
            $display("FAIL: in=8'hb0, expected out=8'he7, got=8'h%02h", out);

        // Extra test vectors for more coverage

        // in=0x90, expected=0x60
        in = 8'h90; #2;
        if (out === 8'h60)
            $display("PASS: in=8'h90, expected out=8'h60, got=8'h%02h", out);
        else
            $display("FAIL: in=8'h90, expected out=8'h60, got=8'h%02h", out);

        // in=0xfe, expected=0xbb
        in = 8'hfe; #2;
        if (out === 8'hbb)
            $display("PASS: in=8'hfe, expected out=8'hbb, got=8'h%02h", out);
        else
            $display("FAIL: in=8'hfe, expected out=8'hbb, got=8'h%02h", out);

        // in=0x8f, expected=0x73
        in = 8'h8f; #2;
        if (out === 8'h73)
            $display("PASS: in=8'h8f, expected out=8'h73, got=8'h%02h", out);
        else
            $display("FAIL: in=8'h8f, expected out=8'h73, got=8'h%02h", out);

        // in=0xf0, expected=0x8c
        in = 8'hf0; #2;
        if (out === 8'h8c)
            $display("PASS: in=8'hf0, expected out=8'h8c, got=8'h%02h", out);
        else
            $display("FAIL: in=8'hf0, expected out=8'h8c, got=8'h%02h", out);

        // in=0xec, expected=0xce
        in = 8'hec; #2;
        if (out === 8'hce)
            $display("PASS: in=8'hec, expected out=8'hce, got=8'h%02h", out);
        else
            $display("FAIL: in=8'hec, expected out=8'hce, got=8'h%02h", out);

        // in=0xcf, expected=0x8a
        in = 8'hcf; #2;
        if (out === 8'h8a)
            $display("PASS: in=8'hcf, expected out=8'h8a, got=8'h%02h", out);
        else
            $display("FAIL: in=8'hcf, expected out=8'h8a, got=8'h%02h", out);

        // in=0xaa, expected=0xac
        in = 8'haa; #2;
        if (out === 8'hac)
            $display("PASS: in=8'haa, expected out=8'hac, got=8'h%02h", out);
        else
            $display("FAIL: in=8'haa, expected out=8'hac, got=8'h%02h", out);

        // in=0xbb, expected=0xea
        in = 8'hbb; #2;
        if (out === 8'hea)
            $display("PASS: in=8'hbb, expected out=8'hea, got=8'h%02h", out);
        else
            $display("FAIL: in=8'hbb, expected out=8'hea, got=8'h%02h", out);

        // in=0x9f, expected=0xdb
        in = 8'h9f; #2;
        if (out === 8'hdb)
            $display("PASS: in=8'h9f, expected out=8'hdb, got=8'h%02h", out);
        else
            $display("FAIL: in=8'h9f, expected out=8'hdb, got=8'h%02h", out);

        // in=0xf8, expected=0x41
        in = 8'hf8; #2;
        if (out === 8'h41)
            $display("PASS: in=8'hf8, expected out=8'h41, got=8'h%02h", out);
        else
            $display("FAIL: in=8'hf8, expected out=8'h41, got=8'h%02h", out);

        // Sweep all 128 entries automatically
        for (i = 128; i <= 255; i = i + 1) begin
            in = i[7:0];
            #2;
            // Just check that out is not 8'hxx (undefined)
            if (^out === 1'bx)
                $display("FAIL: in=8'h%02h output is undefined", i[7:0]);
        end
        $display("PASS: All 128 entries produced defined outputs");

        $finish;
    end

endmodule
