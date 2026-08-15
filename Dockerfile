# HierRTLBench artifact image — MLCAD 2026 AE
#
# Builds a CPU-only environment sufficient for cached-output validation
# (Path A: `run_evaluation.sh --cached`) — no GPU required.
#
# GPU regeneration (Path B/C) needs an NVIDIA GPU + CUDA runtime that Docker
# Desktop / plain `docker run` does not provide by default; run those paths
# on bare metal or with `docker run --gpus all` on an nvidia-container-toolkit
# host using this same image (it already has the CUDA 12.1 PyTorch wheel).
#
# Build:
#   docker build -t hierrtlbench-ae .
# Smoke test (matches artifact_appendix.tex "Installation" section):
#   docker build -t hierrtlbench-ae .
#   docker run --rm hierrtlbench-ae \
#     iverilog -tnull vgen_project/verigen_out/2B/m02_regfile/regfile_mem.v \
#     && echo PASS || echo FAIL
# Full cached-output evaluation (reproduces the paper's key table):
#   docker run --rm hierrtlbench-ae bash run_evaluation.sh --cached

FROM python:3.10-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        iverilog \
        git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /artifact

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cu121

COPY . .

CMD ["bash", "run_evaluation.sh", "--cached"]
