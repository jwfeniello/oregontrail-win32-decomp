[CmdletBinding()]
param(
    [string]$ManifestPath = "tools\otmatch\functions.vc40-real-cpp.csv",
    [string]$OriginalPath = "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe",
    [string]$OriginalDllPath = "Sample\Oregon Trail CD\OTWIN32\OREGON32.DLL",
    [string]$CandidatePath = "artifacts\otmatch\vc40\otwin-match-candidates.dll",
    [string]$CandidateMapPath = "artifacts\otmatch\vc40\otwin-match-candidates.map",
    [string]$OutputDirectory = "artifacts\otmatch\vc40",
    [int]$Top = 40,

    # An explicitly supplied pattern narrows the fail-closed expected_status=wip
    # queue. An empty value scans every WIP row, irrespective of note wording.
    [string]$NotesPattern = "",

    [switch]$IncludeOffsets,

    # Backward compatibility: this still controls the legacy DiffCount and
    # DiffOffsets columns. HardDiffCount always excludes manifest mask bytes and
    # is the value used for queue ranking.
    [switch]$ApplyMasks,

    [string[]]$FunctionMetricsPath = @(
        "tools\ghidra\otwin32\output\function_metrics_oregon32_exe.csv",
        "tools\ghidra\otwin32\output\function_metrics_oregon32_dll.csv"
    ),
    [string]$VerifierResultsPath = "artifacts\otmatch\vc40\function-match-results.csv",
    # Empty derives progress-metrics-summary.json beside VerifierResultsPath.
    [string]$ProgressMetricsSummaryPath = "",
    [string]$ExeProductSourceManifestPath = "tools\otmatch\vc4-exe-product-sources.txt",
    [string]$FrozenWipPath = "tools\otmatch\frozen-wip.csv",
    [switch]$DisableFrozenWip,
    # Optional, checkpoint-bound state for lanes attempted during the current
    # percentage session. Session pauses are deliberately separate from the
    # durable frozen-WIP policy above.
    [string]$SessionLaneLedgerPath = "",
    # Explicit semantic/readiness review for WIP rows. Normal portfolio
    # planning is fail-closed: only rows classified ready may contribute.
    [string]$ReadinessLedgerPath = "",
    # Compatibility/diagnostic escape hatch. Missing readiness rows use the
    # historical residual heuristic only when this switch is explicit.
    [switch]$AllowHeuristicReadiness,
    # Diagnostics may retain an otherwise sufficient portfolio with an
    # unpaired primary. Normal planning requires primary+alternate pairs.
    [switch]$AllowIncompleteAssignments,
    # Serial autonomous sessions consume a ranked queue plus reserves rather
    # than artificial primary/alternate pairs. This does not relax readiness,
    # frozen-lane, policy, or portfolio-size gates.
    [switch]$SerialPortfolio,
    [string]$ExeProductProgram = "Oregon32.exe",
    [switch]$IncludeNonText,

    [double]$CheckpointStepPercent = 5.0,
    [double]$PortfolioMultiplier = 1.5,
    [switch]$AllowNonstandardPortfolioPolicy,

    # Zero selects the automatic target: PortfolioMultiplier times the
    # instruction deficit to the next CheckpointStepPercent boundary.
    [int]$PortfolioTargetInstructions = 0,

    # Diagnostics may opt out explicitly, but normal session planning fails
    # when the ranked queue cannot cover its full target.
    [switch]$AllowPortfolioShortfall
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$maxDiagnosticDiff = [int]::MaxValue

function Get-CsvField($Row, [string]$Name) {
    if ($null -eq $Row) {
        return ""
    }

    $property = $Row.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) {
        return ""
    }

    return [string]$property.Value
}

function Resolve-RepoPath([string]$Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return (Resolve-Path -LiteralPath $Path).Path
    }

    return (Resolve-Path -LiteralPath (Join-Path $repoRoot $Path)).Path
}

function Resolve-OutputPath([string]$Path) {
    $fullPath = if ([System.IO.Path]::IsPathRooted($Path)) {
        [System.IO.Path]::GetFullPath($Path)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
    }

    $matchedAllowedRoot = ""
    foreach ($allowedName in @("a", "artifacts")) {
        $allowedRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $allowedName))
        $allowedPrefix = $allowedRoot.TrimEnd('\', '/') +
            [System.IO.Path]::DirectorySeparatorChar
        if ($fullPath.Equals(
                $allowedRoot,
                [System.StringComparison]::OrdinalIgnoreCase) -or
            $fullPath.StartsWith(
                $allowedPrefix,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            $matchedAllowedRoot = $allowedRoot.TrimEnd('\', '/')
            break
        }
    }

    if ([string]::IsNullOrWhiteSpace($matchedAllowedRoot)) {
        throw ("OutputDirectory must resolve beneath the repository's ignored " +
            "'a' or 'artifacts' root: '$fullPath'.")
    }

    # Lexical containment can be escaped by a junction or symbolic link below
    # an ignored root. Walk every existing ancestor, including the allowed
    # root, before any output directory or file is created.
    $current = $matchedAllowedRoot
    $relativeBelowAllowedRoot = $fullPath.Substring(
        $matchedAllowedRoot.Length).TrimStart('\', '/')
    $pathComponents = @()
    if (-not [string]::IsNullOrWhiteSpace($relativeBelowAllowedRoot)) {
        $pathComponents = @($relativeBelowAllowedRoot -split '[\\/]')
    }
    foreach ($component in @($null) + $pathComponents) {
        if ($null -ne $component) {
            $current = Join-Path $current $component
        }
        if (-not (Test-Path -LiteralPath $current)) {
            continue
        }
        $item = Get-Item -LiteralPath $current -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "OutputDirectory cannot traverse reparse point '$($item.FullName)'."
        }
    }

    $repoRelativePath = $fullPath.Substring(
        $repoRoot.Length).TrimStart('\', '/') -replace '\\', '/'
    & git -C $repoRoot check-ignore --quiet -- $repoRelativePath
    if ($LASTEXITCODE -ne 0) {
        throw "OutputDirectory is not Git-ignored: '$fullPath'."
    }

    return $fullPath
}

function Export-CsvAtomically([object[]]$Rows, [string]$Path) {
    $temporaryPath = "$Path.$PID.$([guid]::NewGuid().ToString('N')).tmp"
    try {
        $Rows | Export-Csv -LiteralPath $temporaryPath -NoTypeInformation
        Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
    } finally {
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

function Write-LinesAtomically([string[]]$Lines, [string]$Path) {
    $temporaryPath = "$Path.$PID.$([guid]::NewGuid().ToString('N')).tmp"
    try {
        [System.IO.File]::WriteAllLines($temporaryPath, $Lines)
        Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
    } finally {
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

function Write-JsonAtomically($Value, [string]$Path) {
    $json = $Value | ConvertTo-Json -Depth 12
    Write-LinesAtomically -Lines ([string[]]@($json)) -Path $Path
}

function Read-U16([byte[]]$Bytes, [int]$Offset) {
    if ($Offset -lt 0 -or ($Offset + 2) -gt $Bytes.Length) {
        throw "Cannot read a 16-bit value at file offset $Offset."
    }

    return [uint16](([uint64]$Bytes[$Offset]) -bor
        (([uint64]$Bytes[$Offset + 1]) -shl 8))
}

function Read-U32([byte[]]$Bytes, [int]$Offset) {
    if ($Offset -lt 0 -or ($Offset + 4) -gt $Bytes.Length) {
        throw "Cannot read a 32-bit value at file offset $Offset."
    }

    return [uint32](([uint64]$Bytes[$Offset]) -bor
        (([uint64]$Bytes[$Offset + 1]) -shl 8) -bor
        (([uint64]$Bytes[$Offset + 2]) -shl 16) -bor
        (([uint64]$Bytes[$Offset + 3]) -shl 24))
}

function Convert-Number([string]$Value, [string]$FieldName) {
    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "Missing required numeric field '$FieldName'."
    }

    $text = $Value.Trim()
    if ($text.StartsWith("0x", [System.StringComparison]::OrdinalIgnoreCase)) {
        return [uint64]::Parse(
            $text.Substring(2),
            [System.Globalization.NumberStyles]::HexNumber,
            [System.Globalization.CultureInfo]::InvariantCulture)
    }

    return [uint64]::Parse(
        $text,
        [System.Globalization.NumberStyles]::Integer,
        [System.Globalization.CultureInfo]::InvariantCulture)
}

function Convert-MaskNumber([string]$Value) {
    return Convert-Number $Value "mask offset"
}

function Convert-ToBoolean([string]$Value, [string]$FieldName, [bool]$AllowEmpty) {
    if ([string]::IsNullOrWhiteSpace($Value)) {
        if ($AllowEmpty) {
            return $null
        }

        throw "Missing required Boolean field '$FieldName'."
    }

    switch ($Value.Trim().ToLowerInvariant()) {
        "true" { return $true }
        "1" { return $true }
        "yes" { return $true }
        "false" { return $false }
        "0" { return $false }
        "no" { return $false }
        default { throw "Invalid Boolean value '$Value' in '$FieldName'." }
    }
}

function Get-FileSha256Hex([string]$Path) {
    $stream = [System.IO.File]::OpenRead((Resolve-Path -LiteralPath $Path).Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($sha.ComputeHash($stream) | ForEach-Object { $_.ToString("x2") }) -join "")
    }
    finally {
        $sha.Dispose()
        $stream.Dispose()
    }
}

function Get-MaskedByteSha256Hex([byte[]]$Bytes, [bool[]]$Mask) {
    if ($Bytes.Length -ne $Mask.Length) {
        throw "Cannot hash a byte range with a differently sized mask."
    }

    $comparable = New-Object byte[] $Bytes.Length
    [System.Array]::Copy($Bytes, $comparable, $Bytes.Length)
    for ($index = 0; $index -lt $comparable.Length; $index++) {
        if ($Mask[$index]) {
            $comparable[$index] = 0
        }
    }

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($sha.ComputeHash($comparable) | ForEach-Object {
            $_.ToString("x2")
        }) -join "")
    } finally {
        $sha.Dispose()
    }
}

function Get-MaskShapeSha256Hex([bool[]]$Mask) {
    $bytes = New-Object byte[] $Mask.Length
    for ($index = 0; $index -lt $Mask.Length; $index++) {
        if ($Mask[$index]) {
            $bytes[$index] = 1
        }
    }
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($sha.ComputeHash($bytes) | ForEach-Object {
            $_.ToString("x2")
        }) -join "")
    } finally {
        $sha.Dispose()
    }
}

function Resolve-CandidateObjectEvidence(
    $VerifierRow,
    [string]$ExpectedObjectName,
    [string]$Name) {

    $resolvedObjectName = (Get-CsvField `
        $VerifierRow "candidate_object").Trim()
    if ($resolvedObjectName -cne $ExpectedObjectName) {
        throw ("Frozen-WIP row '$Name' candidate object changed: recorded " +
            "'$ExpectedObjectName', current '$resolvedObjectName'.")
    }
    if ([string]::IsNullOrWhiteSpace($resolvedObjectName) -or
        [System.IO.Path]::IsPathRooted($resolvedObjectName) -or
        $resolvedObjectName -cne [System.IO.Path]::GetFileName(
            $resolvedObjectName) -or
        [System.IO.Path]::GetExtension($resolvedObjectName) -ine ".obj") {
        throw ("Frozen-WIP row '$Name' candidate object must be a " +
            "basename-only .obj file name.")
    }

    $candidatePath = (Get-CsvField $VerifierRow "candidate_path").Trim()
    if ([string]::IsNullOrWhiteSpace($candidatePath)) {
        throw "Frozen-WIP row '$Name' verifier candidate_path is missing."
    }
    $candidateFullPath = (Resolve-Path -LiteralPath $candidatePath).Path
    $candidateDirectory = [System.IO.Path]::GetFullPath(
        (Split-Path -Parent $candidateFullPath)).TrimEnd('\', '/')
    $objectPath = [System.IO.Path]::GetFullPath(
        (Join-Path $candidateDirectory $resolvedObjectName))
    $candidatePrefix = $candidateDirectory +
        [System.IO.Path]::DirectorySeparatorChar
    if (-not $objectPath.StartsWith(
            $candidatePrefix,
            [System.StringComparison]::OrdinalIgnoreCase)) {
        throw ("Frozen-WIP row '$Name' candidate object escapes the " +
            "candidate image directory.")
    }
    if (-not (Test-Path -LiteralPath $objectPath -PathType Leaf)) {
        throw ("Frozen-WIP row '$Name' candidate object was not found at " +
            "'$objectPath'.")
    }

    return [pscustomobject]@{
        Name = $resolvedObjectName
        Path = $objectPath
        Sha256 = Get-FileSha256Hex $objectPath
    }
}

function Resolve-FrozenEvidenceFile(
    [string]$RecordedPath,
    [string]$RecordedSha256,
    [string]$Description,
    [string]$Name) {

    if ([string]::IsNullOrWhiteSpace($RecordedPath)) {
        throw "Frozen-WIP row '$Name' is missing its $Description path."
    }

    $normalizedSha256 = $RecordedSha256.Trim().ToLowerInvariant()
    if ($normalizedSha256 -notmatch '^[0-9a-f]{64}$') {
        throw "Frozen-WIP row '$Name' has an invalid $Description SHA-256."
    }

    $resolvedPath = if ([System.IO.Path]::IsPathRooted($RecordedPath)) {
        [System.IO.Path]::GetFullPath($RecordedPath)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $RecordedPath))
    }
    if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
        throw "Frozen-WIP row '$Name' $Description file does not exist: '$resolvedPath'."
    }

    $cacheKey = $resolvedPath.ToLowerInvariant()
    if (-not $resultFileHashCache.ContainsKey($cacheKey)) {
        $resultFileHashCache[$cacheKey] = Get-FileSha256Hex $resolvedPath
    }
    if ([string]$resultFileHashCache[$cacheKey] -cne $normalizedSha256) {
        throw "Frozen-WIP row '$Name' recorded $Description SHA-256 changed."
    }

    return [pscustomobject]@{
        RecordedPath = $RecordedPath
        ResolvedPath = $resolvedPath
        Sha256 = $normalizedSha256
    }
}

function Convert-FrozenNonnegativeInt64(
    [string]$Value,
    [string]$FieldName,
    [string]$Name) {

    $parsed = [int64]0
    if ([string]::IsNullOrWhiteSpace($Value) -or
        -not [int64]::TryParse(
            $Value.Trim(),
            [System.Globalization.NumberStyles]::Integer,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [ref]$parsed) -or
        $parsed -lt 0) {
        throw "Frozen-WIP row '$Name' has an invalid nonnegative $FieldName."
    }

    return $parsed
}

function Convert-LedgerNonnegativeInt64(
    [string]$Value,
    [string]$FieldName,
    [string]$Description) {

    $parsed = [int64]0
    if ([string]::IsNullOrWhiteSpace($Value) -or
        -not [int64]::TryParse(
            $Value.Trim(),
            [System.Globalization.NumberStyles]::Integer,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [ref]$parsed) -or
        $parsed -lt 0) {
        throw "$Description has an invalid nonnegative $FieldName."
    }
    return $parsed
}

function Convert-LedgerNonnegativeDouble(
    [string]$Value,
    [string]$FieldName,
    [string]$Description,
    [bool]$AllowEmpty = $false) {

    if ([string]::IsNullOrWhiteSpace($Value)) {
        if ($AllowEmpty) {
            return $null
        }
        throw "$Description is missing $FieldName."
    }

    $parsed = [double]0.0
    if (-not [double]::TryParse(
            $Value.Trim(),
            [System.Globalization.NumberStyles]::Float,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [ref]$parsed) -or
        [double]::IsNaN($parsed) -or
        [double]::IsInfinity($parsed) -or
        $parsed -lt 0.0) {
        throw "$Description has an invalid nonnegative $FieldName."
    }
    return $parsed
}

function Convert-LedgerUtcTimestamp(
    [string]$Value,
    [string]$FieldName,
    [string]$Description) {

    $parsed = [DateTimeOffset]::MinValue
    if ([string]::IsNullOrWhiteSpace($Value) -or
        -not [DateTimeOffset]::TryParse(
            $Value.Trim(),
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::AssumeUniversal,
            [ref]$parsed)) {
        throw "$Description has an invalid $FieldName timestamp."
    }
    return $parsed.ToUniversalTime()
}

function Resolve-LedgerEvidenceFile(
    [string]$RecordedPath,
    [string]$RecordedSha256,
    [string]$FieldName,
    [string]$Description,
    [bool]$AllowEmpty = $false) {

    if ([string]::IsNullOrWhiteSpace($RecordedPath) -and
        [string]::IsNullOrWhiteSpace($RecordedSha256) -and $AllowEmpty) {
        return $null
    }
    if ([string]::IsNullOrWhiteSpace($RecordedPath)) {
        throw "$Description is missing its $FieldName path."
    }
    $normalizedSha256 = $RecordedSha256.Trim().ToLowerInvariant()
    if ($normalizedSha256 -notmatch '^[0-9a-f]{64}$') {
        throw "$Description has an invalid $FieldName SHA-256."
    }

    $resolvedPath = if ([System.IO.Path]::IsPathRooted($RecordedPath)) {
        [System.IO.Path]::GetFullPath($RecordedPath)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $RecordedPath))
    }
    if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
        throw "$Description $FieldName file does not exist: '$resolvedPath'."
    }
    $cacheKey = $resolvedPath.ToLowerInvariant()
    if (-not $resultFileHashCache.ContainsKey($cacheKey)) {
        $resultFileHashCache[$cacheKey] = Get-FileSha256Hex $resolvedPath
    }
    if ([string]$resultFileHashCache[$cacheKey] -cne $normalizedSha256) {
        throw "$Description recorded $FieldName SHA-256 changed."
    }

    return [pscustomobject]@{
        RecordedPath = $RecordedPath
        ResolvedPath = $resolvedPath
        Sha256 = $normalizedSha256
    }
}

function Assert-RecoveryLedgerInputs(
    $Ledger,
    [hashtable]$ExpectedInputs,
    [string]$Description) {

    if ($null -eq $Ledger.PSObject.Properties["inputs"]) {
        throw "$Description is missing hash-bound inputs."
    }
    $inputs = $Ledger.inputs
    foreach ($fieldName in @($ExpectedInputs.Keys | Sort-Object)) {
        $recorded = (Get-CsvField $inputs $fieldName).Trim().ToLowerInvariant()
        if ($recorded -notmatch '^[0-9a-f]{64}$') {
            throw "$Description has an invalid $fieldName SHA-256."
        }
        if ($recorded -cne [string]$ExpectedInputs[$fieldName]) {
            throw "$Description input '$fieldName' does not match the selected checkpoint."
        }
    }
}

function Read-RecoveryLedgerJson([string]$Path, [string]$Description) {
    $resolvedPath = Resolve-RepoPath $Path
    try {
        $ledger = Get-Content -LiteralPath $resolvedPath -Raw | ConvertFrom-Json
    } catch {
        throw ("Invalid {0} '{1}': {2}" -f
            $Description, $resolvedPath, $_.Exception.Message)
    }
    if ([int](Get-CsvField $ledger "schema_version") -ne 1) {
        throw "$Description has an unsupported schema_version; expected 1."
    }
    $sessionId = (Get-CsvField $ledger "session_id").Trim()
    if ([string]::IsNullOrWhiteSpace($sessionId) -or
        $sessionId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
        throw "$Description has an invalid session_id."
    }
    if ($null -eq $ledger.PSObject.Properties["rows"]) {
        throw "$Description is missing its rows array."
    }
    return [pscustomobject]@{
        Path = $resolvedPath
        SessionId = $sessionId
        Ledger = $ledger
    }
}

function Get-TextSha256Hex([string[]]$Lines) {
    $text = ($Lines -join "`n") + "`n"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($sha.ComputeHash($bytes) | ForEach-Object {
            $_.ToString("x2")
        }) -join "")
    } finally {
        $sha.Dispose()
    }
}

function Assert-SummaryFileRecord(
    $Record,
    [string]$ExpectedPath,
    [string]$Description) {

    if ($null -eq $Record -or
        $null -eq $Record.PSObject.Properties["path"] -or
        $null -eq $Record.PSObject.Properties["sha256"]) {
        throw "Progress metrics summary is missing $Description provenance."
    }
    $recordedPath = ([string]$Record.path).Trim()
    $recordedHash = ([string]$Record.sha256).Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($recordedPath) -or
        $recordedHash -notmatch '^[0-9a-f]{64}$') {
        throw "Progress metrics summary contains invalid $Description provenance."
    }

    $resolvedRecordedPath = Resolve-RepoPath $recordedPath
    if (-not [string]::IsNullOrWhiteSpace($ExpectedPath)) {
        $resolvedExpectedPath = Resolve-RepoPath $ExpectedPath
        if (-not $resolvedRecordedPath.Equals(
                $resolvedExpectedPath,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Progress metrics summary references a different $Description file."
        }
    }
    if ((Get-FileSha256Hex $resolvedRecordedPath) -cne $recordedHash) {
        throw "Stale progress metrics summary: $Description SHA-256 changed."
    }
    return $resolvedRecordedPath
}

function New-FunctionKey([string]$Program, [uint64]$Rva) {
    return ("{0}|0x{1:x}" -f $Program.Trim().ToLowerInvariant(), $Rva)
}

function Format-BodyRva([uint64]$Value) {
    return ("0x{0:x8}" -f $Value)
}

function Read-CanonicalBodyRanges(
    $Row,
    [string]$Program,
    [uint64]$EntryRva) {

    $name = (Get-CsvField $Row "name").Trim()
    $identity = if ([string]::IsNullOrWhiteSpace($name)) {
        "${Program} RVA $(Format-BodyRva $EntryRva)"
    } else {
        "'$name' (${Program} RVA $(Format-BodyRva $EntryRva))"
    }
    $text = Get-CsvField $Row "body_ranges"
    if ([string]::IsNullOrWhiteSpace($text)) {
        throw "Function metrics row $identity is missing required body_ranges."
    }

    $size = Convert-Number (Get-CsvField $Row "size") "metrics.size"
    $bodyBytes = Convert-Number `
        (Get-CsvField $Row "body_bytes") "metrics.body_bytes"
    if ($size -eq 0 -or $EntryRva -gt ([uint64]::MaxValue - $size)) {
        throw "Function metrics row $identity has an invalid body envelope size."
    }
    $envelopeEnd = $EntryRva + $size

    $ranges = New-Object System.Collections.Generic.List[object]
    $canonicalParts = New-Object System.Collections.Generic.List[string]
    $unionLength = [uint64]0
    $previousEnd = [uint64]0
    $hasPrevious = $false
    $entryOwned = $false
    foreach ($part in @($text -split ';')) {
        if ($part -cnotmatch '^0x([0-9a-f]+)-0x([0-9a-f]+)$') {
            throw ("Function metrics row {0} has malformed body_ranges '{1}'. " +
                "Expected canonical half-open RVA ranges such as " +
                "0x00001000-0x00001004;0x00001008-0x0000100c." -f
                $identity, $text)
        }
        $start = Convert-Number `
            ("0x" + $Matches[1]) "metrics.body_ranges.start"
        $end = Convert-Number `
            ("0x" + $Matches[2]) "metrics.body_ranges.end"
        if ($end -le $start) {
            throw "Function metrics row $identity has an empty or reversed body range."
        }
        if ($hasPrevious -and $start -lt $previousEnd) {
            throw ("Function metrics row $identity has body ranges that are not " +
                "ordered and internally disjoint.")
        }
        if ($start -lt $EntryRva -or $end -gt $envelopeEnd) {
            throw ("Function metrics row $identity has a body range outside its " +
                "half-open envelope $(Format-BodyRva $EntryRva)-$(Format-BodyRva $envelopeEnd).")
        }

        $length = $end - $start
        if ($unionLength -gt ([uint64]::MaxValue - $length)) {
            throw "Function metrics row $identity has overflowing body range lengths."
        }
        $unionLength += $length
        if ($EntryRva -ge $start -and $EntryRva -lt $end) {
            $entryOwned = $true
        }
        $ranges.Add([pscustomobject]@{
            Start = [uint64]$start
            End = [uint64]$end
        })
        $canonicalParts.Add(
            "$(Format-BodyRva $start)-$(Format-BodyRva $end)")
        $previousEnd = $end
        $hasPrevious = $true
    }

    $canonical = $canonicalParts -join ';'
    if ($canonical -cne $text) {
        throw ("Function metrics row $identity has non-canonical body_ranges " +
            "'$text'; expected '$canonical'.")
    }
    if (-not $entryOwned) {
        throw "Function metrics row $identity does not own its entry RVA."
    }
    if ($unionLength -ne $bodyBytes) {
        throw ("Function metrics row $identity body range union length $unionLength " +
            "does not equal body_bytes $bodyBytes.")
    }

    return [pscustomobject]@{
        Canonical = $canonical
        RangeCount = [uint64]$ranges.Count
        Ranges = [object[]]$ranges
    }
}

function Assert-NoCrossFunctionBodyOverlap([object[]]$OwnedRanges) {
    foreach ($programGroup in @($OwnedRanges |
            Group-Object ProgramKey | Sort-Object Name)) {
        $ordered = @($programGroup.Group | Sort-Object `
            @{Expression = { [uint64]$_.Start }},
            @{Expression = { [uint64]$_.End }},
            @{Expression = { [string]$_.Key }})
        $active = $null
        foreach ($range in $ordered) {
            if ($null -ne $active -and
                [uint64]$range.Start -lt [uint64]$active.End -and
                [string]$range.Key -cne [string]$active.Key) {
                throw ("Function body overlap in program '{0}': {1} owns " +
                    "{2}-{3}, overlapping {4} at {5}-{6}." -f
                    $range.Program, $range.Identity,
                    (Format-BodyRva ([uint64]$range.Start)),
                    (Format-BodyRva ([uint64]$range.End)),
                    $active.Identity,
                    (Format-BodyRva ([uint64]$active.Start)),
                    (Format-BodyRva ([uint64]$active.End)))
            }
            if ($null -eq $active -or
                [uint64]$range.End -gt [uint64]$active.End) {
                $active = $range
            }
        }
    }
}

function Get-Program($Row) {
    $program = (Get-CsvField $Row "program").Trim()
    if ([string]::IsNullOrWhiteSpace($program)) {
        throw "A manifest, metrics, or diagnostic row is missing its program."
    }

    return $program
}

function Get-PeImage([string]$Path) {
    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    $bytes = [System.IO.File]::ReadAllBytes($resolvedPath)
    if ($bytes.Length -lt 0x40) {
        throw "PE image is too small: $resolvedPath"
    }

    $peOffset = [int](Read-U32 $bytes 0x3c)
    if (($peOffset + 24) -gt $bytes.Length -or
        [System.Text.Encoding]::ASCII.GetString($bytes, $peOffset, 4) -cne "PE`0`0") {
        throw "Invalid PE signature in $resolvedPath"
    }

    $coff = $peOffset + 4
    $sectionCount = [int](Read-U16 $bytes ($coff + 2))
    $optHeaderSize = [int](Read-U16 $bytes ($coff + 16))
    $optOffset = $coff + 20
    $sectionTable = $optOffset + $optHeaderSize
    if (($sectionTable + ($sectionCount * 40)) -gt $bytes.Length) {
        throw "Truncated PE section table in $resolvedPath"
    }

    $sections = @()
    for ($i = 0; $i -lt $sectionCount; $i++) {
        $sectionOffset = $sectionTable + ($i * 40)
        $sections += [pscustomobject]@{
            VirtualAddress = [uint64](Read-U32 $bytes ($sectionOffset + 12))
            VirtualSize = [uint64](Read-U32 $bytes ($sectionOffset + 8))
            RawSize = [uint64](Read-U32 $bytes ($sectionOffset + 16))
            RawPointer = [uint64](Read-U32 $bytes ($sectionOffset + 20))
        }
    }

    return [pscustomobject]@{
        Bytes = $bytes
        ImageBase = [uint64](Read-U32 $bytes ($optOffset + 28))
        Sections = $sections
        Path = $resolvedPath
    }
}

function Read-RvaBytes($Image, [uint64]$Rva, [int]$Count) {
    foreach ($section in $Image.Sections) {
        $sectionEnd = $section.VirtualAddress +
            [System.Math]::Max($section.VirtualSize, $section.RawSize)
        if ($Rva -ge $section.VirtualAddress -and $Rva -lt $sectionEnd) {
            $delta = $Rva - $section.VirtualAddress
            if (($delta + [uint64]$Count) -gt $section.RawSize) {
                throw ("RVA range 0x{0:x}+{1} extends past raw section data in {2}." -f
                    $Rva, $Count, $Image.Path)
            }

            $fileOffset = [uint64]$section.RawPointer + $delta
            if (($fileOffset + [uint64]$Count) -gt [uint64]$Image.Bytes.Length) {
                throw ("RVA range 0x{0:x}+{1} extends past the file in {2}." -f
                    $Rva, $Count, $Image.Path)
            }

            $out = New-Object byte[] $Count
            [System.Array]::Copy($Image.Bytes, [int]$fileOffset, $out, 0, $Count)
            return $out
        }
    }

    throw ("RVA 0x{0:x} is not in any section of {1}." -f $Rva, $Image.Path)
}

function Assert-RecordedFileProvenance {
    param(
        $Row,
        [string]$PathColumn,
        [string]$HashColumn,
        [string]$Description
    )

    $recordedPath = (Get-CsvField $Row $PathColumn).Trim()
    $recordedHash = (Get-CsvField $Row $HashColumn).Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($recordedPath) -or
        [string]::IsNullOrWhiteSpace($recordedHash)) {
        throw "Verifier diagnostics are missing $Description provenance."
    }
    if ($recordedHash -notmatch '^[0-9a-f]{64}$') {
        throw "Verifier diagnostics contain an invalid $Description SHA-256."
    }

    $resolvedPath = if ([System.IO.Path]::IsPathRooted($recordedPath)) {
        [System.IO.Path]::GetFullPath($recordedPath)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $recordedPath))
    }
    if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
        throw "Stale verifier diagnostics: recorded $Description does not exist: '$resolvedPath'."
    }

    $cacheKey = $resolvedPath.ToLowerInvariant()
    if (-not $resultFileHashCache.ContainsKey($cacheKey)) {
        $resultFileHashCache[$cacheKey] = Get-FileSha256Hex $resolvedPath
    }
    if ([string]$resultFileHashCache[$cacheKey] -cne $recordedHash) {
        throw "Stale verifier diagnostics: recorded $Description SHA-256 changed."
    }

    return [pscustomobject]@{
        Path = $resolvedPath
        Sha256 = $recordedHash
    }
}

function Get-CandidateObjectNameForSource([string]$SourcePath) {
    $normalized = $SourcePath.Trim() -replace '\\', '/'
    return (($normalized -replace '/', '_') -replace '\.cpp$', '.obj')
}

function Get-Lane([string]$Name) {
    if ($Name -match 'River|Raft|Trade') { return "river/trade" }
    if ($Name -match 'Trail|Wagon|Ox|Fruit|Food|Illness|Weather|Party|Journey') { return "trail" }
    if ($Name -match 'Bitmap|Blit|Sprite|Palette|Graphics|Beveled') { return "graphics" }
    if ($Name -match 'Hunt') { return "hunt" }
    if ($Name -match 'Midi|Wave|Audio|Mci') { return "audio" }
    if ($Name -match 'Dialog|Window|Menu|Control|Runtime|Startup|App') { return "app/ui" }
    if ($Name -match '^switchD_|SwitchCase') { return "switch-fragment" }
    if ($Name -match '^FUN_') { return "anonymous" }
    return "misc"
}

function Get-ResidualClass([int]$DiffCount, [int]$Size) {
    if ($DiffCount -eq $maxDiagnosticDiff) { return "error" }
    if ($DiffCount -eq 0) { return "closed" }
    if ($DiffCount -le 16) { return "tiny" }
    if ($DiffCount -le 64) { return "near" }
    if ($DiffCount -le 128) { return "small" }
    if ($Size -gt 0 -and ($DiffCount / [double]$Size) -le 0.25) { return "sparse" }
    return "broad"
}

function Read-Mask([string]$MaskText, [int]$Size, [string]$Name) {
    $mask = New-Object bool[] $Size
    if ([string]::IsNullOrWhiteSpace($MaskText)) {
        return $mask
    }

    foreach ($rawPart in ($MaskText -split '[;, ]+')) {
        if ([string]::IsNullOrWhiteSpace($rawPart)) {
            continue
        }

        $part = $rawPart.Trim()
        if ($part -match '^(.+)-(.+)$') {
            $start = [int](Convert-MaskNumber $Matches[1])
            $end = [int](Convert-MaskNumber $Matches[2])
        } else {
            $start = [int](Convert-MaskNumber $part)
            $end = $start
        }

        if ($end -lt $start) {
            throw "Mask range '$part' for '$Name' ends before it starts."
        }
        if ($start -lt 0 -or $end -ge $Size) {
            throw "Mask range '$part' for '$Name' is outside the function range."
        }

        for ($offset = $start; $offset -le $end; $offset++) {
            $mask[$offset] = $true
        }
    }

    return $mask
}

function Get-PriorityScore([string]$Name, [int]$DiffCount, [int]$Size) {
    $namePenalty = 0
    if ($Name -match '^FUN_') {
        $namePenalty = 2000
    } elseif ($Name -match '^switchD_|SwitchCase') {
        $namePenalty = 1000
    } elseif ($Name -notmatch '^Ot') {
        $namePenalty = 500
    }

    if ($DiffCount -eq $maxDiagnosticDiff) {
        return $maxDiagnosticDiff
    }

    return $DiffCount + $namePenalty + [int]($Size / 512)
}

function Get-DefaultConfidence(
    [string]$Name,
    [string]$ResidualClass,
    [string]$Status,
    [string]$VerifierActualStatus,
    [bool]$PromotionReady,
    [string]$ProductReachable,
    [bool]$VerifierBlocked) {

    if ($Status -ne "OK") {
        return [double]0.02
    }
    if ($PromotionReady -or $VerifierActualStatus -eq "match") {
        $confidence = [double]0.98
    } else {
        $confidence = switch ($ResidualClass) {
            "closed" { [double]0.95 }
            "tiny" { [double]0.82 }
            "near" { [double]0.68 }
            "small" { [double]0.52 }
            "sparse" { [double]0.38 }
            "broad" { [double]0.22 }
            default { [double]0.05 }
        }
    }

    if ($Name -match '^FUN_') {
        $confidence -= 0.12
    } elseif ($Name -match '^switchD_|SwitchCase') {
        $confidence -= 0.08
    } elseif ($Name -notmatch '^Ot') {
        $confidence -= 0.05
    }

    if ($ProductReachable -eq "False") {
        $confidence -= 0.10
    }
    if ($VerifierBlocked) {
        $confidence *= 0.35
    }

    return [System.Math]::Max(0.02, [System.Math]::Min(0.98, $confidence))
}

function Get-DefaultEffort(
    [string]$Name,
    [string]$ResidualClass,
    [string]$Status,
    [string]$ProductReachable,
    [bool]$HasCandidateLocator,
    [bool]$VerifierBlocked) {

    if ($Status -ne "OK") {
        return [double]10.0
    }

    $effort = switch ($ResidualClass) {
        "closed" { [double]0.5 }
        "tiny" { [double]1.0 }
        "near" { [double]2.0 }
        "small" { [double]3.0 }
        "sparse" { [double]4.0 }
        "broad" { [double]6.0 }
        default { [double]10.0 }
    }

    if ($Name -match '^FUN_') {
        $effort += 2.0
    } elseif ($Name -match '^switchD_|SwitchCase') {
        $effort += 1.0
    }
    if ($ProductReachable -eq "False") {
        $effort += 1.0
    }
    if (-not $HasCandidateLocator) {
        $effort += 2.0
    }
    if ($VerifierBlocked) {
        $effort += 2.0
    }

    return $effort
}

function Normalize-ActualStatus([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return "unavailable"
    }

    switch ($Value.Trim().ToLowerInvariant()) {
        "match" { return "match" }
        "matched" { return "match" }
        "pass" { return "match" }
        "mismatch" { return "mismatch" }
        "different" { return "mismatch" }
        "failed" { return "mismatch" }
        "error" { return "error" }
        default { throw "Unknown verifier actual status '$Value'." }
    }
}

if ($Top -lt 1) {
    throw "Top must be at least 1."
}
if ($CheckpointStepPercent -le 0.0 -or $CheckpointStepPercent -gt 100.0) {
    throw "CheckpointStepPercent must be greater than zero and at most 100."
}
if ($PortfolioMultiplier -le 0.0) {
    throw "PortfolioMultiplier must be greater than zero."
}
if (-not $AllowNonstandardPortfolioPolicy -and
    ([System.Math]::Abs($CheckpointStepPercent - 5.0) -gt 0.000000001 -or
        ($PortfolioMultiplier + 0.000000001) -lt 1.5)) {
    throw ("Recovery planning requires five-point checkpoints and a portfolio " +
        "multiplier of at least 1.5. Use -AllowNonstandardPortfolioPolicy " +
        "only for explicit diagnostics.")
}
if ($PortfolioTargetInstructions -lt 0) {
    throw "PortfolioTargetInstructions cannot be negative."
}

$manifestFullPath = Resolve-RepoPath $ManifestPath
$originalFullPath = Resolve-RepoPath $OriginalPath
$originalDllFullPath = Resolve-RepoPath $OriginalDllPath
$candidateFullPath = Resolve-RepoPath $CandidatePath
$candidateMapFullPath = Resolve-RepoPath $CandidateMapPath
$outputFullPath = Resolve-OutputPath $OutputDirectory

$manifest = @(Import-Csv -LiteralPath $manifestFullPath)
if ($manifest.Count -eq 0) {
    throw "Manifest has no function rows: $ManifestPath"
}

$manifestByKey = @{}
$manifestStateByKey = @{}
$wipRows = @()
foreach ($row in $manifest) {
    $program = Get-Program $row
    $originalRva = Convert-Number (Get-CsvField $row "original_rva") "manifest.original_rva"
    $key = New-FunctionKey $program $originalRva
    if ($manifestByKey.ContainsKey($key)) {
        throw ("Duplicate manifest row for {0} RVA 0x{1:x}." -f $program, $originalRva)
    }

    $name = (Get-CsvField $row "name").Trim()
    if ([string]::IsNullOrWhiteSpace($name)) {
        throw "A manifest row at $key is missing its name."
    }
    $sizeValue = Convert-Number (Get-CsvField $row "size") "manifest.size"
    if ($sizeValue -eq 0 -or $sizeValue -gt [uint64][int]::MaxValue) {
        throw "Manifest row '$name' has invalid size '$sizeValue'."
    }

    $expectedStatus = (Get-CsvField $row "expected_status").Trim().ToLowerInvariant()
    if ($expectedStatus -ne "match" -and $expectedStatus -ne "wip") {
        throw ("Unknown expected_status '{0}' for manifest row '{1}'; expected 'match' or 'wip'." -f
            $expectedStatus, $name)
    }

    $manifestByKey[$key] = $row
    $manifestStateByKey[$key] = [pscustomobject]@{
        Key = $key
        Name = $name
        Program = $program
        OriginalRva = $originalRva
        Size = [int]$sizeValue
        ExpectedStatus = $expectedStatus
    }

    if ($expectedStatus -eq "wip") {
        if ([string]::IsNullOrWhiteSpace($NotesPattern) -or
            (Get-CsvField $row "notes") -like $NotesPattern) {
            $wipRows += $row
        }
    }
}

$metricsByKey = @{}
$metricRows = @()
$metricsFullPaths = @()
$ownedBodyRanges = New-Object System.Collections.Generic.List[object]
foreach ($path in $FunctionMetricsPath) {
    $metricsFullPath = Resolve-RepoPath $path
    $metricsFullPaths += $metricsFullPath
    foreach ($metric in @(Import-Csv -LiteralPath $metricsFullPath)) {
        if (-not $IncludeNonText) {
            $block = (Get-CsvField $metric "block").Trim()
            if (-not [string]::IsNullOrWhiteSpace($block) -and $block -ine ".text") {
                continue
            }
        }

        $program = Get-Program $metric
        $rva = Convert-Number (Get-CsvField $metric "original_rva") "metrics.original_rva"
        $key = New-FunctionKey $program $rva
        if ($metricsByKey.ContainsKey($key)) {
            throw ("Duplicate function metrics row for {0} RVA 0x{1:x}." -f $program, $rva)
        }

        $instructionCount = Convert-Number (
            Get-CsvField $metric "instruction_count") "metrics.instruction_count"
        if ($instructionCount -gt [uint64][int]::MaxValue) {
            throw "Instruction count is too large for metrics row '$key'."
        }
        $bodyOwnership = Read-CanonicalBodyRanges $metric $program $rva

        $metricsByKey[$key] = [pscustomobject]@{
            Row = $metric
            Instructions = [int]$instructionCount
            BodyOwnership = $bodyOwnership
        }
        $metricName = (Get-CsvField $metric "name").Trim()
        $metricIdentity = "'$metricName' at $(Format-BodyRva $rva)"
        foreach ($range in @($bodyOwnership.Ranges)) {
            $ownedBodyRanges.Add([pscustomobject]@{
                Program = $program
                ProgramKey = $program.ToLowerInvariant()
                Key = $key
                Identity = $metricIdentity
                Start = [uint64]$range.Start
                End = [uint64]$range.End
            })
        }
        $metricRows += $metric
    }
}
if ($metricsByKey.Count -eq 0) {
    throw "The selected Ghidra function metrics contain no rows."
}
Assert-NoCrossFunctionBodyOverlap ([object[]]$ownedBodyRanges)
foreach ($key in $manifestByKey.Keys) {
    if (-not $metricsByKey.ContainsKey($key)) {
        $state = $manifestStateByKey[$key]
        throw ("Manifest row '{0}' ({1} RVA 0x{2:x}) is missing from Ghidra function metrics." -f
            $state.Name, $state.Program, $state.OriginalRva)
    }
}

$productSourceFullPath = Resolve-RepoPath $ExeProductSourceManifestPath
$productObjects = @{}
if ($null -ne $productSourceFullPath) {
    foreach ($line in [System.IO.File]::ReadAllLines($productSourceFullPath)) {
        $source = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($source) -or $source.StartsWith("#")) {
            continue
        }

        $source = $source -replace '\\', '/'
        if ($source -notmatch '^src/otwin/(?!_exact/|_recovery/|dll/).+\.cpp$') {
            throw "Invalid EXE Product source manifest entry: '$source'."
        }
        $sourceFullPath = Join-Path $repoRoot ($source -replace '/', '\')
        if (-not (Test-Path -LiteralPath $sourceFullPath -PathType Leaf)) {
            throw "EXE Product source does not exist: '$source'."
        }

        $objectName = Get-CandidateObjectNameForSource $source
        $objectKey = $objectName.ToLowerInvariant()
        if ($productObjects.ContainsKey($objectKey)) {
            throw "Duplicate EXE Product candidate object '$objectName'."
        }
        $productObjects[$objectKey] = $source
    }
    if ($productObjects.Count -eq 0) {
        throw "EXE Product source manifest is empty: $ExeProductSourceManifestPath"
    }
}

$verifierFullPath = Resolve-RepoPath $VerifierResultsPath
$progressMetricsSummaryFullPath = if (
    [string]::IsNullOrWhiteSpace($ProgressMetricsSummaryPath)) {
    Resolve-RepoPath (Join-Path (
        Split-Path -Parent $verifierFullPath) "progress-metrics-summary.json")
} else {
    Resolve-RepoPath $ProgressMetricsSummaryPath
}
$verifierByKey = @{}
$resultFileHashCache = @{}
$manifestSha256 = Get-FileSha256Hex $manifestFullPath
foreach ($diagnostic in @(Import-Csv -LiteralPath $verifierFullPath)) {
        $program = Get-Program $diagnostic
        $rva = Convert-Number (Get-CsvField $diagnostic "original_rva") "verifier.original_rva"
        $key = New-FunctionKey $program $rva
        if ($verifierByKey.ContainsKey($key)) {
            throw ("Duplicate verifier diagnostic for {0} RVA 0x{1:x}." -f $program, $rva)
        }
        if (-not $manifestByKey.ContainsKey($key)) {
            throw "Verifier diagnostic '$key' has no manifest row."
        }

        $schemaVersion = (Get-CsvField $diagnostic "result_schema_version").Trim()
        if ($schemaVersion -ne "4") {
            throw "Unsupported verifier result_schema_version '$schemaVersion'; expected 4."
        }
        foreach ($requiredSchemaFourField in @(
                "mask_shape_valid", "masked_operand_shape_error")) {
            if ($null -eq $diagnostic.PSObject.Properties[
                    $requiredSchemaFourField]) {
                throw ("Schema-4 verifier diagnostics are missing required " +
                    "field '$requiredSchemaFourField'.")
            }
        }
        $recordedManifestSha = (Get-CsvField $diagnostic "manifest_sha256").Trim().ToLowerInvariant()
        if ($recordedManifestSha -cne $manifestSha256) {
            throw "Stale verifier diagnostics: manifest SHA-256 changed."
        }

        [void](Assert-RecordedFileProvenance $diagnostic `
            "original_path" "original_file_sha256" "original image")
        [void](Assert-RecordedFileProvenance $diagnostic `
            "candidate_path" "candidate_file_sha256" "candidate image")
        [void](Assert-RecordedFileProvenance $diagnostic `
            "candidate_map_path" "candidate_map_sha256" "candidate map")

        $manifestState = $manifestStateByKey[$key]
        $diagnosticName = (Get-CsvField $diagnostic "name").Trim()
        if (-not [string]::IsNullOrWhiteSpace($diagnosticName) -and
            $diagnosticName -cne $manifestState.Name) {
            throw "Verifier diagnostic name does not match manifest row '$($manifestState.Name)'."
        }
        $diagnosticExpected = (Get-CsvField $diagnostic "expected_status").Trim().ToLowerInvariant()
        if (-not [string]::IsNullOrWhiteSpace($diagnosticExpected) -and
            $diagnosticExpected -cne $manifestState.ExpectedStatus) {
            throw "Verifier expected_status does not match manifest row '$($manifestState.Name)'."
        }
        $manifestCandidateSymbol = (Get-CsvField `
            $manifestByKey[$key] "candidate_symbol").Trim()
        $diagnosticCandidateSymbol = (Get-CsvField `
            $diagnostic "candidate_symbol").Trim()
        if ($diagnosticCandidateSymbol -cne $manifestCandidateSymbol) {
            throw "Verifier candidate_symbol does not match manifest row '$($manifestState.Name)'."
        }
        $manifestCandidateObject = (Get-CsvField `
            $manifestByKey[$key] "candidate_object").Trim()
        $diagnosticCandidateObjectQualifier = (Get-CsvField `
            $diagnostic "candidate_object_qualifier").Trim()
        if ($diagnosticCandidateObjectQualifier -cne $manifestCandidateObject) {
            throw "Verifier candidate_object qualifier does not match manifest row '$($manifestState.Name)'."
        }
        $diagnosticCandidateFunctionSha256 = (
            Get-CsvField $diagnostic "candidate_sha256").Trim().ToLowerInvariant()
        if ($diagnosticCandidateFunctionSha256 -notmatch '^[0-9a-f]{64}$') {
            throw ("Verifier candidate_sha256 is missing or invalid for " +
                "manifest row '$($manifestState.Name)'.")
        }

        $diagnosticMaskShapeValid = [bool](Convert-ToBoolean `
            (Get-CsvField $diagnostic "mask_shape_valid") `
            "verifier.mask_shape_valid" $false)
        $diagnosticMaskedOperandShapeError = (
            Get-CsvField $diagnostic "masked_operand_shape_error").Trim()
        $diagnosticMaskedImportIdentityError = (
            Get-CsvField $diagnostic "masked_import_identity_error").Trim()
        if ($diagnosticMaskShapeValid -and
            -not [string]::IsNullOrWhiteSpace(
                $diagnosticMaskedOperandShapeError)) {
            throw ("Verifier reports mask_shape_valid=true with a masked " +
                "operand-shape diagnostic for '$($manifestState.Name)'.")
        }
        if (-not $diagnosticMaskShapeValid -and
            [string]::IsNullOrWhiteSpace(
                $diagnosticMaskedOperandShapeError)) {
            throw ("Verifier reports mask_shape_valid=false without a masked " +
                "operand-shape diagnostic for '$($manifestState.Name)'.")
        }
        $diagnosticActualStatus = Normalize-ActualStatus (
            Get-CsvField $diagnostic "actual_status")
        if ($diagnosticActualStatus -eq "unavailable") {
            $diagnosticActualStatus = Normalize-ActualStatus (
                Get-CsvField $diagnostic "status")
        }
        $diagnosticMask = Read-Mask `
            (Get-CsvField $manifestByKey[$key] "mask") `
            $manifestState.Size $manifestState.Name
        $diagnosticMaskBytes = @($diagnosticMask | Where-Object { $_ }).Count
        if (-not $diagnosticMaskShapeValid -and
            ($diagnosticActualStatus -ne "mismatch" -or
                $diagnosticMaskBytes -eq 0)) {
            throw ("Verifier reports inconsistent paired mask-shape metadata " +
                "for '$($manifestState.Name)'.")
        }
        if ($diagnosticActualStatus -eq "match" -and
            -not $diagnosticMaskShapeValid) {
            throw ("Verifier reports an impossible match with invalid paired " +
                "mask shape for '$($manifestState.Name)'.")
        }
        if (-not [string]::IsNullOrWhiteSpace(
                $diagnosticMaskedImportIdentityError) -and
            -not $diagnosticMaskedImportIdentityError.StartsWith(
                "Masked import ", [System.StringComparison]::Ordinal)) {
            throw ("Verifier reports an invalid masked_import_identity_error " +
                "for '$($manifestState.Name)'.")
        }
        if (-not [string]::IsNullOrWhiteSpace(
                $diagnosticMaskedImportIdentityError) -and
            $diagnosticMaskedImportIdentityError -cne
                $diagnosticMaskedOperandShapeError) {
            throw ("Verifier masked import and operand-shape diagnostics " +
                "disagree for '$($manifestState.Name)'.")
        }

        $verifierByKey[$key] = $diagnostic
}
if ($verifierByKey.Count -ne $manifestByKey.Count) {
    throw ("Verifier diagnostics cover {0}/{1} manifest rows; regenerate the full matcher results." -f
        $verifierByKey.Count, $manifestByKey.Count)
}

$frozenFullPath = if ($DisableFrozenWip) {
    $null
} else {
    if ([string]::IsNullOrWhiteSpace($FrozenWipPath)) {
        throw "FrozenWipPath is required unless -DisableFrozenWip is explicit."
    }
    $frozenCandidate = if ([System.IO.Path]::IsPathRooted($FrozenWipPath)) {
        $FrozenWipPath
    } else {
        Join-Path $repoRoot $FrozenWipPath
    }
    if (-not (Test-Path -LiteralPath $frozenCandidate -PathType Leaf)) {
        throw ("Frozen WIP metadata is required but was not found: " +
            "'$FrozenWipPath'. Use -DisableFrozenWip only for explicit diagnostics.")
    }
    (Resolve-Path -LiteralPath $frozenCandidate).Path
}
$frozenByKey = @{}
$retiredFrozenRows = New-Object 'System.Collections.Generic.List[object]'
if ($null -ne $frozenFullPath) {
    foreach ($metadata in @(Import-Csv -LiteralPath $frozenFullPath)) {
        $program = Get-Program $metadata
        $rva = Convert-Number (Get-CsvField $metadata "original_rva") "frozen.original_rva"
        $key = New-FunctionKey $program $rva
        if ($frozenByKey.ContainsKey($key)) {
            throw ("Duplicate frozen-WIP metadata for {0} RVA 0x{1:x}." -f $program, $rva)
        }
        if (-not $manifestByKey.ContainsKey($key)) {
            throw "Frozen-WIP metadata '$key' has no manifest row."
        }

        $manifestState = $manifestStateByKey[$key]
        if ($manifestState.ExpectedStatus -ne "wip") {
            $verifierState = $verifierByKey[$key]
            $actualStatus = (Get-CsvField $verifierState "actual_status").Trim().ToLowerInvariant()
            $verificationStatus =
                (Get-CsvField $verifierState "verification_status").Trim().ToLowerInvariant()
            if ($manifestState.ExpectedStatus -eq "match" -and
                $actualStatus -eq "match" -and
                $verificationStatus -eq "pass") {
                $retiredFrozenRows.Add([pscustomobject][ordered]@{
                    Program = $program
                    OriginalRva = ("0x{0:x8}" -f $rva)
                    Name = $manifestState.Name
                    Reason = "promoted-and-verifier-passing"
                })
                continue
            }
            throw ("Frozen-WIP metadata row '$($manifestState.Name)' is no longer " +
                "expected_status=wip and lacks a passing promoted verifier result.")
        }
        $metadataName = (Get-CsvField $metadata "name").Trim()
        if ($metadataName -cne $manifestState.Name) {
            throw "Frozen-WIP metadata name '$metadataName' does not match '$($manifestState.Name)'."
        }

        $frozen = Convert-ToBoolean (Get-CsvField $metadata "frozen") "frozen.frozen" $false
        $reason = (Get-CsvField $metadata "reason").Trim()
        $revisit = (Get-CsvField $metadata "revisit_condition").Trim()
        if ($frozen -and [string]::IsNullOrWhiteSpace($reason)) {
            throw "Frozen-WIP row '$metadataName' is missing its reason."
        }
        if ($frozen -and [string]::IsNullOrWhiteSpace($revisit)) {
            throw "Frozen-WIP row '$metadataName' is missing its revisit_condition."
        }

        $confidenceText = (Get-CsvField $metadata "confidence").Trim()
        $confidence = $null
        if (-not [string]::IsNullOrWhiteSpace($confidenceText)) {
            $confidence = [double]::Parse(
                $confidenceText,
                [System.Globalization.NumberStyles]::Float,
                [System.Globalization.CultureInfo]::InvariantCulture)
            if ([double]::IsNaN($confidence) -or
                [double]::IsInfinity($confidence) -or
                $confidence -lt 0.0 -or $confidence -gt 1.0) {
                throw ("Frozen-WIP confidence for '$metadataName' must be " +
                    "finite and between zero and one.")
            }
        }

        $effortText = (Get-CsvField $metadata "effort").Trim()
        $effort = $null
        if (-not [string]::IsNullOrWhiteSpace($effortText)) {
            $effort = [double]::Parse(
                $effortText,
                [System.Globalization.NumberStyles]::Float,
                [System.Globalization.CultureInfo]::InvariantCulture)
            if ([double]::IsNaN($effort) -or
                [double]::IsInfinity($effort) -or
                $effort -le 0.0) {
                throw ("Frozen-WIP effort for '$metadataName' must be finite " +
                    "and greater than zero.")
            }
        }

        $freezeDate = ""
        $evidencePath = ""
        $evidenceSha256 = ""
        $sourcePath = ""
        $sourceSha256 = ""
        $meaningfulVariantCount = $null
        $residualKind = ""
        $boundHardDiffCount = $null
        $boundComparedBytes = $null
        $baselineOriginalSha256 = ""
        $baselineCandidateSha256 = ""
        $baselineCandidateObject = ""
        $baselineCandidateObjectSha256 = ""
        $baselineCandidateFunctionSha256 = ""
        $diagnosticNote = (Get-CsvField $metadata "diagnostic_note").Trim()
        if ($frozen) {
            $freezeDate = (Get-CsvField $metadata "freeze_date").Trim()
            $parsedFreezeDate = [datetime]::MinValue
            if ($freezeDate -notmatch '^\d{4}-\d{2}-\d{2}$' -or
                -not [datetime]::TryParseExact(
                    $freezeDate,
                    "yyyy-MM-dd",
                    [System.Globalization.CultureInfo]::InvariantCulture,
                    [System.Globalization.DateTimeStyles]::None,
                    [ref]$parsedFreezeDate)) {
                throw ("Frozen-WIP row '$metadataName' freeze_date must be an " +
                    "exact valid yyyy-MM-dd date.")
            }

            $evidence = Resolve-FrozenEvidenceFile `
                (Get-CsvField $metadata "evidence_path").Trim() `
                (Get-CsvField $metadata "evidence_sha256") `
                "evidence" $metadataName
            $source = Resolve-FrozenEvidenceFile `
                (Get-CsvField $metadata "source_path").Trim() `
                (Get-CsvField $metadata "source_sha256") `
                "source" $metadataName
            $evidencePath = $evidence.RecordedPath
            $evidenceSha256 = $evidence.Sha256
            $sourcePath = $source.RecordedPath
            $sourceSha256 = $source.Sha256

            $meaningfulVariantCount = Convert-FrozenNonnegativeInt64 `
                (Get-CsvField $metadata "meaningful_variant_count") `
                "meaningful_variant_count" $metadataName
            if ($meaningfulVariantCount -lt 8) {
                throw ("Frozen-WIP row '$metadataName' must bind at least eight " +
                    "meaningful variants before it may be frozen.")
            }

            $residualKind = (Get-CsvField $metadata "residual_kind").Trim().ToLowerInvariant()
            if ($residualKind -notin @("strict-linked")) {
                throw ("Frozen-WIP row '$metadataName' has unrecognized " +
                    "residual_kind '$residualKind'.")
            }

            $boundHardDiffCount = Convert-FrozenNonnegativeInt64 `
                (Get-CsvField $metadata "hard_diff_count") `
                "hard_diff_count" $metadataName
            $boundComparedBytes = Convert-FrozenNonnegativeInt64 `
                (Get-CsvField $metadata "compared_bytes") `
                "compared_bytes" $metadataName
            if ($boundComparedBytes -le 0) {
                throw "Frozen-WIP row '$metadataName' compared_bytes must be greater than zero."
            }
            if ($boundHardDiffCount -gt $boundComparedBytes) {
                throw ("Frozen-WIP row '$metadataName' hard_diff_count cannot " +
                    "exceed compared_bytes.")
            }

            $baselineOriginalSha256 = (
                Get-CsvField $metadata "baseline_original_sha256").Trim().ToLowerInvariant()
            $baselineCandidateSha256 = (
                Get-CsvField $metadata "baseline_candidate_sha256").Trim().ToLowerInvariant()
            $baselineCandidateObject = (
                Get-CsvField $metadata "baseline_candidate_object").Trim()
            $baselineCandidateObjectSha256 = (
                Get-CsvField $metadata `
                    "baseline_candidate_object_sha256").Trim().ToLowerInvariant()
            $baselineCandidateFunctionSha256 = (
                Get-CsvField $metadata `
                    "baseline_candidate_function_sha256").Trim().ToLowerInvariant()
            if ($baselineOriginalSha256 -notmatch '^[0-9a-f]{64}$') {
                throw "Frozen-WIP row '$metadataName' has an invalid baseline original SHA-256."
            }
            if ($baselineCandidateSha256 -notmatch '^[0-9a-f]{64}$') {
                throw "Frozen-WIP row '$metadataName' has an invalid baseline candidate SHA-256."
            }
            if ([string]::IsNullOrWhiteSpace($baselineCandidateObject) -or
                [System.IO.Path]::IsPathRooted($baselineCandidateObject) -or
                $baselineCandidateObject -cne [System.IO.Path]::GetFileName(
                    $baselineCandidateObject) -or
                [System.IO.Path]::GetExtension(
                    $baselineCandidateObject) -ine ".obj") {
                throw ("Frozen-WIP row '$metadataName' must bind a " +
                    "basename-only baseline_candidate_object .obj file.")
            }
            if ($baselineCandidateObjectSha256 -notmatch '^[0-9a-f]{64}$') {
                throw ("Frozen-WIP row '$metadataName' has an invalid " +
                    "baseline_candidate_object_sha256.")
            }
            if ($baselineCandidateFunctionSha256 -notmatch '^[0-9a-f]{64}$') {
                throw ("Frozen-WIP row '$metadataName' must bind a valid " +
                    "baseline_candidate_function_sha256 from schema-4 " +
                    "verifier candidate_sha256 evidence.")
            }
        }

        $frozenByKey[$key] = [pscustomobject]@{
            Frozen = [bool]$frozen
            Confidence = $confidence
            Effort = $effort
            Reason = $reason
            RevisitCondition = $revisit
            FreezeDate = $freezeDate
            EvidencePath = $evidencePath
            EvidenceSha256 = $evidenceSha256
            SourcePath = $sourcePath
            SourceSha256 = $sourceSha256
            MeaningfulVariantCount = $meaningfulVariantCount
            ResidualKind = $residualKind
            BoundHardDiffCount = $boundHardDiffCount
            BoundComparedBytes = $boundComparedBytes
            BaselineOriginalSha256 = $baselineOriginalSha256
            BaselineCandidateSha256 = $baselineCandidateSha256
            BaselineCandidateObject = $baselineCandidateObject
            BaselineCandidateObjectSha256 = $baselineCandidateObjectSha256
            BaselineCandidateFunctionSha256 = $baselineCandidateFunctionSha256
            DiagnosticNote = $diagnosticNote
        }
    }
}

try {
    $progressSummary = Get-Content -LiteralPath $progressMetricsSummaryFullPath -Raw |
        ConvertFrom-Json
} catch {
    throw ("Invalid progress metrics summary '{0}': {1}" -f
        $progressMetricsSummaryFullPath, $_.Exception.Message)
}
if ([int]$progressSummary.schema_version -ne 2) {
    throw "Unsupported progress metrics summary schema; expected 2."
}
if (-not [bool]$progressSummary.policy.require_product_reachability) {
    throw "Progress metrics summary did not enforce Product reachability."
}
if ([bool]$progressSummary.policy.include_non_text -ne [bool]$IncludeNonText) {
    throw "Progress metrics summary IncludeNonText policy differs from this queue scan."
}

[void](Assert-SummaryFileRecord `
    $progressSummary.inputs.manifest $manifestFullPath "manifest")
[void](Assert-SummaryFileRecord `
    $progressSummary.inputs.verifier_results $verifierFullPath "verifier results")
[void](Assert-SummaryFileRecord `
    $progressSummary.inputs.exe_product_sources $productSourceFullPath "EXE Product source manifest")
[void](Assert-SummaryFileRecord `
    $progressSummary.inputs.metrics_reporter `
    (Join-Path $PSScriptRoot "report-progress-metrics.ps1") `
    "metrics reporter")
[void](Assert-SummaryFileRecord `
    $progressSummary.inputs.mask_audit_results "" "mask-audit results")

$summaryMetricInputs = @($progressSummary.inputs.function_metrics)
if ($summaryMetricInputs.Count -ne $metricsFullPaths.Count) {
    throw "Progress metrics summary function-metrics input count changed."
}
$summaryMetricPaths = @{}
foreach ($record in $summaryMetricInputs) {
    $resolvedMetricPath = Assert-SummaryFileRecord `
        $record "" "function-metrics input"
    $metricKey = $resolvedMetricPath.ToLowerInvariant()
    if ($summaryMetricPaths.ContainsKey($metricKey)) {
        throw "Progress metrics summary contains a duplicate function-metrics input."
    }
    $summaryMetricPaths[$metricKey] = $true
}
foreach ($metricsFullPath in $metricsFullPaths) {
    if (-not $summaryMetricPaths.ContainsKey($metricsFullPath.ToLowerInvariant())) {
        throw "Progress metrics summary references different function-metrics inputs."
    }
}

$manifestIdentityUniverse = [string[]]@($manifestByKey.Keys)
[System.Array]::Sort(
    $manifestIdentityUniverse,
    [System.StringComparer]::Ordinal)
if ([uint64]$progressSummary.inputs.manifest.identity_count -ne
    [uint64]$manifestIdentityUniverse.Count -or
    ([string]$progressSummary.inputs.manifest.identity_universe_sha256).ToLowerInvariant() -cne
        (Get-TextSha256Hex $manifestIdentityUniverse)) {
    throw "Progress metrics summary manifest identity universe changed."
}

$denominatorKeys = [string[]]@($metricsByKey.Keys)
[System.Array]::Sort($denominatorKeys, [System.StringComparer]::Ordinal)
$denominatorLines = @()
$bodyOwnershipLines = @()
$computedBodyRangeCount = [uint64]0
$computedTotalInstructions = [uint64]0
$computedTotalBodyBytes = [uint64]0
foreach ($key in $denominatorKeys) {
    $metricState = $metricsByKey[$key]
    $metricRow = $metricState.Row
    $metricInstructions = [uint64]$metricState.Instructions
    $metricBodyBytes = Convert-Number (
        Get-CsvField $metricRow "body_bytes") "metrics.body_bytes"
    $metricSize = Convert-Number (
        Get-CsvField $metricRow "size") "metrics.size"
    $computedTotalInstructions += $metricInstructions
    $computedTotalBodyBytes += $metricBodyBytes
    $denominatorLines += ("{0}|instructions={1}|body_bytes={2}|size={3}" -f
        $key, $metricInstructions, $metricBodyBytes, $metricSize)
    $bodyOwnership = $metricState.BodyOwnership
    $bodyOwnershipLines += ("{0}|body_ranges={1}" -f
        $key, [string]$bodyOwnership.Canonical)
    $computedBodyRangeCount += [uint64]$bodyOwnership.RangeCount
}
if ([uint64]$progressSummary.denominator.function_count -ne
        [uint64]$denominatorKeys.Count -or
    [uint64]$progressSummary.denominator.instruction_count -ne
        $computedTotalInstructions -or
    [uint64]$progressSummary.denominator.body_byte_count -ne
        $computedTotalBodyBytes -or
    ([string]$progressSummary.denominator.identity_sha256).ToLowerInvariant() -cne
        (Get-TextSha256Hex $denominatorLines)) {
    throw "Progress metrics summary denominator changed."
}
$recordedBodyOwnershipSha256 = (
    Get-CsvField $progressSummary.denominator "body_ownership_sha256").Trim().ToLowerInvariant()
$recordedBodyRangeCountText = (
    Get-CsvField $progressSummary.denominator "body_range_count").Trim()
if ($recordedBodyOwnershipSha256 -notmatch '^[0-9a-f]{64}$' -or
    [string]::IsNullOrWhiteSpace($recordedBodyRangeCountText)) {
    throw "Progress metrics summary is missing canonical body ownership evidence."
}
$recordedBodyRangeCount = Convert-Number `
    $recordedBodyRangeCountText "summary.denominator.body_range_count"
if ($recordedBodyRangeCount -ne $computedBodyRangeCount -or
    $recordedBodyOwnershipSha256 -cne
        (Get-TextSha256Hex $bodyOwnershipLines)) {
    throw "Progress metrics summary body ownership changed."
}

$summaryAcceptedIdentities = [string[]]@(
    $progressSummary.strict.accepted_identities)
if ([uint64]$progressSummary.strict.accepted_identity_count -ne
        [uint64]$summaryAcceptedIdentities.Count -or
    ([string]$progressSummary.strict.accepted_identity_sha256).ToLowerInvariant() -cne
        (Get-TextSha256Hex $summaryAcceptedIdentities)) {
    throw "Progress metrics summary accepted identity evidence is inconsistent."
}
$summaryAcceptedSet = @{}
$computedAcceptedInstructions = [uint64]0
foreach ($key in $summaryAcceptedIdentities) {
    if ($summaryAcceptedSet.ContainsKey($key) -or
        -not $manifestByKey.ContainsKey($key) -or
        -not $metricsByKey.ContainsKey($key)) {
        throw "Progress metrics summary contains an invalid accepted identity '$key'."
    }
    $summaryAcceptedSet[$key] = $true
    $computedAcceptedInstructions += [uint64]$metricsByKey[$key].Instructions
}
if ([uint64]$progressSummary.strict.accepted_instructions -ne
    $computedAcceptedInstructions) {
    throw "Progress metrics summary accepted instruction total is inconsistent."
}
$totalInstructions = [int64]$computedTotalInstructions
$acceptedInstructions = [int64]$computedAcceptedInstructions

$exeImage = Get-PeImage $originalFullPath
$dllImage = Get-PeImage $originalDllFullPath
$candidateImage = Get-PeImage $candidateFullPath
$scannerOriginalExeSha256 = Get-FileSha256Hex $originalFullPath
$scannerOriginalDllSha256 = Get-FileSha256Hex $originalDllFullPath
$scannerCandidateSha256 = Get-FileSha256Hex $candidateFullPath
$scannerCandidateMapSha256 = Get-FileSha256Hex $candidateMapFullPath

$checkpointInputHashes = @{
    manifest_sha256 = $manifestSha256
    verifier_results_sha256 = Get-FileSha256Hex $verifierFullPath
    progress_metrics_summary_sha256 = Get-FileSha256Hex $progressMetricsSummaryFullPath
    candidate_file_sha256 = $scannerCandidateSha256
    candidate_map_sha256 = $scannerCandidateMapSha256
    original_exe_sha256 = $scannerOriginalExeSha256
    original_dll_sha256 = $scannerOriginalDllSha256
}

$sessionLaneLedgerFullPath = $null
$sessionLaneSessionId = ""
$sessionLaneByKey = @{}
if (-not [string]::IsNullOrWhiteSpace($SessionLaneLedgerPath)) {
    $sessionLaneRecord = Read-RecoveryLedgerJson `
        $SessionLaneLedgerPath "Session lane ledger"
    $sessionLaneLedgerFullPath = $sessionLaneRecord.Path
    $sessionLaneSessionId = $sessionLaneRecord.SessionId
    Assert-RecoveryLedgerInputs `
        $sessionLaneRecord.Ledger $checkpointInputHashes "Session lane ledger"

    foreach ($laneRow in @($sessionLaneRecord.Ledger.rows)) {
        $program = Get-Program $laneRow
        $rva = Convert-Number `
            (Get-CsvField $laneRow "original_rva") "session lane original_rva"
        $key = New-FunctionKey $program $rva
        if ($sessionLaneByKey.ContainsKey($key)) {
            throw ("Duplicate session lane row for {0} RVA 0x{1:x}." -f
                $program, $rva)
        }
        if (-not $manifestByKey.ContainsKey($key)) {
            throw "Session lane row '$key' has no manifest identity."
        }
        $manifestState = $manifestStateByKey[$key]
        if ($manifestState.ExpectedStatus -ne "wip") {
            throw "Session lane row '$($manifestState.Name)' is not expected_status=wip."
        }
        $rowName = (Get-CsvField $laneRow "name").Trim()
        if ($rowName -cne $manifestState.Name) {
            throw "Session lane name '$rowName' does not match '$($manifestState.Name)'."
        }
        $description = "Session lane row '$rowName'"
        $state = (Get-CsvField $laneRow "state").Trim().ToLowerInvariant()
        if ($state -notin @("active", "paused", "frozen", "closed")) {
            throw "$description has invalid state '$state'."
        }
        $hypothesis = (Get-CsvField $laneRow "hypothesis").Trim()
        if ([string]::IsNullOrWhiteSpace($hypothesis)) {
            throw "$description is missing its hypothesis."
        }

        $startedUtc = Convert-LedgerUtcTimestamp `
            (Get-CsvField $laneRow "started_utc") "started_utc" $description
        $updatedUtc = Convert-LedgerUtcTimestamp `
            (Get-CsvField $laneRow "updated_utc") "updated_utc" $description
        if ($updatedUtc -lt $startedUtc) {
            throw "$description updated_utc precedes started_utc."
        }
        $activeRecoveryMinutes = Convert-LedgerNonnegativeDouble `
            (Get-CsvField $laneRow "active_recovery_minutes") `
            "active_recovery_minutes" $description
        $toolTimeMs = Convert-LedgerNonnegativeInt64 `
            (Get-CsvField $laneRow "tool_time_ms") "tool_time_ms" $description
        $meaningfulVariantCount = Convert-LedgerNonnegativeInt64 `
            (Get-CsvField $laneRow "meaningful_variant_count") `
            "meaningful_variant_count" $description
        if ($state -eq "frozen" -and $meaningfulVariantCount -lt 8) {
            throw "$description requires at least eight meaningful variants for session state frozen."
        }

        $evidence = Resolve-LedgerEvidenceFile `
            (Get-CsvField $laneRow "evidence_path").Trim() `
            (Get-CsvField $laneRow "evidence_sha256") `
            "evidence" $description ($state -eq "active")
        $source = Resolve-LedgerEvidenceFile `
            (Get-CsvField $laneRow "source_path").Trim() `
            (Get-CsvField $laneRow "source_sha256") `
            "source" $description $false

        if ($null -eq $laneRow.PSObject.Properties["residual"]) {
            throw "$description is missing its residual record."
        }
        $residual = $laneRow.residual
        $residualKind = (Get-CsvField $residual "kind").Trim().ToLowerInvariant()
        if ($residualKind -ne "strict-linked") {
            throw "$description has unsupported residual kind '$residualKind'."
        }
        $hardDiffCount = Convert-LedgerNonnegativeInt64 `
            (Get-CsvField $residual "hard_diff_count") `
            "residual hard_diff_count" $description
        $comparedBytes = Convert-LedgerNonnegativeInt64 `
            (Get-CsvField $residual "compared_bytes") `
            "residual compared_bytes" $description
        if ($comparedBytes -le 0 -or $hardDiffCount -gt $comparedBytes) {
            throw "$description has an invalid strict-linked residual range."
        }
        if ($state -eq "closed" -and $hardDiffCount -ne 0) {
            throw "$description state closed requires a zero hard residual."
        }
        if ($state -ne "closed" -and $hardDiffCount -eq 0) {
            throw "$description with a zero hard residual must use state closed."
        }
        $candidateFunctionSha256 = (
            Get-CsvField $residual "candidate_function_sha256").Trim().ToLowerInvariant()
        if ($candidateFunctionSha256 -notmatch '^[0-9a-f]{64}$') {
            throw "$description has an invalid residual candidate_function_sha256."
        }

        $sessionLaneByKey[$key] = [pscustomobject]@{
            State = $state
            Hypothesis = $hypothesis
            StartedUtc = $startedUtc.ToString("o")
            UpdatedUtc = $updatedUtc.ToString("o")
            ActiveRecoveryMinutes = $activeRecoveryMinutes
            ToolTimeMs = $toolTimeMs
            MeaningfulVariantCount = $meaningfulVariantCount
            EvidencePath = if ($null -ne $evidence) { $evidence.RecordedPath } else { "" }
            EvidenceSha256 = if ($null -ne $evidence) { $evidence.Sha256 } else { "" }
            SourcePath = $source.RecordedPath
            SourceSha256 = $source.Sha256
            ResidualKind = $residualKind
            HardDiffCount = $hardDiffCount
            ComparedBytes = $comparedBytes
            CandidateFunctionSha256 = $candidateFunctionSha256
        }
    }
}

$readinessLedgerFullPath = $null
$readinessSessionId = ""
$readinessByKey = @{}
if (-not [string]::IsNullOrWhiteSpace($ReadinessLedgerPath)) {
    $readinessRecord = Read-RecoveryLedgerJson `
        $ReadinessLedgerPath "Readiness ledger"
    $readinessLedgerFullPath = $readinessRecord.Path
    $readinessSessionId = $readinessRecord.SessionId
    if (-not [string]::IsNullOrWhiteSpace($sessionLaneSessionId) -and
        $readinessSessionId -cne $sessionLaneSessionId) {
        throw "Readiness and session lane ledgers have different session_id values."
    }
    Assert-RecoveryLedgerInputs `
        $readinessRecord.Ledger $checkpointInputHashes "Readiness ledger"

    foreach ($readinessRow in @($readinessRecord.Ledger.rows)) {
        $program = Get-Program $readinessRow
        $rva = Convert-Number `
            (Get-CsvField $readinessRow "original_rva") "readiness original_rva"
        $key = New-FunctionKey $program $rva
        if ($readinessByKey.ContainsKey($key)) {
            throw ("Duplicate readiness row for {0} RVA 0x{1:x}." -f
                $program, $rva)
        }
        if (-not $manifestByKey.ContainsKey($key)) {
            throw "Readiness row '$key' has no manifest identity."
        }
        $manifestState = $manifestStateByKey[$key]
        if ($manifestState.ExpectedStatus -ne "wip") {
            throw "Readiness row '$($manifestState.Name)' is not expected_status=wip."
        }
        $rowName = (Get-CsvField $readinessRow "name").Trim()
        if ($rowName -cne $manifestState.Name) {
            throw "Readiness name '$rowName' does not match '$($manifestState.Name)'."
        }
        $description = "Readiness row '$rowName'"
        $classification = (
            Get-CsvField $readinessRow "readiness").Trim().ToLowerInvariant()
        if ($classification -notin @("ready", "needs-implementation", "blocked")) {
            throw "$description has invalid readiness '$classification'."
        }
        $dependencyState = (
            Get-CsvField $readinessRow "dependency_state").Trim().ToLowerInvariant()
        if ($dependencyState -notin @("ready", "incomplete", "blocked")) {
            throw "$description has invalid dependency_state '$dependencyState'."
        }
        if ($classification -eq "ready" -and $dependencyState -ne "ready") {
            throw "$description cannot be ready while dependencies are '$dependencyState'."
        }
        $reason = (Get-CsvField $readinessRow "reason").Trim()
        if ([string]::IsNullOrWhiteSpace($reason)) {
            throw "$description is missing its reason."
        }
        $templateDefaultValue = Convert-ToBoolean `
            (Get-CsvField $readinessRow "template_default") `
            "readiness.template_default" $true
        $templateDefault = $null -ne $templateDefaultValue -and
            [bool]$templateDefaultValue
        if ($templateDefault -and
            ($classification -ne "needs-implementation" -or
                $dependencyState -ne "incomplete")) {
            throw ("$description may use template_default only for " +
                "needs-implementation/incomplete fail-closed state.")
        }
        $evidence = Resolve-LedgerEvidenceFile `
            (Get-CsvField $readinessRow "evidence_path").Trim() `
            (Get-CsvField $readinessRow "evidence_sha256") `
            "evidence" $description $templateDefault

        $confidence = Convert-LedgerNonnegativeDouble `
            (Get-CsvField $readinessRow "confidence") `
            "confidence" $description $true
        if ($null -ne $confidence -and $confidence -gt 1.0) {
            throw "$description confidence must be at most one."
        }
        $effort = Convert-LedgerNonnegativeDouble `
            (Get-CsvField $readinessRow "effort") `
            "effort" $description $true
        if ($null -ne $effort -and $effort -le 0.0) {
            throw "$description effort must be greater than zero."
        }
        $candidateBodyBytesText = (Get-CsvField `
            $readinessRow "candidate_body_bytes").Trim()
        $candidateBodyBytes = if ([string]::IsNullOrWhiteSpace($candidateBodyBytesText)) {
            $null
        } else {
            Convert-LedgerNonnegativeInt64 `
                $candidateBodyBytesText "candidate_body_bytes" $description
        }
        $candidateInstructionText = (Get-CsvField `
            $readinessRow "candidate_instruction_count").Trim()
        $candidateInstructionCount = if (
            [string]::IsNullOrWhiteSpace($candidateInstructionText)) {
            $null
        } else {
            Convert-LedgerNonnegativeInt64 `
                $candidateInstructionText "candidate_instruction_count" $description
        }

        $readinessByKey[$key] = [pscustomobject]@{
            Classification = $classification
            DependencyState = $dependencyState
            Reason = $reason
            TemplateDefault = $templateDefault
            EvidencePath = if ($null -ne $evidence) { $evidence.RecordedPath } else { "" }
            EvidenceSha256 = if ($null -ne $evidence) { $evidence.Sha256 } else { "" }
            Confidence = $confidence
            Effort = $effort
            CandidateBodyBytes = $candidateBodyBytes
            CandidateInstructionCount = $candidateInstructionCount
        }
    }
}

function Get-ProductReachability(
    $ManifestRow,
    $VerifierRow,
    [string]$Program,
    [string]$ImplementationKind) {

    if ($ImplementationKind -ne "cpp" -or $Program -ine $ExeProductProgram) {
        return "NotApplicable"
    }
    if ($null -eq $productSourceFullPath) {
        return "Unknown"
    }

    $candidateObject = (Get-CsvField $VerifierRow "candidate_object").Trim()
    if ([string]::IsNullOrWhiteSpace($candidateObject)) {
        $candidateObject = (Get-CsvField $ManifestRow "candidate_object").Trim()
    }
    if ([string]::IsNullOrWhiteSpace($candidateObject)) {
        return "False"
    }

    if ($productObjects.ContainsKey($candidateObject.ToLowerInvariant())) {
        return "True"
    }

    return "False"
}

$results = @()
$missingRequiredReadiness = New-Object System.Collections.Generic.List[string]
foreach ($row in $wipRows) {
    $program = Get-Program $row
    $originalRva = Convert-Number (Get-CsvField $row "original_rva") "manifest.original_rva"
    $key = New-FunctionKey $program $originalRva
    $name = (Get-CsvField $row "name").Trim()
    $size = $manifestStateByKey[$key].Size
    $metric = $metricsByKey[$key]
    $yieldInstructions = [int]$metric.Instructions
    $verifier = if ($verifierByKey.ContainsKey($key)) { $verifierByKey[$key] } else { $null }
    $frozenMetadata = if ($frozenByKey.ContainsKey($key)) { $frozenByKey[$key] } else { $null }
    $sessionLaneMetadata = if ($sessionLaneByKey.ContainsKey($key)) {
        $sessionLaneByKey[$key]
    } else {
        $null
    }
    $readinessMetadata = if ($readinessByKey.ContainsKey($key)) {
        $readinessByKey[$key]
    } else {
        $null
    }

    $implementationKind = (Get-CsvField $row "implementation_kind").Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($implementationKind)) {
        $implementationKind = "unknown"
    }
    $productReachable = Get-ProductReachability $row $verifier $program $implementationKind

    $expectedOriginalSha256 = if ($program -match 'DLL') {
        $scannerOriginalDllSha256
    } else {
        $scannerOriginalExeSha256
    }
    if ((Get-CsvField $verifier "original_file_sha256").Trim().ToLowerInvariant() -cne
        $expectedOriginalSha256) {
        throw "WIP scanner original image does not match verifier diagnostics for '$name'."
    }
    if ((Get-CsvField $verifier "candidate_file_sha256").Trim().ToLowerInvariant() -cne
        $scannerCandidateSha256 -or
        (Get-CsvField $verifier "candidate_map_sha256").Trim().ToLowerInvariant() -cne
        $scannerCandidateMapSha256) {
        throw "WIP scanner candidate image/map does not match verifier diagnostics for '$name'."
    }

    $verifierActualStatus = Normalize-ActualStatus (Get-CsvField $verifier "actual_status")
    if ($verifierActualStatus -eq "unavailable") {
        $verifierActualStatus = Normalize-ActualStatus (Get-CsvField $verifier "status")
    }
    $verificationStatus = (Get-CsvField $verifier "verification_status").Trim()
    $promotionReadyValue = Convert-ToBoolean (
        (Get-CsvField $verifier "promotion_ready")) "verifier.promotion_ready" $true
    $promotionReady = $null -ne $promotionReadyValue -and [bool]$promotionReadyValue
    $verifierError = (Get-CsvField $verifier "error_message").Trim()
    $maskShapeValid = [bool](Convert-ToBoolean (
        Get-CsvField $verifier "mask_shape_valid") `
        "verifier.mask_shape_valid" $false)
    $maskedOperandShapeError = (
        Get-CsvField $verifier "masked_operand_shape_error").Trim()
    $maskedImportIdentityError = (
        Get-CsvField $verifier "masked_import_identity_error").Trim()
    $verifierBlocked = $verifierActualStatus -eq "error" -or
        -not [string]::IsNullOrWhiteSpace($verifierError) -or
        -not $maskShapeValid -or
        -not [string]::IsNullOrWhiteSpace($maskedOperandShapeError) -or
        -not [string]::IsNullOrWhiteSpace($maskedImportIdentityError)

    $status = "OK"
    $candidateRva = $null
    $rawDiffOffsets = New-Object System.Collections.Generic.List[int]
    $hardDiffOffsets = New-Object System.Collections.Generic.List[int]
    $rawDiffCount = $maxDiagnosticDiff
    $hardDiffCount = $maxDiagnosticDiff
    $mask = Read-Mask (Get-CsvField $row "mask") $size $name
    $maskBytes = @($mask | Where-Object { $_ }).Count
    $maskSha256 = Get-MaskShapeSha256Hex $mask
    $candidateFunctionSha256 = ""
    $candidateObjectEvidence = $null
    $hasCandidateLocator = -not [string]::IsNullOrWhiteSpace(
        (Get-CsvField $row "candidate_rva")) -or
        -not [string]::IsNullOrWhiteSpace((Get-CsvField $row "candidate_va")) -or
        -not [string]::IsNullOrWhiteSpace((Get-CsvField $row "candidate_symbol"))

    try {
        $verifierCandidateRva = (Get-CsvField $verifier "candidate_rva").Trim()
        if ([string]::IsNullOrWhiteSpace($verifierCandidateRva)) {
            throw "Schema-4 verifier did not resolve a candidate RVA."
        }
        $candidateRva = Convert-Number `
            $verifierCandidateRva "verifier.candidate_rva"
        $originalImage = if ($program -match 'DLL') { $dllImage } else { $exeImage }
        $originalBytes = Read-RvaBytes $originalImage $originalRva $size
        $candidateBytes = Read-RvaBytes $candidateImage $candidateRva $size
        $candidateFunctionSha256 = Get-MaskedByteSha256Hex $candidateBytes $mask
        $verifierCandidateFunctionSha256 = (
            Get-CsvField $verifier "candidate_sha256").Trim().ToLowerInvariant()
        if ($candidateFunctionSha256 -cne $verifierCandidateFunctionSha256) {
            throw ("WIP scanner candidate function SHA-256 does not match " +
                "verifier diagnostics for '$name'.")
        }

        for ($i = 0; $i -lt $size; $i++) {
            if ($originalBytes[$i] -ne $candidateBytes[$i]) {
                $rawDiffOffsets.Add($i)
                if (-not $mask[$i]) {
                    $hardDiffOffsets.Add($i)
                }
            }
        }
        $rawDiffCount = $rawDiffOffsets.Count
        $hardDiffCount = $hardDiffOffsets.Count
    }
    catch {
        $status = $_.Exception.Message
    }

    $legacyOffsets = if ($ApplyMasks) { $hardDiffOffsets } else { $rawDiffOffsets }
    $legacyDiffCount = if ($ApplyMasks) { $hardDiffCount } else { $rawDiffCount }
    $legacyDiffPercent = if ($size -gt 0 -and $legacyDiffCount -ne $maxDiagnosticDiff) {
        [System.Math]::Round(($legacyDiffCount / [double]$size) * 100.0, 2)
    } else {
        $null
    }
    $hardComparedBytes = $size - $maskBytes
    $hardDiffPercent = if ($hardComparedBytes -gt 0 -and $hardDiffCount -ne $maxDiagnosticDiff) {
        [System.Math]::Round(($hardDiffCount / [double]$hardComparedBytes) * 100.0, 2)
    } else {
        $null
    }

    $residualClass = Get-ResidualClass $legacyDiffCount $size
    $hardResidualClass = Get-ResidualClass $hardDiffCount $hardComparedBytes
    $frozen = $null -ne $frozenMetadata -and [bool]$frozenMetadata.Frozen
    if ($frozen) {
        if ($promotionReady) {
            throw ("Frozen-WIP row '$name' is promotion-ready; its freeze is " +
                "stale and must be reviewed.")
        }
        if ($status -ne "OK") {
            throw ("Frozen-WIP row '$name' could not reproduce its strict " +
                "linked residual: $status")
        }
        if ($frozenMetadata.BaselineOriginalSha256 -cne $expectedOriginalSha256) {
            throw ("Frozen-WIP row '$name' baseline original SHA-256 does not " +
                "match the selected original image.")
        }
        $candidateObjectEvidence = Resolve-CandidateObjectEvidence `
            $verifier $frozenMetadata.BaselineCandidateObject $name
        if ($frozenMetadata.BaselineCandidateObjectSha256 -cne
                $candidateObjectEvidence.Sha256) {
            throw ("Frozen-WIP row '$name' candidate object SHA-256 changed. " +
                "Review and refresh the object-bound freeze evidence.")
        }
        if ([int64]$frozenMetadata.BoundComparedBytes -ne
                [int64]$hardComparedBytes) {
            throw (("Frozen-WIP row '$name' compared-byte coverage changed: " +
                "recorded {0}, current {1}. Review the manifest mask and " +
                "refresh the freeze evidence.") -f
                $frozenMetadata.BoundComparedBytes,
                $hardComparedBytes)
        }
    }
    if ($null -ne $sessionLaneMetadata) {
        if ($status -ne "OK") {
            throw ("Session lane row '$name' could not reproduce its strict " +
                "linked residual: $status")
        }
        if ($sessionLaneMetadata.CandidateFunctionSha256 -cne
                $candidateFunctionSha256) {
            throw ("Session lane row '$name' candidate function SHA-256 " +
                "changed; refresh or close the session evidence.")
        }
        if ([int64]$sessionLaneMetadata.HardDiffCount -ne
                [int64]$hardDiffCount -or
            [int64]$sessionLaneMetadata.ComparedBytes -ne
                [int64]$hardComparedBytes) {
            throw (("Session lane row '$name' strict residual changed: " +
                "recorded {0}/{1}, current {2}/{3}. Refresh or close the " +
                "session evidence.") -f
                $sessionLaneMetadata.HardDiffCount,
                $sessionLaneMetadata.ComparedBytes,
                $hardDiffCount,
                $hardComparedBytes)
        }
        if ($sessionLaneMetadata.State -eq "closed" -and
            $hardDiffCount -ne 0) {
            throw "Session lane row '$name' is closed but is not a strict match."
        }
        if ($sessionLaneMetadata.State -ne "closed" -and
            $hardDiffCount -eq 0) {
            throw ("Session lane row '$name' is now a strict match and must " +
                "use state closed.")
        }
    }

    $readinessClassification = if ($null -ne $readinessMetadata) {
        $readinessMetadata.Classification
    } elseif ($AllowHeuristicReadiness) {
        "ready"
    } else {
        "unclassified"
    }
    $readinessSource = if ($null -ne $readinessMetadata) {
        "readiness-ledger"
    } elseif ($AllowHeuristicReadiness) {
        "heuristic-diagnostic"
    } else {
        "missing"
    }
    $readinessDependencyState = if ($null -ne $readinessMetadata) {
        $readinessMetadata.DependencyState
    } elseif ($AllowHeuristicReadiness) {
        "ready"
    } else {
        ""
    }
    $readinessReason = if ($null -ne $readinessMetadata) {
        $readinessMetadata.Reason
    } elseif ($AllowHeuristicReadiness) {
        "Explicit compatibility override: historical residual heuristic."
    } else {
        "No checkpoint-bound readiness review was supplied."
    }

    $confidence = Get-DefaultConfidence `
        $name $hardResidualClass $status $verifierActualStatus $promotionReady `
        $productReachable $verifierBlocked
    $effort = Get-DefaultEffort `
        $name $hardResidualClass $status $productReachable $hasCandidateLocator $verifierBlocked
    $confidenceSource = "heuristic"
    $effortSource = "heuristic"
    if ($null -ne $frozenMetadata -and $null -ne $frozenMetadata.Confidence) {
        $confidence = [double]$frozenMetadata.Confidence
        $confidenceSource = "metadata"
    }
    if ($null -ne $frozenMetadata -and $null -ne $frozenMetadata.Effort) {
        $effort = [double]$frozenMetadata.Effort
        $effortSource = "metadata"
    }
    if ($null -ne $readinessMetadata -and
        $null -ne $readinessMetadata.Confidence) {
        $confidence = [double]$readinessMetadata.Confidence
        $confidenceSource = "readiness-ledger"
    }
    if ($null -ne $readinessMetadata -and
        $null -ne $readinessMetadata.Effort) {
        $effort = [double]$readinessMetadata.Effort
        $effortSource = "readiness-ledger"
    }

    $matchedFraction = if ($hardComparedBytes -gt 0 -and
        $hardDiffCount -ne $maxDiagnosticDiff) {
        [System.Math]::Max(
            0.0,
            1.0 - ($hardDiffCount / [double]$hardComparedBytes))
    } else {
        0.0
    }
    # Near-closure weighting prevents a large, almost entirely mismatching
    # callback from outranking several structurally close medium functions.
    # The small floor retains instruction yield as a secondary signal while
    # the fourth power sharply rewards genuinely aligned bodies.
    $closureFactor = 0.05 + (0.95 *
        [System.Math]::Pow($matchedFraction, 4.0))
    $opportunityScore = if ($effort -gt 0.0) {
        [System.Math]::Round(
            (($yieldInstructions * $confidence) / $effort) * $closureFactor,
            3)
    } else {
        [double]0.0
    }
    $portfolioExclusions = @()
    if ($frozen) {
        $portfolioExclusions += "frozen"
    }
    if ($status -ne "OK") {
        $portfolioExclusions += "residual scan failed"
    }
    if ($verifierBlocked) {
        $portfolioExclusions += "verifier blocked"
    }
    if ($implementationKind -ne "cpp" -and
        $implementationKind -ne "toolchain-lib") {
        $portfolioExclusions += "implementation is not policy-compliant C++/toolchain-lib"
    }
    if ($productReachable -eq "False") {
        $portfolioExclusions += "C++ row is outside the strict Product graph"
    }
    if ($yieldInstructions -le 0) {
        $portfolioExclusions += "zero instruction yield"
    }
    if ($null -ne $sessionLaneMetadata -and
        $sessionLaneMetadata.State -in @("paused", "frozen", "closed")) {
        $portfolioExclusions += ("session lane is {0}" -f
            $sessionLaneMetadata.State)
    }
    $readinessRequired = ($portfolioExclusions.Count -eq 0)
    if ($readinessClassification -ne "ready") {
        if ($readinessClassification -eq "unclassified") {
            $portfolioExclusions += "checkpoint-bound readiness metadata is required"
            if ($readinessRequired) {
                $missingRequiredReadiness.Add(("{0} {1} ({2})" -f
                    $program, ("0x{0:x}" -f $originalRva), $name))
            }
        } else {
            $portfolioExclusions += ("readiness is {0}" -f
                $readinessClassification)
        }
    }
    $portfolioEligible = ($portfolioExclusions.Count -eq 0)
    $queueScore = if ($portfolioEligible) { $opportunityScore } else { [double]0.0 }

    $results += [pscustomobject][ordered]@{
        Name = $name
        Program = $program
        Lane = Get-Lane $name
        OriginalRva = ("0x{0:x}" -f $originalRva)
        Size = $size
        CandidateRva = if ($null -ne $candidateRva) { "0x{0:x}" -f $candidateRva } else { "" }
        CandidateSymbol = Get-CsvField $row "candidate_symbol"

        # Backward-compatible residual fields.
        DiffCount = $legacyDiffCount
        DiffPercent = $legacyDiffPercent
        ResidualClass = $residualClass
        PriorityScore = Get-PriorityScore $name $legacyDiffCount $size
        Status = $status
        DiffOffsets = if ($IncludeOffsets) {
            ($legacyOffsets | ForEach-Object { "0x{0:x}" -f $_ }) -join " "
        } else {
            ""
        }
        Notes = Get-CsvField $row "notes"

        RawDiffCount = $rawDiffCount
        MaskBytes = $maskBytes
        MaskSha256 = $maskSha256
        HardComparedBytes = $hardComparedBytes
        HardDiffCount = $hardDiffCount
        HardDiffPercent = $hardDiffPercent
        HardResidualClass = $hardResidualClass
        HardDiffOffsets = if ($IncludeOffsets) {
            ($hardDiffOffsets | ForEach-Object { "0x{0:x}" -f $_ }) -join " "
        } else {
            ""
        }

        YieldInstructions = $yieldInstructions
        ImplementationKind = $implementationKind
        Confidence = [System.Math]::Round($confidence, 3)
        ConfidenceSource = $confidenceSource
        Effort = [System.Math]::Round($effort, 3)
        EffortSource = $effortSource
        OpportunityScore = $opportunityScore
        MatchedFraction = [System.Math]::Round($matchedFraction, 4)
        ClosureFactor = [System.Math]::Round($closureFactor, 4)
        QueueScore = $queueScore
        QueueRank = ""
        PortfolioSelected = $false
        PortfolioOrder = ""
        PortfolioCumulativeInstructions = ""
        AssignmentId = ""
        AssignmentRole = ""
        AssignmentPrimaryName = ""
        AssignmentPrimaryLane = ""
        AssignmentAlternateName = ""
        AssignmentAlternateLane = ""
        PortfolioEligible = $portfolioEligible
        PortfolioExclusionReason = $portfolioExclusions -join "; "

        Readiness = $readinessClassification
        ReadinessSource = $readinessSource
        ReadinessDependencyState = $readinessDependencyState
        ReadinessReason = $readinessReason
        ReadinessTemplateDefault = if ($null -ne $readinessMetadata) {
            $readinessMetadata.TemplateDefault
        } else {
            ""
        }
        ReadinessEvidencePath = if ($null -ne $readinessMetadata) {
            $readinessMetadata.EvidencePath
        } else {
            ""
        }
        ReadinessEvidenceSha256 = if ($null -ne $readinessMetadata) {
            $readinessMetadata.EvidenceSha256
        } else {
            ""
        }
        ReadinessCandidateBodyBytes = if ($null -ne $readinessMetadata -and
            $null -ne $readinessMetadata.CandidateBodyBytes) {
            $readinessMetadata.CandidateBodyBytes
        } else {
            ""
        }
        ReadinessCandidateInstructionCount = if (
            $null -ne $readinessMetadata -and
            $null -ne $readinessMetadata.CandidateInstructionCount) {
            $readinessMetadata.CandidateInstructionCount
        } else {
            ""
        }

        SessionLaneState = if ($null -ne $sessionLaneMetadata) {
            $sessionLaneMetadata.State
        } else {
            ""
        }
        SessionLaneHypothesis = if ($null -ne $sessionLaneMetadata) {
            $sessionLaneMetadata.Hypothesis
        } else {
            ""
        }
        SessionLaneStartedUtc = if ($null -ne $sessionLaneMetadata) {
            $sessionLaneMetadata.StartedUtc
        } else {
            ""
        }
        SessionLaneUpdatedUtc = if ($null -ne $sessionLaneMetadata) {
            $sessionLaneMetadata.UpdatedUtc
        } else {
            ""
        }
        SessionLaneActiveRecoveryMinutes = if ($null -ne $sessionLaneMetadata) {
            $sessionLaneMetadata.ActiveRecoveryMinutes
        } else {
            ""
        }
        SessionLaneToolTimeMs = if ($null -ne $sessionLaneMetadata) {
            $sessionLaneMetadata.ToolTimeMs
        } else {
            ""
        }
        SessionLaneMeaningfulVariantCount = if ($null -ne $sessionLaneMetadata) {
            $sessionLaneMetadata.MeaningfulVariantCount
        } else {
            ""
        }
        SessionLaneEvidencePath = if ($null -ne $sessionLaneMetadata) {
            $sessionLaneMetadata.EvidencePath
        } else {
            ""
        }
        SessionLaneEvidenceSha256 = if ($null -ne $sessionLaneMetadata) {
            $sessionLaneMetadata.EvidenceSha256
        } else {
            ""
        }
        SessionLaneSourcePath = if ($null -ne $sessionLaneMetadata) {
            $sessionLaneMetadata.SourcePath
        } else {
            ""
        }
        SessionLaneSourceSha256 = if ($null -ne $sessionLaneMetadata) {
            $sessionLaneMetadata.SourceSha256
        } else {
            ""
        }
        SessionLaneResidualKind = if ($null -ne $sessionLaneMetadata) {
            $sessionLaneMetadata.ResidualKind
        } else {
            ""
        }
        SessionLaneBoundHardDiffCount = if ($null -ne $sessionLaneMetadata) {
            $sessionLaneMetadata.HardDiffCount
        } else {
            ""
        }
        SessionLaneBoundComparedBytes = if ($null -ne $sessionLaneMetadata) {
            $sessionLaneMetadata.ComparedBytes
        } else {
            ""
        }
        SessionLaneCandidateFunctionSha256 = if ($null -ne $sessionLaneMetadata) {
            $sessionLaneMetadata.CandidateFunctionSha256
        } else {
            ""
        }

        Frozen = $frozen
        FreezeDate = if ($null -ne $frozenMetadata) { $frozenMetadata.FreezeDate } else { "" }
        EvidencePath = if ($null -ne $frozenMetadata) { $frozenMetadata.EvidencePath } else { "" }
        EvidenceSha256 = if ($null -ne $frozenMetadata) {
            $frozenMetadata.EvidenceSha256
        } else {
            ""
        }
        SourcePath = if ($null -ne $frozenMetadata) { $frozenMetadata.SourcePath } else { "" }
        SourceSha256 = if ($null -ne $frozenMetadata) { $frozenMetadata.SourceSha256 } else { "" }
        MeaningfulVariantCount = if ($null -ne $frozenMetadata) {
            $frozenMetadata.MeaningfulVariantCount
        } else {
            ""
        }
        ResidualKind = if ($null -ne $frozenMetadata) { $frozenMetadata.ResidualKind } else { "" }
        BoundHardDiffCount = if ($null -ne $frozenMetadata) {
            $frozenMetadata.BoundHardDiffCount
        } else {
            ""
        }
        BoundComparedBytes = if ($null -ne $frozenMetadata) {
            $frozenMetadata.BoundComparedBytes
        } else {
            ""
        }
        BoundHardDiffCountMatches = if ($null -ne $frozenMetadata -and
            $hardDiffCount -ne $maxDiagnosticDiff) {
            [int64]$frozenMetadata.BoundHardDiffCount -eq [int64]$hardDiffCount
        } else {
            ""
        }
        BoundComparedBytesMatches = if ($null -ne $frozenMetadata -and
            $hardDiffCount -ne $maxDiagnosticDiff) {
            [int64]$frozenMetadata.BoundComparedBytes -eq
                [int64]$hardComparedBytes
        } else {
            ""
        }
        BaselineOriginalSha256 = if ($null -ne $frozenMetadata) {
            $frozenMetadata.BaselineOriginalSha256
        } else {
            ""
        }
        BaselineCandidateSha256 = if ($null -ne $frozenMetadata) {
            $frozenMetadata.BaselineCandidateSha256
        } else {
            ""
        }
        BaselineCandidateObject = if ($null -ne $frozenMetadata) {
            $frozenMetadata.BaselineCandidateObject
        } else {
            ""
        }
        BaselineCandidateObjectSha256 = if ($null -ne $frozenMetadata) {
            $frozenMetadata.BaselineCandidateObjectSha256
        } else {
            ""
        }
        BaselineCandidateFunctionSha256 = if ($null -ne $frozenMetadata) {
            $frozenMetadata.BaselineCandidateFunctionSha256
        } else {
            ""
        }
        CurrentCandidateFileSha256 = $scannerCandidateSha256
        CurrentCandidateObject = if ($null -ne $candidateObjectEvidence) {
            $candidateObjectEvidence.Name
        } else {
            ""
        }
        CurrentCandidateObjectPath = if ($null -ne $candidateObjectEvidence) {
            $candidateObjectEvidence.Path
        } else {
            ""
        }
        CurrentCandidateObjectSha256 = if ($null -ne $candidateObjectEvidence) {
            $candidateObjectEvidence.Sha256
        } else {
            ""
        }
        CurrentCandidateFunctionSha256 = $candidateFunctionSha256
        BaselineCandidateFileMatches = if ($null -ne $frozenMetadata -and
            -not [string]::IsNullOrWhiteSpace(
                $frozenMetadata.BaselineCandidateSha256)) {
            $frozenMetadata.BaselineCandidateSha256 -ceq $scannerCandidateSha256
        } else {
            ""
        }
        BaselineCandidateObjectMatches = if (
            $null -ne $frozenMetadata -and
            $null -ne $candidateObjectEvidence) {
            $frozenMetadata.BaselineCandidateObject -ceq
                $candidateObjectEvidence.Name -and
                $frozenMetadata.BaselineCandidateObjectSha256 -ceq
                    $candidateObjectEvidence.Sha256
        } else {
            ""
        }
        BaselineCandidateFunctionMatches = if (
            $null -ne $frozenMetadata -and
            -not [string]::IsNullOrWhiteSpace(
                $frozenMetadata.BaselineCandidateFunctionSha256)) {
            $frozenMetadata.BaselineCandidateFunctionSha256 -ceq
                $candidateFunctionSha256
        } else {
            ""
        }
        FrozenDiagnosticNote = if ($null -ne $frozenMetadata) {
            $frozenMetadata.DiagnosticNote
        } else {
            ""
        }
        FreezeReason = if ($null -ne $frozenMetadata) { $frozenMetadata.Reason } else { "" }
        RevisitCondition = if ($null -ne $frozenMetadata) {
            $frozenMetadata.RevisitCondition
        } else {
            ""
        }

        ProductReachable = $productReachable
        VerifierDiagnosticsAvailable = $null -ne $verifier
        VerifierActualStatus = $verifierActualStatus
        VerificationStatus = $verificationStatus
        PromotionReady = $promotionReady
        VerifierBlocked = $verifierBlocked
        MaskShapeValid = $maskShapeValid
        MaskedOperandShapeError = $maskedOperandShapeError
        VerifierFirstDiff = Get-CsvField $verifier "first_diff"
        VerifierError = $verifierError
        MaskedImportIdentityError = $maskedImportIdentityError
        CandidateObject = if (-not [string]::IsNullOrWhiteSpace(
            (Get-CsvField $verifier "candidate_object"))) {
            Get-CsvField $verifier "candidate_object"
        } else {
            Get-CsvField $row "candidate_object"
        }
    }
}

$queue = @($results | Where-Object { $_.PortfolioEligible } |
    Sort-Object `
        @{ Expression = "QueueScore"; Descending = $true },
        @{ Expression = "YieldInstructions"; Descending = $true },
        @{ Expression = "HardDiffCount"; Ascending = $true },
        @{ Expression = "Name"; Ascending = $true })
$queueRank = 0
foreach ($item in $queue) {
    $queueRank++
    $item.QueueRank = $queueRank
}

$currentPercent = if ($totalInstructions -gt 0) {
    ($acceptedInstructions / [double]$totalInstructions) * 100.0
} else {
    0.0
}
$nextCheckpointPercent = if ($acceptedInstructions -ge $totalInstructions) {
    100.0
} else {
    [System.Math]::Min(
        100.0,
        ([System.Math]::Floor($currentPercent / $CheckpointStepPercent) + 1.0) *
            $CheckpointStepPercent)
}
$nextCheckpointThreshold = [int64][System.Math]::Ceiling(
    $totalInstructions * ($nextCheckpointPercent / 100.0))
$nextCheckpointRequirement = [int64][System.Math]::Max(
    0.0, $nextCheckpointThreshold - $acceptedInstructions)
$automaticPortfolioTarget = [int][System.Math]::Ceiling(
    $nextCheckpointRequirement * $PortfolioMultiplier)
if (-not $AllowNonstandardPortfolioPolicy -and
    $PortfolioTargetInstructions -gt 0 -and
    $PortfolioTargetInstructions -lt $automaticPortfolioTarget) {
    throw (("PortfolioTargetInstructions cannot reduce the automatic {0}-" +
        "instruction recovery floor. Use -AllowNonstandardPortfolioPolicy " +
        "only for explicit diagnostics.") -f $automaticPortfolioTarget)
}
$portfolioTarget = if ($PortfolioTargetInstructions -gt 0) {
    $PortfolioTargetInstructions
} else {
    $automaticPortfolioTarget
}

$portfolioInstructions = 0
$portfolioCount = 0
$portfolioSelectionOrder = 0
$assignments = @()
$incompleteAssignmentCount = 0
if ($portfolioTarget -gt 0) {
    $remainingQueue = New-Object 'System.Collections.Generic.List[object]'
    foreach ($queueItem in $queue) {
        $remainingQueue.Add($queueItem)
    }

    while ($portfolioInstructions -lt $portfolioTarget -and
        $remainingQueue.Count -gt 0) {
        $primary = $remainingQueue[0]
        $remainingQueue.RemoveAt(0)

        $alternate = $null
        $alternateIndex = -1
        if (-not $SerialPortfolio) {
            for ($index = 0; $index -lt $remainingQueue.Count; $index++) {
                if ($remainingQueue[$index].Lane -ceq $primary.Lane) {
                    $alternateIndex = $index
                    break
                }
            }
            if ($alternateIndex -lt 0 -and $remainingQueue.Count -gt 0) {
                $alternateIndex = 0
            }
            if ($alternateIndex -ge 0) {
                $alternate = $remainingQueue[$alternateIndex]
                $remainingQueue.RemoveAt($alternateIndex)
            }
        }

        $assignmentNumber = $assignments.Count + 1
        $assignmentId = "A{0:d3}" -f $assignmentNumber
        $alternateName = if ($null -ne $alternate) { $alternate.Name } else { "" }
        $alternateLane = if ($null -ne $alternate) { $alternate.Lane } else { "" }

        $portfolioSelectionOrder++
        $portfolioInstructions += [int]$primary.YieldInstructions
        $primary.PortfolioSelected = $true
        $primary.PortfolioOrder = $portfolioSelectionOrder
        $primary.PortfolioCumulativeInstructions = $portfolioInstructions
        $primary.AssignmentId = $assignmentId
        $primary.AssignmentRole = "primary"
        $primary.AssignmentPrimaryName = $primary.Name
        $primary.AssignmentPrimaryLane = $primary.Lane
        $primary.AssignmentAlternateName = $alternateName
        $primary.AssignmentAlternateLane = $alternateLane

        if ($null -ne $alternate) {
            $portfolioSelectionOrder++
            $portfolioInstructions += [int]$alternate.YieldInstructions
            $alternate.PortfolioSelected = $true
            $alternate.PortfolioOrder = $portfolioSelectionOrder
            $alternate.PortfolioCumulativeInstructions = $portfolioInstructions
            $alternate.AssignmentId = $assignmentId
            $alternate.AssignmentRole = "alternate"
            $alternate.AssignmentPrimaryName = $primary.Name
            $alternate.AssignmentPrimaryLane = $primary.Lane
            $alternate.AssignmentAlternateName = $alternate.Name
            $alternate.AssignmentAlternateLane = $alternate.Lane
        } elseif (-not $SerialPortfolio) {
            $incompleteAssignmentCount++
        }

        $assignmentInstructions = [int]$primary.YieldInstructions
        if ($null -ne $alternate) {
            $assignmentInstructions += [int]$alternate.YieldInstructions
        }
        $assignments += [pscustomobject][ordered]@{
            AssignmentId = $assignmentId
            PrimaryQueueRank = $primary.QueueRank
            PrimaryName = $primary.Name
            PrimaryLane = $primary.Lane
            PrimaryOriginalRva = $primary.OriginalRva
            PrimaryYieldInstructions = $primary.YieldInstructions
            AlternateQueueRank = if ($null -ne $alternate) {
                $alternate.QueueRank
            } else {
                ""
            }
            AlternateName = $alternateName
            AlternateLane = $alternateLane
            AlternateOriginalRva = if ($null -ne $alternate) {
                $alternate.OriginalRva
            } else {
                ""
            }
            AlternateYieldInstructions = if ($null -ne $alternate) {
                $alternate.YieldInstructions
            } else {
                ""
            }
            AssignmentInstructions = $assignmentInstructions
            PortfolioCumulativeInstructions = $portfolioInstructions
            Complete = $null -ne $alternate
        }
    }
}
$portfolioCount = $portfolioSelectionOrder

$sorted = @($results | Sort-Object `
    @{ Expression = "Frozen"; Ascending = $true },
    @{ Expression = "QueueScore"; Descending = $true },
    @{ Expression = "YieldInstructions"; Descending = $true },
    @{ Expression = "HardDiffCount"; Ascending = $true },
    @{ Expression = "Name"; Ascending = $true })
$csvPath = Join-Path $outputFullPath "wip-residual-dashboard.csv"
$mdPath = Join-Path $outputFullPath "wip-residual-dashboard.md"
$assignmentsCsvPath = Join-Path $outputFullPath "wip-lane-assignments.csv"
$sessionLaneTemplatePath = Join-Path $outputFullPath `
    "session-lane-ledger.template.json"
$readinessTemplatePath = Join-Path $outputFullPath `
    "readiness-ledger.template.json"

$templateSessionId = "checkpoint-{0}-{1}" -f
    $checkpointInputHashes.progress_metrics_summary_sha256.Substring(0, 12),
    $checkpointInputHashes.candidate_file_sha256.Substring(0, 12)
$templateInputs = [pscustomobject][ordered]@{
    manifest_sha256 = $checkpointInputHashes.manifest_sha256
    verifier_results_sha256 = $checkpointInputHashes.verifier_results_sha256
    progress_metrics_summary_sha256 = `
        $checkpointInputHashes.progress_metrics_summary_sha256
    candidate_file_sha256 = $checkpointInputHashes.candidate_file_sha256
    candidate_map_sha256 = $checkpointInputHashes.candidate_map_sha256
    original_exe_sha256 = $checkpointInputHashes.original_exe_sha256
    original_dll_sha256 = $checkpointInputHashes.original_dll_sha256
}
$sessionLaneTemplate = [pscustomobject][ordered]@{
    schema_version = 1
    session_id = $templateSessionId
    inputs = $templateInputs
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
$readinessTemplateRows = @()
foreach ($templateState in @($manifestStateByKey.Values |
        Where-Object { $_.ExpectedStatus -eq "wip" } |
        Sort-Object Key)) {
    $readinessTemplateRows += [pscustomobject][ordered]@{
        program = $templateState.Program
        original_rva = "0x{0:x}" -f $templateState.OriginalRva
        name = $templateState.Name
        readiness = "needs-implementation"
        dependency_state = "incomplete"
        reason = "Template default: evidence-backed readiness review is incomplete."
        template_default = $true
        evidence_path = ""
        evidence_sha256 = ""
        confidence = ""
        effort = ""
        candidate_body_bytes = ""
        candidate_instruction_count = ""
    }
}
$readinessTemplate = [pscustomobject][ordered]@{
    schema_version = 1
    session_id = $templateSessionId
    inputs = $templateInputs
    rows = $readinessTemplateRows
}

$topRows = @($sorted | Select-Object -First $Top)
$summary = [ordered]@{
    TotalRows = @($results).Count
    ManifestWipRows = @($manifestStateByKey.Values | Where-Object {
        $_.ExpectedStatus -eq "wip"
    }).Count
    NotesFilteredRows = @($wipRows).Count
    OKRows = @($results | Where-Object { $_.Status -eq "OK" }).Count
    ClosedRows = @($results | Where-Object { $_.HardDiffCount -eq 0 }).Count
    TinyRows = @($results | Where-Object { $_.HardResidualClass -eq "tiny" }).Count
    NearRows = @($results | Where-Object { $_.HardResidualClass -eq "near" }).Count
    SmallRows = @($results | Where-Object { $_.HardResidualClass -eq "small" }).Count
    FrozenRows = @($results | Where-Object { $_.Frozen }).Count
    SessionActiveRows = @($results | Where-Object {
        $_.SessionLaneState -eq "active"
    }).Count
    SessionPausedRows = @($results | Where-Object {
        $_.SessionLaneState -eq "paused"
    }).Count
    SessionFrozenRows = @($results | Where-Object {
        $_.SessionLaneState -eq "frozen"
    }).Count
    SessionClosedRows = @($results | Where-Object {
        $_.SessionLaneState -eq "closed"
    }).Count
    ReadinessReadyRows = @($results | Where-Object {
        $_.Readiness -eq "ready"
    }).Count
    ReadinessNeedsImplementationRows = @($results | Where-Object {
        $_.Readiness -eq "needs-implementation"
    }).Count
    ReadinessBlockedRows = @($results | Where-Object {
        $_.Readiness -eq "blocked"
    }).Count
    ReadinessUnclassifiedRows = @($results | Where-Object {
        $_.Readiness -eq "unclassified"
    }).Count
    MissingRequiredReadinessRows = $missingRequiredReadiness.Count
    PortfolioEligibleRows = @($results | Where-Object {
        $_.PortfolioEligible
    }).Count
    ProductUnreachableWipRows = @($results | Where-Object {
        $_.ProductReachable -eq "False"
    }).Count
    TotalInstructions = $totalInstructions
    AcceptedInstructions = $acceptedInstructions
    CurrentInstructionPercent = [System.Math]::Round($currentPercent, 2)
    NextCheckpointPercent = [System.Math]::Round($nextCheckpointPercent, 2)
    NextCheckpointThreshold = $nextCheckpointThreshold
    NextCheckpointRequirement = $nextCheckpointRequirement
    PortfolioMultiplier = $PortfolioMultiplier
    SerialPortfolio = [bool]$SerialPortfolio
    RetiredFrozenRows = $retiredFrozenRows.Count
    PortfolioTargetInstructions = $portfolioTarget
    PortfolioSelectedRows = $portfolioCount
    PortfolioSelectedInstructions = $portfolioInstructions
    PortfolioAssignments = @($assignments).Count
    CompleteAssignments = @($assignments | Where-Object { $_.Complete }).Count
    IncompleteAssignments = $incompleteAssignmentCount
    PortfolioShortfallInstructions = [System.Math]::Max(
        0, $portfolioTarget - $portfolioInstructions)
    VerifierDiagnostics = if ($null -ne $verifierFullPath) { $verifierFullPath } else { "unavailable" }
    ProductReachability = if ($null -ne $productSourceFullPath) {
        $productSourceFullPath
    } else {
        "unavailable"
    }
    FrozenMetadata = if ($null -ne $frozenFullPath) { $frozenFullPath } else { "unavailable" }
    SessionLaneMetadata = if ($null -ne $sessionLaneLedgerFullPath) {
        $sessionLaneLedgerFullPath
    } else {
        "unavailable"
    }
    ReadinessMetadata = if ($null -ne $readinessLedgerFullPath) {
        $readinessLedgerFullPath
    } elseif ($AllowHeuristicReadiness) {
        "heuristic-diagnostic override"
    } else {
        "unavailable"
    }
    SessionLaneSeedTemplate = $sessionLaneTemplatePath
    ReadinessSeedTemplate = $readinessTemplatePath
}

$markdown = New-Object System.Collections.Generic.List[string]
$markdown.Add("# WIP Residual Dashboard")
$markdown.Add("")
$markdown.Add(("Generated: {0:yyyy-MM-dd HH:mm:ss zzz}" -f (Get-Date)))
$markdown.Add("")
$markdown.Add(("Manifest: ``{0}``" -f $ManifestPath))
$markdown.Add(("Candidate: ``{0}``" -f $CandidatePath))
$markdown.Add("")
$markdown.Add("## Summary")
$markdown.Add("")
foreach ($summaryKey in $summary.Keys) {
    $markdown.Add(("- {0}: ``{1}``" -f $summaryKey, $summary[$summaryKey]))
}
$markdown.Add("")
$markdown.Add("## Primary and Alternate Lane Assignments")
$markdown.Add("")
$markdown.Add("| Assignment | Primary | Primary lane | Alternate | Alternate lane | Instructions | Cumulative |")
$markdown.Add("|---|---|---|---|---|---:|---:|")
foreach ($assignment in $assignments) {
    $markdown.Add((
        "| {0} | ``{1}`` | {2} | ``{3}`` | {4} | {5} | {6} |" -f
        $assignment.AssignmentId,
        $assignment.PrimaryName,
        $assignment.PrimaryLane,
        $assignment.AlternateName,
        $assignment.AlternateLane,
        $assignment.AssignmentInstructions,
        $assignment.PortfolioCumulativeInstructions))
}
$markdown.Add("")
$markdown.Add(("## Top {0} Ranked Targets" -f $Top))
$markdown.Add("")
$markdown.Add("| Rank | Name | Lane | RVA | Yield | Hard diff | Class | Confidence | Effort | Score | Product | Frozen | Portfolio |")
$markdown.Add("|---:|---|---|---:|---:|---:|---|---:|---:|---:|---|---|---|")
$rank = 0
foreach ($item in $topRows) {
    $rank++
    $portfolioMarker = if ($item.PortfolioSelected) { "yes" } else { "" }
    $markdown.Add((
        "| {0} | ``{1}`` | {2} | ``{3}`` | {4} | {5} | {6} | {7} | {8} | {9} | {10} | {11} | {12} |" -f
        $rank,
        $item.Name,
        $item.Lane,
        $item.OriginalRva,
        $item.YieldInstructions,
        $item.HardDiffCount,
        $item.HardResidualClass,
        $item.Confidence,
        $item.Effort,
        $item.QueueScore,
        $item.ProductReachable,
        $item.Frozen,
        $portfolioMarker))
}
$markdown.Add("")
$markdown.Add(("CSV output: ``{0}``" -f $csvPath))
$markdown.Add(("Assignment CSV output: ``{0}``" -f $assignmentsCsvPath))

[void][System.IO.Directory]::CreateDirectory($outputFullPath)
Export-CsvAtomically -Rows $sorted -Path $csvPath
Export-CsvAtomically -Rows @($assignments) -Path $assignmentsCsvPath
Write-JsonAtomically -Value $sessionLaneTemplate -Path $sessionLaneTemplatePath
Write-JsonAtomically -Value $readinessTemplate -Path $readinessTemplatePath
Write-LinesAtomically -Lines $markdown.ToArray() -Path $mdPath

Write-Host "WIP residual dashboard"
Write-Host ("  Rows scanned:          {0}" -f @($results).Count)
Write-Host ("  Frozen rows:           {0}" -f $summary.FrozenRows)
Write-Host ("  Current instructions:  {0}/{1} ({2:n2}%)" -f
    $acceptedInstructions, $totalInstructions, $currentPercent)
Write-Host ("  Next checkpoint:       {0:n2}% ({1} more instructions)" -f
    $nextCheckpointPercent, $nextCheckpointRequirement)
Write-Host ("  Portfolio target:      {0} instructions ({1:n2}x)" -f
    $portfolioTarget, $PortfolioMultiplier)
Write-Host ("  Portfolio selected:    {0} rows / {1} instructions" -f
    $portfolioCount, $portfolioInstructions)
Write-Host ("  Lane assignments:      {0} ({1} incomplete)" -f
    @($assignments).Count, $incompleteAssignmentCount)
Write-Host ("  CSV:                   {0}" -f $csvPath)
Write-Host ("  Assignments:           {0}" -f $assignmentsCsvPath)
Write-Host ("  Session seed:          {0}" -f $sessionLaneTemplatePath)
Write-Host ("  Readiness seed:        {0}" -f $readinessTemplatePath)
Write-Host ("  Markdown:              {0}" -f $mdPath)
Write-Host ""
$topRows |
    Select-Object QueueRank, Name, Lane, OriginalRva, YieldInstructions,
        HardDiffCount, HardResidualClass, Confidence, Effort, QueueScore,
        Frozen, PortfolioSelected |
    Format-Table -AutoSize

if ($missingRequiredReadiness.Count -gt 0) {
    throw (("Checkpoint-bound readiness metadata is required for {0} viable " +
        "WIP row(s): {1}. Supply -ReadinessLedgerPath, or use " +
        "-AllowHeuristicReadiness for explicit compatibility diagnostics " +
        "only.") -f
        $missingRequiredReadiness.Count,
        ($missingRequiredReadiness -join "; "))
}
if ($incompleteAssignmentCount -gt 0 -and
    -not $AllowIncompleteAssignments) {
    throw (("Recovery portfolio contains {0} incomplete primary/alternate " +
        "lane assignment(s). Add another ready row or use " +
        "-AllowIncompleteAssignments for diagnostics only.") -f
        $incompleteAssignmentCount)
}
if ($summary.PortfolioShortfallInstructions -gt 0 -and
    -not $AllowPortfolioShortfall) {
    throw (("Recovery portfolio is short by {0} instruction(s): selected {1} " +
        "of the required {2}. Add viable WIP rows, revisit a lane only with " +
        "its required evidence, or use -AllowPortfolioShortfall for " +
        "diagnostics only.") -f
        $summary.PortfolioShortfallInstructions,
        $portfolioInstructions,
        $portfolioTarget)
}
