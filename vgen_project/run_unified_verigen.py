#!/usr/bin/env python3
"""
Unified VeriGen HPC Batch Runner
================================
Runs 14 distinct hardware prompts through VeriGen 2B, 6B, and 16B models.
Saves each generated module as a single unified .v file (no subdirectories).

Usage
-----
  # Run all modules for a specific model
  python run_unified_verigen.py --model 2B --output_dir ./unified_outputs

  # Run only ONE module (used by SLURM array jobs)
  python run_unified_verigen.py --model 6B --output_dir ./unified_outputs --idx 5
"""

import os
import sys
import argparse
import torch
from transformers import AutoTokenizer, AutoModelForCausalLM

# ─── Model registry ──────────────────────────────────────────────────────────
MODEL_MAP = {
    "2B": "shailja/fine-tuned-codegen-2B-Verilog",
    "6B": "shailja/fine-tuned-codegen-6B-Verilog",
    "16B": "shailja/fine-tuned-codegen-16B-Verilog", # Adjust HuggingFace path if different
}

# ─── Generation config ───────────────────────────────────────────────────────
GEN_CFG = {
    "max_length":   2048,   
    "temperature":  0,    
    "top_p":        0.95,
    "do_sample":    True,
}

# ─── 14 Unified Prompts ──────────────────────────────────────────────────────
# Format: (file_name, prompt_string)

MODULES = [
    ("m01_alu",
     "// Parameterized N-bit ALU supporting 6 operations with status flags\n"
     "// Operations: ADD, SUB, AND, OR, XOR, SHL (left shift by 1)\n"
     "// Flags: zero (result==0), carry (unsigned overflow on ADD/SUB)\n"
     "// Parameter N sets operand and result bit-width\n"
     "// All outputs are registered on posedge clk\n"
     "// reset is synchronous active-high\n"
     "module alu #(parameter N = 8) (\n"
     "    input wire clk,\n"
     "    input wire reset,\n"
     "    input wire [N-1:0] a,\n"
     "    input wire [N-1:0] b,\n"
     "    input wire [2:0] op, // 000=ADD 001=SUB 010=AND 011=OR 100=XOR 101=SHL\n"
     "    output reg [N-1:0] result,\n"
     "    output reg zero,\n"
     "    output reg carry\n"
     ");\n"
     "    // op encoding: 3'b000=ADD, 3'b001=SUB, 3'b010=AND,\n"
     "    // 3'b011=OR, 3'b100=XOR, 3'b101=SHL\n"
     "    // carry flag: bit N of {1'b0,a} + {1'b0,b} for ADD\n"
     "    // borrow for SUB, 0 for logical ops\n"
     "    // zero flag: (result == 0)\n"),

    ("m02_regfile",
     "// 32-entry, 32-bit-wide register file\n"
     "// Two asynchronous read ports (raddr1, raddr2)\n"
     "// One synchronous write port (write on posedge clk when we=1)\n"
     "// Register 0 (x0) is hardwired to 32'b0 — write to x0 is ignored\n"
     "// reset is synchronous active-high — clears all registers to 0\n"
     "module regfile (\n"
     "    input  wire        clk,\n"
     "    input  wire        reset,\n"
     "    input  wire        we,\n"
     "    input  wire [4:0]  waddr,\n"
     "    input  wire [31:0] wdata,\n"
     "    input  wire [4:0]  raddr1,\n"
     "    input  wire [4:0]  raddr2,\n"
     "    output wire [31:0] rdata1,\n"
     "    output wire [31:0] rdata2\n"
     ");\n"
     "    // rdata1 and rdata2 are combinational reads\n"
     "    // if raddr == waddr and we == 1, read returns OLD value (write-after-read)\n"
     "    // x0 must always read as 32'b0 regardless of writes\n"),

    ("m03_uart_tx",
     "// UART transmitter: 8-N-1 format (8 data bits, no parity, 1 stop bit)\n"
     "// System clock frequency: CLK_FREQ Hz (parameter)\n"
     "// Baud rate: BAUD_RATE bps (parameter)\n"
     "// Baud clock divider = CLK_FREQ / BAUD_RATE\n"
     "// tx idles HIGH. Start bit = LOW. Stop bit = HIGH.\n"
     "// Data bits transmitted LSB first.\n"
     "// Load new byte on load=1 when idle (busy=0)\n"
     "// busy=1 while transmitting; busy=0 when idle\n"
     "module uart_tx #(\n"
     "    parameter CLK_FREQ  = 50_000_000,\n"
     "    parameter BAUD_RATE = 9600\n"
     ") (\n"
     "    input  wire        clk,\n"
     "    input  wire        reset,\n"
     "    input  wire        load,\n"
     "    input  wire [7:0]  data_in,\n"
     "    output reg         tx,\n"
     "    output reg         busy\n"
     ");\n"
     "    // FSM states: IDLE, START, DATA (8 bits), STOP\n"
     "    // Use a baud_counter counting up to CLK_FREQ/BAUD_RATE-1\n"
     "    // Use a bit_counter 0..7 for the 8 data bits\n"
     "    // Shift register: load data_in, shift right each baud tick\n"),

    ("m04_multicycle_cpu",
     "// Multi-cycle RISC CPU with 5 internal phases:\n"
     "// Phase 0: Instruction Fetch  — PC -> MAR, read MEM, IR <- MEM[MAR]\n"
     "// Phase 1: Instruction Decode — RegA <- Reg[rs1], RegB <- Reg[rs2]\n"
     "// Phase 2: Execute            — ALUOut <- ALU(RegA, RegB or imm)\n"
     "// Phase 3: Memory Access      — for LOAD/STORE only\n"
     "// Phase 4: Write Back         — Reg[rd] <- ALUOut or MDR\n"
     "// Supports: ADD, SUB, AND, OR (R-type); ADDI (I-type); LW, SW; BEQ\n"
     "// Harvard architecture: separate instruction and data memory interfaces\n"
     "// 32-bit data width, 32 registers, 10-bit address space\n"
     "// Synchronous reset active-high\n"
     "module multicycle_cpu (\n"
     "    input  wire        clk,\n"
     "    input  wire        reset,\n"
     "    // Instruction memory interface\n"
     "    output wire [9:0]  imem_addr,\n"
     "    input  wire [31:0] imem_data,\n"
     "    // Data memory interface\n"
     "    output wire [9:0]  dmem_addr,\n"
     "    output wire [31:0] dmem_wdata,\n"
     "    output wire        dmem_we,\n"
     "    input  wire [31:0] dmem_rdata\n"
     ");\n"
     "    // Internal registers: PC, IR, MAR, MDR, RegA, RegB, ALUOut\n"
     "    // Control FSM drives all register enables and ALU op select\n"),

    ("m05_control_unit",
     "// Hardwired control unit for a multi-cycle RISC CPU\n"
     "// Inputs: 7-bit opcode, 3-bit phase (0=IF,1=ID,2=EX,3=MEM,4=WB)\n"
     "// Outputs: one control signal per datapath mux and register enable\n"
     "// All outputs are combinational (no registers in control unit)\n"
     "// Use full case statement — every opcode+phase must have defined outputs\n"
     "// Opcodes: 7'b0110011=R-type, 7'b0010011=I-type,\n"
     "//          7'b0000011=LOAD,   7'b0100011=STORE, 7'b1100011=BRANCH\n"
     "module control_unit (\n"
     "    input  wire [6:0] opcode,\n"
     "    input  wire [2:0] phase,\n"
     "    output reg        pc_write,\n"
     "    output reg        ir_write,\n"
     "    output reg        reg_write,\n"
     "    output reg        mem_read,\n"
     "    output reg        mem_write,\n"
     "    output reg        mem_to_reg,\n"
     "    output reg        alu_src_b,   // 0=RegB 1=immediate\n"
     "    output reg [1:0]  alu_op,      // 00=ADD 01=SUB 10=AND 11=OR\n"
     "    output reg        branch\n"
     ");\n"
     "    // Use a casex or nested case on {opcode, phase}\n"
     "    // Default: all outputs = 0 to avoid latches\n"),

    ("m06_pipeline_cpu",
     "// 5-stage pipelined RISC-V RV32I subset processor\n"
     "// Stages: IF (Instruction Fetch) | ID (Decode/Register Read) |\n"
     "//         EX (Execute/ALU)       | MEM (Memory Access)       |\n"
     "//         WB (Write Back)\n"
     "// Pipeline registers: IF_ID, ID_EX, EX_MEM, MEM_WB\n"
     "// Hazard detection unit: inserts NOPs on RAW load-use hazards\n"
     "// Forwarding unit: EX-EX and MEM-EX forwarding paths\n"
     "// Supports: ADD, SUB, AND, OR, ADDI, LW, SW, BEQ\n"
     "// Synchronous reset flushes all pipeline registers\n"
     "module pipeline_cpu (\n"
     "    input  wire        clk,\n"
     "    input  wire        reset,\n"
     "    // Instruction memory (synchronous read)\n"
     "    output wire [31:0] imem_addr,\n"
     "    input  wire [31:0] imem_data,\n"
     "    // Data memory\n"
     "    output wire [31:0] dmem_addr,\n"
     "    output wire [31:0] dmem_wdata,\n"
     "    output wire        dmem_we,\n"
     "    input  wire [31:0] dmem_rdata\n"
     ");\n"
     "    // Pipeline register structs: IF_ID{PC,IR}, ID_EX{...}, EX_MEM{...}, MEM_WB{...}\n"
     "    // Forwarding mux selects: fwd_a, fwd_b (00=reg, 01=MEM, 10=WB)\n"
     "    // Stall signal from hazard unit freezes IF_ID and PC\n"),

    ("m07_dcache",
     "// Direct-mapped cache: 16 sets, 4-byte (32-bit) lines, write-through policy\n"
     "// 32-bit byte address decomposition:\n"
     "//   [1:0]  = byte offset (ignored — word-aligned access)\n"
     "//   [5:2]  = index (4 bits → 16 sets)\n"
     "//   [31:6] = tag (26 bits)\n"
     "// On read hit:  rdata = cache_data[index]; hit = 1\n"
     "// On read miss: fetch from memory (mem_rdata), update cache, hit = 0\n"
     "// On write:     update cache and write through to memory simultaneously\n"
     "// valid array initialised to 0 on reset\n"
     "module dcache (\n"
     "    input  wire        clk,\n"
     "    input  wire        reset,\n"
     "    // CPU interface\n"
     "    input  wire [31:0] addr,\n"
     "    input  wire [31:0] wdata,\n"
     "    input  wire        we,\n"
     "    input  wire        req,\n"
     "    output reg  [31:0] rdata,\n"
     "    output reg         hit,\n"
     "    // Memory interface\n"
     "    output wire [31:0] mem_addr,\n"
     "    output wire [31:0] mem_wdata,\n"
     "    output wire        mem_we,\n"
     "    input  wire [31:0] mem_rdata\n"
     ");\n"
     "    // Arrays: valid[15:0], tag[15:0][25:0], data[15:0][31:0]\n"),

    ("m08_round_robin_arb",
     "// Parameterized round-robin arbiter for N requestors\n"
     "// grant is one-hot: exactly one bit set when any request is active\n"
     "// grant is zero when req == 0\n"
     "// Priority rotates: after granting bit i, next search starts at i+1\n"
     "// Registered output: grant updates on posedge clk\n"
     "// reset is synchronous active-high — priority pointer resets to 0\n"
     "// No starvation: every active requestor is served within N cycles\n"
     "module round_robin_arb #(parameter N = 4) (\n"
     "    input  wire        clk,\n"
     "    input  wire        reset,\n"
     "    input  wire [N-1:0] req,\n"
     "    output reg  [N-1:0] grant\n"
     ");\n"
     "    // Internal: priority pointer register [log2(N)-1:0]\n"
     "    // Algorithm: starting from pointer, find first set bit in req (wrapping)\n"
     "    // Use a for-loop in always block — ensure it synthesises to priority mux\n"
     "    // After grant, advance pointer to (granted_index + 1) % N\n"),

    ("m09_aes128_enc",
     "// AES-128 encryption core — single round function module\n"
     "// (Use chunked prompting: generate SubBytes, MixColumns, top-level separately)\n"
     "// This prompt: complete AES-128 top-level for ONE encryption round\n"
     "// SubBytes: apply 8-bit S-box lookup to each of 16 bytes of state\n"
     "// S-box[0x00]=0x63, S-box[0x01]=0x7c, S-box[0x02]=0x77 ... (full 256-entry LUT)\n"
     "// ShiftRows: row i shifted left by i bytes (i=0,1,2,3)\n"
     "// MixColumns: each column multiplied by fixed matrix in GF(2^8) mod 0x11b\n"
     "// AddRoundKey: state XOR round_key\n"
     "// 10 rounds total; final round skips MixColumns\n"
     "// 128-bit state represented as 16 bytes [127:0]\n"
     "module aes128_enc (\n"
     "    input  wire          clk,\n"
     "    input  wire          reset,\n"
     "    input  wire          start,\n"
     "    input  wire [127:0]  plaintext,\n"
     "    input  wire [127:0]  key,\n"
     "    output reg  [127:0]  ciphertext,\n"
     "    output reg           done\n"
     ");\n"
     "    // Key schedule: expand 128-bit key to 11 round keys (1408 bits total)\n"
     "    // Round counter: 0..10\n"
     "    // State machine: IDLE -> ROUND(10 iterations) -> DONE\n"
     "    // S-box must be a 256x8 ROM: reg [7:0] sbox [0:255]\n"),

    ("m10_sha256",
     "// SHA-256 hash core\n"
     "// Message schedule: W[0..15] from input block; W[i] = sigma1(W[i-2]) + W[i-7]\n"
     "//                   + sigma0(W[i-15]) + W[i-16]  for i=16..63\n"
     "// sigma0(x) = ROTR(x,7)  XOR ROTR(x,18) XOR SHR(x,3)\n"
     "// sigma1(x) = ROTR(x,17) XOR ROTR(x,19) XOR SHR(x,10)\n"
     "// Compression: 64 rounds using working vars a,b,c,d,e,f,g,h\n"
     "// T1 = h + Sigma1(e) + Ch(e,f,g) + K[i] + W[i]\n"
     "// T2 = Sigma0(a) + Maj(a,b,c)\n"
     "// Sigma0(x)=ROTR(x,2)^ROTR(x,13)^ROTR(x,22)\n"
     "// Sigma1(x)=ROTR(x,6)^ROTR(x,11)^ROTR(x,25)\n"
     "// Ch(e,f,g)=(e&f)^(~e&g)   Maj(a,b,c)=(a&b)^(a&c)^(b&c)\n"
     "// Initial hash values H0..H7 (first 32 bits of fractional parts of sqrt of primes)\n"
     "// K constants: first 32 bits of fractional parts of cube roots of first 64 primes\n"
     "// All additions are mod 2^32\n"
     "module sha256 (\n"
     "    input  wire          clk,\n"
     "    input  wire          reset,\n"
     "    input  wire          start,\n"
     "    input  wire [511:0]  block_in,   // one 512-bit message block\n"
     "    output reg  [255:0]  hash_out,\n"
     "    output reg           done\n"
     ");\n"
     "    // Registers: W[63:0][31:0], K[63:0][31:0] (ROM), a..h, round counter\n"),

    ("m11_crc32",
     "// CRC-32 engine using IEEE 802.3 reflected polynomial 0xEDB88320\n"
     "// Bit-serial: one input bit per clock cycle\n"
     "// Input bits are processed LSB first (bit-reflected input)\n"
     "// Output CRC is bit-reflected (standard Ethernet CRC-32 convention)\n"
     "// crc_out is valid one cycle after last input bit when done=1\n"
     "// init=1 resets the LFSR to 32'hFFFFFFFF (standard CRC-32 init)\n"
     "// Final XOR: output = lfsr XOR 32'hFFFFFFFF\n"
     "module crc32 (\n"
     "    input  wire        clk,\n"
     "    input  wire        reset,\n"
     "    input  wire        init,\n"
     "    input  wire        data_in,   // 1 bit per cycle, LSB first\n"
     "    input  wire        data_valid,\n"
     "    output reg  [31:0] crc_out\n"
     ");\n"
     "    // LFSR feedback polynomial (reflected): 0xEDB88320\n"
     "    // = x^32+x^26+x^23+x^22+x^16+x^12+x^11+x^10+x^8+x^7+x^5+x^4+x^2+x+1\n"
     "    // Each cycle: if data_in XOR lfsr[0] == 1, shift and XOR polynomial\n"
     "    //             else just shift right\n"
     "    // crc_out = lfsr XOR 32'hFFFFFFFF\n"),

    ("m12_fft8",
     "// 8-point fixed-point FFT pipeline using Cooley-Tukey DIT (decimation-in-time)\n"
     "// 3 butterfly stages; bit-reversal permutation on input\n"
     "// Fixed-point representation: 16-bit signed (Q1.15 format)\n"
     "// Complex number: {real[15:0], imag[15:0]} packed as 32-bit word\n"
     "// Twiddle factors W_8^k = e^(-j*2*pi*k/8):\n"
     "//   W^0 = ( 1.000,  0.000) = (16'h7FFF, 16'h0000)\n"
     "//   W^1 = ( 0.707, -0.707) = (16'h5A82, 16'hA57E)\n"
     "//   W^2 = ( 0.000, -1.000) = (16'h0000, 16'h8001)\n"
     "//   W^3 = (-0.707, -0.707) = (16'hA57E, 16'hA57E)\n"
     "// Butterfly: A' = A + W*B;  B' = A - W*B\n"
     "// Pipeline: one stage per clock; output valid 3 cycles after input\n"
     "module fft8 (\n"
     "    input  wire        clk,\n"
     "    input  wire        reset,\n"
     "    input  wire        valid_in,\n"
     "    input  wire [31:0] x0, x1, x2, x3, x4, x5, x6, x7,  // bit-reversed order\n"
     "    output reg  [31:0] X0, X1, X2, X3, X4, X5, X6, X7,\n"
     "    output reg         valid_out\n"
     ");\n"
     "    // Stage 1: 4 butterflies with W^0 only\n"
     "    // Stage 2: 4 butterflies with W^0, W^2\n"
     "    // Stage 3: 4 butterflies with W^0, W^1, W^2, W^3\n"
     "    // Use pipeline registers between stages\n"),

    ("m13_matmul16",
     "// 16x16 matrix multiplier using multiply-accumulate (MAC) units\n"
     "// Operands: A[16][16] and B[16][16], each element is 16-bit unsigned\n"
     "// Result:   C[16][16], each element is 32-bit unsigned (sum of 16 products)\n"
     "// C[i][j] = sum_{k=0}^{15} A[i][k] * B[k][j]\n"
     "// Computation is pipelined: one row of C computed per clock after startup\n"
     "// valid_out pulses high when all 256 C elements are ready\n"
     "// Matrices stored in flat arrays: A[i*16+j] = A_flat[i*16+j]\n"
     "module matmul16 (\n"
     "    input  wire          clk,\n"
     "    input  wire          reset,\n"
     "    input  wire          start,\n"
     "    input  wire [4095:0] A_flat,   // 16x16 x 16-bit = 4096 bits\n"
     "    input  wire [4095:0] B_flat,\n"
     "    output reg  [8191:0] C_flat,   // 16x16 x 32-bit = 8192 bits\n"
     "    output reg           valid_out\n"
     ");\n"
     "    // Use generate block to instantiate 16 MAC units per output row\n"
     "    // Each MAC: 16 partial products accumulated in a 32-bit register\n"
     "    // Row counter drives which row of A is being processed\n"),

    ("m14_bubble_sort",
     "// Hardware bubble sort engine for 8 elements of 8-bit unsigned integers\n"
     "// Elements stored in an internal register array: arr[0..7]\n"
     "// load=1 loads input_data into the array on the next posedge clk\n"
     "// start=1 begins sorting (ignored if already busy)\n"
     "// done=1 when array is fully sorted (pulses for 1 cycle)\n"
     "// Sorted output available on arr_out[63:0] (arr[0] in [7:0], arr[7] in [63:56])\n"
     "// Uses bubble sort: N-1 passes, each pass does N-1 compare-swap steps\n"
     "// One compare-swap per clock cycle\n"
     "module bubble_sort (\n"
     "    input  wire        clk,\n"
     "    input  wire        reset,\n"
     "    input  wire        load,\n"
     "    input  wire        start,\n"
     "    input  wire [63:0] input_data,  // arr[0] in [7:0], arr[7] in [63:56]\n"
     "    output reg  [63:0] arr_out,\n"
     "    output reg         done\n"
     ");\n"
     "    // FSM states: IDLE, LOAD, SORT, DONE\n"
     "    // Pass counter: 0..6 (7 passes for 8 elements)\n"
     "    // Step counter: 0..(6-pass) for compare-swap pairs\n"
     "    // Swap: if arr[step] > arr[step+1] then swap them\n")
]

# ─── Helpers ─────────────────────────────────────────────────────────────────

def list_modules():
    print(f"{'IDX':>4}  {'FILE_NAME':<30}  {'PROMPT_PREVIEW'}")
    print("-" * 90)
    for idx, (name, prompt) in enumerate(MODULES):
        preview = prompt.split("\n")[0][:55]
        print(f"{idx:>4}  {name+'.v':<30}  {preview}")


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
    budget   = GEN_CFG["max_length"] - n_prompt
    print(f"  prompt_tokens={n_prompt}  output_budget={budget}")
    if budget < 200:
        print(f"  [WARN] Prompt too long! Only {budget} tokens left for output.")

    with torch.no_grad():
        sample = model.generate(
            input_ids,
            max_length=GEN_CFG["max_length"],
            temperature=GEN_CFG["temperature"],
            top_p=GEN_CFG["top_p"],
            do_sample=GEN_CFG["do_sample"],
            pad_token_id=tokenizer.eos_token_id,
        )

    # Decode and trim at endmodule
    text = tokenizer.decode(
        sample[0],
        skip_special_tokens=True,
        truncate_before_pattern=[r"endmodule"],
    ) + "\nendmodule\n"
    return text


def run_one(idx: int, model_size: str, output_dir: str):
    name, prompt = MODULES[idx]
    device = "cuda" if torch.cuda.is_available() else "cpu"
    tokenizer, model = load_model(model_size, device)

    # We skip the "folder" variable entirely now. Files save directly to the size folder.
    out_dir  = os.path.join(output_dir, model_size)
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, f"{name}.v")

    if os.path.exists(out_path):
        print(f"[SKIP] {out_path} already exists.")
        return

    print(f"\n[GEN] idx={idx}  {name}.v")
    verilog = generate_module(prompt, tokenizer, model, device)
    with open(out_path, "w") as f:
        f.write(verilog)
    print(f"[SAVED] {out_path}")


def run_all(model_size: str, output_dir: str):
    device = "cuda" if torch.cuda.is_available() else "cpu"
    tokenizer, model = load_model(model_size, device)

    for idx, (name, prompt) in enumerate(MODULES):
        # Save directly to model_size folder, no deep subdirectories
        out_dir  = os.path.join(output_dir, model_size)
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, f"{name}.v")

        if os.path.exists(out_path):
            print(f"[SKIP] {out_path}")
            continue

        print(f"\n[GEN {idx:>3}/{len(MODULES)-1}] {name}.v")
        verilog = generate_module(prompt, tokenizer, model, device)
        with open(out_path, "w") as f:
            f.write(verilog)
        print(f"[SAVED] → {out_path}")

    print(f"\n[DONE] All {len(MODULES)} unified modules attempted for {model_size}.")


# ─── Entry point ─────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="VeriGen unified batch runner")
    parser.add_argument("--model",      choices=["2B", "6B", "16B"], default="2B",
                        help="Which VeriGen model to use")
    parser.add_argument("--output_dir", default="./unified_outputs",
                        help="Root output directory")
    parser.add_argument("--idx",        type=int, default=None,
                        help="Run only submodule at this index")
    parser.add_argument("--list",       action="store_true",
                        help="Print all module indices and exit")
    args = parser.parse_args()

    if args.list:
        list_modules()
        return

    total = len(MODULES)
    print(f"[INFO] Total modules: {total}")
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
