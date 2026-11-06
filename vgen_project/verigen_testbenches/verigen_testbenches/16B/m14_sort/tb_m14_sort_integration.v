`timescale 1ns/1ps

module tb_m14_sort_integration;

    // -----------------------------------------------------------------------
    // DUT connections
    // -----------------------------------------------------------------------
    reg         clk;
    reg         rst;
    reg         start;
    reg  [63:0] data_in_flat;
    wire [63:0] data_out_flat;
    wire        done;

    // -----------------------------------------------------------------------
    // DUT instantiation
    // -----------------------------------------------------------------------
    bubble_sort uut (
        .clk          (clk),
        .rst          (rst),
        .start        (start),
        .data_in_flat (data_in_flat),
        .data_out_flat(data_out_flat),
        .done         (done)
    );

    // -----------------------------------------------------------------------
    // Clock generation: 10 ns period
    // -----------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -----------------------------------------------------------------------
    // Helper: pack 8 x 8-bit values into 64-bit flat word (element 0 in MSB)
    // -----------------------------------------------------------------------
    function [63:0] pack8;
        input [7:0] b7, b6, b5, b4, b3, b2, b1, b0;
        begin
            pack8 = {b7, b6, b5, b4, b3, b2, b1, b0};
        end
    endfunction

    // -----------------------------------------------------------------------
    // Test variables
    // -----------------------------------------------------------------------
    integer timeout;
    integer test_pass;
    reg [63:0] expected_out;

    // -----------------------------------------------------------------------
    // Main test sequence
    // -----------------------------------------------------------------------
    initial begin
        // Initialise inputs
        rst          = 1;
        start        = 0;
        data_in_flat = 64'h0;

        // Assert synchronous reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        @(posedge clk); // deassert after 5 edges have passed
        rst = 0;

        // ------------------------------------------------------------------
        // TEST 1: Sort [5,1,4,2,8,3,7,6] -> expected [1,2,3,4,5,6,7,8]
        // Pack: index 0 = element 0 in bits [63:56], index 7 = bits [7:0]
        // i.e. flat = {5,1,4,2,8,3,7,6} with element[0] in MSB
        // ------------------------------------------------------------------

        // Load the unsorted array: {5,1,4,2,8,3,7,6}
        data_in_flat = pack8(8'd5, 8'd1, 8'd4, 8'd2, 8'd8, 8'd3, 8'd7, 8'd6);

        // Assert start for one clock cycle
        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        // Wait for done with timeout (500 clock cycles)
        timeout   = 0;
        test_pass = 0;

        while (!done && timeout < 500) begin
            @(posedge clk);
            timeout = timeout + 1;
        end

        if (done) begin
            // Expected sorted output: {1,2,3,4,5,6,7,8}
            expected_out = pack8(8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8);
            if (data_out_flat === expected_out) begin
                $display("PASS: Sort [5,1,4,2,8,3,7,6] -> [1,2,3,4,5,6,7,8], data_out_flat=0x%016h", data_out_flat);
                test_pass = 1;
            end else begin
                $display("FAIL: Sort [5,1,4,2,8,3,7,6] -> expected 0x%016h, got 0x%016h",
                         expected_out, data_out_flat);
                test_pass = 0;
            end
        end else begin
            $display("FAIL: Sort [5,1,4,2,8,3,7,6] -> done never asserted within timeout");
            test_pass = 0;
        end

        // ------------------------------------------------------------------
        // TEST 2: Already sorted [1,2,3,4,5,6,7,8] -> should still produce [1,2,3,4,5,6,7,8]
        // ------------------------------------------------------------------
        // Reset again
        rst   = 1;
        start = 0;
        repeat (5) @(posedge clk);
        @(posedge clk);
        rst = 0;

        data_in_flat = pack8(8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8);

        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        timeout = 0;
        while (!done && timeout < 500) begin
            @(posedge clk);
            timeout = timeout + 1;
        end

        if (done) begin
            expected_out = pack8(8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8);
            if (data_out_flat === expected_out) begin
                $display("PASS: Sort already-sorted [1,2,3,4,5,6,7,8] -> [1,2,3,4,5,6,7,8], data_out_flat=0x%016h", data_out_flat);
            end else begin
                $display("FAIL: Sort already-sorted -> expected 0x%016h, got 0x%016h",
                         expected_out, data_out_flat);
            end
        end else begin
            $display("FAIL: Sort already-sorted -> done never asserted within timeout");
        end

        // ------------------------------------------------------------------
        // TEST 3: Reverse sorted [8,7,6,5,4,3,2,1] -> [1,2,3,4,5,6,7,8]
        // ------------------------------------------------------------------
        rst   = 1;
        start = 0;
        repeat (5) @(posedge clk);
        @(posedge clk);
        rst = 0;

        data_in_flat = pack8(8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1);

        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        timeout = 0;
        while (!done && timeout < 500) begin
            @(posedge clk);
            timeout = timeout + 1;
        end

        if (done) begin
            expected_out = pack8(8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8);
            if (data_out_flat === expected_out) begin
                $display("PASS: Sort reverse [8,7,6,5,4,3,2,1] -> [1,2,3,4,5,6,7,8], data_out_flat=0x%016h", data_out_flat);
            end else begin
                $display("FAIL: Sort reverse -> expected 0x%016h, got 0x%016h",
                         expected_out, data_out_flat);
            end
        end else begin
            $display("FAIL: Sort reverse -> done never asserted within timeout");
        end

        // ------------------------------------------------------------------
        // TEST 4: All same values [3,3,3,3,3,3,3,3] -> [3,3,3,3,3,3,3,3]
        // ------------------------------------------------------------------
        rst   = 1;
        start = 0;
        repeat (5) @(posedge clk);
        @(posedge clk);
        rst = 0;

        data_in_flat = pack8(8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3);

        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        timeout = 0;
        while (!done && timeout < 500) begin
            @(posedge clk);
            timeout = timeout + 1;
        end

        if (done) begin
            expected_out = pack8(8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3, 8'd3);
            if (data_out_flat === expected_out) begin
                $display("PASS: Sort all-same [3,3,...,3] -> [3,3,...,3], data_out_flat=0x%016h", data_out_flat);
            end else begin
                $display("FAIL: Sort all-same -> expected 0x%016h, got 0x%016h",
                         expected_out, data_out_flat);
            end
        end else begin
            $display("FAIL: Sort all-same -> done never asserted within timeout");
        end

        // ------------------------------------------------------------------
        // Allow a few more clocks then finish
        // ------------------------------------------------------------------
        repeat (10) @(posedge clk);

        $finish;
    end

endmodule
