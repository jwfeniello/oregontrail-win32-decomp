#!/usr/bin/env python3
"""gen_decomp_dev_report.py — emit a decomp.dev progress report for OTWINRe.

decomp.dev consumes objdiff's report schema, and its integration guide allows
generating that schema "from your own tooling if desired". OTWINRe cannot use
objdiff directly: objdiff compares whole target objects against whole base
objects, while this project's comparison contract is a manifest of individual
function envelopes inside two shipped PE images, with per-operand masks. There
are no target objects to diff.

So the report is assembled from the same three inputs the project's own
five-point cadence uses:

  * the harness results CSV written by harness-match.sh (per-row outcome and
    credit),
  * the two Ghidra function inventories, which supply the WHOLE-PROGRAM
    denominator, and
  * the manifest, which maps each row to the candidate object it was built
    from, giving decomp.dev meaningful per-object units.

**The code measure is INSTRUCTIONS, not bytes.** That is deliberate: it is this
project's stated headline, because the remaining WIP functions are much larger
than the already-closed ones, so function count materially overstates progress.
objdiff's schema has one code measure, so instructions occupy it and the
percentage decomp.dev shows is the instruction percentage. Body bytes are
reported per unit as the data measure so the byte view is not lost.

Credit follows the project's policy exactly and is not recomputed here: a row
counts only if harness-match.sh marked it credited, which already requires the
matcher to report `match`, `expected_status` to be `match`, the implementation
to be `cpp` or `toolchain-lib`, at least one compared byte after masks, and the
row to be reachable from the canonical Product graph.

Usage:
    python3 tools/otmatch/gen_decomp_dev_report.py -o build/report.json
    python3 tools/otmatch/gen_decomp_dev_report.py -o build/report.json --pretty
"""
from __future__ import annotations

import argparse
import csv
import json
import re
from collections import OrderedDict
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]

DEFAULT_RESULTS = REPO / "artifacts/otmatch/vc40/harness-results.csv"
DEFAULT_MANIFEST = REPO / "tools/otmatch/functions.vc40-real-cpp.csv"
DEFAULT_INVENTORIES = [
    REPO / "tools/ghidra/otwin32/output/function_metrics_oregon32_exe.csv",
    REPO / "tools/ghidra/otwin32/output/function_metrics_oregon32_dll.csv",
]

REPORT_VERSION = 2

TRUE = {"true", "1", "yes", "y"}


def parse_addr(value: str) -> int:
    v = (value or "").strip()
    if not v:
        raise ValueError("empty address")
    return int(v, 16) if v.lower().startswith("0x") else int(v)


def unit_name(candidate_object: str, implementation_kind: str, program: str) -> str:
    """Turn a candidate .obj name back into the source path it was built from.

    `src_otwin_app_general_helpers.obj` -> `src/otwin/app/general_helpers`.
    Rows with no object are grouped rather than dropped, so every inventory
    function is represented somewhere and the unit totals still sum to the
    headline.
    """
    obj = (candidate_object or "").strip()
    if obj:
        stem = re.sub(r"\.obj$", "", obj, flags=re.IGNORECASE)
        if stem.startswith("src_otwin_"):
            rest = stem[len("src_otwin_"):]
            head, _, tail = rest.partition("_")
            return f"src/otwin/{head}/{tail}" if tail else f"src/otwin/{head}"
        return stem
    if (implementation_kind or "").strip() == "toolchain-lib":
        return "vc4-runtime"
    return f"{program} (unassigned)"


def percent(matched: int, total: int) -> float:
    return 100.0 if total == 0 else matched / total * 100.0


def measures(code_total: int, code_matched: int, code_complete: int,
             data_total: int, data_matched: int,
             fn_total: int, fn_matched: int, units: int) -> dict:
    """Byte counts are uint64 in the protobuf schema; objdiff quotes them."""
    return {
        "fuzzy_match_percent": percent(code_matched, code_total),
        "total_code": str(code_total),
        "matched_code": str(code_matched),
        "matched_code_percent": percent(code_matched, code_total),
        "complete_code": str(code_complete),
        "complete_code_percent": percent(code_complete, code_total),
        "total_data": str(data_total),
        "matched_data": str(data_matched),
        "matched_data_percent": percent(data_matched, data_total),
        "total_functions": fn_total,
        "matched_functions": fn_matched,
        "matched_functions_percent": percent(fn_matched, fn_total),
        "total_units": units,
    }


def build(results_path: Path, manifest_path: Path, inventories: list[Path],
          with_addresses: bool = True) -> dict:
    inventory: dict[tuple[str, int], dict] = {}
    for path in inventories:
        for row in csv.DictReader(path.open(newline="")):
            inventory[(row["program"], parse_addr(row["original_va"]))] = row
    if not inventory:
        raise SystemExit("ERROR: inventory is empty; the whole-program denominator is required")

    objects: dict[tuple[str, int], str] = {}
    for row in csv.DictReader(manifest_path.open(newline="")):
        objects[(row["program"], parse_addr(row["original_va"]))] = row.get("candidate_object", "")

    results = list(csv.DictReader(results_path.open(newline="")))
    if not results:
        raise SystemExit(f"ERROR: no rows in {results_path}")

    missing = [r for r in results
               if (r["program"], parse_addr(r["original_va"])) not in inventory]
    if missing:
        raise SystemExit(
            f"ERROR: {len(missing)} result rows are absent from the inventory "
            f"(first: {missing[0]['name']}). The denominator would be wrong.")

    units: "OrderedDict[str, list]" = OrderedDict()
    for row in results:
        key = (row["program"], parse_addr(row["original_va"]))
        name = unit_name(objects.get(key, ""), row.get("implementation_kind", ""),
                         row["program"])
        units.setdefault(name, []).append((row, inventory[key]))

    unit_reports = []
    t_code = t_matched = t_complete = 0
    t_data = t_data_matched = 0
    t_fn = t_fn_matched = 0

    for name in sorted(units):
        entries = units[name]
        functions = []
        u_code = u_matched = u_data = u_data_matched = u_fn_matched = 0

        for row, inv in sorted(entries, key=lambda e: e[0]["name"]):
            insns = int(inv["instruction_count"] or 0)
            body = int(inv["body_bytes"] or 0)
            credited = (row.get("credited") or "").strip().lower() in TRUE
            u_code += insns
            u_data += body
            if credited:
                u_matched += insns
                u_data_matched += body
                u_fn_matched += 1

            if credited:
                pct = 100.0
            else:
                # Uncredited rows still show how far the envelope agrees, which
                # is what the queue is worked from. It earns no credit.
                compared = int(row.get("compared_bytes") or 0)
                matched = int(row.get("matched_bytes") or 0)
                pct = percent(matched, compared) if compared else 0.0

            entry = {
                "name": row["name"],
                "size": str(insns),
                "fuzzy_match_percent": pct,
            }
            if with_addresses:
                entry["address"] = str(parse_addr(row["original_va"]))
            # objdiff's function metadata accepts only demangled_name and
            # virtual_address; anything else makes the report unparseable.
            # Program, implementation kind and expected status therefore stay
            # out, and the unit name carries the grouping instead.
            entry["metadata"] = {}
            functions.append(entry)

        complete = u_fn_matched == len(entries) and entries
        u_complete = u_code if complete else 0

        unit_reports.append({
            "name": name,
            "measures": measures(u_code, u_matched, u_complete,
                                 u_data, u_data_matched,
                                 len(entries), u_fn_matched, 1),
            "sections": [{"name": ".text", "metadata": {}}],
            "functions": functions,
            "metadata": {"complete": bool(complete)},
        })

        t_code += u_code
        t_matched += u_matched
        t_complete += u_complete
        t_data += u_data
        t_data_matched += u_data_matched
        t_fn += len(entries)
        t_fn_matched += u_fn_matched

    return {
        "measures": measures(t_code, t_matched, t_complete,
                             t_data, t_data_matched,
                             t_fn, t_fn_matched, len(unit_reports)),
        "units": unit_reports,
        "version": REPORT_VERSION,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-o", "--output", type=Path, default=Path("build/report.json"))
    ap.add_argument("--results", type=Path, default=DEFAULT_RESULTS)
    ap.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    ap.add_argument("--inventory", type=Path, action="append", default=None,
                    help="repeatable; defaults to both Ghidra inventories")
    ap.add_argument("--pretty", action="store_true")
    ap.add_argument("--no-addresses", action="store_true",
                    help="omit original function addresses, the one datum in the "
                         "report not already implied by the published source")
    args = ap.parse_args()

    inventories = args.inventory or DEFAULT_INVENTORIES
    for path in [args.results, args.manifest, *inventories]:
        if not path.is_file():
            raise SystemExit(f"ERROR: missing {path}; run harness-match.sh --build first")

    report = build(args.results, args.manifest, inventories,
                   with_addresses=not args.no_addresses)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(report, indent=2 if args.pretty else None) + "\n")

    m = report["measures"]
    print(f"Wrote {args.output}")
    print(f"  units:        {m['total_units']}")
    print(f"  functions:    {m['matched_functions']}/{m['total_functions']} "
          f"({m['matched_functions_percent']:.2f}%)")
    print(f"  instructions: {m['matched_code']}/{m['total_code']} "
          f"({m['matched_code_percent']:.2f}%)   <- decomp.dev headline")
    print(f"  body bytes:   {m['matched_data']}/{m['total_data']} "
          f"({m['matched_data_percent']:.2f}%)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
