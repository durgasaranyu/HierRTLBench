// Multi-cycle RISC CPU with 5 internal phases:
// Phase 0: Instruction Fetch  — PC -> MAR, read MEM, IR <- MEM[MAR]
// Phase 1: Instruction Decode — RegA <- Reg[rs1], RegB <- Reg[rs2]
// Phase 2: Execute            — ALUOut <- ALU(RegA, RegB or imm)
// Phase 3: Memory Access      — for LOAD/STORE only
// Phase 4: Write Back         — Reg[rd] <- ALUOut or MDR
// Supports: ADD, SUB, AND, OR (R-type); ADDI (I-type); LW, SW; BEQ
// Harvard architecture: separate instruction and data memory interfaces
// 32-bit data width, 32 registers, 10-bit address space
// Synchronous reset active-high
module multicycle_cpu (
    input  wire        clk,
    input  wire        reset,
    // Instruction memory interface
    output wire [9:0]  imem_addr,
    input  wire [31:0] imem_data,
    // Data memory interface
    output wire [9:0]  dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire        dmem_we,
    input  wire [31:0] dmem_rdata
);
    // Internal registers: PC, IR, MAR, MDR, RegA, RegB, ALUOut
    // Control FSM drives all register enables and ALU op select
    // ALUOut is only used if it is a R-type instruction
    // Registers are only written by the CPU, not read by the CPU or DMA
    // (i.e. no need to worry about clobbering CPU regs)
    // All registers are 32 bits wide
    reg [31:0] CUR_INST;
    reg [31:0] PC;
    reg [31:0] IR;
    reg [31:0] MAR;
    reg [31:0] MDR;
    reg [4:0]  ALU_op;
    reg [31:0] ALUOut;
    reg [4:0]  ALU_op_select;
    reg [31:0] RegA, RegB;
    // Registers A and B are updated in the execution phase
    // (i.e. the actual cycle in which the instruction is executed)
    reg [31:0] RegA_in, RegB_in;
    // DMA_OUT is updated in the memory access phase
    reg [31:0] DMA_OUT;
    // DMA_IN is updated in the write back phase
    reg [31:0] DMA_IN;
    // Registers A and B are written to the reg file
    // (i.e. the actual cycle in which the instruction is written to regs)
    reg [31:0] RegA_reg, RegB_reg;
    // Registers A and B are written to the reg file
    // (i.e. the actual cycle in which the instruction is written to regs)
    reg [31:0] DMA_IN_reg;
    // The execution phase (phase 2)
    reg [31:0] PC_IN, PC_OUT, MAR_OUT, MDR_OUT, ALUOut_OUT, DMA_OUT_reg;
    // The execution phase (phase 2)
    // ALUOut is only used if it is a R-type instruction
    // ALU_op_select is only used if it is a R-type instruction
    // ALU_op_select is driven by the FSM
    // ALU_op_select = 5'b00000; // Used for ADD, SUB, AND, OR for non-R type instructions
    // ALU_op_select = 5'b00001; // Used for ADDI instruction
    // ALU_op_select = 5'b00010; // Used for LW instruction
    // ALU_op_select = 5'b00011; // Used for SW instruction
    // ALU_op_select = 5'b00100; // Used for BEQ instruction
    // ALU_op_select = 5'b00101; // Used for BNE instruction
    // ALU_op_select = 5'b00110; // Used for BLEZ instruction
    // ALU_op_select = 5'b00111; // Used for BGTZ instruction
    // ALU_op_select = 5'b01000; // Used for BLTZBGEZ instruction
    // ALU_op_select = 5'b01001; // Used for BLTZBGEZ instruction
    // ALU_op_select = 5'b01010; // Used for BLTZBGEZ instruction
    // ALU_op_select = 5'b01011; // Used for BLTZBGEZ instruction
    // ALU_op_select = 5'b01100; // Used for BLTZBGEZ instruction
    // ALU_op_select = 5'b01101; // Used for BLTZBGEZ instruction
    // ALU_op_select = 5'b01110; // Used for BLTZBGEZ instruction
    // ALU_op_select = 5'b01111; // Used for BLTZBGEZ instruction
    // ALU_op_select = 5'b10000; // Used for JR instruction
    // ALU_op_select = 5'b10001; // Used for JALR instruction
    // ALU_op_select = 5'b10010; // Used for SYSCALL instruction
    // ALU_op_select = 5'b10011; // Used for BREAK instruction
    // ALU_op_select = 5'b10100; // Used for MFHI instruction
    // ALU_op_select = 5'b10101; // Used for MFLO instruction
    // ALU_op_select = 5'b10110; // Used for MULT instruction
    // ALU_op_select = 5'b10111; // Used for MULTU instruction
    // ALU_op_select = 5'b11000; // Used for ADDU instruction
    // ALU_op_select = 5'b11001; // Used for SUBU instruction
    // ALU_op_select = 5'b11010; // Used for AND instruction
    // ALU_op_select = 5'b11011; // Used for OR instruction
    // ALU_op_select = 5'b11100; // Used for NOR instruction
    // ALU_op_select = 5'b11101; // Used for SLT instruction
    // ALU_op_select = 5'b11110; // Used for SLTU instruction
    // ALU_op_select = 5'b11111; // Used for DIV instruction
    // ALU_op_select = 5'b00000; // Used for JR
    // ALU_op_select = 5'b00001; // Used for ADDI
    // ALU_op_select = 5'b00010; // Used for LW
    // ALU_op_select = 5'b00011; // Used for SW
    // ALU_op_select = 5'b00100; // Used for BEQ
    // ALU_op_select = 5'b00101; // Used for BNE
    // ALU_op_select = 5'b00110; // Used for BLEZ
    // ALU_op_select = 5'b00111; // Used for BGTZ
    // ALU_op_select = 5'b01000; // Used for BLTZBGEZ
    // ALU_op_select = 5'b01001; // Used for BLTZBGEZ
    // ALU_op_select = 5'b01010; // Used for BLTZBGEZ
    // ALU_op_select = 5'b01011; // Used for BLTZBGEZ
    // ALU_op_select = 5'b01100; // Used for BLTZBGEZ
    // ALU_op_select = 5'b01101; // Used for BLTZBGEZ
    // ALU_op_select = 5'b01110; // Used for BLTZBGEZ
    // ALU_op_select = 5'b01111; // Used for BLTZBGEZ
    // ALU_op_select = 5'b10000; // Used for JR
    // ALU_op_select = 5'b10001; // Used for JALR
    // ALU_op_select = 5'b10010; // Used for SYSCALL
    // ALU_op_select = 5'b10011; // Used for BREAK
    // ALU_op_select = 5'
endmodule
