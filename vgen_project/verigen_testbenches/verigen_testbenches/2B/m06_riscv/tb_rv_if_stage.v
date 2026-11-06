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
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .pc_src(pc_src),
        .branch_target(branch_target),
        .pc(pc),
        .pc_plus4(pc_plus4)
    );

    // Clock generation: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Expected tracking
    reg [31:0] exp_pc;
    reg [31:0] exp_pc4;
    integer    test_num;

    // Task: wait for one rising edge and check outputs
    task check_outputs;
        input [31:0] e_pc;
        input [31:0] e_pc4;
        input [64*8-1:0] desc;
        begin
            @(posedge clk);
            #1; // small delay to let outputs settle after clock edge
            if (pc === e_pc && pc_plus4 === e_pc4) begin
                $display("PASS: %0s  pc=%0d pc_plus4=%0d", desc, pc, pc_plus4);
            end else begin
                $display("FAIL: %0s  Expected pc=%0d pc_plus4=%0d, Got pc=%0d pc_plus4=%0d",
                         desc, e_pc, e_pc4, pc, pc_plus4);
            end
        end
    endtask

    integer i;

    initial begin
        // Initialize inputs
        rst           = 1;
        stall         = 0;
        pc_src        = 0;
        branch_target = 32'h0000_0000;
        test_num      = 0;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);

        // Deassert reset
        rst = 0;

        // After reset: pc should be 0, pc_plus4 should be 0
        // The module resets both pc and pc_plus4 to 0 on rst
        // After first clock post-reset (no stall): pc <= pc_plus4 (=0), pc_plus4 <= 0+4=4
        // Let's check right after reset deassertion - wait 1 ns
        #1;
        if (pc === 32'd0 && pc_plus4 === 32'd0) begin
            $display("PASS: Post-reset check pc=0 pc_plus4=0");
        end else begin
            $display("FAIL: Post-reset check Expected pc=0 pc_plus4=0, Got pc=%0d pc_plus4=%0d", pc, pc_plus4);
        end

        // ---------------------------------------------------------------
        // TEST 1: Normal operation - PC increments by 4 each cycle
        // At posedge clk: pc <= pc_plus4(0)=0, pc_plus4 <= 0+4=4
        stall  = 0;
        pc_src = 0;
        @(posedge clk); #1;
        // Now pc=0, pc_plus4=4
        if (pc === 32'd0 && pc_plus4 === 32'd4) begin
            $display("PASS: Cycle1 normal - pc=0, pc_plus4=4");
        end else begin
            $display("FAIL: Cycle1 normal - Expected pc=0 pc_plus4=4, Got pc=%0d pc_plus4=%0d", pc, pc_plus4);
        end

        // TEST 2: Second normal cycle: pc <= pc_plus4(4)=4, pc_plus4 <= 4+4=8
        @(posedge clk); #1;
        if (pc === 32'd4 && pc_plus4 === 32'd8) begin
            $display("PASS: Cycle2 normal - pc=4, pc_plus4=8");
        end else begin
            $display("FAIL: Cycle2 normal - Expected pc=4 pc_plus4=8, Got pc=%0d pc_plus4=%0d", pc, pc_plus4);
        end

        // TEST 3: Third normal cycle: pc=8, pc_plus4=12
        @(posedge clk); #1;
        if (pc === 32'd8 && pc_plus4 === 32'd12) begin
            $display("PASS: Cycle3 normal - pc=8, pc_plus4=12");
        end else begin
            $display("FAIL: Cycle3 normal - Expected pc=8 pc_plus4=12, Got pc=%0d pc_plus4=%0d", pc, pc_plus4);
        end

        // ---------------------------------------------------------------
        // TEST 4: Stall asserted - PC should load branch_target
        // stall=1, branch_target=0x100
        // According to the module: stall path => pc <= branch_target, pc_plus4 <= branch_target+4
        // Note: pc_src is not used in the module logic (stall takes priority regardless)
        stall         = 1;
        pc_src        = 0;
        branch_target = 32'h0000_0100;
        @(posedge clk); #1;
        if (pc === 32'h0000_0100 && pc_plus4 === 32'h0000_0104) begin
            $display("PASS: Stall - pc=0x100, pc_plus4=0x104");
        end else begin
            $display("FAIL: Stall - Expected pc=0x100 pc_plus4=0x104, Got pc=0x%0h pc_plus4=0x%0h", pc, pc_plus4);
        end

        // TEST 5: Stall deasserted - normal increment from branch target
        // pc=0x100, pc_plus4=0x104 => after posedge: pc<=0x104, pc_plus4<=0x108
        stall  = 0;
        pc_src = 0;
        @(posedge clk); #1;
        if (pc === 32'h0000_0104 && pc_plus4 === 32'h0000_0108) begin
            $display("PASS: After stall normal - pc=0x104, pc_plus4=0x108");
        end else begin
            $display("FAIL: After stall normal - Expected pc=0x104 pc_plus4=0x108, Got pc=0x%0h pc_plus4=0x%0h", pc, pc_plus4);
        end

        // ---------------------------------------------------------------
        // TEST 6: Branch target taken (stall=1 simulates pc_src branch)
        // Use a large branch target to verify
        stall         = 1;
        pc_src        = 1;
        branch_target = 32'hDEAD_BEEF;
        @(posedge clk); #1;
        if (pc === 32'hDEAD_BEEF && pc_plus4 === 32'hDEAD_BEF3) begin
            $display("PASS: Branch target taken - pc=0xDEADBEEF");
        end else begin
            $display("FAIL: Branch target taken - Expected pc=0xDEADBEEF pc_plus4=0xDEADBEF3, Got pc=0x%0h pc_plus4=0x%0h", pc, pc_plus4);
        end

        // TEST 7: All-zero branch target with stall
        stall         = 1;
        pc_src        = 1;
        branch_target = 32'h0000_0000;
        @(posedge clk); #1;
        if (pc === 32'h0000_0000 && pc_plus4 === 32'h0000_0004) begin
            $display("PASS: All-zero branch target - pc=0, pc_plus4=4");
        end else begin
            $display("FAIL: All-zero branch target - Expected pc=0 pc_plus4=4, Got pc=0x%0h pc_plus4=0x%0h", pc, pc_plus4);
        end

        // TEST 8: All-ones branch target with stall
        stall         = 1;
        pc_src        = 1;
        branch_target = 32'hFFFF_FFFF;
        @(posedge clk); #1;
        if (pc === 32'hFFFF_FFFF && pc_plus4 === 32'h0000_0003) begin
            $display("PASS: All-ones branch target - pc=0xFFFFFFFF pc_plus4=0x3 (overflow)");
        end else begin
            $display("FAIL: All-ones branch target - Expected pc=0xFFFFFFFF pc_plus4=0x3, Got pc=0x%0h pc_plus4=0x%0h", pc, pc_plus4);
        end

        // ---------------------------------------------------------------
        // TEST 9: Verify PC increments sequentially for multiple cycles
        // Reset and run 4 sequential increments
        rst = 1;
        @(posedge clk);
        @(posedge clk);
        rst           = 0;
        stall         = 0;
        pc_src        = 0;
        branch_target = 32'd0;

        // Cycle 1 after reset
        @(posedge clk); #1;
        if (pc === 32'd0 && pc_plus4 === 32'd4) begin
            $display("PASS: Sequential check cycle1 - pc=0");
        end else begin
            $display("FAIL: Sequential check cycle1 - Got pc=%0d pc_plus4=%0d", pc, pc_plus4);
        end

        // Cycle 2
        @(posedge clk); #1;
        if (pc === 32'd4 && pc_plus4 === 32'd8) begin
            $display("PASS: Sequential check cycle2 - pc=4");
        end else begin
            $display("FAIL: Sequential check cycle2 - Got pc=%0d pc_plus4=%0d", pc, pc_plus4);
        end

        // Cycle 3
        @(posedge clk); #1;
        if (pc === 32'd8 && pc_plus4 === 32'd12) begin
            $display("PASS: Sequential check cycle3 - pc=8");
        end else begin
            $display("FAIL: Sequential check cycle3 - Got pc=%0d pc_plus4=%0d", pc, pc_plus4);
        end

        // Cycle 4
        @(posedge clk); #1;
        if (pc === 32'd12 && pc_plus4 === 32'd16) begin
            $display("PASS: Sequential check cycle4 - pc=12");
        end else begin
            $display("FAIL: Sequential check cycle4 - Got pc=%0d pc_plus4=%0d", pc, pc_plus4);
        end

        // ---------------------------------------------------------------
        // TEST 10: Maximum value normal (stall=0 after max branch target overflow check)
        // Set via stall to a value near max, then do normal increment
        stall         = 1;
        branch_target = 32'hFFFF_FFF0;
        @(posedge clk); #1;
        if (pc === 32'hFFFF_FFF0 && pc_plus4 === 32'hFFFF_FFF4) begin
            $display("PASS: Near-max stall load - pc=0xFFFFFFF0");
        end else begin
            $display("FAIL: Near-max stall load - Got pc=0x%0h pc_plus4=0x%0h", pc, pc_plus4);
        end

        // Normal increment from near-max: pc <= 0xFFFFFFF4, pc_plus4 <= 0xFFFFFFF8
        stall = 0;
        @(posedge clk); #1;
        if (pc === 32'hFFFF_FFF4 && pc_plus4 === 32'hFFFF_FFF8) begin
            $display("PASS: Near-max normal inc - pc=0xFFFFFFF4");
        end else begin
            $display("FAIL: Near-max normal inc - Got pc=0x%0h pc_plus4=0x%0h", pc, pc_plus4);
        end

        $finish;
    end

endmodule
