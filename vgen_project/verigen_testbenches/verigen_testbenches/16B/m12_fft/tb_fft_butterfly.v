`timescale 1ns/1ps

module tb_fft_butterfly;

    // DUT connections
    reg  signed [15:0] re_hi, im_hi, re_lo, im_lo, tw_re, tw_im;
    wire signed [15:0] out_re_hi, out_im_hi, out_re_lo, out_im_lo;

    // Clock and reset (combinational DUT but kept for requirement)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    fft_butterfly uut (
        .re_hi(re_hi), .im_hi(im_hi),
        .re_lo(re_lo), .im_lo(im_lo),
        .tw_re(tw_re), .tw_im(tw_im),
        .out_re_hi(out_re_hi), .out_im_hi(out_im_hi),
        .out_re_lo(out_re_lo), .out_im_lo(out_im_lo)
    );

    // Helper integers for expected values
    integer exp_re_hi, exp_im_hi, exp_re_lo, exp_im_lo;
    integer tw_re_i, tw_im_i, re_lo_i, im_lo_i, re_hi_i, im_hi_i;
    integer prod_re, prod_im;
    integer pass_count, fail_count;

    // Task to compute expected outputs and check
    // The module comment is confusing but the header says:
    // out_hi = in_hi + tw*in_lo
    // out_lo = in_hi - tw*in_lo
    // Complex multiply: tw*in_lo = (tw_re*re_lo - tw_im*im_lo, tw_re*im_lo + tw_im*re_lo)
    // Truncated to 16 bits (shift right 15 for Q1.15)
    task check_outputs;
        input [127:0] desc; // not used directly
        begin
            tw_re_i = $signed(tw_re);
            tw_im_i = $signed(tw_im);
            re_lo_i = $signed(re_lo);
            im_lo_i = $signed(im_lo);
            re_hi_i = $signed(re_hi);
            im_hi_i = $signed(im_hi);

            // Complex multiply tw * in_lo, Q1.15: result >> 15
            prod_re = ((tw_re_i * re_lo_i) - (tw_im_i * im_lo_i)) >>> 15;
            prod_im = ((tw_re_i * im_lo_i) + (tw_im_i * re_lo_i)) >>> 15;

            exp_re_hi = re_hi_i + prod_re;
            exp_im_hi = im_hi_i + prod_im;
            exp_re_lo = re_hi_i - prod_re;
            exp_im_lo = im_hi_i - prod_im;

            // Truncate to 16 bits
            exp_re_hi = exp_re_hi & 32'hFFFF;
            exp_im_hi = exp_im_hi & 32'hFFFF;
            exp_re_lo = exp_re_lo & 32'hFFFF;
            exp_im_lo = exp_im_lo & 32'hFFFF;
        end
    endtask

    integer test_num;

    initial begin
        pass_count = 0;
        fail_count = 0;
        test_num = 0;

        // Assert reset for 5 clock rising edges
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
        @(negedge clk);

        // -------------------------------------------------------
        // Test 1: W^0 case: tw_re=32767, tw_im=0
        // out_hi = in_hi + in_lo (approx), out_lo = in_hi - in_lo
        // -------------------------------------------------------
        test_num = 1;
        re_hi = 16'sd100; im_hi = 16'sd200;
        re_lo = 16'sd50;  im_lo = 16'sd75;
        tw_re = 16'sd32767; tw_im = 16'sd0;
        #1;
        begin
            // prod_re = (32767*50 - 0*75) >> 15 = 1638350 >> 15 = 49 (truncated)
            // prod_im = (32767*75 + 0*50) >> 15 = 2457525 >> 15 = 74
            // out_re_hi = 100 + 49 = 149
            // out_im_hi = 200 + 74 = 274
            // out_re_lo = 100 - 49 = 51
            // out_im_lo = 200 - 74 = 126
            exp_re_hi = (16'sd100 + (32767*50 >>> 15)) & 16'hFFFF;
            exp_im_hi = (16'sd200 + (32767*75 >>> 15)) & 16'hFFFF;
            exp_re_lo = (16'sd100 - (32767*50 >>> 15)) & 16'hFFFF;
            exp_im_lo = (16'sd200 - (32767*75 >>> 15)) & 16'hFFFF;

            if (out_re_hi === exp_re_hi[15:0] &&
                out_im_hi === exp_im_hi[15:0] &&
                out_re_lo === exp_re_lo[15:0] &&
                out_im_lo === exp_im_lo[15:0]) begin
                $display("PASS: Test1 W^0 basic (re_hi=100,im_hi=200,re_lo=50,im_lo=75)");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test1 W^0 basic got re_hi=%0d im_hi=%0d re_lo=%0d im_lo=%0d, exp re_hi=%0d im_hi=%0d re_lo=%0d im_lo=%0d",
                    $signed(out_re_hi), $signed(out_im_hi), $signed(out_re_lo), $signed(out_im_lo),
                    $signed(exp_re_hi[15:0]), $signed(exp_im_hi[15:0]), $signed(exp_re_lo[15:0]), $signed(exp_im_lo[15:0]));
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 2: All zeros
        // -------------------------------------------------------
        test_num = 2;
        re_hi = 16'sd0; im_hi = 16'sd0;
        re_lo = 16'sd0; im_lo = 16'sd0;
        tw_re = 16'sd0; tw_im = 16'sd0;
        #1;
        if (out_re_hi === 16'sd0 && out_im_hi === 16'sd0 &&
            out_re_lo === 16'sd0 && out_im_lo === 16'sd0) begin
            $display("PASS: Test2 all zeros -> all outputs zero");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test2 all zeros got re_hi=%0d im_hi=%0d re_lo=%0d im_lo=%0d",
                $signed(out_re_hi), $signed(out_im_hi), $signed(out_re_lo), $signed(out_im_lo));
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 3: W^0 with in_lo=0 → out_hi = in_hi, out_lo = in_hi
        // -------------------------------------------------------
        test_num = 3;
        re_hi = 16'sd1000; im_hi = 16'sd-500;
        re_lo = 16'sd0;    im_lo = 16'sd0;
        tw_re = 16'sd32767; tw_im = 16'sd0;
        #1;
        if (out_re_hi === 16'sd1000 && out_im_hi === 16'sd-500 &&
            out_re_lo === 16'sd1000 && out_im_lo === 16'sd-500) begin
            $display("PASS: Test3 W^0, in_lo=0 -> out_hi=out_lo=in_hi");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test3 W^0 in_lo=0 got re_hi=%0d im_hi=%0d re_lo=%0d im_lo=%0d",
                $signed(out_re_hi), $signed(out_im_hi), $signed(out_re_lo), $signed(out_im_lo));
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 4: W^N/4 case: tw_re=0, tw_im=-32767 (multiply by -j)
        // tw * in_lo: prod_re = (0*re_lo - (-32767)*im_lo)>>15 = im_lo (approx)
        //             prod_im = (0*im_lo + (-32767)*re_lo)>>15 = -re_lo (approx)
        // -------------------------------------------------------
        test_num = 4;
        re_hi = 16'sd100; im_hi = 16'sd200;
        re_lo = 16'sd30;  im_lo = 16'sd40;
        tw_re = 16'sd0;   tw_im = 16'sd-32767;
        #1;
        begin
            prod_re = ((0 * 30) - ((-32767) * 40)) >>> 15;  // 1310680 >> 15 = 39
            prod_im = ((0 * 40) + ((-32767) * 30)) >>> 15;  // -983010 >> 15 = -30
            exp_re_hi = (100 + prod_re);
            exp_im_hi = (200 + prod_im);
            exp_re_lo = (100 - prod_re);
            exp_im_lo = (200 - prod_im);

            if ($signed(out_re_hi) === exp_re_hi[15:0] &&
                $signed(out_im_hi) === exp_im_hi[15:0] &&
                $signed(out_re_lo) === exp_re_lo[15:0] &&
                $signed(out_im_lo) === exp_im_lo[15:0]) begin
                $display("PASS: Test4 tw=(0,-32767) complex multiply -j");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test4 tw=(0,-32767) got re_hi=%0d im_hi=%0d re_lo=%0d im_lo=%0d, exp %0d %0d %0d %0d",
                    $signed(out_re_hi), $signed(out_im_hi), $signed(out_re_lo), $signed(out_im_lo),
                    exp_re_hi, exp_im_hi, exp_re_lo, exp_im_lo);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 5: Negative in_hi values, W^0
        // -------------------------------------------------------
        test_num = 5;
        re_hi = 16'sd-300; im_hi = 16'sd-400;
        re_lo = 16'sd200;  im_lo = 16'sd100;
        tw_re = 16'sd32767; tw_im = 16'sd0;
        #1;
        begin
            prod_re = (32767 * 200) >>> 15;   // ~199
            prod_im = (32767 * 100) >>> 15;   // ~99
            exp_re_hi = (-300 + prod_re);
            exp_im_hi = (-400 + prod_im);
            exp_re_lo = (-300 - prod_re);
            exp_im_lo = (-400 - prod_im);

            if ($signed(out_re_hi) === exp_re_hi &&
                $signed(out_im_hi) === exp_im_hi &&
                $signed(out_re_lo) === exp_re_lo &&
                $signed(out_im_lo) === exp_im_lo) begin
                $display("PASS: Test5 negative in_hi with W^0");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test5 negative in_hi got re_hi=%0d im_hi=%0d re_lo=%0d im_lo=%0d, exp %0d %0d %0d %0d",
                    $signed(out_re_hi), $signed(out_im_hi), $signed(out_re_lo), $signed(out_im_lo),
                    exp_re_hi, exp_im_hi, exp_re_lo, exp_im_lo);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 6: All inputs = max positive (32767)
        // -------------------------------------------------------
        test_num = 6;
        re_hi = 16'sd32767; im_hi = 16'sd32767;
        re_lo = 16'sd32767; im_lo = 16'sd32767;
        tw_re = 16'sd32767; tw_im = 16'sd0;
        #1;
        begin
            // prod_re = (32767*32767 - 0) >> 15 = 1073676289 >> 15 = 32766
            // prod_im = (32767*32767 + 0) >> 15 = 32766
            prod_re = (32767 * 32767) >>> 15;
            prod_im = (32767 * 32767) >>> 15;
            exp_re_hi = (32767 + prod_re) & 16'hFFFF;
            exp_im_hi = (32767 + prod_im) & 16'hFFFF;
            exp_re_lo = (32767 - prod_re) & 16'hFFFF;
            exp_im_lo = (32767 - prod_im) & 16'hFFFF;

            if (out_re_hi === exp_re_hi[15:0] &&
                out_im_hi === exp_im_hi[15:0] &&
                out_re_lo === exp_re_lo[15:0] &&
                out_im_lo === exp_im_lo[15:0]) begin
                $display("PASS: Test6 max positive inputs");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test6 max positive got re_hi=%0d im_hi=%0d re_lo=%0d im_lo=%0d, exp %0d %0d %0d %0d",
                    $signed(out_re_hi), $signed(out_im_hi), $signed(out_re_lo), $signed(out_im_lo),
                    $signed(exp_re_hi[15:0]), $signed(exp_im_hi[15:0]), $signed(exp_re_lo[15:0]), $signed(exp_im_lo[15:0]));
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 7: tw_re=-32768 (most negative), tw_im=0
        // -------------------------------------------------------
        test_
