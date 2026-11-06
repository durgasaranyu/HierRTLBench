`timescale 1ns/1ps

module tb_regfile_top;

    // DUT connections
    reg         clk, rst;
    reg  [4:0]  rs1, rs2, rd;
    reg  [31:0] wdata;
    reg         we;
    wire [31:0] rdata1, rdata2;

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

    // Helper task: wait N rising edges
    task wait_clk;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1)
                @(posedge clk);
        end
    endtask

    integer fail_count;

    initial begin
        fail_count = 0;

        // -------------------------------------------------------
        // 1. RESET: Assert for exactly 5 rising edges
        // -------------------------------------------------------
        rst = 1;
        rs1 = 0; rs2 = 0; rd = 0; wdata = 0; we = 0;
        wait_clk(5);
        rst = 0;
        // Give one more cycle for outputs to settle
        @(posedge clk);

        // -------------------------------------------------------
        // Test 1: x0 always reads 0 (before any write)
        // -------------------------------------------------------
        rs1 = 5'd0; rs2 = 5'd0;
        we  = 0;
        @(negedge clk); // read is async, sample after negedge
        #1;
        if (rdata1 === 32'd0 && rdata2 === 32'd0) begin
            $display("PASS: x0 reads 0 after reset");
        end else begin
            $display("FAIL: x0 reads 0 after reset (rdata1=%0h, rdata2=%0h)", rdata1, rdata2);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 2: Write to x0, verify it still reads 0
        // -------------------------------------------------------
        rd = 5'd0; wdata = 32'hDEADBEEF; we = 1;
        @(posedge clk); #1; // sync write
        we  = 0;
        rs1 = 5'd0; rs2 = 5'd0;
        #1;
        if (rdata1 === 32'd0 && rdata2 === 32'd0) begin
            $display("PASS: x0 remains 0 after write attempt");
        end else begin
            $display("FAIL: x0 not 0 after write (rdata1=%0h, rdata2=%0h)", rdata1, rdata2);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 3: Write to x1, then read back via both ports
        // -------------------------------------------------------
        rd = 5'd1; wdata = 32'hA5A5A5A5; we = 1;
        @(posedge clk); #1;
        we  = 0;
        rs1 = 5'd1; rs2 = 5'd1;
        #1;
        if (rdata1 === 32'hA5A5A5A5 && rdata2 === 32'hA5A5A5A5) begin
            $display("PASS: Write/read x1 = 0xA5A5A5A5");
        end else begin
            $display("FAIL: Write/read x1 (rdata1=%0h, rdata2=%0h)", rdata1, rdata2);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 4: Dual read ports with different addresses
        // -------------------------------------------------------
        // Write x2 = 0x12345678
        rd = 5'd2; wdata = 32'h12345678; we = 1;
        @(posedge clk); #1;
        we  = 0;
        // Now read x1 on port1, x2 on port2 simultaneously
        rs1 = 5'd1; rs2 = 5'd2;
        #1;
        if (rdata1 === 32'hA5A5A5A5 && rdata2 === 32'h12345678) begin
            $display("PASS: Dual read x1 and x2 simultaneously");
        end else begin
            $display("FAIL: Dual read (rdata1=%0h, rdata2=%0h)", rdata1, rdata2);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 5: Write-after-read: same cycle as write, old value returned (async read)
        // -------------------------------------------------------
        // x3 is currently 0 after reset; set up read before write clock edge
        rs1 = 5'd3; rs2 = 5'd3;
        #1; // old value should still be 0 (async)
        // Latch old value before clock edge
        begin : check_war
            reg [31:0] old_val;
            old_val = rdata1; // should be 0 (pre-write)
            // Now issue write to x3 on next rising edge
            rd = 5'd3; wdata = 32'hCAFEBABE; we = 1;
            @(posedge clk); #1;
            we = 0;
            // After the clock edge, async read should show new value
            rs1 = 5'd3; rs2 = 5'd3;
            #1;
            if (old_val === 32'd0) begin
                $display("PASS: Write-after-read old value = 0 before clock");
            end else begin
                $display("FAIL: Write-after-read old value unexpected (%0h)", old_val);
                fail_count = fail_count + 1;
            end
            if (rdata1 === 32'hCAFEBABE) begin
                $display("PASS: x3 updated to 0xCAFEBABE after write");
            end else begin
                $display("FAIL: x3 not updated (rdata1=%0h)", rdata1);
                fail_count = fail_count + 1;
            end
        end

        // -------------------------------------------------------
        // Test 6: All-zero write data to non-zero register
        // -------------------------------------------------------
        // x3 currently 0xCAFEBABE, write 0 to it
        rd = 5'd3; wdata = 32'h00000000; we = 1;
        @(posedge clk); #1;
        we = 0;
        rs1 = 5'd3; rs2 = 5'd3;
        #1;
        if (rdata1 === 32'd0 && rdata2 === 32'd0) begin
            $display("PASS: Write all-zeros to x3");
        end else begin
            $display("FAIL: Write all-zeros to x3 (rdata1=%0h, rdata2=%0h)", rdata1, rdata2);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 7: All-ones write to x31 (maximum address, maximum value)
        // -------------------------------------------------------
        rd = 5'd31; wdata = 32'hFFFFFFFF; we = 1;
        @(posedge clk); #1;
        we = 0;
        rs1 = 5'd31; rs2 = 5'd31;
        #1;
        if (rdata1 === 32'hFFFFFFFF && rdata2 === 32'hFFFFFFFF) begin
            $display("PASS: Write all-ones to x31 (max addr/val)");
        end else begin
            $display("FAIL: Write all-ones to x31 (rdata1=%0h, rdata2=%0h)", rdata1, rdata2);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 8: Synchronous reset zeroes all registers
        //         (x1=0xA5A5A5A5, x2=0x12345678, x31=0xFFFFFFFF after above)
        // -------------------------------------------------------
        rst = 1;
        wait_clk(5);
        rst = 0;
        @(posedge clk); #1;
        // Check x1
        rs1 = 5'd1; rs2 = 5'd2; we = 0;
        #1;
        if (rdata1 === 32'd0 && rdata2 === 32'd0) begin
            $display("PASS: Reset zeroes x1 and x2");
        end else begin
            $display("FAIL: Reset x1/x2 (rdata1=%0h, rdata2=%0h)", rdata1, rdata2);
            fail_count = fail_count + 1;
        end
        rs1 = 5'd31; rs2 = 5'd0;
        #1;
        if (rdata1 === 32'd0 && rdata2 === 32'd0) begin
            $display("PASS: Reset zeroes x31 and x0");
        end else begin
            $display("FAIL: Reset x31/x0 (rdata1=%0h, rdata2=%0h)", rdata1, rdata2);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Test 9: Write to multiple registers and verify they are independent
        // -------------------------------------------------------
        rd = 5'd5; wdata = 32'h11111111; we = 1;
        @(posedge clk); #1;
        rd = 5'd10; wdata = 32'h22222222; we = 1;
        @(posedge clk); #1;
        we = 0;
        rs1 = 5'd5; rs2 = 5'd10;
        #1;
        if (rdata1 === 32'h11111111 && rdata2 === 32'h22222222) begin
            $display("PASS: Independent registers x5 and x10");
        end else begin
            $display("FAIL: Independent registers (rdata1=%0h, rdata2=%0h)", rdata1, rdata2);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Summary
        // -------------------------------------------------------
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
