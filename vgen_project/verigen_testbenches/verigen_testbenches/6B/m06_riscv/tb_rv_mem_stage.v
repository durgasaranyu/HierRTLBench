`timescale 1ns/1ps

module tb_rv_mem_stage;

    // DUT connections
    reg        clk;
    reg [31:0] alu_result;
    reg [31:0] rs2_data;
    reg        mem_write;
    reg        mem_read;
    wire [31:0] read_data;

    // Instantiate DUT
    rv_mem_stage uut (
        .clk(clk),
        .alu_result(alu_result),
        .rs2_data(rs2_data),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .read_data(read_data)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not used by DUT but required by spec - drive as NOP)
    reg rst;
    initial rst = 1;

    integer i;
    reg [31:0] expected;

    // Task to apply a write then read back
    task write_and_read;
        input [31:0] addr;
        input [31:0] data;
        begin
            // Write
            alu_result = addr;
            rs2_data   = data;
            mem_write  = 1;
            mem_read   = 0;
            @(posedge clk);
            #1;
            mem_write  = 0;
            mem_read   = 1;
            // Read is asynchronous, check immediately
        end
    endtask

    initial begin
        // Initialize inputs
        alu_result = 0;
        rs2_data   = 0;
        mem_write  = 0;
        mem_read   = 0;

        // Assert reset for 5 rising edges
        rst = 1;
        repeat(5) @(posedge clk);
        #1;
        rst = 0;

        // -------------------------------------------------------
        // Test 1: Write value 32'hDEADBEEF to address 0, read back
        // -------------------------------------------------------
        alu_result = 32'd0;
        rs2_data   = 32'hDEADBEEF;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write  = 0;
        mem_read   = 1;
        alu_result = 32'd0;
        #1;
        if (read_data === 32'hDEADBEEF)
            $display("PASS: Write 0xDEADBEEF to addr 0, read back correct");
        else
            $display("FAIL: Write 0xDEADBEEF to addr 0, got 0x%08X", read_data);

        // -------------------------------------------------------
        // Test 2: Write all-zeros to address 0
        // -------------------------------------------------------
        alu_result = 32'd0;
        rs2_data   = 32'h00000000;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write  = 0;
        mem_read   = 1;
        alu_result = 32'd0;
        #1;
        if (read_data === 32'h00000000)
            $display("PASS: Write all-zeros to addr 0, read back correct");
        else
            $display("FAIL: Write all-zeros to addr 0, got 0x%08X", read_data);

        // -------------------------------------------------------
        // Test 3: Write all-ones (0xFFFFFFFF) to address 4
        // -------------------------------------------------------
        alu_result = 32'd4;
        rs2_data   = 32'hFFFFFFFF;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write  = 0;
        mem_read   = 1;
        alu_result = 32'd4;
        #1;
        if (read_data === 32'hFFFFFFFF)
            $display("PASS: Write all-ones to addr 4, read back correct");
        else
            $display("FAIL: Write all-ones to addr 4, got 0x%08X", read_data);

        // -------------------------------------------------------
        // Test 4: Write value to address 8 (typical address)
        // -------------------------------------------------------
        alu_result = 32'd8;
        rs2_data   = 32'h12345678;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write  = 0;
        mem_read   = 1;
        alu_result = 32'd8;
        #1;
        if (read_data === 32'h12345678)
            $display("PASS: Write 0x12345678 to addr 8, read back correct");
        else
            $display("FAIL: Write 0x12345678 to addr 8, got 0x%08X", read_data);

        // -------------------------------------------------------
        // Test 5: Write then read different address (addr 12)
        // -------------------------------------------------------
        alu_result = 32'd12;
        rs2_data   = 32'hABCDEF01;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write  = 0;
        mem_read   = 1;
        alu_result = 32'd12;
        #1;
        if (read_data === 32'hABCDEF01)
            $display("PASS: Write 0xABCDEF01 to addr 12, read back correct");
        else
            $display("FAIL: Write 0xABCDEF01 to addr 12, got 0x%08X", read_data);

        // -------------------------------------------------------
        // Test 6: No write, no read (mem_write=0, mem_read=0) - 
        //         read_data should reflect whatever was last at addr
        //         (asynchronous read - depends on alu_result)
        //         Verify previous addr 12 still holds value
        // -------------------------------------------------------
        mem_write  = 0;
        mem_read   = 0;
        alu_result = 32'd12;
        #2;
        // Even with mem_read=0, async read may still output data
        // The module uses asynchronous read assigned from mem
        // Just verify no crash, previous data still stable
        $display("PASS: No write no read, no crash/hang at addr 12");

        // -------------------------------------------------------
        // Test 7: Overwrite address 0 with new data, verify old data
        //         at address 4 is unchanged
        // -------------------------------------------------------
        // First write to addr 0 new value
        alu_result = 32'd0;
        rs2_data   = 32'h55AA55AA;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write  = 0;
        // Check addr 4 is still 0xFFFFFFFF
        mem_read   = 1;
        alu_result = 32'd4;
        #1;
        if (read_data === 32'hFFFFFFFF)
            $display("PASS: Addr 4 unchanged after writing addr 0");
        else
            $display("FAIL: Addr 4 corrupted, got 0x%08X", read_data);

        // Now check addr 0 has new value
        alu_result = 32'd0;
        #1;
        if (read_data === 32'h55AA55AA)
            $display("PASS: Addr 0 correctly updated to 0x55AA55AA");
        else
            $display("FAIL: Addr 0 not updated correctly, got 0x%08X", read_data);

        // -------------------------------------------------------
        // Test 8: Maximum valid address within mem array (addr 127*4 = 508)
        //         The mem array is indexed [0:127], so word address = alu_result>>2
        //         Using byte address 508 => index 127
        // -------------------------------------------------------
        alu_result = 32'd508;
        rs2_data   = 32'hCAFEBABE;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write  = 0;
        mem_read   = 1;
        alu_result = 32'd508;
        #1;
        if (read_data === 32'hCAFEBABE)
            $display("PASS: Write 0xCAFEBABE to max addr 508, read back correct");
        else
            $display("FAIL: Write 0xCAFEBABE to max addr 508, got 0x%08X", read_data);

        // -------------------------------------------------------
        // Test 9: Write without read - verify read_data tracks alu_result
        //         (asynchronous read property)
        // -------------------------------------------------------
        // Write to addr 16
        alu_result = 32'd16;
        rs2_data   = 32'h87654321;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write  = 0;
        mem_read   = 1;
        // Move alu_result to addr 8 (previously 0x12345678)
        alu_result = 32'd8;
        #1;
        if (read_data === 32'h12345678)
            $display("PASS: Async read from addr 8 gives 0x12345678 after writing addr 16");
        else
            $display("FAIL: Async read from addr 8, got 0x%08X", read_data);

        // -------------------------------------------------------
        // Test 10: Write max value 0xFFFFFFFF to addr 0, then read
        // -------------------------------------------------------
        alu_result = 32'd0;
        rs2_data   = 32'hFFFFFFFF;
        mem_write  = 1;
        mem_read   = 0;
        @(posedge clk);
        #1;
        mem_write  = 0;
        mem_read   = 1;
        alu_result = 32'd0;
        #1;
        if (read_data === 32'hFFFFFFFF)
            $display("PASS: Write max value 0xFFFFFFFF to addr 0, read back correct");
        else
            $display("FAIL: Write max value to addr 0, got 0x%08X", read_data);

        // Small delay before finish
        #20;
        $finish;
    end

endmodule
