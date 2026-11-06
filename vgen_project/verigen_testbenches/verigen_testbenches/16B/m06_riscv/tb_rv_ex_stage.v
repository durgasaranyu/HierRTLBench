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

    // Clock (not used by combinational DUT but required by general rules)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    rv_ex_stage uut (
        .rs1_data    (rs1_data),
        .rs2_data    (rs2_data),
        .imm_ext     (imm_ext),
        .pc          (pc),
        .fwd_ex_mem  (fwd_ex_mem),
        .fwd_mem_wb  (fwd_mem_wb),
        .forward_a   (forward_a),
        .forward_b   (forward_b),
        .alu_src     (alu_src),
        .alu_op      (alu_op),
        .alu_result  (alu_result),
        .branch_target(branch_target),
        .zero        (zero)
    );

    // Task for applying stimulus and checking
    // The module's alu_result = alu_src ? fwd_ex_mem : fwd_mem_wb
    // branch_target = pc + imm_ext
    // zero = ~|alu_result

    integer fail_count;

    task check_outputs;
        input [31:0] exp_alu_result;
        input [31:0] exp_branch_target;
        input        exp_zero;
        input [63:0] test_num;
        input [255:0] desc;
        begin
            #1; // small delay for combinational settle
            if (alu_result !== exp_alu_result) begin
                $display("FAIL: Test %0d (%s) - alu_result expected %08h got %08h",
                         test_num, desc, exp_alu_result, alu_result);
                fail_count = fail_count + 1;
            end else if (branch_target !== exp_branch_target) begin
                $display("FAIL: Test %0d (%s) - branch_target expected %08h got %08h",
                         test_num, desc, exp_branch_target, branch_target);
                fail_count = fail_count + 1;
            end else if (zero !== exp_zero) begin
                $display("FAIL: Test %0d (%s) - zero expected %b got %b",
                         test_num, desc, exp_zero, zero);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: Test %0d (%s)", test_num, desc);
            end
        end
    endtask

    initial begin
        fail_count = 0;
        rst = 1;
        // Assert reset for 5 clock rising edges
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 0;

        // Initialize all inputs to 0
        rs1_data   = 32'h0;
        rs2_data   = 32'h0;
        imm_ext    = 32'h0;
        pc         = 32'h0;
        fwd_ex_mem = 32'h0;
        fwd_mem_wb = 32'h0;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b00;
        #2;

        // ---------------------------------------------------------------
        // Test 1: All zeros, alu_src=0 => alu_result = fwd_mem_wb = 0
        //         branch_target = pc + imm_ext = 0, zero = 1
        // ---------------------------------------------------------------
        rs1_data   = 32'h0;
        rs2_data   = 32'h0;
        imm_ext    = 32'h0;
        pc         = 32'h0;
        fwd_ex_mem = 32'h0;
        fwd_mem_wb = 32'h0;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b00;
        check_outputs(32'h0, 32'h0, 1'b1, 1, "All zeros alu_src=0");

        // ---------------------------------------------------------------
        // Test 2: alu_src=1 => alu_result = fwd_ex_mem = 0x12345678
        //         branch_target = pc(0x100) + imm_ext(0x4) = 0x104
        //         zero = 0
        // ---------------------------------------------------------------
        rs1_data   = 32'hDEADBEEF;
        rs2_data   = 32'hCAFEBABE;
        imm_ext    = 32'h00000004;
        pc         = 32'h00000100;
        fwd_ex_mem = 32'h12345678;
        fwd_mem_wb = 32'hAABBCCDD;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b1;
        alu_op     = 2'b00;
        check_outputs(32'h12345678, 32'h00000104, 1'b0, 2, "alu_src=1 selects fwd_ex_mem");

        // ---------------------------------------------------------------
        // Test 3: alu_src=0 => alu_result = fwd_mem_wb = 0xAABBCCDD
        //         branch_target = 0x100 + 0x4 = 0x104
        //         zero = 0
        // ---------------------------------------------------------------
        rs1_data   = 32'hDEADBEEF;
        rs2_data   = 32'hCAFEBABE;
        imm_ext    = 32'h00000004;
        pc         = 32'h00000100;
        fwd_ex_mem = 32'h12345678;
        fwd_mem_wb = 32'hAABBCCDD;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b00;
        check_outputs(32'hAABBCCDD, 32'h00000104, 1'b0, 3, "alu_src=0 selects fwd_mem_wb");

        // ---------------------------------------------------------------
        // Test 4: alu_src=1, fwd_ex_mem=0 => alu_result=0, zero=1
        //         branch_target = 0x200 + 0x8 = 0x208
        // ---------------------------------------------------------------
        rs1_data   = 32'h1;
        rs2_data   = 32'h2;
        imm_ext    = 32'h00000008;
        pc         = 32'h00000200;
        fwd_ex_mem = 32'h00000000;
        fwd_mem_wb = 32'hFFFFFFFF;
        forward_a  = 2'b01;
        forward_b  = 2'b10;
        alu_src    = 1'b1;
        alu_op     = 2'b01;
        check_outputs(32'h00000000, 32'h00000208, 1'b1, 4, "fwd_ex_mem=0 zero=1");

        // ---------------------------------------------------------------
        // Test 5: alu_src=0, fwd_mem_wb=0xFFFFFFFF => alu_result=0xFFFFFFFF
        //         branch_target = 0xFFFFFF00 + 0x100 = 0x0 (wrap)
        //         zero = 0
        // ---------------------------------------------------------------
        rs1_data   = 32'hFFFFFFFF;
        rs2_data   = 32'hFFFFFFFF;
        imm_ext    = 32'h00000100;
        pc         = 32'hFFFFFF00;
        fwd_ex_mem = 32'h00000001;
        fwd_mem_wb = 32'hFFFFFFFF;
        forward_a  = 2'b11;
        forward_b  = 2'b11;
        alu_src    = 1'b0;
        alu_op     = 2'b11;
        check_outputs(32'hFFFFFFFF, 32'h00000000, 1'b0, 5, "All-ones inputs fwd_mem_wb");

        // ---------------------------------------------------------------
        // Test 6: alu_src=1, fwd_ex_mem=0xFFFFFFFF => alu_result=0xFFFFFFFF
        //         branch_target = 0x0 + 0xFFFFFFFF = 0xFFFFFFFF
        //         zero = 0
        // ---------------------------------------------------------------
        rs1_data   = 32'h0;
        rs2_data   = 32'h0;
        imm_ext    = 32'hFFFFFFFF;
        pc         = 32'h00000000;
        fwd_ex_mem = 32'hFFFFFFFF;
        fwd_mem_wb = 32'h00000000;
        forward_a  = 2'b10;
        forward_b  = 2'b00;
        alu_src    = 1'b1;
        alu_op     = 2'b10;
        check_outputs(32'hFFFFFFFF, 32'hFFFFFFFF, 1'b0, 6, "fwd_ex_mem=all-ones");

        // ---------------------------------------------------------------
        // Test 7: Maximum PC + maximum imm => branch_target wraps
        //         alu_src=0, fwd_mem_wb = 0xA5A5A5A5
        //         branch_target = 0x7FFFFFFF + 0x80000001 = 0x0
        //         zero = 0
        // ---------------------------------------------------------------
        rs1_data   = 32'h0;
        rs2_data   = 32'h0;
        imm_ext    = 32'h80000001;
        pc         = 32'h7FFFFFFF;
        fwd_ex_mem = 32'h00000000;
        fwd_mem_wb = 32'hA5A5A5A5;
        forward_a  = 2'b00;
        forward_b  = 2'b01;
        alu_src    = 1'b0;
        alu_op     = 2'b01;
        check_outputs(32'hA5A5A5A5, 32'h00000000, 1'b0, 7, "Max PC+imm wraps branch_target");

        // ---------------------------------------------------------------
        // Test 8: alu_src=0, fwd_mem_wb=1 => zero=0
        //         branch_target = 0x400 + 0x10 = 0x410
        // ---------------------------------------------------------------
        rs1_data   = 32'hABCDEF01;
        rs2_data   = 32'h12345678;
        imm_ext    = 32'h00000010;
        pc         = 32'h00000400;
        fwd_ex_mem = 32'h00000000;
        fwd_mem_wb = 32'h00000001;
        forward_a  = 2'b10;
        forward_b  = 2'b10;
        alu_src    = 1'b0;
        alu_op     = 2'b10;
        check_outputs(32'h00000001, 32'h00000410, 1'b0, 8, "fwd_mem_wb=1 zero=0");

        // ---------------------------------------------------------------
        // Test 9: forward_a=2'b01 (EX-MEM forwarding path indicator)
        //         alu_src=1 => alu_result = fwd_ex_mem = 0xCAFECAFE
        //         branch_target = 0x10 + 0x20 = 0x30
        //         zero = 0
        // ---------------------------------------------------------------
        rs1_data   = 32'h0;
        rs2_data   = 32'h0;
        imm_ext    = 32'h00000020;
        pc         = 32'h00000010;
        fwd_ex_mem = 32'hCAFECAFE;
        fwd_mem_wb = 32'h00000000;
        forward_a  = 2'b01;
        forward_b  = 2'b01;
        alu_src    = 1'b1;
        alu_op     = 2'b11;
        check_outputs(32'hCAFECAFE, 32'h00000030, 1'b0, 9, "forward_a=01 alu_src=1");

        // ---------------------------------------------------------------
        // Test 10: alu_src=0, fwd_mem_wb=0, zero=1
        //          branch_target = 0x500 + 0x8 = 0x508
        // ---------------------------------------------------------------
        rs1_data   = 32'h0;
        rs2_data   = 32'h0;
        imm_ext    = 32'h00000008;
        pc         = 32'h00000500;
        fwd_ex_mem = 32'hDEADBEEF;
        fwd_mem_wb = 32'h00000000;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b00;
        check_outputs(32'h00000000, 32'h00000508, 1'b1, 10, "fwd_mem_wb=0 zero=1 normal");

        // Summary
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
