`timescale 1ns/1ps
// Testbench for rv_ex_stage
// NOTE: The DUT source has severe synthesis errors (undefined signals, duplicate assigns, truncated code).
// This testbench instantiates the module and applies stimulus, checking outputs to the extent possible.
// Since the DUT cannot actually be compiled/simulated correctly, all checks are written
// defensively using $display PASS/FAIL logic.

module tb_rv_ex_stage;

    // DUT inputs (driven as reg)
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

    // DUT outputs (driven as wire)
    wire [31:0] alu_result;
    wire [31:0] branch_target;
    wire        zero;

    // Clock and reset (module is combinational, but use clock for timing)
    reg clk;
    reg rst;

    // Expected values for checking
    reg [31:0] exp_alu_result;
    reg [31:0] exp_branch_target;
    reg        exp_zero;

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

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Helper task to check a test vector
    // We compute expected values based on a correct implementation spec:
    //   forward_a: 00 = rs1_data, 01 = fwd_mem_wb, 10 = fwd_ex_mem
    //   forward_b: 00 = rs2_data, 01 = fwd_mem_wb, 10 = fwd_ex_mem
    //   alu_src: 0 = use forwarded rs2, 1 = use imm_ext
    //   alu_op:  00=ADD, 01=SUB, 10=AND, 11=OR
    //   branch_target = pc + imm_ext
    //   zero = (alu_result == 0)

    task compute_expected;
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
        output [31:0] e_alu_result;
        output [31:0] e_branch_target;
        output        e_zero;
        reg [31:0] op_a, op_b_raw, op_b;
        begin
            // Select operand A
            case (t_forward_a)
                2'b00: op_a = t_rs1_data;
                2'b01: op_a = t_fwd_mem_wb;
                2'b10: op_a = t_fwd_ex_mem;
                default: op_a = t_rs1_data;
            endcase
            // Select raw operand B (before alu_src mux)
            case (t_forward_b)
                2'b00: op_b_raw = t_rs2_data;
                2'b01: op_b_raw = t_fwd_mem_wb;
                2'b10: op_b_raw = t_fwd_ex_mem;
                default: op_b_raw = t_rs2_data;
            endcase
            // alu_src mux
            if (t_alu_src)
                op_b = t_imm_ext;
            else
                op_b = op_b_raw;
            // ALU operation
            case (t_alu_op)
                2'b00: e_alu_result = op_a + op_b;
                2'b01: e_alu_result = op_a - op_b;
                2'b10: e_alu_result = op_a & op_b;
                2'b11: e_alu_result = op_a | op_b;
                default: e_alu_result = 32'hx;
            endcase
            e_branch_target = t_pc + t_imm_ext;
            e_zero = (e_alu_result == 32'b0) ? 1'b1 : 1'b0;
        end
    endtask

    integer test_num;

    // Macro-like task to run one test vector
    task run_test;
        input [63:0]  test_id;
        input [31:0]  t_rs1_data;
        input [31:0]  t_rs2_data;
        input [31:0]  t_imm_ext;
        input [31:0]  t_pc;
        input [31:0]  t_fwd_ex_mem;
        input [31:0]  t_fwd_mem_wb;
        input [1:0]   t_forward_a;
        input [1:0]   t_forward_b;
        input         t_alu_src;
        input [1:0]   t_alu_op;
        reg [31:0]    e_alu_result;
        reg [31:0]    e_branch_target;
        reg           e_zero;
        begin
            // Apply inputs
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

            // Wait for combinational settling
            @(posedge clk);
            #1;

            // Compute expected
            compute_expected(
                t_rs1_data, t_rs2_data, t_imm_ext, t_pc,
                t_fwd_ex_mem, t_fwd_mem_wb,
                t_forward_a, t_forward_b, t_alu_src, t_alu_op,
                e_alu_result, e_branch_target, e_zero
            );

            // Check alu_result
            if (alu_result === e_alu_result)
                $display("PASS: Test%0d alu_result=0x%08h (expected 0x%08h)", test_id, alu_result, e_alu_result);
            else
                $display("FAIL: Test%0d alu_result=0x%08h (expected 0x%08h)", test_id, alu_result, e_alu_result);

            // Check branch_target
            if (branch_target === e_branch_target)
                $display("PASS: Test%0d branch_target=0x%08h (expected 0x%08h)", test_id, branch_target, e_branch_target);
            else
                $display("FAIL: Test%0d branch_target=0x%08h (expected 0x%08h)", test_id, branch_target, e_branch_target);

            // Check zero
            if (zero === e_zero)
                $display("PASS: Test%0d zero=%b (expected %b)", test_id, zero, e_zero);
            else
                $display("FAIL: Test%0d zero=%b (expected %b)", test_id, zero, e_zero);
        end
    endtask

    initial begin
        // Initialize all inputs
        rs1_data   = 0;
        rs2_data   = 0;
        imm_ext    = 0;
        pc         = 0;
        fwd_ex_mem = 0;
        fwd_mem_wb = 0;
        forward_a  = 2'b00;
        forward_b  = 2'b00;
        alu_src    = 0;
        alu_op     = 2'b00;
        rst        = 1;

        // Assert reset for 5 rising edges
        repeat (5) @(posedge clk);
        rst = 0;

        // Wait one more cycle after reset deassert
        @(posedge clk);

        // -------------------------------------------------------
        // Test 1: ADD with no forwarding, alu_src=0
        // rs1=5, rs2=3, expected alu_result=8, branch_target=pc+imm
        // -------------------------------------------------------
        run_test(1,
            32'd5,       // rs1_data
            32'd3,       // rs2_data
            32'd4,       // imm_ext
            32'h00000100,// pc
            32'd0,       // fwd_ex_mem
            32'd0,       // fwd_mem_wb
            2'b00,       // forward_a = rs1
            2'b00,       // forward_b = rs2
            1'b0,        // alu_src = rs2
            2'b00        // alu_op = ADD
        );

        // -------------------------------------------------------
        // Test 2: SUB resulting in zero (zero flag check)
        // rs1=10, rs2=10, alu_op=SUB => result=0, zero=1
        // -------------------------------------------------------
        run_test(2,
            32'd10,
            32'd10,
            32'd8,
            32'h00000200,
            32'd0,
            32'd0,
            2'b00,
            2'b00,
            1'b0,
            2'b01        // SUB
        );

        // -------------------------------------------------------
        // Test 3: AND operation
        // rs1=0xFF00FF00, rs2=0x0F0F0F0F => result=0x0F000F00
        // -------------------------------------------------------
        run_test(3,
            32'hFF00FF00,
            32'h0F0F0F0F,
            32'd0,
            32'h00000300,
            32'd0,
            32'd0,
            2'b00,
            2'b00,
            1'b0,
            2'b10        // AND
        );

        // -------------------------------------------------------
        // Test 4: OR operation
        // rs1=0xF0F0F0F0, rs2=0x0F0F0F0F => result=0xFFFFFFFF
        // -------------------------------------------------------
        run_test(4,
            32'hF0F0F0F0,
            32'h0F0F0F0F,
            32'd0,
            32'h00000400,
            32'd0,
            32'd0,
            2'b00,
            2'b00,
            1'b0,
            2'b11        // OR
        );

        // -------------------------------------------------------
        // Test 5: Forwarding from EX/MEM (forward_a=10, forward_b=10)
        // fwd_ex_mem = 100, alu_src=0, alu_op=ADD => 100+100=200
        // -------------------------------------------------------
        run_test(5,
            32'd0,       // rs1 not used (forward_a=10)
            32'd0,       // rs2 not used (forward_b=10)
            32'd50,      // imm_ext
            32'h00000500,
            32'd100,     // fwd_ex_mem
            32'd0,       // fwd_mem_wb
            2'b10,       // forward_a = fwd_ex_mem
            2'b10,       // forward_b = fwd_ex_mem
            1'b0,        // alu_src = forwarded rs2
            2'b00        // ADD
        );

        // -------------------------------------------------------
        // Test 6: Forwarding from MEM/WB (forward_a=01, forward_b=01)
        // fwd_mem_wb = 77, alu_op=SUB => 77-77=0, zero=1
        // -------------------------------------------------------
        run_test(6,
            32'd0,
            32'd0,
            32'd100,
            32'h00000600,
            32'd0,
            32'd77,      // fwd_mem_wb
            2'b01,       // forward_a = fwd_mem_wb
            2'b01,       // forward_b = fwd_mem_wb
            1'b0,
            2'b01        // SUB
        );

        // -------------------------------------------------------
        // Test 7: alu_src=1 (use immediate), ADD
        // rs1=10, imm=20 => 10+20=30
        // -------------------------------------------------------
        run_test(7,
            32'd10,
            32'd99,      // rs2 not used
            32'd20,      // imm_ext
            32'h00000700,
            32'd0,
            32'd0,
            2'b00,
            2'b00,
            1'b1,        // alu_src = imm
            2'b00        // ADD
        );

        // -------------------------------------------------------
        // Test 8: All-zero inputs
        // -------------------------------------------------------
        run_test(8,
            32'h00000000,
            32'h00000000,
            32'h00000000,
            32'h00000000,
            32'h00000000,
            32'h00000000,
            2'b00,
            2'b00,
            1'b0,
            2'b00        // ADD => 0+0=0, zero=1
        );

        // -------------------------------------------------------
        // Test 9: All-ones inputs, OR operation
        // -------------------------------------------------------
        run_test(9,
            32'hFFFFFFFF,
            32'hFFFFFFFF,
            32'hFFFFFFFF,
            32'hFFFFFFFF,
            32'hFFFFFFFF,
            32'hFFFFFFFF,
            2'b00,
            2'b00,
            1'b0,
            2'b11        // OR => 0xFFFFFFFF
        );

        // -------------------------------------------------------
        // Test 10: Max value ADD (overflow check)
        // rs1=0xFFFFFFFF, rs2=1 => result=0 (overflow), zero=1
        // -------------------------------------------------------
        run_test(10,
            32'hFFFFFFFF,
            32'd1,
            32'd8,
            32'h00001000,
            32'd0,
            32'd0,
            2'b00,
            2'b00,
            1'b0,
            2'b00        // ADD overflow
        );

        // -------------------------------------------------------
        // Test 11:
