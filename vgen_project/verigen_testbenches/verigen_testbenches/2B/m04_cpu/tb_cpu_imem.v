`timescale 1ns/1ps

// Testbench for cpu_imem
// Tests the instruction memory module with various address inputs and
// verifies correct instruction output for pre-loaded memory patterns.
// Note: Since cpu_imem uses $readmemh("imem_init.mem", mem), we cannot
// directly initialize the memory from the testbench. Instead, we test
// the address decoding logic by writing to the DUT's internal memory
// via hierarchical reference, and then read back via the output port.

module tb_cpu_imem;

    // Clock and reset (required by general rules, even if DUT is combinational)
    reg clk;
    reg rst;

    // DUT connections
    reg  [31:0] addr;
    wire [31:0] instr;

    // DUT instance
    cpu_imem uut (
        .addr  (addr),
        .instr (instr)
    );

    // Clock generation: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Synchronous reset for 5 rising edges
    integer i;
    initial begin
        rst = 1;
        addr = 32'h0;
        repeat (5) @(posedge clk);
        rst = 0;
    end

    // Pre-load known instructions into the DUT memory via hierarchical reference
    // These represent RISC-V style 32-bit instructions for the tests below.
    // ADD  x1, x2, x3  => 0x003100B3
    // LW   x1, 0(x2)   => 0x00010083
    // SW   x1, 0(x2)   => 0x00110023  (SW x1, 0(x2))
    // BEQ  x1, x1, +8  => 0x00108463  (BEQ x1, x1, offset=8)
    // NOP (ADDI x0,x0,0) => 0x00000013
    // All-zero instruction => 0x00000000
    // All-ones instruction => 0xFFFFFFFF
    // Maximum address test => 0xDEADBEEF

    initial begin
        // Wait until reset is done
        @(negedge rst);
        @(posedge clk); #1;

        // Pre-load DUT internal memory
        uut.mem[0]   = 32'h003100B3; // ADD  x1, x2, x3
        uut.mem[1]   = 32'h00010083; // LW   x1, 0(x2)
        uut.mem[2]   = 32'h00110023; // SW   x1, 0(x2)
        uut.mem[3]   = 32'h00108463; // BEQ  x1, x1, +8
        uut.mem[4]   = 32'h00000013; // NOP
        uut.mem[5]   = 32'h00000000; // All zeros
        uut.mem[63]  = 32'hFFFFFFFF; // All ones (address byte 252 = 0xFC)
        uut.mem[255] = 32'hDEADBEEF; // Max address index

        // ------------------------------------------------------------
        // Test 1: ADD instruction at address 0x000 (word index 0)
        // addr[9:2] = 0
        // ------------------------------------------------------------
        addr = 32'h00000000;
        #2;
        if (instr === 32'h003100B3)
            $display("PASS: Test 1 - ADD instruction read from addr=0x00000000");
        else
            $display("FAIL: Test 1 - ADD instruction, expected 0x003100B3, got 0x%08X", instr);

        // ------------------------------------------------------------
        // Test 2: LW instruction at address 0x004 (word index 1)
        // addr[9:2] = 1
        // ------------------------------------------------------------
        addr = 32'h00000004;
        #2;
        if (instr === 32'h00010083)
            $display("PASS: Test 2 - LW instruction read from addr=0x00000004");
        else
            $display("FAIL: Test 2 - LW instruction, expected 0x00010083, got 0x%08X", instr);

        // ------------------------------------------------------------
        // Test 3: SW instruction at address 0x008 (word index 2)
        // addr[9:2] = 2
        // ------------------------------------------------------------
        addr = 32'h00000008;
        #2;
        if (instr === 32'h00110023)
            $display("PASS: Test 3 - SW instruction read from addr=0x00000008");
        else
            $display("FAIL: Test 3 - SW instruction, expected 0x00110023, got 0x%08X", instr);

        // ------------------------------------------------------------
        // Test 4: BEQ instruction at address 0x00C (word index 3)
        // addr[9:2] = 3
        // ------------------------------------------------------------
        addr = 32'h0000000C;
        #2;
        if (instr === 32'h00108463)
            $display("PASS: Test 4 - BEQ instruction read from addr=0x0000000C");
        else
            $display("FAIL: Test 4 - BEQ instruction, expected 0x00108463, got 0x%08X", instr);

        // ------------------------------------------------------------
        // Test 5: NOP instruction at address 0x010 (word index 4)
        // addr[9:2] = 4
        // ------------------------------------------------------------
        addr = 32'h00000010;
        #2;
        if (instr === 32'h00000013)
            $display("PASS: Test 5 - NOP instruction read from addr=0x00000010");
        else
            $display("FAIL: Test 5 - NOP instruction, expected 0x00000013, got 0x%08X", instr);

        // ------------------------------------------------------------
        // Test 6: All-zero instruction at address 0x014 (word index 5)
        // addr[9:2] = 5
        // ------------------------------------------------------------
        addr = 32'h00000014;
        #2;
        if (instr === 32'h00000000)
            $display("PASS: Test 6 - All-zero instruction read from addr=0x00000014");
        else
            $display("FAIL: Test 6 - All-zero instruction, expected 0x00000000, got 0x%08X", instr);

        // ------------------------------------------------------------
        // Test 7: All-ones instruction at address 0x0FC (word index 63)
        // addr[9:2] = 63, addr = 63*4 = 252 = 0xFC
        // ------------------------------------------------------------
        addr = 32'h000000FC;
        #2;
        if (instr === 32'hFFFFFFFF)
            $display("PASS: Test 7 - All-ones instruction read from addr=0x000000FC");
        else
            $display("FAIL: Test 7 - All-ones instruction, expected 0xFFFFFFFF, got 0x%08X", instr);

        // ------------------------------------------------------------
        // Test 8: Max address index (word index 255, addr = 255*4 = 1020 = 0x3FC)
        // addr[9:2] = 255
        // ------------------------------------------------------------
        addr = 32'h000003FC;
        #2;
        if (instr === 32'hDEADBEEF)
            $display("PASS: Test 8 - Max address (0x3FC) reads 0xDEADBEEF");
        else
            $display("FAIL: Test 8 - Max address, expected 0xDEADBEEF, got 0x%08X", instr);

        // ------------------------------------------------------------
        // Test 9: Address byte offset ignored (addr=0x001 => addr[9:2]=0)
        // Same word as index 0
        // ------------------------------------------------------------
        addr = 32'h00000001;
        #2;
        if (instr === 32'h003100B3)
            $display("PASS: Test 9 - Byte-offset addr=0x001, still reads word index 0");
        else
            $display("FAIL: Test 9 - Byte-offset addr=0x001, expected 0x003100B3, got 0x%08X", instr);

        // ------------------------------------------------------------
        // Test 10: Address bits above [9] ignored (addr=0x00000400 => addr[9:2]=0)
        // Bit 10 set but addr[9:2]=0
        // ------------------------------------------------------------
        addr = 32'h00000400;
        #2;
        if (instr === 32'h003100B3)
            $display("PASS: Test 10 - High bits ignored, addr=0x400 reads word index 0");
        else
            $display("FAIL: Test 10 - High bits ignored, expected 0x003100B3, got 0x%08X", instr);

        // ------------------------------------------------------------
        // Wait a couple of clocks and finish
        // ------------------------------------------------------------
        @(posedge clk);
        @(posedge clk);

        $finish;
    end

endmodule
