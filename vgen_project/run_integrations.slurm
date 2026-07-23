#!/bin/bash
#SBATCH --job-name=verigen_integration
#SBATCH --output=logs/integration_%A_%a.out
#SBATCH --error=logs/integration_%A_%a.err
#SBATCH --array=0-13                         # 14 jobs, one per benchmark module
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G                            # 64 GB RAM for 16B
#SBATCH --time=01:00:00                      # 1 hour ceiling
#SBATCH --partition=gpu_h100_4               # H100 partition

cd $SLURM_SUBMIT_DIR
mkdir -p logs hf_cache verigen_out/16B

# ── CUDA and Environment Setup ────────────────────────────────────────────────
export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$CUDA_HOME/targets/x86_64-linux/lib:$LD_LIBRARY_PATH
export HF_HOME="/scratch/soumyaj/vgen_project/hf_cache"

PYTHON=/scratch/soumyaj/miniconda3/envs/verigen/bin/python

# ── USER CONFIGURATION ────────────────────────────────────────────────────────
MODEL_PATH="shailja/fine-tuned-codegen-16B-Verilog"
OUTPUT_DIR="/scratch/soumyaj/vgen_project/verigen_out/16B"
# ──────────────────────────────────────────────────────────────────────────────

KEYS=(
  "m01_alu/alu_top_integration"
  "m02_regfile/regfile_top_integration"
  "m03_uart/uart_tx_top_integration"
  "m04_cpu/cpu_top_integration"
  "m05_ctrl/ctrl_top_integration"
  "m06_riscv/rv_top_integration"
  "m07_cache/cache_top_integration"
  "m08_arbiter/rr_top_integration"
  "m09_aes/aes_top_integration"
  "m10_sha256/sha256_top_integration"
  "m11_crc32/crc32_top_integration"
  "m12_fft/fft_top_integration"
  "m13_matmul/mat_top_integration"
  "m14_sort/bubble_sort_top_integration"
)

KEY="${KEYS[$SLURM_ARRAY_TASK_ID]}"

echo "========================================"
echo "SLURM_ARRAY_TASK_ID : $SLURM_ARRAY_TASK_ID"
echo "Module key          : $KEY"
echo "Model Path          : $MODEL_PATH"
echo "Output dir          : $OUTPUT_DIR"
echo "========================================"

# Sanity Check
$PYTHON -c "import torch; assert torch.cuda.is_available(), 'CUDA not available'" || {
    echo "ERROR: CUDA check failed — aborting task $SLURM_ARRAY_TASK_ID"
    exit 1
}

# Run the python script
$PYTHON -u generate_integrations.py \
    --model_path  "$MODEL_PATH"  \
    --output_dir  "$OUTPUT_DIR"  \
    --max_new_tokens 1200        \
    --only "$KEY"

echo "Job finished with exit code $?"
