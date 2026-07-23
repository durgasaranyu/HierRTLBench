`timescale 1ns/1ps

module tb_ctrl_phase01;

    // DUT connections
    reg  [6:0] opcode;
    reg  [2:0] phase;
    wire       pc_write;
    wire       ir_write;
    wire       reg_write;
    wire       mem_write;
    wire       alu_src_a;
    wire       alu_src_b;
    wire       mem_to_reg;
    wire       pc_source;

    // Clock and reset (not used by DUT but required by testbench template)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // DUT instantiation
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

    // Task for checking outputs
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
        input [63:0] desc_unused; // not used, just for documentation
        reg         pass;
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
        end
    endtask

    integer pass_flag;

    initial begin
        // Apply reset for 5 clock rising edges
        rst = 1;
        opcode = 7'h0;
        phase  = 3'h0;
        repeat (5) @(posedge clk);
        rst = 0;

        //----------------------------------------------------------------------
        // Phase 0 (IF): expected outputs regardless of opcode
        // pc_write=1, ir_write=1, reg_write=1, mem_write=0,
        // alu_src_a=0, alu_src_b=0, mem_to_reg=0, pc_source=0
        //----------------------------------------------------------------------

        // Test 1: opcode=7'h33 (R-type), phase=0
        opcode = 7'h33; phase = 3'd0; #2;
        pass_flag = 1;
        if (pc_write !== 1)   pass_flag = 0;
        if (ir_write !== 1)   pass_flag = 0;
        if (reg_write !== 1)  pass_flag = 0;
        if (mem_write !== 0)  pass_flag = 0;
        if (alu_src_a !== 0)  pass_flag = 0;
        if (alu_src_b !== 0)  pass_flag = 0;
        if (mem_to_reg !== 0) pass_flag = 0;
        if (pc_source !== 0)  pass_flag = 0;
        if (pass_flag)
            $display("PASS: opcode=7'h33, phase=0 (IF): correct outputs");
        else
            $display("FAIL: opcode=7'h33, phase=0 (IF): incorrect outputs pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                     pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);

        // Test 2: opcode=7'h13 (I-type ALU), phase=0
        opcode = 7'h13; phase = 3'd0; #2;
        pass_flag = 1;
        if (pc_write !== 1)   pass_flag = 0;
        if (ir_write !== 1)   pass_flag = 0;
        if (reg_write !== 1)  pass_flag = 0;
        if (mem_write !== 0)  pass_flag = 0;
        if (alu_src_a !== 0)  pass_flag = 0;
        if (alu_src_b !== 0)  pass_flag = 0;
        if (mem_to_reg !== 0) pass_flag = 0;
        if (pc_source !== 0)  pass_flag = 0;
        if (pass_flag)
            $display("PASS: opcode=7'h13, phase=0 (IF): correct outputs");
        else
            $display("FAIL: opcode=7'h13, phase=0 (IF): incorrect outputs pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                     pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);

        // Test 3: opcode=7'h03 (Load), phase=0
        opcode = 7'h03; phase = 3'd0; #2;
        pass_flag = 1;
        if (pc_write !== 1)   pass_flag = 0;
        if (ir_write !== 1)   pass_flag = 0;
        if (reg_write !== 1)  pass_flag = 0;
        if (mem_write !== 0)  pass_flag = 0;
        if (alu_src_a !== 0)  pass_flag = 0;
        if (alu_src_b !== 0)  pass_flag = 0;
        if (mem_to_reg !== 0) pass_flag = 0;
        if (pc_source !== 0)  pass_flag = 0;
        if (pass_flag)
            $display("PASS: opcode=7'h03, phase=0 (IF): correct outputs");
        else
            $display("FAIL: opcode=7'h03, phase=0 (IF): incorrect outputs pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                     pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);

        // Test 4: opcode=7'h23 (Store), phase=0
        opcode = 7'h23; phase = 3'd0; #2;
        pass_flag = 1;
        if (pc_write !== 1)   pass_flag = 0;
        if (ir_write !== 1)   pass_flag = 0;
        if (reg_write !== 1)  pass_flag = 0;
        if (mem_write !== 0)  pass_flag = 0;
        if (alu_src_a !== 0)  pass_flag = 0;
        if (alu_src_b !== 0)  pass_flag = 0;
        if (mem_to_reg !== 0) pass_flag = 0;
        if (pc_source !== 0)  pass_flag = 0;
        if (pass_flag)
            $display("PASS: opcode=7'h23, phase=0 (IF): correct outputs");
        else
            $display("FAIL: opcode=7'h23, phase=0 (IF): incorrect outputs pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                     pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);

        // Test 5: opcode=7'h63 (Branch), phase=0
        opcode = 7'h63; phase = 3'd0; #2;
        pass_flag = 1;
        if (pc_write !== 1)   pass_flag = 0;
        if (ir_write !== 1)   pass_flag = 0;
        if (reg_write !== 1)  pass_flag = 0;
        if (mem_write !== 0)  pass_flag = 0;
        if (alu_src_a !== 0)  pass_flag = 0;
        if (alu_src_b !== 0)  pass_flag = 0;
        if (mem_to_reg !== 0) pass_flag = 0;
        if (pc_source !== 0)  pass_flag = 0;
        if (pass_flag)
            $display("PASS: opcode=7'h63, phase=0 (IF): correct outputs");
        else
            $display("FAIL: opcode=7'h63, phase=0 (IF): incorrect outputs pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                     pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);

        //----------------------------------------------------------------------
        // Phase 1 (ID): expected outputs regardless of opcode
        // pc_write=0, ir_write=0, reg_write=0, mem_write=1,
        // alu_src_a=0, alu_src_b=1, mem_to_reg=1, pc_source=1
        //----------------------------------------------------------------------

        // Test 6: opcode=7'h33, phase=1
        opcode = 7'h33; phase = 3'd1; #2;
        pass_flag = 1;
        if (pc_write !== 0)   pass_flag = 0;
        if (ir_write !== 0)   pass_flag = 0;
        if (reg_write !== 0)  pass_flag = 0;
        if (mem_write !== 1)  pass_flag = 0;
        if (alu_src_a !== 0)  pass_flag = 0;
        if (alu_src_b !== 1)  pass_flag = 0;
        if (mem_to_reg !== 1) pass_flag = 0;
        if (pc_source !== 1)  pass_flag = 0;
        if (pass_flag)
            $display("PASS: opcode=7'h33, phase=1 (ID): correct outputs");
        else
            $display("FAIL: opcode=7'h33, phase=1 (ID): incorrect outputs pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                     pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);

        // Test 7: opcode=7'h13, phase=1
        opcode = 7'h13; phase = 3'd1; #2;
        pass_flag = 1;
        if (pc_write !== 0)   pass_flag = 0;
        if (ir_write !== 0)   pass_flag = 0;
        if (reg_write !== 0)  pass_flag = 0;
        if (mem_write !== 1)  pass_flag = 0;
        if (alu_src_a !== 0)  pass_flag = 0;
        if (alu_src_b !== 1)  pass_flag = 0;
        if (mem_to_reg !== 1) pass_flag = 0;
        if (pc_source !== 1)  pass_flag = 0;
        if (pass_flag)
            $display("PASS: opcode=7'h13, phase=1 (ID): correct outputs");
        else
            $display("FAIL: opcode=7'h13, phase=1 (ID): incorrect outputs pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                     pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);

        // Test 8: opcode=7'h03, phase=1
        opcode = 7'h03; phase = 3'd1; #2;
        pass_flag = 1;
        if (pc_write !== 0)   pass_flag = 0;
        if (ir_write !== 0)   pass_flag = 0;
        if (reg_write !== 0)  pass_flag = 0;
        if (mem_write !== 1)  pass_flag = 0;
        if (alu_src_a !== 0)  pass_flag = 0;
        if (alu_src_b !== 1)  pass_flag = 0;
        if (mem_to_reg !== 1) pass_flag = 0;
        if (pc_source !== 1)  pass_flag = 0;
        if (pass_flag)
            $display("PASS: opcode=7'h03, phase=1 (ID): correct outputs");
        else
            $display("FAIL: opcode=7'h03, phase=1 (ID): incorrect outputs pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                     pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);

        // Test 9: opcode=7'h23, phase=1
        opcode = 7'h23; phase = 3'd1; #2;
        pass_flag = 1;
        if (pc_write !== 0)   pass_flag = 0;
        if (ir_write !== 0)   pass_flag = 0;
        if (reg_write !== 0)  pass_flag = 0;
        if (mem_write !== 1)  pass_flag = 0;
        if (alu_src_a !== 0)  pass_flag = 0;
        if (alu_src_b !== 1)  pass_flag = 0;
        if (mem_to_reg !== 1) pass_flag = 0;
        if (pc_source !== 1)  pass_flag = 0;
        if (pass_flag)
            $display("PASS: opcode=7'h23, phase=1 (ID): correct outputs");
        else
            $display("FAIL: opcode=7'h23, phase=1 (ID): incorrect outputs pc_
