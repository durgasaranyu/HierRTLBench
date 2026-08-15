#!/usr/bin/env bash
# =============================================================================
# run_evaluation.sh — HierRTLBench end-to-end evaluation script
# =============================================================================
# Validates the key paper results (syntax pass rates) using the pre-generated
# Verilog outputs already included in the repository.
#
# Prerequisites:
#   - iverilog installed  (sudo apt-get install iverilog  OR  brew install icarus-verilog)
#   - Python 3.9+         (pip install -r requirements.txt)
#
# Usage:
#   bash run_evaluation.sh [--cached | --regen-2b | --regen-6b | --regen-16b | --full-regen]
#
# Modes:
#   --cached        (default) Evaluate pre-generated outputs — no GPU needed
#   --regen-2b      Re-generate 2B outputs, then evaluate
#   --regen-6b      Re-generate 6B outputs, then evaluate
#   --regen-16b     Re-generate 16B outputs, then evaluate
#   --full-regen    Re-generate all three models, then evaluate
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HIER_DIR="$REPO_ROOT/vgen_project/verigen_out"
UNIFIED_DIR="$REPO_ROOT/vgen_project/unified_outputs"
TB_DIR="$REPO_ROOT/vgen_project/verigen_testbenches/verigen_testbenches"
VGEN_DIR="$REPO_ROOT/vgen_project"

MODE="${1:---cached}"

# ── Colour helpers ────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ── Dependency checks ─────────────────────────────────────────────────────────
check_deps() {
    info "Checking dependencies..."

    if ! command -v iverilog &> /dev/null; then
        error "iverilog not found. Install it:"
        error "  Ubuntu/Debian : sudo apt-get install iverilog"
        error "  macOS         : brew install icarus-verilog"
        exit 1
    fi
    info "iverilog found: $(iverilog -V 2>&1 | head -1)"

    if ! command -v python3 &> /dev/null; then
        error "python3 not found."
        exit 1
    fi
    info "python3 found: $(python3 --version)"
}

# ── GPU check (only needed for regeneration) ──────────────────────────────────
check_gpu() {
    if ! python3 -c "import torch; assert torch.cuda.is_available()" 2>/dev/null; then
        error "CUDA not available. GPU is required for model inference."
        error "For cached-output validation (no GPU), run: bash run_evaluation.sh --cached"
        exit 1
    fi
    info "CUDA available: $(python3 -c 'import torch; print(torch.cuda.get_device_name(0))')"
}

# ── Hierarchical generation ───────────────────────────────────────────────────
regen_hierarchical() {
    local model="$1"
    info "Running hierarchical generation with VeriGen-${model}..."
    python3 "$VGEN_DIR/verigen_runner.py" \
        --model "$model" \
        --output_dir "$HIER_DIR"
    info "Writing integration top modules..."
    python3 "$VGEN_DIR/write_integrations.py" \
        --output_dir "$HIER_DIR/$model"
}

# ── Unified generation ────────────────────────────────────────────────────────
regen_unified() {
    local model="$1"
    info "Running unified generation with VeriGen-${model}..."
    python3 "$VGEN_DIR/run_unified_verigen.py" \
        --model "$model" \
        --output_dir "$UNIFIED_DIR"
}

# ── Evaluate ──────────────────────────────────────────────────────────────────
run_eval() {
    info "Running syntax evaluation..."
    python3 "$REPO_ROOT/evaluate_syntax.py" \
        --hier_dir    "$HIER_DIR" \
        --unified_dir "$UNIFIED_DIR" \
        --tb_dir      "$TB_DIR"
}

# ── Main ──────────────────────────────────────────────────────────────────────
check_deps

case "$MODE" in
    --cached)
        info "Mode: cached-output validation (no GPU required)"
        run_eval
        ;;
    --regen-2b)
        info "Mode: regenerate 2B outputs"
        check_gpu
        regen_hierarchical 2B
        regen_unified 2B
        run_eval
        ;;
    --regen-6b)
        info "Mode: regenerate 6B outputs"
        check_gpu
        regen_hierarchical 6B
        regen_unified 6B
        run_eval
        ;;
    --regen-16b)
        info "Mode: regenerate 16B outputs"
        check_gpu
        regen_hierarchical 16B
        regen_unified 16B
        run_eval
        ;;
    --full-regen)
        info "Mode: full regeneration (2B + 6B + 16B)"
        check_gpu
        for MODEL in 2B 6B 16B; do
            regen_hierarchical "$MODEL"
            regen_unified "$MODEL"
        done
        run_eval
        ;;
    --help | -h)
        grep '^#' "$0" | grep -v '^#!' | sed 's/^# \?//'
        exit 0
        ;;
    *)
        error "Unknown mode: $MODE"
        echo "Usage: bash run_evaluation.sh [--cached | --regen-2b | --regen-6b | --regen-16b | --full-regen]"
        exit 1
        ;;
esac

info "Done."
