`timescale 1ns/1ps

module tb_fft_stage23;

    // DUT connections
    reg  signed [127:0] s1re_flat;
    reg  signed [127:0] s1im_flat;
    wire signed [127:0] s3re_flat;
    wire signed [127:0] s3im_flat;

    // Clock and reset
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    fft_stage23 uut (
        .s1re_flat(s1re_flat),
        .s1im_flat(s1im_flat),
        .s3re_flat(s3re_flat),
        .s3im_flat(s3im_flat)
    );

    // Helper integers
    integer i;
    integer fail_count;

    // Helper task to extract a 16-bit signed value from a flat 128-bit bus
    // index 0..7, each element is 16 bits
    // We'll work with 16-bit elements packed as 8 x 16-bit

    // Since the module is purely combinational (no clock or reset ports),
    // we drive inputs and check outputs after a small delay.

    // We'll use 16-bit signed elements packed into 128-bit buses
    // Element k occupies bits [16*k+15 : 16*k]

    // Tasks and functions
    function [15:0] get_elem;
        input [127:0] bus;
        input integer idx;
        begin
            get_elem = bus[16*idx +: 16];
        end
    endfunction

    // Variables for expected values
    reg signed [15:0] in_re [0:7];
    reg signed [15:0] in_im [0:7];
    reg signed [15:0] exp_re [0:7];
    reg signed [15:0] exp_im [0:7];
    reg signed [15:0] got_re [0:7];
    reg signed [15:0] got_im [0:7];

    // Combinational stage2+3 reference model
    // Stage 2: butterfly pairs (0,2),(1,3),(4,6),(5,7) with twiddle W^0 = (1,0)
    // Stage 3: butterfly pairs (0,1),(2,3),(4,5),(6,7) with twiddles
    //   pair(0,1): W^0=(1,0), pair(2,3): W^2=(0,-1), pair(4,5): W^0=(1,0), pair(6,7): W^2=(0,-1)
    // All arithmetic in 16-bit signed (no scaling assumed)

    reg signed [15:0] a_re, a_im, b_re, b_im;
    reg signed [15:0] tw_re, tw_im;
    reg signed [15:0] hi_re, hi_im, lo_re, lo_im;
    // temp after stage2
    reg signed [15:0] t_re [0:7];
    reg signed [15:0] t_im [0:7];

    // Reference computation task
    task compute_reference;
        integer k;
        // Stage 2 butterflies: (0,2),(1,3),(4,6),(5,7), twiddle W^0
        // pair (0,2): hi=0, lo=2
        begin
            // pair (0,2): twiddle W^0 = (1,0)
            a_re = in_re[0]; a_im = in_im[0];
            b_re = in_re[2]; b_im = in_im[2];
            // butterfly: hi = a + tw*b, lo = a - tw*b, tw=(1,0) => tw*b = b
            t_re[0] = a_re + b_re; t_im[0] = a_im + b_im;
            t_re[2] = a_re - b_re; t_im[2] = a_im - b_im;

            // pair (1,3): twiddle W^0 = (1,0)
            a_re = in_re[1]; a_im = in_im[1];
            b_re = in_re[3]; b_im = in_im[3];
            t_re[1] = a_re + b_re; t_im[1] = a_im + b_im;
            t_re[3] = a_re - b_re; t_im[3] = a_im - b_im;

            // pair (4,6): twiddle W^0 = (1,0)
            a_re = in_re[4]; a_im = in_im[4];
            b_re = in_re[6]; b_im = in_im[6];
            t_re[4] = a_re + b_re; t_im[4] = a_im + b_im;
            t_re[6] = a_re - b_re; t_im[6] = a_im - b_im;

            // pair (5,7): twiddle W^0 = (1,0)
            a_re = in_re[5]; a_im = in_im[5];
            b_re = in_re[7]; b_im = in_im[7];
            t_re[5] = a_re + b_re; t_im[5] = a_im + b_im;
            t_re[7] = a_re - b_re; t_im[7] = a_im - b_im;

            // Stage 3 butterflies: (0,1),(2,3),(4,5),(6,7)
            // pair (0,1): twiddle W^0 = (1,0)
            a_re = t_re[0]; a_im = t_im[0];
            b_re = t_re[1]; b_im = t_im[1];
            exp_re[0] = a_re + b_re; exp_im[0] = a_im + b_im;
            exp_re[1] = a_re - b_re; exp_im[1] = a_im - b_im;

            // pair (2,3): twiddle W^2 = (0,-1) => tw*b = (0*b_re - (-1)*b_im, 0*b_im + (-1)*b_re) = (b_im, -b_re)
            a_re = t_re[2]; a_im = t_im[2];
            b_re = t_re[3]; b_im = t_im[3];
            hi_re = a_re + b_im;  hi_im = a_im - b_re;
            lo_re = a_re - b_im;  lo_im = a_im + b_re;
            exp_re[2] = hi_re; exp_im[2] = hi_im;
            exp_re[3] = lo_re; exp_im[3] = lo_im;

            // pair (4,5): twiddle W^0 = (1,0)
            a_re = t_re[4]; a_im = t_im[4];
            b_re = t_re[5]; b_im = t_im[5];
            exp_re[4] = a_re + b_re; exp_im[4] = a_im + b_im;
            exp_re[5] = a_re - b_re; exp_im[5] = a_im - b_im;

            // pair (6,7): twiddle W^2 = (0,-1)
            a_re = t_re[6]; a_im = t_im[6];
            b_re = t_re[7]; b_im = t_im[7];
            hi_re = a_re + b_im;  hi_im = a_im - b_re;
            lo_re = a_re - b_im;  lo_im = a_im + b_re;
            exp_re[6] = hi_re; exp_im[6] = hi_im;
            exp_re[7] = lo_re; exp_im[7] = lo_im;
        end
    endtask

    // Pack array into flat bus
    task pack_inputs;
        integer k;
        begin
            s1re_flat = 128'b0;
            s1im_flat = 128'b0;
            for (k = 0; k < 8; k = k + 1) begin
                s1re_flat[16*k +: 16] = in_re[k];
                s1im_flat[16*k +: 16] = in_im[k];
            end
        end
    endtask

    // Check outputs
    task check_outputs;
        input [127:0] test_num;
        input [8*64-1:0] desc;
        integer k;
        reg pass;
        begin
            pass = 1;
            for (k = 0; k < 8; k = k + 1) begin
                got_re[k] = s3re_flat[16*k +: 16];
                got_im[k] = s3im_flat[16*k +: 16];
                if (got_re[k] !== exp_re[k] || got_im[k] !== exp_im[k]) begin
                    pass = 0;
                end
            end
            if (pass)
                $display("PASS: Test%0d %s", test_num, desc);
            else begin
                $display("FAIL: Test%0d %s", test_num, desc);
                fail_count = fail_count + 1;
                for (k = 0; k < 8; k = k + 1) begin
                    $display("  [%0d] got_re=%0d exp_re=%0d got_im=%0d exp_im=%0d",
                        k, got_re[k], exp_re[k], got_im[k], exp_im[k]);
                end
            end
        end
    endtask

    initial begin
        fail_count = 0;
        rst = 1;
        s1re_flat = 128'b0;
        s1im_flat = 128'b0;

        // Assert reset for 5 rising edges
        repeat(5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        //----------------------------------------------------------------------
        // Test 1: All zeros
        //----------------------------------------------------------------------
        begin : t1
            integer k;
            for (k = 0; k < 8; k = k + 1) begin
                in_re[k] = 16'sd0; in_im[k] = 16'sd0;
            end
            pack_inputs;
            #2;
            compute_reference;
            #1;
            check_outputs(1, "All zeros input");
        end

        //----------------------------------------------------------------------
        // Test 2: DC input x[0]=1, rest zero (re only)
        //----------------------------------------------------------------------
        begin : t2
            integer k;
            for (k = 0; k < 8; k = k + 1) begin
                in_re[k] = 16'sd0; in_im[k] = 16'sd0;
            end
            in_re[0] = 16'sd1;
            pack_inputs;
            #2;
            compute_reference;
            #1;
            check_outputs(2, "DC x[0]=1 only");
        end

        //----------------------------------------------------------------------
        // Test 3: All ones (real=1, imag=0)
        //----------------------------------------------------------------------
        begin : t3
            integer k;
            for (k = 0; k < 8; k = k + 1) begin
                in_re[k] = 16'sd1; in_im[k] = 16'sd0;
            end
            pack_inputs;
            #2;
            compute_reference;
            #1;
            check_outputs(3, "All real=1 imag=0");
        end

        //----------------------------------------------------------------------
        // Test 4: Identity twiddle check - W^0 case: in_re/im as butterfly pair
        //----------------------------------------------------------------------
        begin : t4
            integer k;
            for (k = 0; k < 8; k = k + 1) begin
                in_re[k] = 16'sd0; in_im[k] = 16'sd0;
            end
            // Set up so that stage2 pair (0,2) exercises butterfly
            in_re[0] = 16'sd100; in_im[0] = 16'sd50;
            in_re[2] = 16'sd30;  in_im[2] = 16'sd20;
            pack_inputs;
            #2;
            compute_reference;
            #1;
            check_outputs(4, "Butterfly pair (0,2) W^0 check");
        end

        //----------------------------------------------------------------------
        // Test 5: Maximum positive values
        //----------------------------------------------------------------------
        begin : t5
            integer k;
            for (k = 0; k < 8; k = k + 1) begin
                in_re[k] = 16'sd32767; in_im[k] = 16'sd0;
            end
            pack_inputs;
            #2;
            compute_reference;
            #1;
            check_outputs(5, "Max positive real values");
        end

        //----------------------------------------------------------------------
        // Test 6: All negative (minimum signed)
        //----------------------------------------------------------------------
        begin : t6
            integer k;
            for (k = 0; k < 8; k = k + 1) begin
                in_re[k] = -16'sd1; in_im[k] = -16'sd1;
            end
            pack_inputs;
            #2;
            compute_reference;
            #1;
            check_outputs(6, "All real=-1 imag=-1");
        end

        //----------------------------------------------------------------------
        // Test 7: Mixed positive and negative
        //----------------------------------------------------------------------
        begin : t7
            in_re[0] = 16'sd10;  in_im[0] = 16'sd0;
            in_re[1] = -16'sd5;  in_im[1] = 16'sd3;
            in_re[2] = 16'sd7;   in_im[2] = -16'sd2;
            in_re[3] = 16'sd0;   in_im[3] = 16'sd8;
            in_re[4] = -16'sd3;  in_im[4] = 16'sd1;
            in_re[5] = 16'sd4;   in_im[5] = -16'sd6;
            in_re[6] = 16'sd2;   in_im[6] = 16'sd5;
            in_re[7] = -16'sd9;  in_im[7] = -16'sd4;
            pack_inputs;
            #2;
            compute_reference;
            #1;
            check_outputs(7, "Mixed positive and negative values");
        end

        //----------------------------------------------------------------------
        // Test 8: W^2 twiddle path - set only elements 2,3 non-zero
        //----------------------------------------------------------------------
        begin : t8
            integer k;
            for (k = 0; k < 8; k = k + 1) begin
                in_re[k] = 16'sd0; in_im[k] = 16'sd0;
            end
            in_re[2] = 16'sd50;  in_im[2] = 16'sd25;
            in_re[3] = 16'sd30;  in_im[3] = -16'sd10;
            pack_inputs;
            #2;
            compute_reference;
            #1;
            check_outputs(8, "W^2 twiddle pair (2,3) only");
        end

        //----------------------------------------------------------------------
        // Test 9: W^2 twiddle path - set only elements 6,7 non-zero
        //----------------------------------------------------------------------
        begin : t9
            integer k;
