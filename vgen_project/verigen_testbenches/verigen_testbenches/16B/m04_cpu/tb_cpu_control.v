`timescale 1ns/1ps

module tb_cpu_control;

    // DUT inputs
    reg        clk;
    reg        rst;
    reg [6:0]  opcode;
    reg [2:0]  funct3;
    reg        zero;

    // DUT outputs
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

    integer i;
    integer pass_count;
    integer fail_count;

    task apply_clock;
        input integer n;
        integer k;
        begin
            for (k = 0; k < n; k = k + 1) begin
                @(posedge clk);
                #1; // small delay after edge for output sampling
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize inputs
        rst    = 1;
        opcode = 7'b0000000;
        funct3 = 3'b000;
        zero   = 0;

        // Assert reset for exactly 5 rising edges
        repeat (5) @(posedge clk);
        #1;
        rst = 0;

        // =====================================================================
        // The module is a combinational FSM (state = next_state via always@(*))
        // We exercise each state by driving the opcode that causes transitions.
        // Parameters: IDLE=0, FETCH=1, IF_ID=2, ID_EX=3, EX_MEM=4, MEM_WB=5
        // =====================================================================

        // ----- TEST 1: IDLE state with default opcode (stay in IDLE) -----
        opcode = 7'b0000000;
        funct3 = 3'b000;
        zero   = 0;
        #2;
        // In IDLE with non-trigger opcode: all control signals should be 0 except alu_op=2'b10
        if (pc_write === 0 && ir_write === 0 && reg_write === 0 && mem_write === 0 &&
            alu_src_a === 0 && alu_src_b === 0 && mem_to_reg === 0 && pc_source === 0 &&
            alu_op === 2'b10) begin
            $display("PASS: IDLE state with opcode=0 - all control signals default");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: IDLE state with opcode=0 - control signals unexpected. pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_op=%b",
                      pc_write, ir_write, reg_write, mem_write, alu_op);
            fail_count = fail_count + 1;
        end

        // ----- TEST 2: IDLE state with trigger opcode 7'b11000101 -----
        opcode = 7'b11000101;
        #2;
        // Should activate: pc_write=1, reg_write=1, mem_write=1, alu_src_a=1, alu_src_b=1,
        // mem_to_reg=1, alu_op=2'b00; also pc_source treated as pc_source=2 (but it's 1-bit...)
        // Note: pc_source is 1-bit, so 2 wraps to 0
        if (pc_write === 1 && reg_write === 1 && mem_write === 1 &&
            alu_src_a === 1 && alu_src_b === 1 && mem_to_reg === 1 &&
            alu_op === 2'b00) begin
            $display("PASS: IDLE state with opcode=7'b11000101 - trigger signals asserted");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: IDLE state with opcode=7'b11000101 - pc_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b alu_op=%b",
                      pc_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, alu_op);
            fail_count = fail_count + 1;
        end

        // ----- TEST 3: Transition to FETCH state -----
        // IDLE->FETCH when opcode==7'b11000101; state is now FETCH
        // In FETCH: all 0 except alu_op=2'b00
        // Since state=next_state combinationally, after setting opcode=7'b11000101 state becomes FETCH
        opcode = 7'b11000101; // stays in FETCH one more cycle
        #2;
        // Now state should be FETCH (from IDLE->FETCH transition), FETCH->IF_ID always
        // Let's check FETCH outputs: pc_write=0, ir_write=0, reg_write=0, mem_write=0,
        //   alu_src_a=0, alu_src_b=0, mem_to_reg=0, pc_source=0, alu_op=2'b00
        // But since combinational, state=FETCH now also triggers next_state=IF_ID
        // The output is based on current state=FETCH
        if (pc_write === 0 && ir_write === 0 && reg_write === 0 && mem_write === 0 &&
            alu_src_a === 0 && alu_src_b === 0 && mem_to_reg === 0 && pc_source === 0 &&
            alu_op === 2'b00) begin
            $display("PASS: FETCH state outputs - all control signals zero, alu_op=00");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: FETCH state outputs - pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_op=%b",
                      pc_write, ir_write, reg_write, mem_write, alu_op);
            fail_count = fail_count + 1;
        end

        // ----- TEST 4: IF_ID state -----
        // After FETCH->IF_ID, state=IF_ID. Need opcode that keeps us or moves forward.
        // IF_ID: ir_write=1, reg_write=1, mem_write=1, alu_src_a=1, alu_src_b=1, mem_to_reg=1, alu_op=00
        // To reach IF_ID, the FSM went IDLE->FETCH->IF_ID automatically (combinational chaining)
        // With current opcode=7'b11000101, IDLE triggers FETCH, FETCH triggers IF_ID,
        // IF_ID checks: opcode!=7'b11000111 so stays IF_ID... combinationally loops
        // Let's set a neutral opcode for IF_ID and check outputs
        opcode = 7'b0000001; // not 7'b11000111, so stays in IF_ID
        #2;
        // State chains: IDLE(opcode=0000001 -> stay IDLE) or depends on where we are
        // This is a purely combinational FSM - state = next_state instantly
        // Starting from IDLE with opcode=0000001: stays IDLE
        // Outputs: IDLE defaults (alu_op=2'b10, all others 0)
        if (pc_write === 0 && ir_write === 0 && reg_write === 0 && mem_write === 0 &&
            alu_op === 2'b10) begin
            $display("PASS: IDLE with neutral opcode - default control signals");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: IDLE with neutral opcode - pc_write=%b ir_write=%b reg_write=%b alu_op=%b",
                      pc_write, ir_write, reg_write, alu_op);
            fail_count = fail_count + 1;
        end

        // ----- TEST 5: Simulate ADD instruction execution (all 5 phases) -----
        // ADD opcode = 7'h33 = 7'b0110011
        // FSM is combinational; let's trace the auto-chaining behavior
        // Trigger IDLE->FETCH->IF_ID->... 
        // First trigger IDLE with 7'b11000101
        opcode = 7'b11000101;
        #1;
        // IDLE sees 7'b11000101 -> next=FETCH -> FETCH next=IF_ID -> IF_ID(opcode!=7'b11000111)->stay
        // So combinationally we end up at IF_ID
        // Now set to ADD opcode
        opcode = 7'h33; // 7'b0110011
        #2;
        // state=IF_ID with opcode=7'h33 (not 7'b11000111): stays IF_ID
        // IF_ID outputs: ir_write=1, reg_write=1, mem_write=1, alu_src_a=1, alu_src_b=1, mem_to_reg=1, alu_op=00
        if (ir_write === 1 && reg_write === 1 && mem_write === 1 &&
            alu_src_a === 1 && alu_src_b === 1 && mem_to_reg === 1 && alu_op === 2'b00) begin
            $display("PASS: ADD instruction in IF_ID phase - ir_write, reg_write, mem_write asserted");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: ADD instruction in IF_ID phase - ir_write=%b reg_write=%b mem_write=%b alu_op=%b",
                      ir_write, reg_write, mem_write, alu_op);
            fail_count = fail_count + 1;
        end

        // ----- TEST 6: LW instruction -----
        // LW opcode = 7'h03 = 7'b0000011
        opcode = 7'b11000101; // trigger into chain first
        #1;
        opcode = 7'h03; // LW
        #2;
        // state=IF_ID with LW opcode (not 7'b11000111): stays IF_ID
        // IF_ID outputs active
        if (ir_write === 1 && reg_write === 1 && mem_write === 1 && alu_op === 2'b00) begin
            $display("PASS: LW instruction in IF_ID phase - correct memory-related signals");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: LW instruction in IF_ID phase - ir_write=%b reg_write=%b alu_op=%b",
                      ir_write, reg_write, alu_op);
            fail_count = fail_count + 1;
        end

        // ----- TEST 7: SW instruction -----
        // SW opcode = 7'h23 = 7'b0100011
        opcode = 7'b11000101;
        #1;
        opcode = 7'h23; // SW
        #2;
        if (ir_write === 1 && mem_write === 1 && reg_write === 1 && alu_op === 2'b00) begin
            $display("PASS: SW instruction in IF_ID phase - mem_write asserted for store");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: SW instruction in IF_ID phase - ir_write=%b mem_write=%b reg_write=%b alu_op=%b",
                      ir_write, mem_write, reg_write, alu_op);
            fail_count = fail_count + 1;
        end

        // ----- TEST 8: BEQ instruction with zero=1 (rs1==rs2) -----
        // BEQ opcode = 7'h63 = 7'b1100011
        opcode = 7'b11000101;
        zero = 1;
        #1;
        opcode = 7'h63; // BEQ
        #2;
        // state=IF_ID with BEQ; stays IF_ID since BEQ != 7'b11000111
        // IF_ID outputs active; zero=1
        if (ir_write === 1 && reg_write === 1 && alu_op === 2'b00 && zero === 1) begin
            $display("PASS: BEQ instruction with zero=1 (rs1==rs2) in IF_ID phase");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: BEQ instruction with zero=1 - ir_write=%b reg_write=%b alu_op=%b zero=%b",
                      ir_write, reg_write, alu_op, zero);
            fail_count = fail_count + 1;
        end

        // ----- TEST 9: All-zeros opcode -----
        opcode = 7'b0000000;
        funct3 = 3'b000;
        zero   = 0;
        #2;
        if (pc_write === 0 && ir_write === 0 && reg_write === 0 && mem_write === 0 &&
            alu_src_a === 0 && alu_src_b === 0 && mem_to_reg === 0 && pc_source === 0 &&
            alu_op === 2'b10) begin
            $display("PASS: All-zeros opcode - IDLE state, all control signals default");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: All-zeros opcode - unexpected output. alu_op=%b pc_write=%b", alu_op, pc_write);
            fail_count = fail_count + 1;
        end

        // ----- TEST 10: All-ones opcode -----
        opcode = 7'b1111111;
        funct3 = 3'b111;
        zero   = 1;
        #2;
        // opcode=7'b1111111 is not 7'b11000101, so IDLE stays IDLE, all defaults
        if (pc_write === 0 && ir_write === 0 && reg_write === 0 && mem_write === 0 &&
            alu_src_a === 0 && alu_src_b === 0 && mem_to_reg === 0 && pc_source === 0 &&
            alu_op === 2'b10) begin
            $display("PASS: All-ones opcode - IDLE state, all control signals default");
            pass_count = pass_count + 1;
        end else begin
            $display("FAIL: All-ones opcode - unexpected output. alu_op=%b pc_write=%b", alu_
