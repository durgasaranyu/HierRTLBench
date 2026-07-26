# HPC Environment Setup & Troubleshooting Log

Supplementary log documenting the compute environment, job scheduling
configuration, and issues resolved while running VeriGen inference jobs
on the HPC cluster for RTL submodule generation.

## 1. Environment

- **Compute:** NVIDIA H100 80GB GPU nodes
- **Scheduler:** SLURM (job arrays for parallel per-submodule generation)
- **Software:** Python virtual environment (`venv`), PyTorch, HuggingFace Transformers
- **Storage:** `/scratch` (high-capacity, shared) used for model weights and outputs; the user `$HOME` directory has a small quota and is unsuitable for model caches

## 2. Issues Encountered and Fixes

### 2.1 Disk quota exceeded during model download
- **Symptom:** Job appeared to hang; error log showed `IO Error: Disk quota exceeded`.
- **Cause:** HuggingFace's default cache directory is under `$HOME`, which has a small quota (5–10GB) on shared HPC systems. The ~12GB model checkpoint exhausted it mid-download.
- **Fix:** Cleared the partial cache (`rm -rf ~/.cache/huggingface/*`) and redirected the cache to `/scratch` by setting `HF_HOME` in the job script before submission.

### 2.2 SLURM script formatting error
- **Symptom:** Job submission failed after editing the batch script.
- **Cause:** SLURM requires the script's first line to be exactly `#!/bin/bash`; a stray edit broke this.
- **Fix:** Rewrote the script cleanly with the shebang as the first line.

### 2.3 Hardcoded CUDA path
- **Symptom:** Jobs failed with a missing-directory error for a version-specific CUDA path (`/usr/local/cuda-12.3`).
- **Cause:** That path didn't exist on the compute node actually assigned; only a generic CUDA 12 install was present.
- **Fix:** Set `CUDA_HOME=/usr/local/cuda` (the universal symlink present on all nodes) instead of a version-pinned path.

### 2.4 Module system unavailable in batch jobs
- **Symptom:** `module: command not found` when using `module load cuda...` inside a SLURM script.
- **Cause:** The cluster's `lmod` module system is only initialized in interactive login sessions, not in batch job environments.
- **Fix:** Removed `module load` calls from the SLURM script; used direct environment-variable exports instead (see 2.3).

### 2.5 PyTorch/CUDA driver mismatch
- **Symptom:** Runtime CUDA initialization errors after resolving the path issues above.
- **Cause:** The installed PyTorch build was compiled for CUDA 13.0, but the H100 nodes only had CUDA 12.x drivers, which cannot run CUDA 13.0 binaries.
- **Fix:** Reinstalled PyTorch built against CUDA 12.1 (`--index-url https://download.pytorch.org/whl/cu121`), which is compatible with the installed 12.x drivers.

## 3. Job Scheduling Behavior

- Generation jobs were submitted as a **SLURM job array**, with one array task per submodule (`--array=0-49`, 50 submodules per model).
- The cluster enforces a per-user GPU quota (`QOSMaxCpuPerUserLimit`), so only one array task ran at a time; remaining tasks queued automatically and started as prior tasks completed. This is expected scheduler behavior, not a fault condition.
- **Per-task timing:** ≈35 min to load model weights from `/scratch` into GPU memory (repeated on every task, since each array task starts a fresh process) + ≈2 min generation ≈ **37 min/task total**.
- The batch script's requested walltime (`--time`) was set comfortably above the observed per-task duration to avoid premature termination.

## 4. Verification Commands Used

```bash
# Check whether all array tasks have completed
squeue -u $USER          # empty output = all tasks finished

# Count generated Verilog files (expect 50 per model)
find verigen_out/ -name "*.v" | wc -l

# Check for truncated output (missing endmodule)
grep -rL "endmodule" verigen_out/**/*.v   # no output = no truncated files

# Check logs for actual failures (HuggingFace warnings are expected and benign)
grep -i "error" logs/verigen_*.err

# List generated files for a given model
find verigen_out/6B -name "*.v" | sort
```

## Note on file/task counts

Counts in this log (50 submodules per model, 150 verification runs across
2B/6B/16B) are reconciled to match the finalized benchmark reported in the
paper.
