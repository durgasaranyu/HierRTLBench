`timescale 1ns/1ps

module tb_aes_shiftrows;

    // DUT connections
    reg  [127:0] state_in;
    wire [127:0] state_out;

    // Clock and reset (not used by DUT but required by general requirements)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // DUT instantiation
    aes_shiftrows uut (
        .state_in  (state_in),
        .state_out (state_out)
    );

    // Task to compute expected ShiftRows output
    // AES ShiftRows (column-major order):
    // State bytes: [127:120]=b00, [119:112]=b10, [111:104]=b20, [103:96]=b30
    //              [95:88]=b01,   [87:80]=b11,   [79:72]=b21,   [71:64]=b31
    //              [63:56]=b02,   [55:48]=b12,   [47:40]=b22,   [39:32]=b32
    //              [31:24]=b03,   [23:16]=b13,   [15:8]=b23,    [7:0]=b33
    //
    // Row 0 (b00,b01,b02,b03): no shift
    // Row 1 (b10,b11,b12,b13): left shift by 1 -> b11,b12,b13,b10
    // Row 2 (b20,b21,b22,b23): left shift by 2 -> b22,b23,b20,b21
    // Row 3 (b30,b31,b32,b33): left shift by 3 -> b33,b30,b31,b32

    // Helper function - computed inline in tasks
    // We'll use a task with input and output

    reg [127:0] expected;
    reg [7:0] b00, b10, b20, b30;
    reg [7:0] b01, b11, b21, b31;
    reg [7:0] b02, b12, b22, b32;
    reg [7:0] b03, b13, b23, b33;

    task compute_expected;
        input [127:0] s;
        output [127:0] exp;
        reg [7:0] r00, r10, r20, r30;
        reg [7:0] r01, r11, r21, r31;
        reg [7:0] r02, r12, r22, r32;
        reg [7:0] r03, r13, r23, r33;
        begin
            // Extract bytes (column-major)
            r00 = s[127:120]; r10 = s[119:112]; r20 = s[111:104]; r30 = s[103:96];
            r01 = s[95:88];   r11 = s[87:80];   r21 = s[79:72];   r31 = s[71:64];
            r02 = s[63:56];   r12 = s[55:48];   r22 = s[47:40];   r32 = s[39:32];
            r03 = s[31:24];   r13 = s[23:16];   r23 = s[15:8];    r33 = s[7:0];

            // Row 0: no shift
            // Row 1: shift left by 1: b10->b11, b11->b12, b12->b13, b13->b10
            // Row 2: shift left by 2: b20->b22, b21->b23, b22->b20, b23->b21
            // Row 3: shift left by 3: b30->b33, b31->b30, b32->b31, b33->b32

            // Reconstruct column-major
            // col0: row0=r00, row1=r11, row2=r22, row3=r33
            // col1: row0=r01, row1=r12, row2=r23, row3=r30
            // col2: row0=r02, row1=r13, row2=r20, row3=r31
            // col3: row0=r03, row1=r10, row2=r21, row3=r32

            exp = {r00, r11, r22, r33,
                   r01, r12, r23, r30,
                   r02, r13, r20, r31,
                   r03, r10, r21, r32};
        end
    endtask

    integer i;
    reg test_pass;

    // Reset sequence
    initial begin
        rst = 1;
        state_in = 128'h0;
        repeat(5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // -------------------------------------------------------
        // Test 1: All zeros
        // -------------------------------------------------------
        state_in = 128'h00000000000000000000000000000000;
        #1;
        compute_expected(state_in, expected);
        if (state_out === expected)
            $display("PASS: All-zero input - state_out matches expected ShiftRows");
        else
            $display("FAIL: All-zero input - state_out=%h, expected=%h", state_out, expected);

        // -------------------------------------------------------
        // Test 2: All ones (0xFF)
        // -------------------------------------------------------
        state_in = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        #1;
        compute_expected(state_in, expected);
        if (state_out === expected)
            $display("PASS: All-ones input - state_out matches expected ShiftRows");
        else
            $display("FAIL: All-ones input - state_out=%h, expected=%h", state_out, expected);

        // -------------------------------------------------------
        // Test 3: Known AES vector - standard test
        // Input:  00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f (row-major)
        // In column-major (as used in aes_shiftrows):
        // col0=00,01,02,03 col1=04,05,06,07 col2=08,09,0a,0b col3=0c,0d,0e,0f
        // state_in[127:120]=00, [119:112]=01, [111:104]=02, [103:96]=03
        //         [95:88]=04,   [87:80]=05,   [79:72]=06,   [71:64]=07
        //         [63:56]=08,   [55:48]=09,   [47:40]=0a,   [39:32]=0b
        //         [31:24]=0c,   [23:16]=0d,   [15:8]=0e,    [7:0]=0f
        // -------------------------------------------------------
        state_in = 128'h00010203040506070809_0a0b0c0d0e0f;
        #1;
        compute_expected(state_in, expected);
        if (state_out === expected)
            $display("PASS: Sequential bytes input - state_out matches expected ShiftRows");
        else
            $display("FAIL: Sequential bytes input - state_out=%h, expected=%h", state_out, expected);

        // -------------------------------------------------------
        // Test 4: Verify row 0 unchanged
        // Use distinct non-zero bytes per row so we can verify row0 specifically
        // Row 0 bytes: AA, BB, CC, DD (at positions b00, b01, b02, b03)
        // Row 1 bytes: 11, 22, 33, 44
        // Row 2 bytes: 55, 66, 77, 88
        // Row 3 bytes: 99, AA, BB, CC
        // state_in in column-major:
        // col0: AA,11,55,99  col1: BB,22,66,AA  col2: CC,33,77,BB  col3: DD,44,88,CC
        // -------------------------------------------------------
        state_in = {8'hAA, 8'h11, 8'h55, 8'h99,
                    8'hBB, 8'h22, 8'h66, 8'hAA,
                    8'hCC, 8'h33, 8'h77, 8'hBB,
                    8'hDD, 8'h44, 8'h88, 8'hCC};
        #1;
        // Row 0 should be unchanged: AA, BB, CC, DD
        // In output: state_out[127:120]=AA, state_out[95:88]=BB, state_out[63:56]=CC, state_out[31:24]=DD
        compute_expected(state_in, expected);
        if (state_out[127:120] === 8'hAA && state_out[95:88] === 8'hBB &&
            state_out[63:56] === 8'hCC && state_out[31:24] === 8'hDD)
            $display("PASS: Row 0 is unchanged after ShiftRows");
        else
            $display("FAIL: Row 0 changed - got %h %h %h %h, expected AA BB CC DD",
                     state_out[127:120], state_out[95:88], state_out[63:56], state_out[31:24]);

        // -------------------------------------------------------
        // Test 5: Verify row 1 shifts left by 1
        // Row 1 bytes: b10=11, b11=22, b12=33, b13=44
        // After shift: b11=22 at col0, b12=33 at col1, b13=44 at col2, b10=11 at col3
        // In output: state_out[119:112]=22, state_out[87:80]=33, state_out[55:48]=44, state_out[23:16]=11
        // -------------------------------------------------------
        if (state_out[119:112] === 8'h22 && state_out[87:80] === 8'h33 &&
            state_out[55:48] === 8'h44 && state_out[23:16] === 8'h11)
            $display("PASS: Row 1 shifted left by 1 correctly");
        else
            $display("FAIL: Row 1 shift incorrect - got %h %h %h %h, expected 22 33 44 11",
                     state_out[119:112], state_out[87:80], state_out[55:48], state_out[23:16]);

        // -------------------------------------------------------
        // Test 6: Verify row 2 shifts left by 2 (same state_in)
        // Row 2 bytes: b20=55, b21=66, b22=77, b23=88
        // After shift: b22=77 at col0, b23=88 at col1, b20=55 at col2, b21=66 at col3
        // In output: state_out[111:104]=77, state_out[79:72]=88, state_out[47:40]=55, state_out[15:8]=66
        // -------------------------------------------------------
        if (state_out[111:104] === 8'h77 && state_out[79:72] === 8'h88 &&
            state_out[47:40] === 8'h55 && state_out[15:8] === 8'h66)
            $display("PASS: Row 2 shifted left by 2 correctly");
        else
            $display("FAIL: Row 2 shift incorrect - got %h %h %h %h, expected 77 88 55 66",
                     state_out[111:104], state_out[79:72], state_out[47:40], state_out[15:8]);

        // -------------------------------------------------------
        // Test 7: Verify row 3 shifts left by 3 (same state_in)
        // Row 3 bytes: b30=99, b31=AA, b32=BB, b33=CC
        // After shift: b33=CC at col0, b30=99 at col1, b31=AA at col2, b32=BB at col3
        // In output: state_out[103:96]=CC, state_out[71:64]=99, state_out[39:32]=AA, state_out[7:0]=BB
        // -------------------------------------------------------
        if (state_out[103:96] === 8'hCC && state_out[71:64] === 8'h99 &&
            state_out[39:32] === 8'hAA && state_out[7:0] === 8'hBB)
            $display("PASS: Row 3 shifted left by 3 correctly");
        else
            $display("FAIL: Row 3 shift incorrect - got %h %h %h %h, expected CC 99 AA BB",
                     state_out[103:96], state_out[71:64], state_out[39:32], state_out[7:0]);

        // -------------------------------------------------------
        // Test 8: Known AES ShiftRows intermediate value
        // NIST FIPS 197 example, after SubBytes the state is:
        // d4 e0 b8 1e  (row0)
        // 27 bf b4 41  (row1)
        // 11 98 5d 52  (row2)
        // ae f1 e5 30  (row3)
        // In column-major for state_in:
        // col0: d4,27,11,ae  col1: e0,bf,98,f1  col2: b8,b4,5d,e5  col3: 1e,41,52,30
        // After ShiftRows:
        // row0: d4,e0,b8,1e (unchanged)
        // row1: bf,b4,41,27 (left 1)
        // row2: 5d,52,11,98 (left 2)  -- wait: b20=11,b21=98,b22=5d,b23=52 -> 5d,52,11,98
        // row3: 30,ae,f1,e5 (left 3)  -- b30=ae,b31=f1,b32=e5,b33=30 -> 30,ae,f1,e5
        // Output col-major:
        // col0: d4,bf,5d,30  col1: e0,b4,52,ae  col2: b8,41,11,f1  col3: 1e,27,98,e5
        // -------------------------------------------------------
        state_in = {8'hd4, 8'h27, 8'h11, 8'hae,
                    8'he0, 8'hbf, 8'h98, 8'hf1,
                    8'hb8, 8'hb4, 8'h5d, 8'he5,
                    8'h1e, 8'h41, 8'h52, 8'h30};
        #1;
        // Expected output col-major:
        // col0: d4,bf,5d,30  col1: e0,b4,52,ae  col2: b8,41,11,f1  col3: 1e,27,98,e5
        expected = {8'hd4, 8'hbf, 8'h5d, 8'h30,
                    8'he0, 8'hb4, 8'h52, 8'hae,
                    8'hb8, 8'h41, 8'h11, 8'hf1,
                    8'h1e, 8'h27, 8'h98, 8'he5};
        if (state_out === expected)
            $display("PASS: NIST F
