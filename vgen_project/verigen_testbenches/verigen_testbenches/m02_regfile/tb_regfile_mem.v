`timescale 1ns/1ns

module tb_regfile_mem;

    // DUT connections
    reg         clk;
    reg         rst;
    reg  [4:0]  rs1, rs2, rd;
    reg  [31:0] wdata;
    reg         we;
    wire [31:0] rdata1, rdata2;

    // Instantiate DUT
    regfile_mem uut (
        .clk   (clk),
        .rst   (rst),
        .rs1   (rs1),
        .rs2   (rs2),
        .rd    (rd),
        .wdata (wdata),
        .we    (we),
        .rdata1(rdata1),
        .rdata2(rdata2)
    );

    // Clock generation: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    integer i;

    task apply_reset;
        integer k;
        begin
            rst = 1;
            for (k = 0; k < 5; k = k + 1)
                @(posedge clk);
            rst = 0;
            @(negedge clk); // settle after reset deasserted
        end
    endtask

    initial begin
        // Initialize inputs
        rst   = 0;
        rs1   = 0;
        rs2   = 0;
        rd    = 0;
        wdata = 0;
        we    = 0;

        // -------------------------------------------------------
        // TEST 1: Synchronous reset zeroes all registers
        // -------------------------------------------------------
        // First write some values into a few registers
        @(posedge clk); #1;
        rd = 5'd1; wdata = 32'hDEADBEEF; we = 1;
        @(posedge clk); #1;
        rd = 5'd15; wdata = 32'hCAFEBABE; we = 1;
        @(posedge clk); #1;
        we = 0;

        // Now apply reset for 5 rising edges
        apply_reset;

        // Check a few registers are zero after reset
        rs1 = 5'd1;  rs2 = 5'd15; we = 0;
        #1;
        if (rdata1 === 32'h0 && rdata2 === 32'h0)
            $display("PASS: Synchronous reset zeroes registers (reg1=0, reg15=0)");
        else
            $display("FAIL: Synchronous reset - expected 0,0 got %h,%h", rdata1, rdata2);

        // -------------------------------------------------------
        // TEST 2: x0 always reads 0 even after write attempt
        // -------------------------------------------------------
        @(posedge clk); #1;
        rd = 5'd0; wdata = 32'hFFFFFFFF; we = 1;
        @(posedge clk); #1;
        we = 0;
        rs1 = 5'd0; rs2 = 5'd0;
        #1;
        if (rdata1 === 32'h0 && rdata2 === 32'h0)
            $display("PASS: x0 always reads 0 after write attempt");
        else
            $display("FAIL: x0 not zero after write attempt - got rdata1=%h rdata2=%h", rdata1, rdata2);

        // -------------------------------------------------------
        // TEST 3: Normal write and read back (register 1)
        // -------------------------------------------------------
        @(posedge clk); #1;
        rd = 5'd1; wdata = 32'hA5A5A5A5; we = 1;
        @(posedge clk); #1;
        we = 0;
        rs1 = 5'd1;
        #1;
        if (rdata1 === 32'hA5A5A5A5)
            $display("PASS: Normal write/read reg1 = 0xA5A5A5A5");
        else
            $display("FAIL: Normal write/read reg1 expected A5A5A5A5 got %h", rdata1);

        // -------------------------------------------------------
        // TEST 4: Both read ports simultaneously with different addresses
        // -------------------------------------------------------
        // Write to reg2 and reg3 first
        @(posedge clk); #1;
        rd = 5'd2; wdata = 32'h12345678; we = 1;
        @(posedge clk); #1;
        rd = 5'd3; wdata = 32'h87654321; we = 1;
        @(posedge clk); #1;
        we = 0;
        rs1 = 5'd2; rs2 = 5'd3;
        #1;
        if (rdata1 === 32'h12345678 && rdata2 === 32'h87654321)
            $display("PASS: Dual read ports - reg2=%h reg3=%h", rdata1, rdata2);
        else
            $display("FAIL: Dual read ports - expected 12345678/87654321 got %h/%h", rdata1, rdata2);

        // -------------------------------------------------------
        // TEST 5: Write-after-read: old value returned same cycle as write
        // -------------------------------------------------------
        // reg1 currently holds 0xA5A5A5A5
        // Set up read of reg1 while simultaneously writing new value to reg1
        rs1 = 5'd1; rd = 5'd1; wdata = 32'hBBBBBBBB; we = 1;
        #1; // combinational read before clock edge
        if (rdata1 === 32'hA5A5A5A5)
            $display("PASS: Write-after-read: old value 0xA5A5A5A5 seen before clock edge");
        else
            $display("FAIL: Write-after-read: expected A5A5A5A5 got %h", rdata1);
        @(posedge clk); #1;
        we = 0;
        // Now reg1 should hold new value
        rs1 = 5'd1;
        #1;
        if (rdata1 === 32'hBBBBBBBB)
            $display("PASS: Write-after-read: new value 0xBBBBBBBB visible after clock edge");
        else
            $display("FAIL: Write-after-read: new value expected BBBBBBBB got %h", rdata1);

        // -------------------------------------------------------
        // TEST 6: All-zero input data write to non-x0 register
        // -------------------------------------------------------
        @(posedge clk); #1;
        rd = 5'd5; wdata = 32'h00000000; we = 1;
        @(posedge clk); #1;
        we = 0;
        rs1 = 5'd5;
        #1;
        if (rdata1 === 32'h00000000)
            $display("PASS: All-zero write to reg5 reads back 0");
        else
            $display("FAIL: All-zero write to reg5 got %h", rdata1);

        // -------------------------------------------------------
        // TEST 7: All-ones write to a register
        // -------------------------------------------------------
        @(posedge clk); #1;
        rd = 5'd7; wdata = 32'hFFFFFFFF; we = 1;
        @(posedge clk); #1;
        we = 0;
        rs1 = 5'd7;
        #1;
        if (rdata1 === 32'hFFFFFFFF)
            $display("PASS: All-ones write to reg7 reads back 0xFFFFFFFF");
        else
            $display("FAIL: All-ones write to reg7 got %h", rdata1);

        // -------------------------------------------------------
        // TEST 8: Write to register 31 (maximum address) and read back
        // -------------------------------------------------------
        @(posedge clk); #1;
        rd = 5'd31; wdata = 32'hDEADC0DE; we = 1;
        @(posedge clk); #1;
        we = 0;
        rs1 = 5'd31; rs2 = 5'd0;
        #1;
        if (rdata1 === 32'hDEADC0DE && rdata2 === 32'h0)
            $display("PASS: Write/read reg31 = 0xDEADC0DE, reg0 still 0");
        else
            $display("FAIL: reg31 expected DEADC0DE got %h, reg0 expected 0 got %h", rdata1, rdata2);

        // -------------------------------------------------------
        // TEST 9: x0 read on both ports simultaneously
        // -------------------------------------------------------
        rs1 = 5'd0; rs2 = 5'd0; we = 0;
        #1;
        if (rdata1 === 32'h0 && rdata2 === 32'h0)
            $display("PASS: x0 reads 0 on both ports simultaneously");
        else
            $display("FAIL: x0 dual-port read got rdata1=%h rdata2=%h", rdata1, rdata2);

        // -------------------------------------------------------
        // TEST 10: Second reset verifies all registers cleared
        // -------------------------------------------------------
        // Write to several registers
        @(posedge clk); #1;
        rd = 5'd10; wdata = 32'hABCD1234; we = 1;
        @(posedge clk); #1;
        rd = 5'd20; wdata = 32'h5678EFAB; we = 1;
        @(posedge clk); #1;
        rd = 5'd31; wdata = 32'hFFFFFFFF; we = 1;
        @(posedge clk); #1;
        we = 0;

        apply_reset;

        // Check several registers
        rs1 = 5'd10; rs2 = 5'd20; #1;
        if (rdata1 === 32'h0 && rdata2 === 32'h0)
            $display("PASS: Second reset - reg10=0, reg20=0");
        else
            $display("FAIL: Second reset - reg10=%h reg20=%h (expected 0)", rdata1, rdata2);

        rs1 = 5'd31; rs2 = 5'd1; #1;
        if (rdata1 === 32'h0 && rdata2 === 32'h0)
            $display("PASS: Second reset - reg31=0, reg1=0");
        else
            $display("FAIL: Second reset - reg31=%h reg1=%h (expected 0)", rdata1, rdata2);

        // -------------------------------------------------------
        // Done
        // -------------------------------------------------------
        #20;
        $finish;
    end

endmodule
