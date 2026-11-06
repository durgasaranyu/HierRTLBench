`timescale 1ns/1ps

module tb_ctrl_phase234;

    // DUT inputs
    reg [6:0] opcode;
    reg [2:0] phase;

    // DUT outputs
    wire pc_write;
    wire ir_write;
    wire reg_write;
    wire mem_write;
    wire alu_src_a;
    wire alu_src_b;
    wire mem_to_reg;
    wire pc_source;

    // Clock and reset (not used by combinational DUT but required by spec)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    ctrl_phase234 uut (
        .opcode   (opcode),
        .phase    (phase),
        .pc_write (pc_write),
        .ir_write (ir_write),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .mem_to_reg(mem_to_reg),
        .pc_source(pc_source)
    );

    integer failed;

    // Task to check expected outputs
    // According to the module, for ALL phases (0-7), the output is always:
    // pc_write=0, ir_write=1, reg_write=0, mem_write=0,
    // alu_src_a=0, alu_src_b=0, mem_to_reg=0, pc_source=0
    task check_outputs;
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
        input [63:0] desc1;
        input [63:0] desc2;
        begin
            if (pc_write   === exp_pc_write   &&
                ir_write   === exp_ir_write   &&
                reg_write  === exp_reg_write  &&
                mem_write  === exp_mem_write  &&
                alu_src_a  === exp_alu_src_a  &&
                alu_src_b  === exp_alu_src_b  &&
                mem_to_reg === exp_mem_to_reg &&
                pc_source  === exp_pc_source) begin
                $display("PASS: opcode=%b phase=%0d %s%s", t_opcode, t_phase, desc1, desc2);
            end else begin
                $display("FAIL: opcode=%b phase=%0d %s%s | got pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b | exp pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                    t_opcode, t_phase, desc1, desc2,
                    pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source,
                    exp_pc_write, exp_ir_write, exp_reg_write, exp_mem_write, exp_alu_src_a, exp_alu_src_b, exp_mem_to_reg, exp_pc_source);
                failed = failed + 1;
            end
        end
    endtask

    initial begin
        failed = 0;
        rst = 1;

        // Assert reset for 5 rising edges
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        #2; // small delay after reset

        // The DUT is purely combinational. All phases (0-7) produce same output:
        // pc_write=0, ir_write=1, reg_write=0, mem_write=0,
        // alu_src_a=0, alu_src_b=0, mem_to_reg=0, pc_source=0

        // Test 1: opcode=7'h33 (R-type), phase=2 (EX)
        opcode = 7'h33; phase = 3'd2; #2;
        check_outputs(opcode, phase, 0,1,0,0,0,0,0,0, "opcode=h33 ", "phase=2(EX)");

        // Test 2: opcode=7'h33, phase=3 (MEM)
        opcode = 7'h33; phase = 3'd3; #2;
        check_outputs(opcode, phase, 0,1,0,0,0,0,0,0, "opcode=h33 ", "phase=3(MEM)");

        // Test 3: opcode=7'h33, phase=4 (WB)
        opcode = 7'h33; phase = 3'd4; #2;
        check_outputs(opcode, phase, 0,1,0,0,0,0,0,0, "opcode=h33 ", "phase=4(WB)");

        // Test 4: opcode=7'h13 (I-type ALU), phase=2
        opcode = 7'h13; phase = 3'd2; #2;
        check_outputs(opcode, phase, 0,1,0,0,0,0,0,0, "opcode=h13 ", "phase=2(EX)");

        // Test 5: opcode=7'h03 (Load), phase=3
        opcode = 7'h03; phase = 3'd3; #2;
        check_outputs(opcode, phase, 0,1,0,0,0,0,0,0, "opcode=h03 ", "phase=3(MEM)");

        // Test 6: opcode=7'h23 (Store), phase=3
        opcode = 7'h23; phase = 3'd3; #2;
        check_outputs(opcode, phase, 0,1,0,0,0,0,0,0, "opcode=h23 ", "phase=3(MEM)");

        // Test 7: opcode=7'h63 (Branch), phase=2
        opcode = 7'h63; phase = 3'd2; #2;
        check_outputs(opcode, phase, 0,1,0,0,0,0,0,0, "opcode=h63 ", "phase=2(EX)");

        // Test 8: opcode=7'h63, phase=4 (WB)
        opcode = 7'h63; phase = 3'd4; #2;
        check_outputs(opcode, phase, 0,1,0,0,0,0,0,0, "opcode=h63 ", "phase=4(WB)");

        // Test 9: all-zero opcode, phase=0
        opcode = 7'h00; phase = 3'd0; #2;
        check_outputs(opcode, phase, 0,1,0,0,0,0,0,0, "opcode=h00 ", "phase=0");

        // Test 10: all-zero opcode, phase=1
        opcode = 7'h00; phase = 3'd1; #2;
        check_outputs(opcode, phase, 0,1,0,0,0,0,0,0, "opcode=h00 ", "phase=1");

        // Test 11: all-ones opcode (7'h7f), phase=0
        opcode = 7'h7f; phase = 3'd0; #2;
        check_outputs(opcode, phase, 0,1,0,0,0,0,0,0, "opcode=h7f ", "phase=0");

        // Test 12: all-ones opcode, phase=7
        opcode = 7'h7f; phase = 3'd7; #2;
        check_outputs(opcode, phase, 0,1,0,0,0,0,0,0, "opcode=h7f ", "phase=7");

        // Test 13: opcode=7'h03 (Load), phase=4 (WB)
        opcode = 7'h03; phase = 3'd4; #2;
        check_outputs(opcode, phase, 0,1,0,0,0,0,0,0, "opcode=h03 ", "phase=4(WB)");

        // Test 14: opcode=7'h13, phase=4 (WB)
        opcode = 7'h13; phase = 3'd4; #2;
        check_outputs(opcode, phase, 0,1,0,0,0,0,0,0, "opcode=h13 ", "phase=4(WB)");

        // Test 15: opcode=7'h23, phase=4 (WB)
        opcode = 7'h23; phase = 3'd4; #2;
        check_outputs(opcode, phase, 0,1,0,0,0,0,0,0, "opcode=h23 ", "phase=4(WB)");

        // Test 16: opcode=7'h63, phase=3 (MEM)
        opcode = 7'h63; phase = 3'd3; #2;
        check_outputs(opcode, phase, 0,1,0,0,0,0,0,0, "opcode=h63 ", "phase=3(MEM)");

        // Test 17: max opcode, phase=5
        opcode = 7'h7f; phase = 3'd5; #2;
        check_outputs(opcode, phase, 0,1,0,0,0,0,0,0, "opcode=h7f ", "phase=5");

        // Test 18: max opcode, phase=6
        opcode = 7'h7f; phase = 3'd6; #2;
        check_outputs(opcode, phase, 0,1,0,0,0,0,0,0, "opcode=h7f ", "phase=6");

        // Verify pc_write never asserts (for all tested cases)
        // Already verified above implicitly; add explicit check
        if (pc_write !== 0) begin
            $display("FAIL: pc_write should never assert but it is 1");
            failed = failed + 1;
        end else begin
            $display("PASS: pc_write never asserted across all tests");
        end

        if (failed == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("%0d TEST(S) FAILED", failed);
        end

        $finish;
    end

endmodule
