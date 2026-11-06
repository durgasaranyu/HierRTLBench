`timescale 1ns/1ps

module tb_aes_sbox_hi;

    // DUT connections
    reg  [7:0] in;
    wire [7:0] out;

    // Clock (not needed by combinational DUT, but required by general rules)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (required by general rules; not connected to combinational DUT)
    reg rst;
    integer i;
    integer pass_count;
    integer fail_count;

    // Instantiate DUT
    aes_sbox_hi uut (
        .in  (in),
        .out (out)
    );

    // Task to check a single value
    task check;
        input [7:0] t_in;
        input [7:0] expected;
        input [63:0] desc_lo;   // we'll just use $display directly in inline calls
        begin
            in = t_in;
            #2; // small delay for combinational logic to settle
            if (out === expected) begin
                pass_count = pass_count + 1;
            end else begin
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst = 1;

        // Hold reset for 5 rising edges
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        // Small settling time after reset
        #3;

        // -------------------------------------------------------
        // Test 1: in = 8'h80 -> expected 8'hcd
        // -------------------------------------------------------
        in = 8'h80;
        #5;
        if (out === 8'hcd)
            $display("PASS: in=0x80, out=0x%02h (expected 0xcd)", out);
        else
            $display("FAIL: in=0x80, out=0x%02h (expected 0xcd)", out);

        // -------------------------------------------------------
        // Test 2: in = 8'hff -> expected 8'h16  (upper boundary)
        // -------------------------------------------------------
        in = 8'hff;
        #5;
        if (out === 8'h16)
            $display("PASS: in=0xff, out=0x%02h (expected 0x16)", out);
        else
            $display("FAIL: in=0xff, out=0x%02h (expected 0x16)", out);

        // -------------------------------------------------------
        // Test 3: in = 8'hec -> expected 8'hce
        // -------------------------------------------------------
        in = 8'hec;
        #5;
        if (out === 8'hce)
            $display("PASS: in=0xec, out=0x%02h (expected 0xce)", out);
        else
            $display("FAIL: in=0xec, out=0x%02h (expected 0xce)", out);

        // -------------------------------------------------------
        // Test 4: in = 8'ha5 -> expected 8'h06
        // -------------------------------------------------------
        in = 8'ha5;
        #5;
        if (out === 8'h06)
            $display("PASS: in=0xa5, out=0x%02h (expected 0x06)", out);
        else
            $display("FAIL: in=0xa5, out=0x%02h (expected 0x06)", out);

        // -------------------------------------------------------
        // Test 5: in = 8'hd0 -> expected 8'h70
        // -------------------------------------------------------
        in = 8'hd0;
        #5;
        if (out === 8'h70)
            $display("PASS: in=0xd0, out=0x%02h (expected 0x70)", out);
        else
            $display("FAIL: in=0xd0, out=0x%02h (expected 0x70)", out);

        // -------------------------------------------------------
        // Test 6: in = 8'hf0 -> expected 8'h8c
        // -------------------------------------------------------
        in = 8'hf0;
        #5;
        if (out === 8'h8c)
            $display("PASS: in=0xf0, out=0x%02h (expected 0x8c)", out);
        else
            $display("FAIL: in=0xf0, out=0x%02h (expected 0x8c)", out);

        // -------------------------------------------------------
        // Test 7: in = 8'hc0 -> expected 8'hba
        // -------------------------------------------------------
        in = 8'hc0;
        #5;
        if (out === 8'hba)
            $display("PASS: in=0xc0, out=0x%02h (expected 0xba)", out);
        else
            $display("FAIL: in=0xc0, out=0x%02h (expected 0xba)", out);

        // -------------------------------------------------------
        // Test 8: in = 8'hb0 -> expected 8'he7
        // -------------------------------------------------------
        in = 8'hb0;
        #5;
        if (out === 8'he7)
            $display("PASS: in=0xb0, out=0x%02h (expected 0xe7)", out);
        else
            $display("FAIL: in=0xb0, out=0x%02h (expected 0xe7)", out);

        // -------------------------------------------------------
        // Test 9: in = 8'h90 -> expected 8'h60
        // -------------------------------------------------------
        in = 8'h90;
        #5;
        if (out === 8'h60)
            $display("PASS: in=0x90, out=0x%02h (expected 0x60)", out);
        else
            $display("FAIL: in=0x90, out=0x%02h (expected 0x60)", out);

        // -------------------------------------------------------
        // Test 10: in = 8'hfe -> expected 8'hbb  (near-maximum)
        // -------------------------------------------------------
        in = 8'hfe;
        #5;
        if (out === 8'hbb)
            $display("PASS: in=0xfe, out=0x%02h (expected 0xbb)", out);
        else
            $display("FAIL: in=0xfe, out=0x%02h (expected 0xbb)", out);

        // -------------------------------------------------------
        // Test 11: in = 8'h81 -> expected 8'h0c  (low end of range)
        // -------------------------------------------------------
        in = 8'h81;
        #5;
        if (out === 8'h0c)
            $display("PASS: in=0x81, out=0x%02h (expected 0x0c)", out);
        else
            $display("FAIL: in=0x81, out=0x%02h (expected 0x0c)", out);

        // -------------------------------------------------------
        // Test 12: sweep all 128 entries and verify against known table
        // -------------------------------------------------------
        begin : sweep
            reg [7:0] expected_val;
            reg [7:0] sbox_hi [128];
            integer k;

            // Populate reference table (FIPS-197 values for 0x80-0xFF)
            sbox_hi[8'h00] = 8'hcd; sbox_hi[8'h01] = 8'h0c; sbox_hi[8'h02] = 8'h13; sbox_hi[8'h03] = 8'hec;
            sbox_hi[8'h04] = 8'h5f; sbox_hi[8'h05] = 8'h97; sbox_hi[8'h06] = 8'h44; sbox_hi[8'h07] = 8'h17;
            sbox_hi[8'h08] = 8'hc4; sbox_hi[8'h09] = 8'ha7; sbox_hi[8'h0a] = 8'h7e; sbox_hi[8'h0b] = 8'h3d;
            sbox_hi[8'h0c] = 8'h64; sbox_hi[8'h0d] = 8'h5d; sbox_hi[8'h0e] = 8'h19; sbox_hi[8'h0f] = 8'h73;
            sbox_hi[8'h10] = 8'h60; sbox_hi[8'h11] = 8'h81; sbox_hi[8'h12] = 8'h4f; sbox_hi[8'h13] = 8'hdc;
            sbox_hi[8'h14] = 8'h22; sbox_hi[8'h15] = 8'h2a; sbox_hi[8'h16] = 8'h90; sbox_hi[8'h17] = 8'h88;
            sbox_hi[8'h18] = 8'h46; sbox_hi[8'h19] = 8'hee; sbox_hi[8'h1a] = 8'hb8; sbox_hi[8'h1b] = 8'h14;
            sbox_hi[8'h1c] = 8'hde; sbox_hi[8'h1d] = 8'h5e; sbox_hi[8'h1e] = 8'h0b; sbox_hi[8'h1f] = 8'hdb;
            sbox_hi[8'h20] = 8'he0; sbox_hi[8'h21] = 8'h32; sbox_hi[8'h22] = 8'h3a; sbox_hi[8'h23] = 8'h0a;
            sbox_hi[8'h24] = 8'h49; sbox_hi[8'h25] = 8'h06; sbox_hi[8'h26] = 8'h24; sbox_hi[8'h27] = 8'h5c;
            sbox_hi[8'h28] = 8'hc2; sbox_hi[8'h29] = 8'hd3; sbox_hi[8'h2a] = 8'hac; sbox_hi[8'h2b] = 8'h62;
            sbox_hi[8'h2c] = 8'h91; sbox_hi[8'h2d] = 8'h95; sbox_hi[8'h2e] = 8'he4; sbox_hi[8'h2f] = 8'h79;
            sbox_hi[8'h30] = 8'he7; sbox_hi[8'h31] = 8'hc8; sbox_hi[8'h32] = 8'h37; sbox_hi[8'h33] = 8'h6d;
            sbox_hi[8'h34] = 8'h8d; sbox_hi[8'h35] = 8'hd5; sbox_hi[8'h36] = 8'h4e; sbox_hi[8'h37] = 8'ha9;
            sbox_hi[8'h38] = 8'h6c; sbox_hi[8'h39] = 8'h56; sbox_hi[8'h3a] = 8'hf4; sbox_hi[8'h3b] = 8'hea;
            sbox_hi[8'h3c] = 8'h65; sbox_hi[8'h3d] = 8'h7a; sbox_hi[8'h3e] = 8'hae; sbox_hi[8'h3f] = 8'h08;
            sbox_hi[8'h40] = 8'hba; sbox_hi[8'h41] = 8'h78; sbox_hi[8'h42] = 8'h25; sbox_hi[8'h43] = 8'h2e;
            sbox_hi[8'h44] = 8'h1c; sbox_hi[8'h45] = 8'ha6; sbox_hi[8'h46] = 8'hb4; sbox_hi[8'h47] = 8'hc6;
            sbox_hi[8'h48] = 8'he8; sbox_hi[8'h49] = 8'hdd; sbox_hi[8'h4a] = 8'h74; sbox_hi[8'h4b] = 8'h1f;
            sbox_hi[8'h4c] = 8'h4b; sbox_hi[8'h4d] = 8'hbd; sbox_hi[8'h4e] = 8'h8b; sbox_hi[8'h4f] = 8'h8a;
            sbox_hi[8'h50] = 8'h70; sbox_hi[8'h51] = 8'h3e; sbox_hi[8'h52] = 8'hb5; sbox_hi[8'h53] = 8'h66;
            sbox_hi[8'h54] = 8'h48; sbox_hi[8'h55] = 8'h03; sbox_hi[8'h56] = 8'hf6; sbox_hi[8'h57] = 8'h0e;
            sbox_hi[8'h58] = 8'h61; sbox_hi[8'h59] = 8'h35; sbox_hi[8'h5a] = 8'h57; sbox_hi[8'h5b] = 8'hb9;
            sbox_hi[8'h5c] = 8'h86; sbox_hi[8'h5d] = 8'hc1; sbox_hi[8'h5e] = 8'h1d; sbox_hi[8'h5f] = 8'h9e;
            sbox_hi[8'h60] = 8'he1; sbox_hi[8'h61] = 8'hf8; sbox_hi[8'h62] = 8'h98; sbox_hi[8'h63] = 8'h11;
            sbox_hi[8'h64] = 8'h69; sbox_hi[8'h65] = 8'hd9; sbox_hi[8'h66] = 8'h8e; sbox_hi[8'h67] = 8'h94;
            sbox_hi[8'h68] = 8'h9b; sbox_hi[8'h69] = 8'h1e; sbox_hi[8'h6a] = 8'h87; sbox_hi[8'h6b] = 8'he9;
            sbox_hi[8'h6c] = 8'hce; sbox_hi[8'h6d] = 8'h55; sbox_hi[8'h6e] = 8'h28; sbox_hi[8'h6f] = 8'hdf;
            sbox_hi[8'h70] = 8'h8c; sbox_hi[8'h71] = 8'ha1; sbox_hi[8'h72] = 8'h89; sbox_hi[8'h73] = 8'h0d;
            sbox_hi[8'h74] = 8'hbf; sbox_hi[8'h75] = 8'he6; sbox_hi[8'h76] = 8'h42; sbox_hi[8'h77
