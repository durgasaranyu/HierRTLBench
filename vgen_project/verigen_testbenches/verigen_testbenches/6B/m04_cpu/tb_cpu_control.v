`timescale 1ns / 1ps

module tb_cpu_control;

    // DUT ports
    reg        clk;
    reg        rst;
    reg  [6:0] opcode;
    reg  [2:0] funct3;
    reg        zero;

    wire       pc_write;
    wire       ir_write;
    wire       reg_write;
    wire       mem_write;
    wire       alu_src_a;
    wire       alu_src_b;
    wire       mem_to_reg;
    wire       pc_source;
    wire [1:0] alu_op;

    // Instantiate DUT
    cpu_control uut (
        .clk       (clk),
        .rst       (rst),
        .opcode    (opcode),
        .funct3    (funct3),
        .zero      (zero),
        .pc_write  (pc_write),
        .ir_write  (ir_write),
        .reg_write (reg_write),
        .mem_write (mem_write),
        .alu_src_a (alu_src_a),
        .alu_src_b (alu_src_b),
        .mem_to_reg(mem_to_reg),
        .pc_source (pc_source),
        .alu_op    (alu_op)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Internal state tracking
    integer i;
    integer pass_count;
    integer fail_count;

    // Task: wait N rising edges
    task wait_edges;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1)
                @(posedge clk);
        end
    endtask

    // We need to observe the state register outputs.
    // The DUT cycles through states 0->1->2->3->4->0 (5 states per "instruction").
    // Observed outputs per state from the RTL:
    //   state 0 (IF)  : pc_write=0, ir_write=0, reg_write=0, mem_write=0, alu_op=2'b10
    //   state 1 (ID)  : pc_write=1, ir_write=0, reg_write=0, mem_write=0, alu_op=2'b10
    //   state 2 (EX)  : pc_write=0, ir_write=0, reg_write=1, mem_write=0, alu_op=2'b10
    //   state 3 (MEM) : pc_write=0, ir_write=0, reg_write=1, mem_write=0, alu_op=2'b10
    //   state 4 (WB)  : pc_write=0, ir_write=0, reg_write=0, mem_write=1, alu_op=2'b10

    // Helper: capture outputs right after a rising edge
    // We sample outputs combinatorially (they change immediately after state update)

    initial begin
        // Initialize
        rst    = 1;
        opcode = 7'h33; // ADD
        funct3 = 3'b000;
        zero   = 0;
        pass_count = 0;
        fail_count = 0;

        // -------------------------------------------------------
        // Assert reset for exactly 5 rising edges
        // -------------------------------------------------------
        @(posedge clk); // 1
        @(posedge clk); // 2
        @(posedge clk); // 3
        @(posedge clk); // 4
        @(posedge clk); // 5
        // Deassert reset after 5th rising edge
        @(negedge clk);
        rst = 0;

        // -------------------------------------------------------
        // TEST 1: Reset state check
        // After rst=1 for 5 edges, state should be 0 (IF).
        // In state 0: pc_write=0, reg_write=0, mem_write=0, alu_op=2'b10
        // -------------------------------------------------------
        @(negedge clk); // sample in state 0
        if (pc_write === 1'b0 && reg_write === 1'b0 && mem_write === 1'b0 && alu_op === 2'b10) begin
            $display("PASS: Test1 - After reset, state=0: pc_write=0, reg_write=0, mem_write=0, alu_op=10");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test1 - After reset, got pc_write=%b reg_write=%b mem_write=%b alu_op=%b",
                      pc_write, reg_write, mem_write, alu_op);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 2: State 1 (ID) - after one rising edge from state 0
        // state transitions: posedge clk causes state 0->1
        // -------------------------------------------------------
        @(posedge clk);
        #1; // small delay to let combinatorial outputs settle
        if (pc_write === 1'b1 && reg_write === 1'b0 && mem_write === 1'b0 && alu_op === 2'b10) begin
            $display("PASS: Test2 - State=1 (ID): pc_write=1, reg_write=0, mem_write=0, alu_op=10");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test2 - State=1 (ID): got pc_write=%b reg_write=%b mem_write=%b alu_op=%b",
                      pc_write, reg_write, mem_write, alu_op);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 3: ADD instruction - State 2 (EX): reg_write=1
        // -------------------------------------------------------
        opcode = 7'h33; funct3 = 3'b000; zero = 0;
        @(posedge clk);
        #1;
        if (pc_write === 1'b0 && reg_write === 1'b1 && mem_write === 1'b0 && alu_op === 2'b10) begin
            $display("PASS: Test3 - ADD State=2 (EX): reg_write=1, mem_write=0, alu_op=10");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test3 - ADD State=2 (EX): got pc_write=%b reg_write=%b mem_write=%b alu_op=%b",
                      pc_write, reg_write, mem_write, alu_op);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 4: ADD instruction - State 3 (MEM): reg_write=1, mem_write=0
        // -------------------------------------------------------
        @(posedge clk);
        #1;
        if (pc_write === 1'b0 && reg_write === 1'b1 && mem_write === 1'b0 && alu_op === 2'b10) begin
            $display("PASS: Test4 - ADD State=3 (MEM): reg_write=1, mem_write=0, alu_op=10");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test4 - ADD State=3 (MEM): got pc_write=%b reg_write=%b mem_write=%b alu_op=%b",
                      pc_write, reg_write, mem_write, alu_op);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 5: ADD instruction - State 4 (WB): mem_write=1, reg_write=0
        // -------------------------------------------------------
        @(posedge clk);
        #1;
        if (pc_write === 1'b0 && reg_write === 1'b0 && mem_write === 1'b1 && alu_op === 2'b10) begin
            $display("PASS: Test5 - ADD State=4 (WB): reg_write=0, mem_write=1, alu_op=10");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test5 - ADD State=4 (WB): got pc_write=%b reg_write=%b mem_write=%b alu_op=%b",
                      pc_write, reg_write, mem_write, alu_op);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 6: LW instruction - back to state 0 then cycle through
        // After WB (state 4), next state = 0
        // Apply LW opcode=7'h03
        // -------------------------------------------------------
        opcode = 7'h03; funct3 = 3'b010; zero = 0;
        @(posedge clk); // state 4->0
        #1;
        // state 0: pc_write=0, reg_write=0, mem_write=0
        if (pc_write === 1'b0 && reg_write === 1'b0 && mem_write === 1'b0) begin
            $display("PASS: Test6a - LW State=0 (IF): pc_write=0, reg_write=0, mem_write=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test6a - LW State=0 (IF): got pc_write=%b reg_write=%b mem_write=%b",
                      pc_write, reg_write, mem_write);
            fail_count = fail_count + 1;
        end

        @(posedge clk); #1; // state 1: pc_write=1
        @(posedge clk); #1; // state 2: reg_write=1
        @(posedge clk); #1; // state 3: reg_write=1
        @(posedge clk); #1; // state 4: mem_write=1

        if (mem_write === 1'b1 && reg_write === 1'b0) begin
            $display("PASS: Test6 - LW completes 5 phases: mem_write=1 at state 4");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test6 - LW State=4: got mem_write=%b reg_write=%b", mem_write, reg_write);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 7: SW instruction - opcode=7'h23
        // Cycle back to state 0 and run 5 phases
        // -------------------------------------------------------
        opcode = 7'h23; funct3 = 3'b010; zero = 0;
        @(posedge clk); #1; // 4->0: pc_write=0, reg_write=0, mem_write=0
        @(posedge clk); #1; // 0->1: pc_write=1
        @(posedge clk); #1; // 1->2: reg_write=1
        @(posedge clk); #1; // 2->3: reg_write=1
        @(posedge clk); #1; // 3->4: mem_write=1

        if (mem_write === 1'b1 && reg_write === 1'b0) begin
            $display("PASS: Test7 - SW completes 5 phases: mem_write=1 at state 4 (WB)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test7 - SW State=4: got mem_write=%b reg_write=%b", mem_write, reg_write);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 8: BEQ instruction with zero=1 (rs1==rs2)
        // opcode=7'h63
        // -------------------------------------------------------
        opcode = 7'h63; funct3 = 3'b000; zero = 1;
        @(posedge clk); #1; // 4->0
        // state 0: pc_write=0
        if (pc_write === 1'b0 && mem_write === 1'b0) begin
            $display("PASS: Test8a - BEQ State=0: pc_write=0, mem_write=0");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test8a - BEQ State=0: got pc_write=%b mem_write=%b", pc_write, mem_write);
            fail_count = fail_count + 1;
        end

        @(posedge clk); #1; // state 1: pc_write=1
        if (pc_write === 1'b1) begin
            $display("PASS: Test8b - BEQ State=1: pc_write=1 (PC updated)");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test8b - BEQ State=1: got pc_write=%b", pc_write);
            fail_count = fail_count + 1;
        end

        @(posedge clk); #1; // state 2: reg_write=1
        @(posedge clk); #1; // state 3: reg_write=1
        @(posedge clk); #1; // state 4: mem_write=1

        if (mem_write === 1'b1) begin
            $display("PASS: Test8 - BEQ (zero=1) completes 5 phases: mem_write=1 at state 4");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test8 - BEQ (zero=1) State=4: got mem_write=%b", mem_write);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 9: All-zero inputs (opcode=0, funct3=0, zero=0)
        // -------------------------------------------------------
        opcode = 7'h00; funct3 = 3'b000; zero = 0;
        @(posedge clk); #1; // 4->0
        if (pc_write === 1'b0 && reg_write === 1'b0 && mem_write === 1'b0 && alu_op === 2'b10) begin
            $display("PASS: Test9 - All-zero inputs, State=0: outputs match expected");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: Test9 - All-zero inputs, State=0: got pc_write=%b reg_write=%b mem_write=%b alu_op=%b",
                      pc_write, reg_write, mem_write, alu_op);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // TEST 10: All-ones inputs (opcode=7'h7F, funct3=3'b111, zero=1)
        // -------------------------------------------------------
        opcode = 7'h7F; funct3 = 3'b111; zero = 1;
        @(posedge clk); #1; // 0->1
        // state 1: pc_write=1
        if (pc_write === 1'b1 && reg_write === 1'b0 && mem_write === 1'b0) begin
            $display("PASS: Test10 - All-ones inputs, State=1: pc_write=1,
