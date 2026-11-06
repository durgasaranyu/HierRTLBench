`timescale 1ns / 1ps

module tb_aes_addroundkey;

    // DUT connections
    reg  [127:0] state_in;
    reg  [127:0] round_key;
    wire [127:0] state_out;

    // Clock and reset (not used by combinational DUT, but required by testbench rules)
    reg clk;
    reg rst;

    // Instantiate DUT
    aes_addroundkey uut (
        .state_in  (state_in),
        .round_key (round_key),
        .state_out (state_out)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset for exactly 5 rising edges
    integer i;
    initial begin
        rst = 1;
        for (i = 0; i < 5; i = i + 1)
            @(posedge clk);
        rst = 0;
    end

    // Expected value register
    reg [127:0] expected;

    // Task to check output
    task check_output;
        input [127:0] exp;
        input [127:0] got;
        input [255:0] desc; // 32 chars
        begin
            if (got === exp) begin
                $display("PASS: %s | expected=%h, got=%h", desc, exp, got);
            end else begin
                $display("FAIL: %s | expected=%h, got=%h", desc, exp, got);
            end
        end
    endtask

    initial begin
        // Wait for reset to complete
        @(negedge rst);
        @(posedge clk); #1;

        // -------------------------------------------------------------------
        // Test 1: All-zero state XOR all-zero key = all zeros
        // -------------------------------------------------------------------
        state_in  = 128'h0;
        round_key = 128'h0;
        #1;
        expected = 128'h0;
        check_output(expected, state_out, "All zeros state XOR all zeros key ");

        // -------------------------------------------------------------------
        // Test 2: All-ones state XOR all-zero key = all ones
        // -------------------------------------------------------------------
        @(posedge clk); #1;
        state_in  = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        round_key = 128'h0;
        #1;
        expected = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        check_output(expected, state_out, "All-ones XOR all-zeros key        ");

        // -------------------------------------------------------------------
        // Test 3: All-zero state XOR all-ones key = all ones
        // -------------------------------------------------------------------
        @(posedge clk); #1;
        state_in  = 128'h0;
        round_key = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        #1;
        expected = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        check_output(expected, state_out, "All-zeros XOR all-ones key        ");

        // -------------------------------------------------------------------
        // Test 4: All-ones state XOR all-ones key = all zeros
        // -------------------------------------------------------------------
        @(posedge clk); #1;
        state_in  = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        round_key = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        #1;
        expected = 128'h0;
        check_output(expected, state_out, "All-ones XOR all-ones key = zero  ");

        // -------------------------------------------------------------------
        // Test 5: Known AES initial round (FIPS 197 example)
        // state_in  = 3243F6A8885A308D313198A2E0370734
        // round_key = 2B7E151628AED2A6ABF7158809CF4F3C
        // expected  = 193DE3BEA0F4E22B9AC68D2AE9F84808
        // -------------------------------------------------------------------
        @(posedge clk); #1;
        state_in  = 128'h3243F6A8885A308D313198A2E0370734;
        round_key = 128'h2B7E151628AED2A6ABF7158809CF4F3C;
        #1;
        expected  = 128'h193DE3BEA0F4E22B9AC68D2AE9F84808;
        check_output(expected, state_out, "FIPS197 initial round AddRoundKey ");

        // -------------------------------------------------------------------
        // Test 6: State = key (XOR with itself = 0)
        // -------------------------------------------------------------------
        @(posedge clk); #1;
        state_in  = 128'hDEADBEEFCAFEBABE0123456789ABCDEF;
        round_key = 128'hDEADBEEFCAFEBABE0123456789ABCDEF;
        #1;
        expected = 128'h0;
        check_output(expected, state_out, "State XOR itself = zero           ");

        // -------------------------------------------------------------------
        // Test 7: Alternating bit pattern
        // -------------------------------------------------------------------
        @(posedge clk); #1;
        state_in  = 128'hAAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA;
        round_key = 128'h5555_5555_5555_5555_5555_5555_5555_5555;
        #1;
        expected  = 128'hFFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF_FFFF;
        check_output(expected, state_out, "0xAAAA... XOR 0x5555... = 0xFFFF  ");

        // -------------------------------------------------------------------
        // Test 8: Random known values
        // state_in  = 0F0E0D0C0B0A09080706050403020100
        // round_key = 1F1E1D1C1B1A19181716151413121110
        // expected  = 10101010101010101010101010101010
        // -------------------------------------------------------------------
        @(posedge clk); #1;
        state_in  = 128'h0F0E0D0C0B0A09080706050403020100;
        round_key = 128'h1F1E1D1C1B1A19181716151413121110;
        #1;
        expected  = state_in ^ round_key; // 0x10101010...
        check_output(expected, state_out, "Sequential bytes XOR              ");

        // -------------------------------------------------------------------
        // Test 9: Single bit set in state, zero key
        // -------------------------------------------------------------------
        @(posedge clk); #1;
        state_in  = 128'h8000_0000_0000_0000_0000_0000_0000_0001;
        round_key = 128'h0;
        #1;
        expected  = 128'h8000_0000_0000_0000_0000_0000_0000_0001;
        check_output(expected, state_out, "Single bits, zero key passthrough ");

        // -------------------------------------------------------------------
        // Test 10: Maximum distinct state and key values
        // -------------------------------------------------------------------
        @(posedge clk); #1;
        state_in  = 128'hFEDCBA9876543210FEDCBA9876543210;
        round_key = 128'h0123456789ABCDEF0123456789ABCDEF;
        #1;
        expected  = state_in ^ round_key;
        check_output(expected, state_out, "Max distinct state and key XOR    ");

        @(posedge clk); #1;
        $display("All tests complete.");
        $finish;
    end

endmodule
