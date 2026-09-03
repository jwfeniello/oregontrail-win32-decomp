# The Oregon Trail (Win32) — matching decompilation

Reconstructed C++ for the 1996 Windows release of *The Oregon Trail*, targeting
`Oregon32.exe` and `OREGON32.DLL`.

"Matching" here means the recovered source, compiled with the original
Microsoft Visual C++ 4.0 toolchain, must reproduce the original function bytes.
A function counts only when the matcher agrees byte-for-byte across its whole
envelope, with relocated operands masked and their identity proven.

This is an unofficial research project. It is not affiliated with, sponsored by,
or endorsed by MECC, The Learning Company, Houghton Mifflin Harcourt, Microsoft,
or any other rights holder.

## Status

**55.70% of the program recovered** — 35,926 of 64,499 instructions.

| Image | Functions | Instructions | Body bytes |
| --- | ---: | ---: | ---: |
| `OREGON32.DLL` | 69/69 (100.00%) | 2,753/2,753 (100.00%) | 7,765/7,765 (100.00%) |
| `Oregon32.exe` | 679/788 (86.17%) | 33,173/61,746 (53.72%) | 104,145/199,963 (52.08%) |
| **Combined** | **748/857 (87.28%)** | **35,926/64,499 (55.70%)** | **111,910/207,728 (53.87%)** |

**Instructions are the headline, not function count.** The functions still
outstanding are much larger than the ones already closed, so a function
percentage materially overstates how much of the program is recovered. The
denominator is the full Ghidra inventory of both shipped images, not a sum of
the manifest's envelopes — it counts everything in the program, including code
nobody has attempted yet.

A function is credited only when all of the following hold: the matcher reports
`match`; the manifest's `expected_status` is `match`, so a matching
work-in-progress earns nothing until its source is reviewed and promoted; the
implementation is C++ or a genuine VC4 library body, never hand-written
assembly; at least one byte is compared after masking; and credited C++ is
reachable from the canonical product graph.

The headline is provisional in one respect worth stating plainly: it measures
normalized code shape, and remains so until every masked operand's identity is
proven in both images. It is not whole-image identity.

`docs/decompilation-metrics.md` defines all of this precisely.

## What is not here

This is a source-only snapshot. Deliberately excluded:

- the game — `Oregon32.exe`, `OREGON32.DLL`, the disc, and every extracted asset;
- Microsoft Visual C++ 4.0, which is required to build and is not redistributable;
- the Ghidra project and the function inventories exported from it;
- the recovery workbench (`src/otwin/_recovery/`), the legacy exact-match
  scaffolding (`src/otwin/_exact/`), the C# asset viewer, and the per-function
  recovery notes.

Consequently **this repository cannot reproduce its own measurement.** The
candidate DLL is linked from the product source *plus* the workbench and
scaffolding trees, and scoring it needs both original images and both Ghidra
inventories. What is published is the finished product source and the matching
contract it is verified against.

Use only external inputs you are legally entitled to possess.

## Layout

| Path | What |
| --- | --- |
| `src/otwin/<subsystem>/` | Recovered source by subsystem — app, audio, graphics, hunt, river, trade, trail |
| `tools/otmatch/` | The manifest, the VC4 candidate build, the byte matcher, and the link anchors |
| `harness.toml`, `harness-match.sh` | Measurement configuration and the scoring driver |
| `docs/decompilation-metrics.md` | How the headline is defined and gated |

`*_notes.cpp` files alongside the product source hold readable documentation of
what a function does; they are not compiled into the candidate.

## The matching contract

`tools/otmatch/functions.vc40-real-cpp.csv` is the authority: 857 rows naming
each function's location in both images, how many bytes to compare, and which
operand bytes are relocated and must therefore be masked.

Masking is not a loophole. Two independently linked images legitimately place
their own globals at different addresses, so an operand pointing at internal
data can never be expected to agree. Identity is demanded exactly where both
sides should name the same *external* thing — an import.

Scoring is performed by `decomp-harness`, a separate matching harness pinned by
revision in `harness-match.sh` so a result always identifies the exact
implementation that produced it. That harness is not currently published, so the
pin will not resolve for outside readers.

## Progress reporting

`build/report.json` is a [decomp.dev](https://decomp.dev) progress report in
objdiff's report schema, uploaded by `.github/workflows/progress.yml`.

objdiff cannot generate it: objdiff diffs whole target objects against whole
base objects, and this project has no target objects — its contract is a
manifest of function envelopes inside two shipped PE images. decomp.dev's
integration guide permits generating its schema from a project's own tooling, so
`tools/otmatch/gen_decomp_dev_report.py` does, joining the matcher results, both
Ghidra inventories, and the manifest. Its output round-trips through objdiff's
own report parser.

Because the measurement cannot run here, the report is committed rather than
built in CI, and refreshed in the same commit as the source it describes. CI
validates its schema and internal consistency before publishing it.

## Evidence policy

Source is reconstructed from the shipped binaries, their disassembly, and
reproducible compiler and linker experiments. Unlicensed original source,
editor or tag databases, and development-project files are not accepted as
evidence, and public availability of such an artifact is not evidence of
permission to use it.

## License

There is no blanket license. See [`LICENSE_SCOPE.md`](LICENSE_SCOPE.md).
