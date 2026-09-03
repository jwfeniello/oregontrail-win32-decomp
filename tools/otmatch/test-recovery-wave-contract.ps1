[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$hostRepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$orchestratorSourcePath =
    (Resolve-Path (Join-Path $PSScriptRoot "invoke-recovery-wave.ps1")).Path
$shellPath = (Get-Process -Id $PID).Path
$contractId = "recovery-wave-contract-" + [guid]::NewGuid().ToString("N")
$contractRoot = [System.IO.Path]::GetFullPath(
    (Join-Path (Join-Path $hostRepoRoot "a") $contractId))
$sandboxRepoRoot = Join-Path $contractRoot "repo"
$orchestratorPath = Join-Path $sandboxRepoRoot "tools\otmatch\invoke-recovery-wave.ps1"
$outputRootRelative = "a\contract-output"
$outputRootAbsolute =
    [System.IO.Path]::GetFullPath((Join-Path $sandboxRepoRoot $outputRootRelative))
$planSessionId = "contract-plan"
$planSessionRoot = Join-Path $outputRootAbsolute $planSessionId
$planLedgerPath = Join-Path $planSessionRoot "session-ledger.json"
$fakeRunnerPath = Join-Path $sandboxRepoRoot "test-tools\fake-recovery-wave-runner.cmd"
$metricsControlPath = Join-Path $sandboxRepoRoot "test-tools\metrics-summary.json"
$promotionEvidenceRelative = "evidence/promotion-evidence.json"
$promotionEvidencePath = Join-Path $sandboxRepoRoot $promotionEvidenceRelative
$evidenceDossierRelative = "evidence/function-dossier.json"
$evidenceSourceRelative = "src/promotion-evidence.cpp"
$evidenceFocusedResultRelative = "evidence/focused-result.evidence.json"
$genericDossierRelative = "evidence/generic-dossier.md"
$genericFocusedResultRelative = "evidence/generic-focused-result.csv"

$coreStepNames = @(
    "build-candidates",
    "match-functions",
    "audit-function-masks",
    "audit-product-sources",
    "report-progress-metrics",
    "build-product-exe",
    "build-product-dll")
$promotionCoreStepNames = @(
    "build-candidates",
    "match-functions",
    "audit-function-masks",
    "audit-product-sources",
    "report-progress-metrics",
    "promotion-delta-evidence",
    "build-product-exe",
    "build-product-dll")

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Invoke-Wave {
    param(
        [string]$Phase,
        [string]$SessionId,
        [string]$CheckpointId = "",
        [double]$MinimumInstructionPercent = 0.0,
        [long]$MinimumInstructionGain = 0,
        [switch]$OmitMinimumInstructionGain,
        [string]$PromotionEvidencePath = "",
        [int]$SessionLockTimeoutMilliseconds = 30000,
        [switch]$Execute,
        [switch]$OmitSessionId,
        [string]$OutputRoot = $outputRootRelative,
        [string]$Runner = "missing-recovery-wave-runner.exe"
    )

    $arguments = @(
        "-NoProfile", "-ExecutionPolicy", "Bypass",
        "-File", $orchestratorPath,
        "-Phase", $Phase,
        "-OutputRoot", $OutputRoot,
        "-MinimumInstructionPercent",
        $MinimumInstructionPercent.ToString(
            "0.################",
            [System.Globalization.CultureInfo]::InvariantCulture),
        "-SessionLockTimeoutMilliseconds",
        $SessionLockTimeoutMilliseconds.ToString(
            [System.Globalization.CultureInfo]::InvariantCulture),
        "-OriginalExePath", "originals\original.exe",
        "-OriginalDllPath", "originals\original.dll",
        "-VcToolsRoot", "vc4",
        "-PowerShellExecutable", $Runner)
    if (-not $OmitMinimumInstructionGain) {
        if ($Phase -eq "promotion-wave" -and
            -not $PSBoundParameters.ContainsKey("MinimumInstructionGain")) {
            $MinimumInstructionGain = 1
        }
        $arguments += @(
            "-MinimumInstructionGain",
            $MinimumInstructionGain.ToString(
                [System.Globalization.CultureInfo]::InvariantCulture))
    }
    if (-not [string]::IsNullOrWhiteSpace($PromotionEvidencePath)) {
        $arguments += @("-PromotionEvidencePath", $PromotionEvidencePath)
    }
    if (-not $OmitSessionId) {
        $arguments += @("-SessionId", $SessionId)
    }
    if (-not [string]::IsNullOrWhiteSpace($CheckpointId)) {
        $arguments += @("-CheckpointId", $CheckpointId)
    }
    if ($Execute) {
        $arguments += "-Execute"
    }

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = @(& $shellPath @arguments 2>&1 |
            ForEach-Object { [string]$_ })
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }

    # Native error records are formatted differently by Windows PowerShell
    # and PowerShell 7.  Preserve the raw line array, but expose a stable text
    # transcript for contract assertions by removing ANSI controls and
    # collapsing presentation-only whitespace.
    $rawText = $output -join [Environment]::NewLine
    $matchableText = [regex]::Replace(
        $rawText, '\x1B\[[0-?]*[ -/]*[@-~]', '')
    $matchableText = [regex]::Replace($matchableText, '\s+', ' ').Trim()

    return [pscustomobject]@{
        ExitCode = [int]$exitCode
        Output = @($output)
        Text = $matchableText
        RawText = $rawText
    }
}

function Get-Ledger {
    param([string]$SessionId)

    $path = Join-Path (Join-Path $outputRootAbsolute $SessionId) "session-ledger.json"
    Assert-True (Test-Path -LiteralPath $path -PathType Leaf) `
        "The orchestrator did not write its machine-readable ledger for '$SessionId'."
    return (Get-Content -LiteralPath $path -Raw | ConvertFrom-Json)
}

function Get-Step {
    param(
        $Run,
        [string]$Name
    )

    $matches = @($Run.steps | Where-Object { [string]$_.name -ceq $Name })
    Assert-True ($matches.Count -eq 1) `
        "Run '$($Run.run_id)' does not contain exactly one '$Name' step."
    return $matches[0]
}

function Assert-StepNames {
    param(
        $Run,
        [string[]]$Expected
    )

    $actual = @($Run.steps | ForEach-Object { [string]$_.name })
    Assert-True (($actual -join '|') -ceq ($Expected -join '|')) `
        ("Phase '{0}' steps differ. Expected: {1}. Actual: {2}." -f
            $Run.phase, ($Expected -join ', '), ($actual -join ', '))
}

function Assert-HasArgument {
    param(
        $Step,
        [string]$Argument
    )

    Assert-True (@($Step.arguments) -ccontains $Argument) `
        "Step '$($Step.name)' is missing argument '$Argument'."
}

function Assert-LacksArgument {
    param(
        $Step,
        [string]$Argument
    )

    Assert-True (-not (@($Step.arguments) -ccontains $Argument)) `
        "Step '$($Step.name)' unexpectedly contains argument '$Argument'."
}

function Get-ArgumentValue {
    param(
        $Step,
        [string]$Argument
    )

    $arguments = @($Step.arguments)
    for ($index = 0; $index -lt $arguments.Count; $index++) {
        if ([string]$arguments[$index] -ceq $Argument) {
            Assert-True ($index + 1 -lt $arguments.Count) `
                "Step '$($Step.name)' has no value after '$Argument'."
            return [string]$arguments[$index + 1]
        }
    }
    throw "Step '$($Step.name)' is missing valued argument '$Argument'."
}

function Assert-PlannedRun {
    param($Run)

    Assert-True ([string]$Run.mode -ceq "plan") "Dry run has the wrong mode."
    Assert-True ([string]$Run.status -ceq "planned") "Dry run has the wrong status."
    Assert-True (-not [bool]$Run.git_snapshot_captured) `
        "Dry run unexpectedly executed Git to capture a snapshot."
    Assert-True ([string]::IsNullOrEmpty([string]$Run.git_commit_sha)) `
        "Dry run unexpectedly recorded an executed Git snapshot."
    Assert-True ($Run.PSObject.Properties.Name -contains "worktree_status") `
        "Dry run did not record worktree status."
    foreach ($step in @($Run.steps)) {
        Assert-True ([string]$step.status -ceq "planned") `
            "Dry-run step '$($step.name)' was not left in planned state."
        Assert-True (-not [string]::IsNullOrWhiteSpace([string]$step.command)) `
            "Dry-run step '$($step.name)' has no ledger command."
        Assert-True ([string]::IsNullOrWhiteSpace([string]$step.log_path)) `
            "Dry-run step '$($step.name)' unexpectedly has a log path."
    }
}

function Get-TextSha256Hex {
    param([string[]]$Lines)

    $text = ($Lines -join "`n") + "`n"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($sha.ComputeHash($bytes) | ForEach-Object {
            $_.ToString("x2")
        }) -join "")
    }
    finally {
        $sha.Dispose()
    }
}

function Get-FileSha256Hex {
    param([string]$Path)

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Write-DossierEvidenceFixture {
    param(
        [string]$Identity,
        [string]$SourcePath = $evidenceSourceRelative,
        [string]$SourceSha256 = "",
        [switch]$PendingChecklist,
        [switch]$ReviewFalse,
        [switch]$UnresolvedWarnings,
        [switch]$TuMetadataFound,
        [string]$ExtraCompileFlags = "",
        [switch]$StaleProvenanceHash,
        [switch]$ProvenanceInventoryMismatch
    )

    if ([string]::IsNullOrWhiteSpace($SourceSha256)) {
        $SourceSha256 = Get-FileSha256Hex (
            Join-Path $sandboxRepoRoot $SourcePath)
    }
    $parts = $Identity.Split('|')
    $program = $parts[0]
    $rva = $parts[1]
    $warningList = if ($UnresolvedWarnings) {
        @("Synthetic dossier warning requiring disposition.")
    }
    else {
        @()
    }
    $checklistIds = @(
        "semantic.behavior", "semantic.readable_cpp",
        "type.calling_convention", "type.layout", "abi.vc4_flags",
        "abi.exception_model", "mask.paired_shape", "mask.original_audit",
        "mask.target_identity", "evidence.ghidra_anchor",
        "evidence.product_reachability", "evidence.focused_diff")
    $checklist = @()
    foreach ($id in $checklistIds) {
        $state = if ($id -eq "mask.target_identity") {
            "not-applicable"
        }
        elseif ($id -like "mask.*") {
            "pass"
        }
        else {
            "complete"
        }
        if ($PendingChecklist -and $id -eq "semantic.behavior") {
            $state = "pending"
        }
        $checklist += [pscustomobject][ordered]@{
            id = $id
            category = $id.Split('.')[0]
            state = $state
            prompt = "Synthetic completed review for $id."
        }
    }
    $provenance = {
        param([string]$Path)
        $absolutePath = Join-Path $sandboxRepoRoot $Path
        $file = Get-Item -LiteralPath $absolutePath -Force
        [pscustomobject][ordered]@{
            path = $Path
            sha256 = Get-FileSha256Hex $absolutePath
            length = [long]$file.Length
        }
    }
    $originalProvenance = & $provenance "originals/original.exe"
    $candidateProvenance = & $provenance `
        "a/promotion-provenance/candidate.dll"
    $mapProvenance = & $provenance `
        "a/promotion-provenance/candidate.map"
    if ($StaleProvenanceHash) {
        $originalProvenance.sha256 = "0" * 64
    }
    $dossier = [pscustomobject][ordered]@{
        schema_version = 1
        generator = [pscustomobject][ordered]@{
            name = "otmatch-function-dossier"
            schema_version = 1
            script_path = "tools/otmatch/generate-function-dossier.ps1"
            script_sha256 = Get-FileSha256Hex (
                Join-Path $sandboxRepoRoot `
                    "tools/otmatch/generate-function-dossier.ps1")
        }
        identity = [pscustomobject][ordered]@{
            name = "ContractPromotion"
            program = $program
            original_va = "0x00401000"
            original_rva = $rva
            size = 16
            key = $Identity
        }
        manifest = [pscustomobject][ordered]@{
            expected_status = "match"
            implementation_kind = "cpp"
            candidate_symbol = "ContractPromotion"
            candidate_object = "src_promotion-evidence.obj"
            mask = ""
        }
        verifier = [pscustomobject][ordered]@{
            result_schema_version = 4
            verification_status = "pass"
            actual_status = "match"
            mask_shape_valid = $true
            masked_operand_shape_error = ""
            has_verifier_error = $false
            provenance_complete = $true
            original_file = $originalProvenance
            candidate_file = $candidateProvenance
            candidate_map = $mapProvenance
        }
        metrics = [pscustomobject][ordered]@{
            provided = $true
            strict_accepted = $true
        }
        mask_review = [pscustomobject][ordered]@{
            original_audit_state = "not-required-no-mask"
            paired_candidate_shape_valid = $true
            paired_candidate_shape_error = ""
            non_import_target_identity_proven = $false
        }
        recovery_state = [pscustomobject]@{}
        sources = @([pscustomobject][ordered]@{
            path = $SourcePath
            sha256 = $SourceSha256
            object_name = "src_promotion-evidence.obj"
            match_reasons = @("candidate_object", "candidate_symbol", "manifest_name")
            product_reachable = $true
            tu_metadata_found = [bool]$TuMetadataFound
            extra_compile_flags = $ExtraCompileFlags
        })
        decompilation = [pscustomobject]@{}
        prior_recovery_notes = @()
        checklist = @($checklist)
        promotion_review = [pscustomobject][ordered]@{
            identity_key = $Identity
            status = if ($ReviewFalse) { "pending" } else { "passed" }
            reviewed_source_path = $SourcePath
            reviewed_source_sha256 = $SourceSha256
            reviewer = "Recovery Wave Contract"
            reviewed_utc = "2026-07-17T12:00:00.0000000Z"
            semantic = [pscustomobject]@{
                passed = -not $ReviewFalse
                note = "Behavior and readable semantic C++ reviewed."
            }
            type_layout = [pscustomobject]@{
                passed = $true
                note = "Types and layout reviewed."
            }
            abi = [pscustomobject]@{
                passed = $true
                note = "VC4 ABI and TU flags reviewed."
            }
            mask = [pscustomobject]@{
                passed = $true
                note = "Mask policy and target identity reviewed."
            }
            warnings_disposition = [pscustomobject][ordered]@{
                status = if ($UnresolvedWarnings) { "pending" } else { "resolved" }
                note = if ($UnresolvedWarnings) {
                    "Warning review remains pending."
                }
                else {
                    "No dossier warnings remain unresolved."
                }
                resolved_warnings = @()
            }
        }
        warnings = @($warningList)
        evidence = @(
            [pscustomobject][ordered]@{
                roles = @("candidate-source")
                path = $SourcePath
                sha256 = $SourceSha256
                length = 42
            },
            [pscustomobject][ordered]@{
                roles = @("dossier-generator")
                path = "tools/otmatch/generate-function-dossier.ps1"
                sha256 = Get-FileSha256Hex (
                    Join-Path $sandboxRepoRoot `
                        "tools/otmatch/generate-function-dossier.ps1")
                length = 32
            },
            [pscustomobject][ordered]@{
                roles = @($(if ($ProvenanceInventoryMismatch) {
                    "verifier-original-file-stale"
                }
                else { "verifier-original-file" }))
                path = "originals/original.exe"
                sha256 = Get-FileSha256Hex (
                    Join-Path $sandboxRepoRoot "originals/original.exe")
                length = [long](Get-Item -LiteralPath (
                    Join-Path $sandboxRepoRoot "originals/original.exe")).Length
            },
            [pscustomobject][ordered]@{
                roles = @("verifier-candidate-file")
                path = "a/promotion-provenance/candidate.dll"
                sha256 = [string]$candidateProvenance.sha256
                length = [long]$candidateProvenance.length
            },
            [pscustomobject][ordered]@{
                roles = @("verifier-candidate-map")
                path = "a/promotion-provenance/candidate.map"
                sha256 = [string]$mapProvenance.sha256
                length = [long]$mapProvenance.length
            })
    }
    $dossierJson = ($dossier | ConvertTo-Json -Depth 20 -Compress) + "`n"
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot $evidenceDossierRelative),
        $dossierJson,
        [System.Text.UTF8Encoding]::new($false))
}

function Write-FocusedEvidenceFixture {
    param(
        [string]$Identity,
        [string]$CheckpointId,
        [string]$PriorBoundaryRunId,
        [string]$SourcePath = $evidenceSourceRelative,
        [string]$SourceSha256 = "",
        [long]$HardDiffCount = 0,
        [switch]$RestorationFalse,
        [switch]$RestorationHashMismatch,
        [switch]$PromotionIneligible,
        [switch]$CandidateSymbolMismatch,
        [switch]$RunnerHashStale,
        [switch]$RunSummaryStringTiming,
        [switch]$RunSummaryFractionalTiming,
        [switch]$RunSummaryNullTiming,
        [switch]$RunSummaryMissingLatencyFlag
    )

    if ([string]::IsNullOrWhiteSpace($SourceSha256)) {
        $SourceSha256 = Get-FileSha256Hex (
            Join-Path $sandboxRepoRoot $SourcePath)
    }
    $parts = $Identity.Split('|')
    $trialBuildDuration = if ($RunSummaryMissingLatencyFlag) { 15001 } else { 10 }
    $trialTotalDuration = $trialBuildDuration + 2
    $summaryTrialDuration = $trialTotalDuration
    $summaryVariantDuration = $summaryTrialDuration + 2
    $summaryRunnerDuration = 25 + 3 + $summaryVariantDuration + 5
    $baselineSetupDuration = if ($RunSummaryStringTiming) {
        "25"
    } elseif ($RunSummaryFractionalTiming) {
        25.5
    } elseif ($RunSummaryNullTiming) {
        $null
    } else { 25 }
    $artifact = [pscustomobject][ordered]@{
        schema_version = 1
        artifact_type = "otwin-source-shape-evidence"
        runner = [pscustomobject][ordered]@{
            name = "otmatch-source-shape-runner"
            schema_version = 1
            script_path = "tools/otmatch/invoke-source-shape-variants.ps1"
            script_sha256 = if ($RunnerHashStale) {
                "0" * 64
            }
            else {
                Get-FileSha256Hex (Join-Path $sandboxRepoRoot `
                    "tools/otmatch/invoke-source-shape-variants.ps1")
            }
        }
        identity = [pscustomobject][ordered]@{
            key = $Identity
            program = $parts[0]
            name = "ContractPromotion"
            original_rva = $parts[1]
        }
        checkpoint = [pscustomobject][ordered]@{
            checkpoint_id = $CheckpointId
            prior_boundary_run_id = $PriorBoundaryRunId
        }
        source = [pscustomobject][ordered]@{
            path = $SourcePath
            baseline_sha256 = ("4" * 64)
            restored_sha256 = ("4" * 64)
        }
        successful_trial = [pscustomobject][ordered]@{
            variant = "contract-zero-hard"
            status = "OK"
            hypothesis = "Synthetic exact semantic source-shape trial."
            meaningful = $true
            source_sha256 = $SourceSha256
            candidate_symbol = if ($CandidateSymbolMismatch) {
                "ContractPromotionMismatch"
            }
            else { "ContractPromotion" }
            candidate_rva = "0x00002000"
            raw_diff_count = 4
            hard_diff_count = $HardDiffCount
            hard_compared_bytes = 16
            build_duration_ms = $trialBuildDuration
            diff_duration_ms = 2
            total_duration_ms = $trialTotalDuration
        }
        restoration = [pscustomobject][ordered]@{
            attempted = $true
            passed = -not $RestorationFalse
            used_trusted_graph = $false
            baseline_candidate_normalized_sha256 = ("5" * 64)
            restored_candidate_normalized_sha256 = if ($RestorationHashMismatch) {
                "6" * 64
            }
            else { "5" * 64 }
            baseline_map_normalized_sha256 = ("7" * 64)
            restored_map_normalized_sha256 = ("7" * 64)
            baseline_object_sha256 = ("8" * 64)
            restored_object_sha256 = ("8" * 64)
        }
        run_summary = [pscustomobject][ordered]@{
            warm_baseline_reused = $true
            baseline_setup_duration_ms = $baselineSetupDuration
            baseline_diff_duration_ms = 3
            trial_count = 1
            meaningful_trial_count = 1
            trial_tool_time_ms = $summaryTrialDuration
            trial_wall_time_ms = $summaryTrialDuration
            variant_loop_duration_ms = $summaryVariantDuration
            restoration_duration_ms = 5
            runner_elapsed_before_evidence_ms = $summaryRunnerDuration
            maximum_focused_build_seconds = 15
            maximum_focused_diff_seconds = 30
            build_latency_budget_exceeded = $false
            diff_latency_budget_exceeded = $false
            stop_reason = ""
        }
        promotion_eligible = -not $PromotionIneligible
    }
    $artifactJson = ($artifact | ConvertTo-Json -Depth 12 -Compress) + "`n"
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot $evidenceFocusedResultRelative),
        $artifactJson,
        [System.Text.UTF8Encoding]::new($false))
}

function Write-PromotionEvidence {
    param(
        [string]$CheckpointId,
        [string]$PriorBoundaryRunId,
        [string[]]$Identities,
        [switch]$StaleSourceHash,
        [switch]$ReviewFalse,
        [switch]$DossierReviewFalse,
        [switch]$PendingChecklist,
        [switch]$UnresolvedWarnings,
        [switch]$DossierTuMetadataFound,
        [string]$DossierExtraCompileFlags = "",
        [switch]$DossierProvenanceHashStale,
        [switch]$DossierProvenanceInventoryMismatch,
        [switch]$DossierSourceMismatch,
        [switch]$FocusedSourceMismatch,
        [switch]$FocusedSymbolMismatch,
        [switch]$FocusedRunnerHashStale,
        [switch]$NonzeroHardResidual,
        [switch]$RestorationFalse,
        [switch]$RestorationHashMismatch,
        [switch]$PromotionIneligible,
        [switch]$RunSummaryStringTiming,
        [switch]$RunSummaryFractionalTiming,
        [switch]$RunSummaryNullTiming,
        [switch]$RunSummaryMissingLatencyFlag,
        [switch]$UseGenericDossier,
        [switch]$UseGenericFocusedResult,
        [string]$DossierIdentity = "",
        [string]$FocusedIdentity = ""
    )

    $sourcePath = Join-Path $sandboxRepoRoot $evidenceSourceRelative
    $actualSourceSha256 = Get-FileSha256Hex $sourcePath
    $artifactIdentity = if (@($Identities).Count -eq 0) {
        "oregon32.exe|0x4000"
    }
    else {
        [string]$Identities[0]
    }
    $effectiveDossierIdentity = if ([string]::IsNullOrWhiteSpace(
            $DossierIdentity)) {
        $artifactIdentity
    }
    else { $DossierIdentity }
    $effectiveFocusedIdentity = if ([string]::IsNullOrWhiteSpace(
            $FocusedIdentity)) {
        $artifactIdentity
    }
    else { $FocusedIdentity }
    if (-not $UseGenericDossier) {
        Write-DossierEvidenceFixture `
            -Identity $effectiveDossierIdentity `
            -SourceSha256 $(if ($DossierSourceMismatch) {
                "9" * 64
            } else { $actualSourceSha256 }) `
            -PendingChecklist:$PendingChecklist `
            -ReviewFalse:$DossierReviewFalse `
            -UnresolvedWarnings:$UnresolvedWarnings `
            -TuMetadataFound:$DossierTuMetadataFound `
            -ExtraCompileFlags $DossierExtraCompileFlags `
            -StaleProvenanceHash:$DossierProvenanceHashStale `
            -ProvenanceInventoryMismatch:$DossierProvenanceInventoryMismatch
    }
    if (-not $UseGenericFocusedResult) {
        Write-FocusedEvidenceFixture `
            -Identity $effectiveFocusedIdentity `
            -CheckpointId $CheckpointId `
            -PriorBoundaryRunId $PriorBoundaryRunId `
            -SourceSha256 $(if ($FocusedSourceMismatch) {
                "a" * 64
            } else { $actualSourceSha256 }) `
            -HardDiffCount $(if ($NonzeroHardResidual) { 1 } else { 0 }) `
            -RestorationFalse:$RestorationFalse `
            -RestorationHashMismatch:$RestorationHashMismatch `
            -PromotionIneligible:$PromotionIneligible `
            -CandidateSymbolMismatch:$FocusedSymbolMismatch `
            -RunnerHashStale:$FocusedRunnerHashStale `
            -RunSummaryStringTiming:$RunSummaryStringTiming `
            -RunSummaryFractionalTiming:$RunSummaryFractionalTiming `
            -RunSummaryNullTiming:$RunSummaryNullTiming `
            -RunSummaryMissingLatencyFlag:$RunSummaryMissingLatencyFlag
    }

    $dossierRelative = if ($UseGenericDossier) {
        $genericDossierRelative
    }
    else { $evidenceDossierRelative }
    $focusedResultRelative = if ($UseGenericFocusedResult) {
        $genericFocusedResultRelative
    }
    else { $evidenceFocusedResultRelative }
    $dossierPath = Join-Path $sandboxRepoRoot $dossierRelative
    $focusedResultPath = Join-Path $sandboxRepoRoot $focusedResultRelative
    $sourceSha256 = $actualSourceSha256
    if ($StaleSourceHash) {
        $sourceSha256 = "0" * 64
    }
    $entries = @()
    foreach ($identity in $Identities) {
        $entries += [pscustomobject][ordered]@{
            identity = $identity
            dossier_path = $dossierRelative
            dossier_sha256 = Get-FileSha256Hex $dossierPath
            source_path = $evidenceSourceRelative
            source_sha256 = $sourceSha256
            focused_result_path = $focusedResultRelative
            focused_result_sha256 = Get-FileSha256Hex $focusedResultPath
            semantic_review_passed = -not $ReviewFalse
            type_review_passed = $true
            abi_review_passed = $true
            mask_review_passed = $true
        }
    }
    $document = [pscustomobject][ordered]@{
        schema_version = 1
        checkpoint_id = $CheckpointId
        prior_boundary_run_id = $PriorBoundaryRunId
        promotions = @($entries)
    }
    $document | ConvertTo-Json -Depth 8 |
        Set-Content -LiteralPath $promotionEvidencePath -Encoding UTF8
}

function Assert-InvalidPromotionEvidenceCase {
    param(
        [string]$CheckpointId,
        [string]$SessionId,
        [string]$PriorBoundaryRunId,
        [string]$ExpectedPattern,
        [string[]]$Identities = @("oregon32.exe|0x4000"),
        [long]$MinimumInstructionGain = 5,
        [hashtable]$FixtureOptions = @{}
    )

    $writeArguments = @{
        CheckpointId = $CheckpointId
        PriorBoundaryRunId = $PriorBoundaryRunId
        Identities = $Identities
    }
    foreach ($key in $FixtureOptions.Keys) {
        $writeArguments[$key] = $FixtureOptions[$key]
    }
    Write-PromotionEvidence @writeArguments
    $result = Invoke-Wave `
        -Phase "promotion-wave" `
        -SessionId $SessionId `
        -CheckpointId $CheckpointId `
        -MinimumInstructionGain $MinimumInstructionGain `
        -PromotionEvidencePath $promotionEvidenceRelative `
        -Execute `
        -Runner $fakeRunnerPath
    Assert-True ($result.ExitCode -ne 0 -and
        $result.Text -match $ExpectedPattern) `
        (("Invalid promotion evidence case '{0}' was not rejected as " +
            "expected. Output: {1}") -f $CheckpointId, $result.Text)
}

function Write-MetricsControl {
    param(
        [string[]]$AcceptedIdentities,
        [uint64]$AcceptedInstructions,
        [uint64]$DenominatorInstructions = 100,
        [string]$DenominatorIdentitySha256 = ("d" * 64),
        [string]$BodyOwnershipSha256 = ("b" * 64),
        [uint64]$BodyRangeCount = 10,
        [string]$ManifestIdentitySha256 = ("a" * 64),
        [uint64]$ManifestIdentityCount = 10
    )

    $identities = [string[]]@($AcceptedIdentities)
    [Array]::Sort($identities, [System.StringComparer]::Ordinal)
    $summary = [pscustomobject][ordered]@{
        schema_version = 2
        generated_utc = "2000-01-01T00:00:00.0000000Z"
        policy = [pscustomobject]@{
            include_non_text = $false
            require_product_reachability = $true
            required_instruction_percent = 0
        }
        inputs = [pscustomobject]@{
            manifest = [pscustomobject][ordered]@{
                identity_universe_sha256 = $ManifestIdentitySha256
                identity_count = $ManifestIdentityCount
            }
        }
        denominator = [pscustomobject][ordered]@{
            identity_sha256 = $DenominatorIdentitySha256
            body_ownership_sha256 = $BodyOwnershipSha256
            body_range_count = $BodyRangeCount
            function_count = 10
            instruction_count = $DenominatorInstructions
            body_byte_count = 1000
        }
        strict = [pscustomobject][ordered]@{
            accepted_identity_sha256 = Get-TextSha256Hex $identities
            accepted_identity_count = $identities.Count
            accepted_identities = @($identities)
            accepted_instructions = $AcceptedInstructions
            accepted_body_bytes = $AcceptedInstructions
            instruction_percent = if ($DenominatorInstructions -eq 0) {
                0
            }
            else {
                ([double]$AcceptedInstructions /
                    [double]$DenominatorInstructions) * 100.0
            }
        }
    }
    $json = $summary | ConvertTo-Json -Depth 8 -Compress
    [System.IO.File]::WriteAllText(
        $metricsControlPath, $json, [System.Text.Encoding]::UTF8)
}

function Invoke-SandboxGit {
    param([string[]]$Arguments)

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = @(& git @Arguments 2>&1 | ForEach-Object { [string]$_ })
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($exitCode -ne 0) {
        throw "Sandbox git $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
    return @($output)
}

function Initialize-ContractSandbox {
    [void][System.IO.Directory]::CreateDirectory($sandboxRepoRoot)
    [void][System.IO.Directory]::CreateDirectory(
        (Split-Path -Parent $orchestratorPath))
    [void][System.IO.Directory]::CreateDirectory(
        (Split-Path -Parent $fakeRunnerPath))
    [void][System.IO.Directory]::CreateDirectory(
        (Join-Path $sandboxRepoRoot "tools\ghidra\otwin32\output"))
    [void][System.IO.Directory]::CreateDirectory(
        (Join-Path $sandboxRepoRoot "src"))
    [void][System.IO.Directory]::CreateDirectory(
        (Join-Path $sandboxRepoRoot "originals"))
    [void][System.IO.Directory]::CreateDirectory(
        (Join-Path $sandboxRepoRoot "vc4\BIN"))
    [void][System.IO.Directory]::CreateDirectory(
        (Join-Path $sandboxRepoRoot "vc4\INCLUDE"))
    [void][System.IO.Directory]::CreateDirectory(
        (Join-Path $sandboxRepoRoot "vc4\LIB"))
    [void][System.IO.Directory]::CreateDirectory(
        (Join-Path $sandboxRepoRoot "resources\otwin32"))
    [void][System.IO.Directory]::CreateDirectory(
        (Join-Path $sandboxRepoRoot "evidence"))

    Copy-Item -LiteralPath $orchestratorSourcePath -Destination $orchestratorPath
    foreach ($scriptName in @(
            "build-match-candidates.ps1",
            "match-functions.ps1",
            "audit-function-masks.ps1",
            "report-progress-metrics.ps1",
            "audit-vc4-product-sources.ps1",
            "build-vc4-products.ps1",
            "compare-pe-images.ps1",
            "test-verification-contract.ps1",
            "test-progress-metrics-contract.ps1",
            "test-build-cache-contract.ps1",
            "test-wip-queue-contract.ps1",
            "test-recovery-wave-contract.ps1",
            "generate-function-dossier.ps1",
            "test-function-dossier-contract.ps1",
            "invoke-source-shape-variants.ps1",
            "invoke-product-reanchor-evidence.ps1",
            "test-product-reanchor-evidence-contract.ps1")) {
        [System.IO.File]::WriteAllText(
            (Join-Path (Split-Path -Parent $orchestratorPath) $scriptName),
            "# recovery-wave contract gate stub`r`n")
    }

    [System.IO.File]::WriteAllLines(
        $fakeRunnerPath,
        @(
            "@echo off",
            'if not "%OTWIN_RECOVERY_CONTRACT_MUTATE_PATH%"=="" echo mutation>>"%OTWIN_RECOVERY_CONTRACT_MUTATE_PATH%"',
            ":loop",
            'if "%~1"=="" exit /b 0',
            'if /I "%~1"=="-Target" if /I "%~2"=="Oregon32Exe" if not "%OTWIN_RECOVERY_CONTRACT_MUTATE_AFTER_EVIDENCE_PATH%"=="" echo mutation>>"%OTWIN_RECOVERY_CONTRACT_MUTATE_AFTER_EVIDENCE_PATH%"',
            'if /I "%~1"=="-SummaryJsonPath" (',
            '  for %%D in ("%~2") do if not exist "%%~dpD" mkdir "%%~dpD"',
            '  copy /Y "%~dp0metrics-summary.json" "%~2" >nul',
            "  if errorlevel 1 exit /b 9",
            ")",
            "shift /1",
            "goto loop"),
        [System.Text.Encoding]::ASCII)

    [System.IO.File]::WriteAllLines(
        (Join-Path $sandboxRepoRoot ".gitignore"),
        @("/a/", "/originals/", "/vc4/", "/resources/otwin32/"),
        [System.Text.Encoding]::ASCII)
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot "tools\otmatch\functions.vc40-real-cpp.csv"),
        "name,program,original_rva,size,expected_status,implementation_kind`r`n")
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot "tools\otmatch\vc4-exe-product-sources.txt"),
        "src/contract.cpp`r`n")
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot "tools\otmatch\vc4-tu-metadata.csv"),
        "source_path,extra_compile_flags`r`nsrc/contract.cpp,`r`n")
    foreach ($metricName in @(
            "function_metrics_oregon32_exe.csv",
            "function_metrics_oregon32_dll.csv")) {
        [System.IO.File]::WriteAllText(
            (Join-Path $sandboxRepoRoot "tools\ghidra\otwin32\output\$metricName"),
            "program,original_rva,instruction_count,body_bytes,size`r`n")
    }
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot "src\contract.cpp"),
        "int contract_source = 1;`r`n")
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot $evidenceSourceRelative),
        "extern `"C`" int ContractPromotion(void) { return 1; }`r`n")
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot $evidenceDossierRelative),
        "{}`r`n")
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot $evidenceFocusedResultRelative),
        "{}`r`n")
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot $genericDossierRelative),
        "# Generic text is not a promotion dossier.`r`n")
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot $genericFocusedResultRelative),
        "identity,hard_residual`r`noregon32.exe|0x3000,0`r`n")
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot "originals\original.exe"),
        "contract original exe")
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot "originals\original.dll"),
        "contract original dll")
    [void][System.IO.Directory]::CreateDirectory(
        (Join-Path $sandboxRepoRoot "a\promotion-provenance"))
    [System.IO.File]::WriteAllBytes(
        (Join-Path $sandboxRepoRoot `
            "a\promotion-provenance\candidate.dll"),
        [byte[]]@(0x4d, 0x5a, 0x00, 0x43, 0x4f, 0x4e, 0x54, 0x52, 0x41, 0x43, 0x54))
    [System.IO.File]::WriteAllBytes(
        (Join-Path $sandboxRepoRoot `
            "a\promotion-provenance\candidate.map"),
        [byte[]]@(0x00, 0x43, 0x4f, 0x4e, 0x54, 0x52, 0x41, 0x43, 0x54))
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot "vc4\BIN\CL.EXE"),
        "contract cl")
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot "vc4\BIN\LINK.EXE"),
        "contract link")
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot "vc4\BIN\C2.EXE"),
        "contract c2")
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot "vc4\INCLUDE\STDIO.H"),
        "contract include")
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot "vc4\LIB\LIBC.LIB"),
        "contract libc")
    [System.IO.File]::WriteAllText(
        (Join-Path $sandboxRepoRoot "resources\otwin32\contract.res"),
        "contract resource")
    Write-MetricsControl `
        -AcceptedIdentities @("oregon32.exe|0x1000", "oregon32.exe|0x2000") `
        -AcceptedInstructions 50

    Push-Location $sandboxRepoRoot
    try {
        [void](Invoke-SandboxGit @("init", "--quiet"))
        [void](Invoke-SandboxGit @("config", "user.name", "Recovery Wave Contract"))
        [void](Invoke-SandboxGit @("config", "user.email", "contract@example.invalid"))
        [void](Invoke-SandboxGit @("config", "core.autocrlf", "false"))
        [void](Invoke-SandboxGit @("add", "."))
        [void](Invoke-SandboxGit @("commit", "--quiet", "-m", "contract baseline"))
    }
    finally {
        Pop-Location
    }
}

try {
    Initialize-ContractSandbox
    Push-Location $sandboxRepoRoot
    try {
        $baselinePlanResult = Invoke-Wave `
            -Phase "baseline" `
            -SessionId $planSessionId
        Assert-True ($baselinePlanResult.ExitCode -eq 0) `
            "Baseline plan failed: $($baselinePlanResult.Text)"
        Assert-True ($baselinePlanResult.Text -match 'Plan only: no recovery-wave step was executed') `
            "Baseline did not report safe plan-only mode."

        $ledger = Get-Ledger $planSessionId
        Assert-True ([int]$ledger.schema_version -eq 4) "Unexpected ledger schema."
        Assert-True ([bool]$ledger.execution_requires_explicit_switch) `
            "Ledger does not record the explicit execution gate."
        Assert-True (@($ledger.runs).Count -eq 1) `
            "Baseline plan did not create exactly one ledger run."
        $baseline = @($ledger.runs)[0]
        Assert-PlannedRun $baseline
        Assert-StepNames $baseline $coreStepNames
        Assert-True ([string]$baseline.checkpoint_id -ceq "baseline") `
            "Baseline did not receive its default checkpoint ID."
        Assert-HasArgument (Get-Step $baseline "build-candidates") "-Rebuild"
        Assert-LacksArgument (Get-Step $baseline "match-functions") "-AllowMismatches"
        Assert-HasArgument (Get-Step $baseline "audit-function-masks") "-RequireValidated"
        Assert-HasArgument (Get-Step $baseline "report-progress-metrics") "-RequireProductReachability"
        Assert-HasArgument (Get-Step $baseline "report-progress-metrics") "-SummaryJsonPath"
        Assert-LacksArgument (Get-Step $baseline "report-progress-metrics") "-RequireInstructionPercent"
        Assert-True ($null -eq $baseline.gate_snapshot -and
            $null -eq $baseline.metrics_summary) `
            "Plan mode captured execution-only gate or metrics evidence."
        $baselineExeLink = Get-Step $baseline "build-product-exe"
        $baselineDllLink = Get-Step $baseline "build-product-dll"
        Assert-True ((Get-ArgumentValue $baselineExeLink "-Target") -ceq "Oregon32Exe") `
            "Baseline EXE gate selected the wrong Product target."
        Assert-True ((Get-ArgumentValue $baselineExeLink "-ExeGraph") -ceq "Product") `
            "Baseline EXE gate is not using the strict Product graph."
        Assert-True ((Get-ArgumentValue $baselineDllLink "-Target") -ceq "Oregon32Dll") `
            "Baseline DLL gate selected the wrong Product target."
        Assert-LacksArgument $baselineExeLink "-AllowUnresolvedDiagnostic"
        Assert-LacksArgument $baselineDllLink "-AllowUnresolvedDiagnostic"

        $promotionPlanResult = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $planSessionId `
            -CheckpointId "wave-1000"
        Assert-True ($promotionPlanResult.ExitCode -eq 0) `
            "Promotion plan failed: $($promotionPlanResult.Text)"
        $ledger = Get-Ledger $planSessionId
        Assert-True (@($ledger.runs).Count -eq 2) `
            "Promotion plan did not append to the session ledger."
        $promotion = @($ledger.runs)[1]
        Assert-PlannedRun $promotion
        Assert-StepNames $promotion @(
            $promotionCoreStepNames
            "git-diff-head-check",
            "repository-boundary",
            "git-status-informational")
        Assert-True ([string]$promotion.checkpoint_id -ceq "wave-1000") `
            "Promotion plan lost its explicit checkpoint ID."
        Assert-True ([long]$promotion.minimum_instruction_gain -eq 1) `
            "Promotion plan did not bind its required instruction gain."
        Assert-LacksArgument (Get-Step $promotion "build-candidates") "-Rebuild"
        Assert-HasArgument (Get-Step $promotion "audit-function-masks") "-RequireValidated"
        Assert-HasArgument (Get-Step $promotion "report-progress-metrics") "-RequireProductReachability"
        $promotionDiffStep = Get-Step $promotion "git-diff-head-check"
        Assert-HasArgument $promotionDiffStep "HEAD"
        Assert-HasArgument $promotionDiffStep "--check"
        Assert-True ([string](Get-Step $promotion "repository-boundary").kind -ceq "internal") `
            "Promotion repository boundary audit is not fail-closed."
        Assert-True ([string](Get-Step $promotion "promotion-delta-evidence").kind -ceq "internal") `
            "Promotion delta/evidence gate is not fail-closed."

        $finalPlanResult = Invoke-Wave `
            -Phase "final" `
            -SessionId $planSessionId `
            -MinimumInstructionPercent 55.0
        Assert-True ($finalPlanResult.ExitCode -eq 0) `
            "Final plan failed: $($finalPlanResult.Text)"
        $ledger = Get-Ledger $planSessionId
        Assert-True (@($ledger.runs).Count -eq 3) `
            "Final plan did not append to the session ledger."
        $final = @($ledger.runs)[2]
        Assert-PlannedRun $final
        Assert-StepNames $final @(
            $promotionCoreStepNames
            "compare-product-exe",
            "compare-product-dll",
            "test-verifier-contract",
            "test-metrics-contract",
            "test-build-cache-contract",
            "test-wip-queue-contract",
            "test-recovery-wave-contract",
            "test-function-dossier-contract",
            "test-product-reanchor-evidence-contract",
            "cmake-build",
            "ctest",
            "viewer-tests",
            "git-diff-head-check",
            "repository-boundary",
            "git-status-informational")
        Assert-True ([string]$final.checkpoint_id -ceq "final") `
            "Final did not receive its default checkpoint ID."
        Assert-True ([long]$final.minimum_instruction_gain -eq 0) `
            "Final plan did not preserve its allowed zero instruction gain."
        Assert-HasArgument (Get-Step $final "build-candidates") "-Rebuild"
        Assert-HasArgument (Get-Step $final "report-progress-metrics") "-RequireInstructionPercent"
        Assert-True ((Get-ArgumentValue `
                (Get-Step $final "report-progress-metrics") `
                "-RequireInstructionPercent") -ceq "55") `
            "Final metrics step did not receive its exact instruction threshold."
        $diffStep = Get-Step $final "git-diff-head-check"
        Assert-HasArgument $diffStep "HEAD"
        Assert-HasArgument $diffStep "--check"
        Assert-True ([string](Get-Step $final "repository-boundary").kind -ceq "internal") `
            "Repository boundary audit is not an internal fail-closed step."
        Assert-True ([string](Get-Step $final "git-status-informational").category -ceq "worktree-information") `
            "Git status is not explicitly classified as informational."

        $checkpointDirectories = @(
            [string]$baseline.checkpoint_directory,
            [string]$promotion.checkpoint_directory,
            [string]$final.checkpoint_directory)
        Assert-True (@($checkpointDirectories | Select-Object -Unique).Count -eq 3) `
            "Distinct checkpoints reused an evidence directory."
        Assert-True ([string]$baseline.candidate_directory -match '[\\/]checkpoints[\\/]baseline[\\/]vc40$') `
            "Baseline candidate output is outside its checkpoint."
        Assert-True ([string]$promotion.candidate_directory -match '[\\/]checkpoints[\\/]wave-1000[\\/]vc40$') `
            "Promotion candidate output is outside its checkpoint."
        Assert-True ([string]$final.product_directory -match '[\\/]checkpoints[\\/]final[\\/]vc4-products$') `
            "Final Product output is outside its checkpoint."
        foreach ($run in @($baseline, $promotion, $final)) {
            Assert-True ([string]$run.log_directory -like "$planSessionRoot\logs\*") `
                "Run logs are not centralized beneath the session log root."
        }

        $logFiles = @(Get-ChildItem -LiteralPath $planSessionRoot -Filter *.log -File -Recurse -ErrorAction SilentlyContinue)
        Assert-True ($logFiles.Count -eq 0) `
            "Plan mode unexpectedly executed recovery-wave steps or emitted command logs."
        Assert-True (-not (Test-Path -LiteralPath ([string]$baseline.candidate_directory))) `
            "Plan mode unexpectedly created the candidate output directory."
        Assert-True (-not (Test-Path -LiteralPath ([string]$final.product_directory))) `
            "Plan mode unexpectedly created the Product output directory."

        $missingSession = Invoke-Wave `
            -Phase "baseline" `
            -OmitSessionId
        Assert-True ($missingSession.ExitCode -ne 0) `
            "Baseline plan accepted a missing SessionId."
        Assert-True ($missingSession.Text -match 'SessionId must contain only') `
            "Missing SessionId was not explained."

        $missingCheckpointSession = "missing-checkpoint"
        $missingCheckpoint = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $missingCheckpointSession
        Assert-True ($missingCheckpoint.ExitCode -ne 0) `
            "Promotion plan accepted a missing CheckpointId."
        Assert-True ($missingCheckpoint.Text -match 'requires an explicit -CheckpointId') `
            "Missing promotion CheckpointId was not explained."
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $outputRootAbsolute $missingCheckpointSession))) `
            "Invalid promotion plan mutated its session path."

        $missingGainSession = "missing-gain"
        $missingGain = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $missingGainSession `
            -CheckpointId "wave-no-gain" `
            -OmitMinimumInstructionGain
        Assert-True ($missingGain.ExitCode -ne 0) `
            "Promotion plan accepted a zero/missing instruction gain."
        Assert-True ($missingGain.Text -match
            'requires -MinimumInstructionGain greater than zero') `
            "Missing promotion instruction gain was not explained."
        Assert-True (-not (Test-Path -LiteralPath (
                Join-Path $outputRootAbsolute $missingGainSession))) `
            "Missing promotion instruction gain mutated its session path."

        $missingThresholdSession = "missing-threshold"
        $missingThreshold = Invoke-Wave `
            -Phase "final" `
            -SessionId $missingThresholdSession
        Assert-True ($missingThreshold.ExitCode -ne 0) `
            "Final plan accepted a zero instruction threshold."
        Assert-True ($missingThreshold.Text -match 'requires -MinimumInstructionPercent greater than zero') `
            "Missing final threshold was not explained."
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $outputRootAbsolute $missingThresholdSession))) `
            "Invalid final plan mutated its session path."

        $oldLedgerSession = "old-ledger"
        $oldLedgerRoot = Join-Path $outputRootAbsolute $oldLedgerSession
        [void][System.IO.Directory]::CreateDirectory($oldLedgerRoot)
        [pscustomobject]@{
            schema_version = 3
            session_id = $oldLedgerSession
            runs = @()
        } | ConvertTo-Json | Set-Content -LiteralPath `
            (Join-Path $oldLedgerRoot "session-ledger.json") -Encoding UTF8
        $oldLedger = Invoke-Wave `
            -Phase "baseline" `
            -SessionId $oldLedgerSession
        Assert-True ($oldLedger.ExitCode -ne 0) `
            "Schema-3 recovery ledger was silently accepted or migrated."
        Assert-True ($oldLedger.Text -match
            'expected 4.*new SessionId.*not migrated') `
            "Old-ledger rejection did not explain the clean-baseline requirement."

        $invalidRangeSession = "invalid-range"
        $invalidRange = Invoke-Wave `
            -Phase "baseline" `
            -SessionId $invalidRangeSession `
            -MinimumInstructionPercent 101.0
        Assert-True ($invalidRange.ExitCode -ne 0) `
            "Instruction threshold above 100 was not rejected."
        Assert-True ($invalidRange.Text -match
            'ValidateRange|maximum allowed range|MinimumInstructionPercent') `
            "Out-of-range instruction threshold was not explained: $($invalidRange.Text)"
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $outputRootAbsolute $invalidRangeSession))) `
            "Out-of-range threshold mutated its session path."

        $invalidCheckpointSession = "invalid-checkpoint"
        $invalidCheckpoint = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $invalidCheckpointSession `
            -CheckpointId "..\escape"
        Assert-True ($invalidCheckpoint.ExitCode -ne 0) `
            "Unsafe CheckpointId was not rejected."
        Assert-True ($invalidCheckpoint.Text -match 'CheckpointId must contain only') `
            "Unsafe CheckpointId rejection did not explain the path constraint."
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $outputRootAbsolute $invalidCheckpointSession))) `
            "Unsafe CheckpointId mutated its session path."

        $invalidSession = Invoke-Wave `
            -Phase "baseline" `
            -SessionId "..\escape"
        Assert-True ($invalidSession.ExitCode -ne 0) "Unsafe SessionId was not rejected."
        Assert-True ($invalidSession.Text -match 'SessionId must contain only') `
            "Unsafe SessionId rejection did not explain the path constraint."

        $unsafeOutputRelative = Join-Path "docs" ($contractId + "-unsafe")
        $unsafeOutputAbsolute = [System.IO.Path]::GetFullPath(
            (Join-Path $sandboxRepoRoot $unsafeOutputRelative))
        $unsafeOutput = Invoke-Wave `
            -Phase "baseline" `
            -SessionId "unsafe-output" `
            -OutputRoot $unsafeOutputRelative
        Assert-True ($unsafeOutput.ExitCode -ne 0) `
            "Unignored conventional-output violation was not rejected."
        Assert-True ($unsafeOutput.Text -match "ignored.*'a' or 'artifacts'") `
            "Unsafe OutputRoot rejection did not explain the allowed roots."
        Assert-True (-not (Test-Path -LiteralPath $unsafeOutputAbsolute)) `
            "Unsafe OutputRoot rejection wrote into the repository."

        $externalOutputRoot = Join-Path ([System.IO.Path]::GetTempPath()) `
            ("otmatch-wave-output-sentinel-" + [guid]::NewGuid().ToString("N"))
        $reparseOutputAbsolute =
            Join-Path $sandboxRepoRoot "a\reparse-output"
        [void][System.IO.Directory]::CreateDirectory($externalOutputRoot)
        [void][System.IO.Directory]::CreateDirectory(
            (Join-Path $externalOutputRoot "reparse-session"))
        $externalOutputSentinel = Join-Path `
            (Join-Path $externalOutputRoot "reparse-session") `
            "sentinel.txt"
        [System.IO.File]::WriteAllText(
            $externalOutputSentinel, "external output sentinel")
        try {
            [void](New-Item -ItemType Junction -Path $reparseOutputAbsolute `
                -Target $externalOutputRoot -Force)
            $reparseOutputResult = Invoke-Wave `
                -Phase "baseline" `
                -SessionId "reparse-session" `
                -OutputRoot "a\reparse-output"
            Assert-True ($reparseOutputResult.ExitCode -ne 0 -and
                $reparseOutputResult.Text -match 'reparse-point ancestor') `
                "Recovery-wave output accepted a reparse-point ancestor."
            Assert-True ((Get-Content -LiteralPath $externalOutputSentinel -Raw) -ceq
                "external output sentinel") `
                "Recovery-wave output altered an external reparse target."
            $externalLedgerPath = Join-Path `
                (Split-Path -Parent $externalOutputSentinel) `
                "session-ledger.json"
            Assert-True (-not (Test-Path -LiteralPath $externalLedgerPath `
                    -PathType Leaf)) `
                "Recovery-wave output wrote a ledger through a reparse point."
        }
        finally {
            if (Test-Path -LiteralPath $reparseOutputAbsolute) {
                [System.IO.Directory]::Delete($reparseOutputAbsolute)
            }
            if (Test-Path -LiteralPath $externalOutputRoot -PathType Container) {
                $resolvedExternalOutputRoot =
                    (Resolve-Path -LiteralPath $externalOutputRoot).Path
                $tempPrefix = [System.IO.Path]::GetFullPath(
                    [System.IO.Path]::GetTempPath()).TrimEnd('\', '/') +
                    [System.IO.Path]::DirectorySeparatorChar
                if (-not $resolvedExternalOutputRoot.StartsWith(
                        $tempPrefix,
                        [System.StringComparison]::OrdinalIgnoreCase)) {
                    throw "Refusing to clean unexpected output sentinel path."
                }
                Remove-Item -LiteralPath $externalOutputRoot -Recurse -Force
            }
        }

        $lockTimeoutSession = "lock-timeout"
        $lockTimeoutPath = Join-Path `
            (Join-Path $outputRootAbsolute ".session-locks") `
            ($lockTimeoutSession + ".lock")
        [void][System.IO.Directory]::CreateDirectory(
            (Split-Path -Parent $lockTimeoutPath))
        $heldSessionLock = [System.IO.File]::Open(
            $lockTimeoutPath,
            [System.IO.FileMode]::OpenOrCreate,
            [System.IO.FileAccess]::ReadWrite,
            [System.IO.FileShare]::None)
        try {
            $lockTimeout = Invoke-Wave `
                -Phase "baseline" `
                -SessionId $lockTimeoutSession `
                -SessionLockTimeoutMilliseconds 200
        }
        finally {
            $heldSessionLock.Dispose()
        }
        Assert-True ($lockTimeout.ExitCode -ne 0) `
            "Concurrent session invocation bypassed the exclusive ledger lock."
        Assert-True ($lockTimeout.Text -match
            'Timed out.*exclusive recovery-wave session lock') `
            "Session-lock timeout did not fail closed with a useful diagnostic."
        $lockTimeoutSessionPath =
            Join-Path $outputRootAbsolute $lockTimeoutSession
        Assert-True (-not (Test-Path -LiteralPath $lockTimeoutSessionPath)) `
            "Session-lock timeout mutated the locked session ledger."

        $orphanSession = "orphan-promotion"
        $orphanPromotion = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $orphanSession `
            -CheckpointId "wave-orphan" `
            -Execute
        Assert-True ($orphanPromotion.ExitCode -ne 0) `
            "Promotion execution succeeded without a passed baseline."
        Assert-True ($orphanPromotion.Text -match 'requires a passed executed baseline') `
            "Orphan promotion did not report its baseline prerequisite."
        Assert-True (-not (Test-Path -LiteralPath (Join-Path $outputRootAbsolute $orphanSession))) `
            "Orphan promotion wrote a session ledger before its prerequisite passed."

        $dirtyBaselinePath = Join-Path $sandboxRepoRoot "dirty-baseline.txt"
        [System.IO.File]::WriteAllText($dirtyBaselinePath, "dirty baseline")
        $dirtyBaselineSession = "dirty-baseline"
        $dirtyBaselineResult = Invoke-Wave `
            -Phase "baseline" `
            -SessionId $dirtyBaselineSession `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($dirtyBaselineResult.ExitCode -ne 0) `
            "Executed baseline accepted a dirty worktree."
        Assert-True ($dirtyBaselineResult.Text -match 'requires a clean committed worktree') `
            "Dirty baseline rejection did not explain the clean-worktree policy."
        $dirtyBaselineSessionPath =
            Join-Path $outputRootAbsolute $dirtyBaselineSession
        Assert-True (-not (Test-Path -LiteralPath $dirtyBaselineSessionPath)) `
            "Dirty baseline rejection wrote session evidence."
        Remove-Item -LiteralPath $dirtyBaselinePath -Force

        $endMutationSession = "end-mutation"
        $endMutationPath = Join-Path $sandboxRepoRoot "end-mutation.txt"
        $previousMutationPath =
            [Environment]::GetEnvironmentVariable(
                "OTWIN_RECOVERY_CONTRACT_MUTATE_PATH", "Process")
        [Environment]::SetEnvironmentVariable(
            "OTWIN_RECOVERY_CONTRACT_MUTATE_PATH", $endMutationPath, "Process")
        try {
            $endMutationResult = Invoke-Wave `
                -Phase "baseline" `
                -SessionId $endMutationSession `
                -Execute `
                -Runner $fakeRunnerPath
        }
        finally {
            [Environment]::SetEnvironmentVariable(
                "OTWIN_RECOVERY_CONTRACT_MUTATE_PATH", $previousMutationPath, "Process")
        }
        Assert-True ($endMutationResult.ExitCode -ne 0) `
            "Executed baseline passed after its Git worktree changed mid-run."
        Assert-True ($endMutationResult.Text -match
            'Git worktree/index state changed during recovery-wave execution') `
            "End-of-run worktree drift did not fail with a useful diagnostic."
        $endMutationLedger = Get-Ledger $endMutationSession
        $endMutationRun = @($endMutationLedger.runs)[0]
        Assert-True ([string]$endMutationRun.status -ceq "failed" -and
            [bool]$endMutationRun.git_end_snapshot_captured -and
            [bool]$endMutationRun.end_worktree_dirty) `
            "Failed end-of-run boundary was not retained in the ledger."
        Assert-True ($null -ne $endMutationRun.gate_snapshot_end -and
            [string]$endMutationRun.gate_snapshot_end.gate_semantics_sha256 -match
            '^[0-9a-f]{64}$') `
            "End-of-run gate semantics were not recomputed before rejection."
        Remove-Item -LiteralPath $endMutationPath -Force

        $executeSession = "execute-contract"
        $executeBaselineResult = Invoke-Wave `
            -Phase "baseline" `
            -SessionId $executeSession `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($executeBaselineResult.ExitCode -eq 0) `
            "Fake-runner baseline execution failed: $($executeBaselineResult.Text)"
        $executeLedger = Get-Ledger $executeSession
        Assert-True (@($executeLedger.runs).Count -eq 1) `
            "Executed baseline wrote the wrong run count."
        $executeBaseline = @($executeLedger.runs)[0]
        Assert-True ([string]$executeBaseline.status -ceq "passed") `
            "Executed baseline was not recorded as passed."
        Assert-True ([bool]$executeBaseline.git_snapshot_captured) `
            "Executed baseline did not record its Git snapshot."
        Assert-True ([string]$executeBaseline.git_commit_sha -match '^[0-9a-f]{40}$') `
            "Executed baseline did not record its HEAD commit."
        Assert-True ($executeBaseline.PSObject.Properties.Name -contains "worktree_status") `
            "Executed baseline did not record worktree status."
        Assert-True (-not [bool]$executeBaseline.worktree_dirty) `
            "Executed baseline was not recorded as clean."
        Assert-True ([string]$executeBaseline.gate_snapshot.gate_semantics_sha256 -match
            '^[0-9a-f]{64}$') `
            "Executed baseline did not bind its gate semantics."
        Assert-True ([string]$executeBaseline.gate_snapshot.execution_snapshot_sha256 -match
            '^[0-9a-f]{64}$') `
            "Executed baseline did not bind mutable checkpoint inputs."
        Assert-True ([bool]$executeBaseline.git_end_snapshot_captured -and
            [string]$executeBaseline.git_end_commit_sha -ceq
            [string]$executeBaseline.git_commit_sha -and
            [string]$executeBaseline.end_worktree_state_sha256 -ceq
            [string]$executeBaseline.worktree_state_sha256 -and
            -not [bool]$executeBaseline.end_worktree_dirty) `
            "Executed baseline did not retain an identical clean end snapshot."
        Assert-True ([string]$executeBaseline.gate_snapshot_end.execution_snapshot_sha256 -ceq
            [string]$executeBaseline.gate_snapshot.execution_snapshot_sha256) `
            "Executed baseline did not preserve gate/input semantics through completion."
        $boundPayloadNames = @(
            $executeBaseline.gate_snapshot.payload_trees | ForEach-Object {
                [string]$_.name
            })
        foreach ($requiredPayloadName in @(
                "vc4_bin", "vc4_include", "vc4_lib", "product_resources")) {
            Assert-True ($boundPayloadNames -ccontains $requiredPayloadName) `
                "Executed baseline did not bind payload tree '$requiredPayloadName'."
        }
        $boundToolNames = @($executeBaseline.gate_snapshot.tools | ForEach-Object {
            [string]$_.name
        })
        foreach ($requiredToolName in @(
                "process_runner",
                "pe_compare",
                "verifier_contract",
                "metrics_contract",
                "build_cache_contract",
                "wip_queue_contract",
                "recovery_wave_contract",
                "dossier_generator",
                "dossier_contract",
                "source_shape_runner",
                "product_reanchor_generator",
                "product_reanchor_contract")) {
            Assert-True ($boundToolNames -ccontains $requiredToolName) `
                "Executed baseline did not bind gate tool '$requiredToolName'."
        }
        $boundMutableInputNames = @(
            $executeBaseline.gate_snapshot.mutable_inputs |
                ForEach-Object { [string]$_.name })
        Assert-True ($boundMutableInputNames -ccontains "vc4_tu_metadata") `
            "Executed baseline did not bind VC4 translation-unit metadata."
        Assert-True ([int]$executeBaseline.metrics_summary.schema_version -eq 2) `
            "Executed baseline did not bind its metrics summary."
        Assert-True ([int]$executeBaseline.metrics_summary.strict.accepted_identity_count -eq 2) `
            "Executed baseline recorded the wrong accepted identity set."
        Assert-True (@($executeBaseline.steps | Where-Object status -ne "passed").Count -eq 0) `
            "Executed baseline did not pass every core gate."

        Write-MetricsControl `
            -AcceptedIdentities @(
                "oregon32.exe|0x1000",
                "oregon32.exe|0x2000",
                "oregon32.exe|0x3000") `
            -AcceptedInstructions 70
        Write-PromotionEvidence `
            -CheckpointId "wave-execute" `
            -PriorBoundaryRunId ([string]$executeBaseline.run_id) `
            -Identities @("oregon32.exe|0x3000")
        $executePromotionResult = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-execute" `
            -MinimumInstructionGain 20 `
            -PromotionEvidencePath $promotionEvidenceRelative `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($executePromotionResult.ExitCode -eq 0) `
            "Promotion execution did not accept its ancestral baseline: $($executePromotionResult.Text)"
        $executeLedger = Get-Ledger $executeSession
        Assert-True (@($executeLedger.runs).Count -eq 2) `
            "Executed promotion did not append exactly one run."
        $executePromotion = @($executeLedger.runs)[1]
        Assert-True ([string]$executePromotion.status -ceq "passed") `
            "Executed promotion was not recorded as passed."
        Assert-True ([string]$executePromotion.baseline_run_id -ceq [string]$executeBaseline.run_id) `
            "Executed promotion did not record the baseline transition."
        Assert-True ([string]$executePromotion.prior_boundary_run_id -ceq
            [string]$executeBaseline.run_id) `
            "First promotion did not use the baseline as its prior boundary."
        Assert-True ([int]$executePromotion.metrics_summary.strict.accepted_identity_count -eq 3 -and
            [int]$executePromotion.metrics_summary.strict.accepted_instructions -eq 70) `
            "Executed promotion did not record its expanded metrics boundary."
        Assert-True ([uint64]$executePromotion.promotion_delta.accepted_instruction_gain -eq 20 -and
            [uint64]$executePromotion.promotion_delta.new_identity_count -eq 1 -and
            [string]$executePromotion.promotion_delta.new_identities[0] -ceq
                "oregon32.exe|0x3000") `
            "Executed promotion did not retain its exact measured delta."
        Assert-True ([bool]$executePromotion.promotion_evidence.validated -and
            [bool]$executePromotion.promotion_evidence.end_verified -and
            [string]$executePromotion.promotion_evidence.sha256 -match
                '^[0-9a-f]{64}$' -and
            @($executePromotion.promotion_evidence.bindings).Count -eq 1) `
            "Executed promotion did not hash-bind and end-verify exact evidence."
        Assert-True (@($executePromotion.steps | Where-Object status -ne "passed").Count -eq 0) `
            "Executed promotion did not pass its core and precommit gates."

        Write-MetricsControl `
            -AcceptedIdentities @(
                "oregon32.exe|0x1000",
                "oregon32.exe|0x2000",
                "oregon32.exe|0x3000",
                "oregon32.exe|0x4000") `
            -AcceptedInstructions 74
        $deltaShortfall = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-delta-shortfall" `
            -MinimumInstructionGain 5 `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($deltaShortfall.ExitCode -ne 0 -and
            $deltaShortfall.Text -match
                'Accepted-instruction gain 4 is below required minimum 5') `
            "Promotion instruction-delta shortfall was not rejected clearly."

        Write-MetricsControl `
            -AcceptedIdentities @(
                "oregon32.exe|0x1000",
                "oregon32.exe|0x2000",
                "oregon32.exe|0x3000",
                "oregon32.exe|0x4000") `
            -AcceptedInstructions 75
        $missingEvidence = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-missing-evidence" `
            -MinimumInstructionGain 5 `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($missingEvidence.ExitCode -ne 0 -and
            $missingEvidence.Text -match
                'Promotion evidence is required for 1 newly accepted') `
            "Newly accepted identity passed without promotion evidence."

        Write-PromotionEvidence `
            -CheckpointId "wave-omitted-evidence" `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -Identities @()
        $omittedEvidence = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-omitted-evidence" `
            -MinimumInstructionGain 5 `
            -PromotionEvidencePath $promotionEvidenceRelative `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($omittedEvidence.ExitCode -ne 0 -and
            $omittedEvidence.Text -match
                'identity set is not exact.*missing: oregon32.exe\|0x4000') `
            "Omitted promotion evidence identity was not rejected."

        Write-PromotionEvidence `
            -CheckpointId "wave-stale-evidence" `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -Identities @("oregon32.exe|0x4000") `
            -StaleSourceHash
        $staleEvidence = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-stale-evidence" `
            -MinimumInstructionGain 5 `
            -PromotionEvidencePath $promotionEvidenceRelative `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($staleEvidence.ExitCode -ne 0 -and
            $staleEvidence.Text -match 'source SHA256 is stale') `
            "Stale promotion source hash was not rejected."
        $staleEvidenceRun = @((Get-Ledger $executeSession).runs)[-1]
        Assert-True ([string]$staleEvidenceRun.status -ceq "failed" -and
            [string]$staleEvidenceRun.promotion_evidence.sha256 -match
                '^[0-9a-f]{64}$' -and
            [string]$staleEvidenceRun.promotion_evidence.error -match
                'source SHA256 is stale') `
            "Failed promotion did not retain its evidence hash and diagnostic."

        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-generic-dossier" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "extension '.md' is not allowed" `
            -FixtureOptions @{ UseGenericDossier = $true }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-generic-focused-csv" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "extension '.csv' is not allowed" `
            -FixtureOptions @{ UseGenericFocusedResult = $true }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-dossier-identity-mismatch" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "Promotion dossier identity.*does not match" `
            -FixtureOptions @{
                DossierIdentity = "oregon32.exe|0x5000"
            }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-focused-identity-mismatch" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "Focused source-shape identity.*does not match" `
            -FixtureOptions @{
                FocusedIdentity = "oregon32.exe|0x5000"
            }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-dossier-source-stale" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "current source SHA256 is stale or mismatched" `
            -FixtureOptions @{ DossierSourceMismatch = $true }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-tu-flags-without-metadata" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "without TU metadata has nonempty extra_compile_flags" `
            -FixtureOptions @{ DossierExtraCompileFlags = "/GX" }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-invalid-tu-flags" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "TU metadata flags may contain only" `
            -FixtureOptions @{
                DossierTuMetadataFound = $true
                DossierExtraCompileFlags = "/O1"
            }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-stale-verifier-provenance" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "verifier original file SHA256 is stale" `
            -FixtureOptions @{ DossierProvenanceHashStale = $true }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-unbound-verifier-provenance" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "evidence inventory does not bind verifier original_file" `
            -FixtureOptions @{
                DossierProvenanceInventoryMismatch = $true
            }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-focused-source-stale" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "successful trial does not bind the current source" `
            -FixtureOptions @{ FocusedSourceMismatch = $true }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-focused-symbol-mismatch" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "candidate symbol.*does not match dossier.*manifest" `
            -FixtureOptions @{
                DossierTuMetadataFound = $true
                DossierExtraCompileFlags = "/GX /Oy-"
                FocusedSymbolMismatch = $true
            }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-focused-runner-stale" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "runner script SHA256 is stale" `
            -FixtureOptions @{ FocusedRunnerHashStale = $true }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-nonzero-hard-residual" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "does not prove a zero-hard-residual" `
            -FixtureOptions @{ NonzeroHardResidual = $true }
        foreach ($timingCase in @(
                [pscustomobject]@{
                    Id = "wave-run-summary-string-timing"
                    Option = "RunSummaryStringTiming"
                },
                [pscustomobject]@{
                    Id = "wave-run-summary-fractional-timing"
                    Option = "RunSummaryFractionalTiming"
                },
                [pscustomobject]@{
                    Id = "wave-run-summary-null-timing"
                    Option = "RunSummaryNullTiming"
                })) {
            $timingOptions = @{}
            $timingOptions[$timingCase.Option] = $true
            Assert-InvalidPromotionEvidenceCase `
                -CheckpointId $timingCase.Id `
                -SessionId $executeSession `
                -PriorBoundaryRunId ([string]$executePromotion.run_id) `
                -ExpectedPattern "must be a nonnegative JSON integer" `
                -FixtureOptions $timingOptions
        }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-run-summary-missing-latency-flag" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "build timing exceeds its budget without the latency flag" `
            -FixtureOptions @{ RunSummaryMissingLatencyFlag = $true }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-pending-dossier-checklist" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "checklist 'semantic.behavior' is pending" `
            -FixtureOptions @{ PendingChecklist = $true }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-pending-dossier-review" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "promotion_review is pending" `
            -FixtureOptions @{ DossierReviewFalse = $true }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-unresolved-dossier-warning" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "warnings disposition is pending or unresolved" `
            -FixtureOptions @{ UnresolvedWarnings = $true }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-restoration-failed" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "restoration passed must be the JSON boolean true" `
            -FixtureOptions @{ RestorationFalse = $true }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-restoration-boundary-mismatch" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "restored candidate-normalized does not match" `
            -FixtureOptions @{ RestorationHashMismatch = $true }
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-focused-ineligible" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "promotion_eligible must be the JSON boolean true" `
            -FixtureOptions @{ PromotionIneligible = $true }

        $endEvidenceCandidatePath = Join-Path $sandboxRepoRoot `
            "a\promotion-provenance\candidate.dll"
        $endEvidenceCandidateBytes =
            [System.IO.File]::ReadAllBytes($endEvidenceCandidatePath)
        Write-PromotionEvidence `
            -CheckpointId "wave-provenance-end-mutation" `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -Identities @("oregon32.exe|0x4000")
        $previousEvidenceMutationPath = [Environment]::GetEnvironmentVariable(
            "OTWIN_RECOVERY_CONTRACT_MUTATE_AFTER_EVIDENCE_PATH", "Process")
        try {
            [Environment]::SetEnvironmentVariable(
                "OTWIN_RECOVERY_CONTRACT_MUTATE_AFTER_EVIDENCE_PATH",
                $endEvidenceCandidatePath, "Process")
            $endEvidenceMutation = Invoke-Wave `
                -Phase "promotion-wave" `
                -SessionId $executeSession `
                -CheckpointId "wave-provenance-end-mutation" `
                -MinimumInstructionGain 5 `
                -PromotionEvidencePath $promotionEvidenceRelative `
                -Execute `
                -Runner $fakeRunnerPath
        }
        finally {
            [Environment]::SetEnvironmentVariable(
                "OTWIN_RECOVERY_CONTRACT_MUTATE_AFTER_EVIDENCE_PATH",
                $previousEvidenceMutationPath, "Process")
            [System.IO.File]::WriteAllBytes(
                $endEvidenceCandidatePath, $endEvidenceCandidateBytes)
        }
        Assert-True ($endEvidenceMutation.ExitCode -ne 0 -and
            $endEvidenceMutation.Text -match
                'Promotion evidence changed or escaped its repository boundary' -and
            $endEvidenceMutation.Text -match
                'verifier.*candidate file length is stale') `
            (("End-boundary rehash accepted mutated verifier binary " +
                "provenance. Exit={0}; Output={1}") -f
                $endEvidenceMutation.ExitCode, $endEvidenceMutation.Text)
        $endEvidenceMutationRun = @((Get-Ledger $executeSession).runs)[-1]
        Assert-True ([string]$endEvidenceMutationRun.status -ceq "failed" -and
            -not [bool]$endEvidenceMutationRun.promotion_evidence.end_verified -and
            [string]$endEvidenceMutationRun.promotion_evidence.end_error -match
                'verifier candidate file length is stale') `
            "Verifier binary provenance end-boundary failure was not retained."

        Write-MetricsControl `
            -AcceptedIdentities @(
                "oregon32.exe|0x1000",
                "oregon32.exe|0x2000",
                "oregon32.exe|0x3000",
                "oregon32.exe|0x4000",
                "oregon32.exe|0x5000") `
            -AcceptedInstructions 80
        Assert-InvalidPromotionEvidenceCase `
            -CheckpointId "wave-cross-identity-reuse" `
            -SessionId $executeSession `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -ExpectedPattern "Promotion dossier.*is reused across identities" `
            -Identities @(
                "oregon32.exe|0x4000",
                "oregon32.exe|0x5000") `
            -MinimumInstructionGain 10
        Write-MetricsControl `
            -AcceptedIdentities @(
                "oregon32.exe|0x1000",
                "oregon32.exe|0x2000",
                "oregon32.exe|0x3000",
                "oregon32.exe|0x4000") `
            -AcceptedInstructions 75

        Write-PromotionEvidence `
            -CheckpointId "wave-extra-evidence" `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -Identities @(
                "oregon32.exe|0x4000",
                "oregon32.exe|0x5000")
        $extraEvidence = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-extra-evidence" `
            -MinimumInstructionGain 5 `
            -PromotionEvidencePath $promotionEvidenceRelative `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($extraEvidence.ExitCode -ne 0 -and
            $extraEvidence.Text -match
                'identity set is not exact.*extra: oregon32.exe\|0x5000') `
            "Extra promotion evidence identity was not rejected."

        Write-PromotionEvidence `
            -CheckpointId "wave-duplicate-evidence" `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -Identities @(
                "oregon32.exe|0x4000",
                "oregon32.exe|0x4000")
        $duplicateEvidence = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-duplicate-evidence" `
            -MinimumInstructionGain 5 `
            -PromotionEvidencePath $promotionEvidenceRelative `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($duplicateEvidence.ExitCode -ne 0 -and
            $duplicateEvidence.Text -match 'contains duplicate identity') `
            "Duplicate promotion evidence identity was not rejected."

        Write-PromotionEvidence `
            -CheckpointId "wave-review-false" `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -Identities @("oregon32.exe|0x4000") `
            -ReviewFalse
        $reviewFalseEvidence = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-review-false" `
            -MinimumInstructionGain 5 `
            -PromotionEvidencePath $promotionEvidenceRelative `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($reviewFalseEvidence.ExitCode -ne 0 -and
            $reviewFalseEvidence.Text -match
                'requires semantic_review_passed=true') `
            "False semantic review evidence was not rejected."

        [void](Invoke-SandboxGit @("add", "test-tools/metrics-summary.json"))
        [void](Invoke-SandboxGit @(
            "commit", "--quiet", "-m", "contract promotion boundary"))

        $runCountBeforeDuplicate = @((Get-Ledger $executeSession).runs).Count

        $duplicatePromotion = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-execute" `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($duplicatePromotion.ExitCode -ne 0) `
            "A passed checkpoint was allowed to overwrite its evidence."
        Assert-True ($duplicatePromotion.Text -match 'already has a passed execution') `
            "Duplicate checkpoint rejection was not explained."
        $executeLedger = Get-Ledger $executeSession
        Assert-True (@($executeLedger.runs).Count -eq $runCountBeforeDuplicate) `
            "Rejected duplicate checkpoint still changed the ledger."

        Write-MetricsControl `
            -AcceptedIdentities @(
                "oregon32.exe|0x2000",
                "oregon32.exe|0x3000",
                "oregon32.exe|0x4000") `
            -AcceptedInstructions 75
        $baselineIdentityRegression = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-baseline-identity-regression" `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($baselineIdentityRegression.ExitCode -ne 0) `
            "A later wave dropped an identity accepted by the clean baseline."
        Assert-True ($baselineIdentityRegression.Text -match
            'Accepted identity regression relative to the clean session baseline') `
            "Baseline identity regression was not explained."

        Write-MetricsControl `
            -AcceptedIdentities @(
                "oregon32.exe|0x1000",
                "oregon32.exe|0x2000",
                "oregon32.exe|0x4000") `
            -AcceptedInstructions 75
        $priorIdentityRegression = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-prior-identity-regression" `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($priorIdentityRegression.ExitCode -ne 0) `
            "A later wave dropped an identity accepted by the prior wave."
        Assert-True ($priorIdentityRegression.Text -match
            'Accepted identity regression relative to prior passed checkpoint') `
            "Prior-wave identity regression was not explained."

        Write-MetricsControl `
            -AcceptedIdentities @(
                "oregon32.exe|0x1000",
                "oregon32.exe|0x2000",
                "oregon32.exe|0x3000") `
            -AcceptedInstructions 69
        $instructionRegression = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-instruction-regression" `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($instructionRegression.ExitCode -ne 0) `
            "A later wave regressed strict accepted instructions."
        Assert-True ($instructionRegression.Text -match
            'Strict accepted instructions regressed relative to prior passed checkpoint') `
            "Instruction regression was not explained."

        Write-MetricsControl `
            -AcceptedIdentities @(
                "oregon32.exe|0x1000",
                "oregon32.exe|0x2000",
                "oregon32.exe|0x3000") `
            -AcceptedInstructions 70 `
            -ManifestIdentitySha256 ("b" * 64)
        $manifestUniverseRegression = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-manifest-universe-regression" `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($manifestUniverseRegression.ExitCode -ne 0) `
            "A later wave accepted a changed manifest identity universe."
        Assert-True ($manifestUniverseRegression.Text -match
            'Manifest identity universe changed relative to the clean session baseline') `
            "Manifest identity-universe regression was not explained."

        Write-MetricsControl `
            -AcceptedIdentities @(
                "oregon32.exe|0x1000",
                "oregon32.exe|0x2000",
                "oregon32.exe|0x3000") `
            -AcceptedInstructions 70 `
            -DenominatorInstructions 101 `
            -DenominatorIdentitySha256 ("e" * 64)
        $denominatorRegression = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-denominator-regression" `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($denominatorRegression.ExitCode -ne 0) `
            "A later wave accepted a changed metrics denominator."
        Assert-True ($denominatorRegression.Text -match
            'Metrics denominator changed relative to the clean session baseline') `
            "Denominator regression was not explained."

        Write-MetricsControl `
            -AcceptedIdentities @(
                "oregon32.exe|0x1000",
                "oregon32.exe|0x2000",
                "oregon32.exe|0x3000") `
            -AcceptedInstructions 70 `
            -BodyOwnershipSha256 ("c" * 64)
        $ownershipRegression = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-body-ownership-regression" `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($ownershipRegression.ExitCode -ne 0 -and
            $ownershipRegression.Text -match
                'Metrics denominator changed relative to the clean session baseline') `
            "A later wave accepted changed function-body ownership."

        Write-MetricsControl `
            -AcceptedIdentities @(
                "oregon32.exe|0x1000",
                "oregon32.exe|0x2000",
                "oregon32.exe|0x3000",
                "oregon32.exe|0x4000") `
            -AcceptedInstructions 75
        $finalNewIdentity = Invoke-Wave `
            -Phase "final" `
            -SessionId $executeSession `
            -CheckpointId "final-new-identity" `
            -MinimumInstructionPercent 55 `
            -MinimumInstructionGain 0 `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($finalNewIdentity.ExitCode -ne 0 -and
            $finalNewIdentity.Text -match
                'Promotion evidence is required for 1 newly accepted') `
            "Final phase accepted a newly promoted identity without evidence."

        Write-MetricsControl `
            -AcceptedIdentities @(
                "oregon32.exe|0x1000",
                "oregon32.exe|0x2000",
                "oregon32.exe|0x3000") `
            -AcceptedInstructions 70
        $finalNoIdentity = Invoke-Wave `
            -Phase "final" `
            -SessionId $executeSession `
            -CheckpointId "final-no-new-identity" `
            -MinimumInstructionPercent 55 `
            -MinimumInstructionGain 0 `
            -Execute `
            -Runner $fakeRunnerPath
        $finalNoIdentityLedger = Get-Ledger $executeSession
        $finalNoIdentityRun = @($finalNoIdentityLedger.runs)[-1]
        Assert-True ([string](Get-Step $finalNoIdentityRun `
                "promotion-delta-evidence").status -ceq "passed" -and
            [uint64]$finalNoIdentityRun.promotion_delta.accepted_instruction_gain -eq 0 -and
            [string]$finalNoIdentityRun.promotion_evidence.status -ceq "not-required") `
            "Final phase did not allow gain=0 with no newly accepted identities."
        Assert-True ($finalNoIdentity.ExitCode -ne 0 -and
            $finalNoIdentity.Text -match "cmake-build|cmake") `
            "Synthetic final did not proceed beyond promotion evidence to its expected downstream test failure."

        Write-MetricsControl `
            -AcceptedIdentities @(
                "oregon32.exe|0x1000",
                "oregon32.exe|0x2000",
                "oregon32.exe|0x3000") `
            -AcceptedInstructions 70
        $matcherStubPath = Join-Path $sandboxRepoRoot "tools\otmatch\match-functions.ps1"
        [System.IO.File]::AppendAllText($matcherStubPath, "# gate drift`r`n")
        $toolDrift = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-tool-drift" `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($toolDrift.ExitCode -ne 0) `
            "Promotion accepted changed gate semantics."
        Assert-True ($toolDrift.Text -match 'Recovery gate semantics changed since the baseline') `
            "Gate-semantics drift was not explained."
        [System.IO.File]::WriteAllText(
            $matcherStubPath, "# recovery-wave contract gate stub`r`n")

        $productReanchorStubPath = Join-Path $sandboxRepoRoot `
            "tools\otmatch\invoke-product-reanchor-evidence.ps1"
        [System.IO.File]::AppendAllText(
            $productReanchorStubPath, "# Product reanchor gate drift`r`n")
        $productReanchorToolDrift = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-product-reanchor-tool-drift" `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($productReanchorToolDrift.ExitCode -ne 0 -and
            $productReanchorToolDrift.Text -match
                'Recovery gate semantics changed since the baseline') `
            "Product-reanchor gate-tool drift was not rejected and explained."
        [System.IO.File]::WriteAllText(
            $productReanchorStubPath,
            "# recovery-wave contract gate stub`r`n")

        $c2Path = Join-Path $sandboxRepoRoot "vc4\BIN\C2.EXE"
        [System.IO.File]::AppendAllText($c2Path, " drift")
        $compilerPassDrift = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-c2-drift" `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($compilerPassDrift.ExitCode -ne 0 -and
            $compilerPassDrift.Text -match
            'Recovery gate semantics changed since the baseline') `
            "Promotion accepted a changed VC4 compiler-pass payload."
        [System.IO.File]::WriteAllText($c2Path, "contract c2")

        $libcPath = Join-Path $sandboxRepoRoot "vc4\LIB\LIBC.LIB"
        [System.IO.File]::AppendAllText($libcPath, " drift")
        $libraryDrift = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-libc-drift" `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($libraryDrift.ExitCode -ne 0 -and
            $libraryDrift.Text -match
            'Recovery gate semantics changed since the baseline') `
            "Promotion accepted a changed VC4 library payload."
        [System.IO.File]::WriteAllText($libcPath, "contract libc")

        $resourcePayloadPath =
            Join-Path $sandboxRepoRoot "resources\otwin32\contract.res"
        [System.IO.File]::AppendAllText($resourcePayloadPath, " drift")
        $resourceDrift = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-resource-drift" `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($resourceDrift.ExitCode -ne 0 -and
            $resourceDrift.Text -match
            'Recovery gate semantics changed since the baseline') `
            "Promotion accepted a changed ignored Product resource payload."
        [System.IO.File]::WriteAllText(
            $resourcePayloadPath, "contract resource")

        Write-MetricsControl `
            -AcceptedIdentities @(
                "oregon32.exe|0x1000",
                "oregon32.exe|0x2000",
                "oregon32.exe|0x3000",
                "oregon32.exe|0x4000") `
            -AcceptedInstructions 75
        Write-PromotionEvidence `
            -CheckpointId "wave-whitespace-audit" `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -Identities @("oregon32.exe|0x4000")

        $contractSourcePath = Join-Path $sandboxRepoRoot "src\contract.cpp"
        [System.IO.File]::WriteAllText(
            $contractSourcePath, "int contract_source = 1;   `r`n")
        $whitespaceAudit = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-whitespace-audit" `
            -MinimumInstructionGain 5 `
            -PromotionEvidencePath $promotionEvidenceRelative `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($whitespaceAudit.ExitCode -ne 0) `
            "Promotion precommit gate accepted whitespace errors."
        Assert-True ($whitespaceAudit.Text -match 'whitespace error|trailing whitespace') `
            "Promotion whitespace failure was not reported."
        [System.IO.File]::WriteAllText(
            $contractSourcePath, "int contract_source = 1;`r`n")

        Write-PromotionEvidence `
            -CheckpointId "wave-asset-audit" `
            -PriorBoundaryRunId ([string]$executePromotion.run_id) `
            -Identities @("oregon32.exe|0x4000")

        $forbiddenAssetPath = Join-Path $sandboxRepoRoot "forbidden.bmp"
        [System.IO.File]::WriteAllText($forbiddenAssetPath, "not an original asset")
        $assetAudit = Invoke-Wave `
            -Phase "promotion-wave" `
            -SessionId $executeSession `
            -CheckpointId "wave-asset-audit" `
            -MinimumInstructionGain 5 `
            -PromotionEvidencePath $promotionEvidenceRelative `
            -Execute `
            -Runner $fakeRunnerPath
        Assert-True ($assetAudit.ExitCode -ne 0) `
            "Promotion repository boundary accepted a forbidden asset path."
        Assert-True ($assetAudit.Text -match 'Repository boundary check failed.*forbidden.bmp') `
            "Promotion asset-boundary failure was not reported."
        Remove-Item -LiteralPath $forbiddenAssetPath -Force
        if (Test-Path -LiteralPath $promotionEvidencePath -PathType Leaf) {
            Remove-Item -LiteralPath $promotionEvidencePath -Force
        }
        [System.IO.File]::WriteAllText(
            (Join-Path $sandboxRepoRoot $evidenceDossierRelative),
            "{}`r`n")
        [System.IO.File]::WriteAllText(
            (Join-Path $sandboxRepoRoot $evidenceFocusedResultRelative),
            "{}`r`n")

        $failureSession = "failure-contract"
        $failedBaselineResult = Invoke-Wave `
            -Phase "baseline" `
            -SessionId $failureSession `
            -Execute
        Assert-True ($failedBaselineResult.ExitCode -ne 0) `
            "Explicit execution unexpectedly succeeded with a missing runner."
        Assert-True ($failedBaselineResult.Text -match 'Executable was not found') `
            "Explicit execution failure did not identify its missing runner."
        $failureLedger = Get-Ledger $failureSession
        $failedRun = @($failureLedger.runs)[0]
        Assert-True ([string]$failedRun.mode -ceq "execute") `
            "Explicit execution ledger has the wrong mode."
        Assert-True ([string]$failedRun.status -ceq "failed") `
            "Explicit execution failure was not recorded."
        Assert-True ([string]$failedRun.steps[0].status -ceq "failed") `
            "Failed execution step was not recorded."
        Assert-True (@($failedRun.steps | Select-Object -Skip 1 | Where-Object status -ne "skipped").Count -eq 0) `
            "Later execution steps were not skipped after failure."

        Write-Host "Recovery-wave orchestration contract: PASS"
    }
    finally {
        Pop-Location
    }
}
finally {
    $allowedRoot = [System.IO.Path]::GetFullPath((Join-Path $hostRepoRoot "a"))
    $allowedPrefix = $allowedRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    if ($contractRoot.StartsWith($allowedPrefix, [System.StringComparison]::OrdinalIgnoreCase) -and
        (Test-Path -LiteralPath $contractRoot -PathType Container)) {
        Remove-Item -LiteralPath $contractRoot -Recurse -Force
    }
}
