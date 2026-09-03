[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$toolPath = (Resolve-Path (Join-Path $PSScriptRoot `
    "carry-forward-recovery-ledgers.ps1")).Path
$shellPath = (Get-Process -Id $PID).Path
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$contractId = [guid]::NewGuid().ToString("N")
$contractRoot = Join-Path $repoRoot (Join-Path "a" (
    "otmatch-carry-forward-contract-" + $contractId))
$fixtureRoot = Join-Path $contractRoot "fixture"
$previousRoot = Join-Path $fixtureRoot "previous"
$currentRoot = Join-Path $fixtureRoot "current"
$evidenceRoot = Join-Path $fixtureRoot "evidence"
$outputRoot = Join-Path $contractRoot "output"
$unsafeOutput = Join-Path $repoRoot (
    "docs\otmatch-carry-forward-contract-unsafe-" + $contractId)

function Assert-True([bool]$Condition, [string]$Context) {
    if (-not $Condition) { throw $Context }
}

function Assert-Equal($Actual, $Expected, [string]$Context) {
    if ([string]$Actual -cne [string]$Expected) {
        throw "$Context expected '$Expected', got '$Actual'."
    }
}

function Get-FileSha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-TextSha256([string]$Text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return [System.BitConverter]::ToString($sha.ComputeHash(
            $utf8NoBom.GetBytes($Text))).Replace("-", "").ToLowerInvariant()
    } finally {
        $sha.Dispose()
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
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $prefix = $repoRoot.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith(
            $prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Fixture path is outside the repository: '$fullPath'."
    }
    return $fullPath.Substring($prefix.Length).Replace('\', '/')
}

function New-CheckpointInputs([string]$Seed, [string]$CandidateFileSha) {
    return [pscustomobject][ordered]@{
        manifest_sha256 = Get-TextSha256 "$Seed-manifest"
        verifier_results_sha256 = Get-TextSha256 "$Seed-verifier"
        progress_metrics_summary_sha256 = Get-TextSha256 "$Seed-metrics"
        candidate_file_sha256 = $CandidateFileSha
        candidate_map_sha256 = Get-TextSha256 "$Seed-map"
        original_exe_sha256 = Get-TextSha256 "shared-original-exe"
        original_dll_sha256 = Get-TextSha256 "shared-original-dll"
    }
}

function New-DashboardRow(
    [int]$Index,
    [string]$Name,
    [string]$CandidateFileSha,
    [string]$CandidateFunctionSha,
    [int]$HardDiffCount,
    [string]$ProductReachable = "True",
    [string]$ImplementationKind = "cpp",
    [string]$VerificationStatus = "allowed_wip",
    [string]$VerifierActualStatus = "mismatch",
    [string]$MaskSha256 = "") {

    if ([string]::IsNullOrWhiteSpace($MaskSha256)) {
        $MaskSha256 = Get-TextSha256 "mask-shape-$Index"
    }

    return [pscustomobject][ordered]@{
        Name = $Name
        Program = "Oregon32.exe"
        OriginalRva = "0x{0:x}" -f (0x1000 + ($Index * 0x10))
        Size = 16
        CandidateSymbol = "_${Name}_ProductWip"
        Status = "OK"
        HardComparedBytes = 16
        HardDiffCount = $HardDiffCount
        YieldInstructions = 10 + $Index
        ImplementationKind = $ImplementationKind
        ProductReachable = $ProductReachable
        VerifierDiagnosticsAvailable = "True"
        VerifierActualStatus = $VerifierActualStatus
        VerificationStatus = $VerificationStatus
        PromotionReady = if ($HardDiffCount -eq 0) { "True" } else { "False" }
        VerifierBlocked = "False"
        MaskShapeValid = "True"
        MaskedOperandShapeError = ""
        MaskedImportIdentityError = ""
        MaskSha256 = $MaskSha256
        CandidateObject = "contract_${Index}.obj"
        CurrentCandidateFileSha256 = $CandidateFileSha
        CurrentCandidateFunctionSha256 = $CandidateFunctionSha
    }
}

function New-ReadinessRow(
    [int]$Index,
    [string]$Name,
    [bool]$TemplateDefault,
    [string]$EvidencePath = "",
    [string]$EvidenceSha = "",
    [string]$Readiness = "ready",
    [string]$DependencyState = "ready") {

    if ($TemplateDefault) {
        $Readiness = "needs-implementation"
        $DependencyState = "incomplete"
    }
    return [pscustomobject][ordered]@{
        program = "Oregon32.exe"
        original_rva = "0x{0:x}" -f (0x1000 + ($Index * 0x10))
        name = $Name
        readiness = $Readiness
        dependency_state = $DependencyState
        reason = if ($TemplateDefault) {
            "Template default: evidence-backed readiness review is incomplete."
        } else {
            "Synthetic reviewed decision for the carry-forward contract."
        }
        template_default = $TemplateDefault
        evidence_path = $EvidencePath
        evidence_sha256 = $EvidenceSha
        confidence = if ($TemplateDefault) { "" } else { "0.75" }
        effort = if ($TemplateDefault) { "" } else { "2" }
        candidate_body_bytes = ""
        candidate_instruction_count = ""
    }
}

function New-SessionRow(
    [int]$Index,
    [string]$Name,
    [string]$State,
    [int]$HardDiffCount,
    [string]$CandidateFunctionSha,
    [string]$SourcePath,
    [string]$SourceSha,
    [string]$EvidencePath,
    [string]$EvidenceSha,
    [int]$Variants) {

    return [pscustomobject][ordered]@{
        program = "Oregon32.exe"
        original_rva = "0x{0:x}" -f (0x1000 + ($Index * 0x10))
        name = $Name
        state = $State
        hypothesis = "Synthetic bounded hypothesis for contract validation."
        started_utc = "2026-07-18T12:00:00Z"
        updated_utc = "2026-07-18T12:30:00Z"
        active_recovery_minutes = 30
        tool_time_ms = 12000
        meaningful_variant_count = $Variants
        evidence_path = $EvidencePath
        evidence_sha256 = $EvidenceSha
        source_path = $SourcePath
        source_sha256 = $SourceSha
        residual = [pscustomobject][ordered]@{
            kind = "strict-linked"
            hard_diff_count = $HardDiffCount
            compared_bytes = 16
            candidate_function_sha256 = $CandidateFunctionSha
        }
    }
}

function New-SessionTemplate($Inputs, [string]$SessionId) {
    return [pscustomobject][ordered]@{
        schema_version = 1
        session_id = $SessionId
        inputs = $Inputs
        row_template = [pscustomobject][ordered]@{
            program = ""
            original_rva = ""
            name = ""
            state = "active"
            hypothesis = ""
            started_utc = ""
            updated_utc = ""
            active_recovery_minutes = 0
            tool_time_ms = 0
            meaningful_variant_count = 0
            evidence_path = ""
            evidence_sha256 = ""
            source_path = ""
            source_sha256 = ""
            residual = [pscustomobject][ordered]@{
                kind = "strict-linked"
                hard_diff_count = 0
                compared_bytes = 0
                candidate_function_sha256 = ""
            }
        }
        rows = @()
    }
}

function Invoke-CarryCase(
    [string]$Name,
    [string]$CaseOutputDirectory,
    [int]$ExpectedExitCode,
    [string]$ExpectedOutput,
    [string]$CasePreviousDashboard = "",
    [string]$CasePreviousReadiness = "",
    [string]$CasePreviousSession = "",
    [string]$CaseCurrentDashboard = "",
    [string]$CaseCurrentReadiness = "",
    [string]$CaseCurrentSession = "",
    [switch]$CaseForce) {

    if ([string]::IsNullOrWhiteSpace($CasePreviousDashboard)) {
        $CasePreviousDashboard = $previousDashboardPath
    }
    if ([string]::IsNullOrWhiteSpace($CasePreviousReadiness)) {
        $CasePreviousReadiness = $previousReadinessPath
    }
    if ([string]::IsNullOrWhiteSpace($CasePreviousSession)) {
        $CasePreviousSession = $previousSessionPath
    }
    if ([string]::IsNullOrWhiteSpace($CaseCurrentDashboard)) {
        $CaseCurrentDashboard = $currentDashboardPath
    }
    if ([string]::IsNullOrWhiteSpace($CaseCurrentReadiness)) {
        $CaseCurrentReadiness = $currentReadinessPath
    }
    if ([string]::IsNullOrWhiteSpace($CaseCurrentSession)) {
        $CaseCurrentSession = $currentSessionPath
    }

    $arguments = @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $toolPath,
        "-PreviousDashboardPath", $CasePreviousDashboard,
        "-PreviousReadinessLedgerPath", $CasePreviousReadiness,
        "-PreviousSessionLaneLedgerPath", $CasePreviousSession,
        "-CurrentDashboardPath", $CaseCurrentDashboard,
        "-CurrentReadinessTemplatePath", $CaseCurrentReadiness,
        "-CurrentSessionLaneTemplatePath", $CaseCurrentSession,
        "-OutputDirectory", $CaseOutputDirectory)
    if ($CaseForce) { $arguments += "-Force" }

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $shellPath @arguments 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $oldPreference
    }
    $outputText = ($output | Out-String).Trim()
    if ($exitCode -ne $ExpectedExitCode) {
        throw "Case '$Name' expected exit $ExpectedExitCode, got $exitCode.`n$outputText"
    }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedOutput) -and
        $outputText -notlike "*$ExpectedOutput*") {
        throw "Case '$Name' did not report '$ExpectedOutput'.`n$outputText"
    }
    return $outputText
}

function Get-RowByName($Rows, [string]$Name, [string]$Context) {
    $matches = @($Rows | Where-Object { $_.name -ceq $Name })
    Assert-Equal $matches.Count 1 "$Context row count for $Name"
    return $matches[0]
}

try {
    [void][System.IO.Directory]::CreateDirectory($previousRoot)
    [void][System.IO.Directory]::CreateDirectory($currentRoot)
    [void][System.IO.Directory]::CreateDirectory($evidenceRoot)

    $names = @(
        "OtStablePaused",          # 0
        "OtStableFrozen",          # 1
        "OtStableClosed",          # 2
        "OtStaleFunction",         # 3
        "OtChangedReachability",   # 4
        "OtStaleReadinessEvidence",# 5
        "OtStaleSessionSource",    # 6
        "OtStaleSessionEvidence",  # 7
        "OtTemplateOnly",          # 8
        "OtChangedMask")           # 9
    $functionHashes = @()
    foreach ($name in $names) {
        $functionHashes += Get-TextSha256 "candidate-$name"
    }
    $previousCandidateFileSha = Get-TextSha256 "previous-candidate-file"
    $currentCandidateFileSha = Get-TextSha256 "current-candidate-file"
    $previousInputs = New-CheckpointInputs "previous" $previousCandidateFileSha
    $currentInputs = New-CheckpointInputs "current" $currentCandidateFileSha

    $previousDashboardRows = @()
    $currentDashboardRows = @()
    for ($i = 0; $i -lt $names.Count; $i++) {
        $hardDiff = if ($i -eq 2) { 0 } else { 1 }
        $oldStatus = if ($hardDiff -eq 0) { "pass" } else { "allowed_wip" }
        $oldActual = if ($hardDiff -eq 0) { "match" } else { "mismatch" }
        $previousDashboardRows += New-DashboardRow $i $names[$i] `
            $previousCandidateFileSha $functionHashes[$i] $hardDiff `
            -VerificationStatus $oldStatus -VerifierActualStatus $oldActual
        $newFunctionSha = if ($i -eq 3) {
            Get-TextSha256 "changed-function-$($names[$i])"
        } else { $functionHashes[$i] }
        $newReachability = if ($i -eq 4) { "False" } else { "True" }
        $newMaskSha = if ($i -eq 9) {
            Get-TextSha256 "changed-mask-shape-$i"
        } else { "" }
        $currentDashboardRows += New-DashboardRow $i $names[$i] `
            $currentCandidateFileSha $newFunctionSha $hardDiff `
            -ProductReachable $newReachability `
            -VerificationStatus $oldStatus -VerifierActualStatus $oldActual `
            -MaskSha256 $newMaskSha
    }

    $previousDashboardPath = Join-Path $previousRoot "wip-residual-dashboard.csv"
    $currentDashboardPath = Join-Path $currentRoot "wip-residual-dashboard.csv"
    Write-Csv $previousDashboardPath $previousDashboardRows
    Write-Csv $currentDashboardPath $currentDashboardRows

    $stableReadinessEvidence = Join-Path $evidenceRoot "stable-readiness.md"
    $functionEvidence = Join-Path $evidenceRoot "function-readiness.md"
    $reachEvidence = Join-Path $evidenceRoot "reach-readiness.md"
    $staleReadinessEvidence = Join-Path $evidenceRoot "stale-readiness.md"
    Write-Utf8 $stableReadinessEvidence "stable readiness evidence`n"
    Write-Utf8 $functionEvidence "function readiness evidence`n"
    Write-Utf8 $reachEvidence "reachability readiness evidence`n"
    Write-Utf8 $staleReadinessEvidence "old readiness evidence`n"
    $stableReadinessSha = Get-FileSha256 $stableReadinessEvidence
    $functionEvidenceSha = Get-FileSha256 $functionEvidence
    $reachEvidenceSha = Get-FileSha256 $reachEvidence
    $staleReadinessSha = Get-FileSha256 $staleReadinessEvidence

    $previousReadinessRows = @()
    for ($i = 0; $i -lt $names.Count; $i++) {
        $templateDefault = $i -in @(6, 7, 8)
        $evidencePath = ""
        $evidenceSha = ""
        if (-not $templateDefault) {
            if ($i -le 2) {
                $evidencePath = Get-RepoRelativePath $stableReadinessEvidence
                $evidenceSha = $stableReadinessSha
            } elseif ($i -eq 3) {
                $evidencePath = Get-RepoRelativePath $functionEvidence
                $evidenceSha = $functionEvidenceSha
            } elseif ($i -eq 4) {
                $evidencePath = Get-RepoRelativePath $reachEvidence
                $evidenceSha = $reachEvidenceSha
            } elseif ($i -eq 5) {
                $evidencePath = Get-RepoRelativePath $staleReadinessEvidence
                $evidenceSha = $staleReadinessSha
            } else {
                $evidencePath = Get-RepoRelativePath $stableReadinessEvidence
                $evidenceSha = $stableReadinessSha
            }
        }
        $classification = if ($i -eq 1) { "blocked" } else { "ready" }
        $previousReadinessRows += New-ReadinessRow $i $names[$i] `
            $templateDefault $evidencePath $evidenceSha $classification "ready"
    }
    $currentReadinessRows = @()
    for ($i = 0; $i -lt $names.Count; $i++) {
        $currentReadinessRows += New-ReadinessRow $i $names[$i] $true
    }

    $previousReadiness = [pscustomobject][ordered]@{
        schema_version = 1
        session_id = "previous-contract-session"
        inputs = $previousInputs
        rows = $previousReadinessRows
    }
    $currentReadiness = [pscustomobject][ordered]@{
        schema_version = 1
        session_id = "current-contract-session"
        inputs = $currentInputs
        rows = $currentReadinessRows
    }
    $previousReadinessPath = Join-Path $previousRoot "readiness-ledger.json"
    $currentReadinessPath = Join-Path $currentRoot "readiness-ledger.template.json"
    Write-Json $previousReadinessPath $previousReadiness
    Write-Json $currentReadinessPath $currentReadiness

    $stableSource = Join-Path $evidenceRoot "stable-source.cpp"
    $stableSessionEvidence = Join-Path $evidenceRoot "stable-session.json"
    $staleSource = Join-Path $evidenceRoot "stale-source.cpp"
    $staleSourceEvidence = Join-Path $evidenceRoot "stale-source-session.json"
    $staleEvidenceSource = Join-Path $evidenceRoot "stale-evidence-source.cpp"
    $staleSessionEvidence = Join-Path $evidenceRoot "stale-session.json"
    $activeSource = Join-Path $evidenceRoot "active-source.cpp"
    Write-Utf8 $stableSource "int stable_source;`n"
    Write-Utf8 $stableSessionEvidence "{}`n"
    Write-Utf8 $staleSource "int old_source;`n"
    Write-Utf8 $staleSourceEvidence "{}`n"
    Write-Utf8 $staleEvidenceSource "int evidence_source;`n"
    Write-Utf8 $staleSessionEvidence "{`"old`":true}`n"
    Write-Utf8 $activeSource "int active_source;`n"

    $previousSessionRows = @(
        (New-SessionRow 0 $names[0] "paused" 1 $functionHashes[0] `
            (Get-RepoRelativePath $stableSource) (Get-FileSha256 $stableSource) `
            (Get-RepoRelativePath $stableSessionEvidence) `
            (Get-FileSha256 $stableSessionEvidence) 3),
        (New-SessionRow 1 $names[1] "frozen" 1 $functionHashes[1] `
            (Get-RepoRelativePath $stableSource) (Get-FileSha256 $stableSource) `
            (Get-RepoRelativePath $stableSessionEvidence) `
            (Get-FileSha256 $stableSessionEvidence) 8),
        (New-SessionRow 2 $names[2] "closed" 0 $functionHashes[2] `
            (Get-RepoRelativePath $stableSource) (Get-FileSha256 $stableSource) `
            (Get-RepoRelativePath $stableSessionEvidence) `
            (Get-FileSha256 $stableSessionEvidence) 2),
        (New-SessionRow 6 $names[6] "paused" 1 $functionHashes[6] `
            (Get-RepoRelativePath $staleSource) (Get-FileSha256 $staleSource) `
            (Get-RepoRelativePath $staleSourceEvidence) `
            (Get-FileSha256 $staleSourceEvidence) 2),
        (New-SessionRow 7 $names[7] "paused" 1 $functionHashes[7] `
            (Get-RepoRelativePath $staleEvidenceSource) `
            (Get-FileSha256 $staleEvidenceSource) `
            (Get-RepoRelativePath $staleSessionEvidence) `
            (Get-FileSha256 $staleSessionEvidence) 2),
        (New-SessionRow 8 $names[8] "active" 1 $functionHashes[8] `
            (Get-RepoRelativePath $activeSource) (Get-FileSha256 $activeSource) `
            "" "" 0))
    $previousSession = [pscustomobject][ordered]@{
        schema_version = 1
        session_id = "previous-contract-session"
        inputs = $previousInputs
        rows = $previousSessionRows
    }
    $currentSession = New-SessionTemplate `
        $currentInputs "current-contract-session"
    $previousSessionPath = Join-Path $previousRoot "session-lane-ledger.json"
    $currentSessionPath = Join-Path $currentRoot "session-lane-ledger.template.json"
    Write-Json $previousSessionPath $previousSession
    Write-Json $currentSessionPath $currentSession

    # Make three otherwise well-formed bindings stale after their recorded
    # hashes have been sealed into the previous ledgers.
    Write-Utf8 $staleReadinessEvidence "changed readiness evidence`n"
    Write-Utf8 $staleSource "int changed_source;`n"
    Write-Utf8 $staleSessionEvidence "{`"changed`":true}`n"

    [void](Invoke-CarryCase "stable-and-stale-bindings" $outputRoot 0 `
        "Readiness decisions: 3 carried, 4 review required.")

    $outputReadinessPath = Join-Path $outputRoot "readiness-ledger.json"
    $outputSessionPath = Join-Path $outputRoot "session-lane-ledger.json"
    $auditPath = Join-Path $outputRoot "carry-forward-audit.json"
    $auditMarkdownPath = Join-Path $outputRoot "carry-forward-audit.md"
    foreach ($path in @(
            $outputReadinessPath, $outputSessionPath,
            $auditPath, $auditMarkdownPath)) {
        Assert-True (Test-Path -LiteralPath $path -PathType Leaf) `
            "Expected output is missing: $path"
    }

    $outputReadiness = Get-Content $outputReadinessPath -Raw | ConvertFrom-Json
    $outputSession = Get-Content $outputSessionPath -Raw | ConvertFrom-Json
    $audit = Get-Content $auditPath -Raw | ConvertFrom-Json
    Assert-Equal $outputReadiness.schema_version 1 "Readiness schema"
    Assert-Equal $outputReadiness.session_id "current-contract-session" `
        "Current readiness session binding"
    Assert-Equal $outputSession.session_id "current-contract-session" `
        "Current session lane binding"
    Assert-Equal $outputReadiness.inputs.candidate_file_sha256 `
        $currentCandidateFileSha "Current readiness checkpoint binding"
    Assert-Equal $outputSession.inputs.candidate_file_sha256 `
        $currentCandidateFileSha "Current session checkpoint binding"
    Assert-Equal @($outputReadiness.rows).Count $names.Count `
        "Fail-closed current readiness universe"

    foreach ($name in $names[0..2]) {
        $row = Get-RowByName $outputReadiness.rows $name "Carried readiness"
        Assert-Equal $row.template_default "False" `
            "Carried readiness template flag for $name"
    }
    foreach ($name in $names[3..9]) {
        $row = Get-RowByName $outputReadiness.rows $name "Default readiness"
        Assert-Equal $row.template_default "True" `
            "Fail-closed template flag for $name"
        Assert-Equal $row.readiness "needs-implementation" `
            "Fail-closed readiness for $name"
    }
    Assert-Equal @($outputSession.rows).Count 3 "Carried session row count"
    Assert-Equal (Get-RowByName $outputSession.rows $names[0] `
        "Session").state "paused" "Paused state carry"
    Assert-Equal (Get-RowByName $outputSession.rows $names[1] `
        "Session").state "frozen" "Frozen state carry"
    Assert-Equal (Get-RowByName $outputSession.rows $names[2] `
        "Session").state "closed" "Closed state carry"

    Assert-Equal $audit.schema_version 1 "Audit schema"
    Assert-Equal $audit.summary.readiness_non_template_candidates 7 `
        "Readiness candidate count"
    Assert-Equal $audit.summary.readiness_carried 3 "Readiness carry count"
    Assert-Equal $audit.summary.readiness_review_required 4 `
        "Readiness review count"
    Assert-Equal $audit.summary.session_candidates 6 "Session candidate count"
    Assert-Equal $audit.summary.session_carried 3 "Session carry count"
    Assert-Equal $audit.summary.session_review_required 3 "Session review count"
    Assert-Equal $audit.files.output_readiness_ledger.sha256 `
        (Get-FileSha256 $outputReadinessPath) "Readiness output audit hash"
    Assert-Equal $audit.files.output_session_lane_ledger.sha256 `
        (Get-FileSha256 $outputSessionPath) "Session output audit hash"

    $staleFunctionAudit = Get-RowByName $audit.readiness_rows $names[3] `
        "Stale function audit"
    Assert-True ($staleFunctionAudit.reasons -contains
        "candidate_function_sha256_changed") `
        "Stale function hash did not require review."
    Assert-True (-not [string]::IsNullOrWhiteSpace(
        $staleFunctionAudit.binding.previous_row_fingerprint_sha256)) `
        "Previous row fingerprint was not recorded."
    Assert-True (-not [string]::IsNullOrWhiteSpace(
        $staleFunctionAudit.binding.current_row_fingerprint_sha256)) `
        "Current row fingerprint was not recorded."
    Assert-True ((Get-RowByName $audit.readiness_rows $names[4] `
        "Changed reachability audit").reasons -contains
        "product_reachability_changed") `
        "Changed Product reachability did not require review."
    Assert-True ((Get-RowByName $audit.readiness_rows $names[5] `
        "Stale readiness evidence audit").reasons -contains
        "readiness_evidence_stale") `
        "Stale readiness evidence did not require review."
    Assert-True ((Get-RowByName $audit.readiness_rows $names[9] `
        "Changed mask audit").reasons -contains "mask_changed") `
        "Changed canonical mask shape did not require review."
    Assert-True ((Get-RowByName $audit.session_rows $names[6] `
        "Stale source audit").reasons -contains "session_source_stale") `
        "Stale session source did not require review."
    Assert-True ((Get-RowByName $audit.session_rows $names[7] `
        "Stale session evidence audit").reasons -contains
        "session_evidence_stale") `
        "Stale session evidence did not require review."
    Assert-True ((Get-RowByName $audit.session_rows $names[8] `
        "Active lane audit").reasons -contains
        "active_session_lane_not_transferable") `
        "An active session lane was transferred."

    # Parse decisions and audit provenance from one immutable input snapshot.
    # Observe the temporary-output window, mutate an input, and require the
    # pre-publication assertion to fail without leaving final artifacts.
    $toctouOutput = Join-Path $contractRoot "toctou-output"
    $toctouStdout = Join-Path $contractRoot "toctou.stdout.log"
    $toctouStderr = Join-Path $contractRoot "toctou.stderr.log"
    $currentDashboardBytes = [System.IO.File]::ReadAllBytes(
        $currentDashboardPath)
    $toctouArguments = @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $toolPath,
        "-PreviousDashboardPath", $previousDashboardPath,
        "-PreviousReadinessLedgerPath", $previousReadinessPath,
        "-PreviousSessionLaneLedgerPath", $previousSessionPath,
        "-CurrentDashboardPath", $currentDashboardPath,
        "-CurrentReadinessTemplatePath", $currentReadinessPath,
        "-CurrentSessionLaneTemplatePath", $currentSessionPath,
        "-OutputDirectory", $toctouOutput,
        "-BeforePublishDelayMilliseconds", "2000")
    $toctouProcess = Start-Process -FilePath $shellPath `
        -ArgumentList $toctouArguments -PassThru -WindowStyle Hidden `
        -RedirectStandardOutput $toctouStdout `
        -RedirectStandardError $toctouStderr
    try {
        $deadline = [DateTime]::UtcNow.AddSeconds(15)
        $stagingPattern = ".{0}.staging-*" -f (
            Split-Path -Leaf $toctouOutput)
        $stagingParent = Split-Path -Parent $toctouOutput
        $stagingDirectories = @()
        while ([DateTime]::UtcNow -lt $deadline -and
            -not $toctouProcess.HasExited) {
            $stagingDirectories = @(Get-ChildItem -LiteralPath $stagingParent `
                -Filter $stagingPattern -Directory -ErrorAction SilentlyContinue)
            if ($stagingDirectories.Count -gt 0 -and
                @(Get-ChildItem -LiteralPath $stagingDirectories[0].FullName `
                    -File -ErrorAction SilentlyContinue).Count -eq 4) {
                break
            }
            Start-Sleep -Milliseconds 50
        }
        Assert-True ($stagingDirectories.Count -eq 1) `
            "TOCTOU contract did not observe the pre-publication window."
        [System.IO.File]::AppendAllText($currentDashboardPath, "`n")
        $toctouProcess.WaitForExit()
        $toctouText = @(
            if (Test-Path -LiteralPath $toctouStdout) {
                Get-Content -LiteralPath $toctouStdout
            }
            if (Test-Path -LiteralPath $toctouStderr) {
                Get-Content -LiteralPath $toctouStderr
            }) -join "`n"
        Assert-True ($toctouProcess.ExitCode -ne 0 -and
            $toctouText -match
                "Current dashboard changed during carry-forward execution") `
            "Input drift did not fail at the pre-publication boundary."
        foreach ($name in @(
                "readiness-ledger.json", "session-lane-ledger.json",
                "carry-forward-audit.json", "carry-forward-audit.md")) {
            Assert-True (-not (Test-Path -LiteralPath (
                    Join-Path $toctouOutput $name) -PathType Leaf)) `
                "Input drift published stale carry-forward artifact '$name'."
        }
        Assert-True (@(Get-ChildItem -LiteralPath $stagingParent `
                -Filter $stagingPattern -Directory `
                -ErrorAction SilentlyContinue).Count -eq 0) `
            "Input drift left an atomic staging directory behind."
    } finally {
        if (-not $toctouProcess.HasExited) {
            $toctouProcess.Kill()
            $toctouProcess.WaitForExit()
        }
        $toctouProcess.Dispose()
        [System.IO.File]::WriteAllBytes(
            $currentDashboardPath, $currentDashboardBytes)
    }

    # A destination that races into existence after staging must remain wholly
    # untouched. Directory.Move may only publish into a nonexistent path.
    $collisionOutput = Join-Path $contractRoot "collision-output"
    $collisionStdout = Join-Path $contractRoot "collision.stdout.log"
    $collisionStderr = Join-Path $contractRoot "collision.stderr.log"
    $collisionArguments = @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $toolPath,
        "-PreviousDashboardPath", $previousDashboardPath,
        "-PreviousReadinessLedgerPath", $previousReadinessPath,
        "-PreviousSessionLaneLedgerPath", $previousSessionPath,
        "-CurrentDashboardPath", $currentDashboardPath,
        "-CurrentReadinessTemplatePath", $currentReadinessPath,
        "-CurrentSessionLaneTemplatePath", $currentSessionPath,
        "-OutputDirectory", $collisionOutput,
        "-BeforePublishDelayMilliseconds", "2000")
    $collisionProcess = Start-Process -FilePath $shellPath `
        -ArgumentList $collisionArguments -PassThru -WindowStyle Hidden `
        -RedirectStandardOutput $collisionStdout `
        -RedirectStandardError $collisionStderr
    try {
        $collisionDeadline = [DateTime]::UtcNow.AddSeconds(15)
        $collisionStagingPattern = ".{0}.staging-*" -f (
            Split-Path -Leaf $collisionOutput)
        $collisionParent = Split-Path -Parent $collisionOutput
        $collisionStagingDirectories = @()
        while ([DateTime]::UtcNow -lt $collisionDeadline -and
            -not $collisionProcess.HasExited) {
            $collisionStagingDirectories = @(Get-ChildItem `
                -LiteralPath $collisionParent -Filter $collisionStagingPattern `
                -Directory -ErrorAction SilentlyContinue)
            if ($collisionStagingDirectories.Count -gt 0 -and
                @(Get-ChildItem `
                    -LiteralPath $collisionStagingDirectories[0].FullName `
                    -File -ErrorAction SilentlyContinue).Count -eq 4) {
                break
            }
            Start-Sleep -Milliseconds 50
        }
        Assert-True ($collisionStagingDirectories.Count -eq 1) `
            "Collision contract did not observe the pre-publication window."

        [void][System.IO.Directory]::CreateDirectory($collisionOutput)
        $collisionSentinel = Join-Path $collisionOutput "owner-sentinel.txt"
        Write-Utf8 $collisionSentinel "preexisting owner content`n"
        $collisionProcess.WaitForExit()
        $collisionText = @(
            if (Test-Path -LiteralPath $collisionStdout) {
                Get-Content -LiteralPath $collisionStdout
            }
            if (Test-Path -LiteralPath $collisionStderr) {
                Get-Content -LiteralPath $collisionStderr
            }) -join "`n"
        Assert-True ($collisionProcess.ExitCode -ne 0 -and
            $collisionText -match
                "OutputDirectory appeared before atomic publication") `
            "A raced destination did not fail the atomic publication boundary."
        Assert-Equal ([System.IO.File]::ReadAllText($collisionSentinel)) `
            "preexisting owner content`n" `
            "Raced destination sentinel content"
        foreach ($name in @(
                "readiness-ledger.json", "session-lane-ledger.json",
                "carry-forward-audit.json", "carry-forward-audit.md")) {
            Assert-True (-not (Test-Path -LiteralPath (
                    Join-Path $collisionOutput $name) -PathType Leaf)) `
                "Atomic publication overwrote raced destination file '$name'."
        }
        Assert-True (@(Get-ChildItem -LiteralPath $collisionParent `
                -Filter $collisionStagingPattern -Directory `
                -ErrorAction SilentlyContinue).Count -eq 0) `
            "Collision failure left an atomic staging directory behind."
    } finally {
        if (-not $collisionProcess.HasExited) {
            $collisionProcess.Kill()
            $collisionProcess.WaitForExit()
        }
        $collisionProcess.Dispose()
    }

    [void](Invoke-CarryCase "existing-output" $outputRoot 1 `
        "OutputDirectory must not already exist")

    $retiredForceOutput = Join-Path $contractRoot "retired-force-output"
    [void](Invoke-CarryCase "retired-force" $retiredForceOutput 1 `
        "-Force is retired for carry-forward publication" -CaseForce)
    Assert-True (-not (Test-Path -LiteralPath $retiredForceOutput)) `
        "Retired -Force invocation created an output directory."

    $mismatchedSessionPath = Join-Path $currentRoot `
        "session-lane-ledger.mismatched.template.json"
    $mismatchedInputs = New-CheckpointInputs "current" $currentCandidateFileSha
    $mismatchedInputs.candidate_map_sha256 = Get-TextSha256 "wrong-map"
    Write-Json $mismatchedSessionPath (
        New-SessionTemplate $mismatchedInputs "current-contract-session")
    [void](Invoke-CarryCase "mismatched-inputs" `
        (Join-Path $contractRoot "mismatched-output") 1 `
        "Current recovery templates input 'candidate_map_sha256' does not match" `
        -CaseCurrentSession $mismatchedSessionPath)

    [void](Invoke-CarryCase "unsafe-output-root" $unsafeOutput 1 `
        "OutputDirectory must be under the ignored a/ or artifacts/ tree")
    Assert-True (-not (Test-Path -LiteralPath $unsafeOutput)) `
        "Unsafe output directory was created."

    [void](Invoke-CarryCase "input-output-overlap" $previousRoot 1 `
        "An output path would overwrite an input")

    Write-Host "Recovery-ledger carry-forward contract passed."
    Write-Host "  Stable readiness decisions carried: 3"
    Write-Host "  Stale readiness decisions rejected:  4"
    Write-Host "  Stable session lanes carried:        3"
    Write-Host "  Stale/active session lanes rejected: 3"
    Write-Host "  No original binaries, assets, or VC4 invocation required."
} finally {
    if (Test-Path -LiteralPath $contractRoot) {
        $resolvedContract = (Resolve-Path -LiteralPath $contractRoot).Path
        $expectedPrefix = (Join-Path $repoRoot "a").TrimEnd('\', '/') + '\'
        if (-not $resolvedContract.StartsWith(
                $expectedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing unsafe contract cleanup: '$resolvedContract'."
        }
        Remove-Item -LiteralPath $resolvedContract -Recurse -Force
    }
    if (Test-Path -LiteralPath $unsafeOutput) {
        throw "Unsafe contract output escaped cleanup policy: '$unsafeOutput'."
    }
}
