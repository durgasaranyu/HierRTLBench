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
    reg [4:0] control_fsm;
    // Instruction FSM drives all instruction register accesses
    reg [4:0] instruction_fsm;
    // ALU input muxes
    reg [1:0] alu_input_mux;
    // ALU control muxes
    reg [3:0] alu_control_mux;
    // ALU op muxes
    reg [1:0] alu_op_mux;
    // ALU output muxes
    reg [1:0] alu_output_mux;
    // Data memory muxes
    reg [1:0] dmem_mux;
    // Instruction register muxes
    reg [1:0] is_mux;
    // Data memory interface
    reg [9:0] dmem_addr_mux;
    // Instruction register interface
    reg [31:0] ir_mux;
    // Data memory interface
    reg [9:0] dmem_addr_mux;
    // Instruction register interface
    reg [31:0] ir_mux;
    // Data memory interface
    reg dmem_we_mux;
    // Instruction register interface
    reg dmem_we_mux;
    // ALU op muxes
    reg [1:0] alu_op_mux_active;
    // ALU control muxes
    reg [3:0] alu_control_mux_active;
    // ALU output muxes
    reg [1:0] alu_output_mux_active;
    // Instruction register interface
    reg [31:0] instruction_fsm_active;
    // Data memory interface
    reg [9:0] dmem_addr_mux_active;
    // Instruction register interface
    reg [31:0] ir_mux_active;
    // Data memory interface
    reg [9:0] dmem_addr_mux_active;
    // Instruction register interface
    reg [31:0] ir_mux_active;
    // Data memory interface
    reg dmem_we_mux_active;
    // ALU op muxes
    reg [1:0] alu_op_mux_active;
    // ALU control muxes
    reg [3:0] alu_control_mux_active;
    // ALU output muxes
    reg [1:0] alu_output_mux_active;
    // Instruction register interface
    reg [31:0] instruction_fsm_active;
    // Data memory interface
    reg [9:0] dmem_addr_mux_active;
    // Instruction register interface
    reg [31:0] ir_mux_active;
    // Data memory interface
    reg [9:0] dmem_addr_mux_active;
    // Instruction register interface
    reg [31:0] ir_mux_active;
    // Data memory interface
    reg dmem_we_mux_active;
    // ALU op muxes
    reg [1:0] alu_op_mux_active;
    // ALU control muxes
    reg [3:0] alu_control_mux_active;
    // ALU output muxes
    reg [1:0] alu_output_mux_active;
    // Instruction register interface
    reg [31:0] instruction_fsm_active;
    // Data memory interface
    reg [9:0] dmem_addr_mux_active;
    // Instruction register interface
    reg [31:0] ir_mux_active;
    // Data memory interface
    reg [9:0] dmem_addr_mux_active;
    // Instruction register interface
    reg [31:0] ir_mux_active;
    // Data memory interface
    reg dmem_we_mux_active;
    // ALU op muxes
    reg [1:0] alu_op_mux_active;
    // ALU control muxes
    reg [3:0] alu_control_mux_active;
    // ALU output muxes
    reg [1:0] alu_output_mux_active;
    // Instruction register interface
    reg [31:0] instruction_fsm_active;
    // Data memory interface
    reg [9:0] dmem_addr_mux_active;
    // Instruction register interface
    reg [31:0] ir_mux_active;
    // Data memory interface
    reg [9:0] dmem_addr_mux_active;
    // Instruction register interface
    reg [31:0] ir_mux_active;
    // Data memory interface
    reg dmem_we_mux_active;
    // ALU op muxes
    reg [1:0] alu_op_mux_active;
    // ALU control muxes
    reg [3:0] alu_control_mux_active;
    // ALU output muxes
    reg [1:0] alu_output_mux_active;
    // Instruction register interface
    reg [31:0] instruction_fsm_active;
    // Data memory interface
    reg [9:0] dmem_addr_mux_active;
    // Instruction register interface
    reg [31:0] ir_mux_active;
    // Data memory interface
    reg [9:0] dmem_addr_mux_active;
    // Instruction register interface
    reg [31:0] ir_mux_active;
    // Data memory interface
    reg dmem_we_mux_active;
    // ALU op muxes
    reg [1:0] alu_op_mux_active;
    // ALU control muxes
    reg [3:0] alu_control_mux_active;
    // ALU output muxes
    reg [1:0] alu_output_mux_active;
    // Instruction register interface
    reg [31:0] instruction_fsm_active;
    // Data memory interface
    reg [9:0] dmem_addr_mux_active;
    // Instruction register interface
    reg [31:0] ir_mux_active;
    // Data memory interface
    reg [9:0] dmem_addr_mux_active;
    // Instruction register interface
    reg [31:0] ir_mux_active;
    // Data memory interface
    reg dmem_we_mux_active;
    // ALU op muxes
    reg [1:0] alu_op_mux_active;
    // ALU control muxes
    reg [3:0] alu_control_mux_active;
    // ALU output muxes
    reg [1:0] alu_output_mux_active;
    // Instruction register interface
    reg [31:0] instruction_fsm_active;
    // Data memory interface
    reg [9:0] dmem_addr_mux_active;
    // Instruction register interface
    reg [31:
endmodule
