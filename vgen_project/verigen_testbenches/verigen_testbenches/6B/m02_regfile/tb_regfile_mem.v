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

    // Task: wait for rising edge then a small delay for output settling
    task tick;
        begin
            @(posedge clk);
            #1; // small delay to let combinational outputs settle
        end
    endtask

    integer i;

    initial begin
        // Initialize inputs
        rst   = 1;
        rs1   = 0;
        rs2   = 0;
        rd    = 0;
        wdata = 0;
        we    = 0;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // ----------------------------------------------------------------
        // Test 1: After reset, all registers should read 0
        // Check register 1 and register 31 via both read ports
        // ----------------------------------------------------------------
        rs1 = 5'd1;
        rs2 = 5'd31;
        we  = 0;
        #1;
        if (rdata1 === 32'h0 && rdata2 === 32'h0)
            $display("PASS: After reset reg[1]=0 and reg[31]=0");
        else
            $display("FAIL: After reset reg[1]=%h reg[31]=%h (expected 0)", rdata1, rdata2);

        // ----------------------------------------------------------------
        // Test 2: Write to x0 (register 0), verify it always reads 0
        // ----------------------------------------------------------------
        rd    = 5'd0;
        wdata = 32'hDEADBEEF;
        we    = 1;
        tick; // rising edge performs write
        we    = 0;
        rs1   = 5'd0;
        rs2   = 5'd0;
        #1;
        if (rdata1 === 32'h0 && rdata2 === 32'h0)
            $display("PASS: x0 always reads 0 after write attempt");
        else
            $display("FAIL: x0 reads %h/%h after write (expected 0)", rdata1, rdata2);

        // ----------------------------------------------------------------
        // Test 3: Write to register 1 and read it back
        // ----------------------------------------------------------------
        rd    = 5'd1;
        wdata = 32'hAABBCCDD;
        we    = 1;
        tick;
        we    = 0;
        rs1   = 5'd1;
        rs2   = 5'd0;
        #1;
        if (rdata1 === 32'hAABBCCDD)
            $display("PASS: Write/read reg[1]=0xAABBCCDD");
        else
            $display("FAIL: reg[1]=%h (expected 0xAABBCCDD)", rdata1);

        // ----------------------------------------------------------------
        // Test 4: Both read ports simultaneously with different addresses
        // Write to reg[2] first, then read reg[1] and reg[2] simultaneously
        // ----------------------------------------------------------------
        rd    = 5'd2;
        wdata = 32'h12345678;
        we    = 1;
        tick;
        we    = 0;
        rs1   = 5'd1;
        rs2   = 5'd2;
        #1;
        if (rdata1 === 32'hAABBCCDD && rdata2 === 32'h12345678)
            $display("PASS: Dual read port: reg[1]=0xAABBCCDD reg[2]=0x12345678");
        else
            $display("FAIL: Dual read port: rdata1=%h rdata2=%h", rdata1, rdata2);

        // ----------------------------------------------------------------
        // Test 5: Write-after-read - old value returned same cycle as write
        // rs1 points to reg[2] which holds 0x12345678; write new value
        // The read should show OLD value on this clock cycle before edge
        // ----------------------------------------------------------------
        rs1   = 5'd2;
        rs2   = 5'd2;
        rd    = 5'd2;
        wdata = 32'hFFFFFFFF;
        we    = 1;
        // Before the clock edge, rdata1 still shows old value
        #1; // combinational read before clock edge fires
        if (rdata1 === 32'h12345678)
            $display("PASS: Write-after-read: old value 0x12345678 seen before clock edge");
        else
            $display("FAIL: Write-after-read: rdata1=%h (expected old 0x12345678)", rdata1);
        tick; // now write happens
        we    = 0;
        rs1   = 5'd2;
        #1;
        if (rdata1 === 32'hFFFFFFFF)
            $display("PASS: Write-after-read: new value 0xFFFFFFFF seen after clock edge");
        else
            $display("FAIL: Write-after-read: rdata1=%h (expected 0xFFFFFFFF)", rdata1);

        // ----------------------------------------------------------------
        // Test 6: All-zero wdata write to a register
        // ----------------------------------------------------------------
        rd    = 5'd5;
        wdata = 32'h0;
        we    = 1;
        tick;
        we    = 0;
        rs1   = 5'd5;
        #1;
        if (rdata1 === 32'h0)
            $display("PASS: Write all-zero to reg[5], reads back 0");
        else
            $display("FAIL: reg[5]=%h (expected 0)", rdata1);

        // ----------------------------------------------------------------
        // Test 7: All-ones wdata write to register 31 (max address)
        // ----------------------------------------------------------------
        rd    = 5'd31;
        wdata = 32'hFFFFFFFF;
        we    = 1;
        tick;
        we    = 0;
        rs1   = 5'd31;
        rs2   = 5'd5;
        #1;
        if (rdata1 === 32'hFFFFFFFF && rdata2 === 32'h0)
            $display("PASS: reg[31]=0xFFFFFFFF (all-ones), reg[5]=0 (all-zero)");
        else
            $display("FAIL: reg[31]=%h (exp 0xFFFFFFFF), reg[5]=%h (exp 0)", rdata1, rdata2);

        // ----------------------------------------------------------------
        // Test 8: Synchronous reset zeroes all registers
        // Write to several registers, then assert reset and verify all are 0
        // ----------------------------------------------------------------
        // Write to reg[10] and reg[20]
        rd    = 5'd10;
        wdata = 32'hCAFEBABE;
        we    = 1;
        tick;
        rd    = 5'd20;
        wdata = 32'hBEEFDEAD;
        tick;
        we    = 0;

        // Assert synchronous reset for 5 cycles
        rst = 1;
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // Check multiple registers are zeroed
        rs1 = 5'd10;
        rs2 = 5'd20;
        #1;
        if (rdata1 === 32'h0 && rdata2 === 32'h0)
            $display("PASS: Synchronous reset zeroed reg[10] and reg[20]");
        else
            $display("FAIL: After reset reg[10]=%h reg[20]=%h (expected 0)", rdata1, rdata2);

        // Also check reg[31] and reg[1] are zeroed
        rs1 = 5'd31;
        rs2 = 5'd1;
        #1;
        if (rdata1 === 32'h0 && rdata2 === 32'h0)
            $display("PASS: Synchronous reset zeroed reg[31] and reg[1]");
        else
            $display("FAIL: After reset reg[31]=%h reg[1]=%h (expected 0)", rdata1, rdata2);

        // ----------------------------------------------------------------
        // Test 9: Write enable inactive - no write should occur
        // ----------------------------------------------------------------
        rs1   = 5'd3;
        rs2   = 5'd3;
        rd    = 5'd3;
        wdata = 32'h55AA55AA;
        we    = 0; // write enable OFF
        tick;
        #1;
        if (rdata1 === 32'h0)
            $display("PASS: WE=0: reg[3] remains 0, no write occurred");
        else
            $display("FAIL: WE=0: reg[3]=%h (expected 0, no write)", rdata1);

        // ----------------------------------------------------------------
        // Test 10: Maximum value input address (rs1=rs2=rd=31) and max wdata
        // ----------------------------------------------------------------
        rd    = 5'd31;
        wdata = 32'hFFFFFFFF;
        we    = 1;
        tick;
        we    = 0;
        rs1   = 5'd31;
        rs2   = 5'd31;
        #1;
        if (rdata1 === 32'hFFFFFFFF && rdata2 === 32'hFFFFFFFF)
            $display("PASS: Max address reg[31]=0xFFFFFFFF on both ports");
        else
            $display("FAIL: reg[31] rdata1=%h rdata2=%h (expected 0xFFFFFFFF)", rdata1, rdata2);

        // ----------------------------------------------------------------
        // Test 11: x0 still reads 0 after reset and writes
        // ----------------------------------------------------------------
        rd    = 5'd0;
        wdata = 32'hA5A5A5A5;
        we    = 1;
        tick;
        we    = 0;
        rs1   = 5'd0;
        rs2   = 5'd31;
        #1;
        if (rdata1 === 32'h0)
            $display("PASS: x0 still reads 0 after write attempt (final check)");
        else
            $display("FAIL: x0=%h (expected 0)", rdata1);

        #20;
        $finish;
    end

endmodule
