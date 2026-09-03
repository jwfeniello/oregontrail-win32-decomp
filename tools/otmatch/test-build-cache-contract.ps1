param(
    [switch]$KeepFixture
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$buildScript = Join-Path $PSScriptRoot "build-match-candidates.ps1"
$variantScript = Join-Path $PSScriptRoot "invoke-source-shape-variants.ps1"
$fixtureRoot = Join-Path $repoRoot ("a\build-cache-contract-{0}" -f [Guid]::NewGuid().ToString("N"))

function Assert-Contract {
    param(
        [bool]$Condition,
        [string]$Message
    )
    if (-not $Condition) {
        throw "Build-cache contract failure: $Message"
    }
}

function Write-Utf8Text {
    param(
        [string]$Path,
        [string]$Text
    )
    [void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $Path))
    [System.IO.File]::WriteAllText(
        $Path,
        $Text,
        (New-Object System.Text.UTF8Encoding($false)))
}

function Get-LineCount {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return 0
    }
    return @(Get-Content -LiteralPath $Path).Count
}

function Invoke-ContractBuild {
    param(
        [string[]]$AdditionalArguments = @(),
        [string]$CacheDirectoryOverride = "",
        [string]$OutputDirectoryOverride = "",
        [string]$PowerShellExecutable = "powershell.exe"
    )
    $selectedCacheDirectory = if ([string]::IsNullOrWhiteSpace($CacheDirectoryOverride)) {
        $cacheRelative
    } else {
        $CacheDirectoryOverride
    }
    $selectedOutputDirectory = if ([string]::IsNullOrWhiteSpace($OutputDirectoryOverride)) {
        $outputRelative
    } else {
        $OutputDirectoryOverride
    }
    $arguments = @(
        "-NoProfile", "-ExecutionPolicy", "Bypass",
        "-File", $buildScript,
        "-Toolchain", "LegacyMsvc",
        "-ClPath", $fakeCompiler,
        "-LinkPath", $fakeLinker,
        "-IncludePath", $includeRoot,
        "-LibPath", $libRoot,
        "-OutputDirectory", $selectedOutputDirectory,
        "-ObjectCacheDirectory", $selectedCacheDirectory,
        "-CandidateSourceRoot", $sourceRoot,
        "-DefaultOptimization", "/Od",
        "-SemanticOptimization", "/O1"
    )
    $arguments += $AdditionalArguments
    $output = & $PowerShellExecutable @arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Contract candidate build failed:`n$($output | Out-String)"
    }
    return ($output | Out-String)
}

[void][System.IO.Directory]::CreateDirectory($fixtureRoot)
$oldCompilerLog = [Environment]::GetEnvironmentVariable("OTMATCH_FAKE_CL_LOG", "Process")
$oldLinkerLog = [Environment]::GetEnvironmentVariable("OTMATCH_FAKE_LINK_LOG", "Process")
$oldCandidatePath = [Environment]::GetEnvironmentVariable("OTMATCH_FAKE_CANDIDATE", "Process")
$oldMapPath = [Environment]::GetEnvironmentVariable("OTMATCH_FAKE_MAP", "Process")
$oldVariantBuildLog = [Environment]::GetEnvironmentVariable("OTMATCH_VARIANT_BUILD_LOG", "Process")
$oldVariantDiffLog = [Environment]::GetEnvironmentVariable("OTMATCH_VARIANT_DIFF_LOG", "Process")
$oldFakeDiffFail = [Environment]::GetEnvironmentVariable("OTMATCH_FAKE_DIFF_FAIL", "Process")
$oldFakeRestoreFail = [Environment]::GetEnvironmentVariable("OTMATCH_FAKE_RESTORE_FAIL", "Process")
$oldFakeSkipMainExp = [Environment]::GetEnvironmentVariable("OTMATCH_FAKE_SKIP_MAIN_EXP", "Process")
$oldFakeCompileDelay = [Environment]::GetEnvironmentVariable("OTMATCH_FAKE_CL_DELAY_MS", "Process")
$oldFakeCompileBarrierRoot = [Environment]::GetEnvironmentVariable("OTMATCH_FAKE_CL_BARRIER_ROOT", "Process")
$oldFakeCompileBarrierSource = [Environment]::GetEnvironmentVariable("OTMATCH_FAKE_CL_BARRIER_SOURCE", "Process")
$oldContractExitCodePath = [Environment]::GetEnvironmentVariable("OTMATCH_CONTRACT_EXIT_CODE_PATH", "Process")
$oldExpectedCheckpoint = [Environment]::GetEnvironmentVariable("OTMATCH_EXPECT_CHECKPOINT_PATH", "Process")
$oldVariantSource = [Environment]::GetEnvironmentVariable("OTMATCH_VARIANT_SOURCE", "Process")
$oldVariantRepoRoot = [Environment]::GetEnvironmentVariable("OTMATCH_VARIANT_REPO_ROOT", "Process")
$oldFakeNonTimeRestore = [Environment]::GetEnvironmentVariable("OTMATCH_FAKE_NON_TIME_RESTORE", "Process")
$oldFakeNonconvergingStability = [Environment]::GetEnvironmentVariable("OTMATCH_FAKE_NONCONVERGING_STABILITY", "Process")
$backgroundProcess = $null
$escapeSentinelRoot = $null
$externalVariantRoot = $null

try {
    $sourceRoot = Join-Path $fixtureRoot "src"
    $includeRoot = Join-Path $fixtureRoot "include"
    $libRoot = Join-Path $fixtureRoot "lib"
    $toolRoot = Join-Path $fixtureRoot "tools"
    $compilerToolRoot = Join-Path $toolRoot "compiler"
    $linkerToolRoot = Join-Path $toolRoot "linker"
    $compilerLog = Join-Path $fixtureRoot "compiler.log"
    $linkerLog = Join-Path $fixtureRoot "linker.log"
    foreach ($directory in @($sourceRoot, $includeRoot, $libRoot, $compilerToolRoot, $linkerToolRoot)) {
        [void][System.IO.Directory]::CreateDirectory($directory)
    }

    $headerPath = Join-Path $sourceRoot "fixture_value.h"
    $sourcePath = Join-Path $sourceRoot "fixture.cpp"
    $includeHeaderPath = Join-Path $includeRoot "option_value.h"
    $forcedHeaderPath = Join-Path $includeRoot "forced_value.h"
    $trackedLibraryPath = Join-Path $libRoot "tracked.lib"
    Write-Utf8Text $headerPath "#define FIXTURE_VALUE 1`n"
    Write-Utf8Text $includeHeaderPath "#define OPTION_VALUE 3`n"
    Write-Utf8Text $forcedHeaderPath "#define FORCED_VALUE 4`n"
    [System.IO.File]::WriteAllBytes($trackedLibraryPath, [byte[]](1, 2, 3, 4))
    foreach ($libraryName in @("LIBC.LIB", "LIBCMT.LIB", "KERNEL32.LIB", "COMDLG32.LIB")) {
        [System.IO.File]::WriteAllBytes((Join-Path $libRoot $libraryName), [byte[]](9, 9, 9, 9))
    }
    Write-Utf8Text $sourcePath "#include `"fixture_value.h`"`n#include <option_value.h>`nint OtCacheFixture() { return FIXTURE_VALUE + OPTION_VALUE; }`n"

    $compilerHelper = Join-Path $compilerToolRoot "compiler-helper.bin"
    [System.IO.File]::WriteAllBytes($compilerHelper, [byte[]](1, 1, 1, 1))
    $fakeCompilerImpl = Join-Path $compilerToolRoot "fake-cl-impl.ps1"
    $fakeCompiler = Join-Path $compilerToolRoot "fake-cl.cmd"
    Write-Utf8Text $fakeCompilerImpl @'
$ErrorActionPreference = "Stop"
$objectArgument = @($args | Where-Object { $_ -like '/Fo*' } | Select-Object -Last 1)
$sourceArgument = @($args | Where-Object { $_ -like '*.cpp' } | Select-Object -Last 1)
if ($objectArgument.Count -ne 1 -or $sourceArgument.Count -ne 1) { exit 21 }
$objectPath = [string]$objectArgument[0].Substring(3)
$sourcePath = [string]$sourceArgument[0]
[System.IO.File]::AppendAllText($env:OTMATCH_FAKE_CL_LOG, $sourcePath + "`n")
if (-not [string]::IsNullOrWhiteSpace($env:OTMATCH_FAKE_CL_DELAY_MS)) {
    Start-Sleep -Milliseconds ([int]$env:OTMATCH_FAKE_CL_DELAY_MS)
}
if (-not [string]::IsNullOrWhiteSpace($env:OTMATCH_FAKE_CL_BARRIER_ROOT) -and
    $sourcePath.Equals(
        $env:OTMATCH_FAKE_CL_BARRIER_SOURCE,
        [System.StringComparison]::OrdinalIgnoreCase)) {
    $readyPath = $env:OTMATCH_FAKE_CL_BARRIER_ROOT + ".ready"
    $releasePath = $env:OTMATCH_FAKE_CL_BARRIER_ROOT + ".release"
    [System.IO.File]::WriteAllText($readyPath, "ready")
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    while (-not (Test-Path -LiteralPath $releasePath -PathType Leaf) -and
        [DateTime]::UtcNow -lt $deadline) {
        Start-Sleep -Milliseconds 20
    }
    if (-not (Test-Path -LiteralPath $releasePath -PathType Leaf)) {
        Write-Error "timed out waiting for compile barrier release"
        exit 22
    }
}
$normalizedArguments = @($args | ForEach-Object {
    if ($_ -like '/Fo*') { "/Fo" + (Split-Path -Leaf ([string]$_.Substring(3))) } else { $_ }
})
$material = [System.IO.File]::ReadAllText($sourcePath) + "`n" + ($normalizedArguments -join "`n")
foreach ($header in @(Get-ChildItem -LiteralPath (Split-Path -Parent $sourcePath) -Filter *.h -File | Sort-Object FullName)) {
    $material += "`n" + [System.IO.File]::ReadAllText($header.FullName)
}
$sha = [System.Security.Cryptography.SHA256]::Create()
try { $digest = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($material)) } finally { $sha.Dispose() }
$bytes = New-Object byte[] (4 + $digest.Length)
$bytes[0] = 0x4c; $bytes[1] = 0x01; $bytes[2] = 0x01; $bytes[3] = 0x00
[System.Array]::Copy($digest, 0, $bytes, 4, $digest.Length)
[void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $objectPath))
[System.IO.File]::WriteAllBytes($objectPath, $bytes)
exit 0
'@
    Write-Utf8Text $fakeCompiler ("@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"{0}`" %*`r`nexit /b %errorlevel%`r`n" -f $fakeCompilerImpl)

    $linkerHelper = Join-Path $linkerToolRoot "linker-helper.bin"
    [System.IO.File]::WriteAllBytes($linkerHelper, [byte[]](2, 2, 2, 2))
    $fakeLinkerImpl = Join-Path $linkerToolRoot "fake-link-impl.ps1"
    $fakeLinker = Join-Path $linkerToolRoot "fake-link.cmd"
    Write-Utf8Text $fakeLinkerImpl @'
$ErrorActionPreference = "Stop"
$material = $args -join "`n"
foreach ($objectArgument in @($args | Where-Object { $_ -like '*.obj' })) {
    $objectPath = if ([System.IO.Path]::IsPathRooted($objectArgument)) { $objectArgument } else { Join-Path (Get-Location) $objectArgument }
    if (Test-Path -LiteralPath $objectPath -PathType Leaf) {
        $material += "`n" + [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($objectPath))
    }
}
$sha = [System.Security.Cryptography.SHA256]::Create()
try { $digest = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($material)) } finally { $sha.Dispose() }
$linkedOutputPath = ""
foreach ($argument in $args) {
    if ($argument -match '^/(?:OUT|MAP|PDB):(.+)$') {
        $path = $Matches[1]
        if (-not [System.IO.Path]::IsPathRooted($path)) { $path = Join-Path (Get-Location) $path }
        [System.IO.File]::WriteAllBytes($path, $digest)
        if ($argument -match '^/OUT:') { $linkedOutputPath = $path }
    }
}
if ((Split-Path -Leaf $linkedOutputPath) -eq 'otwin-match-candidates.dll') {
    [System.IO.File]::WriteAllBytes(($linkedOutputPath -replace '\.dll$', '.lib'), $digest)
    if ($env:OTMATCH_FAKE_SKIP_MAIN_EXP -ne "1") {
        [System.IO.File]::WriteAllBytes(($linkedOutputPath -replace '\.dll$', '.exp'), $digest)
    }
}
[System.IO.File]::AppendAllText($env:OTMATCH_FAKE_LINK_LOG, ($args -join " ") + "`n")
exit 0
'@
    Write-Utf8Text $fakeLinker ("@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File `"{0}`" %*`r`nexit /b %errorlevel%`r`n" -f $fakeLinkerImpl)

    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_CL_LOG", $compilerLog, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_LINK_LOG", $linkerLog, "Process")
    $fixtureRelative = $fixtureRoot.Substring($repoRoot.Length).TrimStart('\', '/')
    $outputRelative = Join-Path $fixtureRelative "out"
    $cacheRelative = Join-Path $fixtureRelative "cache"

    $escapeSentinelRoot = Join-Path $repoRoot ("output-escape-contract-{0}" -f [Guid]::NewGuid().ToString("N"))
    [void][System.IO.Directory]::CreateDirectory($escapeSentinelRoot)
    $escapeSentinel = Join-Path $escapeSentinelRoot "sentinel.txt"
    Write-Utf8Text $escapeSentinel "preserve me`n"
    $escapingOutput = Join-Path $fixtureRoot ("..\..\{0}" -f (Split-Path -Leaf $escapeSentinelRoot))
    $escapingOutputRejected = $false
    try {
        [void](Invoke-ContractBuild -OutputDirectoryOverride $escapingOutput)
    } catch {
        $escapingOutputRejected = ($_.Exception.Message -match "must be beneath the repository's ignored")
    }
    Assert-Contract $escapingOutputRejected "output path traversal outside ignored roots should be rejected"
    Assert-Contract ([System.IO.File]::ReadAllText($escapeSentinel) -eq "preserve me`n") `
        "rejected escaping output should preserve an existing sentinel"
    Assert-Contract (-not (Test-Path -LiteralPath (Join-Path $escapeSentinelRoot ".otmatch-build.lock") -PathType Leaf)) `
        "escaping output should be rejected before build-lock/output writes"

    $junctionPath = Join-Path $fixtureRoot "output-junction"
    [void](New-Item -ItemType Junction -Path $junctionPath -Target $escapeSentinelRoot)
    $junctionOutputRejected = $false
    try {
        [void](Invoke-ContractBuild -OutputDirectoryOverride (Join-Path $junctionPath "nested"))
    } catch {
        $junctionOutputRejected = ($_.Exception.Message -match 'cannot traverse reparse point')
    }
    Assert-Contract $junctionOutputRejected "output paths beneath a junction should be rejected"
    Assert-Contract ([System.IO.File]::ReadAllText($escapeSentinel) -eq "preserve me`n") `
        "rejected junction output should preserve its external target sentinel"
    # Windows PowerShell 5.1 intermittently throws a NullReferenceException
    # when Remove-Item deletes a directory junction. Directory.Delete removes
    # the link itself (not its target) without that provider-level flake.
    [System.IO.Directory]::Delete($junctionPath)

    $foreignCacheRoot = Join-Path $fixtureRoot "foreign-cache"
    [void][System.IO.Directory]::CreateDirectory($foreignCacheRoot)
    $foreignSentinel = Join-Path $foreignCacheRoot "do-not-delete.txt"
    Write-Utf8Text $foreignSentinel "foreign content`n"
    $foreignCacheRelative = $foreignCacheRoot.Substring($repoRoot.Length).TrimStart('\', '/')
    $foreignCacheRejected = $false
    try {
        [void](Invoke-ContractBuild -CacheDirectoryOverride $foreignCacheRelative)
    } catch {
        $foreignCacheRejected = ($_.Exception.Message -match 'Refusing to adopt non-empty unmarked candidate cache')
    }
    Assert-Contract $foreignCacheRejected "non-empty unmarked cache directories should be rejected"
    Assert-Contract (Test-Path -LiteralPath $foreignSentinel -PathType Leaf) `
        "rejecting an unowned cache directory should preserve its contents"

    $firstOutput = Invoke-ContractBuild
    Assert-Contract ((Get-LineCount $compilerLog) -eq 4) "first build should compile fixture plus three anchors"
    Assert-Contract ((Get-LineCount $linkerLog) -eq 3) "first build should link all three candidates"
    Assert-Contract ($firstOutput -match '2 compile\(s\)') "first main graph should report two compilations"

    $secondOutput = Invoke-ContractBuild
    Assert-Contract ((Get-LineCount $compilerLog) -eq 4) "unchanged build should compile no objects"
    Assert-Contract ((Get-LineCount $linkerLog) -eq 3) "unchanged build should link no candidates"
    Assert-Contract ($secondOutput -match '2 hit\(s\), 0 compile\(s\)') "unchanged main graph should be all cache hits"
    Assert-Contract ($secondOutput -match 'Reusing LCMT anchor object') "LCMT companion object should be cached"
    Assert-Contract ($secondOutput -match 'Reusing dllcrt link outputs') "DLLCRT companion link should be cached"

    # Central TU metadata must affect only the named source's compile key, and
    # every metadata edit (including review rationale) must invalidate a seeded
    # focused-build boundary.
    $metadataPath = Join-Path $fixtureRoot "vc4-tu-metadata.csv"
    $metadataRelative = $metadataPath.Substring($repoRoot.Length).TrimStart('\', '/')
    $metadataSourceRelative = $sourcePath.Substring($repoRoot.Length).
        TrimStart('\', '/').Replace('\', '/')
    $metadataOutputRelative = Join-Path $fixtureRelative "metadata-out"
    $metadataCacheRelative = Join-Path $fixtureRelative "metadata-cache"
    [void](Invoke-ContractBuild `
        -OutputDirectoryOverride $metadataOutputRelative `
        -CacheDirectoryOverride $metadataCacheRelative)
    $metadataOutputFullPath = Join-Path $repoRoot $metadataOutputRelative
    $metadataObject = Get-ChildItem -LiteralPath $metadataOutputFullPath `
        -Filter *fixture.obj -File | Select-Object -First 1
    Assert-Contract ($null -ne $metadataObject) `
        "metadata fixture object should exist before applying a TU exception"
    $objectWithoutMetadata = (Get-FileHash -LiteralPath $metadataObject.FullName `
        -Algorithm SHA256).Hash

    $validMetadata = @"
"source_path","extra_compile_flags","reason"
"$metadataSourceRelative","/GX","contract exception-unwind requirement"
"@
    Write-Utf8Text $metadataPath $validMetadata
    $compilesBeforeMetadata = Get-LineCount $compilerLog
    [void](Invoke-ContractBuild `
        -AdditionalArguments @("-TuMetadataPath", $metadataRelative) `
        -OutputDirectoryOverride $metadataOutputRelative `
        -CacheDirectoryOverride $metadataCacheRelative)
    Assert-Contract ((Get-LineCount $compilerLog) -eq ($compilesBeforeMetadata + 1)) `
        "adding TU metadata should invalidate only the named source object"
    $objectWithMetadata = (Get-FileHash -LiteralPath $metadataObject.FullName `
        -Algorithm SHA256).Hash
    Assert-Contract ($objectWithMetadata -cne $objectWithoutMetadata) `
        "the reviewed TU flag should participate in the object fingerprint"
    $compilesAfterMetadata = Get-LineCount $compilerLog
    [void](Invoke-ContractBuild `
        -AdditionalArguments @("-TuMetadataPath", $metadataRelative) `
        -OutputDirectoryOverride $metadataOutputRelative `
        -CacheDirectoryOverride $metadataCacheRelative)
    Assert-Contract ((Get-LineCount $compilerLog) -eq $compilesAfterMetadata) `
        "unchanged TU metadata should reuse candidate objects"

    $reasonOnlyMetadata = $validMetadata.Replace(
        "contract exception-unwind requirement",
        "review rationale changed without changing flags")
    Write-Utf8Text $metadataPath $reasonOnlyMetadata
    $metadataContextRejected = $false
    try {
        [void](Invoke-ContractBuild `
            -AdditionalArguments @(
                "-TuMetadataPath", $metadataRelative,
                "-ChangedSource", $sourcePath,
                "-FocusedChangedSource",
                "-CandidateGraphLockHeld") `
            -OutputDirectoryOverride $metadataOutputRelative `
            -CacheDirectoryOverride $metadataCacheRelative)
    }
    catch {
        $metadataContextRejected = ($_.Exception.Message -match
            'Focused candidate build context changed')
    }
    Assert-Contract $metadataContextRejected `
        "any TU metadata edit should invalidate the focused-build boundary"

    $invalidMetadata = $validMetadata.Replace('"/GX"', '"/FA"')
    Write-Utf8Text $metadataPath $invalidMetadata
    $unsupportedMetadataRejected = $false
    $unsupportedMetadataError = ""
    try {
        [void](Invoke-ContractBuild `
            -AdditionalArguments @("-TuMetadataPath", $metadataRelative) `
            -OutputDirectoryOverride $metadataOutputRelative `
            -CacheDirectoryOverride $metadataCacheRelative)
    }
    catch {
        $unsupportedMetadataError = $_.Exception.Message
        $unsupportedMetadataRejected = ($unsupportedMetadataError -match
            "uses\s+unsupported\s+flag")
    }
    Assert-Contract $unsupportedMetadataRejected `
        ("TU metadata should reject unreviewed compiler flags; observed: " +
            (($unsupportedMetadataError -replace '[\r\n]+', ' ').Trim()))
    Write-Utf8Text $metadataPath $validMetadata

    $compilesBeforeCompilerHelper = Get-LineCount $compilerLog
    $linksBeforeCompilerHelper = Get-LineCount $linkerLog
    [System.IO.File]::WriteAllBytes($compilerHelper, [byte[]](1, 1, 1, 2))
    [void](Invoke-ContractBuild)
    Assert-Contract ((Get-LineCount $compilerLog) -eq ($compilesBeforeCompilerHelper + 4)) `
        "compiler sibling payload change should invalidate every object key"
    Assert-Contract ((Get-LineCount $linkerLog) -eq $linksBeforeCompilerHelper) `
        "byte-identical objects after compiler helper change should not relink"

    $compilesBeforeLinkerHelper = Get-LineCount $compilerLog
    $linksBeforeLinkerHelper = Get-LineCount $linkerLog
    [System.IO.File]::WriteAllBytes($linkerHelper, [byte[]](2, 2, 2, 3))
    [void](Invoke-ContractBuild)
    Assert-Contract ((Get-LineCount $compilerLog) -eq $compilesBeforeLinkerHelper) `
        "linker sibling payload change should not invalidate objects"
    Assert-Contract ((Get-LineCount $linkerLog) -eq ($linksBeforeLinkerHelper + 3)) `
        "linker sibling payload change should invalidate every link output"

    $outputFullPath = Join-Path $fixtureRoot "out"
    $fixtureObject = Get-ChildItem -LiteralPath $outputFullPath -Filter *fixture.obj -File |
        Select-Object -First 1
    Assert-Contract ($null -ne $fixtureObject) "fixture object should exist in the candidate directory"
    [System.IO.File]::SetLastWriteTimeUtc($sourcePath, [DateTime]::UtcNow)
    [void](Invoke-ContractBuild)
    $fixtureObject.Refresh()
    Assert-Contract ($fixtureObject.LastWriteTimeUtc -ge [System.IO.File]::GetLastWriteTimeUtc($sourcePath)) `
        "cache hits should refresh object mtime for Product stale-object consumers"

    $mainLibPath = Join-Path $outputFullPath "otwin-match-candidates.lib"
    Remove-Item -LiteralPath $mainLibPath -Force
    $linksBeforeMissingOutput = Get-LineCount $linkerLog
    [void](Invoke-ContractBuild)
    Assert-Contract ((Get-LineCount $linkerLog) -eq ($linksBeforeMissingOutput + 1)) `
        "missing main import library should invalidate only the main link"
    Assert-Contract (Test-Path -LiteralPath $mainLibPath -PathType Leaf) `
        "main import library should be restored by relinking"

    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_SKIP_MAIN_EXP", "1", "Process")
    Remove-Item -LiteralPath $mainLibPath -Force
    $partialLinkRejected = $false
    try {
        [void](Invoke-ContractBuild)
    } catch {
        $partialLinkRejected = ($_.Exception.Message -match 'did not produce expected output')
    }
    Assert-Contract $partialLinkRejected "a nominally successful partial link should fail closed"
    foreach ($mainOutputName in @(
            "otwin-match-candidates.dll",
            "otwin-match-candidates.map",
            "otwin-match-candidates.pdb",
            "otwin-match-candidates.lib",
            "otwin-match-candidates.exp")) {
        Assert-Contract (-not (Test-Path -LiteralPath (Join-Path $outputFullPath $mainOutputName) -PathType Leaf)) `
            "failed main link should remove stale/partial output $mainOutputName"
    }
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_SKIP_MAIN_EXP", $null, "Process")
    [void](Invoke-ContractBuild)

    $linksBeforeLibraryChange = Get-LineCount $linkerLog
    [System.IO.File]::WriteAllBytes($trackedLibraryPath, [byte[]](4, 3, 2, 1))
    [void](Invoke-ContractBuild)
    Assert-Contract ((Get-LineCount $linkerLog) -eq ($linksBeforeLibraryChange + 3)) `
        "library content change should invalidate all dependent link outputs"

    $alternateLibRoot = Join-Path $fixtureRoot "alternate-lib"
    [void][System.IO.Directory]::CreateDirectory($alternateLibRoot)
    $alternateLibraryPath = Join-Path $alternateLibRoot "shadow.lib"
    [System.IO.File]::WriteAllBytes($alternateLibraryPath, [byte[]](5, 6, 7, 8))
    $linksBeforeLibPath = Get-LineCount $linkerLog
    [void](Invoke-ContractBuild @("-ExtraLinkFlags", "/LIBPATH:$alternateLibRoot"))
    Assert-Contract ((Get-LineCount $linkerLog) -eq ($linksBeforeLibPath + 3)) `
        "/LIBPATH should produce a distinct link dependency fingerprint"
    $linksAfterLibPath = Get-LineCount $linkerLog
    [void](Invoke-ContractBuild @("-ExtraLinkFlags", "/LIBPATH:$alternateLibRoot"))
    Assert-Contract ((Get-LineCount $linkerLog) -eq $linksAfterLibPath) `
        "unchanged /LIBPATH build should reuse link outputs"
    [System.IO.File]::WriteAllBytes($alternateLibraryPath, [byte[]](8, 7, 6, 5))
    [void](Invoke-ContractBuild @("-ExtraLinkFlags", "/LIBPATH:$alternateLibRoot"))
    Assert-Contract ((Get-LineCount $linkerLog) -eq ($linksAfterLibPath + 3)) `
        "library change under /LIBPATH should invalidate link outputs"

    $externalObjectPath = Join-Path $fixtureRoot "external-input.obj"
    $externalObjectBytes = [byte[]](0x4c, 0x01, 0x01, 0x00, 0, 0, 0, 0, 1, 2, 3, 4)
    [System.IO.File]::WriteAllBytes($externalObjectPath, $externalObjectBytes)
    $linksBeforeExternalObject = Get-LineCount $linkerLog
    [void](Invoke-ContractBuild @("-ExtraLinkFlags", $externalObjectPath))
    Assert-Contract ((Get-LineCount $linkerLog) -eq ($linksBeforeExternalObject + 3)) `
        "explicit external object should participate in every link"
    $externalObjectBytes[11] = 5
    [System.IO.File]::WriteAllBytes($externalObjectPath, $externalObjectBytes)
    [void](Invoke-ContractBuild @("-ExtraLinkFlags", $externalObjectPath))
    Assert-Contract ((Get-LineCount $linkerLog) -eq ($linksBeforeExternalObject + 6)) `
        "explicit external object mutation should invalidate every link key"

    $externalExpPath = Join-Path $fixtureRoot "external-input.exp"
    [System.IO.File]::WriteAllBytes($externalExpPath, [byte[]](6, 6, 6, 6))
    $linksBeforeExternalExp = Get-LineCount $linkerLog
    [void](Invoke-ContractBuild @("-ExtraLinkFlags", $externalExpPath))
    Assert-Contract ((Get-LineCount $linkerLog) -eq ($linksBeforeExternalExp + 3)) `
        "explicit export input should participate in every link"
    [System.IO.File]::WriteAllBytes($externalExpPath, [byte[]](6, 6, 6, 7))
    [void](Invoke-ContractBuild @("-ExtraLinkFlags", $externalExpPath))
    Assert-Contract ((Get-LineCount $linkerLog) -eq ($linksBeforeExternalExp + 6)) `
        "explicit export input mutation should invalidate every link key"

    $compilerResponsePath = Join-Path $fixtureRoot "compiler.rsp"
    Write-Utf8Text $compilerResponsePath "/DRESPONSE_VALUE=1`n"
    $compilesBeforeCompilerResponse = Get-LineCount $compilerLog
    $compilerResponseOutput = Invoke-ContractBuild @("-ExtraCompileFlags", "@$compilerResponsePath")
    [void](Invoke-ContractBuild @("-ExtraCompileFlags", "@$compilerResponsePath"))
    Assert-Contract ((Get-LineCount $compilerLog) -eq ($compilesBeforeCompilerResponse + 8)) `
        "compiler response files should bypass all four object-cache entries on every build"
    Assert-Contract ($compilerResponseOutput -match '2 uncacheable') `
        "compiler response-file bypass should be visible in the main graph summary"

    $compilesBeforePch = Get-LineCount $compilerLog
    $pchOutput = Invoke-ContractBuild @("-ExtraCompileFlags", "/Ycfixture.pch")
    [void](Invoke-ContractBuild @("-ExtraCompileFlags", "/Ycfixture.pch"))
    Assert-Contract ((Get-LineCount $compilerLog) -eq ($compilesBeforePch + 8)) `
        "PCH options should bypass all four object-cache entries on every build"
    Assert-Contract ($pchOutput -match '2 uncacheable') `
        "PCH bypass should be visible in the main graph summary"

    $linkResponsePath = Join-Path $fixtureRoot "link.rsp"
    Write-Utf8Text $linkResponsePath "/COMMENT:response`n"
    $linksBeforeLinkResponse = Get-LineCount $linkerLog
    $linkResponseOutput = Invoke-ContractBuild @("-ExtraLinkFlags", "@$linkResponsePath")
    [void](Invoke-ContractBuild @("-ExtraLinkFlags", "@$linkResponsePath"))
    Assert-Contract ((Get-LineCount $linkerLog) -eq ($linksBeforeLinkResponse + 6)) `
        "link response files should bypass all three link-cache entries on every build"
    Assert-Contract ($linkResponseOutput -match 'link cache bypassed') `
        "link response-file bypass should be reported"

    # Reseed so every cache entry belongs to the current compiler fingerprint;
    # selecting an arbitrary entry is then deterministic even on coarse-mtime
    # filesystems. This also contracts the explicit clean/rebuild escape hatch.
    [void](Invoke-ContractBuild @("-CleanObjectCache"))
    $currentCachedObjects = @(Get-ChildItem -LiteralPath (Join-Path $fixtureRoot "cache") -Filter *.obj -File -Recurse)
    Assert-Contract ($currentCachedObjects.Count -eq 4) "clean cache rebuild should publish exactly the active object graph"
    $cachedObject = $currentCachedObjects | Select-Object -First 1
    Assert-Contract ($null -ne $cachedObject) "object cache should contain content-addressed entries"
    [System.IO.File]::WriteAllBytes($cachedObject.FullName, [byte[]](0, 1, 2, 3))
    $compilesBeforeCorrupt = Get-LineCount $compilerLog
    $corruptOutput = Invoke-ContractBuild
    Assert-Contract ((Get-LineCount $compilerLog) -eq ($compilesBeforeCorrupt + 1)) `
        "corrupt cache entry should force exactly one recompile even when destination object is valid"
    Assert-Contract ($corruptOutput -match 'Ignoring corrupt candidate-object cache entry') "corruption should be reported"

    Write-Utf8Text $headerPath "#define FIXTURE_VALUE 2`n"
    $linksBeforeHeader = Get-LineCount $linkerLog
    $compilesBeforeHeader = Get-LineCount $compilerLog
    [void](Invoke-ContractBuild)
    Assert-Contract ((Get-LineCount $compilerLog) -eq ($compilesBeforeHeader + 1)) "header content change should rebuild its TU only"
    Assert-Contract ((Get-LineCount $linkerLog) -eq ($linksBeforeHeader + 1)) "header content change should relink only the main candidate"

    $alternateIncludeRoot = Join-Path $fixtureRoot "alternate-include"
    [void][System.IO.Directory]::CreateDirectory($alternateIncludeRoot)
    $alternateHeaderPath = Join-Path $alternateIncludeRoot "option_value.h"
    Write-Utf8Text $alternateHeaderPath "#define OPTION_VALUE 7`n"
    $compilesBeforeIncludeFlag = Get-LineCount $compilerLog
    [void](Invoke-ContractBuild @("-ExtraCompileFlags", "/I$alternateIncludeRoot"))
    Assert-Contract ((Get-LineCount $compilerLog) -eq ($compilesBeforeIncludeFlag + 4)) `
        "/I search-order change should produce distinct keys for all compiled objects"
    $compilesAfterIncludeFlag = Get-LineCount $compilerLog
    [void](Invoke-ContractBuild @("-ExtraCompileFlags", "/I$alternateIncludeRoot"))
    Assert-Contract ((Get-LineCount $compilerLog) -eq $compilesAfterIncludeFlag) `
        "unchanged /I build should reuse its cache entries"
    Write-Utf8Text $alternateHeaderPath "#define OPTION_VALUE 8`n"
    [void](Invoke-ContractBuild @("-ExtraCompileFlags", "/I$alternateIncludeRoot"))
    Assert-Contract ((Get-LineCount $compilerLog) -eq ($compilesAfterIncludeFlag + 1)) `
        "content change in the selected /I header should rebuild its dependent TU only"

    $compilesBeforeForcedInclude = Get-LineCount $compilerLog
    [void](Invoke-ContractBuild @("-ExtraCompileFlags", "/FIforced_value.h"))
    Assert-Contract ((Get-LineCount $compilerLog) -eq ($compilesBeforeForcedInclude + 4)) `
        "/FI should participate in every compiled object's dependency closure"
    $compilesAfterForcedInclude = Get-LineCount $compilerLog
    [void](Invoke-ContractBuild @("-ExtraCompileFlags", "/FIforced_value.h"))
    Assert-Contract ((Get-LineCount $compilerLog) -eq $compilesAfterForcedInclude) `
        "unchanged /FI build should reuse its cache entries"
    Write-Utf8Text $forcedHeaderPath "#define FORCED_VALUE 5`n"
    [void](Invoke-ContractBuild @("-ExtraCompileFlags", "/FIforced_value.h"))
    Assert-Contract ((Get-LineCount $compilerLog) -eq ($compilesAfterForcedInclude + 4)) `
        "forced-include content change should invalidate every dependent object"

    # Return the link state to the base compile configuration before forcing a
    # byte-identical TU; the preceding build intentionally used /FI.
    [void](Invoke-ContractBuild)
    $compilesBeforeChanged = Get-LineCount $compilerLog
    $linksBeforeChanged = Get-LineCount $linkerLog
    [void](Invoke-ContractBuild @("-ChangedSource", $sourcePath))
    Assert-Contract ((Get-LineCount $compilerLog) -eq ($compilesBeforeChanged + 1)) "ChangedSource should force its selected TU"
    Assert-Contract ((Get-LineCount $linkerLog) -eq $linksBeforeChanged) "byte-identical forced TU should not relink"

    # A seeded focused build must validate the complete graph and every
    # untouched object, compile only its named TU, and link only the main image.
    $focusedBaselineDll = Join-Path $outputFullPath "otwin-match-candidates.dll"
    $focusedBaselineMap = Join-Path $outputFullPath "otwin-match-candidates.map"
    $focusedBaselineDllBytes = [System.IO.File]::ReadAllBytes($focusedBaselineDll)
    $focusedBaselineMapBytes = [System.IO.File]::ReadAllBytes($focusedBaselineMap)
    $sourceBeforeFocused = [System.IO.File]::ReadAllBytes($sourcePath)
    Write-Utf8Text $sourcePath "#include `"fixture_value.h`"`n#include <option_value.h>`nint OtCacheFixture() { return FIXTURE_VALUE + OPTION_VALUE + 1; }`n"
    $compilesBeforeFocused = Get-LineCount $compilerLog
    $linksBeforeFocused = Get-LineCount $linkerLog
    $focusedOutput = Invoke-ContractBuild @(
        "-ChangedSource", $sourcePath,
        "-FocusedChangedSource",
        "-FocusedGraphAlreadyValidated",
        "-CandidateGraphLockHeld")
    Assert-Contract ((Get-LineCount $compilerLog) -eq ($compilesBeforeFocused + 1)) `
        "focused mode should compile only its selected TU"
    Assert-Contract ((Get-LineCount $linkerLog) -eq ($linksBeforeFocused + 1)) `
        "focused mode should link only the main candidate"
    Assert-Contract ($focusedOutput -match 'Focused candidate mode skipped LCMT and DLLCRT') `
        "focused mode should report skipped companion candidates"
    [System.IO.File]::WriteAllBytes($sourcePath, $sourceBeforeFocused)
    [void](Invoke-ContractBuild @(
        "-ChangedSource", $sourcePath,
        "-FocusedChangedSource",
        "-CandidateGraphLockHeld"))
    Assert-Contract ([Convert]::ToBase64String([System.IO.File]::ReadAllBytes($focusedBaselineDll)) -eq
        [Convert]::ToBase64String($focusedBaselineDllBytes)) `
        "focused restoration should reproduce the seeded main DLL"
    Assert-Contract ([Convert]::ToBase64String([System.IO.File]::ReadAllBytes($focusedBaselineMap)) -eq
        [Convert]::ToBase64String($focusedBaselineMapBytes)) `
        "focused restoration should reproduce the seeded main map"

    $focusWithoutGraphLockRejected = $false
    try {
        [void](Invoke-ContractBuild @(
            "-ChangedSource", $sourcePath,
            "-FocusedChangedSource"))
    } catch {
        $focusWithoutGraphLockRejected = ($_.Exception.Message -match 'exclusive candidate-graph lock')
    }
    Assert-Contract $focusWithoutGraphLockRejected `
        "focused mode should require its caller to hold the candidate-graph lock"

    $unseededFocusedOutput = Join-Path $fixtureRelative "unseeded-focused"
    $unseededFocusedRejected = $false
    try {
        [void](Invoke-ContractBuild `
            -OutputDirectoryOverride $unseededFocusedOutput `
            -AdditionalArguments @(
                "-ChangedSource", $sourcePath,
                "-FocusedChangedSource",
                "-CandidateGraphLockHeld"))
    } catch {
        $unseededFocusedRejected = ($_.Exception.Message -match 'requires a seeded full candidate build state')
    }
    Assert-Contract $unseededFocusedRejected `
        "focused mode should fail closed without a seeded output state"

    $untouchedObject = Get-Item -LiteralPath (Join-Path $outputFullPath "tools_otmatch_match_dll_anchors.obj")
    $untouchedObjectBytes = [System.IO.File]::ReadAllBytes($untouchedObject.FullName)
    $untouchedObjectTimestamp = $untouchedObject.LastWriteTimeUtc
    $tamperedObjectBytes = [byte[]]$untouchedObjectBytes.Clone()
    $tamperedObjectBytes[$tamperedObjectBytes.Length - 1] =
        $tamperedObjectBytes[$tamperedObjectBytes.Length - 1] -bxor 0xff
    [System.IO.File]::WriteAllBytes($untouchedObject.FullName, $tamperedObjectBytes)
    [System.IO.File]::SetLastWriteTimeUtc($untouchedObject.FullName, $untouchedObjectTimestamp)
    $tamperedUntouchedObjectRejected = $false
    try {
        [void](Invoke-ContractBuild @(
            "-ChangedSource", $sourcePath,
            "-FocusedChangedSource",
            "-FocusedGraphAlreadyValidated",
            "-CandidateGraphLockHeld"))
    } catch {
        $tamperedUntouchedObjectRejected = ($_.Exception.Message -match 'object changed or is missing')
    }
    Assert-Contract $tamperedUntouchedObjectRejected `
        "trusted focused mode should exact-hash untouched objects even when length and mtime are preserved"
    [System.IO.File]::WriteAllBytes($untouchedObject.FullName, $untouchedObjectBytes)
    [System.IO.File]::SetLastWriteTimeUtc($untouchedObject.FullName, $untouchedObjectTimestamp)

    $addedSourcePath = Join-Path $sourceRoot "focused_graph_change.cpp"
    Write-Utf8Text $addedSourcePath "int OtFocusedGraphChange() { return 1; }`n"
    $focusedGraphChangeRejected = $false
    try {
        [void](Invoke-ContractBuild @(
            "-ChangedSource", $sourcePath,
            "-FocusedChangedSource",
            "-CandidateGraphLockHeld"))
    } catch {
        $focusedGraphChangeRejected = ($_.Exception.Message -match 'source graph changed')
    } finally {
        Remove-Item -LiteralPath $addedSourcePath -Force
    }
    Assert-Contract $focusedGraphChangeRejected `
        "focused mode should reject source graph additions"

    # Candidate source order is linker-significant. Windows PowerShell 5.1 and
    # PowerShell 7 use different culture collation for a base .cpp name and an
    # underscore-suffixed probe. Seed independently under both hosts, assert
    # the established base-before-probe order, and require byte-identical graph
    # source sequences and fingerprints.
    $powerShell7 = Get-Command pwsh.exe -CommandType Application `
        -ErrorAction SilentlyContinue | Select-Object -First 1
    Assert-Contract ($null -ne $powerShell7) `
        "cross-host candidate-graph contract requires pwsh.exe"
    $ordinalBaseSourcePath = Join-Path $sourceRoot `
        "confirm_state_transition_msgbox.cpp"
    $ordinalProbeSourcePath = Join-Path $sourceRoot `
        "confirm_state_transition_msgbox_80pct_probe.cpp"
    $windowsPowerShellOutputRelative = Join-Path $fixtureRelative `
        "cross-host-windows-powershell-out"
    $windowsPowerShellCacheRelative = Join-Path $fixtureRelative `
        "cross-host-windows-powershell-cache"
    $powerShell7OutputRelative = Join-Path $fixtureRelative `
        "cross-host-pwsh-out"
    $powerShell7CacheRelative = Join-Path $fixtureRelative `
        "cross-host-pwsh-cache"
    try {
        Write-Utf8Text $ordinalBaseSourcePath `
            "int OtOrdinalGraphBase() { return 1; }`n"
        Write-Utf8Text $ordinalProbeSourcePath `
            "int OtOrdinalGraphProbe() { return 2; }`n"
        [void](Invoke-ContractBuild `
            -OutputDirectoryOverride $windowsPowerShellOutputRelative `
            -CacheDirectoryOverride $windowsPowerShellCacheRelative `
            -PowerShellExecutable "powershell.exe")
        [void](Invoke-ContractBuild `
            -OutputDirectoryOverride $powerShell7OutputRelative `
            -CacheDirectoryOverride $powerShell7CacheRelative `
            -PowerShellExecutable $powerShell7.Source)

        $windowsPowerShellStatePath = Join-Path (
            Join-Path $repoRoot $windowsPowerShellOutputRelative) `
            ".otmatch-focused-build-state.json"
        $powerShell7StatePath = Join-Path (
            Join-Path $repoRoot $powerShell7OutputRelative) `
            ".otmatch-focused-build-state.json"
        $windowsPowerShellState = Get-Content `
            -LiteralPath $windowsPowerShellStatePath -Raw |
            ConvertFrom-Json
        $powerShell7State = Get-Content -LiteralPath $powerShell7StatePath -Raw |
            ConvertFrom-Json
        $windowsPowerShellSourceOrder = @(
            $windowsPowerShellState.sources |
                ForEach-Object { [string]$_.source })
        $powerShell7SourceOrder = @($powerShell7State.sources |
            ForEach-Object { [string]$_.source })
        $ordinalFixtureNames = @($windowsPowerShellState.sources |
            ForEach-Object { Split-Path -Leaf ([string]$_.source) } |
            Where-Object { $_ -like 'confirm_state_transition_msgbox*.cpp' })
        Assert-Contract (($ordinalFixtureNames -join '|') -ceq (
                'confirm_state_transition_msgbox.cpp|' +
                'confirm_state_transition_msgbox_80pct_probe.cpp')) `
            "candidate graph should retain ordinal base-before-probe link order"
        Assert-Contract (($windowsPowerShellSourceOrder -join "`n") -ceq
                ($powerShell7SourceOrder -join "`n")) `
            "candidate graph source order should be identical across PowerShell hosts"
        Assert-Contract ([string]$windowsPowerShellState.graph_fingerprint -ceq
                [string]$powerShell7State.graph_fingerprint) `
            "candidate graph fingerprint should be identical across PowerShell hosts"
    } finally {
        foreach ($ordinalSourcePath in @(
                $ordinalBaseSourcePath,
                $ordinalProbeSourcePath)) {
            if (Test-Path -LiteralPath $ordinalSourcePath -PathType Leaf) {
                Remove-Item -LiteralPath $ordinalSourcePath -Force
            }
        }
    }

    $compilesBeforeRebuild = Get-LineCount $compilerLog
    $linksBeforeRebuild = Get-LineCount $linkerLog
    [void](Invoke-ContractBuild @("-Rebuild"))
    Assert-Contract ((Get-LineCount $compilerLog) -eq ($compilesBeforeRebuild + 4)) "Rebuild should bypass every object cache entry"
    Assert-Contract ((Get-LineCount $linkerLog) -eq ($linksBeforeRebuild + 3)) "Rebuild should bypass every link cache entry"

    # A normal build holds a shared cache-root lock. A clean on another output
    # must time out rather than deleting entries being restored/published.
    $lockOutputRelative = Join-Path $fixtureRelative "lock-out"
    $backgroundArguments = @(
        "-NoProfile", "-ExecutionPolicy", "Bypass",
        "-File", $buildScript,
        "-Toolchain", "LegacyMsvc",
        "-ClPath", $fakeCompiler,
        "-LinkPath", $fakeLinker,
        "-IncludePath", $includeRoot,
        "-LibPath", $libRoot,
        "-OutputDirectory", $lockOutputRelative,
        "-ObjectCacheDirectory", $cacheRelative,
        "-CandidateSourceRoot", $sourceRoot,
        "-DefaultOptimization", "/Od",
        "-SemanticOptimization", "/O1",
        "-Rebuild"
    )
    $compilerLinesBeforeLockBuild = Get-LineCount $compilerLog
    $backgroundStdout = Join-Path $fixtureRoot "background-build.stdout.log"
    $backgroundStderr = Join-Path $fixtureRoot "background-build.stderr.log"
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_CL_DELAY_MS", "3000", "Process")
    $backgroundProcess = Start-Process `
        -FilePath "powershell" `
        -ArgumentList $backgroundArguments `
        -PassThru `
        -WindowStyle Hidden `
        -RedirectStandardOutput $backgroundStdout `
        -RedirectStandardError $backgroundStderr
    $lockReadyDeadline = [DateTime]::UtcNow.AddSeconds(15)
    while (-not $backgroundProcess.HasExited -and
        (Get-LineCount $compilerLog) -eq $compilerLinesBeforeLockBuild -and
        [DateTime]::UtcNow -lt $lockReadyDeadline) {
        Start-Sleep -Milliseconds 100
    }
    Assert-Contract (-not $backgroundProcess.HasExited) `
        "background rebuild should still hold the shared cache lock"
    Assert-Contract ((Get-LineCount $compilerLog) -gt $compilerLinesBeforeLockBuild) `
        "background rebuild should reach compilation before clean contention probe"
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_CL_DELAY_MS", $null, "Process")
    $concurrentCleanRejected = $false
    $concurrentCleanFailure = ""
    try {
        [void](Invoke-ContractBuild @("-CleanObjectCache", "-BuildLockTimeoutSeconds", "1"))
    } catch {
        $concurrentCleanFailure = $_.Exception.Message
        $concurrentCleanRejected = ($_.Exception.Message -match 'candidate object cache mutation lock')
    }
    Assert-Contract $concurrentCleanRejected `
        "clean cache should fail closed while another output holds a shared cache lock; observed: $concurrentCleanFailure"
    Assert-Contract (Test-Path -LiteralPath (Join-Path $fixtureRoot "cache\.otmatch-candidate-cache-v1") -PathType Leaf) `
        "rejected concurrent clean should preserve the marked cache"
    if (-not $backgroundProcess.WaitForExit(30000)) {
        Stop-Process -Id $backgroundProcess.Id -Force
        throw "Background cache-lock contract build did not exit."
    }
    # The timed overload can return as soon as the process handle is signaled,
    # before redirected-stream bookkeeping and the managed ExitCode snapshot
    # have settled. Complete the parameterless wait and refresh the process
    # object so this concurrency assertion cannot observe a stale exit code.
    $backgroundProcess.WaitForExit()
    $backgroundProcess.Refresh()
    $backgroundExitCode = [int]$backgroundProcess.ExitCode
    $backgroundFailureOutput = if ($backgroundExitCode -ne 0) {
        ((Get-Content -LiteralPath $backgroundStdout, $backgroundStderr -Raw -ErrorAction SilentlyContinue) -join "`n")
    } else {
        ""
    }
    Assert-Contract ($backgroundExitCode -eq 0) `
        "background rebuild should complete after concurrent clean is rejected (exit $backgroundExitCode); observed: $backgroundFailureOutput"
    $backgroundProcess.Dispose()
    $backgroundProcess = $null

    # Dependency snapshots remain mandatory when incremental reuse is disabled.
    # Mutate a header after the no-cache build fingerprints its first TU and
    # prove the delayed compiler cannot produce a nominally successful result.
    $disabledMutationOutputRelative = Join-Path $fixtureRelative "disabled-mutation-out"
    $disabledMutationStdout = Join-Path $fixtureRoot "disabled-mutation.stdout.log"
    $disabledMutationStderr = Join-Path $fixtureRoot "disabled-mutation.stderr.log"
    $disabledMutationBarrierRoot = Join-Path $fixtureRoot "disabled-mutation-barrier"
    $disabledMutationBarrierReady = $disabledMutationBarrierRoot + ".ready"
    $disabledMutationBarrierRelease = $disabledMutationBarrierRoot + ".release"
    $disabledMutationExitCodePath = Join-Path $fixtureRoot "disabled-mutation.exit-code.txt"
    $exitCapturingPowerShell = Join-Path $fixtureRoot "invoke-powershell-with-exit-code.cmd"
    Write-Utf8Text $exitCapturingPowerShell @'
@echo off
powershell %*
set "otmatch_contract_exit=%ERRORLEVEL%"
>"%OTMATCH_CONTRACT_EXIT_CODE_PATH%" echo %otmatch_contract_exit%
exit /b %otmatch_contract_exit%
'@
    $disabledMutationArguments = @(
        "-NoProfile", "-ExecutionPolicy", "Bypass",
        "-File", $buildScript,
        "-Toolchain", "LegacyMsvc",
        "-ClPath", $fakeCompiler,
        "-LinkPath", $fakeLinker,
        "-IncludePath", $includeRoot,
        "-LibPath", $libRoot,
        "-OutputDirectory", $disabledMutationOutputRelative,
        "-ObjectCacheDirectory", $cacheRelative,
        "-CandidateSourceRoot", $sourceRoot,
        "-DefaultOptimization", "/Od",
        "-SemanticOptimization", "/O1",
        "-DisableIncrementalCache"
    )
    $headerBeforeDisabledMutation = [System.IO.File]::ReadAllBytes($headerPath)
    $headerTimestampBeforeDisabledMutation =
        [System.IO.File]::GetLastWriteTimeUtc($headerPath)
    $compilerLinesBeforeDisabledMutation = Get-LineCount $compilerLog
    try {
        [Environment]::SetEnvironmentVariable(
            "OTMATCH_FAKE_CL_BARRIER_ROOT", $disabledMutationBarrierRoot, "Process")
        [Environment]::SetEnvironmentVariable(
            "OTMATCH_FAKE_CL_BARRIER_SOURCE", $sourcePath, "Process")
        [Environment]::SetEnvironmentVariable(
            "OTMATCH_CONTRACT_EXIT_CODE_PATH", $disabledMutationExitCodePath, "Process")
        if (Test-Path -LiteralPath $disabledMutationExitCodePath -PathType Leaf) {
            Remove-Item -LiteralPath $disabledMutationExitCodePath -Force
        }
        $backgroundProcess = Start-Process `
            -FilePath $exitCapturingPowerShell `
            -ArgumentList $disabledMutationArguments `
            -PassThru `
            -WindowStyle Hidden `
            -RedirectStandardOutput $disabledMutationStdout `
            -RedirectStandardError $disabledMutationStderr
        $mutationReadyDeadline = [DateTime]::UtcNow.AddSeconds(30)
        while (-not $backgroundProcess.HasExited -and
            -not (Test-Path -LiteralPath $disabledMutationBarrierReady -PathType Leaf) -and
            [DateTime]::UtcNow -lt $mutationReadyDeadline) {
            Start-Sleep -Milliseconds 20
        }
        Assert-Contract (-not $backgroundProcess.HasExited) `
            "cache-disabled mutation build should still be compiling its fingerprinted TU"
        Assert-Contract ((Get-LineCount $compilerLog) -gt $compilerLinesBeforeDisabledMutation -and
            (Test-Path -LiteralPath $disabledMutationBarrierReady -PathType Leaf)) `
            "cache-disabled mutation build should reach the deterministic compile barrier"
        Write-Utf8Text $headerPath "#define FIXTURE_VALUE 9`n"
        [System.IO.File]::SetLastWriteTimeUtc(
            $headerPath, $headerTimestampBeforeDisabledMutation)
        [System.IO.File]::WriteAllText($disabledMutationBarrierRelease, "release")
        if (-not $backgroundProcess.WaitForExit(30000)) {
            Stop-Process -Id $backgroundProcess.Id -Force
            throw "Cache-disabled mutation contract build did not exit."
        }
        $backgroundProcess.WaitForExit()
        $backgroundProcess.Refresh()
        Assert-Contract (Test-Path -LiteralPath $disabledMutationExitCodePath -PathType Leaf) `
            "cache-disabled mutation controller did not record the child exit code"
        $disabledMutationExitCode = [int]([System.IO.File]::ReadAllText(
                $disabledMutationExitCodePath).Trim())
        $disabledMutationOutput = ((Get-Content `
            -LiteralPath $disabledMutationStdout, $disabledMutationStderr `
            -Raw `
            -ErrorAction SilentlyContinue) -join "`n")
        Assert-Contract ($disabledMutationExitCode -ne 0) `
            "cache-disabled header mutation should fail the build (exit $disabledMutationExitCode); observed: $disabledMutationOutput"
        Assert-Contract ($disabledMutationOutput -match 'Dependencies changed while compiling|source/header content changed') `
            "cache-disabled mutation failure should identify dependency instability; observed: $disabledMutationOutput"
        $backgroundProcess.Dispose()
        $backgroundProcess = $null
    } finally {
        [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_CL_BARRIER_ROOT", $null, "Process")
        [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_CL_BARRIER_SOURCE", $null, "Process")
        [Environment]::SetEnvironmentVariable("OTMATCH_CONTRACT_EXIT_CODE_PATH", $null, "Process")
        foreach ($barrierPath in @(
                $disabledMutationBarrierReady,
                $disabledMutationBarrierRelease)) {
            if (Test-Path -LiteralPath $barrierPath -PathType Leaf) {
                Remove-Item -LiteralPath $barrierPath -Force
            }
        }
        [System.IO.File]::WriteAllBytes($headerPath, $headerBeforeDisabledMutation)
        if ($null -ne $backgroundProcess -and -not $backgroundProcess.HasExited) {
            Stop-Process -Id $backgroundProcess.Id -Force
        }
        if ($null -ne $backgroundProcess) {
            $backgroundProcess.Dispose()
            $backgroundProcess = $null
        }
    }

    # Variant-runner contract: every trial identifies the changed TU, while
    # source restoration is followed by one explicit complete rebuild.
    $variantRoot = Join-Path $fixtureRoot "variants"
    [void][System.IO.Directory]::CreateDirectory($variantRoot)
    $variantSource = Join-Path $variantRoot "variant.cpp"
    $variantOriginal = Join-Path $variantRoot "original.bin"
    $variantBuildLog = Join-Path $variantRoot "build.log"
    $variantDiffLog = Join-Path $variantRoot "diff.log"
    $variantOutputRoot = Join-Path $variantRoot "build"
    $variantOutputRelative = $variantOutputRoot.Substring($repoRoot.Length).TrimStart('\', '/')
    $variantCandidate = Join-Path $variantOutputRoot "otwin-match-candidates.dll"
    $variantMap = Join-Path $variantOutputRoot "otwin-match-candidates.map"
    $variantResults = Join-Path $variantOutputRoot "source-shape-variants.csv"
    $variantEvidence = Join-Path $variantOutputRoot "source-shape-variants.evidence.json"
    Write-Utf8Text $variantSource "int ShapeValue() { return 0; }`n"
    [System.IO.File]::WriteAllBytes($variantOriginal, [byte[]](0, 0, 0, 0))

    $fakeVariantBuild = Join-Path $variantRoot "fake-build.ps1"
    Write-Utf8Text $fakeVariantBuild @'
param(
    [string[]]$ChangedSource = @(),
    [switch]$Rebuild,
    [string[]]$ExtraCompileFlags = @(),
    [string[]]$ExtraLinkFlags = @(),
    [string]$Toolchain,
    [string]$OutputDirectory,
    [string]$DefaultOptimization,
    [string]$SemanticOptimization,
    [string]$ObjectCacheDirectory,
    [switch]$DisableIncrementalCache,
    [switch]$FocusedChangedSource,
    [switch]$FocusedGraphAlreadyValidated,
    [switch]$ForceMainRelink,
    [switch]$CandidateGraphLockHeld
)
$record = [pscustomobject][ordered]@{
    changedSource = @($ChangedSource)
    rebuild = [bool]$Rebuild
    focused = [bool]$FocusedChangedSource
    trustedGraph = [bool]$FocusedGraphAlreadyValidated
    forceMainRelink = [bool]$ForceMainRelink
    extraCompileFlags = @($ExtraCompileFlags)
    extraLinkFlags = @($ExtraLinkFlags)
    outputDirectory = $OutputDirectory
    candidateGraphLockHeld = [bool]$CandidateGraphLockHeld
}
[System.IO.File]::AppendAllText(
    $env:OTMATCH_VARIANT_BUILD_LOG,
    (($record | ConvertTo-Json -Compress) + "`n"))
if ($env:OTMATCH_FAKE_RESTORE_FAIL -eq "1" -and
    $FocusedChangedSource -and
    -not $ForceMainRelink -and
    @($ChangedSource).Count -eq 1 -and
    [System.IO.File]::ReadAllText([string]$ChangedSource[0]) -match 'return 0') {
    if (-not [string]::IsNullOrWhiteSpace($env:OTMATCH_EXPECT_CHECKPOINT_PATH) -and
        -not (Test-Path -LiteralPath $env:OTMATCH_EXPECT_CHECKPOINT_PATH -PathType Leaf)) {
        throw "variant checkpoint missing before restoration build"
    }
    throw "forced restoration build failure"
}
[void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $env:OTMATCH_FAKE_CANDIDATE))
$callNumber = [uint32]([System.IO.File]::ReadAllLines($env:OTMATCH_VARIANT_BUILD_LOG).Count)
$sourcePath = $env:OTMATCH_VARIANT_SOURCE
$relativeSource = $sourcePath.Substring($env:OTMATCH_VARIANT_REPO_ROOT.Length).
    TrimStart('\', '/')
$candidateObjectName = (($relativeSource -replace '[\\/]', '_') -replace '\.cpp$', '.obj')
$outputRoot = if ([System.IO.Path]::IsPathRooted($OutputDirectory)) {
    $OutputDirectory
} else {
    Join-Path $env:OTMATCH_VARIANT_REPO_ROOT $OutputDirectory
}
[void][System.IO.Directory]::CreateDirectory($outputRoot)
[System.IO.File]::WriteAllBytes(
    (Join-Path $outputRoot $candidateObjectName),
    [System.Text.Encoding]::UTF8.GetBytes([System.IO.File]::ReadAllText($sourcePath)))

$peBytes = New-Object byte[] 768
$peBytes[0] = 0x4d
$peBytes[1] = 0x5a
[BitConverter]::GetBytes([int]0x80).CopyTo($peBytes, 0x3c)
$peBytes[0x80] = 0x50
$peBytes[0x81] = 0x45
[BitConverter]::GetBytes([uint16]1).CopyTo($peBytes, 0x86)
[BitConverter]::GetBytes($callNumber).CopyTo($peBytes, 0x88)
[BitConverter]::GetBytes([uint16]224).CopyTo($peBytes, 0x94)
[BitConverter]::GetBytes([uint16]0x10b).CopyTo($peBytes, 0x98)
[BitConverter]::GetBytes([uint32]16).CopyTo($peBytes, 0xf4)
[BitConverter]::GetBytes([uint32]0x1000).CopyTo($peBytes, 0xf8)
[BitConverter]::GetBytes([uint32]40).CopyTo($peBytes, 0xfc)
[BitConverter]::GetBytes([uint32]0x1040).CopyTo($peBytes, 0x128)
    [BitConverter]::GetBytes([uint32]56).CopyTo($peBytes, 0x12c)
[BitConverter]::GetBytes([uint32]0x100).CopyTo($peBytes, 0x180)
[BitConverter]::GetBytes([uint32]0x1000).CopyTo($peBytes, 0x184)
[BitConverter]::GetBytes([uint32]0x100).CopyTo($peBytes, 0x188)
[BitConverter]::GetBytes([uint32]0x200).CopyTo($peBytes, 0x18c)
[BitConverter]::GetBytes($callNumber).CopyTo($peBytes, 0x204)
[BitConverter]::GetBytes($callNumber).CopyTo($peBytes, 0x244)
[BitConverter]::GetBytes([uint32]2).CopyTo($peBytes, 0x24c)
[BitConverter]::GetBytes([uint32]16).CopyTo($peBytes, 0x250)
    [BitConverter]::GetBytes([uint32]0x280).CopyTo($peBytes, 0x258)
    [BitConverter]::GetBytes($callNumber).CopyTo($peBytes, 0x260)
    [BitConverter]::GetBytes([uint32]4).CopyTo($peBytes, 0x268)
    [BitConverter]::GetBytes([uint32]16).CopyTo($peBytes, 0x26c)
    [BitConverter]::GetBytes([uint32]0x2a0).CopyTo($peBytes, 0x274)
$peBytes[0x280] = 0x4e
$peBytes[0x281] = 0x42
$peBytes[0x282] = 0x31
$peBytes[0x283] = 0x30
    [BitConverter]::GetBytes($callNumber).CopyTo($peBytes, 0x288)
    [BitConverter]::GetBytes([uint32]1).CopyTo($peBytes, 0x2a0)
    [BitConverter]::GetBytes([uint32]16).CopyTo($peBytes, 0x2a4)
    $peBytes[0x2a8] = 0
    $peBytes[0x2a9] = [byte]($callNumber -band 0xff)
    $peBytes[0x2aa] = [byte](($callNumber -shr 8) -band 0xff)
    $peBytes[0x2ab] = [byte](($callNumber -shr 16) -band 0xff)
    $peBytes[0x2ac] = if ($env:OTMATCH_FAKE_NON_TIME_RESTORE -eq "1" -and
        $FocusedChangedSource -and
        -not $ForceMainRelink -and
        [System.IO.File]::ReadAllText($sourcePath) -match 'return 0') {
        0x5b
    } else {
        0x5a
    }
$peBytes[0x2c0] = if ($env:OTMATCH_FAKE_NONCONVERGING_STABILITY -eq "1" -and
    $ForceMainRelink) {
    [byte]($callNumber -band 0xff)
} elseif ($env:OTMATCH_FAKE_NON_TIME_RESTORE -eq "1" -and
    $FocusedChangedSource -and
    -not $ForceMainRelink -and
    [System.IO.File]::ReadAllText($sourcePath) -match 'return 0') {
    0x5b
} else {
    0x5a
}
[System.IO.File]::WriteAllBytes($env:OTMATCH_FAKE_CANDIDATE, $peBytes)
$mapMarker = if ($env:OTMATCH_FAKE_NON_TIME_RESTORE -eq "1" -and
    $FocusedChangedSource -and
    -not $ForceMainRelink -and
    [System.IO.File]::ReadAllText($sourcePath) -match 'return 0') {
    "contract-mutated"
} else {
    "contract"
}
[System.IO.File]::WriteAllText(
    $env:OTMATCH_FAKE_MAP,
    ((" Timestamp is {0:x8} (Thu Jul 06 14:17:07 2026)`n" -f $callNumber) +
        " Non-time marker is $mapMarker`n"))
'@
    $fakeVariantDiff = Join-Path $variantRoot "fake-diff.ps1"
    Write-Utf8Text $fakeVariantDiff @'
param(
    [string]$OriginalPath,
    [uint64]$OriginalRva,
    [int]$Size,
    [string]$CandidatePath,
    [string]$CandidateMapPath,
    [string]$CandidateSymbol,
    [string]$Mask = ""
)
$record = [pscustomobject][ordered]@{
    candidatePath = $CandidatePath
    candidateMapPath = $CandidateMapPath
    mask = $Mask
}
[System.IO.File]::AppendAllText(
    $env:OTMATCH_VARIANT_DIFF_LOG,
    (($record | ConvertTo-Json -Compress) + "`n"))
if ($env:OTMATCH_FAKE_DIFF_FAIL -eq "1") {
    Write-Error "forced diff failure"
    exit 17
}
Write-Output "Original RVA:  0x00000000"
Write-Output "Candidate RVA: 0x00001000"
Write-Output "Size:          4 bytes"
Write-Output "Differences:   2 / 4"
Write-Output "Masked bytes:  2"
Write-Output "Hard differences: 0 / 2"
Write-Output "All diff offsets: 0x1, 0x2"
'@
    $planPath = Join-Path $variantRoot "plan.json"
    $plan = [pscustomobject][ordered]@{
        program = "Oregon32.exe"
        name = "ShapeValue"
        sourcePath = $variantSource
        originalRva = "0x0"
        checkpointId = "contract-checkpoint-1"
        priorBoundaryRunId = "contract-boundary-1"
        size = "0x4"
        candidateSymbol = "_ShapeValue"
        mask = "1-2"
        variants = @(
            [pscustomobject]@{ name = "one"; hypothesis = "non-meaningful control"; meaningful = $false; replacements = @([pscustomobject]@{ old = "return 0"; new = "return 1" }) },
            [pscustomobject]@{ name = "two"; hypothesis = "promotion shape"; meaningful = $true; replacements = @([pscustomobject]@{ old = "return 0"; new = "return 2" }) }
        )
    }
    Write-Utf8Text $planPath (($plan | ConvertTo-Json -Depth 8) + "`n")
    [Environment]::SetEnvironmentVariable("OTMATCH_VARIANT_BUILD_LOG", $variantBuildLog, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_VARIANT_DIFF_LOG", $variantDiffLog, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_CANDIDATE", $variantCandidate, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_MAP", $variantMap, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_VARIANT_SOURCE", $variantSource, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_VARIANT_REPO_ROOT", $repoRoot, "Process")

    $variantParameters = @{
        PlanPath = $planPath
        OriginalPath = $variantOriginal
        BuildOutputDirectory = $variantOutputRelative
        BuildScriptOverride = $fakeVariantBuild
        DiffScriptOverride = $fakeVariantDiff
        ExtraCompileFlags = @("/DVARIANT_ALPHA=1", "/DVARIANT_BETA=2")
        ExtraLinkFlags = @("/ALIGN:4096", "/COMMENT:variant-contract")
    }

    # Source safety is checked before the graph lock, any build, or mutation.
    # Overrides may use only ignored fixtures inside this repository; they may
    # not escape through absolute paths or directory junctions.
    $externalVariantRoot = Join-Path ([System.IO.Path]::GetTempPath()) (
        "otmatch-source-contract-{0}" -f [Guid]::NewGuid().ToString("N"))
    [void][System.IO.Directory]::CreateDirectory($externalVariantRoot)
    $externalVariantSource = Join-Path $externalVariantRoot "external.cpp"
    Write-Utf8Text $externalVariantSource "int ExternalShape() { return 0; }`n"

    # Result/evidence files are mutation-capable outputs. Reject every unsafe
    # target before acquiring the graph lock or deleting/writing any path.
    $sourceBytesBeforeOutputChecks = [System.IO.File]::ReadAllBytes($variantSource)
    $planBytesBeforeOutputChecks = [System.IO.File]::ReadAllBytes($planPath)
    $safeOutputResult = Join-Path $variantRoot "output-safety.csv"
    $safeOutputEvidence = Join-Path $variantRoot "output-safety.evidence.json"

    $evidenceSourceParameters = @{}
    foreach ($key in $variantParameters.Keys) {
        $evidenceSourceParameters[$key] = $variantParameters[$key]
    }
    $evidenceSourceParameters.ResultCsvPath = $safeOutputResult
    $evidenceSourceParameters.EvidenceJsonPath = $variantSource
    $evidenceSourceRejected = $false
    try {
        [void](& $variantScript @evidenceSourceParameters 2>&1)
    } catch {
        $evidenceSourceRejected = ($_.Exception.Message -match 'aliases reserved source path')
    }
    Assert-Contract $evidenceSourceRejected `
        "evidence output should not alias and overwrite the restored source"
    Assert-Contract ([Convert]::ToBase64String([System.IO.File]::ReadAllBytes($variantSource)) -eq
        [Convert]::ToBase64String($sourceBytesBeforeOutputChecks)) `
        "rejected evidence/source alias should preserve source bytes"

    $resultPlanParameters = @{}
    foreach ($key in $variantParameters.Keys) {
        $resultPlanParameters[$key] = $variantParameters[$key]
    }
    $resultPlanParameters.ResultCsvPath = $planPath
    $resultPlanParameters.EvidenceJsonPath = $safeOutputEvidence
    $resultPlanRejected = $false
    try {
        [void](& $variantScript @resultPlanParameters 2>&1)
    } catch {
        $resultPlanRejected = ($_.Exception.Message -match 'aliases reserved plan path')
    }
    Assert-Contract $resultPlanRejected `
        "result output should not alias and overwrite its input plan"
    Assert-Contract ([Convert]::ToBase64String([System.IO.File]::ReadAllBytes($planPath)) -eq
        [Convert]::ToBase64String($planBytesBeforeOutputChecks)) `
        "rejected result/plan alias should preserve plan bytes"

    $outputAliasParameters = @{}
    foreach ($key in $variantParameters.Keys) {
        $outputAliasParameters[$key] = $variantParameters[$key]
    }
    $outputAliasParameters.ResultCsvPath = $safeOutputResult
    $outputAliasParameters.EvidenceJsonPath = $safeOutputResult
    $outputAliasRejected = $false
    try {
        [void](& $variantScript @outputAliasParameters 2>&1)
    } catch {
        $outputAliasRejected = ($_.Exception.Message -match 'must be distinct files')
    }
    Assert-Contract $outputAliasRejected `
        "result and evidence outputs should not alias one another"

    $trackedOutputParameters = @{}
    foreach ($key in $variantParameters.Keys) {
        $trackedOutputParameters[$key] = $variantParameters[$key]
    }
    $trackedOutputParameters.ResultCsvPath = Join-Path $repoRoot "tools\otmatch\unsafe-runner-output.csv"
    $trackedOutputParameters.EvidenceJsonPath = $safeOutputEvidence
    $trackedOutputRejected = $false
    try {
        [void](& $variantScript @trackedOutputParameters 2>&1)
    } catch {
        $trackedOutputRejected = ($_.Exception.Message -match 'ignored a/ or artifacts/ roots')
    }
    Assert-Contract $trackedOutputRejected `
        "tracked-tree runner outputs should fail closed"

    $externalOutputParameters = @{}
    foreach ($key in $variantParameters.Keys) {
        $externalOutputParameters[$key] = $variantParameters[$key]
    }
    $externalOutputParameters.ResultCsvPath = Join-Path $externalVariantRoot "external.csv"
    $externalOutputParameters.EvidenceJsonPath = $safeOutputEvidence
    $externalOutputRejected = $false
    try {
        [void](& $variantScript @externalOutputParameters 2>&1)
    } catch {
        $externalOutputRejected = ($_.Exception.Message -match 'ignored a/ or artifacts/ roots')
    }
    Assert-Contract $externalOutputRejected `
        "external runner outputs should fail closed"

    $outputJunction = Join-Path $variantRoot "output-junction"
    [void](New-Item -ItemType Junction -Path $outputJunction -Target $externalVariantRoot)
    $reparseOutputParameters = @{}
    foreach ($key in $variantParameters.Keys) {
        $reparseOutputParameters[$key] = $variantParameters[$key]
    }
    $reparseOutputParameters.ResultCsvPath = Join-Path $outputJunction "nested.csv"
    $reparseOutputParameters.EvidenceJsonPath = $safeOutputEvidence
    $reparseOutputRejected = $false
    try {
        [void](& $variantScript @reparseOutputParameters 2>&1)
    } catch {
        $reparseOutputRejected = ($_.Exception.Message -match 'cannot traverse reparse point')
    } finally {
        [System.IO.Directory]::Delete($outputJunction)
    }
    Assert-Contract $reparseOutputRejected `
        "runner outputs should not escape through a directory junction"
    Assert-Contract (-not (Test-Path -LiteralPath $safeOutputResult) -and
        -not (Test-Path -LiteralPath $safeOutputEvidence)) `
        "invalid output checks should not create or delete unrelated safe targets"

    $unsafePlanPath = Join-Path $variantRoot "unsafe-plan.json"
    $unsafePlan = [pscustomobject][ordered]@{
        sourcePath = $externalVariantSource
        originalRva = "0x0"
        size = "0x4"
        candidateSymbol = "_ExternalShape"
        variants = @([pscustomobject]@{
                name = "unsafe"
                replacements = @()
            })
    }
    Write-Utf8Text $unsafePlanPath (($unsafePlan | ConvertTo-Json -Depth 8) + "`n")
    $unsafeParameters = @{}
    foreach ($key in $variantParameters.Keys) {
        $unsafeParameters[$key] = $variantParameters[$key]
    }
    $unsafeParameters.PlanPath = $unsafePlanPath
    $externalSourceRejected = $false
    try {
        [void](& $variantScript @unsafeParameters 2>&1)
    } catch {
        $externalSourceRejected = ($_.Exception.Message -match 'must remain inside the repository')
    }
    Assert-Contract $externalSourceRejected `
        "variant runner should reject external sources before locking or building"

    $sourceJunction = Join-Path $variantRoot "source-junction"
    [void](New-Item -ItemType Junction -Path $sourceJunction -Target $externalVariantRoot)
    $unsafePlan.sourcePath = Join-Path $sourceJunction "external.cpp"
    Write-Utf8Text $unsafePlanPath (($unsafePlan | ConvertTo-Json -Depth 8) + "`n")
    $reparseSourceRejected = $false
    try {
        [void](& $variantScript @unsafeParameters 2>&1)
    } catch {
        $reparseSourceRejected = ($_.Exception.Message -match 'cannot traverse reparse point')
    } finally {
        [System.IO.Directory]::Delete($sourceJunction)
    }
    Assert-Contract $reparseSourceRejected `
        "variant runner should reject source paths beneath a reparse point"

    $productionParameters = @{}
    foreach ($key in $variantParameters.Keys) {
        if ($key -ne "BuildScriptOverride") {
            $productionParameters[$key] = $variantParameters[$key]
        }
    }
    $productionFixtureRejected = $false
    try {
        [void](& $variantScript @productionParameters 2>&1)
    } catch {
        $productionFixtureRejected = ($_.Exception.Message -match
            'not part of the default.*candidate graph')
    }
    Assert-Contract $productionFixtureRejected `
        "production variant sessions should accept only the default src/otwin graph"
    Assert-Contract (-not (Test-Path -LiteralPath $variantBuildLog -PathType Leaf)) `
        "unsafe source plans should be rejected before invoking a build"

    # A pre-variant fixed-point failure must invalidate any stale prior success
    # rather than leaving promotion evidence at the requested output paths.
    Write-Utf8Text $variantResults "stale result`n"
    Write-Utf8Text $variantEvidence '{"promotion_eligible":true}'
    [Environment]::SetEnvironmentVariable(
        "OTMATCH_FAKE_NONCONVERGING_STABILITY", "1", "Process")
    $nonconvergingBoundaryRejected = $false
    $nonconvergingBoundaryMessage = ""
    try {
        [void](& $variantScript @variantParameters 2>&1)
    } catch {
        $nonconvergingBoundaryMessage = $_.Exception.Message
        $nonconvergingBoundaryRejected = ($_.Exception.Message -match
            'did not reach a reproducible two-relink fixed point')
    } finally {
        [Environment]::SetEnvironmentVariable(
            "OTMATCH_FAKE_NONCONVERGING_STABILITY", $null, "Process")
    }
    Assert-Contract $nonconvergingBoundaryRejected `
        "nonconverging focused relinks should fail before variant mutation"
    Assert-Contract ($nonconvergingBoundaryMessage -match
        'DLL normalized relink1=[0-9a-f]{64} relink2=[0-9a-f]{64}') `
        "fixed-point failures should name the mismatched boundary and both hashes"
    Assert-Contract ([Convert]::ToBase64String([System.IO.File]::ReadAllBytes($variantSource)) -eq
        [Convert]::ToBase64String($sourceBytesBeforeOutputChecks)) `
        "fixed-point failure should preserve the original source"
    Assert-Contract (-not (Test-Path -LiteralPath $variantResults) -and
        -not (Test-Path -LiteralPath $variantEvidence)) `
        "pre-variant failure should remove stale result and promotion evidence"
    Assert-Contract ((Get-LineCount $variantBuildLog) -eq 3 -and
        -not (Test-Path -LiteralPath $variantDiffLog -PathType Leaf)) `
        "fixed-point failure should stop after the normal seed and two relinks"
    Remove-Item -LiteralPath $variantBuildLog -Force

    $variantOutput = & $variantScript @variantParameters 2>&1
    $buildCalls = @(Get-Content -LiteralPath $variantBuildLog | ForEach-Object { $_ | ConvertFrom-Json })
    Assert-Contract ($buildCalls.Count -eq 6) `
        "baseline, two stability relinks, two variants, and restoration should perform six builds"
    Assert-Contract (@($buildCalls[0].changedSource).Count -eq 0 -and -not [bool]$buildCalls[0].focused) `
        "variant runner should seed a normal baseline build"
    foreach ($stabilityCall in @($buildCalls[1], $buildCalls[2])) {
        Assert-Contract (@($stabilityCall.changedSource) -contains $variantSource -and
            [bool]$stabilityCall.focused -and
            [bool]$stabilityCall.trustedGraph -and
            [bool]$stabilityCall.forceMainRelink) `
            "baseline stabilization should force two trusted focused relinks"
    }
    Assert-Contract (@($buildCalls[3].changedSource) -contains $variantSource -and
        [bool]$buildCalls[3].focused -and [bool]$buildCalls[3].trustedGraph -and
        -not [bool]$buildCalls[3].forceMainRelink) `
        "first variant should use focused mode for its changed TU"
    Assert-Contract (@($buildCalls[4].changedSource) -contains $variantSource -and
        [bool]$buildCalls[4].focused -and [bool]$buildCalls[4].trustedGraph -and
        -not [bool]$buildCalls[4].forceMainRelink) `
        "second variant should use focused mode for its changed TU"
    Assert-Contract (@($buildCalls[5].changedSource) -contains $variantSource -and
        [bool]$buildCalls[5].focused -and -not [bool]$buildCalls[5].rebuild -and
        -not [bool]$buildCalls[5].trustedGraph -and
        -not [bool]$buildCalls[5].forceMainRelink) `
        "restored source should receive a focused rebuild"
    foreach ($call in $buildCalls) {
        Assert-Contract (@($call.extraCompileFlags).Count -eq 2) "every build should receive both compile flags"
        Assert-Contract (@($call.extraCompileFlags) -contains "/DVARIANT_ALPHA=1") "first compile flag should survive native array binding"
        Assert-Contract (@($call.extraCompileFlags) -contains "/DVARIANT_BETA=2") "second compile flag should survive native array binding"
        Assert-Contract (@($call.extraLinkFlags).Count -eq 2) "every build should receive both link flags"
        Assert-Contract (@($call.extraLinkFlags) -contains "/ALIGN:4096") "first link flag should survive native array binding"
        Assert-Contract (@($call.extraLinkFlags) -contains "/COMMENT:variant-contract") "second link flag should survive native array binding"
        Assert-Contract ([bool]$call.candidateGraphLockHeld) `
            "nested variant builds should inherit the exclusive candidate-graph lock"
    }
    $diffCalls = @(Get-Content -LiteralPath $variantDiffLog | ForEach-Object { $_ | ConvertFrom-Json })
    Assert-Contract ($diffCalls.Count -eq 3) "baseline and each variant should run one byte diff"
    Assert-Contract ($diffCalls[1].candidatePath -eq $variantCandidate) `
        "default candidate path should derive from BuildOutputDirectory"
    Assert-Contract ($diffCalls[1].candidateMapPath -eq $variantMap) `
        "default candidate map should derive from BuildOutputDirectory"
    Assert-Contract (@($diffCalls | Where-Object { $_.mask -ne "1-2" }).Count -eq 0) `
        "baseline and variant diffs should receive the plan mask"
    Assert-Contract ([System.IO.File]::ReadAllText($variantSource) -eq "int ShapeValue() { return 0; }`n") "variant source bytes should be restored"
    Assert-Contract (Test-Path -LiteralPath $variantResults -PathType Leaf) `
        "default variant CSV should use a stable path under BuildOutputDirectory"
    Assert-Contract (@(Import-Csv -LiteralPath $variantResults).Count -eq 2) "variant results should retain both trials"
    $variantRows = @(Import-Csv -LiteralPath $variantResults)
    Assert-Contract (@($variantRows | Where-Object {
                [string]::IsNullOrWhiteSpace($_.SourceSha256) -or
                [string]::IsNullOrWhiteSpace($_.BuildDurationMs) -or
                [string]::IsNullOrWhiteSpace($_.DiffDurationMs) -or
                [string]::IsNullOrWhiteSpace($_.HardDiffCount)
            }).Count -eq 0) `
        "variant rows should retain hashes, timings, and hard residuals"
    Assert-Contract ($variantRows[0].Hypothesis -eq "non-meaningful control" -and
        $variantRows[0].Meaningful -eq "False" -and
        $variantRows[1].Hypothesis -eq "promotion shape" -and
        $variantRows[1].Meaningful -eq "True") `
        "variant rows should retain hypothesis and meaningful-trial evidence"
    Assert-Contract (Test-Path -LiteralPath $variantEvidence -PathType Leaf) `
        "successful restored sessions should emit schema-1 evidence beside the CSV"
    $evidence = Get-Content -LiteralPath $variantEvidence -Raw | ConvertFrom-Json
    Assert-Contract ([int]$evidence.schema_version -eq 1 -and
        $evidence.artifact_type -eq "otwin-source-shape-evidence") `
        "variant evidence should use the strict source-shape schema"
    $expectedRunnerSha256 = (Get-FileHash -LiteralPath $variantScript `
        -Algorithm SHA256).Hash.ToLowerInvariant()
    Assert-Contract ($evidence.runner.name -eq "otmatch-source-shape-runner" -and
        [int]$evidence.runner.schema_version -eq 1 -and
        $evidence.runner.script_path -eq
            "tools/otmatch/invoke-source-shape-variants.ps1" -and
        $evidence.runner.script_sha256 -eq $expectedRunnerSha256) `
        "variant evidence should bind the current source-shape runner"
    Assert-Contract ($evidence.identity.key -eq "oregon32.exe|0x0" -and
        $evidence.identity.program -eq "Oregon32.exe" -and
        $evidence.identity.name -eq "ShapeValue" -and
        $evidence.identity.original_rva -eq "0x0") `
        "variant evidence should bind canonical plan identity"
    Assert-Contract ($evidence.checkpoint.checkpoint_id -eq "contract-checkpoint-1" -and
        $evidence.checkpoint.prior_boundary_run_id -eq "contract-boundary-1") `
        "variant evidence should bind checkpoint and prior boundary IDs"
    Assert-Contract ($evidence.successful_trial.variant -eq "two" -and
        [int]$evidence.successful_trial.hard_diff_count -eq 0 -and
        [int]$evidence.successful_trial.hard_compared_bytes -eq 2) `
        "variant evidence should select the first meaningful hypothesized zero-hard trial"
    Assert-Contract ([bool]$evidence.restoration.attempted -and
        [bool]$evidence.restoration.passed -and
        -not [bool]$evidence.restoration.used_trusted_graph -and
        $evidence.restoration.baseline_candidate_normalized_sha256 -eq
            $evidence.restoration.restored_candidate_normalized_sha256 -and
        $evidence.restoration.baseline_map_normalized_sha256 -eq
            $evidence.restoration.restored_map_normalized_sha256 -and
        $evidence.restoration.baseline_object_sha256 -eq
            $evidence.restoration.restored_object_sha256) `
        "evidence should retain successful non-trusting restoration hashes"
    Assert-Contract ([bool]$evidence.promotion_eligible) `
        "identity-bound zero-hard evidence should become eligible only after restoration"

    $stopLossPlanPath = Join-Path $variantRoot "stop-loss-plan.json"
    $stopLossVariants = @()
    foreach ($variantNumber in 1..4) {
        $stopLossVariants += [pscustomobject]@{
            name = "stop-$variantNumber"
            meaningful = $true
            replacements = @([pscustomobject]@{
                    old = "return 0"
                    new = "return $variantNumber"
                })
        }
    }
    $stopLossPlan = [pscustomobject][ordered]@{
        sourcePath = $variantSource
        originalRva = "0x0"
        size = "0x4"
        candidateSymbol = "_ShapeValue"
        mask = "1-2"
        variants = $stopLossVariants
    }
    Write-Utf8Text $stopLossPlanPath (($stopLossPlan | ConvertTo-Json -Depth 8) + "`n")
    $stopLossResults = Join-Path $variantRoot "stop-loss-results.csv"
    $stopLossParameters = @{}
    foreach ($key in $variantParameters.Keys) {
        $stopLossParameters[$key] = $variantParameters[$key]
    }
    $stopLossParameters.PlanPath = $stopLossPlanPath
    $stopLossParameters.ResultCsvPath = $stopLossResults
    $stopLossParameters.MaxNoImprovementVariants = 2
    [void](& $variantScript @stopLossParameters -NoRestoreBuild 2>&1)
    Assert-Contract (@(Import-Csv -LiteralPath $stopLossResults).Count -eq 2) `
        "the configured non-improvement limit should stop a longer plan"
    $stopLossEvidencePath = [System.IO.Path]::ChangeExtension(
        $stopLossResults,
        "evidence.json")
    $stopLossEvidence = Get-Content -LiteralPath $stopLossEvidencePath -Raw |
        ConvertFrom-Json
    Assert-Contract (-not [bool]$stopLossEvidence.promotion_eligible -and
        -not [bool]$stopLossEvidence.restoration.attempted -and
        [string]::IsNullOrWhiteSpace([string]$stopLossEvidence.identity.key) -and
        $null -eq $stopLossEvidence.successful_trial) `
        "identity-free, hypothesis-free, or unrestored diagnostic plans must fail closed for promotion"

    # The fake PE changes every documented VC4 time field and the validated
    # IMAGE_DEBUG_MISC.Reserved[3] bytes on every link. A restoration passes
    # when only those and the exact map timestamp change, but the adjacent first
    # data byte at IMAGE_DEBUG_MISC +12 must remain hash-significant.
    $nonTimePlanPath = Join-Path $variantRoot "non-time-plan.json"
    $nonTimePlan = [pscustomobject][ordered]@{}
    foreach ($property in $plan.PSObject.Properties) {
        $nonTimePlan | Add-Member -NotePropertyName $property.Name `
            -NotePropertyValue $property.Value
    }
    $nonTimePlan.variants = @($plan.variants | Select-Object -First 1)
    Write-Utf8Text $nonTimePlanPath (($nonTimePlan | ConvertTo-Json -Depth 8) + "`n")
    $nonTimeResults = Join-Path $variantRoot "non-time-results.csv"
    $nonTimeParameters = @{}
    foreach ($key in $variantParameters.Keys) {
        $nonTimeParameters[$key] = $variantParameters[$key]
    }
    $nonTimeParameters.PlanPath = $nonTimePlanPath
    $nonTimeParameters.ResultCsvPath = $nonTimeResults
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_NON_TIME_RESTORE", "1", "Process")
    $nonTimeMutationRejected = $false
    try {
        [void](& $variantScript @nonTimeParameters 2>&1)
    } catch {
        $nonTimeMutationRejected = ($_.Exception.Message -match
            'normalizing VC4 linker timestamps')
    } finally {
        [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_NON_TIME_RESTORE", $null, "Process")
    }
    Assert-Contract $nonTimeMutationRejected `
        "PE normalization should retain a non-time negative-control mutation"
    $nonTimeEvidence = Get-Content -LiteralPath (
        [System.IO.Path]::ChangeExtension($nonTimeResults, "evidence.json")) -Raw |
        ConvertFrom-Json
    Assert-Contract ([bool]$nonTimeEvidence.restoration.attempted -and
        -not [bool]$nonTimeEvidence.restoration.passed -and
        -not [bool]$nonTimeEvidence.promotion_eligible -and
        $nonTimeEvidence.restoration.baseline_candidate_normalized_sha256 -ne
            $nonTimeEvidence.restoration.restored_candidate_normalized_sha256 -and
        $nonTimeEvidence.restoration.baseline_map_normalized_sha256 -ne
            $nonTimeEvidence.restoration.restored_map_normalized_sha256) `
        "non-time restoration mismatches should remain durable and ineligible"

    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_DIFF_FAIL", "1", "Process")
    Remove-Item -LiteralPath $variantBuildLog, $variantDiffLog -Force
    [void](& $variantScript @variantParameters -NoRestoreBuild 2>&1)
    $failedDiffRows = @(Import-Csv -LiteralPath $variantResults)
    Assert-Contract (@($failedDiffRows | Where-Object { $_.Status -notmatch '^FAIL:.*exit code 17' }).Count -eq 0) `
        ("nonzero byte-diff exits should mark every affected variant as failed; observed: " +
            (@($failedDiffRows | ForEach-Object {
                "{0}={1}" -f $_.Variant, (($_.Status -replace '[\r\n]+', ' ').Trim())
            }) -join "; "))

    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_DIFF_FAIL", $null, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_RESTORE_FAIL", "1", "Process")
    $explicitVariantResults = Join-Path $variantRoot "explicit\nested\results.csv"
    $restoreVariantParameters = @{}
    foreach ($key in $variantParameters.Keys) {
        $restoreVariantParameters[$key] = $variantParameters[$key]
    }
    $restoreVariantParameters.ResultCsvPath = $explicitVariantResults
    [Environment]::SetEnvironmentVariable("OTMATCH_EXPECT_CHECKPOINT_PATH", $explicitVariantResults, "Process")
    $restoreFailureObserved = $false
    try {
        [void](& $variantScript @restoreVariantParameters 2>&1)
    } catch {
        $restoreFailureObserved = ($_.Exception.Message -match 'forced restoration build failure')
    }
    Assert-Contract $restoreFailureObserved "restoration build failure should propagate to the caller"
    Assert-Contract (@(Import-Csv -LiteralPath $explicitVariantResults).Count -eq 2) `
        "completed variant rows should persist before restoration build failure propagates"
    Assert-Contract ([System.IO.File]::ReadAllText($variantSource) -eq "int ShapeValue() { return 0; }`n") `
        "source bytes should remain restored when the restoration build fails"
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_RESTORE_FAIL", $null, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_EXPECT_CHECKPOINT_PATH", $null, "Process")

    Write-Host "Build-cache and source-shape variant contract: PASS"
} finally {
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_CL_LOG", $oldCompilerLog, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_LINK_LOG", $oldLinkerLog, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_CANDIDATE", $oldCandidatePath, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_MAP", $oldMapPath, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_VARIANT_BUILD_LOG", $oldVariantBuildLog, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_VARIANT_DIFF_LOG", $oldVariantDiffLog, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_DIFF_FAIL", $oldFakeDiffFail, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_RESTORE_FAIL", $oldFakeRestoreFail, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_SKIP_MAIN_EXP", $oldFakeSkipMainExp, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_CL_DELAY_MS", $oldFakeCompileDelay, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_CL_BARRIER_ROOT", $oldFakeCompileBarrierRoot, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_CL_BARRIER_SOURCE", $oldFakeCompileBarrierSource, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_CONTRACT_EXIT_CODE_PATH", $oldContractExitCodePath, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_EXPECT_CHECKPOINT_PATH", $oldExpectedCheckpoint, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_VARIANT_SOURCE", $oldVariantSource, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_VARIANT_REPO_ROOT", $oldVariantRepoRoot, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_NON_TIME_RESTORE", $oldFakeNonTimeRestore, "Process")
    [Environment]::SetEnvironmentVariable("OTMATCH_FAKE_NONCONVERGING_STABILITY", $oldFakeNonconvergingStability, "Process")
    if ($null -ne $backgroundProcess -and -not $backgroundProcess.HasExited) {
        Stop-Process -Id $backgroundProcess.Id -Force
    }
    if (-not [string]::IsNullOrWhiteSpace($escapeSentinelRoot) -and
        (Test-Path -LiteralPath $escapeSentinelRoot -PathType Container)) {
        $resolvedEscapeRoot = [System.IO.Path]::GetFullPath($escapeSentinelRoot)
        $repoPrefix = $repoRoot.TrimEnd('\') + '\'
        if (-not $resolvedEscapeRoot.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase) -or
            (Split-Path -Leaf $resolvedEscapeRoot) -notlike 'output-escape-contract-*') {
            throw "Refusing to clean unexpected output-escape fixture '$resolvedEscapeRoot'."
        }
        Remove-Item -LiteralPath $resolvedEscapeRoot -Recurse -Force
    }
    if (-not [string]::IsNullOrWhiteSpace($externalVariantRoot) -and
        (Test-Path -LiteralPath $externalVariantRoot -PathType Container)) {
        $resolvedExternalRoot = [System.IO.Path]::GetFullPath($externalVariantRoot)
        $temporaryPrefix = [System.IO.Path]::GetFullPath(
            [System.IO.Path]::GetTempPath()).TrimEnd('\') + '\'
        if (-not $resolvedExternalRoot.StartsWith(
                $temporaryPrefix,
                [System.StringComparison]::OrdinalIgnoreCase) -or
            (Split-Path -Leaf $resolvedExternalRoot) -notlike 'otmatch-source-contract-*') {
            throw "Refusing to clean unexpected external source fixture '$resolvedExternalRoot'."
        }
        Remove-Item -LiteralPath $resolvedExternalRoot -Recurse -Force
    }
    if (-not $KeepFixture -and (Test-Path -LiteralPath $fixtureRoot -PathType Container)) {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force
    }
}
