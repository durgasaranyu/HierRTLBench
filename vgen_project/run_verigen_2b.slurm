#!/bin/bash
#SBATCH --job-name=verigen_2b
#SBATCH --output=logs/verigen_2b_%A_%a.out
#SBATCH --error=logs/verigen_2b_%A_%a.err
#SBATCH --array=0-63                            # JUST RUNNING TASK 0 FOR TESTING!
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --partition=gpu_h100_4

cd $SLURM_SUBMIT_DIR
mkdir -p logs hf_cache

# ── CUDA paths ────────────────────────────────────────────────────────────────
# Changed from cuda-12.3 to the generic cuda symlink to work on ANY node
export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$CUDA_HOME/targets/x86_64-linux/lib:$LD_LIBRARY_PATH

# ── Fix for Disk Quota: Route HuggingFace downloads to /scratch ───────────────
export HF_HOME="/scratch/soumyaj/vgen_project/hf_cache"

# ── Use conda python directly (bypasses venv symlink issue) ──────────────────
PYTHON=/scratch/soumyaj/miniconda3/envs/verigen/bin/python

# ── Sanity checks ─────────────────────────────────────────────────────────────
echo "============================================"
echo "SLURM_ARRAY_TASK_ID : $SLURM_ARRAY_TASK_ID"
echo "Node                : $(hostname)"
echo "Python              : $PYTHON"
echo "Python version      : $($PYTHON --version 2>&1)"
echo "Torch version       : $($PYTHON -c 'import torch; print(torch.__version__)' 2>&1)"
echo "CUDA available      : $($PYTHON -c 'import torch; print(torch.cuda.is_available())' 2>&1)"
echo "GPU                 : $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null)"
echo "============================================"

# ── Bail early if broken ──────────────────────────────────────────────────────
$PYTHON -c "import torch; assert torch.cuda.is_available(), 'CUDA not available'" || {
    echo "ERROR: torch/CUDA check failed — aborting task $SLURM_ARRAY_TASK_ID"
    exit 1
}

# ── Run ───────────────────────────────────────────────────────────────────────
MODEL="2B"
OUTPUT_DIR="/scratch/soumyaj/vgen_project/verigen_out"
mkdir -p "$OUTPUT_DIR"

# Run unbuffered (-u) so we see prints immediately
$PYTHON -u verigen_runner.py \
    --model "$MODEL" \
    --output_dir "$OUTPUT_DIR" \
    --idx "$SLURM_ARRAY_TASK_ID"
