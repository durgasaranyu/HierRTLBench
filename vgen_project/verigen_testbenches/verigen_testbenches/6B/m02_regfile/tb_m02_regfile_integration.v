`timescale 1ns/1ps

module tb_m02_regfile_integration;

    // DUT connections
    reg         clk;
    reg         rst;
    reg  [4:0]  rs1;
    reg  [4:0]  rs2;
    reg  [4:0]  rd;
    reg  [31:0] wdata;
    reg         we;
    wire [31:0] rdata1;
    wire [31:0] rdata2;

    // Instantiate DUT
    regfile uut (
        .clk    (clk),
        .rst    (rst),
        .rs1    (rs1),
        .rs2    (rs2),
        .rd     (rd),
        .wdata  (wdata),
        .we     (we),
        .rdata1 (rdata1),
        .rdata2 (rdata2)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    integer fail_count;

    task check;
        input [31:0] got1;
        input [31:0] got2;
        input [31:0] exp1;
        input [31:0] exp2;
        input [127:0] desc; // wide enough for string
        begin
            if (got1 === exp1 && got2 === exp2) begin
                $display("PASS: %s", desc);
            end else begin
                $display("FAIL: %s (rdata1=0x%08h expected=0x%08h, rdata2=0x%08h expected=0x%08h)",
                         desc, got1, exp1, got2, exp2);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Helper: perform write then read
    // Write: assert we, set rd/wdata for one clock
    // Read:  deassert we, set rs1/rs2, wait one clock, sample outputs
    // NOTE: The DUT has async read-like logic but actually registers rdata.
    //       Per the RTL: on posedge, if we==1: write (rdata1 not updated)
    //                                if we==0: rdata1 <= regfile[rs1]; rdata2 <= regfile[rs2]
    //       So we need:
    //         1. posedge with we=1 to write
    //         2. posedge with we=0 and rs1/rs2 set to read, then outputs valid after that edge

    integer i;

    initial begin
        fail_count = 0;

        // Initialize inputs
        rst   = 1;
        we    = 0;
        rs1   = 5'd0;
        rs2   = 5'd0;
        rd    = 5'd0;
        wdata = 32'd0;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        #1; // small delay after last posedge
        rst = 0;

        // -------------------------------------------------------
        // Test 1: x0 is always zero after reset
        // -------------------------------------------------------
        // Read x0 on both ports
        @(negedge clk);
        we  = 0;
        rs1 = 5'd0;
        rs2 = 5'd0;
        @(posedge clk);
        #1;
        check(rdata1, rdata2, 32'd0, 32'd0, "x0 reads zero on both ports after reset");

        // -------------------------------------------------------
        // Test 2: Write to register x1, then read back on both ports
        // -------------------------------------------------------
        @(negedge clk);
        we    = 1;
        rd    = 5'd1;
        wdata = 32'hAABBCCDD;
        @(posedge clk); // write happens here
        #1;

        // Now read back
        @(negedge clk);
        we  = 0;
        rs1 = 5'd1;
        rs2 = 5'd1;
        @(posedge clk); // read happens here
        #1;
        check(rdata1, rdata2, 32'hAABBCCDD, 32'hAABBCCDD,
              "Write x1=0xAABBCCDD, read back on rs1 and rs2");

        // -------------------------------------------------------
        // Test 3: Write to x2 and x3, then simultaneous dual read
        // -------------------------------------------------------
        @(negedge clk);
        we    = 1;
        rd    = 5'd2;
        wdata = 32'h12345678;
        @(posedge clk);
        #1;

        @(negedge clk);
        we    = 1;
        rd    = 5'd3;
        wdata = 32'h9ABCDEF0;
        @(posedge clk);
        #1;

        // Simultaneous read of x2 and x3
        @(negedge clk);
        we  = 0;
        rs1 = 5'd2;
        rs2 = 5'd3;
        @(posedge clk);
        #1;
        check(rdata1, rdata2, 32'h12345678, 32'h9ABCDEF0,
              "Dual simultaneous read x2 and x3");

        // -------------------------------------------------------
        // Test 4: Write to x0 should have NO effect (x0 hardwired 0)
        // -------------------------------------------------------
        @(negedge clk);
        we    = 1;
        rd    = 5'd0;
        wdata = 32'hFFFFFFFF;
        @(posedge clk);
        #1;

        // Read back x0
        @(negedge clk);
        we  = 0;
        rs1 = 5'd0;
        rs2 = 5'd0;
        @(posedge clk);
        #1;
        // x0 should still be 0 (hardwired per spec)
        // Note: the RTL does not explicitly guard x0 writes, so we test per spec intent
        // The spec says "x0 hardwired 0" - if RTL doesn't enforce, this is a design issue.
        // We check what the spec says.
        if (rdata1 === 32'd0 && rdata2 === 32'd0) begin
            $display("PASS: x0 remains zero after attempted write");
        end else begin
            $display("FAIL: x0 not zero after attempted write (rdata1=0x%08h, rdata2=0x%08h)",
                     rdata1, rdata2);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 5: Write multiple registers, read different combinations
        // -------------------------------------------------------
        @(negedge clk);
        we    = 1;
        rd    = 5'd10;
        wdata = 32'hDEADBEEF;
        @(posedge clk);
        #1;

        @(negedge clk);
        we    = 1;
        rd    = 5'd20;
        wdata = 32'hCAFEBABE;
        @(posedge clk);
        #1;

        @(negedge clk);
        we    = 1;
        rd    = 5'd31;
        wdata = 32'h0000FFFF;
        @(posedge clk);
        #1;

        // Read x10 and x20
        @(negedge clk);
        we  = 0;
        rs1 = 5'd10;
        rs2 = 5'd20;
        @(posedge clk);
        #1;
        check(rdata1, rdata2, 32'hDEADBEEF, 32'hCAFEBABE,
              "Dual read x10=0xDEADBEEF and x20=0xCAFEBABE");

        // Read x31 and x0
        @(negedge clk);
        we  = 0;
        rs1 = 5'd31;
        rs2 = 5'd0;
        @(posedge clk);
        #1;
        check(rdata1, rdata2, 32'h0000FFFF, 32'd0,
              "Dual read x31=0x0000FFFF and x0=0");

        // -------------------------------------------------------
        // Test 6: Reset clears all registers
        // -------------------------------------------------------
        @(negedge clk);
        rst = 1;
        we  = 0;
        @(posedge clk);
        #1;
        rst = 0;

        // Read x1 (was 0xAABBCCDD) - should be 0 now
        @(negedge clk);
        we  = 0;
        rs1 = 5'd1;
        rs2 = 5'd10;
        @(posedge clk);
        #1;
        check(rdata1, rdata2, 32'd0, 32'd0,
              "After reset x1 and x10 are both zero");

        // -------------------------------------------------------
        // Test 7: Write and immediately verify with rs2 same cycle
        //         (write x5, then read x5 on rs1 and x1 on rs2)
        // -------------------------------------------------------
        @(negedge clk);
        we    = 1;
        rd    = 5'd5;
        wdata = 32'h55AA55AA;
        @(posedge clk);
        #1;

        @(negedge clk);
        we    = 1;
        rd    = 5'd1;
        wdata = 32'h11223344;
        @(posedge clk);
        #1;

        @(negedge clk);
        we  = 0;
        rs1 = 5'd5;
        rs2 = 5'd1;
        @(posedge clk);
        #1;
        check(rdata1, rdata2, 32'h55AA55AA, 32'h11223344,
              "Dual read x5=0x55AA55AA and x1=0x11223344");

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        if (fail_count == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("%0d TEST(S) FAILED", fail_count);
        end

        $finish;
    end

endmodule
