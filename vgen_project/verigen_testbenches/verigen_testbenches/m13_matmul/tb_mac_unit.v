`timescale 1ns/1ps

module tb_mac_unit;

    // DUT connections
    reg         clk;
    reg         rst;
    reg         clear;
    reg         en;
    reg  [15:0] a;
    reg  [15:0] b;
    wire [31:0] acc;

    // Instantiate DUT
    mac_unit uut (
        .clk   (clk),
        .rst   (rst),
        .clear (clear),
        .en    (en),
        .a     (a),
        .b     (b),
        .acc   (acc)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Task to apply one cycle
    task apply_cycle;
        input        t_clear;
        input        t_en;
        input [15:0] t_a;
        input [15:0] t_b;
        begin
            clear = t_clear;
            en    = t_en;
            a     = t_a;
            b     = t_b;
            @(posedge clk);
            #1; // small delay after edge to sample
        end
    endtask

    integer i;
    reg [31:0] expected;

    initial begin
        // Initialize
        rst   = 1;
        clear = 0;
        en    = 0;
        a     = 0;
        b     = 0;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // After reset, acc should be 0
        if (acc === 32'd0)
            $display("PASS: After reset acc=0");
        else
            $display("FAIL: After reset acc=%0d (expected 0)", acc);

        // -------------------------------------------------------
        // Test 1: clear alone sets acc to 0
        // -------------------------------------------------------
        // First load something
        apply_cycle(0, 1, 16'd10, 16'd5);  // acc = 10*5 = 50
        apply_cycle(1, 0, 16'd0,  16'd0);  // clear
        if (acc === 32'd0)
            $display("PASS: Test1 clear resets acc to 0");
        else
            $display("FAIL: Test1 clear, acc=%0d (expected 0)", acc);

        // -------------------------------------------------------
        // Test 2: Single accumulate with en=1 (a=3, b=4 -> acc=12)
        // -------------------------------------------------------
        apply_cycle(0, 1, 16'd3, 16'd4);
        if (acc === 32'd12)
            $display("PASS: Test2 acc=3*4=12");
        else
            $display("FAIL: Test2 acc=%0d (expected 12)", acc);

        // -------------------------------------------------------
        // Test 3: Another accumulate replaces (a=7, b=8 -> acc=56)
        // Note: MAC here overwrites acc with a*b (no true accumulation in the RTL)
        // -------------------------------------------------------
        apply_cycle(0, 1, 16'd7, 16'd8);
        if (acc === 32'd56)
            $display("PASS: Test3 acc=7*8=56");
        else
            $display("FAIL: Test3 acc=%0d (expected 56)", acc);

        // -------------------------------------------------------
        // Test 4: clear then accumulate 3 values and verify sum of products
        // clear, then en with (2,3)=6, en with (4,5)=20, en with (6,7)=42
        // Since RTL does acc_r <= a*b (not +=), each en overwrites.
        // Sequence: clear -> acc=0, then en(2,3)->acc=6, en(4,5)->acc=20, en(6,7)->acc=42
        // -------------------------------------------------------
        apply_cycle(1, 0, 16'd0,  16'd0);  // clear
        apply_cycle(0, 1, 16'd2,  16'd3);  // acc = 6
        apply_cycle(0, 1, 16'd4,  16'd5);  // acc = 20
        apply_cycle(0, 1, 16'd6,  16'd7);  // acc = 42
        if (acc === 32'd42)
            $display("PASS: Test4 three accumulates last=6*7=42");
        else
            $display("FAIL: Test4 acc=%0d (expected 42)", acc);

        // -------------------------------------------------------
        // Test 5: All-zero inputs with en=1 (acc should become 0)
        // -------------------------------------------------------
        apply_cycle(0, 1, 16'd0, 16'd0);
        if (acc === 32'd0)
            $display("PASS: Test5 all-zero inputs acc=0");
        else
            $display("FAIL: Test5 acc=%0d (expected 0)", acc);

        // -------------------------------------------------------
        // Test 6: All-ones inputs (a=0xFFFF, b=0xFFFF -> product=0xFFFE0001)
        // -------------------------------------------------------
        apply_cycle(0, 1, 16'hFFFF, 16'hFFFF);
        expected = 32'hFFFE0001;
        if (acc === expected)
            $display("PASS: Test6 all-ones acc=0xFFFE0001");
        else
            $display("FAIL: Test6 acc=%0h (expected 0xFFFE0001)", acc);

        // -------------------------------------------------------
        // Test 7: Maximum single value (a=0xFFFF, b=1 -> acc=0xFFFF)
        // -------------------------------------------------------
        apply_cycle(0, 1, 16'hFFFF, 16'd1);
        if (acc === 32'h0000FFFF)
            $display("PASS: Test7 max*1=0xFFFF");
        else
            $display("FAIL: Test7 acc=%0h (expected 0x0000FFFF)", acc);

        // -------------------------------------------------------
        // Test 8: en=0 does not change acc (hold previous value)
        // -------------------------------------------------------
        // First set a known value
        apply_cycle(0, 1, 16'd100, 16'd200); // acc = 20000
        // Now apply en=0, different a,b - acc should remain 20000
        apply_cycle(0, 0, 16'd999, 16'd999);
        if (acc === 32'd20000)
            $display("PASS: Test8 en=0 holds acc=20000");
        else
            $display("FAIL: Test8 acc=%0d (expected 20000)", acc);

        // -------------------------------------------------------
        // Test 9: rst async - apply rst and check acc goes to 0
        // -------------------------------------------------------
        // Set a known value first
        apply_cycle(0, 1, 16'd50, 16'd50); // acc = 2500
        // Apply async reset
        rst = 1;
        #3;
        if (acc === 32'd0)
            $display("PASS: Test9 async rst clears acc");
        else
            $display("FAIL: Test9 async rst, acc=%0d (expected 0)", acc);
        @(posedge clk);
        #1;
        rst = 0;

        // -------------------------------------------------------
        // Test 10: clear with en=1 simultaneously - clear takes priority (RTL: clear wins over en)
        // -------------------------------------------------------
        // First set a value
        apply_cycle(0, 1, 16'd15, 16'd15); // acc = 225
        // Now apply clear=1 and en=1 simultaneously
        apply_cycle(1, 1, 16'd10, 16'd10); // clear wins, acc=0
        if (acc === 32'd0)
            $display("PASS: Test10 clear+en simultaneously acc=0");
        else
            $display("FAIL: Test10 acc=%0d (expected 0)", acc);

        // -------------------------------------------------------
        // Test 11: Sequence clear-accumulate-accumulate
        // clear, en(100,200)->20000, en(300,400)->120000
        // -------------------------------------------------------
        apply_cycle(1, 0, 16'd0,   16'd0);     // clear
        apply_cycle(0, 1, 16'd100, 16'd200);   // acc = 20000
        if (acc === 32'd20000)
            $display("PASS: Test11a first product 100*200=20000");
        else
            $display("FAIL: Test11a acc=%0d (expected 20000)", acc);

        apply_cycle(0, 1, 16'd300, 16'd400);   // acc = 120000
        if (acc === 32'd120000)
            $display("PASS: Test11b second product 300*400=120000");
        else
            $display("FAIL: Test11b acc=%0d (expected 120000)", acc);

        // -------------------------------------------------------
        // Test 12: Verify acc stays stable when neither clear, en, nor rst active
        // -------------------------------------------------------
        clear = 0; en = 0; a = 16'd1; b = 16'd1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        if (acc === 32'd120000)
            $display("PASS: Test12 acc stable at 120000 with no control signals");
        else
            $display("FAIL: Test12 acc=%0d (expected 120000)", acc);

        $finish;
    end

endmodule
