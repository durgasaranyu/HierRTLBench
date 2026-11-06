`timescale 1ns/1ps

module tb_aes_addroundkey;

    // DUT connections
    reg  [127:0] state_in;
    reg  [127:0] round_key;
    wire [127:0] state_out;

    // Clock (not needed for purely combinational, but required by rules)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    aes_addroundkey uut (
        .state_in  (state_in),
        .round_key (round_key),
        .state_out (state_out)
    );

    // Reset (synchronous, 5 rising edges)
    integer i;
    initial begin
        rst = 1;
        state_in  = 128'h0;
        round_key = 128'h0;
        repeat (5) @(posedge clk);
        rst = 0;

        // ----------------------------------------------------------------
        // Test 1: All-zero state XOR all-zero key => all-zero output
        // ----------------------------------------------------------------
        @(posedge clk);
        state_in  = 128'h0000_0000_0000_0000_0000_0000_0000_0000;
        round_key = 128'h0000_0000_0000_0000_0000_0000_0000_0000;
        #1;
        if (state_out === 128'h0000_0000_0000_0000_0000_0000_0000_0000)
            $display("PASS: Test1 - all-zero XOR all-zero = all-zero");
        else
            $display("FAIL: Test1 - all-zero XOR all-zero, got %h", state_out);

        // ----------------------------------------------------------------
        // Test 2: All-ones state XOR all-zero key => all-ones output
        // ----------------------------------------------------------------
        @(posedge clk);
        state_in  = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        round_key = 128'h0000_0000_0000_0000_0000_0000_0000_0000;
        #1;
        if (state_out === 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF)
            $display("PASS: Test2 - all-ones XOR all-zero = all-ones");
        else
            $display("FAIL: Test2 - all-ones XOR all-zero, got %h", state_out);

        // ----------------------------------------------------------------
        // Test 3: All-zero state XOR all-ones key => all-ones output
        // ----------------------------------------------------------------
        @(posedge clk);
        state_in  = 128'h0000_0000_0000_0000_0000_0000_0000_0000;
        round_key = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        #1;
        if (state_out === 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF)
            $display("PASS: Test3 - all-zero XOR all-ones = all-ones");
        else
            $display("FAIL: Test3 - all-zero XOR all-ones, got %h", state_out);

        // ----------------------------------------------------------------
        // Test 4: All-ones XOR all-ones => all-zero
        // ----------------------------------------------------------------
        @(posedge clk);
        state_in  = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        round_key = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        #1;
        if (state_out === 128'h0000_0000_0000_0000_0000_0000_0000_0000)
            $display("PASS: Test4 - all-ones XOR all-ones = all-zero");
        else
            $display("FAIL: Test4 - all-ones XOR all-ones, got %h", state_out);

        // ----------------------------------------------------------------
        // Test 5: Known AES-128 initial AddRoundKey values
        //   state = 00112233445566778899aabbccddeeff
        //   key   = 000102030405060708090a0b0c0d0e0f
        //   out   = 00102030405060708090a0b0c0d0e0f0
        // ----------------------------------------------------------------
        @(posedge clk);
        state_in  = 128'h00112233_44556677_8899aabb_ccddeeff;
        round_key = 128'h00010203_04050607_08090a0b_0c0d0e0f;
        #1;
        if (state_out === 128'h00102030_40506070_8090a0b0_c0d0e0f0)
            $display("PASS: Test5 - Known AES-128 AddRoundKey vector");
        else
            $display("FAIL: Test5 - Known AES-128 AddRoundKey, expected 00102030405060708090a0b0c0d0e0f0, got %h", state_out);

        // ----------------------------------------------------------------
        // Test 6: XOR with itself => zero
        // ----------------------------------------------------------------
        @(posedge clk);
        state_in  = 128'hDEADBEEF_CAFEBABE_12345678_ABCDEF01;
        round_key = 128'hDEADBEEF_CAFEBABE_12345678_ABCDEF01;
        #1;
        if (state_out === 128'h0)
            $display("PASS: Test6 - value XOR itself = zero");
        else
            $display("FAIL: Test6 - value XOR itself, got %h", state_out);

        // ----------------------------------------------------------------
        // Test 7: Alternating bit pattern
        //   state = AAAA...AAAA (alternating 1010...)
        //   key   = 5555...5555 (alternating 0101...)
        //   out   = FFFF...FFFF
        // ----------------------------------------------------------------
        @(posedge clk);
        state_in  = 128'hAAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA;
        round_key = 128'h5555_5555_5555_5555_5555_5555_5555_5555;
        #1;
        if (state_out === 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF)
            $display("PASS: Test7 - alternating 0xAA XOR 0x55 = 0xFF pattern");
        else
            $display("FAIL: Test7 - alternating pattern, got %h", state_out);

        // ----------------------------------------------------------------
        // Test 8: Arbitrary known values
        //   state = FEDCBA9876543210FEDCBA9876543210
        //   key   = 0123456789ABCDEF0123456789ABCDEF
        //   out   = FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF
        // ----------------------------------------------------------------
        @(posedge clk);
        state_in  = 128'hFEDCBA98_76543210_FEDCBA98_76543210;
        round_key = 128'h01234567_89ABCDEF_01234567_89ABCDEF;
        #1;
        if (state_out === (128'hFEDCBA98_76543210_FEDCBA98_76543210 ^ 128'h01234567_89ABCDEF_01234567_89ABCDEF))
            $display("PASS: Test8 - arbitrary XOR check passed");
        else
            $display("FAIL: Test8 - arbitrary XOR, got %h", state_out);

        // ----------------------------------------------------------------
        // Test 9: Maximum value state with maximum key
        // (same as test 4 but verifying max-value edge case explicitly)
        // ----------------------------------------------------------------
        @(posedge clk);
        state_in  = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        round_key = 128'h0000_0000_0000_0000_FFFF_FFFF_FFFF_FFFF;
        #1;
        if (state_out === 128'hFFFF_FFFF_FFFF_FFFF_0000_0000_0000_0000)
            $display("PASS: Test9 - partial all-ones XOR check");
        else
            $display("FAIL: Test9 - partial all-ones XOR, got %h", state_out);

        // ----------------------------------------------------------------
        // Test 10: Single bit differences
        // ----------------------------------------------------------------
        @(posedge clk);
        state_in  = 128'h0000_0000_0000_0000_0000_0000_0000_0001;
        round_key = 128'h0000_0000_0000_0000_0000_0000_0000_0001;
        #1;
        if (state_out === 128'h0)
            $display("PASS: Test10 - single LSB XOR itself = zero");
        else
            $display("FAIL: Test10 - single LSB XOR itself, got %h", state_out);

        $finish;
    end

endmodule
