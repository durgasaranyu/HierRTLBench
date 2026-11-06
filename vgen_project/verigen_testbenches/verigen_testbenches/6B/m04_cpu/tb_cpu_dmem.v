`timescale 1ns / 1ps

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

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset signal (not used by DUT but required by spec)
    reg rst;

    integer i;
    reg [31:0] expected;

    initial begin
        // Initialize
        rst    = 1;
        mem_we = 0;
        addr   = 32'h0;
        wdata  = 32'h0;

        // Assert reset for exactly 5 clock rising edges
        @(posedge clk); // 1
        @(posedge clk); // 2
        @(posedge clk); // 3
        @(posedge clk); // 4
        @(posedge clk); // 5
        rst = 0;

        // Give one more cycle settle time
        @(negedge clk);

        // ----------------------------------------------------------------
        // Test 1: Write to address 0x00 and read back (normal operation)
        // ----------------------------------------------------------------
        addr   = 32'h00000000;
        wdata  = 32'hDEADBEEF;
        mem_we = 1;
        @(posedge clk);
        #1; // small delay after posedge
        mem_we = 0;
        // rdata is asynchronous, check after combinatorial settle
        #1;
        expected = 32'hDEADBEEF;
        if (rdata === expected)
            $display("PASS: Write 0xDEADBEEF to addr 0x00 and read back");
        else
            $display("FAIL: Write 0xDEADBEEF to addr 0x00: expected %h got %h", expected, rdata);

        // ----------------------------------------------------------------
        // Test 2: Write to address 0x04 (word 1) and read back
        // ----------------------------------------------------------------
        addr   = 32'h00000004;
        wdata  = 32'hCAFEBABE;
        mem_we = 1;
        @(posedge clk);
        #1;
        mem_we = 0;
        #1;
        expected = 32'hCAFEBABE;
        if (rdata === expected)
            $display("PASS: Write 0xCAFEBABE to addr 0x04 and read back");
        else
            $display("FAIL: Write 0xCAFEBABE to addr 0x04: expected %h got %h", expected, rdata);

        // ----------------------------------------------------------------
        // Test 3: All-zero data written to address 0x08
        // ----------------------------------------------------------------
        addr   = 32'h00000008;
        wdata  = 32'h00000000;
        mem_we = 1;
        @(posedge clk);
        #1;
        mem_we = 0;
        #1;
        expected = 32'h00000000;
        if (rdata === expected)
            $display("PASS: Write all-zeros to addr 0x08 and read back");
        else
            $display("FAIL: Write all-zeros to addr 0x08: expected %h got %h", expected, rdata);

        // ----------------------------------------------------------------
        // Test 4: All-ones data written to address 0x0C
        // ----------------------------------------------------------------
        addr   = 32'h0000000C;
        wdata  = 32'hFFFFFFFF;
        mem_we = 1;
        @(posedge clk);
        #1;
        mem_we = 0;
        #1;
        expected = 32'hFFFFFFFF;
        if (rdata === expected)
            $display("PASS: Write all-ones to addr 0x0C and read back");
        else
            $display("FAIL: Write all-ones to addr 0x0C: expected %h got %h", expected, rdata);

        // ----------------------------------------------------------------
        // Test 5: Simulate SW (store word) - write known value, verify address
        //         Write 0x12345678 to address 0x10 (word index 4)
        // ----------------------------------------------------------------
        addr   = 32'h00000010;
        wdata  = 32'h12345678;
        mem_we = 1;
        @(posedge clk);
        #1;
        mem_we = 0;
        #1;
        expected = 32'h12345678;
        if (rdata === expected)
            $display("PASS: SW simulation - 0x12345678 stored at addr 0x10");
        else
            $display("FAIL: SW simulation at addr 0x10: expected %h got %h", expected, rdata);

        // ----------------------------------------------------------------
        // Test 6: Simulate LW (load word) - read previously written address
        //         Read from addr 0x04 written in Test 2
        // ----------------------------------------------------------------
        mem_we = 0;
        addr   = 32'h00000004;
        #2;
        expected = 32'hCAFEBABE;
        if (rdata === expected)
            $display("PASS: LW simulation - read 0xCAFEBABE from addr 0x04");
        else
            $display("FAIL: LW simulation from addr 0x04: expected %h got %h", expected, rdata);

        // ----------------------------------------------------------------
        // Test 7: Maximum address - write to last valid word (index 255, addr 0x3FC)
        // ----------------------------------------------------------------
        addr   = 32'h000003FC; // 255 << 2 = 0x3FC
        wdata  = 32'hA5A5A5A5;
        mem_we = 1;
        @(posedge clk);
        #1;
        mem_we = 0;
        #1;
        expected = 32'hA5A5A5A5;
        if (rdata === expected)
            $display("PASS: Write 0xA5A5A5A5 to max addr 0x3FC and read back");
        else
            $display("FAIL: Write to max addr 0x3FC: expected %h got %h", expected, rdata);

        // ----------------------------------------------------------------
        // Test 8: No-write when mem_we=0 - existing data should remain
        //         Address 0x00 should still hold 0xDEADBEEF from Test 1
        // ----------------------------------------------------------------
        addr   = 32'h00000000;
        wdata  = 32'h11223344; // Different value, but mem_we=0
        mem_we = 0;
        @(posedge clk);
        #1;
        expected = 32'hDEADBEEF;
        if (rdata === expected)
            $display("PASS: No write when mem_we=0; addr 0x00 retains 0xDEADBEEF");
        else
            $display("FAIL: No write when mem_we=0; addr 0x00: expected %h got %h", expected, rdata);

        // ----------------------------------------------------------------
        // Test 9 (ADD simulation): Write two operands, compute sum externally,
        //         store result, verify. Simulates ADD rd = rs1 + rs2.
        //         rs1 = 0x00000005, rs2 = 0x00000003, rd = 0x00000008
        // ----------------------------------------------------------------
        // Store rs1 at addr 0x14
        addr   = 32'h00000014;
        wdata  = 32'h00000005;
        mem_we = 1;
        @(posedge clk);
        #1;
        mem_we = 0;

        // Store rs2 at addr 0x18
        addr   = 32'h00000018;
        wdata  = 32'h00000003;
        mem_we = 1;
        @(posedge clk);
        #1;
        mem_we = 0;

        // Read rs1
        addr = 32'h00000014;
        #2;
        // Store rd (sum) at addr 0x1C
        addr   = 32'h0000001C;
        wdata  = 32'h00000005 + 32'h00000003; // = 8
        mem_we = 1;
        @(posedge clk);
        #1;
        mem_we = 0;
        #1;
        expected = 32'h00000008;
        if (rdata === expected)
            $display("PASS: ADD simulation - result 0x00000008 stored and read at addr 0x1C");
        else
            $display("FAIL: ADD simulation at addr 0x1C: expected %h got %h", expected, rdata);

        // ----------------------------------------------------------------
        // Test 10 (BEQ simulation): Write same value to two addresses,
        //         verify equal (branch taken logic verified externally).
        //         rs1 = rs2 = 0xAABBCCDD => branch should be taken.
        // ----------------------------------------------------------------
        addr   = 32'h00000020;
        wdata  = 32'hAABBCCDD;
        mem_we = 1;
        @(posedge clk);
        #1;
        mem_we = 0;

        addr   = 32'h00000024;
        wdata  = 32'hAABBCCDD;
        mem_we = 1;
        @(posedge clk);
        #1;
        mem_we = 0;

        // Read both and compare
        addr = 32'h00000020;
        #2;
        begin : beq_block
            reg [31:0] rs1_val, rs2_val;
            rs1_val = rdata; // 0xAABBCCDD
            addr = 32'h00000024;
            #2;
            rs2_val = rdata; // 0xAABBCCDD
            if (rs1_val === rs2_val)
                $display("PASS: BEQ simulation - rs1==rs2 (0x%h), branch taken", rs1_val);
            else
                $display("FAIL: BEQ simulation - rs1=%h != rs2=%h, branch not taken", rs1_val, rs2_val);
        end

        // ----------------------------------------------------------------
        // Done
        // ----------------------------------------------------------------
        #20;
        $display("All tests completed.");
        $finish;
    end

endmodule
