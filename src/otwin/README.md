# OTWIN32 Recovered Sources

This tree holds source-level recovery for the Win32 `Oregon32.exe` and
`OREGON32.DLL` binaries. Files are organized by subsystem first.

## Layout

```
src/otwin/
├── app/        application bootstrap, CRT/import wrappers, dialog/UI helpers
├── audio/      MCI MIDI/WAVE helpers, route cue playback, audio device setup
├── graphics/   positioned bitmaps, sprite blitter, raw indexed bitmap drawing
├── hunt/       hunt dialog, sprite lifecycle, projectile + hit handling
├── river/      rafting and river-crossing audio + animation
├── trail/      trail map display, event handlers, journey state, route logic
└── _exact/     byte-matched staging scaffolds that are not semantic source yet
```

## File kinds

- **`<name>.cpp`** — match-candidate C++ that VC4 (32-bit MSVC 4.0) compiles
  into the otmatch DLL for byte-level comparison against the original binary.
  Compiled by [tools/otmatch/build-match-candidates.ps1](../../tools/otmatch/build-match-candidates.ps1).
  Always begins with `#if !defined(_MSC_VER) || !defined(_M_IX86) #error ...`.

- **`<name>_notes.cpp`** — readable, javadoc-style documentation of a recovered
  function or subsystem. Modern-portable C++ (no 32-bit guard) used as
  human-facing reference material. Not compiled by the matching pipeline.

- **`_exact/<subsystem>/<name>.cpp`** — byte-matched staging candidates whose
  readable form does not yet byte-match under VC4, usually because of register
  allocator, scheduling, or branch-shape differences. These are not considered
  meaningful decompilation until a human-readable subsystem rewrite replaces
  them.

- **`_exact/generated/*.cpp`** — mechanical byte-literal bootstrap scaffolds
  generated from inventories. These compile with `/Od`; all other
  match-candidate files compile with `/O1`.

## Adding a new function

1. Find the function's RVA, signature, and behavior via Ghidra dumps under
   `tools/ghidra/otwin32/output/`.
2. Write a match-candidate version under the appropriate subsystem dir as a
   `.cpp` with the 32-bit guard.
3. Optionally add a `_notes.cpp` companion documenting the function's intent.
4. Add a row to [tools/otmatch/functions.vc40-real-cpp.csv](../../tools/otmatch/functions.vc40-real-cpp.csv)
   referencing the exported symbol.
5. Run `tools/otmatch/build-match-candidates.ps1` then `match-functions.ps1`
   to verify the bytes align.

If the readable C++ doesn't byte-match, keep the accepted low-level scaffold in
`_exact/<subsystem>/` and leave the readable companion in that subsystem as a
`_notes.cpp` or trial implementation. Do not mechanically move exact scaffolds
into the subsystem tree; promotion requires a meaningful rewrite that still
byte-matches.

The host-side `otprobe` tool now lives under [tools/otprobe/](../../tools/otprobe/).
