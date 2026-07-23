// RISC-V ID stage. Decodes instruction, reads regfile rs1/rs2, sign-extends immediate.
module rv_id_stage (
    input        clk, rst,
    input [31:0] instr,
    input [4:0]  wb_rd,
    input [31:0] wb_data,
    input        wb_we,
    output [31:0] rs1_data, rs2_data, imm_ext,
    output [4:0]  rs1, rs2, rd,
    output [6:0]  opcode, funct7,
    output [2:0]  funct3
);
    reg [31:0] instr_r;
    reg [4:0]  wb_rd_r;
    reg [31:0] wb_data_r;
    reg        wb_we_r;
    reg [31:0] rs1_r, rs2_r;
    reg [31:0] imm_r;
    reg [4:0]  rs1_r2, rs2_r2;
    reg [6:0]  opcode_r;
    reg [2:0]  funct3_r;
    reg [6:0]  funct7_r;
    reg        imm_sign_r;
    reg        reg_we_r;
    reg        mem_we_r;
    reg        mem_addr_r;
    reg [4:0]  reg1_r, reg2_r, reg3_r;
    reg [31:0] reg1_val_r, reg2_val_r, reg3_val_r;
    reg        reg1_val_valid_r, reg2_val_valid_r, reg3_val_valid_r;
    reg [31:0] reg1_r_r, reg2_r_r, reg3_r_r;
    reg [31:0] reg1_i_r, reg2_i_r, reg3_i_r;
    reg [31:0] reg1_i_val_r, reg2_i_val_r, reg3_i_val_r;
    reg        reg1_i_val_valid_r, reg2_i_val_valid_r, reg3_i_val_valid_r;
    reg [31:0] reg1_r_r, reg2_r_r, reg3_r_r;
    reg [31:0] reg1_i_r, reg2_i_r, reg3_i_r;
    reg [31:0] reg1_mem_r, reg2_mem_r, reg3_mem_r;
    reg        reg1_mem_val_r, reg2_mem_val_r, reg3_mem_val_r;
    reg        reg1_mem_val_valid_r, reg2_mem_val_valid_r, reg3_mem_val_valid_r;
    reg [31:0] reg1_r_r, reg2_r_r, reg3_r_r;
    reg [31:0] reg1_i_r, reg2_i_r, reg3_i_r;
    reg [31:0] reg1_mem_r, reg2_mem_r, reg3_mem_r;
    reg        reg1_mem_val_r, reg2_mem_val_r, reg3_mem_val_r;
    reg        reg1_mem_val_valid_r, reg2_mem_val_valid_r, reg3_mem_val_valid_r;
    reg [31:0] reg1_r_r, reg2_r_r, reg3_r_r;
    reg [31:0] reg1_i_r, reg2_i_r, reg3_i_r;
    reg [31:0] reg1_mem_r, reg2_mem_r, reg3_mem_r;
    reg        reg1_mem_val_r, reg2_mem_val_r, reg3_mem_val_r;
    reg        reg1_mem_val_valid_r, reg2_mem_val_valid_r, reg3_mem_val_valid_r;
    reg [31:0] reg1_r_r, reg2_r_r, reg3_r_r;
    reg [31:0] reg1_i_r, reg2_i_r, reg3_i_r;
    reg [31:0] reg1_mem_r, reg2_mem_r, reg3_mem_r;
    reg        reg1_mem_val_r, reg2_mem_val_r, reg3_mem_val_r;
    reg        reg1_mem_val_valid_r, reg2_mem_val_valid_r, reg3_mem_val_valid_r;
    reg [31:0] reg1_r_r, reg2_r_r, reg3_r_r;
    reg [31:0] reg1_i_r, reg2_i_r, reg3_i_r;
    reg [31:0] reg1_mem_r, reg2_mem_r, reg3_mem_r;
    reg        reg1_mem_val_r, reg2_mem_val_r, reg3_mem_val_r;
    reg        reg1_mem_val_valid_r, reg2_mem_val_valid_r, reg3_mem_val_valid_r;
    reg [31:0] reg1_r_r, reg2_r_r, reg3_r_r;
    reg [31:0] reg1_i_r, reg2_i_r, reg3_i_r;
    reg [31:0] reg1_mem_r, reg2_mem_r, reg3_mem_r;
    reg        reg1_mem_val_r, reg2_mem_val_r, reg3_mem_val_r;
    reg        reg1_mem_val_valid_r, reg2_mem_val_valid_r, reg3_mem_val_valid_r;
    reg [31:0] reg1_r_r, reg2_r_r, reg3_r_r;
    reg [31:0] reg1_i_r, reg2_i_r, reg3_i_r;
    reg [31:0] reg1_mem_r, reg2_mem_r, reg3_mem_r;
    reg        reg1_mem_val_r, reg2_mem_val_r, reg3_mem_val_r;
    reg        reg1_mem_val_valid_r, reg2_mem_val_valid_r, reg3_mem_val_valid_r;
    reg [31:0] reg1_r_r, reg2_r_r, reg3_r_r;
    reg [31:0] reg1_i_r, reg2_i_r, reg3_i_r;
    reg [31:0] reg1_mem_r, reg2_mem_r, reg3_mem_r;
    reg        reg1_mem_val_r, reg2_mem_val_r, reg3_mem_val_r;
    reg        reg1_mem_val_valid_r, reg2_mem_val_valid_r, reg3_mem_val_valid_r;
    reg [31:0] reg1_r_r, reg2_r_r, reg3_r_r;
    reg [31:0] reg1_i_r, reg2_i_r, reg3_i_r;
    reg [31:0] reg1_mem_r, reg2_mem_r, reg3_mem_r;
    reg        reg1_mem_val_r, reg2_mem_val_r, reg3_mem_val_r;
    reg        reg1_mem_val_valid_r, reg2_mem_val_valid_r, reg3_mem_val_valid_r;
    reg [31:0] reg1_r_r, reg2_r_r, reg3_r_r;
    reg [31:0] reg1_i_r, reg2_i_r, reg3_i_r;
    reg [31:0] reg1_mem_r, reg2_mem_r, reg3_mem_r;
    reg        reg
endmodule
