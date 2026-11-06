`timescale 1ns/1ps

module tb_aes_sbox;

    // DUT connections
    reg  [7:0] in;
    wire [7:0] out;

    // Clock (not used by combinational DUT, but required by testbench rules)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not used by combinational DUT, but required by testbench rules)
    reg rst;
    initial begin
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
    end

    // Instantiate DUT
    aes_sbox uut (
        .in  (in),
        .out (out)
    );

    // Task to apply a test vector and check result
    task apply_test;
        input [7:0] test_in;
        input [7:0] expected_out;
        input [127:0] description; // use as 16-char string placeholder
        reg [7:0] computed;
        begin
            in = test_in;
            #2; // let combinational logic settle
            computed = out;
            if (computed === expected_out) begin
                $display("PASS: in=0x%02h expected_out=0x%02h got=0x%02h", test_in, expected_out, computed);
            end else begin
                $display("FAIL: in=0x%02h expected_out=0x%02h got=0x%02h", test_in, expected_out, computed);
            end
        end
    endtask

    // Compute expected output using the same combinational logic
    function [7:0] compute_expected;
        input [7:0] i;
        begin
            compute_expected[7] = i[6] ^ i[0];
            compute_expected[6] = i[6] ^ i[1];
            compute_expected[5] = i[6] ^ i[2];
            compute_expected[4] = i[6] ^ i[3];
            compute_expected[3] = i[6] ^ i[4];
            compute_expected[2] = i[6] ^ i[5];
            compute_expected[1] = i[5] ^ i[0];
            compute_expected[0] = i[5] ^ i[1];
        end
    endfunction

    integer i;

    initial begin
        in = 8'h00;

        // Wait for reset to deassert
        wait(rst == 0);
        @(posedge clk);
        #1;

        // Test 1: all-zero input (edge case)
        // expected: out[7]=0^0=0, out[6]=0^0=0, ... all zeros
        in = 8'h00;
        #2;
        if (out === compute_expected(8'h00))
            $display("PASS: in=0x00 expected=0x%02h got=0x%02h", compute_expected(8'h00), out);
        else
            $display("FAIL: in=0x00 expected=0x%02h got=0x%02h", compute_expected(8'h00), out);

        // Test 2: all-ones input (edge case)
        in = 8'hff;
        #2;
        if (out === compute_expected(8'hff))
            $display("PASS: in=0xff expected=0x%02h got=0x%02h", compute_expected(8'hff), out);
        else
            $display("FAIL: in=0xff expected=0x%02h got=0x%02h", compute_expected(8'hff), out);

        // Test 3: sbox[8'h00] check against module-specific requirement (expected 8'h63 per AES spec)
        // But this module is NOT a true AES sbox LUT; it uses XOR logic.
        // We verify the module's own combinational output matches its own formula.
        // Per MODULE-SPECIFIC REQUIREMENTS: verify sbox[8'h00]=8'h63
        // Check if module actually outputs 8'h63 for input 0x00
        in = 8'h00;
        #2;
        if (out === 8'h63)
            $display("PASS: sbox[0x00]=0x63 (AES spec)");
        else
            $display("FAIL: sbox[0x00]: expected=0x63 got=0x%02h (note: module uses XOR not LUT)", out);

        // Test 4: sbox[8'h53] check against module-specific requirement (expected 8'hed)
        in = 8'h53;
        #2;
        if (out === 8'hed)
            $display("PASS: sbox[0x53]=0xed (AES spec)");
        else
            $display("FAIL: sbox[0x53]: expected=0xed got=0x%02h (note: module uses XOR not LUT)", out);

        // Test 5: sbox[8'hff] check against module-specific requirement (expected 8'h16)
        in = 8'hff;
        #2;
        if (out === 8'h16)
            $display("PASS: sbox[0xff]=0x16 (AES spec)");
        else
            $display("FAIL: sbox[0xff]: expected=0x16 got=0x%02h (note: module uses XOR not LUT)", out);

        // Test 6: in[7]=0, in[6]=1, others=0 (test routing for hi bit=0, bit6=1)
        in = 8'h40; // 0100_0000
        #2;
        if (out === compute_expected(8'h40))
            $display("PASS: in=0x40 expected=0x%02h got=0x%02h", compute_expected(8'h40), out);
        else
            $display("FAIL: in=0x40 expected=0x%02h got=0x%02h", compute_expected(8'h40), out);

        // Test 7: in=8'hAA (alternating bits)
        in = 8'hAA;
        #2;
        if (out === compute_expected(8'hAA))
            $display("PASS: in=0xAA expected=0x%02h got=0x%02h", compute_expected(8'hAA), out);
        else
            $display("FAIL: in=0xAA expected=0x%02h got=0x%02h", compute_expected(8'hAA), out);

        // Test 8: in=8'h55 (alternating bits, complement of 0xAA)
        in = 8'h55;
        #2;
        if (out === compute_expected(8'h55))
            $display("PASS: in=0x55 expected=0x%02h got=0x%02h", compute_expected(8'h55), out);
        else
            $display("FAIL: in=0x55 expected=0x%02h got=0x%02h", compute_expected(8'h55), out);

        // Test 9: in=8'h80 (only MSB set)
        in = 8'h80;
        #2;
        if (out === compute_expected(8'h80))
            $display("PASS: in=0x80 expected=0x%02h got=0x%02h", compute_expected(8'h80), out);
        else
            $display("FAIL: in=0x80 expected=0x%02h got=0x%02h", compute_expected(8'h80), out);

        // Test 10: in=8'h01 (only LSB set)
        in = 8'h01;
        #2;
        if (out === compute_expected(8'h01))
            $display("PASS: in=0x01 expected=0x%02h got=0x%02h", compute_expected(8'h01), out);
        else
            $display("FAIL: in=0x01 expected=0x%02h got=0x%02h", compute_expected(8'h01), out);

        // Test 11: Exhaustive sweep - all 256 input values vs formula
        begin : exhaustive
            integer fail_count;
            fail_count = 0;
            for (i = 0; i < 256; i = i + 1) begin
                in = i[7:0];
                #2;
                if (out !== compute_expected(i[7:0])) begin
                    $display("FAIL: exhaustive in=0x%02h expected=0x%02h got=0x%02h", i[7:0], compute_expected(i[7:0]), out);
                    fail_count = fail_count + 1;
                end
            end
            if (fail_count == 0)
                $display("PASS: exhaustive sweep all 256 inputs match combinational formula");
            else
                $display("FAIL: exhaustive sweep had %0d mismatches", fail_count);
        end

        #10;
        $finish;
    end

endmodule
