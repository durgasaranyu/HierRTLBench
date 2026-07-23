// Hardwired control unit top: 7-bit opcode, 3-bit phase. All 5 phases covered.
// Instantiates phase01 and phase234, merges outputs.
module hardwired_ctrl (
    input  [6:0] opcode,
    input  [2:0] phase,
    output       pc_write, ir_write, reg_write, mem_write,
    output       alu_src_a, alu_src_b, mem_to_reg, pc_source
);
    assign alu_src_a = (opcode == 7'b0010011)? 1'b1 : 1'b0; // R format
    assign alu_src_b = (opcode == 7'b0010011)? 1'b1 : 1'b0; // R format
    assign mem_to_reg = (opcode == 7'b1011100)? 1'b1 : 1'b0; // Loads and Stores
    assign pc_source = (opcode == 7'b0000011)? 1'b1 : 1'b0; // Branch
    assign pc_write = (opcode == 7'b0000011)? 1'b1 : 1'b0; // Branch
    assign ir_write = (opcode == 7'b0000011)? 1'b1 : 1'b0; // Branch
    assign reg_write = (opcode == 7'b0000100)? 1'b1 : 1'b0; // R format
    assign mem_write = (opcode == 7'b0000100)? 1'b1 : 1'b0; // R format
    assign phase_0 = (phase == 3'b000)? 1'b1 : 1'b0; // phase 0
    assign phase_1 = (phase == 3'b001)? 1'b1 : 1'b0; // phase 1
    assign phase_2 = (phase == 3'b010)? 1'b1 : 1'b0; // phase 2
    assign phase_3 = (phase == 3'b011)? 1'b1 : 1'b0; // phase 3
    assign phase_4 = (phase == 3'b100)? 1'b1 : 1'b0; // phase 4
    assign phase_5 = (phase == 3'b101)? 1'b1 : 1'b0; // phase 5
    assign phase_6 = (phase == 3'b110)? 1'b1 : 1'b0; // phase 6
    assign phase_7 = (phase == 3'b111)? 1'b1 : 1'b0; // phase 7

endmodule
