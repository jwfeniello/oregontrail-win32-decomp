[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$FunctionName,
    [Parameter(Mandatory = $true)]
    [string]$Program,
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,
    [Parameter(Mandatory = $true)]
    [string]$CheckpointId,
    [Parameter(Mandatory = $true)]
    [string]$PriorBoundaryRunId,
    [Parameter(Mandatory = $true)]
    [string]$SessionLedgerPath,
    [Parameter(Mandatory = $true)]
    [string]$BuildOutputDirectory,
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    [string]$ManifestPath = "tools\otmatch\functions.vc40-real-cpp.csv",
    [string]$ProductSourceManifestPath =
        "tools\otmatch\vc4-exe-product-sources.txt",
    [string]$TuMetadataPath = "tools\otmatch\vc4-tu-metadata.csv",
    [string]$OriginalExePath =
        "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe",
    [string]$OriginalDllPath =
        "Sample\Oregon Trail CD\OTWIN32\OREGON32.DLL",
    [ValidateSet("ModernVs", "LegacyMsvc")]
    [string]$Toolchain = "LegacyMsvc",
    [string]$VcToolsRoot = "C:\MSDEV",
    [string]$DefaultOptimization = "/Od",
    [string]$SemanticOptimization = "/O1",
    [string]$PowerShellExecutable = "powershell.exe"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$generatorRelativePath =
    "tools/otmatch/invoke-product-reanchor-evidence.ps1"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$manifestFields = @(
    "name", "program", "original_va", "original_rva", "size",
    "candidate_va", "candidate_rva", "candidate_symbol", "candidate_dll",
    "candidate_object", "expected_status", "implementation_kind",
    "mask", "notes")
$allowedChangedFields = @(
    "candidate_rva", "candidate_symbol", "candidate_object",
    "expected_status", "notes")
$requiredChangedFields = @(
    "candidate_object", "expected_status", "notes")

function Test-PathInsideRoot {
    param([string]$Path, [string]$Root)
    $prefix = $Root.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    return $Path.StartsWith(
        $prefix,
        [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-ConfiguredFullPath {
    param([string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
}

function Get-RepoRelativePath {
    param([string]$Path)
    $full = [System.IO.Path]::GetFullPath($Path)
    if (-not (Test-PathInsideRoot $full $repoRoot)) {
        throw "Path is outside the repository: '$full'."
    }
    return $full.Substring($repoRoot.Length).
        TrimStart('\', '/').Replace('\', '/')
}

function Assert-NoReparseTraversal {
    param([string]$Path)
    $currentPath = [System.IO.Path]::GetFullPath($Path)
    while (-not (Test-Path -LiteralPath $currentPath)) {
        $parent = Split-Path -Parent $currentPath
        if ([string]::IsNullOrWhiteSpace($parent) -or
            $parent.Equals(
                $currentPath,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Path has no existing repository ancestor: '$Path'."
        }
        $currentPath = $parent
    }
    while ($true) {
        $item = Get-Item -LiteralPath $currentPath -Force
        if (($item.Attributes -band
                [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Path traverses reparse point '$currentPath'."
        }
        if ($currentPath.Equals(
                $repoRoot,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            return
        }
        $parent = Split-Path -Parent $currentPath
        if ([string]::IsNullOrWhiteSpace($parent) -or
            $parent.Equals(
                $currentPath,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            break
        }
        $currentPath = $parent
    }
    throw "Path is not rooted beneath the repository: '$Path'."
}

function Resolve-RepoFile {
    param([string]$Path, [string]$Description)
    $full = Get-ConfiguredFullPath $Path
    if (-not (Test-PathInsideRoot $full $repoRoot) -or
        -not (Test-Path -LiteralPath $full -PathType Leaf)) {
        throw "$Description is missing or outside the repository: '$full'."
    }
    Assert-NoReparseTraversal $full
    return (Resolve-Path -LiteralPath $full).Path
}

function Assert-IgnoredOutputPath {
    param(
        [string]$Path,
        [string]$Description,
        [switch]$Directory
    )
    $full = Get-ConfiguredFullPath $Path
    if (-not (Test-PathInsideRoot $full $repoRoot)) {
        throw "$Description must be repository-contained: '$full'."
    }
    Assert-NoReparseTraversal $full
    $relative = Get-RepoRelativePath $full
    if ($relative -notmatch '^(?i:a|artifacts)/') {
        throw "$Description must be below ignored a/ or artifacts/: '$relative'."
    }
    & git -C $repoRoot check-ignore --quiet -- $relative 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "$Description must be Git-ignored: '$relative'."
    }
    if ($Directory) {
        if (Test-Path -LiteralPath $full) {
            $entries = @(Get-ChildItem -LiteralPath $full -Force)
            if ($entries.Count -ne 0) {
                throw "$Description must be a fresh empty directory: '$relative'."
            }
        }
    }
    elseif ([System.IO.Path]::GetExtension($full).ToLowerInvariant() -cne
        ".json") {
        throw "$Description must use a .json extension: '$relative'."
    }
    if (Test-Path -LiteralPath $full -PathType Leaf) {
        throw "$Description already exists: '$relative'."
    }
    return $full
}

function Get-FileSha256Hex {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).
        Hash.ToLowerInvariant()
}

function Get-FileRecord {
    param([string]$Path)
    $file = Get-Item -LiteralPath $Path -Force
    return [pscustomobject][ordered]@{
        path = Get-RepoRelativePath $file.FullName
        sha256 = Get-FileSha256Hex $file.FullName
        length = [long]$file.Length
    }
}

function Get-CsvField {
    param($Row, [string]$Name)
    $property = $Row.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) {
        return ""
    }
    return [string]$property.Value
}

function Parse-Number {
    param([string]$Value, [string]$Description)
    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "$Description is empty."
    }
    $text = $Value.Trim()
    if ($text.StartsWith(
            "0x", [System.StringComparison]::OrdinalIgnoreCase)) {
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

function Get-CanonicalProgram {
    param([string]$Value)
    if ($Value.Equals(
            "Oregon32.exe",
            [System.StringComparison]::OrdinalIgnoreCase)) {
        return "Oregon32.exe"
    }
    if ($Value.Equals(
            "Oregon32.dll",
            [System.StringComparison]::OrdinalIgnoreCase)) {
        return "Oregon32.dll"
    }
    throw "Unsupported program '$Value'."
}

function Get-ManifestRowRecord {
    param($Row)
    $record = [ordered]@{}
    foreach ($field in $manifestFields) {
        $record[$field] = Get-CsvField $Row $field
    }
    return [pscustomobject]$record
}

function Get-ManifestIdentity {
    param($Row)
    $programName = (Get-CanonicalProgram (Get-CsvField $Row "program")).
        ToLowerInvariant()
    $rva = Parse-Number (Get-CsvField $Row "original_rva") "original_rva"
    return ("{0}|0x{1:x}" -f $programName, $rva)
}

function Get-GitOutput {
    param([string[]]$Arguments, [string]$Description)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = @(& git -C $repoRoot @Arguments 2>&1 |
            ForEach-Object { [string]$_ })
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
    if ($exitCode -ne 0) {
        throw "$Description failed: $($output -join [Environment]::NewLine)"
    }
    return @($output)
}

function Get-GitManifestRows {
    param([string]$Commit, [string]$RelativePath)
    $output = @(Get-GitOutput @(
        "show", ($Commit + ":" + $RelativePath)) "Reading prior manifest")
    $text = [string]::Join([Environment]::NewLine, $output)
    return @($text | ConvertFrom-Csv)
}

function Get-GitBlobOid {
    param(
        [string]$Commit,
        [string]$RelativePath,
        [string]$Description
    )
    $output = @(Get-GitOutput @(
        "rev-parse", ($Commit + ":" + $RelativePath)) $Description)
    if ($output.Count -ne 1 -or
        $output[0].Trim().ToLowerInvariant() -notmatch '^[0-9a-f]{40,64}$') {
        throw "$Description returned an invalid Git blob object ID."
    }
    return $output[0].Trim().ToLowerInvariant()
}

function Get-WorktreeBlobOid {
    param([string]$Path, [string]$Description)
    $output = @(Get-GitOutput @("hash-object", "--", $Path) $Description)
    if ($output.Count -ne 1 -or
        $output[0].Trim().ToLowerInvariant() -notmatch '^[0-9a-f]{40,64}$') {
        throw "$Description returned an invalid Git blob object ID."
    }
    return $output[0].Trim().ToLowerInvariant()
}

function Get-ProductSources {
    param([string]$Path)
    $sources = @()
    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith("#")) {
            continue
        }
        $normalized = $trimmed.Replace('\', '/').TrimStart('./')
        if ($normalized -notmatch '^(?i:src/).+\.cpp$') {
            throw "Invalid Product source-list entry '$trimmed'."
        }
        $sources += $normalized
    }
    return @($sources)
}

function Get-ObjectNameForSource {
    param([string]$RelativePath)
    return (($RelativePath -replace '[\\/]', '_') -replace
        '\.cpp$', '.obj')
}

function Assert-UniqueProductObjectOwner {
    param(
        [string[]]$ProductSources,
        [string]$CandidateObject
    )

    $owners = @($ProductSources | Where-Object {
        (Get-ObjectNameForSource $_).Equals(
            $CandidateObject,
            [System.StringComparison]::OrdinalIgnoreCase)
    })
    if ($owners.Count -ne 1) {
        throw "Current candidate_object is not uniquely owned by one Product source."
    }
}

function Compare-ManifestBoundary {
    param(
        [object[]]$PriorRows,
        [object[]]$CurrentRows,
        [string]$RequiredIdentity
    )
    foreach ($set in @(
            [pscustomobject]@{ Rows = $PriorRows; Name = "Prior manifest" },
            [pscustomobject]@{ Rows = $CurrentRows; Name = "Current manifest" })) {
        foreach ($row in @($set.Rows)) {
            [string[]]$propertyNames = @(
                $row.PSObject.Properties | ForEach-Object { $_.Name })
            if (($propertyNames -join "`n") -cne
                ($manifestFields -join "`n")) {
                throw "$($set.Name) has noncanonical fields or field order."
            }
        }
    }
    if ($PriorRows.Count -ne $CurrentRows.Count) {
        throw "Manifest row count changed; Product reanchor requires one stable row."
    }
    $changes = @()
    for ($index = 0; $index -lt $CurrentRows.Count; $index++) {
        $prior = $PriorRows[$index]
        $current = $CurrentRows[$index]
        $fields = @()
        foreach ($field in $manifestFields) {
            if ((Get-CsvField $prior $field) -cne
                (Get-CsvField $current $field)) {
                $fields += $field
            }
        }
        if ($fields.Count -ne 0) {
            $changes += [pscustomobject]@{
                index = $index
                prior = $prior
                current = $current
                fields = @($fields)
            }
        }
    }
    if ($changes.Count -ne 1) {
        throw ("Product reanchor requires exactly one changed manifest row; " +
            "found $($changes.Count).")
    }
    $change = $changes[0]
    $priorIdentity = Get-ManifestIdentity $change.prior
    $currentIdentity = Get-ManifestIdentity $change.current
    if ($priorIdentity -cne $RequiredIdentity -or
        $currentIdentity -cne $RequiredIdentity) {
        throw "The sole manifest delta does not preserve the requested identity."
    }
    $disallowed = @($change.fields | Where-Object {
        -not ($allowedChangedFields -ccontains $_)
    })
    if ($disallowed.Count -ne 0) {
        throw ("Product reanchor changed forbidden manifest fields: " +
            ($disallowed -join ", ") + ".")
    }
    $missingRequired = @($requiredChangedFields | Where-Object {
        -not ($change.fields -ccontains $_)
    })
    if ($missingRequired.Count -ne 0) {
        throw ("Product reanchor did not change required manifest fields: " +
            ($missingRequired -join ", ") + ".")
    }
    if ((Get-CsvField $change.prior "expected_status") -cne "wip" -or
        (Get-CsvField $change.current "expected_status") -cne "match") {
        throw "Product reanchor requires an exact expected_status wip-to-match transition."
    }
    if ((Get-CsvField $change.prior "implementation_kind") -cne "cpp" -or
        (Get-CsvField $change.current "implementation_kind") -cne "cpp") {
        throw "Product reanchor supports pure C++ rows only."
    }
    if ((Get-CsvField $change.prior "mask") -cne
        (Get-CsvField $change.current "mask")) {
        throw "Product reanchor cannot add, remove, or alter a mask."
    }
    return $change
}

function Invoke-Tool {
    param(
        [string]$ScriptPath,
        [string[]]$Arguments,
        [string]$Description
    )
    $commandArguments = @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $ScriptPath) +
        $Arguments
    $started = [DateTime]::UtcNow
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = @(& $PowerShellExecutable @commandArguments 2>&1 |
            ForEach-Object { [string]$_ })
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
    $duration = [long]([DateTime]::UtcNow - $started).TotalMilliseconds
    if ($exitCode -ne 0) {
        $tail = @($output | Select-Object -Last 20) -join
            [Environment]::NewLine
        throw ($Description + " failed with exit code " + $exitCode + ":" +
            [Environment]::NewLine + $tail)
    }
    return [pscustomobject]@{
        output = @($output)
        duration_ms = $duration
    }
}

function Get-ToolRecord {
    param([string]$Path)
    return [pscustomobject][ordered]@{
        path = Get-RepoRelativePath $Path
        sha256 = Get-FileSha256Hex $Path
    }
}

function Get-ProductSymbolContainment {
    param(
        [string]$MapPath,
        [string]$CandidateSymbol,
        [string]$ExpectedObject,
        [uint64]$CandidateRva,
        [uint64]$Size
    )

    if ($Size -eq 0) {
        throw "Product symbol-containment size must be positive."
    }
    $expression = $CandidateSymbol.Trim()
    if ($expression -notmatch
        '^(?<symbol>.+?)(?:\s*\+\s*(?<offset>0x[0-9A-Fa-f]+|[0-9]+))?$') {
        throw "Invalid Product candidate_symbol expression '$CandidateSymbol'."
    }
    $baseSymbol = $Matches["symbol"].Trim()
    $symbolOffset = [uint64]0
    if ($Matches.ContainsKey("offset") -and
        -not [string]::IsNullOrWhiteSpace($Matches["offset"])) {
        $symbolOffset = Parse-Number $Matches["offset"] `
            "candidate_symbol.offset"
    }

    $mapLines = @(Get-Content -LiteralPath $MapPath)
    $imageBases = @($mapLines | ForEach-Object {
        if ($_ -match
            '^\s*Preferred load address is\s+([0-9A-Fa-f]+)\s*$') {
            [uint64]::Parse(
                $Matches[1],
                [System.Globalization.NumberStyles]::HexNumber,
                [System.Globalization.CultureInfo]::InvariantCulture)
        }
    })
    if ($imageBases.Count -ne 1) {
        throw "Candidate map does not contain exactly one preferred load address."
    }
    $imageBase = [uint64]$imageBases[0]
    $publics = @()
    $inPublics = $false
    foreach ($line in $mapLines) {
        if ($line -match
            '^\s*Address\s+Publics by Value\s+Rva\+Base\s+Lib:Object\s*$') {
            $inPublics = $true
            continue
        }
        if (-not $inPublics) {
            continue
        }
        if ($line -match '^\s*(?:entry point at|Static symbols)\b') {
            break
        }
        $publicMatch = [regex]::Match(
            $line,
            '^\s*(?<segment>[0-9A-Fa-f]{4}):(?<offset>[0-9A-Fa-f]{8,16})\s+(?<symbol>\S+)\s+(?<va>[0-9A-Fa-f]{8,16})(?:\s+(?<tail>.*\S))?\s*$')
        if ($publicMatch.Success) {
            $symbolVa = [uint64]::Parse(
                $publicMatch.Groups["va"].Value,
                [System.Globalization.NumberStyles]::HexNumber,
                [System.Globalization.CultureInfo]::InvariantCulture)
            if ($symbolVa -lt $imageBase) {
                continue
            }
            $objectName = ""
            if (-not [string]::IsNullOrWhiteSpace(
                    $publicMatch.Groups["tail"].Value)) {
                $tailTokens = @(
                    $publicMatch.Groups["tail"].Value.Trim() -split '\s+')
                if ($tailTokens.Count -ne 0 -and
                    $tailTokens[$tailTokens.Count - 1] -notmatch '^[fFiI]+$') {
                    $objectName = $tailTokens[$tailTokens.Count - 1]
                }
            }
            $publics += [pscustomobject]@{
                Symbol = $publicMatch.Groups["symbol"].Value
                Segment = $publicMatch.Groups["segment"].Value.
                    ToLowerInvariant()
                Offset = [uint64]::Parse(
                    $publicMatch.Groups["offset"].Value,
                    [System.Globalization.NumberStyles]::HexNumber,
                    [System.Globalization.CultureInfo]::InvariantCulture)
                Rva = $symbolVa - $imageBase
                Object = $objectName
            }
        }
    }
    if (-not $inPublics -or $publics.Count -eq 0) {
        throw "Candidate map does not contain a usable Publics by Value table."
    }
    $baseMatches = @($publics | Where-Object {
        [string]$_.Symbol -ceq $baseSymbol -and
        [string]$_.Object -ieq $ExpectedObject
    })
    if ($baseMatches.Count -ne 1) {
        throw (("Product candidate base public '{0}' in object '{1}' is " +
            "missing or ambiguous in the candidate map.") -f
            $baseSymbol, $ExpectedObject)
    }
    $base = $baseMatches[0]
    if ($symbolOffset -gt ([uint64]::MaxValue - [uint64]$base.Rva)) {
        throw "Product candidate_symbol offset overflows the candidate RVA."
    }
    $resolvedRva = [uint64]$base.Rva + $symbolOffset
    if ($resolvedRva -ne $CandidateRva) {
        throw ("Product candidate RVA does not equal its qualified map base " +
            "public plus offset.")
    }
    if ($Size -gt ([uint64]::MaxValue - $resolvedRva)) {
        throw "Product candidate byte range overflows the candidate RVA."
    }
    $rangeEnd = $resolvedRva + $Size
    $nextPublics = @($publics | Where-Object {
        [string]$_.Segment -ceq [string]$base.Segment -and
        [uint64]$_.Offset -gt [uint64]$base.Offset
    } | Sort-Object -Property @{ Expression = { [uint64]$_.Offset } })
    if ($nextPublics.Count -eq 0) {
        throw "Product candidate base public has no next-public containment bound."
    }
    $nextPublic = $nextPublics[0]
    if ([uint64]$nextPublic.Rva -le [uint64]$base.Rva -or
        $rangeEnd -gt [uint64]$nextPublic.Rva) {
        throw ("Product candidate byte range escapes its qualified base-public " +
            "extent before the next public symbol.")
    }

    return [pscustomobject][ordered]@{
        proof_method = "msvc-map-qualified-base-to-next-public"
        map_sha256 = Get-FileSha256Hex $MapPath
        candidate_symbol_expression = $expression
        base_symbol = $baseSymbol
        base_rva = ("0x{0:x}" -f [uint64]$base.Rva)
        base_object = [string]$base.Object
        offset = ("0x{0:x}" -f $symbolOffset)
        target_rva = ("0x{0:x}" -f $resolvedRva)
        target_size = [uint64]$Size
        target_end_rva_exclusive = ("0x{0:x}" -f $rangeEnd)
        next_public_symbol = [string]$nextPublic.Symbol
        next_public_rva = ("0x{0:x}" -f [uint64]$nextPublic.Rva)
        next_public_object = [string]$nextPublic.Object
        segment = [string]$base.Segment
        within_base_public_extent = $true
    }
}

function Assert-SourceBoundary {
    param([string]$Source, [string]$ExpectedHash)
    $actual = Get-FileSha256Hex $Source
    if ($actual -cne $ExpectedHash) {
        throw "Product source changed during manifest-only reanchor evidence generation."
    }
}

$Program = Get-CanonicalProgram $Program
if ($Program -cne "Oregon32.exe") {
    throw "Product reanchor evidence is restricted to the Oregon32.exe main image."
}
if ($Toolchain -cne "LegacyMsvc") {
    throw "Product reanchor evidence requires the LegacyMsvc toolchain."
}
if (-not [System.IO.Path]::GetFullPath($VcToolsRoot).Equals(
        [System.IO.Path]::GetFullPath("C:\MSDEV"),
        [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Product reanchor evidence requires the canonical C:\MSDEV VC4 root."
}
if ($DefaultOptimization -cne "/Od" -or
    $SemanticOptimization -cne "/O1") {
    throw "Product reanchor evidence requires canonical /Od and /O1 optimization modes."
}
if ($CheckpointId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
    throw "CheckpointId is invalid."
}
if ([string]::IsNullOrWhiteSpace($PriorBoundaryRunId)) {
    throw "PriorBoundaryRunId is required."
}

$manifestAbsolute = Resolve-RepoFile $ManifestPath "Manifest"
$manifestRelative = Get-RepoRelativePath $manifestAbsolute
$productManifestAbsolute = Resolve-RepoFile $ProductSourceManifestPath "Product source manifest"
if ((Get-RepoRelativePath $productManifestAbsolute) -cne
    "tools/otmatch/vc4-exe-product-sources.txt") {
    throw "Product reanchor evidence requires the canonical EXE Product source list."
}
$tuMetadataAbsolute = Resolve-RepoFile $TuMetadataPath "TU metadata"
if ((Get-RepoRelativePath $tuMetadataAbsolute) -cne
    "tools/otmatch/vc4-tu-metadata.csv") {
    throw "Product reanchor evidence requires the canonical VC4 TU metadata file."
}
$ledgerAbsolute = Resolve-RepoFile $SessionLedgerPath "Session ledger"
$sourceAbsolute = Resolve-RepoFile $SourcePath "Product source"
$sourceRelative = Get-RepoRelativePath $sourceAbsolute
if ($sourceRelative -notmatch '^(?i:src/otwin/).+\.cpp$') {
    throw "Product reanchor source must be a C++ TU below src/otwin/."
}
$originalExeAbsolute = Resolve-RepoFile $OriginalExePath "Original EXE"
$originalDllAbsolute = Resolve-RepoFile $OriginalDllPath "Original DLL"
$outputAbsolute = Assert-IgnoredOutputPath $OutputPath "Evidence output"
$buildOutputAbsolute = Assert-IgnoredOutputPath $BuildOutputDirectory "Build output directory" -Directory

$ledger = Get-Content -LiteralPath $ledgerAbsolute -Raw | ConvertFrom-Json
$boundaryRuns = @($ledger.runs | Where-Object {
    [string]$_.run_id -ceq $PriorBoundaryRunId
})
if ($boundaryRuns.Count -ne 1) {
    throw "Prior boundary run '$PriorBoundaryRunId' is missing or ambiguous."
}
$boundaryRun = $boundaryRuns[0]
if ([string]$boundaryRun.mode -cne "execute" -or
    [string]$boundaryRun.status -cne "passed") {
    throw "Prior boundary run must be a passed executed recovery-wave run."
}
$requiredBoundaryProperties = @(
    "git_snapshot_captured", "git_commit_sha", "worktree_state_sha256",
    "worktree_dirty", "git_end_snapshot_captured", "git_end_commit_sha",
    "end_worktree_state_sha256", "end_worktree_dirty")
foreach ($propertyName in $requiredBoundaryProperties) {
    if ($null -eq $boundaryRun.PSObject.Properties[$propertyName]) {
        throw "Prior boundary run lacks clean committed boundary evidence."
    }
}
if (-not ($boundaryRun.git_snapshot_captured -is [bool]) -or
    -not [bool]$boundaryRun.git_snapshot_captured -or
    -not ($boundaryRun.git_end_snapshot_captured -is [bool]) -or
    -not [bool]$boundaryRun.git_end_snapshot_captured -or
    -not ($boundaryRun.worktree_dirty -is [bool]) -or
    [bool]$boundaryRun.worktree_dirty -or
    -not ($boundaryRun.end_worktree_dirty -is [bool]) -or
    [bool]$boundaryRun.end_worktree_dirty) {
    throw "Prior boundary run must have captured clean start and end worktrees."
}
$boundaryCommit = ([string]$boundaryRun.git_commit_sha).ToLowerInvariant()
if ($boundaryCommit -notmatch '^[0-9a-f]{40}$') {
    throw "Prior boundary run does not bind a valid Git commit."
}
$boundaryStartState = ([string]$boundaryRun.worktree_state_sha256).
    Trim().ToLowerInvariant()
$boundaryEndState = ([string]$boundaryRun.end_worktree_state_sha256).
    Trim().ToLowerInvariant()
if ([string]$boundaryRun.git_end_commit_sha -cne $boundaryCommit -or
    $boundaryStartState -notmatch '^[0-9a-f]{64}$' -or
    $boundaryEndState -cne $boundaryStartState) {
    throw "Prior boundary run does not bind one clean, stable committed Git boundary."
}
[void](Get-GitOutput -Arguments @(
    "merge-base", "--is-ancestor", $boundaryCommit, "HEAD") -Description "Prior-boundary ancestry validation")

$currentRows = @(Import-Csv -LiteralPath $manifestAbsolute)
$priorRows = Get-GitManifestRows $boundaryCommit $manifestRelative
$targetRows = @($currentRows | Where-Object {
    (Get-CsvField $_ "name").Equals(
        $FunctionName,
        [System.StringComparison]::OrdinalIgnoreCase) -and
    (Get-CsvField $_ "program").Equals(
        $Program,
        [System.StringComparison]::OrdinalIgnoreCase)
})
if ($targetRows.Count -ne 1) {
    throw "Current manifest target is missing or ambiguous."
}
$targetRow = $targetRows[0]
$identity = Get-ManifestIdentity $targetRow
$manifestDelta = Compare-ManifestBoundary $priorRows $currentRows $identity
$trackedDeltaPaths = @(Get-GitOutput -Arguments @(
    "diff", "--name-only", $boundaryCommit, "--") -Description "Tracked worktree delta validation" | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    } | ForEach-Object { $_.Trim().Replace('\\', '/') })
if ($trackedDeltaPaths.Count -ne 1 -or
    $trackedDeltaPaths[0] -cne $manifestRelative) {
    throw ("Product reanchor requires the manifest to be the sole tracked " +
        "delta from the prior boundary; found: " +
        $(if ($trackedDeltaPaths.Count -eq 0) {
            "none"
        } else { $trackedDeltaPaths -join ", " }))
}

$productSources = Get-ProductSources $productManifestAbsolute
$normalizedSource = $sourceRelative.Replace('\', '/')
$sourceMatches = @($productSources | Where-Object {
    $_.Equals(
        $normalizedSource,
        [System.StringComparison]::OrdinalIgnoreCase)
})
if ($sourceMatches.Count -ne 1) {
    throw "Selected source is not exactly once in the canonical Product source list."
}
$sourceObject = Get-ObjectNameForSource $normalizedSource
$currentObject = Get-CsvField $manifestDelta.current "candidate_object"
if (-not $currentObject.Equals(
        $sourceObject,
        [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Current candidate_object does not belong to the selected Product source."
}
$productObjects = @($productSources | ForEach-Object {
    Get-ObjectNameForSource $_
})
Assert-UniqueProductObjectOwner $productSources $currentObject
$priorObject = Get-CsvField $manifestDelta.prior "candidate_object"
if (-not [string]::IsNullOrWhiteSpace($priorObject) -and
    @($productObjects | Where-Object {
        $_.Equals(
            $priorObject,
            [System.StringComparison]::OrdinalIgnoreCase)
    }).Count -ne 0) {
    throw "Prior WIP row already points at a Product-list object."
}
$candidateSymbol = Get-CsvField $manifestDelta.current "candidate_symbol"
if ([string]::IsNullOrWhiteSpace($candidateSymbol)) {
    throw "Current Product reanchor requires a symbol-relative locator."
}
if (-not [string]::IsNullOrWhiteSpace(
        (Get-CsvField $manifestDelta.prior "candidate_va")) -or
    -not [string]::IsNullOrWhiteSpace(
        (Get-CsvField $manifestDelta.prior "candidate_dll"))) {
    throw "Product reanchor prior row must use the main candidate image."
}
$priorRva = Get-CsvField $manifestDelta.prior "candidate_rva"
$priorSymbol = Get-CsvField $manifestDelta.prior "candidate_symbol"
if ([string]::IsNullOrWhiteSpace($priorRva) -eq
    [string]::IsNullOrWhiteSpace($priorSymbol)) {
    throw "Product reanchor prior row must use exactly one recovery RVA or symbol locator."
}
if (-not [string]::IsNullOrWhiteSpace($priorRva) -and
    -not [string]::IsNullOrWhiteSpace(
        (Get-CsvField $manifestDelta.prior "candidate_object"))) {
    throw "Product reanchor prior candidate_rva cannot carry candidate_object."
}
if (-not [string]::IsNullOrWhiteSpace($priorSymbol) -and
    [string]::IsNullOrWhiteSpace(
        (Get-CsvField $manifestDelta.prior "candidate_object"))) {
    throw "Product reanchor prior candidate_symbol requires candidate_object."
}
if (-not [string]::IsNullOrWhiteSpace(
        (Get-CsvField $manifestDelta.current "candidate_va")) -or
    -not [string]::IsNullOrWhiteSpace(
        (Get-CsvField $manifestDelta.current "candidate_rva")) -or
    -not [string]::IsNullOrWhiteSpace(
        (Get-CsvField $manifestDelta.current "candidate_dll")) -or
    [string]::IsNullOrWhiteSpace(
        (Get-CsvField $manifestDelta.current "candidate_symbol"))) {
    throw ("Product reanchor current row must use only a main-image " +
        "candidate_symbol locator (no candidate_va, candidate_rva, or " +
        "candidate_dll).")
}
if ([string]::IsNullOrWhiteSpace(
        (Get-CsvField $manifestDelta.current "notes"))) {
    throw "Current Product reanchor notes are empty."
}

[void](Get-GitOutput -Arguments @(
    "diff", "--quiet", $boundaryCommit, "--", $sourceRelative) -Description "Product source boundary validation")
$sourceHash = Get-FileSha256Hex $sourceAbsolute
$sourceBoundaryBlob = Get-GitBlobOid $boundaryCommit $sourceRelative `
    "Product source boundary blob lookup"
$sourceCurrentBlob = Get-WorktreeBlobOid $sourceAbsolute `
    "Product source worktree blob lookup"
if ($sourceBoundaryBlob -cne $sourceCurrentBlob) {
    throw "Product source bytes differ from the prior recovery-wave boundary."
}
$manifestHash = Get-FileSha256Hex $manifestAbsolute
$generatorHashAtStart = Get-FileSha256Hex $PSCommandPath

$evidenceParent = Split-Path -Parent $outputAbsolute
[void][System.IO.Directory]::CreateDirectory($evidenceParent)
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($outputAbsolute)
$verifierAbsolute = Join-Path $evidenceParent `
    ($baseName + ".function-match-results.csv")
$maskAuditAbsolute = Join-Path $evidenceParent `
    ($baseName + ".mask-audit.csv")
$productAuditAbsolute = Join-Path $evidenceParent `
    ($baseName + ".product-source-audit.json")
foreach ($generatedPath in @(
        $verifierAbsolute, $maskAuditAbsolute, $productAuditAbsolute)) {
    if (Test-Path -LiteralPath $generatedPath) {
        throw "Generated evidence output already exists: '$generatedPath'."
    }
}

$buildScript = Resolve-RepoFile "tools/otmatch/build-match-candidates.ps1" "Candidate build script"
$diffScript = Resolve-RepoFile "tools/otmatch/diff-symbol-bytes.ps1" "Focused diff script"
$matcherScript = Resolve-RepoFile "tools/otmatch/match-functions.ps1" "Schema-4 matcher"
$maskScript = Resolve-RepoFile "tools/otmatch/audit-function-masks.ps1" "Mask audit script"
$productAuditScript = Resolve-RepoFile "tools/otmatch/audit-vc4-product-sources.ps1" "Product audit script"

$build = Invoke-Tool $buildScript @(
    "-Toolchain", $Toolchain,
    "-VcToolsRoot", $VcToolsRoot,
    "-OutputDirectory", $buildOutputAbsolute,
    "-TuMetadataPath", $tuMetadataAbsolute,
    "-DefaultOptimization", $DefaultOptimization,
    "-SemanticOptimization", $SemanticOptimization,
    "-Rebuild") "Normal non-trusting candidate rebuild"
Assert-SourceBoundary $sourceAbsolute $sourceHash

$candidatePath = Join-Path $buildOutputAbsolute "otwin-match-candidates.dll"
$candidateMapPath = Join-Path $buildOutputAbsolute "otwin-match-candidates.map"
$candidateLcmtPath =
    Join-Path $buildOutputAbsolute "otwin-match-candidates-lcmt.dll"
$candidateLcmtMapPath =
    Join-Path $buildOutputAbsolute "otwin-match-candidates-lcmt.map"
$candidateDllcrtPath =
    Join-Path $buildOutputAbsolute "otwin-match-candidates-dllcrt.dll"
$candidateDllcrtMapPath =
    Join-Path $buildOutputAbsolute "otwin-match-candidates-dllcrt.map"
$candidateObjectPath = Join-Path $buildOutputAbsolute $sourceObject
foreach ($builtFile in @(
        $candidatePath, $candidateMapPath,
        $candidateLcmtPath, $candidateLcmtMapPath,
        $candidateDllcrtPath, $candidateDllcrtMapPath,
        $candidateObjectPath)) {
    if (-not (Test-Path -LiteralPath $builtFile -PathType Leaf)) {
        throw "Normal rebuild did not produce '$builtFile'."
    }
}

$originalRva = Parse-Number (Get-CsvField $targetRow "original_rva") "original_rva"
$size = Parse-Number (Get-CsvField $targetRow "size") "size"
$mask = Get-CsvField $targetRow "mask"
$selectedOriginal = if ($Program -ceq "Oregon32.exe") {
    $originalExeAbsolute
}
else {
    $originalDllAbsolute
}
$diffArguments = @(
    "-OriginalPath", $selectedOriginal,
    "-OriginalRva", ("0x{0:x}" -f $originalRva),
    "-Size", $size.ToString(
        [System.Globalization.CultureInfo]::InvariantCulture),
    "-CandidatePath", $candidatePath,
    "-CandidateMapPath", $candidateMapPath,
    "-CandidateSymbol", $candidateSymbol)
if (-not [string]::IsNullOrWhiteSpace($mask)) {
    $diffArguments += @("-Mask", $mask)
}
$diff = Invoke-Tool $diffScript $diffArguments "Focused Product reanchor diff"
$diffText = $diff.output -join [Environment]::NewLine
$candidateRvaMatch = [regex]::Match(
    $diffText, '(?m)^Candidate RVA:\s+(0x[0-9a-fA-F]+)\s*$')
$rawMatch = [regex]::Match(
    $diffText, '(?m)^Differences:\s+([0-9]+)\s*/\s*([0-9]+)\s*$')
$hardMatch = [regex]::Match(
    $diffText, '(?m)^Hard differences:\s+([0-9]+)\s*/\s*([0-9]+)\s*$')
if (-not $candidateRvaMatch.Success -or
    -not $rawMatch.Success -or -not $hardMatch.Success) {
    throw "Focused Product reanchor diff output is incomplete."
}
$rawDiffCount = [uint64]$rawMatch.Groups[1].Value
$rawComparedBytes = [uint64]$rawMatch.Groups[2].Value
$hardDiffCount = [uint64]$hardMatch.Groups[1].Value
$hardComparedBytes = [uint64]$hardMatch.Groups[2].Value
if ($rawDiffCount -ne 0 -or $hardDiffCount -ne 0 -or
    $rawComparedBytes -ne $size -or $hardComparedBytes -le 0) {
    throw "Product reanchor requires a zero-raw, zero-hard focused comparison."
}
$candidateRva = Parse-Number $candidateRvaMatch.Groups[1].Value `
    "focused candidate_rva"
$symbolContainment = Get-ProductSymbolContainment `
    $candidateMapPath $candidateSymbol $currentObject $candidateRva $size
Assert-SourceBoundary $sourceAbsolute $sourceHash

$matcher = Invoke-Tool $matcherScript @(
    "-ManifestPath", $manifestAbsolute,
    "-OriginalPath", $originalExeAbsolute,
    "-OriginalDllPath", $originalDllAbsolute,
    "-CandidatePath", $candidatePath,
    "-CandidateMapPath", $candidateMapPath,
    "-CandidateLcmtPath", $candidateLcmtPath,
    "-CandidateLcmtMapPath", $candidateLcmtMapPath,
    "-CandidateDllcrtPath", $candidateDllcrtPath,
    "-CandidateDllcrtMapPath", $candidateDllcrtMapPath,
    "-ResultsCsvPath", $verifierAbsolute,
    "-SummaryOnly") "Full schema-4 matcher"
$maskAudit = Invoke-Tool $maskScript @(
    "-ManifestPath", $manifestAbsolute,
    "-OriginalPath", $originalExeAbsolute,
    "-OriginalDllPath", $originalDllAbsolute,
    "-ResultsCsvPath", $maskAuditAbsolute,
    "-RequireValidated") "Validated original mask audit"
$productAudit = Invoke-Tool $productAuditScript @(
    "-ManifestPath", $productManifestAbsolute,
    "-ResultsJsonPath", $productAuditAbsolute,
    "-SummaryOnly") "Product source-policy audit"
Assert-SourceBoundary $sourceAbsolute $sourceHash
if ((Get-FileSha256Hex $manifestAbsolute) -cne $manifestHash) {
    throw "Manifest changed during Product reanchor evidence generation."
}
if ((Get-FileSha256Hex $PSCommandPath) -cne $generatorHashAtStart) {
    throw "Product reanchor evidence generator changed while it was running."
}

$verifierRows = @(Import-Csv -LiteralPath $verifierAbsolute)
$verifiedRows = @($verifierRows | Where-Object {
    (Get-CsvField $_ "name").Equals(
        $FunctionName,
        [System.StringComparison]::OrdinalIgnoreCase) -and
    (Get-CsvField $_ "program").Equals(
        $Program,
        [System.StringComparison]::OrdinalIgnoreCase)
})
if ($verifiedRows.Count -ne 1) {
    throw "Schema-4 verifier result for the Product reanchor is missing or ambiguous."
}
$verified = $verifiedRows[0]
if ((Get-CsvField $verified "result_schema_version") -cne "4" -or
    (Get-CsvField $verified "expected_status") -cne "match" -or
    (Get-CsvField $verified "actual_status") -cne "match" -or
    (Get-CsvField $verified "verification_status") -cne "pass" -or
    (Get-CsvField $verified "raw_match") -cne "True" -or
    (Get-CsvField $verified "mask_shape_valid") -cne "True" -or
    -not [string]::IsNullOrWhiteSpace(
        (Get-CsvField $verified "error_message"))) {
    throw "Schema-4 verifier did not prove an error-free exact accepted match."
}
if ((Get-CsvField $verified "candidate_symbol") -cne $candidateSymbol -or
    -not (Get-CsvField $verified "candidate_object").Equals(
        $currentObject,
        [System.StringComparison]::OrdinalIgnoreCase) -or
    -not [string]::IsNullOrWhiteSpace(
        (Get-CsvField $verified "candidate_dll")) -or
    (Get-CsvField $verified "candidate_locator_kind") -cne
        "candidate_symbol" -or
    -not (Get-CsvField $verified "candidate_object_qualifier").Equals(
        $currentObject,
        [System.StringComparison]::OrdinalIgnoreCase) -or
    (Get-CsvField $verified "candidate_rva") -cne
        $candidateRvaMatch.Groups[1].Value.ToLowerInvariant()) {
    throw "Schema-4 verifier did not bind the intended symbol/object locator."
}

$maskRows = @(Import-Csv -LiteralPath $maskAuditAbsolute | Where-Object {
    (Get-CsvField $_ "name").Equals(
        $FunctionName,
        [System.StringComparison]::OrdinalIgnoreCase) -and
    (Get-CsvField $_ "program").Equals(
        $Program,
        [System.StringComparison]::OrdinalIgnoreCase)
})
$maskState = "not-required-no-mask"
if (-not [string]::IsNullOrWhiteSpace($mask)) {
    if ($maskRows.Count -eq 0 -or
        @($maskRows | Where-Object {
            -not [string]::IsNullOrWhiteSpace(
                (Get-CsvField $_ "issue")) -or
            (Get-CsvField $_ "classification") -cne
                "full_known_address_operand"
        }).Count -ne 0) {
        throw "Product reanchor mask rows are not fully validated."
    }
    $maskState = "validated-original-operands"
}
elseif ($maskRows.Count -ne 0) {
    throw "Maskless Product reanchor unexpectedly emitted target mask ranges."
}

$priorBlob = Get-GitBlobOid $boundaryCommit $manifestRelative `
    "Prior manifest blob lookup"
$artifact = [pscustomobject][ordered]@{
    schema_version = 1
    artifact_type = "otwin-product-reanchor-evidence"
    generator = [pscustomobject][ordered]@{
        name = "otmatch-product-reanchor-evidence"
        schema_version = 1
        script_path = $generatorRelativePath
        script_sha256 = $generatorHashAtStart
    }
    identity = [pscustomobject][ordered]@{
        key = $identity
        program = $Program
        name = Get-CsvField $targetRow "name"
        original_rva = ("0x{0:x}" -f $originalRva)
        size = [uint64]$size
    }
    checkpoint = [pscustomobject][ordered]@{
        checkpoint_id = $CheckpointId
        prior_boundary_run_id = $PriorBoundaryRunId
        prior_boundary_git_commit = $boundaryCommit
    }
    manifest_delta = [pscustomobject][ordered]@{
        path = $manifestRelative
        current_sha256 = $manifestHash
        prior_git_blob_oid = $priorBlob
        changed_row_count = 1
        changed_identity = $identity
        tracked_paths = @($trackedDeltaPaths)
        changed_fields = @($manifestDelta.fields)
        allowed_fields = @($allowedChangedFields)
        prior_row = Get-ManifestRowRecord $manifestDelta.prior
        current_row = Get-ManifestRowRecord $manifestDelta.current
    }
    source = [pscustomobject][ordered]@{
        path = $sourceRelative
        before_sha256 = $sourceHash
        after_sha256 = Get-FileSha256Hex $sourceAbsolute
        unchanged_from_boundary = $true
        boundary_git_blob_oid = $sourceBoundaryBlob
        current_git_blob_oid = $sourceCurrentBlob
        object_name = $sourceObject
        product_manifest_path =
            Get-RepoRelativePath $productManifestAbsolute
        product_manifest_sha256 =
            Get-FileSha256Hex $productManifestAbsolute
        product_reachable = $true
    }
    build = [pscustomobject][ordered]@{
        tool = Get-ToolRecord $buildScript
        mode = "normal-rebuild"
        toolchain = $Toolchain
        vc_tools_root = [System.IO.Path]::GetFullPath($VcToolsRoot)
        default_optimization = $DefaultOptimization
        semantic_optimization = $SemanticOptimization
        tu_metadata = Get-FileRecord $tuMetadataAbsolute
        rebuild = $true
        used_trusted_graph = $false
        output_directory = Get-RepoRelativePath $buildOutputAbsolute
        duration_ms = [uint64]$build.duration_ms
        candidate_file = Get-FileRecord $candidatePath
        candidate_map = Get-FileRecord $candidateMapPath
        candidate_object = Get-FileRecord $candidateObjectPath
    }
    focused_diff = [pscustomobject][ordered]@{
        tool = Get-ToolRecord $diffScript
        candidate_symbol = $candidateSymbol
        candidate_object = $currentObject
        candidate_rva = $candidateRvaMatch.Groups[1].Value.ToLowerInvariant()
        original_rva = ("0x{0:x}" -f $originalRva)
        size = [uint64]$size
        mask = $mask
        raw_diff_count = $rawDiffCount
        raw_compared_bytes = $rawComparedBytes
        hard_diff_count = $hardDiffCount
        hard_compared_bytes = $hardComparedBytes
        duration_ms = [uint64]$diff.duration_ms
    }
    symbol_containment = $symbolContainment
    verifier = [pscustomobject][ordered]@{
        tool = Get-ToolRecord $matcherScript
        results = Get-FileRecord $verifierAbsolute
        result_schema_version = 4
        verification_status = "pass"
        actual_status = "match"
        expected_status = "match"
        raw_match = $true
        mask_shape_valid = $true
        candidate_symbol = Get-CsvField $verified "candidate_symbol"
        candidate_object = Get-CsvField $verified "candidate_object"
        candidate_object_qualifier =
            Get-CsvField $verified "candidate_object_qualifier"
        candidate_rva = Get-CsvField $verified "candidate_rva"
        candidate_dll = Get-CsvField $verified "candidate_dll"
        candidate_locator_kind = Get-CsvField $verified "candidate_locator_kind"
        duration_ms = [uint64]$matcher.duration_ms
    }
    mask_audit = [pscustomobject][ordered]@{
        tool = Get-ToolRecord $maskScript
        results = Get-FileRecord $maskAuditAbsolute
        state = $maskState
        target_row_count = [uint64]$maskRows.Count
        validated = $true
        duration_ms = [uint64]$maskAudit.duration_ms
    }
    product_source_audit = [pscustomobject][ordered]@{
        tool = Get-ToolRecord $productAuditScript
        results = Get-FileRecord $productAuditAbsolute
        passed = $true
        duration_ms = [uint64]$productAudit.duration_ms
    }
    source_mutation = [pscustomobject][ordered]@{
        attempted = $false
        restoration = "not-applicable"
        disposition =
            "Manifest-only Product reanchor; no source mutation was attempted or required."
    }
    promotion_eligible = $true
}

$json = ($artifact | ConvertTo-Json -Depth 16) +
    [Environment]::NewLine
[System.IO.File]::WriteAllText($outputAbsolute, $json, $utf8NoBom)

Write-Host "Product-reanchor evidence passed:"
Write-Host "  Identity:        $identity"
Write-Host "  Manifest delta:  one row ($($manifestDelta.fields -join ', '))"
Write-Host "  Product source:  $sourceRelative ($sourceHash)"
Write-Host "  Focused diff:    0 raw / 0 hard / $hardComparedBytes compared"
Write-Host "  Schema-4:        pass"
Write-Host "  Source mutation: not applicable"
Write-Host "  Evidence:        $(Get-RepoRelativePath $outputAbsolute)"
