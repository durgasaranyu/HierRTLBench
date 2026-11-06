`timescale 1ns/1ps

module tb_bubble_sort_top;

    // DUT ports
    reg         clk;
    reg         rst;
    reg         start;
    reg  [63:0] data_in_flat;
    wire [63:0] data_out_flat;
    wire        done;

    // Instantiate DUT
    bubble_sort uut (
        .clk          (clk),
        .rst          (rst),
        .start        (start),
        .data_in_flat (data_in_flat),
        .data_out_flat(data_out_flat),
        .done         (done)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Helper integers
    integer i;
    integer pass_count;
    integer fail_count;

    // Timeout counter
    integer timeout;

    // Task: apply reset for 5 rising edges
    task apply_reset;
        integer k;
        begin
            rst   = 1;
            start = 0;
            data_in_flat = 64'h0;
            for (k = 0; k < 5; k = k + 1)
                @(posedge clk);
            @(negedge clk);
            rst = 0;
        end
    endtask

    // Task: run sort, wait for done or timeout
    task run_sort;
        input [63:0] din;
        output done_seen;
        reg done_seen;
        integer t;
        begin
            @(negedge clk);
            data_in_flat = din;
            start        = 1;
            @(negedge clk);
            start        = 0;
            done_seen    = 0;
            for (t = 0; t < 500; t = t + 1) begin
                @(posedge clk);
                if (done) begin
                    done_seen = 1;
                    t = 500; // break
                end
            end
        end
    endtask

    // Pack 8 bytes into flat 64-bit: element[0] in bits [7:0], element[7] in bits [63:56]
    function [63:0] pack8;
        input [7:0] b0, b1, b2, b3, b4, b5, b6, b7;
        begin
            pack8 = {b7, b6, b5, b4, b3, b2, b1, b0};
        end
    endfunction

    // Unpack element i (0-based) from flat
    function [7:0] elem;
        input [63:0] flat;
        input [2:0]  idx;
        begin
            elem = flat[idx*8 +: 8];
        end
    endfunction

    // Check sorted output
    task check_sorted;
        input [63:0] actual;
        input [63:0] expected;
        input [127:0] desc; // 16-char description
        reg ok;
        integer j;
        begin
            ok = 1;
            for (j = 0; j < 8; j = j + 1) begin
                if (actual[j*8 +: 8] !== expected[j*8 +: 8])
                    ok = 0;
            end
            if (ok) begin
                $display("PASS: %s", desc);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %s -- expected=%h actual=%h", desc, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Variables for tests
    reg [63:0] din;
    reg [63:0] expected;
    reg        ds;

    initial begin
        pass_count   = 0;
        fail_count   = 0;
        rst          = 0;
        start        = 0;
        data_in_flat = 64'h0;

        // ---------------------------------------------------------------
        // Reset
        // ---------------------------------------------------------------
        apply_reset;

        // ---------------------------------------------------------------
        // TEST 1: Sort [5,1,4,2,8,3,7,6] -> [1,2,3,4,5,6,7,8]
        // ---------------------------------------------------------------
        din      = pack8(8'd5, 8'd1, 8'd4, 8'd2, 8'd8, 8'd3, 8'd7, 8'd6);
        expected = pack8(8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8);
        run_sort(din, ds);
        if (!ds) begin
            $display("FAIL: Test1 sort [5,1,4,2,8,3,7,6] -- done never asserted");
            fail_count = fail_count + 1;
        end else begin
            check_sorted(data_out_flat, expected, "Sort [5,1,4,2,8,3,7,6]");
        end

        // ---------------------------------------------------------------
        // TEST 2: All zeros -> all zeros
        // ---------------------------------------------------------------
        apply_reset;
        din      = pack8(8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0);
        expected = pack8(8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0);
        run_sort(din, ds);
        if (!ds) begin
            $display("FAIL: Test2 all-zeros -- done never asserted");
            fail_count = fail_count + 1;
        end else begin
            check_sorted(data_out_flat, expected, "Sort all zeros     ");
        end

        // ---------------------------------------------------------------
        // TEST 3: All ones (0xFF) -> all 0xFF
        // ---------------------------------------------------------------
        apply_reset;
        din      = pack8(8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF);
        expected = pack8(8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF);
        run_sort(din, ds);
        if (!ds) begin
            $display("FAIL: Test3 all-0xFF -- done never asserted");
            fail_count = fail_count + 1;
        end else begin
            check_sorted(data_out_flat, expected, "Sort all 0xFF      ");
        end

        // ---------------------------------------------------------------
        // TEST 4: Already sorted [1,2,3,4,5,6,7,8]
        // ---------------------------------------------------------------
        apply_reset;
        din      = pack8(8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8);
        expected = pack8(8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8);
        run_sort(din, ds);
        if (!ds) begin
            $display("FAIL: Test4 already sorted -- done never asserted");
            fail_count = fail_count + 1;
        end else begin
            check_sorted(data_out_flat, expected, "Already sorted     ");
        end

        // ---------------------------------------------------------------
        // TEST 5: Reverse sorted [8,7,6,5,4,3,2,1]
        // ---------------------------------------------------------------
        apply_reset;
        din      = pack8(8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1);
        expected = pack8(8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8);
        run_sort(din, ds);
        if (!ds) begin
            $display("FAIL: Test5 reverse sorted -- done never asserted");
            fail_count = fail_count + 1;
        end else begin
            check_sorted(data_out_flat, expected, "Reverse sorted     ");
        end

        // ---------------------------------------------------------------
        // TEST 6: Max values [255,0,128,64,192,32,96,160]
        // ---------------------------------------------------------------
        apply_reset;
        din      = pack8(8'd255, 8'd0, 8'd128, 8'd64, 8'd192, 8'd32, 8'd96, 8'd160);
        expected = pack8(8'd0,   8'd32, 8'd64, 8'd96, 8'd128, 8'd160, 8'd192, 8'd255);
        run_sort(din, ds);
        if (!ds) begin
            $display("FAIL: Test6 max values -- done never asserted");
            fail_count = fail_count + 1;
        end else begin
            check_sorted(data_out_flat, expected, "Max value mix      ");
        end

        // ---------------------------------------------------------------
        // TEST 7: Duplicates [3,3,1,1,2,2,4,4]
        // ---------------------------------------------------------------
        apply_reset;
        din      = pack8(8'd3, 8'd3, 8'd1, 8'd1, 8'd2, 8'd2, 8'd4, 8'd4);
        expected = pack8(8'd1, 8'd1, 8'd2, 8'd2, 8'd3, 8'd3, 8'd4, 8'd4);
        run_sort(din, ds);
        if (!ds) begin
            $display("FAIL: Test7 duplicates -- done never asserted");
            fail_count = fail_count + 1;
        end else begin
            check_sorted(data_out_flat, expected, "Duplicates         ");
        end

        // ---------------------------------------------------------------
        // TEST 8: Single different [0,0,0,0,0,0,0,255]
        // ---------------------------------------------------------------
        apply_reset;
        din      = pack8(8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd255);
        expected = pack8(8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd255);
        run_sort(din, ds);
        if (!ds) begin
            $display("FAIL: Test8 single max at end -- done never asserted");
            fail_count = fail_count + 1;
        end else begin
            check_sorted(data_out_flat, expected, "Single max at end  ");
        end

        // ---------------------------------------------------------------
        // TEST 9: Single different [255,0,0,0,0,0,0,0]
        // ---------------------------------------------------------------
        apply_reset;
        din      = pack8(8'd255, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0);
        expected = pack8(8'd0,   8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd255);
        run_sort(din, ds);
        if (!ds) begin
            $display("FAIL: Test9 single max at start -- done never asserted");
            fail_count = fail_count + 1;
        end else begin
            check_sorted(data_out_flat, expected, "Single max at start");
        end

        // ---------------------------------------------------------------
        // TEST 10: Reset mid-operation
        // ---------------------------------------------------------------
        apply_reset;
        din   = pack8(8'd9, 8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2);
        @(negedge clk);
        data_in_flat = din;
        start        = 1;
        @(negedge clk);
        start = 0;
        // Wait a few cycles then reset
        repeat(3) @(posedge clk);
        rst = 1;
        repeat(5) @(posedge clk);
        @(negedge clk);
        rst = 0;
        // Now try a proper sort
        din      = pack8(8'd10, 8'd20, 8'd5, 8'd15, 8'd25, 8'd1, 8'd30, 8'd8);
        expected = pack8(8'd1,  8'd5,  8'd8, 8'd10, 8'd15, 8'd20, 8'd25, 8'd30);
        run_sort(din, ds);
        if (!ds) begin
            $display("FAIL: Test10 reset mid-op then sort -- done never asserted");
            fail_count = fail_count + 1;
        end else begin
            check_sorted(data_out_flat, expected, "After mid-op reset ");
        end

        // ---------------------------------------------------------------
        // Summary
        // ---------------------------------------------------------------
        $display("-------------------------------");
        $display("Tests complete: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("-------------------------------");
        $finish;
    end

endmodule
