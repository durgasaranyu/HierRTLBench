`timescale 1ns/1ps

module tb_m05_ctrl_integration;

    // DUT inputs
    reg [6:0] opcode;
    reg [2:0] phase;
    reg       clk;
    reg       rst;

    // DUT outputs
    wire pc_write, ir_write, reg_write, mem_write;
    wire alu_src_a, alu_src_b, mem_to_reg, pc_source;

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

    // Test tracking
    integer pass_count;
    integer fail_count;
    integer test_num;

    // Expected outputs storage
    reg exp_pc_write, exp_ir_write, exp_reg_write, exp_mem_write;

    // Task to check and report results
    task check_outputs;
        input [63:0] test_id;
        input [6:0]  t_opcode;
        input [2:0]  t_phase;
        input        e_pc_write;
        input        e_ir_write;
        input        e_reg_write;
        input        e_mem_write;
        begin
            #1; // Small delay for combinational settling
            if (pc_write  === e_pc_write  &&
                ir_write  === e_ir_write  &&
                reg_write === e_reg_write &&
                mem_write === e_mem_write) begin
                $display("PASS: Test %0d - opcode=%7b phase=%0d pc_write=%b ir_write=%b reg_write=%b mem_write=%b",
                    test_id, t_opcode, t_phase, pc_write, ir_write, reg_write, mem_write);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test %0d - opcode=%7b phase=%0d | Got: pc_write=%b ir_write=%b reg_write=%b mem_write=%b | Expected: pc_write=%b ir_write=%b reg_write=%b mem_write=%b",
                    test_id, t_opcode, t_phase,
                    pc_write, ir_write, reg_write, mem_write,
                    e_pc_write, e_ir_write, e_reg_write, e_mem_write);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Representative opcodes to test with
    // We'll test multiple opcodes across all 5 phases (0-4)
    reg [6:0] test_opcodes [0:7];
    integer i, j;

    initial begin
        pass_count = 0;
        fail_count = 0;
        test_num   = 0;

        // Initialize inputs
        opcode = 7'b0000000;
        phase  = 3'd0;

        // Apply synchronous reset for 5 rising clock edges
        // (We don't have a reset pin on this combinational module,
        //  but we hold inputs stable and wait)
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        // Setup test opcodes
        test_opcodes[0] = 7'b0000000;
        test_opcodes[1] = 7'b0000001;
        test_opcodes[2] = 7'b0100000;
        test_opcodes[3] = 7'b0100011;
        test_opcodes[4] = 7'b1100011;
        test_opcodes[5] = 7'b1101111;
        test_opcodes[6] = 7'b1111111;
        test_opcodes[7] = 7'b0110011;

        // Test Phase 0 (default): pc_write=0, ir_write=0, reg_write=0, mem_write=0
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge clk);
            opcode   = test_opcodes[i];
            phase    = 3'd0;
            test_num = test_num + 1;
            check_outputs(test_num, opcode, phase, 1'b0, 1'b0, 1'b0, 1'b0);
        end

        // Test Phase 1: pc_write=1, ir_write=0, reg_write=0, mem_write=0
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge clk);
            opcode   = test_opcodes[i];
            phase    = 3'd1;
            test_num = test_num + 1;
            check_outputs(test_num, opcode, phase, 1'b1, 1'b0, 1'b0, 1'b0);
        end

        // Test Phase 2: pc_write=0, ir_write=1, reg_write=0, mem_write=0
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge clk);
            opcode   = test_opcodes[i];
            phase    = 3'd2;
            test_num = test_num + 1;
            check_outputs(test_num, opcode, phase, 1'b0, 1'b1, 1'b0, 1'b0);
        end

        // Test Phase 3: pc_write=0, ir_write=0, reg_write=1, mem_write=0
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge clk);
            opcode   = test_opcodes[i];
            phase    = 3'd3;
            test_num = test_num + 1;
            check_outputs(test_num, opcode, phase, 1'b0, 1'b0, 1'b1, 1'b0);
        end

        // Test Phase 4: pc_write=0, ir_write=0, reg_write=0, mem_write=1
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge clk);
            opcode   = test_opcodes[i];
            phase    = 3'd4;
            test_num = test_num + 1;
            check_outputs(test_num, opcode, phase, 1'b0, 1'b0, 1'b0, 1'b1);
        end

        // Test Phase 5,6,7 (default): pc_write=0, ir_write=0, reg_write=0, mem_write=0
        for (j = 5; j <= 7; j = j + 1) begin
            for (i = 0; i < 4; i = i + 1) begin
                @(posedge clk);
                opcode   = test_opcodes[i];
                phase    = j[2:0];
                test_num = test_num + 1;
                check_outputs(test_num, opcode, phase, 1'b0, 1'b0, 1'b0, 1'b0);
            end
        end

        // Additional boundary tests: sweep all phases with opcode=7'h7F
        @(posedge clk);
        opcode = 7'h7F;
        phase  = 3'd0;
        test_num = test_num + 1;
        check_outputs(test_num, opcode, phase, 1'b0, 1'b0, 1'b0, 1'b0);

        @(posedge clk);
        opcode = 7'h7F;
        phase  = 3'd1;
        test_num = test_num + 1;
        check_outputs(test_num, opcode, phase, 1'b1, 1'b0, 1'b0, 1'b0);

        @(posedge clk);
        opcode = 7'h7F;
        phase  = 3'd2;
        test_num = test_num + 1;
        check_outputs(test_num, opcode, phase, 1'b0, 1'b1, 1'b0, 1'b0);

        @(posedge clk);
        opcode = 7'h7F;
        phase  = 3'd3;
        test_num = test_num + 1;
        check_outputs(test_num, opcode, phase, 1'b0, 1'b0, 1'b1, 1'b0);

        @(posedge clk);
        opcode = 7'h7F;
        phase  = 3'd4;
        test_num = test_num + 1;
        check_outputs(test_num, opcode, phase, 1'b0, 1'b0, 1'b0, 1'b1);

        // Additional boundary: opcode=7'h00, all phases
        @(posedge clk);
        opcode = 7'h00;
        phase  = 3'd1;
        test_num = test_num + 1;
        check_outputs(test_num, opcode, phase, 1'b1, 1'b0, 1'b0, 1'b0);

        @(posedge clk);
        opcode = 7'h00;
        phase  = 3'd2;
        test_num = test_num + 1;
        check_outputs(test_num, opcode, phase, 1'b0, 1'b1, 1'b0, 1'b0);

        @(posedge clk);
        opcode = 7'h00;
        phase  = 3'd3;
        test_num = test_num + 1;
        check_outputs(test_num, opcode, phase, 1'b0, 1'b0, 1'b1, 1'b0);

        @(posedge clk);
        opcode = 7'h00;
        phase  = 3'd4;
        test_num = test_num + 1;
        check_outputs(test_num, opcode, phase, 1'b0, 1'b0, 1'b0, 1'b1);

        @(posedge clk);
        opcode = 7'h00;
        phase  = 3'd0;
        test_num = test_num + 1;
        check_outputs(test_num, opcode, phase, 1'b0, 1'b0, 1'b0, 1'b0);

        // Transition test: phase 4 -> phase 1 -> phase 2
        @(posedge clk);
        opcode = 7'b0110011;
        phase  = 3'd4;
        test_num = test_num + 1;
        check_outputs(test_num, opcode, phase, 1'b0, 1'b0, 1'b0, 1'b1);

        @(posedge clk);
        opcode = 7'b0110011;
        phase  = 3'd1;
        test_num = test_num + 1;
        check_outputs(test_num, opcode, phase, 1'b1, 1'b0, 1'b0, 1'b0);

        @(posedge clk);
        opcode = 7'b0110011;
        phase  = 3'd2;
        test_num = test_num + 1;
        check_outputs(test_num, opcode, phase, 1'b0, 1'b1, 1'b0, 1'b0);

        // Summary
        $display("======================================");
        $display("Integration Test Summary: %0d PASSED, %0d FAILED out of %0d tests",
                 pass_count, fail_count, test_num);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $display("======================================");

        $finish;
    end

endmodule
