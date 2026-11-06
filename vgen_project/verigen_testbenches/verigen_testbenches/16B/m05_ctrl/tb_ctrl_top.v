`timescale 1ns/1ps

module tb_ctrl_top;

    // DUT inputs
    reg [6:0] opcode;
    reg [2:0] phase;
    // Unused but required by testbench structure
    reg clk, rst;

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

    // Task: check outputs
    task check;
        input [63:0] desc_id;
        input exp_pc_write, exp_ir_write, exp_reg_write, exp_mem_write;
        input exp_alu_src_a, exp_alu_src_b, exp_mem_to_reg, exp_pc_source;
        input [255:0] desc;
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
                $display("PASS: opcode=%b phase=%0d - %s", opcode, phase, desc);
            else begin
                $display("FAIL: opcode=%b phase=%0d - %s", opcode, phase, desc);
                $display("  pc_write=%b(exp %b) ir_write=%b(exp %b) reg_write=%b(exp %b) mem_write=%b(exp %b)",
                    pc_write, exp_pc_write, ir_write, exp_ir_write,
                    reg_write, exp_reg_write, mem_write, exp_mem_write);
                $display("  alu_src_a=%b(exp %b) alu_src_b=%b(exp %b) mem_to_reg=%b(exp %b) pc_source=%b(exp %b)",
                    alu_src_a, exp_alu_src_a, alu_src_b, exp_alu_src_b,
                    mem_to_reg, exp_mem_to_reg, pc_source, exp_pc_source);
            end
        end
    endtask

    integer i;

    initial begin
        // Assert reset for 5 rising edges
        rst = 1;
        opcode = 7'b0000000;
        phase  = 3'b000;
        repeat(5) @(posedge clk);
        rst = 0;
        @(negedge clk);

        // -----------------------------------------------------------------------
        // Test 1: All-zero inputs (undefined opcode 0x00, phase 0)
        // Expected: all outputs 0
        // -----------------------------------------------------------------------
        opcode = 7'b0000000;
        phase  = 3'b000;
        #2;
        check(1, 0,0,0,0, 0,0,0,0, "all-zero opcode phase=0 -> all outputs 0");

        // -----------------------------------------------------------------------
        // Test 2: All-ones inputs (undefined opcode 0x7F, phase 7)
        // Expected: all outputs 0 (no matching opcode)
        // -----------------------------------------------------------------------
        opcode = 7'b1111111;
        phase  = 3'b111;
        #2;
        check(2, 0,0,0,0, 0,0,0,0, "all-ones opcode/phase -> all outputs 0");

        // -----------------------------------------------------------------------
        // Test 3: opcode = 7'h33 (7'b0110011) - R-type
        // DUT uses 7'b0010011 for alu_src_a/b; 7'b0110011 is undefined -> all 0
        // -----------------------------------------------------------------------
        opcode = 7'h33; // 7'b0110011
        phase  = 3'b010;
        #2;
        check(3, 0,0,0,0, 0,0,0,0, "opcode=7h33 (R-type RISC-V) phase=2 -> all 0 (not matched)");

        // -----------------------------------------------------------------------
        // Test 4: opcode = 7'h13 (7'b0010011) - matches alu_src_a/b in DUT
        // alu_src_a=1, alu_src_b=1; others 0
        // -----------------------------------------------------------------------
        opcode = 7'h13; // 7'b0010011
        phase  = 3'b001;
        #2;
        check(4, 0,0,0,0, 1,1,0,0, "opcode=7h13 (0010011) phase=1 -> alu_src_a=1 alu_src_b=1");

        // -----------------------------------------------------------------------
        // Test 5: opcode = 7'h03 (7'b0000011) - matches pc_write/ir_write/pc_source
        // pc_write=1, ir_write=1, pc_source=1; others 0
        // -----------------------------------------------------------------------
        opcode = 7'h03; // 7'b0000011
        phase  = 3'b000;
        #2;
        check(5, 1,1,0,0, 0,0,0,1, "opcode=7h03 (0000011) phase=0 -> pc_write=1 ir_write=1 pc_source=1");

        // -----------------------------------------------------------------------
        // Test 6: opcode = 7'h03, phase = 3 (another phase, same opcode)
        // Same combinational outputs (phase is not used in DUT logic for these)
        // -----------------------------------------------------------------------
        opcode = 7'h03; // 7'b0000011
        phase  = 3'b011;
        #2;
        check(6, 1,1,0,0, 0,0,0,1, "opcode=7h03 phase=3 -> pc_write=1 ir_write=1 pc_source=1");

        // -----------------------------------------------------------------------
        // Test 7: opcode = 7'h23 (7'b0100011) - undefined in DUT -> all 0
        // -----------------------------------------------------------------------
        opcode = 7'h23; // 7'b0100011
        phase  = 3'b010;
        #2;
        check(7, 0,0,0,0, 0,0,0,0, "opcode=7h23 phase=2 -> all 0 (undefined)");

        // -----------------------------------------------------------------------
        // Test 8: opcode = 7'h63 (7'b1100011) - undefined in DUT -> all 0
        // -----------------------------------------------------------------------
        opcode = 7'h63; // 7'b1100011
        phase  = 3'b100;
        #2;
        check(8, 0,0,0,0, 0,0,0,0, "opcode=7h63 phase=4 -> all 0 (undefined)");

        // -----------------------------------------------------------------------
        // Test 9: opcode = 7'b0000100 (matches reg_write/mem_write)
        // reg_write=1, mem_write=1; others 0
        // -----------------------------------------------------------------------
        opcode = 7'b0000100;
        phase  = 3'b001;
        #2;
        check(9, 0,0,1,1, 0,0,0,0, "opcode=0000100 phase=1 -> reg_write=1 mem_write=1");

        // -----------------------------------------------------------------------
        // Test 10: opcode = 7'b1011100 (matches mem_to_reg)
        // mem_to_reg=1; others 0
        // -----------------------------------------------------------------------
        opcode = 7'b1011100;
        phase  = 3'b011;
        #2;
        check(10, 0,0,0,0, 0,0,1,0, "opcode=1011100 phase=3 -> mem_to_reg=1");

        // -----------------------------------------------------------------------
        // Test 11: opcode = 7'b0010011, all phases 0..4
        // alu_src_a=1, alu_src_b=1 regardless of phase
        // -----------------------------------------------------------------------
        begin : phase_loop
            integer ph;
            for (ph = 0; ph <= 4; ph = ph + 1) begin
                opcode = 7'b0010011;
                phase  = ph[2:0];
                #2;
                check(11+ph, 0,0,0,0, 1,1,0,0, "opcode=0010011 phase=0..4 -> alu_src_a=1 alu_src_b=1");
            end
        end

        // -----------------------------------------------------------------------
        // Test 12: pc_write asserts ONLY for opcode=7'b0000011, not other opcodes
        // -----------------------------------------------------------------------
        opcode = 7'b0110011; phase = 3'b000; #2;
        if (pc_write === 0)
            $display("PASS: pc_write=0 for opcode=7b0110011 phase=0 (not 0000011)");
        else
            $display("FAIL: pc_write should be 0 for opcode=7b0110011 phase=0");

        opcode = 7'b0000011; phase = 3'b100; #2;
        if (pc_write === 1)
            $display("PASS: pc_write=1 for opcode=7b0000011 phase=4");
        else
            $display("FAIL: pc_write should be 1 for opcode=7b0000011 phase=4");

        // -----------------------------------------------------------------------
        // Test 13: Maximum opcode (7'b1111111), all phases
        // All outputs 0
        // -----------------------------------------------------------------------
        begin : maxphase_loop
            integer p2;
            for (p2 = 0; p2 <= 7; p2 = p2 + 1) begin
                opcode = 7'b1111111;
                phase  = p2[2:0];
                #2;
                check(20+p2, 0,0,0,0, 0,0,0,0, "opcode=1111111 -> all 0");
            end
        end

        $display("All tests complete.");
        $finish;
    end

endmodule
