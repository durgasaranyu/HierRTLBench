// Hardwired control unit: phases 0 (IF) and 1 (ID). 7-bit opcode + 3-bit phase input.
// Combinational outputs: pc_write, ir_write, reg_write, mem_write, alu_src_a/b, mem_to_reg, pc_source.
module ctrl_phase01 (
    input  [6:0] opcode,
    input  [2:0] phase,
    output reg   pc_write, ir_write, reg_write, mem_write,
    output reg   alu_src_a, alu_src_b, mem_to_reg, pc_source
);
    always @(*) begin
        pc_write    = 1'b0;
        ir_write    = 1'b0;
        reg_write   = 1'b0;
        mem_write   = 1'b0;
        alu_src_a   = 1'b0;
        alu_src_b   = 1'b0;
        mem_to_reg  = 1'b0;
        pc_source   = 1'b0;
        case (phase)
            3'b000: begin
                pc_write = 1'b1;
                if (opcode == 7'b1100011)
                    ir_write = 1'b1;
                else if (opcode == 7'b1101111)
                    reg_write = 1'b1;
                else if (opcode == 7'b0000011)
                    mem_write = 1'b1;
                else if (opcode == 7'b0100011)
                    alu_src_a = 1'b1;
                else if (opcode == 7'b0110011)
                    alu_src_b = 1'b1;
                else if (opcode == 7'b1100010)
                    mem_to_reg = 1'b1;
                else if (opcode == 7'b0000000)
                    pc_source = 1'b1;
            end
            3'b001: begin
                pc_write = 1'b1;
                if (opcode == 7'b1100011)
                    ir_write = 1'b1;
                else if (opcode == 7'b1101111)
                    reg_write = 1'b1;
                else if (opcode == 7'b0000011)
                    mem_write = 1'b1;
                else if (opcode == 7'b0100011)
                    alu_src_a = 1'b1;
                else if (opcode == 7'b0110011)
                    alu_src_b = 1'b1;
                else if (opcode == 7'b1100010)
                    mem_to_reg = 1'b1;
                else if (opcode == 7'b0100001)
                    pc_source = 1'b1;
            end
            3'b010: begin
                pc_write = 1'b1;
                if (opcode == 7'b1100011)
                    ir_write = 1'b1;
                else if (opcode == 7'b1101111)
                    reg_write = 1'b1;
                else if (opcode == 7'b0000011)
                    mem_write = 1'b1;
                else if (opcode == 7'b0100011)
                    alu_src_a = 1'b1;
                else if (opcode == 7'b0110011)
                    alu_src_b = 1'b1;
                else if (opcode == 7'b1100010)
                    mem_to_reg = 1'b1;
                else if (opcode == 7'b0100001)
                    pc_source = 1'b1;
            end
            3'b011: begin
                pc_write = 1'b1;
                if (opcode == 7'b1100011)
                    ir_write = 1'b1;
                else if (opcode == 7'b1101111)
                    reg_write = 1'b1;
                else if (opcode == 7'b0000011)
                    mem_write = 1'b1;
                else if (opcode == 7'b0100011)
                    alu_src_a = 1'b1;
                else if (opcode == 7'b0110011)
                    alu_src_b = 1'b1;
                else if (opcode == 7'b1100010)
                    mem_to_reg = 1'b1;
                else if (opcode == 7'b0100001)
                    pc_source = 1'b1;
            end
            3'b100: begin
                pc_write = 1'b1;
                if (opcode == 7'b1100011)
                    ir_write = 1'b1;
                else if (opcode == 7'b1101111)
                    reg_write = 1'b1;
                else if (opcode == 7'b0000011)
                    mem_write = 1'b1;
                else if (opcode == 7'b0100011)
                    alu_src_a = 1'b1;
                else if (opcode == 7'b0110011)
                    alu_src_b = 1'b1;
                else if (opcode == 7'b1100010)
                    mem_to_reg = 1'b1;
                else if (opcode == 7'b0100001)
                    pc_source = 1'b1;
            end
            3'b101: begin
                pc_write = 1'b1;
                if (opcode == 7'b1100011)
                    ir_write = 1'b1;
                else if (opcode == 7'b1101111)
                    reg_write = 1'b1;
                else if (opcode == 7'b0000011)
                    mem_write = 1'b1;
                else if (opcode == 7'b0100011)
                    alu_src_a = 1'b1;
                else if (opcode == 7'b0110011)
                    alu_src_b = 1'b1;
                else if (opcode == 7'b1100010)
                    mem_to_reg = 1'b1;
                else if (opcode == 7'b0100001)
                    pc_source = 1'b1;
            end
            3'b110: begin
                pc_write = 1'b1;
                if (opcode == 7'b1100011)
                    ir_write = 1'b1;
                else if (opcode == 7'b1101111)
                    reg_write = 1'b1;
                else if (opcode == 7'b0000011)
                    mem_write = 1'b1;
                else if (opcode == 7'b0100011)
                    alu_src_a = 1'b1;
                else if (opcode == 7'b0110011)
                    alu_src_b = 1'b1;
                else if (opcode == 7'b1100010)
                    mem_to_reg = 1'b1;
                else if (opcode == 7'b0100001)
                    pc_source = 1'b1;
            end
            3'b111: begin
                pc_write = 1'b1;
                if (opcode == 7'b1100011)
                    ir_write = 1'b1;
                else if (opcode == 7'b1101111)
                    reg_write = 1'b1;
                else if (opcode == 7'b0000011)
                    mem_write = 1'b1;
                else if (opcode == 7'b0100011)
                    alu_src_a = 1'b1;
                else if (opcode == 7'b0110011)
                    alu_src_b = 1'b1;
                else if (opcode == 7'b1100010)
                    mem_to_reg = 1'b1;
                else if (opcode == 7'b0100001)
                    pc_source = 1'b1;
            end
        endcase
    end

endmodule
