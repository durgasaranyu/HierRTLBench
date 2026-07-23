#!/usr/bin/env python3
"""
evaluate_syntax.py — HierRTLBench Syntax Pass-Rate Evaluator
=============================================================
Checks all generated Verilog files against iverilog and reports syntax
pass rates per model and per module, matching the tables in the paper.

Usage:
    # Validate pre-generated outputs (default paths)
    python evaluate_syntax.py

    # Specify custom paths
    python evaluate_syntax.py \
        --hier_dir    vgen_project/verigen_out \
        --unified_dir vgen_project/unified_outputs \
        --tb_dir      vgen_project/verigen_testbenches/verigen_testbenches \
        --models 2B 6B 16B

    # Validate a single model only
    python evaluate_syntax.py --models 2B
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

# ── Module metadata ───────────────────────────────────────────────────────────
# Maps module short-name (folder) to a human-readable label.
MODULES = [
    ("m01_alu",    "ALU"),
    ("m02_regfile","Register File"),
    ("m03_uart",   "UART TX"),
    ("m04_cpu",    "Multi-Cycle CPU"),
    ("m05_ctrl",   "Control Unit"),
    ("m06_riscv",  "Pipeline CPU"),
    ("m07_cache",  "D-Cache"),
    ("m08_arbiter","Round-Robin Arbiter"),
    ("m09_aes",    "AES-128 Enc"),
    ("m10_sha256", "SHA-256"),
    ("m11_crc32",  "CRC-32"),
    ("m12_fft",    "FFT-8"),
    ("m13_matmul", "MatMul-16"),
    ("m14_sort",   "Bubble Sort"),
]

# Unified output filenames (one .v per module)
UNIFIED_FILES = [
    "m01_alu.v",
    "m02_regfile.v",
    "m03_uart_tx.v",
    "m04_multicycle_cpu.v",
    "m05_control_unit.v",
    "m06_pipeline_cpu.v",
    "m07_dcache.v",
    "m08_round_robin_arb.v",
    "m09_aes128_enc.v",
    "m10_sha256.v",
    "m11_crc32.v",
    "m12_fft8.v",
    "m13_matmul16.v",
    "m14_bubble_sort.v",
]


def check_iverilog() -> bool:
    """Return True if iverilog is available on PATH."""
    try:
        result = subprocess.run(
            ["iverilog", "-V"],
            capture_output=True, text=True
        )
        return result.returncode == 0 or "Icarus Verilog" in (result.stdout + result.stderr)
    except FileNotFoundError:
        return False


def iverilog_check(verilog_files: list[str]) -> tuple[bool, str]:
    """
    Run `iverilog -tnull` on the supplied list of files.
    Returns (passed: bool, stderr: str).
    """
    if not verilog_files:
        return False, "no files"
    cmd = ["iverilog", "-tnull"] + verilog_files
    try:
        result = subprocess.run(
            cmd, capture_output=True, text=True, timeout=30
        )
        passed = result.returncode == 0
        return passed, result.stderr.strip()
    except subprocess.TimeoutExpired:
        return False, "timeout"
    except Exception as exc:
        return False, str(exc)


def collect_hier_files(hier_dir: Path, module_folder: str) -> list[str]:
    """Return all .v files for a hierarchical module directory."""
    mod_path = hier_dir / module_folder
    if not mod_path.exists():
        return []
    return sorted(str(f) for f in mod_path.glob("*.v"))


def collect_unified_file(unified_dir: Path, unified_filename: str) -> list[str]:
    """Return the single .v file for a unified module, or empty list."""
    path = unified_dir / unified_filename
    return [str(path)] if path.exists() else []


def evaluate_model(
    model: str,
    hier_dir: Path,
    unified_dir: Path,
    tb_dir: Path,
    verbose: bool = False,
) -> dict:
    """
    Evaluate syntax pass rates for a single model.
    Returns a dict with keys 'hierarchical' and 'unified',
    each a list of (module_label, passed: bool, error: str).
    """
    results = {"hierarchical": [], "unified": []}

    for idx, (folder, label) in enumerate(MODULES):
        # ── Hierarchical ──────────────────────────────────────────────────────
        h_files = collect_hier_files(hier_dir / model, folder)
        if h_files:
            passed, err = iverilog_check(h_files)
        else:
            passed, err = False, "output directory missing"
        results["hierarchical"].append((label, passed, err))
        if verbose:
            status = "PASS" if passed else "FAIL"
            print(f"  [Hier/{model}/{folder}] {status}" + (f" — {err}" if not passed and err else ""))

        # ── Unified ───────────────────────────────────────────────────────────
        u_file = UNIFIED_FILES[idx]
        u_files = collect_unified_file(unified_dir / model, u_file)
        if u_files:
            passed_u, err_u = iverilog_check(u_files)
        else:
            passed_u, err_u = False, "output file missing"
        results["unified"].append((label, passed_u, err_u))
        if verbose:
            status = "PASS" if passed_u else "FAIL"
            print(f"  [Unif/{model}/{u_file}] {status}" + (f" — {err_u}" if not passed_u and err_u else ""))

    return results


def print_summary(all_results: dict, models: list[str]) -> None:
    """Print a formatted summary table matching the paper."""
    total = len(MODULES)
    header = f"{'Model':<8}  {'Passed':>8}  {'Total':>6}  {'Rate':>8}"
    sep = "-" * len(header)

    for approach in ("hierarchical", "unified"):
        label = "Hierarchical" if approach == "hierarchical" else "Unified"
        print(f"\n{'='*60}")
        print(f"  {label} Generation — Syntax Pass Rate")
        print(f"{'='*60}")
        print(header)
        print(sep)

        for model in models:
            if model not in all_results:
                continue
            rows = all_results[model][approach]
            passed = sum(1 for _, ok, _ in rows if ok)
            rate = passed / total * 100 if total else 0
            print(f"{model:<8}  {passed:>4}/{total:<3}  {total:>6}  {rate:>7.1f}%")

        print(sep)
        print()

    # Per-module breakdown
    print(f"\n{'='*60}")
    print("  Per-Module Breakdown (Hierarchical)")
    print(f"{'='*60}")
    mod_header = f"{'Module':<22}" + "".join(f"  {m:<6}" for m in models)
    print(mod_header)
    print("-" * len(mod_header))
    for i, (_, label) in enumerate(MODULES):
        row = f"{label:<22}"
        for model in models:
            if model not in all_results:
                row += "  ------"
                continue
            _, ok, _ = all_results[model]["hierarchical"][i]
            row += f"  {'PASS' if ok else 'FAIL':<6}"
        print(row)
    print()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="HierRTLBench syntax pass-rate evaluator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--hier_dir",
        default="vgen_project/verigen_out",
        help="Root of hierarchical outputs (default: vgen_project/verigen_out)",
    )
    parser.add_argument(
        "--unified_dir",
        default="vgen_project/unified_outputs",
        help="Root of unified outputs (default: vgen_project/unified_outputs)",
    )
    parser.add_argument(
        "--tb_dir",
        default="vgen_project/verigen_testbenches/verigen_testbenches",
        help="Root of testbench directory (not used for syntax-only checks, reserved for future use)",
    )
    parser.add_argument(
        "--models",
        nargs="+",
        default=["2B", "6B", "16B"],
        choices=["2B", "6B", "16B"],
        metavar="MODEL",
        help="Model sizes to evaluate (default: 2B 6B 16B)",
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Print per-file pass/fail details",
    )
    args = parser.parse_args()

    # ── Dependency check ──────────────────────────────────────────────────────
    if not check_iverilog():
        print("ERROR: iverilog not found on PATH.", file=sys.stderr)
        print("  Ubuntu/Debian : sudo apt-get install iverilog", file=sys.stderr)
        print("  macOS         : brew install icarus-verilog", file=sys.stderr)
        sys.exit(1)

    hier_dir    = Path(args.hier_dir)
    unified_dir = Path(args.unified_dir)
    tb_dir      = Path(args.tb_dir)

    all_results: dict = {}

    for model in args.models:
        print(f"\nEvaluating model: {model} ...")
        all_results[model] = evaluate_model(
            model, hier_dir, unified_dir, tb_dir, verbose=args.verbose
        )

    print_summary(all_results, args.models)

    # ── Exit code: 0 if all hier results pass (at least one model tested) ─────
    any_pass = any(
        ok
        for model_res in all_results.values()
        for _, ok, _ in model_res["hierarchical"]
    )
    sys.exit(0 if any_pass else 1)


if __name__ == "__main__":
    main()
