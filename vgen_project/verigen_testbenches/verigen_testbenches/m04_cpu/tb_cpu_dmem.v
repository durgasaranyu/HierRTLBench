`timescale 1ns / 1ps

module tb_cpu_dmem;

    // DUT connections
    reg         clk;
    reg  [31:0] addr;
    reg  [31:0] wdata;
    reg         mem_we;
    wire [31:0] rdata;

    // Reset signal (not used by DUT but required by general requirements)
    reg rst;

    // Instantiate DUT
    cpu_dmem uut (
        .clk    (clk),
        .addr   (addr),
        .wdata  (wdata),
        .mem_we (mem_we),
        .rdata  (rdata)
    );

    // Clock generation: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Temporary variable for expected values
    reg [31:0] expected;
    integer    i;

    initial begin
        // Initialize inputs
        addr   = 32'h0;
        wdata  = 32'h0;
        mem_we = 1'b0;
        rst    = 1'b1;

        // Assert synchronous reset for exactly 5 rising edges
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst = 1'b0;

        // ----------------------------------------------------------------
        // Test 1: Write a known value to address 0 and read it back
        //         (SW-like: write 0xDEADBEEF to word address 0)
        // ----------------------------------------------------------------
        addr   = 32'h0000_0000;
        wdata  = 32'hDEAD_BEEF;
        mem_we = 1'b1;
        @(posedge clk); #1;
        mem_we = 1'b0;
        // Asynchronous read - check immediately
        expected = 32'hDEAD_BEEF;
        if (rdata === expected)
            $display("PASS: SW word address 0, wrote 0xDEADBEEF, read back 0x%08X", rdata);
        else
            $display("FAIL: SW word address 0, expected 0x%08X, got 0x%08X", expected, rdata);

        // ----------------------------------------------------------------
        // Test 2: Write to word address 1 (byte addr 4) and read back
        //         (SW to addr 4 -> dmem[1])
        // ----------------------------------------------------------------
        addr   = 32'h0000_0004;
        wdata  = 32'h1234_5678;
        mem_we = 1'b1;
        @(posedge clk); #1;
        mem_we = 1'b0;
        expected = 32'h1234_5678;
        if (rdata === expected)
            $display("PASS: SW byte addr 4 (word 1), wrote 0x12345678, read back 0x%08X", rdata);
        else
            $display("FAIL: SW byte addr 4 (word 1), expected 0x%08X, got 0x%08X", expected, rdata);

        // ----------------------------------------------------------------
        // Test 3: LW - read word address 0 (should still be 0xDEADBEEF)
        // ----------------------------------------------------------------
        addr   = 32'h0000_0000;
        mem_we = 1'b0;
        #1; // asynchronous read
        expected = 32'hDEAD_BEEF;
        if (rdata === expected)
            $display("PASS: LW byte addr 0, expected 0x%08X, got 0x%08X", expected, rdata);
        else
            $display("FAIL: LW byte addr 0, expected 0x%08X, got 0x%08X", expected, rdata);

        // ----------------------------------------------------------------
        // Test 4: LW - read word address 1 (byte addr 4, should be 0x12345678)
        // ----------------------------------------------------------------
        addr   = 32'h0000_0004;
        mem_we = 1'b0;
        #1;
        expected = 32'h1234_5678;
        if (rdata === expected)
            $display("PASS: LW byte addr 4, expected 0x%08X, got 0x%08X", expected, rdata);
        else
            $display("FAIL: LW byte addr 4, expected 0x%08X, got 0x%08X", expected, rdata);

        // ----------------------------------------------------------------
        // Test 5: All-zero write (edge case)
        // ----------------------------------------------------------------
        addr   = 32'h0000_0008; // word index 2
        wdata  = 32'h0000_0000;
        mem_we = 1'b1;
        @(posedge clk); #1;
        mem_we = 1'b0;
        expected = 32'h0000_0000;
        if (rdata === expected)
            $display("PASS: SW all-zeros to addr 8 (word 2), got 0x%08X", rdata);
        else
            $display("FAIL: SW all-zeros to addr 8 (word 2), expected 0x%08X, got 0x%08X", expected, rdata);

        // ----------------------------------------------------------------
        // Test 6: All-ones write (edge case)
        // ----------------------------------------------------------------
        addr   = 32'h0000_000C; // word index 3
        wdata  = 32'hFFFF_FFFF;
        mem_we = 1'b1;
        @(posedge clk); #1;
        mem_we = 1'b0;
        expected = 32'hFFFF_FFFF;
        if (rdata === expected)
            $display("PASS: SW all-ones to addr 0xC (word 3), got 0x%08X", rdata);
        else
            $display("FAIL: SW all-ones to addr 0xC (word 3), expected 0x%08X, got 0x%08X", expected, rdata);

        // ----------------------------------------------------------------
        // Test 7: Maximum address (word index 255, byte addr 0x3FC)
        // ----------------------------------------------------------------
        addr   = 32'h0000_03FC; // 255*4 = 1020 = 0x3FC
        wdata  = 32'hCAFE_BABE;
        mem_we = 1'b1;
        @(posedge clk); #1;
        mem_we = 1'b0;
        expected = 32'hCAFE_BABE;
        if (rdata === expected)
            $display("PASS: SW max addr 0x3FC (word 255), got 0x%08X", rdata);
        else
            $display("FAIL: SW max addr 0x3FC (word 255), expected 0x%08X, got 0x%08X", expected, rdata);

        // ----------------------------------------------------------------
        // Test 8: Verify mem_we=0 does not overwrite existing data
        //         Write attempt with mem_we=0 should not change stored value
        // ----------------------------------------------------------------
        addr   = 32'h0000_0000; // word 0 = 0xDEADBEEF
        wdata  = 32'hBAD0_C0DE; // attempt to write a different value
        mem_we = 1'b0;           // write enable is deasserted
        @(posedge clk); #1;
        expected = 32'hDEAD_BEEF;
        if (rdata === expected)
            $display("PASS: No write when mem_we=0, word 0 still 0x%08X", rdata);
        else
            $display("FAIL: No write when mem_we=0, expected 0x%08X, got 0x%08X", expected, rdata);

        // ----------------------------------------------------------------
        // Test 9: ADD simulation - write result to a register-mapped address
        //         Simulate ADD: result = 5 + 7 = 12, store to addr 0x10
        // ----------------------------------------------------------------
        addr   = 32'h0000_0010; // word index 4
        wdata  = 32'h0000_0005 + 32'h0000_0007; // = 12 = 0xC
        mem_we = 1'b1;
        @(posedge clk); #1;
        mem_we = 1'b0;
        expected = 32'h0000_000C;
        if (rdata === expected)
            $display("PASS: ADD result (5+7=12) stored at addr 0x10, got 0x%08X", rdata);
        else
            $display("FAIL: ADD result (5+7=12) at addr 0x10, expected 0x%08X, got 0x%08X", expected, rdata);

        // ----------------------------------------------------------------
        // Test 10: BEQ simulation - branch check: store branch target to addr 0x14
        //          If rs1==rs2, PC = PC + offset; store the branched PC value
        // ----------------------------------------------------------------
        // Simulate: rs1 = rs2 = 0xA, branch taken, new_PC = 0x20 (branch target)
        addr   = 32'h0000_0014; // word index 5
        wdata  = 32'h0000_0020; // branch target PC
        mem_we = 1'b1;
        @(posedge clk); #1;
        mem_we = 1'b0;
        expected = 32'h0000_0020;
        if (rdata === expected)
            $display("PASS: BEQ branch target 0x20 stored at addr 0x14, got 0x%08X", rdata);
        else
            $display("FAIL: BEQ branch target 0x20 at addr 0x14, expected 0x%08X, got 0x%08X", expected, rdata);

        // ----------------------------------------------------------------
        // Test 11: Multiple back-to-back writes (pipeline-like)
        // ----------------------------------------------------------------
        // Write to word 6
        addr   = 32'h0000_0018;
        wdata  = 32'hAAAA_AAAA;
        mem_we = 1'b1;
        @(posedge clk); #1;
        // Write to word 7
        addr   = 32'h0000_001C;
        wdata  = 32'h5555_5555;
        mem_we = 1'b1;
        @(posedge clk); #1;
        mem_we = 1'b0;

        // Verify word 7
        expected = 32'h5555_5555;
        if (rdata === expected)
            $display("PASS: Back-to-back SW word 7 = 0x55555555, got 0x%08X", rdata);
        else
            $display("FAIL: Back-to-back SW word 7, expected 0x%08X, got 0x%08X", expected, rdata);

        // Verify word 6
        addr   = 32'h0000_0018;
        #1;
        expected = 32'hAAAA_AAAA;
        if (rdata === expected)
            $display("PASS: Back-to-back SW word 6 = 0xAAAAAAAA, got 0x%08X", rdata);
        else
            $display("FAIL: Back-to-back SW word 6, expected 0x%08X, got 0x%08X", expected, rdata);

        // ----------------------------------------------------------------
        // Test 12: Byte-offset address (addr[1:0] != 0) - check word alignment
        //          addr = 0x05 -> addr[31:2] = 1 -> should read word 1
        // ----------------------------------------------------------------
        addr = 32'h0000_0005; // misaligned, but [31:2] = 1
        #1;
        expected = 32'h1234_5678; // word 1 was written in Test 2
        if (rdata === expected)
            $display("PASS: Misaligned addr 0x05 reads word index 1 = 0x%08X", rdata);
        else
            $display("FAIL: Misaligned addr 0x05 reads word index 1, expected 0x%08X, got 0x%08X", expected, rdata);

        // ----------------------------------------------------------------
        // Finish simulation
        // ----------------------------------------------------------------
        #20;
        $finish;
    end

endmodule
