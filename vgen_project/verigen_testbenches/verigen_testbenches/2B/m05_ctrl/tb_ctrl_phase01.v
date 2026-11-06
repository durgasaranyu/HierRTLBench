`timescale 1ns/1ps

module tb_ctrl_phase01;

    // DUT inputs
    reg [6:0] opcode;
    reg [2:0] phase;

    // DUT outputs
    wire pc_write, ir_write, reg_write, mem_write;
    wire alu_src_a, alu_src_b, mem_to_reg, pc_source;

    // Clock and reset (not used by combinational DUT, but required by spec)
    reg clk, rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Reset for 5 rising edges
    integer i;
    initial begin
        rst = 1;
        for (i = 0; i < 5; i = i + 1)
            @(posedge clk);
        rst = 0;
    end

    // Instantiate DUT
    ctrl_phase01 uut (
        .opcode(opcode),
        .phase(phase),
        .pc_write(pc_write),
        .ir_write(ir_write),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .mem_to_reg(mem_to_reg),
        .pc_source(pc_source)
    );

    // Task to check all outputs are zero
    task check_all_zero;
        input [6:0] op;
        input [2:0] ph;
        input [63:0] desc_num; // used to differentiate
        begin
            // All outputs should be 0 for this module
            if (pc_write === 0 && ir_write === 0 && reg_write === 0 &&
                mem_write === 0 && alu_src_a === 0 && alu_src_b === 0 &&
                mem_to_reg === 0 && pc_source === 0) begin
                $display("PASS: opcode=0x%02h phase=%0d all outputs zero", op, ph);
            end else begin
                $display("FAIL: opcode=0x%02h phase=%0d expected all zeros, got pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                    op, ph, pc_write, ir_write, reg_write, mem_write,
                    alu_src_a, alu_src_b, mem_to_reg, pc_source);
            end
        end
    endtask

    integer j;

    initial begin
        // Wait for reset to complete
        @(negedge rst);
        #2;

        // Test Vector 1: opcode=7'h33 (R-type), phase=0
        opcode = 7'h33; phase = 3'b000; #10;
        check_all_zero(opcode, phase, 1);

        // Test Vector 2: opcode=7'h33 (R-type), phase=1
        opcode = 7'h33; phase = 3'b001; #10;
        check_all_zero(opcode, phase, 2);

        // Test Vector 3: opcode=7'h33 (R-type), phase=2
        opcode = 7'h33; phase = 3'b010; #10;
        check_all_zero(opcode, phase, 3);

        // Test Vector 4: opcode=7'h33 (R-type), phase=3
        opcode = 7'h33; phase = 3'b011; #10;
        check_all_zero(opcode, phase, 4);

        // Test Vector 5: opcode=7'h33 (R-type), phase=4
        opcode = 7'h33; phase = 3'b100; #10;
        check_all_zero(opcode, phase, 5);

        // Test Vector 6: opcode=7'h13 (I-type ALU), phase=0
        opcode = 7'h13; phase = 3'b000; #10;
        check_all_zero(opcode, phase, 6);

        // Test Vector 7: opcode=7'h13 (I-type ALU), phase=1
        opcode = 7'h13; phase = 3'b001; #10;
        check_all_zero(opcode, phase, 7);

        // Test Vector 8: opcode=7'h13 (I-type ALU), phase=2
        opcode = 7'h13; phase = 3'b010; #10;
        check_all_zero(opcode, phase, 8);

        // Test Vector 9: opcode=7'h13 (I-type ALU), phase=3
        opcode = 7'h13; phase = 3'b011; #10;
        check_all_zero(opcode, phase, 9);

        // Test Vector 10: opcode=7'h13 (I-type ALU), phase=4
        opcode = 7'h13; phase = 3'b100; #10;
        check_all_zero(opcode, phase, 10);

        // Test Vector 11: opcode=7'h03 (Load), phase=0
        opcode = 7'h03; phase = 3'b000; #10;
        check_all_zero(opcode, phase, 11);

        // Test Vector 12: opcode=7'h03 (Load), phase=1
        opcode = 7'h03; phase = 3'b001; #10;
        check_all_zero(opcode, phase, 12);

        // Test Vector 13: opcode=7'h03 (Load), phase=2
        opcode = 7'h03; phase = 3'b010; #10;
        check_all_zero(opcode, phase, 13);

        // Test Vector 14: opcode=7'h03 (Load), phase=3
        opcode = 7'h03; phase = 3'b011; #10;
        check_all_zero(opcode, phase, 14);

        // Test Vector 15: opcode=7'h03 (Load), phase=4
        opcode = 7'h03; phase = 3'b100; #10;
        check_all_zero(opcode, phase, 15);

        // Test Vector 16: opcode=7'h23 (Store), phase=0
        opcode = 7'h23; phase = 3'b000; #10;
        check_all_zero(opcode, phase, 16);

        // Test Vector 17: opcode=7'h23 (Store), phase=1
        opcode = 7'h23; phase = 3'b001; #10;
        check_all_zero(opcode, phase, 17);

        // Test Vector 18: opcode=7'h23 (Store), phase=2
        opcode = 7'h23; phase = 3'b010; #10;
        check_all_zero(opcode, phase, 18);

        // Test Vector 19: opcode=7'h23 (Store), phase=3
        opcode = 7'h23; phase = 3'b011; #10;
        check_all_zero(opcode, phase, 19);

        // Test Vector 20: opcode=7'h23 (Store), phase=4
        opcode = 7'h23; phase = 3'b100; #10;
        check_all_zero(opcode, phase, 20);

        // Test Vector 21: opcode=7'h63 (Branch), phase=0
        opcode = 7'h63; phase = 3'b000; #10;
        check_all_zero(opcode, phase, 21);

        // Test Vector 22: opcode=7'h63 (Branch), phase=1
        opcode = 7'h63; phase = 3'b001; #10;
        check_all_zero(opcode, phase, 22);

        // Test Vector 23: opcode=7'h63 (Branch), phase=2
        opcode = 7'h63; phase = 3'b010; #10;
        check_all_zero(opcode, phase, 23);

        // Test Vector 24: opcode=7'h63 (Branch), phase=3
        opcode = 7'h63; phase = 3'b011; #10;
        check_all_zero(opcode, phase, 24);

        // Test Vector 25: opcode=7'h63 (Branch), phase=4
        opcode = 7'h63; phase = 3'b100; #10;
        check_all_zero(opcode, phase, 25);

        // Test Vector 26: all-zero inputs (undefined opcode, phase=0)
        opcode = 7'h00; phase = 3'b000; #10;
        check_all_zero(opcode, phase, 26);

        // Test Vector 27: all-ones inputs (undefined opcode, all phases)
        opcode = 7'h7F; phase = 3'b111; #10;
        check_all_zero(opcode, phase, 27);

        // Test Vector 28: undefined opcode, phase=5
        opcode = 7'h55; phase = 3'b101; #10;
        check_all_zero(opcode, phase, 28);

        // Test Vector 29: undefined opcode, phase=6
        opcode = 7'h2A; phase = 3'b110; #10;
        check_all_zero(opcode, phase, 29);

        // Test Vector 30: max opcode, phase=4
        opcode = 7'h7F; phase = 3'b100; #10;
        check_all_zero(opcode, phase, 30);

        // Verify pc_write is never asserted for any opcode and phase 0-4
        // (Since the DUT always outputs 0, pc_write should never be 1)
        begin : pc_write_check
            reg [6:0] op_test;
            reg [2:0] ph_test;
            reg pass_flag;
            pass_flag = 1;
            for (j = 0; j < 128; j = j + 1) begin
                op_test = j[6:0];
                opcode = op_test;
                for (i = 0; i < 8; i = i + 1) begin
                    ph_test = i[2:0];
                    phase = ph_test;
                    #2;
                    if (pc_write !== 0) begin
                        pass_flag = 0;
                        $display("FAIL: pc_write asserted unexpectedly for opcode=0x%02h phase=%0d", op_test, ph_test);
                    end
                end
            end
            if (pass_flag)
                $display("PASS: pc_write never asserted for any opcode/phase combination");
        end

        $finish;
    end

endmodule
