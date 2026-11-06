`timescale 1ns/1ps

`define PRECISION_ROW 4
`define PRECISION_COL 4
`define PRECISION_MEM 8
`define PRECISION_DIV 8

module tb_mat_row;

    // Clock and reset
    reg clk;
    reg rst;
    reg start;
    reg [255:0] row_a_flat;
    reg [255:0] col_b_flat;
    wire [31:0] result;
    wire done;

    // Instantiate DUT
    mat_row uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .row_a_flat(row_a_flat),
        .col_b_flat(col_b_flat),
        .result(result),
        .done(done)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Integer variables
    integer i;
    integer j;
    integer timeout;
    reg [31:0] expected;
    reg [15:0] a_vals [0:15];
    reg [15:0] b_vals [0:15];
    reg [255:0] row_flat_tmp;
    reg [255:0] col_flat_tmp;

    // Task to build flat vectors and compute expected dot product
    task build_and_check;
        input [255:0] row_flat;
        input [255:0] col_flat;
        input [31:0]  exp_result;
        input [79:0]  test_name; // simplified: just use display directly
        begin
            // Apply inputs
            @(negedge clk);
            row_a_flat = row_flat;
            col_b_flat = col_flat;
            start = 1;
            @(posedge clk);
            #1;
            start = 0;

            // Wait for done or timeout
            timeout = 0;
            while (done !== 1'b1 && timeout < 50) begin
                @(posedge clk);
                #1;
                timeout = timeout + 1;
            end

            if (timeout >= 50) begin
                $display("FAIL: %s - timeout waiting for done", test_name);
            end else if (result !== exp_result) begin
                $display("FAIL: %s - expected=%0d got=%0d", test_name, exp_result, result);
            end else begin
                $display("PASS: %s - result=%0d done=%b", test_name, result, done);
            end

            // Wait a couple cycles before next test
            @(posedge clk);
            @(posedge clk);
        end
    endtask

    // Helper function - build flat from array (done inline)

    initial begin
        // Initialize
        rst   = 1;
        start = 0;
        row_a_flat = 0;
        col_b_flat = 0;

        // Assert reset for 5 rising edges
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // Wait a couple cycles after reset
        @(posedge clk);
        @(posedge clk);

        //------------------------------------------------------------------
        // Test 1: All-zero inputs: dot product = 0
        //------------------------------------------------------------------
        row_flat_tmp = 256'h0;
        col_flat_tmp = 256'h0;
        expected = 32'd0;

        @(negedge clk);
        row_a_flat = row_flat_tmp;
        col_b_flat = col_flat_tmp;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        timeout = 0;
        while (done !== 1'b1 && timeout < 50) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        if (timeout >= 50)
            $display("FAIL: All-zeros - timeout");
        else if (result !== expected)
            $display("FAIL: All-zeros - expected=%0d got=%0d", expected, result);
        else
            $display("PASS: All-zeros - result=%0d", result);

        @(posedge clk); @(posedge clk);

        //------------------------------------------------------------------
        // Test 2: [1,2,3,...,16] dot [1,2,3,...,16] = 1+4+9+16+25+36+49+64+81+100+121+144+169+196+225+256 = 1496
        //------------------------------------------------------------------
        row_flat_tmp = 0;
        col_flat_tmp = 0;
        for (i = 0; i < 16; i = i + 1) begin
            row_flat_tmp = row_flat_tmp | (((256'd0 + i + 1) & 256'hFFFF) << (i * 16));
            col_flat_tmp = col_flat_tmp | (((256'd0 + i + 1) & 256'hFFFF) << (i * 16));
        end
        // 1^2+2^2+...+16^2 = 16*17*33/6 = 1496
        expected = 32'd1496;

        @(negedge clk);
        row_a_flat = row_flat_tmp;
        col_b_flat = col_flat_tmp;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        timeout = 0;
        while (done !== 1'b1 && timeout < 50) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        if (timeout >= 50)
            $display("FAIL: [1..16] dot [1..16] - timeout");
        else if (result !== expected)
            $display("FAIL: [1..16] dot [1..16] - expected=%0d got=%0d", expected, result);
        else
            $display("PASS: [1..16] dot [1..16] - result=%0d", result);

        @(posedge clk); @(posedge clk);

        //------------------------------------------------------------------
        // Test 3: All-ones inputs: each element = 1, dot product = 16
        //------------------------------------------------------------------
        row_flat_tmp = 0;
        col_flat_tmp = 0;
        for (i = 0; i < 16; i = i + 1) begin
            row_flat_tmp = row_flat_tmp | (256'h0001 << (i * 16));
            col_flat_tmp = col_flat_tmp | (256'h0001 << (i * 16));
        end
        expected = 32'd16;

        @(negedge clk);
        row_a_flat = row_flat_tmp;
        col_b_flat = col_flat_tmp;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        timeout = 0;
        while (done !== 1'b1 && timeout < 50) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        if (timeout >= 50)
            $display("FAIL: All-ones - timeout");
        else if (result !== expected)
            $display("FAIL: All-ones - expected=%0d got=%0d", expected, result);
        else
            $display("PASS: All-ones - result=%0d", result);

        @(posedge clk); @(posedge clk);

        //------------------------------------------------------------------
        // Test 4: row=[1,0,0,...,0], col=[5,0,...,0] => dot=5
        //------------------------------------------------------------------
        row_flat_tmp = 0;
        col_flat_tmp = 0;
        row_flat_tmp = 256'h0001;  // element 0 = 1
        col_flat_tmp = 256'h0005;  // element 0 = 5
        expected = 32'd5;

        @(negedge clk);
        row_a_flat = row_flat_tmp;
        col_b_flat = col_flat_tmp;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        timeout = 0;
        while (done !== 1'b1 && timeout < 50) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        if (timeout >= 50)
            $display("FAIL: Single element - timeout");
        else if (result !== expected)
            $display("FAIL: Single element - expected=%0d got=%0d", expected, result);
        else
            $display("PASS: Single element - result=%0d", result);

        @(posedge clk); @(posedge clk);

        //------------------------------------------------------------------
        // Test 5: row=[2,2,...,2], col=[3,3,...,3] => dot = 16*6 = 96
        //------------------------------------------------------------------
        row_flat_tmp = 0;
        col_flat_tmp = 0;
        for (i = 0; i < 16; i = i + 1) begin
            row_flat_tmp = row_flat_tmp | (256'h0002 << (i * 16));
            col_flat_tmp = col_flat_tmp | (256'h0003 << (i * 16));
        end
        expected = 32'd96;

        @(negedge clk);
        row_a_flat = row_flat_tmp;
        col_b_flat = col_flat_tmp;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        timeout = 0;
        while (done !== 1'b1 && timeout < 50) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        if (timeout >= 50)
            $display("FAIL: All-twos dot all-threes - timeout");
        else if (result !== expected)
            $display("FAIL: All-twos dot all-threes - expected=%0d got=%0d", expected, result);
        else
            $display("PASS: All-twos dot all-threes - result=%0d", result);

        @(posedge clk); @(posedge clk);

        //------------------------------------------------------------------
        // Test 6: row=[10,20,30,...,160], col=[1,1,...,1] => dot = 10+20+...+160 = 1360
        //------------------------------------------------------------------
        row_flat_tmp = 0;
        col_flat_tmp = 0;
        // sum = 10*(1+2+...+16) = 10*136 = 1360
        for (i = 0; i < 16; i = i + 1) begin
            row_flat_tmp = row_flat_tmp | (((256'd0 + (i+1)*10) & 256'hFFFF) << (i * 16));
            col_flat_tmp = col_flat_tmp | (256'h0001 << (i * 16));
        end
        expected = 32'd1360;

        @(negedge clk);
        row_a_flat = row_flat_tmp;
        col_b_flat = col_flat_tmp;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        timeout = 0;
        while (done !== 1'b1 && timeout < 50) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        if (timeout >= 50)
            $display("FAIL: [10,20,...,160] dot [1..1] - timeout");
        else if (result !== expected)
            $display("FAIL: [10,20,...,160] dot [1..1] - expected=%0d got=%0d", expected, result);
        else
            $display("PASS: [10,20,...,160] dot [1..1] - result=%0d", result);

        @(posedge clk); @(posedge clk);

        //------------------------------------------------------------------
        // Test 7: Maximum value inputs - element 0 of row=16'hFFFF, rest=0; col=16'hFFFF element0 rest=0
        // dot = 0xFFFF * 0xFFFF = 65535*65535 = 4294836225
        //------------------------------------------------------------------
        row_flat_tmp = 256'hFFFF;
        col_flat_tmp = 256'hFFFF;
        expected = 32'd4294836225; // = 0xFFFE0001 -- check: 65535^2 = 4294836225, fits in 32 bits? 
        // 65535^2 = 4294836225 = 0xFFFE0001, yes fits in 32 bits (max 32-bit unsigned = 4294967295)

        @(negedge clk);
        row_a_flat = row_flat_tmp;
        col_b_flat = col_flat_tmp;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        timeout = 0;
        while (done !== 1'b1 && timeout < 50) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        if (timeout >= 50)
            $display("FAIL: Max single element - timeout");
        else if (result !== expected)
            $display("FAIL: Max single element - expected=%0d got=%0d", expected, result);
        else
            $display("PASS: Max single element - result=%0d", result);

        @(posedge clk); @(posedge clk);

        //------------------------------------------------------------------
        // Test 8: row=[0,1,0,...,0], col=[0,0,...,0,7] => dot=0 (orthogonal)
        //------------------------------------------------------------------
        row_flat_tmp = 0;
        col_flat_tmp = 0;
        row_flat_tmp = 256'h0001 << 16;  // element 1 = 1
        col_flat_tmp = 256'h0007 << (15*16); // element 15 = 7
        expected = 32'd0;

        @(negedge clk);
        row_a_flat = row_flat_tmp;
        col_b_flat = col_flat_tmp;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        timeout = 0;
        while (done !== 1'b1 && timeout < 50) begin
            @(posedge clk); #1;
            timeout = timeout + 1;
        end
        if (timeout >= 50)
            $display("FAIL: Orthogonal vectors - timeout");
        else if (result !== expected)
            $display("FAIL: Orthogonal vectors - expected=%0d got=%0d", expected, result);
        else
            $display("PASS: Orthogonal vectors - result=%0d", result);

        @(posedge clk); @(posedge clk);

        //------------------------------------------------------------------
        // Test 9: done signal check - verify done deasserts after reset
        //------------------------------------------------------------------
        @(negedge clk);
        rst = 1;
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;
        if (done === 1'b0)
            $display("PASS: done deasserted after reset");
        else
            $display("FAIL: done should be 0 after reset, got %b", done);

        @(posedge clk); @(posedge clk);

        //------------------------------------------------------------------
        // Test 10: Verify done asserts after 16 cycles
        //------------------------------------------------------------------
        row_flat_tmp = 0;
        col_flat_tmp = 0;
        for (i = 0; i < 16; i = i + 1) begin
            row
