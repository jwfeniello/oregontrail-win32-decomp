# Extracts forensic identifiers from a PE file's COFF header and optional
# header that fingerprint which toolchain produced it. Useful when the
# Rich header is absent (VC4.x and earlier link.exe didn't emit one).
#
# Fields reported:
#   - TimeDateStamp (COFF header):       link timestamp (Unix epoch)
#   - MajorLinkerVersion / MinorLinkerVersion: linker.exe major/minor
#   - MajorImageVersion / MinorImageVersion:   image version (often 0/0)
#   - MajorSubsystemVersion / MinorSubsystemVersion: required Windows version
#   - Magic (PE32 / PE32+):              0x10b = 32-bit, 0x20b = 64-bit
#   - SizeOfHeaders, FileAlignment, SectionAlignment, ImageBase
#   - DllCharacteristics, Subsystem
#
# Linker version → toolchain reference (Microsoft):
#   2.x   = early Win32 SDK / NT 3.x linker
#   3.00  = VC++ 4.0
#   3.10  = VC++ 4.1
#   4.20  = VC++ 4.2
#   5.10  = VC++ 5.0
#   6.00  = VC++ 6.0
#   7.00+ = VS2002 and later

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Path
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Read-U16([byte[]]$b, [int]$o) {
    return [uint16](([uint64]$b[$o]) -bor (([uint64]$b[$o+1]) -shl 8))
}

function Read-U32([byte[]]$b, [int]$o) {
    return [uint32](([uint64]$b[$o]) -bor (([uint64]$b[$o+1]) -shl 8) -bor (([uint64]$b[$o+2]) -shl 16) -bor (([uint64]$b[$o+3]) -shl 24))
}

foreach ($p in $Path) {
    $resolved = Resolve-Path -LiteralPath $p
    $bytes = [System.IO.File]::ReadAllBytes($resolved.Path)
    $peOff = [int](Read-U32 $bytes 0x3c)

    # COFF header at peOff + 4
    $coff = $peOff + 4
    $machine = Read-U16 $bytes $coff
    $numSections = Read-U16 $bytes ($coff + 2)
    $timestamp = Read-U32 $bytes ($coff + 4)
    $optHdrSize = Read-U16 $bytes ($coff + 16)
    $characteristics = Read-U16 $bytes ($coff + 18)

    # Optional header at coff + 20
    $opt = $coff + 20
    $magic = Read-U16 $bytes $opt
    $majorLinker = $bytes[$opt + 2]
    $minorLinker = $bytes[$opt + 3]
    $imageBase = Read-U32 $bytes ($opt + 28)
    $sectionAlign = Read-U32 $bytes ($opt + 32)
    $fileAlign = Read-U32 $bytes ($opt + 36)
    $majorOsVer = Read-U16 $bytes ($opt + 40)
    $minorOsVer = Read-U16 $bytes ($opt + 42)
    $majorImageVer = Read-U16 $bytes ($opt + 44)
    $minorImageVer = Read-U16 $bytes ($opt + 46)
    $majorSubVer = Read-U16 $bytes ($opt + 48)
    $minorSubVer = Read-U16 $bytes ($opt + 50)
    $sizeOfHdrs = Read-U32 $bytes ($opt + 60)
    $subsystem = Read-U16 $bytes ($opt + 68)
    $dllChar = Read-U16 $bytes ($opt + 70)

    $tsDate = (Get-Date -Date "1970-01-01 00:00:00Z").AddSeconds($timestamp).ToString("yyyy-MM-dd HH:mm:ss UTC")

    Write-Host ("=== {0} ===" -f $resolved.Path) -ForegroundColor Cyan
    Write-Host ("  PE offset:                  0x{0:x}" -f $peOff)
    Write-Host ("  Machine:                    0x{0:x4}  ({1})" -f $machine, $(if ($machine -eq 0x14c) { "i386" } elseif ($machine -eq 0x8664) { "x86_64" } else { "?" }))
    Write-Host ("  Sections:                   {0}" -f $numSections)
    Write-Host ("  TimeDateStamp:              {0}  ({1})" -f $timestamp, $tsDate)
    Write-Host ("  OptHdrSize:                 0x{0:x}" -f $optHdrSize)
    Write-Host ("  Characteristics:            0x{0:x4}" -f $characteristics)
    Write-Host ("  Optional header magic:      0x{0:x4}  ({1})" -f $magic, $(if ($magic -eq 0x10b) { "PE32" } elseif ($magic -eq 0x20b) { "PE32+" } else { "?" }))
    Write-Host ("  LinkerVersion:              {0}.{1:D2}" -f $majorLinker, $minorLinker) -ForegroundColor Yellow
    Write-Host ("  ImageBase:                  0x{0:x8}" -f $imageBase)
    Write-Host ("  SectionAlignment:           0x{0:x}" -f $sectionAlign)
    Write-Host ("  FileAlignment:              0x{0:x}" -f $fileAlign)
    Write-Host ("  OS Version:                 {0}.{1:D2}" -f $majorOsVer, $minorOsVer)
    Write-Host ("  Image Version:              {0}.{1:D2}" -f $majorImageVer, $minorImageVer)
    Write-Host ("  Subsystem Version:          {0}.{1:D2}" -f $majorSubVer, $minorSubVer)
    Write-Host ("  SizeOfHeaders:              0x{0:x}" -f $sizeOfHdrs)
    Write-Host ("  Subsystem:                  0x{0:x4}  ({1})" -f $subsystem, $(switch ($subsystem) { 1 {"native"}; 2 {"Windows GUI"}; 3 {"Windows console"}; default {"?"} }))
    Write-Host ("  DllCharacteristics:         0x{0:x4}" -f $dllChar)
    Write-Host ""
}
