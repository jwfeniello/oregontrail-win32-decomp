# OTWIN Function Matcher

`match-functions.ps1` compares function byte ranges from an original PE file
against a rebuilt candidate PE file. It is intentionally manifest-driven so the
matching contract is explicit and can grow one function at a time.

Original PEs, extracted resources, and licensed VC4 toolchain files are local,
ignored inputs and must never be committed. Accepted decompiled implementations
are readable VC4-compatible C++; ASM, `_emit`, and embedded instruction bytes
are tracked only as cleanup debt and receive no progress credit.

## Manifest Format

CSV columns:

- `name`: working function name shown in reports.
- `program`: original image (`Oregon32.exe` or `OREGON32.DLL`).
- `original_va` or `original_rva`: original function start.
- `size`: byte count to compare.
- `candidate_va`, `candidate_rva`, or `candidate_symbol`: rebuilt function start.
- `candidate_dll`: comparison fixture (`libc`, `lcmt`, or `dllcrt`).
- `candidate_object`: optional case-insensitive `Lib:Object` qualifier for an
  ambiguous map symbol. Ambiguous unqualified symbols are verifier errors.
- `expected_status`: `match` for accepted rows or `wip` for an intentional
  semantic-recovery mismatch.
- `implementation_kind`: `cpp`, `asm`, or `toolchain-lib`. Policy progress
  counts C++ and original-toolchain library code, never ASM.
- `mask`: optional byte offsets/ranges to ignore, separated by spaces, commas, or semicolons.
- `notes`: free-form context.

If all candidate location columns are blank, the matcher compares the same RVA
in the candidate PE. That is useful once the rebuilt executable is expected to
have the original layout.

`candidate_symbol` requires an MSVC `.map` file supplied with
`-CandidateMapPath`; the map's `Rva+Base` column is used to resolve the rebuilt
symbol to an RVA.

Masks may cover relocation, IAT, or direct-call address operands only. For a
fully masked PE32 HIGHLOW operand that resolves to an original import-address-
table entry, the matcher also requires the candidate field to be a HIGHLOW
relocation resolving to the same DLL plus symbol or ordinal. A mask covering an
entire function is always a verifier error, even with `-AllowMismatches`.

## Usage

Build the current compiled match-candidate PE:

```powershell
powershell -ExecutionPolicy Bypass -File tools\otmatch\build-match-candidates.ps1
```

Real C++ candidate files named `semantic_*.cpp` are compiled with size-oriented
x86 MSVC codegen plus `/arch:IA32`. That avoids newer CMOV-style output for
small branch helpers and is closer to the original executable's code shape.

## Legacy MSVC Compiler Trials

The original Win32 binaries currently point to Microsoft Visual C++ 4.0-era
tooling. Do not commit old compiler files into this repo; install a licensed
copy locally or inside a VM and point the matcher at that installation.

If the installation uses a standard `MSDEV`/`VC` layout, build a separate
candidate set with:

```powershell
powershell -ExecutionPolicy Bypass -File tools\otmatch\build-match-candidates.ps1 `
  -Toolchain LegacyMsvc `
  -VcToolsRoot C:\MSDEV `
  -OutputDirectory artifacts\otmatch\vc40
```

If the layout differs, pass the tools explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File tools\otmatch\build-match-candidates.ps1 `
  -Toolchain LegacyMsvc `
  -ClPath C:\MSDEV\BIN\CL.EXE `
  -LinkPath C:\MSDEV\BIN\LINK.EXE `
  -IncludePath C:\MSDEV\INCLUDE `
  -LibPath C:\MSDEV\LIB `
  -OutputDirectory artifacts\otmatch\vc40
```

### Content-addressed candidate builds

Candidate objects and link outputs are incremental by default. Object keys bind
the source and transitive include contents, effective compiler flags and include
search order, forced includes, and the compiler/toolchain fingerprint. Link
keys bind ordered object contents, linker flags/toolchain, libraries and other
resolved link inputs, and every required output hash. A cache hit therefore
means content equivalence, not merely an older timestamp.

VC4 COFF timestamps are canonicalized before objects are published. Cache
entries and current link outputs are SHA-256 revalidated before reuse; indirect
dependency modes that cannot be modeled safely, such as response-file or PCH
inputs, bypass reuse.

Use a stable output directory during a shaping lane. The normal build safely
detects every changed source/header; `-ChangedSource` additionally forces a
known TU and is useful for a variant runner:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\build-match-candidates.ps1 `
  -Toolchain LegacyMsvc -VcToolsRoot C:\MSDEV `
  -OutputDirectory artifacts\otmatch\sessions\55pct\lanes\trail\vc40 `
  -DefaultOptimization /Od -SemanticOptimization /O1 `
  -ChangedSource src\otwin\trail\trail_viewport_route_strip.cpp
```

`-Rebuild` recompiles and relinks everything while repopulating the cache.
`-CleanObjectCache` first removes only a marker-owned cache beneath the
repository and then performs that rebuild. `-DisableIncrementalCache` bypasses
reuse and publication without deleting it. Override `-ObjectCacheDirectory` to
isolate an experiment; the default shared cache is
`artifacts\otmatch\.candidate-cache`.

Candidate `-OutputDirectory` is accepted only below a Git-ignored repository
`a/` or `artifacts/` root and cannot traverse an existing reparse point. This
guard applies before output creation or stale-output removal.

Normal candidate builds take a shared graph lock and may run concurrently when
their output directories differ. Source-shape plans take the exclusive graph
lock across source mutation, incremental build, byte diff, restoration, and the
final rebuild. Mutable variant sessions are therefore serialized.

Inspect the live exclusive lock without changing it:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\get-candidate-graph-lock-status.ps1
```

The default report shows lock state, owner, active `-PlanPath`, and process age.
Add `-AsJson` for machine-readable output or `-LockPath <path>` for a contract
fixture. A persistent lock file is not itself a held lock; this helper probes
the file handle and may conservatively report an unresolved owner.

The cache and variant-runner contract is asset-free:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\test-build-cache-contract.ps1
```

Then compare the VC4-specific real-C++ manifest against the legacy-built
candidate:

```powershell
powershell -ExecutionPolicy Bypass -File tools\otmatch\match-functions.ps1 `
  -ManifestPath tools\otmatch\functions.vc40-real-cpp.csv `
  -OriginalPath "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe" `
  -OriginalDllPath "Sample\Oregon Trail CD\OTWIN32\OREGON32.DLL" `
  -CandidatePath artifacts\otmatch\vc40\otwin-match-candidates.dll `
  -CandidateMapPath artifacts\otmatch\vc40\otwin-match-candidates.map `
  -CandidateLcmtPath artifacts\otmatch\vc40\otwin-match-candidates-lcmt.dll `
  -CandidateLcmtMapPath artifacts\otmatch\vc40\otwin-match-candidates-lcmt.map `
  -CandidateDllcrtPath artifacts\otmatch\vc40\otwin-match-candidates-dllcrt.dll `
  -CandidateDllcrtMapPath artifacts\otmatch\vc40\otwin-match-candidates-dllcrt.map `
  -ResultsCsvPath artifacts\otmatch\vc40\function-match-results.csv `
  -SummaryOnly
```

The results CSV is the machine-readable source of truth. Expected-WIP
mismatches are reported as `allowed_wip`; an expected-WIP row that closes is
`promotion_ready`. Errors and unexpected regressions fail the normal command.
`-AllowMismatches` remains only for legacy exploratory manifests and never
suppresses verifier errors.

A masked import-identity failure is a real mismatch, not a parser error. Its
diagnostic is recorded in `masked_import_identity_error`, and an accepted row
therefore becomes a failing `regression`; an expected-WIP row remains WIP and
cannot become `promotion_ready` until the import target agrees.

Metadata-aware results use schema version 4. Every row records the SHA-256 of
the manifest, original PE, selected candidate PE, and candidate map, plus the
exact manifest locator/mask metadata used for the comparison. Schema 4 also
requires complete same-offset operand shapes in both original and candidate
for every mask, plus masked-import identity diagnostics. Older results cannot
retain coverage credit. Non-import HIGHLOW/data and rel32 target identity remain
explicit review items. Re-run the matcher after rebuilding a fixture
or editing the manifest. The progress
reporter hashes the files currently on disk and rejects stale or inconsistent
results.

Run the self-contained matcher contract regression suite (it uses the current
PowerShell PE plus generated minimal PE32 import fixtures and needs no game
assets):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\test-verification-contract.ps1
```

Audit every manifest mask against the original PE relocation table and direct
`rel32` control-transfer operands:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\audit-function-masks.ps1 `
  -ManifestPath tools\otmatch\functions.vc40-real-cpp.csv `
  -OriginalPath "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe" `
  -OriginalDllPath "Sample\Oregon Trail CD\OTWIN32\OREGON32.DLL" `
  -ResultsCsvPath artifacts\otmatch\vc40\mask-audit.csv `
  -RequireValidated
```

HIGHLOW entries are authoritative evidence that the original field is a loader
relocation. Direct-call and branch evidence is a conservative byte-pattern
scan, not an instruction decoder, so partial ranges remain review debt and
opcode-looking data can produce false positives. The audit currently examines
the original image only. During byte matching, paired HIGHLOW import operands
receive the additional DLL-and-symbol/ordinal identity check described above;
rel32 targets and non-import data-object identity are not yet proven. The CSV
preserves these limits. `-RequireValidated` turns any partial or unexplained
range into a failing shape check. Full-function masks are rejected by both the
matcher and this audit.

`functions.real-cpp.csv` remains the modern-MSVC focused manifest. Use
`functions.vc40-real-cpp.csv` for accepted matches produced by the Visual C++
4.0-era toolchain.

## Product-WIP images and whole-PE comparison

The function candidate DLL proves individual code shapes, but it is not the
game executable. The VC4 product-WIP targets distinguish a linkable DLL from
the strictly linkable but still-incomplete pure-C++ EXE graph. Their `.res`
inputs must live outside the repository or under an ignored path:

```powershell
# Regenerate ignored resource inputs in original physical payload order.
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otresdump\dump-otwin32.ps1 -PreserveResourceOrder

# Minimal OREGON32.DLL product target.
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\build-vc4-products.ps1 `
  -Target Oregon32Dll -VcToolsRoot C:\MSDEV

powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\compare-pe-images.ps1 `
  -OriginalPath "Sample\Oregon Trail CD\OTWIN32\OREGON32.DLL" `
  -CandidatePath artifacts\otmatch\vc4-products\OREGON32-DLL-product-wip.dll `
  -ResultsJsonPath artifacts\otmatch\vc4-products\oregon32-dll-pe.json `
  -ResultsCsvPath artifacts\otmatch\vc4-products\oregon32-dll-pe.csv

# Strict no-ASM EXE graph check from fresh VC4 candidate objects.
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\build-vc4-products.ps1 `
  -Target Oregon32Exe -ExeGraph Product -VcToolsRoot C:\MSDEV

# Optional forced-link diagnostic for investigating a future closure regression
# or the non-canonical exhaustive graph. Never run this output.
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\build-vc4-products.ps1 `
  -Target Oregon32Exe -VcToolsRoot C:\MSDEV `
  -CandidateObjectDirectory artifacts\otmatch\vc40 `
  -AllowUnresolvedDiagnostic
```

The canonical EXE target deliberately uses a synthetic `WinMain` that returns
zero. Its explicit 225-source Product manifest excludes all recovery and
`_exact` translation units, and the source-policy audit rejects `__asm`,
`_asm`, and `_emit` tokens throughout every quoted local-include closure. The
policy audit also rejects null/trivial dependencies, `volatile` shaping, and
compiler-entropy markers such as translation-unit context predecessors or
`/d2` switches. The strict default links without `/FORCE`, removes partial
outputs on failure, and
writes a provenance-rich `.link-closure.json` report beside the image.
`-AllowUnresolvedDiagnostic` remains available for closure regressions and the
non-canonical exhaustive graph; it passes `/FORCE:UNRESOLVED` and writes a
separately named diagnostic that must never be run or treated as a product.
The script also checks that in-repo resources and output directories are
ignored and rejects stale candidate objects.

Measure an emitted image—headers, ordered sections, raw bytes, hashes, and
ordered imports—and write stable machine-readable results:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\compare-pe-images.ps1 `
  -OriginalPath "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe" `
  -CandidatePath artifacts\otmatch\vc4-products\Oregon32-EXE-product-wip.exe `
  -ResultsJsonPath artifacts\otmatch\vc4-products\Oregon32-EXE-product-wip.compare.json `
  -ResultsCsvPath artifacts\otmatch\vc4-products\Oregon32-EXE-product-wip.compare.csv
```

The report includes whole-file and per-section matching-byte percentages.
Differences are informational by default while recovery is in progress;
`-RequireExact` makes any whole-file difference fail the command.

Current checkpoint outcomes are deliberately asymmetric. The DLL product-WIP
links and has 23,599,012/23,601,152 matching whole-file positions
(99.990933%), though it is resource-dominated and is not a recovered-source
completion claim. The canonical pure-C++/no-ASM EXE graph now links under VC4
without `/FORCE`: 250 Product objects plus one synthetic CRT anchor, zero
recovery objects, and zero unresolved references. It is still not a runnable
game because the synthetic `WinMain` immediately returns zero. The candidate
is 3,995,648 bytes versus the original's 3,994,624 bytes; raw positional
comparison finds 1,160,564 of 3,995,648 compared positions (29.045702%)
matching overall and 8,763 of 231,936 bytes (3.778197%) in `.text`. These
layout-sensitive figures
establish neither semantic completion nor byte identity. The whole-file count
can vary by a few bytes between fresh links because the VC4 linker stamps the
PE.

Generate a `reccmp` sidecar report for the VC4 candidate after the normal
candidate build:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\run-reccmp-report.ps1 `
  -ReccmpPath C:\path\to\reccmp-reccmp.exe
```

The helper reads `functions.vc40-real-cpp.csv`, emits temporary
`SYNTHETIC ... symbol` annotations for manifest rows whose candidate symbols
exist in the VC4 `.map`, and writes `otmatch-reccmp-report.html`,
`otmatch-reccmp-report.json`, and a selection CSV under
`artifacts\otmatch\vc40\reccmp\`. `reccmp` is optional analysis tooling; keep
`match-functions.ps1` as the authoritative byte-match result. The JSON report
uses `reccmp`'s compact `--json-diet` mode by default because the HTML carries
the per-function diffs; pass `-FullJson` when a machine-readable full diff is
needed. Use `-OnlyWip` or `-Limit <n>` to produce a smaller diagnostic report
while iterating.

The legacy mode intentionally uses older-compatible compiler flags and omits
modern-only switches such as `/GS-` and `/arch:IA32`. Use
`-DefaultOptimization`, `-SemanticOptimization`, `-ExtraCompileFlags`, and
`-ExtraLinkFlags` for controlled per-trial experiments. Keep match-candidate
source compatible with pre-C++11 MSVC syntax so the same files can be tested
against both modern and legacy compilers.

Regenerate the byte-literal `<=20` instruction bootstrap candidates from the
Ghidra inventory:

```powershell
powershell -ExecutionPolicy Bypass -File tools\otmatch\generate-small-function-candidates.ps1
```

The generated small-function candidates are a mechanical inventory/bootstrap,
not accepted reconstruction source. Real C++ replacements live under
`src/otwin/<subsystem>/` (match-candidate form) and `*_notes.cpp`
(documentation form), with byte-identical-but-ugly staging fallbacks kept in
`src/otwin/_exact/<subsystem>/` until a meaningful rewrite byte-matches.

Match the full generated `<=20` instruction set:

```powershell
powershell -ExecutionPolicy Bypass -File tools\otmatch\match-functions.ps1 `
  -ManifestPath tools\otmatch\functions.small-le20.csv `
  -OriginalPath "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe" `
  -CandidatePath artifacts\otmatch\otwin-match-candidates.dll `
  -CandidateMapPath artifacts\otmatch\otwin-match-candidates.map `
  -SummaryOnly
```

Compare the tracked matched-function manifest against that candidate:

```powershell
powershell -ExecutionPolicy Bypass -File tools\otmatch\match-functions.ps1 `
  -ManifestPath tools\otmatch\functions.csv `
  -OriginalPath "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe" `
  -CandidatePath artifacts\otmatch\otwin-match-candidates.dll `
  -CandidateMapPath artifacts\otmatch\otwin-match-candidates.map
```

Compare only the real-C++ small-function candidates:

```powershell
powershell -ExecutionPolicy Bypass -File tools\otmatch\match-functions.ps1 `
  -ManifestPath tools\otmatch\functions.real-cpp.csv `
  -OriginalPath "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe" `
  -CandidatePath artifacts\otmatch\otwin-match-candidates.dll `
  -CandidateMapPath artifacts\otmatch\otwin-match-candidates.map
```

Show the byte diff plus `dumpbin` disassembly context for one candidate symbol:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\diff-symbol-disasm.ps1 `
  -OriginalPath "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe" `
  -OriginalRva 0x<rva> -Size <size> `
  -CandidatePath artifacts\otmatch\vc40\otwin-match-candidates.dll `
  -CandidateMapPath artifacts\otmatch\vc40\otwin-match-candidates.map `
  -CandidateSymbol _SymbolName `
  -ResultsJsonPath artifacts\otmatch\vc40\symbol-instruction-shape.json `
  -SummaryOnly
```

This helper runs `diff-symbol-bytes.ps1` first as the authoritative raw focused
comparison, then uses VC4 `dumpbin /DISASM` to classify instruction alignment,
paired same-offset address operands, and structural mismatch islands. It
auto-resolves the candidate `.obj` from the MSVC map file when possible.
`-ResultsJsonPath` retains the input hashes, raw offsets and child-diff output,
instructions, alignment, and islands as schema-1 diagnostic evidence;
`-SummaryOnly` shortens only the console. Normalized instruction shape grants
zero acceptance credit and never changes a raw difference count. The schema-4
`match-functions.ps1` result remains the full acceptance authority.

Exercise the parser, address-pairing, raw-evidence, output-safety, and
fail-closed coverage rules without original assets:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\test-diff-symbol-disasm-contract.ps1
```

## WIP Residual Prioritization

After the recovery-wave matcher, mask/Product audits, and metrics summary have
passed against the same candidate, build the recovery queue from every
fail-closed `expected_status=wip` row:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\scan-wip-residuals.ps1 `
  -Top 40
```

This writes `artifacts\otmatch\vc40\wip-residual-dashboard.csv` and `.md`.
The scanner requires current schema-4 verifier provenance and the same
checkpoint's schema-2 `progress-metrics-summary.json`. It validates the
summary's manifest, verifier, mask-audit, Product-source, metrics-input, and
reporter hashes, then uses its strict coverage denominator rather than
reimplementing milestone policy. It joins each WIP row to Ghidra instruction
counts and Product reachability, computes mask-aware hard residuals, and ranks
by `(instruction yield × confidence) / effort`. Accepted rows cannot enter
through note wording. `-NotesPattern` can only narrow the WIP set. Frozen,
verifier-blocked, non-policy, zero-yield, and Product-unreachable rows remain
diagnostic but cannot contribute to the portfolio target.

After the current scan emits ledger templates, use
`carry-forward-recovery-ledgers.ps1` when a prior checkpoint has reviewed
ledgers. The helper binds both dashboards and both ledger generations, carries
only reproduced unchanged readiness decisions and stable paused/frozen/closed
lane states, and emits `readiness-ledger.json`, `session-lane-ledger.json`, plus
a JSON/Markdown audit. Drifted or active rows retain the current fail-closed
template values; inspect the audit before supplying the outputs back to the
scanner. The output directory must be new, nonexistent, and ignored; the four
files publish as one directory rename, and `-Force` is rejected. Exercise this
boundary without VC4 or original assets with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\test-carry-forward-recovery-ledgers-contract.ps1
```

The automatic portfolio target is 150% of the instruction deficit to the next
five-point checkpoint. Rows in `frozen-wip.csv` remain visible but cannot enter
the portfolio until their evidence-based revisit condition is satisfied. A
frozen entry records its freeze date and binds evidence/source paths and hashes,
the baseline original hash, schema-4 mask-aware per-function candidate hash,
in `baseline_candidate_function_sha256`, `strict-linked`
hard-difference/compared-byte counts, and at least eight meaningful variants.
Evidence/source, original, function-hash, or residual drift--or a
promotion-ready result--fails closed. `baseline_candidate_sha256` remains
historical whole-file provenance/diagnostic context only; it may change when
unrelated functions are promoted. Use
`-PortfolioTargetInstructions` only to raise the normal target. Reducing the
five-point/1.5x policy requires the explicit diagnostic-only
`-AllowNonstandardPortfolioPolicy` switch. A missing frozen ledger or a viable
queue that falls short of the target is a failure;
`-DisableFrozenWip` and `-AllowPortfolioShortfall` are explicit diagnostic-only
overrides. Dashboard output is restricted to Git-ignored repository `a/` or
`artifacts/` paths with no existing reparse-point ancestor. The CSV and
Markdown are each replaced atomically after input validation, but are not a
transactional pair; a write/process failure can leave versions from different
runs. The deliberate shortfall failure occurs after both files are written and
retains them for planning. Verify the ranking/frozen/provenance contract with:

Use `refresh-recovery-session.ps1` after each promotion boundary to regenerate
the matcher, mask audit, metrics, and dashboard together. Pass
`-SerialPortfolio` for a single autonomous worker; this replaces paired
assignments with a ranked queue without bypassing readiness or target coverage.
Add `-Build` to update candidate artifacts first and `-Build -Rebuild` only at
a clean baseline boundary.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\test-wip-queue-contract.ps1
```

When a WIP row may already have a better semantic implementation elsewhere in
the candidate graph, sweep the linker map before starting a new source-shaping
lane:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\find-wip-alternate-candidates.ps1 `
  -CandidatePath artifacts\otmatch\vc40\otwin-match-candidates.dll `
  -CandidateMapPath artifacts\otmatch\vc40\otwin-match-candidates.map
```

The sweep reads function symbols from every linker code segment (including the
Product `.otsem` segment), and uses both the manifest identity and its selected
`candidate_symbol` when matching generic `FUN_...` rows. Verify those discovery
contracts without requiring original binaries or a VC4 build with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\find-wip-alternate-candidates.ps1 -SelfTest
```

For repeatable source-shaping trials, first write only the policy-clean variant
specification. Batch four to eight meaningful hypotheses so the graph setup and
restoration costs are amortized; do not pad a batch with spelling-only changes:

```json
{
  "schemaVersion": 1,
  "variants": [
    {
      "name": "owner-before-count",
      "hypothesis": "Declaration order controls VC4 register allocation.",
      "meaningful": true,
      "replacements": [
        { "old": "existing source text", "new": "first trial text" }
      ]
    },
    {
      "name": "count-before-owner",
      "hypothesis": "The alternate lifetime order changes the scheduling island.",
      "meaningful": true,
      "replacements": [
        { "old": "existing source text", "new": "second trial text" }
      ]
    }
  ]
}
```

The example abbreviates the batch; add two to six more evidence-driven variants.
Generate the executable plan from the current manifest row and exact source
snapshot rather than hand-copying RVA, size, symbol, mask, or source hashes:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\new-source-shape-plan.ps1 `
  -Program Oregon32.exe `
  -FunctionName OtUpdateTrailViewportRouteStripState `
  -SourcePath src\otwin\trail\trail_viewport_route_strip.cpp `
  -CheckpointId wave-1000 `
  -PriorBoundaryRunId <run_id-from-prior-passed-boundary> `
  -VariantSpecPath artifacts\otmatch\sessions\55pct\lanes\trail\variant-spec.json `
  -OutputPath artifacts\otmatch\sessions\55pct\lanes\trail\source-shape-plan.json
```

The generator resolves exactly one manifest identity and emits a schema-1 plan
bound to the generator, manifest, candidate object, source bytes, and exact
one-occurrence replacement anchors. Its output must be an ignored `.json` below
`a/` or `artifacts/`. `-OriginalRva` may replace or accompany `-FunctionName`;
`-SourcePath` can be omitted when `candidate_object` maps uniquely. For a single
replacement, use the direct `-VariantName`, `-Hypothesis`, `-OldText`, and
`-NewText` parameters instead of `-VariantSpecPath`. Add `-Force` only when
intentionally regenerating the same output path.

Run the generated plan with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\invoke-source-shape-variants.ps1 `
  -PlanPath artifacts\otmatch\sessions\55pct\lanes\trail\source-shape-plan.json `
  -BuildOutputDirectory artifacts\otmatch\sessions\55pct\lanes\trail\vc40 `
  -ResultCsvPath artifacts\otmatch\sessions\55pct\lanes\trail\focused-results.csv `
  -WarmBaselineProofPath artifacts\otmatch\sessions\55pct\lanes\trail\warm-baseline.json `
  -StopLossMinutes 45 -MaxNoImprovementVariants 8 `
  -MaximumFocusedBuildSeconds 15 -MaximumFocusedDiffSeconds 30
```

After taking the exclusive graph lock, the runner automatically reruns generated
plan preflight before deleting old evidence or starting a build. Manifest,
generator, source, or anchor drift therefore fails closed and requires a newly
generated plan. It then snapshots the source file, validates the candidate
graph, and applies one variant at a time. Each trial compiles only the changed
TU, reuses validated untouched objects, conditionally relinks only the main
candidate, diffs the selected symbol, and checkpoints the complete record to
CSV. Interactive output is intentionally compact; the durable CSV retains the
full hypothesis, symbol/RVA, raw and hard offset lists, hashes, and timings.
The batch also stops after the first focused build over 15 seconds or focused
diff over 30 seconds by default. That completed result is retained and source,
object, candidate, and map restoration still run. The evidence JSON includes a
`run_summary` with focused setup, baseline diff, variant loop, per-trial
tool/wall, restoration, runner elapsed, separate latency flags, and stop-reason
telemetry. It does not claim to measure manual review or dossier preparation.

`-WarmBaselineProofPath` is optional. When the named ignored `.json` does not
exist, the cold setup performs three build calls--the normal seed and two
fixed-point relinks--and publishes the proof only after successful non-trusting
restoration. A subsequent run with the same source, configuration, graph state,
outputs, runner/build scripts, and originals validates those bindings and uses
one non-trusting focused setup call. The asset-free contract measured three cold
setup calls versus one warm call. A corrupt or stale existing proof fails
closed; it never silently falls back to cold setup. After an intentional source
or configuration boundary change, archive/remove the ignored proof or select a
new proof path, then allow a cold run to publish the replacement.

A `finally` block restores the exact source bytes and performs the non-trusting
focused validation. The boundary requires the exact restored object hash and
canonical DLL/map content; only documented VC4 linker timestamp fields and the
three reserved bytes of validated `IMAGE_DEBUG_MISC` records are normalized.
Use `-NoRestoreBuild` only for disposable diagnostics, never promotion evidence.
Use `-Exploration` for restoring, diagnostic-only hypothesis batches. Its
evidence is never promotion eligible; rerun a successful spelling normally.
`export-source-shape-patterns.ps1` exports retained successful and failed
hypotheses to a CSV corpus for future dossier review.
By default the runner replaces the result CSV's extension with `.evidence.json`
(for example, `focused-results.csv` produces
`focused-results.evidence.json`). That schema-1 artifact binds the exact
identity/checkpoint/source, current runner provenance, a selected trial, and the
restoration boundary. Promotion requires a meaningful trial with a nonblank
hypothesis and zero hard residual, plus passing non-trusting
source/object/canonical-DLL/map restoration. The CSV, warm proof, and
instruction-shape JSON remain diagnostic/support artifacts, not promotion
evidence.

Exercise generated-plan/preflight/lock safety and cold-versus-warm runner
behavior without VC4 or original assets:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\test-source-shape-plan-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\test-source-shape-warm-baseline-contract.ps1
```

Before promotion, regenerate `generate-function-dossier.ps1` output against the
current accepted schema-4 verifier result and current metrics/binaries. The
generated schema-1 JSON starts with a pending, fail-closed `promotion_review`.
In a reviewed JSON copy, complete every checklist item, bind the current source
path/hash and reviewer/time, add nonblank semantic/type-layout/ABI/mask notes,
and resolve exactly every generated warning. The dossier's current generator
provenance and nested verifier `original_file`, `candidate_file`, and
`candidate_map` path/hash/length records are rehashed by the promotion gate.
The generated Markdown is not promotion evidence.

## Recovery-wave gates

`invoke-recovery-wave.ps1` turns the session playbook into three explicit
phases. It is plan-only by default; `-Execute` is required before any compiler,
matcher, Product build, or test runs. Outputs are isolated by session and named
checkpoint under the ignored `artifacts/` or `a/` roots, and the session ledger
is atomically replaced. Its schema-4 records commands, commit/worktree context,
durations, logs, pass/fail/skip state, and content hashes for gate scripts and
the runner, original and metric inputs, manifest/Product list, VC4
`BIN`/`INCLUDE`/`LIB` and available ATL/MFC payload trees, and the ignored
Product-resource tree. Output roots must be Git-ignored `a/` or `artifacts/`
paths and cannot traverse existing reparse points. An exclusive per-session
lock serializes ledger and checkpoint updates.

```powershell
# Clean, committed session baseline.
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\invoke-recovery-wave.ps1 `
  -Phase baseline -SessionId 55pct-v2 -Execute

# Internal regression/commit boundary after focused row diffs were reviewed.
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\invoke-recovery-wave.ps1 `
  -Phase promotion-wave -SessionId 55pct-v2 -CheckpointId wave-1000 `
  -MinimumInstructionGain 1000 `
  -PromotionEvidencePath artifacts\otmatch\sessions\55pct-v2\wave-1000-evidence.json `
  -Execute

# Five-point checkpoint; a result below 55% fails even if every test passes.
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\invoke-recovery-wave.ps1 `
  -Phase final -SessionId 55pct-v2 -CheckpointId final `
  -MinimumInstructionPercent 55 -Execute
```

Every promotion wave requires a positive instruction gain relative to the
latest passed ancestral boundary. Its schema-1 evidence must list exactly the
newly accepted identities, bind each reviewed schema-1 dossier JSON/current
source/current-runner schema-1 `*.evidence.json` by SHA-256, and affirm
semantic, type/layout, ABI, and mask review through the still-required outer
booleans. The gate also validates the dossier's completed checklist, passed
`promotion_review`, exact warning disposition and current nested binary/map
provenance, plus the focused artifact's identity/boundary/source/symbol,
meaningful zero-hard trial and non-trusting restoration. Markdown, CSV, and
generic JSON cannot satisfy those roles. A final run may use the default zero
gain only when no identities changed since that boundary; new final-run
identities still require `-PromotionEvidencePath`.

Baseline and final use `-Rebuild`; promotion waves reuse the content cache. All
three phases run the complete matcher, strict mask and Product-source audits,
policy metrics, and strict EXE/DLL links. Final adds whole-PE reports, verifier
and tooling contracts, host/Viewer tests, staged/unstaged/conflict audits, and
the original-asset/history boundary check. Executed promotion/final phases
require a successful baseline in the same session ancestry. They reject changed
gate semantics, a changed manifest identity universe or coverage denominator,
and loss of accepted identities/instructions relative to the baseline or latest
passed ancestral checkpoint. Before a would-be successful execution is
accepted, the orchestrator recaptures HEAD plus worktree/index/untracked
content and recomputes the gate/input snapshot; both must exactly equal the
start state.

After baseline, point `scan-wip-residuals.ps1` at that checkpoint's `vc40`
candidate, map, and `function-match-results.csv`; do not combine its verifier
provenance with a candidate from another checkpoint.

Test the plan/ledger safety contract without VC4 or original assets:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\test-recovery-wave-contract.ps1
```

## Progress Metrics

After exporting function metrics from Ghidra, report current coverage by
function, instruction, and body-byte count. The report requires the matcher
results CSV and mask-audit CSV and never treats manifest membership as proof of
a match. Generate both files after the current build/manifest changes before
running this command:

```powershell
powershell -ExecutionPolicy Bypass -File tools\ghidra\otwin32\run_function_metrics.ps1
powershell -ExecutionPolicy Bypass -File tools\otmatch\report-progress-metrics.ps1 `
  -VerifierResultsPath artifacts\otmatch\vc40\function-match-results.csv `
  -MaskAuditResultsPath artifacts\otmatch\vc40\mask-audit.csv `
  -RequireProductReachability `
  -SummaryJsonPath artifacts\otmatch\vc40\progress-metrics-summary.json
```

For an executable milestone gate, also pass
`-RequireInstructionPercent <checkpoint>`. This checks policy-compliant,
Product-reachable instruction coverage—not manifest membership or raw masked
matches—and exits nonzero below the requested percentage.

The primary five-point cadence uses provisional policy-compliant masked
instruction coverage. The report also shows a mask-shape-audited lower bound,
raw matches, ASM debt, mask debt, program splits, and the next three five-point
thresholds. It validates schema-4 hashes against the current manifest,
originals, candidates, and maps, and checks that mask-audit metadata exactly
covers the current manifest masks. Only whole-PE exact comparison is the final
identity gate.

Each Ghidra metrics row must include canonical sorted half-open RVA
`body_ranges`. The reporter rejects missing/malformed, unordered or internally
overlapping ranges, ranges outside the function envelope, an unowned entry RVA,
a union length different from `body_bytes`, or overlap between two functions in
the same program. This makes non-contiguous Ghidra ownership explicit instead
of inferring it from overlapping function envelopes.

The atomically replaced schema-2 summary content-binds the manifest, verifier,
mask audit, Product source list, Ghidra metric CSVs, and metrics reporter. It
also records the ordinal accepted-identity set and strict accepted totals
against a hash-bound denominator, including the canonical body-ownership digest
and total range count. The mask-audit and Ghidra CSV formats do not
themselves bind every upstream source image/generator revision, so regenerate
them for every checkpoint; the summary makes the exact consumed snapshots
auditable without claiming stronger upstream provenance.

`-SummaryJsonPath` is accepted only below a Git-ignored `a/` or `artifacts/`
root with no existing reparse-point ancestor. After destination safety/alias
checks, the reporter deletes any previous summary before report validation. It
parses immutable in-memory byte snapshots and rehashes all consumed inputs
before publishing, so later failure cannot preserve an old green summary at
that path.

Self-check the original binary against itself:

```powershell
powershell -ExecutionPolicy Bypass -File tools\otmatch\match-functions.ps1 `
  -ManifestPath tools\otmatch\functions.example.csv `
  -OriginalPath "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe" `
  -CandidatePath "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe"
```

Compare against a rebuilt PE:

```powershell
powershell -ExecutionPolicy Bypass -File tools\otmatch\match-functions.ps1 `
  -ManifestPath tools\otmatch\functions.csv `
  -OriginalPath "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe" `
  -CandidatePath build\bin\Oregon32.exe `
  -CandidateMapPath build\bin\Oregon32.map
```

For metadata-aware manifests, the script exits nonzero on verifier errors or
unexpected regressions. Declared WIP mismatches do not require
`-AllowMismatches`.
