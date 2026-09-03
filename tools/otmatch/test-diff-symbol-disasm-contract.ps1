[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$toolPath = (Resolve-Path (Join-Path $PSScriptRoot "diff-symbol-disasm.ps1")).Path
$shellPath = (Get-Process -Id $PID).Path
$dumpbinPath = "C:\msdev\bin\DUMPBIN.EXE"
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\.."))
$contractRoot = Join-Path $repoRoot "artifacts\otmatch\contracts"
$workPath = Join-Path $contractRoot (
    "otmatch-disasm-contract-" + [guid]::NewGuid().ToString("N"))
[void][System.IO.Directory]::CreateDirectory($workPath)

function Assert-True([bool]$Condition, [string]$Context) {
    if (-not $Condition) { throw $Context }
}

function Assert-Equal($Actual, $Expected, [string]$Context) {
    if ([string]$Actual -cne [string]$Expected) {
        throw "$Context expected '$Expected', got '$Actual'."
    }
}

function Set-U16([byte[]]$Bytes, [int]$Offset, [uint16]$Value) {
    $Bytes[$Offset] = [byte]($Value -band 0xff)
    $Bytes[$Offset + 1] = [byte](($Value -shr 8) -band 0xff)
}

function Set-U32([byte[]]$Bytes, [int]$Offset, [uint32]$Value) {
    $Bytes[$Offset] = [byte]($Value -band 0xff)
    $Bytes[$Offset + 1] = [byte](($Value -shr 8) -band 0xff)
    $Bytes[$Offset + 2] = [byte](($Value -shr 16) -band 0xff)
    $Bytes[$Offset + 3] = [byte](($Value -shr 24) -band 0xff)
}

function Set-Ascii([byte[]]$Bytes, [int]$Offset, [string]$Value, [int]$Width) {
    $encoded = [System.Text.Encoding]::ASCII.GetBytes($Value)
    if ($encoded.Length -gt $Width) { throw "ASCII fixture value is too wide." }
    [System.Array]::Copy($encoded, 0, $Bytes, $Offset, $encoded.Length)
}

function New-PeFixture(
    [string]$Path,
    [uint32]$ImageBase,
    [byte[]]$FunctionBytes) {

    $bytes = New-Object byte[] 0x800
    $peOffset = 0x80
    $coffOffset = $peOffset + 4
    $optionalOffset = $coffOffset + 20
    $sectionOffset = $optionalOffset + 0xe0
    $sectionRaw = 0x200

    $bytes[0] = 0x4d
    $bytes[1] = 0x5a
    Set-U32 $bytes 0x3c $peOffset
    $bytes[$peOffset] = 0x50
    $bytes[$peOffset + 1] = 0x45
    Set-U16 $bytes $coffOffset 0x014c
    Set-U16 $bytes ($coffOffset + 2) 1
    Set-U16 $bytes ($coffOffset + 16) 0x00e0
    Set-U16 $bytes ($coffOffset + 18) 0x0102

    Set-U16 $bytes $optionalOffset 0x010b
    Set-U32 $bytes ($optionalOffset + 4) 0x00000600
    Set-U32 $bytes ($optionalOffset + 16) 0x00001000
    Set-U32 $bytes ($optionalOffset + 20) 0x00001000
    Set-U32 $bytes ($optionalOffset + 24) 0x00001000
    Set-U32 $bytes ($optionalOffset + 28) $ImageBase
    Set-U32 $bytes ($optionalOffset + 32) 0x00001000
    Set-U32 $bytes ($optionalOffset + 36) 0x00000200
    Set-U16 $bytes ($optionalOffset + 40) 4
    Set-U16 $bytes ($optionalOffset + 48) 4
    Set-U32 $bytes ($optionalOffset + 56) 0x00002000
    Set-U32 $bytes ($optionalOffset + 60) 0x00000200
    Set-U16 $bytes ($optionalOffset + 68) 3
    Set-U32 $bytes ($optionalOffset + 72) 0x00100000
    Set-U32 $bytes ($optionalOffset + 76) 0x00001000
    Set-U32 $bytes ($optionalOffset + 80) 0x00100000
    Set-U32 $bytes ($optionalOffset + 84) 0x00001000
    Set-U32 $bytes ($optionalOffset + 92) 16
    Set-U32 $bytes ($optionalOffset + 136) 0x00001200
    Set-U32 $bytes ($optionalOffset + 140) 0x0000000c

    Set-Ascii $bytes $sectionOffset ".text" 8
    Set-U32 $bytes ($sectionOffset + 8) 0x00000600
    Set-U32 $bytes ($sectionOffset + 12) 0x00001000
    Set-U32 $bytes ($sectionOffset + 16) 0x00000600
    Set-U32 $bytes ($sectionOffset + 20) $sectionRaw
    Set-U32 $bytes ($sectionOffset + 36) 0x60000020

    [System.Array]::Copy($FunctionBytes, 0, $bytes, $sectionRaw,
        $FunctionBytes.Length)
    $relocationOffset = $sectionRaw + 0x200
    Set-U32 $bytes $relocationOffset 0x00001000
    Set-U32 $bytes ($relocationOffset + 4) 12
    Set-U16 $bytes ($relocationOffset + 8) 0x3002
    Set-U16 $bytes ($relocationOffset + 10) 0
    [System.IO.File]::WriteAllBytes($Path, $bytes)
}

function Set-CoffSymbol(
    [byte[]]$Bytes,
    [int]$Offset,
    [string]$Name,
    [uint32]$Value,
    [uint16]$SectionNumber,
    [uint16]$Type,
    [byte]$StorageClass = 2,
    [uint32]$StringTableOffset = 0) {

    $encodedName = [System.Text.Encoding]::ASCII.GetBytes($Name)
    if ($encodedName.Length -le 8) {
        Set-Ascii $Bytes $Offset $Name 8
    } else {
        if ($StringTableOffset -lt 4) {
            throw "A long COFF symbol requires a string-table offset."
        }
        Set-U32 $Bytes $Offset 0
        Set-U32 $Bytes ($Offset + 4) $StringTableOffset
    }
    Set-U32 $Bytes ($Offset + 8) $Value
    Set-U16 $Bytes ($Offset + 12) $SectionNumber
    Set-U16 $Bytes ($Offset + 14) $Type
    $Bytes[$Offset + 16] = $StorageClass
    $Bytes[$Offset + 17] = 0
}

function New-CoffFixture(
    [string]$Path,
    [byte[]]$FunctionBytes,
    [string]$FunctionSymbol = "_probe",
    [switch]$WithoutAbsoluteRelocation,
    [switch]$WithoutRelativeRelocation,
    [switch]$WithInternalTailLabel,
    [switch]$WithExternalTailLabel) {

    if ($WithInternalTailLabel.IsPresent -and
        $WithExternalTailLabel.IsPresent) {
        throw "A COFF fixture tail label cannot be both internal and external."
    }

    $rawPointer = 0x3c
    $relocationPointer = $rawPointer + $FunctionBytes.Length
    $relocationCount = $(if ($WithoutRelativeRelocation.IsPresent) { 1 } else { 2 })
    $symbolPointer = $relocationPointer + ($relocationCount * 10)
    $symbolCount = 3 + $(if ($WithInternalTailLabel.IsPresent -or
        $WithExternalTailLabel.IsPresent) { 1 } else { 0 })
    $stringPointer = $symbolPointer + ($symbolCount * 18)
    $functionSymbolBytes = [System.Text.Encoding]::ASCII.GetBytes($FunctionSymbol)
    $stringTableSize = 4 + $(if ($functionSymbolBytes.Length -gt 8) {
        $functionSymbolBytes.Length + 1
    } else { 0 })
    $bytes = New-Object byte[] ($stringPointer + $stringTableSize)
    Set-U16 $bytes 0 0x014c
    Set-U16 $bytes 2 1
    Set-U32 $bytes 8 $symbolPointer
    Set-U32 $bytes 12 $symbolCount

    Set-Ascii $bytes 20 ".text" 8
    Set-U32 $bytes (20 + 16) $FunctionBytes.Length
    Set-U32 $bytes (20 + 20) $rawPointer
    Set-U32 $bytes (20 + 24) $relocationPointer
    Set-U16 $bytes (20 + 32) $relocationCount
    Set-U32 $bytes (20 + 36) 0x60500020
    [System.Array]::Copy($FunctionBytes, 0, $bytes, $rawPointer,
        $FunctionBytes.Length)

    Set-U32 $bytes $relocationPointer 2
    Set-U32 $bytes ($relocationPointer + 4) 1
    Set-U16 $bytes ($relocationPointer + 8) $(if (
        $WithoutAbsoluteRelocation.IsPresent) { 0 } else { 0x0006 })
    if (-not $WithoutRelativeRelocation.IsPresent) {
        Set-U32 $bytes ($relocationPointer + 10) 7
        Set-U32 $bytes ($relocationPointer + 14) 2
        Set-U16 $bytes ($relocationPointer + 18) 0x0014
    }

    Set-CoffSymbol $bytes $symbolPointer $FunctionSymbol 0 1 0x20 2 `
        $(if ($functionSymbolBytes.Length -gt 8) { 4 } else { 0 })
    Set-CoffSymbol $bytes ($symbolPointer + 18) "_target" 0 0 0
    Set-CoffSymbol $bytes ($symbolPointer + 36) "_callee" 0 0 0
    if ($WithInternalTailLabel.IsPresent) {
        Set-CoffSymbol $bytes ($symbolPointer + 54) '$Ltail' 13 1 0 3
    } elseif ($WithExternalTailLabel.IsPresent) {
        Set-CoffSymbol $bytes ($symbolPointer + 54) "_later" 13 1 0x20
    }
    Set-U32 $bytes $stringPointer $stringTableSize
    if ($functionSymbolBytes.Length -gt 8) {
        Set-Ascii $bytes ($stringPointer + 4) $FunctionSymbol `
            $functionSymbolBytes.Length
    }
    [System.IO.File]::WriteAllBytes($Path, $bytes)
}

function New-DumpbinLabelMutationWrapper(
    [string]$Path,
    [string]$MatchPrefix,
    [string]$ReplacementLabel) {

    $template = @'
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$ToolArguments)

$realDumpbin = '__REAL_DUMPBIN__'
& $realDumpbin @ToolArguments | Out-Null
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$inputPath = [string]$ToolArguments[$ToolArguments.Count - 1]
if ([System.IO.Path]::GetExtension($inputPath) -ieq '.obj') {
    $outArguments = @($ToolArguments | Where-Object { $_ -like '/OUT:*' })
    if ($outArguments.Count -ne 1) {
        throw 'Expected exactly one DUMPBIN /OUT argument.'
    }
    $outputPath = $outArguments[0].Substring(5)
    $lines = @(Get-Content -LiteralPath $outputPath)
    $mutated = $false
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index].StartsWith('__MATCH_PREFIX__ ',
            [System.StringComparison]::Ordinal)) {
            $lines[$index] = '__REPLACEMENT_LABEL__:'
            $mutated = $true
        }
    }
    if (-not $mutated) {
        throw 'The decorated DUMPBIN fixture label was not found.'
    }
    [System.IO.File]::WriteAllLines($outputPath, $lines,
        (New-Object System.Text.UTF8Encoding($false)))
}

exit 0
'@
    $content = $template.Replace('__REAL_DUMPBIN__', $dumpbinPath)
    $content = $content.Replace('__MATCH_PREFIX__', $MatchPrefix)
    $content = $content.Replace('__REPLACEMENT_LABEL__', $ReplacementLabel)
    [System.IO.File]::WriteAllText($Path, $content,
        (New-Object System.Text.UTF8Encoding($false)))
}

function New-DumpbinInputLogWrapper(
    [string]$Path,
    [string]$LogPath) {

    $template = @'
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$ToolArguments)

$realDumpbin = '__REAL_DUMPBIN__'
$logPath = '__LOG_PATH__'
$inputPath = [string]$ToolArguments[$ToolArguments.Count - 1]
[System.IO.File]::AppendAllLines(
    $logPath,
    [string[]]@($inputPath),
    (New-Object System.Text.UTF8Encoding($false)))
& $realDumpbin @ToolArguments | Out-Null
exit $LASTEXITCODE
'@
    $content = $template.Replace(
        '__REAL_DUMPBIN__',
        $dumpbinPath.Replace("'", "''"))
    $content = $content.Replace(
        '__LOG_PATH__',
        $LogPath.Replace("'", "''"))
    [System.IO.File]::WriteAllText($Path, $content,
        (New-Object System.Text.UTF8Encoding($false)))
}

function Invoke-Case(
    [string]$Name,
    [string]$OriginalPath,
    [string]$CandidatePath,
    [string]$MapPath,
    [string]$ObjectPath,
    [string]$CandidateSymbol = "_probe",
    [string]$CaseDumpbinPath = $dumpbinPath) {

    $jsonPath = Join-Path $workPath "$Name.json"
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = @(& $shellPath -NoProfile -ExecutionPolicy Bypass `
            -File $toolPath `
            -OriginalPath $OriginalPath `
            -OriginalRva 0x1000 `
            -Size 16 `
            -CandidatePath $CandidatePath `
            -CandidateMapPath $MapPath `
            -CandidateSymbol $CandidateSymbol `
            -CandidateObjectPath $ObjectPath `
            -DumpbinPath $CaseDumpbinPath `
            -ResultsJsonPath $jsonPath `
            -SummaryOnly 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $oldPreference
    }
    if ($exitCode -ne 0) {
        throw "$Name failed: $($output -join [Environment]::NewLine)"
    }
    Assert-True (Test-Path -LiteralPath $jsonPath -PathType Leaf) `
        "$Name did not write JSON evidence."
    return [pscustomobject]@{
        output = @($output | ForEach-Object { [string]$_ })
        evidence = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
    }
}

function Invoke-ExpectedFailure(
    [string]$Name,
    [string]$OriginalPath,
    [string]$CandidatePath,
    [string]$MapPath,
    [string]$ObjectPath,
    [string]$ResultsPath,
    [string]$ExpectedPattern,
    [bool]$MustFailBeforeByteDiff,
    [string]$CandidateSymbol = "_probe",
    [string]$CaseDumpbinPath = $dumpbinPath) {

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = @(& $shellPath -NoProfile -ExecutionPolicy Bypass `
            -File $toolPath `
            -OriginalPath $OriginalPath `
            -OriginalRva 0x1000 `
            -Size 16 `
            -CandidatePath $CandidatePath `
            -CandidateMapPath $MapPath `
            -CandidateSymbol $CandidateSymbol `
            -CandidateObjectPath $ObjectPath `
            -DumpbinPath $CaseDumpbinPath `
            -ResultsJsonPath $ResultsPath `
            -SummaryOnly 2>&1)
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $oldPreference
    }
    $text = $output -join [Environment]::NewLine
    Assert-True ($exitCode -ne 0) "$Name unexpectedly succeeded."
    Assert-True ($text -match $ExpectedPattern) `
        "$Name did not fail for the expected reason: $text"
    if ($MustFailBeforeByteDiff) {
        Assert-True ($text -notmatch '== Byte diff') `
            "$Name read/diffed inputs before rejecting ResultsJsonPath."
    }
    return @($output | ForEach-Object { [string]$_ })
}

try {
    Assert-True (Test-Path -LiteralPath $dumpbinPath -PathType Leaf) `
        "VC4 dumpbin is required for this contract test."

    $decoratedSymbol = '?probe@@YAHXZ'

    [byte[]]$originalCode = @(
        0x55,
        0xa1, 0x00, 0x20, 0x40, 0x00,
        0xe8, 0xf5, 0x0f, 0x00, 0x00,
        0xc3, 0x90,
        0x33, 0xc0,
        0xc3)
    [byte[]]$candidateCode = @(
        0x55,
        0xa1, 0x00, 0x30, 0x00, 0x10,
        0xe8, 0xf5, 0x1f, 0x00, 0x00,
        0xc3, 0x90,
        0x33, 0xc9,
        0xc3)
    [byte[]]$objectCode = @(
        0x55,
        0xa1, 0, 0, 0, 0,
        0xe8, 0, 0, 0, 0,
        0xc3, 0x90,
        0x33, 0xc9,
        0xc3)
    [byte[]]$memoryOriginalCode = @(
        0xc7, 0x05, 0x00, 0x20, 0x40, 0x00,
        0x78, 0x56, 0x34, 0x12,
        0xc3, 0x90, 0x33, 0xc0, 0x90, 0xc3)
    [byte[]]$memoryCandidateCode = @(
        0xc7, 0x05, 0x00, 0x30, 0x00, 0x10,
        0x78, 0x56, 0x34, 0x12,
        0xc3, 0x90, 0x33, 0xc0, 0x90, 0xc3)
    [byte[]]$memoryObjectCode = @(
        0xc7, 0x05, 0, 0, 0, 0,
        0x78, 0x56, 0x34, 0x12,
        0xc3, 0x90, 0x33, 0xc0, 0x90, 0xc3)
    [byte[]]$ambiguousOriginalCode = [byte[]]$memoryOriginalCode.Clone()
    [byte[]]$ambiguousCandidateCode = [byte[]]$memoryCandidateCode.Clone()
    [byte[]]$ambiguousObjectCode = [byte[]]$memoryObjectCode.Clone()
    for ($index = 6; $index -lt 10; $index++) {
        $ambiguousOriginalCode[$index] = 0
        $ambiguousCandidateCode[$index] = 0
        $ambiguousObjectCode[$index] = 0
    }
    [byte[]]$cmpZeroOriginalCode = @(
        0x83, 0x3d, 0x00, 0x20, 0x40, 0x00, 0x00,
        0xc3, 0x90, 0x33, 0xc0, 0x90, 0x90, 0x90, 0x90, 0xc3)
    [byte[]]$cmpZeroCandidateCode = @(
        0x83, 0x3d, 0x00, 0x30, 0x00, 0x10, 0x00,
        0xc3, 0x90, 0x33, 0xc0, 0x90, 0x90, 0x90, 0x90, 0xc3)
    [byte[]]$cmpZeroObjectCode = @(
        0x83, 0x3d, 0, 0, 0, 0, 0,
        0xc3, 0x90, 0x33, 0xc0, 0x90, 0x90, 0x90, 0x90, 0xc3)
    [byte[]]$unsupportedZeroOriginalCode = @(
        0x81, 0x3d, 0x00, 0x20, 0x40, 0x00, 0, 0, 0, 0,
        0xc3, 0x90, 0x33, 0xc0, 0x90, 0xc3)
    [byte[]]$unsupportedZeroCandidateCode = @(
        0x81, 0x3d, 0x00, 0x30, 0x00, 0x10, 0, 0, 0, 0,
        0xc3, 0x90, 0x33, 0xc0, 0x90, 0xc3)
    [byte[]]$unsupportedZeroObjectCode = @(
        0x81, 0x3d, 0, 0, 0, 0, 0, 0, 0, 0,
        0xc3, 0x90, 0x33, 0xc0, 0x90, 0xc3)

    $originalPath = Join-Path $workPath "original.exe"
    $candidatePath = Join-Path $workPath "candidate.dll"
    $pairedObjectPath = Join-Path $workPath "paired.obj"
    $unpairedObjectPath = Join-Path $workPath "unpaired.obj"
    $shortObjectPath = Join-Path $workPath "short.obj"
    $laterSymbolObjectPath = Join-Path $workPath "later-symbol.obj"
    $memoryOriginalPath = Join-Path $workPath "memory-original.exe"
    $memoryCandidatePath = Join-Path $workPath "memory-candidate.dll"
    $memoryObjectPath = Join-Path $workPath "memory-paired.obj"
    $ambiguousOriginalPath = Join-Path $workPath "ambiguous-original.exe"
    $ambiguousCandidatePath = Join-Path $workPath "ambiguous-candidate.dll"
    $ambiguousObjectPath = Join-Path $workPath "ambiguous.obj"
    $cmpZeroOriginalPath = Join-Path $workPath "cmp-zero-original.exe"
    $cmpZeroCandidatePath = Join-Path $workPath "cmp-zero-candidate.dll"
    $cmpZeroObjectPath = Join-Path $workPath "cmp-zero.obj"
    $unsupportedZeroOriginalPath = Join-Path $workPath `
        "unsupported-zero-original.exe"
    $unsupportedZeroCandidatePath = Join-Path $workPath `
        "unsupported-zero-candidate.dll"
    $unsupportedZeroObjectPath = Join-Path $workPath "unsupported-zero.obj"
    $decoratedObjectPath = Join-Path $workPath "decorated.obj"
    $decoratedMapPath = Join-Path $workPath "decorated.map"
    $malformedDumpbinPath = Join-Path $workPath "malformed-dumpbin.ps1"
    $ambiguousDumpbinPath = Join-Path $workPath "ambiguous-dumpbin.ps1"
    $inputLogDumpbinPath = Join-Path $workPath "input-log-dumpbin.ps1"
    $dumpbinInputLogPath = Join-Path $workPath "dumpbin-inputs.log"
    $mapPath = Join-Path $workPath "candidate.map"
    New-PeFixture $originalPath 0x00400000 $originalCode
    New-PeFixture $candidatePath 0x10000000 $candidateCode
    New-CoffFixture $pairedObjectPath $objectCode -WithInternalTailLabel
    # The unpaired object still matches the linked candidate bytes. Omitting
    # only its absolute relocation proves that the differing operand remains
    # structural without simulating a stale/wrong object file.
    New-CoffFixture $unpairedObjectPath $candidateCode `
        -WithoutAbsoluteRelocation -WithInternalTailLabel
    New-CoffFixture $shortObjectPath ([byte[]]$objectCode[0..14]) `
        -WithInternalTailLabel
    New-CoffFixture $laterSymbolObjectPath $objectCode -WithExternalTailLabel
    New-PeFixture $memoryOriginalPath 0x00400000 $memoryOriginalCode
    New-PeFixture $memoryCandidatePath 0x10000000 $memoryCandidateCode
    New-CoffFixture $memoryObjectPath $memoryObjectCode `
        -WithoutRelativeRelocation
    New-PeFixture $ambiguousOriginalPath 0x00400000 $ambiguousOriginalCode
    New-PeFixture $ambiguousCandidatePath 0x10000000 $ambiguousCandidateCode
    New-CoffFixture $ambiguousObjectPath $ambiguousObjectCode `
        -WithoutRelativeRelocation
    New-PeFixture $cmpZeroOriginalPath 0x00400000 $cmpZeroOriginalCode
    New-PeFixture $cmpZeroCandidatePath 0x10000000 $cmpZeroCandidateCode
    New-CoffFixture $cmpZeroObjectPath $cmpZeroObjectCode `
        -WithoutRelativeRelocation
    New-PeFixture $unsupportedZeroOriginalPath 0x00400000 `
        $unsupportedZeroOriginalCode
    New-PeFixture $unsupportedZeroCandidatePath 0x10000000 `
        $unsupportedZeroCandidateCode
    New-CoffFixture $unsupportedZeroObjectPath $unsupportedZeroObjectCode `
        -WithoutRelativeRelocation
    New-CoffFixture $decoratedObjectPath $objectCode `
        -FunctionSymbol $decoratedSymbol -WithInternalTailLabel
    [System.IO.File]::WriteAllText($mapPath,
        " 0001:00000000 _probe 10001000 f paired.obj`r`n",
        (New-Object System.Text.UTF8Encoding($false)))
    [System.IO.File]::WriteAllText($decoratedMapPath,
        " 0001:00000000 $decoratedSymbol 10001000 f decorated.obj`r`n",
        (New-Object System.Text.UTF8Encoding($false)))
    New-DumpbinLabelMutationWrapper $malformedDumpbinPath $decoratedSymbol `
        "$decoratedSymbol (int __cdecl probe(void)"
    New-DumpbinLabelMutationWrapper $ambiguousDumpbinPath $decoratedSymbol `
        "$decoratedSymbol (int __cdecl probe(void)) (duplicate)"
    New-DumpbinInputLogWrapper $inputLogDumpbinPath $dumpbinInputLogPath

    # Friendly DUMPBIN paths must be invocation-local.  Reusing a deterministic
    # copy for the same spaced input races when focused diffs run concurrently.
    $spacedInputRoot = Join-Path $workPath "friendly input paths"
    [void][System.IO.Directory]::CreateDirectory($spacedInputRoot)
    $spacedOriginalPath = Join-Path $spacedInputRoot "original image.exe"
    $spacedCandidatePath = Join-Path $spacedInputRoot "candidate image.dll"
    $spacedMapPath = Join-Path $spacedInputRoot "candidate symbols.map"
    $spacedObjectPath = Join-Path $spacedInputRoot "paired object.obj"
    Copy-Item -LiteralPath $originalPath -Destination $spacedOriginalPath
    Copy-Item -LiteralPath $candidatePath -Destination $spacedCandidatePath
    Copy-Item -LiteralPath $mapPath -Destination $spacedMapPath
    Copy-Item -LiteralPath $pairedObjectPath -Destination $spacedObjectPath

    [void](Invoke-Case "friendly-path-first" $spacedOriginalPath `
        $spacedCandidatePath $spacedMapPath $spacedObjectPath "_probe" `
        $inputLogDumpbinPath)
    [void](Invoke-Case "friendly-path-second" $spacedOriginalPath `
        $spacedCandidatePath $spacedMapPath $spacedObjectPath "_probe" `
        $inputLogDumpbinPath)
    $friendlyInputs = @(Get-Content -LiteralPath $dumpbinInputLogPath)
    Assert-Equal $friendlyInputs.Count 4 "friendly DUMPBIN input count"
    Assert-True ($friendlyInputs[0] -cne $friendlyInputs[2]) `
        "Repeated original disassembly reused a friendly temporary path."
    Assert-True ($friendlyInputs[1] -cne $friendlyInputs[3]) `
        "Repeated object disassembly reused a friendly temporary path."
    foreach ($friendlyInput in $friendlyInputs) {
        Assert-True ($friendlyInput -notmatch '\s') `
            "DUMPBIN received a whitespace-bearing friendly input path."
        Assert-True (-not (Test-Path -LiteralPath $friendlyInput)) `
            "Friendly DUMPBIN input was not cleaned up: '$friendlyInput'."
    }

    $outsidePath = Join-Path ([System.IO.Path]::GetTempPath()) (
        "otmatch-disasm-outside-" + [guid]::NewGuid().ToString("N") + ".json")
    [void](Invoke-ExpectedFailure "outside-results" $originalPath $candidatePath `
        $mapPath $pairedObjectPath $outsidePath `
        'must be below.*(?:a|artifacts)' $true)
    Assert-True (-not (Test-Path -LiteralPath $outsidePath)) `
        "outside ResultsJsonPath was created."

    $originalHash = (Get-FileHash -LiteralPath $originalPath -Algorithm SHA256).Hash
    [void](Invoke-ExpectedFailure "protected-input-results" $originalPath `
        $candidatePath $mapPath $pairedObjectPath $originalPath `
        'must not overwrite an input or tool file' $true)
    Assert-Equal (Get-FileHash -LiteralPath $originalPath -Algorithm SHA256).Hash `
        $originalHash "protected original hash"

    $shortResultsPath = Join-Path $workPath "short.json"
    [void](Invoke-ExpectedFailure "partial-disassembly" $originalPath `
        $candidatePath $mapPath $shortObjectPath $shortResultsPath `
        'disassembly covers 0x[fF] of 0x10 function bytes' $false)
    Assert-True (-not (Test-Path -LiteralPath $shortResultsPath)) `
        "partial disassembly wrote JSON evidence."

    $laterSymbolResultsPath = Join-Path $workPath "later-symbol.json"
    [void](Invoke-ExpectedFailure "later-external-symbol" $originalPath `
        $candidatePath $mapPath $laterSymbolObjectPath `
        $laterSymbolResultsPath `
        "(?s)encountered later external label '_later'.*before covering 0x10.*bytes" `
        $false)
    Assert-True (-not (Test-Path -LiteralPath $laterSymbolResultsPath)) `
        "later external symbol wrote JSON evidence."

    $decorated = Invoke-Case "decorated" $originalPath $candidatePath `
        $decoratedMapPath $decoratedObjectPath $decoratedSymbol
    Assert-Equal $decorated.evidence.identity.candidate_symbol `
        $decoratedSymbol "exact decorated candidate symbol"
    Assert-Equal $decorated.evidence.summary.paired_address_only_instruction_count 2 `
        "decorated-label paired address-only count"
    Assert-Equal $decorated.evidence.summary.structural_instruction_count 1 `
        "decorated-label structural instruction count"

    $malformedLabelResultsPath = Join-Path $workPath "malformed-label.json"
    [void](Invoke-ExpectedFailure "malformed-decorated-label" $originalPath `
        $candidatePath $decoratedMapPath $decoratedObjectPath `
        $malformedLabelResultsPath `
        '(?s)verified decorated COFF symbol.*malformed parenthesized display suffix' `
        $false $decoratedSymbol $malformedDumpbinPath)
    Assert-True (-not (Test-Path -LiteralPath $malformedLabelResultsPath)) `
        "malformed decorated label wrote JSON evidence."

    $ambiguousLabelResultsPath = Join-Path $workPath "ambiguous-label.json"
    [void](Invoke-ExpectedFailure "ambiguous-decorated-label" $originalPath `
        $candidatePath $decoratedMapPath $decoratedObjectPath `
        $ambiguousLabelResultsPath `
        '(?s)verified decorated COFF symbol.*ambiguous multi-part display suffix' `
        $false $decoratedSymbol $ambiguousDumpbinPath)
    Assert-True (-not (Test-Path -LiteralPath $ambiguousLabelResultsPath)) `
        "ambiguous decorated label wrote JSON evidence."

    $pairedJsonPath = Join-Path $workPath "paired.json"
    [System.IO.File]::WriteAllText($pairedJsonPath, '{"sentinel":true}',
        (New-Object System.Text.UTF8Encoding($false)))

    $paired = Invoke-Case "paired" $originalPath $candidatePath $mapPath `
        $pairedObjectPath
    $evidence = $paired.evidence
    Assert-Equal $evidence.schema_version 1 "schema version"
    Assert-Equal $evidence.artifact_type `
        "otmatch-focused-instruction-shape-evidence" "artifact type"
    Assert-True ([bool]$evidence.authority.diagnostic_only) `
        "normalization must be labeled diagnostic-only."
    Assert-True (-not [bool]$evidence.authority.grants_acceptance_credit) `
        "normalization must grant zero acceptance credit."
    Assert-True (-not [bool]$evidence.authority.normalized_match_is_exact_match) `
        "a normalized match must not be represented as exact."
    Assert-Equal $evidence.raw_exact.difference_count 5 "raw difference count"
    Assert-Equal $evidence.raw_exact.compared_bytes 16 "raw compared bytes"
    Assert-Equal $evidence.raw_exact.difference_offsets.Count 5 `
        "raw difference offset count"
    Assert-True (($evidence.raw_exact.child_diff_output -join "`n") -match
        'Differences:\s+5 / 16') "raw child diff evidence was not preserved."
    Assert-True (($paired.output -join "`n") -notmatch
        '(?m)^All (?:hard )?diff offsets:') `
        "SummaryOnly leaked full raw offset lists to the console."

    Assert-Equal $evidence.summary.original_instruction_count 7 `
        "original instruction count"
    Assert-Equal $evidence.summary.candidate_instruction_count 7 `
        "candidate instruction count"
    Assert-Equal $evidence.summary.exact_instruction_count 4 `
        "exact instruction count"
    Assert-Equal $evidence.summary.paired_address_only_instruction_count 2 `
        "paired address-only count"
    Assert-Equal $evidence.summary.structural_instruction_count 1 `
        "structural instruction count"
    Assert-Equal $evidence.summary.paired_same_offset_address_operand_count 2 `
        "paired same-offset operand count"
    Assert-Equal $evidence.summary.mismatch_island_count 1 `
        "mismatch island count"
    Assert-Equal $evidence.summary.max_absolute_offset_drift 0 `
        "offset drift"
    Assert-Equal $evidence.mismatch_islands[0].original_start_offset 13 `
        "original mismatch island start"
    Assert-Equal $evidence.mismatch_islands[0].original_end_offset_exclusive 15 `
        "original mismatch island end-exclusive"
    Assert-Equal $evidence.mismatch_islands[0].candidate_start_offset 13 `
        "candidate mismatch island start"
    Assert-Equal $evidence.mismatch_islands[0].candidate_end_offset_exclusive 15 `
        "candidate mismatch island end-exclusive"
    $atomicTemps = @(Get-ChildItem -LiteralPath $workPath -Force -Filter `
        '.paired.json.*.tmp' -ErrorAction SilentlyContinue)
    Assert-Equal $atomicTemps.Count 0 "atomic JSON temporary-file cleanup"

    $originalMov = @($evidence.instructions.original | Where-Object {
        $_.offset -eq 1 })[0]
    $candidateMov = @($evidence.instructions.candidate | Where-Object {
        $_.offset -eq 1 })[0]
    Assert-Equal $originalMov.size 5 "original mov size"
    Assert-Equal $originalMov.mnemonic "mov" "normalized mnemonic"
    Assert-Equal $originalMov.operand_classes[0] "register" `
        "destination operand class"
    Assert-Equal $originalMov.operand_classes[1] "memory_address" `
        "source operand class"
    Assert-Equal $originalMov.address_operands[0].function_offset 2 `
        "original address operand offset"
    Assert-Equal $originalMov.address_operands[0].instruction_offset 1 `
        "instruction-relative address operand offset"
    Assert-Equal $originalMov.address_operands[0].width 4 `
        "address operand width"
    Assert-Equal $originalMov.address_operands[0].kind "pe_highlow" `
        "original address operand kind"
    Assert-Equal $candidateMov.address_operands[0].kind "coff_dir32" `
        "candidate address operand kind"
    Assert-Equal $candidateMov.raw_bytes "a100300010" `
        "linked candidate bytes"
    Assert-Equal $candidateMov.dumpbin_bytes "a100000000" `
        "raw object bytes"
    Assert-True ($candidateMov.normalized_bytes_pattern -match
        '<absolute_address_32:4>') "normalized address pattern is absent."
    Assert-True ($candidateMov.normalized_text -match
        '<address:absolute_address_32>') "normalized operand text is absent."
    Assert-True ($candidateMov.block_index -ge 0 -and
        $candidateMov.block_start_offset -ge 0) `
        "candidate basic-block metadata is absent."

    $movAlignment = @($evidence.alignment | Where-Object {
        $_.original_offset -eq 1 -and $_.candidate_offset -eq 1 })[0]
    Assert-Equal $movAlignment.category "paired_address_only" `
        "paired address classification"
    Assert-Equal $movAlignment.paired_same_offset_operands.Count 1 `
        "mov paired operand count"
    Assert-Equal $movAlignment.offset_drift 0 "mov instruction offset drift"
    Assert-Equal $movAlignment.block_start_drift 0 "mov block-start drift"
    Assert-Equal $movAlignment.paired_same_offset_operands[0].original_kind `
        "pe_highlow" "paired original kind"
    Assert-Equal $movAlignment.paired_same_offset_operands[0].candidate_kind `
        "coff_dir32" "paired candidate kind"

    $candidateCall = @($evidence.instructions.candidate | Where-Object {
        $_.offset -eq 6 })[0]
    Assert-Equal $candidateCall.address_operands[0].symbol "_callee" `
        "COFF rel32 target symbol"
    Assert-Equal $candidateCall.address_operands[0].target_scope `
        "external_relocation" "COFF rel32 target scope"
    $xorAlignment = @($evidence.alignment | Where-Object {
        $_.original_offset -eq 13 -and $_.candidate_offset -eq 13 })[0]
    Assert-True ($xorAlignment.category -ne "paired_address_only" -and
        $xorAlignment.category -ne "exact") `
        "register/opcode bytes were hidden by address normalization."

    $memoryPaired = Invoke-Case "memory-paired" $memoryOriginalPath `
        $memoryCandidatePath $mapPath $memoryObjectPath
    Assert-Equal $memoryPaired.evidence.summary.paired_address_only_instruction_count 1 `
        "memory-address paired instruction count"
    Assert-Equal $memoryPaired.evidence.summary.structural_instruction_count 0 `
        "memory-address structural instruction count"
    $originalMemoryMov = @($memoryPaired.evidence.instructions.original |
        Where-Object { $_.offset -eq 0 })[0]
    $candidateMemoryMov = @($memoryPaired.evidence.instructions.candidate |
        Where-Object { $_.offset -eq 0 })[0]
    Assert-Equal $originalMemoryMov.operand_classes[0] "memory_address" `
        "original relocated memory operand class"
    Assert-Equal $originalMemoryMov.operand_classes[1] "immediate" `
        "original immediate operand class"
    Assert-Equal $candidateMemoryMov.operand_classes[0] "memory_address" `
        "candidate relocated memory operand class"
    Assert-Equal $candidateMemoryMov.operand_classes[1] "immediate" `
        "candidate immediate operand class"
    Assert-True ($originalMemoryMov.normalized_text -match
        '\[<address:absolute_address_32>\],12345678h') `
        "original memory address was not normalized independently of its immediate."
    Assert-True ($candidateMemoryMov.normalized_text -match
        '\[<address:absolute_address_32>\],12345678h') `
        "candidate memory address was not normalized independently of its immediate."
    Assert-True ($candidateMemoryMov.normalized_bytes_pattern -match
        '<absolute_address_32:4> 78 56 34 12') `
        "candidate immediate bytes were hidden by address normalization."
    $memoryAlignment = @($memoryPaired.evidence.alignment | Where-Object {
        $_.original_offset -eq 0 -and $_.candidate_offset -eq 0 })[0]
    Assert-Equal $memoryAlignment.category "paired_address_only" `
        "relocated memory/immediate instruction classification"

    $zeroMov = Invoke-Case "zero-mov" $ambiguousOriginalPath `
        $ambiguousCandidatePath $mapPath $ambiguousObjectPath
    Assert-Equal $zeroMov.evidence.summary.paired_address_only_instruction_count 1 `
        "zero-immediate mov paired address-only count"
    Assert-Equal $zeroMov.evidence.summary.structural_instruction_count 0 `
        "zero-immediate mov structural count"
    $candidateZeroMov = @($zeroMov.evidence.instructions.candidate |
        Where-Object { $_.offset -eq 0 })[0]
    Assert-True ($candidateZeroMov.normalized_text -match
        '^mov dword ptr ds:\[<address:absolute_address_32>\],0$') `
        "zero-immediate mov did not normalize only the memory address."
    Assert-Equal $candidateZeroMov.normalized_bytes_pattern `
        "c7 05 <absolute_address_32:4> 00 00 00 00" `
        "zero-immediate mov byte pattern"
    Assert-Equal $candidateZeroMov.operand_classes[0] "memory_address" `
        "zero-immediate mov destination class"
    Assert-Equal $candidateZeroMov.operand_classes[1] "immediate" `
        "zero-immediate mov source class"
    Assert-Equal $candidateZeroMov.address_operands[0].kind "coff_dir32" `
        "zero-immediate mov relocation kind"
    Assert-Equal $candidateZeroMov.address_operands[0].instruction_offset 2 `
        "zero-immediate mov relocation offset"
    $zeroMovAlignment = @($zeroMov.evidence.alignment | Where-Object {
        $_.original_offset -eq 0 -and $_.candidate_offset -eq 0 })[0]
    Assert-Equal $zeroMovAlignment.category "paired_address_only" `
        "zero-immediate mov classification"

    $cmpZero = Invoke-Case "cmp-zero" $cmpZeroOriginalPath `
        $cmpZeroCandidatePath $mapPath $cmpZeroObjectPath
    Assert-Equal $cmpZero.evidence.summary.paired_address_only_instruction_count 1 `
        "zero-immediate cmp paired address-only count"
    Assert-Equal $cmpZero.evidence.summary.structural_instruction_count 0 `
        "zero-immediate cmp structural count"
    $candidateCmpZero = @($cmpZero.evidence.instructions.candidate |
        Where-Object { $_.offset -eq 0 })[0]
    Assert-True ($candidateCmpZero.normalized_text -match
        '^cmp dword ptr ds:\[<address:absolute_address_32>\],0$') `
        "zero-immediate cmp did not normalize only the memory address."
    Assert-Equal $candidateCmpZero.normalized_bytes_pattern `
        "83 3d <absolute_address_32:4> 00" `
        "zero-immediate cmp byte pattern"
    Assert-Equal $candidateCmpZero.operand_classes[0] "memory_address" `
        "zero-immediate cmp destination class"
    Assert-Equal $candidateCmpZero.operand_classes[1] "immediate" `
        "zero-immediate cmp source class"
    Assert-Equal $candidateCmpZero.address_operands[0].kind "coff_dir32" `
        "zero-immediate cmp relocation kind"
    Assert-Equal $candidateCmpZero.address_operands[0].instruction_offset 2 `
        "zero-immediate cmp relocation offset"
    $cmpZeroAlignment = @($cmpZero.evidence.alignment | Where-Object {
        $_.original_offset -eq 0 -and $_.candidate_offset -eq 0 })[0]
    Assert-Equal $cmpZeroAlignment.category "paired_address_only" `
        "zero-immediate cmp classification"

    $unsupportedZeroResultsPath = Join-Path $workPath `
        "unsupported-zero.json"
    [void](Invoke-ExpectedFailure "unsupported-zero-relocated-operand" `
        $unsupportedZeroOriginalPath $unsupportedZeroCandidatePath $mapPath `
        $unsupportedZeroObjectPath $unsupportedZeroResultsPath `
        '(?s)cannot uniquely.*coff_dir32 relocation.*found 2.*matching numeric operands' `
        $false)
    Assert-True (-not (Test-Path -LiteralPath $unsupportedZeroResultsPath)) `
        "unsupported zero-valued relocated operand wrote JSON evidence."

    $unpaired = Invoke-Case "unpaired" $originalPath $candidatePath $mapPath `
        $unpairedObjectPath
    Assert-Equal $unpaired.evidence.summary.paired_address_only_instruction_count 1 `
        "unpaired address-only count"
    Assert-Equal $unpaired.evidence.summary.structural_instruction_count 2 `
        "unpaired structural count"
    $unpairedMov = @($unpaired.evidence.alignment | Where-Object {
        $_.original_offset -eq 1 -and $_.candidate_offset -eq 1 })[0]
    Assert-True ($unpairedMov.category -ne "paired_address_only") `
        "an unpaired relocation was incorrectly normalized as address-only."

    Write-Host "PASS diff-symbol-disasm contract: verified decorated labels and internal continuations stay in-function; malformed labels, unsupported operand mappings, and later symbols fail closed; encoded memory roles disambiguate zero-valued addresses from zero immediates; relocated memory operands preserve immediates; raw evidence and normalization contracts hold."
} finally {
    if (Test-Path -LiteralPath $workPath -PathType Container) {
        Remove-Item -LiteralPath $workPath -Recurse -Force
    }
}
