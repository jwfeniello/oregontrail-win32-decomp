# License scope and third-party notice

This repository is not distributed under a single blanket license.

## Project-authored material

A license applies only to a file that carries an explicit SPDX license
identifier or is listed in a file-specific license manifest. No file is
licensed merely because it appears in this repository.

Eligible project-authored material may include independently written build and
matching automation, analysis utilities and tests, repository maintenance
tools, and original documentation. Any license grant applies only to material
owned by the named author or contributor. Third-party dependencies remain under
their respective licenses.

## Reconstructed and target-derived material

Unless a file explicitly states otherwise, no license is granted by this
project for:

- reconstructed or decompiled target-program source;
- target-derived assembly, symbols, types, constants, strings, tables, or data;
- original executable, debug, SDK, asset, or toolchain files;
- generated exports or files containing material from the target; or
- material carrying a separate third-party notice.

This includes the recovered C++ under `src/otwin/`, the function manifest under
`tools/otmatch/`, and the addresses and sizes reported in `build/report.json`,
all of which are derived from the shipped binaries.

The project makes no claim of ownership over *The Oregon Trail* or other
third-party material and cannot grant permission on behalf of its rights
holders.

## Required external material

Building or verifying anything here requires software this project does not
distribute and cannot license to you:

- the original `Oregon32.exe` and `OREGON32.DLL`;
- Microsoft Visual C++ 4.0.

Obtain and use these only if you are legally entitled to.

## Trademarks and affiliation

This is an unofficial project. It is not affiliated with, sponsored by, or
endorsed by MECC, The Learning Company, Houghton Mifflin Harcourt, Microsoft,
or any other rights holder. All names and marks remain the property of their
respective owners.
