`timescale 1ns/1ps
// M06: 5-stage RISC-V pipeline integration top
// Supports: ADD/SUB/AND/OR/ADDI/LW/SW/BEQ
// Submodules: rv_if_stage, rv_id_stage, rv_ex_stage, rv_mem_stage,
//             rv_hazard, rv_forward
// Pipeline registers (IF/ID, ID/EX, EX/MEM, MEM/WB) implemented here.
// Inline control decoder translates opcode → control signals.
module riscv_pipeline_integration (
    input clk, rst
);
    // ── IF stage ──────────────────────────────────────────────────────────────
    wire [31:0] if_pc, if_pc_plus4;
    wire        stall, flush, pc_src;
    wire [31:0] ex_branch_target;

    rv_if_stage u_if (
        .clk(clk), .rst(rst),
        .stall(stall), .pc_src(pc_src),
        .branch_target(ex_branch_target),
        .pc(if_pc), .pc_plus4(if_pc_plus4)
    );

    // Instruction memory (256x32, inlined — rv_if_stage only outputs PC)
    reg [31:0] imem [0:255];
    wire [31:0] if_instr = imem[if_pc[9:2]];

    // ── IF/ID register ────────────────────────────────────────────────────────
    reg [31:0] ifid_instr, ifid_pc;
    always @(posedge clk) begin
        if (rst || flush) begin
            ifid_instr <= 32'h00000013; // NOP
            ifid_pc    <= 32'h0;
        end else if (!stall) begin
            ifid_instr <= if_instr;
            ifid_pc    <= if_pc;
        end
    end

    // ── ID stage + WB writeback ───────────────────────────────────────────────
    wire [4:0]  wb_rd;
    wire [31:0] wb_data;
    wire        wb_we;
    wire [31:0] id_rs1d, id_rs2d, id_imm;
    wire [4:0]  id_rs1, id_rs2, id_rd;
    wire [6:0]  id_opc, id_f7;
    wire [2:0]  id_f3;

    rv_id_stage u_id (
        .clk(clk), .rst(rst),
        .instr(ifid_instr),
        .wb_rd(wb_rd), .wb_data(wb_data), .wb_we(wb_we),
        .rs1_data(id_rs1d), .rs2_data(id_rs2d), .imm_ext(id_imm),
        .rs1(id_rs1), .rs2(id_rs2), .rd(id_rd),
        .opcode(id_opc), .funct7(id_f7), .funct3(id_f3)
    );

    // ── Hazard unit (uses ID/EX registers declared below) ────────────────────
    reg        idex_mem_read_r;
    reg [4:0]  idex_rd_r;

    rv_hazard u_haz (
        .id_ex_mem_read(idex_mem_rd_r),
        .id_ex_rd(idex_rd_r),
        .if_id_rs1(id_rs1), .if_id_rs2(id_rs2),
        .stall(stall), .flush(flush)
    );

    // ── Inline control decoder ────────────────────────────────────────────────
    // Opcodes: R=7'h33 ADDI=7'h13 LW=7'h03 SW=7'h23 BEQ=7'h63
    wire id_alu_src    = (id_opc != 7'h33) && (id_opc != 7'h63);
    wire id_mem_wr     = (id_opc == 7'h23);
    wire id_mem_rd     = (id_opc == 7'h03);
    wire id_reg_wr     = (id_opc == 7'h33) || (id_opc == 7'h13) || (id_opc == 7'h03);
    wire id_mem2reg    = (id_opc == 7'h03);
    wire id_branch     = (id_opc == 7'h63);
    // alu_op: 00=ADD 01=SUB 10=AND 11=OR
    wire [1:0] id_alu_op =
        (id_opc == 7'h63)                                  ? 2'b01 :  // BEQ→SUB
        (id_opc == 7'h33 && id_f3==3'b000 && id_f7[5])    ? 2'b01 :  // SUB
        (id_opc == 7'h33 && id_f3==3'b111)                 ? 2'b10 :  // AND
        (id_opc == 7'h33 && id_f3==3'b110)                 ? 2'b11 :  // OR
                                                              2'b00;   // ADD

    // ── ID/EX register ────────────────────────────────────────────────────────
    reg [31:0] idex_rs1d, idex_rs2d, idex_imm, idex_pc;
    reg [4:0]  idex_rs1,  idex_rs2;
    reg        idex_alu_src, idex_mem_wr, idex_reg_wr, idex_mem2reg, idex_branch;
    reg [1:0]  idex_alu_op;

    always @(posedge clk) begin
        if (rst || flush) begin
            idex_rs1d    <= 0; idex_rs2d  <= 0; idex_imm   <= 0; idex_pc   <= 0;
            idex_rs1     <= 0; idex_rs2   <= 0; idex_rd_r  <= 0;
            idex_alu_src <= 0; idex_mem_wr<= 0; idex_reg_wr<= 0;
            idex_mem_rd_r<= 0; idex_mem2reg<=0; idex_branch<= 0;
            idex_alu_op  <= 0;
        end else if (!stall) begin
            idex_rs1d    <= id_rs1d;    idex_rs2d   <= id_rs2d;
            idex_imm     <= id_imm;     idex_pc     <= ifid_pc;
            idex_rs1     <= id_rs1;     idex_rs2    <= id_rs2; idex_rd_r <= id_rd;
            idex_alu_src <= id_alu_src; idex_mem_wr <= id_mem_wr;
            idex_reg_wr  <= id_reg_wr;  idex_mem_rd_r<= id_mem_rd;
            idex_mem2reg <= id_mem2reg; idex_branch <= id_branch;
            idex_alu_op  <= id_alu_op;
        end
    end
    // separate reg declaration required by some tools
     // already assigned above; redeclare here for clarity

    // ── Forwarding unit (uses EX/MEM and MEM/WB registers below) ─────────────
    reg [4:0]  exmem_rd_r, memwb_rd_r;
    reg        exmem_rw_r, memwb_rw_r;
    wire [1:0] fwd_a, fwd_b;
    reg [31:0] exmem_alu_r;   // forwarding value from EX/MEM
    reg [31:0] wb_result_r;   // forwarding value from MEM/WB

    rv_forward u_fwd (
        .id_ex_rs1(idex_rs1), .id_ex_rs2(idex_rs2),
        .ex_mem_rd(exmem_rd_r), .mem_wb_rd(memwb_rd_r),
        .ex_mem_reg_write(exmem_rw_r), .mem_wb_reg_write(memwb_rw_r),
        .forward_a(fwd_a), .forward_b(fwd_b)
    );

    // ── EX stage ──────────────────────────────────────────────────────────────
    wire [31:0] ex_alu_res, ex_btgt;
    wire        ex_zero;

    rv_ex_stage u_ex (
        .rs1_data(idex_rs1d), .rs2_data(idex_rs2d),
        .imm_ext(idex_imm), .pc(idex_pc),
        .fwd_ex_mem(exmem_alu_r), .fwd_mem_wb(wb_result_r),
        .forward_a(fwd_a), .forward_b(fwd_b),
        .alu_src(idex_alu_src), .alu_op(idex_alu_op),
        .alu_result(ex_alu_res), .branch_target(ex_btgt),
        .zero(ex_zero)
    );

    assign ex_branch_target = ex_btgt;
    assign pc_src = idex_branch & ex_zero;

    // ── EX/MEM register ───────────────────────────────────────────────────────
    reg [31:0] exmem_rs2d;
    reg        exmem_mem_wr, exmem_mem_rd, exmem_mem2reg;

    always @(posedge clk) begin
        if (rst) begin
            exmem_alu_r  <= 0; exmem_rs2d  <= 0; exmem_rd_r  <= 0;
            exmem_rw_r   <= 0; exmem_mem_wr<= 0; exmem_mem_rd<= 0;
            exmem_mem2reg<= 0;
        end else begin
            exmem_alu_r  <= ex_alu_res;  exmem_rs2d  <= idex_rs2d;
            exmem_rd_r   <= idex_rd_r;   exmem_rw_r  <= idex_reg_wr;
            exmem_mem_wr <= idex_mem_wr; exmem_mem_rd<= idex_mem_rd_r;
            exmem_mem2reg<= idex_mem2reg;
        end
    end

    // ── MEM stage ─────────────────────────────────────────────────────────────
    wire [31:0] mem_rdata;

    rv_mem_stage u_mem (
        .clk(clk),
        .alu_result(exmem_alu_r), .rs2_data(exmem_rs2d),
        .mem_write(exmem_mem_wr), .mem_read(exmem_mem_rd),
        .read_data(mem_rdata)
    );

    // ── MEM/WB register ───────────────────────────────────────────────────────
    reg [31:0] memwb_alu, memwb_rdata;
    reg        memwb_m2r;

    always @(posedge clk) begin
        if (rst) begin
            memwb_alu  <= 0; memwb_rdata<= 0; memwb_rd_r <= 0;
            memwb_rw_r <= 0; memwb_m2r  <= 0;
        end else begin
            memwb_alu  <= exmem_alu_r; memwb_rdata<= mem_rdata;
            memwb_rd_r <= exmem_rd_r;  memwb_rw_r <= exmem_rw_r;
            memwb_m2r  <= exmem_mem2reg;
        end
    end

    // ── WB stage (combinational mux → back to ID) ─────────────────────────────
    assign wb_result_r = memwb_m2r ? memwb_rdata : memwb_alu;
    assign wb_rd       = memwb_rd_r;
    assign wb_data     = wb_result_r;
    assign wb_we       = memwb_rw_r;
endmodule
