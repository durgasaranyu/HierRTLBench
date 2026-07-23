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
    // Opcode format: {funct3, opcode}
    // opcode format: {opcode[6], opcode[5], opcode[4], opcode[3], opcode[2], opcode[1], opcode[0]}
    // opcode 000: r[rt] <- r[rs]
    // opcode 001: r[rt] <- r[rs] + r[rt]
    // opcode 010: r[rt] <- r[rs] - r[rt]
    // opcode 011: r[rt] <- r[rs] - r[rt]
    // opcode 100: r[rt] <- r[rs] & r[rt]
    // opcode 101: r[rt] <- r[rs] | r[rt]
    // opcode 110: r[rt] <- r[rs] ^ r[rt]
    // opcode 111: r[rt] <- r[rs]
    // opcode 000: r[rt] <- r[rs]
    // opcode 001: r[rt] <- r[rs] + {16'h0, immediate}
    // opcode 010: r[rt] <- r[rs] - {16'h0, immediate}
    // opcode 011: r[rt] <- r[rs] - {16'h0, immediate}
    // opcode 100: r[rt] <- r[rs] & {16'h0, immediate}
    // opcode 101: r[rt] <- r[rs] | {16'h0, immediate}
    // opcode 110: r[rt] <- r[rs] ^ {16'h0, immediate}
    // opcode 111: r[rt] <- {16'h0, immediate}
    // opcode 010: r[rt] <- r[rs] - {16'h0, immediate}
    // opcode 011: r[rt] <- r[rs] + {16'h0, immediate}
    // opcode 100: r[rt] <- r[rs] & {16'h0, immediate}
    // opcode 101: r[rt] <- r[rs] | {16'h0, immediate}
    // opcode 110: r[rt] <- r[rs] ^ {16'h0, immediate}
    // opcode 111: r[rt] <- {16'h0, immediate}
    // opcode 000: r[rt] <- r[rs]
    // opcode 001: r[rt] <- r[rs] + {16'h0, immediate}
    // opcode 010: r[rt] <- r[rs] - {16'h0, immediate}
    // opcode 011: r[rt] <- r[rs] - {16'h0, immediate}
    // opcode 100: r[rt] <- r[rs] & {16'h0, immediate}
    // opcode 101: r[rt] <- r[rs] | {16'h0, immediate}
    // opcode 110: r[rt] <- r[rs] ^ {16'h0, immediate}
    // opcode 111: r[rt] <- {16'h0, immediate}
    // opcode 000: r[rt] <- r[rs]
    // opcode 001: r[rt] <- r[rs] + {16'h0, immediate}
    // opcode 010: r[rt] <- r[rs] - {16'h0, immediate}
    // opcode 011: r[rt] <- r[rs] - {16'h0, immediate}
    // opcode 100: r[rt] <- r[rs] & {16'h0, immediate}
    // opcode 101: r[rt] <- r[rs] | {16'h0, immediate}
    // opcode 110: r[rt] <- r[rs] ^ {16'h0, immediate}
    // opcode 111: r[rt] <- {16'h0, immediate}
    // opcode 000: r[rt] <- r[rs]
    // opcode 001: r[rt] <- r[rs] + {16'h0, immediate}
    // opcode 010: r[rt] <- r[rs] - {16'h0, immediate}
    // opcode 011: r[rt] <- r[rs] - {16'h0, immediate}
    // opcode 100: r[rt] <- r[rs] & {16'h0, immediate}
    // opcode 101: r[rt] <- r[rs] | {16'h0, immediate}
    // opcode 110: r[rt] <- r[rs] ^ {16'h0, immediate}
    // opcode 111: r[rt] <- {16'h0, immediate}
    // opcode 000: r[rt] <- r[rs]
    // opcode 001: r[rt] <- r[rs] + {16'h0, immediate}
    // opcode 010: r[rt] <- r[rs] - {16'h0, immediate}
    // opcode 011: r[rt] <- r[rs] - {16'h0, immediate}
    // opcode 100: r[rt] <- r[rs] & {16'h0, immediate}
    // opcode 101: r[rt] <- r[rs] | {16'h0, immediate}
    // opcode 110: r[rt] <- r[rs] ^ {16'h0, immediate}
    // opcode 111: r[rt] <- {16'h0, immediate}
    // opcode 000: r[rt] <- r[rs]
    // opcode 001: r[rt] <- r[rs] + {16'h0, immediate}
    // opcode 010: r[rt] <- r[rs] - {16'h0, immediate}
    // opcode 011: r[rt] <- r[rs] - {16'h0, immediate}
    // opcode 100: r[rt] <- r[rs] & {16'h0, immediate}
    // opcode 101: r[rt] <- r[rs] | {16'h0, immediate}
    // opcode 110: r[rt] <- r[rs] ^ {16'h0, immediate}
    // opcode 111: r[rt] <- {16'h0, immediate}
    // opcode 000: r[rt] <- r[rs]
    // opcode 001: r[rt] <- r[rs] + {16'h0, immediate}
    // opcode 010: r[rt] <- r[rs] - {16'h0, immediate}
    // opcode 011: r[rt] <- r[rs] - {16'h0, immediate}
    // opcode 100: r[rt] <- r[rs] & {16'h0, immediate}
    // opcode 101: r[rt] <- r[rs] | {16'h0, immediate}
    // opcode 110: r[rt] <- r[rs] ^ {16'h0, immediate}
    // opcode 111: r[rt] <- {16'h0, immediate}
    // opcode 000: r[rt] <- r[rs]
    // opcode 001: r[rt] <- r[rs] + {16'h0, immediate}
    // opcode 010: r[rt] <- r[rs] - {16'h0, immediate}
    // opcode 011: r[rt] <- r[rs] - {16'h0, immediate}
    // opcode 100: r[rt] <- r[rs] & {16'h0, immediate}
    // opcode 101: r[rt] <- r[rs] | {16'h0, immediate}
    // opcode 110: r[rt] <- r[rs] ^ {16'h0, immediate}
    //
endmodule
