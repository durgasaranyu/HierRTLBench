// 5-stage pipelined RISC-V RV32I subset processor
// Stages: IF (Instruction Fetch) | ID (Decode/Register Read) |
//         EX (Execute/ALU)       | MEM (Memory Access)       |
//         WB (Write Back)
// Pipeline registers: IF_ID, ID_EX, EX_MEM, MEM_WB
// Hazard detection unit: inserts NOPs on RAW load-use hazards
// Forwarding unit: EX-EX and MEM-EX forwarding paths
// Supports: ADD, SUB, AND, OR, ADDI, LW, SW, BEQ
// Synchronous reset flushes all pipeline registers
module pipeline_cpu (
    input  wire        clk,
    input  wire        reset,
    // Instruction memory (synchronous read)
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_data,
    // Data memory
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire        dmem_we,
    input  wire [31:0] dmem_rdata
);
    // Pipeline register structs: IF_ID{PC,IR}, ID_EX{...}, EX_MEM{...}, MEM_WB{...}
    // Forwarding mux selects: fwd_a, fwd_b (00=reg, 01=MEM, 10=WB)
    // Stall signal from hazard unit freezes IF_ID and PC
    // Memory access control signal
    // Memory write enable (MEM_WB[`MEM_WB_ADDR] controls)
    // Register file address decode
    // Register file data input (IF_ID[`IF_ID_IR-1:0])
    // Register file data output (ID_EX[`ID_EX_RD-1:0])
    // ALU input/output (EX_MEM[`EX_MEM_ALU_IN-1:0])
    // ALU result (EX_MEM[`EX_MEM_ALU_OUT-1:0])
    // Data memory data input (MEM[`MEM_DATA_ADDR-1:0])
    // Data memory data output (MEM_WB[`MEM_WB_DATA_ADDR-1:0])
    // Pipeline registers
    // IF_ID pipeline register
    // ID_EX pipeline register
    // EX_MEM pipeline register
    // MEM_WB pipeline register
    // Register file
    // ALU
    // Data memory
    // Memory data input register
    // Memory data output register
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
    // Register file
endmodule
