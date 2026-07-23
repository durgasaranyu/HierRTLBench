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

    // Clock generation: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Task: apply synchronous reset-like idle for 5 rising edges
    integer i;
    reg [31:0] expected;

    initial begin
        // Initialize inputs
        alu_result = 0;
        rs2_data   = 0;
        mem_write  = 0;
        mem_read   = 0;

        // "Reset" period: hold idle for 5 rising edges
        repeat (5) @(posedge clk);

        // -------------------------------------------------------
        // Test 1: Write data value 32'hDEAD_BEEF to address 0
        // -------------------------------------------------------
        @(negedge clk);
        alu_result = 32'h00000000;
        rs2_data   = 32'hDEADBEEF;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk); // write happens here
        #1;
        mem_write  = 0;

        // -------------------------------------------------------
        // Test 2: Read back from address 0, expect 32'hDEAD_BEEF
        // -------------------------------------------------------
        @(negedge clk);
        alu_result = 32'h00000000;
        mem_read   = 1;
        mem_write  = 0;
        #1;
        expected = 32'hDEADBEEF;
        if (read_data === expected)
            $display("PASS: Read back 0xDEADBEEF from address 0");
        else
            $display("FAIL: Read back from address 0 - expected 0x%08h got 0x%08h", expected, read_data);
        mem_read = 0;

        // -------------------------------------------------------
        // Test 3: Write all-zeros (zero data) to address 4
        // -------------------------------------------------------
        @(negedge clk);
        alu_result = 32'h00000004;
        rs2_data   = 32'h00000000;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write = 0;

        // Read back address 4, expect 0x00000000
        @(negedge clk);
        alu_result = 32'h00000004;
        mem_read   = 1;
        mem_write  = 0;
        #1;
        expected = 32'h00000000;
        if (read_data === expected)
            $display("PASS: Read back 0x00000000 from address 4 (all-zero data)");
        else
            $display("FAIL: Read from address 4 - expected 0x%08h got 0x%08h", expected, read_data);
        mem_read = 0;

        // -------------------------------------------------------
        // Test 4: Write all-ones to address 8
        // -------------------------------------------------------
        @(negedge clk);
        alu_result = 32'h00000008;
        rs2_data   = 32'hFFFFFFFF;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write = 0;

        // Read back address 8, expect 0xFFFFFFFF
        @(negedge clk);
        alu_result = 32'h00000008;
        mem_read   = 1;
        mem_write  = 0;
        #1;
        expected = 32'hFFFFFFFF;
        if (read_data === expected)
            $display("PASS: Read back 0xFFFFFFFF from address 8 (all-ones data)");
        else
            $display("FAIL: Read from address 8 - expected 0x%08h got 0x%08h", expected, read_data);
        mem_read = 0;

        // -------------------------------------------------------
        // Test 5: Write max address value (address 127) with 0xA5A5A5A5
        // -------------------------------------------------------
        @(negedge clk);
        alu_result = 32'h0000007F; // address 127
        rs2_data   = 32'hA5A5A5A5;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write = 0;

        // Read back address 127
        @(negedge clk);
        alu_result = 32'h0000007F;
        mem_read   = 1;
        mem_write  = 0;
        #1;
        expected = 32'hA5A5A5A5;
        if (read_data === expected)
            $display("PASS: Read back 0xA5A5A5A5 from address 127 (max address)");
        else
            $display("FAIL: Read from address 127 - expected 0x%08h got 0x%08h", expected, read_data);
        mem_read = 0;

        // -------------------------------------------------------
        // Test 6: No write (mem_write=0) - data should not change at address 0
        // Address 0 still holds 0xDEADBEEF from Test 1
        // -------------------------------------------------------
        @(negedge clk);
        alu_result = 32'h00000000;
        rs2_data   = 32'h12345678;
        mem_write  = 0; // NOT writing
        mem_read   = 0;
        @(posedge clk);
        #1;

        // Read address 0, should still be 0xDEADBEEF
        @(negedge clk);
        alu_result = 32'h00000000;
        mem_read   = 1;
        mem_write  = 0;
        #1;
        expected = 32'hDEADBEEF;
        if (read_data === expected)
            $display("PASS: Address 0 unchanged when mem_write=0 (still 0xDEADBEEF)");
        else
            $display("FAIL: Address 0 changed without write - expected 0x%08h got 0x%08h", expected, read_data);
        mem_read = 0;

        // -------------------------------------------------------
        // Test 7: Overwrite address 0 with new value 0x12345678
        // -------------------------------------------------------
        @(negedge clk);
        alu_result = 32'h00000000;
        rs2_data   = 32'h12345678;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write = 0;

        // Read back
        @(negedge clk);
        alu_result = 32'h00000000;
        mem_read   = 1;
        mem_write  = 0;
        #1;
        expected = 32'h12345678;
        if (read_data === expected)
            $display("PASS: Overwrite address 0 with 0x12345678 success");
        else
            $display("FAIL: Overwrite address 0 - expected 0x%08h got 0x%08h", expected, read_data);
        mem_read = 0;

        // -------------------------------------------------------
        // Test 8: Write to address 1 and verify different addresses independent
        // -------------------------------------------------------
        @(negedge clk);
        alu_result = 32'h00000001;
        rs2_data   = 32'hCAFEBABE;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write = 0;

        // Read from address 1 -> should be 0xCAFEBABE
        @(negedge clk);
        alu_result = 32'h00000001;
        mem_read   = 1;
        mem_write  = 0;
        #1;
        expected = 32'hCAFEBABE;
        if (read_data === expected)
            $display("PASS: Read 0xCAFEBABE from address 1");
        else
            $display("FAIL: Read from address 1 - expected 0x%08h got 0x%08h", expected, read_data);

        // Also verify address 0 is still 0x12345678
        alu_result = 32'h00000000;
        mem_read   = 1;
        mem_write  = 0;
        #1;
        expected = 32'h12345678;
        if (read_data === expected)
            $display("PASS: Address 0 still holds 0x12345678 after writing address 1");
        else
            $display("FAIL: Address 0 corrupted - expected 0x%08h got 0x%08h", expected, read_data);
        mem_read = 0;

        // -------------------------------------------------------
        // Test 9: mem_read=0, mem_write=0 - no operation, read_data may be anything
        //         Just verify no crash / output is stable
        // -------------------------------------------------------
        @(negedge clk);
        alu_result = 32'h00000002;
        rs2_data   = 32'hBEEFCAFE;
        mem_write  = 0;
        mem_read   = 0;
        #2;
        $display("PASS: No crash when mem_read=0 and mem_write=0 (read_data=0x%08h)", read_data);

        // -------------------------------------------------------
        // Test 10: Write 0x5A5A5A5A to address 63 (mid-range), read back
        // -------------------------------------------------------
        @(negedge clk);
        alu_result = 32'h0000003F; // 63
        rs2_data   = 32'h5A5A5A5A;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write = 0;

        @(negedge clk);
        alu_result = 32'h0000003F;
        mem_read   = 1;
        mem_write  = 0;
        #1;
        expected = 32'h5A5A5A5A;
        if (read_data === expected)
            $display("PASS: Read back 0x5A5A5A5A from address 63 (mid-range)");
        else
            $display("FAIL: Read from address 63 - expected 0x%08h got 0x%08h", expected, read_data);
        mem_read = 0;

        // Extra settling time
        repeat (3) @(posedge clk);

        $display("Testbench complete.");
        $finish;
    end

endmodule
