`timescale 1ns/1ps

module tb_rv_ex_stage;

    // DUT inputs
    reg [31:0] rs1_data;
    reg [31:0] rs2_data;
    reg [31:0] imm_ext;
    reg [31:0] pc;
    reg [31:0] fwd_ex_mem;
    reg [31:0] fwd_mem_wb;
    reg [1:0]  forward_a;
    reg [1:0]  forward_b;
    reg        alu_src;
    reg [1:0]  alu_op;

    // DUT outputs
    wire [31:0] alu_result;
    wire [31:0] branch_target;
    wire        zero;

    // Clock and reset (not used by this combinational module, but required by spec)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    rv_ex_stage uut (
        .rs1_data   (rs1_data),
        .rs2_data   (rs2_data),
        .imm_ext    (imm_ext),
        .pc         (pc),
        .fwd_ex_mem (fwd_ex_mem),
        .fwd_mem_wb (fwd_mem_wb),
        .forward_a  (forward_a),
        .forward_b  (forward_b),
        .alu_src    (alu_src),
        .alu_op     (alu_op),
        .alu_result (alu_result),
        .branch_target(branch_target),
        .zero       (zero)
    );

    // Task to apply inputs and wait for combinational settling
    task apply_and_check;
        input [31:0] t_rs1_data;
        input [31:0] t_rs2_data;
        input [31:0] t_imm_ext;
        input [31:0] t_pc;
        input [31:0] t_fwd_ex_mem;
        input [31:0] t_fwd_mem_wb;
        input [1:0]  t_forward_a;
        input [1:0]  t_forward_b;
        input        t_alu_src;
        input [1:0]  t_alu_op;
        input [31:0] t_expected_alu;
        input [31:0] t_expected_branch;
        input        t_expected_zero;
        input [127:0] t_desc;
        begin
            rs1_data   = t_rs1_data;
            rs2_data   = t_rs2_data;
            imm_ext    = t_imm_ext;
            pc         = t_pc;
            fwd_ex_mem = t_fwd_ex_mem;
            fwd_mem_wb = t_fwd_mem_wb;
            forward_a  = t_forward_a;
            forward_b  = t_forward_b;
            alu_src    = t_alu_src;
            alu_op     = t_alu_op;
            #2; // wait for combinational settling
            if ((alu_result === t_expected_alu) &&
                (branch_target === t_expected_branch) &&
                (zero === t_expected_zero)) begin
                $display("PASS: %s | alu_result=%0d branch_target=%0d zero=%b",
                    t_desc, alu_result, branch_target, zero);
            end else begin
                $display("FAIL: %s | Expected alu=%0d branch=%0d zero=%b Got alu=%0d branch=%0d zero=%b",
                    t_desc, t_expected_alu, t_expected_branch, t_expected_zero,
                    alu_result, branch_target, zero);
            end
        end
    endtask

    // Helper: compute expected values based on module semantics
    // The module as written has synthesis errors, so we treat it as a black-box
    // and simply check that outputs are defined (not X/Z) and note pass/fail
    // based on output presence. Since the module is clearly broken RTL, we do
    // best-effort checking: outputs should not be X.

    integer test_num;

    initial begin
        // Assert reset for 5 rising edges
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // Test 1: All-zero inputs, ADD operation, no forwarding
        rs1_data   = 32'h0;
        rs2_data   = 32'h0;
        imm_ext    = 32'h0;
        pc         = 32'h0;
        fwd_ex_mem = 32'h0;
        fwd_mem_wb = 32'h0;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b00; // ADD
        #2;
        if (alu_result === 32'bx || alu_result === 32'bz)
            $display("FAIL: Test1 all-zeros ADD - alu_result is X/Z");
        else if (alu_result === 32'h0)
            $display("PASS: Test1 all-zeros ADD - alu_result=%0d zero=%b", alu_result, zero);
        else
            $display("FAIL: Test1 all-zeros ADD - expected 0, got %0d", alu_result);

        // Test 2: Normal ADD rs1+rs2, no forwarding, alu_src=0
        rs1_data   = 32'd10;
        rs2_data   = 32'd20;
        imm_ext    = 32'd100;
        pc         = 32'h1000;
        fwd_ex_mem = 32'd0;
        fwd_mem_wb = 32'd0;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b00; // ADD
        #2;
        if (alu_result === 32'd30)
            $display("PASS: Test2 normal ADD 10+20=30 - alu_result=%0d", alu_result);
        else
            $display("FAIL: Test2 normal ADD 10+20 - expected 30, got %0d", alu_result);

        // Test 3: ADD with immediate (alu_src=1)
        rs1_data   = 32'd5;
        rs2_data   = 32'd99;
        imm_ext    = 32'd15;
        pc         = 32'h1000;
        fwd_ex_mem = 32'd0;
        fwd_mem_wb = 32'd0;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b1;
        alu_op     = 2'b00; // ADD
        #2;
        if (alu_result === 32'd20)
            $display("PASS: Test3 ADD with imm 5+15=20 - alu_result=%0d", alu_result);
        else
            $display("FAIL: Test3 ADD with imm 5+15 - expected 20, got %0d", alu_result);

        // Test 4: SUB operation, no forwarding
        rs1_data   = 32'd50;
        rs2_data   = 32'd30;
        imm_ext    = 32'd0;
        pc         = 32'h2000;
        fwd_ex_mem = 32'd0;
        fwd_mem_wb = 32'd0;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b01; // SUB
        #2;
        if (alu_result === 32'd20)
            $display("PASS: Test4 SUB 50-30=20 - alu_result=%0d", alu_result);
        else
            $display("FAIL: Test4 SUB 50-30 - expected 20, got %0d", alu_result);

        // Test 5: SUB yielding zero (zero flag)
        rs1_data   = 32'd42;
        rs2_data   = 32'd42;
        imm_ext    = 32'd0;
        pc         = 32'h3000;
        fwd_ex_mem = 32'd0;
        fwd_mem_wb = 32'd0;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b01; // SUB
        #2;
        if (alu_result === 32'd0 && zero === 1'b1)
            $display("PASS: Test5 SUB 42-42=0 zero=1 - alu_result=%0d zero=%b", alu_result, zero);
        else
            $display("FAIL: Test5 SUB 42-42 - expected 0/zero=1, got %0d/zero=%b", alu_result, zero);

        // Test 6: AND operation
        rs1_data   = 32'hFF00FF00;
        rs2_data   = 32'hF0F0F0F0;
        imm_ext    = 32'd0;
        pc         = 32'h4000;
        fwd_ex_mem = 32'd0;
        fwd_mem_wb = 32'd0;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b10; // AND
        #2;
        if (alu_result === 32'hF000F000)
            $display("PASS: Test6 AND FF00FF00 & F0F0F0F0 = F000F000 - alu_result=%h", alu_result);
        else
            $display("FAIL: Test6 AND - expected F000F000, got %h", alu_result);

        // Test 7: OR operation
        rs1_data   = 32'h00FF00FF;
        rs2_data   = 32'hFF00FF00;
        imm_ext    = 32'd0;
        pc         = 32'h5000;
        fwd_ex_mem = 32'd0;
        fwd_mem_wb = 32'd0;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b11; // OR
        #2;
        if (alu_result === 32'hFFFFFFFF)
            $display("PASS: Test7 OR 00FF00FF | FF00FF00 = FFFFFFFF - alu_result=%h", alu_result);
        else
            $display("FAIL: Test7 OR - expected FFFFFFFF, got %h", alu_result);

        // Test 8: Forwarding from EX/MEM (forward_a=2'b10)
        rs1_data   = 32'd0;    // should be overridden by fwd_ex_mem
        rs2_data   = 32'd5;
        imm_ext    = 32'd0;
        pc         = 32'h6000;
        fwd_ex_mem = 32'd100;  // forwarded value for rs1
        fwd_mem_wb = 32'd0;
        forward_a  = 2'b10;   // use fwd_ex_mem for operand A
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b00; // ADD
        #2;
        if (alu_result === 32'd105)
            $display("PASS: Test8 FWD_A=EX/MEM 100+5=105 - alu_result=%0d", alu_result);
        else
            $display("FAIL: Test8 FWD_A=EX/MEM - expected 105, got %0d", alu_result);

        // Test 9: Forwarding from MEM/WB (forward_a=2'b01)
        rs1_data   = 32'd0;    // should be overridden by fwd_mem_wb
        rs2_data   = 32'd7;
        imm_ext    = 32'd0;
        pc         = 32'h7000;
        fwd_ex_mem = 32'd0;
        fwd_mem_wb = 32'd50;   // forwarded value for rs1
        forward_a  = 2'b01;   // use fwd_mem_wb for operand A
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b00; // ADD
        #2;
        if (alu_result === 32'd57)
            $display("PASS: Test9 FWD_A=MEM/WB 50+7=57 - alu_result=%0d", alu_result);
        else
            $display("FAIL: Test9 FWD_A=MEM/WB - expected 57, got %0d", alu_result);

        // Test 10: All-ones inputs, ADD
        rs1_data   = 32'hFFFFFFFF;
        rs2_data   = 32'hFFFFFFFF;
        imm_ext    = 32'hFFFFFFFF;
        pc         = 32'hFFFFFFFF;
        fwd_ex_mem = 32'hFFFFFFFF;
        fwd_mem_wb = 32'hFFFFFFFF;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b00; // ADD
        #2;
        // 0xFFFFFFFF + 0xFFFFFFFF = 0x1FFFFFFFE, truncated to 32 bits = 0xFFFFFFFE
        if (alu_result === 32'hFFFFFFFE)
            $display("PASS: Test10 all-ones ADD overflow - alu_result=%h", alu_result);
        else
            $display("FAIL: Test10 all-ones ADD - expected FFFFFFFE, got %h", alu_result);

        // Test 11: Branch target = pc + imm
        rs1_data   = 32'd0;
        rs2_data   = 32'd0;
        imm_ext    = 32'd8;
        pc         = 32'h1000;
        fwd_ex_mem = 32'd0;
        fwd_mem_wb = 32'd0;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b00;
        #2;
        if (branch_target === 32'h1008)
            $display("PASS: Test11 branch_target=pc+imm=0x1008 - branch_target=%h", branch_target);
        else
            $display("FAIL: Test11 branch_target - expected 0x1008, got %h", branch_target);

        // Test 12: forward_b from EX/MEM
