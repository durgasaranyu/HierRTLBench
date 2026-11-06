`timescale 1ns/1ps
// Testbench for aes_subbytes
module tb_aes_subbytes;

    // DUT connections
    reg  [127:0] state_in;
    wire [127:0] state_out;

    // Clock (not used by combinational DUT, but required by spec)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not used by combinational DUT, but required by spec)
    reg rst;
    integer i;

    // Instantiate DUT
    aes_subbytes uut (
        .state_in  (state_in),
        .state_out (state_out)
    );

    // Helper task: check a single byte output
    // The module applies S-box to each byte of state_in
    // We know from the module source:
    //   sbox[0x00] -> byte 0 (bits 7:0 of sbox[0]) = 0x63
    //   sbox[0x53] -> byte 0 (bits 7:0 of sbox[0x53]) = 0xed
    //   sbox[0xff] is not defined (truncated), but we check what we can.
    //
    // The sbox array is 32-bit wide. The module must extract 8-bit output per input byte.
    // Looking at sbox[0x00]=32'h63c6a563, the pattern suggests the S-box output byte
    // is bits [7:0] (LSB) = 0x63 for input 0x00.
    // For sbox[0x53]=32'hedc12ced, bits[7:0]=0xed.
    //
    // We'll test by applying known inputs and checking known byte outputs.

    // Expected S-box values (byte, from bits[7:0] of the 32-bit sbox entry):
    // input 0x00 -> 0x63
    // input 0x01 -> 0x7c
    // input 0x02 -> 0x77
    // input 0x03 -> 0x7b
    // input 0x08 -> 0x30
    // input 0x53 -> 0xed
    // input 0x0a -> 0x67
    // input 0x1b -> 0xaf (sbox[0x1b]=32'haf45eaaf -> bits[7:0]=0xaf)
    // input 0x1c -> 0x9c (sbox[0x1c]=32'h9c23bf9c -> bits[7:0]=0x9c)
    // input 0x50 -> 0x53 (sbox[0x50]=32'h53a6f553 -> bits[7:0]=0x53)

    // For all-zero state: each byte=0x00 -> output byte should be 0x63
    // state_out should be 128'h63636363_63636363_63636363_63636363

    // We test by setting state_in to have specific bytes and checking state_out

    reg [7:0] exp_byte;
    reg [7:0] got_byte;
    reg test_pass;

    integer pass_count;
    integer fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;
        state_in = 128'h0;
        rst = 1;

        // Hold reset for 5 rising edges
        repeat(5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // -------------------------------------------------------
        // Test 1: All-zero input
        // Each byte input is 0x00, expected output byte = 0x63
        // -------------------------------------------------------
        state_in = 128'h00000000_00000000_00000000_00000000;
        #2; // small delay for combinational settle
        begin
            test_pass = 1;
            // Check all 16 bytes
            for (i = 0; i < 16; i = i + 1) begin
                got_byte = state_out[i*8 +: 8];
                if (got_byte !== 8'h63) begin
                    test_pass = 0;
                end
            end
            if (test_pass) begin
                $display("PASS: All-zero input -> all 0x63 output");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: All-zero input -> expected all 0x63, got %h", state_out);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 2: Single byte 0x53 in position 0 (bits 7:0), rest 0x00
        // byte 0 should be 0xed, bytes 1..15 should be 0x63
        // -------------------------------------------------------
        state_in = 128'h00000000_00000000_00000000_00000053;
        #2;
        begin
            got_byte = state_out[7:0];
            exp_byte = 8'hed;
            if (got_byte === exp_byte) begin
                $display("PASS: state_in[7:0]=0x53 -> state_out[7:0]=0xed");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: state_in[7:0]=0x53 -> expected 0xed, got %h", got_byte);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 3: Single byte 0x01 in position 0, rest 0x00
        // sbox[0x01] bits[7:0] = 0x7c
        // -------------------------------------------------------
        state_in = 128'h00000000_00000000_00000000_00000001;
        #2;
        begin
            got_byte = state_out[7:0];
            exp_byte = 8'h7c;
            if (got_byte === exp_byte) begin
                $display("PASS: state_in[7:0]=0x01 -> state_out[7:0]=0x7c");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: state_in[7:0]=0x01 -> expected 0x7c, got %h", got_byte);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 4: Single byte 0x02 in position 0, rest 0x00
        // sbox[0x02] bits[7:0] = 0x77
        // -------------------------------------------------------
        state_in = 128'h00000000_00000000_00000000_00000002;
        #2;
        begin
            got_byte = state_out[7:0];
            exp_byte = 8'h77;
            if (got_byte === exp_byte) begin
                $display("PASS: state_in[7:0]=0x02 -> state_out[7:0]=0x77");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: state_in[7:0]=0x02 -> expected 0x77, got %h", got_byte);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 5: Single byte 0x03 in position 0, rest 0x00
        // sbox[0x03] bits[7:0] = 0x7b
        // -------------------------------------------------------
        state_in = 128'h00000000_00000000_00000000_00000003;
        #2;
        begin
            got_byte = state_out[7:0];
            exp_byte = 8'h7b;
            if (got_byte === exp_byte) begin
                $display("PASS: state_in[7:0]=0x03 -> state_out[7:0]=0x7b");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: state_in[7:0]=0x03 -> expected 0x7b, got %h", got_byte);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 6: Single byte 0x08 in position 0, rest 0x00
        // sbox[0x08] bits[7:0] = 0x30
        // -------------------------------------------------------
        state_in = 128'h00000000_00000000_00000000_00000008;
        #2;
        begin
            got_byte = state_out[7:0];
            exp_byte = 8'h30;
            if (got_byte === exp_byte) begin
                $display("PASS: state_in[7:0]=0x08 -> state_out[7:0]=0x30");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: state_in[7:0]=0x08 -> expected 0x30, got %h", got_byte);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 7: Multiple distinct bytes across state
        // state_in bytes: [0]=0x00, [1]=0x01, [2]=0x02, [3]=0x03
        //                 [4..15]=0x00
        // Expected: [0]=0x63, [1]=0x7c, [2]=0x77, [3]=0x7b, [4..15]=0x63
        // -------------------------------------------------------
        state_in = 128'h00000000_00000000_00000000_03020100;
        #2;
        begin
            test_pass = 1;
            if (state_out[7:0]   !== 8'h63) test_pass = 0;
            if (state_out[15:8]  !== 8'h7c) test_pass = 0;
            if (state_out[23:16] !== 8'h77) test_pass = 0;
            if (state_out[31:24] !== 8'h7b) test_pass = 0;
            // bytes 4..15 all 0x00 -> 0x63
            for (i = 4; i < 16; i = i + 1) begin
                if (state_out[i*8 +: 8] !== 8'h63) test_pass = 0;
            end
            if (test_pass) begin
                $display("PASS: Multi-byte test 0x00/01/02/03 -> 0x63/7c/77/7b");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Multi-byte test -> got %h", state_out);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 8: Byte 0x50 in position 0
        // sbox[0x50] = 32'h53a6f553, bits[7:0] = 0x53
        // -------------------------------------------------------
        state_in = 128'h00000000_00000000_00000000_00000050;
        #2;
        begin
            got_byte = state_out[7:0];
            exp_byte = 8'h53;
            if (got_byte === exp_byte) begin
                $display("PASS: state_in[7:0]=0x50 -> state_out[7:0]=0x53");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: state_in[7:0]=0x50 -> expected 0x53, got %h", got_byte);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 9: Byte 0x0a in position 0
        // sbox[0x0a] = 32'h67cea967, bits[7:0] = 0x67
        // -------------------------------------------------------
        state_in = 128'h00000000_00000000_00000000_0000000a;
        #2;
        begin
            got_byte = state_out[7:0];
            exp_byte = 8'h67;
            if (got_byte === exp_byte) begin
                $display("PASS: state_in[7:0]=0x0a -> state_out[7:0]=0x67");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: state_in[7:0]=0x0a -> expected 0x67, got %h", got_byte);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 10: Byte 0x53 in all 16 positions (edge case: same byte repeated)
        // Expected: all output bytes = 0xed
        // -------------------------------------------------------
        state_in = 128'h53535353_53535353_53535353_53535353;
        #2;
        begin
            test_pass = 1;
            for (i = 0; i < 16; i = i + 1) begin
                got_byte = state_out[i*8 +: 8];
                if (got_byte !== 8'hed) test_pass = 0;
            end
            if (test_pass) begin
                $display("PASS: All 0x53 input -> all 0xed output");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: All 0x53 input -> expected all 0xed, got %h", state_out);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 11: Byte 0x1b in position 0
        // sbox[0x1b] = 32'haf45eaaf, bits[7:0] = 0xaf
        // -------------------------------------------------------
        state_in = 128'h00000000_00000000_00000000_0000001b;
        #2;
        begin
            got_byte = state_out[7:0];
            exp_byte = 8'haf;
            if (got_byte === exp_byte) begin
                $display("PASS: state_in[7:0]=0x1b -> state_out[7:0]=0xaf");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: state_in[7:0]=0x1b -> expected 0xaf, got %h", got_byte);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 12: Byte 0x20 in position 0
        // sbox[0x20] = 32'hb775c2b7, bits[7:0] = 0xb7
        // -------------------------------------------------------
        state_in = 128'h00000000_00000000_00000000_00000020;
        #2;
        begin
            got_byte = state_out[7:0];
            exp_byte = 8'hb7;
            if (got_byte === exp_byte) begin
                $display("PASS: state_in[7:0]=0x20 -> state_out[7:0]=0xb7");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: state_in[7:0]=0x20 -> expected 0xb7, got %h", got_byte);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 13: Verify output is non-zero for non-trivial input
        // -------------------------------------------------------
        state_in = 128'h0f0e0d0c_
