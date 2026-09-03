[CmdletBinding()]
param(
    [string]$OutputDirectory = "artifacts\otmatch\session-refresh",
    [string]$CandidateDirectory = "artifacts\otmatch\vc40",
    [switch]$Build,
    [switch]$Rebuild,
    [switch]$SerialPortfolio,
    [switch]$AllowHeuristicReadiness,
    [string]$ReadinessLedgerPath = "",
    [string]$SessionLaneLedgerPath = "",
    [double]$CheckpointStepPercent = 5.0,
    [double]$PortfolioMultiplier = 1.5,
    [int]$Top = 40
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

function Get-FullPath([string]$Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
}

function Invoke-OtScript {
    param([string]$Name, [hashtable]$Arguments)

    $scriptPath = Join-Path $PSScriptRoot $Name
    Write-Host ("==> {0}" -f $Name)
    & $scriptPath @Arguments
    if (-not $?) {
        throw "$Name failed."
    }
}

$outputFull = Get-FullPath $OutputDirectory
$candidateFull = Get-FullPath $CandidateDirectory
$allowedRoots = @(
    (Get-FullPath "a"),
    (Get-FullPath "artifacts")
)
if (-not @($allowedRoots | Where-Object {
            $prefix = $_.TrimEnd('\', '/') +
                [System.IO.Path]::DirectorySeparatorChar
            $outputFull.StartsWith(
                $prefix,
                [System.StringComparison]::OrdinalIgnoreCase)
        }).Count) {
    throw "OutputDirectory must remain beneath the repository's ignored a/ or artifacts/ roots."
}
[void][System.IO.Directory]::CreateDirectory($outputFull)

$candidatePath = Join-Path $candidateFull "otwin-match-candidates.dll"
$candidateMapPath = Join-Path $candidateFull "otwin-match-candidates.map"
if ($Build) {
    $buildArguments = @{
        Toolchain = "LegacyMsvc"
        VcToolsRoot = "C:\msdev"
        OutputDirectory = $candidateFull
        TuMetadataPath = "tools\otmatch\vc4-tu-metadata.csv"
        DefaultOptimization = "/Od"
        SemanticOptimization = "/O1"
    }
    if ($Rebuild) {
        $buildArguments.Rebuild = $true
    }
    Invoke-OtScript "build-match-candidates.ps1" $buildArguments
}

foreach ($required in @($candidatePath, $candidateMapPath)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "Candidate artifact is missing: '$required'. Pass -Build or provide CandidateDirectory."
    }
}

$verifierPath = Join-Path $outputFull "function-match-results.csv"
$maskAuditPath = Join-Path $outputFull "mask-audit.csv"
$metricsPath = Join-Path $outputFull "progress-metrics-summary.json"

Invoke-OtScript "match-functions.ps1" @{
    ManifestPath = "tools\otmatch\functions.vc40-real-cpp.csv"
    OriginalPath = "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe"
    OriginalDllPath = "Sample\Oregon Trail CD\OTWIN32\OREGON32.DLL"
    CandidatePath = $candidatePath
    CandidateMapPath = $candidateMapPath
    CandidateLcmtPath = (Join-Path $candidateFull "otwin-match-candidates-lcmt.dll")
    CandidateLcmtMapPath = (Join-Path $candidateFull "otwin-match-candidates-lcmt.map")
    CandidateDllcrtPath = (Join-Path $candidateFull "otwin-match-candidates-dllcrt.dll")
    CandidateDllcrtMapPath = (Join-Path $candidateFull "otwin-match-candidates-dllcrt.map")
    ResultsCsvPath = $verifierPath
    SummaryOnly = $true
}
Invoke-OtScript "audit-function-masks.ps1" @{
    ManifestPath = "tools\otmatch\functions.vc40-real-cpp.csv"
    OriginalPath = "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe"
    OriginalDllPath = "Sample\Oregon Trail CD\OTWIN32\OREGON32.DLL"
    ResultsCsvPath = $maskAuditPath
    RequireValidated = $true
}
Invoke-OtScript "report-progress-metrics.ps1" @{
    VerifierResultsPath = $verifierPath
    MaskAuditResultsPath = $maskAuditPath
    RequireProductReachability = $true
    SummaryJsonPath = $metricsPath
}

$scanArguments = @{
    CandidatePath = $candidatePath
    CandidateMapPath = $candidateMapPath
    VerifierResultsPath = $verifierPath
    ProgressMetricsSummaryPath = $metricsPath
    OutputDirectory = $outputFull
    CheckpointStepPercent = $CheckpointStepPercent
    PortfolioMultiplier = $PortfolioMultiplier
    Top = $Top
    ApplyMasks = $true
}
if ($SerialPortfolio) {
    $scanArguments.SerialPortfolio = $true
}
if ($AllowHeuristicReadiness) {
    $scanArguments.AllowHeuristicReadiness = $true
}
if (-not [string]::IsNullOrWhiteSpace($ReadinessLedgerPath)) {
    $scanArguments.ReadinessLedgerPath = $ReadinessLedgerPath
}
if (-not [string]::IsNullOrWhiteSpace($SessionLaneLedgerPath)) {
    $scanArguments.SessionLaneLedgerPath = $SessionLaneLedgerPath
}
Invoke-OtScript "scan-wip-residuals.ps1" $scanArguments

Write-Host ""
Write-Host ("Recovery session refreshed: {0}" -f $outputFull)
