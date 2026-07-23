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
    reg [31:0] rs1_data, rs2_data, imm_ext;
    reg [4:0]  rs1, rs2, rd;
    reg [6:0]  opcode, funct7;
    reg [2:0]  funct3;
    reg [31:0] instr_i, instr_f, reg_rs1, reg_rs2, reg_imm;
    reg [4:0]  reg_rd;
    reg [6:0]  reg_opcode, reg_funct7;
    reg [2:0]  reg_funct3;
    reg        reg_we, reg_wb;
    assign rs1 = instr_i[25:21];
    assign rs2 = instr_i[20:16];
    assign rd = instr_i[15:11];
    assign funct3 = instr_i[14:12];
    assign opcode = reg_opcode;
    assign funct7 = reg_funct7;
    assign imm_ext = reg_imm;
    always @(posedge clk)
    begin
        if (rst)
        begin
            instr_i <= 32'b0;
            instr_f <= 32'b0;
            reg_rs1 <= 32'b0;
            reg_rs2 <= 32'b0;
            reg_imm <= 32'b0;
            reg_rd <= 5'b0;
            reg_opcode <= 7'b0;
            reg_funct7 <= 7'b0;
            reg_funct3 <= 3'b0;
            reg_we <= 1'b0;
            reg_wb <= 1'b0;
        end
        else
        begin
            instr_i <= instr;
            instr_f <= instr_i;
            reg_rs1 <= rs1_data;
            reg_rs2 <= rs2_data;
            reg_imm <= imm_ext;
            reg_rd <= rd;
            reg_opcode <= opcode;
            reg_funct7 <= funct7;
            reg_funct3 <= funct3;
            reg_we <= wb_we;
            reg_wb <= wb_wb;
        end
    end
    always @(*)
    begin
        rs1_data = wb_data;
        rs2_data = wb_data;
        imm_ext = wb_data;
        case (wb_rd)
            5'd0:
                begin
                    rd = 5'd0;
                    reg_rd = wb_wb? 5'd0 : wb_rd;
                end
            5'd1:
                begin
                    rd = 5'd1;
                    reg_rd = wb_wb? 5'd1 : wb_rd;
                end
            5'd2:
                begin
                    rd = 5'd2;
                    reg_rd = wb_wb? 5'd2 : wb_rd;
                end
            5'd3:
                begin
                    rd = 5'd3;
                    reg_rd = wb_wb? 5'd3 : wb_rd;
                end
            5'd4:
                begin
                    rd = 5'd4;
                    reg_rd = wb_wb? 5'd4 : wb_rd;
                end
            5'd5:
                begin
                    rd = 5'd5;
                    reg_rd = wb_wb? 5'd5 : wb_rd;
                end
            5'd6:
                begin
                    rd = 5'd6;
                    reg_rd = wb_wb? 5'd6 : wb_rd;
                end
            5'd7:
                begin
                    rd = 5'd7;
                    reg_rd = wb_wb? 5'd7 : wb_rd;
                end
            5'd8:
                begin
                    rd = 5'd8;
                    reg_rd = wb_wb? 5'd8 : wb_rd;
                end
            5'd9:
                begin
                    rd = 5'd9;
                    reg_rd = wb_wb? 5'd9 : wb_rd;
                end
            5'd10:
                begin
                    rd = 5'd10;
                    reg_rd = wb_wb? 5'd10 : wb_rd;
                end
            5'd11:
                begin
                    rd = 5'd11;
                    reg_rd = wb_wb? 5'd11 : wb_rd;
                end
            5'd12:
                begin
                    rd = 5'd12;
                    reg_rd = wb_wb? 5'd12 : wb_rd;
                end
            5'd13:
                begin
                    rd = 5'd13;
                    reg_rd = wb_wb? 5'd13 : wb_rd;
                end
            5'd14:
                begin
                    rd = 5'd14;
                    reg_rd = wb_wb? 5'd14 : wb_rd;
                end
            5'd15:
                begin
                    rd = 5'd15;
                    reg_rd = wb_wb? 5'd15 : wb_rd;
                end
            5'd16:
                begin
                    rd = 5'd16;
                    reg_rd = wb_wb? 5'd16 : wb_rd;
                end
            5'd17:
                begin
                    rd = 5'd17;
                    reg_rd = wb_wb? 5'd17 : wb_rd;
                end
            5'd18:
                begin
                    rd = 5'd18;
                    reg_rd = wb_wb? 5'd18 : wb_rd;
                end
            5'd19:
                begin
                    rd = 5'd19;
                    reg_rd = wb_wb? 5'd19 : wb_rd;
                end
            5'd20:
                begin
                    rd = 5'd20;
                    reg_rd = wb_wb? 5'd20 : wb_rd;
                end
            5'd21:
                begin
                    rd = 5'd21;
                    reg_rd = wb_wb? 5'd21 : wb_rd;
                end
            5'd22:
                begin
                    rd = 5'd22;
                    reg_rd = wb_wb? 5'd22 : wb_rd;
                end
            5'd23:
                begin
                    rd = 5'd23;
                    reg_rd = wb_wb? 5'd23 : wb_rd;
                end
            5'd24:
                begin
                    rd = 5'd24;
                    reg_rd = wb_wb? 5'd24 : wb_rd;
                end
            5'd25:
                begin
                    rd = 5'd25;
                    reg_rd = wb_wb? 5'd25 : wb_rd;
                end
            5'd26:
                begin
                    rd = 5'd26;
                    reg_rd = wb_wb? 5'd26 : wb_rd;
                end
            5'd27:
                begin
                    rd = 5'd27;
                    reg_rd = wb_wb? 5'd27 : wb_rd;
                end
            5'd28:
                begin
                    rd = 5'd28;
                    reg_rd = wb_wb? 5'd28 : wb_rd;
                end
            5'd29:
                begin
                    rd = 5'd29;
                    reg_rd = wb_wb? 5'd29 : wb_rd;
                end
            5'd30:
                begin
                    rd = 5'd30;
                    reg_rd = wb_wb? 5'd30 : wb_rd;
                end
            5'd31:
                begin
                    rd = 5'd31;
                    reg_rd = wb_wb? 5'd31 : wb_rd;
                end
        endcase
        case (funct3
endmodule
