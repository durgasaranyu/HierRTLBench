# Artifact Appendix

**Paper:** HierRTLBench: Evaluating LLM-Based Verilog RTL Generation Under Context-Window Constraints  
**Conference:** ACM/IEEE Workshop on Machine Learning for CAD (MLCAD 2026)  
**Authors:** Yashwant Rajesh, Karthikeya Patana, Durga Saranyu, Aathira Sunil, Sri Parameswaran, Kamesh Chandrasekar, Soumya Joshi, Paresh Saxena

---

## Abstract

This artifact provides the complete benchmark suite, generation scripts, pre-generated Verilog outputs, and testbenches for the HierRTLBench paper. The artifact enables reviewers to:

1. **Validate pre-generated outputs** (no GPU required): Run iverilog syntax checks on the included Verilog files and reproduce the syntax pass-rate table from the paper.
2. **Regenerate outputs** (GPU required): Re-run the VeriGen 2B/6B/16B models using the provided SLURM or local Python scripts to produce new Verilog files and compare against paper results.

The benchmark compares two RTL generation strategies — **unified** (one prompt per module) and **hierarchical** (one prompt per submodule) — across 14 hardware designs of increasing complexity.

**Minimal hardware/software requirements for validation path (A):**
- Any Linux/macOS machine with Python 3.9+ and `iverilog` installed.
- ~2 GB disk space for the repository.

**For full regeneration path (B):**
- NVIDIA GPU with ≥ 16 GB VRAM (≥ 80 GB for 16B model).
- ~60 GB disk for model weights and outputs.

---

## Artifact Checklist (Meta-information)

- **Algorithm:** Hierarchical LLM prompt decomposition for RTL code generation.
- **Program:** 14 custom hardware benchmark modules (ALU, register file, UART, multi-cycle CPU, control unit, pipeline CPU, data cache, round-robin arbiter, AES-128, SHA-256, CRC-32, FFT-8, MatMul-16, bubble sort). All benchmarks are included in the repository.
- **EDA Tools:** Icarus Verilog (`iverilog`) for syntax evaluation — open source, freely available. Synopsys VCS + Verdi used optionally for coverage analysis; not required for reproducing the key paper results. No proprietary PDKs or licensed technology files are required.
- **Compilation:** Python 3.9+; PyTorch 2.1+ (CUDA 12.x). See `requirements.txt`.
- **Transformations:** None.
- **Binary:** No pre-compiled binaries included.
- **Model:** VeriGen models fine-tuned on CodeGen (Salesforce):
  - `shailja/fine-tuned-codegen-2B-Verilog` (~4 GB)
  - `shailja/fine-tuned-codegen-6B-Verilog` (~12 GB)
  - `shailja/fine-tuned-codegen-16B-Verilog` (~32 GB)
  - All publicly available on Hugging Face; downloaded automatically by `transformers`.
- **Model availability and access:** Open-weight models on Hugging Face (no API key required). Download on first run; set `HF_HOME` to redirect to a scratch directory on HPC clusters.
- **LLM prompts and inference settings:** All 67 hierarchical submodule prompts are in `verigen_prompts.txt`; 14 unified prompts are inline in `vgen_project/run_unified_verigen.py`. Inference settings: `max_length=2048`, `temperature=0.2`, `top_p=0.95`, `do_sample=True`, 1 sample per submodule.
- **Data set:** The 14 benchmark module specifications are included as prompt strings in the Python scripts. No external dataset download is required.
- **Run-time environment:** Linux (tested on Ubuntu 20.04/22.04). Python 3.9+, PyTorch 2.1+, `transformers` 4.38+, `accelerate` 0.27+, `sentencepiece` 0.1.99+. See `requirements.txt`.
- **Container, VM, or locked environment:** Not provided; see `vgen_project/setup_env.sh` for a reproducible venv setup. A Conda environment file may be added on request.
- **Hardware:** NVIDIA GPU required for regeneration (≥ 16 GB VRAM for 2B/6B; ≥ 80 GB for 16B). Experiments were run on NVIDIA H100 80 GB GPUs via a SLURM cluster. Syntax evaluation (iverilog) runs on any CPU.
- **Run-time state:** Generation uses temperature sampling; outputs may differ slightly across runs. Pass rates are expected to be within ±1 module (±7%) of the paper values.
- **Execution:** Sequential local execution: ~1.5 hrs (2B), ~2.5 hrs (6B), ~4 hrs (16B) on a single H100. Syntax evaluation: < 1 minute.
- **Metrics:** Syntax pass rate (percentage of generated Verilog files that compile without errors under `iverilog -tnull`), reported per model and per module.
- **Output:** Per-module `.v` files in `vgen_project/verigen_out/` (hierarchical) and `vgen_project/unified_outputs/` (unified). Console summary of pass rates printed by `evaluate_syntax.py`.
- **Expected results and tolerances:** See table below. ±1 module tolerance per model due to temperature sampling.
- **Experiments:** Described in this appendix and `README.md`. Pre-generated outputs are included; reviewers can validate without re-running inference. Full-rerun path is also supported.
- **Proprietary EDA tools, PDKs, and licensed technology files:** Synopsys VCS + Verdi are optional (used in the paper for coverage). Not required to reproduce the syntax pass-rate results. No PDKs or licensed IP are used.
- **How much disk space required (approximately):** ~2 GB for repository + testbenches; ~50 GB for model weights (downloaded on demand).
- **How much time is needed to prepare workflow (approximately):** 10–15 minutes (pip install + iverilog install).
- **How much time is needed to complete experiments (approximately):** < 5 minutes for cached-output validation. 6–8 GPU-hours for full regeneration of all three model sizes.
- **API cost or GPU-hours required (if applicable):** No API cost (open-weight local models). ~6–8 H100 GPU-hours for full regeneration.
- **Publicly available:** Yes.
- **Code licenses (if publicly available):** <!-- TODO: Add license -->
- **Data/model licenses and usage restrictions (if applicable):** VeriGen model weights are subject to the license of `shailja/fine-tuned-codegen-2B-Verilog` on Hugging Face. Reviewers should verify the current license before redistribution.
- **Workflow framework used:** Python scripts + SLURM job arrays (for HPC). No additional workflow framework.
- **Zenodo DOI for archived artifact:** <!-- TODO: Add Zenodo DOI after archiving -->

---

## Description

### How to Access

Clone the repository:

```bash
git clone https://github.com/yashwant/HierRTLBench.git
cd HierRTLBench
```

All generated outputs are already included in the repository under:
- `vgen_project/verigen_out/{2B,6B,16B}/` — hierarchical Verilog outputs
- `vgen_project/unified_outputs/{2B,6B,16B}/` — unified Verilog outputs
- `vgen_project/verigen_testbenches/verigen_testbenches/` — testbenches

Approximate disk usage after clone: ~500 MB (outputs) + downloaded model weights (~50 GB).

### Hardware Dependencies

- **Syntax validation (iverilog):** Any CPU; no GPU required.
- **Full regeneration:** NVIDIA GPU with CUDA 12.x support.
  - VeriGen-2B: ≥ 16 GB VRAM
  - VeriGen-6B: ≥ 24 GB VRAM
  - VeriGen-16B: ≥ 80 GB VRAM (H100 or A100 80 GB recommended)

### Software Dependencies

| Dependency | Version | Source |
|------------|---------|--------|
| Python | 3.9+ | system / Conda |
| PyTorch | 2.1+ | [pytorch.org](https://pytorch.org/get-started/) |
| transformers | 4.38+ | PyPI |
| accelerate | 0.27+ | PyPI |
| sentencepiece | 0.1.99+ | PyPI |
| iverilog | 11.0+ | `apt install iverilog` / `brew install icarus-verilog` |

### Commercial Software and PDK Dependencies

**Synopsys VCS + Verdi** were used optionally for simulation coverage analysis in the paper. These tools are **not required** to reproduce the primary syntax pass-rate results. Reviewers without VCS/Verdi access can use `iverilog` for all key experiments. No PDKs or proprietary technology files are used in this artifact.

### Data Sets

The benchmark consists of 14 hardware module specifications embedded directly as prompt strings in:
- `vgen_project/verigen_runner.py` (hierarchical, 67 submodule prompts)
- `vgen_project/run_unified_verigen.py` (unified, 14 module prompts)
- `verigen_prompts.txt` (human-readable listing of all prompts)

No external dataset download is required.

### Models

Three open-weight VeriGen models, all hosted on Hugging Face:

| Model | HF ID | Size | License |
|-------|-------|------|---------|
| VeriGen-2B | `shailja/fine-tuned-codegen-2B-Verilog` | ~4 GB | See HF page |
| VeriGen-6B | `shailja/fine-tuned-codegen-6B-Verilog` | ~12 GB | See HF page |
| VeriGen-16B | `shailja/fine-tuned-codegen-16B-Verilog` | ~32 GB | See HF page |

Models are downloaded automatically by the Hugging Face `transformers` library on first run. Set the `HF_HOME` environment variable to control the cache location (important on HPC clusters with limited home-directory quotas):

```bash
export HF_HOME=/scratch/<your_username>/hf_cache
```

**Inference settings (identical for all experiments):**

| Parameter | Value |
|-----------|-------|
| `max_length` | 2048 tokens |
| `temperature` | 0.2 |
| `top_p` | 0.95 |
| `do_sample` | True |
| Samples per submodule | 1 |
| Stop sequences | None (model generates until `max_length`) |

---

## Installation

### Step 1: Install system dependencies

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install iverilog python3 python3-venv python3-pip

# macOS (Homebrew)
brew install icarus-verilog python
```

### Step 2: Install Python dependencies

```bash
# From the repository root
pip install -r requirements.txt

# For GPU inference, install PyTorch with the correct CUDA wheel:
pip install torch --index-url https://download.pytorch.org/whl/cu121
```

### Step 3: (HPC only) Create a Conda/venv environment

```bash
bash vgen_project/setup_env.sh
```

### Smoke Test

Verify `iverilog` and the evaluation script work correctly:

```bash
# Should print: PASS
iverilog -tnull vgen_project/verigen_out/2B/m01_alu/alu_addsub.v && echo "PASS" || echo "FAIL"

# Quick pass-rate check on one pre-generated model
python evaluate_syntax.py --models 2B
```

Expected output for the smoke test:

```
=== Hierarchical Generation — Syntax Pass Rate ===
Model   Passed  Total   Rate
2B      X/14    14      X.X%
```

---

## Experiment Workflow

### Validation Path A: Cached-Output Validation (Recommended for Reviewers)

Use the pre-generated outputs included in the repository. No GPU or model download required.

```bash
# Step 1: Install iverilog and Python (see Installation above)

# Step 2: Run syntax evaluation on all pre-generated outputs
python evaluate_syntax.py \
    --hier_dir vgen_project/verigen_out \
    --unified_dir vgen_project/unified_outputs \
    --tb_dir vgen_project/verigen_testbenches/verigen_testbenches

# Step 3: Compare printed results with Table X in the paper
```

### Validation Path B: Full Regeneration (GPU Required)

```bash
# Step 1: Set up environment (see Installation)
pip install -r requirements.txt

# Step 2: Run hierarchical generation for all models
python vgen_project/verigen_runner.py --model 2B --output_dir /tmp/hier_out
python vgen_project/verigen_runner.py --model 6B --output_dir /tmp/hier_out
python vgen_project/verigen_runner.py --model 16B --output_dir /tmp/hier_out

# Step 3: Run unified generation for all models
python vgen_project/run_unified_verigen.py --model 2B --output_dir /tmp/unified_out
python vgen_project/run_unified_verigen.py --model 6B --output_dir /tmp/unified_out
python vgen_project/run_unified_verigen.py --model 16B --output_dir /tmp/unified_out

# Step 4: Write integration top modules (deterministic, no LLM)
python vgen_project/write_integrations.py --output_dir /tmp/hier_out

# Step 5: Evaluate syntax
python evaluate_syntax.py \
    --hier_dir /tmp/hier_out \
    --unified_dir /tmp/unified_out \
    --tb_dir vgen_project/verigen_testbenches/verigen_testbenches
```

### Validation Path C: Bounded Subset (Single Module, Fastest)

```bash
# Generate only M01 ALU (idx=0–4 for hierarchical submodules, ~5 min on H100)
python vgen_project/verigen_runner.py --model 2B \
    --output_dir /tmp/smoke \
    --idx 0   # alu_addsub

# Check syntax
iverilog -tnull /tmp/smoke/m01_alu/alu_addsub.v && echo "PASS" || echo "FAIL"
```

---

## Evaluation and Expected Results

### Key Result: Syntax Pass Rate (Table from Paper)

Run:

```bash
python evaluate_syntax.py
```

Expected output:

```
=== Hierarchical Generation — Syntax Pass Rate ===
Model   Passed  Total   Rate
2B      6/14    14      ~44%
6B      0/14    14        0%
16B     8/14    14      ~54%

=== Unified Generation — Syntax Pass Rate ===
Model   Passed  Total   Rate
2B       X/14   14       X%
6B       X/14   14       X%
16B      X/14   14       X%
```

**Acceptable tolerance:** ±1 module (±7%) per model, per approach. Results are non-deterministic due to temperature sampling (`temperature=0.2`). The cached pre-generated outputs in the repository match the paper exactly.

**Validation path:** For exact paper reproduction, use the pre-generated outputs (Validation Path A). For independent verification, run Path B and compare within tolerance.

### Mapping Scripts to Paper Results

| Paper Section / Table | Script / Output Path |
|----------------------|---------------------|
| Hierarchical pass rates | `evaluate_syntax.py --hier_dir vgen_project/verigen_out` |
| Unified pass rates | `evaluate_syntax.py --unified_dir vgen_project/unified_outputs` |
| Per-module breakdown | Same script, per-module rows in output |
| Generated Verilog (hierarchical) | `vgen_project/verigen_out/{2B,6B,16B}/` |
| Generated Verilog (unified) | `vgen_project/unified_outputs/{2B,6B,16B}/` |

---

## Experiment Customization

- **Model size:** Pass `--model 2B`, `--model 6B`, or `--model 16B` to any runner script.
- **Single submodule:** Use `--idx N` (0–66) to generate one submodule at a time (useful for debugging or HPC array jobs).
- **Output directory:** Use `--output_dir /path/to/dir` in all scripts.
- **Inference temperature:** Edit `GEN_CFG["temperature"]` in `verigen_runner.py` or `run_unified_verigen.py`.
- **Custom prompts:** Add entries to the `SUBMODULES` list in `verigen_runner.py` following the existing format.

---

## Notes

- The SLURM scripts contain HPC-specific paths (e.g., `/scratch/soumyaj/`). Edit the `PYTHON` and `HF_HOME` variables before submitting on your cluster.
- The VeriGen models use the CodeGen architecture with a hard 2048-token limit. Generation stops at this limit even if the module is incomplete, which is the central constraint studied in the paper.
- Model weights are large (~48 GB total for all three); plan storage accordingly.

---

## Methodology

- <https://www.acm.org/publications/policies/artifact-review-and-badging-current>
- <https://github.com/ml-eda/artifact-evaluation/>
