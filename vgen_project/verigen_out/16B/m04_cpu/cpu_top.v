// Multi-cycle Harvard RISC CPU. 5-phase FSM (IF/ID/EX/MEM/WB). ADD/SUB/AND/OR/ADDI/LW/SW/BEQ.
module multicycle_cpu (
    input clk, rst
);
    // INTERNAL SIGNALS
    // IF/ID Pipeline Register
    reg [31:0] IF_ID_IR;
    reg [31:0] IF_ID_NPC;
    reg [31:0] IF_ID_PC;
    reg  [3:0] IF_ID_stage;
    // ID/EX Pipeline Register
    reg [31:0] ID_EX_IR;
    reg [31:0] ID_EX_NPC;
    reg [31:0] ID_EX_AluRe, ID_EX_AluSrc;
    reg [31:0] ID_EX_DataSrc;
    reg [31:0] ID_EX_PC;
    reg  [3:0] ID_EX_stage;
    // EX/MEM Pipeline Register
    reg [31:0] EX_MEM_IR;
    reg [31:0] EX_MEM_ALUOut;
    reg [31:0] EX_MEM_B;
    reg [31:0] EX_MEM_condAddr;
    reg [31:0] EX_MEM_PC;
    reg  [3:0] EX_MEM_stage;
    // MEM/WB Pipeline Register
    reg [31:0] MEM_WB_IR;
    reg [31:0] MEM_WB_ALUOut;
    reg [31:0] MEM_WB_LMD;
    reg [31:0] MEM_WB_PC;
    reg  [3:0] MEM_WB_stage;
    // WB/MEM Pipeline Register
    reg [31:0] WB_MEM_ALUOut;
    reg [31:0] WB_MEM_IR;
    reg [4:0] WB_MEM_stage;
    // Forwarding Control Signals
    reg [31:0] ID_EX_AluRe, ID_EX_AluSrc;
    reg [31:0] ID_EX_DataSrc;
    reg  [3:0] ID_EX_stage;
    reg [31:0] EX_MEM_ALUOut, EX_MEM_B;
    reg [31:0] MEM_WB_ALUOut;
    reg [31:0] MEM_WB_LMD;
    reg [31:0] WB_MEM_ALUOut;
    // ALU Control Signals
    reg [3:0] ALU_Control;
    // ALU Pipeline Register
    reg [31:0] ALU_IR;
    reg [31:0] ALU_NPC;
    reg [31:0] ALU_PC;
    reg  [3:0] ALU_stage;
    // IF/ID Pipeline Register
    reg [31:0] IF_ID_IR;
    reg [31:0] IF_ID_NPC;
    reg [31:0] IF_ID_PC;
    reg  [3:0] IF_ID_stage;
    // IF/ID Pipeline Register
    reg [31:0] ID_EX_IR;
    reg [31:0] ID_EX_NPC;
    reg [31:0] ID_EX_AluRe, ID_EX_AluSrc;
    reg [31:0] ID_EX_DataSrc;
    reg [31:0] ID_EX_PC;
    reg  [3:0] ID_EX_stage;
    // IF/ID Pipeline Register
    reg [31:0] EX_MEM_IR;
    reg [31:0] EX_MEM_NPC;
    reg [31:0] EX_MEM_AluRe, EX_MEM_AluSrc;
    reg [31:0] EX_MEM_DataSrc;
    reg [31:0] EX_MEM_PC;
    reg  [3:0] EX_MEM_stage;
    // IF/ID Pipeline Register
    reg [31:0] MEM_WB_IR;
    reg [31:0] MEM_WB_NPC;
    reg [31:0] MEM_WB_AluRe, MEM_WB_AluSrc;
    reg [31:0] MEM_WB_DataSrc;
    reg [31:0] MEM_WB_PC;
    reg  [3:0] MEM_WB_stage;
    // IF/ID Pipeline Register
    reg [31:0] WB_MEM_IR;
    reg [31:0] WB_MEM_NPC;
    reg [31:0] WB_MEM_AluRe, WB_MEM_AluSrc;
    reg [31:0] WB_MEM_DataSrc;
    reg [31:0] WB_MEM_PC;
    reg  [3:0] WB_MEM_stage;
    // IF/ID Pipeline Register
    reg [31:0] next_WB_IR;
    reg [31:0] next_WB_NPC;
    reg [31:0] next_WB_AluRe, next_WB_AluSrc;
    reg [31:0] next_WB_DataSrc;
    reg [31:0] next_WB_PC;
    reg  [3:0] next_WB_stage;
    // IF/ID Pipeline Register
    reg [31:0] next_MEM_IR;
    reg [31:0] next_MEM_NPC;
    reg [31:0] next_MEM_AluRe, next_MEM_AluSrc;
    reg [31:0] next_MEM_DataSrc;
    reg [31:0] next_MEM_PC;
    reg  [3:0] next_MEM_stage;
    // IF/ID Pipeline Register
    reg [31:0] next_MEM_IR;
    reg [31:0] next_MEM_NPC;
    reg [31:0] next_MEM_AluRe, next_MEM_AluSrc;
    reg [31:0] next_MEM_DataSrc;
    reg [31:0] next_MEM_PC;
    reg  [3:0] next_MEM_stage;
    // IF/ID Pipeline Register
    reg [31:0] next_WB_IR;
    reg [31:0] next_WB_NPC;
    reg [31:0] next_WB_AluRe, next_WB_AluSrc;
    reg [31:0] next_WB_DataSrc;
    reg [31:0] next_WB_PC;
    reg  [3:0] next_WB_stage;
    // IF/ID Pipeline Register
    reg [31:0] next_MEM_IR;
    reg [31:0] next_MEM_NPC;
    reg [31:0] next_MEM_AluRe, next_MEM_AluSrc;
    reg [31:0] next_MEM_DataSrc;
    reg [31:0] next_MEM_PC;
    reg  [3:0] next_MEM_stage;
    // IF/ID Pipeline Register
    reg [31:0] next_WB_IR;
    reg [31:0] next_WB_NPC;
    reg [31:0] next_WB_AluRe, next_WB_AluSrc;
    reg [31:0] next_WB_DataSrc;
    reg [31:0] next_WB_PC;
    reg  [3:0] next_WB_stage;
    // IF/ID Pipeline Register
    reg [31:0] next_MEM_IR;
    reg [31:0] next_MEM_NPC;
    reg [31:0] next_MEM_AluRe, next_MEM_AluSrc;
    reg [31:0] next_MEM_DataSrc;
    reg [31:0] next_MEM_PC;
    reg  [3:0] next_MEM_stage;
    // IF/ID Pipeline Register
    reg [31:0] next_WB_IR;
    reg [31:0] next_WB_NPC;
    reg [31:0] next_WB_AluRe, next_WB_Alu
endmodule
