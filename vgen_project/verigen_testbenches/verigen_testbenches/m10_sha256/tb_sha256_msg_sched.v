`timescale 1ns/1ps

module tb_sha256_msg_sched;

    // DUT connections
    reg  [511:0]  block_in;
    wire [2047:0] W;

    // Instantiate DUT
    sha256_msg_sched uut (
        .block_in(block_in),
        .W(W)
    );

    // Helper function: sigma0(x) = ROTR7(x) ^ ROTR18(x) ^ SHR3(x)
    function [31:0] sigma0;
        input [31:0] x;
        begin
            sigma0 = ({x[6:0],  x[31:7]}  ) ^
                     ({x[17:0], x[31:18]} ) ^
                     (x >> 3);
        end
    endfunction

    // Helper function: sigma1(x) = ROTR17(x) ^ ROTR19(x) ^ SHR10(x)
    function [31:0] sigma1;
        input [31:0] x;
        begin
            sigma1 = ({x[16:0], x[31:17]}) ^
                     ({x[18:0], x[31:19]}) ^
                     (x >> 10);
        end
    endfunction

    // Task to extract W[t] from the 2048-bit packed bus
    // W is packed as W[0] in bits [2047:2016], W[1] in [2015:1984], ..., W[63] in [31:0]
    task get_W;
        input  [5:0]  idx;
        output [31:0] val;
        begin
            val = W[2047 - idx*32 -: 32];
        end
    endtask

    // Compute expected message schedule from a 512-bit block
    task compute_expected_W;
        input [511:0] blk;
        output [2047:0] Wexp;
        reg [31:0] Wt [0:63];
        integer i;
        begin
            // W[0..15] from block
            for (i = 0; i < 16; i = i + 1) begin
                Wt[i] = blk[511 - i*32 -: 32];
            end
            // W[16..63]
            for (i = 16; i < 64; i = i + 1) begin
                Wt[i] = sigma1(Wt[i-2]) + Wt[i-7] + sigma0(Wt[i-15]) + Wt[i-16];
            end
            // Pack into 2048-bit output
            for (i = 0; i < 64; i = i + 1) begin
                Wexp[2047 - i*32 -: 32] = Wt[i];
            end
        end
    endtask

    integer t;
    reg [2047:0] Wexp;
    reg [31:0] wdut, wexp_word;
    reg pass;

    // Clock (not used by combinational module but required by spec)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not used by combinational module but required by spec)
    reg rst;
    initial begin
        rst = 1;
        @(posedge clk); // 1
        @(posedge clk); // 2
        @(posedge clk); // 3
        @(posedge clk); // 4
        @(posedge clk); // 5
        rst = 0;
    end

    initial begin
        block_in = 512'h0;
        #1; // let combinational settle

        // ----------------------------------------------------------------
        // Test 1: All-zero input
        // ----------------------------------------------------------------
        @(negedge clk); // sample after clock edge
        block_in = 512'h0;
        #2;
        compute_expected_W(block_in, Wexp);
        pass = 1;
        for (t = 0; t < 64; t = t + 1) begin
            get_W(t, wdut);
            wexp_word = Wexp[2047 - t*32 -: 32];
            if (wdut !== wexp_word) begin
                pass = 0;
                $display("FAIL: All-zero input W[%0d] expected %08h got %08h", t, wexp_word, wdut);
            end
        end
        if (pass) $display("PASS: All-zero input - all 64 W words correct");

        // ----------------------------------------------------------------
        // Test 2: All-ones input
        // ----------------------------------------------------------------
        @(negedge clk);
        block_in = {512{1'b1}};
        #2;
        compute_expected_W(block_in, Wexp);
        pass = 1;
        for (t = 0; t < 64; t = t + 1) begin
            get_W(t, wdut);
            wexp_word = Wexp[2047 - t*32 -: 32];
            if (wdut !== wexp_word) begin
                pass = 0;
                $display("FAIL: All-ones input W[%0d] expected %08h got %08h", t, wexp_word, wdut);
            end
        end
        if (pass) $display("PASS: All-ones input - all 64 W words correct");

        // ----------------------------------------------------------------
        // Test 3: Known SHA-256 test vector "abc" padded block
        // SHA-256("abc") uses block: 61626380 00000000...00000018
        // ----------------------------------------------------------------
        @(negedge clk);
        block_in = 512'h6162638000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
        #2;
        compute_expected_W(block_in, Wexp);
        pass = 1;
        for (t = 0; t < 64; t = t + 1) begin
            get_W(t, wdut);
            wexp_word = Wexp[2047 - t*32 -: 32];
            if (wdut !== wexp_word) begin
                pass = 0;
                $display("FAIL: abc padded W[%0d] expected %08h got %08h", t, wexp_word, wdut);
            end
        end
        if (pass) $display("PASS: SHA-256 abc padded block - all 64 W words correct");

        // ----------------------------------------------------------------
        // Test 4: Single 1 in MSB
        // ----------------------------------------------------------------
        @(negedge clk);
        block_in = {1'b1, 511'b0};
        #2;
        compute_expected_W(block_in, Wexp);
        pass = 1;
        for (t = 0; t < 64; t = t + 1) begin
            get_W(t, wdut);
            wexp_word = Wexp[2047 - t*32 -: 32];
            if (wdut !== wexp_word) begin
                pass = 0;
                $display("FAIL: MSB-only input W[%0d] expected %08h got %08h", t, wexp_word, wdut);
            end
        end
        if (pass) $display("PASS: Single MSB set - all 64 W words correct");

        // ----------------------------------------------------------------
        // Test 5: Single 1 in LSB
        // ----------------------------------------------------------------
        @(negedge clk);
        block_in = {511'b0, 1'b1};
        #2;
        compute_expected_W(block_in, Wexp);
        pass = 1;
        for (t = 0; t < 64; t = t + 1) begin
            get_W(t, wdut);
            wexp_word = Wexp[2047 - t*32 -: 32];
            if (wdut !== wexp_word) begin
                pass = 0;
                $display("FAIL: LSB-only input W[%0d] expected %08h got %08h", t, wexp_word, wdut);
            end
        end
        if (pass) $display("PASS: Single LSB set - all 64 W words correct");

        // ----------------------------------------------------------------
        // Test 6: Alternating pattern 0xAAAA...
        // ----------------------------------------------------------------
        @(negedge clk);
        block_in = {64{8'hAA}};
        #2;
        compute_expected_W(block_in, Wexp);
        pass = 1;
        for (t = 0; t < 64; t = t + 1) begin
            get_W(t, wdut);
            wexp_word = Wexp[2047 - t*32 -: 32];
            if (wdut !== wexp_word) begin
                pass = 0;
                $display("FAIL: 0xAA pattern W[%0d] expected %08h got %08h", t, wexp_word, wdut);
            end
        end
        if (pass) $display("PASS: 0xAA alternating pattern - all 64 W words correct");

        // ----------------------------------------------------------------
        // Test 7: Alternating pattern 0x5555...
        // ----------------------------------------------------------------
        @(negedge clk);
        block_in = {64{8'h55}};
        #2;
        compute_expected_W(block_in, Wexp);
        pass = 1;
        for (t = 0; t < 64; t = t + 1) begin
            get_W(t, wdut);
            wexp_word = Wexp[2047 - t*32 -: 32];
            if (wdut !== wexp_word) begin
                pass = 0;
                $display("FAIL: 0x55 pattern W[%0d] expected %08h got %08h", t, wexp_word, wdut);
            end
        end
        if (pass) $display("PASS: 0x55 alternating pattern - all 64 W words correct");

        // ----------------------------------------------------------------
        // Test 8: Incremental word values (W[i] = i for i=0..15)
        // ----------------------------------------------------------------
        @(negedge clk);
        block_in = {32'h00000000, 32'h00000001, 32'h00000002, 32'h00000003,
                    32'h00000004, 32'h00000005, 32'h00000006, 32'h00000007,
                    32'h00000008, 32'h00000009, 32'h0000000A, 32'h0000000B,
                    32'h0000000C, 32'h0000000D, 32'h0000000E, 32'h0000000F};
        #2;
        compute_expected_W(block_in, Wexp);
        pass = 1;
        for (t = 0; t < 64; t = t + 1) begin
            get_W(t, wdut);
            wexp_word = Wexp[2047 - t*32 -: 32];
            if (wdut !== wexp_word) begin
                pass = 0;
                $display("FAIL: incremental words W[%0d] expected %08h got %08h", t, wexp_word, wdut);
            end
        end
        if (pass) $display("PASS: Incremental word values 0..15 - all 64 W words correct");

        // ----------------------------------------------------------------
        // Test 9: Max-value (same as all-ones but checking specific W words)
        // ----------------------------------------------------------------
        @(negedge clk);
        block_in = 512'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        #2;
        // Check W[0] directly equals first word of block
        get_W(0, wdut);
        if (wdut === 32'hFFFFFFFF)
            $display("PASS: Max-value W[0] = 0xFFFFFFFF");
        else
            $display("FAIL: Max-value W[0] expected FFFFFFFF got %08h", wdut);

        // Check W[15] directly equals last word of block
        get_W(15, wdut);
        if (wdut === 32'hFFFFFFFF)
            $display("PASS: Max-value W[15] = 0xFFFFFFFF");
        else
            $display("FAIL: Max-value W[15] expected FFFFFFFF got %08h", wdut);

        // ----------------------------------------------------------------
        // Test 10: Verify sigma0/sigma1 correctness for specific known value
        // ----------------------------------------------------------------
        @(negedge clk);
        // block where W[0]=0x61626380, rest zero except W[15]=0x00000018
        block_in = 512'h6162638000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018;
        #2;
        // W[16] = sigma1(W[14]) + W[9] + sigma0(W[1]) + W[0]
        //       = sigma1(0) + 0 + sigma0(0) + 0x61626380
        //       = 0 + 0 + 0 + 0x61626380 = 0x61626380
        get_W(16, wdut);
        begin
            reg [31:0] expected_w16;
            expected_w16 = sigma1(32'h00000000) + 32'h00000000 + sigma0(32'h00000000) + 32'h61626380;
            if (wdut === expected_w16)
                $display("PASS: abc block W[16] = %08h", wdut);
            else
                $display("FAIL: abc block W[16] expected %08h got %08h", expected_w16, wdut);
        end

        #10;
        $finish;
    end

endmodule
