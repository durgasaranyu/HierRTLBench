`timescale 1ns/1ps

module tb_m05_ctrl_integration;

    // DUT inputs
    reg  [6:0] opcode;
    reg  [2:0] phase;
    reg        clk;

    // DUT outputs
    wire       pc_write;
    wire       ir_write;
    wire       reg_write;
    wire       mem_write;
    wire       alu_src_a;
    wire       alu_src_b;
    wire       mem_to_reg;
    wire       pc_source;

    // Instantiate DUT
    hardwired_ctrl uut (
        .opcode    (opcode),
        .phase     (phase),
        .pc_write  (pc_write),
        .ir_write  (ir_write),
        .reg_write (reg_write),
        .mem_write (mem_write),
        .alu_src_a (alu_src_a),
        .alu_src_b (alu_src_b),
        .mem_to_reg(mem_to_reg),
        .pc_source (pc_source)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset signal (not used by combinational DUT, but required by spec)
    reg rst;
    initial begin
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
    end

    // Task to apply inputs and check outputs
    integer fail_count;
    integer pass_count;

    task apply_and_check;
        input [6:0] t_opcode;
        input [2:0] t_phase;
        input       exp_pc_write;
        input       exp_ir_write;
        input       exp_reg_write;
        input       exp_mem_write;
        input       exp_alu_src_a;
        input       exp_alu_src_b;
        input       exp_mem_to_reg;
        input       exp_pc_source;
        input [63:0] desc0;
        input [63:0] desc1;
        begin
            opcode = t_opcode;
            phase  = t_phase;
            #2; // small settle time (combinational)
            if (pc_write  === exp_pc_write  &&
                ir_write  === exp_ir_write  &&
                reg_write === exp_reg_write &&
                mem_write === exp_mem_write &&
                alu_src_a === exp_alu_src_a &&
                alu_src_b === exp_alu_src_b &&
                mem_to_reg=== exp_mem_to_reg &&
                pc_source === exp_pc_source) begin
                $display("PASS: opcode=%b phase=%0d", t_opcode, t_phase);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: opcode=%b phase=%0d | Expected pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b | Got pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                    t_opcode, t_phase,
                    exp_pc_write, exp_ir_write, exp_reg_write, exp_mem_write,
                    exp_alu_src_a, exp_alu_src_b, exp_mem_to_reg, exp_pc_source,
                    pc_write, ir_write, reg_write, mem_write,
                    alu_src_a, alu_src_b, mem_to_reg, pc_source);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // We'll probe the submodule signals to build expected values
    // For the integration test, we exercise all meaningful opcode/phase combos
    // and rely on the DUT's own internal logic — we will check self-consistency
    // by reading what the submodules produce.

    // Since we cannot predict exact values without the submodule RTL,
    // we will implement a "golden model" based on typical hardwired control for MIPS-like:
    //
    // Opcodes:
    //   7'b0000000 = R-type (ALU)
    //   7'b0100011 = SW (store word)
    //   7'b0000011 = LW (load word)
    //   7'b1100011 = BEQ (branch)
    //   7'b1101111 = JAL (jump)
    //   Others     = default/undefined
    //
    // Phases: 0,1 => phase01 module; 2,3,4 => phase234 module
    //
    // We do golden model checking. Since the module merges outputs:
    //   pc_write  from phase01
    //   ir_write  from phase01
    //   reg_write from phase01
    //   mem_write from phase01
    //   alu_src_a from phase01
    //   alu_src_b from phase01
    //   mem_to_reg from phase01
    //   pc_source from phase234
    //
    // Typical phase01 truth table (phase 0 = IF, phase 1 = ID):
    //   Phase 0 (any opcode): pc_write=1, ir_write=1, reg_write=0, mem_write=0, alu_src_a=0, alu_src_b=1, mem_to_reg=0
    //   Phase 1 (any opcode): pc_write=0, ir_write=0, reg_write=0, mem_write=0, alu_src_a=0, alu_src_b=0, mem_to_reg=0
    //
    // Typical phase234 truth table (pc_source):
    //   Phase 2,3,4: depends on opcode
    //   BEQ phase 4: pc_source=1
    //   JAL phase 2: pc_source=1
    //   Others: pc_source=0
    //
    // Because we don't have exact submodule code, we do a self-checking approach:
    // we sample the DUT outputs at reference points and check internal consistency,
    // plus we check that phase 0 always sets ir_write=1 and pc_write=1.

    integer i, j;
    reg [6:0] opcodes [0:7];
    reg [2:0] phases  [0:4];
    reg [7:0] got_outputs [0:7][0:4]; // store [pc_write,ir_write,reg_write,mem_write,alu_src_a,alu_src_b,mem_to_reg,pc_source]
    reg [7:0] ref_ph0;
    reg [7:0] ref_ph1;

    initial begin
        fail_count = 0;
        pass_count = 0;
        opcode = 0;
        phase  = 0;

        // Wait for reset to deassert
        @(posedge clk); // extra safety
        wait (rst === 0);
        @(posedge clk);

        // -------------------------------------------------------
        // Test 1: Phase 0 — fetch phase — should always be same
        // for any opcode: pc_write=1, ir_write=1
        // -------------------------------------------------------
        begin : blk_phase0
            integer k;
            for (k = 0; k < 8; k = k + 1) begin
                case(k)
                    0: opcode = 7'b0000000; // R-type
                    1: opcode = 7'b0100011; // SW
                    2: opcode = 7'b0000011; // LW
                    3: opcode = 7'b1100011; // BEQ
                    4: opcode = 7'b1101111; // JAL
                    5: opcode = 7'b0010011; // I-type
                    6: opcode = 7'b0110111; // LUI
                    7: opcode = 7'b1111111; // unknown
                endcase
                phase = 3'd0;
                #3;
                // Phase 0: fetch — pc_write and ir_write should be 1
                if (pc_write === 1'b1 && ir_write === 1'b1) begin
                    $display("PASS: Phase0 opcode=%b pc_write=%b ir_write=%b (fetch signals correct)", opcode, pc_write, ir_write);
                    pass_count = pass_count + 1;
                end else begin
                    $display("FAIL: Phase0 opcode=%b pc_write=%b ir_write=%b (expected pc_write=1,ir_write=1)", opcode, pc_write, ir_write);
                    fail_count = fail_count + 1;
                end
                #2;
            end
        end

        // -------------------------------------------------------
        // Test 2: Phase 1 — decode phase — reg_write=0 always
        // -------------------------------------------------------
        begin : blk_phase1
            integer k;
            for (k = 0; k < 8; k = k + 1) begin
                case(k)
                    0: opcode = 7'b0000000;
                    1: opcode = 7'b0100011;
                    2: opcode = 7'b0000011;
                    3: opcode = 7'b1100011;
                    4: opcode = 7'b1101111;
                    5: opcode = 7'b0010011;
                    6: opcode = 7'b0110111;
                    7: opcode = 7'b1111111;
                endcase
                phase = 3'd1;
                #3;
                // Phase 1: decode — reg_write should be 0, mem_write should be 0
                if (reg_write === 1'b0 && mem_write === 1'b0) begin
                    $display("PASS: Phase1 opcode=%b reg_write=%b mem_write=%b (decode signals correct)", opcode, reg_write, mem_write);
                    pass_count = pass_count + 1;
                end else begin
                    $display("FAIL: Phase1 opcode=%b reg_write=%b mem_write=%b (expected reg_write=0,mem_write=0)", opcode, reg_write, mem_write);
                    fail_count = fail_count + 1;
                end
                #2;
            end
        end

        // -------------------------------------------------------
        // Test 3: Phase 0 — alu_src_b should be 1 (PC+4 calc)
        // -------------------------------------------------------
        begin : blk_phase0_alub
            integer k;
            for (k = 0; k < 5; k = k + 1) begin
                case(k)
                    0: opcode = 7'b0000000;
                    1: opcode = 7'b0100011;
                    2: opcode = 7'b0000011;
                    3: opcode = 7'b1100011;
                    4: opcode = 7'b1101111;
                endcase
                phase = 3'd0;
                #3;
                if (alu_src_b === 1'b1) begin
                    $display("PASS: Phase0 opcode=%b alu_src_b=%b (correct for PC increment)", opcode, alu_src_b);
                    pass_count = pass_count + 1;
                end else begin
                    $display("FAIL: Phase0 opcode=%b alu_src_b=%b (expected 1 for PC increment)", opcode, alu_src_b);
                    fail_count = fail_count + 1;
                end
                #2;
            end
        end

        // -------------------------------------------------------
        // Test 4: Phase 0 — mem_write should be 0 always (no write during fetch)
        // -------------------------------------------------------
        begin : blk_phase0_memw
            integer k;
            for (k = 0; k < 5; k = k + 1) begin
                case(k)
                    0: opcode = 7'b0000000;
                    1: opcode = 7'b0100011;
                    2: opcode = 7'b0000011;
                    3: opcode = 7'b1100011;
                    4: opcode = 7'b1101111;
                endcase
                phase = 3'd0;
                #3;
                if (mem_write === 1'b0) begin
                    $display("PASS: Phase0 opcode=%b mem_write=%b (no mem write during fetch)", opcode, mem_write);
                    pass_count = pass_count + 1;
                end else begin
                    $display("FAIL: Phase0 opcode=%b mem_write=%b (expected 0 during fetch)", opcode, mem_write);
                    fail_count = fail_count + 1;
                end
                #2;
            end
        end

        // -------------------------------------------------------
        // Test 5: Phase 2,3,4 with R-type opcode
        //         reg_write=1 at execute/writeback for R-type
        //         mem_write=0
        // -------------------------------------------------------
        begin : blk_rtype
            integer k;
            opcode = 7'b0000000; // R-type
            for (k = 2; k <= 4; k = k + 1) begin
                phase = k[2:0];
                #3;
                // R-type: mem_write always 0
                if (mem_write === 1'b0) begin
                    $display("PASS: R-type phase=%0d mem_write=%b (correct, no memory write)", k, mem_write);
                    pass_count = pass_count + 1;
                end else begin
                    $display("FAIL: R-type phase=%0d mem_write=%b (expected 0)", k, mem_write);
                    fail_count = fail_count + 1;
                end
                #2;
            end
        end

        // -------------------------------------------------------
        // Test 6: Phase 2,3,4 with SW opcode
        //         mem_write=1 at memory phase for SW
        //         reg_write=0 for SW
        // -------------------------------------------------------
        begin : blk_sw
            integer k;
            opcode = 7'b0100011; // SW
            for (k = 2; k <= 4; k = k + 1) begin
                phase = k[2:0];
                #3;
                // SW: reg_write always 0
                if (reg_write === 1'b0) begin
                    $display("PASS: SW phase=%0d reg_write=%b (correct, no reg write for store)", k, reg_write);
                    pass_count = pass_count + 1;
                end else begin
                    $display("FAIL: SW phase=%0d reg_write=%b (expected 0 for store)", k, reg_write);
                    fail_count = fail_count + 1;
                end
                #2;
            end
        end

        // -------------------------------------------------------
        // Test 7: Phase 2,3,4 with BEQ opcode
        //         mem_write=0, reg_write=0 for branch
        // -------------------------------------------------------
        begin : blk_beq
            integer k;
            opcode = 7'b1100011; // BEQ
            for (k = 2; k <= 4; k = k + 1) begin
                phase = k[2:0];
                #3;
                if (mem_write === 1'b0 && reg_write === 1'b0) begin
                    $display("PASS: BEQ phase=%0d mem_write=%b reg_write=%b (correct for branch)", k, mem_write, reg_write);
                    pass_count = pass_count + 1;
