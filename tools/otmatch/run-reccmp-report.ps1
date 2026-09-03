param(
    [string]$ManifestPath = "tools\otmatch\functions.vc40-real-cpp.csv",
    [string]$OriginalPath = "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe",
    [string]$CandidatePath = "artifacts\otmatch\vc40\otwin-match-candidates.dll",
    [string]$CandidatePdbPath = "",
    [string]$CandidateMapPath = "artifacts\otmatch\vc40\otwin-match-candidates.map",
    [string]$OutputDirectory = "artifacts\otmatch\vc40\reccmp",
    [string]$ReccmpPath = "",

    [string]$Program = "",
    [string]$CandidateDllKey = "",
    [string]$NamePattern = "",
    [string]$NotesPattern = "",
    [switch]$OnlyWip,
    [int]$Limit = 0,

    [switch]$FullJson,
    [switch]$SkipRun
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

function Resolve-RepoPath {
    param(
        [string]$Path,
        [string]$Description,
        [bool]$RequireLeaf = $true
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "$Description path is empty."
    }

    $candidate = if ([System.IO.Path]::IsPathRooted($Path)) {
        $Path
    } else {
        Join-Path $repoRoot $Path
    }

    if ($RequireLeaf) {
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            throw "$Description was not found at '$candidate'."
        }
    } elseif (-not (Test-Path -LiteralPath $candidate -PathType Container)) {
        throw "$Description was not found at '$candidate'."
    }

    return (Resolve-Path -LiteralPath $candidate).Path
}

function Resolve-OptionalRepoPath {
    param(
        [string]$Path,
        [string]$Description
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ""
    }

    return Resolve-RepoPath -Path $Path -Description $Description
}

function Resolve-OutputPath {
    param([string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    return (Join-Path $repoRoot $Path)
}

function Get-CsvField {
    param(
        $Row,
        [string]$Name
    )

    $property = $Row.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) {
        return ""
    }

    return ([string]$property.Value).Trim()
}

function Parse-OtNumber {
    param(
        [string]$Value,
        [string]$FieldName
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "Missing numeric field '$FieldName'."
    }

    $text = $Value.Trim()
    if ($text.StartsWith("0x", [System.StringComparison]::OrdinalIgnoreCase)) {
        return [uint64]::Parse(
            $text.Substring(2),
            [System.Globalization.NumberStyles]::HexNumber,
            [System.Globalization.CultureInfo]::InvariantCulture)
    }

    return [uint64]::Parse(
        $text,
        [System.Globalization.NumberStyles]::Integer,
        [System.Globalization.CultureInfo]::InvariantCulture)
}

function Format-ReccmpVa {
    param([uint64]$Value)

    return ("0x{0:x8}" -f $Value)
}

function Get-ReccmpModuleName {
    param([string]$Path)

    return [System.IO.Path]::GetFileNameWithoutExtension($Path).ToUpperInvariant()
}

function Resolve-ReccmpExecutable {
    param([string]$ExplicitPath)

    if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
        return Resolve-RepoPath -Path $ExplicitPath -Description "reccmp-reccmp executable"
    }

    $envPath = [Environment]::GetEnvironmentVariable("RECCMP_RECCMP", "Process")
    if (-not [string]::IsNullOrWhiteSpace($envPath)) {
        return Resolve-RepoPath -Path $envPath -Description "RECCMP_RECCMP executable"
    }

    foreach ($name in @("reccmp-reccmp.exe", "reccmp-reccmp")) {
        $command = Get-Command -Name $name -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -ne $command) {
            return $command.Source
        }
    }

    throw "reccmp-reccmp was not found. Put it on PATH, set RECCMP_RECCMP, or pass -ReccmpPath."
}

function Read-MsvcMapSymbols {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    $symbols = New-Object "System.Collections.Hashtable" -ArgumentList ([System.StringComparer]::Ordinal)
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^\s*[0-9A-Fa-f]{4}:[0-9A-Fa-f]{8,16}\s+(\S+)\s+[0-9A-Fa-f]{8,16}(?:\s|$)') {
            $symbols[$Matches[1]] = $true
        }
    }

    return $symbols
}

function Get-CandidateSymbolBase {
    param([string]$Expression)

    $text = $Expression.Trim()
    if ($text -match '^(?<symbol>.+?)(?:\s*\+\s*(?:0x[0-9A-Fa-f]+|[0-9]+))?$') {
        return $Matches["symbol"].Trim()
    }

    return $text
}

$manifestFullPath = Resolve-RepoPath -Path $ManifestPath -Description "manifest"
$originalFullPath = Resolve-RepoPath -Path $OriginalPath -Description "original binary"
$candidateFullPath = Resolve-RepoPath -Path $CandidatePath -Description "candidate binary"
if ([string]::IsNullOrWhiteSpace($CandidatePdbPath)) {
    $CandidatePdbPath = [System.IO.Path]::ChangeExtension($CandidatePath, ".pdb")
}
$candidatePdbFullPath = Resolve-RepoPath -Path $CandidatePdbPath -Description "candidate PDB"
$candidateMapFullPath = Resolve-OptionalRepoPath -Path $CandidateMapPath -Description "candidate map"
$outputFullPath = Resolve-OutputPath $OutputDirectory
$annotationRoot = Join-Path $outputFullPath "annotations"
$annotationPath = Join-Path $annotationRoot "otmatch-reccmp-annotations.cpp"
$selectionPath = Join-Path $outputFullPath "otmatch-reccmp-selection.csv"
$summaryPath = Join-Path $outputFullPath "otmatch-reccmp-summary.txt"
$jsonPath = Join-Path $outputFullPath "otmatch-reccmp-report.json"
$htmlPath = Join-Path $outputFullPath "otmatch-reccmp-report.html"

$programFilter = if ([string]::IsNullOrWhiteSpace($Program)) {
    [System.IO.Path]::GetFileName($originalFullPath)
} else {
    $Program
}

$moduleName = Get-ReccmpModuleName $originalFullPath
$mapSymbols = Read-MsvcMapSymbols $candidateMapFullPath

New-Item -ItemType Directory -Force -Path $annotationRoot | Out-Null

$rows = @(Import-Csv -LiteralPath $manifestFullPath)
$selected = @()
$skipped = @{}

foreach ($row in $rows) {
    $reason = ""
    $rowName = Get-CsvField $row "name"
    $rowProgram = Get-CsvField $row "program"
    $rowCandidateDllKey = Get-CsvField $row "candidate_dll"
    $candidateSymbol = Get-CsvField $row "candidate_symbol"
    $candidateSymbolBase = Get-CandidateSymbolBase $candidateSymbol
    $originalVaText = Get-CsvField $row "original_va"
    $notes = Get-CsvField $row "notes"

    if (-not [string]::IsNullOrWhiteSpace($programFilter) -and
        -not [string]::Equals($rowProgram, $programFilter, [System.StringComparison]::OrdinalIgnoreCase)) {
        $reason = "program"
    } elseif (-not [string]::Equals($rowCandidateDllKey, $CandidateDllKey, [System.StringComparison]::OrdinalIgnoreCase)) {
        $reason = "candidate_dll"
    } elseif ([string]::IsNullOrWhiteSpace($candidateSymbol)) {
        $reason = "no_candidate_symbol"
    } elseif ([string]::IsNullOrWhiteSpace($originalVaText)) {
        $reason = "no_original_va"
    } elseif ($null -ne $mapSymbols -and -not $mapSymbols.ContainsKey($candidateSymbolBase)) {
        $reason = "symbol_not_in_map"
    } elseif (-not [string]::IsNullOrWhiteSpace($NamePattern) -and $rowName -notmatch $NamePattern) {
        $reason = "name_filter"
    } elseif (-not [string]::IsNullOrWhiteSpace($NotesPattern) -and $notes -notmatch $NotesPattern) {
        $reason = "notes_filter"
    } elseif ($OnlyWip -and $notes -notmatch "WIP semantic conversion") {
        $reason = "not_wip"
    }

    if (-not [string]::IsNullOrWhiteSpace($reason)) {
        if (-not $skipped.ContainsKey($reason)) {
            $skipped[$reason] = 0
        }
        $skipped[$reason]++
        continue
    }

    $originalVa = Format-ReccmpVa (Parse-OtNumber -Value $originalVaText -FieldName "original_va")
    $selected += [pscustomobject]@{
        name = $rowName
        program = $rowProgram
        original_va = $originalVa
        candidate_symbol = $candidateSymbol
        candidate_dll = $rowCandidateDllKey
        notes = $notes
    }

    if ($Limit -gt 0 -and @($selected).Count -ge $Limit) {
        break
    }
}

if (@($selected).Count -eq 0) {
    throw "No manifest rows were selected for reccmp annotations."
}

$annotationLines = @(
    "// Generated by tools/otmatch/run-reccmp-report.ps1.",
    "// Source manifest: $ManifestPath",
    "// Source candidate: $CandidatePath",
    ""
)

foreach ($entry in $selected) {
    $annotationLines += ("// SYNTHETIC: {0} {1} symbol" -f $moduleName, $entry.original_va)
    $annotationLines += ("// {0}" -f $entry.candidate_symbol)
    $annotationLines += ""
}

$annotationLines | Set-Content -LiteralPath $annotationPath -Encoding ASCII
$selected | Export-Csv -LiteralPath $selectionPath -NoTypeInformation -Encoding ASCII

$summaryLines = @(
    "manifest=$manifestFullPath",
    "original=$originalFullPath",
    "candidate=$candidateFullPath",
    "pdb=$candidatePdbFullPath",
    "map=$candidateMapFullPath",
    "program=$programFilter",
    "candidate_dll_key=$CandidateDllKey",
    "selected=$(@($selected).Count)",
    "annotations=$annotationPath",
    "selection=$selectionPath",
    "json=$jsonPath",
    "html=$htmlPath"
)

foreach ($key in ($skipped.Keys | Sort-Object)) {
    $summaryLines += ("skipped_{0}={1}" -f $key, $skipped[$key])
}

$summaryLines | Set-Content -LiteralPath $summaryPath -Encoding ASCII

Write-Host ("Generated {0} reccmp annotations at {1}" -f @($selected).Count, $annotationPath)
Write-Host ("Selection CSV: {0}" -f $selectionPath)

if ($SkipRun) {
    Write-Host "Skipping reccmp execution because -SkipRun was passed."
    exit 0
}

$reccmpFullPath = Resolve-ReccmpExecutable $ReccmpPath
$reccmpArgs = @(
    "--paths",
    $originalFullPath,
    $candidateFullPath,
    $candidatePdbFullPath,
    $annotationRoot,
    "--total",
    [string]@($selected).Count,
    "--json",
    $jsonPath,
    "--html",
    $htmlPath,
    "--no-color"
)

if (-not $FullJson) {
    $reccmpArgs += "--json-diet"
}

& $reccmpFullPath @reccmpArgs
if ($LASTEXITCODE -ne 0) {
    throw "reccmp-reccmp failed with exit code $LASTEXITCODE."
}

Write-Host ("reccmp JSON: {0}" -f $jsonPath)
Write-Host ("reccmp HTML: {0}" -f $htmlPath)
