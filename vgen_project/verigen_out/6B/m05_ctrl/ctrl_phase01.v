// Hardwired control unit: phases 0 (IF) and 1 (ID). 7-bit opcode + 3-bit phase input.
// Combinational outputs: pc_write, ir_write, reg_write, mem_write, alu_src_a/b, mem_to_reg, pc_source.
module ctrl_phase01 (
    input  [6:0] opcode,
    input  [2:0] phase,
    output reg   pc_write, ir_write, reg_write, mem_write,
    output reg   alu_src_a, alu_src_b, mem_to_reg, pc_source
);
    always @(*) begin
        if (phase == 0) begin
            pc_write = 1;
            ir_write = 1;
            reg_write = 1;
            mem_write = 0;
            alu_src_a = 0;
            alu_src_b = 0;
            mem_to_reg = 0;
            pc_source = 0;
        end
        else if (phase == 1) begin
            pc_write = 0;
            ir_write = 0;
            reg_write = 0;
            mem_write = 1;
            alu_src_a = 0;
            alu_src_b = 1;
            mem_to_reg = 1;
            pc_source = 1;
        end
        else begin
            pc_write = 0;
            ir_write = 0;
            reg_write = 0;
            mem_write = 0;
            alu_src_a = 1;
            alu_src_b = 0;
            mem_to_reg = 0;
            pc_source = 0;
        end
    end
endmodule

// Hardwired control unit: phases 0 (IF) and 1 (ID). 7-bit opcode + 3-bit phase input.
// Combinational outputs: pc_write, ir_write, reg_write, mem_write, alu_src_a/b, mem_to_reg, pc_source.
module ctrl_phase02 (
    input  [6:0] opcode,
    input  [2:0] phase,
    output reg   pc_write, ir_write, reg_write, mem_write,
    output reg   alu_src_a, alu_src_b, mem_to_reg, pc_source
);
    always @(*) begin
        if (phase == 0) begin
            pc_write = 0;
            ir_write = 0;
            reg_write = 0;
            mem_write = 0;
            alu_src_a = 0;
            alu_src_b = 0;
            mem_to_reg = 0;
            pc_source = 0;
        end
        else if (phase == 1) begin
            pc_write = 1;
            ir_write = 1;
            reg_write = 1;
            mem_write = 0;
            alu_src_a = 0;
            alu_src_b = 0;
            mem_to_reg = 0;
            pc_source = 0;
        end
        else begin
            pc_write = 0;
            ir_write = 0;
            reg_write = 0;
            mem_write = 0;
            alu_src_a = 1;
            alu_src_b = 0;
            mem_to_reg = 0;
            pc_source = 0;
        end
    end
endmodule

// Hardwired control unit: phases 0 (IF) and 1 (ID). 7-bit opcode + 3-bit phase input.
// Combinational outputs: pc_write, ir_write, reg_write, mem_write, alu_src_a/b, mem_to_reg, pc_source.
module ctrl_phase03 (
    input  [6:0] opcode,
    input  [2:0] phase,
    output reg   pc_write, ir_write, reg_write, mem_write,
    output reg   alu_src_a, alu_src_b, mem_to_reg, pc_source
);
    always @(*) begin
        if (phase == 0) begin
            pc_write = 0;
            ir_write = 0;
            reg_write = 0;
            mem_write = 0;
            alu_src_a = 0;
            alu_src_b = 0;
            mem_to_reg = 0;
            pc_source = 0;
        end
        else if (phase == 1) begin
            pc_write = 0;
            ir_write = 0;
            reg_write = 0;
            mem_write = 0;
            alu_src_a = 0;
            alu_src_b = 0;
            mem_to_reg = 0;
            pc_source = 0;
        end
        else begin
            pc_write = 0;
            ir_write = 0;
            reg_write = 0;
            mem_write = 0;
            alu_src_a = 0;
            alu_src_b = 0;
            mem_to_reg = 0;
            pc_source = 0;
        end
    end
endmodule

// Hardwired control unit: phases 0 (IF) and 1 (ID). 7-bit opcode + 3-bit phase input.
// Combinational outputs: pc_write, ir_write, reg_write, mem_write, alu_src_a/b, mem_to_reg, pc_source.
module ctrl_phase04 (
    input  [6:0] opcode,
    input  [2:0] phase,
    output reg   pc_write, ir_write, reg_write, mem_write,
    output reg   alu_src_a, alu_src_b, mem_to_reg, pc_source
);
    always @(*) begin
        if (phase == 0) begin
            pc_write = 0;
            ir_write = 0;
            reg_write = 0;
            mem_write = 0;
            alu_src_a = 0;
            alu_src_b = 0;
            mem_to_reg = 0;
            pc_source = 0;
        end
        else if (phase == 1) begin
            pc_write = 0;
            ir_write = 0;
            reg_write = 0;
            mem_write = 0;
            alu_src_a = 0;
            alu_src_b = 0;
            mem_to_reg = 0;
            pc_source = 0;
        end
        else begin
            pc_write = 0;
            ir_write = 0;
            reg_write = 0;
            mem_write = 0;
            alu_src_a = 0;
            alu_src_b = 0;
            mem_to_reg = 0;
            pc_source = 0;
        end
    end
endmodule

// Hardwired control unit: phases 0 (IF) and 1 (ID). 7-bit opcode + 3-bit phase input.
// Combinational outputs: pc_write, ir_write, reg_write, mem_write, alu_src_a/b, mem_to_reg, pc_source.
module ctrl_phase05 (
    input  [6:0] opcode,
    input  [2:0] phase,
    output reg   pc_write, ir_write, reg_write, mem_write,
    output reg   alu_src_a, alu_src_b, mem_to_reg, pc_source
);
    always @(*) begin
        if (phase == 0) begin
            pc_write = 0;
            ir_write = 0;
            reg_write = 0;
            mem_write = 0;
            alu_src_a = 0;
            alu_src_b = 0;
            mem_to_reg = 0;
            pc_source = 0;
        end
        else if (phase == 1) begin
            pc_write = 0;
            ir_write = 0;
            reg_write = 0;
            mem_write = 0;
            alu_src_a = 0;
            alu_src_b = 0;
            mem_to_reg = 0;
            pc_source = 0;
        end
        else begin
            pc_write = 0;
            ir_write = 0;
            reg_write = 0;
            mem_write = 0;
            alu_src_a = 0;
            alu_src_b = 0;
            
endmodule
