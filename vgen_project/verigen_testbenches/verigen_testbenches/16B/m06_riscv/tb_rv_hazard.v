`timescale 1ns/1ps

module tb_rv_hazard;

    // DUT inputs
    reg        id_ex_mem_read;
    reg [4:0]  id_ex_rd;
    reg [4:0]  if_id_rs1;
    reg [4:0]  if_id_rs2;

    // DUT outputs
    wire stall;
    wire flush;

    // Clock (not used by combinational DUT, but required by general rules)
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not used by combinational DUT, but required by general rules)
    reg rst;
    integer rst_count;
    initial begin
        rst = 1;
        rst_count = 0;
    end

    // Assert reset for exactly 5 rising edges
    always @(posedge clk) begin
        if (rst_count < 5) begin
            rst_count = rst_count + 1;
        end else begin
            rst = 0;
        end
    end

    // Instantiate DUT
    rv_hazard uut (
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_rd      (id_ex_rd),
        .if_id_rs1     (if_id_rs1),
        .if_id_rs2     (if_id_rs2),
        .stall         (stall),
        .flush         (flush)
    );

    // Task for checking
    task check;
        input        exp_stall;
        input        exp_flush;
        input [63:0] test_num;
        input [127:0] description;
        begin
            #1; // small delay for combinational settling
            if (stall === exp_stall && flush === exp_flush) begin
                $display("PASS: Test %0d - %s | stall=%b flush=%b", test_num, description, stall, flush);
            end else begin
                $display("FAIL: Test %0d - %s | expected stall=%b flush=%b, got stall=%b flush=%b",
                         test_num, description, exp_stall, exp_flush, stall, flush);
            end
        end
    endtask

    integer i;

    initial begin
        // Initialize inputs
        id_ex_mem_read = 0;
        id_ex_rd       = 5'd0;
        if_id_rs1      = 5'd0;
        if_id_rs2      = 5'd0;

        // Wait for reset to deassert (5 rising edges)
        @(posedge clk); // 1
        @(posedge clk); // 2
        @(posedge clk); // 3
        @(posedge clk); // 4
        @(posedge clk); // 5
        // After 5th rising edge, rst goes to 0 on next posedge
        @(posedge clk); // rst deasserts now

        // Small settling time
        #2;

        // -----------------------------------------------------------------
        // Test 1: No hazard - id_ex_mem_read=0, no match -> no stall/flush
        // -----------------------------------------------------------------
        id_ex_mem_read = 1'b0;
        id_ex_rd       = 5'd3;
        if_id_rs1      = 5'd3;
        if_id_rs2      = 5'd4;
        check(1'b0, 1'b0, 1, "No hazard: mem_read=0, rd matches rs1");

        // -----------------------------------------------------------------
        // Test 2: Load-use hazard - id_ex_rd matches if_id_rs1
        // -----------------------------------------------------------------
        id_ex_mem_read = 1'b1;
        id_ex_rd       = 5'd5;
        if_id_rs1      = 5'd5;
        if_id_rs2      = 5'd7;
        check(1'b1, 1'b1, 2, "Load-use hazard: rd matches rs1");

        // -----------------------------------------------------------------
        // Test 3: Load-use hazard - id_ex_rd matches if_id_rs2
        // -----------------------------------------------------------------
        id_ex_mem_read = 1'b1;
        id_ex_rd       = 5'd8;
        if_id_rs1      = 5'd2;
        if_id_rs2      = 5'd8;
        check(1'b1, 1'b1, 3, "Load-use hazard: rd matches rs2");

        // -----------------------------------------------------------------
        // Test 4: Load-use hazard - id_ex_rd matches both rs1 and rs2
        // -----------------------------------------------------------------
        id_ex_mem_read = 1'b1;
        id_ex_rd       = 5'd10;
        if_id_rs1      = 5'd10;
        if_id_rs2      = 5'd10;
        check(1'b1, 1'b1, 4, "Load-use hazard: rd matches both rs1 and rs2");

        // -----------------------------------------------------------------
        // Test 5: All zeros - id_ex_mem_read=0, all regs zero -> no hazard
        //         (rd=0 but mem_read=0 so no stall)
        // -----------------------------------------------------------------
        id_ex_mem_read = 1'b0;
        id_ex_rd       = 5'd0;
        if_id_rs1      = 5'd0;
        if_id_rs2      = 5'd0;
        check(1'b0, 1'b0, 5, "All zeros, mem_read=0: no hazard");

        // -----------------------------------------------------------------
        // Test 6: All zeros - id_ex_mem_read=1, all regs zero -> hazard
        //         rd=0 matches rs1=0 and rs2=0 (register x0 case)
        // -----------------------------------------------------------------
        id_ex_mem_read = 1'b1;
        id_ex_rd       = 5'd0;
        if_id_rs1      = 5'd0;
        if_id_rs2      = 5'd0;
        check(1'b1, 1'b1, 6, "All zeros, mem_read=1: hazard on x0");

        // -----------------------------------------------------------------
        // Test 7: All-ones (maximum register index 31) - no match, no hazard
        // -----------------------------------------------------------------
        id_ex_mem_read = 1'b1;
        id_ex_rd       = 5'd31;
        if_id_rs1      = 5'd15;
        if_id_rs2      = 5'd16;
        check(1'b0, 1'b0, 7, "Max reg index rd=31, no match: no hazard");

        // -----------------------------------------------------------------
        // Test 8: All-ones - id_ex_rd=31 matches rs1=31 with mem_read=1
        // -----------------------------------------------------------------
        id_ex_mem_read = 1'b1;
        id_ex_rd       = 5'd31;
        if_id_rs1      = 5'd31;
        if_id_rs2      = 5'd0;
        check(1'b1, 1'b1, 8, "Max reg: rd=31 matches rs1=31, hazard");

        // -----------------------------------------------------------------
        // Test 9: id_ex_mem_read=1 but rd=0 with rs1 and rs2 non-zero
        //         rd=0 does not match rs1 or rs2 -> no hazard
        // -----------------------------------------------------------------
        id_ex_mem_read = 1'b1;
        id_ex_rd       = 5'd0;
        if_id_rs1      = 5'd5;
        if_id_rs2      = 5'd6;
        check(1'b0, 1'b0, 9, "mem_read=1 but rd=0, no match with rs1/rs2");

        // -----------------------------------------------------------------
        // Test 10: Toggle id_ex_mem_read with matching registers
        //          Verify stall toggles accordingly
        // -----------------------------------------------------------------
        id_ex_mem_read = 1'b0;
        id_ex_rd       = 5'd12;
        if_id_rs1      = 5'd12;
        if_id_rs2      = 5'd3;
        check(1'b0, 1'b0, 10, "Toggle: mem_read=0, rd matches rs1: no stall");

        id_ex_mem_read = 1'b1;
        check(1'b1, 1'b1, 11, "Toggle: mem_read=1, rd matches rs1: stall");

        id_ex_mem_read = 1'b0;
        check(1'b0, 1'b0, 12, "Toggle: mem_read=0 again: no stall");

        // -----------------------------------------------------------------
        // Test 13: rs2 match only
        // -----------------------------------------------------------------
        id_ex_mem_read = 1'b1;
        id_ex_rd       = 5'd20;
        if_id_rs1      = 5'd1;
        if_id_rs2      = 5'd20;
        check(1'b1, 1'b1, 13, "Load-use: only rs2 matches rd");

        // -----------------------------------------------------------------
        // Test 14: No match even with mem_read=1
        // -----------------------------------------------------------------
        id_ex_mem_read = 1'b1;
        id_ex_rd       = 5'd25;
        if_id_rs1      = 5'd24;
        if_id_rs2      = 5'd26;
        check(1'b0, 1'b0, 14, "mem_read=1, no register match: no hazard");

        // Allow a few extra cycles before finish
        @(posedge clk);
        @(posedge clk);

        $display("All tests completed.");
        $finish;
    end

endmodule
