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

    // Clock (not strictly needed for combinational but required by spec)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not strictly needed but required by spec)
    reg rst;
    integer i;

    // Task: apply input and check
    task check;
        input [7:0] in_a;
        input [7:0] exp_xtime;
        input [7:0] exp_x3;
        input [63:0] desc1;
        input [63:0] desc2;
        reg [7:0] my_xtime;
        reg [7:0] my_x3;
        begin
            a = in_a;
            #2; // let combinational settle
            my_xtime = {in_a[6:0], in_a[7] ^ in_a[0]};
            my_x3    = my_xtime ^ {my_xtime[6:0], my_xtime[7]};
            if (xtime_a === exp_xtime && x3_a === exp_x3) begin
                $display("PASS: a=0x%02h xtime_a=0x%02h x3_a=0x%02h", in_a, xtime_a, x3_a);
            end else begin
                $display("FAIL: a=0x%02h expected xtime_a=0x%02h got 0x%02h, expected x3_a=0x%02h got 0x%02h",
                         in_a, exp_xtime, xtime_a, exp_x3, x3_a);
            end
        end
    endtask

    // Function to compute expected xtime
    function [7:0] f_xtime;
        input [7:0] v;
        begin
            f_xtime = {v[6:0], v[7] ^ v[0]};
        end
    endfunction

    // Function to compute expected x3
    function [7:0] f_x3;
        input [7:0] v;
        reg [7:0] xt;
        begin
            xt    = {v[6:0], v[7] ^ v[0]};
            f_x3  = xt ^ {xt[6:0], xt[7]};
        end
    endfunction

    // Reset sequence
    initial begin
        rst = 1;
        a   = 8'h00;
        // Hold reset for 5 rising edges
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        // Wait a bit after reset
        #3;

        // -------------------------------------------------------
        // Test 1: a = 0x00 (all zeros)
        // xtime(0x00) = 0x00, x3(0x00) = 0x00
        // -------------------------------------------------------
        a = 8'h00;
        #2;
        if (xtime_a === 8'h00 && x3_a === 8'h00)
            $display("PASS: a=0x00 (all zeros) xtime_a=0x00 x3_a=0x00");
        else
            $display("FAIL: a=0x00 (all zeros) xtime_a=0x%02h x3_a=0x%02h (expected 0x00, 0x00)", xtime_a, x3_a);

        // -------------------------------------------------------
        // Test 2: a = 0xFF (all ones)
        // xtime(0xFF) = {0x7F, 1^1} = {7'b1111111, 0} = 0xFE
        //             = 8'b11111110 = 0xFE
        // x3(0xFF) = xtime ^ rot_left_1(xtime)
        //          = 0xFE ^ {0xFE[6:0], 0xFE[7]}
        //          = 0xFE ^ {7'b1111110, 1} = 0xFE ^ 0xFD = 0x03
        // -------------------------------------------------------
        a = 8'hFF;
        #2;
        if (xtime_a === f_xtime(8'hFF) && x3_a === f_x3(8'hFF))
            $display("PASS: a=0xFF (all ones) xtime_a=0x%02h x3_a=0x%02h", xtime_a, x3_a);
        else
            $display("FAIL: a=0xFF (all ones) xtime_a=0x%02h x3_a=0x%02h (expected 0x%02h, 0x%02h)",
                     xtime_a, x3_a, f_xtime(8'hFF), f_x3(8'hFF));

        // -------------------------------------------------------
        // Test 3: a = 0x01 (LSB set only)
        // xtime(0x01) = {0,1} = 0x02 (shift left, MSB=0 so no XOR)
        // Actually: {a[6:0], a[7]^a[0]} = {7'b0000000, 0^1} = 0x01
        // Wait: a=0x01 => a[7:0]=00000001
        //   xtime = {a[6:0], a[7]^a[0]} = {0000000, 0^1} = 0x01
        // Hmm, this is a rotate with conditional XOR on bit0.
        // -------------------------------------------------------
        a = 8'h01;
        #2;
        if (xtime_a === f_xtime(8'h01) && x3_a === f_x3(8'h01))
            $display("PASS: a=0x01 xtime_a=0x%02h x3_a=0x%02h", xtime_a, x3_a);
        else
            $display("FAIL: a=0x01 xtime_a=0x%02h x3_a=0x%02h (expected 0x%02h, 0x%02h)",
                     xtime_a, x3_a, f_xtime(8'h01), f_x3(8'h01));

        // -------------------------------------------------------
        // Test 4: a = 0x80 (MSB set only)
        // xtime(0x80) = {1000000, 1^0} = {1000000, 1} = 0x81? 
        // a[7]=1, a[0]=0 => {a[6:0], a[7]^a[0]} = {0000000, 1^0} = 0x01? 
        // a=0x80=10000000 => a[6:0]=0000000, a[7]=1, a[0]=0
        // xtime = {0000000, 1^0} = {0000000, 1} = 0x01
        // -------------------------------------------------------
        a = 8'h80;
        #2;
        if (xtime_a === f_xtime(8'h80) && x3_a === f_x3(8'h80))
            $display("PASS: a=0x80 (MSB only) xtime_a=0x%02h x3_a=0x%02h", xtime_a, x3_a);
        else
            $display("FAIL: a=0x80 (MSB only) xtime_a=0x%02h x3_a=0x%02h (expected 0x%02h, 0x%02h)",
                     xtime_a, x3_a, f_xtime(8'h80), f_x3(8'h80));

        // -------------------------------------------------------
        // Test 5: a = 0x53 (AES S-box related value)
        // -------------------------------------------------------
        a = 8'h53;
        #2;
        if (xtime_a === f_xtime(8'h53) && x3_a === f_x3(8'h53))
            $display("PASS: a=0x53 xtime_a=0x%02h x3_a=0x%02h", xtime_a, x3_a);
        else
            $display("FAIL: a=0x53 xtime_a=0x%02h x3_a=0x%02h (expected 0x%02h, 0x%02h)",
                     xtime_a, x3_a, f_xtime(8'h53), f_x3(8'h53));

        // -------------------------------------------------------
        // Test 6: a = 0xAB
        // -------------------------------------------------------
        a = 8'hAB;
        #2;
        if (xtime_a === f_xtime(8'hAB) && x3_a === f_x3(8'hAB))
            $display("PASS: a=0xAB xtime_a=0x%02h x3_a=0x%02h", xtime_a, x3_a);
        else
            $display("FAIL: a=0xAB xtime_a=0x%02h x3_a=0x%02h (expected 0x%02h, 0x%02h)",
                     xtime_a, x3_a, f_xtime(8'hAB), f_x3(8'hAB));

        // -------------------------------------------------------
        // Test 7: a = 0x5A (alternating bits)
        // -------------------------------------------------------
        a = 8'h5A;
        #2;
        if (xtime_a === f_xtime(8'h5A) && x3_a === f_x3(8'h5A))
            $display("PASS: a=0x5A xtime_a=0x%02h x3_a=0x%02h", xtime_a, x3_a);
        else
            $display("FAIL: a=0x5A xtime_a=0x%02h x3_a=0x%02h (expected 0x%02h, 0x%02h)",
                     xtime_a, x3_a, f_xtime(8'h5A), f_x3(8'h5A));

        // -------------------------------------------------------
        // Test 8: a = 0xA5 (alternating bits, complement of 0x5A)
        // -------------------------------------------------------
        a = 8'hA5;
        #2;
        if (xtime_a === f_xtime(8'hA5) && x3_a === f_x3(8'hA5))
            $display("PASS: a=0xA5 xtime_a=0x%02h x3_a=0x%02h", xtime_a, x3_a);
        else
            $display("FAIL: a=0xA5 xtime_a=0x%02h x3_a=0x%02h (expected 0x%02h, 0x%02h)",
                     xtime_a, x3_a, f_xtime(8'hA5), f_x3(8'hA5));

        // -------------------------------------------------------
        // Test 9: a = 0x10 (typical mid-range value)
        // -------------------------------------------------------
        a = 8'h10;
        #2;
        if (xtime_a === f_xtime(8'h10) && x3_a === f_x3(8'h10))
            $display("PASS: a=0x10 xtime_a=0x%02h x3_a=0x%02h", xtime_a, x3_a);
        else
            $display("FAIL: a=0x10 xtime_a=0x%02h x3_a=0x%02h (expected 0x%02h, 0x%02h)",
                     xtime_a, x3_a, f_xtime(8'h10), f_x3(8'h10));

        // -------------------------------------------------------
        // Test 10: a = 0xE3 (another arbitrary value)
        // -------------------------------------------------------
        a = 8'hE3;
        #2;
        if (xtime_a === f_xtime(8'hE3) && x3_a === f_x3(8'hE3))
            $display("PASS: a=0xE3 xtime_a=0x%02h x3_a=0x%02h", xtime_a, x3_a);
        else
            $display("FAIL: a=0xE3 xtime_a=0x%02h x3_a=0x%02h (expected 0x%02h, 0x%02h)",
                     xtime_a, x3_a, f_xtime(8'hE3), f_x3(8'hE3));

        // -------------------------------------------------------
        // Exhaustive sweep (optional, all 256 values)
        // -------------------------------------------------------
        begin : exhaustive
            reg [8:0] idx;
            reg [7:0] exp_xt, exp_x3_val;
            integer fail_count;
            fail_count = 0;
            for (idx = 0; idx < 256; idx = idx + 1) begin
                a = idx[7:0];
                #2;
                exp_xt     = {idx[6:0], idx[7] ^ idx[0]};
                exp_x3_val = exp_xt ^ {exp_xt[6:0], exp_xt[7]};
                if (xtime_a !== exp_xt || x3_a !== exp_x3_val) begin
                    fail_count = fail_count + 1;
                    $display("FAIL: exhaustive a=0x%02h xtime_a=0x%02h (exp 0x%02h) x3_a=0x%02h (exp 0x%02h)",
                             idx[7:0], xtime_a, exp_xt, x3_a, exp_x3_val);
                end
            end
            if (fail_count == 0)
                $display("PASS: exhaustive sweep of all 256 inputs passed");
            else
                $display("FAIL: exhaustive sweep had %0d failures", fail_count);
        end

        #10;
        $finish;
    end

endmodule
