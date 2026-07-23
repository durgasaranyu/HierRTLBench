// 5-stage pipelined RISC-V CPU top. Hazard detection, forwarding unit.
// Supports: ADD/SUB/AND/OR/ADDI/LW/SW/BEQ.
module riscv_pipeline (
    input clk, rst
);
    // Pipeline registers
    reg [31:0] IF_ID_IR, IF_ID_NPC, ID_EX_IR, ID_EX_NPC, EX_MEM_IR, EX_MEM_NPC;
    reg [31:0] ID_EX_A, ID_EX_B, ID_EX_Imm;
    reg [4:0] ID_EX_type, EX_MEM_type;
    reg [31:0] EX_MEM_ALUOut, EX_MEM_B;
    reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;
    reg [31:0] EX_MEM_ALUOut_feedback;
    reg [31:0] EX_MEM_rd, EX_MEM_ALUOut_feedback_out;
    reg [4:0] EX_MEM_type_feedback;
    reg [31:0] EX_MEM_IR_feedback;
    reg [31:0] EX_MEM_B_feedback;
    reg [31:0] EX_MEM_condAddr;
    reg [31:0] EX_MEM_ALUOut_2;
    reg [31:0] EX_MEM_IR_2;
    reg [31:0] EX_MEM_B_2;
    reg [31:0] MEM_WB_IR_feedback;
    reg [31:0] MEM_WB_ALUOut_feedback;
    reg [31:0] MEM_WB_LMD_feedback;
    reg [31:0] EX_MEM_ALUOut_feedback_out;
    reg [31:0] EX_MEM_rd_feedback;
    reg [31:0] EX_MEM_ALUOut_2_feedback;
    reg [31:0] EX_MEM_IR_2_feedback;
    reg [31:0] EX_MEM_B_2_feedback;
    // Pipeline control signals
    reg ID_flush, EX_flush, MEM_flush;
    reg [1:0] stall;
    // IF/ID pipeline registers
    always @(posedge clk) begin
        if (rst) begin
            IF_ID_IR <= 32'b0;
            IF_ID_NPC <= 32'b0;
        end else begin
            IF_ID_IR <= ID_EX_IR;
            IF_ID_NPC <= ID_EX_NPC;
        end
    end
    // IF/ID control unit
    always @(*) begin
        // instruction fetch
        if (!stall) begin
            ID_EX_IR <= IF_ID_IR;
            ID_EX_NPC <= IF_ID_NPC;
        end
        // instruction decode
        ID_EX_A <= ID_EX_IR[25:21];
        ID_EX_B <= ID_EX_IR[20:16];
        ID_EX_Imm <= ID_EX_IR[15:0];
        ID_EX_type <= ID_EX_IR[31:26];
        // register file read
        ID_EX_rd <= ID_EX_A;
        // ALU operation
        ID_EX_ALUOut <= ID_EX_B;
        ID_EX_ALUOut_feedback <= ID_EX_ALUOut;
        ID_EX_ALUOut_feedback_out <= ID_EX_ALUOut_feedback;
        ID_EX_ALUOut_2 <= ID_EX_ALUOut;
        ID_EX_ALUOut_2_feedback <= ID_EX_ALUOut_2;
        ID_EX_IR_feedback <= ID_EX_IR;
        ID_EX_B_feedback <= ID_EX_B;
        ID_EX_type_feedback <= ID_EX_type;
        ID_EX_IR_2 <= ID_EX_IR;
        ID_EX_B_2 <= ID_EX_B;
        ID_EX_type_2 <= ID_EX_type;
        // write back
        ID_EX_rd_feedback <= ID_EX_rd;
        ID_EX_ALUOut_feedback_out <= ID_EX_ALUOut_feedback_out;
        ID_EX_IR_2_feedback <= ID_EX_IR_2;
        ID_EX_B_2_feedback <= ID_EX_B_2;
        ID_EX_type_2_feedback <= ID_EX_type_2;
    end
    // IF/ID pipeline registers
    always @(posedge clk) begin
        if (rst) begin
            IF_ID_IR <= 32'b0;
            IF_ID_NPC <= 32'b0;
        end else begin
            IF_ID_IR <= ID_EX_IR;
            IF_ID_NPC <= ID_EX_NPC;
        end
    end
    // IF/ID control unit
    always @(*) begin
        // instruction fetch
        if (!stall) begin
            ID_EX_IR <= IF_ID_IR;
            ID_EX_NPC <= IF_ID_NPC;
        end
        // instruction decode
        ID_EX_A <= ID_EX_IR[25:21];
        ID_EX_B <= ID_EX_IR[20:16];
        ID_EX_Imm <= ID_EX_IR[15:0];
        ID_EX_type <= ID_EX_IR[31:26];
        // register file read
        ID_EX_rd <= ID_EX_A;
        // ALU operation
        ID_EX_ALUOut <= ID_EX_B;
        ID_EX_ALUOut_feedback <= ID_EX_ALUOut;
        ID_EX_ALUOut_2 <= ID_EX_ALUOut;
        ID_EX_ALUOut_2_feedback <= ID_EX_ALUOut_2;
        ID_EX_IR_feedback <= ID_EX_IR;
        ID_EX_B_feedback <= ID_EX_B;
        ID_EX_type_feedback <= ID_EX_type;
        ID_EX_IR_2 <= ID_EX_IR;
        ID_EX_B_2 <= ID_EX_B;
        ID_EX_type_2 <= ID_EX_type;
        // write back
        ID_EX_rd_feedback <= ID_EX_rd;
        ID_EX_ALUOut_feedback_out <= ID_EX_ALUOut_feedback_out;
        ID_EX_IR_2_feedback <= ID_EX_IR_2;
        ID_EX_B_2_feedback <= ID_EX_B_2;
        ID_EX_type_2_feedback <= ID_EX_type_2;
    end
    // IF/ID pipeline registers
    always @(posedge clk) begin
        if (rst) begin
            IF_ID_IR <= 32'b0;
            IF_ID_NPC <= 32'b0;
        end else begin
            IF_ID_IR <= ID_EX_IR_feedback;
            IF_ID_NPC <= ID_EX_NPC;
        end
    end
    // IF/ID control unit
    always @(*) begin
        // instruction fetch
        if (!stall) begin
            ID_EX_IR <= IF_ID_IR;
            ID_EX_NPC <= IF_ID_NPC;
        end
        // instruction decode
        ID_EX_A <= ID_EX_IR[25:21];
        ID_EX_B <= ID_EX_IR[20:16];
        ID_EX_Imm <= ID_EX_IR[15:0];
        ID_EX_type <= ID_EX_IR[31:26];
        // register file read
        ID_EX_rd <= ID_EX_A;
        // ALU operation
        ID_EX_ALUOut <= ID_EX_B;
        ID_EX_ALUOut_feedback <= ID_EX_ALUOut;
        ID_EX_ALUOut_2 <= ID_EX_ALUOut;
        ID_EX_ALUOut_2_feedback <= ID
endmodule
