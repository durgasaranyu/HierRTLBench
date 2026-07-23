// Multi-cycle RISC datapath. PC, IR, A/B regs, ALUout, MDR. Connects all datapath units.
module cpu_datapath (
    input         clk, rst,
    input         pc_write, ir_write, reg_write, mem_write,
    input         alu_src_a, alu_src_b, mem_to_reg, pc_source,
    input  [1:0]  alu_op,
    output [6:0]  opcode,
    output [2:0]  funct3,
    output        zero
);
    reg [6:0]  inst;
    reg [2:0]  reg_dst_addr, reg_src_addr, alu_operand_addr;
    reg        reg_write_en, ir_write_en, pc_write_en, mem_write_en;
    reg        alu_src_a_en, alu_src_b_en, mem_to_reg_en;
    reg        [1:0] alu_op_en;
    reg        [2:0] state;
    reg        [6:0] opcode;
    reg        [2:0] funct3;
    reg        [0:0] pc_src;
    reg        [1:0] alu_operand_sel;
    reg        [0:0] reg_write_sel, mem_write_sel;
    reg        [2:0] reg_read_sel, mem_read_sel;
    reg        [2:0] alu_operand_sel_d;
    reg        [2:0] reg_write_sel_d, mem_write_sel_d;
    reg        [2:0] reg_read_sel_d, mem_read_sel_d;
    reg        [0:0] pc_src_d;
    reg        [1:0] alu_operand_sel_x;
    reg        [0:0] reg_write_sel_x, mem_write_sel_x;
    reg        [2:0] reg_read_sel_x, mem_read_sel_x;
    reg        [2:0] alu_operand_sel_m;
    reg        [0:0] reg_write_sel_m, mem_write_sel_m;
    reg        [2:0] reg_read_sel_m, mem_read_sel_m;
    reg        [2:0] alu_operand_sel_w;
    reg        [0:0] reg_write_sel_w, mem_write_sel_w;
    reg        [2:0] reg_read_sel_w, mem_read_sel_w;
    reg        [2:0] alu_operand_sel_s;
    reg        [0:0] reg_write_sel_s, mem_write_sel_s;
    reg        [2:0] reg_read_sel_s, mem_read_sel_s;
    reg        [2:0] alu_operand_sel_b;
    reg        [0:0] reg_write_sel_b, mem_write_sel_b;
    reg        [2:0] reg_read_sel_b, mem_read_sel_b;
    reg        [2:0] alu_operand_sel_a;
    reg        [0:0] reg_write_sel_a, mem_write_sel_a;
    reg        [2:0] reg_read_sel_a, mem_read_sel_a;
    reg        [2:0] alu_operand_sel_c;
    reg        [0:0] reg_write_sel_c, mem_write_sel_c;
    reg        [2:0] reg_read_sel_c, mem_read_sel_c;
    reg        [2:0] alu_operand_sel_e;
    reg        [0:0] reg_write_sel_e, mem_write_sel_e;
    reg        [2:0] reg_read_sel_e, mem_read_sel_e;
    reg        [2:0] alu_operand_sel_g;
    reg        [0:0] reg_write_sel_g, mem_write_sel_g;
    reg        [2:0] reg_read_sel_g, mem_read_sel_g;
    reg        [2:0] alu_operand_sel_h;
    reg        [0:0] reg_write_sel_h, mem_write_sel_h;
    reg        [2:0] reg_read_sel_h, mem_read_sel_h;
    reg        [2:0] alu_operand_sel_i;
    reg        [0:0] reg_write_sel_i, mem_write_sel_i;
    reg        [2:0] reg_read_sel_i, mem_read_sel_i;
    reg        [2:0] alu_operand_sel_j;
    reg        [0:0] reg_write_sel_j, mem_write_sel_j;
    reg        [2:0] reg_read_sel_j, mem_read_sel_j;
    reg        [2:0] alu_operand_sel_k;
    reg        [0:0] reg_write_sel_k, mem_write_sel_k;
    reg        [2:0] reg_read_sel_k, mem_read_sel_k;
    reg        [2:0] alu_operand_sel_l;
    reg        [0:0] reg_write_sel_l, mem_write_sel_l;
    reg        [2:0] reg_read_sel_l, mem_read_sel_l;
    reg        [2:0] alu_operand_sel_m;
    reg        [0:0] reg_write_sel_m, mem_write_sel_m;
    reg        [2:0] reg_read_sel_m, mem_read_sel_m;
    reg        [2:0] alu_operand_sel_n;
    reg        [0:0] reg_write_sel_n, mem_write_sel_n;
    reg        [2:0] reg_read_sel_n, mem_read_sel_n;
    reg        [2:0] alu_operand_sel_o;
    reg        [0:0] reg_write_sel_o, mem_write_sel_o;
    reg        [2:0] reg_read_sel_o, mem_read_sel_o;
    reg        [2:0] alu_operand_sel_p;
    reg        [0:0] reg_write_sel_p, mem_write_sel_p;
    reg        [2:0] reg_read_sel_p, mem_read_sel_p;
    reg        [2:0] alu_operand_sel_q;
    reg        [0:0] reg_write_sel_q, mem_write_sel_q;
    reg        [2:0] reg_read_sel_q, mem_read_sel_q;
    reg        [2:0] alu_operand_sel_r;
    reg        [0:0] reg_write_sel_r, mem_write_sel_r;
    reg        [2:0] reg_read_sel_r, mem_read_sel_r;
    reg        [2:0] alu_operand_sel_s;
    reg        [0:0] reg_write_sel_s, mem_write_sel_s;
    reg        [2:0] reg_read_sel_s, mem_read_sel_s;
    reg        [2:0] alu_operand_sel_t;
    reg        [0:0] reg_write_sel_t, mem_write_sel_t;
    reg        [2:0] reg_read_sel_t, mem_read_sel_t;
    reg        [2:0] alu_operand_sel_u;
    reg        [0:0] reg_write_sel_u, mem_write_sel_u;
    reg        [2:0] reg_read_sel_u, mem_read_sel_u;
    reg        [2
endmodule
