`timescale 1ns/1ps

module tb_sha256_msg_sched;

    // DUT connections
    reg  [511:0] block_in;
    wire [2047:0] W;

    // Instantiate DUT
    sha256_msg_sched uut (
        .block_in(block_in),
        .W(W)
    );

    // Helper task to compute sigma0: ROTR7 ^ ROTR18 ^ SHR3
    function [31:0] sigma0;
        input [31:0] x;
        reg [31:0] r7, r18, s3;
        begin
            r7  = {x[6:0],  x[31:7]};
            r18 = {x[17:0], x[31:18]};
            s3  = x >> 3;
            sigma0 = r7 ^ r18 ^ s3;
        end
    endfunction

    // Helper task to compute sigma1: ROTR17 ^ ROTR19 ^ SHR10
    function [31:0] sigma1;
        input [31:0] x;
        reg [31:0] r17, r19, s10;
        begin
            r17 = {x[16:0], x[31:17]};
            r19 = {x[18:0], x[31:19]};
            s10 = x >> 10;
            sigma1 = r17 ^ r19 ^ s10;
        end
    endfunction

    // Function to extract W[t] from packed bus (W[0] at MSB)
    function [31:0] getW;
        input [2047:0] Wbus;
        input integer t;
        begin
            getW = Wbus[2047 - t*32 -: 32];
        end
    endfunction

    integer i;
    reg [31:0] w_arr [0:63];
    reg [31:0] expected;
    reg [511:0] test_block;
    integer pass_count;
    integer fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;
        block_in = 512'h0;
        #20;

        // -------------------------------------------------------
        // Test 1: All-zero input
        // -------------------------------------------------------
        block_in = 512'h0;
        #10;

        // W[0..15] should be 0, W[16..63] computed from zeros -> all zero
        // Verify W[0] through W[7]
        begin : t1
            reg all_zero;
            all_zero = 1;
            for (i = 0; i < 64; i = i + 1) begin
                if (getW(W, i) !== 32'h0) all_zero = 0;
            end
            if (all_zero) begin
                $display("PASS: All-zero input produces all-zero W array");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: All-zero input should produce all-zero W array");
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 2: All-ones input
        // -------------------------------------------------------
        block_in = {512{1'b1}};
        #10;

        // Build expected W array
        for (i = 0; i < 16; i = i + 1)
            w_arr[i] = 32'hFFFFFFFF;
        for (i = 16; i < 64; i = i + 1)
            w_arr[i] = sigma1(w_arr[i-2]) + w_arr[i-7] + sigma0(w_arr[i-15]) + w_arr[i-16];

        begin : t2
            reg match;
            match = 1;
            for (i = 0; i < 64; i = i + 1) begin
                if (getW(W, i) !== w_arr[i]) match = 0;
            end
            if (match) begin
                $display("PASS: All-ones input W array matches expected");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: All-ones input W array mismatch");
                for (i = 0; i < 64; i = i + 1) begin
                    if (getW(W, i) !== w_arr[i])
                        $display("  W[%0d]: got %08h, expected %08h", i, getW(W,i), w_arr[i]);
                end
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 3: Known SHA-256 message block (first block of "abc")
        // "abc" = 0x61626380...00000018 (512-bit padded)
        // -------------------------------------------------------
        block_in = 512'h61626380_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000018;
        #10;

        for (i = 0; i < 16; i = i + 1)
            w_arr[i] = block_in[511 - i*32 -: 32];
        for (i = 16; i < 64; i = i + 1)
            w_arr[i] = sigma1(w_arr[i-2]) + w_arr[i-7] + sigma0(w_arr[i-15]) + w_arr[i-16];

        begin : t3
            reg match;
            match = 1;
            for (i = 0; i < 64; i = i + 1) begin
                if (getW(W, i) !== w_arr[i]) match = 0;
            end
            if (match) begin
                $display("PASS: 'abc' block W array matches expected");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: 'abc' block W array mismatch");
                for (i = 0; i < 64; i = i + 1) begin
                    if (getW(W, i) !== w_arr[i])
                        $display("  W[%0d]: got %08h, expected %08h", i, getW(W,i), w_arr[i]);
                end
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 4: Alternating pattern 0xAAAAAAAA_55555555...
        // -------------------------------------------------------
        block_in = {8{64'hAAAAAAAA_55555555}};
        #10;

        for (i = 0; i < 16; i = i + 1)
            w_arr[i] = block_in[511 - i*32 -: 32];
        for (i = 16; i < 64; i = i + 1)
            w_arr[i] = sigma1(w_arr[i-2]) + w_arr[i-7] + sigma0(w_arr[i-15]) + w_arr[i-16];

        begin : t4
            reg match;
            match = 1;
            for (i = 0; i < 64; i = i + 1) begin
                if (getW(W, i) !== w_arr[i]) match = 0;
            end
            if (match) begin
                $display("PASS: Alternating pattern W array matches expected");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Alternating pattern W array mismatch");
                for (i = 0; i < 64; i = i + 1) begin
                    if (getW(W, i) !== w_arr[i])
                        $display("  W[%0d]: got %08h, expected %08h", i, getW(W,i), w_arr[i]);
                end
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 5: Single bit set - MSB only
        // -------------------------------------------------------
        block_in = 512'h80000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000;
        #10;

        for (i = 0; i < 16; i = i + 1)
            w_arr[i] = block_in[511 - i*32 -: 32];
        for (i = 16; i < 64; i = i + 1)
            w_arr[i] = sigma1(w_arr[i-2]) + w_arr[i-7] + sigma0(w_arr[i-15]) + w_arr[i-16];

        begin : t5
            reg match;
            match = 1;
            for (i = 0; i < 64; i = i + 1) begin
                if (getW(W, i) !== w_arr[i]) match = 0;
            end
            if (match) begin
                $display("PASS: MSB-only block W array matches expected");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: MSB-only block W array mismatch");
                for (i = 0; i < 64; i = i + 1) begin
                    if (getW(W, i) !== w_arr[i])
                        $display("  W[%0d]: got %08h, expected %08h", i, getW(W,i), w_arr[i]);
                end
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 6: Single bit set - LSB only
        // -------------------------------------------------------
        block_in = 512'h00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000001;
        #10;

        for (i = 0; i < 16; i = i + 1)
            w_arr[i] = block_in[511 - i*32 -: 32];
        for (i = 16; i < 64; i = i + 1)
            w_arr[i] = sigma1(w_arr[i-2]) + w_arr[i-7] + sigma0(w_arr[i-15]) + w_arr[i-16];

        begin : t6
            reg match;
            match = 1;
            for (i = 0; i < 64; i = i + 1) begin
                if (getW(W, i) !== w_arr[i]) match = 0;
            end
            if (match) begin
                $display("PASS: LSB-only block W array matches expected");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: LSB-only block W array mismatch");
                for (i = 0; i < 64; i = i + 1) begin
                    if (getW(W, i) !== w_arr[i])
                        $display("  W[%0d]: got %08h, expected %08h", i, getW(W,i), w_arr[i]);
                end
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 7: Incrementing pattern
        // -------------------------------------------------------
        block_in = {32'h00000000,32'h01010101,32'h02020202,32'h03030303,
                    32'h04040404,32'h05050505,32'h06060606,32'h07070707,
                    32'h08080808,32'h09090909,32'h0a0a0a0a,32'h0b0b0b0b,
                    32'h0c0c0c0c,32'h0d0d0d0d,32'h0e0e0e0e,32'h0f0f0f0f};
        #10;

        for (i = 0; i < 16; i = i + 1)
            w_arr[i] = block_in[511 - i*32 -: 32];
        for (i = 16; i < 64; i = i + 1)
            w_arr[i] = sigma1(w_arr[i-2]) + w_arr[i-7] + sigma0(w_arr[i-15]) + w_arr[i-16];

        begin : t7
            reg match;
            match = 1;
            for (i = 0; i < 64; i = i + 1) begin
                if (getW(W, i) !== w_arr[i]) match = 0;
            end
            if (match) begin
                $display("PASS: Incrementing pattern W array matches expected");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Incrementing pattern W array mismatch");
                for (i = 0; i < 64; i = i + 1) begin
                    if (getW(W, i) !== w_arr[i])
                        $display("  W[%0d]: got %08h, expected %08h", i, getW(W,i), w_arr[i]);
                end
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 8: Maximum value (same as all-ones but also verify W[0] directly)
        // -------------------------------------------------------
        block_in = {512{1'b1}};
        #10;

        // W[0] should be 0xFFFFFFFF (first 32 bits of all-ones block)
        if (getW(W, 0) === 32'hFFFFFFFF) begin
            $display("PASS: All-ones W[0] = 0xFFFFFFFF");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: All-ones W[0] expected 0xFFFFFFFF, got %08h", getW(W, 0));
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 9: Random-ish known pattern
        // -------------------------------------------------------
        block_in = {32'hDEADBEEF, 32'hCAFEBABE, 32'h12345678, 32'h9ABCDEF0,
                    32'hFEDCBA98, 32'h76543210, 32'hA5A5A5A5, 32'h5A5A5A5A,
                    32'h01234567, 32'h89ABCDEF, 32'hF0F0F0F0, 32'h0F0F0F0F,
                    32'hC3C3C3C3, 32'h3C3C3C3C, 32'hFFFF0000, 32'h0000FFFF};
        #10;

        for (i = 0; i < 16; i = i + 1)
            w_arr[i] = block_in[511 - i*32 -: 32];
        for (i = 16; i < 64; i = i + 1)
            w_arr[i] = sigma1(w_arr[i-2]) + w_arr[i-7] + sigma0(w_arr[i-15]) + w_arr[i-16];

        begin : t9
            reg match;
            match = 1;
            for (i = 0; i < 64; i = i + 1) begin
                if (getW(W, i) !== w_arr[i])
