`timescale 1ns/1ps

module tb_aes_shiftrows;

    // DUT connections
    reg  [127:0] state_in;
    wire [127:0] state_out;

    // Instantiate DUT
    aes_shiftrows uut (
        .state_in  (state_in),
        .state_out (state_out)
    );

    // Clock (not used by combinational DUT, but required by rules)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not used by combinational DUT, but required by rules)
    reg rst;
    integer i;

    // Helper task: check a single byte of state_out
    // We'll do manual checks inline

    // AES ShiftRows reference implementation in Verilog task
    // Column-major ordering:
    // state[127:120] = col0, row0
    // state[119:112] = col0, row1
    // state[111:104] = col0, row2
    // state[103:96]  = col0, row3
    // state[95:88]   = col1, row0
    // state[87:80]   = col1, row1
    // state[79:72]   = col1, row2
    // state[71:64]   = col1, row3
    // state[63:56]   = col2, row0
    // state[55:48]   = col2, row1
    // state[47:40]   = col2, row2
    // state[39:32]   = col2, row3
    // state[31:24]   = col3, row0
    // state[23:16]   = col3, row1
    // state[15:8]    = col3, row2
    // state[7:0]     = col3, row3
    //
    // ShiftRows:
    // row0: col0,col1,col2,col3 -> col0,col1,col2,col3 (no shift)
    // row1: col0,col1,col2,col3 -> col1,col2,col3,col0 (left shift 1)
    // row2: col0,col1,col2,col3 -> col2,col3,col0,col1 (left shift 2)
    // row3: col0,col1,col2,col3 -> col3,col0,col1,col2 (left shift 3)

    function [127:0] ref_shiftrows;
        input [127:0] s;
        reg [7:0] r0c0, r0c1, r0c2, r0c3;
        reg [7:0] r1c0, r1c1, r1c2, r1c3;
        reg [7:0] r2c0, r2c1, r2c2, r2c3;
        reg [7:0] r3c0, r3c1, r3c2, r3c3;
        reg [127:0] out;
        begin
            // Extract bytes
            r0c0 = s[127:120]; r1c0 = s[119:112]; r2c0 = s[111:104]; r3c0 = s[103:96];
            r0c1 = s[95:88];   r1c1 = s[87:80];   r2c1 = s[79:72];   r3c1 = s[71:64];
            r0c2 = s[63:56];   r1c2 = s[55:48];   r2c2 = s[47:40];   r3c2 = s[39:32];
            r0c3 = s[31:24];   r1c3 = s[23:16];   r2c3 = s[15:8];    r3c3 = s[7:0];

            // Row0: no shift
            // Row1: left shift 1 -> r1c1, r1c2, r1c3, r1c0
            // Row2: left shift 2 -> r2c2, r2c3, r2c0, r2c1
            // Row3: left shift 3 -> r3c3, r3c0, r3c1, r3c2

            out[127:120] = r0c0; out[95:88]  = r0c1; out[63:56] = r0c2; out[31:24] = r0c3;
            out[119:112] = r1c1; out[87:80]  = r1c2; out[55:48] = r1c3; out[23:16] = r1c0;
            out[111:104] = r2c2; out[79:72]  = r2c3; out[47:40] = r2c0; out[15:8]  = r2c1;
            out[103:96]  = r3c3; out[71:64]  = r3c0; out[39:32] = r3c1; out[7:0]   = r3c2;

            ref_shiftrows = out;
        end
    endfunction

    reg [127:0] expected;
    integer pass_count, fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst = 1;

        // Assert reset for 5 rising edges
        repeat (5) @(posedge clk);
        rst = 0;

        // Wait a little after reset
        @(posedge clk);
        #1;

        // -------------------------------------------------------
        // Test 1: All zeros
        // -------------------------------------------------------
        state_in = 128'h00000000000000000000000000000000;
        #10;
        expected = ref_shiftrows(state_in);
        if (state_out === expected) begin
            $display("PASS: Test1 all-zeros input");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test1 all-zeros input. Got %h, Expected %h", state_out, expected);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 2: All ones (all 0xFF)
        // -------------------------------------------------------
        state_in = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        #10;
        expected = ref_shiftrows(state_in);
        if (state_out === expected) begin
            $display("PASS: Test2 all-ones input");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test2 all-ones input. Got %h, Expected %h", state_out, expected);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 3: Row0 unchanged check
        // Each byte in row0 is distinct, other rows are zero
        // row0: col0=0x01, col1=0x02, col2=0x03, col3=0x04
        // row1,row2,row3 = 0x00
        // state: {r0c0,r1c0,r2c0,r3c0, r0c1,r1c1,r2c1,r3c1, r0c2,r1c2,r2c2,r3c2, r0c3,r1c3,r2c3,r3c3}
        //       = {01,00,00,00, 02,00,00,00, 03,00,00,00, 04,00,00,00}
        // -------------------------------------------------------
        state_in = {8'h01, 8'h00, 8'h00, 8'h00,
                    8'h02, 8'h00, 8'h00, 8'h00,
                    8'h03, 8'h00, 8'h00, 8'h00,
                    8'h04, 8'h00, 8'h00, 8'h00};
        #10;
        expected = ref_shiftrows(state_in);
        if (state_out === expected) begin
            $display("PASS: Test3 row0-unchanged check");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test3 row0-unchanged check. Got %h, Expected %h", state_out, expected);
            fail_count = fail_count + 1;
        end

        // Verify row0 is indeed unchanged
        if (state_out[127:120] === 8'h01 && state_out[95:88] === 8'h02 &&
            state_out[63:56] === 8'h03 && state_out[31:24] === 8'h04) begin
            $display("PASS: Test3a row0 bytes unchanged");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test3a row0 bytes changed. r0c0=%h r0c1=%h r0c2=%h r0c3=%h",
                     state_out[127:120], state_out[95:88], state_out[63:56], state_out[31:24]);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 4: Row1 left-shift-by-1 check
        // row1: col0=0xAA, col1=0xBB, col2=0xCC, col3=0xDD
        // row0,row2,row3 = 0x00
        // After shift: row1 in output: col0=BB, col1=CC, col2=DD, col3=AA
        // -------------------------------------------------------
        state_in = {8'h00, 8'hAA, 8'h00, 8'h00,
                    8'h00, 8'hBB, 8'h00, 8'h00,
                    8'h00, 8'hCC, 8'h00, 8'h00,
                    8'h00, 8'hDD, 8'h00, 8'h00};
        #10;
        expected = ref_shiftrows(state_in);
        if (state_out === expected) begin
            $display("PASS: Test4 row1-left-shift-1 check");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test4 row1-left-shift-1 check. Got %h, Expected %h", state_out, expected);
            fail_count = fail_count + 1;
        end

        // Verify row1 shift: output col0=BB, col1=CC, col2=DD, col3=AA
        if (state_out[119:112] === 8'hBB && state_out[87:80] === 8'hCC &&
            state_out[55:48]   === 8'hDD && state_out[23:16] === 8'hAA) begin
            $display("PASS: Test4a row1 correctly shifted left by 1");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test4a row1 shift wrong. r1c0=%h r1c1=%h r1c2=%h r1c3=%h",
                     state_out[119:112], state_out[87:80], state_out[55:48], state_out[23:16]);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 5: Row2 left-shift-by-2 check
        // row2: col0=0x11, col1=0x22, col2=0x33, col3=0x44
        // After shift: row2 output: col0=33, col1=44, col2=11, col3=22
        // -------------------------------------------------------
        state_in = {8'h00, 8'h00, 8'h11, 8'h00,
                    8'h00, 8'h00, 8'h22, 8'h00,
                    8'h00, 8'h00, 8'h33, 8'h00,
                    8'h00, 8'h00, 8'h44, 8'h00};
        #10;
        expected = ref_shiftrows(state_in);
        if (state_out === expected) begin
            $display("PASS: Test5 row2-left-shift-2 check");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test5 row2-left-shift-2 check. Got %h, Expected %h", state_out, expected);
            fail_count = fail_count + 1;
        end

        // Verify row2 shift
        if (state_out[111:104] === 8'h33 && state_out[79:72] === 8'h44 &&
            state_out[47:40]   === 8'h11 && state_out[15:8]  === 8'h22) begin
            $display("PASS: Test5a row2 correctly shifted left by 2");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test5a row2 shift wrong. r2c0=%h r2c1=%h r2c2=%h r2c3=%h",
                     state_out[111:104], state_out[79:72], state_out[47:40], state_out[15:8]);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 6: Row3 left-shift-by-3 check
        // row3: col0=0xA1, col1=0xB2, col2=0xC3, col3=0xD4
        // After shift: row3 output: col0=D4, col1=A1, col2=B2, col3=C3
        // -------------------------------------------------------
        state_in = {8'h00, 8'h00, 8'h00, 8'hA1,
                    8'h00, 8'h00, 8'h00, 8'hB2,
                    8'h00, 8'h00, 8'h00, 8'hC3,
                    8'h00, 8'h00, 8'h00, 8'hD4};
        #10;
        expected = ref_shiftrows(state_in);
        if (state_out === expected) begin
            $display("PASS: Test6 row3-left-shift-3 check");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test6 row3-left-shift-3 check. Got %h, Expected %h", state_out, expected);
            fail_count = fail_count + 1;
        end

        // Verify row3 shift
        if (state_out[103:96] === 8'hD4 && state_out[71:64] === 8'hA1 &&
            state_out[39:32]  === 8'hB2 && state_out[7:0]   === 8'hC3) begin
            $display("PASS: Test6a row3 correctly shifted left by 3");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test6a row3 shift wrong. r3c0=%h r3c1=%h r3c2=%h r3c3=%h",
                     state_out[103:96], state_out[71:64], state_out[39:32], state_out[7:0]);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 7: Known AES ShiftRows example
        // Input state (FIPS 197 intermediate):
        // d4 e0 b8
