# Decompilation Metrics

The five-point cadence headline is **policy-compliant masked instruction
coverage** across `Oregon32.exe` and `OREGON32.DLL`:

- the VC4 matcher must actually report `match` for the row;
- `expected_status` must be `match`; a matching WIP remains uncredited until
  its source and dependencies are reviewed and promoted;
- `implementation_kind` must be `cpp` or `toolchain-lib`, never `asm`;
- credited `cpp` must be reachable from the canonical Product graph, while a
  credited `toolchain-lib` row must identify a genuine VC4 library body;
- at least one byte must be compared after masks; and
- the numerator is the Ghidra instruction count for fully closed functions.

Function count remains a queue metric, not the headline. The remaining WIP
functions are much larger than the already-closed functions, so function count
materially overstates recovery progress. Masked matches measure normalized
code shape. The headline is provisional until every masked operand's identity
is proven in both images; it is not whole-PE identity.

## Authoritative workflow

Build the VC4 comparison fixtures, write machine-readable matcher results, and
then report progress:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\build-match-candidates.ps1 `
  -Toolchain LegacyMsvc -VcToolsRoot C:\msdev `
  -OutputDirectory artifacts\otmatch\vc40 `
  -DefaultOptimization /Od -SemanticOptimization /O1

powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\match-functions.ps1 `
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

powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\audit-function-masks.ps1 `
  -ManifestPath tools\otmatch\functions.vc40-real-cpp.csv `
  -OriginalPath "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe" `
  -OriginalDllPath "Sample\Oregon Trail CD\OTWIN32\OREGON32.DLL" `
  -ResultsCsvPath artifacts\otmatch\vc40\mask-audit.csv `
  -RequireValidated

powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\report-progress-metrics.ps1 `
  -VerifierResultsPath artifacts\otmatch\vc40\function-match-results.csv `
  -MaskAuditResultsPath artifacts\otmatch\vc40\mask-audit.csv `
  -RequireProductReachability
```

For fast iteration, the pinned WSL harness scores the same candidate set and
reports the Ghidra whole-program denominator. Its dedicated gate reruns both
scorers and checks every row, credit decision, populated instruction count,
and inventory total:

```powershell
bash harness-match.sh

powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\otmatch\test-decomp-harness-parity.ps1
```

The harness CSV is parity telemetry, not an acceptance substitute: only the
schema-4 matcher plus mask audit and metrics reporter bind binary/map
provenance, paired operand validation, Product reachability, and promotion
policy.

Refresh the Ghidra denominators only when function discovery changes:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File tools\ghidra\otwin32\run_function_metrics.ps1
```

The matcher emits schema-v4 results with SHA-256 hashes of the manifest,
original PE, selected candidate PE, and candidate map. The reporter verifies
those hashes against the current files and rejects stale builds/results. It
also rejects missing, duplicate, extra, or inconsistent verifier and mask-audit
rows. It never infers match status from the presence of a manifest row.

The generated mask-audit and Ghidra metric CSVs are content-joined to the
manifest but do not yet carry their own source-image/generator provenance
hashes. Regenerate both inputs for each checkpoint. Binding those artifacts to
their original images and generator revisions remains verification hardening
debt; this is another reason the percentages are provisional.

## Verified 55% checkpoint — 2026-09-02

| Scope | Policy functions | Policy instructions | Policy body bytes |
|---|---:|---:|---:|
| `Oregon32.exe` | 679/788 (86.17%) | 33,173/61,746 (53.72%) | 104,145/199,963 (52.08%) |
| `OREGON32.DLL` | 69/69 (100.00%) | 2,753/2,753 (100.00%) | 7,765/7,765 (100.00%) |
| **Combined** | **748/857 (87.28%)** | **35,926/64,499 (55.70%)** | **111,910/207,728 (53.87%)** |

The final cold gate reports 748 byte matches, 109 expected WIP mismatches, and
zero verifier errors. All 748 matches receive policy credit: 547 are
Product-reachable C++ and 201 are genuine VC4 library bodies. Relative to the
reviewed 50% checkpoint, this session added 22 accepted functions, 3,543
instructions, and 11,623 body bytes.

The original-side mask audit validates all 5,471 ranges and 21,984 masked
bytes across 700 manifest rows. Of those rows, 699 have complete paired operand
shape; the one debt row is an expected WIP and receives no credit. The 689
masked accepted matches plus 59 raw matches comprise the 748 accepted rows.
They compare 92,194 of 113,662 range bytes directly (81.11%) and normalize
21,468 bytes. Import identities are checked on both sides; non-import data and
rel32 target identity remain dossier/manual-review evidence, so the headline
remains provisional.

Checkpoint `final-55pct` passed at commit `da547b2` under recovery-wave run
`20260902T145125285Z-3ef54b16`. The corrected, pinned decomp-harness 0.1.1
independently reports the same 857 row outcomes, credit decisions, and
whole-program instruction totals.

## Historical verified 50% checkpoint — 2026-07-16

| Scope | Policy functions | Policy instructions | Policy body bytes |
|---|---:|---:|---:|
| `Oregon32.exe` | 657/788 (83.38%) | 29,630/61,746 (47.99%) | 92,522/199,963 (46.27%) |
| `OREGON32.DLL` | 69/69 (100.00%) | 2,753/2,753 (100.00%) | 7,765/7,765 (100.00%) |
| **Combined** | **726/857 (84.71%)** | **32,383/64,499 (50.21%)** | **100,287/207,728 (48.28%)** |

At that checkpoint, the matcher reported 727 byte matches, 130 expected WIP
mismatches, and zero verifier errors. One matching WIP remained deliberately
uncredited. The 726 accepted rows comprised 525 Product-reachable C++
functions and 201 genuine original-toolchain library functions. At that
checkpoint, no Product-unreachable C++, ASM, WIP, or zero-byte comparison
contributed to the score.

Relative to the reviewed 45% checkpoint, policy coverage gained 254 rows,
3,271 instructions, and 11,317 body bytes. The closing wave promoted readable
hunt outcome/spawn/paint logic, weather advancement, menu state, and river raft
animation. `OtPaintHuntResultsText` supplied the final 483 instructions with an
exact 1,428-byte VC4 body. Near matches such as `OtTrailDivideDialogProc`
remained honest WIPs rather than using ASM, `volatile`, fake dependencies, or
invalid register masks.

The strict original-side mask audit validated all 4,774 ranges and all 19,196
masked bytes across 685 masked manifest rows. There were zero partial or
unexplained ranges and no full-function masks. Schema-4 paired validation
rejected one WIP row's candidate operand shape, so it received no credit.
Across the 727 actual matcher matches, 82,796 of 101,552 accepted range bytes
were compared directly (81.53%); the other 18,756 bytes were normalized
address/control operands. This proved complete paired operand shape and import
identity only; non-import data and rel32 target identity still required review,
so that headline remained provisional.

## Five-point cadence

Each five percentage points is approximately 3,225 of the 64,499 discovered
instructions. Integer checkpoints use `ceil(total * percent / 100)`.

| Checkpoint | Required instructions | Additional from current score |
|---:|---:|---:|
| 45% | 29,025 | reached by 6,901 |
| 50% | 32,250 | reached by 3,676 |
| 55% | 35,475 | reached by 451 |
| 60% | 38,700 | 2,774 |

The 55% gate is complete. The next target requires 2,774 additional accepted
instructions.

At every provisional masked checkpoint, pause for a clean VC4 rebuild, fresh
schema-v4 matcher results, zero unexpected matcher regressions/errors, mask and
ASM review, per-program metrics, asset hygiene, whole-PE product-target
comparison where available, documentation cleanup, and a deliberate commit.

## Separate whole-binary gate

Function coverage cannot prove a 1:1 binary. Product targets are verified
separately through PE header and section contracts, ordered imports, raw
resource identity, per-section byte diffs, whole-file byte diffs, and final
SHA-256 equality. Masks are never used for the final whole-file gate.

At this checkpoint the canonical pure-C++/no-ASM EXE graph links under VC4
without `/FORCE`, using 250 Product objects plus one synthetic CRT anchor, zero
recovery objects, and zero unresolved references. This establishes strict
symbol closure only: the synthetic `WinMain` returns zero, so the image is not
a runnable or complete reconstruction. The candidate is 3,995,648 bytes versus
the original's 3,994,624 and matches 1,160,564 compared positions (29.045702%);
`.text` matches only 8,763/231,936 positions (3.778197%). Its SHA-256 differs,
its section layout differs, and its import order differs.

The independently rebuilt DLL product-WIP is 23,601,152 bytes and matches
23,599,012 positions (99.990933%). That image is overwhelmingly resource data;
its result is a useful reconstruction diagnostic, not a recovered-source
completion score. A fresh VC4 link can shift timestamp bytes, while final 1:1
acceptance requires exact bytes and equal SHA-256 with no masks.
