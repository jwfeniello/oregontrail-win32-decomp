[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [Alias("PriorDashboardPath")]
    [string]$PreviousDashboardPath,

    [Parameter(Mandatory = $true)]
    [Alias("PriorReadinessLedgerPath")]
    [string]$PreviousReadinessLedgerPath,

    [Parameter(Mandatory = $true)]
    [Alias("PriorSessionLaneLedgerPath")]
    [string]$PreviousSessionLaneLedgerPath,

    [Parameter(Mandatory = $true)]
    [string]$CurrentDashboardPath,

    [Parameter(Mandatory = $true)]
    [string]$CurrentReadinessTemplatePath,

    [Parameter(Mandatory = $true)]
    [string]$CurrentSessionLaneTemplatePath,

    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,

    [switch]$Force,

    [Parameter(DontShow = $true)]
    [ValidateRange(0, 10000)]
    [int]$BeforePublishDelayMilliseconds = 0
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$utf8Strict = New-Object System.Text.UTF8Encoding($false, $true)
$shaPattern = '^[0-9a-f]{64}$'
$checkpointInputNames = @(
    "manifest_sha256",
    "verifier_results_sha256",
    "progress_metrics_summary_sha256",
    "candidate_file_sha256",
    "candidate_map_sha256",
    "original_exe_sha256",
    "original_dll_sha256")

if ($Force) {
    throw ("-Force is retired for carry-forward publication. Choose a new, " +
        "nonexistent OutputDirectory so the ledger/audit set can be published atomically.")
}

function Get-PropertyValue($Object, [string]$Name, [string]$Description) {
    if ($null -eq $Object -or
        $null -eq $Object.PSObject.Properties[$Name]) {
        throw "$Description is missing '$Name'."
    }
    return $Object.PSObject.Properties[$Name].Value
}

function Get-RequiredText($Object, [string]$Name, [string]$Description) {
    $value = [string](Get-PropertyValue $Object $Name $Description)
    $value = $value.Trim()
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "$Description has an empty '$Name'."
    }
    return $value
}

function Convert-ContractBoolean(
    $Value,
    [string]$FieldName,
    [string]$Description) {

    if ($Value -is [bool]) {
        return [bool]$Value
    }
    $text = ([string]$Value).Trim().ToLowerInvariant()
    if ($text -eq "true") { return $true }
    if ($text -eq "false") { return $false }
    throw "$Description has an invalid $FieldName boolean."
}

function Convert-NonnegativeInt64(
    $Value,
    [string]$FieldName,
    [string]$Description,
    [switch]$AllowEmpty) {

    $text = ([string]$Value).Trim()
    if ([string]::IsNullOrWhiteSpace($text) -and $AllowEmpty) {
        return $null
    }
    $parsed = [int64]0
    if (-not [int64]::TryParse(
            $text,
            [System.Globalization.NumberStyles]::Integer,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [ref]$parsed) -or $parsed -lt 0) {
        throw "$Description has an invalid nonnegative $FieldName."
    }
    return $parsed
}

function Convert-OptionalDouble(
    $Value,
    [string]$FieldName,
    [string]$Description) {

    $text = ([string]$Value).Trim()
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    $parsed = [double]0
    if (-not [double]::TryParse(
            $text,
            [System.Globalization.NumberStyles]::Float,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [ref]$parsed) -or [double]::IsNaN($parsed) -or
        [double]::IsInfinity($parsed)) {
        throw "$Description has an invalid $FieldName."
    }
    return $parsed
}

function Convert-Rva($Value, [string]$Description) {
    $text = ([string]$Value).Trim()
    $parsed = [uint64]0
    if ($text -match '^0[xX]([0-9a-fA-F]+)$') {
        if (-not [uint64]::TryParse(
                $Matches[1],
                [System.Globalization.NumberStyles]::AllowHexSpecifier,
                [System.Globalization.CultureInfo]::InvariantCulture,
                [ref]$parsed)) {
            throw "$Description has an invalid original_rva."
        }
        return $parsed
    }
    if (-not [uint64]::TryParse(
            $text,
            [System.Globalization.NumberStyles]::Integer,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [ref]$parsed)) {
        throw "$Description has an invalid original_rva."
    }
    return $parsed
}

function Get-Identity($Row, [string]$Description) {
    $program = Get-RequiredText $Row "program" $Description
    $rva = Convert-Rva (
        Get-PropertyValue $Row "original_rva" $Description) $Description
    $name = Get-RequiredText $Row "name" $Description
    return [pscustomobject][ordered]@{
        Key = ("{0}|0x{1:x}" -f $program.ToLowerInvariant(), $rva)
        Program = $program
        OriginalRva = $rva
        OriginalRvaText = "0x{0:x}" -f $rva
        Name = $name
    }
}

function Get-FileSha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-BytesSha256([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return [System.BitConverter]::ToString(
            $sha.ComputeHash($Bytes)).Replace("-", "").ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Get-TextSha256([string]$Text) {
    return Get-BytesSha256 $utf8NoBom.GetBytes($Text)
}

function Test-PathInsideRepo([string]$Path) {
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $prefix = $repoRoot.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    return $fullPath.StartsWith(
        $prefix, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-RepoRelativePath([string]$Path) {
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    if (-not (Test-PathInsideRepo $fullPath)) {
        throw "Path is outside the repository: '$fullPath'."
    }
    $prefix = $repoRoot.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    return $fullPath.Substring($prefix.Length).Replace('\', '/')
}

function Assert-NoReparseComponents([string]$Path, [string]$Description) {
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    if (-not (Test-PathInsideRepo $fullPath)) {
        throw "$Description must stay within the repository."
    }
    $relative = Get-RepoRelativePath $fullPath
    $cursor = $repoRoot
    foreach ($component in @($relative -split '[\\/]')) {
        if ([string]::IsNullOrWhiteSpace($component)) { continue }
        $cursor = Join-Path $cursor $component
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force
            if (($item.Attributes -band
                    [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "$Description traverses a reparse point: '$cursor'."
            }
        }
    }
}

function Resolve-InputFile([string]$Path, [string]$Description) {
    $candidate = if ([System.IO.Path]::IsPathRooted($Path)) {
        [System.IO.Path]::GetFullPath($Path)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
    }
    if (-not (Test-PathInsideRepo $candidate)) {
        throw "$Description must stay within the repository."
    }
    Assert-NoReparseComponents $candidate $Description
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        throw "$Description does not exist: '$candidate'."
    }
    return $candidate
}

function Get-InputSnapshot([string]$Path, [string]$Description) {
    [byte[]]$bytes = [System.IO.File]::ReadAllBytes($Path)
    try {
        $text = $utf8Strict.GetString($bytes)
    } catch {
        throw "$Description is not valid UTF-8: '$Path'."
    }
    if ($text.Length -gt 0 -and $text[0] -eq [char]0xfeff) {
        $text = $text.Substring(1)
    }
    return [pscustomobject][ordered]@{
        Path = $Path
        Description = $Description
        Bytes = $bytes
        Text = $text
        Sha256 = Get-BytesSha256 $bytes
    }
}

function Assert-InputSnapshotsUnchanged([object[]]$Snapshots) {
    foreach ($snapshot in $Snapshots) {
        Assert-NoReparseComponents $snapshot.Path $snapshot.Description
        if (-not (Test-Path -LiteralPath $snapshot.Path -PathType Leaf) -or
            (Get-FileSha256 $snapshot.Path) -cne $snapshot.Sha256) {
            throw "$($snapshot.Description) changed during carry-forward execution."
        }
    }
}

function Read-JsonDocument($Snapshot, [string]$Description) {
    try {
        return $Snapshot.Text | ConvertFrom-Json
    } catch {
        throw "Invalid $Description '$($Snapshot.Path)': $($_.Exception.Message)"
    }
}

function Get-NormalizedSha($Value, [string]$FieldName, [string]$Description) {
    $sha = ([string]$Value).Trim().ToLowerInvariant()
    if ($sha -notmatch $shaPattern) {
        throw "$Description has an invalid $FieldName SHA-256."
    }
    return $sha
}

function Get-CheckpointInputs($Ledger, [string]$Description) {
    $inputs = Get-PropertyValue $Ledger "inputs" $Description
    $result = [ordered]@{}
    foreach ($fieldName in $checkpointInputNames) {
        $result[$fieldName] = Get-NormalizedSha (
            Get-PropertyValue $inputs $fieldName "$Description inputs") `
            $fieldName $Description
    }
    return $result
}

function Assert-InputSetsEqual(
    $Left,
    $Right,
    [string]$Description) {

    foreach ($fieldName in $checkpointInputNames) {
        if ([string]$Left[$fieldName] -cne [string]$Right[$fieldName]) {
            throw "$Description input '$fieldName' does not match."
        }
    }
}

function Read-Ledger($Snapshot, [string]$Description) {
    $document = Read-JsonDocument $Snapshot $Description
    $schemaText = ([string](
        Get-PropertyValue $document "schema_version" $Description)).Trim()
    if ($schemaText -cne "1") {
        throw "$Description has unsupported schema_version; expected 1."
    }
    $sessionId = Get-RequiredText $document "session_id" $Description
    if ($sessionId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
        throw "$Description has an invalid session_id."
    }
    $rows = @(Get-PropertyValue $document "rows" $Description)
    return [pscustomobject]@{
        Document = $document
        SessionId = $sessionId
        Inputs = Get-CheckpointInputs $document $Description
        Rows = $rows
    }
}

function Get-DashboardField($Row, [string]$Name, [string]$Description) {
    if ($null -eq $Row.PSObject.Properties[$Name]) {
        throw "$Description is missing dashboard column '$Name'."
    }
    return ([string]$Row.PSObject.Properties[$Name].Value).Trim()
}

function Get-DashboardBinding($Row, [string]$Description) {
    $identityRow = [pscustomobject]@{
        program = Get-DashboardField $Row "Program" $Description
        original_rva = Get-DashboardField $Row "OriginalRva" $Description
        name = Get-DashboardField $Row "Name" $Description
    }
    $identity = Get-Identity $identityRow $Description
    $size = Convert-NonnegativeInt64 (
        Get-DashboardField $Row "Size" $Description) "Size" $Description
    $yield = Convert-NonnegativeInt64 (
        Get-DashboardField $Row "YieldInstructions" $Description) `
        "YieldInstructions" $Description
    $hardDiff = Convert-NonnegativeInt64 (
        Get-DashboardField $Row "HardDiffCount" $Description) `
        "HardDiffCount" $Description
    $compared = Convert-NonnegativeInt64 (
        Get-DashboardField $Row "HardComparedBytes" $Description) `
        "HardComparedBytes" $Description
    if ($compared -le 0 -or $hardDiff -gt $compared) {
        throw "$Description has an invalid hard residual range."
    }

    $candidateFunctionSha = (
        Get-DashboardField $Row "CurrentCandidateFunctionSha256" $Description
        ).ToLowerInvariant()
    $candidateFunctionShaValid = $candidateFunctionSha -match $shaPattern
    $productReachable = (
        Get-DashboardField $Row "ProductReachable" $Description
        ).ToLowerInvariant()
    if ($productReachable -notin @(
            "true", "false", "unknown", "notapplicable")) {
        throw "$Description has an invalid ProductReachable value."
    }

    $binding = [pscustomobject][ordered]@{
        program = $identity.Program.ToLowerInvariant()
        original_rva = $identity.OriginalRvaText
        name = $identity.Name
        size = $size
        product_reachable = $productReachable
        implementation_kind = (
            Get-DashboardField $Row "ImplementationKind" $Description
            ).ToLowerInvariant()
        verifier_diagnostics_available = Convert-ContractBoolean (
            Get-DashboardField $Row "VerifierDiagnosticsAvailable" $Description) `
            "VerifierDiagnosticsAvailable" $Description
        verifier_actual_status = (
            Get-DashboardField $Row "VerifierActualStatus" $Description
            ).ToLowerInvariant()
        verification_status = (
            Get-DashboardField $Row "VerificationStatus" $Description
            ).ToLowerInvariant()
        verifier_blocked = Convert-ContractBoolean (
            Get-DashboardField $Row "VerifierBlocked" $Description) `
            "VerifierBlocked" $Description
        scan_status = Get-DashboardField $Row "Status" $Description
        promotion_ready = Convert-ContractBoolean (
            Get-DashboardField $Row "PromotionReady" $Description) `
            "PromotionReady" $Description
        mask_shape_valid = Convert-ContractBoolean (
            Get-DashboardField $Row "MaskShapeValid" $Description) `
            "MaskShapeValid" $Description
        masked_operand_shape_error = Get-DashboardField `
            $Row "MaskedOperandShapeError" $Description
        masked_import_identity_error = Get-DashboardField `
            $Row "MaskedImportIdentityError" $Description
        mask_sha256 = Get-NormalizedSha (
            Get-DashboardField $Row "MaskSha256" $Description) `
            "MaskSha256" $Description
        yield_instructions = $yield
        hard_diff_count = $hardDiff
        hard_compared_bytes = $compared
        candidate_object = Get-DashboardField $Row "CandidateObject" $Description
        candidate_symbol = Get-DashboardField $Row "CandidateSymbol" $Description
        candidate_function_sha256 = $candidateFunctionSha
    }
    $canonicalJson = $binding | ConvertTo-Json -Depth 8 -Compress
    $healthy = $candidateFunctionShaValid -and
        $binding.verifier_diagnostics_available -and
        -not $binding.verifier_blocked -and
        $binding.scan_status -ceq "OK" -and
        $binding.mask_shape_valid -and
        [string]::IsNullOrWhiteSpace($binding.masked_operand_shape_error) -and
        [string]::IsNullOrWhiteSpace($binding.masked_import_identity_error) -and
        -not [string]::IsNullOrWhiteSpace($binding.verifier_actual_status) -and
        -not [string]::IsNullOrWhiteSpace($binding.verification_status)

    return [pscustomobject]@{
        Identity = $identity
        Binding = $binding
        FingerprintSha256 = Get-TextSha256 $canonicalJson
        CandidateFunctionShaValid = $candidateFunctionShaValid
        Healthy = $healthy
    }
}

function Read-Dashboard($Snapshot, [string]$Description) {
    $rows = @($Snapshot.Text | ConvertFrom-Csv)
    if ($rows.Count -eq 0) {
        throw "$Description has no rows."
    }
    $byKey = @{}
    $candidateFileHashes = @{}
    foreach ($row in $rows) {
        $binding = Get-DashboardBinding $row "$Description row"
        if ($byKey.ContainsKey($binding.Identity.Key)) {
            throw "$Description has duplicate identity '$($binding.Identity.Key)'."
        }
        $candidateFileSha = Get-NormalizedSha (
            Get-DashboardField $row "CurrentCandidateFileSha256" `
                "$Description row '$($binding.Identity.Name)'") `
            "CurrentCandidateFileSha256" $Description
        $candidateFileHashes[$candidateFileSha] = $true
        $byKey[$binding.Identity.Key] = $binding
    }
    if ($candidateFileHashes.Count -ne 1) {
        throw "$Description does not bind exactly one candidate file SHA-256."
    }
    return [pscustomobject]@{
        Rows = $rows
        ByKey = $byKey
        CandidateFileSha256 = [string]@($candidateFileHashes.Keys)[0]
    }
}

function Assert-DashboardCheckpoint(
    $Dashboard,
    $Inputs,
    [string]$Description) {

    if ($Dashboard.CandidateFileSha256 -cne
        [string]$Inputs["candidate_file_sha256"]) {
        throw "$Description candidate file does not match its checkpoint inputs."
    }
}

function Assert-ValidReadinessRow($Row, [string]$Description) {
    $identity = Get-Identity $Row $Description
    $readiness = (Get-RequiredText $Row "readiness" $Description).ToLowerInvariant()
    if ($readiness -notin @("ready", "needs-implementation", "blocked")) {
        throw "$Description has invalid readiness '$readiness'."
    }
    $dependency = (
        Get-RequiredText $Row "dependency_state" $Description).ToLowerInvariant()
    if ($dependency -notin @("ready", "incomplete", "blocked")) {
        throw "$Description has invalid dependency_state '$dependency'."
    }
    if ($readiness -eq "ready" -and $dependency -ne "ready") {
        throw "$Description cannot be ready with dependency_state '$dependency'."
    }
    $reason = Get-RequiredText $Row "reason" $Description
    $templateDefault = Convert-ContractBoolean (
        Get-PropertyValue $Row "template_default" $Description) `
        "template_default" $Description
    if ($templateDefault -and
        ($readiness -ne "needs-implementation" -or $dependency -ne "incomplete")) {
        throw "$Description has a non-fail-closed template default."
    }
    $evidencePath = ([string](
        Get-PropertyValue $Row "evidence_path" $Description)).Trim()
    $evidenceSha = ([string](
        Get-PropertyValue $Row "evidence_sha256" $Description)).Trim().ToLowerInvariant()
    if ($templateDefault) {
        if (-not [string]::IsNullOrWhiteSpace($evidencePath) -or
            -not [string]::IsNullOrWhiteSpace($evidenceSha)) {
            throw "$Description template default must not contain evidence."
        }
    } else {
        if ([string]::IsNullOrWhiteSpace($evidencePath)) {
            throw "$Description is missing evidence_path."
        }
        $evidenceSha = Get-NormalizedSha $evidenceSha "evidence" $Description
    }

    $confidence = Convert-OptionalDouble (
        Get-PropertyValue $Row "confidence" $Description) "confidence" $Description
    if ($null -ne $confidence -and ($confidence -lt 0 -or $confidence -gt 1)) {
        throw "$Description confidence must be between zero and one."
    }
    $effort = Convert-OptionalDouble (
        Get-PropertyValue $Row "effort" $Description) "effort" $Description
    if ($null -ne $effort -and $effort -le 0) {
        throw "$Description effort must be greater than zero."
    }
    [void](Convert-NonnegativeInt64 (
        Get-PropertyValue $Row "candidate_body_bytes" $Description) `
        "candidate_body_bytes" $Description -AllowEmpty)
    [void](Convert-NonnegativeInt64 (
        Get-PropertyValue $Row "candidate_instruction_count" $Description) `
        "candidate_instruction_count" $Description -AllowEmpty)

    return [pscustomobject]@{
        Identity = $identity
        Readiness = $readiness
        DependencyState = $dependency
        Reason = $reason
        TemplateDefault = $templateDefault
        EvidencePath = $evidencePath
        EvidenceSha256 = $evidenceSha
        Confidence = Get-PropertyValue $Row "confidence" $Description
        Effort = Get-PropertyValue $Row "effort" $Description
        CandidateBodyBytes = Get-PropertyValue `
            $Row "candidate_body_bytes" $Description
        CandidateInstructionCount = Get-PropertyValue `
            $Row "candidate_instruction_count" $Description
    }
}

function Assert-ValidSessionRow($Row, [string]$Description) {
    $identity = Get-Identity $Row $Description
    $state = (Get-RequiredText $Row "state" $Description).ToLowerInvariant()
    if ($state -notin @("active", "paused", "frozen", "closed")) {
        throw "$Description has invalid state '$state'."
    }
    $hypothesis = Get-RequiredText $Row "hypothesis" $Description
    $started = Get-RequiredText $Row "started_utc" $Description
    $updated = Get-RequiredText $Row "updated_utc" $Description
    $startedTime = [DateTimeOffset]::MinValue
    $updatedTime = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParse($started, [ref]$startedTime) -or
        -not [DateTimeOffset]::TryParse($updated, [ref]$updatedTime) -or
        $updatedTime -lt $startedTime) {
        throw "$Description has invalid session timestamps."
    }
    $minutes = Convert-OptionalDouble (
        Get-PropertyValue $Row "active_recovery_minutes" $Description) `
        "active_recovery_minutes" $Description
    if ($null -eq $minutes -or $minutes -lt 0) {
        throw "$Description has invalid active_recovery_minutes."
    }
    $toolTime = Convert-NonnegativeInt64 (
        Get-PropertyValue $Row "tool_time_ms" $Description) `
        "tool_time_ms" $Description
    $variants = Convert-NonnegativeInt64 (
        Get-PropertyValue $Row "meaningful_variant_count" $Description) `
        "meaningful_variant_count" $Description
    if ($state -eq "frozen" -and $variants -lt 8) {
        throw "$Description frozen state requires at least eight meaningful variants."
    }

    $evidencePath = ([string](
        Get-PropertyValue $Row "evidence_path" $Description)).Trim()
    $evidenceSha = ([string](
        Get-PropertyValue $Row "evidence_sha256" $Description)).Trim().ToLowerInvariant()
    if ($state -ne "active" -or
        -not [string]::IsNullOrWhiteSpace($evidencePath) -or
        -not [string]::IsNullOrWhiteSpace($evidenceSha)) {
        if ([string]::IsNullOrWhiteSpace($evidencePath)) {
            throw "$Description is missing evidence_path."
        }
        $evidenceSha = Get-NormalizedSha $evidenceSha "evidence" $Description
    }
    $sourcePath = Get-RequiredText $Row "source_path" $Description
    $sourceSha = Get-NormalizedSha (
        Get-PropertyValue $Row "source_sha256" $Description) `
        "source" $Description

    $residual = Get-PropertyValue $Row "residual" $Description
    $kind = (Get-RequiredText $residual "kind" "$Description residual").ToLowerInvariant()
    if ($kind -ne "strict-linked") {
        throw "$Description has unsupported residual kind '$kind'."
    }
    $hardDiff = Convert-NonnegativeInt64 (
        Get-PropertyValue $residual "hard_diff_count" "$Description residual") `
        "hard_diff_count" "$Description residual"
    $compared = Convert-NonnegativeInt64 (
        Get-PropertyValue $residual "compared_bytes" "$Description residual") `
        "compared_bytes" "$Description residual"
    if ($compared -le 0 -or $hardDiff -gt $compared) {
        throw "$Description has an invalid strict-linked residual range."
    }
    if (($state -eq "closed" -and $hardDiff -ne 0) -or
        ($state -ne "closed" -and $hardDiff -eq 0)) {
        throw "$Description state '$state' does not agree with its residual."
    }
    $functionSha = Get-NormalizedSha (
        Get-PropertyValue $residual "candidate_function_sha256" `
            "$Description residual") "candidate_function" $Description

    return [pscustomobject]@{
        Identity = $identity
        State = $state
        Hypothesis = $hypothesis
        StartedUtc = $started
        UpdatedUtc = $updated
        ActiveRecoveryMinutes = $minutes
        ToolTimeMs = $toolTime
        MeaningfulVariantCount = $variants
        EvidencePath = $evidencePath
        EvidenceSha256 = $evidenceSha
        SourcePath = $sourcePath
        SourceSha256 = $sourceSha
        ResidualKind = $kind
        HardDiffCount = $hardDiff
        ComparedBytes = $compared
        CandidateFunctionSha256 = $functionSha
    }
}

function Assert-ValidSessionRowTemplate($Row, [string]$Description) {
    foreach ($fieldName in @(
            "program", "original_rva", "name", "hypothesis", "started_utc",
            "updated_utc", "evidence_path", "evidence_sha256", "source_path",
            "source_sha256", "candidate_function_sha256")) {
        $container = $Row
        if ($fieldName -eq "candidate_function_sha256") {
            $container = Get-PropertyValue $Row "residual" $Description
        }
        if (-not [string]::IsNullOrWhiteSpace([string](
                Get-PropertyValue $container $fieldName $Description))) {
            throw "$Description field '$fieldName' must be empty."
        }
    }
    if (([string](Get-PropertyValue $Row "state" $Description)).Trim() -cne
        "active") {
        throw "$Description must use state active."
    }
    foreach ($fieldName in @(
            "active_recovery_minutes", "tool_time_ms",
            "meaningful_variant_count")) {
        if ((Convert-NonnegativeInt64 (
                Get-PropertyValue $Row $fieldName $Description) `
                $fieldName $Description) -ne 0) {
            throw "$Description field '$fieldName' must be zero."
        }
    }
    $residual = Get-PropertyValue $Row "residual" $Description
    if (([string](Get-PropertyValue $residual "kind" $Description)).Trim() -cne
        "strict-linked") {
        throw "$Description residual kind must be strict-linked."
    }
    foreach ($fieldName in @("hard_diff_count", "compared_bytes")) {
        if ((Convert-NonnegativeInt64 (
                Get-PropertyValue $residual $fieldName $Description) `
                $fieldName $Description) -ne 0) {
            throw "$Description residual field '$fieldName' must be zero."
        }
    }
}

function Resolve-RecordedFileBinding(
    [string]$RecordedPath,
    [string]$RecordedSha256,
    [string]$Description,
    [switch]$AllowEmpty) {

    if ([string]::IsNullOrWhiteSpace($RecordedPath) -and
        [string]::IsNullOrWhiteSpace($RecordedSha256) -and $AllowEmpty) {
        return [pscustomobject][ordered]@{
            path = ""
            recorded_sha256 = ""
            current_sha256 = ""
            state = "empty"
        }
    }
    $fullPath = if ([System.IO.Path]::IsPathRooted($RecordedPath)) {
        [System.IO.Path]::GetFullPath($RecordedPath)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $RecordedPath))
    }
    if (-not (Test-PathInsideRepo $fullPath)) {
        throw "$Description path must stay within the repository."
    }
    Assert-NoReparseComponents $fullPath "$Description path"
    $currentSha = ""
    $state = "missing"
    if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
        $currentSha = Get-FileSha256 $fullPath
        $state = if ($currentSha -ceq $RecordedSha256) { "current" } else { "stale" }
    }
    return [pscustomobject][ordered]@{
        path = Get-RepoRelativePath $fullPath
        recorded_sha256 = $RecordedSha256
        current_sha256 = $currentSha
        state = $state
    }
}

function Compare-DashboardBindings($Old, $New) {
    $reasons = New-Object System.Collections.Generic.List[string]
    if ($Old.Identity.Name -cne $New.Identity.Name -or
        $Old.Binding.size -ne $New.Binding.size) {
        $reasons.Add("row_identity_changed")
    }
    if ($Old.Binding.product_reachable -cne $New.Binding.product_reachable) {
        $reasons.Add("product_reachability_changed")
    }
    if ($Old.Binding.implementation_kind -cne $New.Binding.implementation_kind) {
        $reasons.Add("implementation_kind_changed")
    }
    if ($Old.Binding.mask_sha256 -cne $New.Binding.mask_sha256) {
        $reasons.Add("mask_changed")
    }
    $verifierFields = @(
        "verifier_diagnostics_available", "verifier_actual_status",
        "verification_status", "verifier_blocked", "scan_status",
        "promotion_ready", "mask_shape_valid", "masked_operand_shape_error",
        "masked_import_identity_error")
    foreach ($field in $verifierFields) {
        if ([string]$Old.Binding.$field -cne [string]$New.Binding.$field) {
            if (-not $reasons.Contains("verifier_status_changed")) {
                $reasons.Add("verifier_status_changed")
            }
        }
    }
    if (-not $Old.Healthy -or -not $New.Healthy) {
        $reasons.Add("verifier_not_reproducible")
    }
    if ($Old.Binding.yield_instructions -ne $New.Binding.yield_instructions) {
        $reasons.Add("instruction_yield_changed")
    }
    if ($Old.Binding.hard_diff_count -ne $New.Binding.hard_diff_count) {
        $reasons.Add("hard_residual_changed")
    }
    if ($Old.Binding.hard_compared_bytes -ne $New.Binding.hard_compared_bytes) {
        $reasons.Add("compared_bytes_changed")
    }
    if ($Old.Binding.candidate_object -cne $New.Binding.candidate_object) {
        $reasons.Add("candidate_object_changed")
    }
    if ($Old.Binding.candidate_symbol -cne $New.Binding.candidate_symbol) {
        $reasons.Add("candidate_identity_changed")
    }
    if (-not $Old.CandidateFunctionShaValid -or
        -not $New.CandidateFunctionShaValid) {
        $reasons.Add("candidate_function_sha256_invalid")
    } elseif ($Old.Binding.candidate_function_sha256 -cne
        $New.Binding.candidate_function_sha256) {
        $reasons.Add("candidate_function_sha256_changed")
    }
    if ($reasons.Count -eq 0 -and
        $Old.FingerprintSha256 -cne $New.FingerprintSha256) {
        $reasons.Add("row_fingerprint_changed")
    }
    return @($reasons)
}

function New-ReadinessOutputRow($Current, $Old) {
    if ($null -eq $Old) {
        return [pscustomobject][ordered]@{
            program = $Current.Identity.Program
            original_rva = $Current.Identity.OriginalRvaText
            name = $Current.Identity.Name
            readiness = $Current.Readiness
            dependency_state = $Current.DependencyState
            reason = $Current.Reason
            template_default = $true
            evidence_path = ""
            evidence_sha256 = ""
            confidence = $Current.Confidence
            effort = $Current.Effort
            candidate_body_bytes = $Current.CandidateBodyBytes
            candidate_instruction_count = $Current.CandidateInstructionCount
        }
    }
    return [pscustomobject][ordered]@{
        program = $Current.Identity.Program
        original_rva = $Current.Identity.OriginalRvaText
        name = $Current.Identity.Name
        readiness = $Old.Readiness
        dependency_state = $Old.DependencyState
        reason = $Old.Reason
        template_default = $false
        evidence_path = $Old.EvidencePath
        evidence_sha256 = $Old.EvidenceSha256
        confidence = $Old.Confidence
        effort = $Old.Effort
        candidate_body_bytes = $Old.CandidateBodyBytes
        candidate_instruction_count = $Old.CandidateInstructionCount
    }
}

function New-SessionOutputRow($CurrentDashboard, $Old) {
    return [pscustomobject][ordered]@{
        program = $CurrentDashboard.Identity.Program
        original_rva = $CurrentDashboard.Identity.OriginalRvaText
        name = $CurrentDashboard.Identity.Name
        state = $Old.State
        hypothesis = $Old.Hypothesis
        started_utc = $Old.StartedUtc
        updated_utc = $Old.UpdatedUtc
        active_recovery_minutes = $Old.ActiveRecoveryMinutes
        tool_time_ms = $Old.ToolTimeMs
        meaningful_variant_count = $Old.MeaningfulVariantCount
        evidence_path = $Old.EvidencePath
        evidence_sha256 = $Old.EvidenceSha256
        source_path = $Old.SourcePath
        source_sha256 = $Old.SourceSha256
        residual = [pscustomobject][ordered]@{
            kind = $Old.ResidualKind
            hard_diff_count = $Old.HardDiffCount
            compared_bytes = $Old.ComparedBytes
            candidate_function_sha256 = $Old.CandidateFunctionSha256
        }
    }
}

function New-AuditBinding($Old, $New) {
    return [pscustomobject][ordered]@{
        previous_row_fingerprint_sha256 = if ($null -ne $Old) {
            $Old.FingerprintSha256
        } else { "" }
        current_row_fingerprint_sha256 = if ($null -ne $New) {
            $New.FingerprintSha256
        } else { "" }
        previous_candidate_function_sha256 = if ($null -ne $Old) {
            $Old.Binding.candidate_function_sha256
        } else { "" }
        current_candidate_function_sha256 = if ($null -ne $New) {
            $New.Binding.candidate_function_sha256
        } else { "" }
        previous_mask_sha256 = if ($null -ne $Old) {
            $Old.Binding.mask_sha256
        } else { "" }
        current_mask_sha256 = if ($null -ne $New) {
            $New.Binding.mask_sha256
        } else { "" }
        previous_hard_diff_count = if ($null -ne $Old) {
            $Old.Binding.hard_diff_count
        } else { "" }
        current_hard_diff_count = if ($null -ne $New) {
            $New.Binding.hard_diff_count
        } else { "" }
        previous_compared_bytes = if ($null -ne $Old) {
            $Old.Binding.hard_compared_bytes
        } else { "" }
        current_compared_bytes = if ($null -ne $New) {
            $New.Binding.hard_compared_bytes
        } else { "" }
        previous_candidate_object = if ($null -ne $Old) {
            $Old.Binding.candidate_object
        } else { "" }
        current_candidate_object = if ($null -ne $New) {
            $New.Binding.candidate_object
        } else { "" }
    }
}

function Escape-Markdown([string]$Text) {
    return $Text.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Get-SnapshotPathRecord($Snapshot) {
    return [pscustomobject][ordered]@{
        path = Get-RepoRelativePath $Snapshot.Path
        sha256 = $Snapshot.Sha256
    }
}

$previousDashboardFullPath = Resolve-InputFile `
    $PreviousDashboardPath "Previous dashboard"
$previousReadinessFullPath = Resolve-InputFile `
    $PreviousReadinessLedgerPath "Previous readiness ledger"
$previousSessionFullPath = Resolve-InputFile `
    $PreviousSessionLaneLedgerPath "Previous session lane ledger"
$currentDashboardFullPath = Resolve-InputFile `
    $CurrentDashboardPath "Current dashboard"
$currentReadinessFullPath = Resolve-InputFile `
    $CurrentReadinessTemplatePath "Current readiness template"
$currentSessionFullPath = Resolve-InputFile `
    $CurrentSessionLaneTemplatePath "Current session lane template"

$previousDashboardSnapshot = Get-InputSnapshot `
    $previousDashboardFullPath "Previous dashboard"
$previousReadinessSnapshot = Get-InputSnapshot `
    $previousReadinessFullPath "Previous readiness ledger"
$previousSessionSnapshot = Get-InputSnapshot `
    $previousSessionFullPath "Previous session lane ledger"
$currentDashboardSnapshot = Get-InputSnapshot `
    $currentDashboardFullPath "Current dashboard"
$currentReadinessSnapshot = Get-InputSnapshot `
    $currentReadinessFullPath "Current readiness template"
$currentSessionSnapshot = Get-InputSnapshot `
    $currentSessionFullPath "Current session lane template"
$inputSnapshots = @(
    $previousDashboardSnapshot, $previousReadinessSnapshot,
    $previousSessionSnapshot, $currentDashboardSnapshot,
    $currentReadinessSnapshot, $currentSessionSnapshot)

$previousReadinessLedger = Read-Ledger `
    $previousReadinessSnapshot "Previous readiness ledger"
$previousSessionLedger = Read-Ledger `
    $previousSessionSnapshot "Previous session lane ledger"
$currentReadinessTemplate = Read-Ledger `
    $currentReadinessSnapshot "Current readiness template"
$currentSessionTemplate = Read-Ledger `
    $currentSessionSnapshot "Current session lane template"

if ($previousReadinessLedger.SessionId -cne $previousSessionLedger.SessionId) {
    throw "Previous readiness and session lane ledgers have different session_id values."
}
if ($currentReadinessTemplate.SessionId -cne $currentSessionTemplate.SessionId) {
    throw "Current readiness and session lane templates have different session_id values."
}
Assert-InputSetsEqual $previousReadinessLedger.Inputs `
    $previousSessionLedger.Inputs "Previous recovery ledgers"
Assert-InputSetsEqual $currentReadinessTemplate.Inputs `
    $currentSessionTemplate.Inputs "Current recovery templates"

$previousDashboard = Read-Dashboard `
    $previousDashboardSnapshot "Previous dashboard"
$currentDashboard = Read-Dashboard `
    $currentDashboardSnapshot "Current dashboard"
Assert-DashboardCheckpoint $previousDashboard `
    $previousReadinessLedger.Inputs "Previous dashboard"
Assert-DashboardCheckpoint $currentDashboard `
    $currentReadinessTemplate.Inputs "Current dashboard"

$previousReadinessByKey = @{}
foreach ($row in $previousReadinessLedger.Rows) {
    $validated = Assert-ValidReadinessRow $row "Previous readiness row"
    $key = $validated.Identity.Key
    if ($previousReadinessByKey.ContainsKey($key)) {
        throw "Previous readiness ledger has duplicate identity '$key'."
    }
    if (-not $previousDashboard.ByKey.ContainsKey($key)) {
        throw "Previous readiness identity '$key' is absent from its dashboard."
    }
    if ($validated.Identity.Name -cne
        $previousDashboard.ByKey[$key].Identity.Name) {
        throw "Previous readiness identity '$key' has a dashboard name mismatch."
    }
    $previousReadinessByKey[$key] = $validated
}

$currentReadinessByKey = @{}
foreach ($row in $currentReadinessTemplate.Rows) {
    $validated = Assert-ValidReadinessRow $row "Current readiness template row"
    $key = $validated.Identity.Key
    if ($currentReadinessByKey.ContainsKey($key)) {
        throw "Current readiness template has duplicate identity '$key'."
    }
    if (-not $validated.TemplateDefault) {
        throw "Current readiness template row '$key' is not fail closed."
    }
    if (-not $currentDashboard.ByKey.ContainsKey($key)) {
        throw "Current readiness template identity '$key' is absent from its dashboard."
    }
    if ($validated.Identity.Name -cne $currentDashboard.ByKey[$key].Identity.Name) {
        throw "Current readiness template identity '$key' has a dashboard name mismatch."
    }
    $currentReadinessByKey[$key] = $validated
}
if ($currentReadinessByKey.Count -ne $currentDashboard.ByKey.Count) {
    throw "Current readiness template and dashboard identity universes differ."
}

$previousSessionByKey = @{}
foreach ($row in $previousSessionLedger.Rows) {
    $validated = Assert-ValidSessionRow $row "Previous session lane row"
    $key = $validated.Identity.Key
    if ($previousSessionByKey.ContainsKey($key)) {
        throw "Previous session lane ledger has duplicate identity '$key'."
    }
    if (-not $previousDashboard.ByKey.ContainsKey($key)) {
        throw "Previous session lane identity '$key' is absent from its dashboard."
    }
    if ($validated.Identity.Name -cne $previousDashboard.ByKey[$key].Identity.Name) {
        throw "Previous session lane identity '$key' has a dashboard name mismatch."
    }
    $previousSessionByKey[$key] = $validated
}

if ($currentSessionTemplate.Rows.Count -ne 0) {
    throw "Current session lane template must have an empty rows array."
}
$sessionRowTemplate = Get-PropertyValue `
    $currentSessionTemplate.Document "row_template" "Current session lane template"
Assert-ValidSessionRowTemplate $sessionRowTemplate `
    "Current session lane row_template"

$readinessAuditRows = @()
$readinessCarryByKey = @{}
foreach ($key in @($previousReadinessByKey.Keys | Sort-Object)) {
    $oldReadiness = $previousReadinessByKey[$key]
    if ($oldReadiness.TemplateDefault) { continue }
    $reasons = New-Object System.Collections.Generic.List[string]
    $oldDashboardRow = $previousDashboard.ByKey[$key]
    $newDashboardRow = if ($currentDashboard.ByKey.ContainsKey($key)) {
        $currentDashboard.ByKey[$key]
    } else { $null }
    if ($null -eq $newDashboardRow -or
        -not $currentReadinessByKey.ContainsKey($key)) {
        $reasons.Add("identity_absent_from_current_checkpoint")
    } else {
        foreach ($reason in @(Compare-DashboardBindings `
                $oldDashboardRow $newDashboardRow)) {
            $reasons.Add($reason)
        }
    }
    $evidence = Resolve-RecordedFileBinding `
        $oldReadiness.EvidencePath $oldReadiness.EvidenceSha256 `
        "Readiness evidence for '$($oldReadiness.Identity.Name)'"
    if ($evidence.state -ne "current") {
        $reasons.Add("readiness_evidence_$($evidence.state)")
    }
    $decision = if ($reasons.Count -eq 0) { "carried" } else { "review-required" }
    if ($decision -eq "carried") {
        $readinessCarryByKey[$key] = $oldReadiness
    }
    $readinessAuditRows += [pscustomobject][ordered]@{
        program = $oldReadiness.Identity.Program
        original_rva = $oldReadiness.Identity.OriginalRvaText
        name = $oldReadiness.Identity.Name
        previous_readiness = $oldReadiness.Readiness
        previous_dependency_state = $oldReadiness.DependencyState
        decision = $decision
        reasons = @($reasons)
        binding = New-AuditBinding $oldDashboardRow $newDashboardRow
        evidence = $evidence
    }
}

$readinessOutputRows = @()
foreach ($key in @($currentReadinessByKey.Keys | Sort-Object)) {
    $oldReadiness = if ($readinessCarryByKey.ContainsKey($key)) {
        $readinessCarryByKey[$key]
    } else { $null }
    $readinessOutputRows += New-ReadinessOutputRow `
        $currentReadinessByKey[$key] $oldReadiness
}

$sessionAuditRows = @()
$sessionOutputRows = @()
foreach ($key in @($previousSessionByKey.Keys | Sort-Object)) {
    $oldSession = $previousSessionByKey[$key]
    $reasons = New-Object System.Collections.Generic.List[string]
    $oldDashboardRow = $previousDashboard.ByKey[$key]
    $newDashboardRow = if ($currentDashboard.ByKey.ContainsKey($key)) {
        $currentDashboard.ByKey[$key]
    } else { $null }
    if ($oldSession.State -notin @("paused", "frozen", "closed")) {
        $reasons.Add("active_session_lane_not_transferable")
    }
    if ($null -eq $newDashboardRow) {
        $reasons.Add("identity_absent_from_current_checkpoint")
    } else {
        foreach ($reason in @(Compare-DashboardBindings `
                $oldDashboardRow $newDashboardRow)) {
            $reasons.Add($reason)
        }
        if ($oldSession.ResidualKind -cne "strict-linked" -or
            $oldSession.HardDiffCount -ne $newDashboardRow.Binding.hard_diff_count -or
            $oldSession.ComparedBytes -ne
                $newDashboardRow.Binding.hard_compared_bytes -or
            $oldSession.CandidateFunctionSha256 -cne
                $newDashboardRow.Binding.candidate_function_sha256) {
            $reasons.Add("session_residual_not_reproduced")
        }
    }
    $source = Resolve-RecordedFileBinding `
        $oldSession.SourcePath $oldSession.SourceSha256 `
        "Session source for '$($oldSession.Identity.Name)'"
    $evidence = Resolve-RecordedFileBinding `
        $oldSession.EvidencePath $oldSession.EvidenceSha256 `
        "Session evidence for '$($oldSession.Identity.Name)'" `
        -AllowEmpty:($oldSession.State -eq "active")
    if ($source.state -ne "current") {
        $reasons.Add("session_source_$($source.state)")
    }
    if ($evidence.state -notin @("current", "empty")) {
        $reasons.Add("session_evidence_$($evidence.state)")
    }
    $decision = if ($reasons.Count -eq 0) { "carried" } else { "review-required" }
    if ($decision -eq "carried") {
        $sessionOutputRows += New-SessionOutputRow $newDashboardRow $oldSession
    }
    $sessionAuditRows += [pscustomobject][ordered]@{
        program = $oldSession.Identity.Program
        original_rva = $oldSession.Identity.OriginalRvaText
        name = $oldSession.Identity.Name
        previous_state = $oldSession.State
        decision = $decision
        reasons = @($reasons)
        binding = New-AuditBinding $oldDashboardRow $newDashboardRow
        source = $source
        evidence = $evidence
    }
}

$outputFullPath = if ([System.IO.Path]::IsPathRooted($OutputDirectory)) {
    [System.IO.Path]::GetFullPath($OutputDirectory)
} else {
    [System.IO.Path]::GetFullPath((Join-Path $repoRoot $OutputDirectory))
}
if (-not (Test-PathInsideRepo $outputFullPath)) {
    throw "OutputDirectory must stay within the repository."
}
$outputRelative = Get-RepoRelativePath $outputFullPath
$outputComponents = @($outputRelative -split '[\\/]')
$outputRootComponent = $outputComponents[0].ToLowerInvariant()
if ($outputRootComponent -notin @("a", "artifacts")) {
    throw "OutputDirectory must be under the ignored a/ or artifacts/ tree."
}
if ($outputComponents.Count -lt 2) {
    throw "OutputDirectory must name a new child directory beneath a/ or artifacts/."
}
& git -C $repoRoot check-ignore --quiet -- $outputRelative
if ($LASTEXITCODE -ne 0) {
    throw "OutputDirectory is not Git-ignored: '$outputFullPath'."
}
Assert-NoReparseComponents $outputFullPath "OutputDirectory"
if (Test-Path -LiteralPath $outputFullPath -PathType Leaf) {
    throw "OutputDirectory names an existing file."
}

$readinessOutputPath = Join-Path $outputFullPath "readiness-ledger.json"
$sessionOutputPath = Join-Path $outputFullPath "session-lane-ledger.json"
$auditJsonPath = Join-Path $outputFullPath "carry-forward-audit.json"
$auditMarkdownPath = Join-Path $outputFullPath "carry-forward-audit.md"
$inputPaths = @($inputSnapshots | ForEach-Object { $_.Path })
foreach ($outputPath in @(
        $readinessOutputPath, $sessionOutputPath,
        $auditJsonPath, $auditMarkdownPath)) {
    foreach ($inputPath in $inputPaths) {
        if ($outputPath.Equals(
                $inputPath, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "An output path would overwrite an input: '$outputPath'."
        }
    }
}
if (Test-Path -LiteralPath $outputFullPath) {
    throw ("OutputDirectory must not already exist; choose a new directory for " +
        "atomic publication: '$outputFullPath'.")
}

$currentInputsObject = [pscustomobject][ordered]@{}
foreach ($fieldName in $checkpointInputNames) {
    $currentInputsObject | Add-Member -NotePropertyName $fieldName `
        -NotePropertyValue $currentReadinessTemplate.Inputs[$fieldName]
}
$readinessOutput = [pscustomobject][ordered]@{
    schema_version = 1
    session_id = $currentReadinessTemplate.SessionId
    inputs = $currentInputsObject
    rows = $readinessOutputRows
}
$sessionOutput = [pscustomobject][ordered]@{
    schema_version = 1
    session_id = $currentSessionTemplate.SessionId
    inputs = $currentInputsObject
    row_template = $sessionRowTemplate
    rows = $sessionOutputRows
}
$readinessJson = ($readinessOutput | ConvertTo-Json -Depth 20) + "`n"
$sessionJson = ($sessionOutput | ConvertTo-Json -Depth 20) + "`n"
$readinessOutputSha = Get-TextSha256 $readinessJson
$sessionOutputSha = Get-TextSha256 $sessionJson

$readinessCarried = @($readinessAuditRows | Where-Object {
    $_.decision -eq "carried" }).Count
$readinessReview = @($readinessAuditRows | Where-Object {
    $_.decision -eq "review-required" }).Count
$sessionCarried = @($sessionAuditRows | Where-Object {
    $_.decision -eq "carried" }).Count
$sessionReview = @($sessionAuditRows | Where-Object {
    $_.decision -eq "review-required" }).Count

$audit = [pscustomobject][ordered]@{
    schema_version = 1
    artifact_type = "otmatch-recovery-ledger-carry-forward-audit"
    generated_utc = [DateTimeOffset]::UtcNow.ToString("o")
    generator = [pscustomobject][ordered]@{
        path = Get-RepoRelativePath $PSCommandPath
        sha256 = Get-FileSha256 $PSCommandPath
    }
    previous_session_id = $previousReadinessLedger.SessionId
    current_session_id = $currentReadinessTemplate.SessionId
    previous_inputs = [pscustomobject]$previousReadinessLedger.Inputs
    current_inputs = [pscustomobject]$currentReadinessTemplate.Inputs
    files = [pscustomobject][ordered]@{
        previous_dashboard = Get-SnapshotPathRecord $previousDashboardSnapshot
        previous_readiness_ledger = Get-SnapshotPathRecord $previousReadinessSnapshot
        previous_session_lane_ledger = Get-SnapshotPathRecord $previousSessionSnapshot
        current_dashboard = Get-SnapshotPathRecord $currentDashboardSnapshot
        current_readiness_template = Get-SnapshotPathRecord $currentReadinessSnapshot
        current_session_lane_template = Get-SnapshotPathRecord $currentSessionSnapshot
        output_readiness_ledger = [pscustomobject][ordered]@{
            path = Get-RepoRelativePath $readinessOutputPath
            sha256 = $readinessOutputSha
        }
        output_session_lane_ledger = [pscustomobject][ordered]@{
            path = Get-RepoRelativePath $sessionOutputPath
            sha256 = $sessionOutputSha
        }
    }
    summary = [pscustomobject][ordered]@{
        readiness_non_template_candidates = $readinessAuditRows.Count
        readiness_carried = $readinessCarried
        readiness_review_required = $readinessReview
        readiness_template_defaults_preserved = `
            $readinessOutputRows.Count - $readinessCarried
        session_candidates = $sessionAuditRows.Count
        session_carried = $sessionCarried
        session_review_required = $sessionReview
    }
    readiness_rows = $readinessAuditRows
    session_rows = $sessionAuditRows
}
$auditJson = ($audit | ConvertTo-Json -Depth 24) + "`n"

$markdown = New-Object System.Collections.Generic.List[string]
$markdown.Add("# Recovery ledger carry-forward audit")
$markdown.Add("")
$markdown.Add("This report records a fail-closed carry from ``$($previousReadinessLedger.SessionId)`` to ``$($currentReadinessTemplate.SessionId)``. No row was promoted and no template row was made ready without a reproduced prior decision.")
$markdown.Add("")
$markdown.Add("## Summary")
$markdown.Add("")
$markdown.Add("| Ledger | Candidates | Carried | Review required |")
$markdown.Add("| --- | ---: | ---: | ---: |")
$markdown.Add("| Readiness | $($readinessAuditRows.Count) | $readinessCarried | $readinessReview |")
$markdown.Add("| Session lanes | $($sessionAuditRows.Count) | $sessionCarried | $sessionReview |")
$markdown.Add("")
$markdown.Add("## Checkpoint inputs")
$markdown.Add("")
$markdown.Add("| Input | Previous SHA-256 | Current SHA-256 |")
$markdown.Add("| --- | --- | --- |")
foreach ($fieldName in $checkpointInputNames) {
    $markdown.Add("| $fieldName | ``$($previousReadinessLedger.Inputs[$fieldName])`` | ``$($currentReadinessTemplate.Inputs[$fieldName])`` |")
}
$markdown.Add("")
$markdown.Add("## Review required")
$markdown.Add("")
$markdown.Add("| Ledger | Identity | Reasons | Previous fingerprint | Current fingerprint |")
$markdown.Add("| --- | --- | --- | --- | --- |")
foreach ($row in @($readinessAuditRows + $sessionAuditRows | Where-Object {
        $_.decision -eq "review-required" })) {
    $ledgerKind = if ($null -ne $row.PSObject.Properties["previous_state"]) {
        "session"
    } else { "readiness" }
    $identity = Escape-Markdown ("{0} {1} {2}" -f
        $row.program, $row.original_rva, $row.name)
    $reasonText = Escape-Markdown (($row.reasons) -join ", ")
    $markdown.Add("| $ledgerKind | $identity | $reasonText | ``$($row.binding.previous_row_fingerprint_sha256)`` | ``$($row.binding.current_row_fingerprint_sha256)`` |")
}
if (($readinessReview + $sessionReview) -eq 0) {
    $markdown.Add("| - | - | None | - | - |")
}
$markdown.Add("")
$markdown.Add("## Output ledgers")
$markdown.Add("")
$markdown.Add("- ``$(Get-RepoRelativePath $readinessOutputPath)`` - ``$readinessOutputSha``")
$markdown.Add("- ``$(Get-RepoRelativePath $sessionOutputPath)`` - ``$sessionOutputSha``")
$markdown.Add("")
$auditMarkdown = ($markdown -join "`n") + "`n"

$outputParentPath = Split-Path -Parent $outputFullPath
$outputLeafName = Split-Path -Leaf $outputFullPath
[void][System.IO.Directory]::CreateDirectory($outputParentPath)
Assert-NoReparseComponents $outputParentPath "OutputDirectory parent"
if (Test-Path -LiteralPath $outputFullPath) {
    throw ("OutputDirectory appeared before staging began; refusing to overwrite " +
        "it: '$outputFullPath'.")
}

$stagingLeafName = ".{0}.staging-{1}" -f
    $outputLeafName, [guid]::NewGuid().ToString("N")
$stagingFullPath = Join-Path $outputParentPath $stagingLeafName
$stagingRelative = Get-RepoRelativePath $stagingFullPath
& git -C $repoRoot check-ignore --quiet -- $stagingRelative
if ($LASTEXITCODE -ne 0) {
    throw "Atomic staging directory is not Git-ignored: '$stagingFullPath'."
}
if (Test-Path -LiteralPath $stagingFullPath) {
    throw "Atomic staging directory unexpectedly already exists: '$stagingFullPath'."
}
[void][System.IO.Directory]::CreateDirectory($stagingFullPath)
Assert-NoReparseComponents $stagingFullPath "Atomic staging directory"

try {
    $writes = @(
        [pscustomobject]@{
            Path = Join-Path $stagingFullPath "readiness-ledger.json"
            Text = $readinessJson
        },
        [pscustomobject]@{
            Path = Join-Path $stagingFullPath "session-lane-ledger.json"
            Text = $sessionJson
        },
        [pscustomobject]@{
            Path = Join-Path $stagingFullPath "carry-forward-audit.json"
            Text = $auditJson
        },
        [pscustomobject]@{
            Path = Join-Path $stagingFullPath "carry-forward-audit.md"
            Text = $auditMarkdown
        })
    foreach ($write in $writes) {
        [System.IO.File]::WriteAllText($write.Path, $write.Text, $utf8NoBom)
    }
    if ($BeforePublishDelayMilliseconds -gt 0) {
        Start-Sleep -Milliseconds $BeforePublishDelayMilliseconds
    }

    Assert-InputSnapshotsUnchanged $inputSnapshots
    Assert-NoReparseComponents $outputParentPath "OutputDirectory parent"
    Assert-NoReparseComponents $stagingFullPath "Atomic staging directory"
    & git -C $repoRoot check-ignore --quiet -- $outputRelative
    if ($LASTEXITCODE -ne 0) {
        throw "OutputDirectory stopped being Git-ignored before publication."
    }
    & git -C $repoRoot check-ignore --quiet -- $stagingRelative
    if ($LASTEXITCODE -ne 0) {
        throw "Atomic staging directory stopped being Git-ignored before publication."
    }
    if (Test-Path -LiteralPath $outputFullPath) {
        throw ("OutputDirectory appeared before atomic publication; refusing to " +
            "overwrite it: '$outputFullPath'.")
    }

    # The staging directory and destination share one parent, so Directory.Move
    # is a single same-volume rename. Consumers see either no output directory
    # or the complete four-file generation; Directory.Move never merges into or
    # replaces a destination that races into existence.
    [System.IO.Directory]::Move($stagingFullPath, $outputFullPath)
} finally {
    if (Test-Path -LiteralPath $stagingFullPath) {
        $resolvedStagingPath = (Resolve-Path -LiteralPath $stagingFullPath).Path
        if (-not $resolvedStagingPath.Equals(
                $stagingFullPath,
                [System.StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-PathInsideRepo $resolvedStagingPath)) {
            throw "Refusing unsafe atomic-staging cleanup: '$resolvedStagingPath'."
        }
        Assert-NoReparseComponents $resolvedStagingPath "Atomic staging cleanup"
        Remove-Item -LiteralPath $resolvedStagingPath -Recurse -Force
    }
}

Write-Host ("Readiness decisions: {0} carried, {1} review required." -f
    $readinessCarried, $readinessReview)
Write-Host ("Session lanes:       {0} carried, {1} review required." -f
    $sessionCarried, $sessionReview)
Write-Host "Audit JSON:         $(Get-RepoRelativePath $auditJsonPath)"
Write-Host "Audit Markdown:     $(Get-RepoRelativePath $auditMarkdownPath)"
