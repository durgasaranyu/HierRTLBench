`timescale 1ns/1ps

module tb_cpu_dmem;

    // -------------------------------------------------------
    // DUT connections
    // -------------------------------------------------------
    reg         clk;
    reg  [31:0] addr;
    reg  [31:0] wdata;
    reg         mem_we;
    wire [31:0] rdata;

    // -------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------
    cpu_dmem uut (
        .clk    (clk),
        .addr   (addr),
        .wdata  (wdata),
        .mem_we (mem_we),
        .rdata  (rdata)
    );

    // -------------------------------------------------------
    // Clock generation: 10 ns period
    // -------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------
    // Helper integer
    // -------------------------------------------------------
    integer i;

    // -------------------------------------------------------
    // Test procedure
    // -------------------------------------------------------
    initial begin
        // Default inputs
        addr   = 32'h0;
        wdata  = 32'h0;
        mem_we = 1'b0;

        // =====================================================
        // Synchronous reset equivalent:
        // Hold inputs at default for 5 rising edges.
        // (cpu_dmem has no rst port; we simply wait.)
        // =====================================================
        repeat (5) @(posedge clk);

        // =====================================================
        // Pre-load known values by writing to several locations
        // =====================================================

        // ----- Test 1: Write to address 0x00 (word 0) -----
        @(negedge clk);
        addr   = 32'h00000000;   // word index 0
        wdata  = 32'hDEADBEEF;
        mem_we = 1'b1;
        @(posedge clk);          // latch on rising edge
        #1;
        mem_we = 1'b0;

        // Read back immediately (asynchronous read)
        addr = 32'h00000000;
        #1;
        if (rdata === 32'hDEADBEEF)
            $display("PASS: SW word 0 -> 0xDEADBEEF, read back 0x%08X", rdata);
        else
            $display("FAIL: SW word 0 -> expected 0xDEADBEEF, got 0x%08X", rdata);

        // ----- Test 2: Write to address 0x04 (word 1) -----
        @(negedge clk);
        addr   = 32'h00000004;   // word index 1
        wdata  = 32'hCAFEBABE;
        mem_we = 1'b1;
        @(posedge clk);
        #1;
        mem_we = 1'b0;
        addr   = 32'h00000004;
        #1;
        if (rdata === 32'hCAFEBABE)
            $display("PASS: SW word 1 -> 0xCAFEBABE, read back 0x%08X", rdata);
        else
            $display("FAIL: SW word 1 -> expected 0xCAFEBABE, got 0x%08X", rdata);

        // ----- Test 3: LW from word 0 -----
        // (No write; just assert read address and check data written in test 1)
        @(negedge clk);
        mem_we = 1'b0;
        addr   = 32'h00000000;
        #1;
        if (rdata === 32'hDEADBEEF)
            $display("PASS: LW word 0 -> 0xDEADBEEF");
        else
            $display("FAIL: LW word 0 -> expected 0xDEADBEEF, got 0x%08X", rdata);

        // ----- Test 4: LW from word 1 -----
        @(negedge clk);
        mem_we = 1'b0;
        addr   = 32'h00000004;
        #1;
        if (rdata === 32'hCAFEBABE)
            $display("PASS: LW word 1 -> 0xCAFEBABE");
        else
            $display("FAIL: LW word 1 -> expected 0xCAFEBABE, got 0x%08X", rdata);

        // ----- Test 5: Write all-zeros to word 2 -----
        @(negedge clk);
        addr   = 32'h00000008;   // word index 2
        wdata  = 32'h00000000;
        mem_we = 1'b1;
        @(posedge clk);
        #1;
        mem_we = 1'b0;
        addr   = 32'h00000008;
        #1;
        if (rdata === 32'h00000000)
            $display("PASS: SW all-zeros to word 2, read back 0x%08X", rdata);
        else
            $display("FAIL: SW all-zeros to word 2 -> expected 0x00000000, got 0x%08X", rdata);

        // ----- Test 6: Write all-ones (max value) to word 63 (address=0xFC) -----
        @(negedge clk);
        addr   = 32'h000000FC;   // word index 63
        wdata  = 32'hFFFFFFFF;
        mem_we = 1'b1;
        @(posedge clk);
        #1;
        mem_we = 1'b0;
        addr   = 32'h000000FC;
        #1;
        if (rdata === 32'hFFFFFFFF)
            $display("PASS: SW all-ones to word 63, read back 0x%08X", rdata);
        else
            $display("FAIL: SW all-ones to word 63 -> expected 0xFFFFFFFF, got 0x%08X", rdata);

        // ----- Test 7: Byte-offset address — only bits [31:2] used -----
        // Writing to address 0x05 should write word index 1 (same as 0x04)
        @(negedge clk);
        addr   = 32'h00000005;   // byte 5, word index 1
        wdata  = 32'h12345678;
        mem_we = 1'b1;
        @(posedge clk);
        #1;
        mem_we = 1'b0;
        // Read from aligned address 0x04 (word 1)
        addr   = 32'h00000004;
        #1;
        if (rdata === 32'h12345678)
            $display("PASS: SW misaligned addr 0x05 -> word 1 = 0x%08X", rdata);
        else
            $display("FAIL: SW misaligned addr 0x05 -> expected 0x12345678, got 0x%08X", rdata);

        // ----- Test 8: mem_we=0 means no write (ADD result should NOT update memory) -----
        // Write known value to word 4, then try to write different value with mem_we=0
        @(negedge clk);
        addr   = 32'h00000010;   // word index 4
        wdata  = 32'hABCD1234;
        mem_we = 1'b1;
        @(posedge clk);
        #1;
        mem_we = 1'b0;
        // Now attempt write with mem_we=0
        addr   = 32'h00000010;
        wdata  = 32'h99999999;
        mem_we = 1'b0;
        @(posedge clk);          // rising edge, but mem_we=0 -> no write
        #1;
        addr   = 32'h00000010;
        #1;
        if (rdata === 32'hABCD1234)
            $display("PASS: mem_we=0 prevents write, word 4 still 0xABCD1234");
        else
            $display("FAIL: mem_we=0 should not write, expected 0xABCD1234, got 0x%08X", rdata);

        // ----- Test 9: Write maximum address word (word 255, addr=0x3FC) -----
        @(negedge clk);
        addr   = 32'h000003FC;   // word index 255
        wdata  = 32'hA5A5A5A5;
        mem_we = 1'b1;
        @(posedge clk);
        #1;
        mem_we = 1'b0;
        addr   = 32'h000003FC;
        #1;
        if (rdata === 32'hA5A5A5A5)
            $display("PASS: SW/LW max word (255) -> 0x%08X", rdata);
        else
            $display("FAIL: SW/LW max word (255) -> expected 0xA5A5A5A5, got 0x%08X", rdata);

        // ----- Test 10: Verify word 0 still holds DEADBEEF (BEQ: no unintended side-effect) -----
        @(negedge clk);
        mem_we = 1'b0;
        addr   = 32'h00000000;
        #1;
        if (rdata === 32'hDEADBEEF)
            $display("PASS: BEQ no side-effect, word 0 still 0xDEADBEEF");
        else
            $display("FAIL: BEQ no side-effect check, expected 0xDEADBEEF, got 0x%08X", rdata);

        // ----- Test 11: ADD result write and read-back (simulate register write through memory) -----
        // ADD: 32'h0000_0005 + 32'h0000_0003 = 32'h0000_0008
        @(negedge clk);
        addr   = 32'h00000014;   // word index 5
        wdata  = 32'h00000005 + 32'h00000003;  // ADD result = 8
        mem_we = 1'b1;
        @(posedge clk);
        #1;
        mem_we = 1'b0;
        addr   = 32'h00000014;
        #1;
        if (rdata === 32'h00000008)
            $display("PASS: ADD result (5+3=8) stored and read from word 5");
        else
            $display("FAIL: ADD result check -> expected 0x00000008, got 0x%08X", rdata);

        // =====================================================
        // Done
        // =====================================================
        #20;
        $finish;
    end

endmodule
