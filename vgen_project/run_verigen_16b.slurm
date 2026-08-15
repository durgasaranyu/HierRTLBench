#!/bin/bash
#SBATCH --job-name=verigen_16b
#SBATCH --output=logs/verigen_16b_%A_%a.out
#SBATCH --error=logs/verigen_16b_%A_%a.err
#SBATCH --array=0-49                      
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G                           # 16B fp16 ≈ 32 GB VRAM; bump CPU RAM too
#SBATCH --time=04:00:00                     # 16B is ~8x slower per task than 2B
#SBATCH --partition=gpu_h100_4              # H100 (80 GB) is required; 40 GB GPU won't fit

cd $SLURM_SUBMIT_DIR
mkdir -p logs hf_cache

# ── FIX: Point to the universal generic CUDA symlink ──────────────────────────
export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$CUDA_HOME/targets/x86_64-linux/lib:$LD_LIBRARY_PATH

export HF_HOME="/scratch/$USER/vgen_project/hf_cache"

PYTHON=/scratch/$USER/miniconda3/envs/verigen/bin/python

# ── Comprehensive Sanity Checks ───────────────────────────────────────────────
echo "============================================"
echo "SLURM_ARRAY_TASK_ID : $SLURM_ARRAY_TASK_ID"
echo "Node                : $(hostname)"
echo "Python              : $PYTHON"
echo "Python version      : $($PYTHON --version 2>&1)"
echo "Torch version       : $($PYTHON -c 'import torch; print(torch.__version__)' 2>&1)"
echo "CUDA available      : $($PYTHON -c 'import torch; print(torch.cuda.is_available())' 2>&1)"
echo "GPU                 : $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null)"
echo "GPU Memory          : $(nvidia-smi --query-gpu=memory.free,memory.total --format=csv,noheader 2>/dev/null)"
echo "============================================"

$PYTHON -c "import torch; assert torch.cuda.is_available(), 'CUDA not available'" || {
    echo "ERROR: CUDA check failed — aborting task $SLURM_ARRAY_TASK_ID"
    exit 1
}

MODEL="16B"
OUTPUT_DIR="/scratch/$USER/vgen_project/verigen_out"
mkdir -p "$OUTPUT_DIR"

$PYTHON -u verigen_runner.py \
    --model "$MODEL" \
    --output_dir "$OUTPUT_DIR" \
    --idx "$SLURM_ARRAY_TASK_ID"
