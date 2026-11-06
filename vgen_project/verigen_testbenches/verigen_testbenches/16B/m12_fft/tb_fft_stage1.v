`timescale 1ns/1ps

module tb_fft_stage1;

    // DUT ports
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

    // Clock (not really needed for combinational, but required by spec)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not used by DUT ports, but required by spec)
    reg rst;
    integer i;

    // Helper task to pack 8 x 16-bit signed values into a 128-bit flat bus
    // We pass individual values and pack manually

    // Signed 16-bit extraction from flat bus
    function signed [15:0] get16;
        input [127:0] flat;
        input integer idx; // 0..7
        begin
            get16 = flat[idx*16 +: 16];
        end
    endfunction

    // Expected values storage
    reg signed [15:0] exp_re [0:7];
    reg signed [15:0] exp_im [0:7];
    reg signed [15:0] got_re [0:7];
    reg signed [15:0] got_im [0:7];

    integer pass_flag;
    integer test_num;

    // Task: check outputs against expected
    task check_outputs;
        input [63:0] test_id;
        input [255:0] desc_bits; // not really used for string, use test_id
        integer k;
        integer ok;
        begin
            ok = 1;
            for (k = 0; k < 8; k = k + 1) begin
                got_re[k] = s1re_flat[k*16 +: 16];
                got_im[k] = s1im_flat[k*16 +: 16];
                if (got_re[k] !== exp_re[k] || got_im[k] !== exp_im[k]) begin
                    ok = 0;
                end
            end
            if (ok)
                $display("PASS: Test %0d", test_id);
            else begin
                $display("FAIL: Test %0d", test_id);
                for (k = 0; k < 8; k = k + 1) begin
                    $display("  out[%0d]: re got=%0d exp=%0d  im got=%0d exp=%0d",
                        k, got_re[k], exp_re[k], got_im[k], exp_im[k]);
                end
            end
        end
    endtask

    // Pack helper: set xre_flat and xim_flat from arrays
    reg signed [15:0] in_re [0:7];
    reg signed [15:0] in_im [0:7];

    task apply_inputs;
        integer k;
        begin
            for (k = 0; k < 8; k = k + 1) begin
                xre_flat[k*16 +: 16] = in_re[k];
                xim_flat[k*16 +: 16] = in_im[k];
            end
        end
    endtask

    // The module computes 4 butterflies on pairs (0,4),(1,5),(2,6),(3,7) with W8^0.
    // W8^0 = 1+0j => twiddle is (32767, 0) in Q1.15
    // Butterfly: out_hi = in_hi + tw*in_lo = in_hi + in_lo
    //            out_lo = in_hi - tw*in_lo = in_hi - in_lo
    // Since module is combinational, we just apply and check immediately.
    // NOTE: The DUT source is truncated, so we can only verify what the spec says.
    // We model the expected behavior: butterfly with W^0 twiddle.
    // For pair (n, n+4): s1[n] = x[n] + x[n+4], s1[n+4] = x[n] - x[n+4]
    // With Q1.15 arithmetic (addition may saturate or just add, we assume plain add)

    // We'll use plain 16-bit signed addition for expected values.

    task compute_expected_butterfly;
        integer k;
        reg signed [15:0] hi_re, hi_im, lo_re, lo_im;
        begin
            for (k = 0; k < 4; k = k + 1) begin
                hi_re = in_re[k];
                hi_im = in_im[k];
                lo_re = in_re[k+4];
                lo_im = in_im[k+4];
                // W^0: tw_re=1, tw_im=0 => tw*lo = lo
                // tw*lo_re = lo_re, tw*lo_im = lo_im (with W^0)
                exp_re[k]   = hi_re + lo_re;
                exp_im[k]   = hi_im + lo_im;
                exp_re[k+4] = hi_re - lo_re;
                exp_im[k+4] = hi_im - lo_im;
            end
        end
    endtask

    // Reset sequence
    initial begin
        rst = 1;
        xre_flat = 128'd0;
        xim_flat = 128'd0;

        // Assert reset for 5 rising edges
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        #2; // small settle time

        // ===== Test 1: All zeros =====
        begin
            in_re[0]=0; in_re[1]=0; in_re[2]=0; in_re[3]=0;
            in_re[4]=0; in_re[5]=0; in_re[6]=0; in_re[7]=0;
            in_im[0]=0; in_im[1]=0; in_im[2]=0; in_im[3]=0;
            in_im[4]=0; in_im[5]=0; in_im[6]=0; in_im[7]=0;
            apply_inputs;
            compute_expected_butterfly;
            #1;
            check_outputs(1, 0);
        end

        // ===== Test 2: All ones (real=1, imag=0) =====
        begin
            in_re[0]=16'd1; in_re[1]=16'd1; in_re[2]=16'd1; in_re[3]=16'd1;
            in_re[4]=16'd1; in_re[5]=16'd1; in_re[6]=16'd1; in_re[7]=16'd1;
            in_im[0]=0; in_im[1]=0; in_im[2]=0; in_im[3]=0;
            in_im[4]=0; in_im[5]=0; in_im[6]=0; in_im[7]=0;
            apply_inputs;
            compute_expected_butterfly;
            #1;
            check_outputs(2, 0);
        end

        // ===== Test 3: DC only x[0]=1, rest 0 (real) =====
        begin
            in_re[0]=16'd1; in_re[1]=0; in_re[2]=0; in_re[3]=0;
            in_re[4]=0;     in_re[5]=0; in_re[6]=0; in_re[7]=0;
            in_im[0]=0; in_im[1]=0; in_im[2]=0; in_im[3]=0;
            in_im[4]=0; in_im[5]=0; in_im[6]=0; in_im[7]=0;
            apply_inputs;
            compute_expected_butterfly;
            #1;
            check_outputs(3, 0);
        end

        // ===== Test 4: Max positive value =====
        begin
            in_re[0]=16'sd32767; in_re[1]=16'sd32767; in_re[2]=16'sd32767; in_re[3]=16'sd32767;
            in_re[4]=16'sd0;     in_re[5]=16'sd0;     in_re[6]=16'sd0;     in_re[7]=16'sd0;
            in_im[0]=0; in_im[1]=0; in_im[2]=0; in_im[3]=0;
            in_im[4]=0; in_im[5]=0; in_im[6]=0; in_im[7]=0;
            apply_inputs;
            compute_expected_butterfly;
            #1;
            check_outputs(4, 0);
        end

        // ===== Test 5: Max negative value (all-ones pattern) =====
        begin
            in_re[0]=-16'sd32768; in_re[1]=-16'sd32768; in_re[2]=-16'sd32768; in_re[3]=-16'sd32768;
            in_re[4]=-16'sd32768; in_re[5]=-16'sd32768; in_re[6]=-16'sd32768; in_re[7]=-16'sd32768;
            in_im[0]=0; in_im[1]=0; in_im[2]=0; in_im[3]=0;
            in_im[4]=0; in_im[5]=0; in_im[6]=0; in_im[7]=0;
            apply_inputs;
            compute_expected_butterfly;
            #1;
            check_outputs(5, 0);
        end

        // ===== Test 6: Alternating +/-1 =====
        begin
            in_re[0]=16'sd1;  in_re[1]=-16'sd1; in_re[2]=16'sd1;  in_re[3]=-16'sd1;
            in_re[4]=-16'sd1; in_re[5]=16'sd1;  in_re[6]=-16'sd1; in_re[7]=16'sd1;
            in_im[0]=0; in_im[1]=0; in_im[2]=0; in_im[3]=0;
            in_im[4]=0; in_im[5]=0; in_im[6]=0; in_im[7]=0;
            apply_inputs;
            compute_expected_butterfly;
            #1;
            check_outputs(6, 0);
        end

        // ===== Test 7: Complex inputs =====
        begin
            in_re[0]=16'sd100;  in_re[1]=16'sd200;  in_re[2]=16'sd300;  in_re[3]=16'sd400;
            in_re[4]=16'sd500;  in_re[5]=16'sd600;  in_re[6]=16'sd700;  in_re[7]=16'sd800;
            in_im[0]=16'sd50;   in_im[1]=16'sd60;   in_im[2]=16'sd70;   in_im[3]=16'sd80;
            in_im[4]=16'sd10;   in_im[5]=16'sd20;   in_im[6]=16'sd30;   in_im[7]=16'sd40;
            apply_inputs;
            compute_expected_butterfly;
            #1;
            check_outputs(7, 0);
        end

        // ===== Test 8: Mixed positive/negative complex =====
        begin
            in_re[0]=16'sd1000;  in_re[1]=-16'sd2000; in_re[2]=16'sd3000;  in_re[3]=-16'sd4000;
            in_re[4]=-16'sd1000; in_re[5]=16'sd2000;  in_re[6]=-16'sd3000; in_re[7]=16'sd4000;
            in_im[0]=-16'sd500;  in_im[1]=16'sd600;   in_im[2]=-16'sd700;  in_im[3]=16'sd800;
            in_im[4]=16'sd500;   in_im[5]=-16'sd600;  in_im[6]=16'sd700;   in_im[7]=-16'sd800;
            apply_inputs;
            compute_expected_butterfly;
            #1;
            check_outputs(8, 0);
        end

        // ===== Test 9: Only imaginary part nonzero =====
        begin
            in_re[0]=0; in_re[1]=0; in_re[2]=0; in_re[3]=0;
            in_re[4]=0; in_re[5]=0; in_re[6]=0; in_re[7]=0;
            in_im[0]=16'sd1000; in_im[1]=16'sd2000; in_im[2]=16'sd3000; in_im[3]=16'sd4000;
            in_im[4]=16'sd1000; in_im[5]=16'sd2000; in_im[6]=16'sd3000; in_im[7]=16'sd4000;
            apply_inputs;
            compute_expected_butterfly;
            #1;
            check_outputs(9, 0);
        end

        // ===== Test 10: Single nonzero in second half =====
        begin
            in_re[0]=0; in_re[1]=0; in_re[2]=0; in_re[3]=0;
            in_re[4]=16'sd32767; in_re[5]=0; in_re[6]=0; in_re[7]=0;
            in_im[0]=0; in_im[1]=0; in_im[2]=0; in_im[3]=0;
            in_im[4]=0; in_im[5]=0; in_im[6]=0; in_im[7]=0;
            apply_inputs;
            compute_expected_butterfly;
            #1;
            check_outputs(10, 0);
        end

        #10;
        $finish;
    end

endmodule
