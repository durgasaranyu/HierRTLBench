// Hardwired control unit: phases 2 (EX), 3 (MEM), 4 (WB). 7-bit opcode + 3-bit phase input.
// Combinational outputs: pc_write, ir_write, reg_write, mem_write, alu_src_a/b, mem_to_reg, pc_source.
module ctrl_phase234 (
    input  [6:0] opcode,
    input  [2:0] phase,
    output reg   pc_write, ir_write, reg_write, mem_write,
    output reg   alu_src_a, alu_src_b, mem_to_reg, pc_source
);
    always @(*) begin
        pc_write = 1'b0;
        ir_write = 1'b0;
        reg_write = 1'b0;
        mem_write = 1'b0;
        alu_src_a = 1'b0;
        alu_src_b = 1'b0;
        mem_to_reg = 1'b0;
        pc_source = 1'b0;
        case (phase)
            3'b000: begin
                pc_write = 1'b1;
                ir_write = 1'b1;
                reg_write = 1'b1;
                mem_write = 1'b1;
                alu_src_a = 1'b1;
                alu_src_b = 1'b1;
                mem_to_reg = 1'b1;
                pc_source = 1'b0;
            end
            3'b001: begin
                pc_write = 1'b1;
                ir_write = 1'b1;
                reg_write = 1'b1;
                mem_write = 1'b1;
                alu_src_a = 1'b1;
                alu_src_b = 1'b1;
                mem_to_reg = 1'b1;
                pc_source = 1'b0;
            end
            3'b010: begin
                pc_write = 1'b1;
                ir_write = 1'b1;
                reg_write = 1'b1;
                mem_write = 1'b1;
                alu_src_a = 1'b1;
                alu_src_b = 1'b1;
                mem_to_reg = 1'b1;
                pc_source = 1'b0;
            end
            3'b011: begin
                pc_write = 1'b1;
                ir_write = 1'b1;
                reg_write = 1'b1;
                mem_write = 1'b1;
                alu_src_a = 1'b1;
                alu_src_b = 1'b1;
                mem_to_reg = 1'b1;
                pc_source = 1'b0;
            end
            3'b100: begin
                pc_write = 1'b1;
                ir_write = 1'b1;
                reg_write = 1'b1;
                mem_write = 1'b1;
                alu_src_a = 1'b1;
                alu_src_b = 1'b1;
                mem_to_reg = 1'b1;
                pc_source = 1'b0;
            end
            3'b101: begin
                pc_write = 1'b1;
                ir_write = 1'b1;
                reg_write = 1'b1;
                mem_write = 1'b1;
                alu_src_a = 1'b1;
                alu_src_b = 1'b1;
                mem_to_reg = 1'b1;
                pc_source = 1'b0;
            end
            3'b110: begin
                pc_write = 1'b1;
                ir_write = 1'b1;
                reg_write = 1'b1;
                mem_write = 1'b1;
                alu_src_a = 1'b1;
                alu_src_b = 1'b1;
                mem_to_reg = 1'b1;
                pc_source = 1'b0;
            end
            3'b111: begin
                pc_write = 1'b1;
                ir_write = 1'b1;
                reg_write = 1'b1;
                mem_write = 1'b1;
                alu_src_a = 1'b1;
                alu_src_b = 1'b1;
                mem_to_reg = 1'b1;
                pc_source = 1'b0;
            end
        endcase
    end

endmodule
