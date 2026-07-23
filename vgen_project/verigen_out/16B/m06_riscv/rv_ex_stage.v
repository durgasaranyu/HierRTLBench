// RISC-V EX stage. ALU with forwarding muxes. Computes branch target = pc + imm.
// alu_op: 00=ADD, 01=SUB, 10=AND, 11=OR.
module rv_ex_stage (
    input [31:0] rs1_data, rs2_data, imm_ext, pc,
    input [31:0] fwd_ex_mem, fwd_mem_wb,
    input [1:0]  forward_a, forward_b,
    input        alu_src,
    input [1:0]  alu_op,
    output [31:0] alu_result, branch_target,
    output        zero
);
    assign zero = ~|alu_result;
    assign branch_target = pc + imm_ext;
    assign alu_result = (alu_src)? fwd_ex_mem : fwd_mem_wb;
    assign branch_mispredict = (forward_a == 2'b01) | (forward_b == 2'b01);
    assign alu_op_ex = (alu_op == 2'b00)? alu_result[31:28] : alu_result[27:24];
    assign alu_op_mem = (alu_op == 2'b00)? alu_result[23:16] : alu_result[15:8];
    assign alu_op_wb = (alu_op == 2'b00)? alu_result[7:0]  : alu_result[15:8];
    assign alu_op_add = (alu_op_ex == 3'b000);
    assign alu_op_sub = (alu_op_ex == 3'b001);
    assign alu_op_and = (alu_op_ex == 3'b100);
    assign alu_op_or  = (alu_op_ex == 3'b101);
    assign alu_op_xor = (alu_op_ex == 3'b110);
    assign alu_op_sll = (alu_op_ex == 3'b111);
    assign alu_op_sra = (alu_op_ex == 3'b011);
    assign alu_op_srl = (alu_op_ex == 3'b101);
    assign alu_op_addi = (alu_op_mem == 3'b000);
    assign alu_op_subi = (alu_op_mem == 3'b001);
    assign alu_op_andi = (alu_op_mem == 3'b100);
    assign alu_op_ori  = (alu_op_mem == 3'b101);
    assign alu_op_xori = (alu_op_mem == 3'b110);
    assign alu_op_call = (alu_op_mem == 3'b111);
    assign alu_op_rdcycle = (alu_op_wb == 3'b000);
    assign alu_op_rdcycleh = (alu_op_wb == 3'b001);
    assign alu_op_rdinstr = (alu_op_wb == 3'b010);
    assign alu_op_rdinstrh = (alu_op_wb == 3'b011);
    assign alu_op_getq = (alu_op_wb == 3'b100);
    assign alu_op_setq = (alu_op_wb == 3'b101);
    assign alu_op_retirq = (alu_op_wb == 3'b110);
    assign alu_op_maskirq = (alu_op_wb == 3'b111);
    assign alu_op_trap = (alu_op_ex == 3'b111);
    assign alu_op_rsv02 = (alu_op_ex == 3'b112);
    assign alu_op_rsv09 = (alu_op_ex == 3'b113);
    assign alu_op_rsv10 = (alu_op_ex == 3'b114);
    assign alu_op_rsv17 = (alu_op_ex == 3'b115);
    assign alu_op_rsv18 = (alu_op_ex == 3'b116);
    assign alu_op_rsv25 = (alu_op_ex == 3'b117);
    assign alu_op_rsv26 = (alu_op_ex == 3'b118);
    assign alu_op_rsv33 = (alu_op_ex == 3'b119);
    assign alu_op_rsv34 = (alu_op_ex == 3'b120);
    assign alu_op_rsv41 = (alu_op_ex == 3'b121);
    assign alu_op_rsv42 = (alu_op_ex == 3'b122);
    assign alu_op_rsv49 = (alu_op_ex == 3'b123);
    assign alu_op_rsv57 = (alu_op_ex == 3'b124);
    assign alu_op_rsv61 = (alu_op_ex == 3'b125);
    assign alu_op_rsv62 = (alu_op_ex == 3'b126);
    assign alu_op_rsv63 = (alu_op_ex == 3'b127);
    assign alu_op_eret = (alu_op_ex == 3'b128);
    assign alu_op_roli = (alu_op_ex == 3'b129);
    assign alu_op_rol = (alu_op_ex == 3'b130);
    assign alu_op_flushp = (alu_op_ex == 3'b131);
    assign alu_op_ret = (alu_op_ex == 3'b132);
    assign alu_op_nor = (alu_op_ex == 3'b133);
    assign alu_op_mulxuu = (alu_op_ex == 3'b134);
    assign alu_op_cmpge = (alu_op_ex == 3'b135);
    assign alu_op_bret = (alu_op_ex == 3'b136);
    assign alu_op_ror = (alu_op_ex == 3'b137);
    assign alu_op_flushi = (alu_op_ex == 3'b138);
    assign alu_op_jmp = (alu_op_ex == 3'b139);
    assign alu_op_and = (alu_op_ex == 3'b140);
    assign alu_op_cmplt = (alu_op_ex == 3'b141);
    assign alu_op_slli = (alu_op_ex == 3'b142);
    assign alu_op_sll = (alu_op_ex == 3'b143);
    assign alu_op_wrcycle = (alu_op_ex == 3'b144);
    assign alu_op_wrcycleh = (alu_op_ex == 3'b145);
    assign alu_op_wrinstr = (alu_op_ex == 3'b146);
    assign alu_op_wrinstrh = (alu_op_ex == 3'b147);
    assign alu_op_bge = (alu_op_ex == 3'b148);
    assign alu_op_rsv10 = (alu_op_ex == 3'b149);
    assign alu_op_rsv42 = (alu_op_ex == 3'b150);
    assign alu_op_rsv34 = (alu_op_ex == 3'b151);
    assign alu_op_rsv62 = (alu_op_ex == 3'b152);
    assign alu_op_rsv02 = (alu_op_ex == 3'b153);
    assign alu_op_rsv18 = (alu_op
endmodule
