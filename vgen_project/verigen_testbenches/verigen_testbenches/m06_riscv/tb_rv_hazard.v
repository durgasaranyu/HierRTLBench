`timescale 1ns/1ps

// Testbench for rv_hazard
// NOTE: The module rv_hazard references 'clk' as a free variable (not a port).
// We declare a global clk net and drive it, then instantiate the DUT.

module tb_rv_hazard;

    // Global clock (used by rv_hazard internally via implicit net)
    reg clk;
    reg rst; // not used by rv_hazard directly but kept for completeness

    // DUT ports
    reg        id_ex_mem_read;
    reg  [4:0] id_ex_rd;
    reg  [4:0] if_id_rs1;
    reg  [4:0] if_id_rs2;
    wire       stall;
    wire       flush;

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    rv_hazard uut (
        .id_ex_mem_read (id_ex_mem_read),
        .id_ex_rd       (id_ex_rd),
        .if_id_rs1      (if_id_rs1),
        .if_id_rs2      (if_id_rs2),
        .stall          (stall),
        .flush          (flush)
    );

    // Task: wait for one rising clock edge
    task wait_clk;
        begin
            @(posedge clk);
            #1; // small delay after edge to sample outputs
        end
    endtask

    integer failed;

    initial begin
        failed = 0;

        // Initialize all inputs
        id_ex_mem_read = 0;
        id_ex_rd       = 5'd0;
        if_id_rs1      = 5'd0;
        if_id_rs2      = 5'd0;
        rst            = 1;

        // Assert reset for 5 rising edges
        repeat(5) @(posedge clk);
        #1;
        rst = 0;

        // ---------------------------------------------------------------
        // The rv_hazard module works as follows:
        //   - On posedge clk: reg1 <= if_id_rs1; reg2 <= if_id_rs2
        //   - On posedge clk: if (id_ex_mem_read & ((reg1==id_ex_rd)|(reg2==id_ex_rd)))
        //                         stall<=1; flush<=1;
        //                     else stall<=0; flush<=0;
        //
        // So to trigger a hazard:
        //   Cycle N:   set if_id_rs1/rs2 -> these get captured into reg1/reg2
        //   Cycle N+1: set id_ex_mem_read=1, id_ex_rd = old rs1 or rs2
        //              -> hazard detected, stall/flush go high after cycle N+1 edge
        // ---------------------------------------------------------------

        // -----------------------------------------------------------
        // TEST 1: All-zero inputs, no hazard expected
        // -----------------------------------------------------------
        id_ex_mem_read = 0;
        id_ex_rd       = 5'd0;
        if_id_rs1      = 5'd0;
        if_id_rs2      = 5'd0;
        wait_clk; // cycle: reg1<=0, reg2<=0; no hazard (mem_read=0) -> stall=0,flush=0
        wait_clk; // check outputs now
        if (stall === 1'b0 && flush === 1'b0) begin
            $display("PASS: TEST1 - All zeros, no hazard: stall=%0b flush=%0b", stall, flush);
        end else begin
            $display("FAIL: TEST1 - All zeros, no hazard: stall=%0b flush=%0b (expected 0,0)", stall, flush);
            failed = failed + 1;
        end

        // -----------------------------------------------------------
        // TEST 2: id_ex_mem_read=0, rs match rd -> no stall (mem_read not set)
        // -----------------------------------------------------------
        // Set up reg1/reg2 first
        if_id_rs1      = 5'd5;
        if_id_rs2      = 5'd6;
        id_ex_mem_read = 0;
        id_ex_rd       = 5'd5;
        wait_clk; // reg1<=5, reg2<=6; stall check: mem_read=0 -> no stall
        // Now check outputs
        if (stall === 1'b0 && flush === 1'b0) begin
            $display("PASS: TEST2 - mem_read=0 with matching rd: stall=%0b flush=%0b", stall, flush);
        end else begin
            $display("FAIL: TEST2 - mem_read=0 with matching rd: stall=%0b flush=%0b (expected 0,0)", stall, flush);
            failed = failed + 1;
        end

        // -----------------------------------------------------------
        // TEST 3: Load-use hazard via rs1 match
        // Step A: clock in rs1=5 into reg1
        // Step B: assert mem_read=1, rd=5 -> should see stall=1, flush=1
        // -----------------------------------------------------------
        // At this point reg1=5, reg2=6 from previous cycle
        // Now apply id_ex_mem_read=1, id_ex_rd=5
        id_ex_mem_read = 1;
        id_ex_rd       = 5'd5;
        if_id_rs1      = 5'd5; // these will update reg1/reg2 at next edge
        if_id_rs2      = 5'd6;
        wait_clk; // edge: reg1<=5,reg2<=6; stall check: mem_read=1 & (reg1_old==5) -> stall=1
        // reg1_old was 5 (from TEST2 step), so hazard triggered
        if (stall === 1'b1 && flush === 1'b1) begin
            $display("PASS: TEST3 - Load-use hazard rs1 match: stall=%0b flush=%0b", stall, flush);
        end else begin
            $display("FAIL: TEST3 - Load-use hazard rs1 match: stall=%0b flush=%0b (expected 1,1)", stall, flush);
            failed = failed + 1;
        end

        // -----------------------------------------------------------
        // TEST 4: Load-use hazard via rs2 match
        // reg1=5,reg2=6 after TEST3 edge; apply mem_read=1, rd=6
        // -----------------------------------------------------------
        id_ex_mem_read = 1;
        id_ex_rd       = 5'd6;
        if_id_rs1      = 5'd3;
        if_id_rs2      = 5'd7;
        wait_clk; // edge: reg1<=3,reg2<=7; stall check: mem_read=1 & (reg2_old==6) -> stall=1
        if (stall === 1'b1 && flush === 1'b1) begin
            $display("PASS: TEST4 - Load-use hazard rs2 match: stall=%0b flush=%0b", stall, flush);
        end else begin
            $display("FAIL: TEST4 - Load-use hazard rs2 match: stall=%0b flush=%0b (expected 1,1)", stall, flush);
            failed = failed + 1;
        end

        // -----------------------------------------------------------
        // TEST 5: No hazard after hazard clears - rd doesn't match
        // reg1=3,reg2=7; apply mem_read=1, rd=10 (no match)
        // -----------------------------------------------------------
        id_ex_mem_read = 1;
        id_ex_rd       = 5'd10;
        if_id_rs1      = 5'd1;
        if_id_rs2      = 5'd2;
        wait_clk; // edge: reg1<=1,reg2<=2; stall check: mem_read=1 & (reg1_old=3!=10)&(reg2_old=7!=10) -> no stall
        if (stall === 1'b0 && flush === 1'b0) begin
            $display("PASS: TEST5 - No hazard, rd no match: stall=%0b flush=%0b", stall, flush);
        end else begin
            $display("FAIL: TEST5 - No hazard, rd no match: stall=%0b flush=%0b (expected 0,0)", stall, flush);
            failed = failed + 1;
        end

        // -----------------------------------------------------------
        // TEST 6: All-ones inputs - rs1=31,rs2=31,rd=31,mem_read=1 -> hazard
        // First clock in rs1/rs2=31
        // -----------------------------------------------------------
        id_ex_mem_read = 0;
        id_ex_rd       = 5'd31;
        if_id_rs1      = 5'd31;
        if_id_rs2      = 5'd31;
        wait_clk; // reg1<=31,reg2<=31; mem_read=0 -> no hazard
        // Now trigger hazard
        id_ex_mem_read = 1;
        id_ex_rd       = 5'd31;
        wait_clk; // reg1=31,reg2=31; mem_read=1 & match -> stall=1
        if (stall === 1'b1 && flush === 1'b1) begin
            $display("PASS: TEST6 - All-ones hazard: stall=%0b flush=%0b", stall, flush);
        end else begin
            $display("FAIL: TEST6 - All-ones hazard: stall=%0b flush=%0b (expected 1,1)", stall, flush);
            failed = failed + 1;
        end

        // -----------------------------------------------------------
        // TEST 7: rs1=0,rs2=0 (x0 register), rd=0, mem_read=1
        // In real RISC-V x0 is always 0 but hazard logic checks register numbers
        // reg1/reg2 still have 31 from TEST6 edge; let's clock in 0s first
        // -----------------------------------------------------------
        id_ex_mem_read = 0;
        id_ex_rd       = 5'd0;
        if_id_rs1      = 5'd0;
        if_id_rs2      = 5'd0;
        wait_clk; // reg1<=0,reg2<=0; no hazard
        id_ex_mem_read = 1;
        id_ex_rd       = 5'd0;
        wait_clk; // reg1=0,reg2=0; mem_read=1 & (0==0) -> stall=1
        if (stall === 1'b1 && flush === 1'b1) begin
            $display("PASS: TEST7 - x0 hazard (rd=0,rs=0): stall=%0b flush=%0b", stall, flush);
        end else begin
            $display("FAIL: TEST7 - x0 hazard (rd=0,rs=0): stall=%0b flush=%0b (expected 1,1)", stall, flush);
            failed = failed + 1;
        end

        // -----------------------------------------------------------
        // TEST 8: Back-to-back: hazard then no hazard then hazard
        // reg1/reg2 will be 0 after TEST7 edge
        // Apply: mem_read=0 -> no stall
        // -----------------------------------------------------------
        id_ex_mem_read = 0;
        id_ex_rd       = 5'd0;
        if_id_rs1      = 5'd15;
        if_id_rs2      = 5'd16;
        wait_clk; // reg1<=15,reg2<=16; no stall
        if (stall === 1'b0 && flush === 1'b0) begin
            $display("PASS: TEST8a - Transition no-hazard: stall=%0b flush=%0b", stall, flush);
        end else begin
            $display("FAIL: TEST8a - Transition no-hazard: stall=%0b flush=%0b (expected 0,0)", stall, flush);
            failed = failed + 1;
        end

        // Now trigger hazard on rs2
        id_ex_mem_read = 1;
        id_ex_rd       = 5'd16;
        if_id_rs1      = 5'd20;
        if_id_rs2      = 5'd21;
        wait_clk; // reg1=15,reg2=16; mem_read=1 & (reg2==16) -> stall=1
        if (stall === 1'b1 && flush === 1'b1) begin
            $display("PASS: TEST8b - Back-to-back hazard on rs2: stall=%0b flush=%0b", stall, flush);
        end else begin
            $display("FAIL: TEST8b - Back-to-back hazard on rs2: stall=%0b flush=%0b (expected 1,1)", stall, flush);
            failed = failed + 1;
        end

        // -----------------------------------------------------------
        // TEST 9: Maximum register values (rd=31, rs1=31, rs2=30), mem_read=1
        // reg1<=20,reg2<=21 from last edge; need to clock in 31
        // -----------------------------------------------------------
        id_ex_mem_read = 0;
        id_ex_rd       = 5'd31;
        if_id_rs1      = 5'd31;
        if_id_rs2      = 5'd30;
        wait_clk; // reg1<=31,reg2<=30; no hazard (mem_read=0)
        id_ex_mem_read = 1;
        id_ex_rd       = 5'd30;
        wait_clk; // reg2_old=30==30 -> stall=1
        if (stall === 1'b1 && flush === 1'b1) begin
            $display("PASS: TEST9 - Max reg values hazard: stall=%0b flush=%0b", stall, flush);
        end else begin
            $display("FAIL: TEST9 - Max reg values hazard: stall=%0b flush=%0b (expected 1,1)", stall, flush);
            failed = failed + 1;
        end

        // -----------------------------------------------------------
        // Summary
        // -----------------------------------------------------------
        if (failed == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("%0d TEST(S) FAILED", failed);
        end

        $finish;
    end

endmodule
