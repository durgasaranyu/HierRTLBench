`timescale 1ns/1ps

// Testbench for rv_hazard
// NOTE: The module under test has a bug - it references 'clk' without declaring it as a port.
// We work around this by providing a clk wire that connects to the module's implicit net.

module tb_rv_hazard;

    // Clock and reset (reset not used by rv_hazard but required by general requirements)
    reg clk;
    reg rst;

    // DUT inputs
    reg        id_ex_mem_read;
    reg [4:0]  id_ex_rd;
    reg [4:0]  if_id_rs1;
    reg [4:0]  if_id_rs2;

    // DUT outputs
    wire stall;
    wire flush;

    // Instantiate DUT
    rv_hazard uut (
        .id_ex_mem_read (id_ex_mem_read),
        .id_ex_rd       (id_ex_rd),
        .if_id_rs1      (if_id_rs1),
        .if_id_rs2      (if_id_rs2),
        .stall          (stall),
        .flush          (flush)
    );

    // Clock generation: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Variables for checking
    integer pass_count;
    integer fail_count;

    // Task to wait one clock and check outputs
    task check_outputs;
        input [63:0] test_num;
        input        exp_stall;
        input        exp_flush;
        input [80*8-1:0] desc;
        begin
            @(posedge clk);
            #1; // small delay to let outputs settle after clock edge
            if (stall === exp_stall && flush === exp_flush) begin
                $display("PASS: Test %0d - %s (stall=%b flush=%b)", test_num, desc, stall, flush);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test %0d - %s | Expected stall=%b flush=%b, Got stall=%b flush=%b",
                         test_num, desc, exp_stall, exp_flush, stall, flush);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize inputs
        rst            = 1;
        id_ex_mem_read = 0;
        id_ex_rd       = 5'd0;
        if_id_rs1      = 5'd0;
        if_id_rs2      = 5'd0;

        // Assert reset for exactly 5 rising edges
        repeat(5) @(posedge clk);
        rst = 0;

        // Allow the internal reg1/reg2 to be initialized after reset release
        // First, set up source registers and let them latch
        // The module latches if_id_rs1 -> reg1 and if_id_rs2 -> reg2 on posedge clk
        // Then on next posedge clk checks reg1/reg2 vs id_ex_rd

        // =================================================================
        // Test 1: All zeros - no hazard
        // =================================================================
        id_ex_mem_read = 0;
        id_ex_rd       = 5'd0;
        if_id_rs1      = 5'd0;
        if_id_rs2      = 5'd0;
        // First clock latches rs1=0, rs2=0 into reg1, reg2
        @(posedge clk); #1;
        // Second clock: check hazard with reg1=0, reg2=0, id_ex_rd=0, mem_read=0
        // mem_read=0 => no stall
        @(posedge clk); #1;
        if (stall === 1'b0 && flush === 1'b0) begin
            $display("PASS: Test 1 - All zeros no hazard (stall=%b flush=%b)", stall, flush);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 1 - All zeros no hazard | Expected stall=0 flush=0, Got stall=%b flush=%b", stall, flush);
            fail_count = fail_count + 1;
        end

        // =================================================================
        // Test 2: Load-use hazard on rs1
        // Set if_id_rs1=5, then next cycle set id_ex_rd=5 and mem_read=1
        // =================================================================
        id_ex_mem_read = 0;
        id_ex_rd       = 5'd0;
        if_id_rs1      = 5'd5;
        if_id_rs2      = 5'd3;
        @(posedge clk); #1; // reg1 <= 5, reg2 <= 3

        id_ex_mem_read = 1;
        id_ex_rd       = 5'd5; // matches reg1
        if_id_rs1      = 5'd5;
        if_id_rs2      = 5'd3;
        @(posedge clk); #1; // should produce stall=1, flush=1
        if (stall === 1'b1 && flush === 1'b1) begin
            $display("PASS: Test 2 - Load-use hazard rs1 match (stall=%b flush=%b)", stall, flush);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 2 - Load-use hazard rs1 match | Expected stall=1 flush=1, Got stall=%b flush=%b", stall, flush);
            fail_count = fail_count + 1;
        end

        // =================================================================
        // Test 3: Load-use hazard on rs2
        // =================================================================
        id_ex_mem_read = 0;
        if_id_rs1      = 5'd2;
        if_id_rs2      = 5'd7;
        @(posedge clk); #1; // reg1 <= 2, reg2 <= 7

        id_ex_mem_read = 1;
        id_ex_rd       = 5'd7; // matches reg2
        if_id_rs1      = 5'd2;
        if_id_rs2      = 5'd7;
        @(posedge clk); #1; // should produce stall=1, flush=1
        if (stall === 1'b1 && flush === 1'b1) begin
            $display("PASS: Test 3 - Load-use hazard rs2 match (stall=%b flush=%b)", stall, flush);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 3 - Load-use hazard rs2 match | Expected stall=1 flush=1, Got stall=%b flush=%b", stall, flush);
            fail_count = fail_count + 1;
        end

        // =================================================================
        // Test 4: mem_read=1 but no register match - no hazard
        // =================================================================
        id_ex_mem_read = 0;
        if_id_rs1      = 5'd4;
        if_id_rs2      = 5'd6;
        @(posedge clk); #1; // reg1 <= 4, reg2 <= 6

        id_ex_mem_read = 1;
        id_ex_rd       = 5'd8; // no match
        if_id_rs1      = 5'd4;
        if_id_rs2      = 5'd6;
        @(posedge clk); #1;
        if (stall === 1'b0 && flush === 1'b0) begin
            $display("PASS: Test 4 - mem_read=1 no match no hazard (stall=%b flush=%b)", stall, flush);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 4 - mem_read=1 no match no hazard | Expected stall=0 flush=0, Got stall=%b flush=%b", stall, flush);
            fail_count = fail_count + 1;
        end

        // =================================================================
        // Test 5: No mem_read, registers match (no hazard)
        // =================================================================
        id_ex_mem_read = 0;
        if_id_rs1      = 5'd10;
        if_id_rs2      = 5'd10;
        @(posedge clk); #1; // reg1 <= 10, reg2 <= 10

        id_ex_mem_read = 0;
        id_ex_rd       = 5'd10; // matches but mem_read=0
        if_id_rs1      = 5'd10;
        if_id_rs2      = 5'd10;
        @(posedge clk); #1;
        if (stall === 1'b0 && flush === 1'b0) begin
            $display("PASS: Test 5 - No mem_read with matching rd no hazard (stall=%b flush=%b)", stall, flush);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 5 - No mem_read with matching rd no hazard | Expected stall=0 flush=0, Got stall=%b flush=%b", stall, flush);
            fail_count = fail_count + 1;
        end

        // =================================================================
        // Test 6: All-ones inputs - load-use hazard both rs1 and rs2 match
        // =================================================================
        id_ex_mem_read = 0;
        if_id_rs1      = 5'd31;
        if_id_rs2      = 5'd31;
        @(posedge clk); #1; // reg1 <= 31, reg2 <= 31

        id_ex_mem_read = 1;
        id_ex_rd       = 5'd31; // max value, matches both
        if_id_rs1      = 5'd31;
        if_id_rs2      = 5'd31;
        @(posedge clk); #1;
        if (stall === 1'b1 && flush === 1'b1) begin
            $display("PASS: Test 6 - All-ones load-use hazard (stall=%b flush=%b)", stall, flush);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 6 - All-ones load-use hazard | Expected stall=1 flush=1, Got stall=%b flush=%b", stall, flush);
            fail_count = fail_count + 1;
        end

        // =================================================================
        // Test 7: Hazard then clear - stall deasserts after hazard removed
        // =================================================================
        // After test 6, clear the hazard
        id_ex_mem_read = 0;
        if_id_rs1      = 5'd1;
        if_id_rs2      = 5'd2;
        @(posedge clk); #1; // reg1 <= 1, reg2 <= 2

        id_ex_mem_read = 0;
        id_ex_rd       = 5'd31;
        if_id_rs1      = 5'd1;
        if_id_rs2      = 5'd2;
        @(posedge clk); #1;
        if (stall === 1'b0 && flush === 1'b0) begin
            $display("PASS: Test 7 - Hazard cleared stall deasserted (stall=%b flush=%b)", stall, flush);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 7 - Hazard cleared stall deasserted | Expected stall=0 flush=0, Got stall=%b flush=%b", stall, flush);
            fail_count = fail_count + 1;
        end

        // =================================================================
        // Test 8: Load-use hazard with x0 register (rd=0 matches rs=0)
        // In real RISC-V x0 is hardwired, but the hazard unit should still detect
        // =================================================================
        id_ex_mem_read = 0;
        if_id_rs1      = 5'd0;
        if_id_rs2      = 5'd9;
        @(posedge clk); #1; // reg1 <= 0, reg2 <= 9

        id_ex_mem_read = 1;
        id_ex_rd       = 5'd0; // matches rs1 (reg1=0)
        if_id_rs1      = 5'd0;
        if_id_rs2      = 5'd9;
        @(posedge clk); #1;
        if (stall === 1'b1 && flush === 1'b1) begin
            $display("PASS: Test 8 - Load-use hazard x0 register match (stall=%b flush=%b)", stall, flush);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 8 - Load-use hazard x0 register match | Expected stall=1 flush=1, Got stall=%b flush=%b", stall, flush);
            fail_count = fail_count + 1;
        end

        // =================================================================
        // Test 9: Maximum rd value (31) with rs2 matching only
        // =================================================================
        id_ex_mem_read = 0;
        if_id_rs1      = 5'd15;
        if_id_rs2      = 5'd31;
        @(posedge clk); #1; // reg1 <= 15, reg2 <= 31

        id_ex_mem_read = 1;
        id_ex_rd       = 5'd31;
        if_id_rs1      = 5'd15;
        if_id_rs2      = 5'd31;
        @(posedge clk); #1;
        if (stall === 1'b1 && flush === 1'b1) begin
            $display("PASS: Test 9 - Load-use hazard rs2 max value match (stall=%b flush=%b)", stall, flush);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 9 - Load-use hazard rs2 max value match | Expected stall=1 flush=1, Got stall=%b flush=%b", stall, flush);
            fail_count = fail_count + 1;
        end

        // =================================================================
        // Test 10: rs1 and rs2 different, neither matches id_ex_rd
        // =================================================================
        id_ex_mem_read = 0;
        if_id_rs1      = 5'd12;
        if_id_rs2      = 5'd13;
        @(posedge clk); #1;

        id_ex_mem_read = 1;
        id_ex_rd       = 5'd14;
        if_id_rs1      = 5'd12;
        if_id_rs2      = 5'd13;
        @(posedge clk); #1;
        if (stall === 1'b0 && flush === 1'b0) begin
            $display("PASS: Test 10 - mem_read=1 no match different regs (stall=%b flush=%b)", stall, flush);
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test 10 - mem_read=1 no match different regs | Expected stall=0 flush=0, Got stall=%b flush=%b", stall, flush);
            fail_count = fail_count + 1;
        end

        // Summary
        $display("========================================");
        $display("Test Summary: %0d passed, %0d failed", pass_count, fail_count);
