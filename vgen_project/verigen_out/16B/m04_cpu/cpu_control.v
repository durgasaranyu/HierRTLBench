// Multi-cycle RISC control FSM. States IF=0,ID=1,EX=2,MEM=3,WB=4.
// Opcodes: ADD/SUB=7'h33, ADDI=7'h13, LW=7'h03, SW=7'h23, BEQ=7'h63.
module cpu_control (
    input       clk, rst,
    input [6:0] opcode,
    input [2:0] funct3,
    input       zero,
    output reg  pc_write, ir_write, reg_write, mem_write,
    output reg  alu_src_a, alu_src_b, mem_to_reg, pc_source,
    output reg [1:0] alu_op
);
    reg [3:0] state, next_state;
    parameter [3:0] IDLE = 4'b0000, FETCH = 4'b0001, IF_ID = 4'b0010, ID_EX = 4'b0011, EX_MEM = 4'b0100, MEM_WB = 4'b0101, WB_MEM = 4'b0110;
    always @(*) begin
        state <= next_state;
    end
    always @(*) begin
        case (state)
            IDLE: begin
                if (opcode == 7'b11000101) next_state = FETCH;
                else next_state = IDLE;
            end
            FETCH: next_state = IF_ID;
            IF_ID: begin
                if (opcode == 7'b11000111) next_state = ID_EX;
                else next_state = IF_ID;
            end
            ID_EX: begin
                if (opcode == 7'b11000111) next_state = ID_EX;
                else if (opcode == 7'b11011011) next_state = EX_MEM;
                else next_state = IF_ID;
            end
            EX_MEM: begin
                if (opcode == 7'b11011111) next_state = EX_MEM;
                else if (opcode == 7'b11011011) next_state = MEM_WB;
                else next_state = IF_ID;
            end
            MEM_WB: begin
                if (opcode == 7'b11000111) next_state = MEM_WB;
                else next_state = IF_ID;
            end
        endcase
    end
    always @(*) begin
        case (state)
            IDLE: begin
                pc_write = 0;
                ir_write = 0;
                reg_write = 0;
                mem_write = 0;
                alu_src_a = 0;
                alu_src_b = 0;
                mem_to_reg = 0;
                pc_source = 0;
                alu_op = 2'b10;
                if (opcode == 7'b11000101) begin
                    pc_write = 1;
                    pc_source = 2;
                    reg_write = 1;
                    mem_write = 1;
                    alu_src_a = 1;
                    alu_src_b = 1;
                    mem_to_reg = 1;
                    alu_op = 2'b00;
                end
            end
            FETCH: begin
                pc_write = 0;
                ir_write = 0;
                reg_write = 0;
                mem_write = 0;
                alu_src_a = 0;
                alu_src_b = 0;
                mem_to_reg = 0;
                pc_source = 0;
                alu_op = 2'b00;
            end
            IF_ID: begin
                pc_write = 0;
                ir_write = 1;
                reg_write = 1;
                mem_write = 1;
                alu_src_a = 1;
                alu_src_b = 1;
                mem_to_reg = 1;
                alu_op = 2'b00;
            end
            ID_EX: begin
                pc_write = 0;
                ir_write = 1;
                reg_write = 1;
                mem_write = 1;
                alu_src_a = 1;
                alu_src_b = 1;
                mem_to_reg = 1;
                alu_op = 2'b00;
            end
            EX_MEM: begin
                pc_write = 0;
                ir_write = 1;
                reg_write = 1;
                mem_write = 1;
                alu_src_a = 1;
                alu_src_b = 1;
                mem_to_reg = 1;
                alu_op = 2'b00;
            end
            MEM_WB: begin
                pc_write = 0;
                ir_write = 1;
                reg_write = 1;
                mem_write = 1;
                alu_src_a = 1;
                alu_src_b = 1;
                mem_to_reg = 1;
                alu_op = 2'b00;
            end
        endcase
    end

endmodule
