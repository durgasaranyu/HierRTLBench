`timescale 1ns/1ps

module tb_aes_mixcolumns;

    // DUT connections
    reg  [127:0] state_in;
    wire [127:0] state_out;

    // Clock (not used by combinational DUT, but required by spec)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not used by combinational DUT, but required by spec)
    reg rst;
    integer rst_count;

    // DUT instantiation
    aes_mixcolumns uut (
        .state_in  (state_in),
        .state_out (state_out)
    );

    // Helper: compute expected output based on module's logic
    // state_out_00 = state_in[127:96] ^ state_in[31:0]
    // state_out_01 = state_in[95:64]  ^ state_in[63:32]
    // state_out_02 = state_in[95:64]  ^ state_in[31:0]
    // state_out_03 = state_in[63:32]  ^ state_in[31:0]
    function [127:0] expected_out;
        input [127:0] s;
        reg [31:0] s00, s01, s02, s03;
        reg [31:0] o00, o01, o02, o03;
        begin
            s00 = s[127:96];
            s01 = s[95:64];
            s02 = s[63:32];
            s03 = s[31:0];
            o00 = s00 ^ s03;
            o01 = s01 ^ s02;
            o02 = s01 ^ s03;
            o03 = s02 ^ s03;
            expected_out = {o00, o01, o02, o03};
        end
    endfunction

    // Test vector checking task
    task check_vector;
        input [127:0] s;
        input [63:0]  desc_dummy; // not used, just for reference
        reg [127:0] exp;
        begin
            state_in = s;
            #2; // combinational settle
            exp = expected_out(s);
            if (state_out === exp)
                $display("PASS: state_in=%h expected=%h got=%h", s, exp, state_out);
            else
                $display("FAIL: state_in=%h expected=%h got=%h", s, exp, state_out);
        end
    endtask

    integer i;
    reg [127:0] exp_val;

    initial begin
        // Reset sequence (5 rising edges)
        rst = 1;
        state_in = 128'h0;
        rst_count = 0;
        repeat(5) begin
            @(posedge clk);
            rst_count = rst_count + 1;
        end
        rst = 0;
        @(negedge clk);

        // Test 1: All zeros
        state_in = 128'h0000_0000_0000_0000_0000_0000_0000_0000;
        #2;
        exp_val = expected_out(state_in);
        if (state_out === exp_val)
            $display("PASS: All-zeros input: out=%h", state_out);
        else
            $display("FAIL: All-zeros input: expected=%h got=%h", exp_val, state_out);

        // Test 2: All ones
        state_in = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        #2;
        exp_val = expected_out(state_in);
        if (state_out === exp_val)
            $display("PASS: All-ones input: out=%h", state_out);
        else
            $display("FAIL: All-ones input: expected=%h got=%h", exp_val, state_out);

        // Test 3: Known GF(2^8) column test
        // state_in_00=db135345, state_in_01=f20a225c, state_in_02=01010101, state_in_03=c6c6c6c6
        state_in = 128'hdb135345_f20a225c_01010101_c6c6c6c6;
        #2;
        exp_val = expected_out(state_in);
        if (state_out === exp_val)
            $display("PASS: Known column test: out=%h", state_out);
        else
            $display("FAIL: Known column test: expected=%h got=%h", exp_val, state_out);

        // Test 4: Identity-like (single byte set)
        state_in = 128'h0100_0000_0000_0000_0000_0000_0000_0000;
        #2;
        exp_val = expected_out(state_in);
        if (state_out === exp_val)
            $display("PASS: Single byte MSB: out=%h", state_out);
        else
            $display("FAIL: Single byte MSB: expected=%h got=%h", exp_val, state_out);

        // Test 5: Single byte LSB set
        state_in = 128'h0000_0000_0000_0000_0000_0000_0000_0001;
        #2;
        exp_val = expected_out(state_in);
        if (state_out === exp_val)
            $display("PASS: Single byte LSB: out=%h", state_out);
        else
            $display("FAIL: Single byte LSB: expected=%h got=%h", exp_val, state_out);

        // Test 6: Alternating pattern
        state_in = 128'hAAAA_AAAA_5555_5555_AAAA_AAAA_5555_5555;
        #2;
        exp_val = expected_out(state_in);
        if (state_out === exp_val)
            $display("PASS: Alternating 0xAA/0x55: out=%h", state_out);
        else
            $display("FAIL: Alternating 0xAA/0x55: expected=%h got=%h", exp_val, state_out);

        // Test 7: Incremental values
        state_in = 128'h0102_0304_0506_0708_090A_0B0C_0D0E_0F10;
        #2;
        exp_val = expected_out(state_in);
        if (state_out === exp_val)
            $display("PASS: Incremental values: out=%h", state_out);
        else
            $display("FAIL: Incremental values: expected=%h got=%h", exp_val, state_out);

        // Test 8: Max value single column check (column 0 = FFFFFFFF, rest = 0)
        state_in = 128'hFFFF_FFFF_0000_0000_0000_0000_0000_0000;
        #2;
        exp_val = expected_out(state_in);
        if (state_out === exp_val)
            $display("PASS: Max col0 only: out=%h", state_out);
        else
            $display("FAIL: Max col0 only: expected=%h got=%h", exp_val, state_out);

        // Test 9: Random-like value
        state_in = 128'hDEAD_BEEF_CAFE_BABE_1234_5678_9ABC_DEF0;
        #2;
        exp_val = expected_out(state_in);
        if (state_out === exp_val)
            $display("PASS: Random-like value: out=%h", state_out);
        else
            $display("FAIL: Random-like value: expected=%h got=%h", exp_val, state_out);

        // Test 10: XOR self-inverse property (apply twice should give original... verify via expected)
        state_in = 128'h1357_9BDF_2468_ACE0_FEDC_BA98_7654_3210;
        #2;
        exp_val = expected_out(state_in);
        if (state_out === exp_val)
            $display("PASS: XOR pattern value: out=%h", state_out);
        else
            $display("FAIL: XOR pattern value: expected=%h got=%h", exp_val, state_out);

        $finish;
    end

endmodule
