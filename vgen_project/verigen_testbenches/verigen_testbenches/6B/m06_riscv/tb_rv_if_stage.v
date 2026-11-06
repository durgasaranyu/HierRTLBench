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

    // Clock generation: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Expected PC tracker
    reg [31:0] expected_pc;
    integer    i;

    // Task: wait for rising edge then check
    task wait_clk;
        begin
            @(posedge clk);
            #1; // small delay to let outputs settle
        end
    endtask

    initial begin
        // Initialise inputs
        rst           = 1;
        stall         = 0;
        pc_src        = 0;
        branch_target = 32'h0000_0000;

        // Assert reset for exactly 5 rising clock edges
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // After reset, PC should be 0
        expected_pc = 32'h0000_0000;
        if (pc === expected_pc)
            $display("PASS: After reset PC = 0x%08h", pc);
        else
            $display("FAIL: After reset PC expected 0x%08h got 0x%08h", expected_pc, pc);

        // Also verify pc_plus4 = pc + 4
        if (pc_plus4 === pc + 4)
            $display("PASS: pc_plus4 = pc + 4 after reset (pc_plus4=0x%08h)", pc_plus4);
        else
            $display("FAIL: pc_plus4 = pc + 4 after reset expected 0x%08h got 0x%08h", pc + 4, pc_plus4);

        // ---------------------------------------------------------------
        // Test 1: Normal sequential PC increment (no stall, no branch)
        // ---------------------------------------------------------------
        stall   = 0;
        pc_src  = 0;
        branch_target = 32'h0;

        // Let it run for 4 cycles and verify PC increments by 4 each cycle
        begin : test1_block
            reg [31:0] prev_pc;
            integer ok;
            ok = 1;
            prev_pc = pc;
            repeat (4) begin
                wait_clk;
                if (pc !== prev_pc + 4) begin
                    $display("FAIL: PC increment expected 0x%08h got 0x%08h", prev_pc + 4, pc);
                    ok = 0;
                end
                prev_pc = pc;
            end
            if (ok)
                $display("PASS: PC incremented by 4 for 4 consecutive cycles");
        end

        // ---------------------------------------------------------------
        // Test 2: pc_plus4 always equals pc + 4
        // ---------------------------------------------------------------
        if (pc_plus4 === pc + 4)
            $display("PASS: pc_plus4 = pc + 4 (0x%08h)", pc_plus4);
        else
            $display("FAIL: pc_plus4 mismatch expected 0x%08h got 0x%08h", pc + 4, pc_plus4);

        // ---------------------------------------------------------------
        // Test 3: Stall — PC should NOT change
        // ---------------------------------------------------------------
        stall  = 1;
        pc_src = 0;
        begin : test3_block
            reg [31:0] stall_pc;
            integer ok;
            ok = 1;
            stall_pc = pc;
            repeat (3) begin
                wait_clk;
                if (pc !== stall_pc) begin
                    $display("FAIL: PC changed during stall: expected 0x%08h got 0x%08h", stall_pc, pc);
                    ok = 0;
                end
            end
            if (ok)
                $display("PASS: PC held constant during stall for 3 cycles (PC=0x%08h)", stall_pc);
        end
        stall = 0;

        // ---------------------------------------------------------------
        // Test 4: Branch taken — PC should jump to branch_target
        // ---------------------------------------------------------------
        branch_target = 32'h0000_1000;
        pc_src = 1;
        wait_clk;
        pc_src = 0;
        if (pc === 32'h0000_1000)
            $display("PASS: Branch taken, PC = 0x%08h", pc);
        else
            $display("FAIL: Branch taken, expected 0x%08h got 0x%08h", 32'h0000_1000, pc);

        // ---------------------------------------------------------------
        // Test 5: After branch, sequential increment resumes
        // ---------------------------------------------------------------
        begin : test5_block
            reg [31:0] prev_pc;
            integer ok;
            ok = 1;
            prev_pc = pc;
            repeat (3) begin
                wait_clk;
                if (pc !== prev_pc + 4) begin
                    $display("FAIL: After branch, PC increment expected 0x%08h got 0x%08h", prev_pc + 4, pc);
                    ok = 0;
                end
                prev_pc = pc;
            end
            if (ok)
                $display("PASS: Sequential increment resumes after branch");
        end

        // ---------------------------------------------------------------
        // Test 6: Branch to all-zeros target
        // ---------------------------------------------------------------
        branch_target = 32'h0000_0000;
        pc_src = 1;
        wait_clk;
        pc_src = 0;
        if (pc === 32'h0000_0000)
            $display("PASS: Branch to 0x00000000 (all-zeros target)");
        else
            $display("FAIL: Branch to all-zeros expected 0x00000000 got 0x%08h", pc);

        // ---------------------------------------------------------------
        // Test 7: Branch to all-ones target (max value)
        // ---------------------------------------------------------------
        branch_target = 32'hFFFF_FFFC; // aligned
        pc_src = 1;
        wait_clk;
        pc_src = 0;
        if (pc === 32'hFFFF_FFFC)
            $display("PASS: Branch to max target 0xFFFFFFFC");
        else
            $display("FAIL: Branch to max target expected 0xFFFFFFFC got 0x%08h", pc);

        // ---------------------------------------------------------------
        // Test 8: Stall while branch_target presented — PC should NOT change
        // ---------------------------------------------------------------
        branch_target = 32'h0000_2000;
        pc_src = 0;
        stall  = 1;
        begin : test8_block
            reg [31:0] stall_pc2;
            stall_pc2 = pc;
            wait_clk;
            if (pc === stall_pc2)
                $display("PASS: PC held during stall with new branch_target (PC=0x%08h)", pc);
            else
                $display("FAIL: PC changed during stall with branch_target: expected 0x%08h got 0x%08h", stall_pc2, pc);
        end
        stall = 0;

        // ---------------------------------------------------------------
        // Test 9: Reset reasserted — PC goes back to 0
        // ---------------------------------------------------------------
        // Let it run a few cycles from wherever we are
        wait_clk;
        wait_clk;
        rst = 1;
        wait_clk;
        #1;
        if (pc === 32'h0000_0000)
            $display("PASS: Reset reasserted, PC = 0x%08h", pc);
        else
            $display("FAIL: Reset reasserted, expected 0x00000000 got 0x%08h", pc);
        rst = 0;

        // ---------------------------------------------------------------
        // Test 10: pc_plus4 = pc + 4 verified immediately after reset release
        // ---------------------------------------------------------------
        wait_clk;
        if (pc_plus4 === pc + 4)
            $display("PASS: pc_plus4 == pc+4 after re-reset (pc=0x%08h, pc_plus4=0x%08h)", pc, pc_plus4);
        else
            $display("FAIL: pc_plus4 mismatch after re-reset expected 0x%08h got 0x%08h", pc + 4, pc_plus4);

        // ---------------------------------------------------------------
        // Test 11: Branch target mid-range value
        // ---------------------------------------------------------------
        branch_target = 32'h0800_0000;
        pc_src = 1;
        wait_clk;
        pc_src = 0;
        if (pc === 32'h0800_0000)
            $display("PASS: Branch to mid-range target 0x08000000");
        else
            $display("FAIL: Branch to mid-range expected 0x08000000 got 0x%08h", pc);

        // A couple more sequential cycles
        begin : test11_seq
            reg [31:0] p;
            p = pc;
            wait_clk;
            if (pc === p + 4)
                $display("PASS: Sequential after mid-range branch (PC=0x%08h)", pc);
            else
                $display("FAIL: Sequential after mid-range branch expected 0x%08h got 0x%08h", p+4, pc);
        end

        $finish;
    end

endmodule
