`timescale 1ns/1ps

module tb_ctrl_phase234;

    // DUT inputs
    reg [6:0] opcode;
    reg [2:0] phase;
    reg       clk;
    reg       rst;

    // DUT outputs
    wire pc_write, ir_write, reg_write, mem_write;
    wire alu_src_a, alu_src_b, mem_to_reg, pc_source;

    // Instantiate DUT
    ctrl_phase234 uut (
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

    // Task for checking outputs
    task check_outputs;
        input [6:0] t_opcode;
        input [2:0] t_phase;
        input       exp_pc_write, exp_ir_write, exp_reg_write, exp_mem_write;
        input       exp_alu_src_a, exp_alu_src_b, exp_mem_to_reg, exp_pc_source;
        input [63:0] test_num;
        reg pass;
        begin
            pass = 1;
            if (pc_write   !== exp_pc_write)   pass = 0;
            if (ir_write   !== exp_ir_write)   pass = 0;
            if (reg_write  !== exp_reg_write)  pass = 0;
            if (mem_write  !== exp_mem_write)  pass = 0;
            if (alu_src_a  !== exp_alu_src_a)  pass = 0;
            if (alu_src_b  !== exp_alu_src_b)  pass = 0;
            if (mem_to_reg !== exp_mem_to_reg) pass = 0;
            if (pc_source  !== exp_pc_source)  pass = 0;

            if (pass)
                $display("PASS: Test %0d opcode=7'h%02h phase=%0d -> pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                    test_num, t_opcode, t_phase,
                    pc_write, ir_write, reg_write, mem_write,
                    alu_src_a, alu_src_b, mem_to_reg, pc_source);
            else
                $display("FAIL: Test %0d opcode=7'h%02h phase=%0d -> got pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b, expected pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                    test_num, t_opcode, t_phase,
                    pc_write, ir_write, reg_write, mem_write,
                    alu_src_a, alu_src_b, mem_to_reg, pc_source,
                    exp_pc_write, exp_ir_write, exp_reg_write, exp_mem_write,
                    exp_alu_src_a, exp_alu_src_b, exp_mem_to_reg, exp_pc_source);
        end
    endtask

    integer i;

    initial begin
        // Initialize
        opcode = 7'h00;
        phase  = 3'b000;
        rst    = 1;

        // Assert reset for 5 rising edges
        repeat(5) @(posedge clk);
        rst = 0;

        // Small delay after reset
        #2;

        // =====================================================================
        // Test 1: phase=000 (default all zeros), any opcode
        // =====================================================================
        opcode = 7'h33; phase = 3'b000; #2;
        check_outputs(opcode, phase,
            0,0,0,0, 0,0,0,0, 1);

        // =====================================================================
        // Test 2: phase=001 -> pc_write=1, pc_source=1
        // =====================================================================
        opcode = 7'h33; phase = 3'b001; #2;
        check_outputs(opcode, phase,
            1,0,0,0, 0,0,0,1, 2);

        // =====================================================================
        // Test 3: phase=010 -> ir_write=1
        // =====================================================================
        opcode = 7'h13; phase = 3'b010; #2;
        check_outputs(opcode, phase,
            0,1,0,0, 0,0,0,0, 3);

        // =====================================================================
        // Test 4: phase=011 -> reg_write=1
        // =====================================================================
        opcode = 7'h03; phase = 3'b011; #2;
        check_outputs(opcode, phase,
            0,0,1,0, 0,0,0,0, 4);

        // =====================================================================
        // Test 5: phase=100 -> mem_write=1
        // =====================================================================
        opcode = 7'h23; phase = 3'b100; #2;
        check_outputs(opcode, phase,
            0,0,0,1, 0,0,0,0, 5);

        // =====================================================================
        // Test 6: phase=101 -> mem_to_reg=1
        // =====================================================================
        opcode = 7'h63; phase = 3'b101; #2;
        check_outputs(opcode, phase,
            0,0,0,0, 0,0,1,0, 6);

        // =====================================================================
        // Test 7: phase=110 -> pc_source=1
        // =====================================================================
        opcode = 7'h33; phase = 3'b110; #2;
        check_outputs(opcode, phase,
            0,0,0,0, 0,0,0,1, 7);

        // =====================================================================
        // Test 8: phase=111 -> pc_source=1
        // =====================================================================
        opcode = 7'h63; phase = 3'b111; #2;
        check_outputs(opcode, phase,
            0,0,0,0, 0,0,0,1, 8);

        // =====================================================================
        // Test 9: All-zero opcode, phase=000
        // =====================================================================
        opcode = 7'h00; phase = 3'b000; #2;
        check_outputs(opcode, phase,
            0,0,0,0, 0,0,0,0, 9);

        // =====================================================================
        // Test 10: All-ones opcode (7'h7f), phase=001
        // =====================================================================
        opcode = 7'h7f; phase = 3'b001; #2;
        check_outputs(opcode, phase,
            1,0,0,0, 0,0,0,1, 10);

        // =====================================================================
        // Test 11: Undefined opcode with phase=010
        // =====================================================================
        opcode = 7'h55; phase = 3'b010; #2;
        check_outputs(opcode, phase,
            0,1,0,0, 0,0,0,0, 11);

        // =====================================================================
        // Test 12: opcode=7'h13 (I-type), phase=011
        // =====================================================================
        opcode = 7'h13; phase = 3'b011; #2;
        check_outputs(opcode, phase,
            0,0,1,0, 0,0,0,0, 12);

        // =====================================================================
        // Test 13: opcode=7'h03 (load), phase=101
        // =====================================================================
        opcode = 7'h03; phase = 3'b101; #2;
        check_outputs(opcode, phase,
            0,0,0,0, 0,0,1,0, 13);

        // =====================================================================
        // Test 14: opcode=7'h23 (store), phase=100
        // =====================================================================
        opcode = 7'h23; phase = 3'b100; #2;
        check_outputs(opcode, phase,
            0,0,0,1, 0,0,0,0, 14);

        // =====================================================================
        // Test 15: opcode=7'h63 (branch), phase=110
        // =====================================================================
        opcode = 7'h63; phase = 3'b110; #2;
        check_outputs(opcode, phase,
            0,0,0,0, 0,0,0,1, 15);

        // =====================================================================
        // Test 16: Verify pc_write NOT asserted in phase=010
        // =====================================================================
        opcode = 7'h33; phase = 3'b010; #2;
        check_outputs(opcode, phase,
            0,1,0,0, 0,0,0,0, 16);

        // =====================================================================
        // Test 17: Verify pc_write NOT asserted in phase=011
        // =====================================================================
        opcode = 7'h33; phase = 3'b011; #2;
        check_outputs(opcode, phase,
            0,0,1,0, 0,0,0,0, 17);

        // =====================================================================
        // Test 18: Verify pc_write NOT asserted in phase=100
        // =====================================================================
        opcode = 7'h33; phase = 3'b100; #2;
        check_outputs(opcode, phase,
            0,0,0,1, 0,0,0,0, 18);

        // =====================================================================
        // Test 19: Sweep all phases with opcode=7'h33
        // =====================================================================
        begin : sweep_phase
            reg [2:0] ph;
            for (ph = 0; ph <= 7; ph = ph + 1) begin
                opcode = 7'h33; phase = ph; #2;
                case(ph)
                    3'b000: check_outputs(opcode, ph, 0,0,0,0, 0,0,0,0, 100+ph);
                    3'b001: check_outputs(opcode, ph, 1,0,0,0, 0,0,0,1, 100+ph);
                    3'b010: check_outputs(opcode, ph, 0,1,0,0, 0,0,0,0, 100+ph);
                    3'b011: check_outputs(opcode, ph, 0,0,1,0, 0,0,0,0, 100+ph);
                    3'b100: check_outputs(opcode, ph, 0,0,0,1, 0,0,0,0, 100+ph);
                    3'b101: check_outputs(opcode, ph, 0,0,0,0, 0,0,1,0, 100+ph);
                    3'b110: check_outputs(opcode, ph, 0,0,0,0, 0,0,0,1, 100+ph);
                    3'b111: check_outputs(opcode, ph, 0,0,0,0, 0,0,0,1, 100+ph);
                endcase
            end
        end

        // =====================================================================
        // Test 20: Sweep all phases with opcode=7'h7f (max)
        // =====================================================================
        begin : sweep_phase_max
            reg [2:0] ph2;
            for (ph2 = 0; ph2 <= 7; ph2 = ph2 + 1) begin
                opcode = 7'h7f; phase = ph2; #2;
                case(ph2)
                    3'b000: check_outputs(opcode, ph2, 0,0,0,0, 0,0,0,0, 200+ph2);
                    3'b001: check_outputs(opcode, ph2, 1,0,0,0, 0,0,0,1, 200+ph2);
                    3'b010: check_outputs(opcode, ph2, 0,1,0,0, 0,0,0,0, 200+ph2);
                    3'b011: check_outputs(opcode, ph2, 0,0,1,0, 0,0,0,0, 200+ph2);
                    3'b100: check_outputs(opcode, ph2, 0,0,0,1, 0,0,0,0, 200+ph2);
                    3'b101: check_outputs(opcode, ph2, 0,0,0,0, 0,0,1,0, 200+ph2);
                    3'b110: check_outputs(opcode, ph2, 0,0,0,0, 0,0,0,1, 200+ph2);
                    3'b111: check_outputs(opcode, ph2, 0,0,0,0, 0,0,0,1, 200+ph2);
                endcase
            end
        end

        #10;
        $finish;
    end

endmodule
