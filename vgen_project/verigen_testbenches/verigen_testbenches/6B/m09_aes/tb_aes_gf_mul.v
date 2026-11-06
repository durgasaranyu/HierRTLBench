`timescale 1ns/1ps

module tb_aes_gf_mul;

    // DUT connections
    reg  [7:0] a;
    wire [7:0] xtime_a;
    wire [7:0] x3_a;

    // Instantiate DUT
    aes_gf_mul uut (
        .a       (a),
        .xtime_a (xtime_a),
        .x3_a    (x3_a)
    );

    // Clock (not needed for combinational, but required by spec)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not needed for combinational, but required by spec)
    reg rst;
    integer i;

    // GF(2^8) xtime reference function
    function [7:0] ref_xtime;
        input [7:0] x;
        begin
            if (x[7])
                ref_xtime = (x << 1) ^ 8'h1b;
            else
                ref_xtime = (x << 1);
        end
    endfunction

    // Reference x3 = xtime(a) ^ a
    function [7:0] ref_x3;
        input [7:0] x;
        begin
            ref_x3 = ref_xtime(x) ^ x;
        end
    endfunction

    // Test variables
    reg [7:0] exp_xtime;
    reg [7:0] exp_x3;
    integer pass_count;
    integer fail_count;

    initial begin
        rst        = 1;
        a          = 8'h00;
        pass_count = 0;
        fail_count = 0;

        // Assert reset for 5 rising edges
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        // Wait a bit after reset
        #3;

        // ---------------------------------------------------------------
        // Test 1: a = 8'h00 (all zeros)
        // ---------------------------------------------------------------
        a = 8'h00;
        #2;
        exp_xtime = ref_xtime(8'h00);
        exp_x3    = ref_x3(8'h00);
        if (xtime_a === exp_xtime && x3_a === exp_x3)
            $display("PASS: a=0x00 xtime_a=0x%02h x3_a=0x%02h", xtime_a, x3_a);
        else begin
            $display("FAIL: a=0x00 expected xtime=0x%02h got 0x%02h, expected x3=0x%02h got 0x%02h",
                     exp_xtime, xtime_a, exp_x3, x3_a);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 2: a = 8'hFF (all ones)
        // ---------------------------------------------------------------
        a = 8'hFF;
        #2;
        exp_xtime = ref_xtime(8'hFF);
        exp_x3    = ref_x3(8'hFF);
        if (xtime_a === exp_xtime && x3_a === exp_x3)
            $display("PASS: a=0xFF xtime_a=0x%02h x3_a=0x%02h", xtime_a, x3_a);
        else begin
            $display("FAIL: a=0xFF expected xtime=0x%02h got 0x%02h, expected x3=0x%02h got 0x%02h",
                     exp_xtime, xtime_a, exp_x3, x3_a);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 3: a = 8'h01 (LSB only)
        // ---------------------------------------------------------------
        a = 8'h01;
        #2;
        exp_xtime = ref_xtime(8'h01);
        exp_x3    = ref_x3(8'h01);
        if (xtime_a === exp_xtime && x3_a === exp_x3)
            $display("PASS: a=0x01 xtime_a=0x%02h x3_a=0x%02h", xtime_a, x3_a);
        else begin
            $display("FAIL: a=0x01 expected xtime=0x%02h got 0x%02h, expected x3=0x%02h got 0x%02h",
                     exp_xtime, xtime_a, exp_x3, x3_a);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 4: a = 8'h80 (MSB only, triggers reduction)
        // ---------------------------------------------------------------
        a = 8'h80;
        #2;
        exp_xtime = ref_xtime(8'h80);
        exp_x3    = ref_x3(8'h80);
        if (xtime_a === exp_xtime && x3_a === exp_x3)
            $display("PASS: a=0x80 xtime_a=0x%02h x3_a=0x%02h", xtime_a, x3_a);
        else begin
            $display("FAIL: a=0x80 expected xtime=0x%02h got 0x%02h, expected x3=0x%02h got 0x%02h",
                     exp_xtime, xtime_a, exp_x3, x3_a);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 5: a = 8'h53 (known AES value)
        // ---------------------------------------------------------------
        a = 8'h53;
        #2;
        exp_xtime = ref_xtime(8'h53);
        exp_x3    = ref_x3(8'h53);
        if (xtime_a === exp_xtime && x3_a === exp_x3)
            $display("PASS: a=0x53 xtime_a=0x%02h x3_a=0x%02h", xtime_a, x3_a);
        else begin
            $display("FAIL: a=0x53 expected xtime=0x%02h got 0x%02h, expected x3=0x%02h got 0x%02h",
                     exp_xtime, xtime_a, exp_x3, x3_a);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 6: a = 8'hAA (alternating bits)
        // ---------------------------------------------------------------
        a = 8'hAA;
        #2;
        exp_xtime = ref_xtime(8'hAA);
        exp_x3    = ref_x3(8'hAA);
        if (xtime_a === exp_xtime && x3_a === exp_x3)
            $display("PASS: a=0xAA xtime_a=0x%02h x3_a=0x%02h", xtime_a, x3_a);
        else begin
            $display("FAIL: a=0xAA expected xtime=0x%02h got 0x%02h, expected x3=0x%02h got 0x%02h",
                     exp_xtime, xtime_a, exp_x3, x3_a);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 7: a = 8'h55 (alternating bits, inverted)
        // ---------------------------------------------------------------
        a = 8'h55;
        #2;
        exp_xtime = ref_xtime(8'h55);
        exp_x3    = ref_x3(8'h55);
        if (xtime_a === exp_xtime && x3_a === exp_x3)
            $display("PASS: a=0x55 xtime_a=0x%02h x3_a=0x%02h", xtime_a, x3_a);
        else begin
            $display("FAIL: a=0x55 expected xtime=0x%02h got 0x%02h, expected x3=0x%02h got 0x%02h",
                     exp_xtime, xtime_a, exp_x3, x3_a);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 8: a = 8'hFE (max minus one, MSB set)
        // ---------------------------------------------------------------
        a = 8'hFE;
        #2;
        exp_xtime = ref_xtime(8'hFE);
        exp_x3    = ref_x3(8'hFE);
        if (xtime_a === exp_xtime && x3_a === exp_x3)
            $display("PASS: a=0xFE xtime_a=0x%02h x3_a=0x%02h", xtime_a, x3_a);
        else begin
            $display("FAIL: a=0xFE expected xtime=0x%02h got 0x%02h, expected x3=0x%02h got 0x%02h",
                     exp_xtime, xtime_a, exp_x3, x3_a);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Additional sweep: 16 random-ish values
        // ---------------------------------------------------------------
        begin : sweep
            reg [7:0] test_vals [0:15];
            integer j;
            test_vals[0]  = 8'h02;
            test_vals[1]  = 8'h03;
            test_vals[2]  = 8'h10;
            test_vals[3]  = 8'h1B;
            test_vals[4]  = 8'h36;
            test_vals[5]  = 8'h6C;
            test_vals[6]  = 8'hD8;
            test_vals[7]  = 8'hAB;
            test_vals[8]  = 8'h4D;
            test_vals[9]  = 8'h9A;
            test_vals[10] = 8'hC3;
            test_vals[11] = 8'h7F;
            test_vals[12] = 8'hE5;
            test_vals[13] = 8'h19;
            test_vals[14] = 8'hB0;
            test_vals[15] = 8'h63;

            for (j = 0; j < 16; j = j + 1) begin
                a = test_vals[j];
                #2;
                exp_xtime = ref_xtime(test_vals[j]);
                exp_x3    = ref_x3(test_vals[j]);
                if (xtime_a === exp_xtime && x3_a === exp_x3)
                    $display("PASS: sweep a=0x%02h xtime_a=0x%02h x3_a=0x%02h",
                             a, xtime_a, x3_a);
                else begin
                    $display("FAIL: sweep a=0x%02h expected xtime=0x%02h got 0x%02h, expected x3=0x%02h got 0x%02h",
                             a, exp_xtime, xtime_a, exp_x3, x3_a);
                    fail_count = fail_count + 1;
                end
            end
        end

        // ---------------------------------------------------------------
        // Summary
        // ---------------------------------------------------------------
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED: %0d failure(s)", fail_count);

        $finish;
    end

endmodule
