`timescale 1ns/1ps

module tb_m02_regfile_integration;

    // DUT signals
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

    integer i;
    integer fail_count;

    // Task: write a value to a register
    task write_reg;
        input [4:0]  addr;
        input [31:0] data;
        begin
            @(negedge clk);
            rd    = addr;
            wdata = data;
            we    = 1;
            @(posedge clk); #1;
            we    = 0;
        end
    endtask

    // Task: read two registers simultaneously and check
    task read_check;
        input [4:0]  a1, a2;
        input [31:0] exp1, exp2;
        input [63:0] test_id; // just a number for display
        begin
            @(negedge clk);
            rs1 = a1;
            rs2 = a2;
            #1; // combinational read settles
            if (rdata1 === exp1 && rdata2 === exp2)
                $display("PASS: Read check test %0d (rs1=%0d exp=%h got=%h, rs2=%0d exp=%h got=%h)",
                         test_id, a1, exp1, rdata1, a2, exp2, rdata2);
            else begin
                $display("FAIL: Read check test %0d (rs1=%0d exp=%h got=%h, rs2=%0d exp=%h got=%h)",
                         test_id, a1, exp1, rdata1, a2, exp2, rdata2);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        fail_count = 0;

        // Initialise inputs
        rst   = 1;
        we    = 0;
        rd    = 0;
        rs1   = 0;
        rs2   = 0;
        wdata = 0;

        // Assert reset for 5 rising edges
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // ---------------------------------------------------------------
        // Test 1: x0 is always zero (read without writing)
        // ---------------------------------------------------------------
        @(negedge clk);
        rs1 = 5'd0;
        rs2 = 5'd0;
        #1;
        if (rdata1 === 32'h0 && rdata2 === 32'h0)
            $display("PASS: x0 reads zero after reset (rdata1=%h rdata2=%h)", rdata1, rdata2);
        else begin
            $display("FAIL: x0 reads zero after reset (rdata1=%h rdata2=%h)", rdata1, rdata2);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 2: Attempt to write x0, confirm it stays zero
        // ---------------------------------------------------------------
        write_reg(5'd0, 32'hDEADBEEF);
        @(negedge clk);
        rs1 = 5'd0;
        rs2 = 5'd0;
        #1;
        // NOTE: The module does NOT hardware-block x0 writes in the RTL;
        // the specification says x0 is hardwired 0, but the assign
        // reads regs[rs1].  We test the observable behaviour:
        // if the design stores to regs[0] we detect it here.
        if (rdata1 === 32'h0 && rdata2 === 32'h0)
            $display("PASS: x0 remains zero after attempted write");
        else begin
            // This is an RTL deficiency; flag but continue.
            $display("FAIL: x0 not hardwired zero after write attempt (rdata1=%h rdata2=%h)",
                     rdata1, rdata2);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 3: Write a single register and read it back on both ports
        // ---------------------------------------------------------------
        write_reg(5'd1, 32'hA5A5A5A5);
        read_check(5'd1, 5'd1, 32'hA5A5A5A5, 32'hA5A5A5A5, 3);

        // ---------------------------------------------------------------
        // Test 4: Write two registers; read simultaneously on rs1 and rs2
        // ---------------------------------------------------------------
        write_reg(5'd2, 32'h12345678);
        write_reg(5'd3, 32'h9ABCDEF0);
        read_check(5'd2, 5'd3, 32'h12345678, 32'h9ABCDEF0, 4);

        // ---------------------------------------------------------------
        // Test 5: rs1 and rs2 read different registers simultaneously
        // ---------------------------------------------------------------
        write_reg(5'd10, 32'hCAFEBABE);
        write_reg(5'd20, 32'hFEEDFACE);
        read_check(5'd10, 5'd20, 32'hCAFEBABE, 32'hFEEDFACE, 5);

        // ---------------------------------------------------------------
        // Test 6: rs2 = rs1 — same register on both ports
        // ---------------------------------------------------------------
        read_check(5'd10, 5'd10, 32'hCAFEBABE, 32'hCAFEBABE, 6);

        // ---------------------------------------------------------------
        // Test 7: Overwrite a register and read updated value
        // ---------------------------------------------------------------
        write_reg(5'd1, 32'h11111111);
        read_check(5'd1, 5'd2, 32'h11111111, 32'h12345678, 7);

        // ---------------------------------------------------------------
        // Test 8: Write all registers 1-31 and verify with dual read
        // ---------------------------------------------------------------
        for (i = 1; i <= 31; i = i + 1) begin
            write_reg(i[4:0], i * 32'h01010101);
        end
        // Spot-check several pairs
        read_check(5'd5,  5'd6,  5  * 32'h01010101, 6  * 32'h01010101, 8);
        read_check(5'd15, 5'd16, 15 * 32'h01010101, 16 * 32'h01010101, 9);
        read_check(5'd31, 5'd1,  31 * 32'h01010101, 1  * 32'h01010101, 10);

        // ---------------------------------------------------------------
        // Test 9: x0 still zero after all the writes above
        // ---------------------------------------------------------------
        @(negedge clk);
        rs1 = 5'd0;
        rs2 = 5'd5;
        #1;
        if (rdata1 === 32'h0)
            $display("PASS: x0 still zero after bulk writes");
        else begin
            $display("FAIL: x0 corrupted after bulk writes (rdata1=%h)", rdata1);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 10: we=0 — write disabled, value must not change
        // ---------------------------------------------------------------
        write_reg(5'd7, 32'hAAAAAAAA);
        // Now try a disabled write
        @(negedge clk);
        rd    = 5'd7;
        wdata = 32'h55555555;
        we    = 0;
        @(posedge clk); #1;
        rs1 = 5'd7;
        rs2 = 5'd7;
        #1;
        if (rdata1 === 32'hAAAAAAAA && rdata2 === 32'hAAAAAAAA)
            $display("PASS: Write disabled — register value unchanged");
        else begin
            $display("FAIL: Write disabled — register changed unexpectedly (rdata1=%h rdata2=%h)",
                     rdata1, rdata2);
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
