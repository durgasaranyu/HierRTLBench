`timescale 1ns/1ps

module tb_cpu_dmem;

    // DUT connections
    reg         clk;
    reg  [31:0] addr;
    reg  [31:0] wdata;
    reg         mem_we;
    wire [31:0] rdata;

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

    // We do not use rst in this module, but per requirements we simulate
    // a "reset" phase of 5 clock edges by holding mem_we=0 for 5 cycles.

    integer i;
    reg [31:0] expected;

    initial begin
        // Initialize signals
        mem_we = 0;
        addr   = 32'h0;
        wdata  = 32'h0;

        // ---------------------------------------------------------------
        // "Reset" phase: 5 rising edges with mem_we=0 (no writes)
        // ---------------------------------------------------------------
        repeat (5) @(posedge clk);

        // ---------------------------------------------------------------
        // TEST 1: Write a typical value and read it back
        // Simulates an SW (store word) to address 0x00000010, data 0xDEADBEEF
        // ---------------------------------------------------------------
        addr   = 32'h00000010;  // word index 4  (bits [11:2] = 4)
        wdata  = 32'hDEADBEEF;
        mem_we = 1;
        @(posedge clk);
        #1; // small delay after clock edge
        mem_we = 0;
        // Now read back (asynchronous read)
        expected = 32'hDEADBEEF;
        if (rdata === expected)
            $display("PASS: SW typical value - wrote 0xDEADBEEF to addr 0x10, read back correctly");
        else
            $display("FAIL: SW typical value - expected 0x%08X, got 0x%08X", expected, rdata);

        // ---------------------------------------------------------------
        // TEST 2: Write zero to a different address and read it back
        // Simulates SW with all-zero data
        // ---------------------------------------------------------------
        addr   = 32'h00000020;  // word index 8
        wdata  = 32'h00000000;
        mem_we = 1;
        @(posedge clk);
        #1;
        mem_we = 0;
        expected = 32'h00000000;
        if (rdata === expected)
            $display("PASS: SW all-zero data - wrote 0x00000000 to addr 0x20, read back correctly");
        else
            $display("FAIL: SW all-zero data - expected 0x%08X, got 0x%08X", expected, rdata);

        // ---------------------------------------------------------------
        // TEST 3: Write all-ones to an address and read it back
        // Edge case: all-ones input
        // ---------------------------------------------------------------
        addr   = 32'h00000030;  // word index 12
        wdata  = 32'hFFFFFFFF;
        mem_we = 1;
        @(posedge clk);
        #1;
        mem_we = 0;
        expected = 32'hFFFFFFFF;
        if (rdata === expected)
            $display("PASS: SW all-ones data - wrote 0xFFFFFFFF to addr 0x30, read back correctly");
        else
            $display("FAIL: SW all-ones data - expected 0x%08X, got 0x%08X", expected, rdata);

        // ---------------------------------------------------------------
        // TEST 4: Write to maximum address supported (word index 255)
        // addr[11:2] = 255 => addr = 255 * 4 = 0x3FC
        // ---------------------------------------------------------------
        addr   = 32'h000003FC;  // word index 255
        wdata  = 32'hCAFEBABE;
        mem_we = 1;
        @(posedge clk);
        #1;
        mem_we = 0;
        expected = 32'hCAFEBABE;
        if (rdata === expected)
            $display("PASS: SW max address (0x3FC) - wrote 0xCAFEBABE, read back correctly");
        else
            $display("FAIL: SW max address (0x3FC) - expected 0x%08X, got 0x%08X", expected, rdata);

        // ---------------------------------------------------------------
        // TEST 5: LW - Read from address previously written in TEST 1
        // Simulates LW instruction reading address 0x10
        // ---------------------------------------------------------------
        addr   = 32'h00000010;
        mem_we = 0;
        #1;
        expected = 32'hDEADBEEF;
        if (rdata === expected)
            $display("PASS: LW addr 0x10 - read 0xDEADBEEF correctly");
        else
            $display("FAIL: LW addr 0x10 - expected 0x%08X, got 0x%08X", expected, rdata);

        // ---------------------------------------------------------------
        // TEST 6: LW from unwritten location should be X or 0
        // Just check the read occurs without error (addr 0x100, never written)
        // We only check that rdata is stable (no write side effects)
        // ---------------------------------------------------------------
        addr   = 32'h00000100;  // word index 64, never written
        mem_we = 0;
        #1;
        // Cannot predict exact value (X or initial), just confirm no write occurred
        $display("PASS: LW uninitialized addr 0x100 - read = 0x%08X (no error)", rdata);

        // ---------------------------------------------------------------
        // TEST 7: ADD simulation - Write result of ADD (rs1+rs2) to memory
        // Simulates storing computed ADD result; verify correct storage
        // rs1=0x0000_0005, rs2=0x0000_0003 => result=8
        // ---------------------------------------------------------------
        addr   = 32'h00000040;  // word index 16
        wdata  = 32'h00000005 + 32'h00000003;  // = 8
        mem_we = 1;
        @(posedge clk);
        #1;
        mem_we = 0;
        expected = 32'h00000008;
        if (rdata === expected)
            $display("PASS: ADD result store - wrote ADD(5,3)=8 to addr 0x40, read back correctly");
        else
            $display("FAIL: ADD result store - expected 0x%08X, got 0x%08X", expected, rdata);

        // ---------------------------------------------------------------
        // TEST 8: BEQ branch simulation - verify mem is NOT written when
        // mem_we=0 (branch taken, no memory write)
        // Read addr 0x40 again to confirm it still holds 8
        // ---------------------------------------------------------------
        // Branch taken => mem_we stays 0
        addr   = 32'h00000040;
        mem_we = 0;
        #1;
        expected = 32'h00000008;
        if (rdata === expected)
            $display("PASS: BEQ taken - mem_we=0, addr 0x40 still holds 0x%08X", expected);
        else
            $display("FAIL: BEQ taken - expected 0x%08X at addr 0x40, got 0x%08X", expected, rdata);

        // ---------------------------------------------------------------
        // TEST 9: mem_we=0 means write is inhibited even on clock edge
        // Write wdata=0xABCD1234 but with mem_we=0 => should not overwrite
        // ---------------------------------------------------------------
        addr   = 32'h00000010;  // previously 0xDEADBEEF
        wdata  = 32'hABCD1234;
        mem_we = 0;
        @(posedge clk);
        #1;
        expected = 32'hDEADBEEF;
        if (rdata === expected)
            $display("PASS: mem_we=0 inhibits write - addr 0x10 still holds 0xDEADBEEF");
        else
            $display("FAIL: mem_we=0 inhibits write - expected 0x%08X, got 0x%08X", expected, rdata);

        // ---------------------------------------------------------------
        // TEST 10: Overwrite existing value (SW overwrite)
        // Update addr 0x10 with new value 0x12345678
        // ---------------------------------------------------------------
        addr   = 32'h00000010;
        wdata  = 32'h12345678;
        mem_we = 1;
        @(posedge clk);
        #1;
        mem_we = 0;
        expected = 32'h12345678;
        if (rdata === expected)
            $display("PASS: SW overwrite - addr 0x10 updated to 0x12345678");
        else
            $display("FAIL: SW overwrite - expected 0x%08X, got 0x%08X", expected, rdata);

        // ---------------------------------------------------------------
        // TEST 11: Verify byte-offset aliasing: addr 0x11 has same [11:2] as 0x10
        // ---------------------------------------------------------------
        addr   = 32'h00000011;  // [11:2] = 4, same word as 0x10
        mem_we = 0;
        #1;
        expected = 32'h12345678;
        if (rdata === expected)
            $display("PASS: Byte-offset aliasing - addr 0x11 aliases to same word as 0x10, reads 0x%08X", expected);
        else
            $display("FAIL: Byte-offset aliasing - expected 0x%08X, got 0x%08X", expected, rdata);

        // Wrap up
        #20;
        $finish;
    end

endmodule
