`timescale 1ns/1ps

module tb_cpu_imem;

    // DUT connections
    reg  [31:0] addr;
    wire [31:0] instr;

    // Clock and reset (not used by this module, but required by general rules)
    reg clk;
    reg rst;

    // Instantiate DUT
    cpu_imem uut (
        .addr  (addr),
        .instr (instr)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset: assert for 5 rising edges, then deassert
    integer i;
    initial begin
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
    end

    // Test variables
    reg [31:0] expected;
    integer fail_count;

    initial begin
        fail_count = 0;

        // Wait until reset is deasserted
        @(negedge rst);
        #2; // small delay after reset

        // ---------------------------------------------------------------
        // Test 1: Address 0 -> mem[0] = 32'h00000000 (NOP)
        // ---------------------------------------------------------------
        addr = 32'd0; // addr[9:2] = 0 -> mem[0]
        #1;
        expected = 32'h00000000;
        if (instr === expected)
            $display("PASS: addr=0, mem[0]=0x%08h (NOP)", instr);
        else begin
            $display("FAIL: addr=0, expected=0x%08h got=0x%08h", expected, instr);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 2: Address 4 -> addr[9:2]=1 -> mem[1] = 32'h00000000
        // ---------------------------------------------------------------
        addr = 32'd4; // addr[9:2] = 1 -> mem[1]
        #1;
        expected = 32'h00000000;
        if (instr === expected)
            $display("PASS: addr=4, mem[1]=0x%08h (NOP)", instr);
        else begin
            $display("FAIL: addr=4, expected=0x%08h got=0x%08h", expected, instr);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 3: Address 8 -> addr[9:2]=2 -> mem[2] = 32'h00000000
        // ---------------------------------------------------------------
        addr = 32'd8; // addr[9:2] = 2 -> mem[2]
        #1;
        expected = 32'h00000000;
        if (instr === expected)
            $display("PASS: addr=8, mem[2]=0x%08h (NOP)", instr);
        else begin
            $display("FAIL: addr=8, expected=0x%08h got=0x%08h", expected, instr);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 4: Simulate ADD instruction fetch - addr[9:2]=3 -> mem[3]
        // All memory is 0 (NOPs), so we verify it reads 0 correctly.
        // This simulates the fetch phase of an ADD instruction pipeline.
        // ---------------------------------------------------------------
        addr = 32'd12; // addr[9:2] = 3 -> mem[3]
        #1;
        expected = 32'h00000000;
        if (instr === expected)
            $display("PASS: ADD fetch phase - addr=12, mem[3]=0x%08h", instr);
        else begin
            $display("FAIL: ADD fetch phase - addr=12, expected=0x%08h got=0x%08h", expected, instr);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 5: Simulate LW instruction fetch - addr[9:2]=4 -> mem[4]
        // Verify correct memory address is read (all zeros)
        // ---------------------------------------------------------------
        addr = 32'd16; // addr[9:2] = 4 -> mem[4]
        #1;
        expected = 32'h00000000;
        if (instr === expected)
            $display("PASS: LW fetch - addr=16, mem[4]=0x%08h", instr);
        else begin
            $display("FAIL: LW fetch - addr=16, expected=0x%08h got=0x%08h", expected, instr);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 6: Simulate SW instruction fetch - addr[9:2]=5 -> mem[5]
        // Verify correct address is written/read
        // ---------------------------------------------------------------
        addr = 32'd20; // addr[9:2] = 5 -> mem[5]
        #1;
        expected = 32'h00000000;
        if (instr === expected)
            $display("PASS: SW fetch - addr=20, mem[5]=0x%08h", instr);
        else begin
            $display("FAIL: SW fetch - addr=20, expected=0x%08h got=0x%08h", expected, instr);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 7: Simulate BEQ instruction fetch - addr[9:2]=6 -> mem[6]
        // Verify BEQ (rs1==rs2) branch address fetch returns 0
        // ---------------------------------------------------------------
        addr = 32'd24; // addr[9:2] = 6 -> mem[6]
        #1;
        expected = 32'h00000000;
        if (instr === expected)
            $display("PASS: BEQ fetch - addr=24, mem[6]=0x%08h", instr);
        else begin
            $display("FAIL: BEQ fetch - addr=24, expected=0x%08h got=0x%08h", expected, instr);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 8: Maximum word address in initialized range - mem[114]
        // addr[9:2] = 114 -> addr = 114*4 = 456
        // ---------------------------------------------------------------
        addr = 32'd456; // addr[9:2] = 114 -> mem[114]
        #1;
        expected = 32'h00000000;
        if (instr === expected)
            $display("PASS: Max init addr - addr=456, mem[114]=0x%08h", instr);
        else begin
            $display("FAIL: Max init addr - addr=456, expected=0x%08h got=0x%08h", expected, instr);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 9: All-zero address (edge case, same as test 1 but explicit)
        // ---------------------------------------------------------------
        addr = 32'h00000000;
        #1;
        expected = 32'h00000000;
        if (instr === expected)
            $display("PASS: All-zero addr=0x%08h, instr=0x%08h", addr, instr);
        else begin
            $display("FAIL: All-zero addr=0x%08h, expected=0x%08h got=0x%08h", addr, expected, instr);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 10: Address with non-zero lower 2 bits (byte address)
        // addr[9:2] = 0 still -> mem[0]
        // ---------------------------------------------------------------
        addr = 32'd3; // addr[9:2] = 0 -> mem[0]
        #1;
        expected = 32'h00000000;
        if (instr === expected)
            $display("PASS: Non-aligned addr=3, addr[9:2]=0, instr=0x%08h", instr);
        else begin
            $display("FAIL: Non-aligned addr=3, expected=0x%08h got=0x%08h", expected, instr);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 11: Address mid-range -> addr[9:2]=50 -> mem[50]
        // ---------------------------------------------------------------
        addr = 32'd200; // addr[9:2] = 50 -> mem[50]
        #1;
        expected = 32'h00000000;
        if (instr === expected)
            $display("PASS: Mid-range addr=200, mem[50]=0x%08h", instr);
        else begin
            $display("FAIL: Mid-range addr=200, expected=0x%08h got=0x%08h", expected, instr);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 12: Address near max (255*4=1020) -> mem[255]
        // (not initialized in module, but X or 0 depending on simulator)
        // We test that it doesn't crash and check for X
        // ---------------------------------------------------------------
        addr = 32'd1020; // addr[9:2] = 255 -> mem[255]
        #1;
        // mem[255] not explicitly initialized, could be X or 0
        // Just verify it's not Z (driven)
        if (instr !== 32'hzzzzzzzz)
            $display("PASS: Max mem addr=1020, mem[255]=0x%08h (not Z)", instr);
        else begin
            $display("FAIL: Max mem addr=1020, instr is high-Z");
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 13: Verify async read - change addr and check immediately
        // ---------------------------------------------------------------
        addr = 32'd0;
        #1;
        addr = 32'd4;
        #1;
        expected = 32'h00000000;
        if (instr === expected)
            $display("PASS: Async read - addr changed to 4, instr=0x%08h immediately", instr);
        else begin
            $display("FAIL: Async read - addr changed to 4, expected=0x%08h got=0x%08h", expected, instr);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Summary
        // ---------------------------------------------------------------
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
