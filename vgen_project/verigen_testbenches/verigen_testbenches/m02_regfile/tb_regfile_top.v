`timescale 1ns/1ps

module tb_regfile_top;

    // DUT connections
    reg         clk;
    reg         rst;
    reg  [4:0]  rs1, rs2, rd;
    reg  [31:0] wdata;
    reg         we;
    wire [31:0] rdata1, rdata2;

    // Instantiate DUT
    regfile uut (
        .clk    (clk),
        .rst    (rst),
        .rs1    (rs1),
        .rs2    (rs2),
        .rd     (rd),
        .wdata  (wdata),
        .we     (we),
        .rdata1 (rdata1),
        .rdata2 (rdata2)
    );

    // Clock generation: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Task to apply one rising edge and wait a bit past it
    task apply_clock;
        begin
            @(posedge clk);
            #1; // small delay to let synchronous outputs settle
        end
    endtask

    integer k;
    reg [31:0] expected1, expected2;

    initial begin
        // --------------------------------------------------
        // Initialise inputs
        // --------------------------------------------------
        rst   = 1;
        rs1   = 5'd0;
        rs2   = 5'd0;
        rd    = 5'd0;
        wdata = 32'd0;
        we    = 0;

        // --------------------------------------------------
        // Assert reset for exactly 5 rising edges
        // --------------------------------------------------
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // --------------------------------------------------
        // After reset: verify that reads return 0 for several
        // registers (async read ports reflect register state)
        // The registers are synchronously written during reset,
        // so after reset they should all be 0.
        // We verify via asynchronous read ports.
        // --------------------------------------------------

        // Test 1: Read x0 after reset - must be 0
        rs1 = 5'd0;
        rs2 = 5'd1;
        we  = 0;
        #2;
        expected1 = 32'd0;
        expected2 = 32'd0;
        if (rdata1 === expected1)
            $display("PASS: Test1 - x0 reads 0 after reset (rdata1=%0h)", rdata1);
        else
            $display("FAIL: Test1 - x0 reads 0 after reset, got rdata1=%0h expected %0h", rdata1, expected1);
        if (rdata2 === expected2)
            $display("PASS: Test1 - x1 reads 0 after reset (rdata2=%0h)", rdata2);
        else
            $display("FAIL: Test1 - x1 reads 0 after reset, got rdata2=%0h expected %0h", rdata2, expected2);

        // --------------------------------------------------
        // Test 2: Write to x1, then read it back
        // --------------------------------------------------
        rd    = 5'd1;
        wdata = 32'hDEADBEEF;
        we    = 1;
        rs1   = 5'd1;
        rs2   = 5'd2;
        // Capture read-before-write (same cycle as write)
        // rdata1/rdata2 are async: they reflect current register value BEFORE the clock edge
        expected1 = 32'd0; // x1 still holds 0 before the clock edge
        expected2 = 32'd0; // x2 still holds 0 before the clock edge
        #1;
        if (rdata1 === expected1)
            $display("PASS: Test2a - write-after-read: old x1 value returned before clock edge (%0h)", rdata1);
        else
            $display("FAIL: Test2a - write-after-read: expected %0h, got %0h", expected1, rdata1);

        // Now clock the write in
        @(posedge clk); #1;
        we = 0;
        // x1 should now hold 0xDEADBEEF
        rs1 = 5'd1;
        rs2 = 5'd2;
        #1;
        expected1 = 32'hDEADBEEF;
        expected2 = 32'd0;
        if (rdata1 === expected1)
            $display("PASS: Test2b - x1 reads 0xDEADBEEF after write (rdata1=%0h)", rdata1);
        else
            $display("FAIL: Test2b - x1 expected %0h, got %0h", expected1, rdata1);
        if (rdata2 === expected2)
            $display("PASS: Test2b - x2 still reads 0 (rdata2=%0h)", rdata2);
        else
            $display("FAIL: Test2b - x2 expected %0h, got %0h", expected2, rdata2);

        // --------------------------------------------------
        // Test 3: Write to x0 and verify it always reads 0
        // The DUT writes regfile[0] on we, but rdata1/rdata2
        // return regfile[rs1/rs2] directly (async). x0 is NOT
        // hardwired in hw; the module description says it is,
        // but the RTL simply writes regfile[rd]. We test the
        // stated requirement: after writing to x0, x0 should
        // still read 0 IF the module enforces it.
        // Since the RTL does write regfile[0], we test what
        // actually happens and check against the module spec.
        // Per spec "x0 hardwired 0" - write should be ignored.
        // --------------------------------------------------
        rd    = 5'd0;
        wdata = 32'hCAFEBABE;
        we    = 1;
        @(posedge clk); #1;
        we  = 0;
        rs1 = 5'd0;
        rs2 = 5'd1;
        #1;
        // If x0 is truly hardwired 0, rdata1 should be 0
        // The RTL does write regfile[0], so it may or may not be 0
        // We check the spec requirement
        if (rdata1 === 32'd0)
            $display("PASS: Test3 - x0 reads 0 after write attempt (hardwired 0)");
        else
            $display("FAIL: Test3 - x0 should be 0 after write attempt, got %0h", rdata1);

        // --------------------------------------------------
        // Test 4: Dual read ports with different addresses
        // Write to x5 and x10, then read both simultaneously
        // --------------------------------------------------
        // Write x5 = 32'h11111111
        rd    = 5'd5;
        wdata = 32'h11111111;
        we    = 1;
        @(posedge clk); #1;
        // Write x10 = 32'h22222222
        rd    = 5'd10;
        wdata = 32'h22222222;
        we    = 1;
        @(posedge clk); #1;
        we  = 0;
        // Read both simultaneously
        rs1 = 5'd5;
        rs2 = 5'd10;
        #1;
        expected1 = 32'h11111111;
        expected2 = 32'h22222222;
        if (rdata1 === expected1 && rdata2 === expected2)
            $display("PASS: Test4 - dual read ports: rdata1=%0h rdata2=%0h", rdata1, rdata2);
        else
            $display("FAIL: Test4 - dual read ports: expected rdata1=%0h rdata2=%0h, got rdata1=%0h rdata2=%0h",
                     expected1, expected2, rdata1, rdata2);

        // --------------------------------------------------
        // Test 5: All-zero inputs (write 0 to x3, read x0 and x3)
        // --------------------------------------------------
        rd    = 5'd3;
        wdata = 32'd0;
        we    = 1;
        @(posedge clk); #1;
        we  = 0;
        rs1 = 5'd0;
        rs2 = 5'd3;
        #1;
        expected1 = 32'd0;
        expected2 = 32'd0;
        if (rdata1 === expected1)
            $display("PASS: Test5 - all-zero: x0=0");
        else
            $display("FAIL: Test5 - all-zero: x0 expected 0, got %0h", rdata1);
        if (rdata2 === expected2)
            $display("PASS: Test5 - all-zero: x3=0 after writing 0");
        else
            $display("FAIL: Test5 - all-zero: x3 expected 0, got %0h", rdata2);

        // --------------------------------------------------
        // Test 6: All-ones / maximum value write to x31
        // --------------------------------------------------
        rd    = 5'd31;
        wdata = 32'hFFFFFFFF;
        we    = 1;
        @(posedge clk); #1;
        we  = 0;
        rs1 = 5'd31;
        rs2 = 5'd31;
        #1;
        expected1 = 32'hFFFFFFFF;
        expected2 = 32'hFFFFFFFF;
        if (rdata1 === expected1)
            $display("PASS: Test6 - all-ones: x31=0xFFFFFFFF (rs1)");
        else
            $display("FAIL: Test6 - all-ones: x31 expected 0xFFFFFFFF, got %0h (rs1)", rdata1);
        if (rdata2 === expected2)
            $display("PASS: Test6 - all-ones: x31=0xFFFFFFFF (rs2)");
        else
            $display("FAIL: Test6 - all-ones: x31 expected 0xFFFFFFFF, got %0h (rs2)", rdata2);

        // --------------------------------------------------
        // Test 7: Synchronous reset zeroes all registers
        // Write non-zero to several registers first
        // --------------------------------------------------
        rd    = 5'd15;
        wdata = 32'hABCDABCD;
        we    = 1;
        @(posedge clk); #1;
        rd    = 5'd20;
        wdata = 32'h12345678;
        we    = 1;
        @(posedge clk); #1;
        we = 0;
        // Assert reset for 5 cycles
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;
        // Check that all written registers now read 0
        rs1 = 5'd15;
        rs2 = 5'd20;
        #1;
        expected1 = 32'd0;
        expected2 = 32'd0;
        if (rdata1 === expected1)
            $display("PASS: Test7 - reset zeroes x15");
        else
            $display("FAIL: Test7 - reset: x15 expected 0, got %0h", rdata1);
        if (rdata2 === expected2)
            $display("PASS: Test7 - reset zeroes x20");
        else
            $display("FAIL: Test7 - reset: x20 expected 0, got %0h", rdata2);

        // Also verify x31 was zeroed
        rs1 = 5'd31;
        rs2 = 5'd1;
        #1;
        if (rdata1 === 32'd0)
            $display("PASS: Test7 - reset zeroes x31");
        else
            $display("FAIL: Test7 - reset: x31 expected 0, got %0h", rdata1);
        if (rdata2 === 32'd0)
            $display("PASS: Test7 - reset zeroes x1");
        else
            $display("FAIL: Test7 - reset: x1 expected 0, got %0h", rdata2);

        // --------------------------------------------------
        // Test 8: Write-after-read on same cycle (write-enable
        // asserted while reading: old value should appear on
        // async read ports during that cycle)
        // --------------------------------------------------
        // First write a known value to x7
        rd    = 5'd7;
        wdata = 32'hBEEFCAFE;
        we    = 1;
        @(posedge clk); #1;
        we = 0;
        // Confirm x7 holds 0xBEEFCAFE
        rs1 = 5'd7;
        #1;
        expected1 = 32'hBEEFCAFE;
        if (rdata1 === expected1)
            $display("PASS: Test8a - x7 pre-check = 0xBEEFCAFE");
        else
            $display("FAIL: Test8a - x7 pre-check expected %0h, got %0h", expected1, rdata1);

        // Now assert write of new value to x7 and check that
        // async rdata1 still returns OLD value before clock edge
        rd    = 5'd7;
        wdata = 32'hFEEDFACE;
        we    = 1;
        rs1   = 5'd7;
        #1; // still before posedge
        expected1 = 32'hBEEFCAFE; // old value
        if (rdata1 === expected1)
            $display("PASS: Test8b - write-after-read: old value %0h seen before clock", rdata1);
        else
            $display("FAIL: Test8b - write-after-read: expected old=%0h, got %0h", expected1, rdata1);
        // Clock in the write
        @(posedge clk); #1;
        we = 0;
        #1;
        expected1 = 32'hFEEDFACE;
        if (rdata1 === expected1)
            $display("PASS: Test8c - new value %0h visible after clock", rdata1);
        else
            $display("FAIL: Test8c - new value expected %0h, got %0h", expected1, rdata1);

        // --------------------------------------------------
        // Additional test 9: we=0, read two distinct registers
        // --------------------------------------------------
        // Write x4=0xAAAAAAAA, x8=0x55555555
        rd    = 5'd4;
        wdata = 32'hAAAAAAAA;
        we    = 1;
        @(posedge clk); #1;
        rd    = 5'd8;
        wdata = 32'h55555555;
        we    = 1;
        @(posedge clk); #1;
        we  = 0;
        rs1 = 5'd4;
        rs2 = 5'd8;
        #1;
        expected1 = 32'hAAAAAAAA;
        expected2 = 32'h55555555;
        if (rdata1 === expected1 && rdata2 === expected2)
            $display("PASS: Test9 - independent reads: rs1=%0h rs2=%0h", rdata1, rdata2);
        else
            $display("FAIL: Test9 - independent reads: expected %0h/%0h, got %0h/%0h",
                     expected1, expected2, rdata1, rdata2);

        // --------------------------------------------------
        // Done
        // --------------------------------------------------
        #10;
        $finish;
    end

endmodule
