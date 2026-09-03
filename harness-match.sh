#!/usr/bin/env bash
# Fast manifest scoring via the pinned decomp-harness parity implementation.
# The schema-4 matcher and progress reporter remain promotion authority; the
# candidate build is unchanged and still driven by build-match-candidates.ps1.
#
#   bash harness-match.sh                       # score the current candidates
#   bash harness-match.sh --build               # rebuild candidates first
#   MANIFEST=tools/otmatch/functions.coverage-70pct.csv bash harness-match.sh
#
# Two denominators are printed and never merged:
#   * manifest-policy   — of policy-eligible manifest rows, how many agree.
#     Says nothing about how much of the game is recovered.
#   * whole-program     — credited functions over the FULL Ghidra inventory of
#     both shipped images. This is the five-point cadence headline in
#     docs/decompilation-metrics.md.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO"

# Acceptance/parity results must identify the exact harness implementation.
# HARNESS_ALLOW_UNPINNED=1 is intentionally diagnostic-only: it permits local
# harness development while printing the provenance deviation.
HARNESS_VERSION="0.1.1"
HARNESS_REVISION="05b50347bd6b5092a750e66279f92ccaac5afe64"
HARNESS_ROOT="${HARNESS_ROOT:-$REPO/../decomp-harness}"
HARNESS_ALLOW_UNPINNED="${HARNESS_ALLOW_UNPINNED:-0}"

if [[ ! -d "$HARNESS_ROOT/src/decomp_harness" ]] ||
   ! git -C "$HARNESS_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    echo "ERROR: decomp-harness checkout not found at $HARNESS_ROOT" >&2
    echo "       clone it there or set HARNESS_ROOT" >&2
    exit 2
fi

ACTUAL_REVISION="$(git -C "$HARNESS_ROOT" rev-parse HEAD)"
DIRTY_STATE="$(git -C "$HARNESS_ROOT" status --porcelain --untracked-files=normal)"
PIN_PROBLEMS=()
if [[ "$ACTUAL_REVISION" != "$HARNESS_REVISION" ]]; then
    PIN_PROBLEMS+=("revision $ACTUAL_REVISION (expected $HARNESS_REVISION)")
fi
if [[ -n "$DIRTY_STATE" ]]; then
    PIN_PROBLEMS+=("checkout has uncommitted files")
fi
if (( ${#PIN_PROBLEMS[@]} )); then
    if [[ "$HARNESS_ALLOW_UNPINNED" != "1" ]]; then
        printf 'ERROR: unpinned decomp-harness: %s\n' "${PIN_PROBLEMS[@]}" >&2
        echo "       use the pinned clean revision, or set HARNESS_ALLOW_UNPINNED=1 for diagnostics" >&2
        exit 2
    fi
    printf 'WARNING: diagnostic run with unpinned decomp-harness: %s\n' \
        "${PIN_PROBLEMS[@]}" >&2
fi

export PYTHONPATH="$HARNESS_ROOT/src${PYTHONPATH:+:$PYTHONPATH}"
HARNESS=(python3 -m decomp_harness.cli.main)
ACTUAL_VERSION="$("${HARNESS[@]}" --version)"
if [[ "$ACTUAL_VERSION" != "decomp-harness $HARNESS_VERSION" ]]; then
    echo "ERROR: $ACTUAL_VERSION loaded from $HARNESS_ROOT; expected decomp-harness $HARNESS_VERSION" >&2
    exit 2
fi

# The AUTHORITATIVE manifest (857 rows, both programs), per
# docs/decompilation-metrics.md. tools/otmatch/functions.csv is a 19-row legacy
# anchor set on an older schema — a smoke test, not a coverage measurement.
MANIFEST="${MANIFEST:-tools/otmatch/functions.vc40-real-cpp.csv}"
OUT="${OUT:-artifacts/otmatch/vc40}"
HARNESS_RESULTS_CSV="${HARNESS_RESULTS_CSV:-$OUT/harness-results.csv}"
ORIGINAL_EXE="${ORIGINAL_EXE:-Sample/Oregon Trail CD/OTWIN32/Oregon32.exe}"
ORIGINAL_DLL="${ORIGINAL_DLL:-Sample/Oregon Trail CD/OTWIN32/OREGON32.DLL}"
GHIDRA="${GHIDRA:-tools/ghidra/otwin32/output}"

if [[ "${1:-}" == "--build" ]]; then
    # MSVC 4.0 runs through WSL interop; no Wine required.
    powershell.exe -ExecutionPolicy Bypass -NoProfile -Command \
        "cd '$(wslpath -w "$REPO")'; .\\tools\\otmatch\\build-match-candidates.ps1 \
         -Toolchain LegacyMsvc -VcToolsRoot 'C:\\MSDEV' -OutputDirectory '${OUT//\//\\}' \
         -DefaultOptimization /Od -SemanticOptimization /O1"
    shift
fi

exec "${HARNESS[@]}" match-manifest \
    --isa x86-pe \
    --manifest "$MANIFEST" \
    --original "Oregon32.exe=$ORIGINAL_EXE" \
    --original "OREGON32.DLL=$ORIGINAL_DLL" \
    --candidate "=$OUT/otwin-match-candidates.dll,$OUT/otwin-match-candidates.map" \
    --candidate "lcmt=$OUT/otwin-match-candidates-lcmt.dll,$OUT/otwin-match-candidates-lcmt.map" \
    --candidate "dllcrt=$OUT/otwin-match-candidates-dllcrt.dll,$OUT/otwin-match-candidates-dllcrt.map" \
    --inventory "$GHIDRA/function_metrics_oregon32_exe.csv" \
    --inventory "$GHIDRA/function_metrics_oregon32_dll.csv" \
    --allow-unexpected-match \
    --results-csv "$HARNESS_RESULTS_CSV" \
    "$@"
