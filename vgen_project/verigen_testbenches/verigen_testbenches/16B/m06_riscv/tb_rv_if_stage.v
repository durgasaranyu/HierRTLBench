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

    integer i;
    reg [31:0] expected_pc;

    task check_pc;
        input [31:0] exp_pc;
        input [31:0] exp_pc4;
        input [63:0] desc_a;
        input [63:0] desc_b;
        begin
            if (pc === exp_pc && pc_plus4 === exp_pc4) begin
                $display("PASS: pc=%0d pc_plus4=%0d [%s %s]", pc, pc_plus4, desc_a, desc_b);
            end else begin
                $display("FAIL: expected pc=%0d pc_plus4=%0d, got pc=%0d pc_plus4=%0d [%s %s]",
                         exp_pc, exp_pc4, pc, pc_plus4, desc_a, desc_b);
            end
        end
    endtask

    initial begin
        // Initialize inputs
        rst           = 1;
        stall         = 0;
        pc_src        = 0;
        branch_target = 32'h0;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);

        // Deassert reset; after this rising edge pc should be 0
        rst = 0;

        // ---------------------------------------------------------------
        // Test 1: After reset, PC should be 0, pc_plus4 = 4
        // ---------------------------------------------------------------
        @(negedge clk); // sample in middle of cycle after rst deasserted
        // PC was set to 0 on the 5th reset rising edge; rst=0 now, next
        // rising edge will advance PC. Let's check current state.
        if (pc === 32'd0 && pc_plus4 === 32'd4) begin
            $display("PASS: After reset PC=0, pc_plus4=4");
        end else begin
            $display("FAIL: After reset expected PC=0 pc_plus4=4, got PC=%0d pc_plus4=%0d", pc, pc_plus4);
        end

        // ---------------------------------------------------------------
        // Test 2: Normal increment - PC should increment by 4 each cycle
        // ---------------------------------------------------------------
        stall   = 0;
        pc_src  = 0;
        // Let PC advance one cycle
        @(posedge clk); #1;
        // PC should now be 4
        if (pc === 32'd4 && pc_plus4 === 32'd8) begin
            $display("PASS: Normal increment cycle1: PC=4, pc_plus4=8");
        end else begin
            $display("FAIL: Normal increment cycle1: expected PC=4 pc_plus4=8, got PC=%0d pc_plus4=%0d", pc, pc_plus4);
        end

        // ---------------------------------------------------------------
        // Test 3: Another normal increment - PC should be 8
        // ---------------------------------------------------------------
        @(posedge clk); #1;
        if (pc === 32'd8 && pc_plus4 === 32'd12) begin
            $display("PASS: Normal increment cycle2: PC=8, pc_plus4=12");
        end else begin
            $display("FAIL: Normal increment cycle2: expected PC=8 pc_plus4=12, got PC=%0d pc_plus4=%0d", pc, pc_plus4);
        end

        // ---------------------------------------------------------------
        // Test 4: Stall - PC should NOT change
        // ---------------------------------------------------------------
        stall = 1;
        @(posedge clk); #1;
        // PC should still be 8
        if (pc === 32'd8 && pc_plus4 === 32'd12) begin
            $display("PASS: Stall: PC held at 8, pc_plus4=12");
        end else begin
            $display("FAIL: Stall: expected PC=8 pc_plus4=12, got PC=%0d pc_plus4=%0d", pc, pc_plus4);
        end

        // ---------------------------------------------------------------
        // Test 5: Stall again - PC still shouldn't change
        // ---------------------------------------------------------------
        @(posedge clk); #1;
        if (pc === 32'd8) begin
            $display("PASS: Stall cycle2: PC still held at 8");
        end else begin
            $display("FAIL: Stall cycle2: expected PC=8, got PC=%0d", pc);
        end

        // ---------------------------------------------------------------
        // Test 6: Branch taken - PC should jump to branch_target
        // ---------------------------------------------------------------
        stall         = 0;
        pc_src        = 1;
        branch_target = 32'h0000_0100; // 256
        @(posedge clk); #1;
        if (pc === 32'h0000_0100 && pc_plus4 === 32'h0000_0104) begin
            $display("PASS: Branch taken: PC=256, pc_plus4=260");
        end else begin
            $display("FAIL: Branch taken: expected PC=256 pc_plus4=260, got PC=%0d pc_plus4=%0d", pc, pc_plus4);
        end

        // ---------------------------------------------------------------
        // Test 7: Branch target all-ones (max value) 
        // ---------------------------------------------------------------
        stall         = 0;
        pc_src        = 1;
        branch_target = 32'hFFFF_FFFC;
        @(posedge clk); #1;
        if (pc === 32'hFFFF_FFFC) begin
            $display("PASS: Branch to max: PC=0xFFFFFFFC");
        end else begin
            $display("FAIL: Branch to max: expected PC=0xFFFFFFFC, got PC=%08h", pc);
        end
        // pc_plus4 wraps around
        if (pc_plus4 === 32'h0000_0000) begin
            $display("PASS: pc_plus4 wraps to 0 at max PC");
        end else begin
            $display("FAIL: pc_plus4 should wrap to 0 at max PC, got %08h", pc_plus4);
        end

        // ---------------------------------------------------------------
        // Test 8: After branch to max, normal increment (pc_src=0) - wraps
        // ---------------------------------------------------------------
        pc_src = 0;
        stall  = 0;
        @(posedge clk); #1;
        // PC was 0xFFFFFFFC, increments to 0x00000000 (wrap)
        if (pc === 32'h0000_0000 && pc_plus4 === 32'h0000_0004) begin
            $display("PASS: Increment from max wraps: PC=0, pc_plus4=4");
        end else begin
            $display("FAIL: Increment from max wraps: expected PC=0 pc_plus4=4, got PC=%08h pc_plus4=%08h", pc, pc_plus4);
        end

        // ---------------------------------------------------------------
        // Test 9: Branch to zero target
        // ---------------------------------------------------------------
        stall         = 0;
        pc_src        = 1;
        branch_target = 32'h0000_0000;
        @(posedge clk); #1;
        if (pc === 32'h0000_0000 && pc_plus4 === 32'h0000_0004) begin
            $display("PASS: Branch to zero: PC=0, pc_plus4=4");
        end else begin
            $display("FAIL: Branch to zero: expected PC=0 pc_plus4=4, got PC=%0d pc_plus4=%0d", pc, pc_plus4);
        end

        // ---------------------------------------------------------------
        // Test 10: Stall while branch target is set (stall takes priority)
        // ---------------------------------------------------------------
        stall         = 1;
        pc_src        = 1;
        branch_target = 32'h0000_0200;
        @(posedge clk); #1;
        // Stall takes priority over pc_src per RTL (stall checked first)
        if (pc === 32'h0000_0000) begin
            $display("PASS: Stall overrides branch: PC stays at 0");
        end else begin
            $display("FAIL: Stall overrides branch: expected PC=0, got PC=%08h", pc);
        end

        // ---------------------------------------------------------------
        // Test 11: Release stall, branch should now take effect
        // ---------------------------------------------------------------
        stall  = 0;
        pc_src = 1;
        branch_target = 32'h0000_0200;
        @(posedge clk); #1;
        if (pc === 32'h0000_0200 && pc_plus4 === 32'h0000_0204) begin
            $display("PASS: Branch after stall release: PC=0x200, pc_plus4=0x204");
        end else begin
            $display("FAIL: Branch after stall release: expected PC=0x200 pc_plus4=0x204, got PC=%08h pc_plus4=%08h", pc, pc_plus4);
        end

        // ---------------------------------------------------------------
        // Test 12: Multiple sequential increments
        // ---------------------------------------------------------------
        pc_src = 0;
        stall  = 0;
        expected_pc = 32'h0000_0200;
        for (i = 0; i < 4; i = i + 1) begin
            @(posedge clk); #1;
            expected_pc = expected_pc + 4;
            if (pc === expected_pc) begin
                $display("PASS: Sequential increment %0d: PC=%0d", i+1, pc);
            end else begin
                $display("FAIL: Sequential increment %0d: expected PC=%0d, got PC=%0d", i+1, expected_pc, pc);
            end
        end

        $finish;
    end

endmodule
