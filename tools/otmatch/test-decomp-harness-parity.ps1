<#
.SYNOPSIS
Rerun OTWIN's native and decomp-harness scorers and require exact parity.

.DESCRIPTION
The default run regenerates isolated ignored artifacts, validates masks and
strict policy metrics, then compares all row identities, outcomes, credit,
instruction-count presence, provenance hashes, and whole-program totals.
Use -ReuseResults to revalidate the selected result paths without rerunning
the scorers.
#>
[CmdletBinding()]
param(
    [switch]$ReuseResults,

    [string]$OutputDirectory =
        "artifacts\otmatch\vc40\decomp-harness-parity",

    [string]$HarnessResultsPath = "",
    [string]$NativeResultsPath = "",
    [string]$MaskAuditResultsPath = "",
    [string]$MetricsSummaryPath = "",
    [string]$WslDistribution = "Ubuntu"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$manifestPath = Join-Path $repoRoot "tools\otmatch\functions.vc40-real-cpp.csv"
$originalPath = Join-Path $repoRoot "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe"
$originalDllPath = Join-Path $repoRoot "Sample\Oregon Trail CD\OTWIN32\OREGON32.DLL"
$candidateDirectory = Join-Path $repoRoot "artifacts\otmatch\vc40"
$metricsPaths = @(
    (Join-Path $repoRoot "tools\ghidra\otwin32\output\function_metrics_oregon32_exe.csv"),
    (Join-Path $repoRoot "tools\ghidra\otwin32\output\function_metrics_oregon32_dll.csv")
)

function Resolve-ProjectPath([string]$Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
}

function Get-Field($Row, [string]$Name) {
    $property = $Row.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) {
        return ""
    }
    return ([string]$property.Value).Trim()
}

function Parse-Number([string]$Value, [string]$Context) {
    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "$Context is empty."
    }
    $text = $Value.Trim()
    if ($text.StartsWith("0x", [System.StringComparison]::OrdinalIgnoreCase)) {
        return [Convert]::ToUInt64($text.Substring(2), 16)
    }
    return [uint64]::Parse(
        $text,
        [System.Globalization.NumberStyles]::Integer,
        [System.Globalization.CultureInfo]::InvariantCulture)
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Assert-InputFile([string]$Path, [string]$Description) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Description not found: $Path"
    }
}

function Invoke-CheckedPowerShell([string]$ScriptPath, [string[]]$Arguments) {
    & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass `
        -File $ScriptPath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$(Split-Path -Leaf $ScriptPath) failed with exit code $LASTEXITCODE."
    }
}

function Convert-ToWslPath([string]$Path) {
    # Passing a Windows path as a direct wsl.exe argument loses backslashes.
    # Quote it for the Linux shell so wslpath receives the exact text.
    $apostropheEscape = "'" + '"' + "'" + '"' + "'"
    $quotedPath = "'" + $Path.Replace("'", $apostropheEscape) + "'"
    $command = "wslpath -u $quotedPath"
    $converted = & wsl.exe -d $WslDistribution -- bash -lc $command
    if ($LASTEXITCODE -ne 0) {
        throw "wslpath failed for '$Path' with exit code $LASTEXITCODE."
    }
    return ([string]$converted).Trim()
}

function Get-NativeOutcome($Row) {
    $verification = (Get-Field $Row "verification_status").ToLowerInvariant()
    switch ($verification) {
        "pass" { return "match" }
        "allowed_wip" { return "wip" }
        "promotion_ready" { return "unexpected-match" }
        "regression" { return "mismatch" }
        "error" { return "error" }
        default {
            if ((Get-Field $Row "actual_status") -eq "error" -or
                -not [string]::IsNullOrWhiteSpace((Get-Field $Row "error_message"))) {
                return "error"
            }
            throw "Unknown native verification_status '$verification'."
        }
    }
}

$resolvedOutputDirectory = Resolve-ProjectPath $OutputDirectory
if ([string]::IsNullOrWhiteSpace($HarnessResultsPath)) {
    $HarnessResultsPath = Join-Path $resolvedOutputDirectory "harness-results.csv"
}
if ([string]::IsNullOrWhiteSpace($NativeResultsPath)) {
    $NativeResultsPath = Join-Path $resolvedOutputDirectory "native-results.csv"
}
if ([string]::IsNullOrWhiteSpace($MaskAuditResultsPath)) {
    $MaskAuditResultsPath = Join-Path $resolvedOutputDirectory "mask-audit.csv"
}
if ([string]::IsNullOrWhiteSpace($MetricsSummaryPath)) {
    $MetricsSummaryPath = Join-Path $resolvedOutputDirectory "metrics-summary.json"
}
$HarnessResultsPath = Resolve-ProjectPath $HarnessResultsPath
$NativeResultsPath = Resolve-ProjectPath $NativeResultsPath
$MaskAuditResultsPath = Resolve-ProjectPath $MaskAuditResultsPath
$MetricsSummaryPath = Resolve-ProjectPath $MetricsSummaryPath

$candidateInputs = @(
    (Join-Path $candidateDirectory "otwin-match-candidates.dll"),
    (Join-Path $candidateDirectory "otwin-match-candidates.map"),
    (Join-Path $candidateDirectory "otwin-match-candidates-lcmt.dll"),
    (Join-Path $candidateDirectory "otwin-match-candidates-lcmt.map"),
    (Join-Path $candidateDirectory "otwin-match-candidates-dllcrt.dll"),
    (Join-Path $candidateDirectory "otwin-match-candidates-dllcrt.map")
)
$stableInputs = @(
    $manifestPath,
    $originalPath,
    $originalDllPath,
    (Join-Path $repoRoot "harness-match.sh"),
    (Join-Path $repoRoot "tools\otmatch\match-functions.ps1"),
    (Join-Path $repoRoot "tools\otmatch\audit-function-masks.ps1"),
    (Join-Path $repoRoot "tools\otmatch\report-progress-metrics.ps1"),
    (Join-Path $repoRoot "tools\otmatch\vc4-exe-product-sources.txt")
) + $candidateInputs + $metricsPaths

$inputSnapshots = @{}
foreach ($path in $stableInputs) {
    Assert-InputFile $path "Parity input"
    $inputSnapshots[$path] = Get-Sha256 $path
}

if (-not $ReuseResults) {
    [void][System.IO.Directory]::CreateDirectory($resolvedOutputDirectory)

    $wslRepoRoot = Convert-ToWslPath $repoRoot
    $wslHarnessResults = Convert-ToWslPath $HarnessResultsPath
    $harnessLogPath = Join-Path $resolvedOutputDirectory "harness.log"
    $harnessOutput = @(& wsl.exe -d $WslDistribution --cd $wslRepoRoot -- `
        env "HARNESS_RESULTS_CSV=$wslHarnessResults" bash ./harness-match.sh 2>&1)
    $harnessExitCode = $LASTEXITCODE
    $harnessOutput | Set-Content -LiteralPath $harnessLogPath -Encoding UTF8
    if ($harnessExitCode -ne 0) {
        $tail = @($harnessOutput | Select-Object -Last 30) -join [Environment]::NewLine
        throw "harness-match.sh failed with exit code $harnessExitCode.`n$tail"
    }
    Write-Host "Pinned harness scorer passed; log: $harnessLogPath"

    $nativeArguments = @(
        "-ManifestPath", $manifestPath,
        "-OriginalPath", $originalPath,
        "-OriginalDllPath", $originalDllPath,
        "-CandidatePath", $candidateInputs[0],
        "-CandidateMapPath", $candidateInputs[1],
        "-CandidateLcmtPath", $candidateInputs[2],
        "-CandidateLcmtMapPath", $candidateInputs[3],
        "-CandidateDllcrtPath", $candidateInputs[4],
        "-CandidateDllcrtMapPath", $candidateInputs[5],
        "-ResultsCsvPath", $NativeResultsPath,
        "-SummaryOnly"
    )
    Invoke-CheckedPowerShell `
        (Join-Path $repoRoot "tools\otmatch\match-functions.ps1") `
        $nativeArguments

    $maskArguments = @(
        "-ManifestPath", $manifestPath,
        "-OriginalPath", $originalPath,
        "-OriginalDllPath", $originalDllPath,
        "-ResultsCsvPath", $MaskAuditResultsPath,
        "-RequireValidated"
    )
    Invoke-CheckedPowerShell `
        (Join-Path $repoRoot "tools\otmatch\audit-function-masks.ps1") `
        $maskArguments

    $metricsArguments = @(
        "-ManifestPath", $manifestPath,
        "-VerifierResultsPath", $NativeResultsPath,
        "-MaskAuditResultsPath", $MaskAuditResultsPath,
        "-RequireProductReachability",
        "-SummaryJsonPath", $MetricsSummaryPath
    )
    Invoke-CheckedPowerShell `
        (Join-Path $repoRoot "tools\otmatch\report-progress-metrics.ps1") `
        $metricsArguments
}

Assert-InputFile $HarnessResultsPath "Harness results"
Assert-InputFile $NativeResultsPath "Native verifier results"
Assert-InputFile $MaskAuditResultsPath "Mask-audit results"
Assert-InputFile $MetricsSummaryPath "Metrics summary"

$manifest = @(Import-Csv -LiteralPath $manifestPath)
$harness = @(Import-Csv -LiteralPath $HarnessResultsPath)
$native = @(Import-Csv -LiteralPath $NativeResultsPath)
$metrics = Get-Content -LiteralPath $MetricsSummaryPath -Raw | ConvertFrom-Json
$differences = @()
$manifestHash = Get-Sha256 $manifestPath

if ($manifest.Count -eq 0) {
    throw "Authoritative manifest is empty."
}
if ($harness.Count -ne $manifest.Count -or $native.Count -ne $manifest.Count) {
    throw ("Row-count mismatch: manifest={0}, harness={1}, native={2}." -f
        $manifest.Count, $harness.Count, $native.Count)
}

$creditedIdentities = @()
for ($index = 0; $index -lt $manifest.Count; $index++) {
    $manifestRow = $manifest[$index]
    $harnessRow = $harness[$index]
    $nativeRow = $native[$index]
    $rowNumber = $index + 1

    if ((Get-Field $nativeRow "result_schema_version") -ne "4") {
        $differences += "row $rowNumber is not a schema-4 native result"
    }
    if ((Get-Field $nativeRow "manifest_sha256").ToLowerInvariant() -ne
        $manifestHash) {
        $differences += "row $rowNumber has stale native manifest provenance"
    }
    $nativeIndex = Get-Field $nativeRow "row_index"
    if ($nativeIndex -ne [string]$rowNumber) {
        $differences += "row $rowNumber native row_index is '$nativeIndex'"
    }
    foreach ($field in @("name", "program", "expected_status", "implementation_kind")) {
        $expected = Get-Field $manifestRow $field
        if ((Get-Field $harnessRow $field) -cne $expected) {
            $differences += "row $rowNumber harness $field differs from manifest"
        }
        if ((Get-Field $nativeRow $field) -cne $expected) {
            $differences += "row $rowNumber native $field differs from manifest"
        }
    }

    try {
        $manifestVa = Parse-Number (Get-Field $manifestRow "original_va") `
            "manifest row $rowNumber original_va"
        $harnessVa = Parse-Number (Get-Field $harnessRow "original_va") `
            "harness row $rowNumber original_va"
        $manifestRva = Parse-Number (Get-Field $manifestRow "original_rva") `
            "manifest row $rowNumber original_rva"
        $nativeRva = Parse-Number (Get-Field $nativeRow "original_rva") `
            "native row $rowNumber original_rva"
        if ($harnessVa -ne $manifestVa -or $nativeRva -ne $manifestRva) {
            $differences += "row $rowNumber address identity differs"
        }
    }
    catch {
        $differences += "row $rowNumber address parse failed: $($_.Exception.Message)"
        $manifestRva = 0
    }

    try {
        $expectedOutcome = Get-NativeOutcome $nativeRow
        $actualOutcome = (Get-Field $harnessRow "outcome").ToLowerInvariant()
        if ($actualOutcome -ne $expectedOutcome) {
            $differences += ("row {0} outcome: native {1}, harness {2}" -f
                $rowNumber, $expectedOutcome, $actualOutcome)
        }
        $nativeVerification =
            (Get-Field $nativeRow "verification_status").ToLowerInvariant()
        $expectedCredit = if ($nativeVerification -eq "pass") {
            "yes"
        }
        else {
            "no"
        }
        if ((Get-Field $harnessRow "credited").ToLowerInvariant() -ne $expectedCredit) {
            $differences += "row $rowNumber credit differs from native policy"
        }
        if ($expectedCredit -eq "yes") {
            $programKey = (Get-Field $manifestRow "program").ToLowerInvariant()
            $creditedIdentities += ("{0}|0x{1:x}" -f $programKey, $manifestRva)
        }
    }
    catch {
        $differences += "row $rowNumber status mapping failed: $($_.Exception.Message)"
    }

    $instructionText = Get-Field $harnessRow "instruction_count"
    $instructionCount = 0
    if (-not [int]::TryParse($instructionText, [ref]$instructionCount) -or
        $instructionCount -le 0) {
        $differences += "row $rowNumber has invalid harness instruction_count '$instructionText'"
    }

    $harnessCompared = Get-Field $harnessRow "compared_bytes"
    $nativeCompared = Get-Field $nativeRow "compared_bytes"
    if ($harnessCompared -ne $nativeCompared) {
        $differences += ("row {0} compared_bytes: native={1}, harness={2}" -f
            $rowNumber, $nativeCompared, $harnessCompared)
    }
}

$nativeHash = Get-Sha256 $NativeResultsPath
$maskHash = Get-Sha256 $MaskAuditResultsPath
if ([int]$metrics.schema_version -ne 2) {
    $differences += "metrics summary is not schema 2"
}
if ([string]$metrics.inputs.manifest.sha256 -ne $manifestHash) {
    $differences += "metrics summary manifest hash is stale"
}
if ([string]$metrics.inputs.verifier_results.sha256 -ne $nativeHash) {
    $differences += "metrics summary native-results hash is stale"
}
if ([string]$metrics.inputs.mask_audit_results.sha256 -ne $maskHash) {
    $differences += "metrics summary mask-audit hash is stale"
}

$productSourcePath = Join-Path $repoRoot "tools\otmatch\vc4-exe-product-sources.txt"
if ([string]$metrics.inputs.exe_product_sources.sha256 -ne
    (Get-Sha256 $productSourcePath)) {
    $differences += "metrics summary Product-source hash is stale"
}
$reporterPath = Join-Path $repoRoot "tools\otmatch\report-progress-metrics.ps1"
if ([string]$metrics.inputs.metrics_reporter.sha256 -ne (Get-Sha256 $reporterPath)) {
    $differences += "metrics summary reporter hash is stale"
}
$summaryMetricHashes = @{}
foreach ($inputRecord in @($metrics.inputs.function_metrics)) {
    $summaryMetricHashes[[System.IO.Path]::GetFullPath([string]$inputRecord.path)] =
        ([string]$inputRecord.sha256).ToLowerInvariant()
}
if ($summaryMetricHashes.Count -ne $metricsPaths.Count) {
    $differences += "metrics summary function-inventory input count differs"
}
foreach ($path in $metricsPaths) {
    if (-not $summaryMetricHashes.ContainsKey($path) -or
        $summaryMetricHashes[$path] -ne (Get-Sha256 $path)) {
        $differences += "metrics summary function-inventory hash is stale: $path"
    }
}

$provenanceFields = @(
    @("original_path", "original_file_sha256"),
    @("candidate_path", "candidate_file_sha256"),
    @("candidate_map_path", "candidate_map_sha256")
)
$nativeFileHashes = @{}
foreach ($row in $native) {
    foreach ($pair in $provenanceFields) {
        $pathText = Get-Field $row $pair[0]
        $hashText = (Get-Field $row $pair[1]).ToLowerInvariant()
        if ([string]::IsNullOrWhiteSpace($pathText)) {
            if (-not [string]::IsNullOrWhiteSpace($hashText)) {
                $differences += "native provenance has a hash without a path"
            }
            continue
        }
        $fullPath = [System.IO.Path]::GetFullPath($pathText)
        if ([string]::IsNullOrWhiteSpace($hashText)) {
            $differences += "native provenance has a path without a hash: $fullPath"
            continue
        }
        if ($nativeFileHashes.ContainsKey($fullPath) -and
            $nativeFileHashes[$fullPath] -ne $hashText) {
            $differences += "native provenance has inconsistent hashes: $fullPath"
        }
        $nativeFileHashes[$fullPath] = $hashText
    }
}
foreach ($path in $nativeFileHashes.Keys) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or
        (Get-Sha256 $path) -ne $nativeFileHashes[$path]) {
        $differences += "native provenance is stale: $path"
    }
}

$summaryIdentities = @($metrics.strict.accepted_identities | Sort-Object)
$creditedIdentities = @($creditedIdentities | Sort-Object)
$identityDifference = @(
    Compare-Object -ReferenceObject $summaryIdentities `
        -DifferenceObject $creditedIdentities
)
if ($identityDifference.Count -ne 0) {
    $differences += ("credited identity set differs from strict metrics ({0} entries)" -f
        $identityDifference.Count)
}

$inventory = @()
foreach ($metricsPath in $metricsPaths) {
    $inventory += @(Import-Csv -LiteralPath $metricsPath)
}
$inventoryByIdentity = @{}
$inventoryInstructions = [uint64]0
$inventoryBytes = [uint64]0
foreach ($entry in $inventory) {
    $entryVa = Parse-Number (Get-Field $entry "original_va") "inventory original_va"
    $key = "{0}|{1}" -f (Get-Field $entry "program").ToLowerInvariant(), $entryVa
    if ($inventoryByIdentity.ContainsKey($key)) {
        throw "Duplicate function inventory identity: $key"
    }
    $inventoryByIdentity[$key] = $entry
    $inventoryInstructions += [uint64](Get-Field $entry "instruction_count")
    $inventoryBytes += [uint64](Get-Field $entry "body_bytes")
}

$creditedFunctions = 0
$creditedInstructions = [uint64]0
$creditedBytes = [uint64]0
foreach ($row in $harness) {
    if ((Get-Field $row "credited").ToLowerInvariant() -ne "yes") {
        continue
    }
    $va = Parse-Number (Get-Field $row "original_va") "credited original_va"
    $key = "{0}|{1}" -f (Get-Field $row "program").ToLowerInvariant(), $va
    if (-not $inventoryByIdentity.ContainsKey($key)) {
        $differences += "credited row is absent from function inventory: $key"
        continue
    }
    $entry = $inventoryByIdentity[$key]
    $creditedFunctions++
    $creditedInstructions += [uint64](Get-Field $entry "instruction_count")
    $creditedBytes += [uint64](Get-Field $entry "body_bytes")
}

$metricChecks = @(
    @("denominator functions", [uint64]$metrics.denominator.function_count, [uint64]$inventory.Count),
    @("denominator instructions", [uint64]$metrics.denominator.instruction_count, $inventoryInstructions),
    @("denominator bytes", [uint64]$metrics.denominator.body_byte_count, $inventoryBytes),
    @("credited functions", [uint64]$metrics.strict.accepted_identity_count, [uint64]$creditedFunctions),
    @("credited instructions", [uint64]$metrics.strict.accepted_instructions, $creditedInstructions),
    @("credited bytes", [uint64]$metrics.strict.accepted_body_bytes, $creditedBytes)
)
foreach ($check in $metricChecks) {
    if ($check[1] -ne $check[2]) {
        $differences += "$($check[0]): native=$($check[1]), harness=$($check[2])"
    }
}

foreach ($path in $stableInputs) {
    if ((Get-Sha256 $path) -ne $inputSnapshots[$path]) {
        $differences += "parity input changed during the run: $path"
    }
}

if ($differences.Count -ne 0) {
    $representative = @($differences | Select-Object -First 30) -join "`n  - "
    throw ("decomp-harness parity failed with {0} difference(s):`n  - {1}" -f
        $differences.Count, $representative)
}

$outcomes = $harness | Group-Object outcome | Sort-Object Name |
    ForEach-Object { "{0}={1}" -f $_.Name, $_.Count }
Write-Host ""
Write-Host ("decomp-harness parity PASS: {0} rows ({1})" -f
    $harness.Count, ($outcomes -join ", "))
Write-Host ("  credited functions:    {0}/{1}" -f $creditedFunctions, $inventory.Count)
Write-Host ("  credited instructions: {0}/{1}" -f $creditedInstructions, $inventoryInstructions)
Write-Host ("  credited body bytes:   {0}/{1}" -f $creditedBytes, $inventoryBytes)
Write-Host ("  harness results:        {0}" -f $HarnessResultsPath)
Write-Host ("  native results:         {0}" -f $NativeResultsPath)
