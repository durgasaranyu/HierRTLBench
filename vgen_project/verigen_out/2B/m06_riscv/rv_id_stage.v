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
    // Sign-extend immediate
    wire [31:0] sext_imm;
    sign_extend sext_inst(.in(instr[15:0]),.out(sext_imm));
    // Decode opcode
    wire [5:0] opcode_s;
    decoder decoder_opcode(.in(instr[31:26]),.out(opcode_s));
    // Decode funct3
    wire [2:0] funct3_s;
    decoder decoder_funct3(.in(instr[5:0]),.out(funct3_s));
    // Decode funct7
    wire [6:0] funct7_s;
    decoder decoder_funct7(.in(instr[10:0]),.out(funct7_s));
    // rs1 data
    wire [31:0] rs1_data_s;
    regfile_32 regfile(
       .clk(clk),
       .rst(rst),
       .rd(rs1),
       .wr(rs1_data_s),
       .wdata(rs1_data),
       .rdata(rs1_data)
    );
    // rs2 data
    wire [31:0] rs2_data_s;
    regfile_32 regfile_s2(
       .clk(clk),
       .rst(rst),
       .rd(rs2),
       .wr(rs2_data_s),
       .wdata(rs2_data),
       .rdata(rs2_data)
    );
    // imm_ext
    wire [31:0] imm_ext_s;
    sign_extend sext_imm_s(.in(sext_imm),.out(imm_ext_s));
    // opcode
    wire [6:0] opcode_s_s;
    decoder_7_seg decoder_opcode_s(.in(opcode_s),.out(opcode_s_s));
    // rd
    wire [4:0] rd_s;
    decoder_5_seg decoder_rd(.in(rd),.out(rd_s));
    // funct3
    wire [2:0] funct3_s_s;
    decoder_3_seg decoder_funct3_s(.in(funct3_s),.out(funct3_s_s));
    // rs1
    wire [31:0] rs1_data_s_s;
    regfile_32 regfile_rs1(
       .clk(clk),
       .rst(rst),
       .rd(rs1_data_s_s[4:0]),
       .wr(rs1_data_s_s[5]),
       .wdata(rs1_data_s_s[6:0]),
       .rdata(rs1_data_s_s[31:0])
    );
    // rs2
    wire [31:0] rs2_data_s_s;
    regfile_32 regfile_rs2(
       .clk(clk),
       .rst(rst),
       .rd(rs2_data_s_s[4:0]),
       .wr(rs2_data_s_s[5]),
       .wdata(rs2_data_s_s[6:0]),
       .rdata(rs2_data_s_s[31:0])
    );
    // opcode
    wire [6:0] opcode_s_s_s;
    decoder_7_seg decoder_opcode_s_s(.in(opcode_s_s),.out(opcode_s_s_s));
    // funct3
    wire [2:0] funct3_s_s_s;
    decoder_3_seg decoder_funct3_s_s(.in(funct3_s_s_s),.out(funct3_s_s_s));
    // rd
    wire [4:0] rd_s_s;
    decoder_5_seg decoder_rd_s(.in(rd_s_s),.out(rd_s_s));
    // rs1
    wire [31:0] rs1_data_s_s_s;
    regfile_32 regfile_rs1_s(
       .clk(clk),
       .rst(rst),
       .rd(rs1_data_s_s_s[4:0]),
       .wr(rs1_data_s_s_s[5]),
       .wdata(rs1_data_s_s_s[6:0]),
       .rdata(rs1_data_s_s_s[31:0])
    );
    // rs2
    wire [31:0] rs2_data_s_s_s;
    regfile_32 regfile_rs2_s(
       .clk(clk),
       .rst(rst),
       .rd(rs2_data_s_s_s[4:0]),
       .wr(rs2_data_s_s_s[5]),
       .wdata(rs2_data_s_s_s[6:0]),
       .rdata(rs2_data_s_s_s[31:0])
    );
    // rs1
    wire [31:0] rs1_data_s_s_s_s;
    regfile_32 regfile_rs1_s_s(
       .clk(clk),
       .rst(rst),
       .rd(rs1_data_s_s_s[4:0]),
       .wr(rs1_data_s_s_s[5]),
       .wdata(rs1_data_s_s_s[6:0]),
       .rdata(rs1_data_s_s_s[31:0])
    );
    // rs2
    wire [31:0] rs2_data_s_s_s_s;
    regfile_32 regfile_rs2_s_s(
       .clk(clk),
       .rst(rst),
       .rd(rs2_data_s_s_s[4:0]),
       .wr(rs2_data_s_s_s[5]),
       .wdata(rs2_data_s_s_s[6:0]),
       .rdata(rs2_data_s_s_s[31:0])
    );
    // rs1
    wire [31:0] rs1_data_s_s_s_s;
    regfile_32 regfile_rs1_s_s_s(
       .clk(clk),
       .rst(rst),
       .rd(rs1_data_s_s_s[4:0]),
       .wr(rs1_data_s_s_s[5]),
       .wdata(rs1_data_s_s_s[6:0]),
       .rdata(rs1_data_s_s_s[31:0])
    );
    // rs2
    wire [31:0] rs2_data_s_s_s_s;
    regfile_32 regfile_rs2_s_s_s(
       .clk(clk),
       .rst(rst),
       .rd(rs2_data_s_s_s[4:0]),
       .wr(rs2_data_s_s_s[5]),
       .wdata(rs2_data_s_s_s[6:0]),
       .rdata(rs2_data_s_s_s[
endmodule
