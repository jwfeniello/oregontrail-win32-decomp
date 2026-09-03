[CmdletBinding()]
param(
    [switch]$KeepFixture
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$generatorPath = (Resolve-Path (Join-Path $PSScriptRoot `
    "new-source-shape-plan.ps1")).Path
$lockStatusPath = (Resolve-Path (Join-Path $PSScriptRoot `
    "get-candidate-graph-lock-status.ps1")).Path
$runnerPath = (Resolve-Path (Join-Path $PSScriptRoot `
    "invoke-source-shape-variants.ps1")).Path
$shellPath = (Get-Process -Id $PID).Path
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$contractId = [guid]::NewGuid().ToString("N")
$fixtureRoot = Join-Path $repoRoot (
    "a\otmatch-source-shape-plan-contract-" + $contractId)
$sourceFixtureRoot = Join-Path $fixtureRoot "src\otwin"
$sourcePath = Join-Path $sourceFixtureRoot "plan_target.cpp"
$manifestPath = Join-Path $fixtureRoot "manifest.csv"
$ambiguousManifestPath = Join-Path $fixtureRoot "ambiguous-manifest.csv"
$variantSpecPath = Join-Path $fixtureRoot "variants.json"
$planPath = Join-Path $fixtureRoot "plan.json"
$namePlanPath = Join-Path $fixtureRoot "name-plan.json"
$specPlanPath = Join-Path $fixtureRoot "spec-plan.json"
$ambiguousPlanPath = Join-Path $fixtureRoot "ambiguous-plan.json"
$missingPlanPath = Join-Path $fixtureRoot "missing-plan.json"
$unsafePlanPath = Join-Path $repoRoot (
    "tools\otmatch\unsafe-plan-contract-" + $contractId + ".json")
$lockPath = Join-Path $fixtureRoot ".candidate-graph.lock"
$holderPath = Join-Path $fixtureRoot "lock-holder.ps1"
$readyPath = Join-Path $fixtureRoot "lock-ready.txt"
$fakePlanPath = Join-Path $fixtureRoot "active-variants.json"
$sourceJunctionPath = Join-Path $fixtureRoot "source-junction"
$holderProcess = $null

function Assert-True([bool]$Condition, [string]$Context) {
    if (-not $Condition) {
        throw $Context
    }
}

function Assert-Equal($Actual, $Expected, [string]$Context) {
    if ([string]$Actual -cne [string]$Expected) {
        throw "$Context expected '$Expected', got '$Actual'."
    }
}

function Assert-ThrowsLike {
    param(
        [scriptblock]$Action,
        [string]$Pattern,
        [string]$Context
    )

    $observed = $false
    $message = ""
    try {
        & $Action
    } catch {
        $message = $_.Exception.Message
        $observed = $message -match $Pattern
    }
    if (-not $observed) {
        throw "$Context expected error /$Pattern/; observed '$message'."
    }
}

function Write-Utf8([string]$Path, [string]$Text) {
    [void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $Path))
    [System.IO.File]::WriteAllText($Path, $Text, $utf8NoBom)
}

function Write-Json([string]$Path, $Value) {
    Write-Utf8 $Path (($Value | ConvertTo-Json -Depth 20) + "`n")
}

function Write-Csv([string]$Path, [object[]]$Rows) {
    Write-Utf8 $Path ((@($Rows | ConvertTo-Csv -NoTypeInformation) -join "`n") + "`n")
}

function Get-RepoRelativePath([string]$Path) {
    $resolved = [System.IO.Path]::GetFullPath($Path)
    $prefix = $repoRoot.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith(
            $prefix,
            [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Fixture path is outside the repository: '$resolved'."
    }
    return $resolved.Substring($prefix.Length).Replace('\', '/')
}

function Get-CandidateObjectName([string]$Path) {
    return (((Get-RepoRelativePath $Path) -replace '/', '_') -replace
        '\.cpp$', '.obj')
}

function Get-FileSha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.
        ToLowerInvariant()
}

function Invoke-Generator($Parameters) {
    return @(& $generatorPath @Parameters -PassThru)
}

try {
    [void][System.IO.Directory]::CreateDirectory($fixtureRoot)
    [void][System.IO.Directory]::CreateDirectory($sourceFixtureRoot)
    Write-Utf8 $sourcePath @'
// Synthetic contract source; contains no original game assets or bytes.
extern "C" int OtPlanContract_Product()
{
    int value = 1;
    return value;
}
'@
    $sourceBytes = [System.IO.File]::ReadAllBytes($sourcePath)
    $candidateObject = Get-CandidateObjectName $sourcePath
    $manifestRow = [pscustomobject][ordered]@{
        name = "OtPlanContract"
        program = "Oregon32.exe"
        original_va = "0x00401000"
        original_rva = "0x00001000"
        size = "0x00000020"
        candidate_va = ""
        candidate_rva = ""
        candidate_symbol = "_OtPlanContract_Product"
        candidate_dll = ""
        candidate_object = $candidateObject
        expected_status = "wip"
        implementation_kind = "cpp"
        mask = "4-7 12-15"
        notes = "Synthetic source-shape planning contract row."
    }
    Write-Csv $manifestPath @($manifestRow)
    $manifestBytes = [System.IO.File]::ReadAllBytes($manifestPath)

    $common = @{
        Program = "Oregon32.exe"
        OriginalRva = "0x1000"
        CheckpointId = "contract-checkpoint"
        PriorBoundaryRunId = "contract-boundary"
        ManifestPath = $manifestPath
        SourceSearchRoot = $sourceFixtureRoot
        OutputPath = $planPath
        VariantName = "direct-shape"
        Hypothesis = "Changing the local initializer tests a direct exact anchor."
        OldText = "int value = 1;"
        NewText = "int value = 2;"
    }
    $result = @(Invoke-Generator $common)
    Assert-True ($result.Count -eq 1 -and [bool]$result[0].passed) `
        "RVA-only direct generation should pass."
    Assert-True (Test-Path -LiteralPath $planPath -PathType Leaf) `
        "Generator did not publish the plan."

    $plan = Get-Content -LiteralPath $planPath -Raw | ConvertFrom-Json
    Assert-Equal $plan.planSchemaVersion 1 "Plan schema"
    Assert-Equal $plan.program "Oregon32.exe" "Canonical program"
    Assert-Equal $plan.name "OtPlanContract" "Canonical function name"
    Assert-Equal $plan.originalRva "0x00001000" "Canonical original RVA"
    Assert-Equal $plan.size "0x00000020" "Manifest size"
    Assert-Equal $plan.candidateSymbol "_OtPlanContract_Product" `
        "Manifest candidate symbol"
    Assert-Equal $plan.mask "4-7 12-15" "Current manifest mask"
    Assert-Equal $plan.sourcePath (Get-RepoRelativePath $sourcePath) `
        "Inferred source path"
    Assert-Equal $plan.sourcePreflight.sourceSha256 (Get-FileSha256 $sourcePath) `
        "Exact source hash"
    Assert-Equal $plan.sourcePreflight.sourceLength $sourceBytes.LongLength `
        "Exact source length"
    Assert-Equal @($plan.sourcePreflight.anchors).Count 1 `
        "One direct replacement anchor"
    Assert-Equal $plan.sourcePreflight.anchors[0].expectedOccurrences 1 `
        "Exact anchor occurrence contract"
    Assert-Equal $plan.checkpointId "contract-checkpoint" "Checkpoint ID"
    Assert-Equal $plan.priorBoundaryRunId "contract-boundary" `
        "Prior boundary run ID"
    Assert-Equal $plan.manifestBinding.candidateObject $candidateObject `
        "Manifest candidate object binding"

    $preflight = @(& $generatorPath -PreflightOnly -PlanPath $planPath -PassThru)
    Assert-True ($preflight.Count -eq 1 -and [bool]$preflight[0].passed) `
        "Fresh generated plan should pass preflight."

    [System.IO.File]::AppendAllText(
        $manifestPath,
        "# manifest drift`n",
        $utf8NoBom)
    Assert-ThrowsLike {
        & $generatorPath -PreflightOnly -PlanPath $planPath
    } 'Manifest snapshot hash mismatch.*Regenerate the plan' `
        "Stale manifest snapshot"

    # The costly runner must enforce generated-plan preflight itself. A stale
    # plan must fail while holding the graph lock but before it calls a build,
    # removes prior diagnostic evidence, or mutates the source.
    $runnerOutputRoot = Join-Path $fixtureRoot "runner-out"
    $runnerResultPath = Join-Path $runnerOutputRoot "results.csv"
    $runnerEvidencePath = Join-Path $runnerOutputRoot "results.evidence.json"
    $runnerWarmProofPath = Join-Path $runnerOutputRoot `
        "warm-baseline-proof.json"
    $runnerBuildMarker = Join-Path $fixtureRoot "runner-build-called.txt"
    $runnerOriginalPath = Join-Path $fixtureRoot "original.bin"
    $runnerBuildPath = Join-Path $fixtureRoot "fake-runner-build.ps1"
    $runnerDiffPath = Join-Path $fixtureRoot "fake-runner-diff.ps1"
    $mutatingPlanPreflightPath = Join-Path $fixtureRoot `
        "mutating-plan-preflight.ps1"
    $mutatingSourcePreflightPath = Join-Path $fixtureRoot `
        "mutating-source-preflight.ps1"
    [void][System.IO.Directory]::CreateDirectory($runnerOutputRoot)
    Write-Utf8 $runnerResultPath "preserve prior CSV evidence`n"
    Write-Utf8 $runnerEvidencePath "preserve prior JSON evidence`n"
    Write-Utf8 $runnerWarmProofPath "preserve prior warm proof`n"
    [System.IO.File]::WriteAllBytes($runnerOriginalPath, [byte[]](0, 0, 0, 0))
    Write-Utf8 $runnerBuildPath @'
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
[System.IO.File]::WriteAllText(
    (Join-Path (Split-Path -Parent $PSCommandPath) "runner-build-called.txt"),
    "called")
throw "Generated-plan preflight allowed an unexpected build."
'@
    Write-Utf8 $runnerDiffPath @'
throw "Generated-plan preflight allowed an unexpected diff."
'@
    Assert-ThrowsLike {
        & $runnerPath `
            -PlanPath $planPath `
            -OriginalPath $runnerOriginalPath `
            -CandidatePath (Join-Path $runnerOutputRoot "candidate.dll") `
            -CandidateMapPath (Join-Path $runnerOutputRoot "candidate.map") `
            -BuildOutputDirectory $runnerOutputRoot `
            -ResultCsvPath $runnerResultPath `
            -EvidenceJsonPath $runnerEvidencePath `
            -WarmBaselineProofPath $runnerWarmProofPath `
            -BuildScriptOverride $runnerBuildPath `
            -DiffScriptOverride $runnerDiffPath
    } 'Generated source-shape plan preflight failed before build or evidence mutation' `
        "Runner-generated plan preflight"
    Assert-True (-not (Test-Path -LiteralPath $runnerBuildMarker)) `
        "Stale generated plan must be rejected before the build script runs."
    Assert-Equal ([System.IO.File]::ReadAllText($runnerResultPath)) `
        "preserve prior CSV evidence`n" `
        "Generated-plan preflight must preserve prior CSV evidence"
    Assert-Equal ([System.IO.File]::ReadAllText($runnerEvidencePath)) `
        "preserve prior JSON evidence`n" `
        "Generated-plan preflight must preserve prior JSON evidence"
    Assert-Equal ([System.IO.File]::ReadAllText($runnerWarmProofPath)) `
        "preserve prior warm proof`n" `
        "Generated-plan preflight must preserve the prior warm proof"
    [System.IO.File]::WriteAllBytes($manifestPath, $manifestBytes)

    # The runner parses before entering the graph lock, while the external
    # preflight independently rereads the plan. Bind those two views so a
    # replaced plan cannot be validated while stale in-memory variants run.
    $freshPlanBytes = [System.IO.File]::ReadAllBytes($planPath)
    Write-Utf8 $mutatingPlanPreflightPath @'
param(
    [switch]$PreflightOnly,
    [string]$PlanPath
)
[System.IO.File]::AppendAllText($PlanPath, " ")
Write-Output "Synthetic plan mutation completed."
'@
    Assert-ThrowsLike {
        & $runnerPath `
            -PlanPath $planPath `
            -OriginalPath $runnerOriginalPath `
            -CandidatePath (Join-Path $runnerOutputRoot "candidate.dll") `
            -CandidateMapPath (Join-Path $runnerOutputRoot "candidate.map") `
            -BuildOutputDirectory $runnerOutputRoot `
            -ResultCsvPath $runnerResultPath `
            -EvidenceJsonPath $runnerEvidencePath `
            -WarmBaselineProofPath $runnerWarmProofPath `
            -BuildScriptOverride $runnerBuildPath `
            -DiffScriptOverride $runnerDiffPath `
            -PlanPreflightScriptOverride $mutatingPlanPreflightPath
    } 'plan bytes changed across graph-lock acquisition or external preflight' `
        "Runner plan TOCTOU binding"
    Assert-True (-not (Test-Path -LiteralPath $runnerBuildMarker)) `
        "Changed plan bytes must be rejected before the build script runs."
    Assert-Equal ([System.IO.File]::ReadAllText($runnerResultPath)) `
        "preserve prior CSV evidence`n" `
        "Plan TOCTOU rejection must preserve prior CSV evidence"
    Assert-Equal ([System.IO.File]::ReadAllText($runnerEvidencePath)) `
        "preserve prior JSON evidence`n" `
        "Plan TOCTOU rejection must preserve prior JSON evidence"
    Assert-Equal ([System.IO.File]::ReadAllText($runnerWarmProofPath)) `
        "preserve prior warm proof`n" `
        "Plan TOCTOU rejection must preserve the prior warm proof"
    [System.IO.File]::WriteAllBytes($planPath, $freshPlanBytes)

    # A source writer can race the successful external preflight. The runner's
    # own byte/length binding must reject that drift before deleting evidence.
    $sourceLiteral = $sourcePath.Replace("'", "''")
    Write-Utf8 $mutatingSourcePreflightPath @"
param(
    [switch]`$PreflightOnly,
    [string]`$PlanPath
)
[System.IO.File]::AppendAllText(
    '$sourceLiteral',
    "// synthetic post-preflight source drift``n")
Write-Output "Synthetic source mutation completed."
"@
    Assert-ThrowsLike {
        & $runnerPath `
            -PlanPath $planPath `
            -OriginalPath $runnerOriginalPath `
            -CandidatePath (Join-Path $runnerOutputRoot "candidate.dll") `
            -CandidateMapPath (Join-Path $runnerOutputRoot "candidate.map") `
            -BuildOutputDirectory $runnerOutputRoot `
            -ResultCsvPath $runnerResultPath `
            -EvidenceJsonPath $runnerEvidencePath `
            -WarmBaselineProofPath $runnerWarmProofPath `
            -BuildScriptOverride $runnerBuildPath `
            -DiffScriptOverride $runnerDiffPath `
            -PlanPreflightScriptOverride $mutatingSourcePreflightPath
    } 'source binding changed after preflight' `
        "Runner post-preflight source binding"
    Assert-True (-not (Test-Path -LiteralPath $runnerBuildMarker)) `
        "Post-preflight source drift must be rejected before a build."
    Assert-Equal ([System.IO.File]::ReadAllText($runnerResultPath)) `
        "preserve prior CSV evidence`n" `
        "Source-binding rejection must preserve prior CSV evidence"
    Assert-Equal ([System.IO.File]::ReadAllText($runnerEvidencePath)) `
        "preserve prior JSON evidence`n" `
        "Source-binding rejection must preserve prior JSON evidence"
    Assert-Equal ([System.IO.File]::ReadAllText($runnerWarmProofPath)) `
        "preserve prior warm proof`n" `
        "Source-binding rejection must preserve the prior warm proof"
    [System.IO.File]::WriteAllBytes($sourcePath, $sourceBytes)

    $tamperedIdentityPlan = Get-Content -LiteralPath $planPath -Raw |
        ConvertFrom-Json
    $tamperedIdentityPlan.candidateSymbol = "_OtPlanContract_Other"
    Write-Json $planPath $tamperedIdentityPlan
    Assert-ThrowsLike {
        & $generatorPath -PreflightOnly -PlanPath $planPath
    } 'does not match its bound manifest row: candidateSymbol' `
        "Tampered manifest-row binding"
    $common.Force = $true
    [void](Invoke-Generator $common)
    $common.Remove("Force")

    $missingAnchorsPlan = Get-Content -LiteralPath $planPath -Raw |
        ConvertFrom-Json
    $missingAnchorsPlan.sourcePreflight.anchors = $null
    Write-Json $planPath $missingAnchorsPlan
    Assert-ThrowsLike {
        & $generatorPath -PreflightOnly -PlanPath $planPath
    } 'sourcePreflight\.anchors must be a JSON array' `
        "Null anchor metadata"
    $common.Force = $true
    [void](Invoke-Generator $common)
    $common.Remove("Force")

    [void](New-Item -ItemType Junction -Path $sourceJunctionPath `
        -Target $sourceFixtureRoot)
    try {
        $junctionParameters = @{}
        foreach ($entry in $common.GetEnumerator()) {
            $junctionParameters[$entry.Key] = $entry.Value
        }
        $junctionParameters.SourcePath = Join-Path $sourceJunctionPath `
            "plan_target.cpp"
        $junctionParameters.OutputPath = Join-Path $fixtureRoot `
            "junction-plan.json"
        Assert-ThrowsLike {
            [void](Invoke-Generator $junctionParameters)
        } 'cannot traverse reparse point' "Reparse-point source path"

        $junctionOutputParameters = @{}
        foreach ($entry in $common.GetEnumerator()) {
            $junctionOutputParameters[$entry.Key] = $entry.Value
        }
        $junctionOutputParameters.OutputPath = Join-Path $sourceJunctionPath `
            "escaped-plan.json"
        Assert-ThrowsLike {
            [void](Invoke-Generator $junctionOutputParameters)
        } 'cannot traverse reparse point' "Reparse-point output path"
        Assert-True (-not (Test-Path -LiteralPath (
                    Join-Path $sourceFixtureRoot "escaped-plan.json"))) `
            "Rejected reparse-point output must not escape into its target."
    } finally {
        if (Test-Path -LiteralPath $sourceJunctionPath) {
            [System.IO.Directory]::Delete($sourceJunctionPath)
        }
    }

    $nameParameters = @{}
    foreach ($entry in $common.GetEnumerator()) {
        $nameParameters[$entry.Key] = $entry.Value
    }
    $nameParameters.Remove("OriginalRva")
    $nameParameters.FunctionName = "OtPlanContract"
    $nameParameters.OutputPath = $namePlanPath
    $nameResult = @(Invoke-Generator $nameParameters)
    Assert-True ($nameResult.Count -eq 1 -and [bool]$nameResult[0].passed) `
        "Name-only identity generation should pass."

    Write-Json $variantSpecPath ([pscustomobject][ordered]@{
            schemaVersion = 1
            variants = @(
                [pscustomobject][ordered]@{
                    name = "initializer-two"
                    hypothesis = "The first spelling tests the initializer shape."
                    meaningful = $true
                    replacements = @([pscustomobject][ordered]@{
                            old = "int value = 1;"
                            new = "int value = 2;"
                        })
                },
                [pscustomobject][ordered]@{
                    name = "initializer-three"
                    hypothesis = "The second spelling tests an alternate constant."
                    meaningful = $true
                    replacements = @([pscustomobject][ordered]@{
                            old = "int value = 1;"
                            new = "int value = 3;"
                        })
                })
        })
    $specResult = @(Invoke-Generator @{
            Program = "Oregon32.exe"
            FunctionName = "OtPlanContract"
            CheckpointId = "contract-checkpoint"
            PriorBoundaryRunId = "contract-boundary"
            ManifestPath = $manifestPath
            SourceSearchRoot = $sourceFixtureRoot
            VariantSpecPath = $variantSpecPath
            OutputPath = $specPlanPath
        })
    Assert-True ($specResult.Count -eq 1 -and
        $specResult[0].variant_count -eq 2 -and
        $specResult[0].anchor_count -eq 2) `
        "Variant-spec mode should preserve two independently validated variants."

    [System.IO.File]::AppendAllText($sourcePath, "// source drift`n", $utf8NoBom)
    Assert-ThrowsLike {
        & $generatorPath -PreflightOnly -PlanPath $planPath
    } 'Source snapshot hash mismatch.*Regenerate the plan' `
        "Stale source snapshot"
    [System.IO.File]::WriteAllBytes($sourcePath, $sourceBytes)

    $tamperedPlan = Get-Content -LiteralPath $planPath -Raw | ConvertFrom-Json
    $tamperedPlan.variants[0].replacements[0].old = "return value;"
    Write-Json $planPath $tamperedPlan
    Assert-ThrowsLike {
        & $generatorPath -PreflightOnly -PlanPath $planPath
    } 'anchor metadata does not match' "Tampered anchor binding"

    $common.OutputPath = $planPath
    $common.Force = $true
    [void](Invoke-Generator $common)
    $common.Remove("Force")

    $ambiguousParameters = @{}
    foreach ($entry in $common.GetEnumerator()) {
        $ambiguousParameters[$entry.Key] = $entry.Value
    }
    $ambiguousParameters.OldText = "value"
    $ambiguousParameters.NewText = "other"
    $ambiguousParameters.OutputPath = $ambiguousPlanPath
    Assert-ThrowsLike {
        [void](Invoke-Generator $ambiguousParameters)
    } 'old anchor must occur exactly once.*observed 2' `
        "Ambiguous replacement anchor"
    Assert-True (-not (Test-Path -LiteralPath $ambiguousPlanPath)) `
        "Ambiguous-anchor failure must not publish a plan."

    $missingParameters = @{}
    foreach ($entry in $common.GetEnumerator()) {
        $missingParameters[$entry.Key] = $entry.Value
    }
    $missingParameters.OriginalRva = "0x9999"
    $missingParameters.OutputPath = $missingPlanPath
    Assert-ThrowsLike {
        [void](Invoke-Generator $missingParameters)
    } 'must resolve to exactly one row; observed 0' "Missing manifest identity"

    $duplicateRow = $manifestRow.PSObject.Copy()
    $duplicateRow.original_va = "0x00401040"
    $duplicateRow.original_rva = "0x00001040"
    Write-Csv $ambiguousManifestPath @($manifestRow, $duplicateRow)
    Assert-ThrowsLike {
        [void](Invoke-Generator @{
                Program = "Oregon32.exe"
                FunctionName = "OtPlanContract"
                CheckpointId = "contract-checkpoint"
                PriorBoundaryRunId = "contract-boundary"
                ManifestPath = $ambiguousManifestPath
                OutputPath = $ambiguousPlanPath
                Hypothesis = "Synthetic ambiguity negative control."
                OldText = "int value = 1;"
                NewText = "int value = 2;"
            })
    } 'must resolve to exactly one row; observed 2' "Ambiguous manifest identity"

    Assert-ThrowsLike {
        [void](Invoke-Generator @{
                Program = "Oregon32.exe"
                FunctionName = "OtPlanContract"
                CheckpointId = "contract-checkpoint"
                PriorBoundaryRunId = "contract-boundary"
                ManifestPath = $manifestPath
                OutputPath = $unsafePlanPath
                Hypothesis = "Synthetic unsafe-output negative control."
                OldText = "int value = 1;"
                NewText = "int value = 2;"
            })
    } 'below Git-ignored a/ or artifacts/' "Unsafe plan output"
    Assert-True (-not (Test-Path -LiteralPath $unsafePlanPath)) `
        "Unsafe-output failure must not create a file."

    Write-Utf8 $holderPath @'
param(
    [string]$LockPath,
    [string]$PlanPath,
    [string]$ReadyPath
)
$ErrorActionPreference = "Stop"
$stream = [System.IO.File]::Open(
    $LockPath,
    [System.IO.FileMode]::OpenOrCreate,
    [System.IO.FileAccess]::ReadWrite,
    [System.IO.FileShare]::None)
try {
    [System.IO.File]::WriteAllText($ReadyPath, "ready")
    Start-Sleep -Seconds 30
} finally {
    $stream.Dispose()
}
'@
    Write-Utf8 $fakePlanPath "{}`n"
    $holderProcess = Start-Process -FilePath $shellPath -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", ('"' + $holderPath + '"'),
        "-LockPath", ('"' + $lockPath + '"'),
        "-PlanPath", ('"' + $fakePlanPath + '"'),
        "-ReadyPath", ('"' + $readyPath + '"')) `
        -WindowStyle Hidden -PassThru
    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    while (-not (Test-Path -LiteralPath $readyPath -PathType Leaf) -and
        [DateTime]::UtcNow -lt $deadline) {
        Start-Sleep -Milliseconds 100
    }
    Assert-True (Test-Path -LiteralPath $readyPath -PathType Leaf) `
        "Lock holder did not become ready."

    $lockedStatus = ((& $lockStatusPath -LockPath $lockPath -AsJson) -join "`n") |
        ConvertFrom-Json
    Assert-True ([bool]$lockedStatus.locked -and
        $lockedStatus.status -eq "locked") `
        "Lock status helper should observe the held lock."
    Assert-True ([int]$lockedStatus.owner_count -ge 1 -and
        @($lockedStatus.owners | Where-Object {
                [int]$_.pid -eq $holderProcess.Id
            }).Count -eq 1) `
        "Lock status helper should identify the holder PID."
    $holderOwner = @($lockedStatus.owners | Where-Object {
            [int]$_.pid -eq $holderProcess.Id
        })[0]
    Assert-True ([string]$holderOwner.plan -match
        [regex]::Escape((Split-Path -Leaf $fakePlanPath))) `
        "Lock status helper should report the holder plan."
    Assert-True ([long]$holderOwner.age_seconds -ge 0) `
        "Lock status helper should report nonnegative owner age."

    Stop-Process -Id $holderProcess.Id -Force
    $holderProcess.WaitForExit()
    $holderProcess = $null
    $unlockedStatus = ((& $lockStatusPath -LockPath $lockPath -AsJson) -join "`n") |
        ConvertFrom-Json
    Assert-True (-not [bool]$unlockedStatus.locked -and
        $unlockedStatus.status -eq "unlocked" -and
        [int]$unlockedStatus.owner_count -eq 0) `
        "Lock status helper should report the released lock as unlocked."

    Write-Host "Source-shape plan and lock-status contract: PASS"
} finally {
    if ($null -ne $holderProcess -and -not $holderProcess.HasExited) {
        Stop-Process -Id $holderProcess.Id -Force
        $holderProcess.WaitForExit()
    }
    if (Test-Path -LiteralPath $sourceJunctionPath) {
        [System.IO.Directory]::Delete($sourceJunctionPath)
    }
    if (Test-Path -LiteralPath $unsafePlanPath -PathType Leaf) {
        Remove-Item -LiteralPath $unsafePlanPath -Force
    }
    if (-not $KeepFixture) {
        if (Test-Path -LiteralPath $fixtureRoot -PathType Container) {
            $resolvedFixtureRoot = [System.IO.Path]::GetFullPath($fixtureRoot)
            $expectedFixturePrefix = [System.IO.Path]::GetFullPath(
                (Join-Path $repoRoot "a")).TrimEnd('\') + '\'
            if (-not $resolvedFixtureRoot.StartsWith(
                    $expectedFixturePrefix,
                    [System.StringComparison]::OrdinalIgnoreCase) -or
                (Split-Path -Leaf $resolvedFixtureRoot) -notlike
                    'otmatch-source-shape-plan-contract-*') {
                throw "Refusing to clean unexpected fixture '$resolvedFixtureRoot'."
            }
            Remove-Item -LiteralPath $resolvedFixtureRoot -Recurse -Force
        }
    }
}
