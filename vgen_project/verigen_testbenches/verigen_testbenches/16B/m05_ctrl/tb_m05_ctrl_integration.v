`timescale 1ns/1ps

module tb_m05_ctrl_integration;

    // DUT inputs
    reg [6:0] opcode;
    reg [2:0] phase;
    reg       clk;

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

    // Reset (not a port, but we'll synchronize test start to 5 rising edges)
    integer i;
    integer pass_count;
    integer fail_count;

    // Task to check outputs
    task check_outputs;
        input [6:0] t_opcode;
        input [2:0] t_phase;
        input exp_pc_write;
        input exp_ir_write;
        input exp_reg_write;
        input exp_mem_write;
        input exp_alu_src_a;
        input exp_alu_src_b;
        input exp_mem_to_reg;
        input exp_pc_source;
        input [63:0] test_id;
        reg failed;
        begin
            failed = 0;
            opcode = t_opcode;
            phase  = t_phase;
            #2; // small settling time (combinational)

            if (pc_write   !== exp_pc_write)   failed = 1;
            if (ir_write   !== exp_ir_write)   failed = 1;
            if (reg_write  !== exp_reg_write)  failed = 1;
            if (mem_write  !== exp_mem_write)  failed = 1;
            if (alu_src_a  !== exp_alu_src_a)  failed = 1;
            if (alu_src_b  !== exp_alu_src_b)  failed = 1;
            if (mem_to_reg !== exp_mem_to_reg) failed = 1;
            if (pc_source  !== exp_pc_source)  failed = 1;

            if (failed) begin
                $display("FAIL: opcode=%b phase=%b | got pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b | exp %b %b %b %b %b %b %b %b",
                    t_opcode, t_phase,
                    pc_write, ir_write, reg_write, mem_write,
                    alu_src_a, alu_src_b, mem_to_reg, pc_source,
                    exp_pc_write, exp_ir_write, exp_reg_write, exp_mem_write,
                    exp_alu_src_a, exp_alu_src_b, exp_mem_to_reg, exp_pc_source);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS: opcode=%b phase=%b -> pc_write=%b ir_write=%b reg_write=%b mem_write=%b alu_src_a=%b alu_src_b=%b mem_to_reg=%b pc_source=%b",
                    t_opcode, t_phase,
                    pc_write, ir_write, reg_write, mem_write,
                    alu_src_a, alu_src_b, mem_to_reg, pc_source);
                pass_count = pass_count + 1;
            end
        end
    endtask

    // Expected output computation
    // pc_write  = (opcode == 7'b0000011)
    // ir_write  = (opcode == 7'b0000011)
    // reg_write = (opcode == 7'b0000100)
    // mem_write = (opcode == 7'b0000100)
    // alu_src_a = (opcode == 7'b0010011)
    // alu_src_b = (opcode == 7'b0010011)
    // mem_to_reg= (opcode == 7'b1011100)
    // pc_source = (opcode == 7'b0000011)

    initial begin
        pass_count = 0;
        fail_count = 0;

        opcode = 7'b0000000;
        phase  = 3'b000;

        // Synchronize: wait for 5 rising edges (simulate "reset" period)
        for (i = 0; i < 5; i = i + 1) begin
            @(posedge clk);
        end
        #1; // slight offset after last edge

        // ------------------------------------------------------------------
        // Test all phases with all relevant opcodes
        // ------------------------------------------------------------------

        // === Branch opcode: 7'b0000011 ===
        // Expected: pc_write=1, ir_write=1, reg_write=0, mem_write=0,
        //           alu_src_a=0, alu_src_b=0, mem_to_reg=0, pc_source=1
        begin : branch_tests
            reg [2:0] ph;
            for (ph = 3'b000; ph <= 3'b111; ph = ph + 1) begin
                check_outputs(7'b0000011, ph,
                    1'b1, 1'b1, 1'b0, 1'b0,
                    1'b0, 1'b0, 1'b0, 1'b1,
                    64'd1);
                @(posedge clk); #1;
            end
        end

        // === R-format / reg_write opcode: 7'b0000100 ===
        // Expected: pc_write=0, ir_write=0, reg_write=1, mem_write=1,
        //           alu_src_a=0, alu_src_b=0, mem_to_reg=0, pc_source=0
        begin : rformat_tests
            reg [2:0] ph;
            for (ph = 3'b000; ph <= 3'b111; ph = ph + 1) begin
                check_outputs(7'b0000100, ph,
                    1'b0, 1'b0, 1'b1, 1'b1,
                    1'b0, 1'b0, 1'b0, 1'b0,
                    64'd2);
                @(posedge clk); #1;
            end
        end

        // === ALU opcode: 7'b0010011 ===
        // Expected: pc_write=0, ir_write=0, reg_write=0, mem_write=0,
        //           alu_src_a=1, alu_src_b=1, mem_to_reg=0, pc_source=0
        begin : alu_tests
            reg [2:0] ph;
            for (ph = 3'b000; ph <= 3'b111; ph = ph + 1) begin
                check_outputs(7'b0010011, ph,
                    1'b0, 1'b0, 1'b0, 1'b0,
                    1'b1, 1'b1, 1'b0, 1'b0,
                    64'd3);
                @(posedge clk); #1;
            end
        end

        // === Load/Store opcode: 7'b1011100 ===
        // Expected: pc_write=0, ir_write=0, reg_write=0, mem_write=0,
        //           alu_src_a=0, alu_src_b=0, mem_to_reg=1, pc_source=0
        begin : load_store_tests
            reg [2:0] ph;
            for (ph = 3'b000; ph <= 3'b111; ph = ph + 1) begin
                check_outputs(7'b1011100, ph,
                    1'b0, 1'b0, 1'b0, 1'b0,
                    1'b0, 1'b0, 1'b1, 1'b0,
                    64'd4);
                @(posedge clk); #1;
            end
        end

        // === Default/Other opcode: 7'b0000000 ===
        // All outputs should be 0
        begin : default_tests
            reg [2:0] ph;
            for (ph = 3'b000; ph <= 3'b111; ph = ph + 1) begin
                check_outputs(7'b0000000, ph,
                    1'b0, 1'b0, 1'b0, 1'b0,
                    1'b0, 1'b0, 1'b0, 1'b0,
                    64'd5);
                @(posedge clk); #1;
            end
        end

        // === Another arbitrary opcode: 7'b1111111 ===
        // All outputs should be 0
        begin : arb_tests
            reg [2:0] ph;
            for (ph = 3'b000; ph <= 3'b111; ph = ph + 1) begin
                check_outputs(7'b1111111, ph,
                    1'b0, 1'b0, 1'b0, 1'b0,
                    1'b0, 1'b0, 1'b0, 1'b0,
                    64'd6);
                @(posedge clk); #1;
            end
        end

        // === More boundary opcodes ===
        // 7'b0000001 - none of the special opcodes
        check_outputs(7'b0000001, 3'b000,
            1'b0, 1'b0, 1'b0, 1'b0,
            1'b0, 1'b0, 1'b0, 1'b0,
            64'd7);
        @(posedge clk); #1;

        check_outputs(7'b0000001, 3'b011,
            1'b0, 1'b0, 1'b0, 1'b0,
            1'b0, 1'b0, 1'b0, 1'b0,
            64'd8);
        @(posedge clk); #1;

        // 7'b0010000 - none of the special opcodes
        check_outputs(7'b0010000, 3'b101,
            1'b0, 1'b0, 1'b0, 1'b0,
            1'b0, 1'b0, 1'b0, 1'b0,
            64'd9);
        @(posedge clk); #1;

        // Double-check branch at phase 0 and 4
        check_outputs(7'b0000011, 3'b000,
            1'b1, 1'b1, 1'b0, 1'b0,
            1'b0, 1'b0, 1'b0, 1'b1,
            64'd10);
        @(posedge clk); #1;

        check_outputs(7'b0000011, 3'b100,
            1'b1, 1'b1, 1'b0, 1'b0,
            1'b0, 1'b0, 1'b0, 1'b1,
            64'd11);
        @(posedge clk); #1;

        // Double-check reg_write opcode at phase 2 and 7
        check_outputs(7'b0000100, 3'b010,
            1'b0, 1'b0, 1'b1, 1'b1,
            1'b0, 1'b0, 1'b0, 1'b0,
            64'd12);
        @(posedge clk); #1;

        check_outputs(7'b0000100, 3'b111,
            1'b0, 1'b0, 1'b1, 1'b1,
            1'b0, 1'b0, 1'b0, 1'b0,
            64'd13);
        @(posedge clk); #1;

        // Double-check alu at phase 5
        check_outputs(7'b0010011, 3'b101,
            1'b0, 1'b0, 1'b0, 1'b0,
            1'b1, 1'b1, 1'b0, 1'b0,
            64'd14);
        @(posedge clk); #1;

        // Double-check load/store at phase 6
        check_outputs(7'b1011100, 3'b110,
            1'b0, 1'b0, 1'b0, 1'b0,
            1'b0, 1'b0, 1'b1, 1'b0,
            64'd15);
        @(posedge clk); #1;

        // ------------------------------------------------------------------
        // Summary
        // ------------------------------------------------------------------
        $display("-----------------------------------");
        $display("Integration Test Summary: PASS=%0d  FAIL=%0d", pass_count, fail_count);
        if (fail_count == 0)
            $display("PASS: All integration tests passed.");
        else
            $display("FAIL: %0d integration test(s) failed.", fail_count);
        $display("-----------------------------------");

        $finish;
    end

endmodule
