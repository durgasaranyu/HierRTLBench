`timescale 1ns/1ps

module tb_fft_top;

    // DUT connections
    reg  signed [127:0] xre_flat;
    reg  signed [127:0] xim_flat;
    wire signed [127:0] Xre_flat;
    wire signed [127:0] Xim_flat;

    // Clock and reset (not used by combinational DUT, but required by testbench spec)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Apply reset for 5 rising edges
    initial begin
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
    end

    // DUT instantiation
    fft8 uut (
        .xre_flat(xre_flat),
        .xim_flat(xim_flat),
        .Xre_flat(Xre_flat),
        .Xim_flat(Xim_flat)
    );

    // Helper function: extract 16-bit signed sample from flat bus
    // Index 0 = bits [15:0], index 7 = bits [127:112]
    // We use tasks/macros inline

    integer k;
    integer pass_count;
    integer fail_count;

    // Signed 16-bit values packed into 128-bit buses
    // xre_flat[16*i +: 16] = sample i real part
    // xim_flat[16*i +: 16] = sample i imag part

    reg signed [15:0] xre [0:7];
    reg signed [15:0] xim [0:7];
    reg signed [15:0] Xre [0:7];
    reg signed [15:0] Xim [0:7];

    // Task to pack arrays into flat buses
    task pack_inputs;
        integer j;
        begin
            xre_flat = 0;
            xim_flat = 0;
            for (j = 0; j < 8; j = j + 1) begin
                xre_flat[j*16 +: 16] = xre[j];
                xim_flat[j*16 +: 16] = xim[j];
            end
        end
    endtask

    // Task to unpack output flat buses
    task unpack_outputs;
        integer j;
        begin
            for (j = 0; j < 8; j = j + 1) begin
                Xre[j] = Xre_flat[j*16 +: 16];
                Xim[j] = Xim_flat[j*16 +: 16];
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Wait for reset to deassert
        @(negedge rst);
        @(posedge clk);
        #2; // small settle

        // -------------------------------------------------------
        // TEST 1: All-zero inputs -> all outputs should be zero
        // -------------------------------------------------------
        for (k = 0; k < 8; k = k + 1) begin
            xre[k] = 0;
            xim[k] = 0;
        end
        pack_inputs;
        #20;
        unpack_outputs;
        begin
            reg all_zero;
            integer j2;
            all_zero = 1;
            for (j2 = 0; j2 < 8; j2 = j2 + 1) begin
                if (Xre[j2] !== 16'sd0 || Xim[j2] !== 16'sd0)
                    all_zero = 0;
            end
            if (all_zero) begin
                $display("PASS: All-zero input -> all-zero output");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: All-zero input -> expected all-zero output");
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // TEST 2: DC only - x[0]=1 (in Q1.15, value 1 = 16'h0001), rest zero
        // For 8-point FFT: X[k] = sum x[n] * W^(nk)
        // With only x[0]=1, X[k] = 1 for all k (no scaling)
        // Note: output is bit-reversed order
        // -------------------------------------------------------
        for (k = 0; k < 8; k = k + 1) begin
            xre[k] = 0;
            xim[k] = 0;
        end
        xre[0] = 16'sd1;
        pack_inputs;
        #20;
        unpack_outputs;
        // X[0] should be 1 (real), 0 (imag)
        if (Xre[0] === 16'sd1 && Xim[0] === 16'sd0) begin
            $display("PASS: DC input x[0]=1, X[0] real=1 imag=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: DC input x[0]=1, X[0] real=%0d imag=%0d (expected 1,0)", 
                     $signed(Xre[0]), $signed(Xim[0]));
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 3: DC only continued - all bins should equal 1 for x[0]=1
        // (bit-reversed order: X[0..7] all = 1)
        // -------------------------------------------------------
        begin
            reg all_one;
            integer j3;
            all_one = 1;
            for (j3 = 0; j3 < 8; j3 = j3 + 1) begin
                if (Xre[j3] !== 16'sd1 || Xim[j3] !== 16'sd0)
                    all_one = 0;
            end
            if (all_one) begin
                $display("PASS: DC input x[0]=1, all X[k]=1+j0");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: DC input x[0]=1, not all X[k]=1+j0");
                for (j3 = 0; j3 < 8; j3 = j3 + 1)
                    $display("  X[%0d] = %0d + j%0d", j3, $signed(Xre[j3]), $signed(Xim[j3]));
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // TEST 4: x[0]=16384 (0.5 in Q1.15) only, rest zero
        // X[k] = 16384 for all k
        // -------------------------------------------------------
        for (k = 0; k < 8; k = k + 1) begin
            xre[k] = 0;
            xim[k] = 0;
        end
        xre[0] = 16'sd16384;
        pack_inputs;
        #20;
        unpack_outputs;
        begin
            reg ok4;
            integer j4;
            ok4 = 1;
            for (j4 = 0; j4 < 8; j4 = j4 + 1) begin
                if (Xre[j4] !== 16'sd16384 || Xim[j4] !== 16'sd0)
                    ok4 = 0;
            end
            if (ok4) begin
                $display("PASS: DC input x[0]=16384, all X[k]=16384+j0");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: DC input x[0]=16384, not all X[k]=16384+j0");
                for (j4 = 0; j4 < 8; j4 = j4 + 1)
                    $display("  X[%0d] = %0d + j%0d", j4, $signed(Xre[j4]), $signed(Xim[j4]));
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // TEST 5: All-ones real input (16'h7FFF = 32767), imag=0
        // X[0] = sum of all inputs = 8*32767, others = 0
        // But bit-reversed: X[0] = 8*32767, X[1..7] = 0
        // Note: overflow may occur in fixed point
        // We just check X[0] and X[1..7] pattern
        // -------------------------------------------------------
        for (k = 0; k < 8; k = k + 1) begin
            xre[k] = 16'sd32767;
            xim[k] = 16'sd0;
        end
        pack_inputs;
        #20;
        unpack_outputs;
        // X[1..7] should all be 0 (real and imag)
        begin
            reg ok5;
            integer j5;
            ok5 = 1;
            for (j5 = 1; j5 < 8; j5 = j5 + 1) begin
                if (Xre[j5] !== 16'sd0 || Xim[j5] !== 16'sd0)
                    ok5 = 0;
            end
            if (ok5) begin
                $display("PASS: All-ones input, X[1..7]=0");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: All-ones input, X[1..7] not all zero");
                for (j5 = 1; j5 < 8; j5 = j5 + 1)
                    $display("  X[%0d] = %0d + j%0d", j5, $signed(Xre[j5]), $signed(Xim[j5]));
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // TEST 6: Impulse at x[1]=1, rest zero
        // X[k] = W^k = e^(-j*2*pi*k/8)
        // Check X[0] = 1 (since sum = 1*W^0 = 1)
        // -------------------------------------------------------
        for (k = 0; k < 8; k = k + 1) begin
            xre[k] = 0;
            xim[k] = 0;
        end
        xre[1] = 16'sd1;
        pack_inputs;
        #20;
        unpack_outputs;
        // X[0] = x[1] * W^(1*0) = 1*1 = 1
        if (Xre[0] === 16'sd1 && Xim[0] === 16'sd0) begin
            $display("PASS: Impulse at x[1]=1, X[0]=1+j0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Impulse at x[1]=1, X[0]=%0d+j%0d (expected 1+j0)", 
                     $signed(Xre[0]), $signed(Xim[0]));
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 7: Alternating pattern x[n] = (-1)^n -> only X[4] nonzero
        // x = [1, -1, 1, -1, 1, -1, 1, -1]
        // X[4] = 8, X[k!=4] = 0 (in bit-reversed output, bin 4 -> index 4)
        // In bit-reversed 8-pt: bit_rev(4) = bit_rev(100b) = 001b = 1
        // Actually let's just verify X[0] = 0
        // -------------------------------------------------------
        for (k = 0; k < 8; k = k + 1) begin
            xim[k] = 16'sd0;
            if (k[0] == 0)
                xre[k] = 16'sd1;
            else
                xre[k] = -16'sd1;
        end
        pack_inputs;
        #20;
        unpack_outputs;
        // For alternating input [1,-1,1,-1,1,-1,1,-1]:
        // X[0] = sum = 0
        if (Xre[0] === 16'sd0 && Xim[0] === 16'sd0) begin
            $display("PASS: Alternating input, X[0]=0+j0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Alternating input, X[0]=%0d+j%0d (expected 0+j0)",
                     $signed(Xre[0]), $signed(Xim[0]));
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 8: Single complex input x[0]=1+j1, rest zero
        // X[k] = 1+j1 for all k
        // -------------------------------------------------------
        for (k = 0; k < 8; k = k + 1) begin
            xre[k] = 0;
            xim[k] = 0;
        end
        xre[0] = 16'sd1;
        xim[0] = 16'sd1;
        pack_inputs;
        #20;
        unpack_outputs;
        begin
            reg ok8;
            integer j8;
            ok8 = 1;
            for (j8 = 0; j8 < 8; j8 = j8 + 1) begin
                if (Xre[j8] !== 16'sd1 || Xim[j8] !== 16'sd1)
                    ok8 = 0;
            end
            if (ok8) begin
                $display("PASS: Complex DC input x[0]=1+j1, all X[k]=1+j1");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Complex DC input x[0]=1+j1, not all X[k]=1+j1");
                for (j8 = 0; j8 < 8; j8 = j8 + 1)
                    $display("  X[%0d] = %0d + j%0d", j8, $signed(Xre[j8]), $signed(Xim[j8]));
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // TEST 9: Maximum negative value x[0]=-32768
        // X[k] = -32768 for all k
        // -------------------------------------------------------
        for (k = 0; k < 8; k = k + 1) begin
            xre[k] = 0;
            xim[k] = 0;
        end
        xre[0] = -16'sd32768;
        pack_inputs;
        #20;
        unpack_outputs;
        begin
            reg ok9;
            integer j9;
            ok9 = 1;
            for (j9 = 0; j9 < 8; j9 = j9 + 1) begin
                if (Xre[j9] !== -16'sd32768 || Xim[j9] !== 16'sd0)
                    ok9 = 0;
            end
            if (ok9) begin
                $display("PASS: Max-negative DC input x[0]=-32768, all X[k]=-32768+j0");
                pass_count = pass
