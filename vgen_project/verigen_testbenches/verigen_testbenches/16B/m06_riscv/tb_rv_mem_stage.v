`timescale 1ns/1ps

module tb_rv_mem_stage;

    // DUT connections
    reg         clk;
    reg  [31:0] alu_result;
    reg  [31:0] rs2_data;
    reg         mem_write;
    reg         mem_read;
    wire [31:0] read_data;

    // Instantiate DUT
    rv_mem_stage uut (
        .clk        (clk),
        .alu_result (alu_result),
        .rs2_data   (rs2_data),
        .mem_write  (mem_write),
        .mem_read   (mem_read),
        .read_data  (read_data)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (no rst pin on DUT, but we still wait appropriate cycles)
    integer fail_count;

    initial begin
        fail_count  = 0;

        // Initialize inputs
        alu_result = 0;
        rs2_data   = 0;
        mem_write  = 0;
        mem_read   = 0;

        // Wait 5 rising edges as per requirements (simulating reset period)
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        #2; // small offset after last edge

        // ---------------------------------------------------------------
        // Test 1: Read from un-written address (should be 0 initially)
        // ---------------------------------------------------------------
        rs2_data  = 32'd10;
        mem_write = 0;
        mem_read  = 1;
        #1; // async read - check immediately
        if (read_data === 32'd0)
            $display("PASS: Test1 - Read from unwritten addr 10 returns 0");
        else begin
            $display("FAIL: Test1 - Read from unwritten addr 10, expected 0, got %0d", read_data);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 2: Write a value and read it back (normal operation)
        // ---------------------------------------------------------------
        alu_result = 32'hDEADBEEF;
        rs2_data   = 32'd5;
        mem_write  = 1;
        mem_read   = 1;
        @(posedge clk); #2;
        // After posedge, mem[5] should be 0xDEADBEEF; async read on rs2_data=5
        mem_write = 0;
        #1;
        if (read_data === 32'hDEADBEEF)
            $display("PASS: Test2 - Write 0xDEADBEEF to addr 5, read back correct");
        else begin
            $display("FAIL: Test2 - Expected 0xDEADBEEF at addr 5, got 0x%08h", read_data);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 3: Write to address 0 (edge case - address zero)
        // ---------------------------------------------------------------
        alu_result = 32'hCAFEBABE;
        rs2_data   = 32'd0;
        mem_write  = 1;
        mem_read   = 1;
        @(posedge clk); #2;
        mem_write = 0;
        #1;
        if (read_data === 32'hCAFEBABE)
            $display("PASS: Test3 - Write 0xCAFEBABE to addr 0, read back correct");
        else begin
            $display("FAIL: Test3 - Expected 0xCAFEBABE at addr 0, got 0x%08h", read_data);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 4: Write to max address (255) - edge case
        // ---------------------------------------------------------------
        alu_result = 32'hFFFFFFFF;
        rs2_data   = 32'd255;
        mem_write  = 1;
        mem_read   = 1;
        @(posedge clk); #2;
        mem_write = 0;
        #1;
        if (read_data === 32'hFFFFFFFF)
            $display("PASS: Test4 - Write 0xFFFFFFFF to addr 255, read back correct");
        else begin
            $display("FAIL: Test4 - Expected 0xFFFFFFFF at addr 255, got 0x%08h", read_data);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 5: All-zeros data written to an address
        // ---------------------------------------------------------------
        // First write a non-zero value
        alu_result = 32'hAAAAAAAA;
        rs2_data   = 32'd20;
        mem_write  = 1;
        @(posedge clk); #2;
        // Now overwrite with zero
        alu_result = 32'd0;
        rs2_data   = 32'd20;
        mem_write  = 1;
        @(posedge clk); #2;
        mem_write = 0;
        #1;
        if (read_data === 32'd0)
            $display("PASS: Test5 - Overwrite addr 20 with 0, read back 0");
        else begin
            $display("FAIL: Test5 - Expected 0 at addr 20, got 0x%08h", read_data);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 6: mem_write=0, no write should occur (value preserved)
        // ---------------------------------------------------------------
        // addr 5 still has 0xDEADBEEF from Test2
        alu_result = 32'h12345678; // different value
        rs2_data   = 32'd5;
        mem_write  = 0;  // no write
        mem_read   = 1;
        @(posedge clk); #2;
        // mem[5] should still be 0xDEADBEEF
        #1;
        if (read_data === 32'hDEADBEEF)
            $display("PASS: Test6 - No write when mem_write=0, addr 5 still 0xDEADBEEF");
        else begin
            $display("FAIL: Test6 - Expected 0xDEADBEEF at addr 5 (no write), got 0x%08h", read_data);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 7: Sequential writes to different addresses
        // ---------------------------------------------------------------
        alu_result = 32'd100;
        rs2_data   = 32'd50;
        mem_write  = 1;
        @(posedge clk); #2;
        alu_result = 32'd200;
        rs2_data   = 32'd51;
        mem_write  = 1;
        @(posedge clk); #2;
        mem_write  = 0;
        // Check addr 50
        rs2_data   = 32'd50;
        #1;
        if (read_data === 32'd100)
            $display("PASS: Test7a - Sequential write addr 50 = 100, correct");
        else begin
            $display("FAIL: Test7a - Expected 100 at addr 50, got %0d", read_data);
            fail_count = fail_count + 1;
        end
        // Check addr 51
        rs2_data   = 32'd51;
        #1;
        if (read_data === 32'd200)
            $display("PASS: Test7b - Sequential write addr 51 = 200, correct");
        else begin
            $display("FAIL: Test7b - Expected 200 at addr 51, got %0d", read_data);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 8: All-ones address (wraps to 255 due to 8-bit indexing)
        // ---------------------------------------------------------------
        // addr 255 already has 0xFFFFFFFF from Test4
        rs2_data  = 32'hFFFFFFFF; // lower 8 bits = 0xFF = 255
        mem_write = 0;
        mem_read  = 1;
        #1;
        if (read_data === 32'hFFFFFFFF)
            $display("PASS: Test8 - All-ones address reads mem[255]=0xFFFFFFFF");
        else begin
            $display("FAIL: Test8 - Expected 0xFFFFFFFF at all-ones addr, got 0x%08h", read_data);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 9: Write max data value (0xFFFFFFFF) to address 1
        // ---------------------------------------------------------------
        alu_result = 32'hFFFFFFFF;
        rs2_data   = 32'd1;
        mem_write  = 1;
        mem_read   = 1;
        @(posedge clk); #2;
        mem_write = 0;
        #1;
        if (read_data === 32'hFFFFFFFF)
            $display("PASS: Test9 - Write max value 0xFFFFFFFF to addr 1, read back correct");
        else begin
            $display("FAIL: Test9 - Expected 0xFFFFFFFF at addr 1, got 0x%08h", read_data);
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
