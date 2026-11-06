`timescale 1ns/1ps

module tb_aes_shiftrows;

    // DUT ports
    reg  [127:0] state_in;
    wire [127:0] state_out;

    // Instantiate DUT
    aes_shiftrows uut (
        .state_in  (state_in),
        .state_out (state_out)
    );

    // Clock (not strictly needed for combinational, but required by spec)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not strictly needed for combinational, but required by spec)
    reg rst;
    integer i;

    // Helper task: check output vs expected
    task check;
        input [127:0] expected;
        input [127:0] got;
        input [255:0] desc; // 32 chars
        begin
            if (got === expected)
                $display("PASS: %s | got=%h", desc, got);
            else
                $display("FAIL: %s | expected=%h got=%h", desc, expected, got);
        end
    endtask

    // -------------------------------------------------------------------------
    // Reference model for correct AES ShiftRows
    // State layout (column-major, big-endian):
    //   byte indices in 128-bit vector (127 = MSB):
    //   col0: bytes 15,14,13,12  (bits 127:96)
    //   col1: bytes 11,10, 9, 8  (bits  95:64)
    //   col2: bytes  7, 6, 5, 4  (bits  63:32)
    //   col3: bytes  3, 2, 1, 0  (bits  31: 0)
    //
    //   Byte extraction: byte[k] = state[127-8*k -: 8]
    //
    //   Row r, col c -> byte index = 4*c + r
    //   Row 0: cols 0,1,2,3 -> bytes 0,4,8,12
    //   Row 1: cols 0,1,2,3 -> bytes 1,5,9,13
    //   Row 2: cols 0,1,2,3 -> bytes 2,6,10,14
    //   Row 3: cols 0,1,2,3 -> bytes 3,7,11,15
    //
    //   ShiftRows:
    //     row0: no shift       -> (0,4,8,12)
    //     row1: left-1         -> (5,9,13,1)
    //     row2: left-2         -> (10,14,2,6)
    //     row3: left-3         -> (15,3,7,11)
    //
    //   Output byte at (row r, col c):
    //     row0 col c: byte[4*c + 0]
    //     row1 col c: byte[4*((c+1)%4) + 1]
    //     row2 col c: byte[4*((c+2)%4) + 2]
    //     row3 col c: byte[4*((c+3)%4) + 3]
    // -------------------------------------------------------------------------

    function [7:0] get_byte;
        input [127:0] s;
        input integer idx; // byte 0..15, byte 0 = bits 7:0
        begin
            get_byte = s[idx*8 +: 8];
        end
    endfunction

    function [127:0] ref_shiftrows;
        input [127:0] s;
        reg [127:0] out;
        integer r, c, src_col;
        integer out_byte_idx;
        begin
            out = 128'b0;
            // row 0: no shift
            for (c = 0; c < 4; c = c + 1) begin
                out_byte_idx = 4*c + 0;
                out[out_byte_idx*8 +: 8] = get_byte(s, 4*c + 0);
            end
            // row 1: left shift by 1
            for (c = 0; c < 4; c = c + 1) begin
                out_byte_idx = 4*c + 1;
                src_col = (c + 1) % 4;
                out[out_byte_idx*8 +: 8] = get_byte(s, 4*src_col + 1);
            end
            // row 2: left shift by 2
            for (c = 0; c < 4; c = c + 1) begin
                out_byte_idx = 4*c + 2;
                src_col = (c + 2) % 4;
                out[out_byte_idx*8 +: 8] = get_byte(s, 4*src_col + 2);
            end
            // row 3: left shift by 3
            for (c = 0; c < 4; c = c + 1) begin
                out_byte_idx = 4*c + 3;
                src_col = (c + 3) % 4;
                out[out_byte_idx*8 +: 8] = get_byte(s, 4*src_col + 3);
            end
            ref_shiftrows = out;
        end
    endfunction

    reg [127:0] expected;

    initial begin
        // Apply reset for 5 clock rising edges
        rst = 1;
        state_in = 128'h0;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // ----------------------------------------------------------------
        // Test 1: All zeros
        // ----------------------------------------------------------------
        state_in = 128'h0000_0000_0000_0000_0000_0000_0000_0000;
        #2;
        expected = ref_shiftrows(state_in);
        // Row 0 unchanged: all zeros still all zeros
        // All rows all zeros -> output all zeros
        check(expected, state_out, "T1: All-zero input      ");

        // ----------------------------------------------------------------
        // Test 2: All ones
        // ----------------------------------------------------------------
        state_in = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        #2;
        expected = ref_shiftrows(state_in);
        check(expected, state_out, "T2: All-ones input      ");

        // ----------------------------------------------------------------
        // Test 3: Row 0 unchanged verification
        // Use a state where only row0 bytes are non-zero
        // Row0 bytes: byte0, byte4, byte8, byte12 (bits 7:0, 39:32, 71:64, 103:96)
        // ----------------------------------------------------------------
        state_in = 128'h0;
        // Set byte12=0xAA, byte8=0xBB, byte4=0xCC, byte0=0xDD (row0)
        state_in[103:96] = 8'hAA; // byte12, col3 row0
        state_in[71:64]  = 8'hBB; // byte8,  col2 row0
        state_in[39:32]  = 8'hCC; // byte4,  col1 row0
        state_in[7:0]    = 8'hDD; // byte0,  col0 row0
        #2;
        expected = ref_shiftrows(state_in);
        // Row0 is unchanged: out_byte0=DD, out_byte4=CC, out_byte8=BB, out_byte12=AA
        check(expected, state_out, "T3: Row0 unchanged      ");

        // Additional check: row0 bytes explicitly
        if (state_out[7:0]    === 8'hDD &&
            state_out[39:32]  === 8'hCC &&
            state_out[71:64]  === 8'hBB &&
            state_out[103:96] === 8'hAA)
            $display("PASS: T3b: Row0 bytes explicit ");
        else
            $display("FAIL: T3b: Row0 bytes explicit | out=%h", state_out);

        // ----------------------------------------------------------------
        // Test 4: Row 1 left-shift by 1 verification
        // Set only row1 bytes non-zero
        // Row1 bytes: byte1(col0), byte5(col1), byte9(col2), byte13(col3)
        // After shift-left-1: out_row1_col0=byte5, out_row1_col1=byte9,
        //                     out_row1_col2=byte13, out_row1_col3=byte1
        // ----------------------------------------------------------------
        state_in = 128'h0;
        state_in[15:8]   = 8'h11; // byte1,  col0 row1
        state_in[47:40]  = 8'h22; // byte5,  col1 row1
        state_in[79:72]  = 8'h33; // byte9,  col2 row1
        state_in[111:104]= 8'h44; // byte13, col3 row1
        #2;
        expected = ref_shiftrows(state_in);
        check(expected, state_out, "T4: Row1 shift-left-1   ");

        // Explicit: out_row1: col0=22, col1=33, col2=44, col3=11
        if (state_out[15:8]    === 8'h22 &&
            state_out[47:40]   === 8'h33 &&
            state_out[79:72]   === 8'h44 &&
            state_out[111:104] === 8'h11)
            $display("PASS: T4b: Row1 explicit shift ");
        else
            $display("FAIL: T4b: Row1 explicit shift | out=%h", state_out);

        // ----------------------------------------------------------------
        // Test 5: Row 2 left-shift by 2 verification
        // Row2 bytes: byte2(col0), byte6(col1), byte10(col2), byte14(col3)
        // After shift-left-2: out_row2_col0=byte10, out_row2_col1=byte14,
        //                     out_row2_col2=byte2,  out_row2_col3=byte6
        // ----------------------------------------------------------------
        state_in = 128'h0;
        state_in[23:16]  = 8'hAA; // byte2,  col0 row2
        state_in[55:48]  = 8'hBB; // byte6,  col1 row2
        state_in[87:80]  = 8'hCC; // byte10, col2 row2
        state_in[119:112]= 8'hDD; // byte14, col3 row2
        #2;
        expected = ref_shiftrows(state_in);
        check(expected, state_out, "T5: Row2 shift-left-2   ");

        // Explicit
        if (state_out[23:16]   === 8'hCC &&
            state_out[55:48]   === 8'hDD &&
            state_out[87:80]   === 8'hAA &&
            state_out[119:112] === 8'hBB)
            $display("PASS: T5b: Row2 explicit shift ");
        else
            $display("FAIL: T5b: Row2 explicit shift | out=%h", state_out);

        // ----------------------------------------------------------------
        // Test 6: Row 3 left-shift by 3 verification
        // Row3 bytes: byte3(col0), byte7(col1), byte11(col2), byte15(col3)
        // After shift-left-3: out_row3_col0=byte15, out_row3_col1=byte3,
        //                     out_row3_col2=byte7,  out_row3_col3=byte11
        // ----------------------------------------------------------------
        state_in = 128'h0;
        state_in[31:24]  = 8'h01; // byte3,  col0 row3
        state_in[63:56]  = 8'h02; // byte7,  col1 row3
        state_in[95:88]  = 8'h03; // byte11, col2 row3
        state_in[127:120]= 8'h04; // byte15, col3 row3
        #2;
        expected = ref_shiftrows(state_in);
        check(expected, state_out, "T6: Row3 shift-left-3   ");

        // Explicit
        if (state_out[31:24]  === 8'h04 &&
            state_out[63:56]  === 8'h01 &&
            state_out[95:88]  === 8'h02 &&
            state_out[127:120]=== 8'h03)
            $display("PASS: T6b: Row3 explicit shift ");
        else
            $display("FAIL: T6b: Row3 explicit shift | out=%h", state_out);

        // ----------------------------------------------------------------
        // Test 7: Known AES ShiftRows test vector
        // FIPS-197 example: after SubBytes, before ShiftRows:
        // d4 e0 b8 1e  27 bf b4 41  11 98 5d 52  ae f1 e5 30
        // Arranged as column-major 128-bit:
        // byte0=d4, byte1=e0, byte2=b8, byte3=1e (col0)
        // byte4=27, byte5=bf, byte6=b4, byte7=41 (col1)
        // byte8=11, byte9=98, byte10=5d, byte11=52 (col2)
        // byte12=ae, byte13=f1, byte14=e5, byte15=30 (col3)
        // ----------------------------------------------------------------
        state_in = {8'h30, 8'he5, 8'hf1, 8'hae,   // byte15..12 (col3) at bits 127:96
                    8'h52, 8'h5d, 8'h98, 8'h11,   // byte11..8  (col2) at bits  95:64
                    8'h41, 8'hb4, 8'hbf, 8'h27,   // byte7..4   (col1) at bits  63:32
                    8'h1e, 8'hb8, 8'he0, 8'hd4};  // byte3..0   (col0) at bits  31: 0
        #2;
        expected = ref_shiftrows(state_in);
        check(expected, state_out, "T7: FIPS-197 example    ");

        // The expected output after ShiftRows (FIPS-197):
        // d4 bf 5d 30  e0 b4 52 ae  b8 41 11 f1  1e 27 98 e5
        // As 128-bit big-endian column-major:
        // col0: d4,bf,5d,30 -> bits 31:0 = 30,5d,bf,d4... wait let me be careful.
        // byte0=d4(col0r0),byte1=bf(col0r1),byte2=5d(col0r2),byte3=30(col0r3)
        // byte4=e0,byte5=b4,byte6=52,byte7=ae
        // byte8=b8,byte9=41,byte10=11,byte11=f1
        // byte12=1e,byte13=27,byte14=98,byte15=e5
        begin
            reg [127:0] fips_expected;
            fips_expected = {8'he5, 8'h98, 8'h27, 8
