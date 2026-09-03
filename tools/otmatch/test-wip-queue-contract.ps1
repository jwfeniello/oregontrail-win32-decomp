[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$scannerPath = (Resolve-Path (Join-Path $PSScriptRoot "scan-wip-residuals.ps1")).Path
$contractId = [guid]::NewGuid().ToString("N")
$workPath = Join-Path ([System.IO.Path]::GetTempPath()) (
    "otmatch-wip-queue-contract-" + $contractId)
$outputRoot = Join-Path $repoRoot (Join-Path "a" ("otmatch-wip-queue-contract-" + $contractId))
$unsafeOutput = Join-Path $repoRoot (
    "docs\otmatch-wip-queue-contract-unsafe-" + $contractId)
$junctionPath = ""
[void][System.IO.Directory]::CreateDirectory($workPath)

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

function New-TestPe([string]$Path, [hashtable]$Payloads) {
    $bytes = New-Object byte[] 0x600
    $bytes[0] = 0x4d
    $bytes[1] = 0x5a
    Set-U32 $bytes 0x3c 0x80

    $bytes[0x80] = 0x50
    $bytes[0x81] = 0x45
    Set-U16 $bytes 0x84 0x014c
    Set-U16 $bytes 0x86 1
    Set-U16 $bytes 0x94 0x00e0

    $optionalHeader = 0x98
    Set-U16 $bytes $optionalHeader 0x010b
    Set-U32 $bytes ($optionalHeader + 28) 0x00400000

    $section = $optionalHeader + 0xe0
    $sectionName = [System.Text.Encoding]::ASCII.GetBytes(".text")
    [System.Array]::Copy($sectionName, 0, $bytes, $section, $sectionName.Length)
    Set-U32 $bytes ($section + 8) 0x00000400
    Set-U32 $bytes ($section + 12) 0x00001000
    Set-U32 $bytes ($section + 16) 0x00000400
    Set-U32 $bytes ($section + 20) 0x00000200

    foreach ($entry in $Payloads.GetEnumerator()) {
        $rva = [uint32]$entry.Key
        $payload = [byte[]]$entry.Value
        $rawOffset = 0x200 + [int]($rva - 0x1000)
        [System.Array]::Copy($payload, 0, $bytes, $rawOffset, $payload.Length)
    }

    [System.IO.File]::WriteAllBytes($Path, $bytes)
}

function Assert-Equal($Actual, $Expected, [string]$Context) {
    if ([string]$Actual -cne [string]$Expected) {
        throw "$Context expected '$Expected', got '$Actual'."
    }
}

function Assert-True([bool]$Condition, [string]$Context) {
    if (-not $Condition) {
        throw "$Context"
    }
}

function Get-FileSha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-ByteArraySha256([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return [System.BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace(
            "-", "").ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Get-TextSha256([string[]]$Lines) {
    $text = ($Lines -join "`n") + "`n"
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return [System.BitConverter]::ToString(
            $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($text))).Replace(
                "-", "").ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Invoke-ScannerCase(
    [string]$Name,
    [string]$CaseManifestPath,
    [string]$CaseMetricsPath,
    [string]$CaseOutputPath,
    [int]$ExpectedExitCode,
    [string]$ExpectedOutput,
    [string]$CaseCandidatePath = "",
    [string]$CaseVerifierPath = "",
    [string]$CaseProgressSummaryPath = "",
    [string]$CaseFrozenPath = "",
    [string]$CaseSessionLaneLedgerPath = "",
    [string]$CaseReadinessLedgerPath = "",
    [switch]$CaseRequireExplicitReadiness,
    [switch]$CaseAllowIncompleteAssignments,
    [int]$CasePortfolioTargetInstructions = 0,
    [switch]$CaseAllowPortfolioShortfall,
    [double]$CaseCheckpointStepPercent = 5.0,
    [double]$CasePortfolioMultiplier = 1.5,
    [switch]$CaseAllowNonstandardPortfolioPolicy) {

    if ([string]::IsNullOrWhiteSpace($CaseVerifierPath)) {
        $CaseVerifierPath = $verifierPath
    }
    if ([string]::IsNullOrWhiteSpace($CaseCandidatePath)) {
        $CaseCandidatePath = $candidatePath
    }
    if ([string]::IsNullOrWhiteSpace($CaseFrozenPath)) {
        $CaseFrozenPath = $frozenPath
    }
    if ([string]::IsNullOrWhiteSpace($CaseProgressSummaryPath)) {
        $CaseProgressSummaryPath = $progressSummaryPath
    }

    $scannerParameters = [ordered]@{
        ManifestPath = $CaseManifestPath
        OriginalPath = $originalPath
        OriginalDllPath = $originalPath
        CandidatePath = $CaseCandidatePath
        CandidateMapPath = $mapPath
        OutputDirectory = $CaseOutputPath
        FunctionMetricsPath = [string[]]@($CaseMetricsPath)
        VerifierResultsPath = $CaseVerifierPath
        ProgressMetricsSummaryPath = $CaseProgressSummaryPath
        ExeProductSourceManifestPath = $productSourcesPath
        FrozenWipPath = $CaseFrozenPath
        CheckpointStepPercent = $CaseCheckpointStepPercent
        PortfolioMultiplier = $CasePortfolioMultiplier
        Top = 10
    }
    if ($CasePortfolioTargetInstructions -gt 0) {
        $scannerParameters["PortfolioTargetInstructions"] = `
            $CasePortfolioTargetInstructions
    }
    if ($CaseAllowPortfolioShortfall) {
        $scannerParameters["AllowPortfolioShortfall"] = $true
    }
    if (-not [string]::IsNullOrWhiteSpace($CaseSessionLaneLedgerPath)) {
        $scannerParameters["SessionLaneLedgerPath"] = $CaseSessionLaneLedgerPath
    }
    if (-not [string]::IsNullOrWhiteSpace($CaseReadinessLedgerPath)) {
        $scannerParameters["ReadinessLedgerPath"] = $CaseReadinessLedgerPath
    } elseif (-not $CaseRequireExplicitReadiness) {
        # Every legacy scenario opts into the old heuristic deliberately. The
        # main contract below supplies an explicit readiness ledger.
        $scannerParameters["AllowHeuristicReadiness"] = $true
    }
    if ($CaseAllowIncompleteAssignments) {
        $scannerParameters["AllowIncompleteAssignments"] = $true
    }
    if ($CaseAllowNonstandardPortfolioPolicy) {
        $scannerParameters["AllowNonstandardPortfolioPolicy"] = $true
    }

    # A fresh in-process runspace preserves case isolation without paying for
    # a new powershell.exe process on every negative contract scenario.
    $runner = [powershell]::Create()
    try {
        [void]$runner.AddCommand("Set-Location")
        [void]$runner.AddParameter("LiteralPath", $repoRoot)
        [void]$runner.AddStatement()
        [void]$runner.AddCommand($scannerPath)
        foreach ($parameterName in $scannerParameters.Keys) {
            [void]$runner.AddParameter(
                $parameterName, $scannerParameters[$parameterName])
        }

        $output = @($runner.Invoke())
        $exitCode = if ($runner.HadErrors) { 1 } else { 0 }
        $outputFragments = New-Object System.Collections.Generic.List[string]
        foreach ($informationRecord in @($runner.Streams.Information)) {
            $outputFragments.Add([string]$informationRecord.MessageData)
        }
        foreach ($warningRecord in @($runner.Streams.Warning)) {
            $outputFragments.Add([string]$warningRecord.Message)
        }
        foreach ($errorRecord in @($runner.Streams.Error)) {
            $outputFragments.Add([string]$errorRecord.Exception.Message)
            $outputFragments.Add([string]$errorRecord)
        }
        foreach ($outputRecord in $output) {
            if ($null -ne $outputRecord -and
                $outputRecord -is [string]) {
                $outputFragments.Add([string]$outputRecord)
            }
        }
    }
    finally {
        $runner.Dispose()
    }

    $outputText = $outputFragments -join [Environment]::NewLine
    if ($exitCode -ne $ExpectedExitCode) {
        throw ("{0}: expected exit {1}, got {2}. Output: {3}" -f
            $Name, $ExpectedExitCode, $exitCode, $outputText)
    }
    if ($outputText -notmatch [regex]::Escape($ExpectedOutput)) {
        throw ("{0}: output did not contain '{1}'. Output: {2}" -f
            $Name, $ExpectedOutput, $outputText)
    }

    Write-Host ("PASS {0}: exit={1}" -f $Name, $exitCode)
}

try {
    $originalPath = Join-Path $workPath "original.exe"
    $candidatePath = Join-Path $workPath "candidate.exe"
    $mapPath = Join-Path $workPath "candidate.map"
    $candidateObjectName = "src_otwin_app_general_helpers.obj"
    $candidateObjectPath = Join-Path $workPath $candidateObjectName
    $manifestPath = Join-Path $workPath "manifest.csv"
    $metricsPath = Join-Path $workPath "metrics.csv"
    $verifierPath = Join-Path $workPath "verifier.csv"
    $maskAuditPath = Join-Path $workPath "mask-audit.csv"
    $progressSummaryPath = Join-Path $workPath "progress-metrics-summary.json"
    $productSourcesPath = Join-Path $workPath "product-sources.txt"
    $frozenPath = Join-Path $workPath "frozen.csv"
    $frozenEvidencePath = Join-Path $workPath "frozen-evidence.md"
    $frozenSourcePath = Join-Path $workPath "frozen-source.cpp"
    $sessionLaneLedgerPath = Join-Path $workPath "session-lanes.json"
    $sessionEvidencePath = Join-Path $workPath "session-evidence.md"
    $sessionSourcePath = Join-Path $workPath "session-source.cpp"
    $readinessLedgerPath = Join-Path $workPath "readiness.json"
    $readinessEvidencePath = Join-Path $workPath "readiness-evidence.md"
    $outputPath = Join-Path $outputRoot "output"

    New-TestPe $originalPath @{
        0x1000 = [byte[]](10, 20, 30, 40)
        0x1010 = [byte[]](1, 2, 3, 4)
        0x1020 = [byte[]](5, 6, 7, 8)
        0x1030 = [byte[]](9, 10, 11, 12)
        0x1040 = [byte[]](1, 1, 1, 1)
        0x1050 = [byte[]](7, 7, 7, 7)
    }
    New-TestPe $candidatePath @{
        0x1000 = [byte[]](11, 99, 30, 40)
        0x1010 = [byte[]](1, 9, 8, 4)
        0x1020 = [byte[]](5, 6, 7, 9)
        0x1030 = [byte[]](9, 10, 11, 12)
        0x1040 = [byte[]](2, 2, 2, 2)
        0x1050 = [byte[]](7, 7, 8, 7)
    }
    [System.IO.File]::WriteAllText($mapPath, " Preferred load address is 00400000")
    [System.IO.File]::WriteAllBytes(
        $candidateObjectPath,
        [byte[]](0x4c, 0x01, 0x00, 0x00, 0x2e, 0x74, 0x65, 0x78, 0x74))

    $manifest = @(
        [pscustomobject][ordered]@{
            name = "OtHighYieldTiny"
            program = "Oregon32.exe"
            original_va = ""
            original_rva = "0x00001000"
            size = "0x00000008"
            candidate_va = ""
            candidate_rva = "0x00001000"
            candidate_symbol = ""
            candidate_dll = ""
            candidate_object = "src_otwin_app_general_helpers.obj"
            expected_status = "wip"
            implementation_kind = "cpp"
            mask = "1"
            notes = "A tiny normalized residual with high instruction yield."
        }
        [pscustomobject][ordered]@{
            name = "OtMediumNear"
            program = "Oregon32.exe"
            original_va = ""
            original_rva = "0x00001010"
            size = "0x00000008"
            candidate_va = ""
            candidate_rva = "0x00001010"
            candidate_symbol = ""
            candidate_dll = ""
            candidate_object = "src_otwin_app_general_helpers.obj"
            expected_status = "wip"
            implementation_kind = "cpp"
            mask = "2"
            notes = "A second portfolio target."
        }
        [pscustomobject][ordered]@{
            name = "OtFrozenResidual"
            program = "Oregon32.exe"
            original_va = ""
            original_rva = "0x00001020"
            size = "0x00000004"
            candidate_va = ""
            candidate_rva = "0x00001020"
            candidate_symbol = ""
            candidate_dll = ""
            candidate_object = "src_otwin_app_general_helpers.obj"
            expected_status = "wip"
            implementation_kind = "cpp"
            mask = ""
            notes = "A bound strict residual must not enter the portfolio."
        }
        [pscustomobject][ordered]@{
            name = "OtAcceptedBaseline"
            program = "Oregon32.exe"
            original_va = ""
            original_rva = "0x00001030"
            size = "0x00000004"
            candidate_va = ""
            candidate_rva = "0x00001030"
            candidate_symbol = ""
            candidate_dll = ""
            candidate_object = "src_otwin_app_general_helpers.obj"
            expected_status = "match"
            implementation_kind = "cpp"
            mask = ""
            notes = "WIP semantic conversion wording must not select a match row."
        }
        [pscustomobject][ordered]@{
            name = "OtBroadFallback"
            program = "Oregon32.exe"
            original_va = ""
            original_rva = "0x00001040"
            size = "0x00000004"
            candidate_va = ""
            candidate_rva = ""
            candidate_symbol = ""
            candidate_dll = ""
            candidate_object = ""
            expected_status = "wip"
            implementation_kind = "cpp"
            mask = ""
            notes = "A lower-confidence fallback."
        }
        [pscustomobject][ordered]@{
            name = "OtSessionPaused"
            program = "Oregon32.exe"
            original_va = ""
            original_rva = "0x00001050"
            size = "0x00000004"
            candidate_va = ""
            candidate_rva = "0x00001050"
            candidate_symbol = ""
            candidate_dll = ""
            candidate_object = "src_otwin_app_general_helpers.obj"
            expected_status = "wip"
            implementation_kind = "cpp"
            mask = ""
            notes = "A viable row paused only for this recovery session."
        }
    )
    $manifest | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8

    @(
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"; name = "FUN_00401000"
            original_va = "0x00401000"; original_rva = "0x00001000"
            size = "0x8"; instruction_count = "60"; body_bytes = "4"
            body_ranges = "0x00001000-0x00001002;0x00001006-0x00001008"
            block = ".text"; notes = ""
        }
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"; name = "FUN_00401010"
            original_va = "0x00401010"; original_rva = "0x00001010"
            size = "0x8"; instruction_count = "40"; body_bytes = "4"
            body_ranges = "0x00001010-0x00001014"
            block = ".text"; notes = ""
        }
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"; name = "FUN_00401020"
            original_va = "0x00401020"; original_rva = "0x00001020"
            size = "0x4"; instruction_count = "220"; body_bytes = "4"
            body_ranges = "0x00001020-0x00001024"
            block = ".text"; notes = ""
        }
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"; name = "FUN_00401030"
            original_va = "0x00401030"; original_rva = "0x00001030"
            size = "0x4"; instruction_count = "500"; body_bytes = "4"
            body_ranges = "0x00001030-0x00001034"
            block = ".text"; notes = ""
        }
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"; name = "FUN_00401040"
            original_va = "0x00401040"; original_rva = "0x00001040"
            size = "0x4"; instruction_count = "100"; body_bytes = "4"
            body_ranges = "0x00001040-0x00001044"
            block = ".text"; notes = ""
        }
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"; name = "FUN_00401050"
            original_va = "0x00401050"; original_rva = "0x00001050"
            size = "0x4"; instruction_count = "80"; body_bytes = "4"
            body_ranges = "0x00001050-0x00001054"
            block = ".text"; notes = ""
        }
    ) | Export-Csv -LiteralPath $metricsPath -NoTypeInformation -Encoding UTF8

    [System.IO.File]::WriteAllLines(
        $productSourcesPath,
        [string[]]@("src/otwin/app/general_helpers.cpp"))

    [System.IO.File]::WriteAllText(
        $frozenEvidencePath,
        "Eight meaningful synthetic variants reached the same strict residual.`n")
    [System.IO.File]::WriteAllText(
        $frozenSourcePath,
        "int OtFrozenResidual() { return 1; }`n")
    [System.IO.File]::WriteAllText(
        $sessionEvidencePath,
        "Four meaningful variants recorded before this session pause.`n")
    [System.IO.File]::WriteAllText(
        $sessionSourcePath,
        "int OtSessionPaused() { return 8; }`n")
    [System.IO.File]::WriteAllText(
        $readinessEvidencePath,
        "Synthetic implementation and dependency readiness review.`n")

    $manifestSha = Get-FileSha256 $manifestPath
    $originalSha = Get-FileSha256 $originalPath
    $candidateSha = Get-FileSha256 $candidatePath
    $candidateObjectSha = Get-FileSha256 $candidateObjectPath
    $mapSha = Get-FileSha256 $mapPath
    $frozenEvidenceSha = Get-FileSha256 $frozenEvidencePath
    $frozenSourceSha = Get-FileSha256 $frozenSourcePath
    $sessionEvidenceSha = Get-FileSha256 $sessionEvidencePath
    $sessionSourceSha = Get-FileSha256 $sessionSourcePath
    $readinessEvidenceSha = Get-FileSha256 $readinessEvidencePath
    $candidateFunctionHashes = @{
        "OtHighYieldTiny" = Get-ByteArraySha256 (
            [byte[]](11, 0, 30, 40, 0, 0, 0, 0))
        "OtMediumNear" = Get-ByteArraySha256 (
            [byte[]](1, 9, 0, 4, 0, 0, 0, 0))
        "OtFrozenResidual" = Get-ByteArraySha256 ([byte[]](5, 6, 7, 9))
        "OtAcceptedBaseline" = Get-ByteArraySha256 ([byte[]](9, 10, 11, 12))
        "OtBroadFallback" = Get-ByteArraySha256 ([byte[]](2, 2, 2, 2))
        "OtSessionPaused" = Get-ByteArraySha256 ([byte[]](7, 7, 8, 7))
    }

    @(
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"; original_rva = "0x00001000"
            name = "OtHighYieldTiny"; frozen = "false"
            freeze_date = ""
            confidence = "0.90"; effort = "1"
            evidence_path = ""; evidence_sha256 = ""
            source_path = ""; source_sha256 = ""
            meaningful_variant_count = ""; residual_kind = ""
            hard_diff_count = ""; compared_bytes = ""
            baseline_original_sha256 = ""; baseline_candidate_sha256 = ""
            baseline_candidate_object = ""
            baseline_candidate_object_sha256 = ""
            baseline_candidate_function_sha256 = ""
            diagnostic_note = ""
            reason = ""; revisit_condition = ""
        }
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"; original_rva = "0x00001010"
            name = "OtMediumNear"; frozen = "false"
            freeze_date = ""
            confidence = "0.80"; effort = "1"
            evidence_path = ""; evidence_sha256 = ""
            source_path = ""; source_sha256 = ""
            meaningful_variant_count = ""; residual_kind = ""
            hard_diff_count = ""; compared_bytes = ""
            baseline_original_sha256 = ""; baseline_candidate_sha256 = ""
            baseline_candidate_object = ""
            baseline_candidate_object_sha256 = ""
            baseline_candidate_function_sha256 = ""
            diagnostic_note = ""
            reason = ""; revisit_condition = ""
        }
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"; original_rva = "0x00001020"
            name = "OtFrozenResidual"; frozen = "true"
            freeze_date = "2026-07-16"
            confidence = "0.99"; effort = "1"
            evidence_path = $frozenEvidencePath
            evidence_sha256 = $frozenEvidenceSha
            source_path = $frozenSourcePath
            source_sha256 = $frozenSourceSha
            meaningful_variant_count = "8"
            residual_kind = "strict-linked"
            hard_diff_count = "1"; compared_bytes = "4"
            baseline_original_sha256 = $originalSha
            baseline_candidate_sha256 = $candidateSha
            baseline_candidate_object = $candidateObjectName
            baseline_candidate_object_sha256 = $candidateObjectSha
            baseline_candidate_function_sha256 = $candidateFunctionHashes["OtFrozenResidual"]
            diagnostic_note = "Bound synthetic strict-linked residual."
            reason = "Synthetic allocator plateau."
            revisit_condition = "New type evidence."
        }
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"; original_rva = "0x00001040"
            name = "OtBroadFallback"; frozen = "false"
            freeze_date = ""
            confidence = "0.10"; effort = "5"
            evidence_path = ""; evidence_sha256 = ""
            source_path = ""; source_sha256 = ""
            meaningful_variant_count = ""; residual_kind = ""
            hard_diff_count = ""; compared_bytes = ""
            baseline_original_sha256 = ""; baseline_candidate_sha256 = ""
            baseline_candidate_object = ""
            baseline_candidate_object_sha256 = ""
            baseline_candidate_function_sha256 = ""
            diagnostic_note = ""
            reason = ""; revisit_condition = ""
        }
    ) | Export-Csv -LiteralPath $frozenPath -NoTypeInformation -Encoding UTF8

    $verifierRows = @(
        [pscustomobject][ordered]@{
            result_schema_version = "4"; manifest_sha256 = $manifestSha
            name = "OtHighYieldTiny"; program = "Oregon32.exe"
            original_rva = "0x00001000"; expected_status = "wip"
            actual_status = "mismatch"; status = "mismatch"
            verification_status = "allowed_wip"; promotion_ready = "False"
            candidate_object = "src_otwin_app_general_helpers.obj"
            first_diff = "0x00000000"; error_message = ""
            masked_import_identity_error = ""; raw_match = "False"
        }
        [pscustomobject][ordered]@{
            result_schema_version = "4"; manifest_sha256 = $manifestSha
            name = "OtMediumNear"; program = "Oregon32.exe"
            original_rva = "0x00001010"; expected_status = "wip"
            actual_status = "mismatch"; status = "mismatch"
            verification_status = "allowed_wip"; promotion_ready = "False"
            candidate_object = "src_otwin_app_general_helpers.obj"
            first_diff = "0x00000001"; error_message = ""
            masked_import_identity_error = ""; raw_match = "False"
        }
        [pscustomobject][ordered]@{
            result_schema_version = "4"; manifest_sha256 = $manifestSha
            name = "OtFrozenResidual"; program = "Oregon32.exe"
            original_rva = "0x00001020"; expected_status = "wip"
            actual_status = "mismatch"; status = "mismatch"
            verification_status = "allowed_wip"; promotion_ready = "False"
            candidate_object = "src_otwin_app_general_helpers.obj"
            first_diff = "0x00000003"; error_message = ""
            masked_import_identity_error = ""; raw_match = "False"
        }
        [pscustomobject][ordered]@{
            result_schema_version = "4"; manifest_sha256 = $manifestSha
            name = "OtAcceptedBaseline"; program = "Oregon32.exe"
            original_rva = "0x00001030"; expected_status = "match"
            actual_status = "match"; status = "match"
            verification_status = "pass"; promotion_ready = "False"
            candidate_object = "src_otwin_app_general_helpers.obj"
            first_diff = ""; error_message = ""
            masked_import_identity_error = ""; raw_match = "True"
        }
        [pscustomobject][ordered]@{
            result_schema_version = "4"; manifest_sha256 = $manifestSha
            name = "OtBroadFallback"; program = "Oregon32.exe"
            original_rva = "0x00001040"; expected_status = "wip"
            actual_status = "mismatch"; status = "mismatch"
            verification_status = "allowed_wip"; promotion_ready = "False"
            candidate_object = ""; first_diff = "0x00000000"
            error_message = ""; masked_import_identity_error = ""
            raw_match = "False"
        }
        [pscustomobject][ordered]@{
            result_schema_version = "4"; manifest_sha256 = $manifestSha
            name = "OtSessionPaused"; program = "Oregon32.exe"
            original_rva = "0x00001050"; expected_status = "wip"
            actual_status = "mismatch"; status = "mismatch"
            verification_status = "allowed_wip"; promotion_ready = "False"
            candidate_object = "src_otwin_app_general_helpers.obj"
            first_diff = "0x00000002"; error_message = ""
            masked_import_identity_error = ""; raw_match = "False"
        }
    )
    foreach ($verifierRow in $verifierRows) {
        $matchingManifestRow = $manifest | Where-Object {
            $_.name -ceq $verifierRow.name
        } | Select-Object -First 1
        $verifierRow | Add-Member -NotePropertyName manifest_path -NotePropertyValue $manifestPath
        $verifierRow | Add-Member -NotePropertyName original_path -NotePropertyValue $originalPath
        $verifierRow | Add-Member -NotePropertyName original_file_sha256 -NotePropertyValue $originalSha
        $verifierRow | Add-Member -NotePropertyName candidate_path -NotePropertyValue $candidatePath
        $verifierRow | Add-Member -NotePropertyName candidate_file_sha256 -NotePropertyValue $candidateSha
        $verifierRow | Add-Member -NotePropertyName candidate_map_path -NotePropertyValue $mapPath
        $verifierRow | Add-Member -NotePropertyName candidate_map_sha256 -NotePropertyValue $mapSha
        $verifierRow | Add-Member -NotePropertyName candidate_symbol `
            -NotePropertyValue ([string]$matchingManifestRow.candidate_symbol)
        $verifierRow | Add-Member -NotePropertyName candidate_object_qualifier `
            -NotePropertyValue ([string]$matchingManifestRow.candidate_object)
        $resolvedCandidateRva = if ([string]::IsNullOrWhiteSpace(
                [string]$matchingManifestRow.candidate_rva)) {
            [string]$matchingManifestRow.original_rva
        } else {
            [string]$matchingManifestRow.candidate_rva
        }
        $verifierRow | Add-Member -NotePropertyName candidate_rva `
            -NotePropertyValue $resolvedCandidateRva
        $verifierRow | Add-Member -NotePropertyName candidate_sha256 `
            -NotePropertyValue $candidateFunctionHashes[$verifierRow.name]
        $verifierRow | Add-Member -NotePropertyName mask_shape_valid `
            -NotePropertyValue "True"
        $verifierRow | Add-Member -NotePropertyName masked_operand_shape_error `
            -NotePropertyValue ""
    }
    $verifierRows | Export-Csv -LiteralPath $verifierPath -NoTypeInformation -Encoding UTF8

    [System.IO.File]::WriteAllText($maskAuditPath, "synthetic mask audit evidence`n")
    $manifestIdentities = [string[]]@(
        "oregon32.exe|0x1000",
        "oregon32.exe|0x1010",
        "oregon32.exe|0x1020",
        "oregon32.exe|0x1030",
        "oregon32.exe|0x1040",
        "oregon32.exe|0x1050")
    $denominatorLines = [string[]]@(
        "oregon32.exe|0x1000|instructions=60|body_bytes=4|size=8",
        "oregon32.exe|0x1010|instructions=40|body_bytes=4|size=8",
        "oregon32.exe|0x1020|instructions=220|body_bytes=4|size=4",
        "oregon32.exe|0x1030|instructions=500|body_bytes=4|size=4",
        "oregon32.exe|0x1040|instructions=100|body_bytes=4|size=4",
        "oregon32.exe|0x1050|instructions=80|body_bytes=4|size=4")
    $bodyOwnershipLines = [string[]]@(
        "oregon32.exe|0x1000|body_ranges=0x00001000-0x00001002;0x00001006-0x00001008",
        "oregon32.exe|0x1010|body_ranges=0x00001010-0x00001014",
        "oregon32.exe|0x1020|body_ranges=0x00001020-0x00001024",
        "oregon32.exe|0x1030|body_ranges=0x00001030-0x00001034",
        "oregon32.exe|0x1040|body_ranges=0x00001040-0x00001044",
        "oregon32.exe|0x1050|body_ranges=0x00001050-0x00001054")
    $acceptedIdentities = [string[]]@("oregon32.exe|0x1030")
    $metricsReporterPath = Join-Path (Split-Path -Parent $scannerPath) `
        "report-progress-metrics.ps1"
    $progressSummary = [pscustomobject][ordered]@{
        schema_version = 2
        generated_utc = [DateTime]::UtcNow.ToString("o")
        policy = [pscustomobject][ordered]@{
            include_non_text = $false
            require_product_reachability = $true
            required_instruction_percent = 0
        }
        inputs = [pscustomobject][ordered]@{
            manifest = [pscustomobject][ordered]@{
                path = $manifestPath
                sha256 = Get-FileSha256 $manifestPath
                identity_universe_sha256 = Get-TextSha256 $manifestIdentities
                identity_count = 6
            }
            verifier_results = [pscustomobject][ordered]@{
                path = $verifierPath
                sha256 = Get-FileSha256 $verifierPath
            }
            mask_audit_results = [pscustomobject][ordered]@{
                path = $maskAuditPath
                sha256 = Get-FileSha256 $maskAuditPath
            }
            function_metrics = @([pscustomobject][ordered]@{
                path = $metricsPath
                sha256 = Get-FileSha256 $metricsPath
            })
            exe_product_sources = [pscustomobject][ordered]@{
                path = $productSourcesPath
                sha256 = Get-FileSha256 $productSourcesPath
            }
            metrics_reporter = [pscustomobject][ordered]@{
                path = $metricsReporterPath
                sha256 = Get-FileSha256 $metricsReporterPath
            }
        }
        denominator = [pscustomobject][ordered]@{
            identity_sha256 = Get-TextSha256 $denominatorLines
            function_count = 6
            instruction_count = 1000
            body_byte_count = 24
            body_ownership_sha256 = Get-TextSha256 $bodyOwnershipLines
            body_range_count = 7
        }
        strict = [pscustomobject][ordered]@{
            accepted_identity_sha256 = Get-TextSha256 $acceptedIdentities
            accepted_identity_count = 1
            accepted_identities = $acceptedIdentities
            accepted_instructions = 500
            accepted_body_bytes = 4
            instruction_percent = 50.0
        }
    }
    $progressSummary | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $progressSummaryPath -Encoding UTF8

    $checkpointInputs = [pscustomobject][ordered]@{
        manifest_sha256 = Get-FileSha256 $manifestPath
        verifier_results_sha256 = Get-FileSha256 $verifierPath
        progress_metrics_summary_sha256 = Get-FileSha256 $progressSummaryPath
        candidate_file_sha256 = Get-FileSha256 $candidatePath
        candidate_map_sha256 = Get-FileSha256 $mapPath
        original_exe_sha256 = Get-FileSha256 $originalPath
        original_dll_sha256 = Get-FileSha256 $originalPath
    }
    $sessionLedger = [pscustomobject][ordered]@{
        schema_version = 1
        session_id = "contract-session"
        inputs = $checkpointInputs
        rows = @([pscustomobject][ordered]@{
            program = "Oregon32.exe"
            original_rva = "0x00001050"
            name = "OtSessionPaused"
            state = "paused"
            hypothesis = "The remaining byte is controlled by local expression shape."
            started_utc = "2026-07-17T12:00:00Z"
            updated_utc = "2026-07-17T12:35:00Z"
            active_recovery_minutes = 35
            tool_time_ms = 14000
            meaningful_variant_count = 4
            evidence_path = $sessionEvidencePath
            evidence_sha256 = $sessionEvidenceSha
            source_path = $sessionSourcePath
            source_sha256 = $sessionSourceSha
            residual = [pscustomobject][ordered]@{
                kind = "strict-linked"
                hard_diff_count = 1
                compared_bytes = 4
                candidate_function_sha256 = `
                    $candidateFunctionHashes["OtSessionPaused"]
            }
        })
    }
    $sessionLedger | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $sessionLaneLedgerPath -Encoding UTF8

    $readinessRows = @(
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"; original_rva = "0x00001000"
            name = "OtHighYieldTiny"; readiness = "ready"
            dependency_state = "ready"
            reason = "Implementation exists and all dependencies are linked."
            evidence_path = $readinessEvidencePath
            evidence_sha256 = $readinessEvidenceSha
            confidence = 0.90; effort = 1
            candidate_body_bytes = 4; candidate_instruction_count = 60
        }
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"; original_rva = "0x00001010"
            name = "OtMediumNear"; readiness = "ready"
            dependency_state = "ready"
            reason = "Implementation exists and all dependencies are linked."
            evidence_path = $readinessEvidencePath
            evidence_sha256 = $readinessEvidenceSha
            confidence = 0.80; effort = 1
            candidate_body_bytes = 4; candidate_instruction_count = 40
        }
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"; original_rva = "0x00001020"
            name = "OtFrozenResidual"; readiness = "blocked"
            dependency_state = "blocked"
            reason = "Durable stop-loss evidence blocks recovery."
            evidence_path = $readinessEvidencePath
            evidence_sha256 = $readinessEvidenceSha
            confidence = 0.10; effort = 8
            candidate_body_bytes = 4; candidate_instruction_count = 220
        }
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"; original_rva = "0x00001040"
            name = "OtBroadFallback"; readiness = "needs-implementation"
            dependency_state = "incomplete"
            reason = "No Product-linked implementation exists."
            evidence_path = $readinessEvidencePath
            evidence_sha256 = $readinessEvidenceSha
            confidence = 0.05; effort = 10
            candidate_body_bytes = 0; candidate_instruction_count = 0
        }
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"; original_rva = "0x00001050"
            name = "OtSessionPaused"; readiness = "ready"
            dependency_state = "ready"
            reason = "Implementation is linked but this session lane is paused."
            evidence_path = $readinessEvidencePath
            evidence_sha256 = $readinessEvidenceSha
            confidence = 0.70; effort = 2
            candidate_body_bytes = 4; candidate_instruction_count = 80
        }
    )
    $readinessLedger = [pscustomobject][ordered]@{
        schema_version = 1
        session_id = "contract-session"
        inputs = $checkpointInputs
        rows = $readinessRows
    }
    $readinessLedger | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $readinessLedgerPath -Encoding UTF8

    Invoke-ScannerCase -Name "ranked-portfolio" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseSessionLaneLedgerPath $sessionLaneLedgerPath `
        -CaseReadinessLedgerPath $readinessLedgerPath `
        -CaseOutputPath $outputPath -ExpectedExitCode 0 `
        -ExpectedOutput "Portfolio target:      75 instructions"

    $dashboardPath = Join-Path $outputPath "wip-residual-dashboard.csv"
    $markdownPath = Join-Path $outputPath "wip-residual-dashboard.md"
    $assignmentsPath = Join-Path $outputPath "wip-lane-assignments.csv"
    $sessionTemplatePath = Join-Path $outputPath `
        "session-lane-ledger.template.json"
    $readinessTemplatePath = Join-Path $outputPath `
        "readiness-ledger.template.json"
    $dashboard = @(Import-Csv -LiteralPath $dashboardPath)
    Assert-Equal $dashboard.Count 5 "Fail-closed WIP row selection"
    Assert-True (-not ($dashboard.Name -contains "OtAcceptedBaseline")) `
        "A match row with WIP-looking notes entered the queue."

    $high = $dashboard | Where-Object { $_.Name -eq "OtHighYieldTiny" }
    Assert-Equal $high.DiffCount 2 "Backward-compatible raw DiffCount"
    Assert-Equal $high.RawDiffCount 2 "Raw residual count"
    Assert-Equal $high.HardDiffCount 1 "Mask-aware hard residual count"
    Assert-Equal $high.YieldInstructions 60 "Ghidra instruction-count join"
    Assert-Equal $high.ProductReachable "True" "Product reachability join"
    Assert-Equal $high.Confidence "0.9" "Confidence metadata override"
    Assert-Equal $high.Effort 1 "Effort metadata override"
    Assert-Equal $high.ConfidenceSource "readiness-ledger" `
        "Readiness confidence provenance"
    Assert-Equal $high.Readiness "ready" "Explicit readiness join"
    Assert-Equal $high.ReadinessSource "readiness-ledger" `
        "Explicit readiness source"
    Assert-Equal $high.MaskShapeValid "True" "Schema-4 mask-shape state"
    $maskAtOne = [byte[]](0, 1, 0, 0, 0, 0, 0, 0)
    Assert-Equal $high.MaskSha256 (Get-ByteArraySha256 $maskAtOne) `
        "Canonical mask digest at offset one"
    Assert-Equal $high.PortfolioSelected "True" "First portfolio selection"
    Assert-Equal $high.PortfolioOrder 1 "First portfolio order"
    Assert-Equal $high.AssignmentId "A001" "Primary assignment identity"
    Assert-Equal $high.AssignmentRole "primary" "Primary assignment role"

    $medium = $dashboard | Where-Object { $_.Name -eq "OtMediumNear" }
    $maskAtTwo = [byte[]](0, 0, 1, 0, 0, 0, 0, 0)
    Assert-Equal $medium.MaskSha256 (Get-ByteArraySha256 $maskAtTwo) `
        "Canonical mask digest at offset two"
    Assert-True ($medium.MaskSha256 -cne $high.MaskSha256) `
        "Equal-width masks at different offsets produced the same digest."
    Assert-Equal $medium.ProductReachable "True" "Second Product reachability join"
    Assert-Equal $medium.PortfolioEligible "True" "Second portfolio eligibility"
    Assert-Equal $medium.PortfolioSelected "True" "Second portfolio selection"
    Assert-Equal $medium.PortfolioOrder 2 "Second portfolio order"
    Assert-Equal $medium.AssignmentId "A001" "Alternate assignment identity"
    Assert-Equal $medium.AssignmentRole "alternate" "Alternate assignment role"
    Assert-Equal $medium.AssignmentPrimaryName "OtHighYieldTiny" `
        "Alternate primary reference"
    Assert-Equal $medium.PortfolioCumulativeInstructions 100 `
        "Portfolio cumulative instruction yield"

    $frozen = $dashboard | Where-Object { $_.Name -eq "OtFrozenResidual" }
    Assert-Equal $frozen.Frozen "True" "Frozen metadata join"
    Assert-Equal $frozen.PromotionReady "False" "Frozen residual verifier status"
    Assert-Equal $frozen.HardDiffCount 1 "Frozen current strict residual"
    Assert-Equal $frozen.BoundHardDiffCount 1 "Frozen bound strict residual"
    Assert-Equal $frozen.BoundComparedBytes 4 "Frozen bound compared bytes"
    Assert-Equal $frozen.BoundHardDiffCountMatches "True" `
        "Initial linked residual-count provenance"
    Assert-Equal $frozen.BoundComparedBytesMatches "True" `
        "Initial compared-byte coverage binding"
    Assert-Equal $frozen.MeaningfulVariantCount 8 "Frozen stop-loss evidence"
    Assert-Equal $frozen.ResidualKind "strict-linked" "Frozen residual kind"
    Assert-Equal $frozen.EvidencePath $frozenEvidencePath "Frozen evidence path"
    Assert-Equal $frozen.EvidenceSha256 $frozenEvidenceSha "Frozen evidence SHA-256"
    Assert-Equal $frozen.SourcePath $frozenSourcePath "Frozen source path"
    Assert-Equal $frozen.SourceSha256 $frozenSourceSha "Frozen source SHA-256"
    Assert-Equal $frozen.BaselineCandidateObject $candidateObjectName `
        "Frozen candidate-object name"
    Assert-Equal $frozen.BaselineCandidateObjectSha256 $candidateObjectSha `
        "Frozen candidate-object identity"
    Assert-Equal $frozen.CurrentCandidateObject $candidateObjectName `
        "Current candidate-object name"
    Assert-Equal $frozen.CurrentCandidateObjectSha256 $candidateObjectSha `
        "Current candidate-object identity"
    Assert-Equal $frozen.BaselineCandidateFunctionSha256 `
        $candidateFunctionHashes["OtFrozenResidual"] `
        "Frozen candidate-function identity"
    Assert-Equal $frozen.CurrentCandidateFunctionSha256 `
        $candidateFunctionHashes["OtFrozenResidual"] `
        "Current candidate-function identity"
    Assert-Equal $frozen.BaselineCandidateFileMatches "True" `
        "Initial whole-file provenance diagnostic"
    Assert-Equal $frozen.BaselineCandidateObjectMatches "True" `
        "Initial candidate-object stable binding"
    Assert-Equal $frozen.BaselineCandidateFunctionMatches "True" `
        "Initial linked-function provenance diagnostic"
    Assert-Equal $frozen.PortfolioSelected "False" "Frozen portfolio exclusion"
    Assert-Equal $frozen.Readiness "blocked" "Frozen readiness diagnostic"
    Assert-True (-not [string]::IsNullOrWhiteSpace($frozen.RevisitCondition)) `
        "Frozen row lost its revisit condition."

    $fallback = $dashboard | Where-Object { $_.Name -eq "OtBroadFallback" }
    Assert-Equal $fallback.Status "OK" "Same-RVA candidate locator fallback"
    Assert-Equal $fallback.CandidateRva "0x1040" "Same-RVA candidate address"
    Assert-Equal $fallback.ProductReachable "False" "Unreachable Product diagnostic"
    Assert-Equal $fallback.PortfolioEligible "False" `
        "Product-unreachable WIP must not enter the portfolio"
    Assert-Equal $fallback.PortfolioSelected "False" `
        "Product-unreachable WIP was selected for milestone yield"
    Assert-True ($fallback.PortfolioExclusionReason -match 'outside the strict Product graph') `
        "Product-unreachable WIP lost its exclusion reason."
    Assert-Equal $fallback.Readiness "needs-implementation" `
        "Implementation readiness classification"

    $paused = $dashboard | Where-Object { $_.Name -eq "OtSessionPaused" }
    Assert-Equal $paused.Frozen "False" `
        "Session pause must not masquerade as durable frozen-WIP state"
    Assert-Equal $paused.SessionLaneState "paused" "Session pause join"
    Assert-Equal $paused.SessionLaneMeaningfulVariantCount 4 `
        "Session meaningful-variant evidence"
    Assert-Equal $paused.SessionLaneSourceSha256 $sessionSourceSha `
        "Session source binding"
    Assert-Equal $paused.Readiness "ready" "Paused row retains readiness diagnostic"
    Assert-Equal $paused.PortfolioEligible "False" "Paused session lane exclusion"
    Assert-Equal $paused.PortfolioSelected "False" "Paused session lane selection"
    Assert-True ($paused.PortfolioExclusionReason -match 'session lane is paused') `
        "Paused session lane lost its distinct exclusion reason."

    $assignments = @(Import-Csv -LiteralPath $assignmentsPath)
    Assert-Equal $assignments.Count 1 "Paired lane assignment count"
    Assert-Equal $assignments[0].PrimaryName "OtHighYieldTiny" `
        "Lane assignment primary"
    Assert-Equal $assignments[0].AlternateName "OtMediumNear" `
        "Lane assignment alternate"
    Assert-Equal $assignments[0].Complete "True" `
        "Lane assignment completeness"

    $sessionTemplate = Get-Content -LiteralPath $sessionTemplatePath -Raw |
        ConvertFrom-Json
    $readinessTemplate = Get-Content -LiteralPath $readinessTemplatePath -Raw |
        ConvertFrom-Json
    Assert-Equal $sessionTemplate.schema_version 1 `
        "Session seed template schema"
    Assert-Equal $readinessTemplate.schema_version 1 `
        "Readiness seed template schema"
    Assert-Equal $sessionTemplate.session_id $readinessTemplate.session_id `
        "Seed template session identity"
    Assert-True ($sessionTemplate.session_id -match '^checkpoint-[0-9a-f]{12}-[0-9a-f]{12}$') `
        "Seed template session identity is not deterministic and hash-derived."
    Assert-Equal @($sessionTemplate.rows).Count 0 `
        "Session seed rows must start empty"
    Assert-True ($null -ne $sessionTemplate.row_template.residual) `
        "Session seed lost its editable row schema."
    foreach ($checkpointInputProperty in $checkpointInputs.PSObject.Properties) {
        $inputName = $checkpointInputProperty.Name
        Assert-Equal $sessionTemplate.inputs.$inputName `
            $checkpointInputProperty.Value `
            "Session seed checkpoint input $inputName"
        Assert-Equal $readinessTemplate.inputs.$inputName `
            $checkpointInputProperty.Value `
            "Readiness seed checkpoint input $inputName"
    }
    Assert-Equal @($readinessTemplate.rows).Count 5 `
        "Readiness seed must cover every WIP identity"
    Assert-True (-not (@($readinessTemplate.rows.name) -contains
            "OtAcceptedBaseline")) `
        "Readiness seed included a manifest match identity."
    foreach ($seedReadinessRow in @($readinessTemplate.rows)) {
        Assert-Equal $seedReadinessRow.readiness "needs-implementation" `
            "Conservative readiness seed for $($seedReadinessRow.name)"
        Assert-Equal $seedReadinessRow.dependency_state "incomplete" `
            "Conservative dependency seed for $($seedReadinessRow.name)"
        Assert-Equal $seedReadinessRow.template_default "True" `
            "Explicit fail-closed template marker for $($seedReadinessRow.name)"
        Assert-Equal $seedReadinessRow.evidence_path "" `
            "Seed evidence must remain an explicit fill-in field"
    }

    $templateReplayOutput = Join-Path $outputRoot "template-replay-output"
    Invoke-ScannerCase -Name "deterministic-ledger-seed-templates" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath $templateReplayOutput `
        -CaseSessionLaneLedgerPath $sessionTemplatePath `
        -CaseReadinessLedgerPath $readinessTemplatePath `
        -CaseAllowPortfolioShortfall `
        -ExpectedExitCode 0 -ExpectedOutput "Portfolio selected:    0 rows / 0 instructions"
    Assert-Equal (Get-FileSha256 $sessionTemplatePath) `
        (Get-FileSha256 (Join-Path $templateReplayOutput `
            "session-lane-ledger.template.json")) `
        "Deterministic session seed template"
    Assert-Equal (Get-FileSha256 $readinessTemplatePath) `
        (Get-FileSha256 (Join-Path $templateReplayOutput `
            "readiness-ledger.template.json")) `
        "Deterministic readiness seed template"

    $markdown = [System.IO.File]::ReadAllText($markdownPath)
    Assert-True ($markdown.Contains('- NextCheckpointPercent: `55`')) `
        "Automatic next checkpoint was not 55 percent."
    Assert-True ($markdown.Contains('- NextCheckpointRequirement: `50`')) `
        "Automatic checkpoint deficit was not 50 instructions."
    Assert-True ($markdown.Contains('- PortfolioTargetInstructions: `75`')) `
        "Default portfolio was not 150 percent of the checkpoint deficit."
    Assert-True ($markdown.Contains('- PortfolioSelectedInstructions: `100`')) `
        "Portfolio did not stop after crossing the target."
    Assert-True ($markdown.Contains('## Primary and Alternate Lane Assignments')) `
        "Markdown lost primary/alternate assignments."
    Assert-True ($markdown.Contains('- IncompleteAssignments: `0`')) `
        "Summary lost assignment completeness."
    Write-Host ("PASS queue columns, readiness, session pause, paired " +
        "assignments, frozen gate, and automatic portfolio")

    $missingReadinessOutput = Join-Path $outputRoot "missing-readiness-output"
    Invoke-ScannerCase -Name "missing-required-readiness" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath $missingReadinessOutput `
        -CaseSessionLaneLedgerPath $sessionLaneLedgerPath `
        -CaseRequireExplicitReadiness `
        -ExpectedExitCode 1 `
        -ExpectedOutput "Checkpoint-bound readiness metadata is required for 2 viable WIP row(s)"
    Assert-True (Test-Path -LiteralPath (
            Join-Path $missingReadinessOutput "wip-residual-dashboard.csv") `
            -PathType Leaf) `
        "Missing readiness did not preserve its diagnostic dashboard."
    Assert-True (Test-Path -LiteralPath (
            Join-Path $missingReadinessOutput "readiness-ledger.template.json") `
            -PathType Leaf) `
        "Fail-closed readiness did not emit its checkpoint-bound seed template."

    $incompleteReadinessPath = Join-Path $workPath "incomplete-readiness.json"
    $incompleteReadiness = Get-Content -LiteralPath $readinessLedgerPath -Raw |
        ConvertFrom-Json
    $incompleteReadiness.rows = @($incompleteReadiness.rows | Where-Object {
        $_.name -cne "OtMediumNear"
    })
    $incompleteReadiness | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $incompleteReadinessPath -Encoding UTF8
    Invoke-ScannerCase -Name "incomplete-readiness-ledger" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "incomplete-readiness-output") `
        -CaseSessionLaneLedgerPath $sessionLaneLedgerPath `
        -CaseReadinessLedgerPath $incompleteReadinessPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "Checkpoint-bound readiness metadata is required for 1 viable WIP row(s)"

    $staleReadinessInputPath = Join-Path $workPath "stale-readiness-input.json"
    $staleReadinessInput = Get-Content -LiteralPath $readinessLedgerPath -Raw |
        ConvertFrom-Json
    $staleReadinessInput.inputs.manifest_sha256 = "0" * 64
    $staleReadinessInput | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $staleReadinessInputPath -Encoding UTF8
    Invoke-ScannerCase -Name "stale-readiness-checkpoint" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "stale-readiness-input-output") `
        -CaseSessionLaneLedgerPath $sessionLaneLedgerPath `
        -CaseReadinessLedgerPath $staleReadinessInputPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "Readiness ledger input 'manifest_sha256' does not match"

    $duplicateReadinessPath = Join-Path $workPath "duplicate-readiness.json"
    $duplicateReadiness = Get-Content -LiteralPath $readinessLedgerPath -Raw |
        ConvertFrom-Json
    $duplicateReadiness.rows = @($duplicateReadiness.rows) +
        @($duplicateReadiness.rows[0])
    $duplicateReadiness | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $duplicateReadinessPath -Encoding UTF8
    Invoke-ScannerCase -Name "duplicate-readiness-identity" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "duplicate-readiness-output") `
        -CaseReadinessLedgerPath $duplicateReadinessPath `
        -ExpectedExitCode 1 -ExpectedOutput "Duplicate readiness row"

    $invalidReadinessPath = Join-Path $workPath "invalid-readiness.json"
    $invalidReadiness = Get-Content -LiteralPath $readinessLedgerPath -Raw |
        ConvertFrom-Json
    $invalidReadiness.rows[0].readiness = "queued"
    $invalidReadiness | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $invalidReadinessPath -Encoding UTF8
    Invoke-ScannerCase -Name "invalid-readiness-classification" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "invalid-readiness-output") `
        -CaseReadinessLedgerPath $invalidReadinessPath `
        -ExpectedExitCode 1 -ExpectedOutput "has invalid readiness 'queued'"

    $invalidReadinessEvidencePath = Join-Path $workPath `
        "invalid-readiness-evidence.json"
    $invalidReadinessEvidence = Get-Content -LiteralPath $readinessLedgerPath -Raw |
        ConvertFrom-Json
    $invalidReadinessEvidence.rows[0].evidence_sha256 = "0" * 64
    $invalidReadinessEvidence | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $invalidReadinessEvidencePath -Encoding UTF8
    Invoke-ScannerCase -Name "stale-readiness-evidence" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "invalid-readiness-evidence-output") `
        -CaseReadinessLedgerPath $invalidReadinessEvidencePath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "Readiness row 'OtHighYieldTiny' recorded evidence SHA-256 changed"

    $singleReadyPath = Join-Path $workPath "single-ready.json"
    $singleReady = Get-Content -LiteralPath $readinessLedgerPath -Raw |
        ConvertFrom-Json
    $singleReadyMedium = $singleReady.rows | Where-Object {
        $_.name -ceq "OtMediumNear"
    }
    $singleReadyMedium.readiness = "blocked"
    $singleReadyMedium.dependency_state = "blocked"
    $singleReadyMedium.reason = "Synthetic blocker for assignment contract."
    $singleReady | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $singleReadyPath -Encoding UTF8
    $singleReadyOutput = Join-Path $outputRoot "single-ready-output"
    Invoke-ScannerCase -Name "incomplete-primary-alternate-assignment" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath $singleReadyOutput `
        -CaseSessionLaneLedgerPath $sessionLaneLedgerPath `
        -CaseReadinessLedgerPath $singleReadyPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "1 incomplete primary/alternate lane assignment(s)"
    $singleAssignment = @(Import-Csv -LiteralPath (
        Join-Path $singleReadyOutput "wip-lane-assignments.csv"))
    Assert-Equal $singleAssignment.Count 1 "Incomplete assignment diagnostic count"
    Assert-Equal $singleAssignment[0].Complete "False" `
        "Incomplete assignment diagnostic state"
    Invoke-ScannerCase -Name "incomplete-assignment-explicit-diagnostic" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "single-ready-allowed-output") `
        -CaseSessionLaneLedgerPath $sessionLaneLedgerPath `
        -CaseReadinessLedgerPath $singleReadyPath `
        -CaseAllowIncompleteAssignments -CaseAllowPortfolioShortfall `
        -ExpectedExitCode 0 -ExpectedOutput "Lane assignments:      1 (1 incomplete)"

    $staleSessionInputPath = Join-Path $workPath "stale-session-input.json"
    $staleSessionInput = Get-Content -LiteralPath $sessionLaneLedgerPath -Raw |
        ConvertFrom-Json
    $staleSessionInput.inputs.candidate_file_sha256 = "0" * 64
    $staleSessionInput | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $staleSessionInputPath -Encoding UTF8
    Invoke-ScannerCase -Name "stale-session-checkpoint" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "stale-session-input-output") `
        -CaseSessionLaneLedgerPath $staleSessionInputPath `
        -CaseReadinessLedgerPath $readinessLedgerPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "Session lane ledger input 'candidate_file_sha256' does not match"

    $duplicateSessionPath = Join-Path $workPath "duplicate-session.json"
    $duplicateSession = Get-Content -LiteralPath $sessionLaneLedgerPath -Raw |
        ConvertFrom-Json
    $duplicateSession.rows = @($duplicateSession.rows) + @($duplicateSession.rows[0])
    $duplicateSession | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $duplicateSessionPath -Encoding UTF8
    Invoke-ScannerCase -Name "duplicate-session-identity" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "duplicate-session-output") `
        -CaseSessionLaneLedgerPath $duplicateSessionPath `
        -CaseReadinessLedgerPath $readinessLedgerPath `
        -ExpectedExitCode 1 -ExpectedOutput "Duplicate session lane row"

    $invalidSessionStatePath = Join-Path $workPath "invalid-session-state.json"
    $invalidSessionState = Get-Content -LiteralPath $sessionLaneLedgerPath -Raw |
        ConvertFrom-Json
    $invalidSessionState.rows[0].state = "stopped"
    $invalidSessionState | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $invalidSessionStatePath -Encoding UTF8
    Invoke-ScannerCase -Name "invalid-session-state" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "invalid-session-state-output") `
        -CaseSessionLaneLedgerPath $invalidSessionStatePath `
        -CaseReadinessLedgerPath $readinessLedgerPath `
        -ExpectedExitCode 1 -ExpectedOutput "has invalid state 'stopped'"

    $staleSessionResidualPath = Join-Path $workPath "stale-session-residual.json"
    $staleSessionResidual = Get-Content -LiteralPath $sessionLaneLedgerPath -Raw |
        ConvertFrom-Json
    $staleSessionResidual.rows[0].residual.hard_diff_count = 2
    $staleSessionResidual | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $staleSessionResidualPath -Encoding UTF8
    Invoke-ScannerCase -Name "stale-session-residual" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "stale-session-residual-output") `
        -CaseSessionLaneLedgerPath $staleSessionResidualPath `
        -CaseReadinessLedgerPath $readinessLedgerPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "strict residual changed: recorded 2/4, current 1/4"

    $staleSessionSourcePath = Join-Path $workPath "stale-session-source.json"
    $staleSessionSource = Get-Content -LiteralPath $sessionLaneLedgerPath -Raw |
        ConvertFrom-Json
    $staleSessionSource.rows[0].source_sha256 = "0" * 64
    $staleSessionSource | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $staleSessionSourcePath -Encoding UTF8
    Invoke-ScannerCase -Name "stale-session-source" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "stale-session-source-output") `
        -CaseSessionLaneLedgerPath $staleSessionSourcePath `
        -CaseReadinessLedgerPath $readinessLedgerPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "Session lane row 'OtSessionPaused' recorded source SHA-256 changed"

    $invalidSessionTimingPath = Join-Path $workPath "invalid-session-timing.json"
    $invalidSessionTiming = Get-Content -LiteralPath $sessionLaneLedgerPath -Raw |
        ConvertFrom-Json
    $invalidSessionTiming.rows[0].updated_utc = "2026-07-17T11:00:00Z"
    $invalidSessionTiming | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $invalidSessionTimingPath -Encoding UTF8
    Invoke-ScannerCase -Name "invalid-session-timing" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "invalid-session-timing-output") `
        -CaseSessionLaneLedgerPath $invalidSessionTimingPath `
        -CaseReadinessLedgerPath $readinessLedgerPath `
        -ExpectedExitCode 1 -ExpectedOutput "updated_utc precedes started_utc"

    $invalidSessionFreezePath = Join-Path $workPath "invalid-session-freeze.json"
    $invalidSessionFreeze = Get-Content -LiteralPath $sessionLaneLedgerPath -Raw |
        ConvertFrom-Json
    $invalidSessionFreeze.rows[0].state = "frozen"
    $invalidSessionFreeze | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $invalidSessionFreezePath -Encoding UTF8
    Invoke-ScannerCase -Name "session-freeze-stop-loss" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "invalid-session-freeze-output") `
        -CaseSessionLaneLedgerPath $invalidSessionFreezePath `
        -CaseReadinessLedgerPath $readinessLedgerPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "requires at least eight meaningful variants"

    $differentSessionIdPath = Join-Path $workPath "different-session-id.json"
    $differentSessionId = Get-Content -LiteralPath $sessionLaneLedgerPath -Raw |
        ConvertFrom-Json
    $differentSessionId.session_id = "different-session"
    $differentSessionId | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $differentSessionIdPath -Encoding UTF8
    Invoke-ScannerCase -Name "ledger-session-id-mismatch" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "session-id-mismatch-output") `
        -CaseSessionLaneLedgerPath $differentSessionIdPath `
        -CaseReadinessLedgerPath $readinessLedgerPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "different session_id values"

    $schemaThreeVerifierPath = Join-Path $workPath "schema-three-verifier.csv"
    $schemaThreeVerifier = @(Import-Csv -LiteralPath $verifierPath)
    $schemaThreeVerifier[0].result_schema_version = "3"
    $schemaThreeVerifier | Export-Csv -LiteralPath $schemaThreeVerifierPath `
        -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "legacy-verifier-schema-rejected" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "schema-three-output") `
        -CaseVerifierPath $schemaThreeVerifierPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "Unsupported verifier result_schema_version '3'; expected 4"

    $missingMaskShapeVerifierPath = Join-Path $workPath `
        "missing-mask-shape-verifier.csv"
    $missingMaskShapeVerifier = @(Import-Csv -LiteralPath $verifierPath)
    $missingMaskShapeVerifier[0].mask_shape_valid = ""
    $missingMaskShapeVerifier | Export-Csv `
        -LiteralPath $missingMaskShapeVerifierPath -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "missing-schema-four-mask-shape" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "missing-mask-shape-output") `
        -CaseVerifierPath $missingMaskShapeVerifierPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "Missing required Boolean field 'verifier.mask_shape_valid'"

    $missingOperandShapeVerifierPath = Join-Path $workPath `
        "missing-operand-shape-verifier.csv"
    $missingOperandShapeVerifier = @(Import-Csv -LiteralPath $verifierPath)
    foreach ($missingOperandShapeRow in $missingOperandShapeVerifier) {
        $missingOperandShapeRow.PSObject.Properties.Remove(
            "masked_operand_shape_error")
    }
    $missingOperandShapeVerifier | Export-Csv `
        -LiteralPath $missingOperandShapeVerifierPath `
        -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "missing-schema-four-operand-shape-field" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "missing-operand-shape-output") `
        -CaseVerifierPath $missingOperandShapeVerifierPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "missing required field 'masked_operand_shape_error'"

    $staleMaskShapeVerifierPath = Join-Path $workPath `
        "stale-mask-shape-verifier.csv"
    $staleMaskShapeVerifier = @(Import-Csv -LiteralPath $verifierPath)
    $staleMaskShapeVerifier[0].masked_operand_shape_error = "stale diagnostic"
    $staleMaskShapeVerifier | Export-Csv `
        -LiteralPath $staleMaskShapeVerifierPath -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "inconsistent-schema-four-mask-shape" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "stale-mask-shape-output") `
        -CaseVerifierPath $staleMaskShapeVerifierPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "mask_shape_valid=true with a masked operand-shape diagnostic"

    $blockedMaskShapeVerifierPath = Join-Path $workPath `
        "blocked-mask-shape-verifier.csv"
    $blockedMaskShapeVerifier = @(Import-Csv -LiteralPath $verifierPath)
    $blockedMaskShapeVerifier[0].mask_shape_valid = "False"
    $blockedMaskShapeVerifier[0].masked_operand_shape_error = `
        "Synthetic paired operand-shape mismatch."
    $blockedMaskShapeVerifier | Export-Csv `
        -LiteralPath $blockedMaskShapeVerifierPath -NoTypeInformation -Encoding UTF8
    $blockedMaskShapeSummaryPath = Join-Path $workPath `
        "blocked-mask-shape-summary.json"
    $blockedMaskShapeSummary = Get-Content -LiteralPath $progressSummaryPath -Raw |
        ConvertFrom-Json
    $blockedMaskShapeSummary.inputs.verifier_results.path = `
        $blockedMaskShapeVerifierPath
    $blockedMaskShapeSummary.inputs.verifier_results.sha256 = `
        Get-FileSha256 $blockedMaskShapeVerifierPath
    $blockedMaskShapeSummary | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $blockedMaskShapeSummaryPath -Encoding UTF8
    $blockedMaskShapeOutput = Join-Path $outputRoot "blocked-mask-shape-output"
    Invoke-ScannerCase -Name "invalid-mask-shape-is-verifier-blocked" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath $blockedMaskShapeOutput `
        -CaseVerifierPath $blockedMaskShapeVerifierPath `
        -CaseProgressSummaryPath $blockedMaskShapeSummaryPath `
        -ExpectedExitCode 0 -ExpectedOutput "Portfolio selected:"
    $blockedMaskShapeRow = Import-Csv -LiteralPath (
        Join-Path $blockedMaskShapeOutput "wip-residual-dashboard.csv") |
        Where-Object { $_.name -ceq "OtHighYieldTiny" }
    Assert-Equal $blockedMaskShapeRow.MaskShapeValid "False" `
        "Invalid mask-shape state diagnostic"
    Assert-Equal $blockedMaskShapeRow.VerifierBlocked "True" `
        "Invalid mask shape must block queue selection"
    Assert-Equal $blockedMaskShapeRow.PortfolioEligible "False" `
        "Invalid mask shape entered the ready portfolio"
    Assert-True ($blockedMaskShapeRow.PortfolioExclusionReason -match
            'verifier blocked') `
        "Invalid mask shape lost its queue exclusion reason."

    $invalidManifestPath = Join-Path $workPath "invalid-status-manifest.csv"
    $invalidManifest = @($manifest | ForEach-Object { $_.PSObject.Copy() })
    ($invalidManifest | Where-Object { $_.name -eq "OtAcceptedBaseline" }).expected_status = "accepted"
    $invalidManifest | Export-Csv -LiteralPath $invalidManifestPath -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "unknown-expected-status" `
        -CaseManifestPath $invalidManifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "invalid-output") `
        -ExpectedExitCode 1 -ExpectedOutput "Unknown expected_status 'accepted'"

    $missingMetricsPath = Join-Path $workPath "missing-metrics.csv"
    @(Import-Csv -LiteralPath $metricsPath | Where-Object {
        $_.original_rva -ne "0x00001010"
    }) | Export-Csv -LiteralPath $missingMetricsPath -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "missing-ghidra-join" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $missingMetricsPath `
        -CaseOutputPath (Join-Path $outputRoot "missing-output") `
        -ExpectedExitCode 1 -ExpectedOutput "is missing from Ghidra function metrics"

    $missingBodyRangesPath = Join-Path $workPath "missing-body-ranges.csv"
    $missingBodyRanges = @(Import-Csv -LiteralPath $metricsPath)
    foreach ($row in $missingBodyRanges) {
        $row.PSObject.Properties.Remove("body_ranges")
    }
    $missingBodyRanges | Export-Csv -LiteralPath $missingBodyRangesPath `
        -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "missing-body-ranges" `
        -CaseManifestPath $manifestPath `
        -CaseMetricsPath $missingBodyRangesPath `
        -CaseOutputPath (Join-Path $outputRoot "missing-body-ranges-output") `
        -ExpectedExitCode 1 -ExpectedOutput "missing required body_ranges"

    $malformedBodyRangesPath = Join-Path $workPath "malformed-body-ranges.csv"
    $malformedBodyRanges = @(Import-Csv -LiteralPath $metricsPath)
    $malformedBodyRanges[0].body_ranges = "0x00001000..0x00001004"
    $malformedBodyRanges | Export-Csv -LiteralPath $malformedBodyRangesPath `
        -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "malformed-body-ranges" `
        -CaseManifestPath $manifestPath `
        -CaseMetricsPath $malformedBodyRangesPath `
        -CaseOutputPath (Join-Path $outputRoot "malformed-body-ranges-output") `
        -ExpectedExitCode 1 -ExpectedOutput "malformed body_ranges"

    $unorderedBodyRangesPath = Join-Path $workPath "unordered-body-ranges.csv"
    $unorderedBodyRanges = @(Import-Csv -LiteralPath $metricsPath)
    $unorderedBodyRanges[0].body_ranges =
        "0x00001006-0x00001008;0x00001000-0x00001002"
    $unorderedBodyRanges | Export-Csv -LiteralPath $unorderedBodyRangesPath `
        -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "unordered-body-ranges" `
        -CaseManifestPath $manifestPath `
        -CaseMetricsPath $unorderedBodyRangesPath `
        -CaseOutputPath (Join-Path $outputRoot "unordered-body-ranges-output") `
        -ExpectedExitCode 1 -ExpectedOutput "ordered and internally disjoint"

    $internalOverlapMetricsPath = Join-Path $workPath "internal-body-overlap.csv"
    $internalOverlapMetrics = @(Import-Csv -LiteralPath $metricsPath)
    $internalOverlapMetrics[0].body_ranges =
        "0x00001000-0x00001003;0x00001002-0x00001003"
    $internalOverlapMetrics | Export-Csv `
        -LiteralPath $internalOverlapMetricsPath -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "internal-body-overlap" `
        -CaseManifestPath $manifestPath `
        -CaseMetricsPath $internalOverlapMetricsPath `
        -CaseOutputPath (Join-Path $outputRoot "internal-body-overlap-output") `
        -ExpectedExitCode 1 -ExpectedOutput "ordered and internally disjoint"

    $unownedEntryMetricsPath = Join-Path $workPath "unowned-entry-metrics.csv"
    $unownedEntryMetrics = @(Import-Csv -LiteralPath $metricsPath)
    $unownedEntryMetrics[0].body_ranges =
        "0x00001001-0x00001002;0x00001005-0x00001008"
    $unownedEntryMetrics | Export-Csv `
        -LiteralPath $unownedEntryMetricsPath -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "unowned-entry" `
        -CaseManifestPath $manifestPath `
        -CaseMetricsPath $unownedEntryMetricsPath `
        -CaseOutputPath (Join-Path $outputRoot "unowned-entry-output") `
        -ExpectedExitCode 1 -ExpectedOutput "does not own its entry RVA"

    $outsideBodyMetricsPath = Join-Path $workPath "outside-body-metrics.csv"
    $outsideBodyMetrics = @(Import-Csv -LiteralPath $metricsPath)
    $outsideBodyMetrics[0].body_ranges =
        "0x00001000-0x00001002;0x00001008-0x0000100a"
    $outsideBodyMetrics | Export-Csv -LiteralPath $outsideBodyMetricsPath `
        -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "body-range-outside-envelope" `
        -CaseManifestPath $manifestPath `
        -CaseMetricsPath $outsideBodyMetricsPath `
        -CaseOutputPath (Join-Path $outputRoot "outside-body-range-output") `
        -ExpectedExitCode 1 -ExpectedOutput "outside its half-open envelope"

    $bodySizeMismatchPath = Join-Path $workPath "body-size-mismatch.csv"
    $bodySizeMismatch = @(Import-Csv -LiteralPath $metricsPath)
    $bodySizeMismatch[0].body_ranges =
        "0x00001000-0x00001002;0x00001006-0x00001007"
    $bodySizeMismatch | Export-Csv -LiteralPath $bodySizeMismatchPath `
        -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "body-union-size-mismatch" `
        -CaseManifestPath $manifestPath `
        -CaseMetricsPath $bodySizeMismatchPath `
        -CaseOutputPath (Join-Path $outputRoot "body-size-mismatch-output") `
        -ExpectedExitCode 1 -ExpectedOutput "does not equal body_bytes"

    $crossBodyOverlapPath = Join-Path $workPath "cross-body-overlap.csv"
    $crossBodyOverlap = @(Import-Csv -LiteralPath $metricsPath)
    $crossBodyOverlap[0].size = "0x14"
    $crossBodyOverlap[0].body_ranges =
        "0x00001000-0x00001002;0x00001010-0x00001012"
    $crossBodyOverlap | Export-Csv -LiteralPath $crossBodyOverlapPath `
        -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "cross-function-body-overlap" `
        -CaseManifestPath $manifestPath `
        -CaseMetricsPath $crossBodyOverlapPath `
        -CaseOutputPath (Join-Path $outputRoot "cross-body-overlap-output") `
        -ExpectedExitCode 1 -ExpectedOutput "Function body overlap in program"

    # Preserve all legacy denominator fields and the aggregate input binding,
    # then alter only canonical ownership. The scanner must independently
    # recompute and reject the stale ownership proof.
    $ownershipDriftMetricsPath = Join-Path $workPath "ownership-drift-metrics.csv"
    $ownershipDriftMetrics = @(Import-Csv -LiteralPath $metricsPath)
    $ownershipDriftMetrics[0].body_ranges =
        "0x00001000-0x00001001;0x00001005-0x00001008"
    $ownershipDriftMetrics | Export-Csv `
        -LiteralPath $ownershipDriftMetricsPath -NoTypeInformation -Encoding UTF8
    $ownershipDriftSummaryPath = Join-Path $workPath "ownership-drift-summary.json"
    $ownershipDriftSummary = Get-Content -LiteralPath $progressSummaryPath -Raw |
        ConvertFrom-Json
    $ownershipDriftSummary.inputs.function_metrics[0].path =
        $ownershipDriftMetricsPath
    $ownershipDriftSummary.inputs.function_metrics[0].sha256 =
        Get-FileSha256 $ownershipDriftMetricsPath
    $ownershipDriftSummary | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $ownershipDriftSummaryPath -Encoding UTF8
    Invoke-ScannerCase -Name "ownership-only-summary-drift" `
        -CaseManifestPath $manifestPath `
        -CaseMetricsPath $ownershipDriftMetricsPath `
        -CaseProgressSummaryPath $ownershipDriftSummaryPath `
        -CaseOutputPath (Join-Path $outputRoot "ownership-drift-output") `
        -ExpectedExitCode 1 `
        -ExpectedOutput "Progress metrics summary body ownership changed"

    $staleVerifierPath = Join-Path $workPath "stale-verifier.csv"
    $staleVerifier = @(Import-Csv -LiteralPath $verifierPath)
    $staleVerifier[0].candidate_file_sha256 = ("0" * 64)
    $staleVerifier | Export-Csv -LiteralPath $staleVerifierPath `
        -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "stale-verifier-candidate" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "stale-verifier-output") `
        -CaseVerifierPath $staleVerifierPath `
        -ExpectedExitCode 1 -ExpectedOutput "recorded candidate image SHA-256 changed"

    $missingFrozenPath = Join-Path $workPath "missing-frozen.csv"
    $missingFrozenOutput = Join-Path $outputRoot "missing-frozen-output"
    Invoke-ScannerCase -Name "missing-frozen-metadata" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath $missingFrozenOutput `
        -CaseFrozenPath $missingFrozenPath `
        -ExpectedExitCode 1 -ExpectedOutput "Frozen WIP metadata is required"
    Assert-True (-not (Test-Path -LiteralPath $missingFrozenOutput)) `
        "Missing frozen metadata created dashboard output before validation."

    $staleEvidenceFrozenPath = Join-Path $workPath "stale-evidence-frozen.csv"
    $staleEvidenceFrozen = @(Import-Csv -LiteralPath $frozenPath)
    ($staleEvidenceFrozen | Where-Object {
        $_.name -eq "OtFrozenResidual"
    }).evidence_sha256 = "0" * 64
    $staleEvidenceFrozen | Export-Csv -LiteralPath $staleEvidenceFrozenPath `
        -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "stale-frozen-evidence" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "stale-frozen-evidence-output") `
        -CaseFrozenPath $staleEvidenceFrozenPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "recorded evidence SHA-256 changed"

    $invalidObjectHashFrozenPath = Join-Path $workPath `
        "invalid-object-hash-frozen.csv"
    $invalidObjectHashFrozen = @(Import-Csv -LiteralPath $frozenPath)
    ($invalidObjectHashFrozen | Where-Object {
        $_.name -eq "OtFrozenResidual"
    }).baseline_candidate_object_sha256 = ""
    $invalidObjectHashFrozen | Export-Csv `
        -LiteralPath $invalidObjectHashFrozenPath -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "invalid-frozen-object-hash" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "invalid-object-hash-output") `
        -CaseFrozenPath $invalidObjectHashFrozenPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "invalid baseline_candidate_object_sha256"

    $objectNameDriftFrozenPath = Join-Path $workPath `
        "object-name-drift-frozen.csv"
    $objectNameDriftFrozen = @(Import-Csv -LiteralPath $frozenPath)
    ($objectNameDriftFrozen | Where-Object {
        $_.name -eq "OtFrozenResidual"
    }).baseline_candidate_object = "different.obj"
    $objectNameDriftFrozen | Export-Csv `
        -LiteralPath $objectNameDriftFrozenPath -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "frozen-object-name-drift" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "object-name-drift-output") `
        -CaseFrozenPath $objectNameDriftFrozenPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "candidate object changed"

    $objectTraversalFrozenPath = Join-Path $workPath `
        "object-traversal-frozen.csv"
    $objectTraversalFrozen = @(Import-Csv -LiteralPath $frozenPath)
    ($objectTraversalFrozen | Where-Object {
        $_.name -eq "OtFrozenResidual"
    }).baseline_candidate_object = "..\outside.obj"
    $objectTraversalFrozen | Export-Csv `
        -LiteralPath $objectTraversalFrozenPath -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "frozen-object-path-traversal" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "object-traversal-output") `
        -CaseFrozenPath $objectTraversalFrozenPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "basename-only baseline_candidate_object"

    $staleResidualFrozenPath = Join-Path $workPath "stale-residual-frozen.csv"
    $staleResidualFrozen = @(Import-Csv -LiteralPath $frozenPath)
    ($staleResidualFrozen | Where-Object {
        $_.name -eq "OtFrozenResidual"
    }).hard_diff_count = "2"
    $staleResidualFrozen | Export-Csv -LiteralPath $staleResidualFrozenPath `
        -NoTypeInformation -Encoding UTF8
    $staleResidualOutput = Join-Path $outputRoot "stale-frozen-residual-output"
    Invoke-ScannerCase -Name "linked-residual-count-is-provenance" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath $staleResidualOutput `
        -CaseFrozenPath $staleResidualFrozenPath `
        -ExpectedExitCode 0 `
        -ExpectedOutput "Portfolio selected:"
    $staleResidualDashboard = Import-Csv -LiteralPath (
        Join-Path $staleResidualOutput "wip-residual-dashboard.csv") |
        Where-Object { $_.name -eq "OtFrozenResidual" }
    Assert-Equal $staleResidualDashboard.BoundHardDiffCountMatches "False" `
        "Linked residual-count provenance drift was not exposed"
    Assert-Equal $staleResidualDashboard.BaselineCandidateObjectMatches "True" `
        "Linked residual-count drift lost its stable object binding"

    $staleCoverageFrozenPath = Join-Path $workPath "stale-coverage-frozen.csv"
    $staleCoverageFrozen = @(Import-Csv -LiteralPath $frozenPath)
    ($staleCoverageFrozen | Where-Object {
        $_.name -eq "OtFrozenResidual"
    }).compared_bytes = "3"
    $staleCoverageFrozen | Export-Csv -LiteralPath $staleCoverageFrozenPath `
        -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "stale-frozen-compared-byte-coverage" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "stale-coverage-output") `
        -CaseFrozenPath $staleCoverageFrozenPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "compared-byte coverage changed: recorded 3, current 4"

    $historicalBinaryFrozenPath = Join-Path $workPath "historical-binary-frozen.csv"
    $historicalBinaryFrozen = @(Import-Csv -LiteralPath $frozenPath)
    ($historicalBinaryFrozen | Where-Object {
        $_.name -eq "OtFrozenResidual"
    }).baseline_candidate_sha256 = "0" * 64
    $historicalBinaryFrozen | Export-Csv -LiteralPath $historicalBinaryFrozenPath `
        -NoTypeInformation -Encoding UTF8
    $historicalBinaryOutput = Join-Path $outputRoot "historical-binary-output"
    Invoke-ScannerCase -Name "whole-binary-hash-is-provenance" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath $historicalBinaryOutput `
        -CaseFrozenPath $historicalBinaryFrozenPath `
        -ExpectedExitCode 0 `
        -ExpectedOutput "Portfolio selected:"
    $historicalBinaryDashboard = Import-Csv -LiteralPath (
        Join-Path $historicalBinaryOutput "wip-residual-dashboard.csv") |
        Where-Object { $_.name -eq "OtFrozenResidual" }
    Assert-Equal $historicalBinaryDashboard.BaselineCandidateFileMatches "False" `
        "Whole-file baseline mismatch must remain a visible provenance diagnostic"

    $metadataOnlyCandidatePath = Join-Path $workPath "metadata-only-candidate.exe"
    $metadataOnlyCandidateBytes = [System.IO.File]::ReadAllBytes($candidatePath)
    Set-U32 $metadataOnlyCandidateBytes 0x88 0x12345678
    [System.IO.File]::WriteAllBytes(
        $metadataOnlyCandidatePath, $metadataOnlyCandidateBytes)
    $metadataOnlyVerifierPath = Join-Path $workPath "metadata-only-verifier.csv"
    $metadataOnlyVerifier = @(Import-Csv -LiteralPath $verifierPath)
    $metadataOnlyCandidateSha = Get-FileSha256 $metadataOnlyCandidatePath
    foreach ($row in $metadataOnlyVerifier) {
        $row.candidate_path = $metadataOnlyCandidatePath
        $row.candidate_file_sha256 = $metadataOnlyCandidateSha
    }
    $metadataOnlyVerifier | Export-Csv -LiteralPath $metadataOnlyVerifierPath `
        -NoTypeInformation -Encoding UTF8
    $metadataOnlySummaryPath = Join-Path $workPath "metadata-only-summary.json"
    $metadataOnlySummary = Get-Content -LiteralPath $progressSummaryPath -Raw |
        ConvertFrom-Json
    $metadataOnlySummary.inputs.verifier_results.path = $metadataOnlyVerifierPath
    $metadataOnlySummary.inputs.verifier_results.sha256 = `
        Get-FileSha256 $metadataOnlyVerifierPath
    $metadataOnlySummary | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $metadataOnlySummaryPath -Encoding UTF8
    $metadataOnlyOutput = Join-Path $outputRoot "metadata-only-output"
    Invoke-ScannerCase -Name "candidate-link-metadata-change" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath $metadataOnlyOutput `
        -CaseCandidatePath $metadataOnlyCandidatePath `
        -CaseVerifierPath $metadataOnlyVerifierPath `
        -CaseProgressSummaryPath $metadataOnlySummaryPath `
        -ExpectedExitCode 0 -ExpectedOutput "Portfolio selected:"
    $metadataOnlyFrozen = Import-Csv -LiteralPath (
        Join-Path $metadataOnlyOutput "wip-residual-dashboard.csv") |
        Where-Object { $_.name -eq "OtFrozenResidual" }
    Assert-Equal $metadataOnlyFrozen.BaselineCandidateFileMatches "False" `
        "Link-metadata-only rebuild must retain a visible file-hash diagnostic"
    Assert-Equal $metadataOnlyFrozen.CurrentCandidateFunctionSha256 `
        $candidateFunctionHashes["OtFrozenResidual"] `
        "Link metadata changed the stable function identity"
    Assert-Equal $metadataOnlyFrozen.BaselineCandidateObjectMatches "True" `
        "Link metadata changed the stable object binding"

    # A relink may alter the value of an already-differing address operand
    # while the compiled object and strict residual stay unchanged.  That
    # linked-function hash is provenance, not a stable freeze identity.
    $relinkedCandidatePath = Join-Path $workPath "relinked-candidate.exe"
    $relinkedCandidateBytes = [System.IO.File]::ReadAllBytes($candidatePath)
    $relinkedCandidateBytes[0x222] = 42
    $relinkedCandidateBytes[0x223] = 10
    [System.IO.File]::WriteAllBytes(
        $relinkedCandidatePath, $relinkedCandidateBytes)
    $relinkedVerifierPath = Join-Path $workPath "relinked-verifier.csv"
    $relinkedVerifier = @(Import-Csv -LiteralPath $verifierPath)
    $relinkedCandidateSha = Get-FileSha256 $relinkedCandidatePath
    foreach ($row in $relinkedVerifier) {
        $row.candidate_path = $relinkedCandidatePath
        $row.candidate_file_sha256 = $relinkedCandidateSha
    }
    ($relinkedVerifier | Where-Object {
        $_.name -eq "OtFrozenResidual"
    }).candidate_sha256 = Get-ByteArraySha256 ([byte[]](5, 6, 42, 10))
    $relinkedVerifier | Export-Csv -LiteralPath $relinkedVerifierPath `
        -NoTypeInformation -Encoding UTF8
    $relinkedSummaryPath = Join-Path $workPath "relinked-summary.json"
    $relinkedSummary = Get-Content -LiteralPath $progressSummaryPath -Raw |
        ConvertFrom-Json
    $relinkedSummary.inputs.verifier_results.path = $relinkedVerifierPath
    $relinkedSummary.inputs.verifier_results.sha256 = `
        Get-FileSha256 $relinkedVerifierPath
    $relinkedSummary | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $relinkedSummaryPath -Encoding UTF8
    $relinkedOutput = Join-Path $outputRoot "relinked-output"
    Invoke-ScannerCase -Name "linked-relocation-value-change" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath $relinkedOutput `
        -CaseCandidatePath $relinkedCandidatePath `
        -CaseVerifierPath $relinkedVerifierPath `
        -CaseProgressSummaryPath $relinkedSummaryPath `
        -ExpectedExitCode 0 -ExpectedOutput "Portfolio selected:"
    $relinkedFrozen = Import-Csv -LiteralPath (
        Join-Path $relinkedOutput "wip-residual-dashboard.csv") |
        Where-Object { $_.name -eq "OtFrozenResidual" }
    Assert-Equal $relinkedFrozen.HardDiffCount 2 `
        "Relink fixture did not change the linked residual count"
    Assert-Equal $relinkedFrozen.BaselineCandidateObjectMatches "True" `
        "Relink lost the stable candidate-object binding"
    Assert-Equal $relinkedFrozen.BoundHardDiffCountMatches "False" `
        "Relink did not expose the residual-count provenance change"
    Assert-Equal $relinkedFrozen.BaselineCandidateFunctionMatches "False" `
        "Relink did not expose the linked-function provenance change"

    $codeDriftDirectory = Join-Path $workPath "code-drift"
    [void][System.IO.Directory]::CreateDirectory($codeDriftDirectory)
    $codeDriftCandidatePath = Join-Path $codeDriftDirectory `
        "code-drift-candidate.exe"
    $codeDriftCandidateBytes = [System.IO.File]::ReadAllBytes($candidatePath)
    $codeDriftCandidateBytes[0x223] = 10
    [System.IO.File]::WriteAllBytes($codeDriftCandidatePath, $codeDriftCandidateBytes)
    $codeDriftObjectPath = Join-Path $codeDriftDirectory $candidateObjectName
    $codeDriftObjectBytes = [System.IO.File]::ReadAllBytes($candidateObjectPath)
    $codeDriftObjectBytes[0] = $codeDriftObjectBytes[0] -bxor 1
    [System.IO.File]::WriteAllBytes($codeDriftObjectPath, $codeDriftObjectBytes)
    $codeDriftVerifierPath = Join-Path $workPath "code-drift-verifier.csv"
    $codeDriftVerifier = @(Import-Csv -LiteralPath $verifierPath)
    $codeDriftCandidateSha = Get-FileSha256 $codeDriftCandidatePath
    foreach ($row in $codeDriftVerifier) {
        $row.candidate_path = $codeDriftCandidatePath
        $row.candidate_file_sha256 = $codeDriftCandidateSha
    }
    ($codeDriftVerifier | Where-Object {
        $_.name -eq "OtFrozenResidual"
    }).candidate_sha256 = Get-ByteArraySha256 ([byte[]](5, 6, 7, 10))
    $codeDriftVerifier | Export-Csv -LiteralPath $codeDriftVerifierPath `
        -NoTypeInformation -Encoding UTF8
    $codeDriftSummaryPath = Join-Path $workPath "code-drift-summary.json"
    $codeDriftSummary = Get-Content -LiteralPath $progressSummaryPath -Raw |
        ConvertFrom-Json
    $codeDriftSummary.inputs.verifier_results.path = $codeDriftVerifierPath
    $codeDriftSummary.inputs.verifier_results.sha256 = `
        Get-FileSha256 $codeDriftVerifierPath
    $codeDriftSummary | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $codeDriftSummaryPath -Encoding UTF8
    Invoke-ScannerCase -Name "candidate-object-code-drift" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "code-drift-output") `
        -CaseCandidatePath $codeDriftCandidatePath `
        -CaseVerifierPath $codeDriftVerifierPath `
        -CaseProgressSummaryPath $codeDriftSummaryPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "candidate object SHA-256 changed"

    $promotionVerifierPath = Join-Path $workPath "promotion-verifier.csv"
    $promotionVerifier = @(Import-Csv -LiteralPath $verifierPath)
    $promotionRow = $promotionVerifier | Where-Object {
        $_.name -eq "OtFrozenResidual"
    }
    $promotionRow.actual_status = "match"
    $promotionRow.status = "match"
    $promotionRow.verification_status = "promotion_ready"
    $promotionRow.promotion_ready = "True"
    $promotionRow.first_diff = ""
    $promotionRow.raw_match = "True"
    $promotionVerifier | Export-Csv -LiteralPath $promotionVerifierPath `
        -NoTypeInformation -Encoding UTF8

    $promotionSummaryPath = Join-Path $workPath "promotion-progress-summary.json"
    $promotionSummary = Get-Content -LiteralPath $progressSummaryPath -Raw |
        ConvertFrom-Json
    $promotionSummary.inputs.verifier_results.path = $promotionVerifierPath
    $promotionSummary.inputs.verifier_results.sha256 = Get-FileSha256 $promotionVerifierPath
    $promotionSummary | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $promotionSummaryPath -Encoding UTF8
    Invoke-ScannerCase -Name "promotion-ready-stale-freeze" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "promotion-stale-freeze-output") `
        -CaseVerifierPath $promotionVerifierPath `
        -CaseProgressSummaryPath $promotionSummaryPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "is promotion-ready; its freeze is stale and must be reviewed"

    $shortfallOutput = Join-Path $outputRoot "shortfall-output"
    Invoke-ScannerCase -Name "portfolio-shortfall" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath $shortfallOutput `
        -CasePortfolioTargetInstructions 1000 `
        -CaseAllowIncompleteAssignments `
        -ExpectedExitCode 1 -ExpectedOutput "Recovery portfolio is short by"
    Assert-True (Test-Path -LiteralPath (
            Join-Path $shortfallOutput "wip-residual-dashboard.csv") -PathType Leaf) `
        "Portfolio shortfall did not preserve its diagnostic dashboard."

    Invoke-ScannerCase -Name "portfolio-shortfall-explicit-diagnostic" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "shortfall-allowed-output") `
        -CasePortfolioTargetInstructions 1000 `
        -CaseAllowIncompleteAssignments `
        -CaseAllowPortfolioShortfall `
        -ExpectedExitCode 0 -ExpectedOutput "Portfolio selected:"

    Invoke-ScannerCase -Name "undersized-explicit-portfolio" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "undersized-target-output") `
        -CasePortfolioTargetInstructions 1 `
        -ExpectedExitCode 1 `
        -ExpectedOutput "cannot reduce the automatic 75-instruction recovery floor"

    Invoke-ScannerCase -Name "sub-150-percent-policy" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "small-multiplier-output") `
        -CasePortfolioMultiplier 1.0 `
        -ExpectedExitCode 1 `
        -ExpectedOutput "requires five-point checkpoints and a portfolio multiplier of at least 1.5"

    Invoke-ScannerCase -Name "non-five-point-policy" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "small-step-output") `
        -CaseCheckpointStepPercent 1.0 `
        -ExpectedExitCode 1 `
        -ExpectedOutput "requires five-point checkpoints and a portfolio multiplier of at least 1.5"

    Invoke-ScannerCase -Name "nonstandard-policy-explicit-diagnostic" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "nonstandard-allowed-output") `
        -CaseCheckpointStepPercent 1.0 `
        -CasePortfolioMultiplier 1.0 `
        -CasePortfolioTargetInstructions 1 `
        -CaseAllowNonstandardPortfolioPolicy `
        -ExpectedExitCode 0 -ExpectedOutput "Portfolio target:      1 instructions"

    $staleSummaryPath = Join-Path $workPath "stale-progress-summary.json"
    $staleSummary = Get-Content -LiteralPath $progressSummaryPath -Raw |
        ConvertFrom-Json
    $staleSummary.inputs.verifier_results.sha256 = "0" * 64
    $staleSummary | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $staleSummaryPath -Encoding UTF8
    Invoke-ScannerCase -Name "stale-progress-summary" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "stale-summary-output") `
        -CaseProgressSummaryPath $staleSummaryPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "Stale progress metrics summary: verifier results SHA-256 changed"

    $locatorMismatchVerifierPath = Join-Path $workPath "locator-mismatch-verifier.csv"
    $locatorMismatchVerifier = @(Import-Csv -LiteralPath $verifierPath)
    $locatorMismatchVerifier[0].candidate_object_qualifier = "wrong.obj"
    $locatorMismatchVerifier | Export-Csv -LiteralPath $locatorMismatchVerifierPath `
        -NoTypeInformation -Encoding UTF8
    Invoke-ScannerCase -Name "verifier-locator-mismatch" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $outputRoot "locator-mismatch-output") `
        -CaseVerifierPath $locatorMismatchVerifierPath `
        -ExpectedExitCode 1 `
        -ExpectedOutput "Verifier candidate_object qualifier does not match manifest row"

    $junctionTarget = Join-Path $workPath "junction-target"
    [void][System.IO.Directory]::CreateDirectory($junctionTarget)
    $junctionPath = Join-Path $outputRoot "output-junction"
    [void](New-Item -ItemType Junction -Path $junctionPath -Target $junctionTarget)
    Invoke-ScannerCase -Name "output-junction-escape" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath (Join-Path $junctionPath "escaped-output") `
        -ExpectedExitCode 1 `
        -ExpectedOutput "OutputDirectory cannot traverse reparse point"
    Assert-True (-not (Test-Path -LiteralPath (
            Join-Path $junctionTarget "escaped-output") -PathType Container)) `
        "Rejected output junction still created a directory outside the ignored root."
    [System.IO.Directory]::Delete($junctionPath)
    $junctionPath = ""

    Invoke-ScannerCase -Name "unsafe-output-root" `
        -CaseManifestPath $manifestPath -CaseMetricsPath $metricsPath `
        -CaseOutputPath $unsafeOutput `
        -ExpectedExitCode 1 `
        -ExpectedOutput "OutputDirectory must resolve beneath the repository's ignored"
    Assert-True (-not (Test-Path -LiteralPath $unsafeOutput)) `
        "Unsafe output-root rejection still mutated the repository."

    Write-Host "WIP queue ranking contract: PASS"
}
finally {
    if (-not [string]::IsNullOrWhiteSpace($junctionPath) -and
        (Test-Path -LiteralPath $junctionPath)) {
        [System.IO.Directory]::Delete($junctionPath)
    }
    if (Test-Path -LiteralPath $workPath -PathType Container) {
        Remove-Item -LiteralPath $workPath -Recurse -Force
    }
    if (Test-Path -LiteralPath $outputRoot -PathType Container) {
        Remove-Item -LiteralPath $outputRoot -Recurse -Force
    }
    if (Test-Path -LiteralPath $unsafeOutput -PathType Container) {
        Remove-Item -LiteralPath $unsafeOutput -Recurse -Force
    }
}
