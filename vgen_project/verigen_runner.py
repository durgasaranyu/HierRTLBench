#!/usr/bin/env python3
"""
VeriGen HPC Batch Runner
========================
Hierarchically decomposes all 14 benchmark modules into submodules
that comfortably fit within the VeriGen 2048-token hard limit.

Strategy
--------
  max_length = 2048 (total: prompt + output)
  Target prompt  < 120 tokens  => ~1920 output token budget
  Each submodule is designed to complete within that budget.

Usage
-----
  # Run all submodules (sequentially)
  python verigen_runner.py --model 2B --output_dir ./outputs

  # Run only ONE submodule (used by SLURM array jobs)
  python verigen_runner.py --model 6B --output_dir ./outputs --idx 7

  # List all submodule keys and their indices
  python verigen_runner.py --list
"""

import os
import sys
import argparse
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM

# ─── Model registry ──────────────────────────────────────────────────────────
MODEL_MAP = {
    "2B":  "shailja/fine-tuned-codegen-2B-Verilog",
    "6B":  "shailja/fine-tuned-codegen-6B-Verilog",
    "16B": "shailja/fine-tuned-codegen-16B-Verilog",   # ← ADD THIS
}
# ─── Generation config ───────────────────────────────────────────────────────
GEN_CFG = {
    "max_length":   2048,   # Hard architectural limit of CodeGen 2B/6B
    "temperature":  0.2,    # Low temp = deterministic, better for RTL
    "top_p":        0.95,
    "do_sample":    True,
}

# ─── Hierarchical submodule prompts ──────────────────────────────────────────
# Each entry: (module_folder, submodule_name, prompt_string)
# Prompts are intentionally < 120 tokens so the model gets ~1920 output tokens.
# Format mirrors the VeriGen training distribution: comment + module header.

SUBMODULES = [

    # ══════════════════════════════════════════════════════════════════════════
    # M01 – Parameterized N-bit ALU
    # Hierarchy: alu_addsub -> alu_logic -> alu_shift -> alu_flags -> alu_top
    # ══════════════════════════════════════════════════════════════════════════
    ("m01_alu", "alu_addsub",
     "// Parameterized N-bit adder-subtractor. op=0: result=a+b carry_out. op=1: result=a-b borrow.\n"
     "module alu_addsub #(parameter N = 8) (\n"
     "    input  [N-1:0] a, b,\n"
     "    input          op,\n"
     "    output [N-1:0] result,\n"
     "    output         carry_out\n"
     ");\n"),

    ("m01_alu", "alu_logic",
     "// N-bit bitwise logic. sel=0 AND, sel=1 OR, sel=2 XOR.\n"
     "module alu_logic #(parameter N = 8) (\n"
     "    input  [N-1:0] a, b,\n"
     "    input  [1:0]   sel,\n"
     "    output [N-1:0] result\n"
     ");\n"),

    ("m01_alu", "alu_shift",
     "// N-bit logical shift-left by 1. carry_out = a[N-1], result = a << 1.\n"
     "module alu_shift #(parameter N = 8) (\n"
     "    input  [N-1:0] a,\n"
     "    output [N-1:0] result,\n"
     "    output         carry_out\n"
     ");\n"),

    ("m01_alu", "alu_flags",
     "// Zero and carry flag generator. zero=1 when result==0.\n"
     "module alu_flags #(parameter N = 8) (\n"
     "    input  [N-1:0] result,\n"
     "    input          carry_in,\n"
     "    output         zero_flag,\n"
     "    output         carry_flag\n"
     ");\n"),

    ("m01_alu", "alu_top",
     "// N-bit ALU. op: 3'b000=ADD, 001=SUB, 010=AND, 011=OR, 100=XOR, 101=SHL.\n"
     "// Synchronous reset. Registered outputs: result, zero_flag, carry_flag.\n"
     "module alu #(parameter N = 8) (\n"
     "    input              clk, rst,\n"
     "    input  [N-1:0]     a, b,\n"
     "    input  [2:0]       op,\n"
     "    output reg [N-1:0] result,\n"
     "    output reg         zero_flag,\n"
     "    output reg         carry_flag\n"
     ");\n"),

    # ══════════════════════════════════════════════════════════════════════════
    # M02 – 32-entry Register File
    # Hierarchy: regfile_mem -> regfile_top
    # ══════════════════════════════════════════════════════════════════════════
    ("m02_regfile", "regfile_mem",
     "// 32x32 register array. Synchronous reset zeroes all registers. x0 always reads 0.\n"
     "module regfile_mem (\n"
     "    input         clk, rst,\n"
     "    input  [4:0]  rs1, rs2, rd,\n"
     "    input  [31:0] wdata,\n"
     "    input         we,\n"
     "    output [31:0] rdata1, rdata2\n"
     ");\n"
     "    reg [31:0] regs [0:31];\n"),

    ("m02_regfile", "regfile_top",
     "// 32-entry register file. Dual async read ports, single sync write. x0 hardwired 0.\n"
     "module regfile (\n"
     "    input         clk, rst,\n"
     "    input  [4:0]  rs1, rs2, rd,\n"
     "    input  [31:0] wdata,\n"
     "    input         we,\n"
     "    output [31:0] rdata1, rdata2\n"
     ");\n"),

    # ══════════════════════════════════════════════════════════════════════════
    # M03 – UART Transmitter (8-N-1)
    # Hierarchy: baud_gen -> uart_tx_shift -> uart_tx_fsm -> uart_tx_top
    # ══════════════════════════════════════════════════════════════════════════
    ("m03_uart", "baud_gen",
     "// Baud rate clock divider. Outputs single-cycle tick every CLK_FREQ/BAUD_RATE clocks.\n"
     "module baud_gen #(parameter CLK_FREQ=50000000, parameter BAUD_RATE=115200) (\n"
     "    input  clk, rst,\n"
     "    output tick\n"
     ");\n"),

    ("m03_uart", "uart_tx_shift",
     "// 8-bit UART shift register. Loads byte on load. Shifts LSB first on shift_en.\n"
     "module uart_tx_shift (\n"
     "    input        clk, rst,\n"
     "    input        load, shift_en,\n"
     "    input  [7:0] data,\n"
     "    output       serial_out,\n"
     "    output       empty\n"
     ");\n"),

    ("m03_uart", "uart_tx_fsm",
     "// UART TX FSM. States: IDLE->START->DATA(8 bits)->STOP->IDLE. Driven by baud tick.\n"
     "module uart_tx_fsm (\n"
     "    input      clk, rst, tick, tx_start,\n"
     "    output reg load, shift_en, tx_out, busy\n"
     ");\n"),

    ("m03_uart", "uart_tx_top",
     "// UART transmitter top (8-N-1). Parametric CLK_FREQ/BAUD_RATE. tx_start pulses send.\n"
     "module uart_tx #(parameter CLK_FREQ=50000000, parameter BAUD_RATE=115200) (\n"
     "    input       clk, rst, tx_start,\n"
     "    input [7:0] tx_data,\n"
     "    output      tx, busy\n"
     ");\n"),

    # ══════════════════════════════════════════════════════════════════════════
    # M04 – Multi-Cycle RISC CPU
    # Hierarchy: cpu_alu -> cpu_imem -> cpu_dmem -> cpu_regfile ->
    #            cpu_control -> cpu_datapath -> cpu_top
    # ══════════════════════════════════════════════════════════════════════════
    ("m04_cpu", "cpu_alu",
     "// 32-bit ALU. op: 0=ADD, 1=SUB, 2=AND, 3=OR. Combinational result and zero flag.\n"
     "module cpu_alu (\n"
     "    input  [31:0] a, b,\n"
     "    input  [1:0]  op,\n"
     "    output [31:0] result,\n"
     "    output        zero\n"
     ");\n"),

    ("m04_cpu", "cpu_imem",
     "// Instruction memory: 256x32-bit words, initialized to 0. Async read by addr[9:2].\n"
     "module cpu_imem (\n"
     "    input  [31:0] addr,\n"
     "    output [31:0] instr\n"
     ");\n"
     "    reg [31:0] mem [0:255];\n"),

    ("m04_cpu", "cpu_dmem",
     "// Data memory: 256x32-bit words. Synchronous write on mem_we. Asynchronous read.\n"
     "module cpu_dmem (\n"
     "    input        clk,\n"
     "    input [31:0] addr, wdata,\n"
     "    input        mem_we,\n"
     "    output [31:0] rdata\n"
     ");\n"),

    ("m04_cpu", "cpu_regfile",
     "// RISC CPU register file. 32x32-bit. Async read rs1,rs2. Sync write on we. x0=0.\n"
     "module cpu_regfile (\n"
     "    input        clk,\n"
     "    input [4:0]  rs1, rs2, rd,\n"
     "    input [31:0] wdata,\n"
     "    input        we,\n"
     "    output [31:0] rdata1, rdata2\n"
     ");\n"),

    ("m04_cpu", "cpu_control",
     "// Multi-cycle RISC control FSM. States IF=0,ID=1,EX=2,MEM=3,WB=4.\n"
     "// Opcodes: ADD/SUB=7'h33, ADDI=7'h13, LW=7'h03, SW=7'h23, BEQ=7'h63.\n"
     "module cpu_control (\n"
     "    input       clk, rst,\n"
     "    input [6:0] opcode,\n"
     "    input [2:0] funct3,\n"
     "    input       zero,\n"
     "    output reg  pc_write, ir_write, reg_write, mem_write,\n"
     "    output reg  alu_src_a, alu_src_b, mem_to_reg, pc_source,\n"
     "    output reg [1:0] alu_op\n"
     ");\n"),

    ("m04_cpu", "cpu_datapath",
     "// Multi-cycle RISC datapath. PC, IR, A/B regs, ALUout, MDR. Connects all datapath units.\n"
     "module cpu_datapath (\n"
     "    input         clk, rst,\n"
     "    input         pc_write, ir_write, reg_write, mem_write,\n"
     "    input         alu_src_a, alu_src_b, mem_to_reg, pc_source,\n"
     "    input  [1:0]  alu_op,\n"
     "    output [6:0]  opcode,\n"
     "    output [2:0]  funct3,\n"
     "    output        zero\n"
     ");\n"),

    ("m04_cpu", "cpu_top",
     "// Multi-cycle Harvard RISC CPU. 5-phase FSM (IF/ID/EX/MEM/WB). ADD/SUB/AND/OR/ADDI/LW/SW/BEQ.\n"
     "module multicycle_cpu (\n"
     "    input clk, rst\n"
     ");\n"),

    # ══════════════════════════════════════════════════════════════════════════
    # M05 – Hardwired Control Unit
    # Hierarchy: ctrl_phase01 -> ctrl_phase234 -> ctrl_top
    # ══════════════════════════════════════════════════════════════════════════
    ("m05_ctrl", "ctrl_phase01",
     "// Hardwired control unit: phases 0 (IF) and 1 (ID). 7-bit opcode + 3-bit phase input.\n"
     "// Combinational outputs: pc_write, ir_write, reg_write, mem_write, alu_src_a/b, mem_to_reg, pc_source.\n"
     "module ctrl_phase01 (\n"
     "    input  [6:0] opcode,\n"
     "    input  [2:0] phase,\n"
     "    output reg   pc_write, ir_write, reg_write, mem_write,\n"
     "    output reg   alu_src_a, alu_src_b, mem_to_reg, pc_source\n"
     ");\n"),

    ("m05_ctrl", "ctrl_phase234",
     "// Hardwired control unit: phases 2 (EX), 3 (MEM), 4 (WB). 7-bit opcode + 3-bit phase input.\n"
     "// Combinational outputs: pc_write, ir_write, reg_write, mem_write, alu_src_a/b, mem_to_reg, pc_source.\n"
     "module ctrl_phase234 (\n"
     "    input  [6:0] opcode,\n"
     "    input  [2:0] phase,\n"
     "    output reg   pc_write, ir_write, reg_write, mem_write,\n"
     "    output reg   alu_src_a, alu_src_b, mem_to_reg, pc_source\n"
     ");\n"),

    ("m05_ctrl", "ctrl_top",
     "// Hardwired control unit top: 7-bit opcode, 3-bit phase. All 5 phases covered.\n"
     "// Instantiates phase01 and phase234, merges outputs.\n"
     "module hardwired_ctrl (\n"
     "    input  [6:0] opcode,\n"
     "    input  [2:0] phase,\n"
     "    output       pc_write, ir_write, reg_write, mem_write,\n"
     "    output       alu_src_a, alu_src_b, mem_to_reg, pc_source\n"
     ");\n"),

    # ══════════════════════════════════════════════════════════════════════════
    # M06 – 5-Stage Pipelined RISC-V CPU
    # Hierarchy: rv_hazard -> rv_forward -> rv_if_stage -> rv_id_stage ->
    #            rv_ex_stage -> rv_mem_stage -> rv_wb_stage -> rv_top
    # ══════════════════════════════════════════════════════════════════════════
    ("m06_riscv", "rv_hazard",
     "// RISC-V hazard detection. Load-use hazard: stall pipeline when id_ex_mem_read and rs match.\n"
     "module rv_hazard (\n"
     "    input      id_ex_mem_read,\n"
     "    input [4:0] id_ex_rd, if_id_rs1, if_id_rs2,\n"
     "    output reg stall, flush\n"
     ");\n"),

    ("m06_riscv", "rv_forward",
     "// RISC-V forwarding unit. forward_a/b: 00=regfile, 01=MEM/WB, 10=EX/MEM.\n"
     "module rv_forward (\n"
     "    input [4:0] id_ex_rs1, id_ex_rs2,\n"
     "    input [4:0] ex_mem_rd, mem_wb_rd,\n"
     "    input       ex_mem_reg_write, mem_wb_reg_write,\n"
     "    output reg [1:0] forward_a, forward_b\n"
     ");\n"),

    ("m06_riscv", "rv_if_stage",
     "// RISC-V IF stage. PC register with stall and branch mux. Outputs PC+4 and next PC.\n"
     "module rv_if_stage (\n"
     "    input        clk, rst, stall, pc_src,\n"
     "    input [31:0] branch_target,\n"
     "    output reg [31:0] pc,\n"
     "    output [31:0] pc_plus4\n"
     ");\n"),

    ("m06_riscv", "rv_id_stage",
     "// RISC-V ID stage. Decodes instruction, reads regfile rs1/rs2, sign-extends immediate.\n"
     "module rv_id_stage (\n"
     "    input        clk, rst,\n"
     "    input [31:0] instr,\n"
     "    input [4:0]  wb_rd,\n"
     "    input [31:0] wb_data,\n"
     "    input        wb_we,\n"
     "    output [31:0] rs1_data, rs2_data, imm_ext,\n"
     "    output [4:0]  rs1, rs2, rd,\n"
     "    output [6:0]  opcode, funct7,\n"
     "    output [2:0]  funct3\n"
     ");\n"),

    ("m06_riscv", "rv_ex_stage",
     "// RISC-V EX stage. ALU with forwarding muxes. Computes branch target = pc + imm.\n"
     "// alu_op: 00=ADD, 01=SUB, 10=AND, 11=OR.\n"
     "module rv_ex_stage (\n"
     "    input [31:0] rs1_data, rs2_data, imm_ext, pc,\n"
     "    input [31:0] fwd_ex_mem, fwd_mem_wb,\n"
     "    input [1:0]  forward_a, forward_b,\n"
     "    input        alu_src,\n"
     "    input [1:0]  alu_op,\n"
     "    output [31:0] alu_result, branch_target,\n"
     "    output        zero\n"
     ");\n"),

    ("m06_riscv", "rv_mem_stage",
     "// RISC-V MEM stage. 256x32 data memory. Sync write on mem_write. Async read.\n"
     "module rv_mem_stage (\n"
     "    input        clk,\n"
     "    input [31:0] alu_result, rs2_data,\n"
     "    input        mem_write, mem_read,\n"
     "    output [31:0] read_data\n"
     ");\n"),

    ("m06_riscv", "rv_top",
     "// 5-stage pipelined RISC-V CPU top. Hazard detection, forwarding unit.\n"
     "// Supports: ADD/SUB/AND/OR/ADDI/LW/SW/BEQ.\n"
     "module riscv_pipeline (\n"
     "    input clk, rst\n"
     ");\n"),

    # ══════════════════════════════════════════════════════════════════════════
    # M07 – Direct-Mapped Cache (16-set)
    # Hierarchy: cache_arrays -> cache_hit_logic -> cache_ctrl -> cache_top
    # ══════════════════════════════════════════════════════════════════════════
    ("m07_cache", "cache_arrays",
     "// Cache storage: 16-entry tag array, 16x32-bit data array, 16 valid bits.\n"
     "// Synchronous reset clears valid bits. Synchronous indexed write.\n"
     "module cache_arrays (\n"
     "    input         clk, rst,\n"
     "    input  [3:0]  index,\n"
     "    input  [23:0] tag_in,\n"
     "    input  [31:0] data_in,\n"
     "    input         we_tag, we_data,\n"
     "    output [23:0] tag_out,\n"
     "    output [31:0] data_out,\n"
     "    output        valid_out\n"
     ");\n"),

    ("m07_cache", "cache_hit_logic",
     "// Cache hit detection. Compares req_tag vs stored_tag when valid. Selects byte by offset.\n"
     "module cache_hit_logic (\n"
     "    input  [23:0] req_tag, stored_tag,\n"
     "    input  [1:0]  byte_offset,\n"
     "    input         valid,\n"
     "    input  [31:0] data,\n"
     "    output        hit,\n"
     "    output [7:0]  read_byte\n"
     ");\n"),

    ("m07_cache", "cache_ctrl",
     "// Write-through cache controller FSM. States: IDLE, COMPARE, MEM_FETCH, WRITE_BACK.\n"
     "// Address: tag[31:6], index[5:2], offset[1:0].\n"
     "module cache_ctrl (\n"
     "    input        clk, rst, cpu_req, mem_ack, hit, cpu_we,\n"
     "    output reg   we_tag, we_data, mem_req, mem_we, stall\n"
     ");\n"),

    ("m07_cache", "cache_top",
     "// Direct-mapped write-through cache: 16 sets, 4-byte lines. 32-bit address.\n"
     "// tag[31:6]=24b, index[5:2]=4b, offset[1:0]=2b. Valid array reset on rst.\n"
     "module cache (\n"
     "    input         clk, rst, cpu_req, cpu_we,\n"
     "    input  [31:0] cpu_addr, cpu_wdata,\n"
     "    output [31:0] cpu_rdata,\n"
     "    output        stall,\n"
     "    output [31:0] mem_addr,\n"
     "    input  [31:0] mem_rdata,\n"
     "    output        mem_req\n"
     ");\n"),

    # ══════════════════════════════════════════════════════════════════════════
    # M08 – Round-Robin Arbiter
    # Hierarchy: rr_ptr -> rr_grant_logic -> rr_top
    # ══════════════════════════════════════════════════════════════════════════
    ("m08_arbiter", "rr_ptr",
     "// Round-robin priority pointer register. Updates to position after last grant on each cycle.\n"
     "module rr_ptr #(parameter N = 4) (\n"
     "    input            clk, rst,\n"
     "    input  [N-1:0]   grant,\n"
     "    output reg [N-1:0] ptr\n"
     ");\n"),

    ("m08_arbiter", "rr_grant_logic",
     "// Round-robin grant logic. One-hot grant starting from ptr position. No starvation.\n"
     "// Uses double-width mask trick to avoid priority inversion.\n"
     "module rr_grant_logic #(parameter N = 4) (\n"
     "    input  [N-1:0] req, ptr,\n"
     "    output [N-1:0] grant\n"
     ");\n"),

    ("m08_arbiter", "rr_top",
     "// Round-robin arbiter top: N requestors, registered one-hot grant, no starvation.\n"
     "module round_robin_arbiter #(parameter N = 4) (\n"
     "    input          clk, rst,\n"
     "    input  [N-1:0] req,\n"
     "    output [N-1:0] grant\n"
     ");\n"),

    # ══════════════════════════════════════════════════════════════════════════
    # M09 – AES-128 Encryption Core
    # Hierarchy: aes_sbox_lo -> aes_sbox_hi -> aes_sbox -> aes_subbytes ->
    #            aes_shiftrows -> aes_gf_mul -> aes_mixcolumns ->
    #            aes_addroundkey -> aes_keyschedule -> aes_top
    # Note: S-box split into lo/hi halves to stay within token budget
    # ══════════════════════════════════════════════════════════════════════════
    ("m09_aes", "aes_sbox_lo",
     "// AES S-box lower half: entries 0x00 to 0x7F. Standard FIPS-197 substitution values.\n"
     "module aes_sbox_lo (\n"
     "    input  [7:0] in,\n"
     "    output reg [7:0] out\n"
     ");\n"
     "    always @(*) case (in)\n"
     "        8'h00: out = 8'h63; 8'h01: out = 8'h7c; 8'h02: out = 8'h77; 8'h03: out = 8'h7b;\n"),

    ("m09_aes", "aes_sbox_hi",
     "// AES S-box upper half: entries 0x80 to 0xFF. Standard FIPS-197 substitution values.\n"
     "module aes_sbox_hi (\n"
     "    input  [7:0] in,\n"
     "    output reg [7:0] out\n"
     ");\n"
     "    always @(*) case (in)\n"
     "        8'h80: out = 8'hcd; 8'h81: out = 8'h0c; 8'h82: out = 8'h13; 8'h83: out = 8'hec;\n"),

    ("m09_aes", "aes_sbox",
     "// AES full S-box: routes to lo (in[7]==0) or hi (in[7]==1) sub-LUT.\n"
     "module aes_sbox (\n"
     "    input  [7:0] in,\n"
     "    output [7:0] out\n"
     ");\n"),

    ("m09_aes", "aes_subbytes",
     "// AES SubBytes: applies S-box to each of 16 bytes in 128-bit state.\n"
     "module aes_subbytes (\n"
     "    input  [127:0] state_in,\n"
     "    output [127:0] state_out\n"
     ");\n"),

    ("m09_aes", "aes_shiftrows",
     "// AES ShiftRows: row0 no-shift, row1 left-1, row2 left-2, row3 left-3.\n"
     "// State is column-major: byte[127:120]=col0/row0 ... byte[7:0]=col3/row3.\n"
     "module aes_shiftrows (\n"
     "    input  [127:0] state_in,\n"
     "    output [127:0] state_out\n"
     ");\n"),

    ("m09_aes", "aes_gf_mul",
     "// GF(2^8) helpers: xtime=a*2 mod x^8+x^4+x^3+x+1. x3_a = xtime(a) XOR a.\n"
     "module aes_gf_mul (\n"
     "    input  [7:0] a,\n"
     "    output [7:0] xtime_a, x3_a\n"
     ");\n"),

    ("m09_aes", "aes_mixcolumns",
     "// AES MixColumns: GF(2^8) matrix multiply on each of 4 columns. Combinational.\n"
     "module aes_mixcolumns (\n"
     "    input  [127:0] state_in,\n"
     "    output [127:0] state_out\n"
     ");\n"),

    ("m09_aes", "aes_addroundkey",
     "// AES AddRoundKey: XOR 128-bit state with 128-bit round key. Purely combinational.\n"
     "module aes_addroundkey (\n"
     "    input  [127:0] state_in, round_key,\n"
     "    output [127:0] state_out\n"
     ");\n"),

    ("m09_aes", "aes_keyschedule",
     "// AES-128 key schedule: expands 128-bit key into 11 round keys (1408-bit output).\n"
     "// Uses SubWord and XOR with Rcon. Combinational.\n"
     "module aes_keyschedule (\n"
     "    input  [127:0] key,\n"
     "    output [1407:0] round_keys\n"
     ");\n"),

    ("m09_aes", "aes_top",
     "// AES-128 encryption core top. 10-round FSM. start pulses encryption.\n"
     "// done asserts when ciphertext is ready.\n"
     "module aes128 (\n"
     "    input         clk, rst, start,\n"
     "    input  [127:0] plaintext, key,\n"
     "    output [127:0] ciphertext,\n"
     "    output         done\n"
     ");\n"),

    # ══════════════════════════════════════════════════════════════════════════
    # M10 – SHA-256 Hash Core
    # Hierarchy: sha256_k_rom -> sha256_sigma -> sha256_msg_sched ->
    #            sha256_compress -> sha256_top
    # ══════════════════════════════════════════════════════════════════════════
    ("m10_sha256", "sha256_k_rom",
     "// SHA-256 K constants ROM: 64 x 32-bit cube-root-derived primes. Combinational.\n"
     "// K[0]=32'h428a2f98, K[1]=32'h71374491, K[2]=32'hb5c0fbcf, K[3]=32'he9b5dba5...\n"
     "module sha256_k_rom (\n"
     "    input  [5:0]  idx,\n"
     "    output reg [31:0] k\n"
     ");\n"
     "    always @(*) case (idx)\n"),

    ("m10_sha256", "sha256_sigma",
     "// SHA-256 Sigma/Ch/Maj functions. All 32-bit. Used in message schedule and compression.\n"
     "// SIGMA0=ROTR2^ROTR13^ROTR22, SIGMA1=ROTR6^ROTR11^ROTR25.\n"
     "// sigma0=ROTR7^ROTR18^SHR3, sigma1=ROTR17^ROTR19^SHR10.\n"
     "module sha256_sigma (\n"
     "    input  [31:0] a, b, c,\n"
     "    output [31:0] SIGMA0_a, SIGMA1_a, sigma0_b, sigma1_b, Ch_abc, Maj_abc\n"
     ");\n"),

    ("m10_sha256", "sha256_msg_sched",
     "// SHA-256 message schedule. W[0..15] from 512-bit block. W[t]=sigma1(W[t-2])+W[t-7]+sigma0(W[t-15])+W[t-16].\n"
     "// All 32-bit arithmetic. Output: 64 x 32-bit words packed as 2048-bit bus.\n"
     "module sha256_msg_sched (\n"
     "    input  [511:0]  block_in,\n"
     "    output [2047:0] W\n"
     ");\n"),

    ("m10_sha256", "sha256_compress",
     "// SHA-256 64-round compression function. Input: H[0..7] init hash + W[0..63] schedule.\n"
     "// Updates a..h each round. Output: H_out = H_in + {a,b,c,d,e,f,g,h}.\n"
     "module sha256_compress (\n"
     "    input  [255:0]  H_in,\n"
     "    input  [2047:0] W,\n"
     "    output [255:0]  H_out\n"
     ");\n"),

    ("m10_sha256", "sha256_top",
     "// SHA-256 core top. Single 512-bit block. FSM: IDLE->SCHEDULE->COMPRESS->DONE.\n"
     "// Outputs 256-bit hash. start pulses computation. done indicates valid hash_out.\n"
     "module sha256 (\n"
     "    input         clk, rst, start,\n"
     "    input  [511:0] block_in,\n"
     "    output [255:0] hash_out,\n"
     "    output         done\n"
     ");\n"),

    # ══════════════════════════════════════════════════════════════════════════
    # M11 – CRC-32 Engine (IEEE 802.3)
    # Hierarchy: crc32_lfsr -> crc32_ctrl -> crc32_top
    # ══════════════════════════════════════════════════════════════════════════
    ("m11_crc32", "crc32_lfsr",
     "// CRC-32 bit-serial LFSR. Reflected polynomial 0xEDB88320. Updates on valid.\n"
     "// Tap positions: bits 0,1,2,4,5,7,8,10,11,12,16,22,23,26.\n"
     "module crc32_lfsr (\n"
     "    input        clk, rst, init,\n"
     "    input        data_in, valid,\n"
     "    output [31:0] crc_reg\n"
     ");\n"),

    ("m11_crc32", "crc32_ctrl",
     "// CRC-32 controller. Init LFSR to 0xFFFFFFFF on start. Final XOR 0xFFFFFFFF on done.\n"
     "module crc32_ctrl (\n"
     "    input         clk, rst, start, done_in,\n"
     "    input  [31:0] crc_raw,\n"
     "    output reg    init,\n"
     "    output [31:0] crc_out\n"
     ");\n"),

    ("m11_crc32", "crc32_top",
     "// CRC-32 IEEE 802.3 engine. Bit-serial. Reflected poly 0xEDB88320. Init/final XOR 0xFFFFFFFF.\n"
     "module crc32 (\n"
     "    input        clk, rst, start, data_in, valid,\n"
     "    output [31:0] crc_out,\n"
     "    output        ready\n"
     ");\n"),

    # ══════════════════════════════════════════════════════════════════════════
    # M12 – 8-Point Fixed-Point FFT
    # Hierarchy: fft_butterfly -> fft_twiddle_rom -> fft_stage1 ->
    #            fft_stage23 -> fft_top
    # ══════════════════════════════════════════════════════════════════════════
    ("m12_fft", "fft_butterfly",
     "// Single Cooley-Tukey DIT butterfly. Q1.15 complex arithmetic.\n"
     "// out_hi = in_hi + tw*in_lo, out_lo = in_hi - tw*in_lo. Truncates to 16-bit.\n"
     "module fft_butterfly (\n"
     "    input  signed [15:0] re_hi, im_hi, re_lo, im_lo, tw_re, tw_im,\n"
     "    output signed [15:0] out_re_hi, out_im_hi, out_re_lo, out_im_lo\n"
     ");\n"),

    ("m12_fft", "fft_twiddle_rom",
     "// 8-point FFT twiddle factor ROM. 4 entries W8^0..W8^3 in Q1.15.\n"
     "// W8^0=(32767,0), W8^1=(23170,-23170), W8^2=(0,-32767), W8^3=(-23170,-23170).\n"
     "module fft_twiddle_rom (\n"
     "    input  [1:0] idx,\n"
     "    output reg signed [15:0] tw_re, tw_im\n"
     ");\n"),

    ("m12_fft", "fft_stage1",
     "// FFT stage 1: 4 butterflies on pairs (0,4),(1,5),(2,6),(3,7). Twiddle W8^0.\n"
     "// Inputs/outputs are 8 Q1.15 complex samples as flat buses.\n"
     "module fft_stage1 (\n"
     "    input  signed [127:0] xre_flat, xim_flat,\n"
     "    output signed [127:0] s1re_flat, s1im_flat\n"
     ");\n"),

    ("m12_fft", "fft_stage23",
     "// FFT stages 2 and 3 combined. Stage2: pairs (0,2),(1,3),(4,6),(5,7).\n"
     "// Stage3: pairs (0,1),(2,3),(4,5),(6,7) with respective twiddles.\n"
     "module fft_stage23 (\n"
     "    input  signed [127:0] s1re_flat, s1im_flat,\n"
     "    output signed [127:0] s3re_flat, s3im_flat\n"
     ");\n"),

    ("m12_fft", "fft_top",
     "// 8-point fixed-point FFT top. Cooley-Tukey DIT, 3 stages, Q1.15 complex arithmetic.\n"
     "// Output is in bit-reversed order.\n"
     "module fft8 (\n"
     "    input  signed [127:0] xre_flat, xim_flat,\n"
     "    output signed [127:0] Xre_flat, Xim_flat\n"
     ");\n"),

    # ══════════════════════════════════════════════════════════════════════════
    # M13 – 16×16 Matrix Multiplier
    # Hierarchy: mac_unit -> mat_row -> mat_top
    # ══════════════════════════════════════════════════════════════════════════
    ("m13_matmul", "mac_unit",
     "// Multiply-accumulate unit. 16-bit unsigned a,b. 32-bit accumulation.\n"
     "// clear resets acc. en enables accumulation of a*b.\n"
     "module mac_unit (\n"
     "    input         clk, rst, clear, en,\n"
     "    input  [15:0] a, b,\n"
     "    output reg [31:0] acc\n"
     ");\n"),

    ("m13_matmul", "mat_row",
     "// Dot product of a 16-element row vector with a 16-element column vector.\n"
     "// 16-bit unsigned elements. 32-bit accumulator. Takes 16 cycles after start.\n"
     "module mat_row (\n"
     "    input         clk, rst, start,\n"
     "    input  [255:0] row_a_flat,\n"
     "    input  [255:0] col_b_flat,\n"
     "    output [31:0]  result,\n"
     "    output         done\n"
     ");\n"),

    ("m13_matmul", "mat_top",
     "// 16x16 matrix multiplier top. 16-bit unsigned inputs A,B. 32-bit output C=A*B.\n"
     "// Pipelined: computes one row of C per 16 cycles. done when all 16 rows complete.\n"
     "module matrix_mult (\n"
     "    input         clk, rst, start,\n"
     "    input  [4095:0] A_flat, B_flat,\n"
     "    output [8191:0] C_flat,\n"
     "    output          done\n"
     ");\n"),

    # ══════════════════════════════════════════════════════════════════════════
    # M14 – Hardware Bubble Sort
    # Hierarchy: compare_swap -> bubble_sort_fsm -> bubble_sort_top
    # ══════════════════════════════════════════════════════════════════════════
    ("m14_sort", "compare_swap",
     "// Compare-and-swap: outputs larger value to hi port, smaller to lo. Combinational.\n"
     "module compare_swap (\n"
     "    input  [7:0] a, b,\n"
     "    output [7:0] hi, lo\n"
     ");\n"),

    ("m14_sort", "bubble_sort_fsm",
     "// Bubble sort FSM controller. States: 0=IDLE, 1=LOAD, 2=SORT, 3=DONE.\n"
     "// 8 elements. Outer pass index j (0..6), inner compare index i (0..6-j).\n"
     "module bubble_sort_fsm (\n"
     "    input        clk, rst, start,\n"
     "    output reg [1:0] state,\n"
     "    output reg [2:0] i, j,\n"
     "    output reg       swap_en, load_en, done\n"
     ");\n"),

    ("m14_sort", "bubble_sort_top",
     "// Hardware bubble sort top. 8 elements, 8-bit unsigned. FSM IDLE/LOAD/SORT/DONE.\n"
     "// One compare-swap per clock cycle. done asserts when sorted.\n"
     "module bubble_sort (\n"
     "    input        clk, rst, start,\n"
     "    input  [63:0] data_in_flat,\n"
     "    output [63:0] data_out_flat,\n"
     "    output        done\n"
     ");\n"),
]

# ─── Helpers ─────────────────────────────────────────────────────────────────

def list_submodules():
    print(f"{'IDX':>4}  {'KEY':<40}  {'PROMPT_PREVIEW'}")
    print("-" * 90)
    for idx, (folder, name, prompt) in enumerate(SUBMODULES):
        preview = prompt.split("\n")[0][:55]
        print(f"{idx:>4}  {folder+'/'+name:<40}  {preview}")


def load_model(model_size: str, device: str):
    name = MODEL_MAP[model_size]
    print(f"[INFO] Loading tokenizer from {name}")
    tokenizer = AutoTokenizer.from_pretrained(name)
    print(f"[INFO] Loading model  from {name}")
    dtype = torch.float16 if "cuda" in device else torch.float32
    model = AutoModelForCausalLM.from_pretrained(name, torch_dtype=dtype).to(device)
    model.eval()
    print(f"[INFO] Model ready on {device}")
    return tokenizer, model


def generate_module(prompt: str, tokenizer, model, device: str) -> str:
    input_ids = tokenizer(prompt, return_tensors="pt").input_ids.to(device)
    n_prompt = input_ids.shape[1]
    budget   = 2048 - n_prompt
    print(f"  prompt_tokens={n_prompt}  output_budget={budget}")
    if budget < 200:
        print(f"  [WARN] Prompt too long! Only {budget} tokens left for output.")

    with torch.no_grad():
        sample = model.generate(
            input_ids,
            max_length=2048,
            temperature=GEN_CFG["temperature"],
            top_p=GEN_CFG["top_p"],
            do_sample=GEN_CFG["do_sample"],
            pad_token_id=tokenizer.eos_token_id,
        )

    # Decode and trim at endmodule (VeriGen convention)
    text = tokenizer.decode(
        sample[0],
        skip_special_tokens=True,
        truncate_before_pattern=[r"endmodule"],
    ) + "\nendmodule\n"
    return text


def run_one(idx: int, model_size: str, output_dir: str):
    folder, name, prompt = SUBMODULES[idx]
    device = "cuda" if torch.cuda.is_available() else "cpu"
    tokenizer, model = load_model(model_size, device)

    out_dir  = os.path.join(output_dir, model_size, folder)
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, f"{name}.v")

    if os.path.exists(out_path):
        print(f"[SKIP] {out_path} already exists.")
        return

    print(f"\n[GEN] idx={idx}  {folder}/{name}")
    verilog = generate_module(prompt, tokenizer, model, device)
    with open(out_path, "w") as f:
        f.write(verilog)
    print(f"[SAVED] {out_path}")


def run_all(model_size: str, output_dir: str):
    device = "cuda" if torch.cuda.is_available() else "cpu"
    tokenizer, model = load_model(model_size, device)

    for idx, (folder, name, prompt) in enumerate(SUBMODULES):
        out_dir  = os.path.join(output_dir, model_size, folder)
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, f"{name}.v")

        if os.path.exists(out_path):
            print(f"[SKIP] {out_path}")
            continue

        print(f"\n[GEN {idx:>3}/{len(SUBMODULES)-1}] {folder}/{name}")
        verilog = generate_module(prompt, tokenizer, model, device)
        with open(out_path, "w") as f:
            f.write(verilog)
        print(f"[SAVED] → {out_path}")

    print(f"\n[DONE] All {len(SUBMODULES)} submodules attempted.")


# ─── Entry point ─────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="VeriGen hierarchical batch runner")
    parser.add_argument("--model",      choices=["2B", "6B", "16B"], default="2B",
                        help="Which VeriGen model to use")
    parser.add_argument("--output_dir", default="./verigen_outputs",
                        help="Root output directory")
    parser.add_argument("--idx",        type=int, default=None,
                        help="Run only submodule at this index (for SLURM array jobs)")
    parser.add_argument("--list",       action="store_true",
                        help="Print all submodule indices and exit")
    args = parser.parse_args()

    if args.list:
        list_submodules()
        return

    total = len(SUBMODULES)
    print(f"[INFO] Total submodules: {total}")
    print(f"[INFO] Model: {args.model}  |  Output: {args.output_dir}")

    if args.idx is not None:
        if not (0 <= args.idx < total):
            print(f"[ERROR] --idx must be 0..{total-1}")
            sys.exit(1)
        run_one(args.idx, args.model, args.output_dir)
    else:
        run_all(args.model, args.output_dir)


if __name__ == "__main__":
    main()

