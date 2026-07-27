# HierRTLBench: Evaluating LLM-Based Verilog RTL Generation Under Context-Window Constraints

**MLCAD 2026 Paper Artifact**

> Yashwant Rajesh, Karthikeya Patana, Durga Saranyu, Aathira Sunil, Sri Parameswaran, Kamesh Chandrasekar, Soumya Joshi, Paresh Saxena

---

## Overview

HierRTLBench is a benchmark suite and evaluation framework for studying how context-window constraints affect LLM-based Verilog RTL generation. The benchmark compares two generation strategies across three VeriGen model sizes (2B, 6B, 16B parameters):

- **Unified approach**: A single natural-language prompt per module, asking the model to generate the entire design at once.
- **Hierarchical approach**: Each module is decomposed into well-scoped submodules. The model generates each submodule independently and the results are assembled into a full design.

The benchmark covers 14 hardware design modules ranging from a simple ALU to AES-128 encryption and a RISC-V pipeline CPU.

---

## Repository Structure

```
HierRTLBench/
├── README.md                        ← This file
├── artifact_appendix.tex            ← MLCAD AE appendix (LaTeX)
├── MLCAD_HierRTLBench.pdf           ← Paper (camera-ready)
├── HierRTLBench.docx                ← Technical report artifact
├── Hpc_environment_setup_log.md     ← HPC setup/troubleshooting log
├── requirements.txt                 ← Python dependencies (pip)
├── conda_env.yml                    ← Python dependencies (conda, alternative)
├── run_evaluation.sh                ← End-to-end evaluation script
├── evaluate_syntax.py               ← Syntax pass-rate checker (iverilog)
├── verigen_prompts.txt              ← Hierarchical submodule prompts (50 in verigen_runner.py)
├── Dockerfile                       ← Container build for cached-output evaluation
├── LICENSE
├── .gitignore
│
└── vgen_project/
    ├── verigen_runner.py            ← Hierarchical inference runner
    ├── run_unified_verigen.py       ← Unified inference runner
    ├── write_integrations.py        ← Deterministic integration top writer
    ├── setup_env.sh                 ← Environment setup (venv + pip)
    │
    ├── run_verigen.slurm            ← SLURM: hierarchical, 6B, array 0–49
    ├── run_verigen_2b.slurm         ← SLURM: hierarchical, 2B
    ├── run_verigen_16b.slurm        ← SLURM: hierarchical, 16B
    ├── run_unified.slurm            ← SLURM: unified, all models
    │
    ├── verigen_out/                 ← Generated hierarchical Verilog outputs
    │   ├── 2B/  m01_alu/ … m14_sort/
    │   ├── 6B/  m01_alu/ … m14_sort/
    │   └── 16B/ m01_alu/ … m14_sort/
    │       └── m01_alu/  alu_addsub.v, alu_flags.v, alu_logic.v,
    │                     alu_shift.v, alu_top_integration.v
    │
    ├── unified_outputs/             ← Generated unified Verilog outputs
    │   ├── 2B/  m01_alu.v, m02_regfile.v, m03_uart_tx.v, m04_multicycle_cpu.v,
    │   │        m05_control_unit.v, m06_pipeline_cpu.v, m07_dcache.v,
    │   │        m08_round_robin_arb.v, m09_aes128_enc.v, m10_sha256.v,
    │   │        m11_crc32.v … m14_bubble_sort.v
    │   ├── 6B/
    │   └── 16B/
    │
    └── verigen_testbenches/
        └── verigen_testbenches/     ← Testbenches for all 14 modules
            ├── m01_alu/
            ├── m02_regfile/
            └── … m14_sort/
```

> **Note:** Integration top modules are generated deterministically via `write_integrations.py` and are named `<module>_top_integration.v` (e.g. `alu_top_integration.v`) inside each module's folder under `verigen_out/`. There is no LLM-based integration generator in this repository — integration wrappers are assembled programmatically, not by the evaluated models.

---

## Benchmark Modules

| ID | Module | Description |
|----|--------|-------------|
| M01 | ALU | Parameterized N-bit ALU (ADD, SUB, AND, OR, XOR, SHL) |
| M02 | Register File | 32-entry 32-bit RISC register file |
| M03 | UART TX | 8-N-1 UART transmitter with parametric baud rate |
| M04 | Multi-Cycle CPU | Harvard RISC multi-cycle CPU |
| M05 | Control Unit | Standalone CPU control unit FSM |
| M06 | Pipeline CPU | 5-stage RISC-V pipeline |
| M07 | D-Cache | Direct-mapped data cache |
| M08 | Round-Robin Arbiter | N-port round-robin bus arbiter |
| M09 | AES-128 Enc | AES-128 encryption core |
| M10 | SHA-256 | SHA-256 hash core |
| M11 | CRC-32 | CRC-32 generator |
| M12 | FFT-8 | 8-point FFT |
| M13 | MatMul-16 | 16×16 matrix multiplier |
| M14 | Bubble Sort | Hardware bubble sort |

---

## Key Results

| Model | Approach | Syntax Pass Rate |
|-------|----------|-----------------|
| VeriGen-2B | Hierarchical | 44% |
| VeriGen-6B | Hierarchical | 0% |
| VeriGen-16B | Hierarchical | 54% |

> **Note:** The unified approach results are also present in `unified_outputs/`. Consult the paper for full tables comparing both approaches.

---

## Models

All models are freely available on Hugging Face (no authentication required):

| Model | Hugging Face ID | Approx. Size |
|-------|----------------|--------------|
| VeriGen-2B | `shailja/fine-tuned-codegen-2B-Verilog` | ~4 GB |
| VeriGen-6B | `shailja/fine-tuned-codegen-6B-Verilog` | ~12 GB |
| VeriGen-16B | `shailja/fine-tuned-codegen-16B-Verilog` | ~32 GB |

**Inference settings (fixed for all experiments):**

| Parameter | Value |
|-----------|-------|
| `max_length` | 2048 tokens |
| `temperature` | 0 |
| `top_p` | 0.95 |
| `do_sample` | False |
| Num samples | 1 per submodule |

---

## Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| GPU | 16 GB VRAM (for 2B) | NVIDIA H100 80 GB |
| GPU RAM | 16 GB (2B), 24 GB (6B) | 80 GB (16B) |
| System RAM | 32 GB | 64 GB |
| Storage | ~60 GB (models + outputs) | 100 GB |

> The experiments in the paper were run on an NVIDIA H100 GPU cluster via SLURM. The evaluation (syntax checking) can be run on any CPU-only machine with iverilog installed.

---

## Software Requirements

- Python 3.9+
- PyTorch (CUDA 12.x recommended)
- `transformers`, `accelerate`, `sentencepiece`
- [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`) for syntax evaluation
- (Optional) Synopsys VCS + Verdi for coverage analysis

Install Python dependencies with pip:

```bash
pip install -r requirements.txt
```

Or with conda:

```bash
conda env create -f conda_env.yml
```

Or use the provided setup script on an HPC cluster:

```bash
bash vgen_project/setup_env.sh
```

---

## Quick Start

### Option A: Evaluate Pre-Generated Outputs (No GPU Required)

The repository already contains all generated Verilog outputs in `vgen_project/verigen_out/` and `vgen_project/unified_outputs/`. You can directly run syntax evaluation with iverilog:

```bash
# Install iverilog (Ubuntu/Debian)
sudo apt-get install iverilog

# Check syntax pass rates for all outputs
python evaluate_syntax.py --hier_dir vgen_project/verigen_out \
                          --unified_dir vgen_project/unified_outputs \
                          --tb_dir vgen_project/verigen_testbenches/verigen_testbenches
```

#### Option A' — Docker (no local installs needed)

```bash
docker build -t hierrtlbench-ae .
docker run --rm hierrtlbench-ae bash run_evaluation.sh --cached
```

### Option B: Regenerate Outputs (GPU Required)

**Step 1: Set up the environment**

```bash
# Using pip (local)
pip install -r requirements.txt

# Or on HPC cluster
bash vgen_project/setup_env.sh
```

**Step 2: Run hierarchical generation**

```bash
# Local: run all 50 submodules sequentially (2B model)
python vgen_project/verigen_runner.py \
    --model 2B \
    --output_dir vgen_project/verigen_out

# List all submodule indices
python vgen_project/verigen_runner.py --list

# HPC (SLURM): submit as a job array (6B model, indices 0–49)
cd vgen_project && sbatch run_verigen.slurm
```

**Step 3: Run unified generation**

```bash
# Local
python vgen_project/run_unified_verigen.py \
    --model 2B \
    --output_dir vgen_project/unified_outputs

# HPC (SLURM)
cd vgen_project && sbatch run_unified.slurm
```

**Step 4: Generate integration top modules**

```bash
# Deterministic integration wrappers (no LLM) — writes <module>_top_integration.v
python vgen_project/write_integrations.py \
    --output_dir vgen_project/verigen_out
```

**Step 5: Evaluate syntax**

```bash
python evaluate_syntax.py \
    --hier_dir vgen_project/verigen_out \
    --unified_dir vgen_project/unified_outputs \
    --tb_dir vgen_project/verigen_testbenches/verigen_testbenches
```

### Option C: Smoke Test (Single Submodule, Fast)

```bash
# Generate only M01 ALU adder-subtractor with VeriGen-2B
python vgen_project/verigen_runner.py --model 2B \
    --output_dir /tmp/hier_smoke \
    --idx 0

# Check iverilog syntax on the generated file
iverilog -tnull /tmp/hier_smoke/m01_alu/alu_addsub.v && echo "PASS" || echo "FAIL"
```

---

## Evaluation Script Reference

### `evaluate_syntax.py`

Checks iverilog syntax for all generated outputs and computes per-module and overall pass rates.

```
usage: evaluate_syntax.py [-h] [--hier_dir DIR] [--unified_dir DIR]
                          [--tb_dir DIR] [--models 2B 6B 16B]

Options:
  --hier_dir     Root of hierarchical outputs  (default: vgen_project/verigen_out)
  --unified_dir  Root of unified outputs       (default: vgen_project/unified_outputs)
  --tb_dir       Root of testbench directory   (default: vgen_project/verigen_testbenches/verigen_testbenches)
  --models       Model sizes to evaluate       (default: 2B 6B 16B)
```
---

## HPC / SLURM Usage

All SLURM scripts are parameterized. Edit the `PYTHON` path and `HF_HOME` variables at the top of each script to match your cluster environment.

| Script | Purpose | Array |
|--------|---------|-------|
| `run_verigen.slurm` | Hierarchical, VeriGen-6B | 0–49 |
| `run_verigen_2b.slurm` | Hierarchical, VeriGen-2B | 0–49 |
| `run_verigen_16b.slurm` | Hierarchical, VeriGen-16B | 0–49 |
| `run_unified.slurm` | Unified, all models | single job |

Estimated GPU time per model:

| Model | Per submodule | Full run (50 submodules) |
|-------|--------------|--------------------------|
| 2B | ~1 min | ~0.8 hrs |
| 6B | ~2 min | ~1.7 hrs |
| 16B | ~3 min | ~2.5 hrs |

For detailed environment setup and cluster troubleshooting notes, see [`Hpc_environment_setup_log.md`](Hpc_environment_setup_log.md).

---

## License

The benchmark code and scripts are released under the [MIT License](LICENSE).

The VeriGen model weights are subject to the license terms of the original model:
[`shailja/fine-tuned-codegen-2B-Verilog`](https://huggingface.co/shailja/fine-tuned-codegen-2B-Verilog).

---

## Citation

If you use HierRTLBench in your research, please cite:

```bibtex
@inproceedings{rajesh2026hierrtlbench,
  title     = {{HierRTLBench}: Evaluating {LLM}-Based {Verilog} {RTL} Generation Under Context-Window Constraints},
  author    = {Yashwant Rajesh, Karthikeya Patana, Durga Saranyu, Aathira Sunil, Sri Parameswaran, Kamesh Chandrasekar, Soumya Joshi, Paresh Saxena}
  booktitle = {Proceedings of the ACM/IEEE Workshop on Machine Learning for CAD (MLCAD)},
  year      = {2026}
}
```

---
