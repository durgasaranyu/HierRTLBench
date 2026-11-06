`timescale 1ns/1ps

// Testbench for cpu_imem
// Note: The DUT is an instruction memory (cpu_imem), not a full CPU.
// We test the memory module directly: write instructions and verify reads.
// The MODULE-SPECIFIC REQUIREMENTS reference a CPU; we satisfy them by
// encoding the respective RISC-V instructions into memory and verifying
// the correct bit-patterns are returned.

module tb_cpu_imem;

    // -------------------------------------------------------------------------
    // DUT connections
    // -------------------------------------------------------------------------
    reg  [31:0] addr;
    wire [31:0] instr;

    // -------------------------------------------------------------------------
    // Clock and reset (kept for structural requirement; not used by pure combo DUT)
    // -------------------------------------------------------------------------
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    cpu_imem uut (
        .addr  (addr),
        .instr (instr)
    );

    // -------------------------------------------------------------------------
    // Task: check
    // -------------------------------------------------------------------------
    task check;
        input [31:0] got;
        input [31:0] expected;
        input [255:0] desc;  // 32-char string packed
        begin
            if (got === expected)
                $display("PASS: %s | got=%08h", desc, got);
            else
                $display("FAIL: %s | got=%08h expected=%08h", desc, got, expected);
        end
    endtask

    // -------------------------------------------------------------------------
    // Helper: encode RISC-V 32-bit instructions
    //   ADD  rd,rs1,rs2  : R-type, funct7=0000000, funct3=000, opcode=0110011
    //   LW   rd,imm(rs1) : I-type, funct3=010, opcode=0000011
    //   SW   rs2,imm(rs1): S-type, funct3=010, opcode=0100011
    //   BEQ  rs1,rs2,off : B-type, funct3=000, opcode=1100011
    //   ADDI rd,rs1,imm  : I-type, funct3=000, opcode=0010011
    // -------------------------------------------------------------------------

    // R-type ADD x1, x2, x3  -> funct7=0,rs2=3,rs1=2,funct3=0,rd=1,opcode=0110011
    // [31:25]=0000000, [24:20]=00011, [19:15]=00010, [14:12]=000, [11:7]=00001, [6:0]=0110011
    localparam ADD_X1_X2_X3 = 32'b0000000_00011_00010_000_00001_0110011;

    // I-type LW x5, 8(x6)  -> imm=12'h008, rs1=6, funct3=010, rd=5, opcode=0000011
    // [31:20]=000000001000, [19:15]=00110, [14:12]=010, [11:7]=00101, [6:0]=0000011
    localparam LW_X5_8_X6 = 32'b000000001000_00110_010_00101_0000011;

    // S-type SW x7, 4(x8)  -> imm=12'h004, rs1=8, rs2=7, funct3=010, opcode=0100011
    // imm[11:5]=0000000, rs2=00111, rs1=01000, funct3=010, imm[4:0]=00100, opcode=0100011
    localparam SW_X7_4_X8 = 32'b0000000_00111_01000_010_00100_0100011;

    // B-type BEQ x9, x10, +8 -> imm=13'h008 -> imm[12]=0,imm[10:5]=000001,rs2=01010,rs1=01001,funct3=000,imm[4:1]=0000,imm[11]=0,opcode=1100011
    // offset=8: bit12=0, bit11=0, bits10:5=000001, bits4:1=0000
    localparam BEQ_X9_X10_8 = 32'b0_000001_01010_01001_000_0000_0_1100011;

    // ADDI x1, x0, 0  (NOP-like, immediate=0)
    localparam ADDI_X1_X0_0 = 32'b000000000000_00000_000_00001_0010011;

    // ADDI x15, x0, -1 (all-ones immediate)
    localparam ADDI_X15_X0_NEG1 = 32'b111111111111_00000_000_01111_0010011;

    // All-zeros instruction (NOP or encoding of ADD x0,x0,x0 in some ISAs)
    localparam ALL_ZEROS = 32'h00000000;

    // All-ones instruction
    localparam ALL_ONES  = 32'hFFFFFFFF;

    // -------------------------------------------------------------------------
    // Integer for loops
    // -------------------------------------------------------------------------
    integer i;

    // -------------------------------------------------------------------------
    // Main test sequence
    // -------------------------------------------------------------------------
    initial begin
        // Default
        addr = 32'h0;

        // ------------------------------------------------------------------
        // Apply reset for 5 rising edges (structural requirement)
        // ------------------------------------------------------------------
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
        @(negedge clk); // settle

        // ------------------------------------------------------------------
        // Initialise instruction memory via hierarchical path
        // (cpu_imem has no write port; use hierarchical access)
        // ------------------------------------------------------------------

        // First clear all to zero
        for (i = 0; i < 256; i = i + 1)
            uut.mem[i] = 32'h00000000;

        // Load instructions at specific word addresses
        uut.mem[0]  = ADD_X1_X2_X3;     // addr 0x000
        uut.mem[1]  = LW_X5_8_X6;       // addr 0x004
        uut.mem[2]  = SW_X7_4_X8;       // addr 0x008
        uut.mem[3]  = BEQ_X9_X10_8;     // addr 0x00C
        uut.mem[4]  = ADDI_X1_X0_0;     // addr 0x010
        uut.mem[5]  = ADDI_X15_X0_NEG1; // addr 0x014
        uut.mem[63] = ALL_ZEROS;         // addr 0x0FC  (all-zero instr)
        uut.mem[255]= ALL_ONES;          // addr 0x3FC  (all-ones instr)

        #1; // let hierarchy writes settle

        // ==================================================================
        // TEST 1: ADD instruction at byte address 0x000
        // ==================================================================
        addr = 32'h00000000;
        #2;
        check(instr, ADD_X1_X2_X3, "ADD x1,x2,x3 at addr 0x000     ");

        // ==================================================================
        // TEST 2: LW instruction at byte address 0x004
        // ==================================================================
        addr = 32'h00000004;
        #2;
        check(instr, LW_X5_8_X6, "LW  x5,8(x6) at addr 0x004      ");

        // ==================================================================
        // TEST 3: SW instruction at byte address 0x008
        // ==================================================================
        addr = 32'h00000008;
        #2;
        check(instr, SW_X7_4_X8, "SW  x7,4(x8) at addr 0x008      ");

        // ==================================================================
        // TEST 4: BEQ instruction at byte address 0x00C
        // ==================================================================
        addr = 32'h0000000C;
        #2;
        check(instr, BEQ_X9_X10_8, "BEQ x9,x10,+8 at addr 0x00C    ");

        // ==================================================================
        // TEST 5: ADDI with zero immediate at byte address 0x010
        // ==================================================================
        addr = 32'h00000010;
        #2;
        check(instr, ADDI_X1_X0_0, "ADDI x1,x0,0 at addr 0x010      ");

        // ==================================================================
        // TEST 6: ADDI with all-ones immediate at byte address 0x014
        // ==================================================================
        addr = 32'h00000014;
        #2;
        check(instr, ADDI_X15_X0_NEG1, "ADDI x15,x0,-1 at addr 0x014   ");

        // ==================================================================
        // TEST 7: All-zero instruction (edge case) at byte address 0x0FC
        //         word index 63: addr = 63*4 = 0xFC
        // ==================================================================
        addr = 32'h000000FC;
        #2;
        check(instr, ALL_ZEROS, "All-zero instr at addr 0x0FC    ");

        // ==================================================================
        // TEST 8: All-ones instruction (edge case) at byte address 0x3FC
        //         word index 255: addr = 255*4 = 0x3FC
        // ==================================================================
        addr = 32'h000003FC;
        #2;
        check(instr, ALL_ONES, "All-ones instr at addr 0x3FC    ");

        // ==================================================================
        // TEST 9: Unwritten location (should read 0 after clearing)
        // ==================================================================
        addr = 32'h00000100; // word index 64
        #2;
        check(instr, 32'h00000000, "Unwritten location reads 0       ");

        // ==================================================================
        // TEST 10: addr bits [1:0] ignored – byte address 0x001 -> word 0
        // ==================================================================
        addr = 32'h00000001; // bits[9:2]=0, so word 0
        #2;
        check(instr, ADD_X1_X2_X3, "Byte addr 0x001 -> word 0 (ADD)  ");

        // ==================================================================
        // TEST 11: addr bits [1:0] ignored – byte address 0x005 -> word 1 (LW)
        // ==================================================================
        addr = 32'h00000005; // bits[9:2]=1, word 1
        #2;
        check(instr, LW_X5_8_X6, "Byte addr 0x005 -> word 1 (LW)   ");

        // ==================================================================
        // TEST 12: Maximum-value address check (addr=0x3FF -> word 255)
        // ==================================================================
        addr = 32'h000003FF;
        #2;
        check(instr, ALL_ONES, "Max addr 0x3FF -> word 255       ");

        // Done
        #10;
        $display("All tests completed.");
        $finish;
    end

endmodule
