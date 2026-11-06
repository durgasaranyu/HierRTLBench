`timescale 1ns/1ps

module tb_m14_sort_integration;

    // DUT connections
    reg         clk;
    reg         rst;
    reg         start;
    reg  [63:0] data_in_flat;
    wire [63:0] data_out_flat;
    wire        done;

    // Instantiate DUT
    bubble_sort uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_in_flat(data_in_flat),
        .data_out_flat(data_out_flat),
        .done(done)
    );

    // Clock generation: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Expected sorted output: [1,2,3,4,5,6,7,8]
    // data_out_flat[63:56]=1, [55:48]=2, [47:40]=3, [39:32]=4,
    //                [31:24]=5, [23:16]=6, [15:8]=7, [7:0]=8
    localparam [63:0] EXPECTED_SORTED = {8'd1, 8'd2, 8'd3, 8'd4,
                                          8'd5, 8'd6, 8'd7, 8'd8};

    // Unsorted input: [5,1,4,2,8,3,7,6]
    localparam [63:0] UNSORTED_INPUT  = {8'd5, 8'd1, 8'd4, 8'd2,
                                          8'd8, 8'd3, 8'd7, 8'd6};

    integer timeout;
    integer i;

    task apply_reset;
        integer k;
        begin
            rst   = 1;
            start = 0;
            // Hold reset for exactly 5 rising edges
            for (k = 0; k < 5; k = k + 1) begin
                @(posedge clk);
            end
            @(negedge clk);
            rst = 0;
        end
    endtask

    initial begin
        // ----------------------------------------------------------------
        // Initialise
        // ----------------------------------------------------------------
        clk          = 0;
        rst          = 1;
        start        = 0;
        data_in_flat = 64'd0;

        // ----------------------------------------------------------------
        // TEST 1: Reset check — done should be low after reset
        // ----------------------------------------------------------------
        apply_reset;

        @(posedge clk);
        #1;
        if (done === 1'b0)
            $display("PASS: done is deasserted after reset");
        else
            $display("FAIL: done should be deasserted after reset, got %b", done);

        // ----------------------------------------------------------------
        // TEST 2: Load unsorted array and start sort
        //         Input: [5,1,4,2,8,3,7,6]
        //         Expected output: [1,2,3,4,5,6,7,8]
        // ----------------------------------------------------------------
        data_in_flat = UNSORTED_INPUT;

        // Assert start for one clock cycle
        @(posedge clk);
        start = 1;
        @(posedge clk);
        #1;
        start = 0;

        // Wait for done to assert, with a generous timeout
        timeout = 0;
        while (done !== 1'b1 && timeout < 5000) begin
            @(posedge clk);
            #1;
            timeout = timeout + 1;
        end

        if (timeout >= 5000) begin
            $display("FAIL: Sort timed out — done never asserted");
        end else begin
            $display("PASS: done asserted after %0d cycles", timeout);
        end

        // ----------------------------------------------------------------
        // TEST 3: Verify sorted output
        // ----------------------------------------------------------------
        if (done === 1'b1 && data_out_flat === EXPECTED_SORTED) begin
            $display("PASS: Sorted output matches [1,2,3,4,5,6,7,8], data_out_flat=%h", data_out_flat);
        end else begin
            $display("FAIL: Sorted output mismatch. Expected %h, Got %h (done=%b)",
                     EXPECTED_SORTED, data_out_flat, done);
        end

        // ----------------------------------------------------------------
        // TEST 4: Re-reset and re-sort with already-sorted input [1,2,3,4,5,6,7,8]
        // ----------------------------------------------------------------
        apply_reset;

        data_in_flat = EXPECTED_SORTED;
        @(posedge clk);
        start = 1;
        @(posedge clk);
        #1;
        start = 0;

        timeout = 0;
        while (done !== 1'b1 && timeout < 5000) begin
            @(posedge clk);
            #1;
            timeout = timeout + 1;
        end

        if (timeout >= 5000) begin
            $display("FAIL: Already-sorted input — done never asserted");
        end else if (data_out_flat === EXPECTED_SORTED) begin
            $display("PASS: Already-sorted input correctly outputs [1,2,3,4,5,6,7,8]");
        end else begin
            $display("FAIL: Already-sorted input output mismatch. Expected %h, Got %h",
                     EXPECTED_SORTED, data_out_flat);
        end

        // ----------------------------------------------------------------
        // TEST 5: Re-reset and sort reverse-sorted input [8,7,6,5,4,3,2,1]
        // ----------------------------------------------------------------
        apply_reset;

        data_in_flat = {8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
        @(posedge clk);
        start = 1;
        @(posedge clk);
        #1;
        start = 0;

        timeout = 0;
        while (done !== 1'b1 && timeout < 5000) begin
            @(posedge clk);
            #1;
            timeout = timeout + 1;
        end

        if (timeout >= 5000) begin
            $display("FAIL: Reverse-sorted input — done never asserted");
        end else if (data_out_flat === EXPECTED_SORTED) begin
            $display("PASS: Reverse-sorted input correctly outputs [1,2,3,4,5,6,7,8]");
        end else begin
            $display("FAIL: Reverse-sorted input output mismatch. Expected %h, Got %h",
                     EXPECTED_SORTED, data_out_flat);
        end

        // ----------------------------------------------------------------
        // TEST 6: Re-reset and verify done stays low without start
        // ----------------------------------------------------------------
        apply_reset;

        // Wait several cycles without asserting start
        repeat(10) @(posedge clk);
        #1;
        if (done === 1'b0)
            $display("PASS: done stays low without start after reset");
        else
            $display("FAIL: done should be low without start, got %b", done);

        // ----------------------------------------------------------------
        // TEST 7: Main integration test — primary requirement
        //         Load [5,1,4,2,8,3,7,6], verify done and [1,2,3,4,5,6,7,8]
        // ----------------------------------------------------------------
        apply_reset;

        data_in_flat = UNSORTED_INPUT;

        @(posedge clk);
        start = 1;
        @(posedge clk);
        #1;
        start = 0;

        timeout = 0;
        while (done !== 1'b1 && timeout < 10000) begin
            @(posedge clk);
            #1;
            timeout = timeout + 1;
        end

        if (done === 1'b1 && data_out_flat === EXPECTED_SORTED)
            $display("PASS: Integration test — [5,1,4,2,8,3,7,6] sorted to [1,2,3,4,5,6,7,8] in %0d cycles", timeout);
        else
            $display("FAIL: Integration test — done=%b, expected=%h, got=%h",
                     done, EXPECTED_SORTED, data_out_flat);

        // Allow a few more cycles for observation
        repeat(5) @(posedge clk);

        $display("Integration testbench complete.");
        $finish;
    end

endmodule
