[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [Alias("Name")]
    [string]$FunctionName,

    [Parameter(Mandatory = $true)]
    [string]$Program,

    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,

    [Parameter(Mandatory = $true)]
    [string]$VerifierResultsPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,

    [string]$OutputBaseName = "",
    [string]$ProgressMetricsSummaryPath = "",
    [string]$MaskAuditResultsPath = "",
    [string]$FrozenWipPath = "",
    [string]$SessionLaneLedgerPath = "",
    [string]$ReadinessLedgerPath = "",
    [string]$ExeProductSourceManifestPath = "",
    [string]$TuMetadataPath = "",
    [string]$SourceRoot = "src\otwin",
    [string]$GhidraOutputDirectory = "tools\ghidra\otwin32\output",
    [string[]]$RecoveryNotesRoot = @("docs\recovery")
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$allowedTextExtensions = @(
    ".c", ".cpp", ".csv", ".h", ".hpp", ".json", ".log", ".md",
    ".ps1", ".txt")
$snapshotCache = @{}
$fileSnapshotCache = @{}
$evidenceMap = @{}
$warnings = New-Object System.Collections.ArrayList

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

function Add-Warning([string]$Message) {
    if (-not [string]::IsNullOrWhiteSpace($Message)) {
        [void]$warnings.Add($Message.Trim())
    }
}

function Get-FileSha256Hex([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-BytesSha256Hex([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return [System.BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace(
            "-", "").ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Resolve-InputPath([string]$Path, [string]$Description) {
    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "$Description path is empty."
    }
    $candidate = if ([System.IO.Path]::IsPathRooted($Path)) {
        $Path
    }
    else {
        Join-Path $repoRoot $Path
    }
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        throw "$Description was not found: '$candidate'."
    }
    return (Resolve-Path -LiteralPath $candidate).Path
}

function Resolve-OptionalDirectory([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ""
    }
    $candidate = if ([System.IO.Path]::IsPathRooted($Path)) {
        $Path
    }
    else {
        Join-Path $repoRoot $Path
    }
    if (-not (Test-Path -LiteralPath $candidate -PathType Container)) {
        return ""
    }
    return (Resolve-Path -LiteralPath $candidate).Path
}

function Get-DisplayPath([string]$ResolvedPath) {
    $repoPrefix = $repoRoot.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    if ($ResolvedPath.StartsWith(
            $repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $ResolvedPath.Substring($repoPrefix.Length).Replace('\', '/')
    }
    return $ResolvedPath.Replace('\', '/')
}

function Get-TextSnapshot([string]$Path, [string]$Description) {
    $resolvedPath = Resolve-InputPath $Path $Description
    $cacheKey = $resolvedPath.ToLowerInvariant()
    if ($snapshotCache.ContainsKey($cacheKey)) {
        return $snapshotCache[$cacheKey]
    }

    $extension = [System.IO.Path]::GetExtension($resolvedPath).ToLowerInvariant()
    if ($allowedTextExtensions -notcontains $extension) {
        throw ("{0} must be a text artifact; extension '{1}' is not allowed. " +
            "Binary verifier provenance is hashed separately and is never " +
            "copied into a dossier.") -f
            $Description, $extension
    }
    $bytes = [System.IO.File]::ReadAllBytes($resolvedPath)
    if ($bytes -contains [byte]0) {
        throw "$Description appears to contain binary data: '$resolvedPath'."
    }

    $stream = New-Object System.IO.MemoryStream(,$bytes)
    $reader = New-Object System.IO.StreamReader(
        $stream, [System.Text.Encoding]::UTF8, $true)
    try {
        $text = $reader.ReadToEnd()
    }
    finally {
        $reader.Dispose()
        $stream.Dispose()
    }

    $snapshot = [pscustomobject]@{
        Path = $resolvedPath
        DisplayPath = Get-DisplayPath $resolvedPath
        Sha256 = Get-BytesSha256Hex $bytes
        Length = [long]$bytes.Length
        Text = $text
    }
    $snapshotCache[$cacheKey] = $snapshot
    return $snapshot
}

function Get-FileSnapshot([string]$Path, [string]$Description) {
    $resolvedPath = Resolve-InputPath $Path $Description
    $cacheKey = $resolvedPath.ToLowerInvariant()
    if ($fileSnapshotCache.ContainsKey($cacheKey)) {
        return $fileSnapshotCache[$cacheKey]
    }
    $item = Get-Item -LiteralPath $resolvedPath -Force
    if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "$Description may not be a reparse-point file: '$resolvedPath'."
    }
    $snapshot = [pscustomobject]@{
        Path = $resolvedPath
        DisplayPath = Get-DisplayPath $resolvedPath
        Sha256 = Get-FileSha256Hex $resolvedPath
        Length = [long]$item.Length
    }
    $fileSnapshotCache[$cacheKey] = $snapshot
    return $snapshot
}

function Add-Evidence($Snapshot, [string]$Role) {
    $key = ([string]$Snapshot.Path).ToLowerInvariant()
    if (-not $evidenceMap.ContainsKey($key)) {
        $roles = New-Object 'System.Collections.Generic.HashSet[string]' (
            [System.StringComparer]::Ordinal)
        $evidenceMap[$key] = [pscustomobject]@{
            Snapshot = $Snapshot
            Roles = $roles
        }
    }
    [void]$evidenceMap[$key].Roles.Add($Role)
}

function Parse-Number([string]$Value, [string]$Description) {
    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "$Description is missing."
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

function Format-Hex([uint64]$Value) {
    return ("0x{0:x8}" -f $Value)
}

function Parse-Boolean([string]$Value, [string]$Description) {
    switch ($Value.Trim().ToLowerInvariant()) {
        "true" { return $true }
        "false" { return $false }
        default { throw "$Description must be 'true' or 'false'." }
    }
}

function Convert-CsvSnapshot($Snapshot, [string]$Description) {
    try {
        return @($Snapshot.Text | ConvertFrom-Csv)
    }
    catch {
        throw "Invalid $Description CSV '$($Snapshot.Path)': $($_.Exception.Message)"
    }
}

function Convert-JsonSnapshot($Snapshot, [string]$Description) {
    try {
        return $Snapshot.Text | ConvertFrom-Json
    }
    catch {
        throw "Invalid $Description JSON '$($Snapshot.Path)': $($_.Exception.Message)"
    }
}

function Assert-Sha256([string]$Value, [string]$Description) {
    $hash = $Value.Trim().ToLowerInvariant()
    if ($hash -notmatch '^[0-9a-f]{64}$') {
        throw "$Description is not a SHA-256 value."
    }
    return $hash
}

function Test-SamePath([string]$Left, [string]$Right) {
    return $Left.Equals($Right, [System.StringComparison]::OrdinalIgnoreCase)
}

function Resolve-PlannedOutputPath(
    [string]$OutputDirectoryPath,
    [string]$LeafName) {

    $path = [System.IO.Path]::GetFullPath(
        (Join-Path $OutputDirectoryPath $LeafName))
    $parent = [System.IO.Path]::GetFullPath((Split-Path -Parent $path))
    if (-not (Test-SamePath $parent $OutputDirectoryPath)) {
        throw "Planned dossier output escapes its validated output directory."
    }
    if (Test-Path -LiteralPath $path) {
        $item = Get-Item -LiteralPath $path -Force
        if ($item.PSIsContainer) {
            throw "Planned dossier output is an existing directory: '$path'."
        }
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Planned dossier output may not be a reparse-point file: '$path'."
        }
        return $item.FullName
    }
    return $path
}

function Get-MaskByteCount(
    [string]$MaskText,
    [uint64]$Size,
    [string]$Description) {

    if ([string]::IsNullOrWhiteSpace($MaskText)) {
        return [uint64]0
    }
    $offsets = New-Object 'System.Collections.Generic.HashSet[uint64]'
    foreach ($token in ($MaskText -split '[\s,;]+')) {
        if ([string]::IsNullOrWhiteSpace($token)) {
            continue
        }
        if ($token -notmatch '^(\d+)-(\d+)$') {
            throw "$Description has invalid mask token '$token'."
        }
        $start = [uint64]::Parse($Matches[1],
            [System.Globalization.CultureInfo]::InvariantCulture)
        $end = [uint64]::Parse($Matches[2],
            [System.Globalization.CultureInfo]::InvariantCulture)
        if ($end -lt $start -or $end -ge $Size) {
            throw "$Description mask token '$token' is outside the function."
        }
        for ($offset = $start; $offset -le $end; $offset++) {
            if (-not $offsets.Add($offset)) {
                throw "$Description has overlapping mask byte $offset."
            }
        }
    }
    return [uint64]$offsets.Count
}

function Get-VerifierFileProvenance(
    $Row,
    [string]$PathField,
    [string]$HashField,
    [string]$Description,
    [string]$Role) {

    $path = (Get-CsvField $Row $PathField).Trim()
    $hash = (Get-CsvField $Row $HashField).Trim()
    if ([string]::IsNullOrWhiteSpace($path) -and
        [string]::IsNullOrWhiteSpace($hash)) {
        Add-Warning "$Description provenance is missing; this dossier is planning-only."
        return $null
    }
    if ([string]::IsNullOrWhiteSpace($path) -or
        [string]::IsNullOrWhiteSpace($hash)) {
        throw "$Description provenance must provide both $PathField and $HashField."
    }
    $expectedHash = Assert-Sha256 $hash "$Description $HashField"
    $snapshot = Get-FileSnapshot $path $Description
    if ($snapshot.Sha256 -cne $expectedHash) {
        throw "Stale $Description provenance: SHA-256 changed."
    }
    Add-Evidence $snapshot $Role
    return [pscustomobject][ordered]@{
        path = $snapshot.DisplayPath
        sha256 = $snapshot.Sha256
        length = [long]$snapshot.Length
    }
}

function Assert-OutputDirectorySafe([string]$Path) {
    $fullPath = if ([System.IO.Path]::IsPathRooted($Path)) {
        [System.IO.Path]::GetFullPath($Path)
    }
    else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
    }

    $matchedRoot = ""
    foreach ($allowedName in @("a", "artifacts")) {
        $allowedRoot = [System.IO.Path]::GetFullPath(
            (Join-Path $repoRoot $allowedName))
        $prefix = $allowedRoot.TrimEnd('\', '/') +
            [System.IO.Path]::DirectorySeparatorChar
        if ($fullPath.StartsWith(
                $prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $matchedRoot = $allowedRoot
            break
        }
    }
    if ([string]::IsNullOrWhiteSpace($matchedRoot)) {
        throw ("Dossier output must be beneath a Git-ignored repository 'a' " +
            "or 'artifacts' directory; tracked source/docs destinations are forbidden.")
    }

    $relative = $fullPath.Substring($repoRoot.TrimEnd('\', '/').Length).
        TrimStart('\', '/')
    $cursor = $repoRoot
    foreach ($part in ($relative -split '[\\/]')) {
        if ([string]::IsNullOrWhiteSpace($part)) {
            continue
        }
        $cursor = Join-Path $cursor $part
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Dossier output may not traverse a reparse point: '$cursor'."
            }
        }
    }

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & git -C $repoRoot check-ignore -q -- $relative 2>$null
        $ignoreExit = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
    if ($ignoreExit -ne 0) {
        throw "Dossier output is not Git-ignored: '$fullPath'."
    }
    return $fullPath
}

function Get-SafeSlug([string]$Value) {
    $slug = ($Value -replace '[^A-Za-z0-9._-]+', '-').Trim('-','.')
    if ([string]::IsNullOrWhiteSpace($slug)) {
        return "function"
    }
    return $slug
}

function Get-ObjectNameForSource([string]$ResolvedPath) {
    $repoPrefix = $repoRoot.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    if (-not $ResolvedPath.StartsWith(
            $repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        return ""
    }
    $relative = $ResolvedPath.Substring($repoPrefix.Length)
    return (($relative -replace '[\\/]', '_') -replace '\.cpp$', '.obj')
}

function Normalize-SourcePath([string]$Value) {
    return $Value.Trim().Replace('\', '/').TrimStart('./').ToLowerInvariant()
}

function Resolve-RowByIdentity(
    [object[]]$Rows,
    [string]$Description,
    [string]$Name,
    [string]$ProgramName,
    [uint64]$Rva,
    [switch]$Optional) {

    $nameMatches = @($Rows | Where-Object {
        (Get-CsvField $_ "name").Equals(
            $Name, [System.StringComparison]::OrdinalIgnoreCase) -and
        (Get-CsvField $_ "program").Equals(
            $ProgramName, [System.StringComparison]::OrdinalIgnoreCase)
    })
    if ($nameMatches.Count -eq 0 -and $Optional) {
        return $null
    }
    if ($nameMatches.Count -ne 1) {
        throw ("{0} identity '{1}' in '{2}' is ambiguous or missing; " +
            "expected exactly one row, found {3}.") -f
            $Description, $Name, $ProgramName, $nameMatches.Count
    }
    $rowRva = Parse-Number (Get-CsvField $nameMatches[0] "original_rva") (
        "$Description original_rva")
    if ($rowRva -ne $Rva) {
        throw ("{0} row for '{1}' points at {2}, expected {3}.") -f
            $Description, $Name, (Format-Hex $rowRva), (Format-Hex $Rva)
    }
    return $nameMatches[0]
}

function Get-ProvenanceSnapshot(
    $Record,
    [string]$Description,
    [string]$Role) {

    if ($null -eq $Record -or
        $null -eq $Record.PSObject.Properties["path"] -or
        $null -eq $Record.PSObject.Properties["sha256"]) {
        throw "Metrics summary is missing $Description provenance."
    }
    $snapshot = Get-TextSnapshot ([string]$Record.path) $Description
    $expectedHash = Assert-Sha256 ([string]$Record.sha256) (
        "$Description provenance hash")
    if ($snapshot.Sha256 -cne $expectedHash) {
        throw "Stale $Description evidence: SHA-256 changed."
    }
    Add-Evidence $snapshot $Role
    return $snapshot
}

function Assert-LedgerInputs($Ledger, [string]$Description,
    $ManifestSnapshot, $VerifierSnapshot, $MetricsSnapshot) {
    if ($null -eq $Ledger.PSObject.Properties["inputs"]) {
        throw "$Description is missing its checkpoint inputs."
    }
    $checks = @(
        @("manifest_sha256", $ManifestSnapshot.Sha256),
        @("verifier_results_sha256", $VerifierSnapshot.Sha256)
    )
    if ($null -ne $MetricsSnapshot) {
        $checks += ,@("progress_metrics_summary_sha256", $MetricsSnapshot.Sha256)
    }
    foreach ($check in $checks) {
        $property = $Ledger.inputs.PSObject.Properties[$check[0]]
        if ($null -eq $property) {
            throw "$Description is missing checkpoint input '$($check[0])'."
        }
        $actual = Assert-Sha256 ([string]$property.Value) (
            "$Description input '$($check[0])'")
        if ($actual -cne [string]$check[1]) {
            throw "$Description does not bind the selected $($check[0]) evidence."
        }
    }
}

function Validate-LinkedEvidence(
    $Row,
    [string]$PathField,
    [string]$HashField,
    [string]$Description,
    [string]$Role,
    [switch]$Optional) {

    $path = (Get-CsvField $Row $PathField).Trim()
    $hash = (Get-CsvField $Row $HashField).Trim()
    if ([string]::IsNullOrWhiteSpace($path) -and
        [string]::IsNullOrWhiteSpace($hash) -and $Optional) {
        return $null
    }
    if ([string]::IsNullOrWhiteSpace($path) -or
        [string]::IsNullOrWhiteSpace($hash)) {
        throw "$Description must provide both $PathField and $HashField."
    }
    $snapshot = Get-TextSnapshot $path $Description
    $expected = Assert-Sha256 $hash "$Description $HashField"
    if ($snapshot.Sha256 -cne $expected) {
        throw "$Description is stale: '$PathField' SHA-256 changed."
    }
    Add-Evidence $snapshot $Role
    return $snapshot
}

function Get-OptionalLedgerRow(
    [string]$Path,
    [string]$Description,
    [string]$Role,
    [string]$Name,
    [string]$ProgramName,
    [uint64]$Rva,
    $ManifestSnapshot,
    $VerifierSnapshot,
    $MetricsSnapshot) {

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }
    $snapshot = Get-TextSnapshot $Path $Description
    Add-Evidence $snapshot $Role
    $ledger = Convert-JsonSnapshot $snapshot $Description
    if ([int]$ledger.schema_version -ne 1) {
        throw "$Description has unsupported schema_version; expected 1."
    }
    Assert-LedgerInputs $ledger $Description $ManifestSnapshot `
        $VerifierSnapshot $MetricsSnapshot
    if ($null -eq $ledger.PSObject.Properties["rows"]) {
        throw "$Description is missing its rows array."
    }
    $row = Resolve-RowByIdentity @($ledger.rows) $Description $Name `
        $ProgramName $Rva -Optional
    if ($null -eq $row) {
        Add-Warning "$Description has no row for this function."
        return [pscustomobject]@{
            Snapshot = $snapshot
            Ledger = $ledger
            Row = $null
        }
    }
    return [pscustomobject]@{
        Snapshot = $snapshot
        Ledger = $ledger
        Row = $row
    }
}

function Escape-Markdown([string]$Value) {
    if ($null -eq $Value) {
        return ""
    }
    return $Value.Replace("|", "\|").Replace("`r", " ").Replace("`n", " ")
}

function Write-TextAtomically([string]$Path, [string]$Text) {
    $temporaryPath = Join-Path (Split-Path -Parent $Path) (
        "." + (Split-Path -Leaf $Path) + ".tmp." +
        [guid]::NewGuid().ToString("N"))
    try {
        [System.IO.File]::WriteAllText($temporaryPath, $Text, $utf8NoBom)
        Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

if ([string]::IsNullOrWhiteSpace($OutputBaseName)) {
    $OutputBaseName = (Get-SafeSlug $Program) + "-" +
        (Get-SafeSlug $FunctionName) + "-dossier"
}
if ($OutputBaseName -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
    throw "OutputBaseName contains unsupported characters."
}

$outputDirectoryFullPath = Assert-OutputDirectorySafe $OutputDirectory
$jsonOutputPath = Resolve-PlannedOutputPath $outputDirectoryFullPath `
    ($OutputBaseName + ".json")
$markdownOutputPath = Resolve-PlannedOutputPath $outputDirectoryFullPath `
    ($OutputBaseName + ".md")
if (Test-SamePath $jsonOutputPath $markdownOutputPath) {
    throw "Planned JSON and Markdown dossier outputs alias each other."
}

$manifestSnapshot = Get-TextSnapshot $ManifestPath "Manifest"
$verifierSnapshot = Get-TextSnapshot $VerifierResultsPath "Verifier results"
$generatorSnapshot = Get-TextSnapshot $PSCommandPath "Dossier generator"
Add-Evidence $manifestSnapshot "manifest"
Add-Evidence $verifierSnapshot "schema-4-verifier-results"
Add-Evidence $generatorSnapshot "dossier-generator"

$manifestRows = @(Convert-CsvSnapshot $manifestSnapshot "manifest")
$manifestNameMatches = @($manifestRows | Where-Object {
    (Get-CsvField $_ "name").Equals(
        $FunctionName, [System.StringComparison]::OrdinalIgnoreCase) -and
    (Get-CsvField $_ "program").Equals(
        $Program, [System.StringComparison]::OrdinalIgnoreCase)
})
if ($manifestNameMatches.Count -ne 1) {
    throw ("Manifest identity '{0}' in '{1}' is ambiguous or missing; " +
        "expected exactly one row, found {2}.") -f
        $FunctionName, $Program, $manifestNameMatches.Count
}
$manifestRow = $manifestNameMatches[0]
$manifestRowIndex = [array]::IndexOf($manifestRows, $manifestRow) + 1
$originalRva = Parse-Number (Get-CsvField $manifestRow "original_rva") `
    "manifest original_rva"
$originalVa = Parse-Number (Get-CsvField $manifestRow "original_va") `
    "manifest original_va"
$functionSize = Parse-Number (Get-CsvField $manifestRow "size") "manifest size"
$identityCollisions = @($manifestRows | Where-Object {
    (Get-CsvField $_ "program").Equals(
        (Get-CsvField $manifestRow "program"),
        [System.StringComparison]::OrdinalIgnoreCase) -and
    (Parse-Number (Get-CsvField $_ "original_rva") "manifest original_rva") -eq
        $originalRva
})
if ($identityCollisions.Count -ne 1) {
    throw ("Manifest program/RVA identity {0}|{1} is ambiguous; found {2} rows.") -f
        (Get-CsvField $manifestRow "program"), (Format-Hex $originalRva),
        $identityCollisions.Count
}

$verifierRows = @(Convert-CsvSnapshot $verifierSnapshot "verifier results")
$verifierNameMatches = @($verifierRows | Where-Object {
    (Get-CsvField $_ "name").Equals(
        (Get-CsvField $manifestRow "name"),
        [System.StringComparison]::OrdinalIgnoreCase) -and
    (Get-CsvField $_ "program").Equals(
        (Get-CsvField $manifestRow "program"),
        [System.StringComparison]::OrdinalIgnoreCase)
})
if ($verifierNameMatches.Count -ne 1) {
    throw ("Verifier identity '{0}' in '{1}' is ambiguous or missing; " +
        "expected exactly one row, found {2}.") -f
        (Get-CsvField $manifestRow "name"),
        (Get-CsvField $manifestRow "program"), $verifierNameMatches.Count
}
$verifierRow = $verifierNameMatches[0]
if ((Get-CsvField $verifierRow "result_schema_version").Trim() -cne "4") {
    throw "Unsupported verifier result_schema_version; expected schema 4."
}
$verifierManifestPathText = (Get-CsvField $verifierRow "manifest_path").Trim()
$verifierManifestPath = Resolve-InputPath $verifierManifestPathText `
    "Verifier manifest"
if (-not (Test-SamePath $verifierManifestPath $manifestSnapshot.Path)) {
    throw "Verifier row references a different manifest path."
}
$verifierManifestHash = Assert-Sha256 (
    Get-CsvField $verifierRow "manifest_sha256") "verifier manifest_sha256"
if ($verifierManifestHash -cne $manifestSnapshot.Sha256) {
    throw "Verifier results are stale: manifest SHA-256 changed."
}
$verifierRva = Parse-Number (Get-CsvField $verifierRow "original_rva") `
    "verifier original_rva"
if ($verifierRva -ne $originalRva) {
    throw "Verifier row points at a different original RVA."
}
$verifierRowIndex = Parse-Number (Get-CsvField $verifierRow "row_index") `
    "verifier row_index"
if ($verifierRowIndex -ne [uint64]$manifestRowIndex) {
    throw "Verifier row_index does not match the selected manifest row."
}
$manifestExpectedStatus = (Get-CsvField $manifestRow `
    "expected_status").Trim().ToLowerInvariant()
if ($manifestExpectedStatus -notin @("match", "wip")) {
    throw "Manifest expected_status is unsupported for a schema-4 dossier."
}
$verifierExpectedStatus = (Get-CsvField $verifierRow `
    "expected_status").Trim().ToLowerInvariant()
if ($verifierExpectedStatus -cne $manifestExpectedStatus) {
    throw "Verifier expected_status does not match the manifest."
}
$manifestImplementationKind = (Get-CsvField $manifestRow `
    "implementation_kind").Trim().ToLowerInvariant()
$verifierImplementationKind = (Get-CsvField $verifierRow `
    "implementation_kind").Trim().ToLowerInvariant()
if ($verifierImplementationKind -cne $manifestImplementationKind) {
    throw "Verifier implementation_kind does not match the manifest."
}
foreach ($fieldName in @("candidate_symbol", "candidate_dll", "candidate_object")) {
    $manifestValue = (Get-CsvField $manifestRow $fieldName).Trim()
    $verifierValue = (Get-CsvField $verifierRow $fieldName).Trim()
    if (-not [string]::IsNullOrWhiteSpace($manifestValue) -and
        $verifierValue -cne $manifestValue) {
        throw "Verifier $fieldName does not match the manifest."
    }
}
$verifierMask = (Get-CsvField $verifierRow "mask").Trim()
$manifestMaskForVerifier = (Get-CsvField $manifestRow "mask").Trim()
if ($verifierMask -cne $manifestMaskForVerifier) {
    throw "Verifier mask does not match the manifest."
}

$actualStatus = (Get-CsvField $verifierRow `
    "actual_status").Trim().ToLowerInvariant()
$statusAlias = (Get-CsvField $verifierRow "status").Trim().ToLowerInvariant()
$verificationStatus = (Get-CsvField $verifierRow `
    "verification_status").Trim().ToLowerInvariant()
if ($actualStatus -notin @("match", "mismatch", "error")) {
    throw "Verifier actual_status '$actualStatus' is not a schema-4 status."
}
if ($statusAlias -cne $actualStatus) {
    throw "Verifier status and actual_status disagree."
}
if ($verificationStatus -notin @(
        "pass", "allowed_wip", "promotion_ready", "regression", "error")) {
    throw "Verifier verification_status '$verificationStatus' is unsupported."
}
$promotionReady = Parse-Boolean (
    Get-CsvField $verifierRow "promotion_ready") "verifier promotion_ready"
$rawMatch = Parse-Boolean (
    Get-CsvField $verifierRow "raw_match") "verifier raw_match"
$expectedVerificationStatus = ""
$expectedPromotionReady = $false
if ($actualStatus -eq "error") {
    $expectedVerificationStatus = "error"
}
elseif ($actualStatus -eq "match" -and $manifestExpectedStatus -eq "wip") {
    $expectedVerificationStatus = "promotion_ready"
    $expectedPromotionReady = $true
}
elseif ($actualStatus -eq "match") {
    $expectedVerificationStatus = "pass"
}
elseif ($manifestExpectedStatus -eq "wip") {
    $expectedVerificationStatus = "allowed_wip"
}
else {
    $expectedVerificationStatus = "regression"
}
if ($verificationStatus -cne $expectedVerificationStatus -or
    $promotionReady -ne $expectedPromotionReady) {
    throw "Verifier status/promotion fields are inconsistent."
}
$verifierErrorMessage = (Get-CsvField $verifierRow "error_message").Trim()
if ($actualStatus -eq "error" -and
    [string]::IsNullOrWhiteSpace($verifierErrorMessage)) {
    throw "Verifier error row is missing error_message."
}
if ($actualStatus -ne "error" -and
    -not [string]::IsNullOrWhiteSpace($verifierErrorMessage)) {
    throw "Non-error verifier row contains error_message."
}

$expectedMaskBytes = Get-MaskByteCount $manifestMaskForVerifier `
    $functionSize "manifest"
$verifierMaskBytes = Parse-Number (Get-CsvField $verifierRow "mask_bytes") `
    "verifier mask_bytes"
$verifierComparedBytes = Parse-Number (
    Get-CsvField $verifierRow "compared_bytes") "verifier compared_bytes"
if ($actualStatus -ne "error" -and
    ($verifierMaskBytes -ne $expectedMaskBytes -or
        ($verifierMaskBytes + $verifierComparedBytes) -ne $functionSize)) {
    throw "Verifier mask_bytes/compared_bytes are inconsistent with the manifest."
}
if ($actualStatus -ne "error") {
    $verifierSize = Parse-Number (Get-CsvField $verifierRow "size") `
        "verifier size"
    if ($verifierSize -ne $functionSize) {
        throw "Verifier size does not match the manifest."
    }
}

$maskShapeValid = Parse-Boolean (
    Get-CsvField $verifierRow "mask_shape_valid") "verifier mask_shape_valid"
$maskShapeError = (Get-CsvField $verifierRow "masked_operand_shape_error").Trim()
$maskedImportIdentityError = (Get-CsvField $verifierRow `
    "masked_import_identity_error").Trim()
if ($actualStatus -ne "error" -and $maskShapeValid -and
    -not [string]::IsNullOrWhiteSpace($maskShapeError)) {
    throw "Verifier mask-shape state is inconsistent."
}
if ($actualStatus -ne "error" -and -not $maskShapeValid -and
    [string]::IsNullOrWhiteSpace($maskShapeError)) {
    throw "Verifier mask-shape failure is missing its diagnostic."
}
if ($actualStatus -eq "match" -and -not $maskShapeValid) {
    throw "Verifier match row cannot have invalid paired mask shape."
}
if ($actualStatus -ne "error" -and -not $maskShapeValid -and
    ($actualStatus -ne "mismatch" -or $expectedMaskBytes -eq 0)) {
    throw "Verifier invalid paired mask shape is inconsistent with status or mask metadata."
}
if (-not [string]::IsNullOrWhiteSpace($maskedImportIdentityError) -and
    $maskedImportIdentityError -cne $maskShapeError) {
    throw "Verifier masked import and operand-shape diagnostics disagree."
}
$pairedMaskShapeDefect = $actualStatus -eq "mismatch" -and
    -not $maskShapeValid -and
    -not [string]::IsNullOrWhiteSpace($maskShapeError)

$rawFirstDiff = (Get-CsvField $verifierRow "raw_first_diff").Trim()
$firstHardDiff = (Get-CsvField $verifierRow "first_diff").Trim()
if ($actualStatus -eq "mismatch" -and
    ([string]::IsNullOrWhiteSpace($firstHardDiff) -or
        ($rawMatch -and -not $pairedMaskShapeDefect))) {
    throw "Verifier mismatch row has inconsistent difference fields."
}
if ($actualStatus -eq "match" -and
    -not [string]::IsNullOrWhiteSpace($firstHardDiff)) {
    throw "Verifier match row unexpectedly reports a hard difference."
}
if ($actualStatus -ne "error" -and $rawMatch -and
    -not [string]::IsNullOrWhiteSpace($rawFirstDiff)) {
    throw "Verifier raw_match=true row reports a raw difference."
}
if ($actualStatus -ne "error" -and -not $rawMatch -and
    [string]::IsNullOrWhiteSpace($rawFirstDiff)) {
    throw "Verifier raw_match=false row is missing raw_first_diff."
}
foreach ($difference in @(
        [pscustomobject]@{ Name = "raw_first_diff"; Value = $rawFirstDiff },
        [pscustomobject]@{ Name = "first_diff"; Value = $firstHardDiff })) {
    if (-not [string]::IsNullOrWhiteSpace([string]$difference.Value)) {
        $differenceOffset = Parse-Number ([string]$difference.Value) `
            ("verifier " + [string]$difference.Name)
        if ($differenceOffset -ge $functionSize) {
            throw "Verifier $($difference.Name) is outside the function."
        }
    }
}

$functionHashes = @{}
foreach ($fieldName in @(
        "original_raw_sha256", "candidate_raw_sha256",
        "original_sha256", "candidate_sha256")) {
    $value = (Get-CsvField $verifierRow $fieldName).Trim()
    if ($actualStatus -ne "error") {
        $value = Assert-Sha256 $value "verifier $fieldName"
    }
    elseif (-not [string]::IsNullOrWhiteSpace($value)) {
        $value = Assert-Sha256 $value "verifier $fieldName"
    }
    $functionHashes[$fieldName] = $value
}
if ($actualStatus -eq "match" -and
    $functionHashes["original_sha256"] -cne
        $functionHashes["candidate_sha256"]) {
    throw "Verifier match row has different masked function hashes."
}
if ($actualStatus -eq "mismatch" -and
    $functionHashes["original_sha256"] -ceq
        $functionHashes["candidate_sha256"] -and
    -not $pairedMaskShapeDefect) {
    throw "Verifier mismatch row has identical masked function hashes."
}
if ($actualStatus -ne "error" -and $rawMatch -and
    $functionHashes["original_raw_sha256"] -cne
        $functionHashes["candidate_raw_sha256"]) {
    throw "Verifier raw_match=true row has different raw function hashes."
}
if ($actualStatus -ne "error" -and -not $rawMatch -and
    $functionHashes["original_raw_sha256"] -ceq
        $functionHashes["candidate_raw_sha256"]) {
    throw "Verifier raw_match=false row has identical raw function hashes."
}

$originalFileProvenance = Get-VerifierFileProvenance $verifierRow `
    "original_path" "original_file_sha256" "Verifier original file" `
    "verifier-original-file"
$candidateFileProvenance = Get-VerifierFileProvenance $verifierRow `
    "candidate_path" "candidate_file_sha256" "Verifier candidate file" `
    "verifier-candidate-file"
$candidateMapProvenance = Get-VerifierFileProvenance $verifierRow `
    "candidate_map_path" "candidate_map_sha256" "Verifier candidate map" `
    "verifier-candidate-map"
$verifierProvenanceComplete = (
    $null -ne $originalFileProvenance -and
    $null -ne $candidateFileProvenance -and
    $null -ne $candidateMapProvenance)
if (-not $verifierProvenanceComplete) {
    Add-Warning "Verifier file provenance is incomplete; promotion review must remain pending."
}

$metricsSnapshot = $null
$metricsSummary = $null
$functionMetric = $null
$effectiveMaskPath = $MaskAuditResultsPath
$effectiveProductPath = $ExeProductSourceManifestPath
$metricsState = [ordered]@{
    provided = $false
    strict_accepted = $false
    checkpoint_instruction_percent = $null
    function_instruction_count = $null
    function_body_bytes = $null
    function_block = ""
}
if (-not [string]::IsNullOrWhiteSpace($ProgressMetricsSummaryPath)) {
    $metricsSnapshot = Get-TextSnapshot $ProgressMetricsSummaryPath `
        "Progress metrics summary"
    Add-Evidence $metricsSnapshot "progress-metrics-summary"
    $metricsSummary = Convert-JsonSnapshot $metricsSnapshot "progress metrics summary"
    if ([int]$metricsSummary.schema_version -ne 2) {
        throw "Progress metrics summary has unsupported schema_version; expected 2."
    }
    if ([string]$metricsSummary.denominator.body_ownership_sha256 -notmatch
            '^[0-9a-f]{64}$' -or
        [uint64]$metricsSummary.denominator.body_range_count -lt
            [uint64]$metricsSummary.denominator.function_count) {
        throw "Progress metrics summary has invalid body-ownership evidence."
    }
    $summaryManifest = Get-ProvenanceSnapshot $metricsSummary.inputs.manifest `
        "metrics manifest" "metrics-bound-manifest"
    $summaryVerifier = Get-ProvenanceSnapshot $metricsSummary.inputs.verifier_results `
        "metrics verifier results" "metrics-bound-verifier-results"
    if (-not (Test-SamePath $summaryManifest.Path $manifestSnapshot.Path) -or
        $summaryManifest.Sha256 -cne $manifestSnapshot.Sha256) {
        throw "Progress metrics summary references a different manifest."
    }
    if (-not (Test-SamePath $summaryVerifier.Path $verifierSnapshot.Path) -or
        $summaryVerifier.Sha256 -cne $verifierSnapshot.Sha256) {
        throw "Progress metrics summary references different verifier results."
    }

    $summaryMask = Get-ProvenanceSnapshot `
        $metricsSummary.inputs.mask_audit_results "metrics mask audit" `
        "metrics-bound-mask-audit"
    if ([string]::IsNullOrWhiteSpace($effectiveMaskPath)) {
        $effectiveMaskPath = $summaryMask.Path
    }
    elseif (-not (Test-SamePath (Resolve-InputPath $effectiveMaskPath `
                    "Mask audit") $summaryMask.Path)) {
        throw "Explicit mask audit differs from the progress metrics input."
    }

    $summaryProduct = Get-ProvenanceSnapshot `
        $metricsSummary.inputs.exe_product_sources "metrics Product source list" `
        "metrics-bound-product-source-list"
    if ([string]::IsNullOrWhiteSpace($effectiveProductPath)) {
        $effectiveProductPath = $summaryProduct.Path
    }
    elseif (-not (Test-SamePath (Resolve-InputPath $effectiveProductPath `
                    "Product source list") $summaryProduct.Path)) {
        throw "Explicit Product source list differs from the progress metrics input."
    }
    [void](Get-ProvenanceSnapshot $metricsSummary.inputs.metrics_reporter `
        "metrics reporter" "metrics-reporter")

    $metricMatches = @()
    foreach ($record in @($metricsSummary.inputs.function_metrics)) {
        $metricSnapshot = Get-ProvenanceSnapshot $record `
            "Ghidra function metrics" "ghidra-function-metrics"
        $metricRows = @(Convert-CsvSnapshot $metricSnapshot "Ghidra function metrics")
        $metricMatches += @($metricRows | Where-Object {
            (Get-CsvField $_ "program").Equals(
                (Get-CsvField $manifestRow "program"),
                [System.StringComparison]::OrdinalIgnoreCase) -and
            (Parse-Number (Get-CsvField $_ "original_rva") `
                "function metrics original_rva") -eq $originalRva
        })
    }
    if ($metricMatches.Count -ne 1) {
        throw ("Progress metrics inputs contain {0} rows for {1}|{2}; expected one.") -f
            $metricMatches.Count, (Get-CsvField $manifestRow "program"),
            (Format-Hex $originalRva)
    }
    $functionMetric = $metricMatches[0]
    $acceptedIdentity = ("{0}|0x{1:x}" -f
        (Get-CsvField $manifestRow "program").ToLowerInvariant(), $originalRva)
    $accepted = @($metricsSummary.strict.accepted_identities) -contains $acceptedIdentity
    $metricsState = [ordered]@{
        provided = $true
        strict_accepted = [bool]$accepted
        checkpoint_instruction_percent = [double]$metricsSummary.strict.instruction_percent
        function_instruction_count = [long](Parse-Number (
            Get-CsvField $functionMetric "instruction_count") `
            "function metric instruction_count")
        function_body_bytes = [long](Parse-Number (
            Get-CsvField $functionMetric "body_bytes") `
            "function metric body_bytes")
        function_block = (Get-CsvField $functionMetric "block").Trim()
    }
}
else {
    Add-Warning "No progress metrics summary was supplied; checkpoint acceptance and instruction yield are unbound."
}

$manifestMask = (Get-CsvField $manifestRow "mask").Trim()
$maskAuditRows = @()
$maskAuditState = "not-provided"
if (-not [string]::IsNullOrWhiteSpace($effectiveMaskPath)) {
    $maskSnapshot = Get-TextSnapshot $effectiveMaskPath "Mask audit"
    Add-Evidence $maskSnapshot "mask-audit"
    $allMaskRows = @(Convert-CsvSnapshot $maskSnapshot "mask audit")
    $maskAuditRows = @($allMaskRows | Where-Object {
        (Get-CsvField $_ "name").Equals(
            (Get-CsvField $manifestRow "name"),
            [System.StringComparison]::OrdinalIgnoreCase) -and
        (Get-CsvField $_ "program").Equals(
            (Get-CsvField $manifestRow "program"),
            [System.StringComparison]::OrdinalIgnoreCase) -and
        (Parse-Number (Get-CsvField $_ "original_rva") `
            "mask audit original_rva") -eq $originalRva
    })
    if ([string]::IsNullOrWhiteSpace($manifestMask)) {
        if ($maskAuditRows.Count -gt 0) {
            throw "Mask audit contains ranges for a manifest row with no mask."
        }
        $maskAuditState = "not-required-no-mask"
    }
    elseif ($maskAuditRows.Count -eq 0) {
        $maskAuditState = "missing-row"
        Add-Warning "Manifest masks exist, but the supplied mask audit has no rows for this function."
    }
    else {
        $badMaskRows = @($maskAuditRows | Where-Object {
            -not [string]::IsNullOrWhiteSpace((Get-CsvField $_ "issue")) -or
            (Get-CsvField $_ "classification") -cne "full_known_address_operand"
        })
        $maskAuditState = if ($badMaskRows.Count -eq 0) {
            "validated-original-operands"
        }
        else {
            "issues-present"
        }
    }
}
elseif ([string]::IsNullOrWhiteSpace($manifestMask)) {
    $maskAuditState = "not-required-no-mask"
}
else {
    Add-Warning "No original-image mask audit was supplied for a masked function."
}
if (-not [string]::IsNullOrWhiteSpace($manifestMask)) {
    Add-Warning ("Non-import masked target identity remains a separate review item; " +
        "paired operand shape alone is not semantic target proof.")
}

$productSourcesSnapshot = $null
$productSourceSet = @{}
if (-not [string]::IsNullOrWhiteSpace($effectiveProductPath)) {
    $productSourcesSnapshot = Get-TextSnapshot $effectiveProductPath `
        "Product source list"
    Add-Evidence $productSourcesSnapshot "product-source-list"
    foreach ($line in ($productSourcesSnapshot.Text -split "`r?`n")) {
        $clean = ($line -split '#', 2)[0].Trim()
        if (-not [string]::IsNullOrWhiteSpace($clean)) {
            $productSourceSet[(Normalize-SourcePath $clean)] = $true
        }
    }
}
else {
    Add-Warning "No Product source list was supplied; source reachability cannot be established."
}

$tuMetadataSnapshot = $null
$tuMetadataRows = @()
$tuPathColumn = ""
$tuFlagsColumn = ""
if (-not [string]::IsNullOrWhiteSpace($TuMetadataPath)) {
    $tuMetadataSnapshot = Get-TextSnapshot $TuMetadataPath "TU metadata"
    Add-Evidence $tuMetadataSnapshot "vc4-tu-metadata"
    $tuMetadataRows = @(Convert-CsvSnapshot $tuMetadataSnapshot "TU metadata")
    if ($tuMetadataRows.Count -eq 0) {
        throw "TU metadata contains no rows."
    }
    foreach ($candidate in @("source_path", "source", "path")) {
        if ($null -ne $tuMetadataRows[0].PSObject.Properties[$candidate]) {
            $tuPathColumn = $candidate
            break
        }
    }
    foreach ($candidate in @(
            "extra_compile_flags", "compile_flags", "flags")) {
        if ($null -ne $tuMetadataRows[0].PSObject.Properties[$candidate]) {
            $tuFlagsColumn = $candidate
            break
        }
    }
    if ([string]::IsNullOrWhiteSpace($tuPathColumn) -or
        [string]::IsNullOrWhiteSpace($tuFlagsColumn)) {
        throw ("TU metadata must provide a source path column and a compile " +
            "flags column.")
    }
}
else {
    Add-Warning "No centralized TU metadata was supplied; effective VC4 flags require manual confirmation."
}

$candidateSources = @()
$resolvedSourceRoot = Resolve-OptionalDirectory $SourceRoot
if ([string]::IsNullOrWhiteSpace($resolvedSourceRoot)) {
    Add-Warning "Source root is unavailable; no candidate TU could be located."
}
else {
    $candidateSymbol = (Get-CsvField $manifestRow "candidate_symbol").Trim()
    $candidateObject = (Get-CsvField $manifestRow "candidate_object").Trim()
    foreach ($file in @(Get-ChildItem -LiteralPath $resolvedSourceRoot `
            -Filter *.cpp -File -Recurse | Sort-Object FullName)) {
        if ($file.Name -like '*_notes.cpp') {
            continue
        }
        $objectName = Get-ObjectNameForSource $file.FullName
        $reasons = New-Object System.Collections.ArrayList
        if (-not [string]::IsNullOrWhiteSpace($candidateObject) -and
            $objectName.Equals(
                $candidateObject, [System.StringComparison]::OrdinalIgnoreCase)) {
            [void]$reasons.Add("candidate_object")
        }
        $sourceSnapshot = $null
        if ($reasons.Count -eq 0 -or
            -not [string]::IsNullOrWhiteSpace($candidateSymbol)) {
            $sourceSnapshot = Get-TextSnapshot $file.FullName "Candidate source discovery"
            if (-not [string]::IsNullOrWhiteSpace($candidateSymbol) -and
                $sourceSnapshot.Text.IndexOf(
                    $candidateSymbol,
                    [System.StringComparison]::Ordinal) -ge 0) {
                [void]$reasons.Add("candidate_symbol")
            }
            if ($sourceSnapshot.Text.IndexOf(
                    (Get-CsvField $manifestRow "name"),
                    [System.StringComparison]::Ordinal) -ge 0) {
                [void]$reasons.Add("manifest_name")
            }
        }
        if ($reasons.Count -eq 0) {
            continue
        }
        if ($null -eq $sourceSnapshot) {
            $sourceSnapshot = Get-TextSnapshot $file.FullName "Candidate source"
        }
        Add-Evidence $sourceSnapshot "candidate-source"
        $relativeSource = Normalize-SourcePath $sourceSnapshot.DisplayPath
        $tuMatches = @()
        if ($tuMetadataRows.Count -gt 0) {
            $tuMatches = @($tuMetadataRows | Where-Object {
                (Normalize-SourcePath (Get-CsvField $_ $tuPathColumn)) -ceq
                    $relativeSource
            })
            if ($tuMatches.Count -gt 1) {
                throw "TU metadata is ambiguous for '$($sourceSnapshot.DisplayPath)'."
            }
        }
        $candidateSources += [pscustomobject][ordered]@{
            path = $sourceSnapshot.DisplayPath
            sha256 = $sourceSnapshot.Sha256
            object_name = $objectName
            match_reasons = @($reasons | Sort-Object -Unique)
            product_reachable = if ($null -ne $productSourcesSnapshot) {
                [bool]$productSourceSet.ContainsKey($relativeSource)
            }
            else {
                $null
            }
            extra_compile_flags = if ($tuMatches.Count -eq 1) {
                (Get-CsvField $tuMatches[0] $tuFlagsColumn).Trim()
            }
            else {
                ""
            }
            tu_metadata_found = [bool]($tuMatches.Count -eq 1)
        }
    }
}
if ($candidateSources.Count -eq 0) {
    Add-Warning "No candidate source TU was found by candidate object, symbol, or manifest name."
}
elseif ($candidateSources.Count -gt 1) {
    Add-Warning "Multiple candidate source TUs were found; ownership requires review."
}
if ($null -ne $tuMetadataSnapshot -and
    @($candidateSources | Where-Object { $_.tu_metadata_found }).Count -eq 0) {
    Add-Warning "TU metadata was supplied but has no row for the located candidate source."
}

$ghidraSymbol = ("FUN_{0:X8}" -f $originalVa)
$ghidraAnchors = @()
$directCallNames = @{}
$resolvedGhidraDirectory = Resolve-OptionalDirectory $GhidraOutputDirectory
if ([string]::IsNullOrWhiteSpace($resolvedGhidraDirectory)) {
    Add-Warning "Ghidra output directory is unavailable; decompile anchor is missing."
}
else {
    $targetPattern = '(?i)\b' + [regex]::Escape($ghidraSymbol) + '\b'
    foreach ($file in @(Get-ChildItem -LiteralPath $resolvedGhidraDirectory `
            -Filter *.c -File -Recurse | Sort-Object FullName)) {
        $snapshot = Get-TextSnapshot $file.FullName "Ghidra decompile discovery"
        if ($snapshot.Text -notmatch $targetPattern) {
            continue
        }
        $lines = @($snapshot.Text -split "`r?`n")
        $entryIndex = -1
        for ($lineIndex = 0; $lineIndex -lt $lines.Count; $lineIndex++) {
            if ($lines[$lineIndex] -match $targetPattern) {
                $entryIndex = $lineIndex
                if ($lines[$lineIndex] -match '(?i)//\s*Function:') {
                    break
                }
            }
        }
        if ($entryIndex -lt 0) {
            continue
        }
        $blockStart = $entryIndex
        for ($lineIndex = $entryIndex; $lineIndex -ge 0; $lineIndex--) {
            if ($lines[$lineIndex] -match '(?i)^\s*//\s*Function:') {
                $blockStart = $lineIndex
                break
            }
        }
        $blockEnd = $lines.Count
        for ($lineIndex = $blockStart + 1; $lineIndex -lt $lines.Count; $lineIndex++) {
            if ($lines[$lineIndex] -match '(?i)^\s*//\s*Function:') {
                $blockEnd = $lineIndex
                break
            }
        }
        $block = ($lines[$blockStart..($blockEnd - 1)] -join "`n")
        $callMatches = [regex]::Matches(
            $block, '\b([A-Za-z_][A-Za-z0-9_@$?]*)\s*\(')
        $ignoredCalls = @{
            "do" = $true; "for" = $true; "if" = $true; "return" = $true
            "sizeof" = $true; "switch" = $true; "while" = $true
        }
        foreach ($match in $callMatches) {
            $callee = $match.Groups[1].Value
            if (-not $callee.Equals(
                    $ghidraSymbol, [System.StringComparison]::OrdinalIgnoreCase) -and
                -not $ignoredCalls.ContainsKey($callee.ToLowerInvariant())) {
                $directCallNames[$callee] = $true
            }
        }
        Add-Evidence $snapshot "ghidra-decompile-anchor"
        $ghidraAnchors += [pscustomobject][ordered]@{
            path = $snapshot.DisplayPath
            sha256 = $snapshot.Sha256
            entry_line = $entryIndex + 1
            block_start_line = $blockStart + 1
            entry_symbol = $ghidraSymbol
        }
    }
}
$ghidraAnchors = @($ghidraAnchors | Sort-Object path, entry_line)
if ($ghidraAnchors.Count -eq 0) {
    Add-Warning "No Ghidra decompile anchor was found for $ghidraSymbol."
}
elseif ($ghidraAnchors.Count -gt 1) {
    Add-Warning "Multiple Ghidra decompile anchors were found; the first path is only a deterministic primary."
}

$imageBase = $originalVa - $originalRva
$directCalls = @()
foreach ($callee in @($directCallNames.Keys | Sort-Object)) {
    $calleeVa = $null
    $calleeRva = $null
    $manifestDependency = $null
    if ($callee -match '^FUN_([0-9A-Fa-f]{8})$') {
        $calleeVa = [uint64]::Parse(
            $Matches[1],
            [System.Globalization.NumberStyles]::HexNumber,
            [System.Globalization.CultureInfo]::InvariantCulture)
        if ($calleeVa -ge $imageBase) {
            $calleeRva = $calleeVa - $imageBase
            $dependencyRows = @($manifestRows | Where-Object {
                (Get-CsvField $_ "program").Equals(
                    (Get-CsvField $manifestRow "program"),
                    [System.StringComparison]::OrdinalIgnoreCase) -and
                (Parse-Number (Get-CsvField $_ "original_rva") `
                    "manifest dependency original_rva") -eq $calleeRva
            })
            if ($dependencyRows.Count -eq 1) {
                $manifestDependency = $dependencyRows[0]
            }
        }
    }
    $directCalls += [pscustomobject][ordered]@{
        symbol = $callee
        original_va = if ($null -ne $calleeVa) {
            Format-Hex $calleeVa
        }
        else { "" }
        original_rva = if ($null -ne $calleeRva) {
            Format-Hex $calleeRva
        }
        else { "" }
        manifest_name = if ($null -ne $manifestDependency) {
            Get-CsvField $manifestDependency "name"
        }
        else { "" }
        manifest_expected_status = if ($null -ne $manifestDependency) {
            Get-CsvField $manifestDependency "expected_status"
        }
        else { "" }
    }
}

$priorNotes = @()
$noteTerms = @(
    (Get-CsvField $manifestRow "name"),
    (Get-CsvField $manifestRow "candidate_symbol"),
    $ghidraSymbol,
    (Format-Hex $originalRva),
    (Format-Hex $originalVa)
) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique
$noteFiles = @{}
foreach ($root in @($RecoveryNotesRoot)) {
    $resolvedRoot = Resolve-OptionalDirectory $root
    if ([string]::IsNullOrWhiteSpace($resolvedRoot)) {
        continue
    }
    foreach ($file in @(Get-ChildItem -LiteralPath $resolvedRoot -Filter *.md `
            -File -Recurse | Sort-Object FullName)) {
        $noteFiles[$file.FullName.ToLowerInvariant()] = $file.FullName
    }
}
if (-not [string]::IsNullOrWhiteSpace($resolvedSourceRoot)) {
    foreach ($file in @(Get-ChildItem -LiteralPath $resolvedSourceRoot `
            -Filter *_notes.cpp -File -Recurse | Sort-Object FullName)) {
        $noteFiles[$file.FullName.ToLowerInvariant()] = $file.FullName
    }
}
foreach ($notePath in @($noteFiles.Values | Sort-Object)) {
    $snapshot = Get-TextSnapshot $notePath "Prior recovery note discovery"
    $matchedTerms = @($noteTerms | Where-Object {
        $snapshot.Text.IndexOf(
            $_, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
    })
    if ($matchedTerms.Count -eq 0) {
        continue
    }
    Add-Evidence $snapshot "prior-recovery-note"
    $priorNotes += [pscustomobject][ordered]@{
        path = $snapshot.DisplayPath
        sha256 = $snapshot.Sha256
        matched_on = @($matchedTerms | Sort-Object -Unique)
    }
}
if ($priorNotes.Count -eq 0) {
    Add-Warning "No prior recovery note was found for this identity."
}

$frozenState = $null
if (-not [string]::IsNullOrWhiteSpace($FrozenWipPath)) {
    $frozenSnapshot = Get-TextSnapshot $FrozenWipPath "Frozen-WIP ledger"
    Add-Evidence $frozenSnapshot "frozen-wip-ledger"
    $frozenRows = @(Convert-CsvSnapshot $frozenSnapshot "Frozen-WIP ledger")
    $frozenRow = Resolve-RowByIdentity $frozenRows "Frozen-WIP ledger" `
        (Get-CsvField $manifestRow "name") (Get-CsvField $manifestRow "program") `
        $originalRva -Optional
    if ($null -eq $frozenRow) {
        $frozenState = [ordered]@{ listed = $false }
    }
    else {
        $frozenEvidence = Validate-LinkedEvidence $frozenRow "evidence_path" `
            "evidence_sha256" "Frozen-WIP evidence" "frozen-wip-evidence"
        $frozenSource = Validate-LinkedEvidence $frozenRow "source_path" `
            "source_sha256" "Frozen-WIP best source" "frozen-wip-source"
        $frozenState = [ordered]@{
            listed = $true
            frozen = Parse-Boolean (Get-CsvField $frozenRow "frozen") `
                "Frozen-WIP frozen"
            freeze_date = (Get-CsvField $frozenRow "freeze_date").Trim()
            meaningful_variant_count = (Get-CsvField $frozenRow `
                "meaningful_variant_count").Trim()
            residual_kind = (Get-CsvField $frozenRow "residual_kind").Trim()
            hard_diff_count = (Get-CsvField $frozenRow "hard_diff_count").Trim()
            compared_bytes = (Get-CsvField $frozenRow "compared_bytes").Trim()
            evidence_path = $frozenEvidence.DisplayPath
            evidence_sha256 = $frozenEvidence.Sha256
            source_path = $frozenSource.DisplayPath
            source_sha256 = $frozenSource.Sha256
            baseline_candidate_object = (Get-CsvField $frozenRow `
                "baseline_candidate_object").Trim()
            baseline_candidate_object_sha256 = (Get-CsvField $frozenRow `
                "baseline_candidate_object_sha256").Trim().ToLowerInvariant()
            baseline_candidate_function_sha256 = (Get-CsvField $frozenRow `
                "baseline_candidate_function_sha256").Trim().ToLowerInvariant()
            reason = (Get-CsvField $frozenRow "reason").Trim()
            revisit_condition = (Get-CsvField $frozenRow `
                "revisit_condition").Trim()
        }
    }
}
else {
    Add-Warning "No durable frozen-WIP ledger was supplied."
}

$sessionRecord = Get-OptionalLedgerRow $SessionLaneLedgerPath `
    "Session lane ledger" "session-lane-ledger" `
    (Get-CsvField $manifestRow "name") (Get-CsvField $manifestRow "program") `
    $originalRva $manifestSnapshot $verifierSnapshot $metricsSnapshot
$sessionState = $null
if ($null -ne $sessionRecord -and $null -ne $sessionRecord.Row) {
    $sessionEvidence = Validate-LinkedEvidence $sessionRecord.Row `
        "evidence_path" "evidence_sha256" "Session lane evidence" `
        "session-lane-evidence"
    $sessionSource = Validate-LinkedEvidence $sessionRecord.Row `
        "source_path" "source_sha256" "Session lane source" `
        "session-lane-source" -Optional
    $sessionState = [ordered]@{
        session_id = [string]$sessionRecord.Ledger.session_id
        state = (Get-CsvField $sessionRecord.Row "state").Trim()
        hypothesis = (Get-CsvField $sessionRecord.Row "hypothesis").Trim()
        meaningful_variant_count = (Get-CsvField $sessionRecord.Row `
            "meaningful_variant_count").Trim()
        active_recovery_minutes = (Get-CsvField $sessionRecord.Row `
            "active_recovery_minutes").Trim()
        evidence_path = $sessionEvidence.DisplayPath
        evidence_sha256 = $sessionEvidence.Sha256
        source_path = if ($null -ne $sessionSource) {
            $sessionSource.DisplayPath
        }
        else { "" }
        source_sha256 = if ($null -ne $sessionSource) {
            $sessionSource.Sha256
        }
        else { "" }
    }
}
elseif ([string]::IsNullOrWhiteSpace($SessionLaneLedgerPath)) {
    Add-Warning "No session-local lane ledger was supplied."
}

$readinessRecord = Get-OptionalLedgerRow $ReadinessLedgerPath `
    "Readiness ledger" "readiness-ledger" `
    (Get-CsvField $manifestRow "name") (Get-CsvField $manifestRow "program") `
    $originalRva $manifestSnapshot $verifierSnapshot $metricsSnapshot
$readinessState = $null
if ($null -ne $readinessRecord -and $null -ne $readinessRecord.Row) {
    $readinessEvidence = Validate-LinkedEvidence $readinessRecord.Row `
        "evidence_path" "evidence_sha256" "Readiness evidence" `
        "readiness-evidence"
    $readinessState = [ordered]@{
        session_id = [string]$readinessRecord.Ledger.session_id
        readiness = (Get-CsvField $readinessRecord.Row "readiness").Trim()
        dependency_state = (Get-CsvField $readinessRecord.Row `
            "dependency_state").Trim()
        confidence = (Get-CsvField $readinessRecord.Row "confidence").Trim()
        effort = (Get-CsvField $readinessRecord.Row "effort").Trim()
        candidate_body_bytes = (Get-CsvField $readinessRecord.Row `
            "candidate_body_bytes").Trim()
        candidate_instruction_count = (Get-CsvField $readinessRecord.Row `
            "candidate_instruction_count").Trim()
        reason = (Get-CsvField $readinessRecord.Row "reason").Trim()
        evidence_path = $readinessEvidence.DisplayPath
        evidence_sha256 = $readinessEvidence.Sha256
    }
}
elseif ([string]::IsNullOrWhiteSpace($ReadinessLedgerPath)) {
    Add-Warning "No checkpoint-bound readiness ledger was supplied."
}

$maskAuditSummaryRows = @($maskAuditRows | Sort-Object {
    Parse-Number (Get-CsvField $_ "range_start") "mask audit range_start"
} | ForEach-Object {
    [pscustomobject][ordered]@{
        range = ("{0}-{1}" -f (Get-CsvField $_ "range_start"),
            (Get-CsvField $_ "range_end"))
        classification = (Get-CsvField $_ "classification").Trim()
        issue = (Get-CsvField $_ "issue").Trim()
        operand_kinds = (Get-CsvField $_ "operand_kinds").Trim()
        operand_ranges = (Get-CsvField $_ "operand_ranges").Trim()
    }
})

$sourceReachableCount = @($candidateSources | Where-Object {
    $_.product_reachable -eq $true
}).Count
$tuMetadataCount = @($candidateSources | Where-Object {
    $_.tu_metadata_found
}).Count
$checklist = @(
    [pscustomobject][ordered]@{
        id = "semantic.behavior"; category = "semantic"; state = "pending"
        prompt = "Explain the function's game behavior and side effects in subsystem terms."
    },
    [pscustomobject][ordered]@{
        id = "semantic.readable_cpp"; category = "semantic"; state = "pending"
        prompt = "Confirm the candidate is readable VC4-compatible C++ with no ASM, _emit, volatile shaping, fake dependencies, or embedded instruction bytes."
    },
    [pscustomobject][ordered]@{
        id = "type.calling_convention"; category = "type"; state = "pending"
        prompt = "Confirm calling convention, return type, parameter widths, signedness, and pointer/reference types."
    },
    [pscustomobject][ordered]@{
        id = "type.layout"; category = "type"; state = "pending"
        prompt = "Confirm class/aggregate layout, member offsets, ownership, construction order, and integer widths."
    },
    [pscustomobject][ordered]@{
        id = "abi.vc4_flags"; category = "ABI"
        state = if ($tuMetadataCount -gt 0) { "complete" } else { "pending" }
        prompt = "Confirm the exact VC4 optimization, exception, frame-pointer, and per-TU flags."
    },
    [pscustomobject][ordered]@{
        id = "abi.exception_model"; category = "ABI"; state = "pending"
        prompt = "Review constructors, destructors, EH cleanup, hidden parameters, and member-call lowering."
    },
    [pscustomobject][ordered]@{
        id = "mask.paired_shape"; category = "mask"
        state = if ($maskShapeValid) { "pass" } else { "fail" }
        prompt = "Require same-offset, same-kind paired address-operand shape and import identity where applicable."
    },
    [pscustomobject][ordered]@{
        id = "mask.original_audit"; category = "mask"
        state = if ($maskAuditState -in @(
                "validated-original-operands", "not-required-no-mask")) {
            "pass"
        }
        elseif ($maskAuditState -eq "issues-present") { "fail" }
        else { "pending" }
        prompt = "Confirm every manifest mask range is a complete validated address operand."
    },
    [pscustomobject][ordered]@{
        id = "mask.target_identity"; category = "mask"
        state = if ([string]::IsNullOrWhiteSpace($manifestMask)) {
            "not-applicable"
        }
        else { "pending" }
        prompt = "Review semantic target identity for non-import data and direct-call operands; paired shape is not target proof."
    },
    [pscustomobject][ordered]@{
        id = "evidence.ghidra_anchor"; category = "evidence"
        state = if ($ghidraAnchors.Count -gt 0) { "complete" } else { "pending" }
        prompt = "Open the bound decompile anchor and reconcile direct dependencies."
    },
    [pscustomobject][ordered]@{
        id = "evidence.product_reachability"; category = "evidence"
        state = if ($sourceReachableCount -gt 0) { "complete" } else { "pending" }
        prompt = "Confirm the recovered TU is in the canonical Product graph before promotion."
    },
    [pscustomobject][ordered]@{
        id = "evidence.focused_diff"; category = "evidence"; state = "pending"
        prompt = "Record a focused raw and hard residual with source hash, hypothesis, timings, and stop-loss state."
    }
)

$evidence = @($evidenceMap.Values | ForEach-Object {
    [pscustomobject][ordered]@{
        roles = @($_.Roles | Sort-Object)
        path = $_.Snapshot.DisplayPath
        sha256 = $_.Snapshot.Sha256
        length = [long]$_.Snapshot.Length
    }
} | Sort-Object path)

foreach ($entry in $evidenceMap.Values) {
    $snapshot = $entry.Snapshot
    if (-not (Test-Path -LiteralPath $snapshot.Path -PathType Leaf)) {
        throw "Evidence disappeared while the dossier was being prepared: '$($snapshot.Path)'."
    }
    $item = Get-Item -LiteralPath $snapshot.Path
    if ([long]$item.Length -ne [long]$snapshot.Length -or
        (Get-FileSha256Hex $snapshot.Path) -cne $snapshot.Sha256) {
        throw "Evidence changed while the dossier was being prepared: '$($snapshot.Path)'."
    }
    if ((Test-SamePath $snapshot.Path $jsonOutputPath) -or
        (Test-SamePath $snapshot.Path $markdownOutputPath)) {
        throw "Dossier output aliases an evidence input."
    }
}

# Only after every direct, transitive, discovered, and binary-provenance input
# has been resolved and checked for aliases may old planned outputs be removed.
# This prevents a caller from turning a required evidence file into a deletion
# target through OutputDirectory/OutputBaseName.
foreach ($oldOutput in @($jsonOutputPath, $markdownOutputPath)) {
    if (Test-Path -LiteralPath $oldOutput -PathType Leaf) {
        Remove-Item -LiteralPath $oldOutput -Force
    }
}

$warningList = @($warnings | Sort-Object -Unique)
$identityKey = ("{0}|0x{1:x}" -f
    (Get-CsvField $manifestRow "program").ToLowerInvariant(), $originalRva)
$dossier = [pscustomobject][ordered]@{
    schema_version = 1
    generator = [pscustomobject][ordered]@{
        name = "otmatch-function-dossier"
        schema_version = 1
        script_path = $generatorSnapshot.DisplayPath
        script_sha256 = $generatorSnapshot.Sha256
    }
    identity = [pscustomobject][ordered]@{
        name = Get-CsvField $manifestRow "name"
        program = Get-CsvField $manifestRow "program"
        original_va = Format-Hex $originalVa
        original_rva = Format-Hex $originalRva
        size = [long]$functionSize
        key = $identityKey
    }
    manifest = [pscustomobject][ordered]@{
        row_index = $manifestRowIndex
        expected_status = (Get-CsvField $manifestRow "expected_status").Trim()
        implementation_kind = (Get-CsvField $manifestRow `
            "implementation_kind").Trim()
        candidate_symbol = (Get-CsvField $manifestRow "candidate_symbol").Trim()
        candidate_dll = (Get-CsvField $manifestRow "candidate_dll").Trim()
        candidate_object = (Get-CsvField $manifestRow "candidate_object").Trim()
        mask = $manifestMask
        notes = (Get-CsvField $manifestRow "notes").Trim()
    }
    verifier = [pscustomobject][ordered]@{
        result_schema_version = 4
        verification_status = $verificationStatus
        actual_status = $actualStatus
        promotion_ready = $promotionReady
        raw_match = $rawMatch
        mask_bytes = [long]$verifierMaskBytes
        compared_bytes = [long]$verifierComparedBytes
        first_hard_diff = $firstHardDiff
        original_function_sha256 = $functionHashes["original_sha256"]
        candidate_function_sha256 = $functionHashes["candidate_sha256"]
        mask_shape_valid = $maskShapeValid
        mask_shape_evaluated = [bool]($actualStatus -ne "error")
        masked_operand_shape_error = $maskShapeError
        masked_import_identity_error = $maskedImportIdentityError
        has_verifier_error = [bool]($actualStatus -eq "error")
        provenance_complete = $verifierProvenanceComplete
        original_file = $originalFileProvenance
        candidate_file = $candidateFileProvenance
        candidate_map = $candidateMapProvenance
    }
    metrics = [pscustomobject]$metricsState
    mask_review = [pscustomobject][ordered]@{
        manifest_mask = $manifestMask
        original_audit_state = $maskAuditState
        paired_candidate_shape_valid = $maskShapeValid
        paired_candidate_shape_error = $maskShapeError
        audit_rows = $maskAuditSummaryRows
        non_import_target_identity_proven = $false
    }
    recovery_state = [pscustomobject][ordered]@{
        frozen_wip = $frozenState
        session_lane = $sessionState
        readiness = $readinessState
    }
    sources = @($candidateSources | Sort-Object path)
    decompilation = [pscustomobject][ordered]@{
        expected_entry_symbol = $ghidraSymbol
        primary_anchor = if ($ghidraAnchors.Count -gt 0) {
            $ghidraAnchors[0].path
        }
        else { "" }
        anchors = $ghidraAnchors
        direct_call_hints = $directCalls
    }
    prior_recovery_notes = @($priorNotes | Sort-Object path)
    checklist = $checklist
    promotion_review = [pscustomobject][ordered]@{
        identity_key = $identityKey
        status = "pending"
        reviewed_source_path = ""
        reviewed_source_sha256 = ""
        reviewer = ""
        reviewed_utc = ""
        semantic = [pscustomobject][ordered]@{
            passed = $false
            note = ""
        }
        type_layout = [pscustomobject][ordered]@{
            passed = $false
            note = ""
        }
        abi = [pscustomobject][ordered]@{
            passed = $false
            note = ""
        }
        mask = [pscustomobject][ordered]@{
            passed = $false
            note = ""
        }
        warnings_disposition = [pscustomobject][ordered]@{
            status = "pending"
            note = ""
            resolved_warnings = @()
        }
    }
    warnings = $warningList
    evidence = $evidence
}

$jsonText = ($dossier | ConvertTo-Json -Depth 20) + "`n"
$markdown = New-Object System.Text.StringBuilder
[void]$markdown.AppendLine("# Function dossier: $($dossier.identity.name)")
[void]$markdown.AppendLine()
[void]$markdown.AppendLine("This is an asset-free, hash-bound planning dossier. It contains no original PE/resource bytes and does not replace focused compilation or matching.")
[void]$markdown.AppendLine()
[void]$markdown.AppendLine("## Identity")
[void]$markdown.AppendLine()
[void]$markdown.AppendLine("| Field | Value |")
[void]$markdown.AppendLine("| --- | --- |")
[void]$markdown.AppendLine("| Program | $(Escape-Markdown $dossier.identity.program) |")
[void]$markdown.AppendLine("| RVA | $($dossier.identity.original_rva) |")
[void]$markdown.AppendLine("| VA / Ghidra entry | $($dossier.identity.original_va) / $ghidraSymbol |")
[void]$markdown.AppendLine("| Size | $($dossier.identity.size) bytes |")
[void]$markdown.AppendLine("| Candidate symbol | $(Escape-Markdown $dossier.manifest.candidate_symbol) |")
[void]$markdown.AppendLine("| Candidate object | $(Escape-Markdown $dossier.manifest.candidate_object) |")
[void]$markdown.AppendLine("| Expected / actual | $(Escape-Markdown $dossier.manifest.expected_status) / $(Escape-Markdown $dossier.verifier.actual_status) |")
[void]$markdown.AppendLine()
[void]$markdown.AppendLine("## Verification and mask state")
[void]$markdown.AppendLine()
[void]$markdown.AppendLine("| Check | State |")
[void]$markdown.AppendLine("| --- | --- |")
[void]$markdown.AppendLine("| Verification | $(Escape-Markdown $dossier.verifier.verification_status) |")
[void]$markdown.AppendLine("| Strict checkpoint accepted | $($dossier.metrics.strict_accepted) |")
[void]$markdown.AppendLine("| Manifest mask | $(Escape-Markdown $manifestMask) |")
[void]$markdown.AppendLine("| Original operand audit | $maskAuditState |")
[void]$markdown.AppendLine("| Paired operand shape | $maskShapeValid |")
[void]$markdown.AppendLine("| Paired-shape diagnostic | $(Escape-Markdown $maskShapeError) |")
[void]$markdown.AppendLine()
[void]$markdown.AppendLine("## Candidate sources")
[void]$markdown.AppendLine()
if ($candidateSources.Count -eq 0) {
    [void]$markdown.AppendLine("No candidate source was located.")
}
else {
    [void]$markdown.AppendLine("| Path | Product | VC4 extra flags | SHA-256 |")
    [void]$markdown.AppendLine("| --- | --- | --- | --- |")
    foreach ($source in @($candidateSources | Sort-Object path)) {
        [void]$markdown.AppendLine(("| {0} | {1} | {2} | `{3}` |" -f
            (Escape-Markdown $source.path), $source.product_reachable,
            (Escape-Markdown $source.extra_compile_flags), $source.sha256))
    }
}
[void]$markdown.AppendLine()
[void]$markdown.AppendLine("## Decompile anchors and dependencies")
[void]$markdown.AppendLine()
if ($ghidraAnchors.Count -eq 0) {
    [void]$markdown.AppendLine("No Ghidra anchor was located.")
}
else {
    foreach ($anchor in $ghidraAnchors) {
        [void]$markdown.AppendLine(("- {0}:{1} (`{2}`)" -f
            $anchor.path, $anchor.entry_line, $anchor.sha256))
    }
}
if ($directCalls.Count -gt 0) {
    [void]$markdown.AppendLine()
    [void]$markdown.AppendLine("Direct-call hints:")
    [void]$markdown.AppendLine()
    foreach ($call in $directCalls) {
        $resolvedName = if ([string]::IsNullOrWhiteSpace($call.manifest_name)) {
            "unresolved"
        }
        else { $call.manifest_name }
        [void]$markdown.AppendLine(("- `{0}` -> {1} {2}" -f
            $call.symbol, $resolvedName, $call.original_rva))
    }
}
[void]$markdown.AppendLine()
[void]$markdown.AppendLine("## Prior recovery notes")
[void]$markdown.AppendLine()
if ($priorNotes.Count -eq 0) {
    [void]$markdown.AppendLine("No prior note was located.")
}
else {
    foreach ($note in @($priorNotes | Sort-Object path)) {
        [void]$markdown.AppendLine(("- {0} (`{1}`)" -f $note.path, $note.sha256))
    }
}
[void]$markdown.AppendLine()
[void]$markdown.AppendLine("## Review checklist")
[void]$markdown.AppendLine()
[void]$markdown.AppendLine("| State | Category | Review |")
[void]$markdown.AppendLine("| --- | --- | --- |")
foreach ($item in $checklist) {
    [void]$markdown.AppendLine(("| {0} | {1} | {2} |" -f
        $item.state, $item.category, (Escape-Markdown $item.prompt)))
}
[void]$markdown.AppendLine()
[void]$markdown.AppendLine("## Promotion review")
[void]$markdown.AppendLine()
[void]$markdown.AppendLine("Status: **pending**. Fill the structured `promotion_review` object in a reviewed copy of the JSON dossier; the generated template deliberately fails closed.")
[void]$markdown.AppendLine()
[void]$markdown.AppendLine("## Missing evidence / warnings")
[void]$markdown.AppendLine()
if ($warningList.Count -eq 0) {
    [void]$markdown.AppendLine("None.")
}
else {
    foreach ($warning in $warningList) {
        [void]$markdown.AppendLine("- $warning")
    }
}
[void]$markdown.AppendLine()
[void]$markdown.AppendLine("## Evidence hashes")
[void]$markdown.AppendLine()
[void]$markdown.AppendLine("| Roles | Path | SHA-256 | Bytes |")
[void]$markdown.AppendLine("| --- | --- | --- | ---: |")
foreach ($item in $evidence) {
    [void]$markdown.AppendLine(("| {0} | {1} | `{2}` | {3} |" -f
        (Escape-Markdown ($item.roles -join ", ")),
        (Escape-Markdown $item.path), $item.sha256, $item.length))
}

[void][System.IO.Directory]::CreateDirectory($outputDirectoryFullPath)
try {
    Write-TextAtomically $jsonOutputPath $jsonText
    Write-TextAtomically $markdownOutputPath $markdown.ToString()
}
catch {
    foreach ($failedOutput in @($jsonOutputPath, $markdownOutputPath)) {
        if (Test-Path -LiteralPath $failedOutput -PathType Leaf) {
            Remove-Item -LiteralPath $failedOutput -Force
        }
    }
    throw
}

Write-Host "Function dossier generated:"
Write-Host "  JSON:     $jsonOutputPath"
Write-Host "  Markdown: $markdownOutputPath"
Write-Host "  Evidence: $($evidence.Count) hash-bound text artifact(s)"
Write-Host "  Warnings: $($warningList.Count)"
