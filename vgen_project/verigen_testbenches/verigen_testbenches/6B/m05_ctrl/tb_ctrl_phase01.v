`timescale 1ns/1ps

module tb_ctrl_phase01;

    // DUT connections
    reg  [6:0] opcode;
    reg  [2:0] phase;
    wire       pc_write, ir_write, reg_write, mem_write;
    wire       alu_src_a, alu_src_b, mem_to_reg, pc_source;

    // Clock and reset (not used by combinational DUT, but required by rules)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    ctrl_phase01 uut (
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

    // Expected outputs
    reg exp_pc_write, exp_ir_write, exp_reg_write, exp_mem_write;
    reg exp_alu_src_a, exp_alu_src_b, exp_mem_to_reg, exp_pc_source;

    integer fail_count;

    // Task to check outputs
    task check_outputs;
        input [63:0] desc_unused; // placeholder
        input [6:0]  op;
        input [2:0]  ph;
        input        e_pc_write, e_ir_write, e_reg_write, e_mem_write;
        input        e_alu_src_a, e_alu_src_b, e_mem_to_reg, e_pc_source;
        input [127:0] desc;
        begin
            if (pc_write  !== e_pc_write  ||
                ir_write  !== e_ir_write  ||
                reg_write !== e_reg_write ||
                mem_write !== e_mem_write ||
                alu_src_a !== e_alu_src_a ||
                alu_src_b !== e_alu_src_b ||
                mem_to_reg!== e_mem_to_reg||
                pc_source !== e_pc_source) begin
                $display("FAIL: opcode=%h phase=%0d pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b (expected pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b)",
                    op, ph,
                    pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source,
                    e_pc_write, e_ir_write, e_reg_write, e_mem_write, e_alu_src_a, e_alu_src_b, e_mem_to_reg, e_pc_source);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: opcode=%h phase=%0d -> pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                    op, ph,
                    pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);
            end
        end
    endtask

    // Simpler task using current opcode/phase
    task apply_and_check;
        input [6:0]  op;
        input [2:0]  ph;
        input        e_pc_write, e_ir_write, e_reg_write, e_mem_write;
        input        e_alu_src_a, e_alu_src_b, e_mem_to_reg, e_pc_source;
        begin
            opcode = op;
            phase  = ph;
            #2; // combinational settle
            if (pc_write  !== e_pc_write  ||
                ir_write  !== e_ir_write  ||
                reg_write !== e_reg_write ||
                mem_write !== e_mem_write ||
                alu_src_a !== e_alu_src_a ||
                alu_src_b !== e_alu_src_b ||
                mem_to_reg!== e_mem_to_reg||
                pc_source !== e_pc_source) begin
                $display("FAIL: opcode=7'h%02h phase=%0d: got {%b,%b,%b,%b,%b,%b,%b,%b} expected {%b,%b,%b,%b,%b,%b,%b,%b}",
                    op, ph,
                    pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source,
                    e_pc_write, e_ir_write, e_reg_write, e_mem_write, e_alu_src_a, e_alu_src_b, e_mem_to_reg, e_pc_source);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: opcode=7'h%02h phase=%0d -> {pc_wr=%b ir_wr=%b rg_wr=%b mm_wr=%b alu_a=%b alu_b=%b m2r=%b pcsrc=%b}",
                    op, ph,
                    pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);
            end
            #3; // complete 5ns half-period
        end
    endtask

    integer i;

    initial begin
        fail_count = 0;
        opcode = 7'h00;
        phase  = 3'h0;
        rst    = 1;

        // Assert reset for 5 rising edges
        repeat(5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // ---------------------------------------------------------------
        // The module ctrl_phase01 is purely combinational and ignores opcode.
        // Behavior:
        //   phase==0: pc_write=1, ir_write=1, reg_write=1, mem_write=0,
        //             alu_src_a=0, alu_src_b=0, mem_to_reg=0, pc_source=0
        //   phase==1: pc_write=0, ir_write=0, reg_write=0, mem_write=1,
        //             alu_src_a=0, alu_src_b=1, mem_to_reg=1, pc_source=1
        //   phase>=2: pc_write=0, ir_write=0, reg_write=0, mem_write=0,
        //             alu_src_a=1, alu_src_b=0, mem_to_reg=0, pc_source=0
        // ---------------------------------------------------------------

        // Test 1: phase=0, opcode=7'h33 (R-type)
        apply_and_check(7'h33, 3'd0,  1,1,1,0, 0,0,0,0);

        // Test 2: phase=1, opcode=7'h33 (R-type)
        apply_and_check(7'h33, 3'd1,  0,0,0,1, 0,1,1,1);

        // Test 3: phase=2, opcode=7'h33 (R-type)
        apply_and_check(7'h33, 3'd2,  0,0,0,0, 1,0,0,0);

        // Test 4: phase=0, opcode=7'h13 (I-type ALU)
        apply_and_check(7'h13, 3'd0,  1,1,1,0, 0,0,0,0);

        // Test 5: phase=1, opcode=7'h13 (I-type ALU)
        apply_and_check(7'h13, 3'd1,  0,0,0,1, 0,1,1,1);

        // Test 6: phase=3, opcode=7'h03 (Load)
        apply_and_check(7'h03, 3'd3,  0,0,0,0, 1,0,0,0);

        // Test 7: phase=4, opcode=7'h23 (Store)
        apply_and_check(7'h23, 3'd4,  0,0,0,0, 1,0,0,0);

        // Test 8: phase=0, opcode=7'h63 (Branch)
        apply_and_check(7'h63, 3'd0,  1,1,1,0, 0,0,0,0);

        // Test 9: phase=1, opcode=7'h63 (Branch)
        apply_and_check(7'h63, 3'd1,  0,0,0,1, 0,1,1,1);

        // Test 10: phase=2, opcode=7'h63 (Branch)
        apply_and_check(7'h63, 3'd2,  0,0,0,0, 1,0,0,0);

        // Test 11: phase=0, all-zero opcode
        apply_and_check(7'h00, 3'd0,  1,1,1,0, 0,0,0,0);

        // Test 12: phase=1, all-zero opcode
        apply_and_check(7'h00, 3'd1,  0,0,0,1, 0,1,1,1);

        // Test 13: phase=2, all-zero opcode (undefined opcode -> else branch)
        apply_and_check(7'h00, 3'd2,  0,0,0,0, 1,0,0,0);

        // Test 14: phase=0, all-ones opcode (7'h7f)
        apply_and_check(7'h7f, 3'd0,  1,1,1,0, 0,0,0,0);

        // Test 15: phase=1, all-ones opcode
        apply_and_check(7'h7f, 3'd1,  0,0,0,1, 0,1,1,1);

        // Test 16: phase=3, opcode=7'h03 (Load, phase>=2)
        apply_and_check(7'h03, 3'd3,  0,0,0,0, 1,0,0,0);

        // Test 17: phase=4, opcode=7'h63 (Branch, phase>=2)
        apply_and_check(7'h63, 3'd4,  0,0,0,0, 1,0,0,0);

        // Test 18: Verify pc_write only asserts in phase==0
        // phase=5 (>=2 -> else)
        apply_and_check(7'h13, 3'd5,  0,0,0,0, 1,0,0,0);

        // Test 19: phase=6
        apply_and_check(7'h23, 3'd6,  0,0,0,0, 1,0,0,0);

        // Test 20: phase=7
        apply_and_check(7'h7f, 3'd7,  0,0,0,0, 1,0,0,0);

        // Summary
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
