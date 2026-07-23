#!/usr/bin/env python3
"""
write_integrations.py
=====================
Writes all 14 *_top_integration.v files directly to your output tree.
No LLM inference required — these are deterministic wiring/glue modules.

Usage:
    python write_integrations.py --output_dir /scratch/you/verigen_outputs

Files written (one per benchmark module):
    m01_alu/alu_top_integration.v
    m02_regfile/regfile_top_integration.v
    m03_uart/uart_tx_top_integration.v
    m04_cpu/cpu_top_integration.v
    m05_ctrl/ctrl_top_integration.v
    m06_riscv/rv_top_integration.v
    m07_cache/cache_top_integration.v
    m08_arbiter/rr_top_integration.v
    m09_aes/aes_top_integration.v
    m10_sha256/sha256_top_integration.v
    m11_crc32/crc32_top_integration.v
    m12_fft/fft_top_integration.v
    m13_matmul/mat_top_integration.v
    m14_sort/bubble_sort_top_integration.v
"""

import os, argparse

# ─────────────────────────────────────────────────────────────────────────────
# All 14 integration modules as verbatim Verilog strings
# ─────────────────────────────────────────────────────────────────────────────

FILES = {}

# ── M01: N-bit ALU ────────────────────────────────────────────────────────────
FILES["m01_alu/alu_top_integration.v"] = """\
`timescale 1ns/1ps
// M01: N-bit ALU integration top
// Instantiates alu_addsub, alu_logic, alu_shift, alu_flags.
// op: 000=ADD 001=SUB 010=AND 011=OR 100=XOR 101=SHL
// Registered outputs on posedge clk, synchronous reset.
module alu_integration #(parameter N = 8) (
    input              clk, rst,
    input  [N-1:0]     a, b,
    input  [2:0]       op,
    output reg [N-1:0] result,
    output reg         zero_flag, carry_flag
);
    // ── submodule output wires ────────────────────────────────────────────────
    wire [N-1:0] add_res, log_res, sh_res;
    wire         add_c, sh_c;

    // alu_addsub: op=0 → ADD, op=1 → SUB (uses op[0])
    alu_addsub #(.N(N)) u_addsub (
        .a(a), .b(b), .op(op[0]),
        .result(add_res), .carry_out(add_c)
    );

    // alu_logic: sel 00=AND 01=OR 10=XOR
    // map ALU op to logic sel
    wire [1:0] log_sel = (op == 3'b010) ? 2'b00 :   // AND
                         (op == 3'b011) ? 2'b01 :   // OR
                         (op == 3'b100) ? 2'b10 :   // XOR
                                          2'b00;
    alu_logic #(.N(N)) u_logic (
        .a(a), .b(b), .sel(log_sel),
        .result(log_res)
    );

    // alu_shift: logical left shift by 1
    alu_shift #(.N(N)) u_shift (
        .a(a), .result(sh_res), .carry_out(sh_c)
    );

    // ── result mux ───────────────────────────────────────────────────────────
    wire [N-1:0] mux_res;
    wire         carry_w;

    assign mux_res = (op[2:1] == 2'b00) ? add_res :   // ADD or SUB
                     (op == 3'b101)      ? sh_res  :   // SHL
                                           log_res;    // AND/OR/XOR

    assign carry_w = (op == 3'b101) ? sh_c : add_c;

    // ── flags ────────────────────────────────────────────────────────────────
    wire zf_w, cf_w;
    alu_flags #(.N(N)) u_flags (
        .result(mux_res), .carry_in(carry_w),
        .zero_flag(zf_w), .carry_flag(cf_w)
    );

    // ── registered outputs ───────────────────────────────────────────────────
    always @(posedge clk) begin
        if (rst) begin
            result     <= {N{1'b0}};
            zero_flag  <= 1'b0;
            carry_flag <= 1'b0;
        end else begin
            result     <= mux_res;
            zero_flag  <= zf_w;
            carry_flag <= cf_w;
        end
    end
endmodule
"""

# ── M02: Register File ────────────────────────────────────────────────────────
FILES["m02_regfile/regfile_top_integration.v"] = """\
`timescale 1ns/1ps
// M02: 32-entry register file integration top
// Wraps regfile_mem. Dual async read, single sync write. x0 hardwired 0.
module regfile_integration (
    input         clk, rst,
    input  [4:0]  rs1, rs2, rd,
    input  [31:0] wdata,
    input         we,
    output [31:0] rdata1, rdata2
);
    regfile_mem u_mem (
        .clk(clk), .rst(rst),
        .rs1(rs1), .rs2(rs2), .rd(rd),
        .wdata(wdata), .we(we),
        .rdata1(rdata1), .rdata2(rdata2)
    );
endmodule
"""

# ── M03: UART TX ──────────────────────────────────────────────────────────────
FILES["m03_uart/uart_tx_top_integration.v"] = """\
`timescale 1ns/1ps
// M03: UART TX integration top (8-N-1)
// Instantiates baud_gen, uart_tx_fsm, uart_tx_shift.
// baud_gen  → tick → uart_tx_fsm (load, shift_en, tx_out, busy)
// uart_tx_shift holds the byte; FSM controls load/shift timing.
module uart_tx_integration #(
    parameter CLK_FREQ  = 50000000,
    parameter BAUD_RATE = 115200
) (
    input        clk, rst, tx_start,
    input  [7:0] tx_data,
    output       tx, busy
);
    wire tick, load, shift_en, tx_out, busy_w, serial_out, empty;

    baud_gen #(
        .CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)
    ) u_baud (
        .clk(clk), .rst(rst), .tick(tick)
    );

    uart_tx_shift u_shift (
        .clk(clk), .rst(rst),
        .load(load), .shift_en(shift_en),
        .data(tx_data),
        .serial_out(serial_out),
        .empty(empty)
    );

    uart_tx_fsm u_fsm (
        .clk(clk), .rst(rst),
        .tick(tick), .tx_start(tx_start),
        .load(load), .shift_en(shift_en),
        .tx_out(tx_out), .busy(busy_w)
    );

    // FSM drives tx_out (start=0, data bits, stop=1)
    assign tx   = tx_out;
    assign busy = busy_w;
endmodule
"""

# ── M04: Multi-Cycle CPU ──────────────────────────────────────────────────────
FILES["m04_cpu/cpu_top_integration.v"] = """\
`timescale 1ns/1ps
// M04: Multi-cycle Harvard RISC CPU integration top
// Wires cpu_control <-> cpu_datapath.
// Control signals flow control→datapath; status signals flow datapath→control.
module multicycle_cpu_integration (
    input clk, rst
);
    // control → datapath
    wire        pc_write, ir_write, reg_write, mem_write;
    wire        alu_src_a, alu_src_b, mem_to_reg, pc_source;
    wire [1:0]  alu_op;
    // datapath → control
    wire [6:0]  opcode;
    wire [2:0]  funct3;
    wire        zero;

    cpu_control u_ctrl (
        .clk(clk), .rst(rst),
        .opcode(opcode), .funct3(funct3), .zero(zero),
        .pc_write(pc_write), .ir_write(ir_write),
        .reg_write(reg_write), .mem_write(mem_write),
        .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
        .mem_to_reg(mem_to_reg), .pc_source(pc_source),
        .alu_op(alu_op)
    );

    cpu_datapath u_dp (
        .clk(clk), .rst(rst),
        .pc_write(pc_write), .ir_write(ir_write),
        .reg_write(reg_write), .mem_write(mem_write),
        .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
        .mem_to_reg(mem_to_reg), .pc_source(pc_source),
        .alu_op(alu_op),
        .opcode(opcode), .funct3(funct3), .zero(zero)
    );
endmodule
"""

# ── M05: Hardwired Control ────────────────────────────────────────────────────
FILES["m05_ctrl/ctrl_top_integration.v"] = """\
`timescale 1ns/1ps
// M05: Hardwired control integration top
// Muxes ctrl_phase01 (phases 0-1) and ctrl_phase234 (phases 2-4).
module hardwired_ctrl_integration (
    input  [6:0] opcode,
    input  [2:0] phase,
    output       pc_write, ir_write, reg_write, mem_write,
    output       alu_src_a, alu_src_b, mem_to_reg, pc_source
);
    wire p01_pcw,  p01_irw,  p01_rgw,  p01_mew;
    wire p01_sa,   p01_sb,   p01_m2r,  p01_pcs;
    wire p234_pcw, p234_irw, p234_rgw, p234_mew;
    wire p234_sa,  p234_sb,  p234_m2r, p234_pcs;

    ctrl_phase01 u_p01 (
        .opcode(opcode), .phase(phase),
        .pc_write(p01_pcw), .ir_write(p01_irw),
        .reg_write(p01_rgw), .mem_write(p01_mew),
        .alu_src_a(p01_sa), .alu_src_b(p01_sb),
        .mem_to_reg(p01_m2r), .pc_source(p01_pcs)
    );

    ctrl_phase234 u_p234 (
        .opcode(opcode), .phase(phase),
        .pc_write(p234_pcw), .ir_write(p234_irw),
        .reg_write(p234_rgw), .mem_write(p234_mew),
        .alu_src_a(p234_sa), .alu_src_b(p234_sb),
        .mem_to_reg(p234_m2r), .pc_source(p234_pcs)
    );

    wire use01 = (phase <= 3'd1);
    assign pc_write  = use01 ? p01_pcw  : p234_pcw;
    assign ir_write  = use01 ? p01_irw  : p234_irw;
    assign reg_write = use01 ? p01_rgw  : p234_rgw;
    assign mem_write = use01 ? p01_mew  : p234_mew;
    assign alu_src_a = use01 ? p01_sa   : p234_sa;
    assign alu_src_b = use01 ? p01_sb   : p234_sb;
    assign mem_to_reg= use01 ? p01_m2r  : p234_m2r;
    assign pc_source = use01 ? p01_pcs  : p234_pcs;
endmodule
"""

# ── M06: 5-Stage RISC-V Pipeline ─────────────────────────────────────────────
FILES["m06_riscv/rv_top_integration.v"] = """\
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
"""

# ── M07: Direct-Mapped Cache ──────────────────────────────────────────────────
FILES["m07_cache/cache_top_integration.v"] = """\
`timescale 1ns/1ps
// M07: Direct-mapped write-through cache integration top
// 16 sets, 4-byte lines. tag[31:6]=24b, index[5:2]=4b, offset[1:0]=2b.
module cache_integration (
    input         clk, rst, cpu_req, cpu_we,
    input  [31:0] cpu_addr, cpu_wdata,
    output [31:0] cpu_rdata,
    output        stall,
    output [31:0] mem_addr,
    input  [31:0] mem_rdata,
    output        mem_req
);
    wire [23:0] req_tag  = cpu_addr[31:6];
    wire [3:0]  idx      = cpu_addr[5:2];
    wire [1:0]  offset   = cpu_addr[1:0];

    wire [23:0] tag_out;
    wire [31:0] data_out;
    wire        valid_out, hit, we_tag, we_data, mem_we, mem_ack;
    wire [7:0]  read_byte;

    // On write fill from cpu_wdata; on miss fill from mem_rdata
    wire [31:0] data_in = cpu_we ? cpu_wdata : mem_rdata;

    cache_arrays u_arr (
        .clk(clk), .rst(rst), .index(idx),
        .tag_in(req_tag), .data_in(data_in),
        .we_tag(we_tag), .we_data(we_data),
        .tag_out(tag_out), .data_out(data_out), .valid_out(valid_out)
    );

    cache_hit_logic u_hit (
        .req_tag(req_tag), .stored_tag(tag_out),
        .byte_offset(offset), .valid(valid_out), .data(data_out),
        .hit(hit), .read_byte(read_byte)
    );

    // Single-cycle memory model: ack immediately
    assign mem_ack = mem_req;

    cache_ctrl u_ctrl (
        .clk(clk), .rst(rst),
        .cpu_req(cpu_req), .mem_ack(mem_ack), .hit(hit), .cpu_we(cpu_we),
        .we_tag(we_tag), .we_data(we_data),
        .mem_req(mem_req), .mem_we(mem_we), .stall(stall)
    );

    assign cpu_rdata = {4{read_byte}};          // byte replicated to word
    assign mem_addr  = {cpu_addr[31:2], 2'b00}; // word-aligned
endmodule
"""

# ── M08: Round-Robin Arbiter ──────────────────────────────────────────────────
FILES["m08_arbiter/rr_top_integration.v"] = """\
`timescale 1ns/1ps
// M08: Round-robin arbiter integration top
// rr_grant_logic (combinational) → register → rr_ptr (updates pointer).
module round_robin_arbiter_integration #(parameter N = 4) (
    input          clk, rst,
    input  [N-1:0] req,
    output reg [N-1:0] grant
);
    wire [N-1:0] ptr, grant_comb;

    rr_grant_logic #(.N(N)) u_gl (
        .req(req), .ptr(ptr), .grant(grant_comb)
    );

    rr_ptr #(.N(N)) u_ptr (
        .clk(clk), .rst(rst),
        .grant(grant),      // use registered grant so ptr advances after commit
        .ptr(ptr)
    );

    always @(posedge clk) begin
        if (rst) grant <= {N{1'b0}};
        else     grant <= grant_comb;
    end
endmodule
"""

# ── M09: AES-128 ──────────────────────────────────────────────────────────────
FILES["m09_aes/aes_top_integration.v"] = """\
`timescale 1ns/1ps
// M09: AES-128 encryption integration top
// 10-round FSM. All round submodules are purely combinational.
// INIT: state = plaintext XOR rk[0]
// ROUND 1-9: sub → shift → mix → addroundkey
// FINAL (round 10): sub → shift → addroundkey (no mix)
module aes128_integration (
    input          clk, rst, start,
    input  [127:0] plaintext, key,
    output reg [127:0] ciphertext,
    output reg         done
);
    localparam IDLE=3'd0, INIT=3'd1, ROUND=3'd2, FINAL=3'd3, DONE_ST=3'd4;
    reg [2:0] state;
    reg [3:0] round;        // 1..9 for ROUND, 10 for FINAL

    // Key schedule: combinational, 11x128-bit round keys packed as 1408 bits
    wire [1407:0] rk_all;
    aes_keyschedule u_ks (.key(key), .round_keys(rk_all));

    wire [127:0] cur_rk = rk_all[128*round +: 128];

    // State register (updated each FSM clock)
    reg [127:0] aes_st;

    // Round pipeline (combinational, fed from aes_st)
    wire [127:0] sb_out, sr_out, mc_out;
    wire [127:0] ark_round, ark_final, ark_init;

    aes_subbytes    u_sb  (.state_in(aes_st),    .state_out(sb_out));
    aes_shiftrows   u_sr  (.state_in(sb_out),    .state_out(sr_out));
    aes_mixcolumns  u_mc  (.state_in(sr_out),    .state_out(mc_out));

    // Rounds 1-9: addroundkey after mix
    aes_addroundkey u_ark_r (.state_in(mc_out),   .round_key(cur_rk), .state_out(ark_round));
    // Round 10 (final): addroundkey after shift (no mix)
    aes_addroundkey u_ark_f (.state_in(sr_out),   .round_key(cur_rk), .state_out(ark_final));
    // Initial round: plaintext XOR rk[0]
    aes_addroundkey u_ark_i (.state_in(plaintext), .round_key(rk_all[127:0]), .state_out(ark_init));

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE; round <= 4'd0; done <= 0;
            aes_st <= 0; ciphertext <= 0;
        end else begin
            done <= 0;
            case (state)
                IDLE:    if (start) state <= INIT;
                INIT: begin
                    aes_st <= ark_init;
                    round  <= 4'd1;
                    state  <= ROUND;
                end
                ROUND: begin
                    aes_st <= ark_round;         // sub+shift+mix+addroundkey
                    if (round == 4'd9) begin
                        round <= 4'd10;
                        state <= FINAL;
                    end else
                        round <= round + 4'd1;
                end
                FINAL: begin
                    aes_st     <= ark_final;     // sub+shift+addroundkey
                    ciphertext <= ark_final;
                    done       <= 1'b1;
                    state      <= DONE_ST;
                end
                DONE_ST: state <= IDLE;
            endcase
        end
    end
endmodule
"""

# ── M10: SHA-256 ──────────────────────────────────────────────────────────────
FILES["m10_sha256/sha256_top_integration.v"] = """\
`timescale 1ns/1ps
// M10: SHA-256 integration top — single 512-bit block
// sha256_msg_sched and sha256_compress are both purely combinational,
// so the FSM advances one state per clock cycle.
// FSM: IDLE -> SCHEDULE -> COMPRESS -> DONE
module sha256_integration (
    input          clk, rst, start,
    input  [511:0] block_in,
    output reg [255:0] hash_out,
    output reg         done
);
    // SHA-256 initial hash values (FIPS 180-4 §5.3.3)
    localparam [255:0] H_INIT = {
        32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372, 32'ha54ff53a,
        32'h510e527f, 32'h9b05688c, 32'h1f83d9ab, 32'h5be0cd19
    };

    localparam IDLE=2'd0, SCHEDULE=2'd1, COMPRESS=2'd2, DONE_ST=2'd3;
    reg [1:0] state;

    // Both submodules are purely combinational
    wire [2047:0] W;
    wire [255:0]  H_out;

    sha256_msg_sched u_sched (.block_in(block_in), .W(W));
    // For single-block hashing H_in = H_INIT.
    // For multi-block extend this to pass previous hash_out as H_in.
    sha256_compress  u_comp  (.H_in(H_INIT), .W(W), .H_out(H_out));

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE; done <= 0; hash_out <= 0;
        end else begin
            done <= 0;
            case (state)
                IDLE:     if (start) state <= SCHEDULE;
                SCHEDULE:            state <= COMPRESS;
                COMPRESS: begin
                    hash_out <= H_out;
                    done     <= 1'b1;
                    state    <= DONE_ST;
                end
                DONE_ST: state <= IDLE;
            endcase
        end
    end
endmodule
"""

# ── M11: CRC-32 ───────────────────────────────────────────────────────────────
FILES["m11_crc32/crc32_top_integration.v"] = """\
`timescale 1ns/1ps
// M11: CRC-32 IEEE 802.3 integration top (bit-serial)
// done_in to ctrl: falling edge of valid (end of data stream).
module crc32_integration (
    input         clk, rst, start, data_in, valid,
    output [31:0] crc_out,
    output        ready
);
    wire init;
    wire [31:0] crc_reg;

    crc32_lfsr u_lfsr (
        .clk(clk), .rst(rst),
        .init(init), .data_in(data_in), .valid(valid),
        .crc_reg(crc_reg)
    );

    // Detect falling edge of valid → pulse done_in
    reg valid_d;
    always @(posedge clk) valid_d <= rst ? 1'b0 : valid;
    wire done_in = valid_d & ~valid;

    crc32_ctrl u_ctrl (
        .clk(clk), .rst(rst),
        .start(start), .done_in(done_in),
        .crc_raw(crc_reg),
        .init(init), .crc_out(crc_out)
    );

    // ready: asserts one cycle after done_in
    reg ready_r;
    always @(posedge clk) ready_r <= rst ? 1'b0 : done_in;
    assign ready = ready_r;
endmodule
"""

# ── M12: 8-Point FFT ─────────────────────────────────────────────────────────
FILES["m12_fft/fft_top_integration.v"] = """\
`timescale 1ns/1ps
// M12: 8-point fixed-point FFT integration top (Cooley-Tukey DIT, Q1.15)
// Purely combinational: stage1 → stage23, output in bit-reversed order.
module fft8_integration (
    input  signed [127:0] xre_flat, xim_flat,
    output signed [127:0] Xre_flat, Xim_flat
);
    wire signed [127:0] s1re, s1im;

    fft_stage1  u_s1  (
        .xre_flat(xre_flat), .xim_flat(xim_flat),
        .s1re_flat(s1re),    .s1im_flat(s1im)
    );
    fft_stage23 u_s23 (
        .s1re_flat(s1re),    .s1im_flat(s1im),
        .s3re_flat(Xre_flat),.s3im_flat(Xim_flat)
    );
endmodule
"""

# ── M13: 16×16 Matrix Multiplier ─────────────────────────────────────────────
FILES["m13_matmul/mat_top_integration.v"] = """\
`timescale 1ns/1ps
// M13: 16x16 matrix multiply integration top
// 16 mat_row instances run in parallel (one per row of A).
// A column counter sequences through columns 0..15 of B.
// Each column takes 16 cycles. Total wall time = 16*16 = 256 cycles.
// C[i][j] = A_row_i · B_col_j  stored at C_flat[32*(16*i+j) +: 32].
// Row-major storage: A_flat[256*i +: 256] = row i of A (16x 16-bit elements).
//                    B_flat[32*(16*r+c) +: 32] = B[r][c]
module matrix_mult_integration (
    input          clk, rst, start,
    input  [4095:0] A_flat, B_flat,
    output reg [8191:0] C_flat,
    output             done
);
    // ── Column extraction helper ──────────────────────────────────────────────
    // col_j_flat[16*r +: 16] = B[r][col] for r=0..15, packed as 256-bit vector
    // B stores 32-bit elements; take lower 16 bits as the unsigned value
    function [255:0] get_col;
        input [4095:0] B;
        input [3:0]    col;
        integer r;
        begin
            for (r = 0; r < 16; r = r+1)
                get_col[16*r +: 16] = B[32*(16*r + col) +: 16];
        end
    endfunction

    // ── Sequencer ─────────────────────────────────────────────────────────────
    reg [3:0]  col;
    reg        row_start;
    reg [1:0]  seq;
    localparam S_IDLE=2'd0, S_KICK=2'd1, S_WAIT=2'd2, S_DONE=2'd3;

    wire [255:0] col_b_flat = get_col(B_flat, col);

    // ── 16 mat_row instances ──────────────────────────────────────────────────
    genvar gi;
    wire [31:0] rres [0:15];
    wire [15:0] rdone;

    generate
        for (gi = 0; gi < 16; gi = gi+1) begin : ROWS
            mat_row u_r (
                .clk(clk), .rst(rst),
                .start(row_start),
                .row_a_flat(A_flat[256*gi +: 256]),
                .col_b_flat(col_b_flat),
                .result(rres[gi]),
                .done(rdone[gi])
            );
        end
    endgenerate

    // ── Collect results ───────────────────────────────────────────────────────
    integer ri;
    always @(posedge clk) begin
        if (rdone[0]) begin   // all 16 rows finish simultaneously
            for (ri = 0; ri < 16; ri = ri+1)
                C_flat[32*(16*ri + col) +: 32] <= rres[ri];
        end
    end

    // ── FSM ───────────────────────────────────────────────────────────────────
    always @(posedge clk) begin
        if (rst) begin
            seq <= S_IDLE; col <= 0; row_start <= 0;
        end else begin
            row_start <= 0;
            case (seq)
                S_IDLE: if (start) begin col <= 0; seq <= S_KICK; end
                S_KICK: begin row_start <= 1; seq <= S_WAIT; end
                S_WAIT: if (rdone[0]) begin
                    if (col == 4'd15) seq <= S_DONE;
                    else begin col <= col + 1; seq <= S_KICK; end
                end
                S_DONE: seq <= S_IDLE;
            endcase
        end
    end

    assign done = (seq == S_DONE);
endmodule
"""

# ── M14: Hardware Bubble Sort ─────────────────────────────────────────────────
FILES["m14_sort/bubble_sort_top_integration.v"] = """\
`timescale 1ns/1ps
// M14: Hardware bubble sort integration top
// 8 elements, 8-bit unsigned.
// bubble_sort_fsm controls load_en, swap_en, i (compare index), j (pass index).
// compare_swap does one element swap combinationally each cycle swap_en is high.
module bubble_sort_integration (
    input         clk, rst, start,
    input  [63:0] data_in_flat,
    output [63:0] data_out_flat,
    output        done
);
    reg [7:0] arr [0:7];

    wire [1:0] state;
    wire [2:0] i, j;
    wire       swap_en, load_en;

    bubble_sort_fsm u_fsm (
        .clk(clk), .rst(rst), .start(start),
        .state(state), .i(i), .j(j),
        .swap_en(swap_en), .load_en(load_en), .done(done)
    );

    // Compare-swap on arr[i] and arr[i+1]
    wire [7:0] cs_hi, cs_lo;
    compare_swap u_cs (
        .a(arr[i]), .b(arr[i+1]),
        .hi(cs_hi), .lo(cs_lo)
    );

    integer k;
    always @(posedge clk) begin
        if (rst) begin
            for (k = 0; k < 8; k = k+1) arr[k] <= 8'h0;
        end else if (load_en) begin
            for (k = 0; k < 8; k = k+1)
                arr[k] <= data_in_flat[8*k +: 8];
        end else if (swap_en) begin
            arr[i]   <= cs_hi;
            arr[i+1] <= cs_lo;
        end
    end

    genvar gi;
    generate
        for (gi = 0; gi < 8; gi = gi+1) begin : PACK
            assign data_out_flat[8*gi +: 8] = arr[gi];
        end
    endgenerate
endmodule
"""

# ─────────────────────────────────────────────────────────────────────────────
# Writer
# ─────────────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Write 14 integration top .v files — no LLM needed.")
    parser.add_argument(
        "--output_dir", default="./verigen_outputs",
        help="Root directory that already contains m01_alu/, m02_regfile/, etc.")
    args = parser.parse_args()

    written = 0
    for rel_path, verilog in FILES.items():
        full_path = os.path.join(args.output_dir, rel_path)
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        with open(full_path, "w") as f:
            f.write(verilog.lstrip("\n"))
        lines = verilog.count("\n")
        print(f"  wrote  {full_path}  ({lines} lines)")
        written += 1

    print(f"\n[DONE] {written}/14 integration files written to {args.output_dir}")

if __name__ == "__main__":
    main()


