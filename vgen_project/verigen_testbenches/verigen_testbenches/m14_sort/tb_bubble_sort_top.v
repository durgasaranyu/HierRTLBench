`timescale 1ns/1ps

module tb_bubble_sort_top;

    // DUT connections
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
    integer timeout;
    integer pass_count;
    integer fail_count;

    // Task: wait for done with timeout
    task wait_for_done;
        input integer max_cycles;
        begin
            timeout = 0;
            while (done !== 1'b1 && timeout < max_cycles) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
        end
    endtask

    // Task: apply a sort and check result
    // Inputs as individual bytes (element 0 = LSB bytes)
    task apply_and_check;
        input [7:0] in0, in1, in2, in3, in4, in5, in6, in7;
        input [7:0] ex0, ex1, ex2, ex3, ex4, ex5, ex6, ex7;
        input [255:0] desc; // test description (32 bytes)
        reg [63:0] expected_flat;
        reg [63:0] got_flat;
        reg [7:0] got_byte;
        reg check_pass;
        begin
            // Pack inputs: element 0 in bits [7:0], element 7 in bits [63:56]
            data_in_flat = {in7, in6, in5, in4, in3, in2, in1, in0};
            expected_flat = {ex7, ex6, ex5, ex4, ex3, ex2, ex1, ex0};

            // Pulse start
            start = 1;
            @(posedge clk);
            #1;
            start = 0;

            // Wait for done
            wait_for_done(2000);

            // Check
            if (done !== 1'b1) begin
                $display("FAIL: %s - done never asserted", desc);
                fail_count = fail_count + 1;
            end else begin
                got_flat = data_out_flat;
                if (got_flat === expected_flat) begin
                    $display("PASS: %s", desc);
                    pass_count = pass_count + 1;
                end else begin
                    $display("FAIL: %s - expected %h got %h", desc, expected_flat, got_flat);
                    fail_count = fail_count + 1;
                end
            end

            // Let done settle then reset for next test
            @(posedge clk);
            @(posedge clk);
        end
    endtask

    initial begin
        pass_count   = 0;
        fail_count   = 0;
        rst          = 1;
        start        = 0;
        data_in_flat = 64'h0;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // Wait a couple cycles after reset
        @(posedge clk);
        @(posedge clk);

        // ---------------------------------------------------------------
        // Test 1: [5,1,4,2,8,3,7,6] -> [1,2,3,4,5,6,7,8]
        // ---------------------------------------------------------------
        apply_and_check(
            8'd5, 8'd1, 8'd4, 8'd2, 8'd8, 8'd3, 8'd7, 8'd6,
            8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8,
            "Sort [5,1,4,2,8,3,7,6] -> [1,2,3,4,5,6,7,8]"
        );

        // ---------------------------------------------------------------
        // Test 2: Already sorted [1,2,3,4,5,6,7,8] -> [1,2,3,4,5,6,7,8]
        // ---------------------------------------------------------------
        apply_and_check(
            8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8,
            8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8,
            "Already sorted [1,2,3,4,5,6,7,8]"
        );

        // ---------------------------------------------------------------
        // Test 3: All zeros -> all zeros
        // ---------------------------------------------------------------
        apply_and_check(
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0, 8'd0,
            "All-zero input [0,0,0,0,0,0,0,0]"
        );

        // ---------------------------------------------------------------
        // Test 4: All max (0xFF) -> all 0xFF
        // ---------------------------------------------------------------
        apply_and_check(
            8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF,
            8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'hFF,
            "All-max input [FF,FF,FF,FF,FF,FF,FF,FF]"
        );

        // ---------------------------------------------------------------
        // Test 5: Reverse sorted [8,7,6,5,4,3,2,1] -> [1,2,3,4,5,6,7,8]
        // ---------------------------------------------------------------
        apply_and_check(
            8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1,
            8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8,
            "Reverse sorted [8,7,6,5,4,3,2,1]"
        );

        // ---------------------------------------------------------------
        // Test 6: All equal non-zero [5,5,5,5,5,5,5,5] -> same
        // ---------------------------------------------------------------
        apply_and_check(
            8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5,
            8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5, 8'd5,
            "All equal [5,5,5,5,5,5,5,5]"
        );

        // ---------------------------------------------------------------
        // Test 7: Max values mixed [0xFF,0,0xFF,0,0xFF,0,0xFF,0]
        // ---------------------------------------------------------------
        apply_and_check(
            8'hFF, 8'h00, 8'hFF, 8'h00, 8'hFF, 8'h00, 8'hFF, 8'h00,
            8'h00, 8'h00, 8'h00, 8'h00, 8'hFF, 8'hFF, 8'hFF, 8'hFF,
            "Mixed max/zero [FF,0,FF,0,FF,0,FF,0]"
        );

        // ---------------------------------------------------------------
        // Test 8: Single unique max at front [0xFF,1,2,3,4,5,6,7]
        // ---------------------------------------------------------------
        apply_and_check(
            8'hFF, 8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7,
            8'd1,  8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'hFF,
            "Max at front [FF,1,2,3,4,5,6,7]"
        );

        // ---------------------------------------------------------------
        // Test 9: Random-like [10,200,30,150,5,220,75,100]
        // ---------------------------------------------------------------
        apply_and_check(
            8'd10, 8'd200, 8'd30, 8'd150, 8'd5, 8'd220, 8'd75, 8'd100,
            8'd5,  8'd10,  8'd30, 8'd75,  8'd100, 8'd150, 8'd200, 8'd220,
            "Random [10,200,30,150,5,220,75,100]"
        );

        // ---------------------------------------------------------------
        // Summary
        // ---------------------------------------------------------------
        $display("--------------------------------------------------");
        $display("Results: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("--------------------------------------------------");

        $finish;
    end

endmodule
