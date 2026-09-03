[CmdletBinding()]
param(
    [ValidateSet("baseline", "promotion-wave", "final")]
    [string]$Phase = "baseline",

    # Planning is the safe default. No compiler, original image, product
    # resource, test runner, or Git command is invoked without this switch.
    [switch]$Execute,

    [string]$SessionId = "",
    [string]$CheckpointId = "",
    [ValidateRange(0.0, 100.0)]
    [double]$MinimumInstructionPercent = 0.0,
    [ValidateRange(0, [long]::MaxValue)]
    [long]$MinimumInstructionGain = 0,
    [string]$PromotionEvidencePath = "",
    [string]$OutputRoot = "artifacts\otmatch\sessions",
    [string]$VcToolsRoot = "C:\MSDEV",
    [string]$OriginalExePath = "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe",
    [string]$OriginalDllPath = "Sample\Oregon Trail CD\OTWIN32\OREGON32.DLL",
    [string]$ManifestPath = "tools\otmatch\functions.vc40-real-cpp.csv",
    [string]$ResourceRoot = "resources\otwin32",
    [string]$BuildDirectory = "build",
    [string]$ViewerSolution = "OregonTrailViewer.slnx",
    [string]$PowerShellExecutable = "powershell.exe",
    [ValidateRange(0, 300000)]
    [int]$SessionLockTimeoutMilliseconds = 30000
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

if ([double]::IsNaN($MinimumInstructionPercent) -or
    [double]::IsInfinity($MinimumInstructionPercent)) {
    throw "MinimumInstructionPercent must be a finite value from 0 through 100."
}
if ($Phase -eq "final" -and $MinimumInstructionPercent -le 0.0) {
    throw "The final phase requires -MinimumInstructionPercent greater than zero."
}
if ($Phase -eq "promotion-wave" -and $MinimumInstructionGain -le 0) {
    throw "The promotion-wave phase requires -MinimumInstructionGain greater than zero."
}
if ($Phase -eq "baseline" -and
    -not [string]::IsNullOrWhiteSpace($PromotionEvidencePath)) {
    throw "PromotionEvidencePath is only valid for promotion-wave or final phases."
}

if ([string]::IsNullOrWhiteSpace($CheckpointId)) {
    if ($Phase -eq "promotion-wave") {
        throw "The promotion-wave phase requires an explicit -CheckpointId (for example, wave-1000)."
    }
    $CheckpointId = $Phase
}
$CheckpointId = $CheckpointId.Trim()
if ($CheckpointId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
    throw "CheckpointId must contain only letters, digits, dot, underscore, or hyphen and may not begin with punctuation."
}

function Get-ContainedRepoPath {
    param(
        [string]$RelativePath,
        [string]$Description
    )

    if ([System.IO.Path]::IsPathRooted($RelativePath)) {
        throw "$Description must be repository-relative: '$RelativePath'."
    }

    $absolute = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $RelativePath))
    $repoPrefix = $repoRoot.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    if (-not $absolute.StartsWith(
        $repoPrefix,
        [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "$Description escaped the repository: '$RelativePath'."
    }

    return $absolute
}

function Assert-ConventionalOutputRoot {
    param(
        [string]$AbsolutePath,
        [switch]$SkipGitIgnore
    )

    $allowedRoots = @(
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot "a")),
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot "artifacts"))
    )
    $matchedRoot = $null
    foreach ($allowedRoot in $allowedRoots) {
        $allowedPrefix = $allowedRoot.TrimEnd('\', '/') +
            [System.IO.Path]::DirectorySeparatorChar
        if ($AbsolutePath.Equals(
                $allowedRoot,
                [System.StringComparison]::OrdinalIgnoreCase) -or
            $AbsolutePath.StartsWith(
                $allowedPrefix,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            $matchedRoot = $allowedRoot
            break
        }
    }
    if ($null -eq $matchedRoot) {
        throw ("OutputRoot must resolve beneath the repository's ignored " +
            "'a' or 'artifacts' root: '$AbsolutePath'.")
    }

    $current = $AbsolutePath
    while ($true) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (-not $item.PSIsContainer) {
                throw "Recovery output ancestor is not a directory: '$current'."
            }
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Recovery output has a reparse-point ancestor: '$current'."
            }
        }
        if ($current.Equals(
                $matchedRoot,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            break
        }
        $parent = [System.IO.Path]::GetDirectoryName($current)
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -ceq $current) {
            throw "Could not validate recovery output ancestry: '$AbsolutePath'."
        }
        $current = $parent
    }

    if (-not $SkipGitIgnore) {
        $repoPrefix = $repoRoot.TrimEnd('\', '/') +
            [System.IO.Path]::DirectorySeparatorChar
        $relativePath = $AbsolutePath.Substring($repoPrefix.Length).Replace('\', '/')
        & git -C $repoRoot check-ignore -q -- $relativePath
        if ($LASTEXITCODE -ne 0) {
            throw "Recovery output path is not Git-ignored: '$AbsolutePath'."
        }
    }
}

function Get-RequiredFilePath {
    param(
        [string]$Path,
        [string]$Description
    )

    $absolute = if ([System.IO.Path]::IsPathRooted($Path)) {
        [System.IO.Path]::GetFullPath($Path)
    }
    else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
    }
    if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
        throw "$Description was not found: '$absolute'."
    }
    return $absolute
}

function Get-FileSha256Hex {
    param([string]$Path)

    $stream = [System.IO.File]::OpenRead($Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($sha.ComputeHash($stream) | ForEach-Object {
            $_.ToString("x2")
        }) -join "")
    }
    finally {
        $sha.Dispose()
        $stream.Dispose()
    }
}

function Get-TextSha256Hex {
    param([string[]]$Lines)

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

function New-FileHashRecord {
    param(
        [string]$Name,
        [string]$Path,
        [string]$Description
    )

    $absolute = Get-RequiredFilePath $Path $Description
    return [pscustomobject][ordered]@{
        name = $Name
        path = $absolute
        sha256 = Get-FileSha256Hex $absolute
    }
}

function New-DirectoryTreeHashRecord {
    param(
        [string]$Name,
        [string]$Path,
        [string]$Description
    )

    $absolute = if ([System.IO.Path]::IsPathRooted($Path)) {
        [System.IO.Path]::GetFullPath($Path)
    }
    else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
    }
    if (-not (Test-Path -LiteralPath $absolute -PathType Container)) {
        throw "$Description was not found: '$absolute'."
    }
    $absolute = (Resolve-Path -LiteralPath $absolute).Path
    $prefix = $absolute.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    $filesByRelativePath = @{}
    foreach ($file in @(Get-ChildItem -LiteralPath $absolute -Recurse -File -Force)) {
        $relativePath = $file.FullName.Substring($prefix.Length).
            Replace('\', '/').ToLowerInvariant()
        if ($filesByRelativePath.ContainsKey($relativePath)) {
            throw "$Description contains a duplicate normalized path '$relativePath'."
        }
        $filesByRelativePath[$relativePath] = $file
    }
    if ($filesByRelativePath.Count -eq 0) {
        throw "$Description contains no files: '$absolute'."
    }

    [string[]]$relativePaths = @($filesByRelativePath.Keys)
    [Array]::Sort($relativePaths, [System.StringComparer]::Ordinal)
    $identityLines = @()
    [uint64]$totalBytes = 0
    foreach ($relativePath in $relativePaths) {
        $file = $filesByRelativePath[$relativePath]
        $totalBytes += [uint64]$file.Length
        $identityLines += ("{0}|bytes={1}|sha256={2}" -f
            $relativePath, $file.Length, (Get-FileSha256Hex $file.FullName))
    }

    return [pscustomobject][ordered]@{
        name = $Name
        path = $absolute
        sha256 = Get-TextSha256Hex $identityLines
        file_count = [uint64]$relativePaths.Count
        total_bytes = $totalBytes
    }
}

function Enter-SessionLock {
    param(
        [string]$Path,
        [int]$TimeoutMilliseconds
    )

    $parent = Split-Path -Parent $Path
    [void][System.IO.Directory]::CreateDirectory($parent)
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    while ($true) {
        try {
            if (Test-Path -LiteralPath $Path) {
                $lockItem = Get-Item -LiteralPath $Path -Force
                if ($lockItem.PSIsContainer -or
                    ($lockItem.Attributes -band
                        [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                    throw "Recovery-wave session lock path is unsafe: '$Path'."
                }
            }
            $stream = [System.IO.File]::Open(
                $Path,
                [System.IO.FileMode]::OpenOrCreate,
                [System.IO.FileAccess]::ReadWrite,
                [System.IO.FileShare]::None)
            $metadata = "pid=$PID acquired_utc=$([DateTime]::UtcNow.ToString('o'))`r`n"
            $bytes = [System.Text.Encoding]::ASCII.GetBytes($metadata)
            $stream.SetLength(0)
            $stream.Write($bytes, 0, $bytes.Length)
            $stream.Flush()
            return $stream
        }
        catch [System.IO.IOException] {
            if ($stopwatch.ElapsedMilliseconds -ge $TimeoutMilliseconds) {
                throw (("Timed out after {0} ms acquiring exclusive " +
                    "recovery-wave session lock '{1}'.") -f
                    $TimeoutMilliseconds, $Path)
            }
            $remaining = $TimeoutMilliseconds -
                [int]$stopwatch.ElapsedMilliseconds
            Start-Sleep -Milliseconds ([Math]::Max(1, [Math]::Min(100, $remaining)))
        }
    }
}

function Exit-SessionLock {
    param($Stream)

    if ($null -ne $Stream) {
        $Stream.Dispose()
    }
}

function Get-GateSemanticsSnapshot {
    param([System.Collections.IDictionary]$ToolPaths)

    $tools = @()
    foreach ($entry in @($ToolPaths.GetEnumerator() | Sort-Object Key)) {
        $tools += New-FileHashRecord `
            ([string]$entry.Key) ([string]$entry.Value) `
            ("Recovery gate tool '{0}'" -f $entry.Key)
    }

    $processRunner = Get-Command -Name $PowerShellExecutable `
        -CommandType Application -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($null -eq $processRunner -or
        [string]::IsNullOrWhiteSpace([string]$processRunner.Path)) {
        # Preserve normal step-level failure evidence for a missing runner. A
        # passed boundary can never contain this record because the first
        # process step will fail, but the attempted semantics remain explicit.
        $tools += [pscustomobject][ordered]@{
            name = "process_runner"
            path = $PowerShellExecutable
            sha256 = ""
        }
    }
    else {
        $tools += New-FileHashRecord `
            "process_runner" ([string]$processRunner.Path) `
            "Recovery process runner"
    }

    $vcToolsRootAbsolute = if ([System.IO.Path]::IsPathRooted($VcToolsRoot)) {
        [System.IO.Path]::GetFullPath($VcToolsRoot)
    }
    else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $VcToolsRoot))
    }
    $immutableInputs = @(
        (New-FileHashRecord "original_exe" $OriginalExePath "Original EXE"),
        (New-FileHashRecord "original_dll" $OriginalDllPath "Original DLL"),
        (New-FileHashRecord "metrics_exe" `
            "tools\ghidra\otwin32\output\function_metrics_oregon32_exe.csv" `
            "EXE function metrics"),
        (New-FileHashRecord "metrics_dll" `
            "tools\ghidra\otwin32\output\function_metrics_oregon32_dll.csv" `
            "DLL function metrics"),
        (New-FileHashRecord "vc4_cl" (Join-Path $vcToolsRootAbsolute "BIN\CL.EXE") `
            "Visual C++ 4.0 compiler"),
        (New-FileHashRecord "vc4_link" (Join-Path $vcToolsRootAbsolute "BIN\LINK.EXE") `
            "Visual C++ 4.0 linker")
    )
    $mutableInputs = @(
        (New-FileHashRecord "manifest" $ManifestPath "Function manifest"),
        (New-FileHashRecord "exe_product_sources" `
            "tools\otmatch\vc4-exe-product-sources.txt" `
            "EXE Product source manifest"),
        (New-FileHashRecord "vc4_tu_metadata" `
            "tools\otmatch\vc4-tu-metadata.csv" `
            "VC4 translation-unit metadata")
    )
    $payloadTrees = @(
        (New-DirectoryTreeHashRecord "vc4_bin" `
            (Join-Path $vcToolsRootAbsolute "BIN") "Visual C++ 4.0 BIN payload"),
        (New-DirectoryTreeHashRecord "vc4_include" `
            (Join-Path $vcToolsRootAbsolute "INCLUDE") "Visual C++ 4.0 INCLUDE tree"),
        (New-DirectoryTreeHashRecord "vc4_lib" `
            (Join-Path $vcToolsRootAbsolute "LIB") "Visual C++ 4.0 LIB tree"),
        (New-DirectoryTreeHashRecord "product_resources" `
            $ResourceRoot "Product resource tree")
    )
    foreach ($optionalTree in @(
            [pscustomobject]@{
                Name = "vc4_atl_include"
                Path = Join-Path $vcToolsRootAbsolute "ATL\INCLUDE"
            },
            [pscustomobject]@{
                Name = "vc4_mfc_include"
                Path = Join-Path $vcToolsRootAbsolute "MFC\INCLUDE"
            },
            [pscustomobject]@{
                Name = "vc4_mfc_lib"
                Path = Join-Path $vcToolsRootAbsolute "MFC\LIB"
            })) {
        if (Test-Path -LiteralPath $optionalTree.Path -PathType Container) {
            $payloadTrees += New-DirectoryTreeHashRecord `
                $optionalTree.Name $optionalTree.Path `
                ("Visual C++ 4.0 payload '{0}'" -f $optionalTree.Name)
        }
    }
    $policy = [ordered]@{
        candidate_default_optimization = "/Od"
        candidate_semantic_optimization = "/O1"
        complete_matcher = $true
        validated_masks_required = $true
        product_reachability_required = $true
        product_exe_graph = "Product"
        strict_product_links = $true
        include_non_text_metrics = $false
        process_include_environment = [string][Environment]::GetEnvironmentVariable(
            "INCLUDE", "Process")
        process_lib_environment = [string][Environment]::GetEnvironmentVariable(
            "LIB", "Process")
        process_cl_environment = [string][Environment]::GetEnvironmentVariable(
            "CL", "Process")
        process_post_cl_environment = [string][Environment]::GetEnvironmentVariable(
            "_CL_", "Process")
        process_link_environment = [string][Environment]::GetEnvironmentVariable(
            "LINK", "Process")
        process_post_link_environment = [string][Environment]::GetEnvironmentVariable(
            "_LINK_", "Process")
    }

    $canonical = @()
    foreach ($record in @($tools | Sort-Object name)) {
        $canonical += "tool|$($record.name)|$($record.sha256)"
    }
    foreach ($record in @($immutableInputs | Sort-Object name)) {
        $canonical += "immutable-input|$($record.name)|$($record.sha256)"
    }
    foreach ($record in @($payloadTrees | Sort-Object name)) {
        $canonical += ("payload-tree|{0}|{1}|{2}|files={3}|bytes={4}" -f
            $record.name, ([string]$record.path).ToLowerInvariant(),
            $record.sha256, $record.file_count, $record.total_bytes)
    }
    foreach ($key in @($policy.Keys | Sort-Object)) {
        $canonical += "policy|$key|$($policy[$key])"
    }

    $executionCanonical = @($canonical)
    foreach ($record in @($mutableInputs | Sort-Object name)) {
        $executionCanonical += "mutable-input|$($record.name)|$($record.sha256)"
    }

    return [pscustomobject][ordered]@{
        schema_version = 1
        gate_semantics_sha256 = Get-TextSha256Hex $canonical
        execution_snapshot_sha256 = Get-TextSha256Hex $executionCanonical
        tools = @($tools)
        immutable_inputs = @($immutableInputs)
        mutable_inputs = @($mutableInputs)
        payload_trees = @($payloadTrees)
        policy = [pscustomobject]$policy
    }
}

function Format-CommandToken {
    param([string]$Token)

    if ($Token -notmatch '[\s''"]') {
        return $Token
    }
    return "'" + $Token.Replace("'", "''") + "'"
}

function Format-CommandLine {
    param(
        [string]$Executable,
        [string[]]$Arguments
    )

    $tokens = @((Format-CommandToken $Executable))
    foreach ($argument in $Arguments) {
        $tokens += Format-CommandToken ([string]$argument)
    }
    return ($tokens -join " ")
}

function New-ProcessStep {
    param(
        [string]$Name,
        [string]$Category,
        [string]$Executable,
        [string[]]$Arguments
    )

    return [pscustomobject][ordered]@{
        name = $Name
        category = $Category
        kind = "process"
        executable = $Executable
        arguments = @($Arguments)
        command = Format-CommandLine $Executable $Arguments
        status = "planned"
        started_utc = ""
        completed_utc = ""
        duration_ms = 0
        exit_code = $null
        log_path = ""
        output_tail = @()
        error = ""
    }
}

function New-InternalStep {
    param(
        [string]$Name,
        [string]$Category,
        [string]$Command
    )

    return [pscustomobject][ordered]@{
        name = $Name
        category = $Category
        kind = "internal"
        executable = ""
        arguments = @()
        command = $Command
        status = "planned"
        started_utc = ""
        completed_utc = ""
        duration_ms = 0
        exit_code = $null
        log_path = ""
        output_tail = @()
        error = ""
    }
}

function Write-SessionLedger {
    param(
        $Ledger,
        [string]$Path
    )

    $temporaryPath = "$Path.tmp-$PID"
    $Ledger | ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $temporaryPath -Encoding UTF8
    Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
}

function Get-OutputTail {
    param(
        [string[]]$Lines,
        [int]$Count = 20
    )

    if ($Lines.Count -le $Count) {
        return @($Lines)
    }
    return @($Lines[($Lines.Count - $Count)..($Lines.Count - 1)])
}

function Invoke-ProcessStep {
    param(
        $Step,
        [string]$LogPath
    )

    $command = Get-Command -Name $Step.executable -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($null -eq $command) {
        throw "Executable was not found for step '$($Step.name)': '$($Step.executable)'."
    }

    $lines = New-Object System.Collections.ArrayList
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $Step.executable @($Step.arguments) 2>&1 | ForEach-Object {
            $line = [string]$_
            [void]$lines.Add($line)
            Write-Host $line
        }
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousPreference
    }

    @($lines) | Set-Content -LiteralPath $LogPath -Encoding UTF8
    return [pscustomobject]@{
        ExitCode = [int]$exitCode
        Lines = @($lines)
    }
}

function Invoke-GitCapture {
    param([string[]]$Arguments)

    $lines = @(& git @Arguments 2>&1 | ForEach-Object { [string]$_ })
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed: $($lines -join [Environment]::NewLine)"
    }
    return $lines
}

function Invoke-GitSearchCapture {
    param([string[]]$Arguments)

    $lines = @(& git @Arguments 2>&1 | ForEach-Object { [string]$_ })
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0) {
        return $lines
    }
    if ($exitCode -eq 1) {
        return @()
    }
    throw "git $($Arguments -join ' ') failed: $($lines -join [Environment]::NewLine)"
}

function Get-GitSnapshot {
    $commitLines = @(Invoke-GitCapture @("rev-parse", "--verify", "HEAD"))
    if ($commitLines.Count -ne 1 -or
        $commitLines[0].Trim() -notmatch '^[0-9a-fA-F]{40}$') {
        throw "Could not capture a unique 40-character HEAD commit SHA."
    }
    $statusLines = @(Invoke-GitCapture @(
        "status", "--porcelain=v1", "--untracked-files=all"))
    $headDiffLines = @(Invoke-GitCapture @(
        "diff", "--binary", "--no-ext-diff", "HEAD", "--", "."))
    $indexDiffLines = @(Invoke-GitCapture @(
        "diff", "--cached", "--binary", "--no-ext-diff", "HEAD", "--", "."))
    [string[]]$untrackedPaths = @(Invoke-GitCapture @(
        "ls-files", "--others", "--exclude-standard"))
    [Array]::Sort($untrackedPaths, [System.StringComparer]::Ordinal)
    $stateLines = @($statusLines | ForEach-Object { "status|$_" })
    $stateLines += @($headDiffLines | ForEach-Object { "head-diff|$_" })
    $stateLines += @($indexDiffLines | ForEach-Object { "index-diff|$_" })
    foreach ($path in $untrackedPaths) {
        $absolutePath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $path))
        if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
            throw "Untracked path changed while capturing Git state: '$path'."
        }
        $stateLines += "untracked|$path|$(Get-FileSha256Hex $absolutePath)"
    }
    return [pscustomobject]@{
        Commit = $commitLines[0].Trim().ToLowerInvariant()
        WorktreeStatus = @($statusLines)
        WorktreeStateSha256 = Get-TextSha256Hex $stateLines
    }
}

function Test-GitAncestor {
    param(
        [string]$Ancestor,
        [string]$Descendant
    )

    $output = @(& git -C $repoRoot "merge-base" "--is-ancestor" `
        $Ancestor $Descendant 2>&1 |
        ForEach-Object { [string]$_ })
    $exitCode = $LASTEXITCODE
    if ($exitCode -eq 0) {
        return $true
    }
    if ($exitCode -eq 1) {
        return $false
    }
    throw ("git merge-base --is-ancestor failed for '$Ancestor' and " +
        "'$Descendant': $($output -join [Environment]::NewLine)")
}

function Read-MetricsSummary {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Metrics reporter did not produce its machine-readable summary: '$Path'."
    }
    $summary = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ([int]$summary.schema_version -ne 2) {
        throw "Unsupported metrics summary schema in '$Path'."
    }
    if ($null -eq $summary.denominator -or $null -eq $summary.strict) {
        throw "Metrics summary is missing denominator/strict evidence: '$Path'."
    }
    if ($null -eq $summary.inputs -or $null -eq $summary.inputs.manifest) {
        throw "Metrics summary is missing manifest identity evidence: '$Path'."
    }

    $identities = @($summary.strict.accepted_identities | ForEach-Object {
        [string]$_
    })
    if (@($identities | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -ne 0) {
        throw "Metrics summary contains an empty accepted identity: '$Path'."
    }
    $sortedIdentities = [string[]]@($identities)
    [Array]::Sort($sortedIdentities, [System.StringComparer]::Ordinal)
    if (($identities -join "`n") -cne ($sortedIdentities -join "`n")) {
        throw "Metrics summary accepted identities are not ordinally sorted: '$Path'."
    }
    if (@($identities | Select-Object -Unique).Count -ne $identities.Count) {
        throw "Metrics summary contains duplicate accepted identities: '$Path'."
    }

    $acceptedCount = [uint64]$summary.strict.accepted_identity_count
    $acceptedInstructions = [uint64]$summary.strict.accepted_instructions
    $denominatorFunctions = [uint64]$summary.denominator.function_count
    $denominatorInstructions = [uint64]$summary.denominator.instruction_count
    $denominatorBodyBytes = [uint64]$summary.denominator.body_byte_count
    if ($acceptedCount -ne [uint64]$identities.Count) {
        throw "Metrics summary accepted identity count does not match its identity set: '$Path'."
    }
    if ($acceptedCount -gt $denominatorFunctions -or
        $acceptedInstructions -gt $denominatorInstructions) {
        throw "Metrics summary strict coverage exceeds its denominator: '$Path'."
    }

    $reportedIdentityHash =
        ([string]$summary.strict.accepted_identity_sha256).Trim().ToLowerInvariant()
    $actualIdentityHash = Get-TextSha256Hex $identities
    if ($reportedIdentityHash -cne $actualIdentityHash) {
        throw "Metrics summary accepted identity hash is invalid: '$Path'."
    }
    $denominatorIdentityHash =
        ([string]$summary.denominator.identity_sha256).Trim().ToLowerInvariant()
    $bodyOwnershipHash =
        ([string]$summary.denominator.body_ownership_sha256).Trim().ToLowerInvariant()
    $bodyRangeCount = [uint64]$summary.denominator.body_range_count
    if ($denominatorIdentityHash -notmatch '^[0-9a-f]{64}$' -or
        $bodyOwnershipHash -notmatch '^[0-9a-f]{64}$' -or
        $bodyRangeCount -lt $denominatorFunctions) {
        throw "Metrics summary denominator ownership evidence is invalid: '$Path'."
    }
    $manifestIdentityHash =
        ([string]$summary.inputs.manifest.identity_universe_sha256).Trim().ToLowerInvariant()
    $manifestIdentityCount = [uint64]$summary.inputs.manifest.identity_count
    if ($manifestIdentityHash -notmatch '^[0-9a-f]{64}$' -or
        $manifestIdentityCount -lt $acceptedCount) {
        throw "Metrics summary manifest identity evidence is invalid: '$Path'."
    }

    return $summary
}

function Assert-MetricsBoundary {
    param(
        $CurrentSummary,
        $RequiredSummary,
        [string]$BoundaryDescription
    )

    if ([string]$CurrentSummary.inputs.manifest.identity_universe_sha256 -cne
        [string]$RequiredSummary.inputs.manifest.identity_universe_sha256 -or
        [uint64]$CurrentSummary.inputs.manifest.identity_count -ne
        [uint64]$RequiredSummary.inputs.manifest.identity_count) {
        throw "Manifest identity universe changed relative to $BoundaryDescription; start a new clean baseline."
    }

    if ([string]$CurrentSummary.denominator.identity_sha256 -cne
        [string]$RequiredSummary.denominator.identity_sha256 -or
        [string]$CurrentSummary.denominator.body_ownership_sha256 -cne
        [string]$RequiredSummary.denominator.body_ownership_sha256 -or
        [uint64]$CurrentSummary.denominator.body_range_count -ne
        [uint64]$RequiredSummary.denominator.body_range_count -or
        [uint64]$CurrentSummary.denominator.function_count -ne
        [uint64]$RequiredSummary.denominator.function_count -or
        [uint64]$CurrentSummary.denominator.instruction_count -ne
        [uint64]$RequiredSummary.denominator.instruction_count -or
        [uint64]$CurrentSummary.denominator.body_byte_count -ne
        [uint64]$RequiredSummary.denominator.body_byte_count) {
        throw "Metrics denominator changed relative to $BoundaryDescription; start a new clean baseline."
    }

    $currentIdentities = New-Object 'System.Collections.Generic.HashSet[string]' `
        ([System.StringComparer]::Ordinal)
    foreach ($identity in @($CurrentSummary.strict.accepted_identities)) {
        [void]$currentIdentities.Add([string]$identity)
    }
    $missing = @()
    foreach ($identity in @($RequiredSummary.strict.accepted_identities)) {
        if (-not $currentIdentities.Contains([string]$identity)) {
            $missing += [string]$identity
        }
    }
    if ($missing.Count -ne 0) {
        $examples = @($missing | Select-Object -First 5) -join ", "
        throw ("Accepted identity regression relative to {0}: {1} row(s) disappeared ({2})." -f
            $BoundaryDescription, $missing.Count, $examples)
    }

    if ([uint64]$CurrentSummary.strict.accepted_identity_count -lt
        [uint64]$RequiredSummary.strict.accepted_identity_count) {
        throw "Strict accepted row count regressed relative to $BoundaryDescription."
    }
    if ([uint64]$CurrentSummary.strict.accepted_instructions -lt
        [uint64]$RequiredSummary.strict.accepted_instructions) {
        throw "Strict accepted instructions regressed relative to $BoundaryDescription."
    }
}

function Assert-JsonObjectShape {
    param(
        $Value,
        [string[]]$RequiredProperties,
        [string]$Description
    )

    if ($null -eq $Value -or
        -not ($Value -is [System.Management.Automation.PSCustomObject])) {
        throw "$Description must be a JSON object."
    }

    $actual = @($Value.PSObject.Properties | ForEach-Object {
        [string]$_.Name
    })
    $missing = @($RequiredProperties | Where-Object {
        -not ($actual -ccontains $_)
    })
    $extra = @($actual | Where-Object {
        -not ($RequiredProperties -ccontains $_)
    })
    if ($missing.Count -ne 0 -or $extra.Count -ne 0) {
        throw ("{0} has the wrong property set (missing: {1}; extra: {2})." -f
            $Description,
            $(if ($missing.Count -eq 0) { "none" } else { $missing -join ", " }),
            $(if ($extra.Count -eq 0) { "none" } else { $extra -join ", " }))
    }
}

function Assert-CanonicalPromotionIdentity {
    param(
        [string]$Identity,
        [string]$Description
    )

    if ([string]::IsNullOrWhiteSpace($Identity) -or
        $Identity -cnotmatch '^(oregon32\.exe|oregon32\.dll)\|0x(0|[1-9a-f][0-9a-f]*)$') {
        throw ("{0} is ambiguous or noncanonical: '{1}'. Expected " +
            "'<lowercase program>|0x<lowercase RVA>'.") -f
            $Description, $Identity
    }
}

function Get-SafePromotionEvidenceFile {
    param(
        [string]$RelativePath,
        [string]$Role,
        [string]$ExpectedSha256 = ""
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        throw "Promotion evidence $Role path is empty."
    }
    if ([System.IO.Path]::IsPathRooted($RelativePath)) {
        throw "Promotion evidence $Role path must be repository-relative: '$RelativePath'."
    }
    $pathSegments = @($RelativePath.Replace('\', '/').Split('/') |
        Where-Object { $_ -ne "" })
    if ($pathSegments.Count -eq 0 -or
        @($pathSegments | Where-Object { $_ -eq "." -or $_ -eq ".." }).Count -ne 0) {
        throw "Promotion evidence $Role path is not canonical: '$RelativePath'."
    }

    $absolute = Get-ContainedRepoPath $RelativePath "Promotion evidence $Role"
    if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
        throw "Promotion evidence $Role file was not found: '$absolute'."
    }

    $repoPrefix = $repoRoot.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    $normalized = $absolute.Substring($repoPrefix.Length).Replace('\', '/')
    $normalizedLower = $normalized.ToLowerInvariant()
    if ($normalizedLower -match '^(sample|originals|vc4|build)/' -or
        ($normalizedLower -match '^resources/otwin32/' -and
            $normalizedLower -cne 'resources/otwin32/readme.md')) {
        throw "Promotion evidence $Role points into an original/generated payload tree: '$normalized'."
    }

    $extension = [System.IO.Path]::GetExtension($normalized).ToLowerInvariant()
    [string[]]$allowedExtensions = switch ($Role) {
        "document" { @(".json") }
        "dossier" { @(".json") }
        "source" { @(".c", ".cc", ".cpp", ".cxx", ".h", ".hpp", ".inl") }
        "focused result" { @(".json") }
        default { throw "Unknown promotion evidence file role '$Role'." }
    }
    if (-not ($allowedExtensions -ccontains $extension)) {
        throw ("Promotion evidence {0} must be a regular text/evidence file; " +
            "extension '{1}' is not allowed for '{2}'.") -f
            $Role, $extension, $normalized
    }
    if ($Role -eq "source" -and $normalizedLower -notmatch '^src/') {
        throw "Promotion evidence source must remain beneath src/: '$normalized'."
    }

    $current = $absolute
    while (-not $current.Equals(
            $repoRoot,
            [System.StringComparison]::OrdinalIgnoreCase)) {
        if (-not (Test-Path -LiteralPath $current)) {
            throw "Promotion evidence $Role path changed during validation: '$current'."
        }
        $item = Get-Item -LiteralPath $current -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Promotion evidence $Role has a reparse-point path component: '$current'."
        }
        if ($current -ceq $absolute -and $item.PSIsContainer) {
            throw "Promotion evidence $Role is not a regular file: '$absolute'."
        }
        $parent = [System.IO.Path]::GetDirectoryName($current)
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -ceq $current) {
            throw "Could not validate promotion evidence $Role ancestry: '$absolute'."
        }
        $current = $parent
    }

    $bytes = [System.IO.File]::ReadAllBytes($absolute)
    if ($bytes -contains [byte]0) {
        throw "Promotion evidence $Role is not a UTF-8 text file (NUL byte found): '$normalized'."
    }
    try {
        $strictUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
        [void]$strictUtf8.GetString($bytes)
    }
    catch {
        throw "Promotion evidence $Role is not valid UTF-8 text: '$normalized'."
    }

    $sha256 = Get-FileSha256Hex $absolute
    if (-not [string]::IsNullOrWhiteSpace($ExpectedSha256)) {
        $expected = $ExpectedSha256.Trim().ToLowerInvariant()
        if ($expected -notmatch '^[0-9a-f]{64}$') {
            throw "Promotion evidence $Role SHA256 is invalid for '$normalized'."
        }
        if ($sha256 -cne $expected) {
            throw ("Promotion evidence {0} SHA256 is stale for '{1}' " +
                "(expected {2}, actual {3}).") -f
                $Role, $normalized, $expected, $sha256
        }
    }

    return [pscustomobject][ordered]@{
        path = $normalized
        absolute_path = $absolute
        sha256 = $sha256
    }
}

function Get-SafePromotionProvenanceFile {
    param(
        [string]$RelativePath,
        [string]$ExpectedSha256,
        [long]$ExpectedLength,
        [ValidateSet("original file", "candidate file", "candidate map")]
        [string]$Role
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath) -or
        [System.IO.Path]::IsPathRooted($RelativePath)) {
        throw "Promotion dossier verifier $Role path must be repository-relative."
    }
    $segments = @($RelativePath.Replace('\', '/').Split('/') |
        Where-Object { $_ -ne "" })
    if ($segments.Count -eq 0 -or
        @($segments | Where-Object {
            $_ -eq "." -or $_ -eq ".."
        }).Count -ne 0) {
        throw "Promotion dossier verifier $Role path is not canonical: '$RelativePath'."
    }
    if ($ExpectedLength -le 0) {
        throw "Promotion dossier verifier $Role length must be positive."
    }
    $expectedHash = Assert-Sha256Value $ExpectedSha256 `
        "Promotion dossier verifier $Role sha256"
    $absolute = Get-ContainedRepoPath $RelativePath `
        "Promotion dossier verifier $Role"
    if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
        throw "Promotion dossier verifier $Role file was not found: '$absolute'."
    }

    $repoPrefix = $repoRoot.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    $normalized = $absolute.Substring($repoPrefix.Length).Replace('\', '/')
    $extension = [System.IO.Path]::GetExtension($normalized).ToLowerInvariant()
    $allowedExtensions = switch ($Role) {
        "original file" { @(".exe", ".dll") }
        "candidate file" { @(".dll") }
        "candidate map" { @(".map") }
    }
    if (-not ($allowedExtensions -ccontains $extension)) {
        throw ("Promotion dossier verifier {0} extension '{1}' is not " +
            "allowed for binary provenance.") -f $Role, $extension
    }

    $current = $absolute
    while (-not $current.Equals(
            $repoRoot,
            [System.StringComparison]::OrdinalIgnoreCase)) {
        if (-not (Test-Path -LiteralPath $current)) {
            throw "Promotion dossier verifier $Role path changed: '$current'."
        }
        $item = Get-Item -LiteralPath $current -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Promotion dossier verifier $Role traverses a reparse point: '$current'."
        }
        if ($current -ceq $absolute -and $item.PSIsContainer) {
            throw "Promotion dossier verifier $Role is not a regular file."
        }
        $parent = [System.IO.Path]::GetDirectoryName($current)
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -ceq $current) {
            throw "Could not validate promotion dossier verifier $Role ancestry."
        }
        $current = $parent
    }

    $file = Get-Item -LiteralPath $absolute -Force
    if ([long]$file.Length -ne $ExpectedLength) {
        throw ("Promotion dossier verifier {0} length is stale " +
            "(expected {1}, actual {2}).") -f
            $Role, $ExpectedLength, $file.Length
    }
    $actualHash = Get-FileSha256Hex $absolute
    if ($actualHash -cne $expectedHash) {
        throw "Promotion dossier verifier $Role SHA256 is stale."
    }

    return [pscustomobject][ordered]@{
        role = $Role
        path = $normalized
        absolute_path = $absolute
        sha256 = $actualHash
        length = [long]$file.Length
    }
}

function Get-SafeProductReanchorFile {
    param(
        $Record,
        [string]$Role,
        [string[]]$AllowedExtensions,
        [switch]$RequireIgnoredOutput
    )

    Assert-JsonObjectShape $Record @("path", "sha256", "length") `
        "Product reanchor $Role provenance"
    $relativePath = [string]$Record.path
    if ([string]::IsNullOrWhiteSpace($relativePath) -or
        [System.IO.Path]::IsPathRooted($relativePath)) {
        throw "Product reanchor $Role path must be repository-relative."
    }
    $segments = @($relativePath.Replace('\', '/').Split('/') |
        Where-Object { $_ -ne "" })
    if ($segments.Count -eq 0 -or
        @($segments | Where-Object {
            $_ -eq "." -or $_ -eq ".."
        }).Count -ne 0) {
        throw "Product reanchor $Role path is not canonical."
    }
    $absolute = Get-ContainedRepoPath $relativePath `
        "Product reanchor $Role"
    if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
        throw "Product reanchor $Role file was not found: '$absolute'."
    }
    $repoPrefix = $repoRoot.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    $normalized = $absolute.Substring($repoPrefix.Length).Replace('\', '/')
    $extension = [System.IO.Path]::GetExtension($normalized).ToLowerInvariant()
    if (-not ($AllowedExtensions -ccontains $extension)) {
        throw "Product reanchor $Role has forbidden extension '$extension'."
    }
    if ($RequireIgnoredOutput) {
        if ($normalized -notmatch '^(?i:a|artifacts)/') {
            throw "Product reanchor $Role must remain below ignored a/ or artifacts/."
        }
        & git -C $repoRoot check-ignore --quiet -- $normalized 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Product reanchor $Role must be Git-ignored."
        }
    }
    $current = $absolute
    while (-not $current.Equals(
            $repoRoot,
            [System.StringComparison]::OrdinalIgnoreCase)) {
        $item = Get-Item -LiteralPath $current -Force
        if (($item.Attributes -band
                [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Product reanchor $Role traverses a reparse point."
        }
        $parent = [System.IO.Path]::GetDirectoryName($current)
        if ([string]::IsNullOrWhiteSpace($parent) -or
            $parent -ceq $current) {
            throw "Could not validate Product reanchor $Role ancestry."
        }
        $current = $parent
    }
    $file = Get-Item -LiteralPath $absolute -Force
    if (-not ($Record.length -is [byte]) -and
        -not ($Record.length -is [int16]) -and
        -not ($Record.length -is [int32]) -and
        -not ($Record.length -is [int64]) -and
        -not ($Record.length -is [uint16]) -and
        -not ($Record.length -is [uint32]) -and
        -not ($Record.length -is [uint64])) {
        throw "Product reanchor $Role length must be a JSON integer."
    }
    if ([long]$Record.length -le 0 -or
        [long]$file.Length -ne [long]$Record.length) {
        throw "Product reanchor $Role length is stale or invalid."
    }
    $expectedHash = Assert-Sha256Value $Record.sha256 `
        "Product reanchor $Role SHA256"
    $actualHash = Get-FileSha256Hex $absolute
    if ($actualHash -cne $expectedHash) {
        throw "Product reanchor $Role SHA256 is stale."
    }
    return [pscustomobject][ordered]@{
        role = $Role
        path = $normalized
        absolute_path = $absolute
        sha256 = $actualHash
        length = [long]$file.Length
    }
}

function Get-CurrentProductReanchorFile {
    param(
        [string]$Path,
        [string]$Role,
        [string[]]$AllowedExtensions
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or
        [System.IO.Path]::IsPathRooted($Path)) {
        throw "Current Product reanchor $Role path must be repository-relative."
    }
    $absolute = Get-ContainedRepoPath $Path "Current Product reanchor $Role"
    if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
        throw "Current Product reanchor $Role file was not found: '$absolute'."
    }
    $repoPrefix = $repoRoot.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    $relative = $absolute.Substring($repoPrefix.Length).Replace('\', '/')
    $file = Get-Item -LiteralPath $absolute -Force
    $record = [pscustomobject][ordered]@{
        path = $relative
        sha256 = Get-FileSha256Hex $absolute
        length = [long]$file.Length
    }
    return Get-SafeProductReanchorFile $record $Role $AllowedExtensions `
        -RequireIgnoredOutput
}

function Get-ReanchorCsvField {
    param($Row, [string]$Name)

    $property = $Row.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) {
        return ""
    }
    return [string]$property.Value
}

function ConvertFrom-ReanchorNumber {
    param([string]$Value, [string]$Description)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "Product reanchor $Description is empty."
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

function Get-ProductReanchorSymbolContainment {
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
        $symbolOffset = ConvertFrom-ReanchorNumber $Matches["offset"] `
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

function Assert-ProductReanchorSymbolContainment {
    param($Reported, $Expected)

    $fields = @(
        "proof_method", "map_sha256", "candidate_symbol_expression",
        "base_symbol", "base_rva", "base_object", "offset",
        "target_rva", "target_size", "target_end_rva_exclusive",
        "next_public_symbol", "next_public_rva", "next_public_object",
        "segment", "within_base_public_extent")
    Assert-JsonObjectShape $Reported $fields `
        "Product reanchor symbol-containment proof"
    foreach ($field in @($fields | Where-Object {
            $_ -ne "target_size" -and
            $_ -ne "within_base_public_extent"
        })) {
        if ([string]$Reported.PSObject.Properties[$field].Value -cne
            [string]$Expected.PSObject.Properties[$field].Value) {
            throw "Product reanchor symbol-containment proof is stale at '$field'."
        }
    }
    if ((Assert-JsonNonnegativeInteger $Reported.target_size `
            "Product reanchor containment target_size") -ne
        [uint64]$Expected.target_size) {
        throw "Product reanchor symbol-containment target size is stale."
    }
    Assert-JsonTrue $Reported.within_base_public_extent `
        "Product reanchor containment within_base_public_extent"
    if (-not [bool]$Expected.within_base_public_extent) {
        throw "Internal Product reanchor containment recomputation failed."
    }
}

function Get-ReanchorIdentity {
    param($Row)

    $program = (Get-ReanchorCsvField $Row "program").ToLowerInvariant()
    if ($program -cne "oregon32.exe") {
        throw "Product reanchor is restricted to the Oregon32.exe main image."
    }
    $rva = ConvertFrom-ReanchorNumber `
        (Get-ReanchorCsvField $Row "original_rva") "original_rva"
    return ("{0}|0x{1:x}" -f $program, $rva)
}

function Get-GitFileRowsAtCommit {
    param(
        [string]$Commit,
        [string]$RelativePath,
        [string]$Description
    )

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = @(& git -C $repoRoot show `
            ($Commit + ":" + $RelativePath) 2>&1 |
            ForEach-Object { [string]$_ })
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
    if ($exitCode -ne 0) {
        throw "$Description could not be read from Git commit '$Commit'."
    }
    $text = [string]::Join([Environment]::NewLine, $output)
    return @($text | ConvertFrom-Csv)
}

function Get-ReanchorGitBlobOid {
    param(
        [string]$Commit,
        [string]$RelativePath,
        [string]$Description
    )

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = @(& git -C $repoRoot rev-parse `
            ($Commit + ":" + $RelativePath) 2>&1 |
            ForEach-Object { [string]$_ })
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
    if ($exitCode -ne 0 -or $output.Count -ne 1) {
        throw "$Description could not be resolved from Git commit '$Commit'."
    }
    $oid = $output[0].Trim().ToLowerInvariant()
    if ($oid -notmatch '^[0-9a-f]{40,64}$') {
        throw "$Description returned an invalid Git blob object ID."
    }
    return $oid
}

function Get-ReanchorWorktreeBlobOid {
    param([string]$Path, [string]$Description)

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = @(& git -C $repoRoot hash-object -- $Path 2>&1 |
            ForEach-Object { [string]$_ })
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
    if ($exitCode -ne 0 -or $output.Count -ne 1) {
        throw "$Description could not be hashed by Git."
    }
    $oid = $output[0].Trim().ToLowerInvariant()
    if ($oid -notmatch '^[0-9a-f]{40,64}$') {
        throw "$Description returned an invalid Git blob object ID."
    }
    return $oid
}

function Get-DirectProductSourcePaths {
    param([string]$Path)

    $sources = @()
    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith("#")) {
            continue
        }
        $normalized = $trimmed.Replace('\', '/').TrimStart('./')
        if ($normalized -notmatch '^(?i:src/).+\.cpp$') {
            throw "Product source manifest contains invalid entry '$trimmed'."
        }
        $sources += $normalized
    }
    return @($sources)
}

function Get-ProductObjectName {
    param([string]$SourcePath)

    return (($SourcePath -replace '[\\/]', '_') -replace
        '\.cpp$', '.obj')
}

function Get-ReanchorManifestChange {
    param(
        [object[]]$PriorRows,
        [object[]]$CurrentRows,
        [string]$RequiredIdentity
    )

    $fields = @(
        "name", "program", "original_va", "original_rva", "size",
        "candidate_va", "candidate_rva", "candidate_symbol",
        "candidate_dll", "candidate_object", "expected_status",
        "implementation_kind", "mask", "notes")
    $allowedFields = @(
        "candidate_rva", "candidate_symbol", "candidate_object",
        "expected_status", "notes")
    $requiredFields = @(
        "candidate_object", "expected_status", "notes")
    foreach ($set in @(
            [pscustomobject]@{ Rows = $PriorRows; Name = "Prior manifest" },
            [pscustomobject]@{ Rows = $CurrentRows; Name = "Current manifest" })) {
        foreach ($row in @($set.Rows)) {
            [string[]]$propertyNames = @(
                $row.PSObject.Properties | ForEach-Object { $_.Name })
            if (($propertyNames -join "`n") -cne ($fields -join "`n")) {
                throw "$($set.Name) has noncanonical fields or field order."
            }
        }
    }
    if ($PriorRows.Count -ne $CurrentRows.Count) {
        throw "Product reanchor manifest row count changed."
    }
    $changes = @()
    for ($index = 0; $index -lt $CurrentRows.Count; $index++) {
        $changedFields = @()
        foreach ($field in $fields) {
            if ((Get-ReanchorCsvField $PriorRows[$index] $field) -cne
                (Get-ReanchorCsvField $CurrentRows[$index] $field)) {
                $changedFields += $field
            }
        }
        if ($changedFields.Count -ne 0) {
            $changes += [pscustomobject]@{
                prior = $PriorRows[$index]
                current = $CurrentRows[$index]
                fields = @($changedFields)
            }
        }
    }
    if ($changes.Count -ne 1) {
        throw ("Product reanchor requires exactly one changed manifest row; " +
            "found $($changes.Count).")
    }
    $change = $changes[0]
    if ((Get-ReanchorIdentity $change.prior) -cne $RequiredIdentity -or
        (Get-ReanchorIdentity $change.current) -cne $RequiredIdentity) {
        throw "Product reanchor manifest delta changed or missed its identity."
    }
    $disallowed = @($change.fields | Where-Object {
        -not ($allowedFields -ccontains $_)
    })
    if ($disallowed.Count -ne 0) {
        throw ("Product reanchor changed forbidden manifest fields: " +
            ($disallowed -join ", ") + ".")
    }
    $missing = @($requiredFields | Where-Object {
        -not ($change.fields -ccontains $_)
    })
    if ($missing.Count -ne 0) {
        throw ("Product reanchor did not change required manifest fields: " +
            ($missing -join ", ") + ".")
    }
    if ((Get-ReanchorCsvField $change.prior "expected_status") -cne "wip" -or
        (Get-ReanchorCsvField $change.current "expected_status") -cne "match") {
        throw "Product reanchor requires expected_status wip-to-match."
    }
    if ((Get-ReanchorCsvField $change.prior "implementation_kind") -cne
            "cpp" -or
        (Get-ReanchorCsvField $change.current "implementation_kind") -cne
            "cpp") {
        throw "Product reanchor requires pure-C++ prior and current rows."
    }
    if ((Get-ReanchorCsvField $change.prior "mask") -cne
        (Get-ReanchorCsvField $change.current "mask")) {
        throw "Product reanchor cannot alter its mask."
    }
    if (-not [string]::IsNullOrWhiteSpace(
            (Get-ReanchorCsvField $change.prior "candidate_va")) -or
        -not [string]::IsNullOrWhiteSpace(
            (Get-ReanchorCsvField $change.prior "candidate_dll"))) {
        throw "Product reanchor prior row must use the main candidate image."
    }
    $priorRva = Get-ReanchorCsvField $change.prior "candidate_rva"
    $priorSymbol = Get-ReanchorCsvField $change.prior "candidate_symbol"
    if ([string]::IsNullOrWhiteSpace($priorRva) -eq
        [string]::IsNullOrWhiteSpace($priorSymbol)) {
        throw "Product reanchor prior row must use exactly one recovery RVA or symbol locator."
    }
    if (-not [string]::IsNullOrWhiteSpace($priorRva) -and
        -not [string]::IsNullOrWhiteSpace(
            (Get-ReanchorCsvField $change.prior "candidate_object"))) {
        throw "Product reanchor prior candidate_rva cannot carry candidate_object."
    }
    if (-not [string]::IsNullOrWhiteSpace($priorSymbol) -and
        [string]::IsNullOrWhiteSpace(
            (Get-ReanchorCsvField $change.prior "candidate_object"))) {
        throw "Product reanchor prior candidate_symbol requires candidate_object."
    }
    if (-not [string]::IsNullOrWhiteSpace(
            (Get-ReanchorCsvField $change.current "candidate_va")) -or
        -not [string]::IsNullOrWhiteSpace(
            (Get-ReanchorCsvField $change.current "candidate_rva")) -or
        -not [string]::IsNullOrWhiteSpace(
            (Get-ReanchorCsvField $change.current "candidate_dll")) -or
        [string]::IsNullOrWhiteSpace(
            (Get-ReanchorCsvField $change.current "candidate_symbol"))) {
        throw ("Product reanchor current row must use only a main-image " +
            "candidate_symbol locator (no candidate_va, candidate_rva, or " +
            "candidate_dll).")
    }
    if ([string]::IsNullOrWhiteSpace(
            (Get-ReanchorCsvField $change.current "notes"))) {
        throw "Product reanchor current row must carry a nonblank semantic note."
    }
    return [pscustomobject]@{
        prior = $change.prior
        current = $change.current
        fields = @($change.fields)
        allowed_fields = @($allowedFields)
        all_fields = @($fields)
    }
}

function Assert-JsonRequiredProperties {
    param(
        $Value,
        [string[]]$RequiredProperties,
        [string]$Description
    )

    if ($null -eq $Value -or
        -not ($Value -is [System.Management.Automation.PSCustomObject])) {
        throw "$Description must be a JSON object."
    }
    $actual = @($Value.PSObject.Properties | ForEach-Object {
        [string]$_.Name
    })
    $missing = @($RequiredProperties | Where-Object {
        -not ($actual -ccontains $_)
    })
    if ($missing.Count -ne 0) {
        throw "$Description is missing required properties: $($missing -join ', ')."
    }
}

function Read-JsonEvidenceArtifact {
    param(
        $File,
        [string]$Description
    )

    try {
        $value = Get-Content -LiteralPath $File.absolute_path -Raw |
            ConvertFrom-Json
    }
    catch {
        throw "$Description JSON could not be parsed: $($_.Exception.Message)"
    }
    if ($null -eq $value -or
        -not ($value -is [System.Management.Automation.PSCustomObject])) {
        throw "$Description must contain one JSON object."
    }
    return $value
}

function Assert-JsonTrue {
    param(
        $Value,
        [string]$Description
    )

    if (-not ($Value -is [bool]) -or -not [bool]$Value) {
        throw "$Description must be the JSON boolean true."
    }
}

function Assert-JsonNonnegativeInteger {
    param(
        $Value,
        [string]$Description
    )

    $isInteger = $Value -is [byte] -or $Value -is [sbyte] -or
        $Value -is [int16] -or $Value -is [uint16] -or
        $Value -is [int32] -or $Value -is [uint32] -or
        $Value -is [int64] -or $Value -is [uint64]
    if (-not $isInteger -or [decimal]$Value -lt 0) {
        throw "$Description must be a nonnegative JSON integer."
    }
    return [uint64]$Value
}

function Assert-NonBlankString {
    param(
        $Value,
        [string]$Description
    )

    if ([string]::IsNullOrWhiteSpace([string]$Value)) {
        throw "$Description must be nonblank."
    }
}

function Assert-Sha256Value {
    param(
        $Value,
        [string]$Description
    )

    $hash = ([string]$Value).Trim().ToLowerInvariant()
    if ($hash -notmatch '^[0-9a-f]{64}$') {
        throw "$Description must be a SHA256 value."
    }
    return $hash
}

function Assert-ExactStringSet {
    param(
        [string[]]$Actual,
        [string[]]$Expected,
        [string]$Description
    )

    if (@($Actual | Where-Object {
            [string]::IsNullOrWhiteSpace($_)
        }).Count -ne 0) {
        throw "$Description contains an empty value."
    }
    $actualUnique = New-Object 'System.Collections.Generic.HashSet[string]' `
        ([System.StringComparer]::Ordinal)
    foreach ($value in $Actual) {
        if (-not $actualUnique.Add([string]$value)) {
            throw "$Description contains duplicate value '$value'."
        }
    }
    [string[]]$actualSorted = @($actualUnique)
    [string[]]$expectedSorted = @($Expected)
    [Array]::Sort($actualSorted, [System.StringComparer]::Ordinal)
    [Array]::Sort($expectedSorted, [System.StringComparer]::Ordinal)
    if (($actualSorted -join "`n") -cne ($expectedSorted -join "`n")) {
        throw ("{0} does not exactly match its required set " +
            "(actual: {1}; expected: {2}).") -f
            $Description,
            $(if ($actualSorted.Count -eq 0) {
                "none"
            } else { $actualSorted -join ", " }),
            $(if ($expectedSorted.Count -eq 0) {
                "none"
            } else { $expectedSorted -join ", " })
    }
}

function Test-SameEvidencePath {
    param(
        [string]$Left,
        [string]$Right
    )

    return $Left.Replace('\', '/').Equals(
        $Right.Replace('\', '/'),
        [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-ReanchorToolRecord {
    param($Record, [string]$ExpectedPath, [string]$Description)
    Assert-JsonObjectShape $Record @("path", "sha256") $Description
    if (-not (Test-SameEvidencePath ([string]$Record.path) $ExpectedPath)) {
        throw "$Description path is not canonical."
    }
    $hash = Assert-Sha256Value $Record.sha256 "$Description SHA256"
    if ($hash -cne (Get-FileSha256Hex (Join-Path $repoRoot $ExpectedPath))) {
        throw "$Description SHA256 is stale."
    }
    return $hash
}

function Assert-ReanchorRowRecord {
    param($Record, $ExpectedRow, [string[]]$Fields, [string]$Description)
    Assert-JsonObjectShape $Record $Fields $Description
    foreach ($field in $Fields) {
        if ([string]$Record.PSObject.Properties[$field].Value -cne (Get-ReanchorCsvField $ExpectedRow $field)) {
            throw "$Description field '$field' is stale or mismatched."
        }
    }
}

function Test-AllowedCompletedChecklistState {
    param(
        [string]$Id,
        [string]$State,
        [bool]$HasMask
    )

    if ($Id -eq "mask.target_identity" -and -not $HasMask) {
        return ($State -ceq "not-applicable")
    }
    if ($Id -like "mask.*") {
        return ($State -ceq "pass")
    }
    return ($State -ceq "complete" -or $State -ceq "pass")
}

function Test-PromotionDossier {
    param(
        $File,
        [string]$Identity,
        $Source
    )

    $dossier = Read-JsonEvidenceArtifact $File "Promotion dossier"
    Assert-JsonObjectShape $dossier @(
        "schema_version", "generator", "identity", "manifest", "verifier",
        "metrics", "mask_review", "recovery_state", "sources",
        "decompilation", "prior_recovery_notes", "checklist", "warnings",
        "evidence", "promotion_review") "Promotion dossier"
    if ([int]$dossier.schema_version -ne 1) {
        throw "Promotion dossier must use schema_version 1."
    }

    Assert-JsonObjectShape $dossier.generator @(
        "name", "schema_version", "script_path", "script_sha256") `
        "Promotion dossier generator"
    if ([string]$dossier.generator.name -cne "otmatch-function-dossier" -or
        [int]$dossier.generator.schema_version -ne 1) {
        throw "Promotion dossier was not emitted by the schema-1 otmatch dossier generator."
    }
    if (-not (Test-SameEvidencePath `
            ([string]$dossier.generator.script_path) `
            "tools/otmatch/generate-function-dossier.ps1")) {
        throw "Promotion dossier generator script_path is not the canonical dossier generator."
    }
    $generatorPath = Join-Path $repoRoot `
        "tools\otmatch\generate-function-dossier.ps1"
    $reportedGeneratorHash = Assert-Sha256Value `
        $dossier.generator.script_sha256 `
        "Promotion dossier generator script_sha256"
    if ($reportedGeneratorHash -cne (Get-FileSha256Hex $generatorPath)) {
        throw "Promotion dossier generator script_sha256 is stale."
    }

    Assert-JsonObjectShape $dossier.identity @(
        "name", "program", "original_va", "original_rva", "size", "key") `
        "Promotion dossier identity"
    if ([string]$dossier.identity.key -cne $Identity) {
        throw ("Promotion dossier identity '{0}' does not match promotion " +
            "identity '{1}'.") -f $dossier.identity.key, $Identity
    }

    Assert-JsonRequiredProperties $dossier.manifest @(
        "expected_status", "implementation_kind", "candidate_symbol",
        "candidate_object", "mask") `
        "Promotion dossier manifest"
    if ([string]$dossier.manifest.expected_status -cne "match" -or
        [string]$dossier.manifest.implementation_kind -cne "cpp") {
        throw "Promotion dossier must bind an accepted pure-C++ manifest row."
    }
    Assert-NonBlankString $dossier.manifest.candidate_symbol `
        "Promotion dossier manifest candidate_symbol"
    Assert-NonBlankString $dossier.manifest.candidate_object `
        "Promotion dossier manifest candidate_object"

    Assert-JsonRequiredProperties $dossier.verifier @(
        "result_schema_version", "verification_status", "actual_status",
        "mask_shape_valid", "masked_operand_shape_error",
        "has_verifier_error", "provenance_complete", "original_file",
        "candidate_file", "candidate_map") "Promotion dossier verifier"
    if ([int]$dossier.verifier.result_schema_version -ne 4 -or
        [string]$dossier.verifier.verification_status -cne "pass" -or
        [string]$dossier.verifier.actual_status -cne "match") {
        throw "Promotion dossier verifier does not prove an accepted schema-4 match."
    }
    Assert-JsonTrue $dossier.verifier.mask_shape_valid `
        "Promotion dossier verifier mask_shape_valid"
    Assert-JsonTrue $dossier.verifier.provenance_complete `
        "Promotion dossier verifier provenance_complete"
    if (-not ($dossier.verifier.has_verifier_error -is [bool]) -or
        [bool]$dossier.verifier.has_verifier_error -or
        -not [string]::IsNullOrWhiteSpace(
            [string]$dossier.verifier.masked_operand_shape_error)) {
        throw "Promotion dossier verifier contains an error or mask-shape diagnostic."
    }
    $provenanceFiles = @()
    foreach ($provenanceSpec in @(
            [pscustomobject]@{
                Property = "original_file"
                Role = "original file"
                EvidenceRole = "verifier-original-file"
            },
            [pscustomobject]@{
                Property = "candidate_file"
                Role = "candidate file"
                EvidenceRole = "verifier-candidate-file"
            },
            [pscustomobject]@{
                Property = "candidate_map"
                Role = "candidate map"
                EvidenceRole = "verifier-candidate-map"
            })) {
        $provenanceName = [string]$provenanceSpec.Property
        $provenance = $dossier.verifier.PSObject.Properties[$provenanceName].Value
        Assert-JsonObjectShape $provenance @("path", "sha256", "length") `
            "Promotion dossier verifier $provenanceName"
        $resolvedProvenance = Get-SafePromotionProvenanceFile `
            ([string]$provenance.path) ([string]$provenance.sha256) `
            ([long]$provenance.length) ([string]$provenanceSpec.Role)
        $inventoryMatches = @($dossier.evidence | Where-Object {
            (Test-SameEvidencePath ([string]$_.path) `
                ([string]$resolvedProvenance.path)) -and
            ([string]$_.sha256).Trim().ToLowerInvariant() -ceq
                [string]$resolvedProvenance.sha256 -and
            [long]$_.length -eq [long]$resolvedProvenance.length -and
            @($_.roles) -ccontains [string]$provenanceSpec.EvidenceRole
        })
        if ($inventoryMatches.Count -ne 1) {
            throw ("Promotion dossier evidence inventory does not bind verifier " +
                "{0} with role '{1}'.") -f
                $provenanceName, $provenanceSpec.EvidenceRole
        }
        $provenanceFiles += $resolvedProvenance
    }

    Assert-JsonRequiredProperties $dossier.metrics @(
        "provided", "strict_accepted") "Promotion dossier metrics"
    Assert-JsonTrue $dossier.metrics.provided `
        "Promotion dossier metrics provided"
    Assert-JsonTrue $dossier.metrics.strict_accepted `
        "Promotion dossier metrics strict_accepted"

    $sourceMatches = @($dossier.sources | Where-Object {
        Test-SameEvidencePath ([string]$_.path) ([string]$Source.path)
    })
    if ($sourceMatches.Count -ne 1) {
        throw ("Promotion dossier must contain exactly one current source " +
            "binding for '{0}'.") -f $Source.path
    }
    $dossierSource = $sourceMatches[0]
    Assert-JsonRequiredProperties $dossierSource @(
        "path", "sha256", "object_name", "match_reasons",
        "product_reachable", "tu_metadata_found", "extra_compile_flags") `
        "Promotion dossier current source"
    if ((Assert-Sha256Value $dossierSource.sha256 `
            "Promotion dossier current source sha256") -cne
        [string]$Source.sha256) {
        throw "Promotion dossier current source SHA256 is stale or mismatched."
    }
    Assert-JsonTrue $dossierSource.product_reachable `
        "Promotion dossier current source product_reachable"
    if (-not ($dossierSource.tu_metadata_found -is [bool])) {
        throw "Promotion dossier current source tu_metadata_found must be a JSON boolean."
    }
    $extraCompileFlags = ([string]$dossierSource.extra_compile_flags).Trim()
    if ([bool]$dossierSource.tu_metadata_found) {
        if ([string]::IsNullOrWhiteSpace($extraCompileFlags)) {
            throw "Promotion dossier TU metadata row has no exceptional compile flag."
        }
        $flagTokens = @($extraCompileFlags -split '\s+' | Where-Object {
            -not [string]::IsNullOrWhiteSpace($_)
        })
        $uniqueFlags = @($flagTokens | Select-Object -Unique)
        if ($uniqueFlags.Count -ne $flagTokens.Count -or
            @($flagTokens | Where-Object {
                $_ -cne "/GX" -and $_ -cne "/Oy-"
            }).Count -ne 0) {
            throw ("Promotion dossier TU metadata flags may contain only one " +
                "each of /GX and/or /Oy-.")
        }
    }
    elseif (-not [string]::IsNullOrWhiteSpace($extraCompileFlags)) {
        throw "Promotion dossier source without TU metadata has nonempty extra_compile_flags."
    }
    $recognizedSourceReasons = @($dossierSource.match_reasons | Where-Object {
        [string]$_ -in @("candidate_object", "candidate_symbol", "manifest_name")
    })
    if ($recognizedSourceReasons.Count -eq 0) {
        throw "Promotion dossier current source lacks a generator discovery reason."
    }
    $sourceEvidence = @($dossier.evidence | Where-Object {
        (Test-SameEvidencePath ([string]$_.path) ([string]$Source.path)) -and
        ([string]$_.sha256).Trim().ToLowerInvariant() -ceq
            [string]$Source.sha256 -and
        @($_.roles) -ccontains "candidate-source"
    })
    if ($sourceEvidence.Count -ne 1) {
        throw "Promotion dossier evidence inventory does not bind the current candidate source."
    }
    $generatorEvidence = @($dossier.evidence | Where-Object {
        (Test-SameEvidencePath ([string]$_.path) `
            "tools/otmatch/generate-function-dossier.ps1") -and
        ([string]$_.sha256).Trim().ToLowerInvariant() -ceq
            $reportedGeneratorHash -and
        @($_.roles) -ccontains "dossier-generator"
    })
    if ($generatorEvidence.Count -ne 1) {
        throw "Promotion dossier evidence inventory does not bind its current generator."
    }

    $manifestMask = [string]$dossier.manifest.mask
    $hasMask = -not [string]::IsNullOrWhiteSpace($manifestMask)
    Assert-JsonRequiredProperties $dossier.mask_review @(
        "original_audit_state", "paired_candidate_shape_valid",
        "paired_candidate_shape_error", "non_import_target_identity_proven") `
        "Promotion dossier mask review"
    Assert-JsonTrue $dossier.mask_review.paired_candidate_shape_valid `
        "Promotion dossier paired candidate mask shape"
    if (-not [string]::IsNullOrWhiteSpace(
            [string]$dossier.mask_review.paired_candidate_shape_error)) {
        throw "Promotion dossier mask review contains a paired-shape error."
    }
    if ($hasMask) {
        if ([string]$dossier.mask_review.original_audit_state -cne
            "validated-original-operands") {
            throw "Promotion dossier mask ranges lack a validated original audit."
        }
        Assert-JsonTrue $dossier.mask_review.non_import_target_identity_proven `
            "Promotion dossier non-import masked target identity proof"
    }
    elseif ([string]$dossier.mask_review.original_audit_state -cne
        "not-required-no-mask") {
        throw "Maskless promotion dossier has an inconsistent original audit state."
    }

    $requiredChecklistIds = @(
        "semantic.behavior", "semantic.readable_cpp",
        "type.calling_convention", "type.layout", "abi.vc4_flags",
        "abi.exception_model", "mask.paired_shape", "mask.original_audit",
        "mask.target_identity", "evidence.ghidra_anchor",
        "evidence.product_reachability", "evidence.focused_diff")
    $checklistIds = @()
    foreach ($item in @($dossier.checklist)) {
        Assert-JsonObjectShape $item @("id", "category", "state", "prompt") `
            "Promotion dossier checklist entry"
        $id = [string]$item.id
        $state = [string]$item.state
        Assert-NonBlankString $item.prompt "Promotion dossier checklist prompt"
        if (-not (Test-AllowedCompletedChecklistState $id $state $hasMask)) {
            throw "Promotion dossier checklist '$id' is pending or failed (state '$state')."
        }
        $checklistIds += $id
    }
    Assert-ExactStringSet $checklistIds $requiredChecklistIds `
        "Promotion dossier checklist identities"

    [string[]]$warnings = @($dossier.warnings | ForEach-Object {
        [string]$_
    })
    Assert-JsonObjectShape $dossier.promotion_review @(
        "identity_key", "status", "reviewed_source_path",
        "reviewed_source_sha256", "reviewer", "reviewed_utc", "semantic",
        "type_layout", "abi", "mask", "warnings_disposition") `
        "Promotion dossier promotion_review"
    $review = $dossier.promotion_review
    if ([string]$review.identity_key -cne $Identity -or
        [string]$review.status -cne "passed") {
        throw "Promotion dossier promotion_review is pending or identity-mismatched."
    }
    if (-not (Test-SameEvidencePath `
            ([string]$review.reviewed_source_path) ([string]$Source.path)) -or
        (Assert-Sha256Value $review.reviewed_source_sha256 `
            "Promotion dossier reviewed source SHA256") -cne
            [string]$Source.sha256) {
        throw "Promotion dossier review does not bind the current source path/SHA256."
    }
    Assert-NonBlankString $review.reviewer "Promotion dossier reviewer"
    # PowerShell 7's ConvertFrom-Json eagerly materializes ISO-8601 strings as
    # DateTime values, while Windows PowerShell 5.1 preserves them as strings.
    # Re-emit typed timestamps in round-trip form before applying the same
    # timezone-bearing evidence rule on both hosts.  An Unspecified DateTime
    # still represents a JSON value without a timezone and must fail closed.
    $reviewedUtcValue = $review.reviewed_utc
    $reviewedUtcText = if ($reviewedUtcValue -is [DateTime]) {
        if ($reviewedUtcValue.Kind -eq [DateTimeKind]::Unspecified) {
            ""
        }
        else {
            $reviewedUtcValue.ToString(
                "o", [System.Globalization.CultureInfo]::InvariantCulture)
        }
    }
    elseif ($reviewedUtcValue -is [DateTimeOffset]) {
        $reviewedUtcValue.ToString(
            "o", [System.Globalization.CultureInfo]::InvariantCulture)
    }
    else {
        [string]$reviewedUtcValue
    }
    $reviewedAt = [DateTimeOffset]::MinValue
    if ($reviewedUtcText -notmatch '(Z|[+-][0-9]{2}:[0-9]{2})$' -or
        -not [DateTimeOffset]::TryParse(
            $reviewedUtcText,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::RoundtripKind,
            [ref]$reviewedAt)) {
        throw "Promotion dossier reviewed_utc must be a valid timestamp with timezone."
    }
    foreach ($categoryName in @("semantic", "type_layout", "abi", "mask")) {
        $category = $review.PSObject.Properties[$categoryName].Value
        Assert-JsonObjectShape $category @("passed", "note") `
            "Promotion dossier $categoryName review"
        Assert-JsonTrue $category.passed `
            "Promotion dossier $categoryName review passed"
        Assert-NonBlankString $category.note `
            "Promotion dossier $categoryName review note"
    }
    Assert-JsonObjectShape $review.warnings_disposition @(
        "status", "note", "resolved_warnings") `
        "Promotion dossier warnings disposition"
    if ([string]$review.warnings_disposition.status -cne "resolved") {
        throw "Promotion dossier warnings disposition is pending or unresolved."
    }
    Assert-NonBlankString $review.warnings_disposition.note `
        "Promotion dossier warnings disposition note"
    [string[]]$resolvedWarnings = @(
        $review.warnings_disposition.resolved_warnings |
            ForEach-Object { [string]$_ })
    Assert-ExactStringSet $resolvedWarnings $warnings `
        "Promotion dossier resolved warnings"

    return [pscustomobject][ordered]@{
        schema_version = 1
        identity = $Identity
        source_path = [string]$Source.path
        source_sha256 = [string]$Source.sha256
        reviewer = [string]$review.reviewer
        reviewed_utc = $reviewedAt.ToString("o")
        warning_count = [uint64]$warnings.Count
        checklist_count = [uint64]$requiredChecklistIds.Count
        candidate_symbol = [string]$dossier.manifest.candidate_symbol
        candidate_object = [string]$dossier.manifest.candidate_object
        provenance_files = @($provenanceFiles)
    }
}

function Test-FocusedPromotionResult {
    param(
        $File,
        [string]$Identity,
        $Source,
        [string]$CheckpointId,
        [string]$BoundaryRunId,
        [string]$ExpectedCandidateSymbol
    )

    $artifact = Read-JsonEvidenceArtifact $File `
        "Focused source-shape promotion evidence"
    Assert-JsonObjectShape $artifact @(
        "schema_version", "artifact_type", "runner", "identity", "checkpoint",
        "source", "successful_trial", "restoration", "run_summary",
        "promotion_eligible") `
        "Focused source-shape promotion evidence"
    if ([int]$artifact.schema_version -ne 1 -or
        [string]$artifact.artifact_type -cne
            "otwin-source-shape-evidence") {
        throw ("Focused source-shape promotion evidence must use the runner's " +
            "schema-1 artifact type.")
    }
    Assert-JsonTrue $artifact.promotion_eligible `
        "Focused source-shape promotion_eligible"

    Assert-JsonObjectShape $artifact.runner @(
        "name", "schema_version", "script_path", "script_sha256") `
        "Focused source-shape runner provenance"
    if ([string]$artifact.runner.name -cne
            "otmatch-source-shape-runner" -or
        [int]$artifact.runner.schema_version -ne 1 -or
        -not (Test-SameEvidencePath `
            ([string]$artifact.runner.script_path) `
            "tools/otmatch/invoke-source-shape-variants.ps1")) {
        throw "Focused source-shape runner provenance is not canonical schema 1."
    }
    $runnerPath = Join-Path $repoRoot `
        "tools\otmatch\invoke-source-shape-variants.ps1"
    $runnerHash = Assert-Sha256Value $artifact.runner.script_sha256 `
        "Focused source-shape runner script SHA256"
    if ($runnerHash -cne (Get-FileSha256Hex $runnerPath)) {
        throw "Focused source-shape runner script SHA256 is stale."
    }

    Assert-JsonObjectShape $artifact.identity @(
        "key", "program", "name", "original_rva") `
        "Focused source-shape identity"
    if ([string]$artifact.identity.key -cne $Identity) {
        throw ("Focused source-shape identity '{0}' does not match promotion " +
            "identity '{1}'.") -f $artifact.identity.key, $Identity
    }
    Assert-NonBlankString $artifact.identity.program `
        "Focused source-shape identity program"
    Assert-NonBlankString $artifact.identity.name `
        "Focused source-shape identity name"
    Assert-NonBlankString $artifact.identity.original_rva `
        "Focused source-shape identity original_rva"

    Assert-JsonObjectShape $artifact.checkpoint @(
        "checkpoint_id", "prior_boundary_run_id") `
        "Focused source-shape checkpoint"
    if ([string]$artifact.checkpoint.checkpoint_id -cne $CheckpointId -or
        [string]$artifact.checkpoint.prior_boundary_run_id -cne
            $BoundaryRunId) {
        throw "Focused source-shape checkpoint/prior-boundary binding is stale or mismatched."
    }

    Assert-JsonObjectShape $artifact.source @(
        "path", "baseline_sha256", "restored_sha256") `
        "Focused source-shape source"
    if (-not (Test-SameEvidencePath `
            ([string]$artifact.source.path) ([string]$Source.path))) {
        throw "Focused source-shape source path does not match the current source."
    }
    $baselineSourceHash = Assert-Sha256Value `
        $artifact.source.baseline_sha256 `
        "Focused source-shape baseline source SHA256"
    $restoredSourceHash = Assert-Sha256Value `
        $artifact.source.restored_sha256 `
        "Focused source-shape restored source SHA256"
    if ($baselineSourceHash -cne $restoredSourceHash) {
        throw "Focused source-shape source restoration boundary does not match its baseline."
    }

    Assert-JsonObjectShape $artifact.successful_trial @(
        "variant", "status", "hypothesis", "meaningful", "source_sha256",
        "candidate_symbol", "candidate_rva", "raw_diff_count",
        "hard_diff_count", "hard_compared_bytes", "build_duration_ms",
        "diff_duration_ms", "total_duration_ms") `
        "Focused source-shape successful trial"
    $trial = $artifact.successful_trial
    if ([string]$trial.status -cne "OK") {
        throw "Focused source-shape successful trial status is not OK."
    }
    Assert-NonBlankString $trial.variant `
        "Focused source-shape successful trial variant"
    Assert-NonBlankString $trial.hypothesis `
        "Focused source-shape successful trial hypothesis"
    Assert-JsonTrue $trial.meaningful `
        "Focused source-shape successful trial meaningful"
    if ((Assert-Sha256Value $trial.source_sha256 `
            "Focused source-shape successful trial source SHA256") -cne
        [string]$Source.sha256) {
        throw "Focused source-shape successful trial does not bind the current source SHA256."
    }
    if ([string]$trial.candidate_symbol -cne $ExpectedCandidateSymbol) {
        throw ("Focused source-shape successful trial candidate symbol '{0}' " +
            "does not match dossier manifest symbol '{1}'.") -f
            $trial.candidate_symbol, $ExpectedCandidateSymbol
    }
    Assert-NonBlankString $trial.candidate_rva `
        "Focused source-shape successful trial candidate RVA"
    $trialRawDiffCount = Assert-JsonNonnegativeInteger `
        $trial.raw_diff_count "Focused source-shape successful trial raw_diff_count"
    $trialHardDiffCount = Assert-JsonNonnegativeInteger `
        $trial.hard_diff_count "Focused source-shape successful trial hard_diff_count"
    $trialHardComparedBytes = Assert-JsonNonnegativeInteger `
        $trial.hard_compared_bytes `
        "Focused source-shape successful trial hard_compared_bytes"
    if ($trialHardDiffCount -ne 0 -or $trialHardComparedBytes -le 0) {
        throw "Focused source-shape successful trial does not prove a zero-hard-residual comparison."
    }
    $trialTimings = @{}
    foreach ($timingName in @(
            "build_duration_ms", "diff_duration_ms", "total_duration_ms")) {
        $trialTimings[$timingName] = Assert-JsonNonnegativeInteger `
            $trial.PSObject.Properties[$timingName].Value `
            "Focused source-shape successful trial $timingName"
    }

    Assert-JsonObjectShape $artifact.restoration @(
        "attempted", "passed", "used_trusted_graph",
        "baseline_candidate_normalized_sha256",
        "restored_candidate_normalized_sha256",
        "baseline_map_normalized_sha256", "restored_map_normalized_sha256",
        "baseline_object_sha256", "restored_object_sha256") `
        "Focused source-shape restoration"
    $restoration = $artifact.restoration
    Assert-JsonTrue $restoration.attempted `
        "Focused source-shape restoration attempted"
    Assert-JsonTrue $restoration.passed `
        "Focused source-shape restoration passed"
    if (-not ($restoration.used_trusted_graph -is [bool]) -or
        [bool]$restoration.used_trusted_graph) {
        throw "Focused source-shape restoration must use a non-trusting graph validation."
    }
    foreach ($boundary in @(
            [pscustomobject]@{
                Name = "candidate-normalized"
                Baseline = "baseline_candidate_normalized_sha256"
                Restored = "restored_candidate_normalized_sha256"
            },
            [pscustomobject]@{
                Name = "map-normalized"
                Baseline = "baseline_map_normalized_sha256"
                Restored = "restored_map_normalized_sha256"
            },
            [pscustomobject]@{
                Name = "object"
                Baseline = "baseline_object_sha256"
                Restored = "restored_object_sha256"
            })) {
        $baselineHash = Assert-Sha256Value `
            $restoration.PSObject.Properties[$boundary.Baseline].Value `
            "Focused source-shape baseline $($boundary.Name) SHA256"
        $restoredHash = Assert-Sha256Value `
            $restoration.PSObject.Properties[$boundary.Restored].Value `
            "Focused source-shape restored $($boundary.Name) SHA256"
        if ($baselineHash -cne $restoredHash) {
            throw ("Focused source-shape restored {0} does not match its " +
                "baseline boundary.") -f $boundary.Name
        }
    }

    Assert-JsonObjectShape $artifact.run_summary @(
        "warm_baseline_reused", "baseline_setup_duration_ms",
        "baseline_diff_duration_ms", "trial_count",
        "meaningful_trial_count", "trial_tool_time_ms", "trial_wall_time_ms",
        "variant_loop_duration_ms", "restoration_duration_ms",
        "runner_elapsed_before_evidence_ms",
        "maximum_focused_build_seconds", "maximum_focused_diff_seconds",
        "build_latency_budget_exceeded", "diff_latency_budget_exceeded",
        "stop_reason") `
        "Focused source-shape run summary"
    $runSummary = $artifact.run_summary
    foreach ($booleanName in @(
            "warm_baseline_reused", "build_latency_budget_exceeded",
            "diff_latency_budget_exceeded")) {
        if (-not ($runSummary.PSObject.Properties[$booleanName].Value -is [bool])) {
            throw "Focused source-shape run summary $booleanName must be a JSON boolean."
        }
    }
    $summaryTimings = @{}
    foreach ($timingName in @(
            "baseline_setup_duration_ms", "baseline_diff_duration_ms",
            "trial_tool_time_ms", "trial_wall_time_ms",
            "variant_loop_duration_ms", "restoration_duration_ms",
            "runner_elapsed_before_evidence_ms")) {
        $summaryTimings[$timingName] = Assert-JsonNonnegativeInteger `
            $runSummary.PSObject.Properties[$timingName].Value `
            "Focused source-shape run summary $timingName"
    }
    $trialCount = Assert-JsonNonnegativeInteger $runSummary.trial_count `
        "Focused source-shape run summary trial_count"
    $meaningfulTrialCount = Assert-JsonNonnegativeInteger `
        $runSummary.meaningful_trial_count `
        "Focused source-shape run summary meaningful_trial_count"
    if ($trialCount -lt 1 -or $meaningfulTrialCount -lt 1 -or
        $meaningfulTrialCount -gt $trialCount) {
        throw "Focused source-shape run summary trial counts are invalid."
    }
    $maximumFocusedBuildSeconds = Assert-JsonNonnegativeInteger `
        $runSummary.maximum_focused_build_seconds `
        "Focused source-shape run summary maximum_focused_build_seconds"
    $maximumFocusedDiffSeconds = Assert-JsonNonnegativeInteger `
        $runSummary.maximum_focused_diff_seconds `
        "Focused source-shape run summary maximum_focused_diff_seconds"
    if ($maximumFocusedBuildSeconds -lt 1 -or
        $maximumFocusedBuildSeconds -gt 3600 -or
        $maximumFocusedDiffSeconds -lt 1 -or
        $maximumFocusedDiffSeconds -gt 3600) {
        throw "Focused source-shape run summary latency budgets are invalid."
    }
    if ($summaryTimings.trial_tool_time_ms -lt
            ($trialTimings.build_duration_ms + $trialTimings.diff_duration_ms) -or
        $summaryTimings.trial_wall_time_ms -lt $trialTimings.total_duration_ms) {
        throw "Focused source-shape run summary does not cover the successful trial timing."
    }
    if ($summaryTimings.variant_loop_duration_ms -lt
            $summaryTimings.trial_wall_time_ms -or
        $summaryTimings.runner_elapsed_before_evidence_ms -lt
            ($summaryTimings.baseline_setup_duration_ms +
             $summaryTimings.baseline_diff_duration_ms +
             $summaryTimings.variant_loop_duration_ms +
             $summaryTimings.restoration_duration_ms)) {
        throw "Focused source-shape run summary phase timings are inconsistent."
    }
    $buildBudgetExceeded = [bool]$runSummary.build_latency_budget_exceeded
    $diffBudgetExceeded = [bool]$runSummary.diff_latency_budget_exceeded
    $runStopReason = [string]$runSummary.stop_reason
    if (-not ($runSummary.stop_reason -is [string])) {
        throw "Focused source-shape run summary stop_reason must be a JSON string."
    }
    $buildBudgetMs = $maximumFocusedBuildSeconds * 1000L
    $diffBudgetMs = $maximumFocusedDiffSeconds * 1000L
    if ($trialTimings.build_duration_ms -gt $buildBudgetMs -and
        -not $buildBudgetExceeded) {
        throw "Focused source-shape build timing exceeds its budget without the latency flag."
    }
    if ($trialTimings.diff_duration_ms -gt $diffBudgetMs -and
        -not $diffBudgetExceeded) {
        throw "Focused source-shape diff timing exceeds its budget without the latency flag."
    }
    if ($buildBudgetExceeded -and
        $runStopReason -notmatch '^focused-build latency budget exceeded') {
        throw "Focused source-shape build-latency stop is missing its canonical reason."
    }
    if (-not $buildBudgetExceeded -and $diffBudgetExceeded -and
        $runStopReason -notmatch '^focused-diff latency budget exceeded') {
        throw "Focused source-shape diff-latency stop is missing its canonical reason."
    }
    if (-not $buildBudgetExceeded -and -not $diffBudgetExceeded -and
        $runStopReason -match '^focused-(build|diff) latency budget exceeded') {
        throw "Focused source-shape latency stop reason has no exceeded budget."
    }

    return [pscustomobject][ordered]@{
        schema_version = 1
        runner_sha256 = $runnerHash
        identity = $Identity
        checkpoint_id = $CheckpointId
        prior_boundary_run_id = $BoundaryRunId
        source_path = [string]$Source.path
        source_sha256 = [string]$Source.sha256
        candidate_symbol = [string]$trial.candidate_symbol
        variant = [string]$trial.variant
        hard_diff_count = [long]$trial.hard_diff_count
        hard_compared_bytes = [long]$trial.hard_compared_bytes
        restoration_passed = $true
    }
}

function Test-ProductReanchorPromotionResult {
    param(
        $File,
        [string]$Identity,
        $Source,
        [string]$CheckpointId,
        $BoundaryRun,
        [string]$ExpectedCandidateSymbol,
        [string]$ExpectedCandidateObject,
        $CurrentMetricsSummary,
        [string]$CheckpointCandidateMapPath,
        [string]$CheckpointVerifierResultsPath
    )

    if ([string]$File.path -notmatch '^(?i:a|artifacts)/') {
        throw "Product reanchor focused evidence must remain below ignored a/ or artifacts/."
    }
    & git -C $repoRoot check-ignore --quiet -- ([string]$File.path) 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Product reanchor focused evidence must be Git-ignored."
    }
    $artifact = Read-JsonEvidenceArtifact $File "Product reanchor promotion evidence"
    Assert-JsonObjectShape $artifact @(
        "schema_version", "artifact_type", "generator", "identity",
        "checkpoint", "manifest_delta", "source", "build",
        "focused_diff", "symbol_containment", "verifier", "mask_audit",
        "product_source_audit", "source_mutation", "promotion_eligible") "Product reanchor promotion evidence"
    if ([int]$artifact.schema_version -ne 1 -or [string]$artifact.artifact_type -cne "otwin-product-reanchor-evidence") {
        throw "Product reanchor evidence must use its canonical schema-1 artifact type."
    }
    Assert-JsonTrue $artifact.promotion_eligible "Product reanchor promotion_eligible"

    Assert-JsonObjectShape $artifact.generator @(
        "name", "schema_version", "script_path", "script_sha256") "Product reanchor generator"
    $generatorRelative = "tools/otmatch/invoke-product-reanchor-evidence.ps1"
    if ([string]$artifact.generator.name -cne "otmatch-product-reanchor-evidence" -or [int]$artifact.generator.schema_version -ne 1 -or -not (Test-SameEvidencePath ([string]$artifact.generator.script_path) $generatorRelative)) {
        throw "Product reanchor generator provenance is not canonical schema 1."
    }
    $generatorHash = Assert-Sha256Value $artifact.generator.script_sha256 "Product reanchor generator SHA256"
    if ($generatorHash -cne (Get-FileSha256Hex (Join-Path $repoRoot $generatorRelative))) {
        throw "Product reanchor generator SHA256 is stale."
    }

    Assert-JsonObjectShape $artifact.identity @(
        "key", "program", "name", "original_rva", "size") "Product reanchor identity"
    if ([string]$artifact.identity.key -cne $Identity) {
        throw "Product reanchor identity does not match the promoted identity."
    }
    if ([string]$artifact.identity.program -cne "Oregon32.exe" -or
        $Identity -cnotmatch '^oregon32\.exe\|') {
        throw "Product reanchor evidence is restricted to the Oregon32.exe main image."
    }
    $artifactRva = ConvertFrom-ReanchorNumber ([string]$artifact.identity.original_rva) "artifact original_rva"
    $artifactSize = Assert-JsonNonnegativeInteger $artifact.identity.size "Product reanchor identity size"
    if ($artifactSize -le 0) {
        throw "Product reanchor identity size must be positive."
    }

    Assert-JsonObjectShape $artifact.checkpoint @(
        "checkpoint_id", "prior_boundary_run_id", "prior_boundary_git_commit") "Product reanchor checkpoint"
    $boundaryCommit = ([string]$BoundaryRun.git_commit_sha).Trim().ToLowerInvariant()
    foreach ($propertyName in @(
            "git_snapshot_captured", "git_commit_sha",
            "worktree_state_sha256", "worktree_dirty",
            "git_end_snapshot_captured", "git_end_commit_sha",
            "end_worktree_state_sha256", "end_worktree_dirty")) {
        if ($null -eq $BoundaryRun.PSObject.Properties[$propertyName]) {
            throw "Product reanchor prior boundary lacks clean committed evidence."
        }
    }
    if ([string]$BoundaryRun.mode -cne "execute" -or
        [string]$BoundaryRun.status -cne "passed" -or
        -not ($BoundaryRun.git_snapshot_captured -is [bool]) -or
        -not [bool]$BoundaryRun.git_snapshot_captured -or
        -not ($BoundaryRun.git_end_snapshot_captured -is [bool]) -or
        -not [bool]$BoundaryRun.git_end_snapshot_captured -or
        -not ($BoundaryRun.worktree_dirty -is [bool]) -or
        [bool]$BoundaryRun.worktree_dirty -or
        -not ($BoundaryRun.end_worktree_dirty -is [bool]) -or
        [bool]$BoundaryRun.end_worktree_dirty) {
        throw "Product reanchor prior boundary must be clean and committed at a passed executed run."
    }
    $boundaryStartState = ([string]$BoundaryRun.worktree_state_sha256).
        Trim().ToLowerInvariant()
    $boundaryEndState = ([string]$BoundaryRun.end_worktree_state_sha256).
        Trim().ToLowerInvariant()
    if ([string]$BoundaryRun.git_end_commit_sha -cne $boundaryCommit -or
        $boundaryStartState -notmatch '^[0-9a-f]{64}$' -or
        $boundaryEndState -cne $boundaryStartState) {
        throw "Product reanchor prior boundary must bind one clean, stable commit."
    }
    if ($boundaryCommit -notmatch '^[0-9a-f]{40}$' -or [string]$artifact.checkpoint.checkpoint_id -cne $CheckpointId -or [string]$artifact.checkpoint.prior_boundary_run_id -cne [string]$BoundaryRun.run_id -or [string]$artifact.checkpoint.prior_boundary_git_commit -cne $boundaryCommit) {
        throw "Product reanchor checkpoint, boundary run, or Git commit is stale."
    }

    $manifestAbsolute = if ([System.IO.Path]::IsPathRooted($ManifestPath)) {
        [System.IO.Path]::GetFullPath($ManifestPath)
    }
    else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $ManifestPath))
    }
    if (-not (Test-Path -LiteralPath $manifestAbsolute -PathType Leaf)) {
        throw "Current Product reanchor manifest is missing."
    }
    $repoPrefix = $repoRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    if (-not $manifestAbsolute.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Current Product reanchor manifest escaped the repository."
    }
    $manifestRelative = $manifestAbsolute.Substring($repoPrefix.Length).Replace('\', '/')
    $manifestHash = Get-FileSha256Hex $manifestAbsolute
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $currentStatus = @(& git -C $repoRoot status --porcelain=v1 `
            --untracked-files=all 2>&1 | ForEach-Object { [string]$_ })
        $currentStatusExit = $LASTEXITCODE
        $headOutput = @(& git -C $repoRoot rev-parse HEAD 2>&1 |
            ForEach-Object { [string]$_ })
        $headExit = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
    $currentStatus = @($currentStatus | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    })
    if ($currentStatusExit -ne 0 -or $currentStatus.Count -ne 0) {
        throw "Product reanchor promotion requires a clean current worktree."
    }
    if ($headExit -ne 0 -or $headOutput.Count -ne 1 -or
        $headOutput[0].Trim().ToLowerInvariant() -notmatch '^[0-9a-f]{40}$') {
        throw "Product reanchor promotion could not resolve current HEAD."
    }
    $headCommit = $headOutput[0].Trim().ToLowerInvariant()
    if (-not (Test-GitAncestor $boundaryCommit $headCommit)) {
        throw "Product reanchor prior boundary is not an ancestor of current committed HEAD."
    }
    $headManifestOid = Get-ReanchorGitBlobOid $headCommit $manifestRelative `
        "Current Product reanchor manifest blob"
    $worktreeManifestOid = Get-ReanchorWorktreeBlobOid $manifestAbsolute `
        "Current Product reanchor manifest worktree blob"
    if ($headManifestOid -cne $worktreeManifestOid) {
        throw "Product reanchor current manifest is not committed at HEAD."
    }
    $priorRows = Get-GitFileRowsAtCommit $boundaryCommit $manifestRelative "Prior Product reanchor manifest"
    $currentRows = @(Import-Csv -LiteralPath $manifestAbsolute)
    $manifestChange = Get-ReanchorManifestChange $priorRows $currentRows $Identity

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $trackedDelta = @(& git -C $repoRoot diff --name-only $boundaryCommit -- 2>&1 | ForEach-Object { [string]$_ })
        $trackedDeltaExit = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
    $trackedDelta = @($trackedDelta | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim().Replace('\', '/') })
    if ($trackedDeltaExit -ne 0 -or $trackedDelta.Count -ne 1 -or $trackedDelta[0] -cne $manifestRelative) {
        throw "Product reanchor requires the manifest to be the sole tracked delta from the prior boundary."
    }

    Assert-JsonObjectShape $artifact.manifest_delta @(
        "path", "current_sha256", "prior_git_blob_oid",
        "changed_row_count", "changed_identity", "tracked_paths",
        "changed_fields", "allowed_fields", "prior_row", "current_row") "Product reanchor manifest delta"
    if (-not (Test-SameEvidencePath ([string]$artifact.manifest_delta.path) $manifestRelative) -or (Assert-Sha256Value $artifact.manifest_delta.current_sha256 "Product reanchor current manifest SHA256") -cne $manifestHash -or (Assert-JsonNonnegativeInteger $artifact.manifest_delta.changed_row_count "Product reanchor changed_row_count") -ne 1 -or [string]$artifact.manifest_delta.changed_identity -cne $Identity) {
        throw "Product reanchor manifest binding is stale or not a one-row delta."
    }
    [string[]]$reportedTrackedPaths = @($artifact.manifest_delta.tracked_paths | ForEach-Object { [string]$_ })
    Assert-ExactStringSet $reportedTrackedPaths @($manifestRelative) "Product reanchor tracked paths"
    [string[]]$reportedChangedFields = @($artifact.manifest_delta.changed_fields | ForEach-Object { [string]$_ })
    [string[]]$reportedAllowedFields = @($artifact.manifest_delta.allowed_fields | ForEach-Object { [string]$_ })
    Assert-ExactStringSet $reportedChangedFields @($manifestChange.fields) "Product reanchor changed fields"
    Assert-ExactStringSet $reportedAllowedFields @($manifestChange.allowed_fields) "Product reanchor allowed fields"
    Assert-ReanchorRowRecord $artifact.manifest_delta.prior_row $manifestChange.prior @($manifestChange.all_fields) "Product reanchor prior row"
    Assert-ReanchorRowRecord $artifact.manifest_delta.current_row $manifestChange.current @($manifestChange.all_fields) "Product reanchor current row"

    $priorBlob = Get-ReanchorGitBlobOid $boundaryCommit $manifestRelative `
        "Prior Product reanchor manifest blob"
    if ([string]$artifact.manifest_delta.prior_git_blob_oid -cne $priorBlob) {
        throw "Product reanchor prior manifest blob binding is stale."
    }

    $currentName = Get-ReanchorCsvField $manifestChange.current "name"
    $currentProgram = Get-ReanchorCsvField $manifestChange.current "program"
    $currentRva = ConvertFrom-ReanchorNumber (Get-ReanchorCsvField $manifestChange.current "original_rva") "current original_rva"
    $currentSize = ConvertFrom-ReanchorNumber (Get-ReanchorCsvField $manifestChange.current "size") "current size"
    $currentMask = Get-ReanchorCsvField $manifestChange.current "mask"
    $currentObject = Get-ReanchorCsvField $manifestChange.current "candidate_object"
    $priorObject = Get-ReanchorCsvField $manifestChange.prior "candidate_object"
    if ([string]$artifact.identity.name -cne $currentName -or
        [string]$currentProgram -cne "Oregon32.exe" -or
        [string]$artifact.identity.program -cne $currentProgram -or
        $artifactRva -ne $currentRva -or $artifactSize -ne $currentSize -or
        $ExpectedCandidateSymbol -cne
            (Get-ReanchorCsvField $manifestChange.current "candidate_symbol") -or
        -not $ExpectedCandidateObject.Equals(
            $currentObject,
            [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Product reanchor identity disagrees with the current manifest row."
    }

    Assert-JsonObjectShape $artifact.source @(
        "path", "before_sha256", "after_sha256",
        "unchanged_from_boundary", "boundary_git_blob_oid",
        "current_git_blob_oid", "object_name",
        "product_manifest_path", "product_manifest_sha256",
        "product_reachable") "Product reanchor source"
    if (-not (Test-SameEvidencePath ([string]$artifact.source.path) ([string]$Source.path))) {
        throw "Product reanchor source path does not match promotion evidence."
    }
    $beforeHash = Assert-Sha256Value $artifact.source.before_sha256 "Product reanchor source before SHA256"
    $afterHash = Assert-Sha256Value $artifact.source.after_sha256 "Product reanchor source after SHA256"
    if ($beforeHash -cne [string]$Source.sha256 -or $afterHash -cne [string]$Source.sha256) {
        throw "Product reanchor source hash changed before or after the normal build."
    }
    Assert-JsonTrue $artifact.source.unchanged_from_boundary "Product reanchor source unchanged_from_boundary"
    Assert-JsonTrue $artifact.source.product_reachable "Product reanchor source product_reachable"
    $sourceBoundaryOid = Get-ReanchorGitBlobOid $boundaryCommit `
        ([string]$Source.path) "Product reanchor boundary source blob"
    $sourceHeadOid = Get-ReanchorGitBlobOid $headCommit `
        ([string]$Source.path) "Product reanchor current committed source blob"
    $sourceCurrentOid = Get-ReanchorWorktreeBlobOid `
        ([string]$Source.absolute_path) "Product reanchor current source blob"
    if ([string]$artifact.source.boundary_git_blob_oid -cne
            $sourceBoundaryOid -or
        [string]$artifact.source.current_git_blob_oid -cne $sourceCurrentOid -or
        $sourceBoundaryOid -cne $sourceHeadOid -or
        $sourceHeadOid -cne $sourceCurrentOid) {
        throw "Product reanchor source does not exactly match the prior boundary bytes."
    }

    $productManifestRelative = "tools/otmatch/vc4-exe-product-sources.txt"
    $productManifestAbsolute = Join-Path $repoRoot $productManifestRelative
    if (-not (Test-SameEvidencePath ([string]$artifact.source.product_manifest_path) $productManifestRelative) -or (Assert-Sha256Value $artifact.source.product_manifest_sha256 "Product reanchor Product manifest SHA256") -cne (Get-FileSha256Hex $productManifestAbsolute)) {
        throw "Product reanchor Product source-manifest binding is stale."
    }
    $productSources = Get-DirectProductSourcePaths $productManifestAbsolute
    $sourceMatches = @($productSources | Where-Object { Test-SameEvidencePath $_ ([string]$Source.path) })
    if ($sourceMatches.Count -ne 1) {
        throw "Product reanchor source is not exactly once in the Product source list."
    }
    $sourceObject = Get-ProductObjectName ([string]$Source.path)
    if ([string]$artifact.source.object_name -cne $sourceObject -or -not $currentObject.Equals($sourceObject, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Product reanchor candidate object is not owned by its Product source."
    }
    $productObjects = @($productSources | ForEach-Object { Get-ProductObjectName $_ })
    if (@($productObjects | Where-Object {
            $_.Equals($currentObject,
                [System.StringComparison]::OrdinalIgnoreCase)
        }).Count -ne 1) {
        throw "Product reanchor candidate object is not uniquely owned by one Product source."
    }
    if (-not [string]::IsNullOrWhiteSpace($priorObject) -and @($productObjects | Where-Object { $_.Equals($priorObject, [System.StringComparison]::OrdinalIgnoreCase) }).Count -ne 0) {
        throw "Product reanchor prior WIP owner was already Product-reachable."
    }

    Assert-JsonObjectShape $artifact.build @(
        "tool", "mode", "toolchain", "vc_tools_root",
        "default_optimization", "semantic_optimization", "tu_metadata",
        "rebuild", "used_trusted_graph",
        "output_directory", "duration_ms", "candidate_file",
        "candidate_map", "candidate_object") "Product reanchor build"
    $buildToolHash = Test-ReanchorToolRecord $artifact.build.tool "tools/otmatch/build-match-candidates.ps1" "Product reanchor build tool"
    if ([string]$artifact.build.mode -cne "normal-rebuild") {
        throw "Product reanchor evidence must use a fresh normal rebuild."
    }
    if ([string]$artifact.build.toolchain -cne "LegacyMsvc" -or
        -not [System.IO.Path]::GetFullPath(
            [string]$artifact.build.vc_tools_root).Equals(
                [System.IO.Path]::GetFullPath("C:\MSDEV"),
                [System.StringComparison]::OrdinalIgnoreCase) -or
        [string]$artifact.build.default_optimization -cne "/Od" -or
        [string]$artifact.build.semantic_optimization -cne "/O1") {
        throw "Product reanchor build configuration is not canonical VC4 /Od+/O1."
    }
    $tuMetadataFile = Get-SafeProductReanchorFile `
        $artifact.build.tu_metadata "TU metadata" @(".csv")
    if (-not (Test-SameEvidencePath ([string]$tuMetadataFile.path) `
            "tools/otmatch/vc4-tu-metadata.csv")) {
        throw "Product reanchor TU-metadata provenance is not canonical."
    }
    Assert-JsonTrue $artifact.build.rebuild "Product reanchor build rebuild"
    if (-not ($artifact.build.used_trusted_graph -is [bool]) -or [bool]$artifact.build.used_trusted_graph) {
        throw "Product reanchor build cannot use a trusted graph shortcut."
    }
    [void](Assert-JsonNonnegativeInteger $artifact.build.duration_ms "Product reanchor build duration_ms")
    $candidateFile = Get-SafeProductReanchorFile `
        $artifact.build.candidate_file "candidate file" @(".dll") `
        -RequireIgnoredOutput
    $candidateMap = Get-SafeProductReanchorFile `
        $artifact.build.candidate_map "candidate map" @(".map") `
        -RequireIgnoredOutput
    $candidateObjectFile = Get-SafeProductReanchorFile `
        $artifact.build.candidate_object "candidate object" @(".obj") `
        -RequireIgnoredOutput
    $outputDirectory = ([string]$artifact.build.output_directory).Replace('\', '/').TrimEnd('/')
    foreach ($builtEvidence in @($candidateFile, $candidateMap, $candidateObjectFile)) {
        $parent = [System.IO.Path]::GetDirectoryName(([string]$builtEvidence.path).Replace('/', '\')).Replace('\', '/')
        if ($parent -cne $outputDirectory) {
            throw "Product reanchor build files do not share the declared output directory."
        }
    }
    if ([System.IO.Path]::GetFileName($candidateFile.path) -cne "otwin-match-candidates.dll" -or [System.IO.Path]::GetFileName($candidateMap.path) -cne "otwin-match-candidates.map" -or -not [System.IO.Path]::GetFileName($candidateObjectFile.path).Equals($currentObject, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Product reanchor normal build files do not bind the intended object."
    }

    Assert-JsonObjectShape $artifact.focused_diff @(
        "tool", "candidate_symbol", "candidate_object", "candidate_rva",
        "original_rva", "size", "mask", "raw_diff_count",
        "raw_compared_bytes", "hard_diff_count", "hard_compared_bytes",
        "duration_ms") "Product reanchor focused diff"
    $diffToolHash = Test-ReanchorToolRecord $artifact.focused_diff.tool "tools/otmatch/diff-symbol-bytes.ps1" "Product reanchor focused-diff tool"
    if ([string]$artifact.focused_diff.candidate_symbol -cne $ExpectedCandidateSymbol -or -not ([string]$artifact.focused_diff.candidate_object).Equals($currentObject, [System.StringComparison]::OrdinalIgnoreCase) -or [string]$artifact.focused_diff.mask -cne $currentMask -or (ConvertFrom-ReanchorNumber ([string]$artifact.focused_diff.original_rva) "focused original_rva") -ne $currentRva -or (Assert-JsonNonnegativeInteger $artifact.focused_diff.size "Product reanchor focused size") -ne $currentSize) {
        throw "Product reanchor focused diff locator or identity is stale."
    }
    Assert-NonBlankString $artifact.focused_diff.candidate_rva "Product reanchor focused candidate_rva"
    $focusedCandidateRva = ConvertFrom-ReanchorNumber `
        ([string]$artifact.focused_diff.candidate_rva) `
        "focused candidate_rva"
    $rawDiff = Assert-JsonNonnegativeInteger $artifact.focused_diff.raw_diff_count "Product reanchor raw_diff_count"
    $rawCompared = Assert-JsonNonnegativeInteger $artifact.focused_diff.raw_compared_bytes "Product reanchor raw_compared_bytes"
    $hardDiff = Assert-JsonNonnegativeInteger $artifact.focused_diff.hard_diff_count "Product reanchor hard_diff_count"
    $hardCompared = Assert-JsonNonnegativeInteger $artifact.focused_diff.hard_compared_bytes "Product reanchor hard_compared_bytes"
    if ($rawDiff -ne 0 -or $hardDiff -ne 0 -or $rawCompared -ne $currentSize -or $hardCompared -le 0) {
        throw "Product reanchor focused diff is not zero raw and zero hard."
    }
    [void](Assert-JsonNonnegativeInteger $artifact.focused_diff.duration_ms "Product reanchor focused diff duration_ms")

    $expectedContainment = Get-ProductReanchorSymbolContainment `
        ([string]$candidateMap.absolute_path) $ExpectedCandidateSymbol `
        $currentObject $focusedCandidateRva $currentSize
    Assert-ProductReanchorSymbolContainment `
        $artifact.symbol_containment $expectedContainment

    Assert-JsonObjectShape $artifact.verifier @(
        "tool", "results", "result_schema_version",
        "verification_status", "actual_status", "expected_status",
        "raw_match", "mask_shape_valid", "candidate_symbol",
        "candidate_object", "candidate_object_qualifier", "candidate_rva", "candidate_dll",
        "candidate_locator_kind", "duration_ms") "Product reanchor verifier"
    $matcherHash = Test-ReanchorToolRecord $artifact.verifier.tool "tools/otmatch/match-functions.ps1" "Product reanchor matcher tool"
    $verifierFile = Get-SafeProductReanchorFile `
        $artifact.verifier.results "verifier results" @(".csv") `
        -RequireIgnoredOutput
    if ([int]$artifact.verifier.result_schema_version -ne 4 -or [string]$artifact.verifier.verification_status -cne "pass" -or [string]$artifact.verifier.actual_status -cne "match" -or [string]$artifact.verifier.expected_status -cne "match") {
        throw "Product reanchor verifier summary is not an accepted schema-4 match."
    }
    Assert-JsonTrue $artifact.verifier.raw_match "Product reanchor verifier raw_match"
    Assert-JsonTrue $artifact.verifier.mask_shape_valid "Product reanchor verifier mask_shape_valid"
    if ([string]$artifact.verifier.candidate_symbol -cne
            $ExpectedCandidateSymbol -or
        -not ([string]$artifact.verifier.candidate_object).Equals(
            $currentObject, [System.StringComparison]::OrdinalIgnoreCase) -or
        -not ([string]$artifact.verifier.candidate_object_qualifier).Equals(
            $currentObject, [System.StringComparison]::OrdinalIgnoreCase) -or
        [string]$artifact.verifier.candidate_rva -cne
            [string]$artifact.focused_diff.candidate_rva -or
        -not [string]::IsNullOrWhiteSpace(
            [string]$artifact.verifier.candidate_dll) -or
        [string]$artifact.verifier.candidate_locator_kind -cne
            "candidate_symbol") {
        throw "Product reanchor verifier locator disagrees with the focused diff."
    }
    [void](Assert-JsonNonnegativeInteger $artifact.verifier.duration_ms "Product reanchor verifier duration_ms")
    $verifierRows = @(Import-Csv -LiteralPath $verifierFile.absolute_path | Where-Object {
        (Get-ReanchorCsvField $_ "name").Equals($currentName, [System.StringComparison]::OrdinalIgnoreCase) -and
        (Get-ReanchorCsvField $_ "program").Equals($currentProgram, [System.StringComparison]::OrdinalIgnoreCase)
    })
    if ($verifierRows.Count -ne 1) {
        throw "Product reanchor schema-4 result row is missing or ambiguous."
    }
    $verified = $verifierRows[0]
    if ((Get-ReanchorCsvField $verified "result_schema_version") -cne "4" -or
        (Get-ReanchorCsvField $verified "manifest_sha256") -cne $manifestHash -or
        (Get-ReanchorCsvField $verified "verification_status") -cne "pass" -or
        (Get-ReanchorCsvField $verified "actual_status") -cne "match" -or
        (Get-ReanchorCsvField $verified "expected_status") -cne "match" -or
        (Get-ReanchorCsvField $verified "raw_match") -cne "True" -or
        (Get-ReanchorCsvField $verified "mask_shape_valid") -cne "True" -or
        (Get-ReanchorCsvField $verified "candidate_locator_kind") -cne
            "candidate_symbol" -or
        -not [string]::IsNullOrWhiteSpace(
            (Get-ReanchorCsvField $verified "candidate_dll")) -or
        (Get-ReanchorCsvField $verified "candidate_symbol") -cne
            $ExpectedCandidateSymbol -or
        -not (Get-ReanchorCsvField $verified "candidate_object").Equals(
            $currentObject, [System.StringComparison]::OrdinalIgnoreCase) -or
        -not (Get-ReanchorCsvField $verified "candidate_object_qualifier").Equals(
            $currentObject, [System.StringComparison]::OrdinalIgnoreCase) -or
        (Get-ReanchorCsvField $verified "candidate_rva") -cne
            [string]$artifact.focused_diff.candidate_rva -or
        (Get-ReanchorCsvField $verified "candidate_file_sha256") -cne
            [string]$candidateFile.sha256 -or
        (Get-ReanchorCsvField $verified "candidate_map_sha256") -cne
            [string]$candidateMap.sha256 -or
        -not [string]::IsNullOrWhiteSpace(
            (Get-ReanchorCsvField $verified "error_message"))) {
        throw "Product reanchor schema-4 result does not bind the exact current build."
    }

    $checkpointMap = Get-CurrentProductReanchorFile `
        $CheckpointCandidateMapPath "checkpoint candidate map" @(".map")
    $checkpointVerifierFile = Get-CurrentProductReanchorFile `
        $CheckpointVerifierResultsPath "checkpoint verifier results" @(".csv")
    if ($null -eq $CurrentMetricsSummary -or
        $null -eq $CurrentMetricsSummary.inputs -or
        $null -eq $CurrentMetricsSummary.inputs.verifier_results) {
        throw "Product reanchor current metrics lack checkpoint verifier provenance."
    }
    $metricsVerifier = $CurrentMetricsSummary.inputs.verifier_results
    Assert-JsonRequiredProperties $metricsVerifier @("path", "sha256") `
        "Product reanchor current metrics verifier provenance"
    $metricsVerifierAbsolute = if ([System.IO.Path]::IsPathRooted(
            [string]$metricsVerifier.path)) {
        [System.IO.Path]::GetFullPath([string]$metricsVerifier.path)
    }
    else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot `
            ([string]$metricsVerifier.path)))
    }
    if (-not $metricsVerifierAbsolute.Equals(
            [string]$checkpointVerifierFile.absolute_path,
            [System.StringComparison]::OrdinalIgnoreCase) -or
        (Assert-Sha256Value $metricsVerifier.sha256 `
            "Product reanchor current metrics verifier SHA256") -cne
            [string]$checkpointVerifierFile.sha256) {
        throw "Product reanchor checkpoint verifier is not the metrics-accepted result."
    }
    $checkpointRows = @(Import-Csv -LiteralPath `
        $checkpointVerifierFile.absolute_path | Where-Object {
            (Get-ReanchorCsvField $_ "name").Equals(
                $currentName,
                [System.StringComparison]::OrdinalIgnoreCase) -and
            (Get-ReanchorCsvField $_ "program").Equals(
                $currentProgram,
                [System.StringComparison]::OrdinalIgnoreCase)
        })
    if ($checkpointRows.Count -ne 1) {
        throw "Product reanchor checkpoint schema-4 result row is missing or ambiguous."
    }
    $checkpointVerified = $checkpointRows[0]
    if ((Get-ReanchorCsvField $checkpointVerified "result_schema_version") -cne
            "4" -or
        (Get-ReanchorCsvField $checkpointVerified "manifest_sha256") -cne
            $manifestHash -or
        (Get-ReanchorCsvField $checkpointVerified "verification_status") -cne
            "pass" -or
        (Get-ReanchorCsvField $checkpointVerified "actual_status") -cne
            "match" -or
        (Get-ReanchorCsvField $checkpointVerified "expected_status") -cne
            "match" -or
        (Get-ReanchorCsvField $checkpointVerified "raw_match") -cne "True" -or
        (Get-ReanchorCsvField $checkpointVerified "mask_shape_valid") -cne
            "True" -or
        (Get-ReanchorCsvField $checkpointVerified `
            "candidate_locator_kind") -cne "candidate_symbol" -or
        -not [string]::IsNullOrWhiteSpace(
            (Get-ReanchorCsvField $checkpointVerified "candidate_dll")) -or
        (Get-ReanchorCsvField $checkpointVerified "candidate_symbol") -cne
            $ExpectedCandidateSymbol -or
        -not (Get-ReanchorCsvField $checkpointVerified `
            "candidate_object").Equals(
                $currentObject,
                [System.StringComparison]::OrdinalIgnoreCase) -or
        -not (Get-ReanchorCsvField $checkpointVerified `
            "candidate_object_qualifier").Equals(
                $currentObject,
                [System.StringComparison]::OrdinalIgnoreCase) -or
        (Get-ReanchorCsvField $checkpointVerified "candidate_map_sha256") -cne
            [string]$checkpointMap.sha256 -or
        -not [string]::IsNullOrWhiteSpace(
            (Get-ReanchorCsvField $checkpointVerified "error_message"))) {
        throw "Product reanchor checkpoint schema-4 result does not bind its current map and locator."
    }
    $checkpointCandidateRva = ConvertFrom-ReanchorNumber `
        (Get-ReanchorCsvField $checkpointVerified "candidate_rva") `
        "checkpoint candidate_rva"
    $checkpointContainment = Get-ProductReanchorSymbolContainment `
        ([string]$checkpointMap.absolute_path) $ExpectedCandidateSymbol `
        $currentObject $checkpointCandidateRva $currentSize

    Assert-JsonObjectShape $artifact.mask_audit @(
        "tool", "results", "state", "target_row_count",
        "validated", "duration_ms") "Product reanchor mask audit"
    $maskToolHash = Test-ReanchorToolRecord $artifact.mask_audit.tool "tools/otmatch/audit-function-masks.ps1" "Product reanchor mask-audit tool"
    $maskFile = Get-SafeProductReanchorFile `
        $artifact.mask_audit.results "mask audit results" @(".csv") `
        -RequireIgnoredOutput
    Assert-JsonTrue $artifact.mask_audit.validated "Product reanchor mask audit validated"
    [void](Assert-JsonNonnegativeInteger $artifact.mask_audit.duration_ms "Product reanchor mask audit duration_ms")
    $maskRows = @(Import-Csv -LiteralPath $maskFile.absolute_path | Where-Object {
        (Get-ReanchorCsvField $_ "name").Equals($currentName, [System.StringComparison]::OrdinalIgnoreCase) -and
        (Get-ReanchorCsvField $_ "program").Equals($currentProgram, [System.StringComparison]::OrdinalIgnoreCase)
    })
    if ((Assert-JsonNonnegativeInteger $artifact.mask_audit.target_row_count "Product reanchor mask target_row_count") -ne $maskRows.Count) {
        throw "Product reanchor mask target-row count is stale."
    }
    if ([string]::IsNullOrWhiteSpace($currentMask)) {
        if ([string]$artifact.mask_audit.state -cne "not-required-no-mask" -or $maskRows.Count -ne 0) {
            throw "Maskless Product reanchor lacks a not-applicable mask audit."
        }
    }
    elseif ([string]$artifact.mask_audit.state -cne "validated-original-operands" -or $maskRows.Count -eq 0 -or @($maskRows | Where-Object { -not [string]::IsNullOrWhiteSpace((Get-ReanchorCsvField $_ "issue")) -or (Get-ReanchorCsvField $_ "classification") -cne "full_known_address_operand" }).Count -ne 0) {
        throw "Masked Product reanchor lacks fully validated mask rows."
    }

    Assert-JsonObjectShape $artifact.product_source_audit @(
        "tool", "results", "passed", "duration_ms") "Product reanchor Product source audit"
    $productAuditHash = Test-ReanchorToolRecord $artifact.product_source_audit.tool "tools/otmatch/audit-vc4-product-sources.ps1" "Product reanchor Product-audit tool"
    $productAuditFile = Get-SafeProductReanchorFile `
        $artifact.product_source_audit.results `
        "Product source audit results" @(".json") -RequireIgnoredOutput
    Assert-JsonTrue $artifact.product_source_audit.passed "Product reanchor Product source audit passed"
    [void](Assert-JsonNonnegativeInteger $artifact.product_source_audit.duration_ms "Product reanchor Product audit duration_ms")
    $productAudit = Get-Content -LiteralPath $productAuditFile.absolute_path -Raw | ConvertFrom-Json
    $zeroProductCounts = @(
        "null_import_anchor_count", "null_callback_anchor_count",
        "absolute_code_pointer_anchor_count", "empty_dependency_body_count",
        "trivial_dependency_body_count", "sink_dependency_body_count",
        "empty_deallocator_body_count", "recovery_cpp_include_count",
        "volatile_token_count", "compiler_entropy_marker_count")
    Assert-JsonRequiredProperties $productAudit (@("schema_version", "manifest_path") + $zeroProductCounts) "Product reanchor Product audit result"
    if ([int]$productAudit.schema_version -ne 2 -or -not (Test-SameEvidencePath ([string]$productAudit.manifest_path) $productManifestRelative)) {
        throw "Product reanchor Product audit has stale schema or manifest."
    }
    foreach ($countName in $zeroProductCounts) {
        if ((Assert-JsonNonnegativeInteger $productAudit.PSObject.Properties[$countName].Value "Product reanchor Product audit $countName") -ne 0) {
            throw "Product reanchor Product source audit contains policy debt."
        }
    }

    Assert-JsonObjectShape $artifact.source_mutation @(
        "attempted", "restoration", "disposition") "Product reanchor source mutation"
    if (-not ($artifact.source_mutation.attempted -is [bool]) -or [bool]$artifact.source_mutation.attempted -or [string]$artifact.source_mutation.restoration -cne "not-applicable") {
        throw "Product reanchor source mutation must be unattempted and not applicable."
    }
    Assert-NonBlankString $artifact.source_mutation.disposition "Product reanchor source-mutation disposition"

    return [pscustomobject][ordered]@{
        schema_version = 1
        evidence_mode = "product-reanchor"
        generator_sha256 = $generatorHash
        identity = $Identity
        checkpoint_id = $CheckpointId
        prior_boundary_run_id = [string]$BoundaryRun.run_id
        prior_boundary_git_commit = $boundaryCommit
        current_git_commit = $headCommit
        source_path = [string]$Source.path
        source_sha256 = [string]$Source.sha256
        candidate_symbol = $ExpectedCandidateSymbol
        candidate_object = $currentObject
        symbol_containment = $expectedContainment
        checkpoint_symbol_containment = $checkpointContainment
        manifest_file = [pscustomobject][ordered]@{
            role = "current manifest"
            path = $manifestRelative
            absolute_path = $manifestAbsolute
            sha256 = $manifestHash
            length = [long](Get-Item -LiteralPath $manifestAbsolute).Length
        }
        raw_diff_count = [uint64]$rawDiff
        hard_diff_count = [uint64]$hardDiff
        hard_compared_bytes = [uint64]$hardCompared
        source_mutation = "not-applicable"
        tool_sha256 = [pscustomobject][ordered]@{
            build = $buildToolHash
            diff = $diffToolHash
            matcher = $matcherHash
            mask_audit = $maskToolHash
            product_audit = $productAuditHash
            tu_metadata = [string]$tuMetadataFile.sha256
        }
        provenance_files = @(
            $candidateFile, $candidateMap, $candidateObjectFile,
            $verifierFile, $maskFile, $productAuditFile)
        checkpoint_provenance_files = @(
            $checkpointMap, $checkpointVerifierFile)
    }
}

function Get-PromotionFocusedArtifactType {
    param($File)

    $artifact = Read-JsonEvidenceArtifact $File `
        "Promotion focused-result evidence"
    Assert-JsonRequiredProperties $artifact @(
        "schema_version", "artifact_type") `
        "Promotion focused-result evidence"
    if ([int]$artifact.schema_version -ne 1) {
        throw "Promotion focused-result evidence must use schema_version 1."
    }
    $artifactType = [string]$artifact.artifact_type
    if ($artifactType -cne "otwin-source-shape-evidence" -and
        $artifactType -cne "otwin-product-reanchor-evidence") {
        throw "Unsupported promotion focused-result artifact_type '$artifactType'."
    }
    return $artifactType
}

function Assert-PromotionFocusedArtifactComposition {
    param([string[]]$ArtifactTypes)

    $productCount = @($ArtifactTypes | Where-Object {
        $_ -ceq "otwin-product-reanchor-evidence"
    }).Count
    if ($productCount -ne 0 -and
        ($ArtifactTypes.Count -ne 1 -or $productCount -ne 1)) {
        throw ("Product-reanchor promotion evidence must be the only entry in " +
            "a one-promotion document; mixed or multi-row reanchor waves are " +
            "forbidden.")
    }
}

function Test-PromotionFocusedResult {
    param(
        $File,
        [string]$ArtifactType,
        [string]$Identity,
        $Source,
        [string]$CheckpointId,
        $BoundaryRun,
        $DossierValidation,
        $CurrentMetricsSummary,
        [string]$CheckpointCandidateMapPath,
        [string]$CheckpointVerifierResultsPath
    )

    switch ($ArtifactType) {
        "otwin-source-shape-evidence" {
            return Test-FocusedPromotionResult `
                $File $Identity $Source $CheckpointId `
                ([string]$BoundaryRun.run_id) `
                ([string]$DossierValidation.candidate_symbol)
        }
        "otwin-product-reanchor-evidence" {
            return Test-ProductReanchorPromotionResult `
                $File $Identity $Source $CheckpointId $BoundaryRun `
                ([string]$DossierValidation.candidate_symbol) `
                ([string]$DossierValidation.candidate_object) `
                $CurrentMetricsSummary $CheckpointCandidateMapPath `
                $CheckpointVerifierResultsPath
        }
        default {
            throw "Unsupported promotion focused-result artifact_type '$ArtifactType'."
        }
    }
}

function Read-PromotionEvidence {
    param(
        [string]$EvidencePath,
        [string]$RequiredCheckpointId,
        $RequiredBoundaryRun,
        [string[]]$RequiredIdentities,
        $CurrentMetricsSummary,
        [string]$CheckpointCandidateMapPath,
        [string]$CheckpointVerifierResultsPath
    )

    $RequiredBoundaryRunId = [string]$RequiredBoundaryRun.run_id
    if ([string]::IsNullOrWhiteSpace($RequiredBoundaryRunId)) {
        throw "Promotion evidence requires a concrete prior boundary run."
    }

    $documentFile = Get-SafePromotionEvidenceFile `
        $EvidencePath "document"
    try {
        $document = Get-Content -LiteralPath $documentFile.absolute_path -Raw |
            ConvertFrom-Json
    }
    catch {
        throw "Promotion evidence JSON could not be parsed: $($_.Exception.Message)"
    }
    Assert-JsonObjectShape $document @(
        "schema_version",
        "checkpoint_id",
        "prior_boundary_run_id",
        "promotions") "Promotion evidence document"
    if ([int]$document.schema_version -ne 1) {
        throw "Unsupported promotion evidence schema; expected schema_version 1."
    }
    if ([string]$document.checkpoint_id -cne $RequiredCheckpointId) {
        throw ("Promotion evidence checkpoint_id '{0}' does not match '{1}'." -f
            $document.checkpoint_id, $RequiredCheckpointId)
    }
    if ([string]$document.prior_boundary_run_id -cne $RequiredBoundaryRunId) {
        throw ("Promotion evidence prior_boundary_run_id '{0}' does not match " +
            "the prior passed ancestral boundary '{1}'.") -f
            $document.prior_boundary_run_id, $RequiredBoundaryRunId
    }

    $requiredEntryProperties = @(
        "identity",
        "dossier_path", "dossier_sha256",
        "source_path", "source_sha256",
        "focused_result_path", "focused_result_sha256",
        "semantic_review_passed", "type_review_passed",
        "abi_review_passed", "mask_review_passed")
    $identitySet = New-Object 'System.Collections.Generic.HashSet[string]' `
        ([System.StringComparer]::Ordinal)
    $caseFoldedIdentitySet = New-Object 'System.Collections.Generic.HashSet[string]' `
        ([System.StringComparer]::OrdinalIgnoreCase)
    $entries = @($document.promotions)
    foreach ($entry in $entries) {
        Assert-JsonObjectShape $entry $requiredEntryProperties `
            "Promotion evidence entry"
        $identity = [string]$entry.identity
        Assert-CanonicalPromotionIdentity $identity "Promotion evidence identity"
        if (-not $identitySet.Add($identity)) {
            throw "Promotion evidence contains duplicate identity '$identity'."
        }
        if (-not $caseFoldedIdentitySet.Add($identity)) {
            throw "Promotion evidence contains an ambiguous identity '$identity'."
        }

        foreach ($reviewName in @(
                "semantic_review_passed",
                "type_review_passed",
                "abi_review_passed",
                "mask_review_passed")) {
            $reviewValue = $entry.PSObject.Properties[$reviewName].Value
            if (-not ($reviewValue -is [bool]) -or -not [bool]$reviewValue) {
                throw "Promotion evidence '$identity' requires $reviewName=true."
            }
        }
    }

    [string[]]$reportedIdentities = @($identitySet)
    [Array]::Sort($reportedIdentities, [System.StringComparer]::Ordinal)
    [string[]]$expectedIdentities = @($RequiredIdentities)
    [Array]::Sort($expectedIdentities, [System.StringComparer]::Ordinal)
    if (($reportedIdentities -join "`n") -cne
        ($expectedIdentities -join "`n")) {
        $missing = @($expectedIdentities | Where-Object {
            -not ($reportedIdentities -ccontains $_)
        })
        $extra = @($reportedIdentities | Where-Object {
            -not ($expectedIdentities -ccontains $_)
        })
        throw ("Promotion evidence identity set is not exact (missing: {0}; extra: {1})." -f
            $(if ($missing.Count -eq 0) { "none" } else { $missing -join ", " }),
            $(if ($extra.Count -eq 0) { "none" } else { $extra -join ", " }))
    }

    $preparedEntries = @()
    foreach ($entry in $entries) {
        $identity = [string]$entry.identity
        $dossier = Get-SafePromotionEvidenceFile `
            ([string]$entry.dossier_path) "dossier" `
            ([string]$entry.dossier_sha256)
        $source = Get-SafePromotionEvidenceFile `
            ([string]$entry.source_path) "source" `
            ([string]$entry.source_sha256)
        $focusedResult = Get-SafePromotionEvidenceFile `
            ([string]$entry.focused_result_path) "focused result" `
            ([string]$entry.focused_result_sha256)
        if (@($dossier.path, $source.path, $focusedResult.path |
                Select-Object -Unique).Count -ne 3) {
            throw "Promotion evidence '$identity' must bind three distinct evidence files."
        }
        if (@($dossier.path, $source.path, $focusedResult.path) -ccontains
            [string]$documentFile.path) {
            throw "Promotion evidence '$identity' cannot use its JSON document as a bound evidence file."
        }

        $preparedEntries += [pscustomobject][ordered]@{
            entry = $entry
            identity = $identity
            dossier = $dossier
            source = $source
            focused_result = $focusedResult
            focused_artifact_type = Get-PromotionFocusedArtifactType `
                $focusedResult
        }
    }

    [string[]]$focusedArtifactTypes = @($preparedEntries |
        ForEach-Object { [string]$_.focused_artifact_type })
    Assert-PromotionFocusedArtifactComposition $focusedArtifactTypes

    $dossierOwners = @{}
    $focusedResultOwners = @{}
    $bindings = @()
    foreach ($prepared in $preparedEntries) {
        $entry = $prepared.entry
        $identity = [string]$prepared.identity
        $dossier = $prepared.dossier
        $source = $prepared.source
        $focusedResult = $prepared.focused_result

        $dossierKey = $dossier.path.ToLowerInvariant()
        if ($dossierOwners.ContainsKey($dossierKey)) {
            throw ("Promotion dossier '{0}' is reused across identities '{1}' " +
                "and '{2}'; schema-1 dossiers bind exactly one identity.") -f
                $dossier.path, $dossierOwners[$dossierKey], $identity
        }
        $dossierOwners[$dossierKey] = $identity
        $focusedResultKey = $focusedResult.path.ToLowerInvariant()
        if ($focusedResultOwners.ContainsKey($focusedResultKey)) {
            throw ("Focused source-shape artifact '{0}' is reused across " +
                "identities '{1}' and '{2}'; schema-1 focused artifacts bind " +
                "exactly one identity.") -f
                $focusedResult.path,
                $focusedResultOwners[$focusedResultKey], $identity
        }
        $focusedResultOwners[$focusedResultKey] = $identity

        $dossierValidation = Test-PromotionDossier `
            $dossier $identity $source
        $focusedValidation = Test-PromotionFocusedResult `
            $focusedResult ([string]$prepared.focused_artifact_type) `
            $identity $source $RequiredCheckpointId `
            $RequiredBoundaryRun $dossierValidation $CurrentMetricsSummary `
            $CheckpointCandidateMapPath $CheckpointVerifierResultsPath

        $bindings += [pscustomobject][ordered]@{
            identity = $identity
            dossier = $dossier
            dossier_validation = $dossierValidation
            source = $source
            focused_result = $focusedResult
            focused_artifact_type = [string]$prepared.focused_artifact_type
            focused_result_validation = $focusedValidation
            semantic_review_passed = $true
            type_review_passed = $true
            abi_review_passed = $true
            mask_review_passed = $true
        }
    }

    return [pscustomobject][ordered]@{
        supplied = $true
        repository_relative_path = $documentFile.path
        absolute_path = $documentFile.absolute_path
        sha256 = $documentFile.sha256
        schema_version = 1
        checkpoint_id = $RequiredCheckpointId
        prior_boundary_run_id = $RequiredBoundaryRunId
        identity_count = [uint64]$reportedIdentities.Count
        identity_sha256 = Get-TextSha256Hex $reportedIdentities
        identities = @($reportedIdentities)
        bindings = @($bindings)
        validated = $true
        status = "passed"
        error = ""
        end_verified = $false
        end_error = ""
    }
}

function Invoke-PromotionDeltaEvidenceCheck {
    param(
        $CurrentSummary,
        $BoundaryRun,
        [long]$RequiredInstructionGain,
        [string]$EvidencePath,
        [string]$RequiredCheckpointId,
        $Run,
        [string]$CheckpointCandidateMapPath,
        [string]$CheckpointVerifierResultsPath
    )

    try {
        if ($null -eq $BoundaryRun -or $null -eq $BoundaryRun.metrics_summary) {
            throw "No prior passed ancestral metrics boundary is available for promotion validation."
        }
        $beforeInstructions =
            [uint64]$BoundaryRun.metrics_summary.strict.accepted_instructions
        $afterInstructions = [uint64]$CurrentSummary.strict.accepted_instructions
        if ($afterInstructions -lt $beforeInstructions) {
            throw "Strict accepted instructions regressed before promotion delta validation."
        }
        $instructionGain = [uint64]($afterInstructions - $beforeInstructions)

        $boundaryIdentities = New-Object `
            'System.Collections.Generic.HashSet[string]' `
            ([System.StringComparer]::Ordinal)
        foreach ($identityValue in @(
                $BoundaryRun.metrics_summary.strict.accepted_identities)) {
            $identity = [string]$identityValue
            Assert-CanonicalPromotionIdentity $identity `
                "Prior boundary accepted identity"
            [void]$boundaryIdentities.Add($identity)
        }
        $newIdentities = @()
        foreach ($identityValue in @($CurrentSummary.strict.accepted_identities)) {
            $identity = [string]$identityValue
            Assert-CanonicalPromotionIdentity $identity `
                "Current accepted identity"
            if (-not $boundaryIdentities.Contains($identity)) {
                $newIdentities += $identity
            }
        }
        [string[]]$newIdentityArray = @($newIdentities)
        [Array]::Sort($newIdentityArray, [System.StringComparer]::Ordinal)

        $Run.promotion_delta.prior_boundary_run_id = [string]$BoundaryRun.run_id
        $Run.promotion_delta.prior_boundary_checkpoint_id =
            [string]$BoundaryRun.checkpoint_id
        $Run.promotion_delta.accepted_instructions_before = $beforeInstructions
        $Run.promotion_delta.accepted_instructions_after = $afterInstructions
        $Run.promotion_delta.accepted_instruction_gain = $instructionGain
        $Run.promotion_delta.new_identity_count =
            [uint64]$newIdentityArray.Count
        $Run.promotion_delta.new_identity_sha256 =
            Get-TextSha256Hex $newIdentityArray
        $Run.promotion_delta.new_identities = @($newIdentityArray)

        if ($newIdentityArray.Count -eq 0 -and $instructionGain -ne 0) {
            throw ("Metrics summary is inconsistent: accepted instructions gained " +
                "{0}, but no newly accepted identity exists relative to the prior " +
                "passed ancestral boundary.") -f $instructionGain
        }

        if ($instructionGain -lt [uint64]$RequiredInstructionGain) {
            throw ("Accepted-instruction gain {0} is below required minimum {1} " +
                "relative to prior passed ancestral checkpoint '{2}'.") -f
                $instructionGain, $RequiredInstructionGain,
                $BoundaryRun.checkpoint_id
        }

        if ($newIdentityArray.Count -ne 0 -and
            [string]::IsNullOrWhiteSpace($EvidencePath)) {
            throw ("Promotion evidence is required for {0} newly accepted " +
                "identity/identities.") -f $newIdentityArray.Count
        }

        if (-not [string]::IsNullOrWhiteSpace($EvidencePath)) {
            $evidenceDocument = Get-SafePromotionEvidenceFile `
                $EvidencePath "document"
            $Run.promotion_evidence.repository_relative_path =
                $evidenceDocument.path
            $Run.promotion_evidence.absolute_path =
                $evidenceDocument.absolute_path
            $Run.promotion_evidence.sha256 = $evidenceDocument.sha256
            $Run.promotion_evidence.status = "validating"
            $Run.promotion_evidence = Read-PromotionEvidence `
                $EvidencePath $RequiredCheckpointId `
                $BoundaryRun $newIdentityArray $CurrentSummary `
                $CheckpointCandidateMapPath $CheckpointVerifierResultsPath
        }
        else {
            $Run.promotion_evidence.status = "not-required"
        }
        $Run.promotion_delta.status = "passed"
        $Run.promotion_delta.error = ""

        $lines = @(
            ("Prior passed ancestral boundary: {0} ({1})" -f
                $BoundaryRun.checkpoint_id, $BoundaryRun.run_id),
            ("Accepted-instruction gain: {0} (required: {1})" -f
                $instructionGain, $RequiredInstructionGain),
            ("New accepted identities: {0} (sha256: {1})" -f
                $newIdentityArray.Count,
                $Run.promotion_delta.new_identity_sha256))
        if ([bool]$Run.promotion_evidence.validated) {
            $lines += ("Promotion evidence validated: {0} ({1})" -f
                $Run.promotion_evidence.repository_relative_path,
                $Run.promotion_evidence.sha256)
        }
        else {
            $lines += "Promotion evidence: not required (no new accepted identities)."
        }
        return $lines
    }
    catch {
        $Run.promotion_delta.status = "failed"
        $Run.promotion_delta.error = $_.Exception.Message
        if (-not [bool]$Run.promotion_evidence.validated) {
            $Run.promotion_evidence.status = "failed"
            $Run.promotion_evidence.error = $_.Exception.Message
        }
        throw
    }
}

function Assert-PromotionEvidenceEndBoundary {
    param($Evidence)

    if ($null -eq $Evidence -or -not [bool]$Evidence.validated) {
        return
    }
    try {
        [void](Get-SafePromotionEvidenceFile `
            ([string]$Evidence.repository_relative_path) "document" `
            ([string]$Evidence.sha256))
        foreach ($binding in @($Evidence.bindings)) {
            [void](Get-SafePromotionEvidenceFile `
                ([string]$binding.dossier.path) "dossier" `
                ([string]$binding.dossier.sha256))
            [void](Get-SafePromotionEvidenceFile `
                ([string]$binding.source.path) "source" `
                ([string]$binding.source.sha256))
            [void](Get-SafePromotionEvidenceFile `
                ([string]$binding.focused_result.path) "focused result" `
                ([string]$binding.focused_result.sha256))
            foreach ($provenance in @(
                    $binding.dossier_validation.provenance_files)) {
                [void](Get-SafePromotionProvenanceFile `
                    ([string]$provenance.path) `
                    ([string]$provenance.sha256) `
                    ([long]$provenance.length) `
                    ([string]$provenance.role))
            }
            $focusedValidation = $binding.focused_result_validation
            $evidenceModeProperty = if ($null -eq $focusedValidation) {
                $null
            }
            else {
                $focusedValidation.PSObject.Properties["evidence_mode"]
            }
            if ($null -ne $evidenceModeProperty -and
                [string]$evidenceModeProperty.Value -ceq "product-reanchor") {
                $manifestRecord = [pscustomobject][ordered]@{
                    path = [string]$focusedValidation.manifest_file.path
                    sha256 = [string]$focusedValidation.manifest_file.sha256
                    length = [long]$focusedValidation.manifest_file.length
                }
                [void](Get-SafeProductReanchorFile `
                    $manifestRecord "current manifest" @(".csv"))
                foreach ($provenance in @(
                        $focusedValidation.provenance_files)) {
                    $record = [pscustomobject][ordered]@{
                        path = [string]$provenance.path
                        sha256 = [string]$provenance.sha256
                        length = [long]$provenance.length
                    }
                    $extension = [System.IO.Path]::GetExtension(
                        [string]$provenance.path).ToLowerInvariant()
                    [void](Get-SafeProductReanchorFile `
                        $record ([string]$provenance.role) @($extension) `
                        -RequireIgnoredOutput)
                }
                foreach ($provenance in @(
                        $focusedValidation.checkpoint_provenance_files)) {
                    $record = [pscustomobject][ordered]@{
                        path = [string]$provenance.path
                        sha256 = [string]$provenance.sha256
                        length = [long]$provenance.length
                    }
                    $extension = [System.IO.Path]::GetExtension(
                        [string]$provenance.path).ToLowerInvariant()
                    [void](Get-SafeProductReanchorFile `
                        $record ([string]$provenance.role) @($extension) `
                        -RequireIgnoredOutput)
                }
                $candidateMaps = @(
                    $focusedValidation.provenance_files | Where-Object {
                        [string]$_.role -ceq "candidate map"
                    })
                if ($candidateMaps.Count -ne 1) {
                    throw ("Product reanchor end boundary lacks exactly one " +
                        "candidate-map containment input.")
                }
                $endContainment = Get-ProductReanchorSymbolContainment `
                    ([string]$candidateMaps[0].absolute_path) `
                    ([string]$focusedValidation.candidate_symbol) `
                    ([string]$focusedValidation.candidate_object) `
                    (ConvertFrom-ReanchorNumber `
                        ([string]$focusedValidation.symbol_containment.target_rva) `
                        "end-boundary containment target_rva") `
                    ([uint64]$focusedValidation.symbol_containment.target_size)
                Assert-ProductReanchorSymbolContainment `
                    $focusedValidation.symbol_containment $endContainment
                $checkpointMaps = @(
                    $focusedValidation.checkpoint_provenance_files |
                        Where-Object {
                            [string]$_.role -ceq "checkpoint candidate map"
                        })
                $checkpointVerifierFiles = @(
                    $focusedValidation.checkpoint_provenance_files |
                        Where-Object {
                            [string]$_.role -ceq
                                "checkpoint verifier results"
                        })
                if ($checkpointMaps.Count -ne 1 -or
                    $checkpointVerifierFiles.Count -ne 1) {
                    throw ("Product reanchor end boundary lacks its exact " +
                        "checkpoint map/result containment inputs.")
                }
                $endCheckpointContainment =
                    Get-ProductReanchorSymbolContainment `
                        ([string]$checkpointMaps[0].absolute_path) `
                        ([string]$focusedValidation.candidate_symbol) `
                        ([string]$focusedValidation.candidate_object) `
                        (ConvertFrom-ReanchorNumber `
                            ([string]$focusedValidation.
                                checkpoint_symbol_containment.target_rva) `
                            "end-boundary checkpoint containment target_rva") `
                        ([uint64]$focusedValidation.
                            checkpoint_symbol_containment.target_size)
                Assert-ProductReanchorSymbolContainment `
                    $focusedValidation.checkpoint_symbol_containment `
                    $endCheckpointContainment
            }
        }
        $Evidence.end_verified = $true
        $Evidence.end_error = ""
    }
    catch {
        $Evidence.end_verified = $false
        $Evidence.end_error = $_.Exception.Message
        throw ("Promotion evidence changed or escaped its repository boundary " +
            "during execution: {0}") -f $_.Exception.Message
    }
}

function Test-OriginalAssetPath {
    param([string]$Path)

    $normalized = $Path.Replace('\', '/')
    if ($normalized -match '^(Sample|a|artifacts|build)/') {
        return $true
    }
    if ($normalized -match '^resources/otwin32/' -and
        $normalized -cne 'resources/otwin32/README.md') {
        return $true
    }
    return ($normalized -match '(?i)\.(exe|dll|bmp|dib|wav|mid|midi|avi|res|obj|lib|pdb|ico|png|jpe?g|gif|cur|ani|ttf|otf)$')
}

function Test-TextAuditPath {
    param([string]$Path)

    $fileName = [System.IO.Path]::GetFileName($Path)
    if ($fileName -in @(".gitignore", ".gitattributes", ".editorconfig")) {
        return $true
    }
    $extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    return $extension -in @(
        ".c", ".cc", ".cpp", ".cxx", ".h", ".hpp", ".inl",
        ".cs", ".csproj", ".sln", ".slnx", ".ps1", ".psd1", ".psm1",
        ".md", ".txt", ".csv", ".json", ".xml", ".yml", ".yaml",
        ".cmake", ".rc", ".rc2", ".def", ".ini", ".props", ".targets")
}

function Find-UntrackedConflictMarkers {
    param([string[]]$Paths)

    $findings = New-Object System.Collections.ArrayList
    foreach ($path in $Paths) {
        if (-not (Test-TextAuditPath $path)) {
            continue
        }
        $absolutePath = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $path))
        if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
            continue
        }

        $reader = [System.IO.File]::OpenText($absolutePath)
        try {
            $lineNumber = 0
            while ($null -ne ($line = $reader.ReadLine())) {
                $lineNumber++
                if ($line -match '^(<<<<<<<|=======|>>>>>>>)(?: |$)') {
                    [void]$findings.Add("untracked-conflict:${path}:$lineNumber")
                }
            }
        }
        finally {
            $reader.Dispose()
        }
    }
    return @($findings)
}

function Invoke-RepositoryBoundaryCheck {
    $findings = New-Object System.Collections.ArrayList

    foreach ($path in @(Invoke-GitCapture @("ls-files"))) {
        if (Test-OriginalAssetPath $path) {
            [void]$findings.Add("tracked:$path")
        }
    }

    $untrackedPaths = @(
        Invoke-GitCapture @("ls-files", "--others", "--exclude-standard"))
    foreach ($path in $untrackedPaths) {
        if (Test-OriginalAssetPath $path) {
            [void]$findings.Add("untracked:$path")
        }
    }

    foreach ($record in @(Invoke-GitCapture @("rev-list", "--objects", "--all"))) {
        $separator = $record.IndexOf(' ')
        if ($separator -lt 0) {
            continue
        }
        $path = $record.Substring($separator + 1)
        if (Test-OriginalAssetPath $path) {
            [void]$findings.Add("history:$path")
        }
    }

    $unmerged = @(Invoke-GitCapture @("ls-files", "-u"))
    if ($unmerged.Count -ne 0) {
        [void]$findings.Add("unmerged Git index entries: $($unmerged.Count)")
    }

    $stagedPaths = @(
        Invoke-GitCapture @(
            "diff", "--cached", "--name-only", "--diff-filter=ACMR"))
    foreach ($path in $stagedPaths) {
        if (Test-OriginalAssetPath $path) {
            [void]$findings.Add("staged-forbidden:$path")
        }
    }

    $conflictPattern = '^(<<<<<<<|=======|>>>>>>>)( |$)'
    foreach ($line in @(Invoke-GitSearchCapture @(
            "grep", "-n", "-I", "-E", $conflictPattern, "--", "."))) {
        [void]$findings.Add("worktree-conflict:$line")
    }
    foreach ($line in @(Invoke-GitSearchCapture @(
            "grep", "--cached", "-n", "-I", "-E", $conflictPattern, "--", "."))) {
        [void]$findings.Add("index-conflict:$line")
    }
    foreach ($line in @(Find-UntrackedConflictMarkers $untrackedPaths)) {
        [void]$findings.Add($line)
    }

    if ($findings.Count -ne 0) {
        throw "Repository boundary check failed: $($findings -join '; ')"
    }

    return @(
        "No tracked, pending, or reachable-history path crossed the original-asset boundary.",
        "No unmerged Git index entries or staged forbidden paths were found.",
        "No conflict markers were found in tracked, staged, or untracked text."
    )
}

function Invoke-InternalStep {
    param(
        $Step,
        [string]$LogPath
    )

    switch ($Step.name) {
        "repository-boundary" {
            $lines = @(Invoke-RepositoryBoundaryCheck)
        }
        "promotion-delta-evidence" {
            $lines = @(Invoke-PromotionDeltaEvidenceCheck `
                $run.metrics_summary $priorBoundaryRun `
                $MinimumInstructionGain $promotionEvidenceRelative `
                $CheckpointId $run $candidateMap $matchResults)
        }
        default {
            throw "Unknown internal recovery-wave step '$($Step.name)'."
        }
    }

    foreach ($line in $lines) {
        Write-Host $line
    }
    $lines | Set-Content -LiteralPath $LogPath -Encoding UTF8
    return [pscustomobject]@{
        ExitCode = 0
        Lines = @($lines)
    }
}

if ($SessionId -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
    throw "SessionId must contain only letters, digits, dot, underscore, or hyphen and may not begin with punctuation."
}

$promotionEvidenceRelative = ""
$promotionEvidenceAbsolute = ""
if (-not [string]::IsNullOrWhiteSpace($PromotionEvidencePath)) {
    if ([System.IO.Path]::IsPathRooted($PromotionEvidencePath)) {
        throw "PromotionEvidencePath must be repository-relative: '$PromotionEvidencePath'."
    }
    $evidenceSegments = @(
        $PromotionEvidencePath.Replace('\', '/').Split('/') |
            Where-Object { $_ -ne "" })
    if ($evidenceSegments.Count -eq 0 -or
        @($evidenceSegments | Where-Object {
            $_ -eq "." -or $_ -eq ".."
        }).Count -ne 0) {
        throw "PromotionEvidencePath is not canonical: '$PromotionEvidencePath'."
    }
    $promotionEvidenceAbsolute = Get-ContainedRepoPath `
        $PromotionEvidencePath "PromotionEvidencePath"
    $repoPrefix = $repoRoot.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    $promotionEvidenceRelative =
        $promotionEvidenceAbsolute.Substring($repoPrefix.Length).Replace('\', '/')
    if ([System.IO.Path]::GetExtension(
            $promotionEvidenceRelative).ToLowerInvariant() -cne ".json") {
        throw "PromotionEvidencePath must name a JSON file: '$PromotionEvidencePath'."
    }
    $promotionEvidenceLower = $promotionEvidenceRelative.ToLowerInvariant()
    if ($promotionEvidenceLower -match '^(sample|originals|vc4|build)/' -or
        ($promotionEvidenceLower -match '^resources/otwin32/' -and
            $promotionEvidenceLower -cne 'resources/otwin32/readme.md')) {
        throw ("PromotionEvidencePath points into an original/generated payload " +
            "tree: '$promotionEvidenceRelative'.")
    }
}

$outputRootAbsolute = Get-ContainedRepoPath $OutputRoot "OutputRoot"
Assert-ConventionalOutputRoot $outputRootAbsolute
$sessionRootRelative = Join-Path $OutputRoot $SessionId
$sessionRootAbsolute = Get-ContainedRepoPath $sessionRootRelative "Session output"
$checkpointsRootRelative = Join-Path $sessionRootRelative "checkpoints"
$checkpointsRootAbsolute = Get-ContainedRepoPath $checkpointsRootRelative "Checkpoints output"
$checkpointRootRelative = Join-Path $checkpointsRootRelative $CheckpointId
$checkpointRootAbsolute = Get-ContainedRepoPath $checkpointRootRelative "Checkpoint output"
$candidateDirectoryRelative = Join-Path $checkpointRootRelative "vc40"
$candidateDirectoryAbsolute = Get-ContainedRepoPath $candidateDirectoryRelative "Candidate output"
$productDirectoryRelative = Join-Path $checkpointRootRelative "vc4-products"
$productDirectoryAbsolute = Get-ContainedRepoPath $productDirectoryRelative "Product output"
$ledgerPath = Join-Path $sessionRootAbsolute "session-ledger.json"
$sessionLockPath = Join-Path `
    (Join-Path $outputRootAbsolute ".session-locks") `
    ($SessionId + ".lock")
foreach ($safeOutputDirectory in @(
        $checkpointsRootAbsolute,
        $checkpointRootAbsolute,
        $candidateDirectoryAbsolute,
        $productDirectoryAbsolute,
        (Split-Path -Parent $sessionLockPath))) {
    Assert-ConventionalOutputRoot $safeOutputDirectory -SkipGitIgnore
}
Assert-ConventionalOutputRoot $sessionRootAbsolute

$candidateDll = Join-Path $candidateDirectoryRelative "otwin-match-candidates.dll"
$candidateMap = Join-Path $candidateDirectoryRelative "otwin-match-candidates.map"
$candidateLcmtDll = Join-Path $candidateDirectoryRelative "otwin-match-candidates-lcmt.dll"
$candidateLcmtMap = Join-Path $candidateDirectoryRelative "otwin-match-candidates-lcmt.map"
$candidateDllcrtDll = Join-Path $candidateDirectoryRelative "otwin-match-candidates-dllcrt.dll"
$candidateDllcrtMap = Join-Path $candidateDirectoryRelative "otwin-match-candidates-dllcrt.map"
$matchResults = Join-Path $candidateDirectoryRelative "function-match-results.csv"
$maskResults = Join-Path $candidateDirectoryRelative "mask-audit.csv"
$metricsSummary = Join-Path $candidateDirectoryRelative "progress-metrics-summary.json"
$metricsSummaryAbsolute = Get-ContainedRepoPath $metricsSummary "Metrics summary output"
$sourceAuditResults = Join-Path $productDirectoryRelative "product-source-audit.json"
$productExe = Join-Path $productDirectoryRelative "Oregon32-EXE-product-wip.exe"
$productDll = Join-Path $productDirectoryRelative "OREGON32-DLL-product-wip.dll"

$buildCandidateScript = Join-Path $PSScriptRoot "build-match-candidates.ps1"
$matcherScript = Join-Path $PSScriptRoot "match-functions.ps1"
$maskAuditScript = Join-Path $PSScriptRoot "audit-function-masks.ps1"
$metricsScript = Join-Path $PSScriptRoot "report-progress-metrics.ps1"
$sourceAuditScript = Join-Path $PSScriptRoot "audit-vc4-product-sources.ps1"
$productBuildScript = Join-Path $PSScriptRoot "build-vc4-products.ps1"
$peCompareScript = Join-Path $PSScriptRoot "compare-pe-images.ps1"
$verifierContractScript = Join-Path $PSScriptRoot "test-verification-contract.ps1"
$metricsContractScript = Join-Path $PSScriptRoot "test-progress-metrics-contract.ps1"
$buildCacheContractScript = Join-Path $PSScriptRoot "test-build-cache-contract.ps1"
$wipQueueContractScript = Join-Path $PSScriptRoot "test-wip-queue-contract.ps1"
$recoveryWaveContractScript = Join-Path $PSScriptRoot "test-recovery-wave-contract.ps1"
$dossierGeneratorScript = Join-Path $PSScriptRoot "generate-function-dossier.ps1"
$dossierContractScript = Join-Path $PSScriptRoot "test-function-dossier-contract.ps1"
$sourceShapeRunnerScript = Join-Path $PSScriptRoot `
    "invoke-source-shape-variants.ps1"
$productReanchorGeneratorScript = Join-Path $PSScriptRoot `
    "invoke-product-reanchor-evidence.ps1"
$productReanchorContractScript = Join-Path $PSScriptRoot `
    "test-product-reanchor-evidence-contract.ps1"
$gateToolPaths = [ordered]@{
    orchestrator = $PSCommandPath
    build_candidates = $buildCandidateScript
    matcher = $matcherScript
    mask_audit = $maskAuditScript
    metrics_reporter = $metricsScript
    product_source_audit = $sourceAuditScript
    product_builder = $productBuildScript
    pe_compare = $peCompareScript
    verifier_contract = $verifierContractScript
    metrics_contract = $metricsContractScript
    build_cache_contract = $buildCacheContractScript
    wip_queue_contract = $wipQueueContractScript
    recovery_wave_contract = $recoveryWaveContractScript
    dossier_generator = $dossierGeneratorScript
    dossier_contract = $dossierContractScript
    source_shape_runner = $sourceShapeRunnerScript
    product_reanchor_generator = $productReanchorGeneratorScript
    product_reanchor_contract = $productReanchorContractScript
}

$steps = New-Object System.Collections.ArrayList

$buildCandidateArguments = @(
    "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $buildCandidateScript,
    "-Toolchain", "LegacyMsvc", "-VcToolsRoot", $VcToolsRoot,
    "-OutputDirectory", $candidateDirectoryRelative,
    "-DefaultOptimization", "/Od", "-SemanticOptimization", "/O1")
if ($Phase -eq "baseline" -or $Phase -eq "final") {
    $buildCandidateArguments += "-Rebuild"
}
[void]$steps.Add((New-ProcessStep "build-candidates" "candidate" `
    $PowerShellExecutable $buildCandidateArguments))

[void]$steps.Add((New-ProcessStep "match-functions" "verification" $PowerShellExecutable @(
    "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $matcherScript,
    "-ManifestPath", $ManifestPath,
    "-OriginalPath", $OriginalExePath, "-OriginalDllPath", $OriginalDllPath,
    "-CandidatePath", $candidateDll, "-CandidateMapPath", $candidateMap,
    "-CandidateLcmtPath", $candidateLcmtDll,
    "-CandidateLcmtMapPath", $candidateLcmtMap,
    "-CandidateDllcrtPath", $candidateDllcrtDll,
    "-CandidateDllcrtMapPath", $candidateDllcrtMap,
    "-ResultsCsvPath", $matchResults, "-SummaryOnly")))

[void]$steps.Add((New-ProcessStep "audit-function-masks" "verification" $PowerShellExecutable @(
    "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $maskAuditScript,
    "-ManifestPath", $ManifestPath,
    "-OriginalPath", $OriginalExePath, "-OriginalDllPath", $OriginalDllPath,
    "-ResultsCsvPath", $maskResults, "-RequireValidated")))

[void]$steps.Add((New-ProcessStep "audit-product-sources" "product" $PowerShellExecutable @(
    "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $sourceAuditScript,
    "-ResultsJsonPath", $sourceAuditResults, "-SummaryOnly")))

$metricsArguments = @(
    "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $metricsScript,
    "-ManifestPath", $ManifestPath,
    "-VerifierResultsPath", $matchResults,
    "-MaskAuditResultsPath", $maskResults,
    "-RequireProductReachability",
    "-SummaryJsonPath", $metricsSummary)
if ($MinimumInstructionPercent -gt 0.0) {
    $metricsArguments += @(
        "-RequireInstructionPercent",
        $MinimumInstructionPercent.ToString(
            "0.################",
            [System.Globalization.CultureInfo]::InvariantCulture))
}
[void]$steps.Add((New-ProcessStep "report-progress-metrics" "verification" `
    $PowerShellExecutable $metricsArguments))

if ($Phase -eq "promotion-wave" -or $Phase -eq "final") {
    [void]$steps.Add((New-InternalStep `
        "promotion-delta-evidence" "promotion-evidence" `
        "internal: enforce instruction gain and exact reviewed promotion evidence"))
}

[void]$steps.Add((New-ProcessStep "build-product-exe" "product" $PowerShellExecutable @(
    "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $productBuildScript,
    "-Target", "Oregon32Exe", "-ExeGraph", "Product",
    "-VcToolsRoot", $VcToolsRoot,
    "-OutputDirectory", $productDirectoryRelative,
    "-CandidateObjectDirectory", $candidateDirectoryRelative,
    "-ResourceRoot", $ResourceRoot)))

[void]$steps.Add((New-ProcessStep "build-product-dll" "product" $PowerShellExecutable @(
    "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $productBuildScript,
    "-Target", "Oregon32Dll", "-VcToolsRoot", $VcToolsRoot,
    "-OutputDirectory", $productDirectoryRelative,
    "-ResourceRoot", $ResourceRoot)))

if ($Phase -eq "final") {
    [void]$steps.Add((New-ProcessStep "compare-product-exe" "pe-comparison" $PowerShellExecutable @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $peCompareScript,
        "-OriginalPath", $OriginalExePath, "-CandidatePath", $productExe,
        "-ResultsJsonPath", (Join-Path $productDirectoryRelative "oregon32-exe-pe.json"),
        "-ResultsCsvPath", (Join-Path $productDirectoryRelative "oregon32-exe-pe.csv"))))

    [void]$steps.Add((New-ProcessStep "compare-product-dll" "pe-comparison" $PowerShellExecutable @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $peCompareScript,
        "-OriginalPath", $OriginalDllPath, "-CandidatePath", $productDll,
        "-ResultsJsonPath", (Join-Path $productDirectoryRelative "oregon32-dll-pe.json"),
        "-ResultsCsvPath", (Join-Path $productDirectoryRelative "oregon32-dll-pe.csv"))))

    [void]$steps.Add((New-ProcessStep "test-verifier-contract" "repository-test" $PowerShellExecutable @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $verifierContractScript)))
    [void]$steps.Add((New-ProcessStep "test-metrics-contract" "repository-test" $PowerShellExecutable @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $metricsContractScript)))
    [void]$steps.Add((New-ProcessStep "test-build-cache-contract" "repository-test" $PowerShellExecutable @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $buildCacheContractScript)))
    [void]$steps.Add((New-ProcessStep "test-wip-queue-contract" "repository-test" $PowerShellExecutable @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $wipQueueContractScript)))
    [void]$steps.Add((New-ProcessStep "test-recovery-wave-contract" "repository-test" $PowerShellExecutable @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $recoveryWaveContractScript)))
    [void]$steps.Add((New-ProcessStep "test-function-dossier-contract" "repository-test" $PowerShellExecutable @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $dossierContractScript)))
    [void]$steps.Add((New-ProcessStep `
        "test-product-reanchor-evidence-contract" "repository-test" `
        $PowerShellExecutable @(
            "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
            $productReanchorContractScript)))
    [void]$steps.Add((New-ProcessStep "cmake-build" "repository-test" "cmake" @(
        "--build", $BuildDirectory)))
    [void]$steps.Add((New-ProcessStep "ctest" "repository-test" "ctest" @(
        "--test-dir", $BuildDirectory, "--output-on-failure")))
    [void]$steps.Add((New-ProcessStep "viewer-tests" "repository-test" "dotnet" @(
        "test", $ViewerSolution)))
}

if ($Phase -eq "promotion-wave" -or $Phase -eq "final") {
    [void]$steps.Add((New-ProcessStep "git-diff-head-check" "worktree" "git" @(
        "diff", "HEAD", "--check")))
    [void]$steps.Add((New-InternalStep "repository-boundary" "asset" "internal: audit asset paths, staged paths, conflict markers, and unmerged entries"))
    [void]$steps.Add((New-ProcessStep "git-status-informational" "worktree-information" "git" @(
        "status", "--short", "--branch")))
}

$sessionLock = Enter-SessionLock `
    $sessionLockPath $SessionLockTimeoutMilliseconds
try {
if (Test-Path -LiteralPath $ledgerPath -PathType Leaf) {
    $ledger = Get-Content -LiteralPath $ledgerPath -Raw | ConvertFrom-Json
    if ([int]$ledger.schema_version -ne 4) {
        throw ("Unsupported recovery-wave ledger schema in '{0}': found {1}, " +
            "expected 4. Start a new SessionId with a clean executed baseline; " +
            "older ledgers are intentionally not migrated.") -f
            $ledgerPath, $ledger.schema_version
    }
    if ([string]$ledger.session_id -cne $SessionId) {
        throw "Recovery-wave ledger session mismatch in '$ledgerPath'."
    }
    if ([string]$ledger.output_root -cne $outputRootAbsolute -or
        [string]$ledger.session_root -cne $sessionRootAbsolute) {
        throw "Recovery-wave ledger output paths do not match this invocation."
    }
    $priorRuns = @($ledger.runs)
}
else {
    $priorRuns = @()
    $ledger = [pscustomobject][ordered]@{
        schema_version = 4
        session_id = $SessionId
        execution_requires_explicit_switch = $true
        repo_root = $repoRoot
        output_root = $outputRootAbsolute
        session_root = $sessionRootAbsolute
        checkpoints_root = $checkpointsRootAbsolute
        logs_root = Join-Path $sessionRootAbsolute "logs"
        ledger_path = $ledgerPath
        runs = @()
    }
}

$gitSnapshot = if ($Execute) {
    Get-GitSnapshot
}
else {
    [pscustomobject]@{
        Commit = ""
        WorktreeStatus = @()
        WorktreeStateSha256 = ""
    }
}
if ($Execute -and $Phase -eq "baseline" -and
    @($gitSnapshot.WorktreeStatus).Count -ne 0) {
    $examples = @($gitSnapshot.WorktreeStatus | Select-Object -First 8) -join "; "
    throw ("An executed recovery-wave baseline requires a clean committed worktree. " +
        "Commit or remove pending changes first. Git status: $examples")
}

$gateSnapshot = $null
$baselineRunId = ""
$priorBoundaryRunId = ""
$baselineRun = $null
$priorBoundaryRun = $null
if ($Execute -and ($Phase -eq "promotion-wave" -or $Phase -eq "final")) {
    $passedBaselines = @(
        $priorRuns | Where-Object {
            [string]$_.phase -eq "baseline" -and
            [string]$_.mode -eq "execute" -and
            [string]$_.status -eq "passed"
        })
    if ($passedBaselines.Count -eq 0) {
        throw ("Executing phase '$Phase' requires a passed executed baseline " +
            "in recovery-wave session '$SessionId'.")
    }

    $baselineRun = $passedBaselines[-1]
    $baselineCommit = [string]$baselineRun.git_commit_sha
    if ($baselineCommit -notmatch '^[0-9a-fA-F]{40}$') {
        throw "The passed baseline run has no valid git_commit_sha."
    }
    if (-not (Test-GitAncestor $baselineCommit $gitSnapshot.Commit)) {
        throw ("Baseline commit '$baselineCommit' is not an ancestor of " +
            "current HEAD '$($gitSnapshot.Commit)'.")
    }
    $baselineRunId = [string]$baselineRun.run_id

    $gateSnapshot = Get-GateSemanticsSnapshot $gateToolPaths

    $baselineGateHash =
        ([string]$baselineRun.gate_snapshot.gate_semantics_sha256).Trim().ToLowerInvariant()
    if ($baselineGateHash -notmatch '^[0-9a-f]{64}$' -or
        $null -eq $baselineRun.metrics_summary) {
        throw "The passed baseline run is missing its gate/metrics boundary evidence."
    }
    if ([string]$gateSnapshot.gate_semantics_sha256 -cne $baselineGateHash) {
        throw ("Recovery gate semantics changed since the baseline; start a new " +
            "clean recovery-wave session baseline.")
    }

    $ancestralBoundaries = @()
    foreach ($candidateRun in $priorRuns) {
        if ([string]$candidateRun.mode -ne "execute" -or
            [string]$candidateRun.status -ne "passed" -or
            $null -eq $candidateRun.metrics_summary) {
            continue
        }
        $candidateCommit = [string]$candidateRun.git_commit_sha
        if ($candidateCommit -notmatch '^[0-9a-fA-F]{40}$') {
            continue
        }
        if (Test-GitAncestor $candidateCommit $gitSnapshot.Commit) {
            $ancestralBoundaries += $candidateRun
        }
    }
    if ($ancestralBoundaries.Count -eq 0) {
        throw "No passed ancestral metrics boundary is available for phase '$Phase'."
    }
    $priorBoundaryRun = $ancestralBoundaries[-1]
    $priorBoundaryRunId = [string]$priorBoundaryRun.run_id
}

if ($Execute -and $null -eq $gateSnapshot) {
    $gateSnapshot = Get-GateSemanticsSnapshot $gateToolPaths
}

if ($Execute) {
    $completedCheckpointRuns = @(
        $priorRuns | Where-Object {
            [string]$_.mode -eq "execute" -and
            [string]$_.status -eq "passed" -and
            [string]$_.checkpoint_id -eq $CheckpointId
        })
    if ($completedCheckpointRuns.Count -ne 0) {
        throw ("CheckpointId '$CheckpointId' already has a passed execution " +
            "in session '$SessionId'; choose a distinct checkpoint ID.")
    }
}

$runStarted = [DateTime]::UtcNow
$runId = $runStarted.ToString("yyyyMMddTHHmmssfffZ") + "-" +
    [guid]::NewGuid().ToString("N").Substring(0, 8)
$logDirectory = Join-Path (Join-Path $sessionRootAbsolute "logs") $runId
$run = [pscustomobject][ordered]@{
    run_id = $runId
    phase = $Phase
    checkpoint_id = $CheckpointId
    checkpoint_directory = $checkpointRootAbsolute
    candidate_directory = $candidateDirectoryAbsolute
    product_directory = $productDirectoryAbsolute
    log_directory = $logDirectory
    minimum_instruction_percent = $MinimumInstructionPercent
    minimum_instruction_gain = $MinimumInstructionGain
    git_snapshot_captured = [bool]$Execute
    git_commit_sha = $gitSnapshot.Commit
    worktree_state_sha256 = $gitSnapshot.WorktreeStateSha256
    worktree_dirty = if ($Execute) {
        (@($gitSnapshot.WorktreeStatus).Count -ne 0)
    }
    else {
        $null
    }
    worktree_status = @($gitSnapshot.WorktreeStatus)
    git_end_snapshot_captured = $false
    git_end_commit_sha = ""
    end_worktree_state_sha256 = ""
    end_worktree_dirty = $null
    end_worktree_status = @()
    gate_snapshot_end = $null
    end_boundary_error = ""
    baseline_run_id = $baselineRunId
    prior_boundary_run_id = $priorBoundaryRunId
    gate_snapshot = $gateSnapshot
    metrics_summary = $null
    promotion_delta = [pscustomobject][ordered]@{
        prior_boundary_run_id = $priorBoundaryRunId
        prior_boundary_checkpoint_id = if ($null -eq $priorBoundaryRun) {
            ""
        }
        else {
            [string]$priorBoundaryRun.checkpoint_id
        }
        accepted_instructions_before = $null
        accepted_instructions_after = $null
        accepted_instruction_gain = $null
        new_identity_count = $null
        new_identity_sha256 = ""
        new_identities = @()
        status = if ($Phase -eq "baseline") {
            "not-applicable"
        }
        elseif ($Execute) {
            "pending"
        }
        else {
            "planned"
        }
        error = ""
    }
    promotion_evidence = [pscustomobject][ordered]@{
        supplied = -not [string]::IsNullOrWhiteSpace($promotionEvidenceRelative)
        repository_relative_path = $promotionEvidenceRelative
        absolute_path = $promotionEvidenceAbsolute
        sha256 = ""
        schema_version = $null
        checkpoint_id = $CheckpointId
        prior_boundary_run_id = $priorBoundaryRunId
        identity_count = $null
        identity_sha256 = ""
        identities = @()
        bindings = @()
        validated = $false
        status = if ($Phase -eq "baseline") {
            "not-applicable"
        }
        elseif ($Execute) {
            "pending"
        }
        else {
            "planned"
        }
        error = ""
        end_verified = $false
        end_error = ""
    }
    mode = if ($Execute) { "execute" } else { "plan" }
    status = if ($Execute) { "running" } else { "planned" }
    started_utc = $runStarted.ToString("o")
    completed_utc = ""
    duration_ms = 0
    steps = @($steps)
}

$ledger.runs = @($priorRuns + @($run))
[void][System.IO.Directory]::CreateDirectory($sessionRootAbsolute)

Write-Host ("Recovery wave session '{0}', checkpoint '{1}', phase '{2}', mode '{3}'" -f
    $SessionId, $CheckpointId, $Phase, $run.mode)
Write-Host ("Checkpoint candidate output: {0}" -f $candidateDirectoryAbsolute)
Write-Host ("Checkpoint Product output:   {0}" -f $productDirectoryAbsolute)
Write-Host ""
foreach ($step in $steps) {
    Write-Host ("[{0}] {1}" -f $step.name, $step.command)
}

if (-not $Execute) {
    $run.completed_utc = [DateTime]::UtcNow.ToString("o")
    $run.duration_ms = [long]([DateTime]::UtcNow - $runStarted).TotalMilliseconds
    Write-SessionLedger $ledger $ledgerPath
    Write-Host ""
    Write-Host "Plan only: no recovery-wave step was executed. Pass -Execute to run it."
    Write-Host ("Session ledger: {0}" -f $ledgerPath)
    return
}

[void][System.IO.Directory]::CreateDirectory($checkpointRootAbsolute)
[void][System.IO.Directory]::CreateDirectory($logDirectory)
if (Test-Path -LiteralPath $metricsSummaryAbsolute -PathType Leaf) {
    Remove-Item -LiteralPath $metricsSummaryAbsolute -Force
}
Write-SessionLedger $ledger $ledgerPath
$failure = $null

Push-Location $repoRoot
try {
    for ($index = 0; $index -lt $steps.Count; $index++) {
        $step = $steps[$index]
        $safeName = $step.name -replace '[^A-Za-z0-9._-]', '_'
        $logPath = Join-Path $logDirectory ("{0:D2}-{1}.log" -f ($index + 1), $safeName)
        $step.log_path = $logPath
        $step.status = "running"
        $step.started_utc = [DateTime]::UtcNow.ToString("o")
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        Write-Host ""
        Write-Host ("== {0}/{1}: {2} ==" -f ($index + 1), $steps.Count, $step.name) -ForegroundColor Cyan
        try {
            if ($step.kind -eq "process") {
                $result = Invoke-ProcessStep $step $logPath
            }
            else {
                $result = Invoke-InternalStep $step $logPath
            }
            $step.exit_code = [int]$result.ExitCode
            $step.output_tail = @(Get-OutputTail @($result.Lines))
            if ($step.exit_code -ne 0) {
                throw "Step '$($step.name)' exited $($step.exit_code)."
            }
            if ($step.name -eq "report-progress-metrics") {
                $currentMetricsSummary = Read-MetricsSummary $metricsSummaryAbsolute
                $run.metrics_summary = $currentMetricsSummary
                if ($Phase -eq "promotion-wave" -or $Phase -eq "final") {
                    Assert-MetricsBoundary `
                        $currentMetricsSummary $baselineRun.metrics_summary `
                        "the clean session baseline"
                    if ([string]$priorBoundaryRun.run_id -cne
                        [string]$baselineRun.run_id) {
                        Assert-MetricsBoundary `
                            $currentMetricsSummary $priorBoundaryRun.metrics_summary `
                            ("prior passed checkpoint '{0}'" -f
                                $priorBoundaryRun.checkpoint_id)
                    }
                }
            }
            $step.status = "passed"
        }
        catch {
            $step.status = "failed"
            $step.error = $_.Exception.Message
            if ($null -eq $step.exit_code -or [int]$step.exit_code -eq 0) {
                $step.exit_code = 1
            }
            $failure = $_
        }
        finally {
            $stopwatch.Stop()
            $step.duration_ms = [long]$stopwatch.ElapsedMilliseconds
            $step.completed_utc = [DateTime]::UtcNow.ToString("o")
        }

        if ($null -ne $failure) {
            for ($remaining = $index + 1; $remaining -lt $steps.Count; $remaining++) {
                $steps[$remaining].status = "skipped"
                $steps[$remaining].error = "Skipped after '$($step.name)' failed."
            }
            break
        }
    }
}
finally {
    try {
        $endGitSnapshot = Get-GitSnapshot
        $run.git_end_snapshot_captured = $true
        $run.git_end_commit_sha = $endGitSnapshot.Commit
        $run.end_worktree_state_sha256 =
            $endGitSnapshot.WorktreeStateSha256
        $run.end_worktree_dirty =
            (@($endGitSnapshot.WorktreeStatus).Count -ne 0)
        $run.end_worktree_status = @($endGitSnapshot.WorktreeStatus)

        if ($null -eq $failure) {
            $endGateSnapshot = Get-GateSemanticsSnapshot $gateToolPaths
            $run.gate_snapshot_end = $endGateSnapshot
            if ([string]$endGitSnapshot.Commit -cne
                [string]$gitSnapshot.Commit) {
                throw ("Git HEAD changed during recovery-wave execution " +
                    "(start {0}, end {1})." -f
                    $gitSnapshot.Commit, $endGitSnapshot.Commit)
            }
            if ([string]$endGitSnapshot.WorktreeStateSha256 -cne
                [string]$gitSnapshot.WorktreeStateSha256) {
                throw ("Git worktree/index state changed during recovery-wave " +
                    "execution; discard this checkpoint and rerun it.")
            }
            if ([string]$endGateSnapshot.gate_semantics_sha256 -cne
                [string]$gateSnapshot.gate_semantics_sha256 -or
                [string]$endGateSnapshot.execution_snapshot_sha256 -cne
                [string]$gateSnapshot.execution_snapshot_sha256) {
                throw ("Recovery gate/input semantics changed during checkpoint " +
                    "execution; discard this checkpoint and rerun it.")
            }
            Assert-PromotionEvidenceEndBoundary $run.promotion_evidence
        }
    }
    catch {
        $run.end_boundary_error = $_.Exception.Message
        if ($null -eq $failure) {
            $failure = $_
        }
    }

    Pop-Location
    $run.completed_utc = [DateTime]::UtcNow.ToString("o")
    $run.duration_ms = [long]([DateTime]::UtcNow - $runStarted).TotalMilliseconds
    $run.status = if ($null -eq $failure) { "passed" } else { "failed" }
    Write-SessionLedger $ledger $ledgerPath
}

Write-Host ""
Write-Host ("Session ledger: {0}" -f $ledgerPath)
if ($null -ne $failure) {
    throw $failure
}
Write-Host ("Recovery wave phase '{0}' passed in {1:N1} seconds." -f
    $Phase, ([double]$run.duration_ms / 1000.0))
}
finally {
    Exit-SessionLock $sessionLock
}
