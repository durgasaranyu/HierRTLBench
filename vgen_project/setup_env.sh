#!/bin/bash
# setup_env.sh — run once on the HPC login node before submitting jobs
# Creates a venv and installs all required packages.

set -e

VENV="$HOME/venvs/verigen"

echo "[1/3] Creating virtual environment at $VENV"
python3 -m venv "$VENV"
source "$VENV/bin/activate"

echo "[2/3] Installing PyTorch (adjust cuda version for your cluster)"
# Change cu121 to match your CUDA version (module show cuda)
pip install --upgrade pip
pip install torch --index-url https://download.pytorch.org/whl/cu121

echo "[3/3] Installing HuggingFace dependencies"
pip install transformers accelerate sentencepiece

echo ""
echo "Done. Test with:"
echo "  source $VENV/bin/activate"
echo "  python verigen_runner.py --list"

