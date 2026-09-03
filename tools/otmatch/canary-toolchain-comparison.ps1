# Compares the byte output of the same canary .cpp file across multiple
# legacy MSVC toolchains (e.g., VC4.0 / VC4.1 / VC4.2) against an original
# binary. The goal is to identify whether a different patch level of the
# compiler produces bytes that match the original where the current toolchain
# does not.
#
# Output is a tabular grid: rows are canary functions, columns are toolchain
# roots, cells show the number of differing bytes (or "MATCH" for zero).

[CmdletBinding()]
param(
    [string]$CanaryCpp = "c:\tmp\canary_toolchain_eval.cpp",

    [string]$OriginalExe = "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe",

    [string[]]$ToolchainRoots = @("C:\MSDEV", "C:\MSDEV41", "C:\MSDEV42"),

    [string]$WorkDir = "c:\tmp\canary_eval",

    [string[]]$OptimizationFlags = @("/Od"),

    # Extra flags appended to cl invocation. Useful for /d2*-prefixed
    # passthroughs that forward switches to c2.exe (the codegen back-end),
    # e.g. /d2norecy, /d2noimmreg. CL bundles /d2 flags into MSC_CMD_FLAGS
    # which c2.exe parses internally.
    [string[]]$ExtraC2Flags = @(),

    [Parameter(Mandatory = $true)]
    [object[]]$Canaries
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest


function Read-U16([byte[]]$b, [int]$o) {
    return [uint16](([uint64]$b[$o]) -bor (([uint64]$b[$o+1]) -shl 8))
}

function Read-U32([byte[]]$b, [int]$o) {
    return [uint32](([uint64]$b[$o]) -bor (([uint64]$b[$o+1]) -shl 8) -bor (([uint64]$b[$o+2]) -shl 16) -bor (([uint64]$b[$o+3]) -shl 24))
}

function Get-PeImage([string]$Path) {
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $Path).Path)
    $peOff = [int](Read-U32 $bytes 0x3c)
    $coff = $peOff + 4
    $sectionCount = [int](Read-U16 $bytes ($coff + 2))
    $optHdrSize = [int](Read-U16 $bytes ($coff + 16))
    $optOff = $coff + 20
    $sectionTbl = $optOff + $optHdrSize
    $sections = @()
    for ($i = 0; $i -lt $sectionCount; $i++) {
        $so = $sectionTbl + ($i * 40)
        $sections += [pscustomobject]@{
            VirtualAddress = [uint64](Read-U32 $bytes ($so + 12))
            VirtualSize    = [uint64](Read-U32 $bytes ($so + 8))
            RawSize        = [uint64](Read-U32 $bytes ($so + 16))
            RawPointer     = [uint64](Read-U32 $bytes ($so + 20))
        }
    }
    return [pscustomobject]@{ Bytes = $bytes; Sections = $sections }
}

function Read-RvaBytes($Image, [uint64]$Rva, [int]$Count) {
    foreach ($s in $Image.Sections) {
        if ($Rva -ge $s.VirtualAddress -and $Rva -lt ($s.VirtualAddress + [System.Math]::Max($s.VirtualSize, $s.RawSize))) {
            $delta = $Rva - $s.VirtualAddress
            $fileOff = [int]($s.RawPointer + $delta)
            $out = New-Object byte[] $Count
            [System.Array]::Copy($Image.Bytes, $fileOff, $out, 0, $Count)
            return $out
        }
    }
    throw "RVA 0x$($Rva.ToString('x')) not in any section"
}

function Resolve-MapSymbolRvaByContains([string]$MapPath, [string]$SymbolContains) {
    $lines = Get-Content $MapPath
    foreach ($line in $lines) {
        if ($line -match '^\s*\d+:[0-9a-fA-F]+\s+(\S+)\s+([0-9a-fA-F]+)') {
            $sym = $matches[1]
            if ($sym -like "*$SymbolContains*") {
                $va = [uint64]::Parse($matches[2], [System.Globalization.NumberStyles]::HexNumber)
                return [pscustomobject]@{
                    Symbol = $sym
                    Rva    = ($va - [uint64]0x10000000)
                }
            }
        }
    }
    throw "Symbol containing '$SymbolContains' not found in $MapPath"
}


# === Resolve original exe path relative to repo root ===
$repoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$origPath = Join-Path $repoRoot $OriginalExe
if (-not (Test-Path $origPath)) {
    throw "Original binary not found: $origPath"
}

# === Set up work dir ===
if (Test-Path $WorkDir) { Remove-Item -Recurse -Force $WorkDir }
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null

# === Compile + link the canary DLL once per toolchain ===
$builds = @()
foreach ($root in $ToolchainRoots) {
    $cl = Join-Path $root "BIN\CL.EXE"
    $link = Join-Path $root "BIN\LINK.EXE"
    if (-not (Test-Path $cl)) { throw "CL.EXE not found at $cl" }
    if (-not (Test-Path $link)) { throw "LINK.EXE not found at $link" }

    $tcName = (Split-Path -Leaf $root)
    $tcDir = Join-Path $WorkDir $tcName
    New-Item -ItemType Directory -Force -Path $tcDir | Out-Null
    $obj = Join-Path $tcDir "canary.obj"
    $dll = Join-Path $tcDir "canary.dll"
    $map = Join-Path $tcDir "canary.map"

    $env:INCLUDE = (Join-Path $root "INCLUDE")
    $env:LIB     = (Join-Path $root "LIB")

    Write-Host "=== [$tcName] Compile ===" -ForegroundColor Cyan
    $compileArgs = @("/nologo", "/c", "/Gd", "/Zl") + $OptimizationFlags + $ExtraC2Flags + @("/Fo$obj", $CanaryCpp)
    $compileLog = & $cl @compileArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        $compileLog | Write-Host
        throw "[$tcName] Compile failed (exit $LASTEXITCODE)"
    }

    Write-Host "=== [$tcName] Link ===" -ForegroundColor Cyan
    $linkArgs = @(
        "/nologo", "/DLL", "/NOENTRY",
        "/INCREMENTAL:NO", "/OPT:NOREF",
        "/OUT:$dll", "/MAP:$map",
        $obj
    )
    $linkLog = & $link @linkArgs 2>&1
    if ($LASTEXITCODE -ne 0) {
        $linkLog | Write-Host
        throw "[$tcName] Link failed (exit $LASTEXITCODE)"
    }

    $builds += [pscustomobject]@{
        Name = $tcName
        Root = $root
        Dll  = $dll
        Map  = $map
    }
}

# === Diff each canary against original under each toolchain ===
$origImg = Get-PeImage $origPath

$grid = @()
foreach ($canary in $Canaries) {
    $row = [ordered]@{ Canary = $canary.Name; Size = $canary.Size; OriginalRva = ("0x{0:x}" -f $canary.OriginalRva) }
    foreach ($build in $builds) {
        try {
            $resolved = Resolve-MapSymbolRvaByContains $build.Map $canary.SymbolContains
            $candImg = Get-PeImage $build.Dll
            $origBytes = Read-RvaBytes $origImg $canary.OriginalRva $canary.Size
            $candBytes = Read-RvaBytes $candImg $resolved.Rva $canary.Size
            $diffCount = 0
            for ($i = 0; $i -lt $canary.Size; $i++) {
                if ($origBytes[$i] -ne $candBytes[$i]) { $diffCount++ }
            }
            $cell = if ($diffCount -eq 0) { "MATCH ({0} B)" -f $canary.Size } else { "{0}/{1}" -f $diffCount, $canary.Size }
        } catch {
            $cell = "ERR: $($_.Exception.Message)"
        }
        $row[$build.Name] = $cell
    }
    $grid += [pscustomobject]$row
}

Write-Host "`n=== Canary x Toolchain diff grid ===" -ForegroundColor Yellow
$grid | Format-Table -AutoSize

# Also dump per-cell detail for any non-MATCH cell with low diff count
Write-Host "`n=== Per-cell detail (diffs < 32 bytes) ===" -ForegroundColor Yellow
foreach ($canary in $Canaries) {
    foreach ($build in $builds) {
        try {
            $resolved = Resolve-MapSymbolRvaByContains $build.Map $canary.SymbolContains
            $candImg = Get-PeImage $build.Dll
            $origBytes = Read-RvaBytes $origImg $canary.OriginalRva $canary.Size
            $candBytes = Read-RvaBytes $candImg $resolved.Rva $canary.Size
            $diffs = @()
            for ($i = 0; $i -lt $canary.Size; $i++) {
                if ($origBytes[$i] -ne $candBytes[$i]) { $diffs += $i }
            }
            if ($diffs.Count -gt 0 -and $diffs.Count -lt 32) {
                Write-Host ("[{0}] {1}: {2} diffs at offsets {3}" -f $build.Name, $canary.Name, $diffs.Count, (($diffs | ForEach-Object { '0x{0:x}' -f $_ }) -join ' '))
            }
        } catch { }
    }
}
