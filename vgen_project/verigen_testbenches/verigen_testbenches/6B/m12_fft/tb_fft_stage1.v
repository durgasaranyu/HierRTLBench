`timescale 1ns/1ps

module tb_fft_stage1;

    // DUT connections
    reg  signed [127:0] xre_flat;
    reg  signed [127:0] xim_flat;
    wire signed [127:0] s1re_flat;
    wire signed [127:0] s1im_flat;

    // Instantiate DUT
    fft_stage1 uut (
        .xre_flat(xre_flat),
        .xim_flat(xim_flat),
        .s1re_flat(s1re_flat),
        .s1im_flat(s1im_flat)
    );

    // Clock (not actually used by DUT, but required by testbench rules)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset signal (not used by DUT but required by rules)
    reg rst;
    integer rst_count;
    initial begin
        rst = 1;
        rst_count = 0;
    end

    // Helper integers
    integer i;
    integer pass_count;
    integer fail_count;

    // Temporary variables for expected values
    reg signed [15:0] in_re [0:7];
    reg signed [15:0] in_im [0:7];
    reg signed [15:0] exp_re [0:7];
    reg signed [15:0] exp_im [0:7];
    reg signed [15:0] got_re [0:7];
    reg signed [15:0] got_im [0:7];

    integer test_pass;
    integer vec;

    // Task to pack flat buses
    task pack_inputs;
        integer idx;
        begin
            xre_flat = 128'b0;
            xim_flat = 128'b0;
            for (idx = 0; idx < 8; idx = idx + 1) begin
                xre_flat[idx*16 +: 16] = in_re[idx];
                xim_flat[idx*16 +: 16] = in_im[idx];
            end
        end
    endtask

    // Task to unpack output flat buses
    task unpack_outputs;
        integer idx;
        begin
            for (idx = 0; idx < 8; idx = idx + 1) begin
                got_re[idx] = s1re_flat[idx*16 +: 16];
                got_im[idx] = s1im_flat[idx*16 +: 16];
            end
        end
    endtask

    // Task to compute expected FFT stage1 butterfly outputs
    // Pairs: (0,4),(1,5),(2,6),(3,7) with twiddle W8^0 = (1,0)
    // out_hi = in_hi + in_lo, out_lo = in_hi - in_lo
    task compute_expected;
        integer idx;
        begin
            for (idx = 0; idx < 4; idx = idx + 1) begin
                exp_re[idx]   = in_re[idx] + in_re[idx+4];
                exp_im[idx]   = in_im[idx] + in_im[idx+4];
                exp_re[idx+4] = in_re[idx] - in_re[idx+4];
                exp_im[idx+4] = in_im[idx] - in_im[idx+4];
            end
        end
    endtask

    // Task to check outputs against expected
    task check_outputs;
        input [63:0] test_num;
        input [255:0] desc;
        integer idx;
        reg local_pass;
        begin
            local_pass = 1;
            unpack_outputs;
            for (idx = 0; idx < 8; idx = idx + 1) begin
                if (got_re[idx] !== exp_re[idx] || got_im[idx] !== exp_im[idx]) begin
                    local_pass = 0;
                end
            end
            if (local_pass) begin
                $display("PASS: Test %0d - %s", test_num, desc);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test %0d - %s", test_num, desc);
                for (idx = 0; idx < 8; idx = idx + 1) begin
                    $display("  [%0d] got_re=%0d exp_re=%0d  got_im=%0d exp_im=%0d",
                             idx, got_re[idx], exp_re[idx], got_im[idx], exp_im[idx]);
                end
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Assert reset for 5 rising edges
        rst = 1;
        @(posedge clk); // 1
        @(posedge clk); // 2
        @(posedge clk); // 3
        @(posedge clk); // 4
        @(posedge clk); // 5
        rst = 0;
        #2;

        // -------------------------------------------------------
        // Test 1: All zeros
        // -------------------------------------------------------
        for (i = 0; i < 8; i = i + 1) begin
            in_re[i] = 16'sd0;
            in_im[i] = 16'sd0;
        end
        pack_inputs;
        #2;
        compute_expected;
        check_outputs(1, "All zeros input");

        // -------------------------------------------------------
        // Test 2: All ones (real=1, imag=1)
        // -------------------------------------------------------
        for (i = 0; i < 8; i = i + 1) begin
            in_re[i] = 16'sd1;
            in_im[i] = 16'sd1;
        end
        pack_inputs;
        #2;
        compute_expected;
        check_outputs(2, "All ones input (re=1,im=1)");

        // -------------------------------------------------------
        // Test 3: All max positive (Q1.15 max = 32767)
        // -------------------------------------------------------
        for (i = 0; i < 8; i = i + 1) begin
            in_re[i] = 16'sd32767;
            in_im[i] = 16'sd32767;
        end
        pack_inputs;
        #2;
        compute_expected;
        check_outputs(3, "All max positive (32767)");

        // -------------------------------------------------------
        // Test 4: All max negative (-32768)
        // -------------------------------------------------------
        for (i = 0; i < 8; i = i + 1) begin
            in_re[i] = -16'sd32768;
            in_im[i] = -16'sd32768;
        end
        pack_inputs;
        #2;
        compute_expected;
        check_outputs(4, "All max negative (-32768)");

        // -------------------------------------------------------
        // Test 5: Typical case - distinct values
        // -------------------------------------------------------
        in_re[0] = 16'sd100;  in_im[0] = 16'sd200;
        in_re[1] = 16'sd300;  in_im[1] = 16'sd400;
        in_re[2] = 16'sd500;  in_im[2] = 16'sd600;
        in_re[3] = 16'sd700;  in_im[3] = 16'sd800;
        in_re[4] = 16'sd150;  in_im[4] = 16'sd250;
        in_re[5] = 16'sd350;  in_im[5] = 16'sd450;
        in_re[6] = 16'sd550;  in_im[6] = 16'sd650;
        in_re[7] = 16'sd750;  in_im[7] = 16'sd850;
        pack_inputs;
        #2;
        compute_expected;
        check_outputs(5, "Typical distinct positive values");

        // -------------------------------------------------------
        // Test 6: Mixed positive and negative
        // -------------------------------------------------------
        in_re[0] = 16'sd1000;   in_im[0] = -16'sd1000;
        in_re[1] = -16'sd2000;  in_im[1] = 16'sd2000;
        in_re[2] = 16'sd3000;   in_im[2] = -16'sd3000;
        in_re[3] = -16'sd4000;  in_im[3] = 16'sd4000;
        in_re[4] = 16'sd500;    in_im[4] = -16'sd500;
        in_re[5] = -16'sd1500;  in_im[5] = 16'sd1500;
        in_re[6] = 16'sd2500;   in_im[6] = -16'sd2500;
        in_re[7] = -16'sd3500;  in_im[7] = 16'sd3500;
        pack_inputs;
        #2;
        compute_expected;
        check_outputs(6, "Mixed positive and negative values");

        // -------------------------------------------------------
        // Test 7: Only lower half non-zero (idx 4-7 zero)
        // -------------------------------------------------------
        in_re[0] = 16'sd1000;  in_im[0] = 16'sd2000;
        in_re[1] = 16'sd3000;  in_im[1] = 16'sd4000;
        in_re[2] = 16'sd5000;  in_im[2] = 16'sd6000;
        in_re[3] = 16'sd7000;  in_im[3] = 16'sd8000;
        in_re[4] = 16'sd0;     in_im[4] = 16'sd0;
        in_re[5] = 16'sd0;     in_im[5] = 16'sd0;
        in_re[6] = 16'sd0;     in_im[6] = 16'sd0;
        in_re[7] = 16'sd0;     in_im[7] = 16'sd0;
        pack_inputs;
        #2;
        compute_expected;
        check_outputs(7, "Lower half non-zero, upper half zero");

        // -------------------------------------------------------
        // Test 8: Only upper half non-zero (idx 0-3 zero)
        // -------------------------------------------------------
        in_re[0] = 16'sd0;     in_im[0] = 16'sd0;
        in_re[1] = 16'sd0;     in_im[1] = 16'sd0;
        in_re[2] = 16'sd0;     in_im[2] = 16'sd0;
        in_re[3] = 16'sd0;     in_im[3] = 16'sd0;
        in_re[4] = 16'sd1000;  in_im[4] = 16'sd2000;
        in_re[5] = 16'sd3000;  in_im[5] = 16'sd4000;
        in_re[6] = 16'sd5000;  in_im[6] = 16'sd6000;
        in_re[7] = 16'sd7000;  in_im[7] = 16'sd8000;
        pack_inputs;
        #2;
        compute_expected;
        check_outputs(8, "Upper half non-zero, lower half zero");

        // -------------------------------------------------------
        // Test 9: Single non-zero element at index 0
        // -------------------------------------------------------
        for (i = 0; i < 8; i = i + 1) begin
            in_re[i] = 16'sd0;
            in_im[i] = 16'sd0;
        end
        in_re[0] = 16'sd1;
        pack_inputs;
        #2;
        compute_expected;
        check_outputs(9, "DC impulse: x[0]=1, rest zero");

        // -------------------------------------------------------
        // Test 10: Alternating max/min values
        // -------------------------------------------------------
        for (i = 0; i < 8; i = i + 1) begin
            if (i % 2 == 0) begin
                in_re[i] = 16'sd32767;
                in_im[i] = 16'sd32767;
            end else begin
                in_re[i] = -16'sd32768;
                in_im[i] = -16'sd32768;
            end
        end
        pack_inputs;
        #2;
        compute_expected;
        check_outputs(10, "Alternating max positive and max negative");

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        $display("------------------------------------");
        $display("Total PASS: %0d  Total FAIL: %0d", pass_count, fail_count);
        $display("------------------------------------");

        $finish;
    end

endmodule
