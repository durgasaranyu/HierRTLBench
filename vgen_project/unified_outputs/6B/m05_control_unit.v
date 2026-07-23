// Hardwired control unit for a multi-cycle RISC CPU
// Inputs: 7-bit opcode, 3-bit phase (0=IF,1=ID,2=EX,3=MEM,4=WB)
// Outputs: one control signal per datapath mux and register enable
// All outputs are combinational (no registers in control unit)
// Use full case statement — every opcode+phase must have defined outputs
// Opcodes: 7'b0110011=R-type, 7'b0010011=I-type,
//          7'b0000011=LOAD,   7'b0100011=STORE, 7'b1100011=BRANCH
module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] phase,
    output reg        pc_write,
    output reg        ir_write,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        mem_to_reg,
    output reg        alu_src_b,   // 0=RegB 1=immediate
    output reg [1:0]  alu_op,      // 00=ADD 01=SUB 10=AND 11=OR
    output reg        branch
);
    // Use a casex or nested case on {opcode, phase}
    // Default: all outputs = 0 to avoid latches
    // Opcodes: 7'b0110011=R-type, 7'b0010011=I-type, 7'b0000011=LOAD, 7'b0100011=STORE
    //          7'b1100011=BRANCH
    // Phases: 3'b000=ID, 3'b001=EX, 3'b010=MEM, 3'b011=WB
always @(opcode or phase)
    case (opcode)
        7'b0110011: // R-type
            case (phase)
                3'b000: begin // ID
                    pc_write = 1'b0;
                    ir_write = 1'b1;
                    reg_write = 1'b0;
                    mem_read = 1'b0;
                    mem_write = 1'b0;
                    mem_to_reg = 1'b0;
                    alu_src_b = 1'b0;
                    alu_op = 2'b10;
                    branch = 1'b0;
                end
                3'b001: begin // EX
                    pc_write = 1'b0;
                    ir_write = 1'b0;
                    reg_write = 1'b1;
                    mem_read = 1'b0;
                    mem_write = 1'b0;
                    mem_to_reg = 1'b0;
                    alu_src_b = 1'b0;
                    alu_op = 2'b10;
                    branch = 1'b0;
                end
                3'b010: begin // MEM
                    pc_write = 1'b0;
                    ir_write = 1'b0;
                    reg_write = 1'b0;
                    mem_read = 1'b1;
                    mem_write = 1'b0;
                    mem_to_reg = 1'b0;
                    alu_src_b = 1'b0;
                    alu_op = 2'b10;
                    branch = 1'b0;
                end
                3'b011: begin // WB
                    pc_write = 1'b0;
                    ir_write = 1'b0;
                    reg_write = 1'b0;
                    mem_read = 1'b0;
                    mem_write = 1'b1;
                    mem_to_reg = 1'b0;
                    alu_src_b = 1'b0;
                    alu_op = 2'b10;
                    branch = 1'b0;
                end
                3'b100: begin // BR
                    pc_write = 1'b0;
                    ir_write = 1'b0;
                    reg_write = 1'b0;
                    mem_read = 1'b0;
                    mem_write = 1'b0;
                    mem_to_reg = 1'b0;
                    alu_src_b = 1'b1;
                    alu_op = 2'b01;
                    branch = 1'b1;
                end
            endcase
        7'b0010011: // I-type
            case (phase)
                3'b000: begin // ID
                    pc_write = 1'b0;
                    ir_write = 1'b1;
                    reg_write = 1'b0;
                    mem_read = 1'b0;
                    mem_write = 1'b0;
                    mem_to_reg = 1'b0;
                    alu_src_b = 1'b0;
                    alu_op = 2'b10;
                    branch = 1'b0;
                end
                3'b001: begin // EX
                    pc_write = 1'b0;
                    ir_write = 1'b0;
                    reg_write = 1'b1;
                    mem_read = 1'b0;
                    mem_write = 1'b0;
                    mem_to_reg = 1'b0;
                    alu_src_b = 1'b0;
                    alu_op = 2'b10;
                    branch = 1'b0;
                end
                3'b010: begin // MEM
                    pc_write = 1'b0;
                    ir_write = 1'b0;
                    reg_write = 1'b0;
                    mem_read = 1'b1;
                    mem_write = 1'b0;
                    mem_to_reg = 1'b0;
                    alu_src_b = 1'b0;
                    alu_op = 2'b10;
                    branch = 1'b0;
                end
                3'b011: begin // WB
                    pc_write = 1'b0;
                    ir_write = 1'b0;
                    reg_write = 1'b0;
                    mem_read = 1'b0;
                    mem_write = 1'b1;
                    mem_to_reg = 1'b0;
                    alu_src_b = 1'b0;
                    alu_op = 2'b10;
                    branch = 1'b0;
                end
                3'b100: begin // BR
                    pc_write = 1'b0;
                    ir_write = 1'b0;
                    reg_write = 1'b0;
                    mem_read = 1'b0;
                    mem_write = 1'b0;
                    mem_to_reg = 1'b0;
                    alu_src_b = 1'b1;
                    alu_op = 2'b01;
                    branch = 1'b1;
                end
            endcase
        7'b0000011: // LOAD
            case (phase)
                3'b000: begin // ID
                    pc_write = 1'b0;
                    ir_write = 1'b1;
                    reg_write = 1'b0;
                    mem_read = 1'b0;
                    mem_write = 1'b0;
                    mem_to_reg = 1'b0;
                    alu_src_b = 1'b0;
                    alu_op = 2'b00;
                    branch = 1'b0;
                end
                3'b001: begin // EX
                    pc_write = 1'b0;
                    ir_write = 1'b0;
                    reg_write = 1'b1;
                    mem_read = 1'b0;
                    mem_write = 1'b0;
                    mem_to_reg = 1'b0;
                    alu_src_b = 1'b0;
                    alu_op = 2'b00;
                    branch = 1'b0;
                end
                3'b010: begin // MEM
                    pc_write = 1'b0;
                    ir_write = 1'b0;
                    reg_write = 1'b0;
                    mem_read = 1'b1;
                    mem_write = 1'b0;
                    mem_to_reg = 1'b0;
                    alu_src_b = 1'b0;
                    alu_op = 2'b00;
                    branch = 1'b0;
                end
                3'b011: begin // WB
                    pc_write = 1'b0;
endmodule
