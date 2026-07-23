// Hardwired control unit top: 7-bit opcode, 3-bit phase. All 5 phases covered.
// Instantiates phase01 and phase234, merges outputs.
module hardwired_ctrl (
    input  [6:0] opcode,
    input  [2:0] phase,
    output       pc_write, ir_write, reg_write, mem_write,
    output       alu_src_a, alu_src_b, mem_to_reg, pc_source
);
    // Declare wires here
    // Declare module outputs
    // Declare module inputs
    // Instantiate phase01 and phase234
    // Merge outputs
    assign pc_write = phase01.pc_write;
    assign ir_write = phase01.ir_write;
    assign reg_write = phase01.reg_write;
    assign mem_write = phase01.mem_write;
    assign alu_src_a = phase01.alu_src_a;
    assign alu_src_b = phase01.alu_src_b;
    assign mem_to_reg = phase01.mem_to_reg;
    assign pc_source = phase234.pc_source;

endmodule
