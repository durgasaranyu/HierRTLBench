`timescale 1ns/1ps

module tb_cpu_imem;

    // DUT connections
    reg  [31:0] addr;
    wire [31:0] instr;

    // Instantiate DUT
    cpu_imem uut (
        .addr  (addr),
        .instr (instr)
    );

    // Clock and reset (not used by DUT directly, but required by testbench rules)
    reg clk;
    reg rst;

    initial clk = 0;
    always #5 clk = ~clk;

    // Reset for 5 rising edges
    integer i;
    initial begin
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;
    end

    // Helper task
    task check;
        input [31:0] got;
        input [31:0] expected;
        input [255:0] desc;
        begin
            if (got === expected)
                $display("PASS: %s | addr=%0h instr=%0h", desc, addr, got);
            else
                $display("FAIL: %s | addr=%0h expected=%0h got=%0h", desc, addr, expected, got);
        end
    endtask

    initial begin
        // Wait for reset to finish
        @(negedge rst);
        #2; // small delay after reset

        // ---------------------------------------------------------------
        // Test 1: addr=0 => mem[0] = NOP = 0x00000000
        // addr[9:2] = 0 => mem[0]
        addr = 32'h00000000;
        #5;
        check(instr, 32'h00000000, "addr=0 -> mem[0] = NOP");

        // ---------------------------------------------------------------
        // Test 2: addr=4 => mem[1] = NOP = 0x00000000
        // addr[9:2] = 1 => mem[1]
        addr = 32'h00000004;
        #5;
        check(instr, 32'h00000000, "addr=4 -> mem[1] = NOP");

        // ---------------------------------------------------------------
        // Test 3: addr=8 => mem[2] = NOP = 0x00000000
        addr = 32'h00000008;
        #5;
        check(instr, 32'h00000000, "addr=8 -> mem[2] = NOP");

        // ---------------------------------------------------------------
        // Test 4: addr = 0x28 (40 decimal) => addr[9:2] = 10 => mem[10] = NOP
        addr = 32'h00000028;
        #5;
        check(instr, 32'h00000000, "addr=0x28 -> mem[10] = NOP");

        // ---------------------------------------------------------------
        // Test 5: addr = 0x80 => addr[9:2] = 32 => mem[32] = NOP
        addr = 32'h00000080;
        #5;
        check(instr, 32'h00000000, "addr=0x80 -> mem[32] = NOP");

        // ---------------------------------------------------------------
        // Test 6: addr = 0x1A0 => addr[9:2] = 0x68 = 104 => mem[104] = NOP
        addr = 32'h000001A0;
        #5;
        check(instr, 32'h00000000, "addr=0x1A0 -> mem[104] = NOP");

        // ---------------------------------------------------------------
        // Test 7: addr = 0x1C8 => addr[9:2] = 0x72 = 114 => mem[114] = NOP
        addr = 32'h000001C8;
        #5;
        check(instr, 32'h00000000, "addr=0x1C8 -> mem[114] = NOP");

        // ---------------------------------------------------------------
        // Test 8: addr = 0x3FC => addr[9:2] = 0xFF = 255 => mem[255]
        // mem[255] was not explicitly initialized; should be 0 (Verilog reg default)
        addr = 32'h000003FC;
        #5;
        check(instr, 32'h00000000, "addr=0x3FC -> mem[255] = 0 (default)");

        // ---------------------------------------------------------------
        // Test 9: addr with all zeros - same as test 1
        addr = 32'h00000000;
        #5;
        check(instr, 32'h00000000, "all-zero addr -> mem[0] = NOP");

        // ---------------------------------------------------------------
        // Test 10: addr with upper bits set but lower 2 bits varying (alignment check)
        // addr = 0x00000001 => addr[9:2] = 0 => mem[0]
        addr = 32'h00000001;
        #5;
        check(instr, 32'h00000000, "addr=0x1 (unaligned) -> addr[9:2]=0 -> mem[0]");

        // ---------------------------------------------------------------
        // Test 11: addr = 0x00000002 => addr[9:2] = 0 => mem[0]
        addr = 32'h00000002;
        #5;
        check(instr, 32'h00000000, "addr=0x2 (unaligned) -> addr[9:2]=0 -> mem[0]");

        // ---------------------------------------------------------------
        // Test 12: addr = 0x00000003 => addr[9:2] = 0 => mem[0]
        addr = 32'h00000003;
        #5;
        check(instr, 32'h00000000, "addr=0x3 (unaligned) -> addr[9:2]=0 -> mem[0]");

        // ---------------------------------------------------------------
        // Test 13: ADD instruction pattern test
        // Simulate reading addr where we'd expect an ADD: 
        // R-type ADD: funct7=0, rs2=1, rs1=2, funct3=0, rd=3, opcode=0110011
        // = 0000000_00001_00010_000_00011_0110011 = 0x00110133
        // mem[0] is currently NOP. We just verify mem[0]=0 (it IS NOP/ADD x0,x0,x0)
        addr = 32'h00000000;
        #5;
        // NOP (addi x0,x0,0) encodes as 0x00000013 in RISC-V, but in this module
        // mem[0] = 0x00000000 which is actually "add x0, x0, x0" - valid R-type
        check(instr, 32'h00000000, "ADD/NOP pattern: mem[0] = 0x00000000 (add x0,x0,x0)");

        // ---------------------------------------------------------------
        // Test 14: LW address check - addr[9:2]=5 => mem[5]
        addr = 32'h00000014; // 0x14 = 20 => addr[9:2] = 5
        #5;
        check(instr, 32'h00000000, "LW addr check: addr=0x14 -> mem[5] = NOP");

        // ---------------------------------------------------------------
        // Test 15: SW address check - addr[9:2]=6 => mem[6]
        addr = 32'h00000018; // 0x18 = 24 => addr[9:2] = 6
        #5;
        check(instr, 32'h00000000, "SW addr check: addr=0x18 -> mem[6] = NOP");

        // ---------------------------------------------------------------
        // Test 16: BEQ address check - addr[9:2]=7 => mem[7]
        addr = 32'h0000001C; // 0x1C = 28 => addr[9:2] = 7
        #5;
        check(instr, 32'h00000000, "BEQ addr check: addr=0x1C -> mem[7] = NOP");

        // ---------------------------------------------------------------
        // Test 17: Max meaningful addr within initialized range
        // addr[9:2] = 113 => mem[113]
        addr = 32'h000001C4; // 0x1C4 = 452 => addr[9:2] = 113
        #5;
        check(instr, 32'h00000000, "addr=0x1C4 -> mem[113] = NOP");

        // ---------------------------------------------------------------
        // Test 18: addr = 0xFFFFFFFF (all ones)
        // addr[9:2] = 0xFF = 255 => mem[255] = 0
        addr = 32'hFFFFFFFF;
        #5;
        check(instr, 32'h00000000, "addr=0xFFFFFFFF (all-ones) -> mem[255] = 0");

        // ---------------------------------------------------------------
        // Test 19: addr = 0xDEADBEEF
        // addr[9:2] = {addr[9:2]} = 0xDEADBEEF[9:2] = 0xAF = 175 => mem[175]
        addr = 32'hDEADBEEF;
        #5;
        // addr[9:2] of 0xDEADBEEF: bits [9:2] = (0xBEF >> 2) & 0xFF
        // 0xBEF = 1011_1110_1111
        // bits 9:2 = 10_1111_10 = 0xBE = 190
        check(instr, 32'h00000000, "addr=0xDEADBEEF -> mem[190] = 0 (uninitialized default)");

        // ---------------------------------------------------------------
        // Test 20: addr = 0x00000100 => addr[9:2] = 64 => mem[64] = NOP
        addr = 32'h00000100;
        #5;
        check(instr, 32'h00000000, "addr=0x100 -> mem[64] = NOP");

        #10;
        $display("All tests completed.");
        $finish;
    end

endmodule
