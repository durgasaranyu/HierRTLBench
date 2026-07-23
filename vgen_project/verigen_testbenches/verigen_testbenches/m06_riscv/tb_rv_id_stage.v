`timescale 1ns/1ps

module tb_rv_id_stage;

    // DUT connections
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

    integer fail_count;

    task apply_and_wait;
        input [31:0] i_instr;
        input [4:0]  i_wb_rd;
        input [31:0] i_wb_data;
        input        i_wb_we;
        begin
            instr   = i_instr;
            wb_rd   = i_wb_rd;
            wb_data = i_wb_data;
            wb_we   = i_wb_we;
            @(posedge clk);
            #1; // small delay to observe outputs after clock edge
        end
    endtask

    initial begin
        fail_count = 0;

        // Initialise inputs
        instr   = 32'h0;
        wb_rd   = 5'h0;
        wb_data = 32'h0;
        wb_we   = 1'b0;
        rst     = 1'b1;

        // Assert reset for exactly 5 rising edges
        repeat(5) @(posedge clk);
        #1;
        rst = 1'b0;

        // ------------------------------------------------------------------
        // Test 1: All-zero instruction (NOP-like)
        // R-type fields: opcode=0, rs1=0, rs2=0, rd=0, funct3=0, funct7=0
        // ------------------------------------------------------------------
        apply_and_wait(32'h00000000, 5'd0, 32'h0, 1'b0);
        if (opcode === 7'h00 && rs1 === 5'd0 && rs2 === 5'd0 && rd === 5'd0 &&
            funct3 === 3'd0 && funct7 === 7'd0)
            $display("PASS: Test1 - All-zero instruction decodes correctly");
        else begin
            $display("FAIL: Test1 - All-zero instruction decode. opcode=%0h rs1=%0d rs2=%0d rd=%0d funct3=%0h funct7=%0h",
                     opcode, rs1, rs2, rd, funct3, funct7);
            fail_count = fail_count + 1;
        end

        // ------------------------------------------------------------------
        // Test 2: All-ones instruction
        // opcode[6:0]=7'h7f, rs1[19:15]=5'h1f, rs2[24:20]=5'h1f,
        // rd[11:7]=5'h1f, funct3[14:12]=3'h7, funct7[31:25]=7'h7f
        // ------------------------------------------------------------------
        apply_and_wait(32'hFFFFFFFF, 5'd0, 32'h0, 1'b0);
        if (opcode === 7'h7f && rs1 === 5'h1f && rs2 === 5'h1f &&
            rd === 5'h1f && funct3 === 3'h7 && funct7 === 7'h7f)
            $display("PASS: Test2 - All-ones instruction decodes correctly");
        else begin
            $display("FAIL: Test2 - All-ones instruction decode. opcode=%0h rs1=%0d rs2=%0d rd=%0d funct3=%0h funct7=%0h",
                     opcode, rs1, rs2, rd, funct3, funct7);
            fail_count = fail_count + 1;
        end

        // ------------------------------------------------------------------
        // Test 3: R-type ADD x1, x2, x3
        // funct7=0, rs2=x3(5'd3), rs1=x2(5'd2), funct3=000, rd=x1(5'd1), opcode=0110011
        // Encoding: 0000000_00011_00010_000_00001_0110011
        // = 32'h00310033 ... let's compute:
        // [31:25]=0000000, [24:20]=00011, [19:15]=00010, [14:12]=000, [11:7]=00001, [6:0]=0110011
        // = 0000000 00011 00010 000 00001 0110011
        // ------------------------------------------------------------------
        begin
            // bit 31-25: 7'b0000000 = 7'h00
            // bit 24-20: 5'b00011   = rs2=3
            // bit 19-15: 5'b00010   = rs1=2
            // bit 14-12: 3'b000     = funct3=0
            // bit 11-7:  5'b00001   = rd=1
            // bit  6-0:  7'b0110011 = opcode=0x33
            // full word: 0000_0000_0011_0001_0000_0000_1011_0011 = 32'h00310033
        end
        apply_and_wait(32'h00310033, 5'd0, 32'h0, 1'b0);
        if (opcode === 7'h33 && rs1 === 5'd2 && rs2 === 5'd3 && rd === 5'd1 &&
            funct3 === 3'd0 && funct7 === 7'd0)
            $display("PASS: Test3 - R-type ADD decode correct");
        else begin
            $display("FAIL: Test3 - R-type ADD decode. opcode=%0h rs1=%0d rs2=%0d rd=%0d funct3=%0h funct7=%0h",
                     opcode, rs1, rs2, rd, funct3, funct7);
            fail_count = fail_count + 1;
        end

        // ------------------------------------------------------------------
        // Test 4: I-type ADDI x5, x6, 42
        // imm[11:0]=12'd42=12'h02A, rs1=x6=5'd6, funct3=000, rd=x5=5'd5, opcode=0010011
        // bit 31-20: 12'h02A
        // bit 19-15: 5'd6
        // bit 14-12: 3'b000
        // bit 11-7:  5'd5
        // bit  6-0:  7'b0010011 = 0x13
        // 0000_0010_1010_0011_0000_0010_1001_0011 = 32'h02A30293
        // ------------------------------------------------------------------
        apply_and_wait(32'h02A30293, 5'd0, 32'h0, 1'b0);
        if (opcode === 7'h13 && rs1 === 5'd6 && rd === 5'd5 && funct3 === 3'd0)
            $display("PASS: Test4 - I-type ADDI decode correct (opcode/rs1/rd/funct3)");
        else begin
            $display("FAIL: Test4 - I-type ADDI decode. opcode=%0h rs1=%0d rd=%0d funct3=%0h",
                     opcode, rs1, rd, funct3);
            fail_count = fail_count + 1;
        end

        // ------------------------------------------------------------------
        // Test 5: Immediate sign extension check - negative immediate
        // ADDI x1, x0, -1  (imm = 12'hFFF = -1 sign extended)
        // bit 31-20: 12'hFFF
        // bit 19-15: 5'd0  (rs1=x0)
        // bit 14-12: 3'b000
        // bit 11-7:  5'd1  (rd=x1)
        // bit  6-0:  7'h13
        // 1111_1111_1111_0000_0000_0000_1001_0011 = 32'hFFF00093
        // ------------------------------------------------------------------
        apply_and_wait(32'hFFF00093, 5'd0, 32'h0, 1'b0);
        if (opcode === 7'h13 && rs1 === 5'd0 && rd === 5'd1 && funct3 === 3'd0 &&
            imm_ext === 32'hFFFFFFFF)
            $display("PASS: Test5 - Negative immediate sign extended correctly");
        else begin
            $display("FAIL: Test5 - Negative immediate. opcode=%0h rs1=%0d rd=%0d imm_ext=%0h",
                     opcode, rs1, rd, imm_ext);
            fail_count = fail_count + 1;
        end

        // ------------------------------------------------------------------
        // Test 6: Writeback - write to register and then read back
        // Step 6a: Write value 0xDEADBEEF to register x7 via wb port
        // Step 6b: Read rs1=x7 in next instruction
        // ------------------------------------------------------------------
        // Write to x7
        apply_and_wait(32'h00000013, 5'd7, 32'hDEADBEEF, 1'b1); // NOP with wb to x7
        // Now issue instruction with rs1=x7
        // ADDI x1, x7, 0: imm=0, rs1=x7=5'd7, funct3=000, rd=x1, opcode=0x13
        // bit 19-15 = 5'd7 = 5'b00111
        // 0000_0000_0000_0011_1000_0000_1001_0011 = 32'h00038093
        apply_and_wait(32'h00038093, 5'd0, 32'h0, 1'b0);
        if (rs1_data === 32'hDEADBEEF)
            $display("PASS: Test6 - Register writeback and readback correct");
        else begin
            $display("FAIL: Test6 - Register writeback. Expected rs1_data=DEADBEEF, got %0h", rs1_data);
            fail_count = fail_count + 1;
        end

        // ------------------------------------------------------------------
        // Test 7: Writeback to x0 should not change x0 (x0 is always 0)
        // ------------------------------------------------------------------
        apply_and_wait(32'h00000013, 5'd0, 32'hCAFEBABE, 1'b1); // wb to x0
        // Read x0 as rs1
        // ADDI x1, x0, 0: rs1=x0=5'd0
        // 32'h00000093
        apply_and_wait(32'h00000093, 5'd0, 32'h0, 1'b0);
        if (rs1_data === 32'h0)
            $display("PASS: Test7 - x0 always reads as zero");
        else begin
            $display("FAIL: Test7 - x0 should be zero, got rs1_data=%0h", rs1_data);
            fail_count = fail_count + 1;
        end

        // ------------------------------------------------------------------
        // Test 8: S-type instruction - SW
        // SW x2, 8(x1): opcode=0100011, funct3=010
        // imm[11:5]=0000000, rs2=x2=5'd2, rs1=x1=5'd1, funct3=010, imm[4:0]=01000
        // bit 31-25: 7'b0000000
        // bit 24-20: 5'd2
        // bit 19-15: 5'd1
        // bit 14-12: 3'b010
        // bit 11-7:  5'b01000  (imm[4:0])
        // bit  6-0:  7'b0100011 = 0x23
        // 0000_0000_0010_0000_1010_0100_0010_0011 = 32'h0020A423
        // ------------------------------------------------------------------
        apply_and_wait(32'h0020A423, 5'd0, 32'h0, 1'b0);
        if (opcode === 7'h23 && rs1 === 5'd1 && rs2 === 5'd2 && funct3 === 3'd2)
            $display("PASS: Test8 - S-type SW decode correct");
        else begin
            $display("FAIL: Test8 - S-type SW decode. opcode=%0h rs1=%0d rs2=%0d funct3=%0h",
                     opcode, rs1, rs2, funct3);
            fail_count = fail_count + 1;
        end

        // ------------------------------------------------------------------
        // Test 9: R-type SUB x4, x5, x6
        // funct7=0100000, rs2=x6=5'd6, rs1=x5=5'd5, funct3=000, rd=x4=5'd4, opcode=0110011
        // bit 31-25: 7'b0100000
        // bit 24-20: 5'd6
        // bit 19-15: 5'd5
        // bit 14-12: 3'b000
        // bit 11-7:  5'd4
        // bit  6-0:  7'h33
        // 0100_0000_0110_0010_1000_0010_0011_0011 = 32'h40628233
        // ------------------------------------------------------------------
        apply_and_wait(32'h40628233, 5'd0, 32'h0, 1'b0);
        if (opcode === 7'h33 && rs1 === 5'd5 && rs2 === 5'd6 && rd === 5'd4 &&
            funct3 === 3'd0 && funct7 === 7'h20)
            $display("PASS: Test9 - R-type SUB decode correct");
        else begin
            $display("FAIL: Test9 - R-type SUB decode. opcode=%0h rs1=%0d rs2=%0d rd=%0d funct3=%0h funct7=%0h",
                     opcode, rs1, rs2, rd, funct3, funct7);
            fail_count = fail_count + 1;
        end

        // ------------------------------------------------------------------
        // Test 10: Write two registers and verify rs2_data readback
        // Write 0xABCD1234 to x10
        // ------------------------------------------------------------------
        apply_and_wait(32'h
