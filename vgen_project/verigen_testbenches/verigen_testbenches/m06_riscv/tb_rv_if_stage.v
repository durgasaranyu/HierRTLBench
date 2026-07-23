`timescale 1ns/1ps

module tb_rv_if_stage;

    // DUT connections
    reg         clk;
    reg         rst;
    reg         stall;
    reg         pc_src;
    reg  [31:0] branch_target;
    wire [31:0] pc;
    wire [31:0] pc_plus4;

    // Instantiate DUT
    rv_if_stage uut (
        .clk           (clk),
        .rst           (rst),
        .stall         (stall),
        .pc_src        (pc_src),
        .branch_target (branch_target),
        .pc            (pc),
        .pc_plus4      (pc_plus4)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Task to wait for one rising edge
    task wait_cycle;
        begin
            @(posedge clk);
            #1; // small delay to sample outputs after clock edge
        end
    endtask

    integer i;
    reg [31:0] expected_pc;
    reg [31:0] expected_pc_plus4;

    initial begin
        // Initialize inputs
        rst           = 1;
        stall         = 0;
        pc_src        = 0;
        branch_target = 32'h0000_0000;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // ---------------------------------------------------------------
        // After reset, PC should be 0 (or whatever reset value is)
        // We sample pc after the first non-reset cycle
        // ---------------------------------------------------------------

        // TEST 1: Check PC is 0 after reset
        @(posedge clk); #1;
        expected_pc       = 32'h0000_0000;
        expected_pc_plus4 = expected_pc + 4;
        if (pc === expected_pc && pc_plus4 === expected_pc_plus4)
            $display("PASS: After reset PC=0, pc_plus4=4");
        else
            $display("FAIL: After reset PC=%0h (exp %0h), pc_plus4=%0h (exp %0h)",
                     pc, expected_pc, pc_plus4, expected_pc_plus4);

        // ---------------------------------------------------------------
        // TEST 2: Normal operation - PC increments by 4 each cycle
        // ---------------------------------------------------------------
        // After reset deasserted, on each rising edge PC should advance by 4
        // Let's check over 3 cycles
        stall   = 0;
        pc_src  = 0;

        @(posedge clk); #1;
        expected_pc       = 32'h0000_0004;
        expected_pc_plus4 = expected_pc + 4;
        if (pc === expected_pc && pc_plus4 === expected_pc_plus4)
            $display("PASS: Normal increment cycle1: PC=4, pc_plus4=8");
        else
            $display("FAIL: Normal increment cycle1: PC=%0h (exp %0h), pc_plus4=%0h (exp %0h)",
                     pc, expected_pc, pc_plus4, expected_pc_plus4);

        @(posedge clk); #1;
        expected_pc       = 32'h0000_0008;
        expected_pc_plus4 = expected_pc + 4;
        if (pc === expected_pc && pc_plus4 === expected_pc_plus4)
            $display("PASS: Normal increment cycle2: PC=8, pc_plus4=12");
        else
            $display("FAIL: Normal increment cycle2: PC=%0h (exp %0h), pc_plus4=%0h (exp %0h)",
                     pc, expected_pc, pc_plus4, expected_pc_plus4);

        @(posedge clk); #1;
        expected_pc       = 32'h0000_000C;
        expected_pc_plus4 = expected_pc + 4;
        if (pc === expected_pc && pc_plus4 === expected_pc_plus4)
            $display("PASS: Normal increment cycle3: PC=0xC, pc_plus4=0x10");
        else
            $display("FAIL: Normal increment cycle3: PC=%0h (exp %0h), pc_plus4=%0h (exp %0h)",
                     pc, expected_pc, pc_plus4, expected_pc_plus4);

        // ---------------------------------------------------------------
        // TEST 3: Stall - PC should NOT change when stall=1
        // ---------------------------------------------------------------
        stall  = 1;
        pc_src = 0;

        // Record current PC before stall cycle
        // At this point PC should be 0x10 after next edge (but stall holds it)
        @(posedge clk); #1;
        // PC should remain 0xC (stalled)
        expected_pc       = 32'h0000_000C;
        expected_pc_plus4 = expected_pc + 4;
        if (pc === expected_pc && pc_plus4 === expected_pc_plus4)
            $display("PASS: Stall holds PC=0xC");
        else
            $display("FAIL: Stall: PC=%0h (exp %0h), pc_plus4=%0h (exp %0h)",
                     pc, expected_pc, pc_plus4, expected_pc_plus4);

        @(posedge clk); #1;
        // Still stalled - PC=0xC
        if (pc === expected_pc && pc_plus4 === expected_pc_plus4)
            $display("PASS: Stall still holds PC=0xC on second stall cycle");
        else
            $display("FAIL: Stall second cycle: PC=%0h (exp %0h), pc_plus4=%0h (exp %0h)",
                     pc, expected_pc, pc_plus4, expected_pc_plus4);

        // Release stall
        stall = 0;

        // ---------------------------------------------------------------
        // TEST 4: Branch taken - PC should jump to branch_target
        // ---------------------------------------------------------------
        pc_src        = 1;
        branch_target = 32'hDEAD_BEF0;

        @(posedge clk); #1;
        // After branch taken, PC should be branch_target
        expected_pc       = 32'hDEAD_BEF0;
        expected_pc_plus4 = expected_pc + 4;
        if (pc === expected_pc && pc_plus4 === expected_pc_plus4)
            $display("PASS: Branch taken: PC=0xDEADBEF0, pc_plus4=0xDEADBEF4");
        else
            $display("FAIL: Branch taken: PC=%0h (exp %0h), pc_plus4=%0h (exp %0h)",
                     pc, expected_pc, pc_plus4, expected_pc_plus4);

        // ---------------------------------------------------------------
        // TEST 5: Normal increment after branch
        // ---------------------------------------------------------------
        pc_src = 0;

        @(posedge clk); #1;
        expected_pc       = 32'hDEAD_BEF4;
        expected_pc_plus4 = expected_pc + 4;
        if (pc === expected_pc && pc_plus4 === expected_pc_plus4)
            $display("PASS: Normal increment after branch: PC=0xDEADBEF4");
        else
            $display("FAIL: Normal increment after branch: PC=%0h (exp %0h), pc_plus4=%0h (exp %0h)",
                     pc, expected_pc, pc_plus4, expected_pc_plus4);

        // ---------------------------------------------------------------
        // TEST 6: All-zero branch_target with pc_src=1
        // ---------------------------------------------------------------
        pc_src        = 1;
        branch_target = 32'h0000_0000;

        @(posedge clk); #1;
        expected_pc       = 32'h0000_0000;
        expected_pc_plus4 = 32'h0000_0004;
        if (pc === expected_pc && pc_plus4 === expected_pc_plus4)
            $display("PASS: Branch to zero: PC=0, pc_plus4=4");
        else
            $display("FAIL: Branch to zero: PC=%0h (exp %0h), pc_plus4=%0h (exp %0h)",
                     pc, expected_pc, pc_plus4, expected_pc_plus4);

        // ---------------------------------------------------------------
        // TEST 7: All-ones branch_target (max value)
        // ---------------------------------------------------------------
        pc_src        = 1;
        branch_target = 32'hFFFF_FFFC;

        @(posedge clk); #1;
        expected_pc       = 32'hFFFF_FFFC;
        expected_pc_plus4 = 32'h0000_0000; // wraps around
        if (pc === expected_pc && pc_plus4 === expected_pc_plus4)
            $display("PASS: Branch to max addr: PC=0xFFFFFFFC, pc_plus4 wraps to 0");
        else
            $display("FAIL: Branch to max addr: PC=%0h (exp %0h), pc_plus4=%0h (exp %0h)",
                     pc, expected_pc, pc_plus4, expected_pc_plus4);

        // ---------------------------------------------------------------
        // TEST 8: Stall with pc_src asserted - should stall, not branch
        // ---------------------------------------------------------------
        pc_src        = 0;
        branch_target = 32'h1234_5678;
        stall         = 0;

        @(posedge clk); #1;
        // PC should be 0xFFFFFFFC + 4 = 0 (wrapped), since no stall and no branch last cycle
        // Actually from test 7 PC=0xFFFFFFFC, now pc_src=0 stall=0 so PC becomes 0
        expected_pc       = 32'h0000_0000;
        expected_pc_plus4 = 32'h0000_0004;
        if (pc === expected_pc && pc_plus4 === expected_pc_plus4)
            $display("PASS: After max-addr normal increment wraps to 0");
        else
            $display("FAIL: After max-addr increment: PC=%0h (exp %0h), pc_plus4=%0h (exp %0h)",
                     pc, expected_pc, pc_plus4, expected_pc_plus4);

        // Now stall=1 and pc_src=1 simultaneously
        stall         = 1;
        pc_src        = 1;
        branch_target = 32'h1234_5678;

        @(posedge clk); #1;
        // If stall takes priority, PC stays at 0
        // (module-specific behavior: stall should prevent update)
        expected_pc       = 32'h0000_0000;
        expected_pc_plus4 = 32'h0000_0004;
        if (pc === expected_pc)
            $display("PASS: Stall overrides branch: PC stays 0");
        else
            $display("FAIL: Stall+branch: PC=%0h (exp stall held at %0h)", pc, expected_pc);

        // ---------------------------------------------------------------
        // Release all, verify pc_plus4 = pc + 4 invariant
        // ---------------------------------------------------------------
        stall  = 0;
        pc_src = 0;

        @(posedge clk); #1;
        if (pc_plus4 === pc + 4)
            $display("PASS: pc_plus4 = pc + 4 invariant holds");
        else
            $display("FAIL: pc_plus4 = pc + 4 invariant broken: pc=%0h pc_plus4=%0h", pc, pc_plus4);

        $finish;
    end

endmodule
