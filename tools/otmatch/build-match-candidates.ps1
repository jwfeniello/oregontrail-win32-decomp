param(
    [string]$OutputDirectory = "artifacts\otmatch",

    [ValidateSet("ModernVs", "LegacyMsvc")]
    [string]$Toolchain = "ModernVs",

    [string]$DevShell = "C:\Program Files\Microsoft Visual Studio\18\Community\Common7\Tools\Launch-VsDevShell.ps1",

    [string]$VcToolsRoot = "",
    [string]$ClPath = "",
    [string]$LinkPath = "",
    [string[]]$IncludePath = @(),
    [string[]]$LibPath = @(),

    [string]$DefaultOptimization = "",
    [string]$SemanticOptimization = "",
    [string[]]$ExtraCompileFlags = @(),
    [string[]]$ExtraLinkFlags = @(),
    [string]$TuMetadataPath = "tools\otmatch\vc4-tu-metadata.csv",

    [string]$ObjectCacheDirectory = "artifacts\otmatch\.candidate-cache",
    [string[]]$ChangedSource = @(),
    [switch]$FocusedChangedSource,
    [switch]$Rebuild,
    [Alias("CleanCache")]
    [switch]$CleanObjectCache,
    [switch]$DisableIncrementalCache,
    [ValidateRange(1, 3600)]
    [int]$BuildLockTimeoutSeconds = 120,

    # Asset-free contract tests use a tiny source tree while exercising the
    # real build/cache orchestration. Normal callers should leave this unset.
    [Parameter(DontShow = $true)]
    [string]$CandidateSourceRoot = "",

    # Source-shape sessions hold the exclusive graph lock across mutation,
    # build, diff, and restoration, so their nested builds must not reacquire.
    [Parameter(DontShow = $true)]
    [switch]$CandidateGraphLockHeld,

    # A source-shape runner may validate a seeded state once while holding the
    # exclusive graph lock, then request cheap diagnostic iterations. The
    # runner must finish with one non-trusting focused restoration build.
    [Parameter(DontShow = $true)]
    [switch]$FocusedGraphAlreadyValidated,

    # The source-shape runner uses two byte-identical focused relinks to prove
    # that VC4/PDB state has reached a reproducible lane boundary before source
    # mutation. This never enables companion links or a graph rebuild.
    [Parameter(DontShow = $true)]
    [switch]$ForceMainRelink
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$compileWorkingDirectory = (Get-Location).Path
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$outputPath = $null
$tuMetadataSha256 = ""
$tuMetadataBySource = @{}
# Match-candidate sources live in three trees:
#   src/otwin/<subsystem>/          readable product-shaped recovered code
#   src/otwin/_recovery/<subsystem>/ recovery-only WIP/probe/hybrid candidates
#   src/otwin/_exact/<subsystem>/    byte-matched exact scaffolds/promotions
#
# The recovery tree remains buildable for byte comparison, but its rows are not
# product-semantic until they are promoted back into a subsystem folder. The
# VC4 CRT/import link anchors live next to this script as match_dll_anchors.cpp.
$sourceRoot = if ([string]::IsNullOrWhiteSpace($CandidateSourceRoot)) {
    Join-Path $repoRoot "src\otwin"
} elseif ([System.IO.Path]::IsPathRooted($CandidateSourceRoot)) {
    (Resolve-Path -LiteralPath $CandidateSourceRoot).Path
} else {
    (Resolve-Path -LiteralPath (Join-Path $repoRoot $CandidateSourceRoot)).Path
}
if (-not [string]::IsNullOrWhiteSpace($CandidateSourceRoot) -and
    -not $PSBoundParameters.ContainsKey("TuMetadataPath")) {
    # Asset-free contract fixtures use a custom graph and must opt into their
    # own metadata instead of consuming the production graph's TU exceptions.
    $TuMetadataPath = ""
}
$anchorFile = Join-Path $PSScriptRoot "match_dll_anchors.cpp"
$lcmtAnchorFile = Join-Path $PSScriptRoot "match_dll_anchors_lcmt.cpp"
$dllcrtAnchorFile = Join-Path $PSScriptRoot "match_dll_anchors_dllcrt.cpp"
$dllPath = $null
$mapPath = $null
$lcmtDllPath = $null
$lcmtMapPath = $null
$dllcrtDllPath = $null
$dllcrtMapPath = $null

function Resolve-FirstExistingFile {
    param(
        [string[]]$Candidates,
        [string]$Description
    )

    foreach ($candidate in $Candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }

        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    throw "$Description was not found. Tried: $($Candidates -join '; ')"
}

function Get-ExistingDirectories {
    param([string[]]$Candidates)

    $paths = @()
    foreach ($candidate in $Candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }

        if (Test-Path -LiteralPath $candidate -PathType Container) {
            $paths += (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    return $paths
}

function Prepend-EnvironmentList {
    param(
        [string]$Name,
        [string[]]$Paths
    )

    $resolved = Get-ExistingDirectories $Paths
    if (@($resolved).Count -eq 0) {
        return
    }

    $current = [Environment]::GetEnvironmentVariable($Name, "Process")
    if ([string]::IsNullOrWhiteSpace($current)) {
        [Environment]::SetEnvironmentVariable($Name, ($resolved -join ";"), "Process")
    } else {
        [Environment]::SetEnvironmentVariable($Name, (($resolved + @($current)) -join ";"), "Process")
    }
}

function Resolve-CommandPath {
    param([string]$CommandName)

    $command = Get-Command -Name $CommandName -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) {
        return ""
    }

    return $command.Source
}

function Invoke-LinkInWorkingDirectory {
    param(
        [string]$LinkPath,
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )

    Push-Location $WorkingDirectory
    try {
        & $LinkPath @Arguments
    } finally {
        Pop-Location
    }
}

function Test-CoffObjectHasSections {
    param([string]$Path)

    $stream = [System.IO.File]::OpenRead($Path)
    try {
        if ($stream.Length -lt 4) {
            throw "COFF object is too small: '$Path'."
        }
        $reader = New-Object System.IO.BinaryReader($stream)
        [void]$reader.ReadUInt16() # Machine
        return ($reader.ReadUInt16() -ne 0)
    } finally {
        $stream.Dispose()
    }
}

function Clear-CoffObjectTimestamp {
    param([string]$Path)

    # VC4 writes the current epoch time into IMAGE_FILE_HEADER.TimeDateStamp
    # (bytes 4..7) on every compile. It does not affect linked code/data, but
    # leaving it intact makes byte-identical recompiles appear different and
    # defeats content-addressed object/link reuse.
    $stream = [System.IO.File]::Open(
        $Path,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::ReadWrite,
        [System.IO.FileShare]::None)
    try {
        if ($stream.Length -lt 8) {
            throw "COFF object is too small to canonicalize: '$Path'."
        }
        $header = New-Object byte[] 8
        if ($stream.Read($header, 0, $header.Length) -ne $header.Length) {
            throw "Could not read the COFF header while canonicalizing '$Path'."
        }
        $timestampOffset = if ($header[0] -eq 0x4c -and $header[1] -eq 0x01) {
            4 # IMAGE_FILE_HEADER
        } elseif ($header[0] -eq 0 -and $header[1] -eq 0 -and
            $header[2] -eq 0xff -and $header[3] -eq 0xff -and
            $header[6] -eq 0x4c -and $header[7] -eq 0x01) {
            8 # ANON_OBJECT_HEADER_BIGOBJ
        } else {
            throw "Expected an x86 COFF object while canonicalizing '$Path'."
        }
        if ($stream.Length -lt ($timestampOffset + 4)) {
            throw "COFF object is too small to canonicalize: '$Path'."
        }
        $stream.Position = $timestampOffset
        $stream.Write([byte[]](0, 0, 0, 0), 0, 4)
        $stream.Flush()
    } finally {
        $stream.Dispose()
    }
}

function Get-Sha256HexFromBytes {
    param([byte[]]$Bytes)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return [System.BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace("-", "").ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Get-StringSha256Hex {
    param([string]$Text)

    return Get-Sha256HexFromBytes ([System.Text.Encoding]::UTF8.GetBytes($Text))
}

function Get-FileSha256Hex {
    param([string]$Path)

    $stream = [System.IO.File]::OpenRead((Resolve-Path -LiteralPath $Path).Path)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return [System.BitConverter]::ToString($sha.ComputeHash($stream)).Replace("-", "").ToLowerInvariant()
    } finally {
        $sha.Dispose()
        $stream.Dispose()
    }
}

function Test-FileMatchesSha256 {
    param(
        [string]$Path,
        [long]$ExpectedLength,
        [string]$ExpectedSha256,
        [System.Security.Cryptography.HashAlgorithm]$Hasher
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }
    $file = Get-Item -LiteralPath $Path
    if ([long]$file.Length -ne $ExpectedLength) {
        return $false
    }

    $stream = [System.IO.File]::Open(
        $file.FullName,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::Read)
    try {
        $actual = [System.BitConverter]::ToString(
            $Hasher.ComputeHash($stream)).Replace("-", "").ToLowerInvariant()
        return $actual -eq $ExpectedSha256
    } finally {
        $stream.Dispose()
    }
}

function Resolve-RepoOwnedDirectory {
    param(
        [string]$Path,
        [string]$Description
    )

    $fullPath = if ([System.IO.Path]::IsPathRooted($Path)) {
        [System.IO.Path]::GetFullPath($Path)
    } else {
        [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
    }
    $repoPrefix = $repoRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "$Description must remain inside the repository: '$fullPath'."
    }
    return $fullPath.TrimEnd('\', '/')
}

function Resolve-IgnoredRepoOutputDirectory {
    param([string]$Path)

    $fullPath = Resolve-RepoOwnedDirectory $Path "Candidate output directory"
    $matchedAllowedRoot = ""
    foreach ($allowedRelativeRoot in @("a", "artifacts")) {
        $allowedRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot $allowedRelativeRoot)).TrimEnd('\', '/')
        $allowedPrefix = $allowedRoot + [System.IO.Path]::DirectorySeparatorChar
        if ($fullPath.StartsWith($allowedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            $matchedAllowedRoot = $allowedRoot
            break
        }
    }
    if ([string]::IsNullOrWhiteSpace($matchedAllowedRoot)) {
        throw "Candidate output directory must be beneath the repository's ignored 'a' or 'artifacts' roots: '$fullPath'."
    }

    # Lexical containment is insufficient when an existing junction/symlink
    # below an ignored root redirects writes and stale-output removals. Reject
    # every existing reparse-point ancestor, including the allowed root.
    $current = $matchedAllowedRoot
    $relativeBelowAllowedRoot = $fullPath.Substring($matchedAllowedRoot.Length).TrimStart('\', '/')
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
            throw "Candidate output directory cannot traverse reparse point '$($item.FullName)'."
        }
    }

    $repoRelativePath = $fullPath.Substring($repoRoot.Length).TrimStart('\', '/') -replace '\\', '/'
    & git -C $repoRoot check-ignore -q -- $repoRelativePath
    if ($LASTEXITCODE -ne 0) {
        throw "Candidate output directory is not Git-ignored: '$fullPath'."
    }
    return $fullPath
}

$outputPath = Resolve-IgnoredRepoOutputDirectory $OutputDirectory
$dllPath = Join-Path $outputPath "otwin-match-candidates.dll"
$mapPath = Join-Path $outputPath "otwin-match-candidates.map"
$lcmtDllPath = Join-Path $outputPath "otwin-match-candidates-lcmt.dll"
$lcmtMapPath = Join-Path $outputPath "otwin-match-candidates-lcmt.map"
$dllcrtDllPath = Join-Path $outputPath "otwin-match-candidates-dllcrt.dll"
$dllcrtMapPath = Join-Path $outputPath "otwin-match-candidates-dllcrt.map"

function Write-TextAtomically {
    param(
        [string]$Path,
        [string]$Text
    )

    $directory = Split-Path -Parent $Path
    [void][System.IO.Directory]::CreateDirectory($directory)
    $temporaryPath = "$Path.$PID.$([Guid]::NewGuid().ToString('N')).tmp"
    try {
        [System.IO.File]::WriteAllText(
            $temporaryPath,
            $Text,
            (New-Object System.Text.UTF8Encoding($false)))
        Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
    } finally {
        if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

function Enter-ExclusiveFileLock {
    param(
        [string]$Path,
        [int]$TimeoutSeconds,
        [string]$Description
    )

    [void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $Path))
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while ($true) {
        try {
            return [System.IO.File]::Open(
                $Path,
                [System.IO.FileMode]::OpenOrCreate,
                [System.IO.FileAccess]::ReadWrite,
                [System.IO.FileShare]::None)
        } catch [System.IO.IOException] {
            if ([DateTime]::UtcNow -ge $deadline) {
                throw "Timed out after $TimeoutSeconds second(s) waiting for $Description lock '$Path'."
            }
            Start-Sleep -Milliseconds 100
        }
    }
}

function Enter-SharedFileLock {
    param(
        [string]$Path,
        [int]$TimeoutSeconds,
        [string]$Description
    )

    [void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $Path))
    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    while ($true) {
        try {
            if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
                $initializer = [System.IO.File]::Open(
                    $Path,
                    [System.IO.FileMode]::OpenOrCreate,
                    [System.IO.FileAccess]::ReadWrite,
                    [System.IO.FileShare]::ReadWrite)
                $initializer.Dispose()
            }
            return [System.IO.File]::Open(
                $Path,
                [System.IO.FileMode]::Open,
                [System.IO.FileAccess]::Read,
                [System.IO.FileShare]::Read)
        } catch [System.IO.IOException] {
            if ([DateTime]::UtcNow -ge $deadline) {
                throw "Timed out after $TimeoutSeconds second(s) waiting for $Description lock '$Path'."
            }
            Start-Sleep -Milliseconds 100
        }
    }
}

function Get-DirectoryPayloadFingerprint {
    param(
        [string]$ToolPath,
        [switch]$Fresh
    )

    $resolvedToolPath = (Resolve-Path -LiteralPath $ToolPath).Path
    $directory = Split-Path -Parent $resolvedToolPath
    if (-not $Fresh -and $toolDirectoryFingerprintCache.ContainsKey($directory)) {
        return $toolDirectoryFingerprintCache[$directory]
    }

    # CL.EXE and LINK.EXE are only launchers. VC4 code generation/linking also
    # depends on adjacent passes and DLLs (notably C1XX.EXE, C2.EXE, and
    # MSPDB40.DLL). Hash the complete sibling payload so wrapper scripts and
    # helper changes cannot silently reuse objects produced by another binary.
    $entries = @("directory=$($directory.ToLowerInvariant())")
    foreach ($file in @(Get-ChildItem -LiteralPath $directory -File | Sort-Object Name)) {
        $entries += ($file.Name.ToLowerInvariant() + "=" + (Get-FileSha256Hex $file.FullName))
    }
    $fingerprint = Get-StringSha256Hex ($entries -join "`n")
    $toolDirectoryFingerprintCache[$directory] = $fingerprint
    return $fingerprint
}

function Get-IncludeSearchPaths {
    $paths = @()
    $includeEnvironment = [Environment]::GetEnvironmentVariable("INCLUDE", "Process")
    $includeEntries = @($IncludePath) + @($includeEnvironment -split ';')
    foreach ($entry in $includeEntries) {
        $candidate = $entry.Trim().Trim('"')
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and
            (Test-Path -LiteralPath $candidate -PathType Container)) {
            $resolved = (Resolve-Path -LiteralPath $candidate).Path
            if ($paths -notcontains $resolved) {
                $paths += $resolved
            }
        }
    }
    return $paths
}

function Split-MsvcOptionString {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }
    $tokens = @()
    foreach ($match in [regex]::Matches($Text, '(?:[^\s"]+|"[^"]*")+')) {
        $tokens += $match.Value
    }
    return $tokens
}

function Get-CompileDependencyOptions {
    param([string[]]$CompileArguments)

    $tokens = @()
    $tokens += Split-MsvcOptionString ([Environment]::GetEnvironmentVariable("CL", "Process"))
    $tokens += $CompileArguments
    $tokens += Split-MsvcOptionString ([Environment]::GetEnvironmentVariable("_CL_", "Process"))

    $optionIncludePaths = @()
    $forcedIncludeNames = @()
    $compilerDependencyFiles = @()
    $cacheable = $true
    $reasons = @()
    $ignoreEnvironmentIncludes = $false
    for ($index = 0; $index -lt $tokens.Count; $index++) {
        $token = ([string]$tokens[$index]).Trim()
        $unquotedToken = $token.Replace('"', '')
        if ($unquotedToken.StartsWith('@')) {
            # Compiler response files can add include paths, forced includes,
            # pass overrides, and source inputs. Bypass until they are parsed.
            $cacheable = $false
            $reasons += "compiler response file '$token'"
            continue
        }
        if ($unquotedToken -match '^[/-][Xx]$') {
            $ignoreEnvironmentIncludes = $true
            continue
        }
        if ($unquotedToken -match '^[/-](?:Yu|Yc|Fp)') {
            # Reusing a PCH safely requires fingerprinting both the PCH and
            # its compiler-owned dependency graph. No candidate currently
            # uses one, so conservatively bypass these TUs.
            $cacheable = $false
            $reasons += "precompiled-header option '$token'"
            continue
        }

        $pathValue = ""
        if ($unquotedToken -match '^[/-][Ii]$') {
            if (($index + 1) -ge $tokens.Count) {
                $cacheable = $false
                $reasons += "missing /I argument"
                continue
            }
            $index++
            $pathValue = ([string]$tokens[$index]).Trim().Trim('"')
        } elseif ($unquotedToken -match '^[/-][Ii](.+)$') {
            $pathValue = $Matches[1].TrimStart('=').Trim('"')
        }
        if (-not [string]::IsNullOrWhiteSpace($pathValue)) {
            $candidate = if ([System.IO.Path]::IsPathRooted($pathValue)) {
                $pathValue
            } else {
                Join-Path $compileWorkingDirectory $pathValue
            }
            if (Test-Path -LiteralPath $candidate -PathType Container) {
                $resolved = (Resolve-Path -LiteralPath $candidate).Path
                if ($optionIncludePaths -notcontains $resolved) {
                    $optionIncludePaths += $resolved
                }
            }
            continue
        }

        if ($unquotedToken -match '^[/-][Ff][Ii]$') {
            if (($index + 1) -ge $tokens.Count) {
                $cacheable = $false
                $reasons += "missing /FI argument"
                continue
            }
            $index++
            $forcedIncludeNames += ([string]$tokens[$index]).Trim().Trim('"')
        } elseif ($unquotedToken -match '^[/-][Ff][Ii](.+)$') {
            $forcedIncludeNames += $Matches[1].TrimStart('=').Trim('"')
        }

        $compilerPassPath = ""
        if ($unquotedToken -match '^[/-][Bb][12]$') {
            if (($index + 1) -ge $tokens.Count) {
                $cacheable = $false
                $reasons += "missing $token argument"
                continue
            }
            $index++
            $compilerPassPath = ([string]$tokens[$index]).Trim().Trim('"')
        } elseif ($unquotedToken -match '^[/-][Bb][12](.+)$') {
            $compilerPassPath = $Matches[1].TrimStart('=').Trim('"')
        }
        if (-not [string]::IsNullOrWhiteSpace($compilerPassPath)) {
            $candidate = if ([System.IO.Path]::IsPathRooted($compilerPassPath)) {
                $compilerPassPath
            } else {
                Join-Path $compileWorkingDirectory $compilerPassPath
            }
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                $compilerDependencyFiles += (Resolve-Path -LiteralPath $candidate).Path
            } else {
                $cacheable = $false
                $reasons += "unresolved compiler pass override '$compilerPassPath'"
            }
        }
    }

    $effectiveIncludePaths = @($optionIncludePaths)
    if (-not $ignoreEnvironmentIncludes) {
        $effectiveIncludePaths += $environmentIncludeSearchPaths
    }
    $context = @(
        "paths=$($effectiveIncludePaths -join [char]0x1f)",
        "forced=$($forcedIncludeNames -join [char]0x1f)",
        "passes=$($compilerDependencyFiles -join [char]0x1f)",
        "cacheable=$cacheable"
    ) -join "`n"
    return [pscustomobject]@{
        Cacheable = $cacheable
        Reasons = @($reasons)
        IncludePaths = @($effectiveIncludePaths)
        ForcedIncludeNames = @($forcedIncludeNames)
        CompilerDependencyFiles = @($compilerDependencyFiles)
        ContextFingerprint = Get-StringSha256Hex $context
    }
}

function Resolve-IncludeFile {
    param(
        [string]$IncludingFile,
        [string]$IncludeName,
        [bool]$Quoted,
        [string[]]$IncludePaths
    )

    $searchDirectories = @()
    if ($Quoted) {
        $searchDirectories += Split-Path -Parent $IncludingFile
    }
    $searchDirectories += $IncludePaths

    foreach ($directory in $searchDirectories) {
        $candidate = Join-Path $directory ($IncludeName -replace '/', '\')
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    return ""
}

function Get-DirectDependencyInfo {
    param(
        [string]$Path,
        [string[]]$IncludePaths,
        [string]$ContextFingerprint,
        [switch]$Fresh
    )

    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    $cacheKey = $ContextFingerprint + "|" + $resolvedPath
    if (-not $Fresh -and $directDependencyCache.ContainsKey($cacheKey)) {
        $cachedInfo = $directDependencyCache[$cacheKey]
        $currentFile = Get-Item -LiteralPath $resolvedPath
        if ($currentFile.Length -eq $cachedInfo.Length -and
            $currentFile.LastWriteTimeUtc.Ticks -eq $cachedInfo.LastWriteTimeUtcTicks) {
            return $cachedInfo
        }
    }

    $fileBeforeRead = Get-Item -LiteralPath $resolvedPath
    $fileBytes = [System.IO.File]::ReadAllBytes($resolvedPath)
    $fileAfterRead = Get-Item -LiteralPath $resolvedPath
    $text = [System.Text.Encoding]::Default.GetString($fileBytes)
    $dependencies = @()
    $pragmaLibraries = @()
    $pragmaLinkerOptions = @()
    $cacheable = ($text -notmatch '__(DATE|TIME|TIMESTAMP)__')
    $reasons = @()
    if (-not $cacheable) {
        $reasons += "dynamic compiler time macro in '$resolvedPath'"
    }
    if ($fileBeforeRead.Length -ne $fileAfterRead.Length -or
        $fileBeforeRead.LastWriteTimeUtc.Ticks -ne $fileAfterRead.LastWriteTimeUtc.Ticks) {
        $cacheable = $false
        $reasons += "file changed while dependency snapshot was read: '$resolvedPath'"
    }
    $includeLines = [regex]::Matches(
        $text,
        '(?m)^\s*#\s*include\s+([^\r\n]+)')
    foreach ($includeLine in $includeLines) {
        $operand = $includeLine.Groups[1].Value.Trim()
        $quoted = $false
        $includeName = ""
        if ($operand -match '^"([^"]+)"') {
            $quoted = $true
            $includeName = $Matches[1]
        } elseif ($operand -match '^<([^>]+)>') {
            $includeName = $Matches[1]
        } else {
            # Macro-generated includes cannot be resolved safely without the
            # compiler preprocessor, so this TU deliberately bypasses reuse.
            $cacheable = $false
            $reasons += "macro include in '$resolvedPath': $operand"
            continue
        }

        $dependency = Resolve-IncludeFile $resolvedPath $includeName $quoted $IncludePaths
        if ([string]::IsNullOrWhiteSpace($dependency)) {
            $cacheable = $false
            $reasons += "unresolved include in '$resolvedPath': $includeName"
        } elseif ($dependencies -notcontains $dependency) {
            $dependencies += $dependency
        }
    }
    foreach ($pragmaLibrary in [regex]::Matches(
            $text,
            '(?im)^\s*#\s*pragma\s+comment\s*\(\s*lib\s*,\s*"([^"]+)"')) {
        $value = $pragmaLibrary.Groups[1].Value
        $discoveredPragmaLibraries[$value] = $true
        $pragmaLibraries += $value
    }
    foreach ($pragmaLinkerOption in [regex]::Matches(
            $text,
            '(?im)^\s*#\s*pragma\s+comment\s*\(\s*linker\s*,\s*"([^"]+)"')) {
        $value = $pragmaLinkerOption.Groups[1].Value
        $discoveredPragmaLinkerOptions[$value] = $true
        $pragmaLinkerOptions += $value
    }

    $info = [pscustomobject]@{
        Path = $resolvedPath
        FileSha256 = Get-Sha256HexFromBytes $fileBytes
        Length = $fileAfterRead.Length
        LastWriteTimeUtcTicks = $fileAfterRead.LastWriteTimeUtc.Ticks
        Dependencies = @($dependencies)
        PragmaLibraries = @($pragmaLibraries | Select-Object -Unique)
        PragmaLinkerOptions = @($pragmaLinkerOptions | Select-Object -Unique)
        Cacheable = $cacheable
        Reasons = @($reasons)
    }
    if (-not $Fresh) {
        $directDependencyCache[$cacheKey] = $info
    }
    return $info
}

function Get-SourceClosureFingerprint {
    param(
        [string]$SourcePath,
        [string[]]$IncludePaths,
        [string[]]$ForcedIncludeNames,
        [string]$ContextFingerprint,
        [bool]$OptionsCacheable,
        [switch]$FreshDependencies
    )

    $queue = @((Resolve-Path -LiteralPath $SourcePath).Path)
    $cacheable = $OptionsCacheable
    $reasons = @()
    foreach ($forcedIncludeName in $ForcedIncludeNames) {
        $forcedInclude = Resolve-IncludeFile $SourcePath $forcedIncludeName $true $IncludePaths
        if ([string]::IsNullOrWhiteSpace($forcedInclude)) {
            $cacheable = $false
            $reasons += "unresolved forced include: $forcedIncludeName"
        } else {
            $queue += $forcedInclude
        }
    }
    $seen = @{}
    $entries = @()
    $snapshots = @()
    $pragmaLibraries = @()
    $pragmaLinkerOptions = @()
    while ($queue.Count -ne 0) {
        $current = $queue[0]
        if ($queue.Count -eq 1) {
            $queue = @()
        } else {
            $queue = @($queue[1..($queue.Count - 1)])
        }
        if ($seen.ContainsKey($current)) {
            continue
        }
        $seen[$current] = $true

        $info = Get-DirectDependencyInfo `
            -Path $current `
            -IncludePaths $IncludePaths `
            -ContextFingerprint $ContextFingerprint `
            -Fresh:$FreshDependencies
        if (-not $info.Cacheable) {
            $cacheable = $false
            $reasons += $info.Reasons
        }
        $entries += (([string]$info.Path).ToLowerInvariant() + "=" + $info.FileSha256)
        $snapshots += [pscustomobject]@{
            Path = [string]$info.Path
            Hash = [string]$info.FileSha256
            Length = [long]$info.Length
            LastWriteTimeUtcTicks = [long]$info.LastWriteTimeUtcTicks
        }
        $pragmaLibraries += @($info.PragmaLibraries)
        $pragmaLinkerOptions += @($info.PragmaLinkerOptions)
        foreach ($dependency in $info.Dependencies) {
            if (-not $seen.ContainsKey($dependency)) {
                $queue += $dependency
            }
        }
    }

    $closureText = (@($entries | Sort-Object) -join "`n")
    return [pscustomobject]@{
        Cacheable = $cacheable
        Fingerprint = Get-StringSha256Hex $closureText
        FileCount = $entries.Count
        DependencySnapshots = @($snapshots)
        PragmaLibraries = @($pragmaLibraries | Sort-Object -Unique)
        PragmaLinkerOptions = @($pragmaLinkerOptions | Sort-Object -Unique)
        Reasons = @($reasons | Select-Object -Unique)
    }
}

function Get-CompileFingerprint {
    param(
        [string]$SourcePath,
        [string]$ObjectName,
        [string[]]$CompileArguments,
        [switch]$FreshDependencies
    )

    $dependencyOptions = Get-CompileDependencyOptions $CompileArguments
    $closure = Get-SourceClosureFingerprint `
        -SourcePath $SourcePath `
        -IncludePaths $dependencyOptions.IncludePaths `
        -ForcedIncludeNames $dependencyOptions.ForcedIncludeNames `
        -ContextFingerprint $dependencyOptions.ContextFingerprint `
        -OptionsCacheable $dependencyOptions.Cacheable `
        -FreshDependencies:$FreshDependencies
    $normalizedArguments = @()
    foreach ($argument in $CompileArguments) {
        if ($argument -like '/Fo*') {
            $normalizedArguments += "/Fo$ObjectName"
        } else {
            $normalizedArguments += $argument
        }
    }
    $fields = @(
        "schema=otmatch-object-cache-v3",
        "toolchain=$Toolchain",
        "compiler=$compilerFingerprint",
        "source=$((Resolve-Path -LiteralPath $SourcePath).Path.ToLowerInvariant())",
        "closure=$($closure.Fingerprint)",
        "dependency_options=$($dependencyOptions.ContextFingerprint)",
        "include=$([Environment]::GetEnvironmentVariable('INCLUDE', 'Process'))",
        "cl=$([Environment]::GetEnvironmentVariable('CL', 'Process'))",
        "_cl_=$([Environment]::GetEnvironmentVariable('_CL_', 'Process'))",
        "arguments=$($normalizedArguments -join [char]0x1f)"
    )
    $dependencySnapshots = @($closure.DependencySnapshots)
    foreach ($compilerDependencyFile in @($dependencyOptions.CompilerDependencyFiles | Sort-Object -Unique)) {
        $compilerDependencyInfo = Get-Item -LiteralPath $compilerDependencyFile
        $compilerDependencyHash = Get-FileSha256Hex $compilerDependencyFile
        $fields += ("compiler_dependency={0}={1}" -f
            $compilerDependencyFile.ToLowerInvariant(),
            $compilerDependencyHash)
        $dependencySnapshots += [pscustomobject]@{
            Path = $compilerDependencyFile
            Hash = $compilerDependencyHash
            Length = [long]$compilerDependencyInfo.Length
            LastWriteTimeUtcTicks = [long]$compilerDependencyInfo.LastWriteTimeUtc.Ticks
        }
    }
    return [pscustomobject]@{
        Cacheable = $closure.Cacheable
        Reasons = @($dependencyOptions.Reasons + $closure.Reasons | Select-Object -Unique)
        Fingerprint = Get-StringSha256Hex ($fields -join "`n")
        DependencyFileCount = $closure.FileCount
        DependencySnapshots = @($dependencySnapshots)
        PragmaLibraries = @($closure.PragmaLibraries)
        PragmaLinkerOptions = @($closure.PragmaLinkerOptions)
    }
}

function Test-DependencySnapshotsUnchanged {
    param(
        [object[]]$Snapshots,
        [switch]$VerifyContent
    )

    $seen = @{}
    foreach ($snapshot in $Snapshots) {
        $key = ([string]$snapshot.Path).ToLowerInvariant()
        if ($seen.ContainsKey($key)) {
            $first = $seen[$key]
            if ($VerifyContent -and [string]$first.Hash -ne [string]$snapshot.Hash) {
                return $false
            }
            continue
        }
        $seen[$key] = $snapshot
        if (-not (Test-Path -LiteralPath $snapshot.Path -PathType Leaf)) {
            return $false
        }
        $current = Get-Item -LiteralPath $snapshot.Path
        if ($VerifyContent) {
            if ((Get-FileSha256Hex $snapshot.Path) -ne [string]$snapshot.Hash) {
                return $false
            }
        } else {
            if ($current.Length -ne [long]$snapshot.Length -or
                $current.LastWriteTimeUtc.Ticks -ne [long]$snapshot.LastWriteTimeUtcTicks) {
                return $false
            }
        }
    }
    return $true
}

function Assert-CandidateCompileInputsStable {
    $currentCompilerFingerprint = Get-DirectoryPayloadFingerprint $resolvedCompilerPath -Fresh
    if ($currentCompilerFingerprint -ne $compilerFingerprint) {
        throw "Compiler toolchain payload changed during the candidate build."
    }
    $allSnapshots = @()
    foreach ($record in $script:compileDependencyRecords) {
        $allSnapshots += @($record.Snapshots)
    }
    if (-not (Test-DependencySnapshotsUnchanged $allSnapshots -VerifyContent)) {
        throw "Candidate source/header content changed during the build."
    }
}

function Restore-CachedObject {
    param(
        [string]$Fingerprint,
        [string]$Destination
    )

    $prefix = $Fingerprint.Substring(0, 2)
    $cacheDirectory = Join-Path (Join-Path $objectCacheRoot "objects") $prefix
    $cacheObject = Join-Path $cacheDirectory "$Fingerprint.obj"
    $cacheHash = "$cacheObject.sha256"
    if (-not (Test-Path -LiteralPath $cacheObject -PathType Leaf) -or
        -not (Test-Path -LiteralPath $cacheHash -PathType Leaf)) {
        return $false
    }

    $entryLock = Enter-ExclusiveFileLock `
        -Path "$cacheObject.lock" `
        -TimeoutSeconds $BuildLockTimeoutSeconds `
        -Description "candidate object cache entry"
    try {
        if (-not (Test-Path -LiteralPath $cacheObject -PathType Leaf) -or
            -not (Test-Path -LiteralPath $cacheHash -PathType Leaf)) {
            return $false
        }
        $expectedHash = ([System.IO.File]::ReadAllText($cacheHash)).Trim().ToLowerInvariant()
        if ($expectedHash -notmatch '^[0-9a-f]{64}$') {
            Write-Warning "Ignoring corrupt candidate-object cache entry '$cacheObject'."
            return $false
        }
        if ((Get-FileSha256Hex $cacheObject) -ne $expectedHash) {
            Write-Warning "Ignoring corrupt candidate-object cache entry '$cacheObject'."
            return $false
        }
        if ((Test-Path -LiteralPath $Destination -PathType Leaf) -and
            (Get-FileSha256Hex $Destination) -eq $expectedHash) {
            [System.IO.File]::SetLastWriteTimeUtc($Destination, [DateTime]::UtcNow)
            return $true
        }
        Copy-Item -LiteralPath $cacheObject -Destination $Destination -Force
        [System.IO.File]::SetLastWriteTimeUtc($Destination, [DateTime]::UtcNow)
        return $true
    } finally {
        $entryLock.Dispose()
    }
}

function Publish-CachedObject {
    param(
        [string]$Fingerprint,
        [string]$ObjectPath
    )

    $prefix = $Fingerprint.Substring(0, 2)
    $cacheDirectory = Join-Path (Join-Path $objectCacheRoot "objects") $prefix
    [void][System.IO.Directory]::CreateDirectory($cacheDirectory)
    $cacheObject = Join-Path $cacheDirectory "$Fingerprint.obj"
    $cacheHash = "$cacheObject.sha256"
    $entryLock = Enter-ExclusiveFileLock `
        -Path "$cacheObject.lock" `
        -TimeoutSeconds $BuildLockTimeoutSeconds `
        -Description "candidate object cache entry"
    try {
        $objectHash = Get-FileSha256Hex $ObjectPath
        if ((Test-Path -LiteralPath $cacheObject -PathType Leaf) -and
            (Test-Path -LiteralPath $cacheHash -PathType Leaf)) {
            $existingHash = ([System.IO.File]::ReadAllText($cacheHash)).Trim().ToLowerInvariant()
            if ($existingHash -match '^[0-9a-f]{64}$' -and
                (Get-FileSha256Hex $cacheObject) -eq $existingHash) {
                if ($existingHash -ne $objectHash) {
                    throw "Compiler produced different bytes for existing cache fingerprint '$Fingerprint'."
                }
                return
            }
        }

        $temporaryObject = "$cacheObject.$PID.$([Guid]::NewGuid().ToString('N')).tmp"
        try {
            Copy-Item -LiteralPath $ObjectPath -Destination $temporaryObject -Force
            Move-Item -LiteralPath $temporaryObject -Destination $cacheObject -Force
            Write-TextAtomically $cacheHash ($objectHash + "`n")
        } finally {
            if (Test-Path -LiteralPath $temporaryObject -PathType Leaf) {
                Remove-Item -LiteralPath $temporaryObject -Force
            }
        }
    } finally {
        $entryLock.Dispose()
    }
}

function Get-ImmutableLinkInputHash {
    param(
        [string]$Path,
        [switch]$Fresh
    )

    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    $current = Get-Item -LiteralPath $resolvedPath
    $cached = if ($linkInputHashCache.ContainsKey($resolvedPath)) {
        $linkInputHashCache[$resolvedPath]
    } else {
        $null
    }
    if ($Fresh -or $null -eq $cached -or
        $cached.Length -ne $current.Length -or
        $cached.LastWriteTimeUtcTicks -ne $current.LastWriteTimeUtc.Ticks) {
        $cached = [pscustomobject]@{
            Hash = Get-FileSha256Hex $resolvedPath
            Length = [long]$current.Length
            LastWriteTimeUtcTicks = [long]$current.LastWriteTimeUtc.Ticks
        }
        $linkInputHashCache[$resolvedPath] = $cached
    }
    return $cached.Hash
}

function Get-LinkDependencyFingerprint {
    param(
        [string[]]$Arguments,
        [switch]$Fresh
    )

    $tokens = @()
    $tokens += Split-MsvcOptionString ([Environment]::GetEnvironmentVariable("LINK", "Process"))
    $tokens += $Arguments
    $tokens += Split-MsvcOptionString ([Environment]::GetEnvironmentVariable("_LINK_", "Process"))
    foreach ($pragmaLinkerOption in @($discoveredPragmaLinkerOptions.Keys | Sort-Object)) {
        $tokens += Split-MsvcOptionString $pragmaLinkerOption
    }

    $searchDirectories = @()
    $cacheable = $true
    foreach ($tokenValue in $tokens) {
        $token = ([string]$tokenValue).Trim()
        $unquotedToken = $token.Replace('"', '')
        if ($unquotedToken.StartsWith('@')) {
            # Response files may introduce arbitrary /LIBPATH and file inputs.
            $cacheable = $false
            continue
        }
        if ($unquotedToken -match '^[/-]LIBPATH:(.+)$') {
            $pathValue = $Matches[1].Trim('"')
            $candidate = if ([System.IO.Path]::IsPathRooted($pathValue)) {
                $pathValue
            } else {
                Join-Path $outputPath $pathValue
            }
            if (Test-Path -LiteralPath $candidate -PathType Container) {
                $resolved = (Resolve-Path -LiteralPath $candidate).Path
                if ($searchDirectories -notcontains $resolved) {
                    $searchDirectories += $resolved
                }
            }
        }
        if ($unquotedToken -match '^[/-](?:DEF|STUB):(.+)$') {
            $pathValue = $Matches[1].Trim('"')
            $candidate = if ([System.IO.Path]::IsPathRooted($pathValue)) {
                $pathValue
            } else {
                Join-Path $outputPath $pathValue
            }
            if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
                $cacheable = $false
            }
        }
        if ($unquotedToken -match '^[/-](?:ORDER|BASE):@') {
            # Includes /ORDER:@file, /BASE:@file, and equivalent indirect
            # inputs whose dependency closure is not parsed here.
            $cacheable = $false
        }
    }

    $libEnvironment = [Environment]::GetEnvironmentVariable("LIB", "Process")
    $libEntries = @($LibPath) + @($libEnvironment -split ';')
    foreach ($entry in $libEntries) {
        $directory = $entry.Trim().Trim('"')
        if (-not [string]::IsNullOrWhiteSpace($directory) -and
            (Test-Path -LiteralPath $directory -PathType Container)) {
            $resolved = (Resolve-Path -LiteralPath $directory).Path
            if ($searchDirectories -notcontains $resolved) {
                $searchDirectories += $resolved
            }
        }
    }

    $entries = @(
        "schema=otmatch-link-dependencies-v2",
        "lib=$libEnvironment",
        "link=$([Environment]::GetEnvironmentVariable('LINK', 'Process'))",
        "_link_=$([Environment]::GetEnvironmentVariable('_LINK_', 'Process'))",
        "search=$($searchDirectories -join [char]0x1f)"
    )
    $seenFiles = @{}
    $dependencySnapshots = @()
    foreach ($directory in $searchDirectories) {
        foreach ($library in @(Get-ChildItem -LiteralPath $directory -Filter *.lib -File |
                Sort-Object FullName)) {
            $seenFiles[$library.FullName] = $true
        }
    }

    foreach ($tokenValue in $tokens) {
        $token = ([string]$tokenValue).Trim().Trim('"')
        $candidate = ""
        $requiresResolvedFile = $false
        if ($token -match '^[/-](?:DEF|STUB):(.+)$') {
            $requiresResolvedFile = $true
            $pathValue = $Matches[1].Trim('"')
            $candidate = if ([System.IO.Path]::IsPathRooted($pathValue)) {
                $pathValue
            } else {
                Join-Path $outputPath $pathValue
            }
        } elseif ($token -match '^[/-]DEFAULTLIB:(.+)$') {
            $requiresResolvedFile = $true
            $token = $Matches[1].Trim('"')
            foreach ($directory in @($outputPath) + $searchDirectories) {
                $searchCandidate = Join-Path $directory $token
                if (Test-Path -LiteralPath $searchCandidate -PathType Leaf) {
                    $candidate = $searchCandidate
                    break
                }
            }
            if ([string]::IsNullOrWhiteSpace($candidate)) {
                $cacheable = $false
            }
        } elseif ($token -match '\.(?:lib|res|def|obj|exp)$') {
            $requiresResolvedFile = $true
            if ([System.IO.Path]::IsPathRooted($token)) {
                $candidate = $token
            } else {
                $workingCandidate = Join-Path $outputPath $token
                if (Test-Path -LiteralPath $workingCandidate -PathType Leaf) {
                    $candidate = $workingCandidate
                } else {
                    foreach ($directory in @($outputPath) + $searchDirectories) {
                        $searchCandidate = Join-Path $directory $token
                        if (Test-Path -LiteralPath $searchCandidate -PathType Leaf) {
                            $candidate = $searchCandidate
                            break
                        }
                    }
                }
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and
            (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            $seenFiles[(Resolve-Path -LiteralPath $candidate).Path] = $true
        } elseif ($requiresResolvedFile) {
            $cacheable = $false
        }
    }

    foreach ($pragmaLibrary in @($discoveredPragmaLibraries.Keys | Sort-Object)) {
        $candidate = ""
        if ([System.IO.Path]::IsPathRooted($pragmaLibrary)) {
            $candidate = $pragmaLibrary
        } else {
            foreach ($directory in @($outputPath) + $searchDirectories) {
                $searchCandidate = Join-Path $directory $pragmaLibrary
                if (Test-Path -LiteralPath $searchCandidate -PathType Leaf) {
                    $candidate = $searchCandidate
                    break
                }
            }
        }
        if ([string]::IsNullOrWhiteSpace($candidate) -or
            -not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            $cacheable = $false
        } else {
            $seenFiles[(Resolve-Path -LiteralPath $candidate).Path] = $true
        }
    }

    foreach ($path in @($seenFiles.Keys | Sort-Object)) {
        $inputHash = Get-ImmutableLinkInputHash $path -Fresh:$Fresh
        $entries += ($path.ToLowerInvariant() + "=" + $inputHash)
        $file = Get-Item -LiteralPath $path
        $dependencySnapshots += [pscustomobject]@{
            Path = $file.FullName
            Hash = $inputHash
            Length = [long]$file.Length
            LastWriteTimeUtcTicks = [long]$file.LastWriteTimeUtc.Ticks
        }
    }
    return [pscustomobject]@{
        Cacheable = $cacheable
        Fingerprint = Get-StringSha256Hex ($entries -join "`n")
        DependencySnapshots = @($dependencySnapshots)
    }
}

function Get-LinkFingerprint {
    param(
        [string]$Kind,
        [string[]]$Arguments,
        [string[]]$ObjectPaths,
        [hashtable]$PrecomputedObjectHashes = @{},
        [switch]$FreshDependencies
    )

    $dependencyFingerprint = Get-LinkDependencyFingerprint $Arguments -Fresh:$FreshDependencies
    $entries = @(
        "schema=otmatch-link-cache-v1",
        "kind=$Kind",
        "linker=$linkerFingerprint",
        "dependencies=$($dependencyFingerprint.Fingerprint)",
        "working_directory=$($outputPath.ToLowerInvariant())",
        "arguments=$($Arguments -join [char]0x1f)"
    )
    $dependencySnapshots = @($dependencyFingerprint.DependencySnapshots)
    foreach ($objectPath in $ObjectPaths) {
        $objectKey = (Resolve-Path -LiteralPath $objectPath).Path.ToLowerInvariant()
        $objectHash = if ($PrecomputedObjectHashes.ContainsKey($objectKey)) {
            [string]$PrecomputedObjectHashes[$objectKey]
        } else {
            Get-FileSha256Hex $objectPath
        }
        $entries += ((Split-Path -Leaf $objectPath) + "=" + $objectHash)
        $object = Get-Item -LiteralPath $objectPath
        $dependencySnapshots += [pscustomobject]@{
            Path = $object.FullName
            Hash = $objectHash
            Length = [long]$object.Length
            LastWriteTimeUtcTicks = [long]$object.LastWriteTimeUtc.Ticks
        }
    }
    return [pscustomobject]@{
        Cacheable = $dependencyFingerprint.Cacheable
        Fingerprint = Get-StringSha256Hex ($entries -join "`n")
        DependencySnapshots = @($dependencySnapshots)
    }
}

function Test-LinkCacheState {
    param(
        [string]$StatePath,
        [string]$Fingerprint,
        [string[]]$OutputFiles
    )

    if (-not (Test-Path -LiteralPath $StatePath -PathType Leaf)) {
        return $false
    }
    try {
        $state = [System.IO.File]::ReadAllText($StatePath) | ConvertFrom-Json
        if ([int]$state.version -ne 1 -or [string]$state.fingerprint -ne $Fingerprint) {
            return $false
        }
        $recordedOutputs = @($state.outputs)
        if ($recordedOutputs.Count -ne $OutputFiles.Count) {
            return $false
        }
        foreach ($outputFile in $OutputFiles) {
            if (-not (Test-Path -LiteralPath $outputFile -PathType Leaf)) {
                return $false
            }
            $name = Split-Path -Leaf $outputFile
            $record = @($recordedOutputs | Where-Object { $_.name -eq $name })
            if ($record.Count -ne 1 -or
                [string]$record[0].sha256 -ne (Get-FileSha256Hex $outputFile)) {
                return $false
            }
        }
        return $true
    } catch {
        Write-Warning "Ignoring invalid link-cache state '$StatePath': $($_.Exception.Message)"
        return $false
    }
}

function Write-LinkCacheState {
    param(
        [string]$StatePath,
        [string]$Fingerprint,
        [string[]]$OutputFiles
    )

    $outputs = @()
    foreach ($outputFile in $OutputFiles) {
        if (-not (Test-Path -LiteralPath $outputFile -PathType Leaf)) {
            throw "Link did not produce expected output '$outputFile'."
        }
        $outputs += [pscustomobject][ordered]@{
            name = Split-Path -Leaf $outputFile
            sha256 = Get-FileSha256Hex $outputFile
        }
    }
    $state = [pscustomobject][ordered]@{
        version = 1
        fingerprint = $Fingerprint
        outputs = $outputs
    }
    Write-TextAtomically $StatePath (($state | ConvertTo-Json -Depth 4) + "`n")
}

function Invoke-CachedLink {
    param(
        [string]$Kind,
        [string[]]$Arguments,
        [string[]]$ObjectPaths,
        [string[]]$OutputFiles,
        [hashtable]$PrecomputedObjectHashes = @{},
        [switch]$TrustPrecomputedObjectHashes,
        [switch]$Force
    )

    $statePath = Join-Path $outputPath ".otmatch-$Kind-link-cache.json"
    $fingerprintInfo = Get-LinkFingerprint `
        $Kind $Arguments $ObjectPaths $PrecomputedObjectHashes
    $stabilitySnapshots = if ($TrustPrecomputedObjectHashes) {
        @($fingerprintInfo.DependencySnapshots | Where-Object {
                -not $PrecomputedObjectHashes.ContainsKey(([string]$_.Path).ToLowerInvariant())
            })
    } else {
        @($fingerprintInfo.DependencySnapshots)
    }
    if ($fingerprintInfo.Cacheable -and -not $forceRebuild -and -not $Force -and
        -not $DisableIncrementalCache -and
        (Test-LinkCacheState $statePath $fingerprintInfo.Fingerprint $OutputFiles)) {
        $currentLinkerFingerprint = Get-DirectoryPayloadFingerprint $resolvedLinkerPath -Fresh
        if (-not (Test-DependencySnapshotsUnchanged $stabilitySnapshots -VerifyContent) -or
            $currentLinkerFingerprint -ne $linkerFingerprint) {
            throw "$Kind link inputs changed while cached outputs were being validated."
        }
        Write-Host ("Reusing {0} link outputs." -f $Kind)
        return
    }

    if (Test-Path -LiteralPath $statePath -PathType Leaf) {
        Remove-Item -LiteralPath $statePath -Force
    }
    foreach ($outputFile in $OutputFiles) {
        if (Test-Path -LiteralPath $outputFile -PathType Leaf) {
            Remove-Item -LiteralPath $outputFile -Force
        }
    }
    try {
        Invoke-LinkInWorkingDirectory `
            -LinkPath $toolchainConfig.Link `
            -Arguments $Arguments `
            -WorkingDirectory $outputPath
        if ($LASTEXITCODE -ne 0) {
            throw "$Kind candidate link failed with exit code $LASTEXITCODE."
        }
        foreach ($outputFile in $OutputFiles) {
            if (-not (Test-Path -LiteralPath $outputFile -PathType Leaf)) {
                throw "$Kind link did not produce expected output '$outputFile'."
            }
        }
        $currentLinkerFingerprint = Get-DirectoryPayloadFingerprint $resolvedLinkerPath -Fresh
        if (-not (Test-DependencySnapshotsUnchanged $stabilitySnapshots -VerifyContent) -or
            $currentLinkerFingerprint -ne $linkerFingerprint) {
            throw "$Kind link inputs changed while the linker was running."
        }
    } catch {
        foreach ($outputFile in $OutputFiles) {
            if (Test-Path -LiteralPath $outputFile -PathType Leaf) {
                Remove-Item -LiteralPath $outputFile -Force
            }
        }
        throw
    }
    if ($fingerprintInfo.Cacheable -and -not $DisableIncrementalCache) {
        Write-LinkCacheState $statePath $fingerprintInfo.Fingerprint $OutputFiles
    } elseif (-not $fingerprintInfo.Cacheable) {
        Write-Host ("{0} link cache bypassed because an indirect dependency flag is present." -f $Kind)
    }
}

function Invoke-CompanionCompile {
    param(
        [string]$Kind,
        [string]$SourcePath,
        [string]$ObjectPath,
        [string[]]$Arguments
    )

    $fingerprintInfo = Get-CompileFingerprint `
        -SourcePath $SourcePath `
        -ObjectName (Split-Path -Leaf $ObjectPath) `
        -CompileArguments $Arguments
    $script:compileDependencyRecords += [pscustomobject]@{
        Source = $SourcePath
        Snapshots = @($fingerprintInfo.DependencySnapshots)
    }
    if (-not $DisableIncrementalCache -and -not $forceRebuild -and
        $fingerprintInfo.Cacheable -and
        (Restore-CachedObject $fingerprintInfo.Fingerprint $ObjectPath)) {
        Write-Host ("Reusing {0} anchor object." -f $Kind)
        return
    }

    if (Test-Path -LiteralPath $ObjectPath -PathType Leaf) {
        Remove-Item -LiteralPath $ObjectPath -Force
    }
    & $toolchainConfig.Cl @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Kind anchor compilation failed with exit code $LASTEXITCODE."
    }
    if (-not (Test-Path -LiteralPath $ObjectPath -PathType Leaf)) {
        throw "Compiler did not produce expected object '$ObjectPath'."
    }
    Clear-CoffObjectTimestamp $ObjectPath
    if ($fingerprintInfo.Cacheable) {
        if (-not (Test-DependencySnapshotsUnchanged `
                $fingerprintInfo.DependencySnapshots -VerifyContent)) {
            throw "$Kind anchor dependencies changed while the compiler was running; object was not cached."
        }
        if (-not $DisableIncrementalCache) {
            Publish-CachedObject $fingerprintInfo.Fingerprint $ObjectPath
        }
    }
}

function Initialize-ModernVsToolchain {
    if (-not (Test-Path -LiteralPath $DevShell -PathType Leaf)) {
        throw "Visual Studio developer shell was not found at '$DevShell'. Override -DevShell or use -Toolchain LegacyMsvc."
    }

    $devShellOutput = & $DevShell -Arch x86 -HostArch amd64 -SkipAutomaticLocation 2>&1
    if ($LASTEXITCODE -ne 0) {
        $devShellOutput | ForEach-Object { Write-Host $_ }
        throw "Visual Studio developer shell failed with exit code $LASTEXITCODE."
    }

    $defaultOpt = if ([string]::IsNullOrWhiteSpace($DefaultOptimization)) { "/Od" } else { $DefaultOptimization }
    $semanticOpt = if ([string]::IsNullOrWhiteSpace($SemanticOptimization)) { "/O1" } else { $SemanticOptimization }

    return [pscustomobject]@{
        Cl = "cl.exe"
        Link = "link.exe"
        CompileFlags = @("/nologo", "/c", "/TP", "/Gd", "/GR-", "/GS-", "/arch:IA32", "/Ob0", "/Zl")
        LinkFlags = @("/nologo", "/DLL", "/NOENTRY", "/INCREMENTAL:NO", "/OPT:NOREF", "/OPT:NOICF", "/DEBUG")
        DefaultOptimization = $defaultOpt
        SemanticOptimization = $semanticOpt
    }
}

function Initialize-LegacyMsvcToolchain {
    $rootCandidates = @()
    if (-not [string]::IsNullOrWhiteSpace($VcToolsRoot)) {
        $root = (Resolve-Path -LiteralPath $VcToolsRoot).Path
        $rootCandidates += $root
        $rootCandidates += (Join-Path $root "MSDEV")
        $rootCandidates += (Join-Path $root "VC")
        $rootCandidates += (Join-Path $root "VC98")
    }

    if (-not [string]::IsNullOrWhiteSpace($ClPath)) {
        $clDirectory = Split-Path -Parent (Resolve-Path -LiteralPath $ClPath).Path
        $rootCandidates += (Split-Path -Parent $clDirectory)
    }

    $clCandidates = @()
    if (-not [string]::IsNullOrWhiteSpace($ClPath)) {
        $clCandidates += $ClPath
    }
    foreach ($rootCandidate in $rootCandidates) {
        $clCandidates += (Join-Path $rootCandidate "bin\cl.exe")
        $clCandidates += (Join-Path $rootCandidate "cl.exe")
    }
    $pathCl = Resolve-CommandPath "cl.exe"
    if (-not [string]::IsNullOrWhiteSpace($pathCl)) {
        $clCandidates += $pathCl
    }

    $linkCandidates = @()
    if (-not [string]::IsNullOrWhiteSpace($LinkPath)) {
        $linkCandidates += $LinkPath
    }
    foreach ($rootCandidate in $rootCandidates) {
        $linkCandidates += (Join-Path $rootCandidate "bin\link.exe")
        $linkCandidates += (Join-Path $rootCandidate "link.exe")
    }
    $pathLink = Resolve-CommandPath "link.exe"
    if (-not [string]::IsNullOrWhiteSpace($pathLink)) {
        $linkCandidates += $pathLink
    }

    $cl = Resolve-FirstExistingFile $clCandidates "Legacy MSVC cl.exe"
    $link = Resolve-FirstExistingFile $linkCandidates "Legacy MSVC link.exe"

    Prepend-EnvironmentList "PATH" @((Split-Path -Parent $cl), (Split-Path -Parent $link))

    $includeCandidates = @()
    if ($IncludePath.Count -gt 0) {
        $includeCandidates += $IncludePath
    } else {
        foreach ($rootCandidate in $rootCandidates) {
            $includeCandidates += (Join-Path $rootCandidate "include")
            $includeCandidates += (Join-Path $rootCandidate "atl\include")
            $includeCandidates += (Join-Path $rootCandidate "mfc\include")
        }
    }
    Prepend-EnvironmentList "INCLUDE" $includeCandidates

    $libCandidates = @()
    if ($LibPath.Count -gt 0) {
        $libCandidates += $LibPath
    } else {
        foreach ($rootCandidate in $rootCandidates) {
            $libCandidates += (Join-Path $rootCandidate "lib")
            $libCandidates += (Join-Path $rootCandidate "mfc\lib")
        }
    }
    Prepend-EnvironmentList "LIB" $libCandidates

    $defaultOpt = if ([string]::IsNullOrWhiteSpace($DefaultOptimization)) { "/Od" } else { $DefaultOptimization }
    $semanticOpt = if ([string]::IsNullOrWhiteSpace($SemanticOptimization)) { "/O1" } else { $SemanticOptimization }

    return [pscustomobject]@{
        Cl = $cl
        Link = $link
        CompileFlags = @("/nologo", "/c", "/Gd", "/Zl")
        LinkFlags = @("/nologo", "/DLL", "/NOENTRY", "/INCREMENTAL:NO", "/OPT:NOREF", "/DEBUG")
        DefaultOptimization = $defaultOpt
        SemanticOptimization = $semanticOpt
    }
}

function Get-RepoRelativePath {
    param([System.IO.FileInfo]$SourceFile)

    return $SourceFile.FullName.Substring($repoRoot.Length).TrimStart('\','/') -replace '/', '\'
}

function Get-MatchCandidateSortKey {
    param([System.IO.FileInfo]$SourceFile)

    $relative = Get-RepoRelativePath $SourceFile

    # Preserve the previous logical link order after moving WIP/probe files
    # into src/otwin/_recovery/. That keeps rel32 call distances stable unless a
    # row is intentionally reshaped.
    if ($relative -match '^src\\otwin\\_recovery\\root\\(.+)$') {
        return "src\otwin\$($Matches[1])"
    }
    if ($relative -match '^src\\otwin\\_recovery\\([^\\]+)\\(.+)$') {
        return "src\otwin\$($Matches[1])\$($Matches[2])"
    }

    return $relative
}

function New-SourceRecord {
    param(
        [System.IO.FileInfo]$SourceFile,
        [string]$Kind
    )

    return [pscustomobject]@{
        File = $SourceFile
        Kind = $Kind
        SortKey = Get-MatchCandidateSortKey $SourceFile
    }
}

function Get-OrdinallySortedSourceRecords {
    param([object[]]$Records)

    # Sort-Object uses host-specific culture collation. Windows PowerShell 5.1
    # and PowerShell 7 disagree about punctuation such as the dot before a file
    # extension versus an underscore suffix, which can silently reorder linker
    # inputs and invalidate a focused-build graph seeded by the other host.
    # Ordinal ordering preserves the established VC4 link order while making
    # the graph independent of the PowerShell host and current culture.
    $ordered = New-Object 'System.Collections.Generic.List[object]'
    foreach ($record in $Records) {
        [void]$ordered.Add($record)
    }
    $comparison = [System.Comparison[object]]{
        param($left, $right)

        $result = [System.StringComparer]::Ordinal.Compare(
            [string]$left.SortKey,
            [string]$right.SortKey)
        if ($result -ne 0) {
            return $result
        }
        return [System.StringComparer]::Ordinal.Compare(
            [string]$left.File.FullName,
            [string]$right.File.FullName)
    }
    $ordered.Sort($comparison)
    return @($ordered.ToArray())
}

function Get-CandidateObjectName {
    param([System.IO.FileInfo]$SourceFile)

    $relative = $SourceFile.FullName.Substring($repoRoot.Length).TrimStart('\','/')
    return (($relative -replace '[\\/]','_') -replace '\.cpp$','.obj')
}

function Get-FocusedBuildContextFingerprint {
    $fields = @(
        "schema=otmatch-focused-build-context-v1",
        "script=$(Get-FileSha256Hex $PSCommandPath)",
        "source_root=$($sourceRoot.ToLowerInvariant())",
        "toolchain=$Toolchain",
        "compiler_path=$($resolvedCompilerPath.ToLowerInvariant())",
        "compiler=$compilerFingerprint",
        "linker_path=$($resolvedLinkerPath.ToLowerInvariant())",
        "linker=$linkerFingerprint",
        "default_optimization=$DefaultOptimization",
        "semantic_optimization=$SemanticOptimization",
        "extra_compile=$($ExtraCompileFlags -join [char]0x1f)",
        "extra_link=$($ExtraLinkFlags -join [char]0x1f)",
        "tu_metadata=$tuMetadataSha256",
        "include_path=$($IncludePath -join [char]0x1f)",
        "lib_path=$($LibPath -join [char]0x1f)",
        "include=$([Environment]::GetEnvironmentVariable('INCLUDE', 'Process'))",
        "lib=$([Environment]::GetEnvironmentVariable('LIB', 'Process'))",
        "cl=$([Environment]::GetEnvironmentVariable('CL', 'Process'))",
        "_cl_=$([Environment]::GetEnvironmentVariable('_CL_', 'Process'))",
        "link=$([Environment]::GetEnvironmentVariable('LINK', 'Process'))",
        "_link_=$([Environment]::GetEnvironmentVariable('_LINK_', 'Process'))"
    )
    return Get-StringSha256Hex ($fields -join "`n")
}

function Initialize-TuMetadata {
    if ([string]::IsNullOrWhiteSpace($TuMetadataPath)) {
        return
    }

    $resolvedMetadataPath = if ([System.IO.Path]::IsPathRooted($TuMetadataPath)) {
        (Resolve-Path -LiteralPath $TuMetadataPath).Path
    } else {
        (Resolve-Path -LiteralPath (Join-Path $repoRoot $TuMetadataPath)).Path
    }
    $repoPrefix = $repoRoot.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    if (-not $resolvedMetadataPath.StartsWith(
            $repoPrefix,
            [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "TU metadata must remain inside the repository: '$resolvedMetadataPath'."
    }

    $script:tuMetadataSha256 = Get-FileSha256Hex $resolvedMetadataPath
    $rows = @(Import-Csv -LiteralPath $resolvedMetadataPath)
    foreach ($row in $rows) {
        $sourcePath = ([string]$row.source_path).Trim().Replace('\', '/')
        $flagsText = ([string]$row.extra_compile_flags).Trim()
        $reason = ([string]$row.reason).Trim()
        if ([string]::IsNullOrWhiteSpace($sourcePath) -or
            [System.IO.Path]::IsPathRooted($sourcePath) -or
            $sourcePath -notmatch '^.+\.cpp$' -or
            $sourcePath -match '(^|/)\.\.(/|$)') {
            throw "TU metadata contains an invalid repository source path: '$sourcePath'."
        }
        if ([string]::IsNullOrWhiteSpace($CandidateSourceRoot) -and
            $sourcePath -notmatch '^src/otwin/.+\.cpp$') {
            throw "Default-graph TU metadata must name src/otwin/**/*.cpp: '$sourcePath'."
        }
        if ([string]::IsNullOrWhiteSpace($flagsText) -or
            [string]::IsNullOrWhiteSpace($reason)) {
            throw "TU metadata row '$sourcePath' requires flags and a reason."
        }

        $sourceFullPath = [System.IO.Path]::GetFullPath(
            (Join-Path $repoRoot $sourcePath))
        $sourceRootPrefix = $sourceRoot.TrimEnd('\', '/') +
            [System.IO.Path]::DirectorySeparatorChar
        if (-not $sourceFullPath.StartsWith(
                $repoPrefix,
                [System.StringComparison]::OrdinalIgnoreCase) -or
            -not $sourceFullPath.StartsWith(
                $sourceRootPrefix,
                [System.StringComparison]::OrdinalIgnoreCase) -or
            -not (Test-Path -LiteralPath $sourceFullPath -PathType Leaf)) {
            throw "TU metadata source does not exist inside the candidate source root: '$sourcePath'."
        }
        $key = $sourceFullPath.ToLowerInvariant()
        if ($script:tuMetadataBySource.ContainsKey($key)) {
            throw "TU metadata contains duplicate source '$sourcePath'."
        }

        $flags = @($flagsText -split '\s+' | Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            })
        foreach ($flag in $flags) {
            if ($flag -notin @('/GX', '/Oy-')) {
                throw "TU metadata source '$sourcePath' uses unsupported flag '$flag'."
            }
        }
        $script:tuMetadataBySource[$key] = [pscustomobject]@{
            SourcePath = $sourcePath
            Flags = @($flags)
            Reason = $reason
        }
    }
}

function Get-CandidateGraphFingerprint {
    param([object[]]$Records)

    $entries = foreach ($record in $Records) {
        @(
            ([string]$record.File.FullName).ToLowerInvariant(),
            [string]$record.Kind,
            [string]$record.SortKey,
            (Get-CandidateObjectName $record.File)
        ) -join [char]0x1f
    }
    return Get-StringSha256Hex ($entries -join "`n")
}

function Read-FocusedBuildState {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Focused changed-source mode requires a seeded full candidate build state at '$Path'."
    }
    try {
        $state = [System.IO.File]::ReadAllText($Path) | ConvertFrom-Json
    } catch {
        throw "Focused candidate build state is invalid: $($_.Exception.Message)"
    }
    if ([int]$state.schema_version -ne 1) {
        throw "Unsupported focused candidate build state schema at '$Path'."
    }
    return $state
}

function Get-OutputHashRecords {
    param([string[]]$Paths)

    $records = @()
    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Expected candidate output is missing: '$path'."
        }
        $records += [pscustomobject][ordered]@{
            path = (Resolve-Path -LiteralPath $path).Path
            length = [long](Get-Item -LiteralPath $path).Length
            sha256 = Get-FileSha256Hex $path
        }
    }
    return $records
}

function New-CandidateBuildStateRecord {
    param(
        $SourceRecord,
        [string]$ObjectName,
        [string]$ObjectPath,
        $FingerprintInfo
    )

    return [pscustomobject][ordered]@{
        source = [string]$SourceRecord.File.FullName
        kind = [string]$SourceRecord.Kind
        sort_key = [string]$SourceRecord.SortKey
        object_name = $ObjectName
        object_length = [long](Get-Item -LiteralPath $ObjectPath).Length
        object_sha256 = Get-FileSha256Hex $ObjectPath
        has_sections = [bool](Test-CoffObjectHasSections $ObjectPath)
        compile_fingerprint = [string]$FingerprintInfo.Fingerprint
        dependency_snapshots = @($FingerprintInfo.DependencySnapshots)
        pragma_libraries = @($FingerprintInfo.PragmaLibraries)
        pragma_linker_options = @($FingerprintInfo.PragmaLinkerOptions)
    }
}

Initialize-TuMetadata

$candidateGraphLockPath = Join-Path $repoRoot "artifacts\otmatch\.candidate-graph.lock"
$candidateGraphLockStream = $null
if (-not $CandidateGraphLockHeld) {
    $candidateGraphLockStream = Enter-SharedFileLock `
        -Path $candidateGraphLockPath `
        -TimeoutSeconds $BuildLockTimeoutSeconds `
        -Description "candidate source graph"
}
$buildLockStream = $null
$cacheRootLockStream = $null
try {
$sourceRecords = @()

$productFiles = Get-ChildItem -LiteralPath $sourceRoot -Filter *.cpp -File -Recurse |
    Where-Object {
        $_.Name -notlike '*_notes.cpp' -and
        $_.FullName -notlike "*\src\otwin\_exact\*" -and
        $_.FullName -notlike "*\src\otwin\_recovery\*"
    }
foreach ($sourceFile in $productFiles) {
    $sourceRecords += New-SourceRecord $sourceFile "product"
}

$recoveryRoot = Join-Path $sourceRoot "_recovery"
if (Test-Path -LiteralPath $recoveryRoot -PathType Container) {
    $recoveryFiles = Get-ChildItem -LiteralPath $recoveryRoot -Filter *.cpp -File -Recurse |
        Where-Object { $_.Name -notlike '*_notes.cpp' }
    foreach ($sourceFile in $recoveryFiles) {
        $sourceRecords += New-SourceRecord $sourceFile "recovery"
    }
}

$exactRoot = Join-Path $sourceRoot "_exact"
if (Test-Path -LiteralPath $exactRoot -PathType Container) {
    $exactFiles = Get-ChildItem -LiteralPath $exactRoot -Filter *.cpp -File -Recurse |
        Where-Object { $_.Name -notlike '*_notes.cpp' }
    foreach ($sourceFile in $exactFiles) {
        $sourceRecords += New-SourceRecord $sourceFile "exact"
    }
}

$sourceRecords += [pscustomobject]@{
    File = Get-Item -LiteralPath $anchorFile
    Kind = "anchor"
    SortKey = Get-RepoRelativePath (Get-Item -LiteralPath $anchorFile)
}

$sourceRecords = @(Get-OrdinallySortedSourceRecords @($sourceRecords))

if ($sourceRecords.Count -eq 0) {
    throw "No match candidate source files were found under src/otwin/."
}

$candidateSourceSet = @{}
foreach ($sourceRecord in $sourceRecords) {
    $candidateSourceSet[$sourceRecord.File.FullName.ToLowerInvariant()] = $true
}
foreach ($metadataKey in $tuMetadataBySource.Keys) {
    if (-not $candidateSourceSet.ContainsKey($metadataKey)) {
        throw ("TU metadata source is not part of the candidate graph: '{0}'." -f
            $tuMetadataBySource[$metadataKey].SourcePath)
    }
}

New-Item -ItemType Directory -Force -Path $outputPath | Out-Null
$buildLockPath = Join-Path $outputPath ".otmatch-build.lock"
$buildLockStream = Enter-ExclusiveFileLock `
        -Path $buildLockPath `
        -TimeoutSeconds $BuildLockTimeoutSeconds `
        -Description "candidate output"

if ($Toolchain -eq "ModernVs") {
    $toolchainConfig = Initialize-ModernVsToolchain
} else {
    $toolchainConfig = Initialize-LegacyMsvcToolchain
}

Write-Host "Using match-candidate toolchain:"
Write-Host "  Mode: $Toolchain"
Write-Host "  CL:   $($toolchainConfig.Cl)"
Write-Host "  LINK: $($toolchainConfig.Link)"

$resolvedCompilerPath = if (Test-Path -LiteralPath $toolchainConfig.Cl -PathType Leaf) {
    (Resolve-Path -LiteralPath $toolchainConfig.Cl).Path
} else {
    Resolve-CommandPath $toolchainConfig.Cl
}
$resolvedLinkerPath = if (Test-Path -LiteralPath $toolchainConfig.Link -PathType Leaf) {
    (Resolve-Path -LiteralPath $toolchainConfig.Link).Path
} else {
    Resolve-CommandPath $toolchainConfig.Link
}
if ([string]::IsNullOrWhiteSpace($resolvedCompilerPath) -or
    [string]::IsNullOrWhiteSpace($resolvedLinkerPath)) {
    throw "Could not resolve compiler/linker paths for cache fingerprinting."
}
$toolDirectoryFingerprintCache = @{}
$compilerFingerprint = Get-DirectoryPayloadFingerprint $resolvedCompilerPath
$linkerFingerprint = Get-DirectoryPayloadFingerprint $resolvedLinkerPath
$environmentIncludeSearchPaths = @(Get-IncludeSearchPaths)
$directDependencyCache = @{}
$discoveredPragmaLibraries = @{}
$discoveredPragmaLinkerOptions = @{}
$linkInputHashCache = @{}
$forceRebuild = ($Rebuild -or $CleanObjectCache)

$objectCacheRoot = Resolve-RepoOwnedDirectory $ObjectCacheDirectory "Candidate object cache"
$cacheRootLockPath = "$objectCacheRoot.otmatch-cache.lock"
if ($CleanObjectCache) {
    $cacheRootLockStream = Enter-ExclusiveFileLock `
        -Path $cacheRootLockPath `
        -TimeoutSeconds $BuildLockTimeoutSeconds `
        -Description "candidate object cache mutation"
} elseif (-not $DisableIncrementalCache) {
    $cacheRootLockStream = Enter-SharedFileLock `
        -Path $cacheRootLockPath `
        -TimeoutSeconds $BuildLockTimeoutSeconds `
        -Description "candidate object cache"
}
$cacheMarkerPath = Join-Path $objectCacheRoot ".otmatch-candidate-cache-v1"
if ($CleanObjectCache -and (Test-Path -LiteralPath $objectCacheRoot -PathType Container)) {
    if (-not (Test-Path -LiteralPath $cacheMarkerPath -PathType Leaf)) {
        throw "Refusing to clean unmarked candidate cache '$objectCacheRoot'."
    }
    Remove-Item -LiteralPath $objectCacheRoot -Recurse -Force
}
if (-not $DisableIncrementalCache) {
    if ((Test-Path -LiteralPath $objectCacheRoot -PathType Container) -and
        -not (Test-Path -LiteralPath $cacheMarkerPath -PathType Leaf)) {
        $unownedEntries = @(Get-ChildItem -LiteralPath $objectCacheRoot -Force)
        if ($unownedEntries.Count -ne 0) {
            throw "Refusing to adopt non-empty unmarked candidate cache '$objectCacheRoot'."
        }
    }
    [void][System.IO.Directory]::CreateDirectory($objectCacheRoot)
    if (-not (Test-Path -LiteralPath $cacheMarkerPath -PathType Leaf)) {
        Write-TextAtomically $cacheMarkerPath "otmatch candidate cache v1`n"
    }
}

$changedSourceSet = @{}
foreach ($changedSourceEntry in $ChangedSource) {
    if ([string]::IsNullOrWhiteSpace($changedSourceEntry)) {
        continue
    }
    $changedSourcePath = if ([System.IO.Path]::IsPathRooted($changedSourceEntry)) {
        (Resolve-Path -LiteralPath $changedSourceEntry).Path
    } else {
        (Resolve-Path -LiteralPath (Join-Path $repoRoot $changedSourceEntry)).Path
    }
    $changedSourceSet[$changedSourcePath] = $true
}
if ($changedSourceSet.Count -ne 0) {
    $knownSourceSet = @{}
    foreach ($sourceRecord in $sourceRecords) {
        $knownSourceSet[$sourceRecord.File.FullName] = $true
    }
    foreach ($changedSourcePath in $changedSourceSet.Keys) {
        if (-not $knownSourceSet.ContainsKey($changedSourcePath)) {
            throw "Changed source is not part of the candidate graph: '$changedSourcePath'."
        }
    }
}

$focusedBuildStatePath = Join-Path $outputPath ".otmatch-focused-build-state.json"
$focusedBuildState = $null
$focusedRecordBySource = @{}
$focusedTargetPath = ""
$focusedContextFingerprint = Get-FocusedBuildContextFingerprint
$candidateGraphFingerprint = Get-CandidateGraphFingerprint @($sourceRecords)
$mainPdbPath = $dllPath -replace '\.dll$', '.pdb'
$mainLibPath = $dllPath -replace '\.dll$', '.lib'
$mainExpPath = $dllPath -replace '\.dll$', '.exp'
$mainOutputPaths = @($dllPath, $mapPath, $mainPdbPath, $mainLibPath, $mainExpPath)

if ($FocusedChangedSource) {
    if (-not $CandidateGraphLockHeld) {
        throw "Focused changed-source mode is available only while the caller holds the exclusive candidate-graph lock."
    }
    if ($Rebuild -or $CleanObjectCache -or $DisableIncrementalCache) {
        throw "Focused changed-source mode cannot be combined with rebuild, cache cleaning, or cache disabling."
    }
    if ($changedSourceSet.Count -ne 1) {
        throw "Focused changed-source mode requires exactly one ChangedSource entry."
    }
    $focusedTargetPath = [string]@($changedSourceSet.Keys)[0]
    $focusedBuildState = Read-FocusedBuildState $focusedBuildStatePath
    if ([string]$focusedBuildState.context_fingerprint -ne $focusedContextFingerprint) {
        throw "Focused candidate build context changed; run a normal full-graph candidate build to reseed the focused state."
    }
    if ([string]$focusedBuildState.graph_fingerprint -ne $candidateGraphFingerprint -or
        @($focusedBuildState.sources).Count -ne @($sourceRecords).Count) {
        throw "Focused candidate source graph changed; run a normal full-graph candidate build to reseed the focused state."
    }

    $untouchedSnapshots = @{}
    $trustedObjectHasher = if ($FocusedGraphAlreadyValidated) {
        [System.Security.Cryptography.SHA256]::Create()
    } else {
        $null
    }
    try {
        foreach ($stateRecord in @($focusedBuildState.sources)) {
            $stateSource = [string]$stateRecord.source
            $stateKey = $stateSource.ToLowerInvariant()
            if ($focusedRecordBySource.ContainsKey($stateKey)) {
                throw "Focused candidate build state contains duplicate source '$stateSource'."
            }
            $focusedRecordBySource[$stateKey] = $stateRecord
            if ($stateSource.Equals($focusedTargetPath, [System.StringComparison]::OrdinalIgnoreCase)) {
                continue
            }

            $stateObjectPath = Join-Path $outputPath ([string]$stateRecord.object_name)
            $stateObjectValid = if ($FocusedGraphAlreadyValidated) {
                Test-FileMatchesSha256 `
                    -Path $stateObjectPath `
                    -ExpectedLength ([long]$stateRecord.object_length) `
                    -ExpectedSha256 ([string]$stateRecord.object_sha256) `
                    -Hasher $trustedObjectHasher
            } elseif (Test-Path -LiteralPath $stateObjectPath -PathType Leaf) {
                (Get-FileSha256Hex $stateObjectPath) -eq
                    [string]$stateRecord.object_sha256
            } else {
                $false
            }
            if (-not $stateObjectValid) {
                throw "Focused candidate object changed or is missing for untouched source '$stateSource'."
            }
            if (-not $FocusedGraphAlreadyValidated) {
                foreach ($snapshot in @($stateRecord.dependency_snapshots)) {
                    $snapshotPath = [string]$snapshot.Path
                    if ($snapshotPath.Equals($focusedTargetPath, [System.StringComparison]::OrdinalIgnoreCase)) {
                        throw "Focused source '$focusedTargetPath' is included by untouched source '$stateSource'; a focused build would be unsafe."
                    }
                    $snapshotKey = $snapshotPath.ToLowerInvariant()
                    if ($untouchedSnapshots.ContainsKey($snapshotKey) -and
                        [string]$untouchedSnapshots[$snapshotKey].Hash -ne [string]$snapshot.Hash) {
                        throw "Focused candidate state has conflicting dependency hashes for '$snapshotPath'."
                    }
                    $untouchedSnapshots[$snapshotKey] = $snapshot
                }
            }
            foreach ($library in @($stateRecord.pragma_libraries)) {
                $discoveredPragmaLibraries[[string]$library] = $true
            }
            foreach ($option in @($stateRecord.pragma_linker_options)) {
                $discoveredPragmaLinkerOptions[[string]$option] = $true
            }
        }
    } finally {
        if ($null -ne $trustedObjectHasher) {
            $trustedObjectHasher.Dispose()
        }
    }
    if (-not $focusedRecordBySource.ContainsKey($focusedTargetPath.ToLowerInvariant())) {
        throw "Focused source '$focusedTargetPath' is missing from the seeded candidate state."
    }
    if (-not $FocusedGraphAlreadyValidated -and
        -not (Test-DependencySnapshotsUnchanged @($untouchedSnapshots.Values) -VerifyContent)) {
        throw "An untouched candidate source/header changed; focused mode refuses to reuse the seeded graph."
    }
    if (@($focusedBuildState.main_outputs).Count -ne $mainOutputPaths.Count) {
        throw "Focused candidate state does not bind every main link output."
    }
    Write-Host ("Focused candidate mode: validating and compiling only {0}" -f
        (Get-RepoRelativePath (Get-Item -LiteralPath $focusedTargetPath)))
} elseif ($FocusedGraphAlreadyValidated) {
    throw "FocusedGraphAlreadyValidated is valid only with FocusedChangedSource."
} elseif ($ForceMainRelink) {
    throw "ForceMainRelink is valid only with FocusedChangedSource."
}

$cacheHitCount = 0
$compiledCount = 0
$forcedCompileCount = 0
$uncacheableCount = 0
$focusedObjectReuseCount = 0
$compileDependencyRecords = @()
$candidateBuildStateRecords = @()

$objectPaths = @()
foreach ($sourceRecord in $sourceRecords) {
    $sourceFile = $sourceRecord.File
    # Multiple files share a BaseName across subsystem folders (e.g.
    # _exact/app/exact_promotions.cpp and _exact/graphics/exact_promotions.cpp),
    # so derive the .obj name from the path relative to the repo root with
    # separators flattened to underscores.
    $objectName = Get-CandidateObjectName $sourceFile
    $objectPath = Join-Path $outputPath $objectName
    $objectPaths += $objectPath

    if ($FocusedChangedSource -and
        -not $sourceFile.FullName.Equals($focusedTargetPath, [System.StringComparison]::OrdinalIgnoreCase)) {
        $stateRecord = $focusedRecordBySource[$sourceFile.FullName.ToLowerInvariant()]
        if (-not $FocusedGraphAlreadyValidated) {
            $compileDependencyRecords += [pscustomobject]@{
                Source = $sourceFile.FullName
                Snapshots = @($stateRecord.dependency_snapshots)
            }
        }
        $candidateBuildStateRecords += $stateRecord
        $focusedObjectReuseCount++
        continue
    }

    # Opt selection: scaffolds with __declspec(naked) + _emit byte sequences
    # (the auto-generated coverage/small-stub files under _exact/generated/)
    # build at $DefaultOptimization (typically /Od). Everything else --
    # including readable promoted C++ that lives under _exact/<sub>/ -- compiles
    # at $SemanticOptimization (typically /O1) so VC4's short-jump peephole
    # encoding matches the original release codegen.
    if ($sourceFile.FullName -like "*\src\otwin\_exact\generated\*") {
        $optimizationFlag = $toolchainConfig.DefaultOptimization
    } else {
        $optimizationFlag = $toolchainConfig.SemanticOptimization
    }

    $compileArgs = @()
    $compileArgs += $toolchainConfig.CompileFlags
    $compileArgs += $optimizationFlag
    $tuMetadataKey = $sourceFile.FullName.ToLowerInvariant()
    if ($tuMetadataBySource.ContainsKey($tuMetadataKey)) {
        $compileArgs += @($tuMetadataBySource[$tuMetadataKey].Flags)
    }
    $compileArgs += $ExtraCompileFlags
    $compileArgs += "/Fo$objectPath"
    $compileArgs += $sourceFile.FullName

    $compileFingerprintInfo = Get-CompileFingerprint `
        -SourcePath $sourceFile.FullName `
        -ObjectName $objectName `
        -CompileArguments $compileArgs
    $compileDependencyRecords += [pscustomobject]@{
        Source = $sourceFile.FullName
        Snapshots = @($compileFingerprintInfo.DependencySnapshots)
    }
    $forceSourceCompile = ($forceRebuild -or
        $changedSourceSet.ContainsKey($sourceFile.FullName))
    $restoredFromCache = $false
    if (-not $DisableIncrementalCache -and
        $compileFingerprintInfo.Cacheable -and
        -not $forceSourceCompile) {
        $restoredFromCache = Restore-CachedObject `
            $compileFingerprintInfo.Fingerprint $objectPath
    }

    if ($restoredFromCache) {
        $cacheHitCount++
        $candidateBuildStateRecords += New-CandidateBuildStateRecord `
            $sourceRecord $objectName $objectPath $compileFingerprintInfo
        continue
    }
    if ($forceSourceCompile) {
        $forcedCompileCount++
    }
    if (-not $compileFingerprintInfo.Cacheable) {
        $uncacheableCount++
        Write-Host ("Candidate object cache bypass: {0}: {1}" -f
            (Get-RepoRelativePath $sourceFile),
            ($compileFingerprintInfo.Reasons -join "; "))
    }

    if (Test-Path -LiteralPath $objectPath -PathType Leaf) {
        Remove-Item -LiteralPath $objectPath -Force
    }
    & $toolchainConfig.Cl @compileArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Candidate compilation failed for '$($sourceFile.FullName)' with exit code $LASTEXITCODE."
    }
    if (-not (Test-Path -LiteralPath $objectPath -PathType Leaf)) {
        throw "Compiler did not produce expected object '$objectPath'."
    }
    Clear-CoffObjectTimestamp $objectPath
    $compiledCount++
    if ($compileFingerprintInfo.Cacheable) {
        if (-not (Test-DependencySnapshotsUnchanged `
                $compileFingerprintInfo.DependencySnapshots -VerifyContent)) {
            throw "Dependencies changed while compiling '$($sourceFile.FullName)'; object was not cached."
        }
        if (-not $DisableIncrementalCache) {
            Publish-CachedObject $compileFingerprintInfo.Fingerprint $objectPath
        }
    }
    $candidateBuildStateRecords += New-CandidateBuildStateRecord `
        $sourceRecord $objectName $objectPath $compileFingerprintInfo
}

Write-Host ("Candidate object cache: {0} hit(s), {1} compile(s), {2} forced, {3} uncacheable." -f
    $cacheHitCount, $compiledCount, $forcedCompileCount, $uncacheableCount)
if ($FocusedChangedSource) {
    Write-Host ("Focused candidate objects: {0} validated local reuse, {1} compile." -f
        $focusedObjectReuseCount, $compiledCount)
}

# Detect graph edits made after an early cache hit and before link. This matters
# in multi-agent sessions where another process can modify a TU during the
# 500-object scan even though source-shape runners cooperate via the graph lock.
if (-not $FocusedGraphAlreadyValidated) {
    Assert-CandidateCompileInputsStable
}

# A large recovery tree contains intentionally disabled probe translation units
# that compile to sectionless COFF files (only a .file debug symbol). They make
# no contribution to the image, but spelling all of their long filenames on a
# VC4 link command can overflow the old linker's exports-file pass. Preserve
# compilation coverage while omitting only objects that provably have zero
# COFF sections from the link input list.
$linkObjectPaths = @(
    foreach ($stateRecord in $candidateBuildStateRecords) {
        if ([bool]$stateRecord.has_sections) {
            Join-Path $outputPath ([string]$stateRecord.object_name)
        }
    }
)
$sectionlessObjectCount = $objectPaths.Count - $linkObjectPaths.Count
Write-Host ("Omitting {0} sectionless COFF object(s) from the link input list." -f
    $sectionlessObjectCount)
$focusedLinkObjectHashes = @{}
if ($FocusedChangedSource) {
    foreach ($stateRecord in $candidateBuildStateRecords) {
        if (-not [bool]$stateRecord.has_sections) {
            continue
        }
        $stateObjectPath = (Resolve-Path -LiteralPath (Join-Path $outputPath ([string]$stateRecord.object_name))).Path
        $focusedLinkObjectHashes[$stateObjectPath.ToLowerInvariant()] = [string]$stateRecord.object_sha256
    }
}

$linkArgs = @()
$linkArgs += $toolchainConfig.LinkFlags
$linkArgs += $ExtraLinkFlags
$linkArgs += "/MAP:$(Split-Path -Leaf $mapPath)"
$mainPdbPath = $dllPath -replace '\.dll$', '.pdb'
$mainLibPath = $dllPath -replace '\.dll$', '.lib'
$mainExpPath = $dllPath -replace '\.dll$', '.exp'
$linkArgs += "/PDB:$(Split-Path -Leaf $mainPdbPath)"
$linkArgs += "/OUT:$(Split-Path -Leaf $dllPath)"

# Resolve the forced WinMain CRT anchor before LIBC.LIB sees semantic bodies
# that reference startup-owned globals such as __error_mode.  Without this
# command-line force, the library can extract crt0.obj first and later extract
# wincrt0.obj for the anchor pragma, producing duplicate startup globals.  Keep
# the established candidate-object order unchanged because candidate_rva rows
# and compiler-generated funclet layout depend on that order.
$linkArgs += "/INCLUDE:_WinMainCRTStartup"
$linkArgs += ($linkObjectPaths | ForEach-Object { Split-Path -Leaf $_ })

Invoke-CachedLink `
    -Kind "main" `
    -Arguments $linkArgs `
    -ObjectPaths $linkObjectPaths `
    -OutputFiles @($dllPath, $mapPath, $mainPdbPath, $mainLibPath, $mainExpPath) `
    -PrecomputedObjectHashes $focusedLinkObjectHashes `
    -TrustPrecomputedObjectHashes:$FocusedGraphAlreadyValidated `
    -Force:$ForceMainRelink

Write-Host "Match candidate PE:"
Write-Host "  $dllPath"
Write-Host "Map file:"
Write-Host "  $mapPath"

if (-not $FocusedChangedSource) {
# Companion LCMT match-candidate DLL: just the LIBCMT anchor file. Built
# separately because LIBC.LIB and LIBCMT.LIB export the same symbols with
# different bytes, so they cannot coexist in one link image. Manifest rows
# whose original PE is OREGON32.DLL select this DLL via candidate_dll=lcmt.
$lcmtObjectPath = Join-Path $outputPath "match_dll_anchors_lcmt.obj"
$lcmtCompileArgs = @()
$lcmtCompileArgs += $toolchainConfig.CompileFlags
$lcmtCompileArgs += $toolchainConfig.SemanticOptimization
$lcmtCompileArgs += $ExtraCompileFlags
$lcmtCompileArgs += "/Fo$lcmtObjectPath"
$lcmtCompileArgs += $lcmtAnchorFile

Invoke-CompanionCompile `
    -Kind "LCMT" `
    -SourcePath $lcmtAnchorFile `
    -ObjectPath $lcmtObjectPath `
    -Arguments $lcmtCompileArgs

$lcmtLinkArgs = @()
$lcmtLinkArgs += $toolchainConfig.LinkFlags
$lcmtLinkArgs += $ExtraLinkFlags
$lcmtLinkArgs += "/MAP:$(Split-Path -Leaf $lcmtMapPath)"
$lcmtPdbPath = $lcmtDllPath -replace '\.dll$', '.pdb'
$lcmtLinkArgs += "/PDB:$(Split-Path -Leaf $lcmtPdbPath)"
$lcmtLinkArgs += "/OUT:$(Split-Path -Leaf $lcmtDllPath)"
$lcmtLinkArgs += (Split-Path -Leaf $lcmtObjectPath)

Invoke-CachedLink `
    -Kind "lcmt" `
    -Arguments $lcmtLinkArgs `
    -ObjectPaths @($lcmtObjectPath) `
    -OutputFiles @($lcmtDllPath, $lcmtMapPath, $lcmtPdbPath)

Write-Host "LCMT match candidate PE:"
Write-Host "  $lcmtDllPath"
Write-Host "Map file:"
Write-Host "  $lcmtMapPath"

# Third companion: dllcrt0-anchored DLL for _DllMainCRTStartup@12 +
# _CRT_INIT@12 (and any other dllcrt0.obj symbols). Built isolated from
# the main and LCMT candidates because dllcrt0.obj defines the same
# globals as crt0.obj, which the LCMT candidate's __amsg_exit anchor
# pulls in. Manifest rows reach this DLL via candidate_dll=dllcrt.
$dllcrtObjectPath = Join-Path $outputPath "match_dll_anchors_dllcrt.obj"
$dllcrtCompileArgs = @()
$dllcrtCompileArgs += $toolchainConfig.CompileFlags
$dllcrtCompileArgs += $toolchainConfig.SemanticOptimization
$dllcrtCompileArgs += $ExtraCompileFlags
$dllcrtCompileArgs += "/Fo$dllcrtObjectPath"
$dllcrtCompileArgs += $dllcrtAnchorFile

Invoke-CompanionCompile `
    -Kind "DLLCRT" `
    -SourcePath $dllcrtAnchorFile `
    -ObjectPath $dllcrtObjectPath `
    -Arguments $dllcrtCompileArgs

$dllcrtLinkArgs = @()
$dllcrtLinkArgs += $toolchainConfig.LinkFlags
$dllcrtLinkArgs += $ExtraLinkFlags
$dllcrtLinkArgs += "/MAP:$(Split-Path -Leaf $dllcrtMapPath)"
$dllcrtPdbPath = $dllcrtDllPath -replace '\.dll$', '.pdb'
$dllcrtLinkArgs += "/PDB:$(Split-Path -Leaf $dllcrtPdbPath)"
$dllcrtLinkArgs += "/OUT:$(Split-Path -Leaf $dllcrtDllPath)"
$dllcrtLinkArgs += (Split-Path -Leaf $dllcrtObjectPath)

Invoke-CachedLink `
    -Kind "dllcrt" `
    -Arguments $dllcrtLinkArgs `
    -ObjectPaths @($dllcrtObjectPath) `
    -OutputFiles @($dllcrtDllPath, $dllcrtMapPath, $dllcrtPdbPath)

Write-Host "DLLCRT match candidate PE:"
Write-Host "  $dllcrtDllPath"
Write-Host "Map file:"
Write-Host "  $dllcrtMapPath"
} else {
    Write-Host "Focused candidate mode skipped LCMT and DLLCRT companion builds."
}
if ($FocusedGraphAlreadyValidated) {
    $focusedTargetSnapshots = @()
    foreach ($record in $compileDependencyRecords) {
        $focusedTargetSnapshots += @($record.Snapshots)
    }
    if (-not (Test-DependencySnapshotsUnchanged $focusedTargetSnapshots -VerifyContent)) {
        throw "Focused source/header content changed during the diagnostic build."
    }
} else {
    Assert-CandidateCompileInputsStable
}

if (-not $FocusedGraphAlreadyValidated) {
    $focusedState = [pscustomobject][ordered]@{
        schema_version = 1
        context_fingerprint = $focusedContextFingerprint
        graph_fingerprint = $candidateGraphFingerprint
        generated_utc = [DateTime]::UtcNow.ToString("o")
        sources = @($candidateBuildStateRecords)
        main_outputs = @(Get-OutputHashRecords $mainOutputPaths)
    }
    Write-TextAtomically $focusedBuildStatePath (($focusedState | ConvertTo-Json -Depth 8) + "`n")
} else {
    Write-Host "Focused diagnostic iteration retained the immutable lane-boundary state."
}
} finally {
    if ($null -ne $buildLockStream) {
        $buildLockStream.Dispose()
    }
    if ($null -ne $cacheRootLockStream) {
        $cacheRootLockStream.Dispose()
    }
    if ($null -ne $candidateGraphLockStream) {
        $candidateGraphLockStream.Dispose()
    }
}
