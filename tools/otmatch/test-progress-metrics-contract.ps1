[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$matcherPath = (Resolve-Path (Join-Path $PSScriptRoot "match-functions.ps1")).Path
$metricsReporterPath = (Resolve-Path (Join-Path $PSScriptRoot "report-progress-metrics.ps1")).Path
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$shellPath = (Get-Process -Id $PID).Path
$contractParent = [System.IO.Path]::GetFullPath((Join-Path $repoRoot "a"))
$workPath = Join-Path $contractParent `
    ("otmatch-metrics-contract-" + [guid]::NewGuid().ToString("N"))
[void][System.IO.Directory]::CreateDirectory($workPath)
$fixturePath = Join-Path $workPath "original.exe"
$externalSentinelRoot = ""
$junctionPath = ""

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Invoke-MetricsCase {
    param(
        [string]$Name,
        [string]$ManifestPath,
        [string]$ResultsPath,
        [string]$MetricsPath,
        [string]$MaskAuditPath,
        [int]$ExpectedExitCode,
        [string]$ExpectedOutput,
        [double]$RequireInstructionPercent = 0.0,
        [int]$ExpectedAcceptedCount = -1,
        [int64]$ExpectedAcceptedInstructions = -1,
        [int64]$ExpectedDenominatorInstructions = -1,
        [int64]$ExpectedBodyRangeCount = -1
    )

    $summaryPath = Join-Path $workPath ("{0}-summary.json" -f $Name)
    # Every invocation begins with an obsolete success artifact. The reporter
    # must remove it before validation so no failed run can leave stale proof.
    [System.IO.File]::WriteAllText($summaryPath, '{"stale":true}')
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $shellPath -NoProfile -ExecutionPolicy Bypass `
            -File $metricsReporterPath `
            -ManifestPath $ManifestPath `
            -VerifierResultsPath $ResultsPath `
            -MaskAuditResultsPath $MaskAuditPath `
            -FunctionMetricsPath $MetricsPath `
            -RequireInstructionPercent $RequireInstructionPercent `
            -SummaryJsonPath $summaryPath 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $outputText = $output -join [Environment]::NewLine
    if ($exitCode -ne $ExpectedExitCode) {
        throw ("{0}: expected exit {1}, got {2}. Output: {3}" -f
            $Name, $ExpectedExitCode, $exitCode, $outputText)
    }
    if ($outputText -notmatch [regex]::Escape($ExpectedOutput)) {
        throw ("{0}: output did not contain '{1}'. Output: {2}" -f
            $Name, $ExpectedOutput, $outputText)
    }

    if ($ExpectedExitCode -eq 0) {
        if (-not (Test-Path -LiteralPath $summaryPath -PathType Leaf)) {
            throw "${Name}: successful metrics run did not write its JSON summary."
        }
        $summary = Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
        if ([int]$summary.schema_version -ne 2) {
            throw "${Name}: metrics summary has the wrong schema."
        }
        $identities = @($summary.strict.accepted_identities)
        if ([uint64]$summary.strict.accepted_identity_count -ne
            [uint64]$identities.Count) {
            throw "${Name}: metrics summary identity count is inconsistent."
        }
        if ([string]$summary.strict.accepted_identity_sha256 -notmatch
            '^[0-9a-f]{64}$' -or
            [string]$summary.denominator.identity_sha256 -notmatch
                '^[0-9a-f]{64}$' -or
            [string]$summary.denominator.body_ownership_sha256 -notmatch
                '^[0-9a-f]{64}$' -or
            [string]$summary.inputs.manifest.identity_universe_sha256 -notmatch
                '^[0-9a-f]{64}$') {
            throw "${Name}: metrics summary is missing identity fingerprints."
        }
        if ([int]$summary.inputs.manifest.identity_count -ne 2) {
            throw "${Name}: metrics summary has the wrong manifest identity universe."
        }
        $expectedInputHashes = @{
            manifest = (Get-FileHash -LiteralPath $ManifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
            verifier_results = (Get-FileHash -LiteralPath $ResultsPath -Algorithm SHA256).Hash.ToLowerInvariant()
            mask_audit_results = (Get-FileHash -LiteralPath $MaskAuditPath -Algorithm SHA256).Hash.ToLowerInvariant()
        }
        foreach ($inputName in $expectedInputHashes.Keys) {
            if ([string]$summary.inputs.$inputName.sha256 -cne
                [string]$expectedInputHashes[$inputName]) {
                throw "${Name}: metrics summary did not bind the parsed '$inputName' bytes."
            }
        }
        $expectedMetricsHash =
            (Get-FileHash -LiteralPath $MetricsPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ([string]@($summary.inputs.function_metrics)[0].sha256 -cne
            $expectedMetricsHash) {
            throw "${Name}: metrics summary did not bind the parsed function metrics bytes."
        }
        if ($ExpectedAcceptedCount -ge 0 -and
            [int]$summary.strict.accepted_identity_count -ne $ExpectedAcceptedCount) {
            throw "${Name}: unexpected strict accepted identity count."
        }
        if ($ExpectedAcceptedInstructions -ge 0 -and
            [int64]$summary.strict.accepted_instructions -ne
            $ExpectedAcceptedInstructions) {
            throw "${Name}: unexpected strict accepted instruction count."
        }
        if ($ExpectedDenominatorInstructions -ge 0 -and
            [int64]$summary.denominator.instruction_count -ne
            $ExpectedDenominatorInstructions) {
            throw "${Name}: unexpected instruction denominator."
        }
        if ($ExpectedBodyRangeCount -ge 0 -and
            [int64]$summary.denominator.body_range_count -ne
            $ExpectedBodyRangeCount) {
            throw "${Name}: unexpected canonical body-range count."
        }
    }
    elseif (Test-Path -LiteralPath $summaryPath -PathType Leaf) {
        throw "${Name}: failed metrics run left a success summary."
    }

    Write-Host ("PASS {0}: exit={1}" -f $Name, $exitCode)
}

function Export-MutatedResults {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [scriptblock]$Mutation
    )

    $rows = @(Import-Csv -LiteralPath $SourcePath)
    & $Mutation $rows
    $rows | Export-Csv -LiteralPath $DestinationPath -NoTypeInformation -Encoding UTF8
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

function Set-AsciiZ([byte[]]$Bytes, [int]$Offset, [string]$Value) {
    $encoded = [System.Text.Encoding]::ASCII.GetBytes($Value)
    [System.Array]::Copy($encoded, 0, $Bytes, $Offset, $encoded.Length)
    $Bytes[$Offset + $encoded.Length] = 0
}

function New-MaskShapeFixture([string]$Path) {
    $bytes = New-Object byte[] 0x800
    $peOffset = 0x80
    $coffOffset = $peOffset + 4
    $optionalOffset = $coffOffset + 20
    $sectionOffset = $optionalOffset + 0xe0
    $sectionRaw = 0x200

    $bytes[0] = 0x4d
    $bytes[1] = 0x5a
    Set-U32 $bytes 0x3c $peOffset
    Set-AsciiZ $bytes $peOffset "PE"
    Set-U16 $bytes $coffOffset 0x014c
    Set-U16 $bytes ($coffOffset + 2) 1
    Set-U16 $bytes ($coffOffset + 16) 0x00e0
    Set-U16 $bytes ($coffOffset + 18) 0x0102

    Set-U16 $bytes $optionalOffset 0x010b
    Set-U32 $bytes ($optionalOffset + 4) 0x00000600
    Set-U32 $bytes ($optionalOffset + 16) 0x00001000
    Set-U32 $bytes ($optionalOffset + 20) 0x00001000
    Set-U32 $bytes ($optionalOffset + 24) 0x00001000
    Set-U32 $bytes ($optionalOffset + 28) 0x00400000
    Set-U32 $bytes ($optionalOffset + 32) 0x00001000
    Set-U32 $bytes ($optionalOffset + 36) 0x00000200
    Set-U32 $bytes ($optionalOffset + 56) 0x00002000
    Set-U32 $bytes ($optionalOffset + 60) 0x00000200
    Set-U16 $bytes ($optionalOffset + 68) 3
    Set-U32 $bytes ($optionalOffset + 92) 16
    # IMAGE_DIRECTORY_ENTRY_BASERELOC
    Set-U32 $bytes ($optionalOffset + 136) 0x00001200
    Set-U32 $bytes ($optionalOffset + 140) 0x0000000c

    Set-AsciiZ $bytes $sectionOffset ".text"
    Set-U32 $bytes ($sectionOffset + 8) 0x00000600
    Set-U32 $bytes ($sectionOffset + 12) 0x00001000
    Set-U32 $bytes ($sectionOffset + 16) 0x00000600
    Set-U32 $bytes ($sectionOffset + 20) $sectionRaw
    Set-U32 $bytes ($sectionOffset + 36) 0x60000020

    # mov eax, 0x00401300; ret -- the immediate is a complete HIGHLOW field.
    $bytes[$sectionRaw] = 0xb8
    Set-U32 $bytes ($sectionRaw + 1) 0x00401300
    $bytes[$sectionRaw + 5] = 0xc3
    $bytes[$sectionRaw + 6] = 0xc3
    $bytes[$sectionRaw + 7] = 0x90

    $relocationOffset = $sectionRaw + 0x200
    Set-U32 $bytes $relocationOffset 0x00001000
    Set-U32 $bytes ($relocationOffset + 4) 12
    Set-U16 $bytes ($relocationOffset + 8) 0x3001
    Set-U16 $bytes ($relocationOffset + 10) 0

    [System.IO.File]::WriteAllBytes($Path, $bytes)
}

try {
    $candidatePath = Join-Path $workPath "candidate.exe"
    $mapPath = Join-Path $workPath "candidate.map"
    $manifestPath = Join-Path $workPath "manifest.csv"
    $resultsPath = Join-Path $workPath "results.csv"
    $metricsPath = Join-Path $workPath "metrics.csv"
    $maskAuditPath = Join-Path $workPath "mask-audit.csv"
    New-MaskShapeFixture $fixturePath
    [System.IO.File]::Copy($fixturePath, $candidatePath)
    [System.IO.File]::WriteAllText($mapPath, "self-contained candidate map fixture")

    @(
        [pscustomobject][ordered]@{
            name = "masked_probe"
            program = "Oregon32.exe"
            original_va = ""
            original_rva = "0x00001000"
            size = "0x00000008"
            candidate_va = ""
            candidate_rva = "0x00001000"
            candidate_symbol = ""
            candidate_dll = ""
            candidate_object = ""
            expected_status = "match"
            implementation_kind = "cpp"
            mask = "1-4"
            notes = "Metrics contract masked probe."
        }
        [pscustomobject][ordered]@{
            name = "maskless_probe"
            program = "Oregon32.exe"
            original_va = ""
            original_rva = "0x00001002"
            size = "0x00000002"
            candidate_va = ""
            candidate_rva = "0x00001002"
            candidate_symbol = ""
            candidate_dll = ""
            candidate_object = ""
            expected_status = "match"
            implementation_kind = "cpp"
            mask = ""
            notes = "Metrics contract raw probe."
        }
    ) | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8

    @(
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"
            name = "FUN_00000002"
            original_va = "0x00401000"
            original_rva = "0x00001000"
            size = "0x00000008"
            instruction_count = "2"
            body_bytes = "4"
            body_ranges = "0x00001000-0x00001002;0x00001006-0x00001008"
            block = ".text"
            notes = ""
        }
        [pscustomobject][ordered]@{
            program = "Oregon32.exe"
            name = "FUN_00000004"
            original_va = "0x00401002"
            original_rva = "0x00001002"
            size = "0x00000002"
            instruction_count = "1"
            body_bytes = "2"
            body_ranges = "0x00001002-0x00001004"
            block = ".text"
            notes = ""
        }
    ) | Export-Csv -LiteralPath $metricsPath -NoTypeInformation -Encoding UTF8

    @(
        [pscustomobject][ordered]@{
            name = "masked_probe"
            program = "Oregon32.exe"
            original_rva = "0x00001000"
            function_size = "8"
            expected_status = "match"
            implementation_kind = "cpp"
            mask = "1-4"
            range_start = "1"
            range_end = "4"
            range_length = "4"
            classification = "full_known_address_operand"
            issue = ""
            validated_bytes = "4"
            partial_known_bytes = "0"
            unexplained_bytes = "0"
            operand_count = "1"
            operand_kinds = "highlow"
            operand_ranges = "1-4:highlow"
            full_function_mask = "False"
            notes = "Synthetic original-image shape result."
        }
    ) | Export-Csv -LiteralPath $maskAuditPath -NoTypeInformation -Encoding UTF8

    $matcherOutput = & $shellPath -NoProfile -ExecutionPolicy Bypass `
        -File $matcherPath `
        -ManifestPath $manifestPath `
        -OriginalPath $fixturePath `
        -CandidatePath $candidatePath `
        -CandidateMapPath $mapPath `
        -ResultsCsvPath $resultsPath `
        -SummaryOnly 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Fixture matcher failed: $($matcherOutput -join [Environment]::NewLine)"
    }

    $externalSentinelRoot = Join-Path ([System.IO.Path]::GetTempPath()) `
        ("otmatch-metrics-sentinel-" + [guid]::NewGuid().ToString("N"))
    [void][System.IO.Directory]::CreateDirectory($externalSentinelRoot)
    $externalSentinelPath =
        Join-Path $externalSentinelRoot "stale-summary.json"
    [System.IO.File]::WriteAllText(
        $externalSentinelPath, '{"external_sentinel":true}')
    $junctionPath = Join-Path $workPath "reparse-output"
    [void](New-Item -ItemType Junction -Path $junctionPath `
        -Target $externalSentinelRoot -Force)
    $reparseSummaryPath = Join-Path $junctionPath "stale-summary.json"
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $reparseOutput = & $shellPath -NoProfile -ExecutionPolicy Bypass `
            -File $metricsReporterPath `
            -ManifestPath $manifestPath `
            -VerifierResultsPath $resultsPath `
            -MaskAuditResultsPath $maskAuditPath `
            -FunctionMetricsPath $metricsPath `
            -SummaryJsonPath $reparseSummaryPath 2>&1
        $reparseExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    Assert-True ($reparseExitCode -ne 0 -and
        ($reparseOutput -join [Environment]::NewLine) -match
        'reparse-point ancestor') `
        "Metrics reporter did not reject a reparse-point summary ancestor."
    Assert-True ((Get-Content -LiteralPath $externalSentinelPath -Raw) -ceq
        '{"external_sentinel":true}') `
        "Metrics reporter deleted or rewrote an external reparse target."
    [System.IO.Directory]::Delete($junctionPath)
    $junctionPath = ""

    Invoke-MetricsCase -Name "fresh-contract" `
        -ManifestPath $manifestPath -ResultsPath $resultsPath `
        -MetricsPath $metricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 0 -ExpectedOutput "Matched EXE C++ rows outside the Product graph: 2" `
        -ExpectedAcceptedCount 0 -ExpectedAcceptedInstructions 0 `
        -ExpectedDenominatorInstructions 3 -ExpectedBodyRangeCount 3

    # The first function's 8-byte envelope contains the second function's
    # 2-byte envelope, but their explicit Ghidra bodies are disjoint. This is
    # valid ownership and must not be rejected as an envelope overlap.
    $freshSummaryPath = Join-Path $workPath "fresh-contract-summary.json"
    $freshSummary = Get-Content -LiteralPath $freshSummaryPath -Raw |
        ConvertFrom-Json

    # Move only body ownership while preserving every legacy denominator
    # field and the total number of ranges. The ownership fingerprint must be
    # the evidence that changes.
    $ownershipDriftMetricsPath = Join-Path $workPath "ownership-drift-metrics.csv"
    $ownershipDriftMetrics = @(Import-Csv -LiteralPath $metricsPath)
    $ownershipDriftMetrics[0].body_ranges =
        "0x00001000-0x00001001;0x00001005-0x00001008"
    $ownershipDriftMetrics | Export-Csv `
        -LiteralPath $ownershipDriftMetricsPath -NoTypeInformation -Encoding UTF8
    Invoke-MetricsCase -Name "ownership-only-drift" `
        -ManifestPath $manifestPath -ResultsPath $resultsPath `
        -MetricsPath $ownershipDriftMetricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 0 -ExpectedOutput "Validated result rows: 2/2" `
        -ExpectedDenominatorInstructions 3 -ExpectedBodyRangeCount 3
    $ownershipDriftSummary = Get-Content -LiteralPath (
        Join-Path $workPath "ownership-only-drift-summary.json") -Raw |
        ConvertFrom-Json
    Assert-True (
        [string]$ownershipDriftSummary.denominator.identity_sha256 -ceq
            [string]$freshSummary.denominator.identity_sha256) `
        "Ownership-only drift unexpectedly changed the legacy denominator digest."
    Assert-True (
        [string]$ownershipDriftSummary.denominator.body_ownership_sha256 -cne
            [string]$freshSummary.denominator.body_ownership_sha256) `
        "Ownership-only drift did not invalidate the body-ownership digest."

    $missingBodyRangesPath = Join-Path $workPath "missing-body-ranges.csv"
    $missingBodyRanges = @(Import-Csv -LiteralPath $metricsPath)
    foreach ($row in $missingBodyRanges) {
        $row.PSObject.Properties.Remove("body_ranges")
    }
    $missingBodyRanges | Export-Csv -LiteralPath $missingBodyRangesPath `
        -NoTypeInformation -Encoding UTF8
    Invoke-MetricsCase -Name "missing-body-ranges" `
        -ManifestPath $manifestPath -ResultsPath $resultsPath `
        -MetricsPath $missingBodyRangesPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "missing required body_ranges"

    $malformedBodyRangesPath = Join-Path $workPath "malformed-body-ranges.csv"
    $malformedBodyRanges = @(Import-Csv -LiteralPath $metricsPath)
    $malformedBodyRanges[0].body_ranges = "0x00001000..0x00001004"
    $malformedBodyRanges | Export-Csv -LiteralPath $malformedBodyRangesPath `
        -NoTypeInformation -Encoding UTF8
    Invoke-MetricsCase -Name "malformed-body-ranges" `
        -ManifestPath $manifestPath -ResultsPath $resultsPath `
        -MetricsPath $malformedBodyRangesPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "malformed body_ranges"

    $noncanonicalBodyRangesPath = Join-Path $workPath "noncanonical-body-ranges.csv"
    $noncanonicalBodyRanges = @(Import-Csv -LiteralPath $metricsPath)
    $noncanonicalBodyRanges[0].body_ranges =
        "0x1000-0x1002;0x1006-0x1008"
    $noncanonicalBodyRanges | Export-Csv `
        -LiteralPath $noncanonicalBodyRangesPath -NoTypeInformation -Encoding UTF8
    Invoke-MetricsCase -Name "noncanonical-body-ranges" `
        -ManifestPath $manifestPath -ResultsPath $resultsPath `
        -MetricsPath $noncanonicalBodyRangesPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "non-canonical body_ranges"

    $unorderedBodyRangesPath = Join-Path $workPath "unordered-body-ranges.csv"
    $unorderedBodyRanges = @(Import-Csv -LiteralPath $metricsPath)
    $unorderedBodyRanges[0].body_ranges =
        "0x00001006-0x00001008;0x00001000-0x00001002"
    $unorderedBodyRanges | Export-Csv -LiteralPath $unorderedBodyRangesPath `
        -NoTypeInformation -Encoding UTF8
    Invoke-MetricsCase -Name "unordered-body-ranges" `
        -ManifestPath $manifestPath -ResultsPath $resultsPath `
        -MetricsPath $unorderedBodyRangesPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "ordered and internally disjoint"

    $internalOverlapMetricsPath = Join-Path $workPath "internal-body-overlap.csv"
    $internalOverlapMetrics = @(Import-Csv -LiteralPath $metricsPath)
    $internalOverlapMetrics[0].body_ranges =
        "0x00001000-0x00001003;0x00001002-0x00001003"
    $internalOverlapMetrics | Export-Csv `
        -LiteralPath $internalOverlapMetricsPath -NoTypeInformation -Encoding UTF8
    Invoke-MetricsCase -Name "internal-body-overlap" `
        -ManifestPath $manifestPath -ResultsPath $resultsPath `
        -MetricsPath $internalOverlapMetricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "ordered and internally disjoint"

    $unownedEntryMetricsPath = Join-Path $workPath "unowned-entry-metrics.csv"
    $unownedEntryMetrics = @(Import-Csv -LiteralPath $metricsPath)
    $unownedEntryMetrics[0].body_ranges =
        "0x00001001-0x00001002;0x00001005-0x00001008"
    $unownedEntryMetrics | Export-Csv `
        -LiteralPath $unownedEntryMetricsPath -NoTypeInformation -Encoding UTF8
    Invoke-MetricsCase -Name "unowned-entry" `
        -ManifestPath $manifestPath -ResultsPath $resultsPath `
        -MetricsPath $unownedEntryMetricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "does not own its entry RVA"

    $outsideBodyMetricsPath = Join-Path $workPath "outside-body-metrics.csv"
    $outsideBodyMetrics = @(Import-Csv -LiteralPath $metricsPath)
    $outsideBodyMetrics[0].body_ranges =
        "0x00001000-0x00001002;0x00001008-0x0000100a"
    $outsideBodyMetrics | Export-Csv -LiteralPath $outsideBodyMetricsPath `
        -NoTypeInformation -Encoding UTF8
    Invoke-MetricsCase -Name "body-range-outside-envelope" `
        -ManifestPath $manifestPath -ResultsPath $resultsPath `
        -MetricsPath $outsideBodyMetricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "outside its half-open envelope"

    $bodySizeMismatchPath = Join-Path $workPath "body-size-mismatch.csv"
    $bodySizeMismatch = @(Import-Csv -LiteralPath $metricsPath)
    $bodySizeMismatch[0].body_ranges =
        "0x00001000-0x00001002;0x00001006-0x00001007"
    $bodySizeMismatch | Export-Csv -LiteralPath $bodySizeMismatchPath `
        -NoTypeInformation -Encoding UTF8
    Invoke-MetricsCase -Name "body-union-size-mismatch" `
        -ManifestPath $manifestPath -ResultsPath $resultsPath `
        -MetricsPath $bodySizeMismatchPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "does not equal body_bytes"

    $crossBodyOverlapPath = Join-Path $workPath "cross-body-overlap.csv"
    $crossBodyOverlap = @(Import-Csv -LiteralPath $metricsPath)
    $crossBodyOverlap[0].body_ranges =
        "0x00001000-0x00001003;0x00001007-0x00001008"
    $crossBodyOverlap | Export-Csv -LiteralPath $crossBodyOverlapPath `
        -NoTypeInformation -Encoding UTF8
    Invoke-MetricsCase -Name "cross-function-body-overlap" `
        -ManifestPath $manifestPath -ResultsPath $resultsPath `
        -MetricsPath $crossBodyOverlapPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "Function body overlap in program"

    $thresholdResultsPath = Join-Path $workPath "threshold-results.csv"
    Export-MutatedResults $resultsPath $thresholdResultsPath {
        param($rows)
        foreach ($row in $rows) {
            $row.candidate_object = "src_otwin_app_general_helpers.obj"
        }
    }
    Invoke-MetricsCase -Name "instruction-threshold-pass" `
        -ManifestPath $manifestPath -ResultsPath $thresholdResultsPath `
        -MetricsPath $metricsPath -MaskAuditPath $maskAuditPath `
        -RequireInstructionPercent 100 `
        -ExpectedExitCode 0 -ExpectedOutput "Required instruction threshold passed" `
        -ExpectedAcceptedCount 2 -ExpectedAcceptedInstructions 3 `
        -ExpectedDenominatorInstructions 3

    $partialThresholdResultsPath = Join-Path $workPath "partial-threshold-results.csv"
    Export-MutatedResults $thresholdResultsPath $partialThresholdResultsPath {
        param($rows)
        $rows[1].status = "mismatch"
        $rows[1].actual_status = "mismatch"
        $rows[1].verification_status = "regression"
        $rows[1].raw_match = "False"
    }
    Invoke-MetricsCase -Name "instruction-threshold-fail" `
        -ManifestPath $manifestPath -ResultsPath $partialThresholdResultsPath `
        -MetricsPath $metricsPath -MaskAuditPath $maskAuditPath `
        -RequireInstructionPercent 100 `
        -ExpectedExitCode 1 -ExpectedOutput "below the required 100.0000%"

    $casePath = Join-Path $workPath "obsolete-schema-results.csv"
    Export-MutatedResults $resultsPath $casePath { param($rows) $rows[0].result_schema_version = "3" }
    Invoke-MetricsCase -Name "obsolete-verifier-schema" `
        -ManifestPath $manifestPath -ResultsPath $casePath `
        -MetricsPath $metricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "expected 4"

    $casePath = Join-Path $workPath "stale-manifest-results.csv"
    Export-MutatedResults $resultsPath $casePath { param($rows) $rows[0].manifest_sha256 = ("0" * 64) }
    Invoke-MetricsCase -Name "stale-manifest-hash" `
        -ManifestPath $manifestPath -ResultsPath $casePath `
        -MetricsPath $metricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "manifest SHA-256 changed"

    $casePath = Join-Path $workPath "changed-mask-results.csv"
    Export-MutatedResults $resultsPath $casePath { param($rows) $rows[0].mask = "1" }
    Invoke-MetricsCase -Name "exact-mask-metadata" `
        -ManifestPath $manifestPath -ResultsPath $casePath `
        -MetricsPath $metricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "mask text does not exactly match"

    $casePath = Join-Path $workPath "changed-locator-results.csv"
    Export-MutatedResults $resultsPath $casePath { param($rows) $rows[0].candidate_locator = "2" }
    Invoke-MetricsCase -Name "exact-locator-metadata" `
        -ManifestPath $manifestPath -ResultsPath $casePath `
        -MetricsPath $metricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "candidate_locator does not exactly match"

    $casePath = Join-Path $workPath "impossible-raw-results.csv"
    Export-MutatedResults $resultsPath $casePath { param($rows) $rows[1].raw_match = "False" }
    Invoke-MetricsCase -Name "impossible-maskless-match" `
        -ManifestPath $manifestPath -ResultsPath $casePath `
        -MetricsPath $metricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "impossible maskless match"

    $casePath = Join-Path $workPath "raw-mismatch-without-import-diagnostic.csv"
    Export-MutatedResults $resultsPath $casePath {
        param($rows)
        $rows[0].status = "mismatch"
        $rows[0].actual_status = "mismatch"
        $rows[0].verification_status = "regression"
    }
    Invoke-MetricsCase -Name "raw-mismatch-without-import-diagnostic" `
        -ManifestPath $manifestPath -ResultsPath $casePath `
        -MetricsPath $metricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "raw_match=true but actual_status='mismatch'"

    $casePath = Join-Path $workPath "masked-import-identity-mismatch.csv"
    Export-MutatedResults $resultsPath $casePath {
        param($rows)
        $rows[0].status = "mismatch"
        $rows[0].actual_status = "mismatch"
        $rows[0].verification_status = "regression"
        $diagnostic = "Masked import identity mismatch at function offset 0x00000000: synthetic contract probe."
        $rows[0].mask_shape_valid = "False"
        $rows[0].masked_operand_shape_error = $diagnostic
        $rows[0].masked_import_identity_error = $diagnostic
    }
    Invoke-MetricsCase -Name "masked-import-identity-mismatch" `
        -ManifestPath $manifestPath -ResultsPath $casePath `
        -MetricsPath $metricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 0 -ExpectedOutput "Actual verifier status: match=1, mismatch=1, error=0"

    $casePath = Join-Path $workPath "raw-identical-non-import-shape-defect.csv"
    Export-MutatedResults $resultsPath $casePath {
        param($rows)
        $rows[0].status = "mismatch"
        $rows[0].actual_status = "mismatch"
        $rows[0].verification_status = "regression"
        $rows[0].first_diff = "0x00000001"
        $rows[0].mask_shape_valid = "False"
        $rows[0].masked_operand_shape_error =
            "Masked operand shape mismatch at function range 0x00000001-0x00000004: synthetic contract probe."
        $rows[0].masked_import_identity_error = ""
    }
    Invoke-MetricsCase -Name "raw-identical-non-import-shape-defect" `
        -ManifestPath $manifestPath -ResultsPath $casePath `
        -MetricsPath $metricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 0 `
        -ExpectedOutput "Actual verifier status: match=1, mismatch=1, error=0"

    $casePath = Join-Path $workPath "invalid-shape-without-diagnostic.csv"
    Export-MutatedResults $resultsPath $casePath {
        param($rows)
        $rows[0].status = "mismatch"
        $rows[0].actual_status = "mismatch"
        $rows[0].verification_status = "regression"
        $rows[0].mask_shape_valid = "False"
        $rows[0].masked_operand_shape_error = ""
    }
    Invoke-MetricsCase -Name "invalid-shape-without-diagnostic" `
        -ManifestPath $manifestPath -ResultsPath $casePath `
        -MetricsPath $metricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "mask_shape_valid=false without"

    $casePath = Join-Path $workPath "valid-shape-with-diagnostic.csv"
    Export-MutatedResults $resultsPath $casePath {
        param($rows)
        $rows[0].masked_operand_shape_error = "synthetic stale diagnostic"
    }
    Invoke-MetricsCase -Name "valid-shape-with-diagnostic" `
        -ManifestPath $manifestPath -ResultsPath $casePath `
        -MetricsPath $metricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "mask_shape_valid=true"

    $casePath = Join-Path $workPath "maskless-invalid-shape.csv"
    Export-MutatedResults $resultsPath $casePath {
        param($rows)
        $rows[1].status = "mismatch"
        $rows[1].actual_status = "mismatch"
        $rows[1].verification_status = "regression"
        $rows[1].raw_match = "False"
        $rows[1].mask_shape_valid = "False"
        $rows[1].masked_operand_shape_error = "synthetic maskless diagnostic"
    }
    Invoke-MetricsCase -Name "maskless-invalid-shape" `
        -ManifestPath $manifestPath -ResultsPath $casePath `
        -MetricsPath $metricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "inconsistent paired mask-shape metadata"

    $oversizedMetricsPath = Join-Path $workPath "oversized-metrics.csv"
    $oversizedMetrics = @(Import-Csv -LiteralPath $metricsPath)
    $oversizedMetrics[1].size = "3"
    $oversizedMetrics[1].body_bytes = "3"
    $oversizedMetrics[1].body_ranges = "0x00001002-0x00001005"
    $oversizedMetrics | Export-Csv -LiteralPath $oversizedMetricsPath -NoTypeInformation -Encoding UTF8
    Invoke-MetricsCase -Name "whole-function-range-guard" `
        -ManifestPath $manifestPath -ResultsPath $resultsPath `
        -MetricsPath $oversizedMetricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "whole-function coverage cannot be credited"

    $changedAuditPath = Join-Path $workPath "changed-mask-audit.csv"
    $changedAudit = @(Import-Csv -LiteralPath $maskAuditPath)
    $changedAudit[0].mask = "1"
    $changedAudit | Export-Csv -LiteralPath $changedAuditPath -NoTypeInformation -Encoding UTF8
    Invoke-MetricsCase -Name "exact-audit-mask" `
        -ManifestPath $manifestPath -ResultsPath $resultsPath `
        -MetricsPath $metricsPath -MaskAuditPath $changedAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "Mask-audit mask does not exactly match"

    $changedAuditPath = Join-Path $workPath "changed-classification-audit.csv"
    $changedAudit = @(Import-Csv -LiteralPath $maskAuditPath)
    $changedAudit[0].classification = "partial_known_operand"
    $changedAudit | Export-Csv -LiteralPath $changedAuditPath -NoTypeInformation -Encoding UTF8
    Invoke-MetricsCase -Name "audit-classification-consistency" `
        -ManifestPath $manifestPath -ResultsPath $resultsPath `
        -MetricsPath $metricsPath -MaskAuditPath $changedAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "classification 'partial_known_operand' is inconsistent"

    [System.IO.File]::WriteAllText($mapPath, "changed candidate map fixture")
    Invoke-MetricsCase -Name "stale-candidate-map" `
        -ManifestPath $manifestPath -ResultsPath $resultsPath `
        -MetricsPath $metricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "candidate map SHA-256 changed"
    [System.IO.File]::WriteAllText($mapPath, "self-contained candidate map fixture")

    $candidateBytes = [System.IO.File]::ReadAllBytes($candidatePath)
    $candidateBytes[$candidateBytes.Length - 1] = $candidateBytes[$candidateBytes.Length - 1] -bxor 1
    [System.IO.File]::WriteAllBytes($candidatePath, $candidateBytes)
    Invoke-MetricsCase -Name "stale-candidate-image" `
        -ManifestPath $manifestPath -ResultsPath $resultsPath `
        -MetricsPath $metricsPath -MaskAuditPath $maskAuditPath `
        -ExpectedExitCode 1 -ExpectedOutput "candidate PE SHA-256 changed"

    Write-Host "Progress metrics verification contract: PASS"
}
finally {
    if (-not [string]::IsNullOrWhiteSpace($junctionPath) -and
        (Test-Path -LiteralPath $junctionPath)) {
        [System.IO.Directory]::Delete($junctionPath)
    }
    if (Test-Path -LiteralPath $workPath -PathType Container) {
        $resolvedWorkPath = (Resolve-Path -LiteralPath $workPath).Path
        $contractPrefix = $contractParent.TrimEnd('\', '/') +
            [System.IO.Path]::DirectorySeparatorChar
        if (-not $resolvedWorkPath.StartsWith(
                $contractPrefix,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to clean unexpected metrics-contract path '$resolvedWorkPath'."
        }
        Remove-Item -LiteralPath $workPath -Recurse -Force
    }
    if (-not [string]::IsNullOrWhiteSpace($externalSentinelRoot) -and
        (Test-Path -LiteralPath $externalSentinelRoot -PathType Container)) {
        $resolvedSentinelRoot =
            (Resolve-Path -LiteralPath $externalSentinelRoot).Path
        $tempPrefix = [System.IO.Path]::GetFullPath(
            [System.IO.Path]::GetTempPath()).TrimEnd('\', '/') +
            [System.IO.Path]::DirectorySeparatorChar
        if (-not $resolvedSentinelRoot.StartsWith(
                $tempPrefix,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Refusing to clean unexpected sentinel path '$resolvedSentinelRoot'."
        }
        Remove-Item -LiteralPath $externalSentinelRoot -Recurse -Force
    }
}
