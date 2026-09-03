param(
    [Parameter(Mandatory = $true)]
    [string]$PlanPath,

    [string]$OriginalPath = "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe",
    [string]$CandidatePath = "artifacts\otmatch\vc40\otwin-match-candidates.dll",
    [string]$CandidateMapPath = "artifacts\otmatch\vc40\otwin-match-candidates.map",
    [string]$BuildOutputDirectory = "artifacts\otmatch\vc40",
    [ValidateSet("LegacyMsvc", "ModernVs")]
    [string]$Toolchain = "LegacyMsvc",
    [string]$DefaultOptimization = "/Od",
    [string]$SemanticOptimization = "/O1",
    [string[]]$ExtraCompileFlags = @(),
    [string[]]$ExtraLinkFlags = @(),
    [string]$ObjectCacheDirectory = "",
    [switch]$DisableIncrementalCache,
    [string]$ResultCsvPath = "",
    [string]$EvidenceJsonPath = "",
    [string]$WarmBaselineProofPath = "",
    # Runs the same locked, restoring focused loop but deliberately emits
    # diagnostic-only evidence. A zero residual must be reproduced without
    # this switch before promotion.
    [switch]$Exploration,
    [switch]$NoRestoreBuild,
    [ValidateRange(1, 240)]
    [int]$StopLossMinutes = 45,
    [ValidateRange(1, 100)]
    [int]$MaxNoImprovementVariants = 8,
    # Stop after the first abnormally slow focused build or symbol diff. The
    # completed trial and mandatory restoration remain durable.
    [ValidateRange(1, 3600)]
    [int]$MaximumFocusedBuildSeconds = 15,
    [ValidateRange(1, 3600)]
    [int]$MaximumFocusedDiffSeconds = 30,
    [ValidateRange(1, 3600)]
    [int]$SourceLockTimeoutSeconds = 120,

    [Parameter(DontShow = $true)]
    [string]$BuildScriptOverride = "",
    [Parameter(DontShow = $true)]
    [string]$DiffScriptOverride = "",
    [Parameter(DontShow = $true)]
    [string]$PlanPreflightScriptOverride = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$runnerWatch = [System.Diagnostics.Stopwatch]::StartNew()

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
if (-not $PSBoundParameters.ContainsKey("CandidatePath")) {
    $CandidatePath = Join-Path $BuildOutputDirectory "otwin-match-candidates.dll"
}
if (-not $PSBoundParameters.ContainsKey("CandidateMapPath")) {
    $CandidateMapPath = Join-Path $BuildOutputDirectory "otwin-match-candidates.map"
}
$buildScript = if ([string]::IsNullOrWhiteSpace($BuildScriptOverride)) {
    Join-Path $PSScriptRoot "build-match-candidates.ps1"
} else {
    (Resolve-Path -LiteralPath $BuildScriptOverride).Path
}
$diffScript = if ([string]::IsNullOrWhiteSpace($DiffScriptOverride)) {
    Join-Path $PSScriptRoot "diff-symbol-bytes.ps1"
} else {
    (Resolve-Path -LiteralPath $DiffScriptOverride).Path
}
$generatedPlanPreflightScript = if (
    [string]::IsNullOrWhiteSpace($PlanPreflightScriptOverride)) {
    Join-Path $PSScriptRoot "new-source-shape-plan.ps1"
} else {
    (Resolve-Path -LiteralPath $PlanPreflightScriptOverride).Path
}

function Resolve-RepoPath([string]$Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return (Resolve-Path -LiteralPath $Path).Path
    }

    return (Resolve-Path -LiteralPath (Join-Path $repoRoot $Path)).Path
}

function Test-PathInsideRoot {
    param(
        [string]$Path,
        [string]$Root
    )

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

function Assert-NoOutputReparseTraversal {
    param([string]$Path)

    $currentPath = [System.IO.Path]::GetFullPath($Path)
    while (-not (Test-Path -LiteralPath $currentPath)) {
        $parentPath = Split-Path -Parent $currentPath
        if ([string]::IsNullOrWhiteSpace($parentPath) -or
            $parentPath.Equals(
                $currentPath,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Runner output path has no existing repository ancestor: '$Path'."
        }
        $currentPath = $parentPath
    }

    $current = Get-Item -LiteralPath $currentPath -Force
    while ($null -ne $current) {
        if (($current.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Runner output path cannot traverse reparse point '$($current.FullName)'."
        }
        if ($current.FullName.Equals(
                $repoRoot,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            return
        }
        $parentPath = Split-Path -Parent $current.FullName
        if ([string]::IsNullOrWhiteSpace($parentPath) -or
            $parentPath.Equals(
                $current.FullName,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            break
        }
        $current = Get-Item -LiteralPath $parentPath -Force
    }
    throw "Runner output path is not rooted beneath the repository: '$Path'."
}

function Assert-SafeRunnerOutputPaths {
    param(
        [string]$ResultPath,
        [string]$EvidencePath,
        [string]$WarmProofPath = "",
        [hashtable]$ReservedPaths
    )

    $outputPaths = [ordered]@{
        result_csv = [System.IO.Path]::GetFullPath($ResultPath)
        evidence_json = [System.IO.Path]::GetFullPath($EvidencePath)
    }
    if (-not [string]::IsNullOrWhiteSpace($WarmProofPath)) {
        $outputPaths.warm_baseline_proof =
            [System.IO.Path]::GetFullPath($WarmProofPath)
    }
    $seenOutputPaths = @{}
    foreach ($entry in $outputPaths.GetEnumerator()) {
        $outputKey = ([string]$entry.Value).ToLowerInvariant()
        if ($seenOutputPaths.ContainsKey($outputKey)) {
            throw ("Runner outputs '{0}' and '{1}' must be distinct files." -f
                $seenOutputPaths[$outputKey], $entry.Key)
        }
        $seenOutputPaths[$outputKey] = $entry.Key
    }

    $allowedRoots = @(
        (Join-Path $repoRoot "a"),
        (Join-Path $repoRoot "artifacts")
    )
    foreach ($entry in $outputPaths.GetEnumerator()) {
        $path = [string]$entry.Value
        if (Test-Path -LiteralPath $path -PathType Container) {
            throw "Runner output '$($entry.Key)' must name a file, not a directory: '$path'."
        }
        $insideAllowedRoot = @($allowedRoots | Where-Object {
                Test-PathInsideRoot $path ([System.IO.Path]::GetFullPath($_))
            }).Count -ne 0
        if (-not $insideAllowedRoot) {
            throw ("Runner output '$($entry.Key)' must remain beneath the " +
                "repository's ignored a/ or artifacts/ roots: '$path'.")
        }
        Assert-NoOutputReparseTraversal $path

        $relativePath = $path.Substring($repoRoot.Length).
            TrimStart('\', '/').Replace('\', '/')
        & git -C $repoRoot check-ignore --quiet -- $relativePath 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Runner output is not Git-ignored: '$relativePath'."
        }

        foreach ($reserved in $ReservedPaths.GetEnumerator()) {
            if ([string]::IsNullOrWhiteSpace([string]$reserved.Value)) {
                continue
            }
            $reservedPath = [System.IO.Path]::GetFullPath([string]$reserved.Value)
            if ($path.Equals(
                    $reservedPath,
                    [System.StringComparison]::OrdinalIgnoreCase)) {
                throw ("Runner output '$($entry.Key)' aliases reserved " +
                    "$($reserved.Key) path '$reservedPath'.")
            }
        }
        if ($entry.Key -eq "warm_baseline_proof" -and
            -not [System.IO.Path]::GetExtension($path).Equals(
                ".json",
                [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Runner output 'warm_baseline_proof' must name a .json file: '$path'."
        }
    }
}

function Assert-NoReparseTraversal {
    param([string]$Path)

    $current = Get-Item -LiteralPath $Path -Force
    while ($null -ne $current) {
        if (($current.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Source-shape source cannot traverse reparse point '$($current.FullName)'."
        }
        if ($current.FullName.Equals(
                $repoRoot,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            return
        }
        $parentPath = Split-Path -Parent $current.FullName
        if ([string]::IsNullOrWhiteSpace($parentPath) -or
            $parentPath.Equals(
                $current.FullName,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            break
        }
        $current = Get-Item -LiteralPath $parentPath -Force
    }
    throw "Source-shape source is not rooted beneath the repository."
}

function Assert-SafeSourceShapePath {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Source-shape source must be an existing regular .cpp file: '$Path'."
    }
    $sourceFile = Get-Item -LiteralPath $Path -Force
    if (-not ($sourceFile -is [System.IO.FileInfo]) -or
        -not $sourceFile.Extension.Equals(
            ".cpp",
            [System.StringComparison]::OrdinalIgnoreCase) -or
        ($sourceFile.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Source-shape source must be a regular non-reparse .cpp file: '$Path'."
    }
    if (-not (Test-PathInsideRoot $sourceFile.FullName $repoRoot)) {
        throw "Source-shape source must remain inside the repository: '$($sourceFile.FullName)'."
    }
    Assert-NoReparseTraversal $sourceFile.FullName

    if ([string]::IsNullOrWhiteSpace($BuildScriptOverride)) {
        $defaultSourceRoot = Join-Path $repoRoot "src\otwin"
        if (-not (Test-PathInsideRoot $sourceFile.FullName $defaultSourceRoot) -or
            $sourceFile.Name -like '*_notes.cpp') {
            throw ("Production source-shape source is not part of the default " +
                "src/otwin candidate graph: '$($sourceFile.FullName)'.")
        }
        return
    }

    $relativePath = $sourceFile.FullName.Substring($repoRoot.Length).
        TrimStart('\', '/').Replace('\', '/')
    & git -C $repoRoot check-ignore --quiet -- $relativePath 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw ("Override source-shape fixtures must be repository-contained, " +
            "Git-ignored .cpp files: '$relativePath'.")
    }
}

function Convert-HexNumber([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return [uint64]0
    }

    $text = $Value.Trim()
    if ($text.StartsWith("0x", [System.StringComparison]::OrdinalIgnoreCase)) {
        $text = $text.Substring(2)
    }

    return [uint64]::Parse($text, [System.Globalization.NumberStyles]::HexNumber)
}

function Enter-CandidateGraphLock {
    $lockPath = Join-Path $repoRoot "artifacts\otmatch\.candidate-graph.lock"
    [void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $lockPath))
    $deadline = [DateTime]::UtcNow.AddSeconds($SourceLockTimeoutSeconds)
    while ($true) {
        try {
            return [System.IO.File]::Open(
                $lockPath,
                [System.IO.FileMode]::OpenOrCreate,
                [System.IO.FileAccess]::ReadWrite,
                [System.IO.FileShare]::None)
        } catch [System.IO.IOException] {
            if ([DateTime]::UtcNow -ge $deadline) {
                throw "Timed out after $SourceLockTimeoutSeconds second(s) waiting for exclusive candidate-graph lock."
            }
            Start-Sleep -Milliseconds 100
        }
    }
}

function Get-ProcessEnvironmentSnapshot {
    $snapshot = @{}
    foreach ($entry in [Environment]::GetEnvironmentVariables("Process").GetEnumerator()) {
        $snapshot[[string]$entry.Key] = [string]$entry.Value
    }
    return $snapshot
}

function Restore-ProcessEnvironment($Snapshot) {
    foreach ($entry in [Environment]::GetEnvironmentVariables("Process").GetEnumerator()) {
        if (-not $Snapshot.ContainsKey([string]$entry.Key)) {
            [Environment]::SetEnvironmentVariable([string]$entry.Key, $null, "Process")
        }
    }
    foreach ($name in $Snapshot.Keys) {
        [Environment]::SetEnvironmentVariable($name, [string]$Snapshot[$name], "Process")
    }
}

function Invoke-CandidateBuild {
    param(
        [string[]]$ChangedSources = @(),
        [switch]$ForceRebuild,
        [switch]$Focused,
        [switch]$TrustValidatedGraph,
        [switch]$ForceMainRelink
    )

    $buildParameters = @{
        Toolchain = $Toolchain
        OutputDirectory = $BuildOutputDirectory
        DefaultOptimization = $DefaultOptimization
        SemanticOptimization = $SemanticOptimization
        ExtraCompileFlags = @($ExtraCompileFlags)
        ExtraLinkFlags = @($ExtraLinkFlags)
        ChangedSource = @($ChangedSources)
        CandidateGraphLockHeld = $true
    }

    if (-not [string]::IsNullOrWhiteSpace($ObjectCacheDirectory)) {
        $buildParameters.ObjectCacheDirectory = $ObjectCacheDirectory
    }
    if ($DisableIncrementalCache) {
        $buildParameters.DisableIncrementalCache = $true
    }
    if ($ForceRebuild) {
        $buildParameters.Rebuild = $true
    }
    if ($Focused) {
        $buildParameters.FocusedChangedSource = $true
    }
    if ($TrustValidatedGraph) {
        $buildParameters.FocusedGraphAlreadyValidated = $true
    }
    if ($ForceMainRelink) {
        $buildParameters.ForceMainRelink = $true
    }

    # A child script scope preserves native string[] binding (powershell
    # -File cannot reliably transport multiple array values) and avoids one
    # process launch per variant. Restore process environment because the
    # toolchain initializer intentionally mutates PATH/INCLUDE/LIB.
    $environmentSnapshot = Get-ProcessEnvironmentSnapshot
    try {
        & $buildScript @buildParameters
    } finally {
        Restore-ProcessEnvironment $environmentSnapshot
    }
}

function Invoke-Diff(
    [uint64]$OriginalRva,
    [int]$Size,
    [string]$CandidateSymbol,
    [string]$Mask
) {
    # Native stderr is represented as ErrorRecord objects by Windows
    # PowerShell. With the session-wide Stop policy, a diagnostic emitted by a
    # failing diff process can otherwise terminate this assignment before its
    # exit code is captured, obscuring the actionable failure in the CSV.
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $diffArguments = @(
            "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $diffScript,
            "-OriginalPath", (Resolve-RepoPath $OriginalPath),
            "-OriginalRva", [string]$OriginalRva,
            "-Size", [string]$Size,
            "-CandidatePath", (Resolve-RepoPath $CandidatePath),
            "-CandidateMapPath", (Resolve-RepoPath $CandidateMapPath),
            "-CandidateSymbol", $CandidateSymbol)
        if (-not [string]::IsNullOrWhiteSpace($Mask)) {
            $diffArguments += @("-Mask", $Mask)
        }
        $output = & powershell @diffArguments 2>&1
        $diffExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    $text = $output | Out-String
    if ($diffExitCode -ne 0) {
        throw "diff-symbol-bytes.ps1 failed with exit code $diffExitCode`n$text"
    }
    $diffCount = $null
    $candidateRva = ""
    $offsets = ""
    $hardDiffCount = $null
    $hardComparedBytes = $Size
    $hardOffsets = ""
    if ($text -match 'Candidate RVA:\s+(0x[0-9a-fA-F]+)') {
        $candidateRva = $matches[1]
    }
    if ($text -match 'Differences:\s+([0-9]+)\s*/') {
        $diffCount = [int]$matches[1]
    }
    if ($text -match 'All diff offsets:\s+([^\r\n]+)') {
        $offsets = $matches[1]
    }
    if ($text -match 'Hard differences:\s+([0-9]+)\s*/\s*([0-9]+)') {
        $hardDiffCount = [int]$matches[1]
        $hardComparedBytes = [int]$matches[2]
    }
    if ($text -match 'All hard diff offsets:\s+([^\r\n]+)') {
        $hardOffsets = $matches[1]
    }
    if ($null -eq $hardDiffCount) {
        $hardDiffCount = $diffCount
    }

    return [pscustomobject]@{
        CandidateRva = $candidateRva
        DiffCount    = $diffCount
        DiffOffsets  = $offsets
        HardDiffCount = $hardDiffCount
        HardComparedBytes = $hardComparedBytes
        HardDiffOffsets = $hardOffsets
        RawOutput    = $text
    }
}

function Get-BytesSha256Hex([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return [System.BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace("-", "").ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Get-FileSha256Hex([string]$Path) {
    return Get-BytesSha256Hex ([System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).Path))
}

function Convert-TextBytesToString([byte[]]$Bytes) {
    $memory = New-Object System.IO.MemoryStream
    $reader = $null
    try {
        $memory.Write($Bytes, 0, $Bytes.Length)
        $memory.Position = 0
        # Match Windows PowerShell's file decoding: recognize a BOM and use
        # the process ANSI code page for legacy no-BOM plans.
        $reader = New-Object System.IO.StreamReader(
            $memory,
            [System.Text.Encoding]::Default,
            $true)
        return $reader.ReadToEnd()
    } finally {
        if ($null -ne $reader) {
            $reader.Dispose()
        } else {
            $memory.Dispose()
        }
    }
}

function Clear-ByteRange([byte[]]$Bytes, [int]$Offset, [int]$Length) {
    if ($Offset -lt 0 -or $Length -lt 0 -or $Offset + $Length -gt $Bytes.Length) {
        throw "Cannot normalize byte range $Offset..$($Offset + $Length - 1) in a $($Bytes.Length)-byte file."
    }
    for ($index = 0; $index -lt $Length; $index++) {
        $Bytes[$Offset + $index] = 0
    }
}

function Convert-PeRvaToFileOffset(
    [byte[]]$Bytes,
    [int]$PeOffset,
    [int]$OptionalHeaderOffset,
    [uint32]$Rva
) {
    if ($Rva -eq 0) {
        return -1
    }

    $sectionCount = [BitConverter]::ToUInt16($Bytes, $PeOffset + 6)
    $optionalHeaderSize = [BitConverter]::ToUInt16($Bytes, $PeOffset + 20)
    $sectionOffset = $OptionalHeaderOffset + $optionalHeaderSize
    for ($sectionIndex = 0; $sectionIndex -lt $sectionCount; $sectionIndex++) {
        $entryOffset = $sectionOffset + (40 * $sectionIndex)
        if ($entryOffset + 40 -gt $Bytes.Length) {
            throw "PE section table extends beyond the candidate file."
        }
        $virtualSize = [BitConverter]::ToUInt32($Bytes, $entryOffset + 8)
        $virtualAddress = [BitConverter]::ToUInt32($Bytes, $entryOffset + 12)
        $rawSize = [BitConverter]::ToUInt32($Bytes, $entryOffset + 16)
        $rawOffset = [BitConverter]::ToUInt32($Bytes, $entryOffset + 20)
        $mappedSize = [Math]::Max([uint64]$virtualSize, [uint64]$rawSize)
        if ([uint64]$Rva -ge [uint64]$virtualAddress -and
            [uint64]$Rva -lt ([uint64]$virtualAddress + $mappedSize)) {
            $fileOffset = [uint64]$rawOffset + ([uint64]$Rva - [uint64]$virtualAddress)
            if ($fileOffset -ge [uint64]$Bytes.Length) {
                throw "PE RVA 0x$($Rva.ToString('x')) maps beyond the candidate file."
            }
            return [int]$fileOffset
        }
    }
    return -1
}

function Get-NormalizedPeSha256Hex([string]$Path) {
    [byte[]]$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).Path)
    if ($bytes.Length -lt 64 -or $bytes[0] -ne 0x4d -or $bytes[1] -ne 0x5a) {
        return Get-BytesSha256Hex $bytes
    }

    $peOffset = [BitConverter]::ToInt32($bytes, 0x3c)
    if ($peOffset -lt 0 -or $peOffset + 24 -gt $bytes.Length -or
        $bytes[$peOffset] -ne 0x50 -or $bytes[$peOffset + 1] -ne 0x45 -or
        $bytes[$peOffset + 2] -ne 0 -or $bytes[$peOffset + 3] -ne 0) {
        return Get-BytesSha256Hex $bytes
    }

    # LINK 4.x writes wall-clock values into the COFF header, export directory,
    # IMAGE_DEBUG_DIRECTORY records, and NB10 CodeView record. It also leaves
    # the documented IMAGE_DEBUG_MISC.Reserved[3] bytes uninitialized. Those
    # fields can change across a faithful relink even when every section and
    # symbol byte is identical. Normalize only those validated fields.
    Clear-ByteRange $bytes ($peOffset + 8) 4
    $optionalHeaderOffset = $peOffset + 24
    $magic = [BitConverter]::ToUInt16($bytes, $optionalHeaderOffset)
    $directoryCountOffset = if ($magic -eq 0x10b) {
        $optionalHeaderOffset + 92
    } elseif ($magic -eq 0x20b) {
        $optionalHeaderOffset + 108
    } else {
        return Get-BytesSha256Hex $bytes
    }
    $directoryOffset = $directoryCountOffset + 4
    $directoryCount = [BitConverter]::ToUInt32($bytes, $directoryCountOffset)

    if ($directoryCount -gt 0 -and $directoryOffset + 8 -le $bytes.Length) {
        $exportRva = [BitConverter]::ToUInt32($bytes, $directoryOffset)
        $exportOffset = Convert-PeRvaToFileOffset $bytes $peOffset $optionalHeaderOffset $exportRva
        if ($exportOffset -ge 0 -and $exportOffset + 8 -le $bytes.Length) {
            Clear-ByteRange $bytes ($exportOffset + 4) 4
        }
    }

    if ($directoryCount -gt 6 -and $directoryOffset + 56 -le $bytes.Length) {
        $debugDirectoryOffset = $directoryOffset + (6 * 8)
        $debugRva = [BitConverter]::ToUInt32($bytes, $debugDirectoryOffset)
        $debugSize = [BitConverter]::ToUInt32($bytes, $debugDirectoryOffset + 4)
        $debugOffset = Convert-PeRvaToFileOffset $bytes $peOffset $optionalHeaderOffset $debugRva
        if ($debugOffset -ge 0) {
            $debugCount = [Math]::Floor([double]$debugSize / 28)
            for ($debugIndex = 0; $debugIndex -lt $debugCount; $debugIndex++) {
                $entryOffset = $debugOffset + (28 * $debugIndex)
                if ($entryOffset + 28 -gt $bytes.Length) {
                    throw "PE debug directory extends beyond the candidate file."
                }
                Clear-ByteRange $bytes ($entryOffset + 4) 4
                $debugType = [BitConverter]::ToUInt32($bytes, $entryOffset + 12)
                $debugDataSize = [BitConverter]::ToUInt32($bytes, $entryOffset + 16)
                $debugDataOffset = [BitConverter]::ToUInt32($bytes, $entryOffset + 24)
                if ($debugType -eq 2 -and $debugDataSize -ge 12 -and
                    [uint64]$debugDataOffset + 12 -le [uint64]$bytes.Length -and
                    $bytes[$debugDataOffset] -eq 0x4e -and
                    $bytes[$debugDataOffset + 1] -eq 0x42 -and
                    $bytes[$debugDataOffset + 2] -eq 0x31 -and
                    $bytes[$debugDataOffset + 3] -eq 0x30) {
                    Clear-ByteRange $bytes ([int]$debugDataOffset + 8) 4
                }
                if ($debugType -eq 4 -and $debugDataSize -ge 12 -and
                    [uint64]$debugDataOffset + [uint64]$debugDataSize -le
                        [uint64]$bytes.Length) {
                    $miscDataType = [BitConverter]::ToUInt32($bytes, [int]$debugDataOffset)
                    $miscLength = [BitConverter]::ToUInt32($bytes, [int]$debugDataOffset + 4)
                    $miscUnicode = $bytes[[int]$debugDataOffset + 8]
                    if ($miscDataType -eq 1 -and
                        $miscLength -ge 12 -and
                        $miscLength -le $debugDataSize -and
                        ($miscUnicode -eq 0 -or $miscUnicode -eq 1)) {
                        Clear-ByteRange $bytes ([int]$debugDataOffset + 9) 3
                    }
                }
            }
        }
    }

    return Get-BytesSha256Hex $bytes
}

function Get-NormalizedMapSha256Hex([string]$Path) {
    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    $text = [System.IO.File]::ReadAllText($resolvedPath)
    $normalized = [regex]::Replace(
        $text,
        '(?m)^ Timestamp is [0-9a-f]{8} \((?:Sun|Mon|Tue|Wed|Thu|Fri|Sat) ' +
            '(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) ' +
            '(?: [1-9]|0[1-9]|[12][0-9]|3[01]) [0-2][0-9]:[0-5][0-9]:' +
            '[0-5][0-9] [0-9]{4}\)\r?$',
        ' Timestamp is <normalized>')
    return Get-BytesSha256Hex ([System.Text.Encoding]::UTF8.GetBytes($normalized))
}

function Get-OptionalJsonValue($Object, [string]$Name, $DefaultValue) {
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $DefaultValue
    }

    return $property.Value
}

function Get-OptionalJsonAliasValue {
    param(
        $Object,
        [string[]]$Names,
        $DefaultValue
    )

    foreach ($name in $Names) {
        $property = $Object.PSObject.Properties[$name]
        if ($null -ne $property) {
            return $property.Value
        }
    }
    return $DefaultValue
}

function Write-JsonAtomically {
    param(
        [string]$Path,
        $Value
    )

    $directory = Split-Path -Parent $Path
    [void][System.IO.Directory]::CreateDirectory($directory)
    $temporaryPath = Join-Path $directory (
        ".{0}.{1}.tmp" -f (Split-Path -Leaf $Path), [Guid]::NewGuid().ToString("N"))
    $backupPath = $temporaryPath + ".bak"
    try {
        [System.IO.File]::WriteAllText(
            $temporaryPath,
            (($Value | ConvertTo-Json -Depth 8) + "`n"),
            (New-Object System.Text.UTF8Encoding($false)))
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            [System.IO.File]::Replace($temporaryPath, $Path, $backupPath, $true)
        } else {
            [System.IO.File]::Move($temporaryPath, $Path)
        }
    } finally {
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
        if (Test-Path -LiteralPath $backupPath -PathType Leaf) {
            Remove-Item -LiteralPath $backupPath -Force
        }
    }
}

function Get-StringSha256Hex([string]$Text) {
    return Get-BytesSha256Hex ([System.Text.Encoding]::UTF8.GetBytes($Text))
}

function Get-JsonValueSha256Hex($Value) {
    return Get-StringSha256Hex ($Value | ConvertTo-Json -Depth 12 -Compress)
}

function Assert-Sha256Value {
    param(
        [string]$Value,
        [string]$Description
    )

    if ($Value -cnotmatch '^[0-9a-f]{64}$') {
        throw "$Description is not a canonical lowercase SHA256 value."
    }
}

function Get-WarmBaselineConfigurationSha256 {
    param(
        [string]$RunnerSha256,
        [string]$BuildScriptSha256,
        [string]$SourcePath,
        [string]$OriginalFilePath,
        [string]$OutputDirectory,
        [string]$CandidateFilePath,
        [string]$CandidateMapFilePath,
        [string]$FocusedStatePath,
        [string]$ObjectCachePath
    )

    $fields = @(
        "schema=otmatch-source-shape-warm-configuration-v1",
        "runner=$RunnerSha256",
        "build_script=$BuildScriptSha256",
        "source=$($SourcePath.ToLowerInvariant())",
        "original=$($OriginalFilePath.ToLowerInvariant())",
        "output=$($OutputDirectory.ToLowerInvariant())",
        "candidate=$($CandidateFilePath.ToLowerInvariant())",
        "candidate_map=$($CandidateMapFilePath.ToLowerInvariant())",
        "focused_state=$($FocusedStatePath.ToLowerInvariant())",
        "toolchain=$Toolchain",
        "default_optimization=$DefaultOptimization",
        "semantic_optimization=$SemanticOptimization",
        "extra_compile=$($ExtraCompileFlags -join [char]0x1f)",
        "extra_link=$($ExtraLinkFlags -join [char]0x1f)",
        "object_cache=$($ObjectCachePath.ToLowerInvariant())",
        "disable_incremental_cache=$([bool]$DisableIncrementalCache)"
    )
    return Get-StringSha256Hex ($fields -join "`n")
}

function Read-FocusedBuildStateBinding {
    param(
        [string]$StatePath,
        [string]$ExpectedSourcePath,
        [string]$ExpectedObjectName,
        [string]$ExpectedCandidatePath,
        [string]$ExpectedMapPath
    )

    if (-not (Test-Path -LiteralPath $StatePath -PathType Leaf)) {
        throw "Warm baseline requires focused build state '$StatePath'."
    }
    try {
        $state = [System.IO.File]::ReadAllText($StatePath) | ConvertFrom-Json
    } catch {
        throw "Warm baseline focused build state is invalid: $($_.Exception.Message)"
    }
    if ([int]$state.schema_version -ne 1 -or
        [string]::IsNullOrWhiteSpace([string]$state.context_fingerprint) -or
        [string]::IsNullOrWhiteSpace([string]$state.graph_fingerprint)) {
        throw "Warm baseline focused build state is not supported schema 1."
    }
    Assert-Sha256Value ([string]$state.context_fingerprint) `
        "Warm baseline focused context fingerprint"
    Assert-Sha256Value ([string]$state.graph_fingerprint) `
        "Warm baseline candidate graph fingerprint"

    $sourceRecords = @($state.sources)
    $targetRecords = @($sourceRecords | Where-Object {
            ([string]$_.source).Equals(
                $ExpectedSourcePath,
                [System.StringComparison]::OrdinalIgnoreCase)
        })
    if ($targetRecords.Count -ne 1 -or
        -not ([string]$targetRecords[0].object_name).Equals(
            $ExpectedObjectName,
            [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Warm baseline focused state does not bind the expected source/object identity."
    }
    Assert-Sha256Value ([string]$targetRecords[0].object_sha256) `
        "Warm baseline focused object SHA256"

    $mainOutputs = @($state.main_outputs)
    if ($sourceRecords.Count -eq 0 -or $mainOutputs.Count -eq 0) {
        throw "Warm baseline focused state must bind source records and main outputs."
    }
    foreach ($expectedOutputPath in @($ExpectedCandidatePath, $ExpectedMapPath)) {
        if (@($mainOutputs | Where-Object {
                    ([string]$_.path).Equals(
                        $expectedOutputPath,
                        [System.StringComparison]::OrdinalIgnoreCase)
                }).Count -ne 1) {
            throw "Warm baseline focused state does not bind expected main output '$expectedOutputPath'."
        }
    }
    foreach ($output in $mainOutputs) {
        $outputPath = [string]$output.path
        if ([string]::IsNullOrWhiteSpace($outputPath) -or
            -not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
            throw "Warm baseline main output is missing: '$outputPath'."
        }
        Assert-Sha256Value ([string]$output.sha256) `
            "Warm baseline main output SHA256"
        $file = Get-Item -LiteralPath $outputPath
        if ([long]$file.Length -ne [long]$output.length -or
            (Get-FileSha256Hex $outputPath) -cne [string]$output.sha256) {
            throw "Warm baseline main output is stale: '$outputPath'."
        }
    }

    return [pscustomobject][ordered]@{
        StateSha256 = Get-FileSha256Hex $StatePath
        ContextFingerprint = [string]$state.context_fingerprint
        GraphFingerprint = [string]$state.graph_fingerprint
        SourceGraphSha256 = Get-JsonValueSha256Hex $state.sources
        MainOutputsSha256 = Get-JsonValueSha256Hex $state.main_outputs
        FocusedObjectSha256 = [string]$targetRecords[0].object_sha256
    }
}

function Read-WarmBaselineProof([string]$Path) {
    try {
        $proof = [System.IO.File]::ReadAllText($Path) | ConvertFrom-Json
    } catch {
        throw "Warm baseline proof is invalid: $($_.Exception.Message)"
    }
    $requiredProperties = @(
        "schema_version", "artifact_type", "created_utc", "runner_sha256",
        "build_script_sha256", "configuration_sha256", "source_path",
        "source_sha256", "original_path", "original_sha256",
        "focused_state_path", "focused_state_sha256",
        "focused_context_fingerprint", "candidate_graph_fingerprint",
        "source_graph_sha256", "main_outputs_sha256",
        "candidate_normalized_sha256", "map_normalized_sha256",
        "focused_object_sha256")
    $actualProperties = @($proof.PSObject.Properties | ForEach-Object {
            [string]$_.Name
        })
    $missing = @($requiredProperties | Where-Object {
            -not ($actualProperties -ccontains $_)
        })
    $extra = @($actualProperties | Where-Object {
            -not ($requiredProperties -ccontains $_)
        })
    if ($missing.Count -ne 0 -or $extra.Count -ne 0 -or
        [int]$proof.schema_version -ne 1 -or
        [string]$proof.artifact_type -cne
            "otmatch-source-shape-warm-baseline") {
        throw "Warm baseline proof is not the canonical schema-1 artifact."
    }
    foreach ($propertyName in @(
            "runner_sha256", "build_script_sha256", "configuration_sha256",
            "source_sha256", "original_sha256", "focused_state_sha256",
            "focused_context_fingerprint", "candidate_graph_fingerprint",
            "source_graph_sha256", "main_outputs_sha256",
            "candidate_normalized_sha256", "map_normalized_sha256",
            "focused_object_sha256")) {
        Assert-Sha256Value ([string]$proof.PSObject.Properties[$propertyName].Value) `
            "Warm baseline proof $propertyName"
    }
    return $proof
}

function Assert-WarmBaselineProofBinding {
    param(
        $Proof,
        $StateBinding,
        [string]$ConfigurationSha256,
        [string]$RunnerSha256,
        [string]$BuildScriptSha256,
        [string]$SourcePath,
        [string]$SourceSha256,
        [string]$OriginalFilePath,
        [string]$OriginalSha256,
        [string]$FocusedStatePath,
        [string]$CandidateNormalizedSha256,
        [string]$MapNormalizedSha256,
        [string]$FocusedObjectSha256,
        [switch]$IgnoreStateFileSha256
    )

    $mismatches = @()
    $bindings = [ordered]@{
        runner_sha256 = @([string]$Proof.runner_sha256, $RunnerSha256)
        build_script_sha256 = @([string]$Proof.build_script_sha256, $BuildScriptSha256)
        configuration_sha256 = @([string]$Proof.configuration_sha256, $ConfigurationSha256)
        source_sha256 = @([string]$Proof.source_sha256, $SourceSha256)
        original_sha256 = @([string]$Proof.original_sha256, $OriginalSha256)
        focused_context_fingerprint = @([string]$Proof.focused_context_fingerprint, [string]$StateBinding.ContextFingerprint)
        candidate_graph_fingerprint = @([string]$Proof.candidate_graph_fingerprint, [string]$StateBinding.GraphFingerprint)
        source_graph_sha256 = @([string]$Proof.source_graph_sha256, [string]$StateBinding.SourceGraphSha256)
        main_outputs_sha256 = @([string]$Proof.main_outputs_sha256, [string]$StateBinding.MainOutputsSha256)
        candidate_normalized_sha256 = @([string]$Proof.candidate_normalized_sha256, $CandidateNormalizedSha256)
        map_normalized_sha256 = @([string]$Proof.map_normalized_sha256, $MapNormalizedSha256)
        focused_object_sha256 = @([string]$Proof.focused_object_sha256, $FocusedObjectSha256)
    }
    if (-not $IgnoreStateFileSha256) {
        $bindings["focused_state_sha256"] = @(
            [string]$Proof.focused_state_sha256,
            [string]$StateBinding.StateSha256)
    }
    foreach ($entry in $bindings.GetEnumerator()) {
        if ([string]$entry.Value[0] -cne [string]$entry.Value[1]) {
            $mismatches += [string]$entry.Key
        }
    }
    foreach ($pathBinding in @(
            @("source_path", [string]$Proof.source_path, $SourcePath),
            @("original_path", [string]$Proof.original_path, $OriginalFilePath),
            @("focused_state_path", [string]$Proof.focused_state_path, $FocusedStatePath))) {
        if (-not ([string]$pathBinding[1]).Equals(
                [string]$pathBinding[2],
                [System.StringComparison]::OrdinalIgnoreCase)) {
            $mismatches += [string]$pathBinding[0]
        }
    }
    if ($mismatches.Count -ne 0) {
        throw ("Warm baseline proof is stale; mismatched binding(s): {0}." -f
            ($mismatches -join ", "))
    }
}

function New-WarmBaselineProof {
    param(
        $StateBinding,
        [string]$ConfigurationSha256,
        [string]$RunnerSha256,
        [string]$BuildScriptSha256,
        [string]$SourcePath,
        [string]$SourceSha256,
        [string]$OriginalFilePath,
        [string]$OriginalSha256,
        [string]$FocusedStatePath,
        [string]$CandidateNormalizedSha256,
        [string]$MapNormalizedSha256,
        [string]$FocusedObjectSha256
    )

    return [pscustomobject][ordered]@{
        schema_version = 1
        artifact_type = "otmatch-source-shape-warm-baseline"
        created_utc = [DateTime]::UtcNow.ToString("o")
        runner_sha256 = $RunnerSha256
        build_script_sha256 = $BuildScriptSha256
        configuration_sha256 = $ConfigurationSha256
        source_path = $SourcePath
        source_sha256 = $SourceSha256
        original_path = $OriginalFilePath
        original_sha256 = $OriginalSha256
        focused_state_path = $FocusedStatePath
        focused_state_sha256 = [string]$StateBinding.StateSha256
        focused_context_fingerprint = [string]$StateBinding.ContextFingerprint
        candidate_graph_fingerprint = [string]$StateBinding.GraphFingerprint
        source_graph_sha256 = [string]$StateBinding.SourceGraphSha256
        main_outputs_sha256 = [string]$StateBinding.MainOutputsSha256
        candidate_normalized_sha256 = $CandidateNormalizedSha256
        map_normalized_sha256 = $MapNormalizedSha256
        focused_object_sha256 = $FocusedObjectSha256
    }
}

function Get-CanonicalIdentityKey {
    param(
        [string]$Program,
        [string]$OriginalRvaText,
        [uint64]$OriginalRva
    )

    if ([string]::IsNullOrWhiteSpace($Program) -or
        [string]::IsNullOrWhiteSpace($OriginalRvaText)) {
        return ""
    }
    return ("{0}|0x{1}" -f
        $Program.Trim().ToLowerInvariant(),
        $OriginalRva.ToString("x"))
}

function Apply-Replacements([string]$Text, $Replacements) {
    if ($null -eq $Replacements) {
        return $Text
    }

    $updated = $Text
    foreach ($replacement in @($Replacements)) {
        $old = [string]$replacement.old
        $new = [string]$replacement.new
        if (-not $updated.Contains($old)) {
            throw "Replacement text was not found: $old"
        }

        $updated = $updated.Replace($old, $new)
    }

    return $updated
}

$planFullPath = Resolve-RepoPath $PlanPath
$parsedPlanBytes = [System.IO.File]::ReadAllBytes($planFullPath)
$parsedPlanSha256 = Get-BytesSha256Hex $parsedPlanBytes
$plan = Convert-TextBytesToString $parsedPlanBytes | ConvertFrom-Json
$generatedPlanSchema = $plan.PSObject.Properties["planSchemaVersion"]
$runnerScriptSha256 = Get-FileSha256Hex $PSCommandPath
$sourceFullPath = Resolve-RepoPath ([string]$plan.sourcePath)
Assert-SafeSourceShapePath $sourceFullPath
if ([string]::IsNullOrWhiteSpace($ResultCsvPath)) {
    $ResultCsvPath = Get-ConfiguredFullPath (
        Join-Path $BuildOutputDirectory "source-shape-variants.csv")
} else {
    $ResultCsvPath = Get-ConfiguredFullPath $ResultCsvPath
}
if ([string]::IsNullOrWhiteSpace($EvidenceJsonPath)) {
    $EvidenceJsonPath = [System.IO.Path]::ChangeExtension(
        $ResultCsvPath,
        "evidence.json")
} else {
    $EvidenceJsonPath = Get-ConfiguredFullPath $EvidenceJsonPath
}
$WarmBaselineProofPath = if ([string]::IsNullOrWhiteSpace($WarmBaselineProofPath)) {
    ""
} else {
    Get-ConfiguredFullPath $WarmBaselineProofPath
}
$resolvedBuildOutputDirectory = Get-ConfiguredFullPath $BuildOutputDirectory
$resolvedCandidatePath = Get-ConfiguredFullPath $CandidatePath
$resolvedCandidateMapPath = Get-ConfiguredFullPath $CandidateMapPath
$resolvedOriginalPath = Resolve-RepoPath $OriginalPath
$focusedBuildStatePath = Join-Path $resolvedBuildOutputDirectory `
    ".otmatch-focused-build-state.json"
$relativeSourcePath = $sourceFullPath.Substring($repoRoot.Length).
    TrimStart('\', '/')
$candidateObjectName = (($relativeSourcePath -replace '[\\/]', '_') -replace
    '\.cpp$', '.obj')
$candidateObjectPath = Join-Path $resolvedBuildOutputDirectory `
    $candidateObjectName
$reservedRunnerPaths = @{
    plan = $planFullPath
    source = $sourceFullPath
    original = $resolvedOriginalPath
    candidate = $resolvedCandidatePath
    candidate_map = $resolvedCandidateMapPath
    build_output = $resolvedBuildOutputDirectory
    focused_build_state = $focusedBuildStatePath
    focused_object = $candidateObjectPath
    build_script = $buildScript
    diff_script = $diffScript
    plan_preflight_script = $generatedPlanPreflightScript
}
Assert-SafeRunnerOutputPaths `
    -ResultPath $ResultCsvPath `
    -EvidencePath $EvidenceJsonPath `
    -WarmProofPath $WarmBaselineProofPath `
    -ReservedPaths $reservedRunnerPaths
$sourceLockStream = Enter-CandidateGraphLock
try {
Assert-SafeSourceShapePath $sourceFullPath
Assert-SafeRunnerOutputPaths `
    -ResultPath $ResultCsvPath `
    -EvidencePath $EvidenceJsonPath `
    -WarmProofPath $WarmBaselineProofPath `
    -ReservedPaths $reservedRunnerPaths
if ($null -ne $generatedPlanSchema) {
    if (-not (Test-Path -LiteralPath $generatedPlanPreflightScript -PathType Leaf)) {
        throw ("Generated source-shape plan requires preflight helper '{0}'." -f
            $generatedPlanPreflightScript)
    }

    # Generated plans bind their generator, manifest row, source bytes, and
    # exact replacement anchors. Re-run that fail-closed preflight while the
    # exclusive graph lock is held, before deleting old evidence or paying for
    # any candidate build. Legacy hand-authored plans remain supported.
    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $preflightOutput = & powershell `
            -NoProfile `
            -ExecutionPolicy Bypass `
            -File $generatedPlanPreflightScript `
            -PreflightOnly `
            -PlanPath $planFullPath 2>&1
        $preflightExitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($preflightExitCode -ne 0) {
        throw ("Generated source-shape plan preflight failed before build " +
            "or evidence mutation (exit $preflightExitCode):`n" +
            ($preflightOutput | Out-String))
    }
    if ((Get-FileSha256Hex $planFullPath) -cne $parsedPlanSha256) {
        throw ("Generated source-shape plan bytes changed across graph-lock " +
            "acquisition or external preflight; retry with the current plan.")
    }
    Write-Host ($preflightOutput | Out-String).TrimEnd()
}
$sourceEncoding = [System.Text.Encoding]::Default
$originalBytes = [System.IO.File]::ReadAllBytes($sourceFullPath)
$originalText = [System.IO.File]::ReadAllText($sourceFullPath, $sourceEncoding)
$baselineSourceSha256 = Get-BytesSha256Hex $originalBytes
if ($null -ne $generatedPlanSchema) {
    $sourcePreflight = Get-OptionalJsonValue $plan "sourcePreflight" $null
    if ($null -eq $sourcePreflight) {
        throw "Generated source-shape plan is missing sourcePreflight."
    }
    $plannedSourceSha256 = [string](Get-OptionalJsonValue `
        $sourcePreflight "sourceSha256" "")
    $plannedSourceLength = [long](Get-OptionalJsonValue `
        $sourcePreflight "sourceLength" -1)
    if ($plannedSourceSha256 -cnotmatch '^[0-9a-f]{64}$' -or
        $plannedSourceSha256 -cne $baselineSourceSha256 -or
        $plannedSourceLength -ne $originalBytes.LongLength) {
        throw ("Generated source-shape plan source binding changed after " +
            "preflight; regenerate the plan before running variants.")
    }
}
[void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $ResultCsvPath))
[void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $EvidenceJsonPath))
foreach ($staleOutputPath in @($ResultCsvPath, $EvidenceJsonPath)) {
    if (Test-Path -LiteralPath $staleOutputPath -PathType Leaf) {
        Remove-Item -LiteralPath $staleOutputPath -Force
    }
}
$planProgram = [string](Get-OptionalJsonValue $plan "program" "")
$planName = [string](Get-OptionalJsonValue $plan "name" "")
$planOriginalRvaText = [string](Get-OptionalJsonValue $plan "originalRva" "")
$checkpointId = [string](Get-OptionalJsonAliasValue `
    $plan @("checkpointId", "checkpoint_id") "")
$priorBoundaryRunId = [string](Get-OptionalJsonAliasValue `
    $plan @("priorBoundaryRunId", "prior_boundary_run_id") "")
$originalRva = Convert-HexNumber $planOriginalRvaText
$canonicalOriginalRva = if ([string]::IsNullOrWhiteSpace($planOriginalRvaText)) {
    ""
} else {
    "0x" + $originalRva.ToString("x")
}
$identityKey = Get-CanonicalIdentityKey `
    $planProgram $planOriginalRvaText $originalRva
$size = [int](Convert-HexNumber ([string]$plan.size))
$defaultSymbol = [string](Get-OptionalJsonValue $plan "candidateSymbol" "")
$symbolTemplate = [string](Get-OptionalJsonValue $plan "candidateSymbolTemplate" "")
$mask = [string](Get-OptionalJsonValue $plan "mask" "")

$evidenceSourcePath = $relativeSourcePath.Replace('\', '/')
$buildScriptSha256 = ""
$originalFileSha256 = ""
$warmConfigurationSha256 = ""
if (-not [string]::IsNullOrWhiteSpace($WarmBaselineProofPath)) {
    $buildScriptSha256 = Get-FileSha256Hex $buildScript
    $originalFileSha256 = Get-FileSha256Hex $resolvedOriginalPath
    $resolvedObjectCachePath = if ([string]::IsNullOrWhiteSpace($ObjectCacheDirectory)) {
        "<build-default>"
    } else {
        Get-ConfiguredFullPath $ObjectCacheDirectory
    }
    $warmConfigurationSha256 = Get-WarmBaselineConfigurationSha256 `
        -RunnerSha256 $runnerScriptSha256 `
        -BuildScriptSha256 $buildScriptSha256 `
        -SourcePath $sourceFullPath `
        -OriginalFilePath $resolvedOriginalPath `
        -OutputDirectory $resolvedBuildOutputDirectory `
        -CandidateFilePath $resolvedCandidatePath `
        -CandidateMapFilePath $resolvedCandidateMapPath `
        -FocusedStatePath $focusedBuildStatePath `
        -ObjectCachePath $resolvedObjectCachePath
}

$baselineBuildWatch = [System.Diagnostics.Stopwatch]::StartNew()
$baselineObjectSha256 = ""
$baselineCandidateNormalizedSha256 = ""
$baselineMapNormalizedSha256 = ""
$warmBaselineReused = $false
if (-not [string]::IsNullOrWhiteSpace($WarmBaselineProofPath) -and
    (Test-Path -LiteralPath $WarmBaselineProofPath -PathType Leaf)) {
    $warmProof = Read-WarmBaselineProof $WarmBaselineProofPath
    $preWarmState = Read-FocusedBuildStateBinding `
        -StatePath $focusedBuildStatePath `
        -ExpectedSourcePath $sourceFullPath `
        -ExpectedObjectName $candidateObjectName `
        -ExpectedCandidatePath $resolvedCandidatePath `
        -ExpectedMapPath $resolvedCandidateMapPath
    if (-not (Test-Path -LiteralPath $candidateObjectPath -PathType Leaf)) {
        throw "Warm baseline focused object is missing: '$candidateObjectPath'."
    }
    $preWarmCandidateSha256 = Get-NormalizedPeSha256Hex $resolvedCandidatePath
    $preWarmMapSha256 = Get-NormalizedMapSha256Hex $resolvedCandidateMapPath
    $preWarmObjectSha256 = Get-FileSha256Hex $candidateObjectPath
    Assert-WarmBaselineProofBinding `
        -Proof $warmProof `
        -StateBinding $preWarmState `
        -ConfigurationSha256 $warmConfigurationSha256 `
        -RunnerSha256 $runnerScriptSha256 `
        -BuildScriptSha256 $buildScriptSha256 `
        -SourcePath $sourceFullPath `
        -SourceSha256 $baselineSourceSha256 `
        -OriginalFilePath $resolvedOriginalPath `
        -OriginalSha256 $originalFileSha256 `
        -FocusedStatePath $focusedBuildStatePath `
        -CandidateNormalizedSha256 $preWarmCandidateSha256 `
        -MapNormalizedSha256 $preWarmMapSha256 `
        -FocusedObjectSha256 $preWarmObjectSha256

    # Reuse is still guarded by a complete, non-trusting focused validation.
    # The build script recomputes the current toolchain/context and graph
    # fingerprints, hashes every untouched object and dependency, recompiles
    # the focused source, and refreshes the state before any source mutation.
    Write-Host ("Warm baseline proof bindings accepted; validating: {0}" -f
        $WarmBaselineProofPath) -ForegroundColor Green
    Invoke-CandidateBuild `
        -ChangedSources @($sourceFullPath) `
        -Focused

    $postWarmState = Read-FocusedBuildStateBinding `
        -StatePath $focusedBuildStatePath `
        -ExpectedSourcePath $sourceFullPath `
        -ExpectedObjectName $candidateObjectName `
        -ExpectedCandidatePath $resolvedCandidatePath `
        -ExpectedMapPath $resolvedCandidateMapPath
    $baselineCandidateNormalizedSha256 =
        Get-NormalizedPeSha256Hex $resolvedCandidatePath
    $baselineMapNormalizedSha256 =
        Get-NormalizedMapSha256Hex $resolvedCandidateMapPath
    $baselineObjectSha256 = Get-FileSha256Hex $candidateObjectPath
    Assert-WarmBaselineProofBinding `
        -Proof $warmProof `
        -StateBinding $postWarmState `
        -ConfigurationSha256 $warmConfigurationSha256 `
        -RunnerSha256 $runnerScriptSha256 `
        -BuildScriptSha256 $buildScriptSha256 `
        -SourcePath $sourceFullPath `
        -SourceSha256 (Get-FileSha256Hex $sourceFullPath) `
        -OriginalFilePath $resolvedOriginalPath `
        -OriginalSha256 (Get-FileSha256Hex $resolvedOriginalPath) `
        -FocusedStatePath $focusedBuildStatePath `
        -CandidateNormalizedSha256 $baselineCandidateNormalizedSha256 `
        -MapNormalizedSha256 $baselineMapNormalizedSha256 `
        -FocusedObjectSha256 $baselineObjectSha256 `
        -IgnoreStateFileSha256
    $warmBaselineReused = $true
} else {
    Invoke-CandidateBuild
    if (Test-Path -LiteralPath $candidateObjectPath -PathType Leaf) {
        $baselineObjectSha256 = Get-FileSha256Hex $candidateObjectPath
    } elseif ([string]::IsNullOrWhiteSpace($BuildScriptOverride)) {
        throw "Baseline build did not produce the focused candidate object '$candidateObjectPath'."
    }

    # A normal seed can inherit VC4 PDB/link state from an older boundary.
    # Prove a fixed point before mutating source by forcing two byte-identical
    # main relinks through the same focused path used by trials/restoration.
    Invoke-CandidateBuild `
        -ChangedSources @($sourceFullPath) `
        -Focused `
        -TrustValidatedGraph `
        -ForceMainRelink
    $stabilizedCandidateSha256 = Get-NormalizedPeSha256Hex $resolvedCandidatePath
    $stabilizedMapSha256 = Get-NormalizedMapSha256Hex $resolvedCandidateMapPath
    $stabilizedObjectSha256 = if ([string]::IsNullOrWhiteSpace($baselineObjectSha256)) {
        ""
    } else {
        Get-FileSha256Hex $candidateObjectPath
    }

    Invoke-CandidateBuild `
        -ChangedSources @($sourceFullPath) `
        -Focused `
        -TrustValidatedGraph `
        -ForceMainRelink
    $baselineCandidateNormalizedSha256 = Get-NormalizedPeSha256Hex $resolvedCandidatePath
    $baselineMapNormalizedSha256 = Get-NormalizedMapSha256Hex $resolvedCandidateMapPath
    $baselineObjectSha256 = if ([string]::IsNullOrWhiteSpace($baselineObjectSha256)) {
        ""
    } else {
        Get-FileSha256Hex $candidateObjectPath
    }
    $fixedPointMismatches = @()
    if ($baselineCandidateNormalizedSha256 -ne $stabilizedCandidateSha256) {
        $fixedPointMismatches += ("DLL normalized relink1={0} relink2={1}" -f
            $stabilizedCandidateSha256, $baselineCandidateNormalizedSha256)
    }
    if ($baselineMapNormalizedSha256 -ne $stabilizedMapSha256) {
        $fixedPointMismatches += ("map normalized relink1={0} relink2={1}" -f
            $stabilizedMapSha256, $baselineMapNormalizedSha256)
    }
    if ($baselineObjectSha256 -ne $stabilizedObjectSha256) {
        $fixedPointMismatches += ("focused object relink1={0} relink2={1}" -f
            $stabilizedObjectSha256, $baselineObjectSha256)
    }
    if ($fixedPointMismatches.Count -gt 0) {
        throw ("Focused baseline did not reach a reproducible two-relink fixed point " +
            "before source mutation: " + ($fixedPointMismatches -join '; ') + ".")
    }
}
$baselineBuildWatch.Stop()
Write-Host ("Baseline setup mode: {0} ({1} ms)." -f
    $(if ($warmBaselineReused) {
            "warm proof reuse (one non-trusting focused validation)"
        } else {
            "cold seed plus two-relink fixed point"
        }),
    [long]$baselineBuildWatch.ElapsedMilliseconds)
$bestHardDiffCount = [int]::MaxValue
$baselineDiffDurationMs = 0L
if (-not [string]::IsNullOrWhiteSpace($defaultSymbol)) {
    $baselineDiffWatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $baselineDiff = Invoke-Diff $originalRva $size $defaultSymbol $mask
        if ($null -ne $baselineDiff.HardDiffCount) {
            $bestHardDiffCount = [int]$baselineDiff.HardDiffCount
        }
    } catch {
        Write-Warning ("Baseline symbol diff was unavailable; stop-loss improvement tracking starts with the first successful variant: {0}" -f
            $_.Exception.Message)
    } finally {
        $baselineDiffWatch.Stop()
        $baselineDiffDurationMs = [long]$baselineDiffWatch.ElapsedMilliseconds
    }
}

$results = @()
$restorationAttempted = $false
$restorationPassed = $false
$restoredSourceSha256 = ""
$restoredCandidateNormalizedSha256 = ""
$restoredMapNormalizedSha256 = ""
$restoredObjectSha256 = ""
$restorationDurationMs = 0L
$noImprovementCount = 0
$stopLossWatch = [System.Diagnostics.Stopwatch]::StartNew()
$stopReason = ""
try {
    foreach ($variant in @($plan.variants)) {
        if ($stopLossWatch.Elapsed.TotalMinutes -ge $StopLossMinutes) {
            $stopReason = "elapsed stop-loss reached ($StopLossMinutes minute(s))"
            break
        }
        if ($noImprovementCount -ge $MaxNoImprovementVariants) {
            $stopReason = "$MaxNoImprovementVariants meaningful variant(s) without hard-residual improvement"
            break
        }
        $name = [string](Get-OptionalJsonValue $variant "name" "")
        if ([string]::IsNullOrWhiteSpace($name)) {
            throw "Every variant must have a name."
        }

        $candidateSymbol = [string](Get-OptionalJsonValue $variant "candidateSymbol" "")
        if ([string]::IsNullOrWhiteSpace($candidateSymbol) -and
            -not [string]::IsNullOrWhiteSpace($symbolTemplate)) {
            $candidateSymbol = $symbolTemplate.Replace("{name}", $name)
        }
        if ([string]::IsNullOrWhiteSpace($candidateSymbol)) {
            $candidateSymbol = $defaultSymbol
        }
        if ([string]::IsNullOrWhiteSpace($candidateSymbol)) {
            throw "Variant '$name' does not provide a candidate symbol."
        }
        $hypothesis = [string](Get-OptionalJsonValue $variant "hypothesis" "")
        $meaningfulValue = Get-OptionalJsonValue $variant "meaningful" $true
        $meaningful = if ($meaningfulValue -is [bool]) {
            [bool]$meaningfulValue
        } else {
            [bool]::Parse(([string]$meaningfulValue).Trim())
        }

        Write-Host ("=== Variant: {0} ===" -f $name) -ForegroundColor Cyan
        $variantText = Apply-Replacements $originalText (
            Get-OptionalJsonValue $variant "replacements" @())
        $appendText = [string](Get-OptionalJsonValue $variant "append" "")
        if (-not [string]::IsNullOrEmpty($appendText)) {
            $variantText += $appendText
        }

        [System.IO.File]::WriteAllText($sourceFullPath, $variantText, $sourceEncoding)
        $sourceSha256 = Get-BytesSha256Hex ([System.IO.File]::ReadAllBytes($sourceFullPath))

        $status = "OK"
        $diff = $null
        $buildDurationMs = 0L
        $diffDurationMs = 0L
        $variantWatch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $buildWatch = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                Invoke-CandidateBuild -ChangedSources @($sourceFullPath) -Focused -TrustValidatedGraph
            } finally {
                $buildWatch.Stop()
                $buildDurationMs = [long]$buildWatch.ElapsedMilliseconds
            }
            $diffWatch = [System.Diagnostics.Stopwatch]::StartNew()
            try {
                $diff = Invoke-Diff $originalRva $size $candidateSymbol $mask
            } finally {
                $diffWatch.Stop()
                $diffDurationMs = [long]$diffWatch.ElapsedMilliseconds
            }
        } catch {
            $status = "FAIL: $($_.Exception.Message)"
        } finally {
            $variantWatch.Stop()
        }

        $result = [pscustomobject][ordered]@{
            Variant         = $name
            Status          = $status
            Hypothesis      = $hypothesis
            Meaningful      = $meaningful
            SourceSha256    = $sourceSha256
            CandidateSymbol = $candidateSymbol
            CandidateRva    = if ($diff) { $diff.CandidateRva } else { "" }
            DiffCount       = if ($diff) { $diff.DiffCount } else { "" }
            DiffOffsets     = if ($diff) { $diff.DiffOffsets } else { "" }
            RawDiffCount    = if ($diff) { $diff.DiffCount } else { "" }
            HardDiffCount   = if ($diff) { $diff.HardDiffCount } else { "" }
            HardComparedBytes = if ($diff) { $diff.HardComparedBytes } else { "" }
            HardDiffOffsets = if ($diff) { $diff.HardDiffOffsets } else { "" }
            BaselineBuildDurationMs = [long]$baselineBuildWatch.ElapsedMilliseconds
            BuildDurationMs = $buildDurationMs
            DiffDurationMs = $diffDurationMs
            TotalDurationMs = [long]$variantWatch.ElapsedMilliseconds
        }
        $results += $result
        if ($diff -and [int]$diff.HardDiffCount -lt $bestHardDiffCount) {
            $bestHardDiffCount = [int]$diff.HardDiffCount
            $noImprovementCount = 0
        } elseif ($meaningful) {
            $noImprovementCount++
        }
        # Checkpoint after every completed trial so a later process/build/diff
        # failure cannot discard earlier measurements from a long plan.
        $results | Export-Csv -LiteralPath $ResultCsvPath -NoTypeInformation
        # Keep interactive output compact; the durable CSV retains the full
        # raw and hard offset lists for later structural analysis.
        $result | Select-Object `
            Variant, Status, Meaningful, RawDiffCount, HardDiffCount,
            HardComparedBytes, BaselineBuildDurationMs, BuildDurationMs,
            DiffDurationMs, TotalDurationMs, SourceSha256 | Format-List
        $focusedBuildBudgetMs = [long]$MaximumFocusedBuildSeconds * 1000L
        $focusedDiffBudgetMs = [long]$MaximumFocusedDiffSeconds * 1000L
        if ([long]$result.BuildDurationMs -gt $focusedBuildBudgetMs) {
            $stopReason = ("focused-build latency budget exceeded ({0} ms > " +
                "{1} ms); investigate candidate-cache/graph performance before more variants") -f
                [long]$result.BuildDurationMs,
                $focusedBuildBudgetMs
            break
        }
        if ([long]$result.DiffDurationMs -gt $focusedDiffBudgetMs) {
            $stopReason = ("focused-diff latency budget exceeded ({0} ms > " +
                "{1} ms); investigate symbol-diff performance before more variants") -f
                [long]$result.DiffDurationMs,
                $focusedDiffBudgetMs
            break
        }
    }
} finally {
    $stopLossWatch.Stop()
    [System.IO.File]::WriteAllBytes($sourceFullPath, $originalBytes)
    $restoredSourceSha256 = Get-FileSha256Hex $sourceFullPath
    $restoreBuildFailure = $null
    if (-not $NoRestoreBuild) {
        $restorationAttempted = $true
        Write-Host "Restored source snapshot; rebuilding the focused baseline candidate..." -ForegroundColor Yellow
        $restorationWatch = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            Invoke-CandidateBuild -ChangedSources @($sourceFullPath) -Focused
            $restoredCandidateNormalizedSha256 = Get-NormalizedPeSha256Hex $resolvedCandidatePath
            $restoredMapNormalizedSha256 = Get-NormalizedMapSha256Hex $resolvedCandidateMapPath
            $restoredObjectSha256 = if ([string]::IsNullOrWhiteSpace($baselineObjectSha256)) {
                ""
            } elseif (Test-Path -LiteralPath $candidateObjectPath -PathType Leaf) {
                Get-FileSha256Hex $candidateObjectPath
            } else {
                "missing"
            }
            if ($restoredCandidateNormalizedSha256 -ne $baselineCandidateNormalizedSha256 -or
                $restoredMapNormalizedSha256 -ne $baselineMapNormalizedSha256 -or
                $restoredObjectSha256 -ne $baselineObjectSha256) {
                throw ("Focused restoration did not reproduce the pre-plan candidate content " +
                    "after normalizing VC4 linker timestamps and validated " +
                    "IMAGE_DEBUG_MISC reserved bytes (DLL/map/object).")
            }
            $restorationPassed = $true
        } catch {
            $restoreBuildFailure = $_
        } finally {
            $restorationWatch.Stop()
            $restorationDurationMs = [long]$restorationWatch.ElapsedMilliseconds
            Write-Host ("Restoration verification duration: {0} ms" -f $restorationDurationMs)
        }
    } else {
        Write-Host "Restored source snapshot. Candidate DLL still reflects the last variant build." -ForegroundColor Yellow
    }
    # Preserve every completed trial even when the mandatory restoration build
    # fails. The failure is rethrown after the durable CSV is written.
    $results | Export-Csv -LiteralPath $ResultCsvPath -NoTypeInformation

    $warmProofPublishFailure = $null
    if (-not [string]::IsNullOrWhiteSpace($WarmBaselineProofPath) -and
        $restorationPassed) {
        try {
            if ((Get-FileSha256Hex $PSCommandPath) -cne $runnerScriptSha256 -or
                (Get-FileSha256Hex $buildScript) -cne $buildScriptSha256) {
                throw "Runner or build script changed during the source-shape session."
            }
            $restoredStateBinding = Read-FocusedBuildStateBinding `
                -StatePath $focusedBuildStatePath `
                -ExpectedSourcePath $sourceFullPath `
                -ExpectedObjectName $candidateObjectName `
                -ExpectedCandidatePath $resolvedCandidatePath `
                -ExpectedMapPath $resolvedCandidateMapPath
            if ([string]$restoredStateBinding.FocusedObjectSha256 -cne
                    $restoredObjectSha256 -or
                (Get-FileSha256Hex $resolvedOriginalPath) -cne
                    $originalFileSha256) {
                throw "Warm baseline inputs changed after restoration validation."
            }
            $newWarmProof = New-WarmBaselineProof `
                -StateBinding $restoredStateBinding `
                -ConfigurationSha256 $warmConfigurationSha256 `
                -RunnerSha256 $runnerScriptSha256 `
                -BuildScriptSha256 $buildScriptSha256 `
                -SourcePath $sourceFullPath `
                -SourceSha256 $restoredSourceSha256 `
                -OriginalFilePath $resolvedOriginalPath `
                -OriginalSha256 $originalFileSha256 `
                -FocusedStatePath $focusedBuildStatePath `
                -CandidateNormalizedSha256 $restoredCandidateNormalizedSha256 `
                -MapNormalizedSha256 $restoredMapNormalizedSha256 `
                -FocusedObjectSha256 $restoredObjectSha256
            Write-JsonAtomically $WarmBaselineProofPath $newWarmProof
            Write-Host ("Warm baseline proof refreshed: {0}" -f
                $WarmBaselineProofPath) -ForegroundColor Green
        } catch {
            $warmProofPublishFailure = $_
        }
    }

    $successfulResult = @($results | Where-Object {
            $_.Status -eq "OK" -and
            [bool]$_.Meaningful -and
            -not [string]::IsNullOrWhiteSpace([string]$_.Hypothesis) -and
            -not [string]::IsNullOrWhiteSpace([string]$_.HardDiffCount) -and
            [int]$_.HardDiffCount -eq 0 -and
            [int]$_.HardComparedBytes -gt 0 -and
            -not [string]::IsNullOrWhiteSpace([string]$_.SourceSha256)
        } | Select-Object -First 1)
    $successfulTrial = $null
    if ($successfulResult.Count -eq 1) {
        $row = $successfulResult[0]
        $successfulTrial = [pscustomobject][ordered]@{
            variant = [string]$row.Variant
            status = [string]$row.Status
            hypothesis = [string]$row.Hypothesis
            meaningful = [bool]$row.Meaningful
            source_sha256 = [string]$row.SourceSha256
            candidate_symbol = [string]$row.CandidateSymbol
            candidate_rva = [string]$row.CandidateRva
            raw_diff_count = [int]$row.RawDiffCount
            hard_diff_count = [int]$row.HardDiffCount
            hard_compared_bytes = [int]$row.HardComparedBytes
            build_duration_ms = [long]$row.BuildDurationMs
            diff_duration_ms = [long]$row.DiffDurationMs
            total_duration_ms = [long]$row.TotalDurationMs
        }
    }

    $identityComplete = -not [string]::IsNullOrWhiteSpace($identityKey) -and
        -not [string]::IsNullOrWhiteSpace($planProgram) -and
        -not [string]::IsNullOrWhiteSpace($planName) -and
        -not [string]::IsNullOrWhiteSpace($canonicalOriginalRva)
    $checkpointComplete = -not [string]::IsNullOrWhiteSpace($checkpointId) -and
        -not [string]::IsNullOrWhiteSpace($priorBoundaryRunId)
    $missingRestorationHashes = @(@(
            $baselineCandidateNormalizedSha256,
            $restoredCandidateNormalizedSha256,
            $baselineMapNormalizedSha256,
            $restoredMapNormalizedSha256,
            $baselineObjectSha256,
            $restoredObjectSha256
        ) | Where-Object { [string]::IsNullOrWhiteSpace([string]$_) })
    $promotionEligible = (-not $Exploration) -and
        $identityComplete -and
        $checkpointComplete -and
        $null -ne $successfulTrial -and
        $restorationAttempted -and
        $restorationPassed -and
        $missingRestorationHashes.Count -eq 0 -and
        $baselineCandidateNormalizedSha256 -eq $restoredCandidateNormalizedSha256 -and
        $baselineMapNormalizedSha256 -eq $restoredMapNormalizedSha256 -and
        $baselineObjectSha256 -eq $restoredObjectSha256 -and
        $baselineSourceSha256 -eq $restoredSourceSha256

    $trialToolTimeMs = 0L
    $trialWallTimeMs = 0L
    foreach ($timedResult in @($results)) {
        $trialToolTimeMs += [long]$timedResult.BuildDurationMs +
            [long]$timedResult.DiffDurationMs
        $trialWallTimeMs += [long]$timedResult.TotalDurationMs
    }
    $focusedBuildBudgetMs = [long]$MaximumFocusedBuildSeconds * 1000L
    $focusedDiffBudgetMs = [long]$MaximumFocusedDiffSeconds * 1000L
    $buildLatencyBudgetExceeded = @($results | Where-Object {
            [long]$_.BuildDurationMs -gt $focusedBuildBudgetMs
        }).Count -gt 0
    $diffLatencyBudgetExceeded = @($results | Where-Object {
            [long]$_.DiffDurationMs -gt $focusedDiffBudgetMs
        }).Count -gt 0

    $evidence = [pscustomobject][ordered]@{
        schema_version = 1
        artifact_type = "otwin-source-shape-evidence"
        runner = [pscustomobject][ordered]@{
            name = "otmatch-source-shape-runner"
            schema_version = 1
            script_path = "tools/otmatch/invoke-source-shape-variants.ps1"
            script_sha256 = $runnerScriptSha256
        }
        identity = [pscustomobject][ordered]@{
            key = $identityKey
            program = $planProgram.Trim()
            name = $planName.Trim()
            original_rva = $canonicalOriginalRva
        }
        checkpoint = [pscustomobject][ordered]@{
            checkpoint_id = $checkpointId
            prior_boundary_run_id = $priorBoundaryRunId
        }
        source = [pscustomobject][ordered]@{
            path = $evidenceSourcePath
            baseline_sha256 = $baselineSourceSha256
            restored_sha256 = $restoredSourceSha256
        }
        successful_trial = $successfulTrial
        restoration = [pscustomobject][ordered]@{
            attempted = $restorationAttempted
            passed = $restorationPassed
            used_trusted_graph = $false
            baseline_candidate_normalized_sha256 = $baselineCandidateNormalizedSha256
            restored_candidate_normalized_sha256 = $restoredCandidateNormalizedSha256
            baseline_map_normalized_sha256 = $baselineMapNormalizedSha256
            restored_map_normalized_sha256 = $restoredMapNormalizedSha256
            baseline_object_sha256 = $baselineObjectSha256
            restored_object_sha256 = $restoredObjectSha256
        }
        run_summary = [pscustomobject][ordered]@{
            warm_baseline_reused = [bool]$warmBaselineReused
            baseline_setup_duration_ms = [long]$baselineBuildWatch.ElapsedMilliseconds
            baseline_diff_duration_ms = [long]$baselineDiffDurationMs
            trial_count = @($results).Count
            meaningful_trial_count = @($results | Where-Object {
                    [bool]$_.Meaningful
                }).Count
            trial_tool_time_ms = $trialToolTimeMs
            trial_wall_time_ms = $trialWallTimeMs
            variant_loop_duration_ms = [long]$stopLossWatch.ElapsedMilliseconds
            restoration_duration_ms = [long]$restorationDurationMs
            runner_elapsed_before_evidence_ms = [long]$runnerWatch.ElapsedMilliseconds
            maximum_focused_build_seconds = $MaximumFocusedBuildSeconds
            maximum_focused_diff_seconds = $MaximumFocusedDiffSeconds
            build_latency_budget_exceeded = [bool]$buildLatencyBudgetExceeded
            diff_latency_budget_exceeded = [bool]$diffLatencyBudgetExceeded
            stop_reason = $stopReason
        }
        promotion_eligible = [bool]$promotionEligible
    }
    if ($Exploration) {
        $evidence | Add-Member -NotePropertyName "mode" `
            -NotePropertyValue "exploration"
        $evidence | Add-Member -NotePropertyName "promotion_ineligible_reason" `
            -NotePropertyValue ("Exploration mode is diagnostic-only; reproduce " +
                "the selected variant in promotion mode.")
    }
    Write-JsonAtomically $EvidenceJsonPath $evidence
    if ($null -ne $restoreBuildFailure) {
        throw $restoreBuildFailure
    }
    if ($null -ne $warmProofPublishFailure) {
        throw $warmProofPublishFailure
    }
}

if (-not [string]::IsNullOrWhiteSpace($stopReason)) {
    Write-Host ("Variant stop-loss: {0}." -f $stopReason) -ForegroundColor Yellow
}
Write-Host ("Variant results: {0}" -f $ResultCsvPath)
Write-Host ("Variant evidence: {0}" -f $EvidenceJsonPath)
$results | Sort-Object HardDiffCount, RawDiffCount, Variant |
    Select-Object Variant, Status, Meaningful, RawDiffCount, HardDiffCount,
        HardComparedBytes, BuildDurationMs, DiffDurationMs, TotalDurationMs |
    Format-Table -AutoSize
} finally {
    $sourceLockStream.Dispose()
}
