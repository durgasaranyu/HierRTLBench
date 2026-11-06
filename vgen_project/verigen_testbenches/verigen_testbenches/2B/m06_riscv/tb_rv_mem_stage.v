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

    // Synchronous reset equivalent: just idle for 5 rising edges
    // (module has no reset, so we simply wait)
    integer i;
    integer pass_count;
    integer fail_count;

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize inputs
        alu_result = 0;
        rs2_data   = 0;
        mem_write  = 0;
        mem_read   = 0;

        // Wait for 5 rising edges (reset equivalent)
        repeat (5) @(posedge clk);

        // ----------------------------------------------------------------
        // Test 1: Write to address 0, read back
        // ----------------------------------------------------------------
        alu_result = 32'd0;
        rs2_data   = 32'hDEADBEEF;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1; // small delay after clock edge
        mem_write  = 0;
        mem_read   = 1;
        alu_result = 32'd0;
        #1;
        if (read_data === 32'hDEADBEEF) begin
            $display("PASS: Test 1 - Write/Read address 0 (0xDEADBEEF)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 1 - Write/Read address 0. Expected 0xDEADBEEF, got 0x%08X", read_data);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 2: Write to address 1, read back
        // ----------------------------------------------------------------
        alu_result = 32'd1;
        rs2_data   = 32'hCAFEBABE;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write  = 0;
        mem_read   = 1;
        alu_result = 32'd1;
        #1;
        if (read_data === 32'hCAFEBABE) begin
            $display("PASS: Test 2 - Write/Read address 1 (0xCAFEBABE)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 2 - Write/Read address 1. Expected 0xCAFEBABE, got 0x%08X", read_data);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 3: All-zero data write to address 5
        // ----------------------------------------------------------------
        alu_result = 32'd5;
        rs2_data   = 32'h00000000;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write  = 0;
        mem_read   = 1;
        alu_result = 32'd5;
        #1;
        if (read_data === 32'h00000000) begin
            $display("PASS: Test 3 - All-zero data at address 5");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 3 - All-zero data at address 5. Expected 0x00000000, got 0x%08X", read_data);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 4: All-ones data write to address 10
        // ----------------------------------------------------------------
        alu_result = 32'd10;
        rs2_data   = 32'hFFFFFFFF;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write  = 0;
        mem_read   = 1;
        alu_result = 32'd10;
        #1;
        if (read_data === 32'hFFFFFFFF) begin
            $display("PASS: Test 4 - All-ones data at address 10");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 4 - All-ones data at address 10. Expected 0xFFFFFFFF, got 0x%08X", read_data);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 5: Write to maximum address (255), read back
        // ----------------------------------------------------------------
        alu_result = 32'd255;
        rs2_data   = 32'h12345678;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write  = 0;
        mem_read   = 1;
        alu_result = 32'd255;
        #1;
        if (read_data === 32'h12345678) begin
            $display("PASS: Test 5 - Write/Read maximum address 255");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 5 - Write/Read maximum address 255. Expected 0x12345678, got 0x%08X", read_data);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 6: No write (mem_write=0) does not change memory
        // Write known value first, then attempt write with mem_write=0
        // ----------------------------------------------------------------
        // First write known value to address 20
        alu_result = 32'd20;
        rs2_data   = 32'hA5A5A5A5;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        // Now attempt to overwrite with mem_write=0
        alu_result = 32'd20;
        rs2_data   = 32'hBEEFBEEF;
        mem_write  = 0;
        mem_read   = 0;
        @(posedge clk);
        #1;
        // Read back - should still be A5A5A5A5
        mem_write  = 0;
        mem_read   = 1;
        alu_result = 32'd20;
        #1;
        if (read_data === 32'hA5A5A5A5) begin
            $display("PASS: Test 6 - mem_write=0 does not alter memory");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 6 - mem_write=0 altered memory. Expected 0xA5A5A5A5, got 0x%08X", read_data);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 7: Asynchronous read - address 0 still holds written value
        // ----------------------------------------------------------------
        mem_write  = 0;
        mem_read   = 1;
        alu_result = 32'd0;
        #2;
        if (read_data === 32'hDEADBEEF) begin
            $display("PASS: Test 7 - Async read address 0 still 0xDEADBEEF");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 7 - Async read address 0. Expected 0xDEADBEEF, got 0x%08X", read_data);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 8: Sequential writes to multiple addresses, verify independently
        // ----------------------------------------------------------------
        mem_write  = 1;
        mem_read   = 0;

        alu_result = 32'd50;
        rs2_data   = 32'h11111111;
        @(posedge clk);
        #1;

        alu_result = 32'd51;
        rs2_data   = 32'h22222222;
        @(posedge clk);
        #1;

        alu_result = 32'd52;
        rs2_data   = 32'h33333333;
        @(posedge clk);
        #1;

        mem_write  = 0;
        mem_read   = 1;

        // Check address 50
        alu_result = 32'd50;
        #1;
        if (read_data === 32'h11111111) begin
            $display("PASS: Test 8a - Sequential write address 50 = 0x11111111");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 8a - address 50. Expected 0x11111111, got 0x%08X", read_data);
            fail_count = fail_count + 1;
        end

        // Check address 51
        alu_result = 32'd51;
        #1;
        if (read_data === 32'h22222222) begin
            $display("PASS: Test 8b - Sequential write address 51 = 0x22222222");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 8b - address 51. Expected 0x22222222, got 0x%08X", read_data);
            fail_count = fail_count + 1;
        end

        // Check address 52
        alu_result = 32'd52;
        #1;
        if (read_data === 32'h33333333) begin
            $display("PASS: Test 8c - Sequential write address 52 = 0x33333333");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 8c - address 52. Expected 0x33333333, got 0x%08X", read_data);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Test 9: Overwrite existing location and verify new value
        // ----------------------------------------------------------------
        alu_result = 32'd1;
        rs2_data   = 32'h0000FFFF;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write  = 0;
        mem_read   = 1;
        alu_result = 32'd1;
        #1;
        if (read_data === 32'h0000FFFF) begin
            $display("PASS: Test 9 - Overwrite address 1 with 0x0000FFFF");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 9 - Overwrite address 1. Expected 0x0000FFFF, got 0x%08X", read_data);
            fail_count = fail_count + 1;
        end

        // ----------------------------------------------------------------
        // Summary
        // ----------------------------------------------------------------
        $display("-------------------------------------------");
        $display("Tests complete: %0d passed, %0d failed", pass_count, fail_count);
        $display("-------------------------------------------");

        $finish;
    end

endmodule
