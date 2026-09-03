param(
    [switch]$KeepFixture
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$runner = Join-Path $PSScriptRoot "invoke-source-shape-variants.ps1"
$fixtureRoot = Join-Path $repoRoot (
    "a\source-shape-warm-contract-{0}" -f [Guid]::NewGuid().ToString("N"))

function Assert-Contract {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        throw "Source-shape warm-baseline contract failure: $Message"
    }
}

function Write-Utf8Text {
    param([string]$Path, [string]$Text)
    [void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $Path))
    [System.IO.File]::WriteAllText(
        $Path,
        $Text,
        (New-Object System.Text.UTF8Encoding($false)))
}

function Get-CallRecords([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return @()
    }
    return @(Get-Content -LiteralPath $Path | ForEach-Object {
            $_ | ConvertFrom-Json
        })
}

[void][System.IO.Directory]::CreateDirectory($fixtureRoot)
$oldBuildLog = [Environment]::GetEnvironmentVariable(
    "OTMATCH_WARM_BUILD_LOG", "Process")
$oldSource = [Environment]::GetEnvironmentVariable(
    "OTMATCH_WARM_SOURCE", "Process")
$oldHeader = [Environment]::GetEnvironmentVariable(
    "OTMATCH_WARM_HEADER", "Process")
$oldRepoRoot = [Environment]::GetEnvironmentVariable(
    "OTMATCH_WARM_REPO_ROOT", "Process")
$oldDiffDelay = [Environment]::GetEnvironmentVariable(
    "OTMATCH_WARM_DIFF_DELAY_MS", "Process")
$oldBuildDelay = [Environment]::GetEnvironmentVariable(
    "OTMATCH_WARM_BUILD_DELAY_MS", "Process")
[Environment]::SetEnvironmentVariable(
    "OTMATCH_WARM_DIFF_DELAY_MS", $null, "Process")
[Environment]::SetEnvironmentVariable(
    "OTMATCH_WARM_BUILD_DELAY_MS", $null, "Process")

try {
    $sourcePath = Join-Path $fixtureRoot "warm.cpp"
    $headerPath = Join-Path $fixtureRoot "warm.h"
    $originalPath = Join-Path $fixtureRoot "original.bin"
    $buildLog = Join-Path $fixtureRoot "build.log"
    $outputRoot = Join-Path $fixtureRoot "out"
    $outputRelative = $outputRoot.Substring($repoRoot.Length).TrimStart('\', '/')
    $candidatePath = Join-Path $outputRoot "otwin-match-candidates.dll"
    $mapPath = Join-Path $outputRoot "otwin-match-candidates.map"
    $statePath = Join-Path $outputRoot ".otmatch-focused-build-state.json"
    $resultPath = Join-Path $outputRoot "source-shape-variants.csv"
    $evidencePath = Join-Path $outputRoot "source-shape-variants.evidence.json"
    $proofPath = Join-Path $outputRoot "warm-baseline-proof.json"
    Write-Utf8Text $sourcePath "int WarmValue() { return 0; }`n"
    Write-Utf8Text $headerPath "#define WARM_HEADER_VALUE 7`n"
    [System.IO.File]::WriteAllBytes($originalPath, [byte[]](0, 0, 0, 0))

    $fakeBuild = Join-Path $fixtureRoot "fake-build.ps1"
    Write-Utf8Text $fakeBuild @'
param(
    [string[]]$ChangedSource = @(),
    [switch]$Rebuild,
    [string[]]$ExtraCompileFlags = @(),
    [string[]]$ExtraLinkFlags = @(),
    [string]$Toolchain,
    [string]$OutputDirectory,
    [string]$DefaultOptimization,
    [string]$SemanticOptimization,
    [string]$ObjectCacheDirectory,
    [switch]$DisableIncrementalCache,
    [switch]$FocusedChangedSource,
    [switch]$FocusedGraphAlreadyValidated,
    [switch]$ForceMainRelink,
    [switch]$CandidateGraphLockHeld
)
$ErrorActionPreference = "Stop"
$record = [pscustomobject][ordered]@{
    focused = [bool]$FocusedChangedSource
    trusted = [bool]$FocusedGraphAlreadyValidated
    force_relink = [bool]$ForceMainRelink
    changed_source_count = @($ChangedSource).Count
}
[System.IO.File]::AppendAllText(
    $env:OTMATCH_WARM_BUILD_LOG,
    (($record | ConvertTo-Json -Compress) + "`n"))
if ($FocusedGraphAlreadyValidated -and
    -not [string]::IsNullOrWhiteSpace($env:OTMATCH_WARM_BUILD_DELAY_MS)) {
    Start-Sleep -Milliseconds ([int]$env:OTMATCH_WARM_BUILD_DELAY_MS)
}

function Get-Sha([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

$outputRoot = if ([System.IO.Path]::IsPathRooted($OutputDirectory)) {
    $OutputDirectory
} else {
    Join-Path $env:OTMATCH_WARM_REPO_ROOT $OutputDirectory
}
$statePath = Join-Path $outputRoot ".otmatch-focused-build-state.json"
if ($FocusedChangedSource -and -not $FocusedGraphAlreadyValidated -and
    (Test-Path -LiteralPath $statePath -PathType Leaf)) {
    $oldState = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    foreach ($snapshot in @($oldState.sources[0].dependency_snapshots)) {
        if (-not (Test-Path -LiteralPath ([string]$snapshot.Path) -PathType Leaf) -or
            (Get-Sha ([string]$snapshot.Path)) -cne [string]$snapshot.Hash) {
            throw "non-trusting focused dependency validation rejected stale content"
        }
    }
}

[void][System.IO.Directory]::CreateDirectory($outputRoot)
$sourceText = [System.IO.File]::ReadAllText($env:OTMATCH_WARM_SOURCE)
$relativeSource = $env:OTMATCH_WARM_SOURCE.Substring(
    $env:OTMATCH_WARM_REPO_ROOT.Length).TrimStart('\', '/')
$objectName = (($relativeSource -replace '[\\/]', '_') -replace '\.cpp$', '.obj')
$objectPath = Join-Path $outputRoot $objectName
[System.IO.File]::WriteAllBytes(
    $objectPath,
    [System.Text.Encoding]::UTF8.GetBytes($sourceText))

$candidatePath = Join-Path $outputRoot "otwin-match-candidates.dll"
$mapPath = Join-Path $outputRoot "otwin-match-candidates.map"
$pdbPath = Join-Path $outputRoot "otwin-match-candidates.pdb"
$libPath = Join-Path $outputRoot "otwin-match-candidates.lib"
$expPath = Join-Path $outputRoot "otwin-match-candidates.exp"
$payload = [System.Text.Encoding]::UTF8.GetBytes("candidate|" + $sourceText)
[System.IO.File]::WriteAllBytes($candidatePath, $payload)
[System.IO.File]::WriteAllText($mapPath, "map|" + $sourceText)
[System.IO.File]::WriteAllBytes($pdbPath, $payload)
[System.IO.File]::WriteAllBytes($libPath, $payload)
[System.IO.File]::WriteAllBytes($expPath, $payload)

if (-not $FocusedGraphAlreadyValidated) {
    $snapshots = @(
        [pscustomobject][ordered]@{
            Path = $env:OTMATCH_WARM_SOURCE
            Hash = Get-Sha $env:OTMATCH_WARM_SOURCE
            Length = [long](Get-Item -LiteralPath $env:OTMATCH_WARM_SOURCE).Length
            LastWriteTimeUtcTicks = [long](Get-Item -LiteralPath $env:OTMATCH_WARM_SOURCE).LastWriteTimeUtc.Ticks
        },
        [pscustomobject][ordered]@{
            Path = $env:OTMATCH_WARM_HEADER
            Hash = Get-Sha $env:OTMATCH_WARM_HEADER
            Length = [long](Get-Item -LiteralPath $env:OTMATCH_WARM_HEADER).Length
            LastWriteTimeUtcTicks = [long](Get-Item -LiteralPath $env:OTMATCH_WARM_HEADER).LastWriteTimeUtc.Ticks
        })
    $outputs = @($candidatePath, $mapPath, $pdbPath, $libPath, $expPath |
        ForEach-Object {
            [pscustomobject][ordered]@{
                path = $_
                length = [long](Get-Item -LiteralPath $_).Length
                sha256 = Get-Sha $_
            }
        })
    $state = [pscustomobject][ordered]@{
        schema_version = 1
        context_fingerprint = "11" * 32
        graph_fingerprint = "22" * 32
        generated_utc = [DateTime]::UtcNow.ToString("o")
        sources = @([pscustomobject][ordered]@{
                source = $env:OTMATCH_WARM_SOURCE
                kind = "semantic"
                sort_key = "warm.cpp"
                object_name = $objectName
                object_length = [long](Get-Item -LiteralPath $objectPath).Length
                object_sha256 = Get-Sha $objectPath
                has_sections = $true
                compile_fingerprint = "33" * 32
                dependency_snapshots = $snapshots
                pragma_libraries = @()
                pragma_linker_options = @()
            })
        main_outputs = $outputs
    }
    [System.IO.File]::WriteAllText(
        $statePath,
        (($state | ConvertTo-Json -Depth 8) + "`n"),
        (New-Object System.Text.UTF8Encoding($false)))
}
'@

    $fakeDiff = Join-Path $fixtureRoot "fake-diff.ps1"
    Write-Utf8Text $fakeDiff @'
param(
    [string]$OriginalPath,
    [uint64]$OriginalRva,
    [int]$Size,
    [string]$CandidatePath,
    [string]$CandidateMapPath,
    [string]$CandidateSymbol,
    [string]$Mask = ""
)
$delayMs = 0
if (-not [string]::IsNullOrWhiteSpace($env:OTMATCH_WARM_DIFF_DELAY_MS)) {
    $delayMs = [int]$env:OTMATCH_WARM_DIFF_DELAY_MS
}
if ($delayMs -gt 0) {
    Start-Sleep -Milliseconds $delayMs
}
Write-Output "Candidate RVA: 0x00001000"
Write-Output "Differences: 1 / 4"
Write-Output "Hard differences: 1 / 4"
Write-Output "All diff offsets: 0x0"
Write-Output "All hard diff offsets: 0x0"
'@

    $planPath = Join-Path $fixtureRoot "plan.json"
    $plan = [pscustomobject][ordered]@{
        program = "Oregon32.exe"
        name = "WarmValue"
        sourcePath = $sourcePath
        originalRva = "0x0"
        checkpointId = "warm-contract-checkpoint"
        priorBoundaryRunId = "warm-contract-boundary"
        size = "0x4"
        candidateSymbol = "_WarmValue"
        variants = @([pscustomobject][ordered]@{
                name = "one"
                hypothesis = "change the return value"
                meaningful = $true
                replacements = @([pscustomobject][ordered]@{
                        old = "return 0"
                        new = "return 1"
                    })
            })
    }
    Write-Utf8Text $planPath (($plan | ConvertTo-Json -Depth 8) + "`n")

    [Environment]::SetEnvironmentVariable(
        "OTMATCH_WARM_BUILD_LOG", $buildLog, "Process")
    [Environment]::SetEnvironmentVariable(
        "OTMATCH_WARM_SOURCE", $sourcePath, "Process")
    [Environment]::SetEnvironmentVariable(
        "OTMATCH_WARM_HEADER", $headerPath, "Process")
    [Environment]::SetEnvironmentVariable(
        "OTMATCH_WARM_REPO_ROOT", $repoRoot, "Process")

    $runnerParameters = @{
        PlanPath = $planPath
        OriginalPath = $originalPath
        BuildOutputDirectory = $outputRelative
        BuildScriptOverride = $fakeBuild
        DiffScriptOverride = $fakeDiff
        WarmBaselineProofPath = $proofPath
    }

    $unsafeProofParameters = @{}
    foreach ($key in $runnerParameters.Keys) {
        $unsafeProofParameters[$key] = $runnerParameters[$key]
    }
    $unsafeProofParameters.WarmBaselineProofPath = $sourcePath
    $unsafeProofRejected = $false
    try {
        [void](& $runner @unsafeProofParameters 2>&1)
    } catch {
        $unsafeProofRejected = ($_.Exception.Message -match
            "warm_baseline_proof.*aliases reserved source path")
    }
    Assert-Contract $unsafeProofRejected `
        "warm proof must not alias the source it is meant to protect"
    Assert-Contract (@(Get-CallRecords $buildLog).Count -eq 0) `
        "unsafe warm-proof output should be rejected before any build"

    $relativeSource = $sourcePath.Substring($repoRoot.Length).TrimStart('\', '/')
    $focusedObjectName = (($relativeSource -replace '[\\/]', '_') -replace
        '\.cpp$', '.obj')
    $focusedObjectPath = Join-Path $outputRoot $focusedObjectName
    $objectAliasParameters = @{}
    foreach ($key in $runnerParameters.Keys) {
        $objectAliasParameters[$key] = $runnerParameters[$key]
    }
    $objectAliasParameters.WarmBaselineProofPath = $focusedObjectPath
    $objectAliasRejected = $false
    try {
        [void](& $runner @objectAliasParameters 2>&1)
    } catch {
        $objectAliasRejected = ($_.Exception.Message -match
            "warm_baseline_proof.*aliases reserved focused_object path")
    }
    Assert-Contract $objectAliasRejected `
        "warm proof must not alias the focused candidate object"
    Assert-Contract (@(Get-CallRecords $buildLog).Count -eq 0 -and
        -not (Test-Path -LiteralPath $focusedObjectPath)) `
        "focused-object alias should be rejected before build or publication"

    $nonJsonProofParameters = @{}
    foreach ($key in $runnerParameters.Keys) {
        $nonJsonProofParameters[$key] = $runnerParameters[$key]
    }
    $nonJsonProofParameters.WarmBaselineProofPath =
        (Join-Path $outputRoot "warm-baseline-proof.bin")
    $nonJsonProofRejected = $false
    try {
        [void](& $runner @nonJsonProofParameters 2>&1)
    } catch {
        $nonJsonProofRejected = ($_.Exception.Message -match
            "warm_baseline_proof.*must name a \.json file")
    }
    Assert-Contract $nonJsonProofRejected `
        "warm proof must use its canonical JSON artifact extension"
    Assert-Contract (@(Get-CallRecords $buildLog).Count -eq 0) `
        "non-JSON warm-proof output should be rejected before any build"

    [void](& $runner @runnerParameters 2>&1)
    $coldCalls = Get-CallRecords $buildLog
    Assert-Contract ($coldCalls.Count -eq 5) `
        "cold run should use three setup builds, one trial, and restoration"
    Assert-Contract (-not [bool]$coldCalls[0].focused -and
        [bool]$coldCalls[1].focused -and [bool]$coldCalls[1].trusted -and
        [bool]$coldCalls[1].force_relink -and
        [bool]$coldCalls[2].focused -and [bool]$coldCalls[2].trusted -and
        [bool]$coldCalls[2].force_relink) `
        "cold setup should remain a normal seed plus two trusted forced relinks"
    Assert-Contract ([bool]$coldCalls[4].focused -and
        -not [bool]$coldCalls[4].trusted -and
        -not [bool]$coldCalls[4].force_relink) `
        "cold run should finish with non-trusting focused restoration"
    Assert-Contract (Test-Path -LiteralPath $proofPath -PathType Leaf) `
        "successful restoration should publish the warm proof"
    Assert-Contract (Test-Path -LiteralPath $evidencePath -PathType Leaf) `
        "cold run should publish source-shape evidence"
    $coldEvidence = Get-Content -LiteralPath $evidencePath -Raw |
        ConvertFrom-Json
    $coldRows = @(Import-Csv -LiteralPath $resultPath)
    $coldTrialToolTimeMs = 0L
    $coldTrialWallTimeMs = 0L
    foreach ($row in $coldRows) {
        $coldTrialToolTimeMs += [long]$row.BuildDurationMs +
            [long]$row.DiffDurationMs
        $coldTrialWallTimeMs += [long]$row.TotalDurationMs
    }
    Assert-Contract ($null -ne $coldEvidence.PSObject.Properties["run_summary"] -and
        -not [bool]$coldEvidence.run_summary.warm_baseline_reused -and
        [int]$coldEvidence.run_summary.trial_count -eq 1 -and
        [int]$coldEvidence.run_summary.meaningful_trial_count -eq 1 -and
        [int]$coldEvidence.run_summary.maximum_focused_build_seconds -eq 15 -and
        [int]$coldEvidence.run_summary.maximum_focused_diff_seconds -eq 30 -and
        -not [bool]$coldEvidence.run_summary.build_latency_budget_exceeded -and
        -not [bool]$coldEvidence.run_summary.diff_latency_budget_exceeded -and
        [long]$coldEvidence.run_summary.baseline_setup_duration_ms -ge 0 -and
        [long]$coldEvidence.run_summary.baseline_diff_duration_ms -ge 0 -and
        [long]$coldEvidence.run_summary.trial_tool_time_ms -eq
            $coldTrialToolTimeMs -and
        [long]$coldEvidence.run_summary.trial_wall_time_ms -eq
            $coldTrialWallTimeMs -and
        [long]$coldEvidence.run_summary.variant_loop_duration_ms -ge
            $coldTrialWallTimeMs -and
        [long]$coldEvidence.run_summary.restoration_duration_ms -ge 0 -and
        [long]$coldEvidence.run_summary.runner_elapsed_before_evidence_ms -ge
            ([long]$coldEvidence.run_summary.baseline_setup_duration_ms +
             [long]$coldEvidence.run_summary.baseline_diff_duration_ms +
             [long]$coldEvidence.run_summary.variant_loop_duration_ms +
             [long]$coldEvidence.run_summary.restoration_duration_ms) -and
        [bool]$coldEvidence.restoration.attempted -and
        [bool]$coldEvidence.restoration.passed -and
        -not [bool]$coldEvidence.restoration.used_trusted_graph -and
        [string]::IsNullOrWhiteSpace(
            [string]$coldEvidence.run_summary.stop_reason)) `
        "evidence should preserve honest cold setup/trial/restoration timing"
    $proof = Get-Content -LiteralPath $proofPath -Raw | ConvertFrom-Json
    Assert-Contract ([int]$proof.schema_version -eq 1 -and
        $proof.artifact_type -eq "otmatch-source-shape-warm-baseline" -and
        [string]$proof.focused_context_fingerprint -eq ("11" * 32) -and
        [string]$proof.candidate_graph_fingerprint -eq ("22" * 32) -and
        [string]$proof.source_graph_sha256 -match '^[0-9a-f]{64}$' -and
        [string]$proof.main_outputs_sha256 -match '^[0-9a-f]{64}$') `
        "proof should bind toolchain context, graph/source records, and outputs"

    $callsBeforeWarm = $coldCalls.Count
    [void](& $runner @runnerParameters 2>&1)
    $allCalls = Get-CallRecords $buildLog
    $warmCalls = @($allCalls | Select-Object -Skip $callsBeforeWarm)
    Assert-Contract ($warmCalls.Count -eq 3) `
        "warm run should use one setup build, one trial, and restoration"
    Assert-Contract ([bool]$warmCalls[0].focused -and
        -not [bool]$warmCalls[0].trusted -and
        -not [bool]$warmCalls[0].force_relink) `
        "warm setup should be exactly one non-trusting focused validation"
    Assert-Contract ([bool]$warmCalls[2].focused -and
        -not [bool]$warmCalls[2].trusted -and
        -not [bool]$warmCalls[2].force_relink) `
        "warm reuse must retain mandatory non-trusting restoration"
    $warmEvidence = Get-Content -LiteralPath $evidencePath -Raw |
        ConvertFrom-Json
    Assert-Contract ([bool]$warmEvidence.run_summary.warm_baseline_reused -and
        [int]$warmEvidence.run_summary.trial_count -eq 1 -and
        -not [bool]$warmEvidence.run_summary.build_latency_budget_exceeded -and
        -not [bool]$warmEvidence.run_summary.diff_latency_budget_exceeded -and
        [bool]$warmEvidence.restoration.attempted -and
        [bool]$warmEvidence.restoration.passed -and
        -not [bool]$warmEvidence.restoration.used_trusted_graph) `
        "warm evidence should identify proof reuse and retain latency telemetry"
    Assert-Contract ([System.IO.File]::ReadAllText($sourcePath) -eq
        "int WarmValue() { return 0; }`n") `
        "warm run should restore exact source content"

    # A slow first trial must stop the remaining batch while preserving the
    # completed result and mandatory non-trusting restoration.
    $plan.variants = @(
        $plan.variants[0],
        [pscustomobject][ordered]@{
            name = "two"
            hypothesis = "try a second return value"
            meaningful = $true
            replacements = @([pscustomobject][ordered]@{
                    old = "return 0"
                    new = "return 2"
                })
        })
    Write-Utf8Text $planPath (($plan | ConvertTo-Json -Depth 8) + "`n")
    [Environment]::SetEnvironmentVariable(
        "OTMATCH_WARM_DIFF_DELAY_MS", "1100", "Process")
    $latencyParameters = @{}
    foreach ($key in $runnerParameters.Keys) {
        $latencyParameters[$key] = $runnerParameters[$key]
    }
    $latencyParameters.MaximumFocusedDiffSeconds = 1
    $callsBeforeLatency = (Get-CallRecords $buildLog).Count
    [void](& $runner @latencyParameters 2>&1)
    $latencyCalls = @((Get-CallRecords $buildLog) |
        Select-Object -Skip $callsBeforeLatency)
    Assert-Contract ($latencyCalls.Count -eq 3) `
        "latency stop should use one warm setup, one trial, and restoration"
    $latencyRows = @(Import-Csv -LiteralPath $resultPath)
    $latencyEvidence = Get-Content -LiteralPath $evidencePath -Raw |
        ConvertFrom-Json
    $latencyTrialToolTimeMs = 0L
    $latencyTrialWallTimeMs = 0L
    foreach ($row in $latencyRows) {
        $latencyTrialToolTimeMs += [long]$row.BuildDurationMs +
            [long]$row.DiffDurationMs
        $latencyTrialWallTimeMs += [long]$row.TotalDurationMs
    }
    Assert-Contract ($latencyRows.Count -eq 1 -and
        [string]$latencyRows[0].Variant -eq "one" -and
        [int]$latencyEvidence.run_summary.trial_count -eq 1 -and
        -not [bool]$latencyEvidence.run_summary.build_latency_budget_exceeded -and
        [bool]$latencyEvidence.run_summary.diff_latency_budget_exceeded -and
        [int]$latencyEvidence.run_summary.maximum_focused_build_seconds -eq 15 -and
        [int]$latencyEvidence.run_summary.maximum_focused_diff_seconds -eq 1 -and
        [long]$latencyEvidence.run_summary.baseline_diff_duration_ms -ge 1000 -and
        [long]$latencyEvidence.run_summary.trial_tool_time_ms -eq
            $latencyTrialToolTimeMs -and
        [long]$latencyEvidence.run_summary.trial_wall_time_ms -eq
            $latencyTrialWallTimeMs -and
        [bool]$latencyEvidence.restoration.attempted -and
        [bool]$latencyEvidence.restoration.passed -and
        -not [bool]$latencyEvidence.restoration.used_trusted_graph -and
        [string]$latencyEvidence.run_summary.stop_reason -match
            '^focused-diff latency budget exceeded') `
        "slow first trial should durably stop a two-variant batch"
    Assert-Contract ([bool]$latencyCalls[-1].focused -and
        -not [bool]$latencyCalls[-1].trusted -and
        -not [bool]$latencyCalls[-1].force_relink) `
        "latency stop should finish with non-trusting restoration"
    Assert-Contract ([System.IO.File]::ReadAllText($sourcePath) -eq
        "int WarmValue() { return 0; }`n") `
        "latency stop should restore exact source content"

    # The build budget is independent from the diff budget and identifies a
    # slow focused compile/relink without delaying setup or restoration.
    [Environment]::SetEnvironmentVariable(
        "OTMATCH_WARM_DIFF_DELAY_MS", $null, "Process")
    [Environment]::SetEnvironmentVariable(
        "OTMATCH_WARM_BUILD_DELAY_MS", "1100", "Process")
    $buildLatencyParameters = @{}
    foreach ($key in $runnerParameters.Keys) {
        $buildLatencyParameters[$key] = $runnerParameters[$key]
    }
    $buildLatencyParameters.MaximumFocusedBuildSeconds = 1
    $callsBeforeBuildLatency = (Get-CallRecords $buildLog).Count
    [void](& $runner @buildLatencyParameters 2>&1)
    $buildLatencyCalls = @((Get-CallRecords $buildLog) |
        Select-Object -Skip $callsBeforeBuildLatency)
    $buildLatencyRows = @(Import-Csv -LiteralPath $resultPath)
    $buildLatencyEvidence = Get-Content -LiteralPath $evidencePath -Raw |
        ConvertFrom-Json
    Assert-Contract ($buildLatencyCalls.Count -eq 3 -and
        $buildLatencyRows.Count -eq 1 -and
        [string]$buildLatencyRows[0].Variant -eq "one" -and
        [long]$buildLatencyRows[0].BuildDurationMs -ge 1000 -and
        [bool]$buildLatencyEvidence.run_summary.build_latency_budget_exceeded -and
        -not [bool]$buildLatencyEvidence.run_summary.diff_latency_budget_exceeded -and
        [int]$buildLatencyEvidence.run_summary.maximum_focused_build_seconds -eq 1 -and
        [int]$buildLatencyEvidence.run_summary.maximum_focused_diff_seconds -eq 30 -and
        [bool]$buildLatencyEvidence.restoration.attempted -and
        [bool]$buildLatencyEvidence.restoration.passed -and
        -not [bool]$buildLatencyEvidence.restoration.used_trusted_graph -and
        [string]$buildLatencyEvidence.run_summary.stop_reason -match
            '^focused-build latency budget exceeded') `
        "slow focused build should stop independently of a healthy diff"
    Assert-Contract ([bool]$buildLatencyCalls[-1].focused -and
        -not [bool]$buildLatencyCalls[-1].trusted -and
        -not [bool]$buildLatencyCalls[-1].force_relink -and
        [System.IO.File]::ReadAllText($sourcePath) -eq
            "int WarmValue() { return 0; }`n") `
        "build-latency stop should finish with exact non-trusting restoration"
    $plan.variants = @($plan.variants[0])
    Write-Utf8Text $planPath (($plan | ConvertTo-Json -Depth 8) + "`n")
    [Environment]::SetEnvironmentVariable(
        "OTMATCH_WARM_DIFF_DELAY_MS", $null, "Process")
    [Environment]::SetEnvironmentVariable(
        "OTMATCH_WARM_BUILD_DELAY_MS", $null, "Process")
    $allCalls = Get-CallRecords $buildLog

    # A dependency change is discovered by the required non-trusting warm
    # validation before the runner writes any trial source.
    $callsBeforeStaleDependency = $allCalls.Count
    Write-Utf8Text $headerPath "#define WARM_HEADER_VALUE 8`n"
    $staleDependencyRejected = $false
    try {
        [void](& $runner @runnerParameters 2>&1)
    } catch {
        $staleDependencyRejected = ($_.Exception.Message -match
            "dependency validation rejected stale content")
    }
    Assert-Contract $staleDependencyRejected `
        "changed source-graph dependency should fail closed"
    $afterStaleDependency = Get-CallRecords $buildLog
    Assert-Contract ($afterStaleDependency.Count -eq
        ($callsBeforeStaleDependency + 1)) `
        "stale dependency should stop in the single warm validation build"
    Assert-Contract ([System.IO.File]::ReadAllText($sourcePath) -eq
        "int WarmValue() { return 0; }`n") `
        "stale dependency rejection should occur before trial mutation"
    Write-Utf8Text $headerPath "#define WARM_HEADER_VALUE 7`n"

    # Output tampering is rejected directly by the proof/state boundary, with
    # no build invocation and no cold fallback.
    $candidateBytes = [System.IO.File]::ReadAllBytes($candidatePath)
    [System.IO.File]::WriteAllBytes($candidatePath, [byte[]](9, 9, 9))
    $callsBeforeTamper = (Get-CallRecords $buildLog).Count
    $tamperedOutputRejected = $false
    try {
        [void](& $runner @runnerParameters 2>&1)
    } catch {
        $tamperedOutputRejected = ($_.Exception.Message -match
            "main output is stale")
    }
    Assert-Contract $tamperedOutputRejected `
        "tampered baseline output should fail closed"
    Assert-Contract ((Get-CallRecords $buildLog).Count -eq $callsBeforeTamper) `
        "tampered output should be rejected before any build"
    [System.IO.File]::WriteAllBytes($candidatePath, $candidateBytes)

    # Tool/build orchestration participates in the proof key as well.
    $fakeBuildBytes = [System.IO.File]::ReadAllBytes($fakeBuild)
    [System.IO.File]::WriteAllText($fakeBuild, "# stale tool`n")
    $callsBeforeToolChange = (Get-CallRecords $buildLog).Count
    $toolChangeRejected = $false
    try {
        [void](& $runner @runnerParameters 2>&1)
    } catch {
        $toolChangeRejected = ($_.Exception.Message -match
            "mismatched binding.*build_script_sha256")
    }
    Assert-Contract $toolChangeRejected `
        "changed build orchestration should invalidate the proof"
    Assert-Contract ((Get-CallRecords $buildLog).Count -eq $callsBeforeToolChange) `
        "changed build orchestration should be rejected before any build"
    [System.IO.File]::WriteAllBytes($fakeBuild, $fakeBuildBytes)

    Assert-Contract (-not (Test-Path -LiteralPath $resultPath -PathType Leaf) -and
        -not (Test-Path -LiteralPath $evidencePath -PathType Leaf)) `
        "stale warm starts should remove prior diagnostic/promotion outputs"
    Write-Host ("Source-shape warm baseline contract: PASS " +
        "(cold setup 3 calls; warm setup 1 call; 67% fewer setup calls)")
} finally {
    [Environment]::SetEnvironmentVariable(
        "OTMATCH_WARM_BUILD_LOG", $oldBuildLog, "Process")
    [Environment]::SetEnvironmentVariable(
        "OTMATCH_WARM_SOURCE", $oldSource, "Process")
    [Environment]::SetEnvironmentVariable(
        "OTMATCH_WARM_HEADER", $oldHeader, "Process")
    [Environment]::SetEnvironmentVariable(
        "OTMATCH_WARM_REPO_ROOT", $oldRepoRoot, "Process")
    [Environment]::SetEnvironmentVariable(
        "OTMATCH_WARM_DIFF_DELAY_MS", $oldDiffDelay, "Process")
    [Environment]::SetEnvironmentVariable(
        "OTMATCH_WARM_BUILD_DELAY_MS", $oldBuildDelay, "Process")
    if (-not $KeepFixture -and
        (Test-Path -LiteralPath $fixtureRoot -PathType Container)) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}
