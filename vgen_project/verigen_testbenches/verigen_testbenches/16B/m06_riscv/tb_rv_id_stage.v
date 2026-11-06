`timescale 1ns/1ps

module tb_rv_id_stage;

    // DUT ports
    reg         clk;
    reg         rst;
    reg  [31:0] instr;
    reg  [4:0]  wb_rd;
    reg  [31:0] wb_data;
    reg         wb_we;

    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] imm_ext;
    wire [4:0]  rs1;
    wire [4:0]  rs2;
    wire [4:0]  rd;
    wire [6:0]  opcode;
    wire [6:0]  funct7;
    wire [2:0]  funct3;

    // DUT instantiation
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

    integer fail_count;

    // Task to wait one clock and check outputs
    task wait_clk;
        begin
            @(posedge clk);
            #1; // small delay after edge for output settle
        end
    endtask

    initial begin
        fail_count = 0;

        // Initialize inputs
        rst     = 1;
        instr   = 32'b0;
        wb_rd   = 5'b0;
        wb_data = 32'b0;
        wb_we   = 1'b0;

        // Assert reset for exactly 5 rising edges
        repeat(5) @(posedge clk);
        #1;
        rst = 0;

        // ---------------------------------------------------------------
        // Test 1: All-zero instruction, wb_rd=0, wb_data=0, wb_we=0
        // After reset deassert, apply zero instruction
        // ---------------------------------------------------------------
        instr   = 32'h0000_0000;
        wb_rd   = 5'd0;
        wb_data = 32'h0000_0000;
        wb_we   = 1'b0;
        wait_clk;
        // rs1 = instr_i[25:21], instr_i is latched on posedge, so instr_i = prev instr = 0
        // After reset, instr_i=0 => rs1=0, rs2=0, funct3=0
        // rd driven by wb_rd=0 combinationally => rd=0
        // rs1_data = wb_data = 0, rs2_data=0, imm_ext=0
        if (rs1 === 5'd0 && rs2 === 5'd0 && rd === 5'd0 &&
            rs1_data === 32'd0 && rs2_data === 32'd0 && imm_ext === 32'd0)
            $display("PASS: Test1 - All-zero instruction and wb signals");
        else begin
            $display("FAIL: Test1 - All-zero instruction and wb signals rs1=%0d rs2=%0d rd=%0d rs1_data=%0h rs2_data=%0h imm_ext=%0h",
                      rs1, rs2, rd, rs1_data, rs2_data, imm_ext);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 2: R-type instruction fields extracted correctly
        // instr = {funct7=0b0000000, rs2=5, rs1=3, funct3=000, rd=2, opcode=0110011}
        // bit layout [31:0]: funct7[31:25] rs2[24:20] rs1[19:15] funct3[14:12] rd[11:7] opcode[6:0]
        // BUT this DUT uses non-standard bit layout: rs1=instr_i[25:21], rs2=instr_i[20:16], rd=instr_i[15:11], funct3=instr_i[14:12]
        // So let's construct according to DUT's fields:
        // instr[25:21]=rs1_field=5, instr[20:16]=rs2_field=3, instr[15:11]=rd_field=2, instr[14:12]=funct3=3'b001
        // ---------------------------------------------------------------
        instr   = 32'b0000_0000_0_00101_00011_001_00010_0110011; 
        // bits: [31:26]=0, [25:21]=5, [20:16]=3, [15:11]=2, [14:12]=001, [6:0]=0110011
        // Let me build it carefully:
        // instr[25:21] = 5'd5  => bits 25-21
        // instr[20:16] = 5'd3  => bits 20-16
        // instr[15:11] = 5'd2  => bits 15-11
        // instr[14:12] = 3'b001
        // instr[6:0]   = 7'b0110011
        instr = {6'b000000, 5'd5, 5'd3, 3'b001, 5'd2, 7'b0110011};
        // Wait one clock so instr_i latches this value
        wb_rd   = 5'd5;
        wb_data = 32'hDEAD_BEEF;
        wb_we   = 1'b1;
        wait_clk;
        // Now instr_i should hold previous instr (all-zero from test1), 
        // But we applied new instr before wait_clk, so instr_i latches new instr on this edge
        // Wait another cycle for instr_i to have our new instruction
        wait_clk;
        // Now instr_i = constructed instr => rs1=5, rs2=3, rd=5 (from wb_rd combinational), funct3=001
        // rd is set by combinational case on wb_rd=5 => rd=5
        if (rs1 === 5'd5 && rs2 === 5'd3 && funct3 === 3'b001)
            $display("PASS: Test2 - R-type field extraction rs1=%0d rs2=%0d funct3=%0b", rs1, rs2, funct3);
        else begin
            $display("FAIL: Test2 - R-type field extraction rs1=%0d (exp 5) rs2=%0d (exp 3) funct3=%0b (exp 001)",
                      rs1, rs2, funct3);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 3: wb_data forwarded to rs1_data, rs2_data, imm_ext
        // ---------------------------------------------------------------
        wb_rd   = 5'd7;
        wb_data = 32'hCAFE_BABE;
        wb_we   = 1'b1;
        instr   = 32'h0000_0000;
        wait_clk;
        if (rs1_data === 32'hCAFE_BABE && rs2_data === 32'hCAFE_BABE && imm_ext === 32'hCAFE_BABE)
            $display("PASS: Test3 - wb_data forwarded to rs1_data/rs2_data/imm_ext");
        else begin
            $display("FAIL: Test3 - wb_data forwarding rs1_data=%0h rs2_data=%0h imm_ext=%0h (all exp CAFEBABE)",
                      rs1_data, rs2_data, imm_ext);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 4: wb_rd=0 => rd=0 (register x0 always 0)
        // ---------------------------------------------------------------
        wb_rd   = 5'd0;
        wb_data = 32'hFFFF_FFFF;
        wb_we   = 1'b1;
        instr   = {6'b0, 5'd0, 5'd0, 3'b000, 5'd0, 7'b0};
        wait_clk;
        if (rd === 5'd0)
            $display("PASS: Test4 - wb_rd=0 -> rd=0");
        else begin
            $display("FAIL: Test4 - wb_rd=0 -> rd=%0d (exp 0)", rd);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 5: wb_rd=31 (max value), wb_data=all-ones
        // ---------------------------------------------------------------
        wb_rd   = 5'd31;
        wb_data = 32'hFFFF_FFFF;
        wb_we   = 1'b1;
        instr   = {6'b0, 5'd31, 5'd31, 3'b111, 5'd31, 7'b1111111};
        wait_clk;
        if (rd === 5'd31 && rs1_data === 32'hFFFF_FFFF && rs2_data === 32'hFFFF_FFFF)
            $display("PASS: Test5 - wb_rd=31 max value, all-ones wb_data");
        else begin
            $display("FAIL: Test5 - wb_rd=31 rd=%0d rs1_data=%0h rs2_data=%0h",
                      rd, rs1_data, rs2_data);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 6: wb_we=0, check outputs still present (combinational)
        // ---------------------------------------------------------------
        wb_rd   = 5'd10;
        wb_data = 32'h1234_5678;
        wb_we   = 1'b0;
        instr   = {6'b0, 5'd10, 5'd10, 3'b010, 5'd10, 7'b0};
        wait_clk;
        if (rs1_data === 32'h1234_5678 && rd === 5'd10)
            $display("PASS: Test6 - wb_we=0, outputs still driven combinationally");
        else begin
            $display("FAIL: Test6 - wb_we=0 rs1_data=%0h (exp 12345678) rd=%0d (exp 10)",
                      rs1_data, rd);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 7: Change wb_rd mid-stream, verify rd follows combinationally
        // ---------------------------------------------------------------
        wb_rd   = 5'd15;
        wb_data = 32'hABCD_EF01;
        wb_we   = 1'b1;
        instr   = {6'b0, 5'd15, 5'd15, 3'b101, 5'd15, 7'b0};
        #1; // purely combinational check before clock
        if (rd === 5'd15 && rs1_data === 32'hABCD_EF01)
            $display("PASS: Test7 - Combinational rd follows wb_rd=15 immediately");
        else begin
            $display("FAIL: Test7 - Combinational check rd=%0d (exp 15) rs1_data=%0h (exp ABCDEF01)",
                      rd, rs1_data);
            fail_count = fail_count + 1;
        end
        wait_clk;

        // ---------------------------------------------------------------
        // Test 8: Assert reset again and verify all outputs zero
        // ---------------------------------------------------------------
        rst = 1;
        instr   = 32'hFFFF_FFFF;
        wb_rd   = 5'd31;
        wb_data = 32'hFFFF_FFFF;
        wb_we   = 1'b1;
        repeat(5) @(posedge clk);
        #1;
        // After reset, internal registers should be zero
        // opcode and funct7 are driven by reg_opcode/reg_funct7 which are reset to 0
        if (opcode === 7'b0 && funct7 === 7'b0 && imm_ext === 32'b0)
            $display("PASS: Test8 - Re-assert reset clears registered outputs (opcode=0, funct7=0, imm_ext=0)");
        else begin
            $display("FAIL: Test8 - Reset check opcode=%0b funct7=%0b imm_ext=%0h",
                      opcode, funct7, imm_ext);
            fail_count = fail_count + 1;
        end
        rst = 0;

        // ---------------------------------------------------------------
        // Test 9: Boundary - wb_rd=16, typical data
        // ---------------------------------------------------------------
        @(posedge clk); #1;
        wb_rd   = 5'd16;
        wb_data = 32'h0000_0001;
        wb_we   = 1'b1;
        instr   = {6'b0, 5'd16, 5'd16, 3'b011, 5'd16, 7'b0};
        wait_clk;
        if (rd === 5'd16 && rs1_data === 32'h0000_0001)
            $display("PASS: Test9 - wb_rd=16, data=1");
        else begin
            $display("FAIL: Test9 - wb_rd=16 rd=%0d rs1_data=%0h", rd, rs1_data);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Test 10: funct3 extraction check
        // ---------------------------------------------------------------
        // Set instr so that instr_i[14:12] = 3'b110
        instr = {6'b0, 5'd1, 5'd2, 3'b110, 5'd3, 7'b0};
        wb_rd   = 5'd3;
        wb_data = 32'h5A5A_5A5A;
        wb_we   = 1'b0;
        wait_clk; // latch instr into instr_i
        wait_clk; // now instr_i has this instruction
        if (funct3 === 3'b110)
            $display("PASS: Test10 - funct3 extraction = 3'b110");
        else begin
            $display("FAIL: Test10 - funct3=%0b (exp 110)", funct3);
            fail_count = fail_count + 1;
        end

        // ---------------------------------------------------------------
        // Summary
        // ---------------------------------------------------------------
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", fail_count);

        $finish;
    end

endmodule
