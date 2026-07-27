#!/bin/bash
#SBATCH --job-name=verigen_unified
#SBATCH --output=logs/unified_%j.out
#SBATCH --error=logs/unified_%j.err
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G                            # Keep 64G to comfortably fit the 16B model
#SBATCH --time=04:00:00                      # 4 hours is plenty of time to run all 14 prompts sequentially
#SBATCH --partition=gpu_h100_4               # Using your exact H100 partition

cd $SLURM_SUBMIT_DIR
mkdir -p logs hf_cache

# ── Use your exact CUDA symlinks ──────────────────────────
export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$CUDA_HOME/targets/x86_64-linux/lib:$LD_LIBRARY_PATH

export HF_HOME="/scratch/$USER/vgen_project/hf_cache"

# ── Use your exact python environment ─────────────────────
PYTHON=/scratch/$USER/miniconda3/envs/verigen/bin/python

# ── Comprehensive Sanity Checks ───────────────────────────────────────────────
echo "============================================"
echo "Job ID              : $SLURM_JOB_ID"
echo "Node                : $(hostname)"
echo "Python              : $PYTHON"
echo "Python version      : $($PYTHON --version 2>&1)"
echo "Torch version       : $($PYTHON -c 'import torch; print(torch.__version__)' 2>&1)"
echo "CUDA available      : $($PYTHON -c 'import torch; print(torch.cuda.is_available())' 2>&1)"
echo "GPU                 : $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null)"
echo "GPU Memory          : $(nvidia-smi --query-gpu=memory.free,memory.total --format=csv,noheader 2>/dev/null)"
echo "============================================"

$PYTHON -c "import torch; assert torch.cuda.is_available(), 'CUDA not available'" || {
    echo "ERROR: CUDA check failed — aborting job"
    exit 1
}

# The folder where the 2B, 6B, and 16B outputs will be saved
OUTPUT_DIR="/scratch/$USER/vgen_project/unified_outputs"
mkdir -p "$OUTPUT_DIR"

# ── Run the Python script for all 3 models ────────────────────────────────────
# Note: Since we are not using `--idx`, the Python script will automatically 
# loop through and generate all 14 modules per model size.

echo ""
echo ">>>>>>>> Running 2B Model <<<<<<<<"
$PYTHON -u run_unified_verigen.py \
    --model "2B" \
    --output_dir "$OUTPUT_DIR"

echo ""
echo ">>>>>>>> Running 6B Model <<<<<<<<"
$PYTHON -u run_unified_verigen.py \
    --model "6B" \
    --output_dir "$OUTPUT_DIR"

echo ""
echo ">>>>>>>> Running 16B Model <<<<<<<<"
$PYTHON -u run_unified_verigen.py \
    --model "16B" \
    --output_dir "$OUTPUT_DIR"

echo ""
echo "============================================"
echo "All unified generation tasks completed successfully!"
