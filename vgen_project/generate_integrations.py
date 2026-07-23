#!/usr/bin/env python3
"""
VeriGen Integration Top-Module Generator
========================================
Generates 14 *_top_integration.v files — one per benchmark module —
each of which instantiates the already-generated submodules.
"""

import os
import re
import argparse
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM

# ──────────────────────────────────────────────────────────────────────────────
# 14 INTEGRATION PROMPTS
# ──────────────────────────────────────────────────────────────────────────────

PROMPTS = {

# ── M01: N-bit ALU ────────────────────────────────────────────────────────────
"m01_alu/alu_top_integration": """\
// N-bit ALU integration top. op[2:0]: 000=ADD,001=SUB,010=AND,011=OR,100=XOR,101=SHL.
// Instantiate alu_addsub #(N)(a,b,op[0],add_res,add_c),
//             alu_logic   #(N)(a,b,op[1:0],log_res),
//             alu_shift   #(N)(a,sh_res,sh_c),
//             alu_flags   #(N)(mux_res,c_in,zf,cf).
// Combinational mux selects mux_res by op (add/sub/and/or/xor/shl).
// carry wire = add_c|sh_c depending on op.
// Register result,zero_flag,carry_flag on posedge clk. Synchronous rst.
module alu_integration #(parameter N=8)(
  input              clk, rst,
  input  [N-1:0]     a, b,
  input  [2:0]       op,
  output reg [N-1:0] result,
  output reg         zero_flag, carry_flag
);""",

# ── M02: Register File ────────────────────────────────────────────────────────
"m02_regfile/regfile_top_integration": """\
// Register file integration top. Dual async read, single sync write, x0=0.
// Instantiate regfile_mem(clk,rst,rs1[4:0],rs2[4:0],rd[4:0],
//                         wdata[31:0],we,rdata1[31:0],rdata2[31:0]).
// Pass all top-level ports directly to regfile_mem.
module regfile_integration(
  input         clk, rst,
  input  [4:0]  rs1, rs2, rd,
  input  [31:0] wdata,
  input         we,
  output [31:0] rdata1, rdata2
);""",

# ── M03: UART TX ──────────────────────────────────────────────────────────────
"m03_uart/uart_tx_top_integration": """\
// UART TX integration top (8-N-1). Parametric CLK_FREQ, BAUD_RATE.
// Instantiate baud_gen     #(CLK_FREQ,BAUD_RATE)(clk,rst,tick),
//             uart_tx_fsm  (clk,rst,tick,tx_start,load,shift_en,tx_out,busy_w),
//             uart_tx_shift(clk,rst,load,shift_en,tx_data[7:0],serial_out,empty).
// Connect: tick->fsm. Assign tx=tx_out, busy=busy_w.
module uart_tx_integration #(
  parameter CLK_FREQ  = 50000000,
  parameter BAUD_RATE = 115200
)(
  input        clk, rst, tx_start,
  input  [7:0] tx_data,
  output       tx, busy
);""",

# ── M04: Multi-Cycle CPU ──────────────────────────────────────────────────────
"m04_cpu/cpu_top_integration": """\
// Multi-cycle Harvard RISC CPU integration top.
// Instantiate cpu_control (clk,rst,opcode[6:0],funct3[2:0],zero,
//                          pc_write,ir_write,reg_write,mem_write,
//                          alu_src_a,alu_src_b,mem_to_reg,pc_source,alu_op[1:0])
//         and cpu_datapath(clk,rst,
//                          pc_write,ir_write,reg_write,mem_write,
//                          alu_src_a,alu_src_b,mem_to_reg,pc_source,alu_op[1:0],
//                          opcode[6:0],funct3[2:0],zero).
// Wire every control signal from cpu_control to cpu_datapath.
// Wire status signals (opcode,funct3,zero) from datapath to control.
module multicycle_cpu_integration(input clk, rst);""",

# ── M05: Hardwired Control ────────────────────────────────────────────────────
"m05_ctrl/ctrl_top_integration": """\
// Hardwired control integration top. All 5 phases covered.
// Instantiate ctrl_phase01 (opcode[6:0],phase[2:0],
//                           p01_pcw,p01_irw,p01_rgw,p01_mew,
//                           p01_sa,p01_sb,p01_m2r,p01_pcs)
//         and ctrl_phase234(opcode[6:0],phase[2:0],
//                           p234_pcw,p234_irw,p234_rgw,p234_mew,
//                           p234_sa,p234_sb,p234_m2r,p234_pcs).
// Merge: output = p01 signals when phase<=1, else p234 signals.
module hardwired_ctrl_integration(
  input  [6:0] opcode,
  input  [2:0] phase,
  output       pc_write, ir_write, reg_write, mem_write,
  output       alu_src_a, alu_src_b, mem_to_reg, pc_source
);""",

# ── M06: 5-Stage RISC-V Pipeline ─────────────────────────────────────────────
"m06_riscv/rv_top_integration": """\
// 5-stage RISC-V pipeline integration top.
// Submodule ports:
//   rv_if_stage (clk,rst,stall,pc_src,branch_target[31:0],pc[31:0],pc_plus4[31:0])
//   rv_id_stage (clk,rst,instr[31:0],wb_rd[4:0],wb_data[31:0],wb_we,
//                rs1_data[31:0],rs2_data[31:0],imm_ext[31:0],
//                rs1[4:0],rs2[4:0],rd[4:0],opcode[6:0],funct7[6:0],funct3[2:0])
//   rv_ex_stage (rs1_data,rs2_data,imm_ext,pc,fwd_ex_mem[31:0],fwd_mem_wb[31:0],
//                forward_a[1:0],forward_b[1:0],alu_src,alu_op[1:0],
//                alu_result[31:0],branch_target[31:0],zero)
//   rv_mem_stage(clk,alu_result,rs2_data,mem_write,mem_read,read_data[31:0])
//   rv_hazard   (id_ex_mem_read,id_ex_rd[4:0],if_id_rs1[4:0],if_id_rs2[4:0],stall,flush)
//   rv_forward  (id_ex_rs1[4:0],id_ex_rs2[4:0],ex_mem_rd[4:0],mem_wb_rd[4:0],
//                ex_mem_reg_write,mem_wb_reg_write,forward_a[1:0],forward_b[1:0])
// Add IF/ID, ID/EX, EX/MEM, MEM/WB pipeline registers.
// Derive alu_src, alu_op[1:0], mem_write, mem_read, reg_write from opcode in EX stage.
module riscv_pipeline_integration(input clk, rst);""",

# ── M07: Direct-Mapped Cache ──────────────────────────────────────────────────
"m07_cache/cache_top_integration": """\
// Direct-mapped write-through cache integration top. 16 sets, 4-byte lines.
// Address decode: tag=addr[31:6](24b), index=addr[5:2](4b), offset=addr[1:0](2b).
// Instantiate cache_arrays  (clk,rst,index[3:0],tag_in[23:0],data_in[31:0],
//                            we_tag,we_data,tag_out[23:0],data_out[31:0],valid_out)
//             cache_hit_logic(req_tag[23:0],tag_out,byte_offset[1:0],
//                             valid_out,data_out,hit,read_byte[7:0])
//             cache_ctrl     (clk,rst,cpu_req,mem_ack,hit,cpu_we,
//                             we_tag,we_data,mem_req,mem_we,stall).
// mem_ack = mem_req (single-cycle memory model). cpu_rdata = {4{read_byte}}.
module cache_integration(
  input         clk, rst, cpu_req, cpu_we,
  input  [31:0] cpu_addr, cpu_wdata,
  output [31:0] cpu_rdata,
  output        stall,
  output [31:0] mem_addr,
  input  [31:0] mem_rdata,
  output        mem_req
);""",

# ── M08: Round-Robin Arbiter ──────────────────────────────────────────────────
"m08_arbiter/rr_top_integration": """\
// Round-robin arbiter integration top. N requestors, one-hot grant, no starvation.
// Instantiate rr_grant_logic #(N)(req[N-1:0],ptr[N-1:0],grant_comb[N-1:0])
//         and rr_ptr         #(N)(clk,rst,grant[N-1:0],ptr[N-1:0]).
// Register grant_comb to grant on posedge clk (synchronous reset to 0).
module round_robin_arbiter_integration #(parameter N=4)(
  input          clk, rst,
  input  [N-1:0] req,
  output reg [N-1:0] grant
);""",

# ── M09: AES-128 ──────────────────────────────────────────────────────────────
"m09_aes/aes_top_integration": """\
// AES-128 encryption integration top. 10-round FSM.
// States: IDLE=0, INIT=1, ROUND=2, FINAL=3, DONE=4. round counter 0..9.
// Instantiate aes_keyschedule(key[127:0], round_keys[1407:0])
//             aes_addroundkey (state,rk[127:0],ark_out[127:0])
//             aes_subbytes    (state,sb_out[127:0])
//             aes_shiftrows   (state,sr_out[127:0])
//             aes_mixcolumns  (state,mc_out[127:0])
// INIT  : state = plaintext XOR round_keys[127:0].
// ROUND 1-9: state = addroundkey(mixcols(shiftrows(subbytes(state))),
//                                round_keys[128*r+127:128*r]).
// FINAL : state = addroundkey(shiftrows(subbytes(state)), round_keys[1279:1152]).
// DONE  : ciphertext = state, done = 1.
module aes128_integration(
  input          clk, rst, start,
  input  [127:0] plaintext, key,
  output reg [127:0] ciphertext,
  output reg         done
);""",

# ── M10: SHA-256 ──────────────────────────────────────────────────────────────
"m10_sha256/sha256_top_integration": """\
// SHA-256 integration top. Single 512-bit block.
// FSM: IDLE=0, SCHEDULE=1, COMPRESS=2, DONE=3.
// Instantiate sha256_msg_sched(block_in[511:0], W[2047:0])
//         and sha256_compress  (H_in[255:0], W[2047:0], H_out[255:0]).
// Initial hash values H[0..7]:
//   6a09e667 bb67ae85 3c6ef372 a54ff53a 510e527f 9b05688c 1f83d9ab 5be0cd19
// hash_out = H_out. done asserts one cycle after COMPRESS completes.
module sha256_integration(
  input          clk, rst, start,
  input  [511:0] block_in,
  output reg [255:0] hash_out,
  output reg         done
);""",

# ── M11: CRC-32 ───────────────────────────────────────────────────────────────
"m11_crc32/crc32_top_integration": """\
// CRC-32 IEEE 802.3 integration top. Bit-serial, reflected poly 0xEDB88320.
// Instantiate crc32_lfsr(clk,rst,init,data_in,valid,crc_reg[31:0])
//         and crc32_ctrl(clk,rst,start,done_in,crc_reg[31:0],init,crc_out[31:0]).
// done_in: assert when valid goes low after data stream ends (use falling-edge detect).
// ready = done_in registered one cycle.
module crc32_integration(
  input         clk, rst, start, data_in, valid,
  output [31:0] crc_out,
  output        ready
);""",

# ── M12: 8-Point FFT ─────────────────────────────────────────────────────────
"m12_fft/fft_top_integration": """\
// 8-point fixed-point FFT integration top. Cooley-Tukey DIT, Q1.15.
// Instantiate fft_stage1 (xre_flat[127:0], xim_flat[127:0],
//                         s1re_flat[127:0], s1im_flat[127:0])
//         and fft_stage23(s1re_flat[127:0], s1im_flat[127:0],
//                         s3re_flat[127:0], s3im_flat[127:0]).
// Wire stage1 outputs directly to stage23 inputs.
// Assign Xre_flat=s3re_flat, Xim_flat=s3im_flat. Output bit-reversed order.
module fft8_integration(
  input  signed [127:0] xre_flat, xim_flat,
  output signed [127:0] Xre_flat, Xim_flat
);""",

# ── M13: 16×16 Matrix Multiplier ─────────────────────────────────────────────
"m13_matmul/mat_top_integration": """\
// 16x16 matrix multiply integration top. 16-bit unsigned inputs, 32-bit output C=AxB.
// Instantiate 16 mat_row instances (one per row of A).
// mat_row ports: clk,rst,start,row_a_flat[255:0],col_b_flat[255:0],result[31:0],done.
// Sequence columns 0..15 for each row instance using a 4-bit col_counter.
// C_flat[32*(16*row+col)+31 : 32*(16*row+col)] = result of row x col dot product.
// Global done asserts when all 16 row instances have finished all 16 columns.
module matrix_mult_integration(
  input          clk, rst, start,
  input  [4095:0] A_flat, B_flat,
  output reg [8191:0] C_flat,
  output             done
);""",

# ── M14: Hardware Bubble Sort ─────────────────────────────────────────────────
"m14_sort/bubble_sort_top_integration": """\
// Hardware bubble sort integration top. 8 elements, 8-bit unsigned.
// Instantiate bubble_sort_fsm(clk,rst,start,state[1:0],i[2:0],j[2:0],
//                             swap_en,load_en,done)
//         and compare_swap   (a[7:0],b[7:0],hi[7:0],lo[7:0]).
// 8-element reg array. On load_en: load data_in_flat[8*k+7:8*k] into arr[k].
// On swap_en: feed arr[i],arr[i+1] to compare_swap; write hi->arr[i],lo->arr[i+1].
// data_out_flat[8*k+7:8*k] = arr[k]. done from FSM.
module bubble_sort_integration(
  input        clk, rst, start,
  input  [63:0] data_in_flat,
  output [63:0] data_out_flat,
  output        done
);"""

}  # end PROMPTS dict


# ──────────────────────────────────────────────────────────────────────────────
# GENERATION ENGINE
# ──────────────────────────────────────────────────────────────────────────────

def load_model(model_path: str):
    print(f"[INFO] Loading tokenizer from {model_path}")
    tok = AutoTokenizer.from_pretrained(model_path, trust_remote_code=True)
    print(f"[INFO] Loading model from {model_path}")
    model = AutoModelForCausalLM.from_pretrained(
        model_path,
        torch_dtype=torch.float16,
        device_map="auto",
        trust_remote_code=True,
    )
    model.eval()
    print(f"[INFO] Model loaded.")
    return tok, model


def generate_verilog(tok, model, prompt: str, max_new_tokens: int = 1200) -> str:
    """Generate Verilog given a prompt. Returns only the generated text."""
    inputs = tok(prompt, return_tensors="pt").to(model.device)
    input_len = inputs["input_ids"].shape[1]

    if input_len > 800:
        print(f"  [WARN] Prompt is {input_len} tokens — may crowd output budget.")

    with torch.no_grad():
        output = model.generate(
            **inputs,
            max_new_tokens=max_new_tokens,
            do_sample=False,          # greedy — deterministic, best for code
            temperature=1.0,
            pad_token_id=tok.eos_token_id,
            eos_token_id=tok.eos_token_id,
        )

    # Decode only the newly generated tokens (strip the prompt)
    generated_ids = output[0][input_len:]
    return tok.decode(generated_ids, skip_special_tokens=True)


def clean_output(prompt: str, raw: str) -> str:
    """
    Combine prompt + generated text and ensure the file ends at
    the first 'endmodule' token so we don't capture garbage.
    """
    combined = prompt + "\n" + raw
    # Trim everything after the first endmodule
    match = re.search(r"endmodule", combined)
    if match:
        combined = combined[: match.end()]
    return combined.strip() + "\n"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model_path", required=True,
                        help="Path to VeriGen model directory on HPC")
    parser.add_argument("--output_dir", default="./verigen_outputs",
                        help="Root output directory (same structure as existing submodules)")
    parser.add_argument("--max_new_tokens", type=int, default=1200)
    parser.add_argument("--only", nargs="*", default=None,
                        help="Run only specific keys, e.g. m01_alu/alu_top_integration")
    args = parser.parse_args()

    tok, model = load_model(args.model_path)

    keys = args.only if args.only else list(PROMPTS.keys())

    for key in keys:
        if key not in PROMPTS:
            print(f"[SKIP] Unknown key: {key}")
            continue

        prompt = PROMPTS[key]
        out_path = os.path.join(args.output_dir, key + ".v")
        os.makedirs(os.path.dirname(out_path), exist_ok=True)

        print(f"\n[GEN] {key}")
        raw = generate_verilog(tok, model, prompt, args.max_new_tokens)
        final = clean_output(prompt, raw)

        with open(out_path, "w") as f:
            f.write(final)

        lines = final.count("\n")
        print(f"  → Saved {lines} lines to {out_path}")

    print("\n[DONE] All integration modules generated.")


if __name__ == "__main__":
    main()
