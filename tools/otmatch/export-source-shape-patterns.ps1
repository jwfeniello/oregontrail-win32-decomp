[CmdletBinding()]
param(
    [string[]]$SearchRoot = @("artifacts", "a"),
    [string]$OutputPath = "artifacts\otmatch\source-shape-patterns.csv"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

function Resolve-ConfiguredPath([string]$Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
}

function Get-PropertyValue($Object, [string]$Name, $Default = $null) {
    if ($null -eq $Object) {
        return $Default
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $Default
    }
    return $property.Value
}

$rows = New-Object 'System.Collections.Generic.List[object]'
foreach ($root in $SearchRoot) {
    $fullRoot = Resolve-ConfiguredPath $root
    if (-not (Test-Path -LiteralPath $fullRoot -PathType Container)) {
        continue
    }
    foreach ($file in @(Get-ChildItem -LiteralPath $fullRoot -Recurse `
            -Filter "*.evidence.json" -File -ErrorAction SilentlyContinue)) {
        try {
            $evidence = Get-Content -LiteralPath $file.FullName -Raw |
                ConvertFrom-Json
        } catch {
            continue
        }
        if ([string]$evidence.artifact_type -cne
            "otwin-source-shape-evidence") {
            continue
        }
        $identity = Get-PropertyValue $evidence "identity"
        $runSummary = Get-PropertyValue $evidence "run_summary"
        $successfulTrial = Get-PropertyValue $evidence "successful_trial"
        $successfulVariant = ""
        $successfulHypothesis = ""
        if ($null -ne $successfulTrial) {
            $successfulVariant = [string](Get-PropertyValue `
                $successfulTrial "variant" "")
            $successfulHypothesis =
                [string](Get-PropertyValue $successfulTrial "hypothesis" "")
        }
        $rows.Add([pscustomobject][ordered]@{
            Program = [string](Get-PropertyValue $identity "program" "")
            Name = [string](Get-PropertyValue $identity "name" "")
            OriginalRva = [string](Get-PropertyValue $identity "original_rva" "")
            Mode = if ($null -ne $evidence.PSObject.Properties["mode"]) {
                [string]$evidence.mode
            } else {
                "promotion"
            }
            Successful = $null -ne $successfulTrial
            Variant = $successfulVariant
            Hypothesis = $successfulHypothesis
            TrialCount = [int](Get-PropertyValue $runSummary "trial_count" 0)
            MeaningfulTrialCount =
                [int](Get-PropertyValue $runSummary "meaningful_trial_count" 0)
            StopReason = [string](Get-PropertyValue $runSummary "stop_reason" "")
            EvidencePath = $file.FullName.Substring(
                $repoRoot.Length + 1).Replace('\', '/')
        })
    }
}

$outputFull = Resolve-ConfiguredPath $OutputPath
[void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $outputFull))
$rows | Sort-Object `
    @{ Expression = "Successful"; Descending = $true },
    @{ Expression = "Program"; Ascending = $true },
    @{ Expression = "OriginalRva"; Ascending = $true } |
    Export-Csv -LiteralPath $outputFull -NoTypeInformation -Encoding UTF8
Write-Host ("Source-shape pattern corpus: {0} evidence rows -> {1}" -f
    $rows.Count, $outputFull)
