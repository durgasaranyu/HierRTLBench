`timescale 1ns/1ps

module tb_aes_gf_mul;

    // DUT connections
    reg  [7:0] a;
    wire [7:0] xtime_a;
    wire [7:0] x3_a;

    // Reference function for xtime: multiply by 2 in GF(2^8)
    function [7:0] f_xtime;
        input [7:0] val;
        begin
            if (val[7])
                f_xtime = (val << 1) ^ 8'h1b;
            else
                f_xtime = (val << 1);
        end
    endfunction

    // Reference function for x3: xtime(a) XOR a
    function [7:0] f_x3;
        input [7:0] val;
        begin
            f_x3 = f_xtime(val) ^ val;
        end
    endfunction

    // Clock (required by general requirements, module is combinational)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (required by general requirements)
    reg rst;
    integer i;

    // DUT instantiation
    aes_gf_mul uut (
        .a       (a),
        .xtime_a (xtime_a),
        .x3_a    (x3_a)
    );

    // Task to check one test vector
    task check_vector;
        input [7:0] test_a;
        input [7:0] exp_xtime;
        input [7:0] exp_x3;
        input [63:0] desc0;
        input [63:0] desc1;
        begin
            a = test_a;
            #2; // let combinational settle
            if (xtime_a === exp_xtime && x3_a === exp_x3)
                $display("PASS: a=0x%02h xtime=0x%02h x3=0x%02h", test_a, exp_xtime, exp_x3);
            else begin
                $display("FAIL: a=0x%02h expected xtime=0x%02h got=0x%02h, expected x3=0x%02h got=0x%02h",
                         test_a, exp_xtime, xtime_a, exp_x3, x3_a);
            end
        end
    endtask

    // Variables for expected values
    reg [7:0] exp_xtime_r;
    reg [7:0] exp_x3_r;

    initial begin
        // Assert reset for 5 rising edges
        rst = 1;
        a   = 8'h00;
        repeat (5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // -------------------------------------------------------
        // Test 1: a = 0x00 (all zeros)
        // -------------------------------------------------------
        exp_xtime_r = f_xtime(8'h00);
        exp_x3_r    = f_x3(8'h00);
        a = 8'h00;
        #2;
        if (xtime_a === exp_xtime_r && x3_a === exp_x3_r)
            $display("PASS: a=0x00 (all zeros): xtime=0x%02h x3=0x%02h", xtime_a, x3_a);
        else
            $display("FAIL: a=0x00 (all zeros): got xtime=0x%02h (exp 0x%02h) x3=0x%02h (exp 0x%02h)",
                     xtime_a, exp_xtime_r, x3_a, exp_x3_r);

        // -------------------------------------------------------
        // Test 2: a = 0xFF (all ones)
        // -------------------------------------------------------
        exp_xtime_r = f_xtime(8'hFF);
        exp_x3_r    = f_x3(8'hFF);
        a = 8'hFF;
        #2;
        if (xtime_a === exp_xtime_r && x3_a === exp_x3_r)
            $display("PASS: a=0xFF (all ones): xtime=0x%02h x3=0x%02h", xtime_a, x3_a);
        else
            $display("FAIL: a=0xFF (all ones): got xtime=0x%02h (exp 0x%02h) x3=0x%02h (exp 0x%02h)",
                     xtime_a, exp_xtime_r, x3_a, exp_x3_r);

        // -------------------------------------------------------
        // Test 3: a = 0x01 (MSB=0, minimal nonzero)
        // -------------------------------------------------------
        exp_xtime_r = f_xtime(8'h01);
        exp_x3_r    = f_x3(8'h01);
        a = 8'h01;
        #2;
        if (xtime_a === exp_xtime_r && x3_a === exp_x3_r)
            $display("PASS: a=0x01: xtime=0x%02h x3=0x%02h", xtime_a, x3_a);
        else
            $display("FAIL: a=0x01: got xtime=0x%02h (exp 0x%02h) x3=0x%02h (exp 0x%02h)",
                     xtime_a, exp_xtime_r, x3_a, exp_x3_r);

        // -------------------------------------------------------
        // Test 4: a = 0x80 (MSB=1, max single-bit high)
        // -------------------------------------------------------
        exp_xtime_r = f_xtime(8'h80);
        exp_x3_r    = f_x3(8'h80);
        a = 8'h80;
        #2;
        if (xtime_a === exp_xtime_r && x3_a === exp_x3_r)
            $display("PASS: a=0x80: xtime=0x%02h x3=0x%02h", xtime_a, x3_a);
        else
            $display("FAIL: a=0x80: got xtime=0x%02h (exp 0x%02h) x3=0x%02h (exp 0x%02h)",
                     xtime_a, exp_xtime_r, x3_a, exp_x3_r);

        // -------------------------------------------------------
        // Test 5: a = 0x53 (AES standard example byte)
        // -------------------------------------------------------
        exp_xtime_r = f_xtime(8'h53);
        exp_x3_r    = f_x3(8'h53);
        a = 8'h53;
        #2;
        if (xtime_a === exp_xtime_r && x3_a === exp_x3_r)
            $display("PASS: a=0x53: xtime=0x%02h x3=0x%02h", xtime_a, x3_a);
        else
            $display("FAIL: a=0x53: got xtime=0x%02h (exp 0x%02h) x3=0x%02h (exp 0x%02h)",
                     xtime_a, exp_xtime_r, x3_a, exp_x3_r);

        // -------------------------------------------------------
        // Test 6: a = 0xAB (mixed pattern)
        // -------------------------------------------------------
        exp_xtime_r = f_xtime(8'hAB);
        exp_x3_r    = f_x3(8'hAB);
        a = 8'hAB;
        #2;
        if (xtime_a === exp_xtime_r && x3_a === exp_x3_r)
            $display("PASS: a=0xAB: xtime=0x%02h x3=0x%02h", xtime_a, x3_a);
        else
            $display("FAIL: a=0xAB: got xtime=0x%02h (exp 0x%02h) x3=0x%02h (exp 0x%02h)",
                     xtime_a, exp_xtime_r, x3_a, exp_x3_r);

        // -------------------------------------------------------
        // Test 7: a = 0x7F (MSB=0, all lower bits 1)
        // -------------------------------------------------------
        exp_xtime_r = f_xtime(8'h7F);
        exp_x3_r    = f_x3(8'h7F);
        a = 8'h7F;
        #2;
        if (xtime_a === exp_xtime_r && x3_a === exp_x3_r)
            $display("PASS: a=0x7F: xtime=0x%02h x3=0x%02h", xtime_a, x3_a);
        else
            $display("FAIL: a=0x7F: got xtime=0x%02h (exp 0x%02h) x3=0x%02h (exp 0x%02h)",
                     xtime_a, exp_xtime_r, x3_a, exp_x3_r);

        // -------------------------------------------------------
        // Test 8: a = 0xFE (maximum with LSB=0)
        // -------------------------------------------------------
        exp_xtime_r = f_xtime(8'hFE);
        exp_x3_r    = f_x3(8'hFE);
        a = 8'hFE;
        #2;
        if (xtime_a === exp_xtime_r && x3_a === exp_x3_r)
            $display("PASS: a=0xFE: xtime=0x%02h x3=0x%02h", xtime_a, x3_a);
        else
            $display("FAIL: a=0xFE: got xtime=0x%02h (exp 0x%02h) x3=0x%02h (exp 0x%02h)",
                     xtime_a, exp_xtime_r, x3_a, exp_x3_r);

        // -------------------------------------------------------
        // Sweep all 256 values
        // -------------------------------------------------------
        begin : sweep_block
            integer sv;
            for (sv = 0; sv < 256; sv = sv + 1) begin
                a = sv[7:0];
                #2;
                exp_xtime_r = f_xtime(sv[7:0]);
                exp_x3_r    = f_x3(sv[7:0]);
                if (xtime_a !== exp_xtime_r || x3_a !== exp_x3_r) begin
                    $display("FAIL: sweep a=0x%02h: got xtime=0x%02h (exp 0x%02h) x3=0x%02h (exp 0x%02h)",
                             sv[7:0], xtime_a, exp_xtime_r, x3_a, exp_x3_r);
                end
            end
            $display("PASS: Full 256-value sweep completed (any failures shown above)");
        end

        $finish;
    end

endmodule
