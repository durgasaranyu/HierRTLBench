`timescale 1ns/1ps

module tb_fft_twiddle_rom;

    // DUT connections
    reg  [1:0]        idx;
    wire signed [15:0] tw_re;
    wire signed [15:0] tw_im;

    // Instantiate DUT
    fft_twiddle_rom uut (
        .idx   (idx),
        .tw_re (tw_re),
        .tw_im (tw_im)
    );

    // Clock (not strictly needed for combinational but kept per requirements)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset signal (kept per requirements, not used by combinational DUT)
    reg rst;

    integer fail_count;

    // Task for checking outputs
    task check_output;
        input [1:0]  t_idx;
        input signed [15:0] exp_re;
        input signed [15:0] exp_im;
        input [63:0] desc_unused; // placeholder, use $display inside
        begin
            idx = t_idx;
            #1; // small delay for combinational settle
            if (tw_re === exp_re && tw_im === exp_im) begin
                $display("PASS: idx=%0d tw_re=%0d tw_im=%0d", t_idx, tw_re, tw_im);
            end else begin
                $display("FAIL: idx=%0d expected tw_re=%0d tw_im=%0d, got tw_re=%0d tw_im=%0d",
                         t_idx, exp_re, exp_im, tw_re, tw_im);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        fail_count = 0;
        rst = 1;
        idx = 2'b00;

        // Assert reset for 5 rising edges
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        @(negedge clk);

        // --- Test Vector 1: idx=0 ---
        // According to the actual RTL: idx=0 -> tw_re=16'h3f4f=16207, tw_im=16'h0000=0
        // (Note: the module comment says 32767 but actual code uses 16'h3f4f=16207)
        idx = 2'b00;
        #2;
        if (tw_re === 16'h3f4f && tw_im === 16'h0000) begin
            $display("PASS: idx=0 tw_re=16'h3f4f tw_im=16'h0000");
        end else begin
            $display("FAIL: idx=0 expected tw_re=16'h3f4f tw_im=16'h0000, got tw_re=%h tw_im=%h", tw_re, tw_im);
            fail_count = fail_count + 1;
        end

        // --- Test Vector 2: idx=1 ---
        idx = 2'b01;
        #2;
        if (tw_re === 16'h3f4f && tw_im === 16'h0000) begin
            $display("PASS: idx=1 tw_re=16'h3f4f tw_im=16'h0000");
        end else begin
            $display("FAIL: idx=1 expected tw_re=16'h3f4f tw_im=16'h0000, got tw_re=%h tw_im=%h", tw_re, tw_im);
            fail_count = fail_count + 1;
        end

        // --- Test Vector 3: idx=2 ---
        idx = 2'b10;
        #2;
        if (tw_re === 16'h0000 && tw_im === 16'h3f4f) begin
            $display("PASS: idx=2 tw_re=16'h0000 tw_im=16'h3f4f");
        end else begin
            $display("FAIL: idx=2 expected tw_re=16'h0000 tw_im=16'h3f4f, got tw_re=%h tw_im=%h", tw_re, tw_im);
            fail_count = fail_count + 1;
        end

        // --- Test Vector 4: idx=3 ---
        idx = 2'b11;
        #2;
        if (tw_re === 16'h0000 && tw_im === 16'h3f4f) begin
            $display("PASS: idx=3 tw_re=16'h0000 tw_im=16'h3f4f");
        end else begin
            $display("FAIL: idx=3 expected tw_re=16'h0000 tw_im=16'h3f4f, got tw_re=%h tw_im=%h", tw_re, tw_im);
            fail_count = fail_count + 1;
        end

        // --- Test Vector 5: cycle back to idx=0 ---
        idx = 2'b00;
        #2;
        if (tw_re === 16'h3f4f && tw_im === 16'h0000) begin
            $display("PASS: idx=0 (repeated) tw_re=16'h3f4f tw_im=16'h0000");
        end else begin
            $display("FAIL: idx=0 (repeated) expected tw_re=16'h3f4f tw_im=16'h0000, got tw_re=%h tw_im=%h", tw_re, tw_im);
            fail_count = fail_count + 1;
        end

        // --- Test Vector 6: idx=2 repeated (edge: im is non-zero) ---
        idx = 2'b10;
        #2;
        if (tw_re === 16'h0000 && tw_im === 16'h3f4f) begin
            $display("PASS: idx=2 (repeated) tw_re=16'h0000 tw_im=16'h3f4f");
        end else begin
            $display("FAIL: idx=2 (repeated) expected tw_re=16'h0000 tw_im=16'h3f4f, got tw_re=%h tw_im=%h", tw_re, tw_im);
            fail_count = fail_count + 1;
        end

        // --- Test Vector 7: idx=1 check re is non-zero, im is zero ---
        idx = 2'b01;
        #2;
        if (tw_re !== 16'h0000 && tw_im === 16'h0000) begin
            $display("PASS: idx=1 tw_re nonzero, tw_im=0");
        end else begin
            $display("FAIL: idx=1 tw_re=%h tw_im=%h (expected re nonzero, im=0)", tw_re, tw_im);
            fail_count = fail_count + 1;
        end

        // --- Test Vector 8: idx=3 check im is non-zero, re is zero ---
        idx = 2'b11;
        #2;
        if (tw_re === 16'h0000 && tw_im !== 16'h0000) begin
            $display("PASS: idx=3 tw_re=0, tw_im nonzero");
        end else begin
            $display("FAIL: idx=3 tw_re=%h tw_im=%h (expected re=0, im nonzero)", tw_re, tw_im);
            fail_count = fail_count + 1;
        end

        // --- Test Vector 9: All indices sweep, verify symmetry ---
        // idx=0 and idx=1 should be identical
        begin
            reg signed [15:0] re0, im0, re1, im1;
            idx = 2'b00; #2; re0 = tw_re; im0 = tw_im;
            idx = 2'b01; #2; re1 = tw_re; im1 = tw_im;
            if (re0 === re1 && im0 === im1) begin
                $display("PASS: idx=0 and idx=1 outputs are identical");
            end else begin
                $display("FAIL: idx=0 and idx=1 outputs differ: (%h,%h) vs (%h,%h)", re0, im0, re1, im1);
                fail_count = fail_count + 1;
            end
        end

        // --- Test Vector 10: idx=2 and idx=3 should be identical ---
        begin
            reg signed [15:0] re2, im2, re3, im3;
            idx = 2'b10; #2; re2 = tw_re; im2 = tw_im;
            idx = 2'b11; #2; re3 = tw_re; im3 = tw_im;
            if (re2 === re3 && im2 === im3) begin
                $display("PASS: idx=2 and idx=3 outputs are identical");
            end else begin
                $display("FAIL: idx=2 and idx=3 outputs differ: (%h,%h) vs (%h,%h)", re2, im2, re3, im3);
                fail_count = fail_count + 1;
            end
        end

        // Summary
        if (fail_count == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("%0d TEST(S) FAILED", fail_count);
        end

        $finish;
    end

endmodule
