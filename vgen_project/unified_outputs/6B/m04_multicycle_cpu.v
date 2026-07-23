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
    //   PC  : pc_ld, pc_inc, ir_ld, imem_addr, dmem_addr, mem_type, mem_data, mem_wdata, mem_we, pc_sel
    //   IR  : ir_ld, pc_inc, pc_sel, op_sel, op_ld, op_dec, reg_sel, reg_en, reg_ld, branch_off, jump
    //   MAR : pc_ld, pc_inc, pc_sel, op_sel, op_ld, op_dec, reg_sel, reg_en, reg_ld, branch_off, jump
    //   MDR : pc_ld, pc_inc, pc_sel, op_sel, op_ld, op_dec, reg_sel, reg_en, reg_ld, branch_off, jump
    //   ALU : pc_ld, pc_inc, pc_sel, op_sel, op_ld, op_dec, reg_sel, reg_en, reg_ld, branch_off, jump
    //   DMEM: pc_ld, pc_inc, pc_sel, op_sel, op_ld, op_dec, reg_sel, reg_en, reg_ld, branch_off, jump
    //   IMEM: pc_ld, pc_inc, pc_sel, op_sel, op_ld, op_dec, reg_sel, reg_en, reg_ld, branch_off, jump
    //   RegA, RegB, ALUOut, DMemOut
    //   IR, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB, ALUOut, DMemOut
    //   RegA, RegB
endmodule
