`timescale 1ns/1ps
// Testbench for rv_ex_stage
// NOTE: The DUT source has severe syntax errors and incomplete code.
// This testbench instantiates the module and applies test vectors,
// checking outputs as best as possible given the module's intended behavior.
// Since the module cannot actually compile/simulate correctly,
// the testbench is written to be syntactically correct and self-checking
// based on expected ALU behavior described in the module comments.

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

    // Clock
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset (not a port of DUT, but kept for general requirement compliance)
    reg rst;
    integer i;
    integer pass_count;
    integer fail_count;

    // Task to check alu_result
    task check_alu;
        input [31:0] expected_result;
        input        expected_zero;
        input [63:0] desc_id; // used as numeric label
        begin
            #1; // small delay for combinational settle
            if (alu_result === expected_result && zero === expected_zero) begin
                $display("PASS: Test %0d alu_result=%0h zero=%0b", desc_id, alu_result, zero);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test %0d expected alu_result=%0h got=%0h expected_zero=%0b got_zero=%0b",
                         desc_id, expected_result, alu_result, expected_zero, zero);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Task to check branch_target
    task check_branch;
        input [31:0] expected_bt;
        input [63:0] desc_id;
        begin
            #1;
            if (branch_target === expected_bt) begin
                $display("PASS: Test %0d branch_target=%0h", desc_id, branch_target);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Test %0d expected branch_target=%0h got=%0h", desc_id, expected_bt, branch_target);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Helper function for expected ALU result based on forward mux and alu_op
    // forward_a: 00=rs1_data, 01=fwd_mem_wb, 10=fwd_ex_mem
    // forward_b: 00=rs2_data, 01=fwd_mem_wb, 10=fwd_ex_mem
    // alu_src: 0=use forward_b result, 1=use imm_ext
    // alu_op: 00=ADD, 01=SUB, 10=AND, 11=OR
    function [31:0] calc_operand_a;
        input [31:0] rs1, fwd_em, fwd_mw;
        input [1:0]  fwd_a;
        begin
            case (fwd_a)
                2'b00: calc_operand_a = rs1;
                2'b01: calc_operand_a = fwd_mw;
                2'b10: calc_operand_a = fwd_em;
                default: calc_operand_a = rs1;
            endcase
        end
    endfunction

    function [31:0] calc_operand_b;
        input [31:0] rs2, fwd_em, fwd_mw, imm;
        input [1:0]  fwd_b;
        input        src;
        begin
            if (src) begin
                calc_operand_b = imm;
            end else begin
                case (fwd_b)
                    2'b00: calc_operand_b = rs2;
                    2'b01: calc_operand_b = fwd_mw;
                    2'b10: calc_operand_b = fwd_em;
                    default: calc_operand_b = rs2;
                endcase
            end
        end
    endfunction

    function [31:0] calc_alu;
        input [31:0] a, b;
        input [1:0]  op;
        begin
            case (op)
                2'b00: calc_alu = a + b;
                2'b01: calc_alu = a - b;
                2'b10: calc_alu = a & b;
                2'b11: calc_alu = a | b;
                default: calc_alu = 32'hx;
            endcase
        end
    endfunction

    function calc_zero;
        input [31:0] result;
        begin
            calc_zero = (result == 32'b0) ? 1'b1 : 1'b0;
        end
    endfunction

    function [31:0] calc_branch_target;
        input [31:0] pc_val, imm_val;
        begin
            calc_branch_target = pc_val + imm_val;
        end
    endfunction

    reg [31:0] exp_a, exp_b, exp_result, exp_bt;
    reg        exp_zero;

    initial begin
        pass_count = 0;
        fail_count = 0;
        rst = 1;
        rs1_data   = 32'b0;
        rs2_data   = 32'b0;
        imm_ext    = 32'b0;
        pc         = 32'b0;
        fwd_ex_mem = 32'b0;
        fwd_mem_wb = 32'b0;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b00;

        // Hold reset for 5 rising edges
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        @(negedge clk);

        // -------------------------------------------------------
        // Test 1: ADD, no forwarding, rs1=5, rs2=3, alu_src=0
        // -------------------------------------------------------
        @(negedge clk);
        rs1_data   = 32'd5;
        rs2_data   = 32'd3;
        imm_ext    = 32'd100;
        pc         = 32'h0000_0000;
        fwd_ex_mem = 32'd0;
        fwd_mem_wb = 32'd0;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b00;
        #2;
        exp_a      = calc_operand_a(rs1_data, fwd_ex_mem, fwd_mem_wb, forward_a);
        exp_b      = calc_operand_b(rs2_data, fwd_ex_mem, fwd_mem_wb, imm_ext, forward_b, alu_src);
        exp_result = calc_alu(exp_a, exp_b, alu_op);
        exp_zero   = calc_zero(exp_result);
        exp_bt     = calc_branch_target(pc, imm_ext);
        check_alu(exp_result, exp_zero, 64'd1);
        check_branch(exp_bt, 64'd1);

        // -------------------------------------------------------
        // Test 2: SUB producing zero, no forwarding, rs1=rs2=7
        // -------------------------------------------------------
        @(negedge clk);
        rs1_data   = 32'd7;
        rs2_data   = 32'd7;
        imm_ext    = 32'd4;
        pc         = 32'h0000_0004;
        fwd_ex_mem = 32'd0;
        fwd_mem_wb = 32'd0;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b01;
        #2;
        exp_a      = calc_operand_a(rs1_data, fwd_ex_mem, fwd_mem_wb, forward_a);
        exp_b      = calc_operand_b(rs2_data, fwd_ex_mem, fwd_mem_wb, imm_ext, forward_b, alu_src);
        exp_result = calc_alu(exp_a, exp_b, alu_op);
        exp_zero   = calc_zero(exp_result);
        exp_bt     = calc_branch_target(pc, imm_ext);
        check_alu(exp_result, exp_zero, 64'd2);
        check_branch(exp_bt, 64'd2);

        // -------------------------------------------------------
        // Test 3: AND, no forwarding, typical values
        // -------------------------------------------------------
        @(negedge clk);
        rs1_data   = 32'hFF00FF00;
        rs2_data   = 32'h0F0F0F0F;
        imm_ext    = 32'd8;
        pc         = 32'h0000_0008;
        fwd_ex_mem = 32'd0;
        fwd_mem_wb = 32'd0;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b10;
        #2;
        exp_a      = calc_operand_a(rs1_data, fwd_ex_mem, fwd_mem_wb, forward_a);
        exp_b      = calc_operand_b(rs2_data, fwd_ex_mem, fwd_mem_wb, imm_ext, forward_b, alu_src);
        exp_result = calc_alu(exp_a, exp_b, alu_op);
        exp_zero   = calc_zero(exp_result);
        exp_bt     = calc_branch_target(pc, imm_ext);
        check_alu(exp_result, exp_zero, 64'd3);
        check_branch(exp_bt, 64'd3);

        // -------------------------------------------------------
        // Test 4: OR, no forwarding
        // -------------------------------------------------------
        @(negedge clk);
        rs1_data   = 32'hAA00AA00;
        rs2_data   = 32'h0055_0055;
        imm_ext    = 32'd12;
        pc         = 32'h0000_000C;
        fwd_ex_mem = 32'd0;
        fwd_mem_wb = 32'd0;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b0;
        alu_op     = 2'b11;
        #2;
        exp_a      = calc_operand_a(rs1_data, fwd_ex_mem, fwd_mem_wb, forward_a);
        exp_b      = calc_operand_b(rs2_data, fwd_ex_mem, fwd_mem_wb, imm_ext, forward_b, alu_src);
        exp_result = calc_alu(exp_a, exp_b, alu_op);
        exp_zero   = calc_zero(exp_result);
        exp_bt     = calc_branch_target(pc, imm_ext);
        check_alu(exp_result, exp_zero, 64'd4);
        check_branch(exp_bt, 64'd4);

        // -------------------------------------------------------
        // Test 5: ADD with alu_src=1 (use imm_ext as operand B)
        // -------------------------------------------------------
        @(negedge clk);
        rs1_data   = 32'd10;
        rs2_data   = 32'd99; // should be ignored
        imm_ext    = 32'd20;
        pc         = 32'h0000_0010;
        fwd_ex_mem = 32'd0;
        fwd_mem_wb = 32'd0;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 1'b1;
        alu_op     = 2'b00;
        #2;
        exp_a      = calc_operand_a(rs1_data, fwd_ex_mem, fwd_mem_wb, forward_a);
        exp_b      = calc_operand_b(rs2_data, fwd_ex_mem, fwd_mem_wb, imm_ext, forward_b, alu_src);
        exp_result = calc_alu(exp_a, exp_b, alu_op);
        exp_zero   = calc_zero(exp_result);
        exp_bt     = calc_branch_target(pc, imm_ext);
        check_alu(exp_result, exp_zero, 64'd5);
        check_branch(exp_bt, 64'd5);

        // -------------------------------------------------------
        // Test 6: Forwarding from EX/MEM (forward_a=10, forward_b=10)
        // -------------------------------------------------------
        @(negedge clk);
        rs1_data   = 32'd1; // should be overridden
        rs2_data   = 32'd2; // should be overridden
        imm_ext    = 32'd16;
        pc         = 32'h0000_0014;
        fwd_ex_mem = 32'd100;
        fwd_mem_wb = 32'd200;
        forward_a  = 2'b10;
        forward_b  = 2'b10;
        alu_src    = 1'b0;
        alu_op     = 2'b00;
        #2;
        exp_a      = calc_operand_a(rs1_data, fwd_ex_mem, fwd_mem_wb, forward_a);
        exp_b      = calc_operand_b(rs2_data, fwd_ex_mem, fwd_mem_wb, imm_ext, forward_b, alu_src);
        exp_result = calc_alu(exp_a, exp_b, alu_op);
        exp
