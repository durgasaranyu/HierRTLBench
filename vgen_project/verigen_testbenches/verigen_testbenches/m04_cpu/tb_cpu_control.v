`timescale 1ns / 1ps

module tb_cpu_control;

    // Clock and reset
    reg clk;
    reg rst;

    // DUT inputs
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg       zero;

    // DUT outputs
    wire        pc_write;
    wire        ir_write;
    wire        reg_write;
    wire        mem_write;
    wire        alu_src_a;
    wire        alu_src_b;
    wire        mem_to_reg;
    wire        pc_source;
    wire [1:0]  alu_op;

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

    // 10 ns clock period
    initial clk = 0;
    always #5 clk = ~clk;

    // Task: wait for N rising edges
    task wait_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    // Integer for loop variable
    integer i;

    // State tracking
    reg [2:0] expected_state;

    // -----------------------------------------------------------------------
    // Main test body
    // -----------------------------------------------------------------------
    initial begin
        // Initialise inputs
        rst    = 1;
        opcode = 7'h00;
        funct3 = 3'b000;
        zero   = 0;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        // Deassert reset
        @(negedge clk);
        rst = 0;

        // After reset, state should be 3'b000
        // The combinational outputs are for state 000:
        //   pc_write=0, ir_write=0, reg_write=0, mem_write=0
        //   alu_src_a=0, alu_src_b=0, mem_to_reg=0, alu_op=2'b10
        @(negedge clk); // sample outputs in state 000
        if (pc_write === 1'b0 && ir_write === 1'b0 && reg_write === 1'b0 &&
            mem_write === 1'b0 && alu_op === 2'b10)
            $display("PASS: Reset -> State 000: outputs correct");
        else
            $display("FAIL: Reset -> State 000: pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_op=%b",
                     pc_write, ir_write, reg_write, mem_write, alu_op);

        // -----------------------------------------------------------------------
        // TEST 1: Observe State 001 (one clock after reset release)
        // State 001: pc_write=1, ir_write=0, reg_write=0, mem_write=0, alu_op=2'b10
        // -----------------------------------------------------------------------
        @(posedge clk); // state transitions to 001
        #1; // small delay to let combinational settle
        if (pc_write === 1'b1 && ir_write === 1'b0 && reg_write === 1'b0 &&
            mem_write === 1'b0 && alu_op === 2'b10)
            $display("PASS: Test1 State 001: pc_write=1 correct");
        else
            $display("FAIL: Test1 State 001: pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_op=%b",
                     pc_write, ir_write, reg_write, mem_write, alu_op);

        // -----------------------------------------------------------------------
        // TEST 2: State 010 - reg_write=1, pc_write=0
        // -----------------------------------------------------------------------
        @(posedge clk); // state transitions to 010
        #1;
        if (pc_write === 1'b0 && reg_write === 1'b1 && mem_write === 1'b0 &&
            alu_op === 2'b10)
            $display("PASS: Test2 State 010 (EX): reg_write=1 correct");
        else
            $display("FAIL: Test2 State 010 (EX): pc_write=%b reg_write=%b mem_write=%b alu_op=%b",
                     pc_write, reg_write, mem_write, alu_op);

        // -----------------------------------------------------------------------
        // TEST 3: State 011 - reg_write=1
        // -----------------------------------------------------------------------
        @(posedge clk); // state transitions to 011
        #1;
        if (pc_write === 1'b0 && reg_write === 1'b1 && mem_write === 1'b0 &&
            alu_op === 2'b10)
            $display("PASS: Test3 State 011 (MEM): reg_write=1 correct");
        else
            $display("FAIL: Test3 State 011 (MEM): pc_write=%b reg_write=%b mem_write=%b alu_op=%b",
                     pc_write, reg_write, mem_write, alu_op);

        // -----------------------------------------------------------------------
        // TEST 4: State 100 (WB) - mem_write=1, reg_write=0, pc_write=0
        // -----------------------------------------------------------------------
        @(posedge clk); // state transitions to 100
        #1;
        if (pc_write === 1'b0 && reg_write === 1'b0 && mem_write === 1'b1 &&
            alu_op === 2'b10)
            $display("PASS: Test4 State 100 (WB): mem_write=1 correct");
        else
            $display("FAIL: Test4 State 100 (WB): pc_write=%b reg_write=%b mem_write=%b alu_op=%b",
                     pc_write, reg_write, mem_write, alu_op);

        // -----------------------------------------------------------------------
        // TEST 5: Cycles back to State 000
        // State 100 -> next_state = 000
        // -----------------------------------------------------------------------
        @(posedge clk); // state transitions back to 000
        #1;
        if (pc_write === 1'b0 && ir_write === 1'b0 && reg_write === 1'b0 &&
            mem_write === 1'b0 && alu_op === 2'b10)
            $display("PASS: Test5 Wraparound State 000: outputs correct");
        else
            $display("FAIL: Test5 Wraparound State 000: pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_op=%b",
                     pc_write, ir_write, reg_write, mem_write, alu_op);

        // -----------------------------------------------------------------------
        // TEST 6: ADD instruction simulation - run 5 full phases and check
        // Apply ADD opcode throughout
        // -----------------------------------------------------------------------
        opcode = 7'h33; // ADD/SUB opcode
        funct3 = 3'b000;
        zero   = 0;

        // Currently in state 000, run through all 5 states
        // State 000: pc_write=0
        #1;
        if (pc_write === 1'b0)
            $display("PASS: Test6a ADD State 000: pc_write=0");
        else
            $display("FAIL: Test6a ADD State 000: pc_write=%b", pc_write);

        @(posedge clk); #1; // -> state 001
        if (pc_write === 1'b1)
            $display("PASS: Test6b ADD State 001: pc_write=1");
        else
            $display("FAIL: Test6b ADD State 001: pc_write=%b", pc_write);

        @(posedge clk); #1; // -> state 010
        if (reg_write === 1'b1)
            $display("PASS: Test6c ADD State 010 (EX): reg_write=1");
        else
            $display("FAIL: Test6c ADD State 010 (EX): reg_write=%b", reg_write);

        @(posedge clk); #1; // -> state 011
        if (reg_write === 1'b1)
            $display("PASS: Test6d ADD State 011 (MEM): reg_write=1");
        else
            $display("FAIL: Test6d ADD State 011 (MEM): reg_write=%b", reg_write);

        @(posedge clk); #1; // -> state 100
        if (mem_write === 1'b1 && reg_write === 1'b0)
            $display("PASS: Test6e ADD State 100 (WB): mem_write=1");
        else
            $display("FAIL: Test6e ADD State 100 (WB): mem_write=%b reg_write=%b", mem_write, reg_write);

        // -----------------------------------------------------------------------
        // TEST 7: LW instruction - verify state 011 (MEM) reg_write
        // -----------------------------------------------------------------------
        opcode = 7'h03; // LW opcode
        funct3 = 3'b010;
        zero   = 0;

        @(posedge clk); #1; // -> state 000 (wraparound)
        if (pc_write === 1'b0 && mem_write === 1'b0)
            $display("PASS: Test7a LW State 000: correct");
        else
            $display("FAIL: Test7a LW State 000: pc_write=%b mem_write=%b", pc_write, mem_write);

        @(posedge clk); #1; // -> state 001
        if (pc_write === 1'b1)
            $display("PASS: Test7b LW State 001: pc_write=1");
        else
            $display("FAIL: Test7b LW State 001: pc_write=%b", pc_write);

        @(posedge clk); #1; // -> state 010
        if (reg_write === 1'b1)
            $display("PASS: Test7c LW State 010 (EX): reg_write=1 (address calc)");
        else
            $display("FAIL: Test7c LW State 010 (EX): reg_write=%b", reg_write);

        @(posedge clk); #1; // -> state 011
        // MEM state: reg_write=1 per the RTL
        if (reg_write === 1'b1)
            $display("PASS: Test7d LW State 011 (MEM read): reg_write=1");
        else
            $display("FAIL: Test7d LW State 011 (MEM read): reg_write=%b", reg_write);

        // -----------------------------------------------------------------------
        // TEST 8: SW instruction - verify mem_write in state 100
        // -----------------------------------------------------------------------
        opcode = 7'h23; // SW opcode
        funct3 = 3'b010;
        zero   = 0;

        @(posedge clk); #1; // -> state 100 (WB)
        if (mem_write === 1'b1)
            $display("PASS: Test8a SW State 100 (WB): mem_write=1 (store data)");
        else
            $display("FAIL: Test8a SW State 100 (WB): mem_write=%b", mem_write);

        @(posedge clk); #1; // -> state 000 (wraparound)
        if (mem_write === 1'b0 && pc_write === 1'b0)
            $display("PASS: Test8b SW State 000: mem_write=0");
        else
            $display("FAIL: Test8b SW State 000: mem_write=%b pc_write=%b", mem_write, pc_write);

        // -----------------------------------------------------------------------
        // TEST 9: BEQ with zero=1 (rs1==rs2)
        // -----------------------------------------------------------------------
        opcode = 7'h63; // BEQ opcode
        funct3 = 3'b000;
        zero   = 1;

        @(posedge clk); #1; // -> state 001
        if (pc_write === 1'b1)
            $display("PASS: Test9a BEQ State 001: pc_write=1");
        else
            $display("FAIL: Test9a BEQ State 001: pc_write=%b", pc_write);

        @(posedge clk); #1; // -> state 010
        if (reg_write === 1'b1)
            $display("PASS: Test9b BEQ State 010 (EX): correct");
        else
            $display("FAIL: Test9b BEQ State 010 (EX): reg_write=%b", reg_write);

        // -----------------------------------------------------------------------
        // TEST 10: All-zero inputs
        // -----------------------------------------------------------------------
        opcode = 7'h00;
        funct3 = 3'b000;
        zero   = 0;

        @(posedge clk); #1; // -> state 011
        if (alu_op === 2'b10)
            $display("PASS: Test10a All-zero opcode State 011: alu_op=2'b10");
        else
            $display("FAIL: Test10a All-zero opcode State 011: alu_op=%b", alu_op);

        // -----------------------------------------------------------------------
        // TEST 11: All-ones inputs
        // -----------------------------------------------------------------------
        opcode = 7'h7F;
        funct3 = 3'b111;
        zero   = 1;

        @(posedge clk); #1; // -> state 100
        if (mem_write === 1'b1)
            $display("PASS: Test11 All-ones opcode State 100: mem_write=1");
        else
            $display("FAIL: Test11 All-ones opcode State 100: mem_write=%b", mem_write);

        // -----------------------------------------------------------------------
        // TEST 12: Reset mid-operation - ensure state goes to 000
        // -----------------------------------------------------------------------
        @(posedge clk); #1; // -> state 000 (wraparound)
        // Now apply reset
        rst = 1;
        @(posedge clk); #1; // state should be 000 due to reset
        if (pc_write === 1'b0 && ir_write === 1'b0 && reg_write === 1'b0 &&
            mem_write === 1'b0 && alu_op === 2'b10)
            $display("PASS: Test12 Mid-operation reset: state=000 outputs correct");
        else
            $display("FAIL: Test12 Mid-operation reset: pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_op=%b",
                     pc_write, ir_write, reg_write, mem_write, alu_op);

        // Deassert reset
        @(negedge clk);
        rst = 0;
        opcode = 7'h00;
        funct3 = 3'b000;
        zero   = 0;

        // -----------------------------------------------------------------------
        // TEST 13: ADDI instruction - run full cycle
