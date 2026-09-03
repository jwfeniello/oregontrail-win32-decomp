[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$generatorPath = (Resolve-Path (Join-Path $PSScriptRoot `
    "generate-function-dossier.ps1")).Path
$shellPath = (Get-Process -Id $PID).Path
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$contractId = [guid]::NewGuid().ToString("N")
$outputRoot = Join-Path $repoRoot (Join-Path "a" (
    "otmatch-function-dossier-contract-" + $contractId))
$fixtureRoot = Join-Path $outputRoot "fixture"
$unsafeOutput = Join-Path $repoRoot (
    "docs\otmatch-function-dossier-contract-unsafe-" + $contractId)

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

function Get-FileSha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Write-Utf8([string]$Path, [string]$Text) {
    [void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $Path))
    [System.IO.File]::WriteAllText($Path, $Text, $utf8NoBom)
}

function Write-CsvFixture([string]$Path, [object[]]$Rows) {
    $text = (@($Rows | ConvertTo-Csv -NoTypeInformation) -join "`n") + "`n"
    Write-Utf8 $Path $text
}

function Write-JsonFixture([string]$Path, $Value) {
    Write-Utf8 $Path (($Value | ConvertTo-Json -Depth 20) + "`n")
}

function Get-RepoRelativePath([string]$Path) {
    $resolved = [System.IO.Path]::GetFullPath($Path)
    $prefix = $repoRoot.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith(
            $prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Contract fixture is outside the repository: '$resolved'."
    }
    return $resolved.Substring($prefix.Length).Replace('\', '/')
}

function Get-ObjectName([string]$Path) {
    return ((Get-RepoRelativePath $Path) -replace '/', '_' -replace
        '\.cpp$', '.obj')
}

function Invoke-DossierCase(
    [string]$Name,
    [string]$CaseManifestPath,
    [string]$CaseVerifierPath,
    [string]$CaseOutputDirectory,
    [int]$ExpectedExitCode,
    [string]$ExpectedOutput,
    [string]$CaseMetricsPath = "",
    [string]$CaseMaskPath = "",
    [string]$CaseFrozenPath = "",
    [string]$CaseSessionPath = "",
    [string]$CaseReadinessPath = "",
    [string]$CaseProductPath = "",
    [string]$CaseTuPath = "",
    [string]$CaseSourceRoot = "",
    [string]$CaseGhidraRoot = "",
    [string[]]$CaseNotesRoot = @(),
    [string]$CaseOutputBaseName = "") {

    $arguments = @(
        "-NoProfile", "-ExecutionPolicy", "Bypass",
        "-File", $generatorPath,
        "-FunctionName", "OtContractTarget",
        "-Program", "Oregon32.exe",
        "-ManifestPath", $CaseManifestPath,
        "-VerifierResultsPath", $CaseVerifierPath,
        "-OutputDirectory", $CaseOutputDirectory)
    if (-not [string]::IsNullOrWhiteSpace($CaseOutputBaseName)) {
        $arguments += @("-OutputBaseName", $CaseOutputBaseName)
    }
    if (-not [string]::IsNullOrWhiteSpace($CaseMetricsPath)) {
        $arguments += @("-ProgressMetricsSummaryPath", $CaseMetricsPath)
    }
    if (-not [string]::IsNullOrWhiteSpace($CaseMaskPath)) {
        $arguments += @("-MaskAuditResultsPath", $CaseMaskPath)
    }
    if (-not [string]::IsNullOrWhiteSpace($CaseFrozenPath)) {
        $arguments += @("-FrozenWipPath", $CaseFrozenPath)
    }
    if (-not [string]::IsNullOrWhiteSpace($CaseSessionPath)) {
        $arguments += @("-SessionLaneLedgerPath", $CaseSessionPath)
    }
    if (-not [string]::IsNullOrWhiteSpace($CaseReadinessPath)) {
        $arguments += @("-ReadinessLedgerPath", $CaseReadinessPath)
    }
    if (-not [string]::IsNullOrWhiteSpace($CaseProductPath)) {
        $arguments += @("-ExeProductSourceManifestPath", $CaseProductPath)
    }
    if (-not [string]::IsNullOrWhiteSpace($CaseTuPath)) {
        $arguments += @("-TuMetadataPath", $CaseTuPath)
    }
    if (-not [string]::IsNullOrWhiteSpace($CaseSourceRoot)) {
        $arguments += @("-SourceRoot", $CaseSourceRoot)
    }
    if (-not [string]::IsNullOrWhiteSpace($CaseGhidraRoot)) {
        $arguments += @("-GhidraOutputDirectory", $CaseGhidraRoot)
    }
    if ($CaseNotesRoot.Count -gt 0) {
        $arguments += "-RecoveryNotesRoot"
        $arguments += $CaseNotesRoot
    }

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $shellPath @arguments 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
    $text = $output -join [Environment]::NewLine
    if ($exitCode -ne $ExpectedExitCode) {
        throw ("{0}: expected exit {1}, got {2}. Output: {3}" -f
            $Name, $ExpectedExitCode, $exitCode, $text)
    }
    if ($text -notmatch [regex]::Escape($ExpectedOutput)) {
        throw ("{0}: output did not contain '{1}'. Output: {2}" -f
            $Name, $ExpectedOutput, $text)
    }
    Write-Host ("PASS {0}: exit={1}" -f $Name, $exitCode)
}

function New-VerifierRows(
    [string]$ManifestFile,
    [string]$OriginalFile,
    [string]$CandidateFile,
    [string]$CandidateMapFile,
    [string]$Schema = "4",
    [switch]$OnlyDependency) {

    $manifestSha = Get-FileSha256 $ManifestFile
    $common = [ordered]@{
        result_schema_version = $Schema
        manifest_path = $ManifestFile
        manifest_sha256 = $ManifestSha
        status = "mismatch"
        actual_status = "mismatch"
        expected_status = "wip"
        verification_status = "allowed_wip"
        promotion_ready = "False"
        implementation_kind = "cpp"
        original_path = $OriginalFile
        original_file_sha256 = Get-FileSha256 $OriginalFile
        candidate_path = $CandidateFile
        candidate_file_sha256 = Get-FileSha256 $CandidateFile
        candidate_map_path = $CandidateMapFile
        candidate_map_sha256 = Get-FileSha256 $CandidateMapFile
        candidate_locator_kind = "candidate_symbol"
        candidate_dll = ""
        mask_bytes = "4"
        compared_bytes = "12"
        raw_match = "False"
        raw_first_diff = "0x00000000"
        first_diff = "0x00000004"
        original_raw_sha256 = ("6" * 64)
        candidate_raw_sha256 = ("5" * 64)
        original_sha256 = ("4" * 64)
        candidate_sha256 = ("3" * 64)
        mask_shape_valid = "True"
        masked_operand_shape_error = ""
        masked_import_identity_error = ""
        error_message = ""
        notes = "Synthetic verifier note"
    }
    $target = [pscustomobject][ordered]@{}
    foreach ($entry in $common.GetEnumerator()) {
        $target | Add-Member -NotePropertyName $entry.Key `
            -NotePropertyValue $entry.Value
    }
    $target | Add-Member row_index "1"
    $target | Add-Member name "OtContractTarget"
    $target | Add-Member program "Oregon32.exe"
    $target | Add-Member original_rva "0x00001000"
    $target | Add-Member candidate_symbol "_OtContractTarget_00401000_Wip"
    $target | Add-Member candidate_object $script:targetObject
    $target | Add-Member candidate_locator "_OtContractTarget_00401000_Wip"
    $target | Add-Member candidate_object_qualifier $script:targetObject
    $target | Add-Member candidate_rva "0x00002000"
    $target | Add-Member size "16"
    $target | Add-Member mask "0-3"

    $dependency = $target.PSObject.Copy()
    $dependency.row_index = "2"
    $dependency.name = "OtContractDependency"
    $dependency.original_rva = "0x00001010"
    $dependency.candidate_symbol = "_OtContractDependency_00401010_Wip"
    $dependency.candidate_locator = "_OtContractDependency_00401010_Wip"
    $dependency.candidate_rva = "0x00002010"
    $dependency.mask = ""
    $dependency.mask_bytes = "0"
    $dependency.compared_bytes = "16"
    if ($OnlyDependency) {
        return @($dependency)
    }
    return @($target, $dependency)
}

try {
    [void][System.IO.Directory]::CreateDirectory($fixtureRoot)
    $sourceRoot = Join-Path $fixtureRoot "src\otwin"
    $targetSource = Join-Path $sourceRoot "trail\target.cpp"
    $notesRoot = Join-Path $fixtureRoot "notes"
    $notePath = Join-Path $notesRoot "target-notes.md"
    $ghidraRoot = Join-Path $fixtureRoot "ghidra"
    $ghidraPath = Join-Path $ghidraRoot "synthetic_decompile.c"
    $emptyRoot = Join-Path $fixtureRoot "empty"
    $manifestPath = Join-Path $fixtureRoot "manifest.csv"
    $verifierPath = Join-Path $fixtureRoot "verifier.csv"
    $originalEvidencePath = Join-Path $fixtureRoot "synthetic-original.exe"
    $candidateEvidencePath = Join-Path $fixtureRoot "synthetic-candidate.dll"
    $candidateMapEvidencePath = Join-Path $fixtureRoot "synthetic-candidate.map"
    $maskPath = Join-Path $fixtureRoot "mask-audit.csv"
    $functionMetricsPath = Join-Path $fixtureRoot "function-metrics.csv"
    $productPath = Join-Path $fixtureRoot "product-sources.txt"
    $reporterPath = Join-Path $fixtureRoot "synthetic-reporter.ps1"
    $metricsPath = Join-Path $fixtureRoot "progress-metrics-summary.json"
    $tuPath = Join-Path $fixtureRoot "vc4-tu-metadata.csv"
    $frozenPath = Join-Path $fixtureRoot "frozen.csv"
    $sessionPath = Join-Path $fixtureRoot "session.json"
    $readinessPath = Join-Path $fixtureRoot "readiness.json"
    $sessionEvidencePath = Join-Path $fixtureRoot "session-evidence.md"
    $readinessEvidencePath = Join-Path $fixtureRoot "readiness-evidence.md"
    $outputDirectory = Join-Path $outputRoot "output"
    $minimalOutputDirectory = Join-Path $outputRoot "minimal-output"
    $ambiguousOutputDirectory = Join-Path $outputRoot "ambiguous-output"
    $missingOutputDirectory = Join-Path $outputRoot "missing-output"
    $schemaOutputDirectory = Join-Path $outputRoot "schema-output"
    $binaryOutputDirectory = Join-Path $outputRoot "binary-output"
    [void][System.IO.Directory]::CreateDirectory($emptyRoot)

    Write-Utf8 $targetSource @'
// Pure synthetic contract fixture. No original game bytes are present.
extern "C" int _OtContractDependency_00401010_Wip();
extern "C" int _OtContractTarget_00401000_Wip()
{
    return _OtContractDependency_00401010_Wip();
}
'@
    $script:targetObject = Get-ObjectName $targetSource
    Write-Utf8 $notePath @'
# OtContractTarget recovery note

Synthetic semantic/type/ABI notes for FUN_00401000 at 0x00001000.
'@
    Write-Utf8 $ghidraPath @'
/* DO_NOT_LEAK_SYNTHETIC_DECOMPILE_BODY_SENTINEL */
// Function: FUN_00401000 @ 00401000
void FUN_00401000(void)
{
  FUN_00401010();
  CreateWindowA();
}

// Function: FUN_00401010 @ 00401010
void FUN_00401010(void)
{
}
'@
    Write-Utf8 $sessionEvidencePath "Synthetic session evidence.`n"
    Write-Utf8 $readinessEvidencePath "Synthetic readiness evidence.`n"
    Write-Utf8 $reporterPath "# Synthetic reporter evidence only.`n"
    Write-Utf8 $originalEvidencePath `
        "DO_NOT_LEAK_SYNTHETIC_ORIGINAL_BODY_SENTINEL`n"
    Write-Utf8 $candidateEvidencePath `
        "DO_NOT_LEAK_SYNTHETIC_CANDIDATE_BODY_SENTINEL`n"
    Write-Utf8 $candidateMapEvidencePath `
        "DO_NOT_LEAK_SYNTHETIC_MAP_BODY_SENTINEL`n"

    $manifestRows = @(
        [pscustomobject][ordered]@{
            name = "OtContractTarget"; program = "Oregon32.exe"
            original_va = "0x00401000"; original_rva = "0x00001000"
            size = "0x00000010"; candidate_va = ""; candidate_rva = ""
            candidate_symbol = "_OtContractTarget_00401000_Wip"
            candidate_dll = ""; candidate_object = $script:targetObject
            expected_status = "wip"; implementation_kind = "cpp"
            mask = "0-3"; notes = "Synthetic semantic WIP target."
        },
        [pscustomobject][ordered]@{
            name = "OtContractDependency"; program = "Oregon32.exe"
            original_va = "0x00401010"; original_rva = "0x00001010"
            size = "0x00000010"; candidate_va = ""; candidate_rva = ""
            candidate_symbol = "_OtContractDependency_00401010_Wip"
            candidate_dll = ""; candidate_object = $script:targetObject
            expected_status = "wip"; implementation_kind = "cpp"
            mask = ""; notes = "Synthetic dependency."
        })
    Write-CsvFixture $manifestPath $manifestRows
    Write-CsvFixture $verifierPath (New-VerifierRows `
        $manifestPath $originalEvidencePath $candidateEvidencePath `
        $candidateMapEvidencePath)
    Write-CsvFixture $maskPath @(
        [pscustomobject][ordered]@{
            name = "OtContractTarget"; program = "Oregon32.exe"
            original_rva = "0x00001000"; function_size = "16"
            expected_status = "wip"; implementation_kind = "cpp"
            mask = "0-3"; range_start = "0"; range_end = "3"
            range_length = "4"; classification = "full_known_address_operand"
            issue = ""; validated_bytes = "4"; partial_known_bytes = "0"
            unexplained_bytes = "0"; operand_count = "1"
            operand_kinds = "highlow"; operand_ranges = "0-3:highlow"
            full_function_mask = "False"; notes = "Synthetic mask evidence."
        })
    Write-CsvFixture $functionMetricsPath @(
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"; name = "FUN_00401000"
            original_va = "0x00401000"; original_rva = "0x00001000"
            size = "0x10"; instruction_count = "7"; body_bytes = "16"
            block = ".text"; notes = ""
        },
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"; name = "FUN_00401010"
            original_va = "0x00401010"; original_rva = "0x00001010"
            size = "0x10"; instruction_count = "3"; body_bytes = "16"
            block = ".text"; notes = ""
        })
    $targetRelative = Get-RepoRelativePath $targetSource
    Write-Utf8 $productPath ($targetRelative + "`n")
    Write-CsvFixture $tuPath @(
        [pscustomobject][ordered]@{
            source_path = $targetRelative
            extra_compile_flags = "/O1 /GX"
        })

    $metricsSummary = [pscustomobject][ordered]@{
        schema_version = 2
        inputs = [pscustomobject][ordered]@{
            manifest = [pscustomobject][ordered]@{
                path = $manifestPath; sha256 = Get-FileSha256 $manifestPath
            }
            verifier_results = [pscustomobject][ordered]@{
                path = $verifierPath; sha256 = Get-FileSha256 $verifierPath
            }
            mask_audit_results = [pscustomobject][ordered]@{
                path = $maskPath; sha256 = Get-FileSha256 $maskPath
            }
            function_metrics = @([pscustomobject][ordered]@{
                path = $functionMetricsPath
                sha256 = Get-FileSha256 $functionMetricsPath
            })
            exe_product_sources = [pscustomobject][ordered]@{
                path = $productPath; sha256 = Get-FileSha256 $productPath
            }
            metrics_reporter = [pscustomobject][ordered]@{
                path = $reporterPath; sha256 = Get-FileSha256 $reporterPath
            }
        }
        denominator = [pscustomobject][ordered]@{
            identity_sha256 = ("1" * 64); function_count = 2
            instruction_count = 10; body_byte_count = 32
            body_ownership_sha256 = ("3" * 64); body_range_count = 2
        }
        strict = [pscustomobject][ordered]@{
            accepted_identity_sha256 = ("2" * 64)
            accepted_identity_count = 0; accepted_identities = @()
            accepted_instructions = 0; accepted_body_bytes = 0
            instruction_percent = 50.25
        }
    }
    Write-JsonFixture $metricsPath $metricsSummary

    $checkpointInputs = [pscustomobject][ordered]@{
        manifest_sha256 = Get-FileSha256 $manifestPath
        verifier_results_sha256 = Get-FileSha256 $verifierPath
        progress_metrics_summary_sha256 = Get-FileSha256 $metricsPath
        candidate_file_sha256 = ("a" * 64)
        candidate_map_sha256 = ("b" * 64)
        original_exe_sha256 = ("c" * 64)
        original_dll_sha256 = ("d" * 64)
    }
    Write-CsvFixture $frozenPath @(
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"; original_rva = "0x00001000"
            name = "OtContractTarget"; frozen = "false"
            freeze_date = "2026-07-17"; confidence = "0.5"; effort = "2"
            evidence_path = $notePath; evidence_sha256 = Get-FileSha256 $notePath
            source_path = $targetSource
            source_sha256 = Get-FileSha256 $targetSource
            meaningful_variant_count = "3"; residual_kind = "strict-linked"
            hard_diff_count = "2"; compared_bytes = "12"
            baseline_original_sha256 = ("4" * 64)
            baseline_candidate_sha256 = ("5" * 64)
            baseline_candidate_object = "contract.obj"
            baseline_candidate_object_sha256 = ("6" * 64)
            baseline_candidate_function_sha256 = ("3" * 64)
            diagnostic_note = "Synthetic diagnostic."
            reason = "Below permanent-freeze evidence threshold."
            revisit_condition = "Review after a new type hypothesis."
        })
    Write-JsonFixture $sessionPath ([pscustomobject][ordered]@{
        schema_version = 1; session_id = "contract-session"
        inputs = $checkpointInputs
        rows = @([pscustomobject][ordered]@{
            program = "Oregon32.exe"; original_rva = "0x00001000"
            name = "OtContractTarget"; state = "active"
            hypothesis = "Synthetic source-shape hypothesis."
            meaningful_variant_count = 3; active_recovery_minutes = 12
            evidence_path = $sessionEvidencePath
            evidence_sha256 = Get-FileSha256 $sessionEvidencePath
            source_path = $targetSource
            source_sha256 = Get-FileSha256 $targetSource
        })
    })
    Write-JsonFixture $readinessPath ([pscustomobject][ordered]@{
        schema_version = 1; session_id = "contract-session"
        inputs = $checkpointInputs
        rows = @([pscustomobject][ordered]@{
            program = "Oregon32.exe"; original_rva = "0x00001000"
            name = "OtContractTarget"; readiness = "ready"
            dependency_state = "ready"; confidence = 0.8; effort = 2
            candidate_body_bytes = 16; candidate_instruction_count = 7
            reason = "Synthetic Product implementation and dependencies exist."
            evidence_path = $readinessEvidencePath
            evidence_sha256 = Get-FileSha256 $readinessEvidencePath
        })
    })

    $happyArguments = @{
        Name = "complete-evidence"
        CaseManifestPath = $manifestPath
        CaseVerifierPath = $verifierPath
        CaseOutputDirectory = $outputDirectory
        ExpectedExitCode = 0
        ExpectedOutput = "Function dossier generated"
        CaseMetricsPath = $metricsPath
        CaseMaskPath = $maskPath
        CaseFrozenPath = $frozenPath
        CaseSessionPath = $sessionPath
        CaseReadinessPath = $readinessPath
        CaseProductPath = $productPath
        CaseTuPath = $tuPath
        CaseSourceRoot = $sourceRoot
        CaseGhidraRoot = $ghidraRoot
        CaseNotesRoot = @($notesRoot)
    }
    Invoke-DossierCase @happyArguments

    $jsonPath = Join-Path $outputDirectory `
        "Oregon32.exe-OtContractTarget-dossier.json"
    $markdownPath = Join-Path $outputDirectory `
        "Oregon32.exe-OtContractTarget-dossier.md"
    Assert-True (Test-Path -LiteralPath $jsonPath -PathType Leaf) `
        "JSON dossier was not published."
    Assert-True (Test-Path -LiteralPath $markdownPath -PathType Leaf) `
        "Markdown dossier was not published."
    $dossier = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
    Assert-Equal $dossier.schema_version 1 "Dossier schema"
    Assert-Equal $dossier.generator.name "otmatch-function-dossier" `
        "Generator provenance name"
    Assert-Equal $dossier.generator.schema_version 1 `
        "Generator provenance schema"
    Assert-Equal $dossier.generator.script_path `
        "tools/otmatch/generate-function-dossier.ps1" `
        "Generator provenance path"
    Assert-Equal $dossier.generator.script_sha256 `
        (Get-FileSha256 $generatorPath) "Generator provenance hash"
    Assert-Equal $dossier.identity.key "oregon32.exe|0x1000" `
        "Canonical identity"
    Assert-Equal $dossier.verifier.result_schema_version 4 `
        "Verifier schema binding"
    Assert-Equal $dossier.verifier.actual_status "mismatch" `
        "Matcher-shaped actual status"
    Assert-Equal $dossier.verifier.verification_status "allowed_wip" `
        "Matcher-shaped verification status"
    Assert-Equal $dossier.verifier.provenance_complete True `
        "Verifier file provenance completeness"
    Assert-Equal $dossier.verifier.original_file.sha256 `
        (Get-FileSha256 $originalEvidencePath) "Original provenance hash"
    Assert-Equal $dossier.verifier.candidate_file.sha256 `
        (Get-FileSha256 $candidateEvidencePath) "Candidate provenance hash"
    Assert-Equal $dossier.verifier.candidate_map.sha256 `
        (Get-FileSha256 $candidateMapEvidencePath) "Candidate-map provenance hash"
    Assert-Equal $dossier.metrics.function_instruction_count 7 `
        "Function-metrics join"
    Assert-Equal @($dossier.sources).Count 1 "Candidate source discovery"
    Assert-Equal $dossier.sources[0].product_reachable True `
        "Product reachability"
    Assert-Equal $dossier.sources[0].extra_compile_flags "/O1 /GX" `
        "Centralized TU flags"
    Assert-Equal @($dossier.decompilation.anchors).Count 1 `
        "Ghidra anchor count"
    $dependency = @($dossier.decompilation.direct_call_hints | Where-Object {
        $_.symbol -eq "FUN_00401010"
    })
    Assert-Equal $dependency.Count 1 "Direct-call dependency extraction"
    Assert-Equal $dependency[0].manifest_name "OtContractDependency" `
        "Direct-call manifest join"
    Assert-Equal $dossier.promotion_review.identity_key $dossier.identity.key `
        "Promotion-review identity binding"
    Assert-Equal $dossier.promotion_review.status "pending" `
        "Promotion-review default status"
    foreach ($reviewCategory in @("semantic", "type_layout", "abi", "mask")) {
        Assert-Equal $dossier.promotion_review.$reviewCategory.passed False `
            "Promotion-review fail-safe $reviewCategory default"
        Assert-Equal $dossier.promotion_review.$reviewCategory.note "" `
            "Promotion-review empty $reviewCategory note"
    }
    Assert-Equal $dossier.promotion_review.warnings_disposition.status `
        "pending" "Promotion warning-disposition default"
    Assert-Equal @($dossier.promotion_review.warnings_disposition.
        resolved_warnings).Count 0 "Promotion warning-resolution default"
    Assert-True (@($dossier.evidence).Count -ge 12) `
        "Expected evidence files were not hash-bound."
    foreach ($evidence in @($dossier.evidence)) {
        $evidencePath = if ([System.IO.Path]::IsPathRooted([string]$evidence.path)) {
            [string]$evidence.path
        }
        else {
            Join-Path $repoRoot ([string]$evidence.path).Replace('/', '\')
        }
        Assert-Equal (Get-FileSha256 $evidencePath) $evidence.sha256 `
            "Evidence hash for $($evidence.path)"
    }
    $publishedText = (Get-Content -LiteralPath $jsonPath -Raw) +
        (Get-Content -LiteralPath $markdownPath -Raw)
    foreach ($sentinel in @(
            "DO_NOT_LEAK_SYNTHETIC_ORIGINAL_BODY_SENTINEL",
            "DO_NOT_LEAK_SYNTHETIC_CANDIDATE_BODY_SENTINEL",
            "DO_NOT_LEAK_SYNTHETIC_MAP_BODY_SENTINEL",
            "DO_NOT_LEAK_SYNTHETIC_DECOMPILE_BODY_SENTINEL")) {
        Assert-True ($publishedText -notmatch [regex]::Escape($sentinel)) `
            "Dossier leaked non-dossier evidence content '$sentinel'."
    }

    $firstJsonHash = Get-FileSha256 $jsonPath
    $firstMarkdownHash = Get-FileSha256 $markdownPath
    Invoke-DossierCase @happyArguments
    Assert-Equal (Get-FileSha256 $jsonPath) $firstJsonHash `
        "Deterministic JSON output"
    Assert-Equal (Get-FileSha256 $markdownPath) $firstMarkdownHash `
        "Deterministic Markdown output"
    Assert-Equal @(Get-ChildItem -LiteralPath $outputDirectory -Filter '*.tmp.*' `
        -File).Count 0 "Atomic temporary-file cleanup"

    $jsonAliasCases = @(
        [pscustomobject]@{
            Name = "metrics-json-input-alias"
            InputPath = $metricsPath
            BaseName = "progress-metrics-summary"
        },
        [pscustomobject]@{
            Name = "session-json-input-alias"
            InputPath = $sessionPath
            BaseName = "session"
        },
        [pscustomobject]@{
            Name = "readiness-json-input-alias"
            InputPath = $readinessPath
            BaseName = "readiness"
        })
    foreach ($aliasCase in $jsonAliasCases) {
        $companionPath = Join-Path $fixtureRoot ($aliasCase.BaseName + ".md")
        Write-Utf8 $companionPath ("Preserve companion for {0}.`n" -f
            $aliasCase.Name)
        $inputHashBefore = Get-FileSha256 $aliasCase.InputPath
        $companionHashBefore = Get-FileSha256 $companionPath
        $aliasArguments = $happyArguments.Clone()
        $aliasArguments.Name = $aliasCase.Name
        $aliasArguments.CaseOutputDirectory = $fixtureRoot
        $aliasArguments.CaseOutputBaseName = $aliasCase.BaseName
        $aliasArguments.ExpectedExitCode = 1
        $aliasArguments.ExpectedOutput = "aliases an evidence input"
        Invoke-DossierCase @aliasArguments
        Assert-Equal (Get-FileSha256 $aliasCase.InputPath) $inputHashBefore `
            "$($aliasCase.Name) preserved aliased JSON input"
        Assert-Equal (Get-FileSha256 $companionPath) $companionHashBefore `
            "$($aliasCase.Name) preserved planned Markdown companion"
    }

    $markdownAliasJsonCompanion = Join-Path $notesRoot "target-notes.json"
    Write-Utf8 $markdownAliasJsonCompanion `
        "Preserve planned JSON companion for Markdown alias.`n"
    $noteHashBefore = Get-FileSha256 $notePath
    $markdownAliasJsonHashBefore = Get-FileSha256 $markdownAliasJsonCompanion
    $markdownAliasArguments = $happyArguments.Clone()
    $markdownAliasArguments.Name = "markdown-evidence-alias"
    $markdownAliasArguments.CaseOutputDirectory = $notesRoot
    $markdownAliasArguments.CaseOutputBaseName = "target-notes"
    $markdownAliasArguments.ExpectedExitCode = 1
    $markdownAliasArguments.ExpectedOutput = "aliases an evidence input"
    Invoke-DossierCase @markdownAliasArguments
    Assert-Equal (Get-FileSha256 $notePath) $noteHashBefore `
        "Markdown alias preserved linked recovery-note evidence"
    Assert-Equal (Get-FileSha256 $markdownAliasJsonCompanion) `
        $markdownAliasJsonHashBefore `
        "Markdown alias preserved planned JSON companion"

    $sessionEvidenceOriginal = Get-Content -LiteralPath $sessionEvidencePath -Raw
    Write-Utf8 $sessionEvidencePath "Mutated without ledger hash update.`n"
    Invoke-DossierCase -Name "stale-linked-evidence" `
        -CaseManifestPath $manifestPath -CaseVerifierPath $verifierPath `
        -CaseOutputDirectory $outputDirectory -ExpectedExitCode 1 `
        -ExpectedOutput "Session lane evidence is stale" `
        -CaseMetricsPath $metricsPath -CaseMaskPath $maskPath `
        -CaseFrozenPath $frozenPath -CaseSessionPath $sessionPath `
        -CaseReadinessPath $readinessPath -CaseProductPath $productPath `
        -CaseTuPath $tuPath -CaseSourceRoot $sourceRoot `
        -CaseGhidraRoot $ghidraRoot -CaseNotesRoot @($notesRoot)
    Assert-Equal (Get-FileSha256 $jsonPath) $firstJsonHash `
        "Failed preflight preserved prior JSON output"
    Assert-Equal (Get-FileSha256 $markdownPath) $firstMarkdownHash `
        "Failed preflight preserved prior Markdown output"
    Write-Utf8 $sessionEvidencePath $sessionEvidenceOriginal

    $candidateEvidenceOriginal = Get-Content -LiteralPath `
        $candidateEvidencePath -Raw
    Write-Utf8 $candidateEvidencePath `
        "Mutated candidate after verifier publication.`n"
    Invoke-DossierCase -Name "stale-verifier-file-provenance" `
        -CaseManifestPath $manifestPath -CaseVerifierPath $verifierPath `
        -CaseOutputDirectory $outputDirectory -ExpectedExitCode 1 `
        -ExpectedOutput "Stale Verifier candidate file provenance" `
        -CaseMetricsPath $metricsPath -CaseMaskPath $maskPath `
        -CaseFrozenPath $frozenPath -CaseSessionPath $sessionPath `
        -CaseReadinessPath $readinessPath -CaseProductPath $productPath `
        -CaseTuPath $tuPath -CaseSourceRoot $sourceRoot `
        -CaseGhidraRoot $ghidraRoot -CaseNotesRoot @($notesRoot)
    Write-Utf8 $candidateEvidencePath $candidateEvidenceOriginal

    $promotionVerifierPath = Join-Path $fixtureRoot `
        "promotion-ready-verifier.csv"
    $promotionRows = @(New-VerifierRows $manifestPath $originalEvidencePath `
        $candidateEvidencePath $candidateMapEvidencePath)
    $promotionRows[0].status = "match"
    $promotionRows[0].actual_status = "match"
    $promotionRows[0].verification_status = "promotion_ready"
    $promotionRows[0].promotion_ready = "True"
    $promotionRows[0].first_diff = ""
    $promotionRows[0].candidate_sha256 = $promotionRows[0].original_sha256
    Write-CsvFixture $promotionVerifierPath $promotionRows
    Invoke-DossierCase -Name "promotion-ready-status" `
        -CaseManifestPath $manifestPath -CaseVerifierPath $promotionVerifierPath `
        -CaseOutputDirectory (Join-Path $outputRoot "promotion-status-output") `
        -ExpectedExitCode 0 -ExpectedOutput "Function dossier generated" `
        -CaseSourceRoot $emptyRoot -CaseGhidraRoot $emptyRoot `
        -CaseNotesRoot @($emptyRoot)

    $matchManifestPath = Join-Path $fixtureRoot "match-manifest.csv"
    $matchManifestRows = @(Import-Csv -LiteralPath $manifestPath)
    $matchManifestRows[0].expected_status = "match"
    Write-CsvFixture $matchManifestPath $matchManifestRows

    $passVerifierPath = Join-Path $fixtureRoot "pass-verifier.csv"
    $passRows = @(New-VerifierRows $matchManifestPath $originalEvidencePath `
        $candidateEvidencePath $candidateMapEvidencePath)
    $passRows[0].expected_status = "match"
    $passRows[0].status = "match"
    $passRows[0].actual_status = "match"
    $passRows[0].verification_status = "pass"
    $passRows[0].first_diff = ""
    $passRows[0].candidate_sha256 = $passRows[0].original_sha256
    Write-CsvFixture $passVerifierPath $passRows
    Invoke-DossierCase -Name "pass-status" `
        -CaseManifestPath $matchManifestPath -CaseVerifierPath $passVerifierPath `
        -CaseOutputDirectory (Join-Path $outputRoot "pass-status-output") `
        -ExpectedExitCode 0 -ExpectedOutput "Function dossier generated" `
        -CaseSourceRoot $emptyRoot -CaseGhidraRoot $emptyRoot `
        -CaseNotesRoot @($emptyRoot)

    $regressionVerifierPath = Join-Path $fixtureRoot "regression-verifier.csv"
    $regressionRows = @(New-VerifierRows $matchManifestPath `
        $originalEvidencePath $candidateEvidencePath $candidateMapEvidencePath)
    $regressionRows[0].expected_status = "match"
    $regressionRows[0].verification_status = "regression"
    Write-CsvFixture $regressionVerifierPath $regressionRows
    Invoke-DossierCase -Name "regression-status" `
        -CaseManifestPath $matchManifestPath `
        -CaseVerifierPath $regressionVerifierPath `
        -CaseOutputDirectory (Join-Path $outputRoot "regression-status-output") `
        -ExpectedExitCode 0 -ExpectedOutput "Function dossier generated" `
        -CaseSourceRoot $emptyRoot -CaseGhidraRoot $emptyRoot `
        -CaseNotesRoot @($emptyRoot)

    $shapeDefectVerifierPath = Join-Path $fixtureRoot `
        "raw-identical-shape-defect-verifier.csv"
    $shapeDefectRows = @(New-VerifierRows $manifestPath `
        $originalEvidencePath $candidateEvidencePath $candidateMapEvidencePath)
    $shapeDefectRows[0].raw_match = "True"
    $shapeDefectRows[0].raw_first_diff = ""
    $shapeDefectRows[0].first_diff = "0x00000000"
    $shapeDefectRows[0].candidate_raw_sha256 =
        $shapeDefectRows[0].original_raw_sha256
    $shapeDefectRows[0].candidate_sha256 =
        $shapeDefectRows[0].original_sha256
    $shapeDefectRows[0].mask_shape_valid = "False"
    $shapeDefectRows[0].masked_operand_shape_error =
        "Masked operand shape mismatch at function range 0x00000000-0x00000003: synthetic contract probe."
    $shapeDefectRows[0].masked_import_identity_error = ""
    Write-CsvFixture $shapeDefectVerifierPath $shapeDefectRows
    Invoke-DossierCase -Name "raw-identical-non-import-shape-defect" `
        -CaseManifestPath $manifestPath `
        -CaseVerifierPath $shapeDefectVerifierPath `
        -CaseOutputDirectory (Join-Path $outputRoot "shape-defect-output") `
        -ExpectedExitCode 0 -ExpectedOutput "Function dossier generated" `
        -CaseSourceRoot $emptyRoot -CaseGhidraRoot $emptyRoot `
        -CaseNotesRoot @($emptyRoot)

    $missingShapeDiagnosticPath = Join-Path $fixtureRoot `
        "shape-defect-without-diagnostic-verifier.csv"
    $missingShapeDiagnosticRows = @(Import-Csv -LiteralPath `
        $shapeDefectVerifierPath)
    $missingShapeDiagnosticRows[0].masked_operand_shape_error = ""
    Write-CsvFixture $missingShapeDiagnosticPath $missingShapeDiagnosticRows
    Invoke-DossierCase -Name "shape-defect-without-diagnostic" `
        -CaseManifestPath $manifestPath `
        -CaseVerifierPath $missingShapeDiagnosticPath `
        -CaseOutputDirectory (Join-Path $outputRoot "missing-shape-diagnostic-output") `
        -ExpectedExitCode 1 `
        -ExpectedOutput "mask-shape failure is missing its diagnostic" `
        -CaseSourceRoot $emptyRoot -CaseGhidraRoot $emptyRoot `
        -CaseNotesRoot @($emptyRoot)

    $validShapeWithDiagnosticPath = Join-Path $fixtureRoot `
        "valid-shape-with-diagnostic-verifier.csv"
    $validShapeWithDiagnosticRows = @(Import-Csv -LiteralPath `
        $shapeDefectVerifierPath)
    $validShapeWithDiagnosticRows[0].mask_shape_valid = "True"
    Write-CsvFixture $validShapeWithDiagnosticPath $validShapeWithDiagnosticRows
    Invoke-DossierCase -Name "valid-shape-with-diagnostic" `
        -CaseManifestPath $manifestPath `
        -CaseVerifierPath $validShapeWithDiagnosticPath `
        -CaseOutputDirectory (Join-Path $outputRoot "valid-shape-diagnostic-output") `
        -ExpectedExitCode 1 -ExpectedOutput "mask-shape state is inconsistent" `
        -CaseSourceRoot $emptyRoot -CaseGhidraRoot $emptyRoot `
        -CaseNotesRoot @($emptyRoot)

    $rawIdenticalValidShapePath = Join-Path $fixtureRoot `
        "raw-identical-valid-shape-verifier.csv"
    $rawIdenticalValidShapeRows = @(Import-Csv -LiteralPath `
        $shapeDefectVerifierPath)
    $rawIdenticalValidShapeRows[0].mask_shape_valid = "True"
    $rawIdenticalValidShapeRows[0].masked_operand_shape_error = ""
    Write-CsvFixture $rawIdenticalValidShapePath $rawIdenticalValidShapeRows
    Invoke-DossierCase -Name "raw-identical-valid-shape-rejected" `
        -CaseManifestPath $manifestPath `
        -CaseVerifierPath $rawIdenticalValidShapePath `
        -CaseOutputDirectory (Join-Path $outputRoot "raw-identical-valid-shape-output") `
        -ExpectedExitCode 1 `
        -ExpectedOutput "mismatch row has inconsistent difference fields" `
        -CaseSourceRoot $emptyRoot -CaseGhidraRoot $emptyRoot `
        -CaseNotesRoot @($emptyRoot)

    $errorVerifierPath = Join-Path $fixtureRoot "error-verifier.csv"
    $errorRows = @(New-VerifierRows $manifestPath $originalEvidencePath `
        $candidateEvidencePath $candidateMapEvidencePath)
    $errorRows[0].status = "error"
    $errorRows[0].actual_status = "error"
    $errorRows[0].verification_status = "error"
    $errorRows[0].error_message = "Synthetic matcher failure."
    $errorRows[0].raw_first_diff = ""
    $errorRows[0].first_diff = ""
    $errorRows[0].original_raw_sha256 = ""
    $errorRows[0].candidate_raw_sha256 = ""
    $errorRows[0].original_sha256 = ""
    $errorRows[0].candidate_sha256 = ""
    $errorRows[0].mask_bytes = "0"
    $errorRows[0].compared_bytes = "0"
    $errorRows[0].mask_shape_valid = "False"
    Write-CsvFixture $errorVerifierPath $errorRows
    Invoke-DossierCase -Name "error-status" `
        -CaseManifestPath $manifestPath -CaseVerifierPath $errorVerifierPath `
        -CaseOutputDirectory (Join-Path $outputRoot "error-status-output") `
        -ExpectedExitCode 0 -ExpectedOutput "Function dossier generated" `
        -CaseSourceRoot $emptyRoot -CaseGhidraRoot $emptyRoot `
        -CaseNotesRoot @($emptyRoot)

    $invalidStatusVerifierPath = Join-Path $fixtureRoot `
        "invalid-status-verifier.csv"
    $invalidStatusRows = @(Import-Csv -LiteralPath $verifierPath)
    $invalidStatusRows[0].status = "wip"
    $invalidStatusRows[0].actual_status = "wip"
    Write-CsvFixture $invalidStatusVerifierPath $invalidStatusRows
    Invoke-DossierCase -Name "invalid-schema4-status" `
        -CaseManifestPath $manifestPath `
        -CaseVerifierPath $invalidStatusVerifierPath `
        -CaseOutputDirectory (Join-Path $outputRoot "invalid-status-output") `
        -ExpectedExitCode 1 -ExpectedOutput "not a schema-4 status" `
        -CaseSourceRoot $emptyRoot -CaseGhidraRoot $emptyRoot `
        -CaseNotesRoot @($emptyRoot)

    Invoke-DossierCase -Name "missing-optional-evidence" `
        -CaseManifestPath $manifestPath -CaseVerifierPath $verifierPath `
        -CaseOutputDirectory $minimalOutputDirectory -ExpectedExitCode 0 `
        -ExpectedOutput "Warnings:" -CaseSourceRoot $emptyRoot `
        -CaseGhidraRoot $emptyRoot -CaseNotesRoot @($emptyRoot)
    $minimalJsonPath = Join-Path $minimalOutputDirectory `
        "Oregon32.exe-OtContractTarget-dossier.json"
    $minimal = Get-Content -LiteralPath $minimalJsonPath -Raw | ConvertFrom-Json
    Assert-True (@($minimal.warnings).Count -ge 6) `
        "Missing optional evidence did not produce explicit warnings."
    Assert-Equal $minimal.metrics.provided False `
        "Missing metrics state"

    $ambiguousManifestPath = Join-Path $fixtureRoot "ambiguous-manifest.csv"
    Write-CsvFixture $ambiguousManifestPath @($manifestRows[0], $manifestRows[0],
        $manifestRows[1])
    Invoke-DossierCase -Name "ambiguous-manifest-identity" `
        -CaseManifestPath $ambiguousManifestPath -CaseVerifierPath $verifierPath `
        -CaseOutputDirectory $ambiguousOutputDirectory -ExpectedExitCode 1 `
        -ExpectedOutput "ambiguous or missing" -CaseSourceRoot $emptyRoot `
        -CaseGhidraRoot $emptyRoot -CaseNotesRoot @($emptyRoot)
    Assert-True (-not (Test-Path -LiteralPath $ambiguousOutputDirectory)) `
        "Ambiguous identity published output."

    $missingVerifierPath = Join-Path $fixtureRoot "missing-verifier.csv"
    Write-CsvFixture $missingVerifierPath (New-VerifierRows `
        $manifestPath $originalEvidencePath $candidateEvidencePath `
        $candidateMapEvidencePath -OnlyDependency)
    Invoke-DossierCase -Name "missing-verifier-identity" `
        -CaseManifestPath $manifestPath -CaseVerifierPath $missingVerifierPath `
        -CaseOutputDirectory $missingOutputDirectory -ExpectedExitCode 1 `
        -ExpectedOutput "Verifier identity" -CaseSourceRoot $emptyRoot `
        -CaseGhidraRoot $emptyRoot -CaseNotesRoot @($emptyRoot)

    $schemaVerifierPath = Join-Path $fixtureRoot "schema3-verifier.csv"
    Write-CsvFixture $schemaVerifierPath (New-VerifierRows `
        $manifestPath $originalEvidencePath $candidateEvidencePath `
        $candidateMapEvidencePath "3")
    Invoke-DossierCase -Name "schema4-required" `
        -CaseManifestPath $manifestPath -CaseVerifierPath $schemaVerifierPath `
        -CaseOutputDirectory $schemaOutputDirectory -ExpectedExitCode 1 `
        -ExpectedOutput "expected schema 4" -CaseSourceRoot $emptyRoot `
        -CaseGhidraRoot $emptyRoot -CaseNotesRoot @($emptyRoot)

    Invoke-DossierCase -Name "unsafe-tracked-output" `
        -CaseManifestPath $manifestPath -CaseVerifierPath $verifierPath `
        -CaseOutputDirectory $unsafeOutput -ExpectedExitCode 1 `
        -ExpectedOutput "Dossier output" `
        -CaseSourceRoot $emptyRoot -CaseGhidraRoot $emptyRoot `
        -CaseNotesRoot @($emptyRoot)
    Assert-True (-not (Test-Path -LiteralPath $unsafeOutput)) `
        "Unsafe output directory was created."

    $binaryExtensionPath = Join-Path $fixtureRoot "synthetic-original.bin"
    Write-Utf8 $binaryExtensionPath "Synthetic text, deliberately forbidden by extension.`n"
    Invoke-DossierCase -Name "binary-evidence-rejected" `
        -CaseManifestPath $manifestPath -CaseVerifierPath $verifierPath `
        -CaseOutputDirectory $binaryOutputDirectory -ExpectedExitCode 1 `
        -ExpectedOutput "extension '.bin' is not allowed" `
        -CaseMaskPath $binaryExtensionPath -CaseSourceRoot $emptyRoot `
        -CaseGhidraRoot $emptyRoot -CaseNotesRoot @($emptyRoot)

    Write-Host "Function dossier contract checks passed."
}
finally {
    $safeRoot = [System.IO.Path]::GetFullPath($outputRoot)
    $allowedPrefix = [System.IO.Path]::GetFullPath(
        (Join-Path $repoRoot "a")).TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    if (-not $safeRoot.StartsWith(
            $allowedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to clean unexpected contract path '$safeRoot'."
    }
    if (Test-Path -LiteralPath $safeRoot) {
        Remove-Item -LiteralPath $safeRoot -Recurse -Force
    }
    if (Test-Path -LiteralPath $unsafeOutput) {
        $unsafeFull = [System.IO.Path]::GetFullPath($unsafeOutput)
        $docsPrefix = [System.IO.Path]::GetFullPath(
            (Join-Path $repoRoot "docs")).TrimEnd('\', '/') +
            [System.IO.Path]::DirectorySeparatorChar
        if (-not $unsafeFull.StartsWith(
                $docsPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to clean unexpected unsafe-test path '$unsafeFull'."
        }
        Remove-Item -LiteralPath $unsafeFull -Recurse -Force
    }
}
