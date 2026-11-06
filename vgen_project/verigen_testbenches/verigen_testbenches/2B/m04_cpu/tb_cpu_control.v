`timescale 1ns/1ps

module tb_cpu_control;

    // DUT ports
    reg        clk, rst;
    reg  [6:0] opcode;
    reg  [2:0] funct3;
    reg        zero;
    wire       pc_write, ir_write, reg_write, mem_write;
    wire       alu_src_a, alu_src_b, mem_to_reg, pc_source;
    wire [1:0] alu_op;

    // State encoding
    parameter IF  = 3'd0;
    parameter ID  = 3'd1;
    parameter EX  = 3'd2;
    parameter MEM = 3'd3;
    parameter WB  = 3'd4;

    // Opcodes
    parameter OP_RTYPE = 7'h33;
    parameter OP_ADDI  = 7'h13;
    parameter OP_LW    = 7'h03;
    parameter OP_SW    = 7'h23;
    parameter OP_BEQ   = 7'h63;

    integer fail_count;
    integer i;
    reg [2:0] state_tracker; // to know which state we're in

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

    // Task: apply reset for 5 rising edges
    task apply_reset;
        integer j;
        begin
            rst = 1;
            for (j = 0; j < 5; j = j + 1)
                @(posedge clk);
            @(negedge clk); // settle
            rst = 0;
        end
    endtask

    // Task: advance N clock cycles
    task advance_clocks;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1)
                @(posedge clk);
        end
    endtask

    // We'll track state manually to know expected outputs
    // The FSM transitions: IF->ID->EX->MEM->WB->IF (for most instructions)
    // For BEQ: IF->ID->EX->IF (3 states)
    // We'll observe outputs after each clock edge

    initial begin
        fail_count = 0;

        // Initialize inputs
        opcode  = 7'h00;
        funct3  = 3'b000;
        zero    = 0;

        // ===================================================
        // Apply Reset
        // ===================================================
        apply_reset;
        // After reset, FSM should be in IF state (state=0)
        // Check: ir_write should be high in IF state, pc_write should be high
        #1; // small delay after negedge to let outputs settle
        // We need to clock once to get out of reset and see IF outputs
        // Actually after rst=0, next posedge clk transitions to IF
        // Let's clock once and check
        @(posedge clk); #1;
        // Now in IF state - check ir_write and pc_write
        if (ir_write === 1'b1 && pc_write === 1'b1)
            $display("PASS: Reset - IF state: ir_write=1, pc_write=1");
        else
            begin
                $display("FAIL: Reset - IF state: ir_write=%b, pc_write=%b (expected 1,1)", ir_write, pc_write);
                fail_count = fail_count + 1;
            end

        // ===================================================
        // TEST 1: ADD instruction - walk through all 5 phases
        // ===================================================
        apply_reset;
        opcode = OP_RTYPE;
        funct3 = 3'b000;
        zero   = 0;

        // Cycle 1: IF state
        @(posedge clk); #1;
        // Should be in IF: ir_write=1, pc_write=1
        if (ir_write === 1'b1 && pc_write === 1'b1)
            $display("PASS: ADD - IF: ir_write=1, pc_write=1");
        else
            begin
                $display("FAIL: ADD - IF: ir_write=%b, pc_write=%b", ir_write, pc_write);
                fail_count = fail_count + 1;
            end

        // Cycle 2: ID state
        @(posedge clk); #1;
        // ID state: typically no mem_write, no reg_write
        if (mem_write === 1'b0 && reg_write === 1'b0)
            $display("PASS: ADD - ID: mem_write=0, reg_write=0");
        else
            begin
                $display("FAIL: ADD - ID: mem_write=%b, reg_write=%b", mem_write, reg_write);
                fail_count = fail_count + 1;
            end

        // Cycle 3: EX state
        @(posedge clk); #1;
        // EX state: alu_op should indicate R-type (likely 2'b10)
        if (alu_op === 2'b10)
            $display("PASS: ADD - EX: alu_op=10 (R-type)");
        else
            begin
                $display("FAIL: ADD - EX: alu_op=%b (expected 10)", alu_op);
                fail_count = fail_count + 1;
            end

        // Cycle 4: MEM state
        @(posedge clk); #1;
        // MEM state for R-type: no mem_write
        if (mem_write === 1'b0)
            $display("PASS: ADD - MEM: mem_write=0");
        else
            begin
                $display("FAIL: ADD - MEM: mem_write=%b (expected 0)", mem_write);
                fail_count = fail_count + 1;
            end

        // Cycle 5: WB state
        @(posedge clk); #1;
        // WB state: reg_write=1
        if (reg_write === 1'b1)
            $display("PASS: ADD - WB: reg_write=1 (register updated)");
        else
            begin
                $display("FAIL: ADD - WB: reg_write=%b (expected 1)", reg_write);
                fail_count = fail_count + 1;
            end

        // ===================================================
        // TEST 2: LW instruction - verify mem_to_reg and no mem_write
        // ===================================================
        apply_reset;
        opcode = OP_LW;
        funct3 = 3'b010;
        zero   = 0;

        // IF
        @(posedge clk); #1;
        // ID
        @(posedge clk); #1;
        // EX - address calculation, alu_src_b should be 1 (immediate)
        @(posedge clk); #1;
        if (alu_src_b === 1'b1)
            $display("PASS: LW - EX: alu_src_b=1 (using immediate for address)");
        else
            begin
                $display("FAIL: LW - EX: alu_src_b=%b (expected 1)", alu_src_b);
                fail_count = fail_count + 1;
            end

        // MEM - memory read (no mem_write)
        @(posedge clk); #1;
        if (mem_write === 1'b0)
            $display("PASS: LW - MEM: mem_write=0 (memory read, not write)");
        else
            begin
                $display("FAIL: LW - MEM: mem_write=%b (expected 0)", mem_write);
                fail_count = fail_count + 1;
            end

        // WB - reg_write=1, mem_to_reg=1
        @(posedge clk); #1;
        if (reg_write === 1'b1 && mem_to_reg === 1'b1)
            $display("PASS: LW - WB: reg_write=1, mem_to_reg=1");
        else
            begin
                $display("FAIL: LW - WB: reg_write=%b, mem_to_reg=%b (expected 1,1)", reg_write, mem_to_reg);
                fail_count = fail_count + 1;
            end

        // ===================================================
        // TEST 3: SW instruction - verify mem_write in MEM state
        // ===================================================
        apply_reset;
        opcode = OP_SW;
        funct3 = 3'b010;
        zero   = 0;

        // IF
        @(posedge clk); #1;
        // ID
        @(posedge clk); #1;
        // EX
        @(posedge clk); #1;
        if (alu_src_b === 1'b1)
            $display("PASS: SW - EX: alu_src_b=1 (using immediate for address)");
        else
            begin
                $display("FAIL: SW - EX: alu_src_b=%b (expected 1)", alu_src_b);
                fail_count = fail_count + 1;
            end

        // MEM - memory write
        @(posedge clk); #1;
        if (mem_write === 1'b1)
            $display("PASS: SW - MEM: mem_write=1 (store to memory)");
        else
            begin
                $display("FAIL: SW - MEM: mem_write=%b (expected 1)", mem_write);
                fail_count = fail_count + 1;
            end

        // ===================================================
        // TEST 4: BEQ with zero=1 (rs1==rs2) - verify PC branches
        // ===================================================
        apply_reset;
        opcode = OP_BEQ;
        funct3 = 3'b000;
        zero   = 1; // rs1 == rs2

        // IF
        @(posedge clk); #1;
        // ID
        @(posedge clk); #1;
        // EX - for BEQ, should check zero and potentially set pc_source and pc_write
        @(posedge clk); #1;
        if (pc_write === 1'b1 && pc_source === 1'b1)
            $display("PASS: BEQ(zero=1) - EX: pc_write=1, pc_source=1 (branch taken)");
        else
            begin
                $display("FAIL: BEQ(zero=1) - EX: pc_write=%b, pc_source=%b (expected 1,1)", pc_write, pc_source);
                fail_count = fail_count + 1;
            end

        // ===================================================
        // TEST 5: BEQ with zero=0 (rs1!=rs2) - verify PC does not branch
        // ===================================================
        apply_reset;
        opcode = OP_BEQ;
        funct3 = 3'b000;
        zero   = 0; // rs1 != rs2

        // IF
        @(posedge clk); #1;
        // ID
        @(posedge clk); #1;
        // EX
        @(posedge clk); #1;
        if (pc_source === 1'b0)
            $display("PASS: BEQ(zero=0) - EX: pc_source=0 (branch not taken)");
        else
            begin
                $display("FAIL: BEQ(zero=0) - EX: pc_source=%b (expected 0)", pc_source);
                fail_count = fail_count + 1;
            end

        // ===================================================
        // TEST 6: ADDI instruction - ALU src_b should use immediate
        // ===================================================
        apply_reset;
        opcode = OP_ADDI;
        funct3 = 3'b000;
        zero   = 0;

        // IF
        @(posedge clk); #1;
        // ID
        @(posedge clk); #1;
        // EX
        @(posedge clk); #1;
        if (alu_src_b === 1'b1)
            $display("PASS: ADDI - EX: alu_src_b=1 (immediate source)");
        else
            begin
                $display("FAIL: ADDI - EX: alu_src_b=%b (expected 1)", alu_src_b);
                fail_count = fail_count + 1;
            end

        // WB state - reg_write should be 1
        @(posedge clk); #1; // MEM
        @(posedge clk); #1; // WB
        if (reg_write === 1'b1)
            $display("PASS: ADDI - WB: reg_write=1");
        else
            begin
                $display("FAIL: ADDI - WB: reg_write=%b (expected 1)", reg_write);
                fail_count = fail_count + 1;
            end

        // ===================================================
        // TEST 7: All-zero inputs (opcode=0) - must not crash
        // ===================================================
        apply_reset;
        opcode = 7'h00;
        funct3 = 3'b000;
        zero   = 0;

        // Run 5 cycles
        advance_clocks(5);
        $display("PASS: All-zero opcode - no hang/crash after 5 cycles");

        // ===================================================
        // TEST 8: All-ones inputs
        // ===================================================
        apply_reset;
        opcode = 7'h7F;
        funct3 = 3'b111;
        zero   = 1;

        // Run 5 cycles
        advance_clocks(5);
        $display("PASS: All-ones inputs - no hang/crash after 5 cycles");

        // ===================================================
        // TEST 9: FSM cycles back to IF after WB (R-type ADD)
        // ===================================================
        apply_reset;
        opcode = OP_RTYPE;
        funct3 = 3'b000;
        zero   = 0;

        // Run through IF, ID, EX, MEM, WB (5 cycles)
        advance_clocks(5);
        // Cycle 6: should be back in IF
        @(posedge clk); #1;
        if (ir_write === 1'b1 && pc_write === 1'b1)
            $display("PASS: FSM cycles back to IF after WB: ir_write=1, pc_write=1");
        else
            begin
                $display("FAIL: FSM did not return to IF: ir_write=%b, pc_write=%b", ir_write, pc_write);
                fail_count = fail_count + 1;
            end

        // ===================================================
        // TEST 10: SW does not write to register file in WB
        // ===================================================
        apply_reset;
        opcode = OP_SW;
        funct3 = 3'b010;
        zero   = 0;

        // IF, ID, EX, MEM (SW typically has no WB stage or reg_write=0)
        @(posedge clk); #1
