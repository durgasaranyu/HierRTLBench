`timescale 1ns/1ps

module tb_mat_row;

    // DUT connections
    reg         clk;
    reg         rst;
    reg         start;
    reg  [255:0] row_a_flat;
    reg  [255:0] col_b_flat;
    wire [31:0]  result;
    wire         done;

    // Instantiate DUT
    mat_row uut (
        .clk        (clk),
        .rst        (rst),
        .start      (start),
        .row_a_flat (row_a_flat),
        .col_b_flat (col_b_flat),
        .result     (result),
        .done       (done)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Helper task: apply inputs and check result
    integer idx;
    reg [31:0] expected;
    reg [15:0] a_arr [0:15];
    reg [15:0] b_arr [0:15];

    // Build flat vectors from arrays
    task build_flat;
        integer k;
        begin
            row_a_flat = 256'd0;
            col_b_flat = 256'd0;
            for (k = 0; k < 16; k = k + 1) begin
                row_a_flat[16*k +: 16] = a_arr[k];
                col_b_flat[16*k +: 16] = b_arr[k];
            end
        end
    endtask

    // Compute expected dot product
    task compute_expected;
        integer k;
        reg [63:0] acc;
        begin
            acc = 64'd0;
            for (k = 0; k < 16; k = k + 1) begin
                acc = acc + ({48'd0, a_arr[k]} * {48'd0, b_arr[k]});
            end
            expected = acc[31:0];
        end
    endtask

    integer pass_count;
    integer fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst   = 1;
        start = 0;
        row_a_flat = 256'd0;
        col_b_flat = 256'd0;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst = 0;

        // ------------------------------------------------------------------
        // Test 1: All-zero inputs
        // ------------------------------------------------------------------
        for (idx = 0; idx < 16; idx = idx + 1) begin
            a_arr[idx] = 16'd0;
            b_arr[idx] = 16'd0;
        end
        build_flat;
        compute_expected; // expected = 0

        @(negedge clk);
        start = 1;
        @(posedge clk); // start active
        @(negedge clk);
        start = 0;

        @(posedge clk); // wait one more cycle for done
        #1;
        if (result === expected && done === 1'b1)
            begin $display("PASS: All-zero inputs, result=%0d", result); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: All-zero inputs, expected=%0d got=%0d done=%b", expected, result, done); fail_count = fail_count + 1; end

        // ------------------------------------------------------------------
        // Test 2: All-ones inputs (each element = 1)
        // ------------------------------------------------------------------
        for (idx = 0; idx < 16; idx = idx + 1) begin
            a_arr[idx] = 16'd1;
            b_arr[idx] = 16'd1;
        end
        build_flat;
        compute_expected; // expected = 16

        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        @(posedge clk);
        #1;
        if (result === expected && done === 1'b1)
            begin $display("PASS: All-ones inputs, result=%0d expected=%0d", result, expected); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: All-ones inputs, expected=%0d got=%0d done=%b", expected, result, done); fail_count = fail_count + 1; end

        // ------------------------------------------------------------------
        // Test 3: Dot product of [1,2,...,16] with itself
        //         expected = 1+4+9+...+256 = 1496
        // ------------------------------------------------------------------
        for (idx = 0; idx < 16; idx = idx + 1) begin
            a_arr[idx] = idx + 1;
            b_arr[idx] = idx + 1;
        end
        build_flat;
        compute_expected;

        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        @(posedge clk);
        #1;
        if (result === expected && done === 1'b1)
            begin $display("PASS: [1..16] dot [1..16], result=%0d expected=%0d", result, expected); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: [1..16] dot [1..16], expected=%0d got=%0d done=%b", expected, result, done); fail_count = fail_count + 1; end

        // ------------------------------------------------------------------
        // Test 4: Maximum value inputs (0xFFFF each)
        //         expected = 16 * (65535*65535) = 16 * 4294836225
        //         Truncated to 32 bits: (16 * 4294836225) mod 2^32
        // ------------------------------------------------------------------
        for (idx = 0; idx < 16; idx = idx + 1) begin
            a_arr[idx] = 16'hFFFF;
            b_arr[idx] = 16'hFFFF;
        end
        build_flat;
        compute_expected;

        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        @(posedge clk);
        #1;
        if (result === expected && done === 1'b1)
            begin $display("PASS: Max-value inputs (0xFFFF), result=%0d expected=%0d", result, expected); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: Max-value inputs, expected=%0d got=%0d done=%b", expected, result, done); fail_count = fail_count + 1; end

        // ------------------------------------------------------------------
        // Test 5: Orthogonal-like vectors (alternating 1 and 0)
        //         a = [1,0,1,0,...], b = [0,1,0,1,...] => expected = 0
        // ------------------------------------------------------------------
        for (idx = 0; idx < 16; idx = idx + 1) begin
            a_arr[idx] = (idx % 2 == 0) ? 16'd1 : 16'd0;
            b_arr[idx] = (idx % 2 == 0) ? 16'd0 : 16'd1;
        end
        build_flat;
        compute_expected;

        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        @(posedge clk);
        #1;
        if (result === expected && done === 1'b1)
            begin $display("PASS: Orthogonal-like vectors, result=%0d expected=%0d", result, expected); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: Orthogonal-like vectors, expected=%0d got=%0d done=%b", expected, result, done); fail_count = fail_count + 1; end

        // ------------------------------------------------------------------
        // Test 6: Power-of-two elements
        //         a_arr[i] = 1 << (i % 8), b = same
        // ------------------------------------------------------------------
        for (idx = 0; idx < 16; idx = idx + 1) begin
            a_arr[idx] = 1 << (idx % 8);
            b_arr[idx] = 1 << (idx % 8);
        end
        build_flat;
        compute_expected;

        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        @(posedge clk);
        #1;
        if (result === expected && done === 1'b1)
            begin $display("PASS: Power-of-two elements, result=%0d expected=%0d", result, expected); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: Power-of-two elements, expected=%0d got=%0d done=%b", expected, result, done); fail_count = fail_count + 1; end

        // ------------------------------------------------------------------
        // Test 7: start not asserted => done should go to 0
        // ------------------------------------------------------------------
        // After previous test start=0, wait a cycle and check done=0
        @(negedge clk);
        start = 0;
        @(posedge clk);
        #1;
        if (done === 1'b0)
            begin $display("PASS: done=0 when start=0"); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: done should be 0 when start=0, got done=%b", done); fail_count = fail_count + 1; end

        // ------------------------------------------------------------------
        // Test 8: Reset clears result
        // ------------------------------------------------------------------
        // First do a computation to get non-zero result
        for (idx = 0; idx < 16; idx = idx + 1) begin
            a_arr[idx] = 16'd100;
            b_arr[idx] = 16'd100;
        end
        build_flat;

        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;
        @(posedge clk);
        #1;
        // Now assert reset for 5 cycles
        @(negedge clk);
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        if (result === 32'd0 && done === 1'b1)
            begin $display("PASS: Reset clears result, result=%0d done=%b", result, done); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: Reset should clear result, got result=%0d done=%b", result, done); fail_count = fail_count + 1; end
        @(negedge clk);
        rst = 0;

        // ------------------------------------------------------------------
        // Test 9: Mixed small and large values
        // ------------------------------------------------------------------
        for (idx = 0; idx < 16; idx = idx + 1) begin
            a_arr[idx] = (idx < 8) ? 16'd256 : 16'd1;
            b_arr[idx] = (idx < 8) ? 16'd256 : 16'd1;
        end
        build_flat;
        compute_expected;

        @(negedge clk);
        start = 1;
        @(posedge clk);
        @(negedge clk);
        start = 0;

        @(posedge clk);
        #1;
        if (result === expected && done === 1'b1)
            begin $display("PASS: Mixed small/large values, result=%0d expected=%0d", result, expected); pass_count = pass_count + 1; end
        else
            begin $display("FAIL: Mixed small/large values, expected=%0d got=%0d done=%b", expected, result, done); fail_count = fail_count + 1; end

        // ------------------------------------------------------------------
        // Summary
        // ------------------------------------------------------------------
        $display("Tests complete: %0d passed, %0d failed", pass_count, fail_count);

        $finish;
    end

endmodule
