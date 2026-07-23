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
    wire        stall;
    wire        fwd_a, fwd_b;
    wire        fwd_a_b, fwd_a_f, fwd_b_b, fwd_b_f;
    wire        fwd_a_wb, fwd_b_wb;
    wire        fwd_a_ex, fwd_b_ex;
    wire        fwd_a_ex_b, fwd_a_ex_f, fwd_b_ex_b, fwd_b_ex_f;
    wire        fwd_a_ex_wb, fwd_b_ex_wb;
    wire        fwd_a_mem, fwd_b_mem;
    wire        fwd_a_mem_b, fwd_a_mem_f, fwd_b_mem_b, fwd_b_mem_f;
    wire        fwd_a_mem_wb, fwd_b_mem_wb;
    wire        fwd_a_wb, fwd_b_wb;
    wire        fwd_a_wb_b, fwd_a_wb_f, fwd_b_wb_b, fwd_b_wb_f;
    wire        fwd_a_wb_wb, fwd_b_wb_wb;
    wire        fwd_a_wb_wb_b, fwd_b_wb_wb_b;
    wire        fwd_a_wb_wb_f, fwd_b_wb_wb_f;
    wire        fwd_a_wb_wb_wb, fwd_b_wb_wb_wb;
    wire        fwd_a_wb_wb_wb_b, fwd_b_wb_wb_wb_b;
    wire        fwd_a_wb_wb_wb_f, fwd_b_wb_wb_wb_f;
    wire        fwd_a_wb_wb_wb_wb, fwd_b_wb_wb_wb_wb;
    wire        fwd_a_wb_wb_wb_wb_b, fwd_b_wb_wb_wb_wb_b;
    wire        fwd_a_wb_wb_wb_wb_f, fwd_b_wb_wb_wb_wb_f;
    wire        fwd_a_wb_wb_wb_wb_wb, fwd_b_wb_wb_wb_wb_wb;
    wire        fwd_a_wb_wb_wb_wb_wb_b, fwd_b_wb_wb_wb_wb_wb_b;
    wire        fwd_a_wb_wb_wb_wb_wb_f, fwd_b_wb_wb_wb_wb_wb_f;
    wire        fwd_a_wb_wb_wb_wb_wb_wb, fwd_b_wb_wb_wb_wb_wb_wb;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_b, fwd_b_wb_wb_wb_wb_wb_wb_b;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_f, fwd_b_wb_wb_wb_wb_wb_wb_f;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_wb, fwd_b_wb_wb_wb_wb_wb_wb_wb;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_wb_b, fwd_b_wb_wb_wb_wb_wb_wb_wb_b;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_wb_f, fwd_b_wb_wb_wb_wb_wb_wb_wb_f;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_wb_wb, fwd_b_wb_wb_wb_wb_wb_wb_wb_wb;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_wb_wb_b, fwd_b_wb_wb_wb_wb_wb_wb_wb_wb_b;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_wb_wb_f, fwd_b_wb_wb_wb_wb_wb_wb_wb_wb_f;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_wb_wb_wb, fwd_b_wb_wb_wb_wb_wb_wb_wb_wb_wb;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_wb_wb_wb_b, fwd_b_wb_wb_wb_wb_wb_wb_wb_wb_wb_b;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_wb_wb_wb_f, fwd_b_wb_wb_wb_wb_wb_wb_wb_wb_wb_f;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb, fwd_b_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_b, fwd_b_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_b;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_f, fwd_b_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_f;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb, fwd_b_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_b, fwd_b_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_b;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_f, fwd_b_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_f;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb, fwd_b_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb;
    wire        fwd_a_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_b, fwd_b_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_wb_b;

endmodule
