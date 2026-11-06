`timescale 1ns/1ps

module tb_ctrl_top;

    // DUT ports
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

    // Clock and reset (not used by DUT but kept per requirements)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

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

    // Reset for 5 rising edges
    integer i;
    initial begin
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
    end

    // Test procedure
    integer fail_count;

    task check;
        input [63:0] desc_unused;
        input exp_pc_write;
        input exp_ir_write;
        input exp_reg_write;
        input exp_mem_write;
        input exp_alu_src_a;
        input exp_alu_src_b;
        input exp_mem_to_reg;
        input exp_pc_source;
        input [127:0] desc;
        begin
            #1; // let combinational settle
            if (pc_write   === exp_pc_write   &&
                ir_write   === exp_ir_write   &&
                reg_write  === exp_reg_write  &&
                mem_write  === exp_mem_write  &&
                alu_src_a  === exp_alu_src_a  &&
                alu_src_b  === exp_alu_src_b  &&
                mem_to_reg === exp_mem_to_reg &&
                pc_source  === exp_pc_source) begin
                $display("PASS: opcode=%h phase=%0d", opcode, phase);
            end else begin
                $display("FAIL: opcode=%h phase=%0d | got pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b | exp pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                    opcode, phase,
                    pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source,
                    exp_pc_write, exp_ir_write, exp_reg_write, exp_mem_write, exp_alu_src_a, exp_alu_src_b, exp_mem_to_reg, exp_pc_source);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Simple display-based check without task parameters for strings
    // We'll do inline checks

    initial begin
        fail_count = 0;

        // Wait for reset to deassert
        @(posedge clk); // wait one extra cycle after reset
        #2;

        // -------------------------------------------------------
        // Phase 0: Fetch (all opcodes should behave the same)
        // Expected: pc_write=1, ir_write=1, rest=0
        // -------------------------------------------------------
        opcode = 7'h33; phase = 3'd0; #10;
        if (pc_write===1 && ir_write===1 && reg_write===0 && mem_write===0 &&
            alu_src_a===0 && alu_src_b===0 && mem_to_reg===0 && pc_source===0)
            $display("PASS: opcode=33 phase=0 (fetch)");
        else begin
            $display("FAIL: opcode=33 phase=0 (fetch) got pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);
            fail_count = fail_count + 1;
        end

        opcode = 7'h13; phase = 3'd0; #10;
        if (pc_write===1 && ir_write===1 && reg_write===0 && mem_write===0 &&
            alu_src_a===0 && alu_src_b===0 && mem_to_reg===0 && pc_source===0)
            $display("PASS: opcode=13 phase=0 (fetch)");
        else begin
            $display("FAIL: opcode=13 phase=0 (fetch) got pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);
            fail_count = fail_count + 1;
        end

        opcode = 7'h03; phase = 3'd0; #10;
        if (pc_write===1 && ir_write===1 && reg_write===0 && mem_write===0 &&
            alu_src_a===0 && alu_src_b===0 && mem_to_reg===0 && pc_source===0)
            $display("PASS: opcode=03 phase=0 (fetch)");
        else begin
            $display("FAIL: opcode=03 phase=0 (fetch) got pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);
            fail_count = fail_count + 1;
        end

        opcode = 7'h23; phase = 3'd0; #10;
        if (pc_write===1 && ir_write===1 && reg_write===0 && mem_write===0 &&
            alu_src_a===0 && alu_src_b===0 && mem_to_reg===0 && pc_source===0)
            $display("PASS: opcode=23 phase=0 (fetch)");
        else begin
            $display("FAIL: opcode=23 phase=0 (fetch) got pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);
            fail_count = fail_count + 1;
        end

        opcode = 7'h63; phase = 3'd0; #10;
        if (pc_write===1 && ir_write===1 && reg_write===0 && mem_write===0 &&
            alu_src_a===0 && alu_src_b===0 && mem_to_reg===0 && pc_source===0)
            $display("PASS: opcode=63 phase=0 (fetch)");
        else begin
            $display("FAIL: opcode=63 phase=0 (fetch) got pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Phase 1: Decode (all opcodes should behave the same)
        // Expected: pc_write=0, ir_write=0, others may vary by design
        // -------------------------------------------------------
        opcode = 7'h33; phase = 3'd1; #10;
        $display("INFO: opcode=33 phase=1 pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
            pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);
        // pc_write must NOT be asserted in phase 1
        if (pc_write === 0)
            $display("PASS: opcode=33 phase=1 pc_write=0");
        else begin
            $display("FAIL: opcode=33 phase=1 pc_write should be 0, got %b", pc_write);
            fail_count = fail_count + 1;
        end

        opcode = 7'h13; phase = 3'd1; #10;
        $display("INFO: opcode=13 phase=1 pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
            pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);
        if (pc_write === 0)
            $display("PASS: opcode=13 phase=1 pc_write=0");
        else begin
            $display("FAIL: opcode=13 phase=1 pc_write should be 0, got %b", pc_write);
            fail_count = fail_count + 1;
        end

        opcode = 7'h03; phase = 3'd1; #10;
        $display("INFO: opcode=03 phase=1 pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
            pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);
        if (pc_write === 0)
            $display("PASS: opcode=03 phase=1 pc_write=0");
        else begin
            $display("FAIL: opcode=03 phase=1 pc_write should be 0, got %b", pc_write);
            fail_count = fail_count + 1;
        end

        opcode = 7'h23; phase = 3'd1; #10;
        $display("INFO: opcode=23 phase=1 pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
            pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);
        if (pc_write === 0)
            $display("PASS: opcode=23 phase=1 pc_write=0");
        else begin
            $display("FAIL: opcode=23 phase=1 pc_write should be 0, got %b", pc_write);
            fail_count = fail_count + 1;
        end

        opcode = 7'h63; phase = 3'd1; #10;
        $display("INFO: opcode=63 phase=1 pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
            pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);
        if (pc_write === 0)
            $display("PASS: opcode=63 phase=1 pc_write=0");
        else begin
            $display("FAIL: opcode=63 phase=1 pc_write should be 0, got %b", pc_write);
            fail_count = fail_count + 1;
        end

        // -------------------------------------------------------
        // Phase 2: Execute
        // -------------------------------------------------------
        opcode = 7'h33; phase = 3'd2; #10;
        $display("INFO: opcode=33 phase=2 pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
            pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);
        if (pc_write === 0)
            $display("PASS: opcode=33 phase=2 pc_write=0");
        else begin
            $display("FAIL: opcode=33 phase=2 pc_write should be 0 got %b", pc_write);
            fail_count = fail_count + 1;
        end

        opcode = 7'h13; phase = 3'd2; #10;
        $display("INFO: opcode=13 phase=2 pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
            pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);
        if (pc_write === 0)
            $display("PASS: opcode=13 phase=2 pc_write=0");
        else begin
            $display("FAIL: opcode=13 phase=2 pc_write should be 0 got %b", pc_write);
            fail_count = fail_count + 1;
        end

        opcode = 7'h03; phase = 3'd2; #10;
        $display("INFO: opcode=03 phase=2 pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
            pc_write, ir_write, reg_write, mem_write, alu_src_a, alu_src_b, mem_to_reg, pc_source);
        if (pc_write === 0)
            $display("PASS: opcode=03 phase=2 pc_write=0");
        else begin
            $display("FAIL: opcode=03 phase=2 pc_write should be 0 got %b", pc_write);
            fail_count = fail_count + 1;
        end

        opcode = 7'h23; phase = 3'd2; #10;
        $display("INFO: opcode=23 phase=2 pc_write=%b ir_write=%b reg_write=%b mem_
