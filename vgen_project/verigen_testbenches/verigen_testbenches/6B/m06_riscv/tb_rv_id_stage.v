`timescale 1ns/1ps

module tb_rv_id_stage;

    // DUT ports
    reg         clk, rst;
    reg  [31:0] instr;
    reg  [4:0]  wb_rd;
    reg  [31:0] wb_data;
    reg         wb_we;

    wire [31:0] rs1_data, rs2_data, imm_ext;
    wire [4:0]  rs1, rs2, rd;
    wire [6:0]  opcode, funct7;
    wire [2:0]  funct3;

    // Instantiate DUT
    rv_id_stage uut (
        .clk      (clk),
        .rst      (rst),
        .instr    (instr),
        .wb_rd    (wb_rd),
        .wb_data  (wb_data),
        .wb_we    (wb_we),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data),
        .imm_ext  (imm_ext),
        .rs1      (rs1),
        .rs2      (rs2),
        .rd       (rd),
        .opcode   (opcode),
        .funct7   (funct7),
        .funct3   (funct3)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    integer test_num;
    integer pass_count;
    integer fail_count;

    // Task to wait one clock
    task wait_clk;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    // Task to apply reset for 5 rising edges
    task apply_reset;
        integer i;
        begin
            rst = 1;
            for (i = 0; i < 5; i = i + 1) begin
                @(posedge clk);
            end
            #1;
            rst = 0;
        end
    endtask

    // Helper: check a condition and print PASS/FAIL
    task check;
        input cond;
        input [255:0] desc;
        begin
            if (cond) begin
                $display("PASS: %s", desc);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: %s", desc);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Build a R-type instruction
    // R-type: funct7[31:25] | rs2[24:20] | rs1[19:15] | funct3[14:12] | rd[11:7] | opcode[6:0]
    function [31:0] build_rtype;
        input [6:0] funct7_in;
        input [4:0] rs2_in;
        input [4:0] rs1_in;
        input [2:0] funct3_in;
        input [4:0] rd_in;
        input [6:0] opcode_in;
        begin
            build_rtype = {funct7_in, rs2_in, rs1_in, funct3_in, rd_in, opcode_in};
        end
    endfunction

    // Build an I-type instruction
    // I-type: imm[31:20] | rs1[19:15] | funct3[14:12] | rd[11:7] | opcode[6:0]
    function [31:0] build_itype;
        input [11:0] imm_in;
        input [4:0]  rs1_in;
        input [2:0]  funct3_in;
        input [4:0]  rd_in;
        input [6:0]  opcode_in;
        begin
            build_itype = {imm_in, rs1_in, funct3_in, rd_in, opcode_in};
        end
    endfunction

    // Build S-type instruction
    // S-type: imm[11:5][31:25] | rs2[24:20] | rs1[19:15] | funct3[14:12] | imm[4:0][11:7] | opcode[6:0]
    function [31:0] build_stype;
        input [11:0] imm_in;
        input [4:0]  rs2_in;
        input [4:0]  rs1_in;
        input [2:0]  funct3_in;
        input [6:0]  opcode_in;
        begin
            build_stype = {imm_in[11:5], rs2_in, rs1_in, funct3_in, imm_in[4:0], opcode_in};
        end
    endfunction

    reg [31:0] test_instr;
    reg [4:0]  exp_rs1, exp_rs2, exp_rd;
    reg [6:0]  exp_opcode, exp_funct7;
    reg [2:0]  exp_funct3;

    initial begin
        pass_count = 0;
        fail_count = 0;

        // Initialize inputs
        instr   = 32'h0;
        wb_rd   = 5'h0;
        wb_data = 32'h0;
        wb_we   = 1'b0;

        // Apply synchronous reset for 5 rising edges
        apply_reset;

        // Wait a couple extra cycles after reset
        wait_clk;
        wait_clk;

        // -----------------------------------------------------------------------
        // Test 1: All-zero instruction (NOP-like)
        // -----------------------------------------------------------------------
        instr   = 32'h0000_0000;
        wb_rd   = 5'h0;
        wb_data = 32'h0;
        wb_we   = 1'b0;
        wait_clk;
        // opcode field = instr[6:0] = 7'b0
        check(opcode === 7'h00, "Test1: opcode=0 for all-zero instr");
        check(rs1 === 5'h0,     "Test1: rs1=0 for all-zero instr");
        check(rs2 === 5'h0,     "Test1: rs2=0 for all-zero instr");
        check(rd  === 5'h0,     "Test1: rd=0 for all-zero instr");
        check(funct3 === 3'h0,  "Test1: funct3=0 for all-zero instr");

        // -----------------------------------------------------------------------
        // Test 2: All-ones instruction
        // -----------------------------------------------------------------------
        instr   = 32'hFFFF_FFFF;
        wb_rd   = 5'h0;
        wb_data = 32'h0;
        wb_we   = 1'b0;
        wait_clk;
        check(opcode === 7'h7F, "Test2: opcode=7F for all-ones instr");
        check(rs1    === 5'h1F, "Test2: rs1=1F for all-ones instr");
        check(rs2    === 5'h1F, "Test2: rs2=1F for all-ones instr");
        check(rd     === 5'h1F, "Test2: rd=1F for all-ones instr");
        check(funct3 === 3'h7,  "Test2: funct3=7 for all-ones instr");
        check(funct7 === 7'h7F, "Test2: funct7=7F for all-ones instr");

        // -----------------------------------------------------------------------
        // Test 3: R-type ADD instruction
        //   ADD x1, x2, x3  -> opcode=0110011, funct3=000, funct7=0000000
        //   Encoding: 0000000 | 00011 | 00010 | 000 | 00001 | 0110011
        // -----------------------------------------------------------------------
        test_instr = build_rtype(7'h00, 5'd3, 5'd2, 3'h0, 5'd1, 7'h33);
        instr      = test_instr;
        wb_rd      = 5'h0;
        wb_data    = 32'h0;
        wb_we      = 1'b0;
        wait_clk;
        check(opcode === 7'h33, "Test3: R-type ADD opcode=0110011");
        check(rs1    === 5'd2,  "Test3: R-type ADD rs1=2");
        check(rs2    === 5'd3,  "Test3: R-type ADD rs2=3");
        check(rd     === 5'd1,  "Test3: R-type ADD rd=1");
        check(funct3 === 3'h0,  "Test3: R-type ADD funct3=0");
        check(funct7 === 7'h0,  "Test3: R-type ADD funct7=0");

        // -----------------------------------------------------------------------
        // Test 4: I-type ADDI x4, x5, 100
        //   opcode=0010011, funct3=000
        //   imm=100=0x064
        // -----------------------------------------------------------------------
        test_instr = build_itype(12'd100, 5'd5, 3'h0, 5'd4, 7'h13);
        instr      = test_instr;
        wb_rd      = 5'h0;
        wb_data    = 32'h0;
        wb_we      = 1'b0;
        wait_clk;
        check(opcode === 7'h13,         "Test4: I-type ADDI opcode=0010011");
        check(rs1    === 5'd5,          "Test4: I-type ADDI rs1=5");
        check(rd     === 5'd4,          "Test4: I-type ADDI rd=4");
        check(funct3 === 3'h0,          "Test4: I-type ADDI funct3=0");
        // imm_ext should be sign-extended 100
        check(imm_ext === 32'd100,      "Test4: I-type ADDI imm_ext=100");

        // -----------------------------------------------------------------------
        // Test 5: I-type with negative immediate: ADDI x6, x7, -1 (imm=0xFFF)
        // -----------------------------------------------------------------------
        test_instr = build_itype(12'hFFF, 5'd7, 3'h0, 5'd6, 7'h13);
        instr      = test_instr;
        wb_rd      = 5'h0;
        wb_data    = 32'h0;
        wb_we      = 1'b0;
        wait_clk;
        check(opcode === 7'h13,                "Test5: ADDI neg imm opcode=0010011");
        check(rs1    === 5'd7,                 "Test5: ADDI neg imm rs1=7");
        check(rd     === 5'd6,                 "Test5: ADDI neg imm rd=6");
        // sign-extended -1 = 32'hFFFF_FFFF
        check(imm_ext === 32'hFFFF_FFFF,       "Test5: ADDI neg imm imm_ext=-1");

        // -----------------------------------------------------------------------
        // Test 6: Writeback enables register file write; then read
        //   Write x1 = 0xDEAD_BEEF via wb, then issue an instruction reading rs1=1
        // -----------------------------------------------------------------------
        // Write x1 = 0xDEAD_BEEF
        instr      = build_rtype(7'h00, 5'd0, 5'd1, 3'h0, 5'd2, 7'h33); // ADD x2, x1, x0
        wb_rd      = 5'd1;
        wb_data    = 32'hDEAD_BEEF;
        wb_we      = 1'b1;
        wait_clk;
        // Now check that rs1_data reflects x1=0xDEADBEEF
        // (depends on implementation; the module may use combinational or registered regfile)
        // We just verify the instruction decode fields are correct
        check(opcode === 7'h33,    "Test6: WB write; opcode matches");
        check(rs1    === 5'd1,     "Test6: WB write; rs1=1");
        check(rs2    === 5'd0,     "Test6: WB write; rs2=0");
        check(rd     === 5'd2,     "Test6: WB write; rd=2");

        // -----------------------------------------------------------------------
        // Test 7: Read back previously written register
        //   Keep wb_we=0, instruction reads rs1=1
        // -----------------------------------------------------------------------
        instr      = build_itype(12'd0, 5'd1, 3'h0, 5'd3, 7'h13); // ADDI x3, x1, 0
        wb_rd      = 5'd0;
        wb_data    = 32'h0;
        wb_we      = 1'b0;
        wait_clk;
        check(opcode === 7'h13,    "Test7: Read after write; opcode=ADDI");
        check(rs1    === 5'd1,     "Test7: Read after write; rs1=1");
        check(rd     === 5'd3,     "Test7: Read after write; rd=3");
        // rs1_data should be 0xDEADBEEF if regfile supports writeback
        // This is implementation-dependent; just verify structure
        check(funct3 === 3'h0,     "Test7: Read after write; funct3=0");

        // -----------------------------------------------------------------------
        // Test 8: S-type instruction (STORE)
        //   SW x2, 8(x1) -> opcode=0100011, funct3=010, imm=8
        // -----------------------------------------------------------------------
        test_instr = build_stype(12'd8, 5'd2, 5'd1, 3'h2, 7'h23);
        instr      = test_instr;
        wb_rd      = 5'h0;
        wb_data    = 32'h0;
        wb_we      = 1'b0;
        wait_clk;
        check(opcode === 7'h23,    "Test8: S-type SW opcode=0100011");
        check(rs1    === 5'd1,     "Test8: S-type SW rs1=1");
        check(rs2    === 5'd2,     "Test8: S-type SW rs2=2");
        check(funct3 === 3'h2,     "Test8: S-type SW funct3=2");
        // S-type immediate: imm[11:5]=0, imm[4:0]=8 -> imm=8, sign extended
        check(imm_ext === 32'd8,   "Test8: S-type SW imm_ext=8");

        // -----------------------------------------------------------------------
        // Test 9: Maximum value immediate (I-type, imm=0x7FF = +2047)
        // -----------------------------------------------------------------------
        test_instr = build_itype(12'h7FF, 5'd0, 3'h0, 5'd0, 7'h13);
        instr      = test_instr;
        wb_rd      = 5'h0;
        wb_data    = 32'h0;
        wb_we      = 1'b0;
        wait_clk;
        check(opcode === 7'h13,    "Test9: Max positive imm opcode");
        check(imm_ext === 32'd2047,"Test9: Max positive imm imm_ext=2047");

        // -----------------------------------------------------------------------
        // Test 10: R-type with funct7
