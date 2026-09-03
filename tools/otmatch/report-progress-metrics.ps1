param(
    [string]$ManifestPath = "tools\otmatch\functions.vc40-real-cpp.csv",

    [Alias("ResultsPath", "MatchResultsPath", "ResultsCsvPath")]
    [string]$VerifierResultsPath = "artifacts\otmatch\vc40\function-match-results.csv",

    [string]$MaskAuditResultsPath = "artifacts\otmatch\vc40\mask-audit.csv",

    [string[]]$FunctionMetricsPath = @(
        "tools\ghidra\otwin32\output\function_metrics_oregon32_exe.csv",
        "tools\ghidra\otwin32\output\function_metrics_oregon32_dll.csv"
    ),

    [string]$ExeProductSourceManifestPath = "tools\otmatch\vc4-exe-product-sources.txt",

    [string]$ExeProductProgram = "Oregon32.exe",

    [string]$ManifestProgram = "Oregon32.exe",
    [switch]$IncludeNonText,
    [switch]$RequireProductReachability,

    # A nonzero value turns the policy-compliant instruction percentage into
    # an executable milestone gate. The normal report remains informational.
    [ValidateRange(0.0, 100.0)]
    [double]$RequireInstructionPercent = 0.0,

    # Optional machine-readable evidence for recovery-wave checkpoint ledgers.
    # The file is written atomically only after every requested policy gate
    # passes.
    [string]$SummaryJsonPath = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

function Get-CsvField($Row, [string]$Name) {
    $property = $Row.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) {
        return ""
    }

    return [string]$property.Value
}

function Resolve-CsvColumn($ExampleRow, [string]$Purpose, [string[]]$Aliases) {
    foreach ($alias in $Aliases) {
        if ($null -ne $ExampleRow.PSObject.Properties[$alias]) {
            return $alias
        }
    }

    throw ("Verifier results are missing the {0} column. Accepted names: {1}." -f
        $Purpose, ($Aliases -join ", "))
}

function Parse-Number([string]$Value, [string]$FieldName, [bool]$AllowEmpty = $false) {
    if ([string]::IsNullOrWhiteSpace($Value)) {
        if ($AllowEmpty) {
            return $null
        }

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

function Parse-Boolean([string]$Value, [string]$FieldName) {
    switch ($Value.Trim().ToLowerInvariant()) {
        "true" { return $true }
        "1" { return $true }
        "yes" { return $true }
        "match" { return $true }
        "false" { return $false }
        "0" { return $false }
        "no" { return $false }
        "mismatch" { return $false }
        default { throw "Invalid Boolean value '$Value' in '$FieldName'." }
    }
}

function Get-FileSha256Hex([string]$Path) {
    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    $stream = [System.IO.File]::OpenRead($resolvedPath)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($sha.ComputeHash($stream) | ForEach-Object { $_.ToString("x2") }) -join "")
    }
    finally {
        $sha.Dispose()
        $stream.Dispose()
    }
}

function Get-BytesSha256Hex([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($sha.ComputeHash($Bytes) | ForEach-Object {
            $_.ToString("x2")
        }) -join "")
    }
    finally {
        $sha.Dispose()
    }
}

function Convert-InputBytesToText([byte[]]$Bytes) {
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xff -and $Bytes[1] -eq 0xfe) {
        return [System.Text.Encoding]::Unicode.GetString(
            $Bytes, 2, $Bytes.Length - 2)
    }
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xfe -and $Bytes[1] -eq 0xff) {
        return [System.Text.Encoding]::BigEndianUnicode.GetString(
            $Bytes, 2, $Bytes.Length - 2)
    }
    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xef -and
        $Bytes[1] -eq 0xbb -and $Bytes[2] -eq 0xbf) {
        return [System.Text.Encoding]::UTF8.GetString(
            $Bytes, 3, $Bytes.Length - 3)
    }
    return [System.Text.Encoding]::UTF8.GetString($Bytes)
}

function New-InputSnapshot([string]$Path, [string]$Description) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Description not found: $Path"
    }

    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    $bytes = [System.IO.File]::ReadAllBytes($resolvedPath)
    return [pscustomobject][ordered]@{
        description = $Description
        path = $resolvedPath
        sha256 = Get-BytesSha256Hex $bytes
        text = Convert-InputBytesToText $bytes
    }
}

function ConvertFrom-InputCsv($Snapshot) {
    return @(([string]$Snapshot.text) | ConvertFrom-Csv)
}

function Get-InputLines($Snapshot) {
    $reader = New-Object System.IO.StringReader ([string]$Snapshot.text)
    $lines = New-Object System.Collections.ArrayList
    try {
        while ($null -ne ($line = $reader.ReadLine())) {
            [void]$lines.Add($line)
        }
    }
    finally {
        $reader.Dispose()
    }
    return @($lines)
}

function Assert-InputSnapshotsUnchanged([object[]]$Snapshots) {
    foreach ($snapshot in $Snapshots) {
        if (-not (Test-Path -LiteralPath $snapshot.path -PathType Leaf)) {
            throw (("Metrics input changed during reporting: {0} was removed " +
                "('{1}').") -f $snapshot.description, $snapshot.path)
        }
        $currentHash = Get-FileSha256Hex ([string]$snapshot.path)
        if ($currentHash -cne [string]$snapshot.sha256) {
            throw (("Metrics input changed during reporting: {0} ('{1}').") -f
                $snapshot.description, $snapshot.path)
        }
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
    }
    finally {
        $sha.Dispose()
    }
}

function Resolve-OutputFilePath([string]$Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
}

function Assert-SafeSummaryOutputPath([string]$ResolvedPath) {
    $allowedRoot = $null
    foreach ($candidateRoot in @(
            (Join-Path $repoRoot "a"),
            (Join-Path $repoRoot "artifacts"))) {
        $candidateRoot = [System.IO.Path]::GetFullPath($candidateRoot)
        $candidatePrefix = $candidateRoot.TrimEnd('\', '/') +
            [System.IO.Path]::DirectorySeparatorChar
        if ($ResolvedPath.StartsWith(
                $candidatePrefix,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            $allowedRoot = $candidateRoot
            break
        }
    }
    if ($null -eq $allowedRoot) {
        throw ("SummaryJsonPath must resolve beneath the repository's ignored " +
            "'a' or 'artifacts' root: '$ResolvedPath'.")
    }

    $current = Split-Path -Parent $ResolvedPath
    while ($true) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (-not $item.PSIsContainer) {
                throw "SummaryJsonPath ancestor is not a directory: '$current'."
            }
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "SummaryJsonPath has a reparse-point ancestor: '$current'."
            }
        }
        if ($current.Equals(
                $allowedRoot,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            break
        }
        $parent = [System.IO.Path]::GetDirectoryName($current)
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -ceq $current) {
            throw "Could not validate SummaryJsonPath ancestry: '$ResolvedPath'."
        }
        $current = $parent
    }

    if (Test-Path -LiteralPath $ResolvedPath) {
        $outputItem = Get-Item -LiteralPath $ResolvedPath -Force
        if (($outputItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "SummaryJsonPath is a reparse point: '$ResolvedPath'."
        }
        if ($outputItem.PSIsContainer) {
            throw "SummaryJsonPath is a directory: '$ResolvedPath'."
        }
    }

    $repoPrefix = $repoRoot.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    $relativePath = $ResolvedPath.Substring($repoPrefix.Length).Replace('\', '/')
    & git -C $repoRoot check-ignore -q -- $relativePath
    if ($LASTEXITCODE -ne 0) {
        throw "SummaryJsonPath is not Git-ignored: '$ResolvedPath'."
    }
}

function Write-JsonAtomically($Value, [string]$Path) {
    $resolvedPath = Resolve-OutputFilePath $Path
    $parent = Split-Path -Parent $resolvedPath
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        throw "SummaryJsonPath parent directory does not exist: '$parent'."
    }

    $temporaryPath = "$resolvedPath.tmp-$PID-$([guid]::NewGuid().ToString('N'))"
    try {
        $Value | ConvertTo-Json -Depth 12 |
            Set-Content -LiteralPath $temporaryPath -Encoding UTF8
        Move-Item -LiteralPath $temporaryPath -Destination $resolvedPath -Force
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

$resolvedSummaryJsonPath = ""
if (-not [string]::IsNullOrWhiteSpace($SummaryJsonPath)) {
    $resolvedSummaryJsonPath = Resolve-OutputFilePath $SummaryJsonPath
    Assert-SafeSummaryOutputPath $resolvedSummaryJsonPath
    $directInputPaths = @(
        $ManifestPath,
        $VerifierResultsPath,
        $MaskAuditResultsPath,
        $ExeProductSourceManifestPath,
        $PSCommandPath) + @($FunctionMetricsPath)
    foreach ($inputPath in $directInputPaths) {
        if ([string]::IsNullOrWhiteSpace([string]$inputPath)) {
            continue
        }
        $resolvedInputCandidate = Resolve-OutputFilePath ([string]$inputPath)
        if ($resolvedSummaryJsonPath.Equals(
                $resolvedInputCandidate,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "SummaryJsonPath must not overwrite a metrics input: '$resolvedSummaryJsonPath'."
        }
    }

    # A prior successful summary must never survive a failed validation/gate.
    if (Test-Path -LiteralPath $resolvedSummaryJsonPath -PathType Leaf) {
        Remove-Item -LiteralPath $resolvedSummaryJsonPath -Force
    }
}

function Format-OtHex([uint64]$Value) {
    return ("0x{0:x8}" -f $Value)
}

function Read-CanonicalBodyRanges(
    $Row,
    [string]$Program,
    [uint64]$EntryRva) {

    $name = (Get-CsvField $Row "name").Trim()
    $identity = if ([string]::IsNullOrWhiteSpace($name)) {
        "${Program} RVA $(Format-OtHex $EntryRva)"
    } else {
        "'$name' (${Program} RVA $(Format-OtHex $EntryRva))"
    }
    $text = Get-CsvField $Row "body_ranges"
    if ([string]::IsNullOrWhiteSpace($text)) {
        throw "Function metrics row $identity is missing required body_ranges."
    }

    $size = Parse-Number (Get-CsvField $Row "size") "metrics.size"
    $bodyBytes = Parse-Number `
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
        $start = Parse-Number ("0x" + $Matches[1]) "metrics.body_ranges.start"
        $end = Parse-Number ("0x" + $Matches[2]) "metrics.body_ranges.end"
        if ($end -le $start) {
            throw "Function metrics row $identity has an empty or reversed body range."
        }
        if ($hasPrevious -and $start -lt $previousEnd) {
            throw ("Function metrics row $identity has body ranges that are not " +
                "ordered and internally disjoint.")
        }
        if ($start -lt $EntryRva -or $end -gt $envelopeEnd) {
            throw ("Function metrics row $identity has a body range outside its " +
                "half-open envelope $(Format-OtHex $EntryRva)-$(Format-OtHex $envelopeEnd).")
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
            "$(Format-OtHex $start)-$(Format-OtHex $end)")
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
                    (Format-OtHex ([uint64]$range.Start)),
                    (Format-OtHex ([uint64]$range.End)),
                    $active.Identity,
                    (Format-OtHex ([uint64]$active.Start)),
                    (Format-OtHex ([uint64]$active.End)))
            }
            if ($null -eq $active -or
                [uint64]$range.End -gt [uint64]$active.End) {
                $active = $range
            }
        }
    }
}

function Normalize-ActualStatus([string]$Value) {
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

function Normalize-ImplementationKind([string]$Value) {
    $kind = $Value.Trim().ToLowerInvariant()
    switch ($kind) {
        "cpp" { return "cpp" }
        "asm" { return "asm" }
        "toolchain-lib" { return "toolchain-lib" }
        default {
            throw ("Unknown implementation_kind '{0}'. Expected cpp, asm, or toolchain-lib." -f $Value)
        }
    }
}

function Format-Percent([uint64]$Part, [uint64]$Whole) {
    if ($Whole -eq 0) {
        return "0.00%"
    }

    return ("{0:n2}%" -f (([double]$Part / [double]$Whole) * 100.0))
}

function New-MetricKey([string]$Program, [uint64]$Rva) {
    return ("{0}|0x{1:x}" -f $Program.Trim().ToLowerInvariant(), $Rva)
}

function Get-CandidateObjectNameForSource([string]$SourcePath) {
    $normalized = $SourcePath.Trim() -replace '\\', '/'
    return (($normalized -replace '/', '_') -replace '\.cpp$', '.obj')
}

function Get-ProgramImageBase([string]$Program) {
    if ($Program -ieq "OREGON32.DLL") {
        return [uint64]0x10000000
    }

    return [uint64]0x400000
}

function Get-ManifestRva($Row, [string]$Program) {
    $rvaText = Get-CsvField $Row "original_rva"
    if (-not [string]::IsNullOrWhiteSpace($rvaText)) {
        return Parse-Number $rvaText "manifest.original_rva"
    }

    $va = Parse-Number (Get-CsvField $Row "original_va") "manifest.original_va"
    $imageBase = Get-ProgramImageBase $Program
    if ($va -lt $imageBase) {
        throw ("Manifest original_va 0x{0:x} is below the image base for {1}." -f $va, $Program)
    }

    return $va - $imageBase
}

function Get-ManifestLocator($Row, [uint64]$OriginalRva) {
    $candidateRva = (Get-CsvField $Row "candidate_rva").Trim()
    if (-not [string]::IsNullOrWhiteSpace($candidateRva)) {
        return [pscustomobject]@{
            Kind = "candidate_rva"
            Locator = $candidateRva
            Symbol = ""
            ObjectQualifier = ""
        }
    }

    $candidateVa = (Get-CsvField $Row "candidate_va").Trim()
    if (-not [string]::IsNullOrWhiteSpace($candidateVa)) {
        return [pscustomobject]@{
            Kind = "candidate_va"
            Locator = $candidateVa
            Symbol = ""
            ObjectQualifier = ""
        }
    }

    $candidateSymbol = (Get-CsvField $Row "candidate_symbol").Trim()
    if (-not [string]::IsNullOrWhiteSpace($candidateSymbol)) {
        return [pscustomobject]@{
            Kind = "candidate_symbol"
            Locator = $candidateSymbol
            Symbol = $candidateSymbol
            ObjectQualifier = (Get-CsvField $Row "candidate_object").Trim()
        }
    }

    return [pscustomobject]@{
        Kind = "original_rva"
        Locator = Format-OtHex $OriginalRva
        Symbol = ""
        ObjectQualifier = ""
    }
}

function Read-Mask([string]$MaskText, [uint64]$Size, [string]$RowName) {
    if ($Size -gt [uint64][int]::MaxValue) {
        throw "Function '$RowName' is too large to measure its mask."
    }

    $masked = New-Object bool[] ([int]$Size)
    if ([string]::IsNullOrWhiteSpace($MaskText)) {
        return $masked
    }

    foreach ($rawPart in ($MaskText -split '[;, ]+')) {
        if ([string]::IsNullOrWhiteSpace($rawPart)) {
            continue
        }

        $part = $rawPart.Trim()
        if ($part -match '^(.+)-(.+)$') {
            $start = Parse-Number $Matches[1] "manifest.mask.start"
            $end = Parse-Number $Matches[2] "manifest.mask.end"
        }
        else {
            $start = Parse-Number $part "manifest.mask.offset"
            $end = $start
        }

        if ($end -lt $start) {
            throw "Mask range '$part' for '$RowName' ends before it starts."
        }
        if ($end -ge $Size) {
            throw "Mask range '$part' for '$RowName' is outside its $Size-byte range."
        }

        for ($offset = [int]$start; $offset -le [int]$end; $offset++) {
            $masked[$offset] = $true
        }
    }

    return $masked
}

function Measure-MaskBytes([string]$MaskText, [uint64]$Size, [string]$RowName) {
    $mask = Read-Mask $MaskText $Size $RowName
    $count = [uint64]0
    foreach ($value in $mask) {
        if ($value) {
            $count++
        }
    }

    return $count
}

function New-CoverageSummary(
    [string]$Program,
    [object[]]$MetricRows,
    $JoinedByKey,
    [bool]$Strict,
    [bool]$MaskShapeAudited = $false) {
    $matchedFunctions = [uint64]0
    $matchedInstructions = [uint64]0
    $matchedBodyBytes = [uint64]0
    $totalInstructions = [uint64]0
    $totalBodyBytes = [uint64]0

    foreach ($metric in $MetricRows) {
        $instructions = Parse-Number (Get-CsvField $metric "instruction_count") "metrics.instruction_count"
        $bodyBytes = Parse-Number (Get-CsvField $metric "body_bytes") "metrics.body_bytes"
        $totalInstructions += $instructions
        $totalBodyBytes += $bodyBytes

        $rva = Parse-Number (Get-CsvField $metric "original_rva") "metrics.original_rva"
        $key = New-MetricKey $Program $rva
        if (-not $JoinedByKey.ContainsKey($key)) {
            continue
        }

        $joined = $JoinedByKey[$key]
        $covered = if ($MaskShapeAudited) {
            [bool]$joined.MaskShapeAuditedMatch
        }
        elseif ($Strict) {
            [bool]$joined.StrictMatch
        }
        else {
            [bool]$joined.MaskedMatch
        }
        if ($covered) {
            $matchedFunctions++
            $matchedInstructions += $instructions
            $matchedBodyBytes += $bodyBytes
        }
    }

    return [pscustomobject]@{
        program = $Program
        matched_functions = $matchedFunctions
        total_functions = [uint64]$MetricRows.Count
        function_pct = Format-Percent $matchedFunctions ([uint64]$MetricRows.Count)
        matched_instructions = $matchedInstructions
        total_instructions = $totalInstructions
        instruction_pct = Format-Percent $matchedInstructions $totalInstructions
        matched_body_bytes = $matchedBodyBytes
        total_body_bytes = $totalBodyBytes
        body_byte_pct = Format-Percent $matchedBodyBytes $totalBodyBytes
    }
}

function New-OverallCoverageSummary([object[]]$Rows) {
    $matchedFunctions = [uint64]0
    $totalFunctions = [uint64]0
    $matchedInstructions = [uint64]0
    $totalInstructions = [uint64]0
    $matchedBodyBytes = [uint64]0
    $totalBodyBytes = [uint64]0
    foreach ($row in $Rows) {
        $matchedFunctions += [uint64]$row.matched_functions
        $totalFunctions += [uint64]$row.total_functions
        $matchedInstructions += [uint64]$row.matched_instructions
        $totalInstructions += [uint64]$row.total_instructions
        $matchedBodyBytes += [uint64]$row.matched_body_bytes
        $totalBodyBytes += [uint64]$row.total_body_bytes
    }

    return [pscustomobject]@{
        program = "Combined"
        matched_functions = $matchedFunctions
        total_functions = $totalFunctions
        function_pct = Format-Percent $matchedFunctions $totalFunctions
        matched_instructions = $matchedInstructions
        total_instructions = $totalInstructions
        instruction_pct = Format-Percent $matchedInstructions $totalInstructions
        matched_body_bytes = $matchedBodyBytes
        total_body_bytes = $totalBodyBytes
        body_byte_pct = Format-Percent $matchedBodyBytes $totalBodyBytes
    }
}

if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    throw "Manifest file not found: $ManifestPath"
}
if (-not (Test-Path -LiteralPath $VerifierResultsPath -PathType Leaf)) {
    throw ("Verifier results file not found: {0}. Run match-functions.ps1 with " +
        "-ResultsCsvPath {0}; progress is never inferred from manifest membership.") -f $VerifierResultsPath
}
if (-not (Test-Path -LiteralPath $MaskAuditResultsPath -PathType Leaf)) {
    throw ("Mask-audit results file not found: {0}. Run audit-function-masks.ps1 with " +
        "-ResultsCsvPath {0}; the mask-shape-audited lower bound requires current audit evidence.") -f
        $MaskAuditResultsPath
}
if (-not (Test-Path -LiteralPath $ExeProductSourceManifestPath -PathType Leaf)) {
    throw "EXE Product source manifest not found: $ExeProductSourceManifestPath"
}
foreach ($path in $FunctionMetricsPath) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Function metrics file not found: $path. Generate it with tools\ghidra\otwin32\run_function_metrics.ps1."
    }
}

# Capture the exact bytes used for parsing before parsing any input. All
# reported hashes come from these immutable in-memory snapshots, and the files
# are rehashed before a success summary is emitted.
$manifestInputSnapshot = New-InputSnapshot $ManifestPath "Manifest file"
$verifierInputSnapshot =
    New-InputSnapshot $VerifierResultsPath "Verifier results file"
$maskAuditInputSnapshot =
    New-InputSnapshot $MaskAuditResultsPath "Mask-audit results file"
$productSourceInputSnapshot = New-InputSnapshot `
    $ExeProductSourceManifestPath "EXE Product source manifest"
$functionMetricInputSnapshots = @()
foreach ($path in $FunctionMetricsPath) {
    $functionMetricInputSnapshots += New-InputSnapshot `
        $path "Function metrics file"
}
$reporterInputSnapshot =
    New-InputSnapshot $PSCommandPath "Metrics reporter script"
$allStableInputSnapshots = @(
    $manifestInputSnapshot,
    $verifierInputSnapshot,
    $maskAuditInputSnapshot,
    $productSourceInputSnapshot,
    $reporterInputSnapshot) + @($functionMetricInputSnapshots)

$resolvedManifestPath = [string]$manifestInputSnapshot.path
$manifestSha256 = [string]$manifestInputSnapshot.sha256
$resolvedVerifierResultsPath = [string]$verifierInputSnapshot.path
$resolvedMaskAuditResultsPath = [string]$maskAuditInputSnapshot.path
$resolvedExeProductSourceManifestPath = [string]$productSourceInputSnapshot.path

$exeProductObjects = @{}
$exeProductSourceCount = 0
foreach ($line in @(Get-InputLines $productSourceInputSnapshot)) {
    $source = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($source) -or $source.StartsWith("#")) {
        continue
    }

    $source = $source -replace '\\', '/'
    if ($source -notmatch '^src/otwin/(?!_exact/|_recovery/|dll/).+\.cpp$') {
        throw "Invalid EXE Product source manifest entry: '$source'."
    }
    $sourcePath = Join-Path $repoRoot ($source -replace '/', '\')
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "EXE Product source does not exist: '$source'."
    }
    $objectName = Get-CandidateObjectNameForSource $source
    $key = $objectName.ToLowerInvariant()
    if ($exeProductObjects.ContainsKey($key)) {
        throw "Duplicate EXE Product candidate object '$objectName'."
    }
    $exeProductObjects[$key] = $source
    $exeProductSourceCount++
}
if ($exeProductSourceCount -eq 0) {
    throw "EXE Product source manifest is empty: $ExeProductSourceManifestPath"
}

$metrics = @()
foreach ($snapshot in $functionMetricInputSnapshots) {
    $metrics += @(ConvertFrom-InputCsv $snapshot)
}
if (-not $IncludeNonText) {
    $metrics = @($metrics | Where-Object {
        [string]::IsNullOrWhiteSpace((Get-CsvField $_ "block")) -or
            (Get-CsvField $_ "block") -ieq ".text"
    })
}
if ($metrics.Count -eq 0) {
    throw "The selected function metrics files contain no rows."
}

$metricsByKey = @{}
$metricBodyOwnershipByKey = @{}
$ownedBodyRanges = New-Object System.Collections.Generic.List[object]
foreach ($row in $metrics) {
    $program = (Get-CsvField $row "program").Trim()
    if ([string]::IsNullOrWhiteSpace($program)) {
        throw "A function metrics row is missing its program."
    }
    $rva = Parse-Number (Get-CsvField $row "original_rva") "metrics.original_rva"
    $key = New-MetricKey $program $rva
    if ($metricsByKey.ContainsKey($key)) {
        throw ("Duplicate function metrics row for {0} RVA 0x{1:x}." -f $program, $rva)
    }
    $bodyOwnership = Read-CanonicalBodyRanges $row $program $rva
    $metricsByKey[$key] = $row
    $metricBodyOwnershipByKey[$key] = $bodyOwnership
    $metricIdentity = "'$((Get-CsvField $row "name").Trim())' at $(Format-OtHex $rva)"
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
}
Assert-NoCrossFunctionBodyOverlap ([object[]]$ownedBodyRanges)

$manifest = @(ConvertFrom-InputCsv $manifestInputSnapshot)
if ($manifest.Count -eq 0) {
    throw "Manifest has no function rows: $ManifestPath"
}

$manifestByKey = @{}
foreach ($row in $manifest) {
    $program = (Get-CsvField $row "program").Trim()
    if ([string]::IsNullOrWhiteSpace($program)) {
        $program = $ManifestProgram
    }
    $rva = Get-ManifestRva $row $program
    $key = New-MetricKey $program $rva
    if ($manifestByKey.ContainsKey($key)) {
        throw ("Duplicate manifest row for {0} RVA 0x{1:x}." -f $program, $rva)
    }
    if (-not $metricsByKey.ContainsKey($key)) {
        throw ("Manifest row '{0}' ({1} RVA 0x{2:x}) is missing from function metrics." -f
            (Get-CsvField $row "name"), $program, $rva)
    }
    $manifestByKey[$key] = $row
}

$maskProvenanceRows = @(ConvertFrom-InputCsv $maskAuditInputSnapshot)
if ($maskProvenanceRows.Count -eq 0) {
    throw "Mask-audit results contain no rows: $MaskAuditResultsPath"
}
$requiredMaskAuditColumns = @(
    "name", "program", "original_rva", "function_size", "expected_status",
    "implementation_kind", "mask", "range_start", "range_end", "range_length",
    "classification", "validated_bytes", "partial_known_bytes", "unexplained_bytes",
    "full_function_mask"
)
foreach ($column in $requiredMaskAuditColumns) {
    if ($null -eq $maskProvenanceRows[0].PSObject.Properties[$column]) {
        throw "Mask-audit results are missing required column '$column'."
    }
}

$maskAuditGroups = @{}
foreach ($auditRow in $maskProvenanceRows) {
    $program = (Get-CsvField $auditRow "program").Trim()
    if ([string]::IsNullOrWhiteSpace($program)) {
        $program = $ManifestProgram
    }
    $rva = Parse-Number (Get-CsvField $auditRow "original_rva") "mask_audit.original_rva"
    $key = New-MetricKey $program $rva
    if (-not $manifestByKey.ContainsKey($key)) {
        throw ("Mask-audit row '{0}' ({1} RVA 0x{2:x}) has no manifest row." -f
            (Get-CsvField $auditRow "name"), $program, $rva)
    }
    if (-not $maskAuditGroups.ContainsKey($key)) {
        $maskAuditGroups[$key] = @()
    }
    $maskAuditGroups[$key] = @($maskAuditGroups[$key]) + $auditRow
}

$maskAuditCleanByKey = @{}
foreach ($key in $manifestByKey.Keys) {
    $manifestRow = $manifestByKey[$key]
    $manifestName = (Get-CsvField $manifestRow "name").Trim()
    $manifestProgram = (Get-CsvField $manifestRow "program").Trim()
    if ([string]::IsNullOrWhiteSpace($manifestProgram)) {
        $manifestProgram = $ManifestProgram
    }
    $manifestSize = Parse-Number (Get-CsvField $manifestRow "size") "manifest.size"
    $manifestMaskText = (Get-CsvField $manifestRow "mask").Trim()
    $manifestMask = Read-Mask $manifestMaskText $manifestSize $manifestName
    $auditGroup = @()
    if ($maskAuditGroups.ContainsKey($key)) {
        $auditGroup = @($maskAuditGroups[$key])
    }

    $manifestMaskedByteCount = [uint64]0
    foreach ($isMasked in $manifestMask) {
        if ($isMasked) {
            $manifestMaskedByteCount++
        }
    }
    if ($manifestMaskedByteCount -eq 0) {
        if ($auditGroup.Count -ne 0) {
            throw "Mask-audit results contain ranges for maskless manifest row '$manifestName'."
        }
        $maskAuditCleanByKey[$key] = $true
        continue
    }
    if ($auditGroup.Count -eq 0) {
        throw "Mask-audit results are missing masked manifest row '$manifestName'."
    }

    $auditedMask = New-Object bool[] ([int]$manifestSize)
    $rowIsClean = $true
    foreach ($auditRow in $auditGroup) {
        $auditName = (Get-CsvField $auditRow "name").Trim()
        if ($auditName -cne $manifestName) {
            throw "Mask-audit name '$auditName' does not match manifest name '$manifestName' at $key."
        }
        $auditProgram = (Get-CsvField $auditRow "program").Trim()
        if ($auditProgram -cne $manifestProgram) {
            throw "Mask-audit program '$auditProgram' does not match manifest program '$manifestProgram' for '$manifestName'."
        }
        $auditSize = Parse-Number (Get-CsvField $auditRow "function_size") "mask_audit.function_size"
        if ($auditSize -ne $manifestSize) {
            throw "Mask-audit function_size $auditSize does not match manifest size $manifestSize for '$manifestName'."
        }
        $auditMaskText = (Get-CsvField $auditRow "mask").Trim()
        if ($auditMaskText -cne $manifestMaskText) {
            throw "Mask-audit mask does not exactly match the manifest mask for '$manifestName'."
        }
        if ((Get-CsvField $auditRow "expected_status").Trim() -cne
            (Get-CsvField $manifestRow "expected_status").Trim()) {
            throw "Mask-audit expected_status does not match the manifest for '$manifestName'."
        }
        if ((Get-CsvField $auditRow "implementation_kind").Trim() -cne
            (Get-CsvField $manifestRow "implementation_kind").Trim()) {
            throw "Mask-audit implementation_kind does not match the manifest for '$manifestName'."
        }

        $rangeStart = Parse-Number (Get-CsvField $auditRow "range_start") "mask_audit.range_start"
        $rangeEnd = Parse-Number (Get-CsvField $auditRow "range_end") "mask_audit.range_end"
        $rangeLength = Parse-Number (Get-CsvField $auditRow "range_length") "mask_audit.range_length"
        if ($rangeEnd -lt $rangeStart -or $rangeEnd -ge $manifestSize -or
            $rangeLength -ne ($rangeEnd - $rangeStart + 1)) {
            throw "Mask-audit range $rangeStart-$rangeEnd is invalid for '$manifestName'."
        }
        for ($offset = [int]$rangeStart; $offset -le [int]$rangeEnd; $offset++) {
            if ($auditedMask[$offset]) {
                throw "Mask-audit ranges overlap at offset $offset for '$manifestName'."
            }
            $auditedMask[$offset] = $true
        }

        $validatedBytes = Parse-Number (Get-CsvField $auditRow "validated_bytes") "mask_audit.validated_bytes"
        $partialBytes = Parse-Number (Get-CsvField $auditRow "partial_known_bytes") "mask_audit.partial_known_bytes"
        $unexplainedBytes = Parse-Number (Get-CsvField $auditRow "unexplained_bytes") "mask_audit.unexplained_bytes"
        if (($validatedBytes + $partialBytes + $unexplainedBytes) -ne $rangeLength) {
            throw "Mask-audit byte classifications do not sum to range_length for '$manifestName'."
        }

        $classification = (Get-CsvField $auditRow "classification").Trim()
        if ($classification -notin @("full_known_address_operand", "partial_known_operand", "unexplained")) {
            throw "Unknown mask-audit classification '$classification' for '$manifestName'."
        }
        $fullFunctionMask = Parse-Boolean (Get-CsvField $auditRow "full_function_mask") "mask_audit.full_function_mask"
        $expectedFullFunctionMask = $manifestMaskedByteCount -eq $manifestSize
        if ($fullFunctionMask -ne $expectedFullFunctionMask) {
            throw "Mask-audit full_function_mask is inconsistent with the manifest mask for '$manifestName'."
        }
        $expectedClassification = if ($fullFunctionMask) {
            "unexplained"
        }
        elseif ($validatedBytes -eq $rangeLength) {
            "full_known_address_operand"
        }
        elseif (($validatedBytes + $partialBytes) -gt 0) {
            "partial_known_operand"
        }
        else {
            "unexplained"
        }
        if ($classification -cne $expectedClassification) {
            throw ("Mask-audit classification '{0}' is inconsistent with its byte counts; expected '{1}' for '{2}'." -f
                $classification, $expectedClassification, $manifestName)
        }
        if ($classification -ne "full_known_address_operand" -or $fullFunctionMask) {
            $rowIsClean = $false
        }
    }

    for ($offset = 0; $offset -lt $manifestMask.Length; $offset++) {
        if ($manifestMask[$offset] -ne $auditedMask[$offset]) {
            throw "Mask-audit ranges do not exactly cover the manifest mask for '$manifestName'."
        }
    }
    $maskAuditCleanByKey[$key] = $rowIsClean
}

$verifierResults = @(ConvertFrom-InputCsv $verifierInputSnapshot)
if ($verifierResults.Count -eq 0) {
    throw "Verifier results contain no rows: $VerifierResultsPath"
}

$exampleResult = $verifierResults[0]
$resultColumns = @{
    SchemaVersion = Resolve-CsvColumn $exampleResult "result schema version" @("result_schema_version")
    ManifestSha256 = Resolve-CsvColumn $exampleResult "manifest SHA-256" @("manifest_sha256")
    Status = Resolve-CsvColumn $exampleResult "actual status" @("actual_status", "status", "match_status", "result")
    ExpectedStatus = Resolve-CsvColumn $exampleResult "expected status" @("expected_status")
    Name = Resolve-CsvColumn $exampleResult "function name" @("name", "function_name", "symbol")
    Program = Resolve-CsvColumn $exampleResult "program" @("program", "target_program", "image")
    Rva = Resolve-CsvColumn $exampleResult "original RVA" @("original_rva", "rva")
    OriginalPath = Resolve-CsvColumn $exampleResult "original PE path" @("original_path")
    OriginalSha256 = Resolve-CsvColumn $exampleResult "original PE SHA-256" @("original_file_sha256")
    Size = Resolve-CsvColumn $exampleResult "function size" @("size", "function_size", "range_size")
    ImplementationKind = Resolve-CsvColumn $exampleResult "implementation kind" @("implementation_kind", "implementation", "source_kind", "code_kind")
    CandidateDll = Resolve-CsvColumn $exampleResult "candidate DLL selector" @("candidate_dll")
    CandidatePath = Resolve-CsvColumn $exampleResult "candidate PE path" @("candidate_path")
    CandidateSha256 = Resolve-CsvColumn $exampleResult "candidate PE SHA-256" @("candidate_file_sha256")
    CandidateMapPath = Resolve-CsvColumn $exampleResult "candidate map path" @("candidate_map_path")
    CandidateMapSha256 = Resolve-CsvColumn $exampleResult "candidate map SHA-256" @("candidate_map_sha256")
    CandidateLocatorKind = Resolve-CsvColumn $exampleResult "candidate locator kind" @("candidate_locator_kind")
    CandidateLocator = Resolve-CsvColumn $exampleResult "candidate locator" @("candidate_locator")
    CandidateSymbol = Resolve-CsvColumn $exampleResult "candidate symbol" @("candidate_symbol")
    CandidateObjectQualifier = Resolve-CsvColumn $exampleResult "candidate object qualifier" @("candidate_object_qualifier")
    CandidateObject = Resolve-CsvColumn $exampleResult "resolved candidate object" @("candidate_object")
    Mask = Resolve-CsvColumn $exampleResult "mask text" @("mask")
    MaskBytes = Resolve-CsvColumn $exampleResult "masked-byte count" @("mask_bytes", "masked_bytes")
    ComparedBytes = Resolve-CsvColumn $exampleResult "compared-byte count" @("compared_bytes", "evidence_bytes")
    RawMatch = Resolve-CsvColumn $exampleResult "raw-match state" @("raw_match", "is_raw_match")
    MaskShapeValid = Resolve-CsvColumn $exampleResult "paired mask-shape state" @("mask_shape_valid")
    MaskedOperandShapeError = Resolve-CsvColumn $exampleResult "masked operand-shape diagnostic" @("masked_operand_shape_error")
    MaskedImportIdentityError = Resolve-CsvColumn $exampleResult "masked import-identity diagnostic" @("masked_import_identity_error")
}

$fileHashCache = @{}
function Assert-CurrentFileHash(
    [string]$Path,
    [string]$ExpectedSha256,
    [string]$Description,
    [bool]$AllowEmpty) {
    $trimmedPath = $Path.Trim()
    $trimmedHash = $ExpectedSha256.Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($trimmedPath)) {
        if (-not $AllowEmpty -or -not [string]::IsNullOrWhiteSpace($trimmedHash)) {
            throw "$Description path/hash metadata is incomplete."
        }
        return
    }
    if ([string]::IsNullOrWhiteSpace($trimmedHash)) {
        throw "$Description SHA-256 metadata is missing for '$trimmedPath'."
    }
    if (-not (Test-Path -LiteralPath $trimmedPath -PathType Leaf)) {
        throw "$Description file no longer exists: $trimmedPath"
    }

    $resolvedPath = (Resolve-Path -LiteralPath $trimmedPath).Path
    if (-not $fileHashCache.ContainsKey($resolvedPath)) {
        $fileHashCache[$resolvedPath] = Get-FileSha256Hex $resolvedPath
    }
    $actualHash = [string]$fileHashCache[$resolvedPath]
    if ($actualHash -cne $trimmedHash) {
        throw ("Stale verifier results: {0} SHA-256 changed for '{1}' (recorded {2}, current {3})." -f
            $Description, $resolvedPath, $trimmedHash, $actualHash)
    }
}

function Assert-ValidatedFilesUnchanged {
    foreach ($resolvedPath in @($fileHashCache.Keys)) {
        if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
            throw "Verifier-bound file changed during metrics reporting: '$resolvedPath' was removed."
        }
        $currentHash = Get-FileSha256Hex $resolvedPath
        if ($currentHash -cne [string]$fileHashCache[$resolvedPath]) {
            throw "Verifier-bound file changed during metrics reporting: '$resolvedPath'."
        }
    }
}

$resultsByKey = @{}
foreach ($result in $verifierResults) {
    $schemaVersion = Parse-Number (Get-CsvField $result $resultColumns.SchemaVersion) "verifier.result_schema_version"
    if ($schemaVersion -ne 4) {
        throw "Unsupported verifier result_schema_version '$schemaVersion'; expected 4."
    }
    $resultManifestSha256 = (Get-CsvField $result $resultColumns.ManifestSha256).Trim().ToLowerInvariant()
    if ($resultManifestSha256 -cne $manifestSha256) {
        throw ("Stale verifier results: manifest SHA-256 changed (recorded {0}, current {1})." -f
            $resultManifestSha256, $manifestSha256)
    }
    Assert-CurrentFileHash `
        (Get-CsvField $result $resultColumns.OriginalPath) `
        (Get-CsvField $result $resultColumns.OriginalSha256) `
        "original PE" `
        $false
    Assert-CurrentFileHash `
        (Get-CsvField $result $resultColumns.CandidatePath) `
        (Get-CsvField $result $resultColumns.CandidateSha256) `
        "candidate PE" `
        $false
    Assert-CurrentFileHash `
        (Get-CsvField $result $resultColumns.CandidateMapPath) `
        (Get-CsvField $result $resultColumns.CandidateMapSha256) `
        "candidate map" `
        $true

    $program = (Get-CsvField $result $resultColumns.Program).Trim()
    if ([string]::IsNullOrWhiteSpace($program)) {
        $program = $ManifestProgram
    }
    $rva = Parse-Number (Get-CsvField $result $resultColumns.Rva) "verifier.original_rva"
    $key = New-MetricKey $program $rva
    if ($resultsByKey.ContainsKey($key)) {
        throw ("Duplicate verifier result for {0} RVA 0x{1:x}." -f $program, $rva)
    }
    if (-not $manifestByKey.ContainsKey($key)) {
        throw ("Verifier result '{0}' ({1} RVA 0x{2:x}) has no manifest row." -f
            (Get-CsvField $result $resultColumns.Name), $program, $rva)
    }
    $resultsByKey[$key] = $result
}

if ($resultsByKey.Count -ne $manifestByKey.Count) {
    $missing = @($manifestByKey.Keys | Where-Object { -not $resultsByKey.ContainsKey($_) })
    if ($missing.Count -gt 0) {
        $examples = @($missing | Select-Object -First 5 | ForEach-Object {
            Get-CsvField $manifestByKey[$_] "name"
        })
        throw ("Verifier results are missing {0} of {1} manifest rows. Examples: {2}." -f
            $missing.Count, $manifestByKey.Count, ($examples -join ", "))
    }

    throw ("Verifier result count {0} does not equal manifest row count {1}." -f
        $resultsByKey.Count, $manifestByKey.Count)
}

$joinedByKey = @{}
foreach ($key in $manifestByKey.Keys) {
    if (-not $resultsByKey.ContainsKey($key)) {
        throw "Verifier results are missing manifest key '$key'."
    }

    $manifestRow = $manifestByKey[$key]
    $result = $resultsByKey[$key]
    $manifestName = (Get-CsvField $manifestRow "name").Trim()
    $manifestRowProgram = (Get-CsvField $manifestRow "program").Trim()
    if ([string]::IsNullOrWhiteSpace($manifestRowProgram)) {
        $manifestRowProgram = $ManifestProgram
    }
    $resultName = (Get-CsvField $result $resultColumns.Name).Trim()
    if ($resultName -cne $manifestName) {
        throw ("Verifier result name '{0}' does not match manifest name '{1}' at {2}." -f
            $resultName, $manifestName, $key)
    }

    $manifestSize = Parse-Number (Get-CsvField $manifestRow "size") "manifest.size"
    $resultSize = Parse-Number (Get-CsvField $result $resultColumns.Size) "verifier.size"
    if ($resultSize -ne $manifestSize) {
        throw ("Verifier size {0} does not match manifest size {1} for '{2}'." -f
            $resultSize, $manifestSize, $manifestName)
    }

    $metricRow = $metricsByKey[$key]
    $metricRangeSize = Parse-Number (Get-CsvField $metricRow "size") "metrics.size"
    $metricBodyBytes = Parse-Number (Get-CsvField $metricRow "body_bytes") "metrics.body_bytes"
    $requiredMetricBytes = [uint64][System.Math]::Max(
        [double]$metricRangeSize,
        [double]$metricBodyBytes)
    if ($manifestSize -lt $requiredMetricBytes) {
        throw ("Manifest range {0} is smaller than the function-metrics range/body requirement {1} for '{2}'; whole-function coverage cannot be credited." -f
            $manifestSize, $requiredMetricBytes, $manifestName)
    }

    $manifestMaskText = (Get-CsvField $manifestRow "mask").Trim()
    $resultMaskText = (Get-CsvField $result $resultColumns.Mask).Trim()
    if ($resultMaskText -cne $manifestMaskText) {
        throw "Verifier mask text does not exactly match the manifest mask for '$manifestName'."
    }
    $manifestMaskBytes = Measure-MaskBytes $manifestMaskText $manifestSize $manifestName
    $resultMaskBytes = Parse-Number (Get-CsvField $result $resultColumns.MaskBytes) "verifier.mask_bytes"
    $resultComparedBytes = Parse-Number (Get-CsvField $result $resultColumns.ComparedBytes) "verifier.compared_bytes"
    if ($resultMaskBytes -ne $manifestMaskBytes) {
        throw ("Verifier mask_bytes {0} does not match the manifest's {1} masked bytes for '{2}'." -f
            $resultMaskBytes, $manifestMaskBytes, $manifestName)
    }
    if ($resultComparedBytes -ne ($manifestSize - $manifestMaskBytes)) {
        throw ("Verifier compared_bytes {0} does not equal size minus mask_bytes ({1}) for '{2}'." -f
            $resultComparedBytes, ($manifestSize - $manifestMaskBytes), $manifestName)
    }

    $manifestExpectedStatus = (Get-CsvField $manifestRow "expected_status").Trim().ToLowerInvariant()
    $resultExpectedStatus = (Get-CsvField $result $resultColumns.ExpectedStatus).Trim().ToLowerInvariant()
    if ($resultExpectedStatus -cne $manifestExpectedStatus) {
        throw ("Verifier expected_status '{0}' does not match manifest value '{1}' for '{2}'." -f
            $resultExpectedStatus, $manifestExpectedStatus, $manifestName)
    }

    $manifestCandidateDll = (Get-CsvField $manifestRow "candidate_dll").Trim().ToLowerInvariant()
    $resultCandidateDll = (Get-CsvField $result $resultColumns.CandidateDll).Trim().ToLowerInvariant()
    if ($resultCandidateDll -cne $manifestCandidateDll) {
        throw ("Verifier candidate_dll '{0}' does not match manifest value '{1}' for '{2}'." -f
            $resultCandidateDll, $manifestCandidateDll, $manifestName)
    }
    $originalRva = Get-ManifestRva $manifestRow $manifestRowProgram
    $manifestLocator = Get-ManifestLocator $manifestRow $originalRva
    $resultLocatorKind = (Get-CsvField $result $resultColumns.CandidateLocatorKind).Trim()
    $resultLocator = (Get-CsvField $result $resultColumns.CandidateLocator).Trim()
    $resultCandidateSymbol = (Get-CsvField $result $resultColumns.CandidateSymbol).Trim()
    $resultObjectQualifier = (Get-CsvField $result $resultColumns.CandidateObjectQualifier).Trim()
    if ($resultLocatorKind -cne [string]$manifestLocator.Kind) {
        throw "Verifier candidate_locator_kind does not match the manifest locator for '$manifestName'."
    }
    if ($resultLocator -cne [string]$manifestLocator.Locator) {
        throw "Verifier candidate_locator does not exactly match the manifest locator for '$manifestName'."
    }
    if ($resultCandidateSymbol -cne [string]$manifestLocator.Symbol) {
        throw "Verifier candidate_symbol does not exactly match the manifest for '$manifestName'."
    }
    if ($resultObjectQualifier -cne [string]$manifestLocator.ObjectQualifier) {
        throw "Verifier candidate_object_qualifier does not exactly match the manifest for '$manifestName'."
    }

    $actualStatus = Normalize-ActualStatus (Get-CsvField $result $resultColumns.Status)
    $implementationKind = Normalize-ImplementationKind (Get-CsvField $result $resultColumns.ImplementationKind)
    $manifestImplementationKind = Normalize-ImplementationKind (
        Get-CsvField $manifestRow "implementation_kind")
    if ($implementationKind -cne $manifestImplementationKind) {
        throw ("Verifier implementation_kind '{0}' does not match manifest value '{1}' for '{2}'." -f
            $implementationKind, $manifestImplementationKind, $manifestName)
    }
    $rawMatch = Parse-Boolean (Get-CsvField $result $resultColumns.RawMatch) "verifier.raw_match"
    $maskedMatch = $actualStatus -eq "match"
    $maskShapeValid = Parse-Boolean (
        Get-CsvField $result $resultColumns.MaskShapeValid) "verifier.mask_shape_valid"
    $maskedOperandShapeError = (
        Get-CsvField $result $resultColumns.MaskedOperandShapeError).Trim()
    $maskedImportIdentityError = (
        Get-CsvField $result $resultColumns.MaskedImportIdentityError).Trim()
    if ($maskShapeValid -and -not [string]::IsNullOrWhiteSpace($maskedOperandShapeError)) {
        throw "Verifier reports mask_shape_valid=true with a masked operand-shape diagnostic for '$manifestName'."
    }
    if (-not $maskShapeValid -and [string]::IsNullOrWhiteSpace($maskedOperandShapeError)) {
        throw "Verifier reports mask_shape_valid=false without a masked operand-shape diagnostic for '$manifestName'."
    }
    if (-not $maskShapeValid -and
        ($actualStatus -ne "mismatch" -or $manifestMaskBytes -eq 0)) {
        throw "Verifier reports inconsistent paired mask-shape metadata for '$manifestName'."
    }
    if ($actualStatus -eq "match" -and -not $maskShapeValid) {
        throw "Verifier reports an impossible match with invalid paired mask shape for '$manifestName'."
    }
    if (-not [string]::IsNullOrWhiteSpace($maskedImportIdentityError) -and
        -not $maskedImportIdentityError.StartsWith(
            "Masked import ", [System.StringComparison]::Ordinal)) {
        throw "Verifier reports an invalid masked_import_identity_error for '$manifestName'."
    }
    if (-not [string]::IsNullOrWhiteSpace($maskedImportIdentityError) -and
        ($actualStatus -ne "mismatch" -or $manifestMaskBytes -eq 0)) {
        throw "Verifier reports inconsistent masked import-identity metadata for '$manifestName'."
    }
    if (-not [string]::IsNullOrWhiteSpace($maskedImportIdentityError) -and
        $maskedImportIdentityError -cne $maskedOperandShapeError) {
        throw "Verifier masked import and operand-shape diagnostics disagree for '$manifestName'."
    }
    $pairedMaskShapeDefect = -not $maskShapeValid -and
        -not [string]::IsNullOrWhiteSpace($maskedOperandShapeError)
    if ($rawMatch -and $actualStatus -eq "mismatch" -and
        -not $pairedMaskShapeDefect) {
        throw ("Verifier reports raw_match=true but actual_status='mismatch' " +
            "without a diagnosed invalid paired mask for '$manifestName'.")
    }
    if ($actualStatus -eq "match" -and $manifestMaskBytes -eq 0 -and -not $rawMatch) {
        throw "Verifier reports an impossible maskless match with raw_match=false for '$manifestName'."
    }

    $resolvedCandidateObject = (Get-CsvField $result $resultColumns.CandidateObject).Trim()
    $productReachable = $true
    if ($implementationKind -eq "cpp" -and $manifestRowProgram -ieq $ExeProductProgram) {
        $productReachable = -not [string]::IsNullOrWhiteSpace($resolvedCandidateObject) -and
            $exeProductObjects.ContainsKey($resolvedCandidateObject.ToLowerInvariant())
    }
    $policyCompliant = ($implementationKind -eq "cpp" -or
        $implementationKind -eq "toolchain-lib") -and $productReachable
    $evidenceBearing = $resultComparedBytes -gt 0
    $manifestAccepted = $manifestExpectedStatus -eq "match"
    $strictMatch = $maskedMatch -and $manifestAccepted -and
        $policyCompliant -and $evidenceBearing
    $maskShapeAudited = [bool]$maskAuditCleanByKey[$key] -and $maskShapeValid
    $maskShapeAuditedMatch = $strictMatch -and $maskShapeAudited

    $joinedByKey[$key] = [pscustomobject]@{
        Name = $manifestName
        Program = $manifestRowProgram
        MaskedMatch = $maskedMatch
        StrictMatch = $strictMatch
        MaskShapeAudited = $maskShapeAudited
        CandidateMaskShapeValid = $maskShapeValid
        MaskedOperandShapeError = $maskedOperandShapeError
        MaskShapeAuditedMatch = $maskShapeAuditedMatch
        RawMatch = $rawMatch
        ActualStatus = $actualStatus
        ImplementationKind = $implementationKind
        PolicyCompliant = $policyCompliant
        ManifestAccepted = $manifestAccepted
        ProductReachable = $productReachable
        CandidateObject = $resolvedCandidateObject
        EvidenceBearing = $evidenceBearing
        Size = $manifestSize
        MaskBytes = $manifestMaskBytes
        ComparedBytes = $resultComparedBytes
    }
}

$programGroups = @($metrics |
    Group-Object { (Get-CsvField $_ "program").Trim() } |
    Sort-Object Name)

$maskedCoverage = @()
$strictCoverage = @()
$maskShapeAuditedCoverage = @()
foreach ($group in $programGroups) {
    $maskedCoverage += New-CoverageSummary $group.Name @($group.Group) $joinedByKey $false $false
    $strictCoverage += New-CoverageSummary $group.Name @($group.Group) $joinedByKey $true $false
    $maskShapeAuditedCoverage += New-CoverageSummary $group.Name @($group.Group) $joinedByKey $true $true
}
$maskedCoverage += New-OverallCoverageSummary $maskedCoverage
$strictCoverage += New-OverallCoverageSummary $strictCoverage
$maskShapeAuditedCoverage += New-OverallCoverageSummary $maskShapeAuditedCoverage

$matchedRows = @($joinedByKey.Values | Where-Object { $_.MaskedMatch })
$maskedMatchedRows = @($matchedRows | Where-Object { $_.MaskBytes -gt 0 })
$maskedMatchRangeBytes = [uint64]0
$acceptedMaskBytes = [uint64]0
$acceptedComparedBytes = [uint64]0
foreach ($row in $matchedRows) {
    $maskedMatchRangeBytes += [uint64]$row.Size
    $acceptedMaskBytes += [uint64]$row.MaskBytes
    $acceptedComparedBytes += [uint64]$row.ComparedBytes
}

$allMaskRows = @($joinedByKey.Values | Where-Object { $_.MaskBytes -gt 0 })
$allRangeBytes = [uint64]0
$allMaskBytes = [uint64]0
foreach ($row in $joinedByKey.Values) {
    $allRangeBytes += [uint64]$row.Size
    $allMaskBytes += [uint64]$row.MaskBytes
}

$rawMatches = @($matchedRows | Where-Object { $_.RawMatch })
$zeroEvidenceRows = @($joinedByKey.Values | Where-Object { -not $_.EvidenceBearing })
$asmMatches = @($matchedRows | Where-Object { $_.ImplementationKind -eq "asm" })
$cppMatches = @($matchedRows | Where-Object {
    $_.ImplementationKind -eq "cpp" -and $_.EvidenceBearing -and $_.ManifestAccepted
})
$toolchainMatches = @($matchedRows | Where-Object {
    $_.ImplementationKind -eq "toolchain-lib" -and $_.EvidenceBearing -and $_.ManifestAccepted
})
$productUnreachableCppMatches = @($cppMatches | Where-Object { -not $_.ProductReachable })
$matchedWipRows = @($matchedRows | Where-Object { -not $_.ManifestAccepted })
$maskShapeCleanRows = @($joinedByKey.Values | Where-Object {
    $_.MaskBytes -gt 0 -and $_.MaskShapeAudited
})
$maskShapeDebtRows = @($joinedByKey.Values | Where-Object {
    $_.MaskBytes -gt 0 -and -not $_.MaskShapeAudited
})

$maskAuditRows = @()
$joinedGroups = @($joinedByKey.Values | Group-Object Program | Sort-Object Name)
foreach ($group in $joinedGroups) {
    $groupMatches = @($group.Group | Where-Object { $_.MaskedMatch })
    $groupMaskedMatches = @($groupMatches | Where-Object { $_.MaskBytes -gt 0 })
    $groupRawMatches = @($groupMatches | Where-Object { $_.RawMatch })
    $groupRangeBytes = [uint64]0
    $groupMaskBytes = [uint64]0
    foreach ($row in $groupMatches) {
        $groupRangeBytes += [uint64]$row.Size
        $groupMaskBytes += [uint64]$row.MaskBytes
    }
    $maskAuditRows += [pscustomobject]@{
        program = $group.Name
        matched_rows = [uint64]$groupMatches.Count
        raw_matches = [uint64]$groupRawMatches.Count
        masked_rows = [uint64]$groupMaskedMatches.Count
        mask_bytes = $groupMaskBytes
        matched_range_bytes = $groupRangeBytes
        mask_pct = Format-Percent $groupMaskBytes $groupRangeBytes
    }
}
$maskAuditRows += [pscustomobject]@{
    program = "Combined"
    matched_rows = [uint64]$matchedRows.Count
    raw_matches = [uint64]$rawMatches.Count
    masked_rows = [uint64]$maskedMatchedRows.Count
    mask_bytes = $acceptedMaskBytes
    matched_range_bytes = $maskedMatchRangeBytes
    mask_pct = Format-Percent $acceptedMaskBytes $maskedMatchRangeBytes
}

Write-Host ""
Write-Host "OTWIN verifier-backed decompilation progress"
Write-Host ("Manifest:         {0}" -f (Resolve-Path -LiteralPath $ManifestPath).Path)
Write-Host ("Verifier results: {0}" -f $resolvedVerifierResultsPath)
Write-Host ("Mask audit:       {0}" -f $resolvedMaskAuditResultsPath)
Write-Host ("EXE Product graph:{0}" -f $resolvedExeProductSourceManifestPath)
Write-Host ("Product sources/objects: {0}/{0}" -f $exeProductSourceCount)
Write-Host ("Validated result rows: {0}/{0}" -f $manifest.Count)
Write-Host ("Actual verifier status: match={0}, mismatch={1}, error={2}" -f
    @($joinedByKey.Values | Where-Object { $_.ActualStatus -eq "match" }).Count,
    @($joinedByKey.Values | Where-Object { $_.ActualStatus -eq "mismatch" }).Count,
    @($joinedByKey.Values | Where-Object { $_.ActualStatus -eq "error" }).Count)

Write-Host ""
Write-Host "Provisional masked coverage (actual verifier status; paired operand shape and HIGHLOW import identity checked; other masked targets not proven)"
$maskedCoverage |
    Select-Object program,
        @{Name="functions"; Expression={ "{0}/{1}" -f $_.matched_functions, $_.total_functions }}, function_pct,
        @{Name="instructions"; Expression={ "{0}/{1}" -f $_.matched_instructions, $_.total_instructions }}, instruction_pct,
        @{Name="body_bytes"; Expression={ "{0}/{1}" -f $_.matched_body_bytes, $_.total_body_bytes }}, body_byte_pct |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Policy-compliant provisional masked coverage (accepted Product-reachable cpp + toolchain-lib; WIP, asm, and zero-byte comparisons excluded)"
$strictCoverage |
    Select-Object program,
        @{Name="functions"; Expression={ "{0}/{1}" -f $_.matched_functions, $_.total_functions }}, function_pct,
        @{Name="instructions"; Expression={ "{0}/{1}" -f $_.matched_instructions, $_.total_instructions }}, instruction_pct,
        @{Name="body_bytes"; Expression={ "{0}/{1}" -f $_.matched_body_bytes, $_.total_body_bytes }}, body_byte_pct |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Mask-shape-audited lower bound (accepted Product-reachable cpp + toolchain-lib; WIP and mask-debt rows excluded)"
Write-Host "Audit scope: original-image operand evidence plus same-offset candidate HIGHLOW/rel32 class; imports are identity-checked, non-import rel32/data target identity remains provisional."
$maskShapeAuditedCoverage |
    Select-Object program,
        @{Name="functions"; Expression={ "{0}/{1}" -f $_.matched_functions, $_.total_functions }}, function_pct,
        @{Name="instructions"; Expression={ "{0}/{1}" -f $_.matched_instructions, $_.total_instructions }}, instruction_pct,
        @{Name="body_bytes"; Expression={ "{0}/{1}" -f $_.matched_body_bytes, $_.total_body_bytes }}, body_byte_pct |
    Format-Table -AutoSize
Write-Host ("Masked manifest rows by audit shape: clean={0}, debt={1}" -f
    $maskShapeCleanRows.Count, $maskShapeDebtRows.Count)

Write-Host ""
Write-Host "Accepted implementation breakdown"
@(
    [pscustomobject]@{ implementation = "Product-reachable cpp"; matched_rows = ($cppMatches.Count - $productUnreachableCppMatches.Count); policy_covered = $true }
    [pscustomobject]@{ implementation = "Product-unreachable cpp"; matched_rows = $productUnreachableCppMatches.Count; policy_covered = $false }
    [pscustomobject]@{ implementation = "toolchain-lib"; matched_rows = $toolchainMatches.Count; policy_covered = $true }
    [pscustomobject]@{ implementation = "asm"; matched_rows = $asmMatches.Count; policy_covered = $false }
) | Format-Table -AutoSize
Write-Host ("Zero-byte comparison rows: {0} (never counted as policy coverage)" -f $zeroEvidenceRows.Count)
Write-Host ("Matched EXE C++ rows outside the Product graph: {0} (never counted as policy coverage)" -f
    $productUnreachableCppMatches.Count)
if ($productUnreachableCppMatches.Count -gt 0) {
    $productUnreachableCppMatches |
        Sort-Object Name |
        Select-Object -First 12 Name, CandidateObject |
        Format-Table -AutoSize
    if ($productUnreachableCppMatches.Count -gt 12) {
        Write-Host ("  ... {0} additional unreachable matched rows omitted" -f
            ($productUnreachableCppMatches.Count - 12))
    }
}
Write-Host ("Verifier-matching WIP rows: {0} (promotion candidates, never counted as policy coverage)" -f
    $matchedWipRows.Count)

Write-Host ""
Write-Host "Mask and raw-match audit"
$maskAuditRows | Format-Table -AutoSize
Write-Host ("Compared bytes in accepted matches: {0}/{1} ({2})" -f
    $acceptedComparedBytes, $maskedMatchRangeBytes, (Format-Percent $acceptedComparedBytes $maskedMatchRangeBytes))
Write-Host ("All manifest masked bytes:     {0} bytes across {1} rows ({2} of {3} range bytes)" -f
    $allMaskBytes, $allMaskRows.Count, (Format-Percent $allMaskBytes $allRangeBytes), $allRangeBytes)

$overallStrict = $strictCoverage[-1]
$strictInstructions = [uint64]$overallStrict.matched_instructions
$totalInstructions = [uint64]$overallStrict.total_instructions
if ($totalInstructions -gt 0 -and $strictInstructions -lt $totalInstructions) {
    $currentPercent = ([double]$strictInstructions / [double]$totalInstructions) * 100.0
    $nextCheckpoint = ([System.Math]::Floor($currentPercent / 5.0) + 1.0) * 5.0

    Write-Host ""
    Write-Host "Next provisional evidence-bearing instruction checkpoints"
    $checkpointRows = @()
    for ($index = 0; $index -lt 3 -and $nextCheckpoint -le 100.0; $index++) {
        $targetInstructions = [uint64][System.Math]::Ceiling(
            ([double]$totalInstructions * $nextCheckpoint) / 100.0)
        $needed = if ($targetInstructions -gt $strictInstructions) {
            $targetInstructions - $strictInstructions
        }
        else {
            [uint64]0
        }
        $checkpointRows += [pscustomobject]@{
            checkpoint = ("{0:n0}%" -f $nextCheckpoint)
            target_instructions = $targetInstructions
            additional_needed = $needed
        }
        $nextCheckpoint += 5.0
    }
    $checkpointRows | Format-Table -AutoSize
}

if ($RequireProductReachability -and $productUnreachableCppMatches.Count -gt 0) {
    throw ("{0} accepted, verifier-matching EXE C++ row(s) resolve outside the strict Product graph." -f
        $productUnreachableCppMatches.Count)
}

if ($RequireInstructionPercent -gt 0.0) {
    if ($totalInstructions -eq 0) {
        throw "Cannot enforce an instruction milestone with a zero-instruction denominator."
    }

    $actualInstructionPercent =
        ([double]$strictInstructions / [double]$totalInstructions) * 100.0
    if (($actualInstructionPercent + 0.000000001) -lt $RequireInstructionPercent) {
        throw ("Policy-compliant instruction coverage is {0}/{1} ({2:n4}%), below the required {3:n4}%." -f
            $strictInstructions, $totalInstructions, $actualInstructionPercent,
            $RequireInstructionPercent)
    }

    Write-Host ("Required instruction threshold passed: {0:n4}% >= {1:n4}%." -f
        $actualInstructionPercent, $RequireInstructionPercent)
}

if (-not [string]::IsNullOrWhiteSpace($SummaryJsonPath)) {
    [string[]]$manifestIdentityUniverse = @($manifestByKey.Keys)
    [Array]::Sort(
        $manifestIdentityUniverse,
        [System.StringComparer]::Ordinal)

    [string[]]$strictAcceptedIdentities = @(
        $joinedByKey.GetEnumerator() |
            Where-Object { $_.Value.StrictMatch } |
            ForEach-Object { [string]$_.Key })
    [Array]::Sort(
        $strictAcceptedIdentities,
        [System.StringComparer]::Ordinal)
    if ([uint64]$strictAcceptedIdentities.Count -ne
        [uint64]$overallStrict.matched_functions) {
        throw "Internal metrics error: strict accepted identity count does not match coverage totals."
    }

    $denominatorLines = @()
    $bodyOwnershipLines = @()
    $bodyRangeCount = [uint64]0
    [string[]]$denominatorKeys = @($metricsByKey.Keys)
    [Array]::Sort($denominatorKeys, [System.StringComparer]::Ordinal)
    foreach ($key in $denominatorKeys) {
        $metricRow = $metricsByKey[$key]
        $metricInstructions = Parse-Number `
            (Get-CsvField $metricRow "instruction_count") `
            "metrics.instruction_count"
        $metricBodyBytes = Parse-Number `
            (Get-CsvField $metricRow "body_bytes") `
            "metrics.body_bytes"
        $metricSize = Parse-Number `
            (Get-CsvField $metricRow "size") "metrics.size"
        $denominatorLines += ("{0}|instructions={1}|body_bytes={2}|size={3}" -f
            $key, $metricInstructions, $metricBodyBytes, $metricSize)
        $bodyOwnership = $metricBodyOwnershipByKey[$key]
        $bodyOwnershipLines += ("{0}|body_ranges={1}" -f
            $key, [string]$bodyOwnership.Canonical)
        $bodyRangeCount += [uint64]$bodyOwnership.RangeCount
    }

    $metricInputRecords = @()
    foreach ($snapshot in $functionMetricInputSnapshots) {
        $metricInputRecords += [pscustomobject][ordered]@{
            path = [string]$snapshot.path
            sha256 = [string]$snapshot.sha256
        }
    }

    $instructionPercent = if ($totalInstructions -eq 0) {
        [double]0.0
    }
    else {
        ([double]$strictInstructions / [double]$totalInstructions) * 100.0
    }
    $summary = [pscustomobject][ordered]@{
        schema_version = 2
        generated_utc = [DateTime]::UtcNow.ToString("o")
        policy = [pscustomobject][ordered]@{
            include_non_text = [bool]$IncludeNonText
            require_product_reachability = [bool]$RequireProductReachability
            required_instruction_percent = $RequireInstructionPercent
        }
        inputs = [pscustomobject][ordered]@{
            manifest = [pscustomobject][ordered]@{
                path = $resolvedManifestPath
                sha256 = $manifestSha256
                identity_universe_sha256 =
                    Get-TextSha256Hex $manifestIdentityUniverse
                identity_count = [uint64]$manifestIdentityUniverse.Count
            }
            verifier_results = [pscustomobject][ordered]@{
                path = $resolvedVerifierResultsPath
                sha256 = [string]$verifierInputSnapshot.sha256
            }
            mask_audit_results = [pscustomobject][ordered]@{
                path = $resolvedMaskAuditResultsPath
                sha256 = [string]$maskAuditInputSnapshot.sha256
            }
            function_metrics = @($metricInputRecords)
            exe_product_sources = [pscustomobject][ordered]@{
                path = $resolvedExeProductSourceManifestPath
                sha256 = [string]$productSourceInputSnapshot.sha256
            }
            metrics_reporter = [pscustomobject][ordered]@{
                path = $PSCommandPath
                sha256 = [string]$reporterInputSnapshot.sha256
            }
        }
        denominator = [pscustomobject][ordered]@{
            identity_sha256 = Get-TextSha256Hex $denominatorLines
            function_count = [uint64]$overallStrict.total_functions
            instruction_count = [uint64]$overallStrict.total_instructions
            body_byte_count = [uint64]$overallStrict.total_body_bytes
            body_ownership_sha256 = Get-TextSha256Hex $bodyOwnershipLines
            body_range_count = $bodyRangeCount
        }
        strict = [pscustomobject][ordered]@{
            accepted_identity_sha256 = Get-TextSha256Hex $strictAcceptedIdentities
            accepted_identity_count = [uint64]$strictAcceptedIdentities.Count
            accepted_identities = @($strictAcceptedIdentities)
            accepted_instructions = [uint64]$overallStrict.matched_instructions
            accepted_body_bytes = [uint64]$overallStrict.matched_body_bytes
            instruction_percent = $instructionPercent
        }
    }

    Assert-InputSnapshotsUnchanged $allStableInputSnapshots
    Assert-ValidatedFilesUnchanged
    Write-JsonAtomically $summary $SummaryJsonPath
    Write-Host ("Machine-readable metrics summary: {0}" -f
        (Resolve-OutputFilePath $SummaryJsonPath))
}
