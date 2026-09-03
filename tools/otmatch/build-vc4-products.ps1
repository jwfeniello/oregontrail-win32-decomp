[CmdletBinding()]
param(
    [ValidateSet("Oregon32Dll", "Oregon32Exe")]
    [string]$Target = "Oregon32Dll",

    [string]$OutputDirectory = "artifacts\otmatch\vc4-products",

    [string]$VcToolsRoot = "C:\MSDEV",
    [string]$ClPath = "",
    [string]$LinkPath = "",
    [string[]]$IncludePath = @(),
    [string[]]$LibPath = @(),

    # ResourceRoot contains the ignored oregon32_dll/ and oregon32_exe/ trees.
    # ResourcePath overrides ResourceRoot when the selected .res lives elsewhere.
    [string]$ResourceRoot = "resources\otwin32",
    [string]$ResourcePath = "",

    # Oregon32Exe reuses the VC4 objects produced by build-match-candidates.ps1.
    # Product mode selects only the explicit canonical source manifest;
    # Exhaustive mode is the separate recovery-probe closure diagnostic.
    [string]$CandidateObjectDirectory = "artifacts\otmatch\vc40",

    [ValidateSet("Product", "Exhaustive")]
    [string]$ExeGraph = "Product",

    [string]$ExeProductManifestPath = "tools\otmatch\vc4-exe-product-sources.txt",

    # The strict EXE link is the default. This opt-in asks LINK to emit a
    # non-runnable diagnostic PE even when pure-C++ dependencies are missing.
    [switch]$AllowUnresolvedDiagnostic
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

function Get-AbsolutePath {
    param([string]$Path)

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
}

function Resolve-FirstExistingFile {
    param(
        [string[]]$Candidates,
        [string]$Description
    )

    foreach ($candidate in $Candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }

        $absolute = Get-AbsolutePath $candidate
        if (Test-Path -LiteralPath $absolute -PathType Leaf) {
            return (Resolve-Path -LiteralPath $absolute).Path
        }
    }

    throw "$Description was not found. Tried: $($Candidates -join '; ')"
}

function Get-ExistingDirectories {
    param([string[]]$Candidates)

    $result = @()
    foreach ($candidate in $Candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }

        $absolute = Get-AbsolutePath $candidate
        if (Test-Path -LiteralPath $absolute -PathType Container) {
            $result += (Resolve-Path -LiteralPath $absolute).Path
        }
    }

    return $result
}

function Prepend-EnvironmentList {
    param(
        [string]$Name,
        [string[]]$Paths
    )

    $resolved = @(Get-ExistingDirectories $Paths)
    if ($resolved.Count -eq 0) {
        return
    }

    $current = [Environment]::GetEnvironmentVariable($Name, "Process")
    $combined = if ([string]::IsNullOrWhiteSpace($current)) {
        $resolved
    } else {
        $resolved + @($current)
    }
    [Environment]::SetEnvironmentVariable($Name, ($combined -join ";"), "Process")
}

function Test-PathWithinRepo {
    param([string]$AbsolutePath)

    $repoPrefix = $repoRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    return $AbsolutePath.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)
}

function Assert-RepoPathIgnored {
    param(
        [string]$AbsolutePath,
        [string]$Description
    )

    if (-not (Test-PathWithinRepo $AbsolutePath)) {
        return
    }

    $relative = $AbsolutePath.Substring($repoRoot.Length).TrimStart('\', '/')
    & git -C $repoRoot check-ignore --quiet -- $relative
    if ($LASTEXITCODE -ne 0) {
        throw "$Description is inside the repository but is not ignored: '$relative'. Use an ignored path or a path outside the repository."
    }
}

function Assert-Vc4Tool {
    param(
        [string]$Path,
        [string]$Description,
        [string]$ExpectedFileVersionPrefix
    )

    $version = (Get-Item -LiteralPath $Path).VersionInfo
    if (-not $version.ProductVersion.StartsWith("4.0") -or
        -not $version.FileVersion.StartsWith($ExpectedFileVersionPrefix)) {
        throw "$Description is not the expected Visual C++ 4.0 tool: '$Path' (file $($version.FileVersion), product $($version.ProductVersion))."
    }

    return $version
}

function Resolve-Vc4Library {
    param(
        [string]$Name,
        [string[]]$Directories
    )

    $candidates = @($Directories | ForEach-Object { Join-Path $_ $Name })
    return Resolve-FirstExistingFile $candidates "Visual C++ 4.0 $Name"
}

function Test-SourceContainsInlineAssembly {
    param(
        [string]$Path,
        [hashtable]$Visited = $null
    )

    if ($null -eq $Visited) {
        $Visited = @{}
    }

    $absolutePath = [System.IO.Path]::GetFullPath($Path)
    $visitKey = $absolutePath.ToLowerInvariant()
    if ($Visited.ContainsKey($visitKey)) {
        return $false
    }
    $Visited[$visitKey] = $true

    $sourceText = [System.IO.File]::ReadAllText($absolutePath)
    $nonCodePattern = @'
(?s)/\*.*?\*/|//[^\r\n]*|"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'
'@
    $codeText = [System.Text.RegularExpressions.Regex]::Replace(
        $sourceText,
        $nonCodePattern,
        " "
    )
    if ([System.Text.RegularExpressions.Regex]::IsMatch(
        $codeText,
        '(?i)(?<![A-Za-z0-9_])(?:__asm|_asm|_emit)(?![A-Za-z0-9_])|__declspec\s*\(\s*naked\s*\)'
    )) {
        return $true
    }

    # A product .cpp may textually include another local implementation file.
    # Follow every quoted include that resolves on disk so an otherwise-clean
    # shim cannot hide ASM in its transitive translation-unit closure.
    $commentFreeText = [System.Text.RegularExpressions.Regex]::Replace(
        $sourceText,
        '(?s)/\*.*?\*/|//[^\r\n]*',
        ' '
    )
    $includeMatches = [System.Text.RegularExpressions.Regex]::Matches(
        $commentFreeText,
        '(?m)^\s*#\s*include\s*"(?<path>[^"]+)"'
    )
    foreach ($includeMatch in $includeMatches) {
        $includePath = Join-Path `
            (Split-Path -Parent $absolutePath) `
            $includeMatch.Groups['path'].Value
        if (Test-Path -LiteralPath $includePath -PathType Leaf) {
            if (Test-SourceContainsInlineAssembly $includePath $Visited) {
                return $true
            }
        }
    }

    return $false
}

function Get-ExeProductManifestSources {
    param([string]$Path)

    $absolutePath = Get-AbsolutePath $Path
    if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
        throw "EXE product source manifest was not found: '$absolutePath'."
    }

    $sources = @()
    $seen = @{}
    $lineNumber = 0
    foreach ($line in [System.IO.File]::ReadAllLines($absolutePath)) {
        $lineNumber++
        $source = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($source) -or $source.StartsWith("#")) {
            continue
        }

        $source = $source -replace '\\', '/'
        if ($source -notmatch '^src/otwin/(?!_exact/|_recovery/|dll/).+\.cpp$' -or
            $source -like '*_notes.cpp' -or
            $source.Contains("../") -or
            [System.IO.Path]::IsPathRooted($source)) {
            throw "Invalid product source '$source' at ${absolutePath}:$lineNumber."
        }

        $key = $source.ToLowerInvariant()
        if ($seen.ContainsKey($key)) {
            throw "Duplicate product source '$source' at ${absolutePath}:$lineNumber."
        }
        $seen[$key] = $true

        $sourcePath = Get-AbsolutePath $source
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
            throw "Product source '$source' from '$absolutePath' does not exist."
        }
        if (Test-SourceContainsInlineAssembly $sourcePath) {
            throw "Product source closure '$source' contains inline assembly, emitted bytes, or a naked function and is not eligible for the canonical graph."
        }
        $sources += $source
    }

    if ($sources.Count -eq 0) {
        throw "EXE product source manifest '$absolutePath' is empty."
    }

    return [pscustomobject]@{
        Path = $absolutePath
        Sources = @($sources)
    }
}

function Get-ExeCandidateObjectRecords {
    param(
        [string]$ObjectDirectory,
        [ValidateSet("Product", "Exhaustive")]
        [string]$Graph,
        [string[]]$ProductSources = @()
    )

    # Use current source files as the authority so stale objects left behind by
    # renamed/deleted probes are never pulled into the product-WIP image. The
    # ordering mirrors build-match-candidates.ps1 closely enough to retain its
    # current exact/recovery/product candidate layout.
    $sourceRoot = Join-Path $repoRoot "src\otwin"
    $sourceFiles = @(Get-ChildItem -LiteralPath $sourceRoot -Filter *.cpp -File -Recurse)
    $records = @()
    $excludedExact = @()
    $excludedRecovery = @()
    $excludedInlineAssembly = @()
    $unmanifestedProduct = @()
    $productSourceSet = @{}
    foreach ($productSource in $ProductSources) {
        $productSourceSet[$productSource.ToLowerInvariant()] = $true
    }
    foreach ($sourceFile in $sourceFiles) {
        $trackedPath = $sourceFile.FullName.Substring($repoRoot.Length).TrimStart('\', '/') -replace '\\', '/'
        if ($trackedPath -notlike '*.cpp' -or
            $trackedPath -like '*_notes.cpp' -or
            $trackedPath -like 'src/otwin/dll/*') {
            continue
        }

        # _exact is legacy byte scaffolding and is not eligible for a pure-C++
        # product graph, even when an individual translation unit happens not
        # to contain an inline-assembly token.
        if ($trackedPath -like 'src/otwin/_exact/*') {
            $excludedExact += $trackedPath
            continue
        }

        $kind = if ($trackedPath -like 'src/otwin/_recovery/*') {
            "recovery"
        } else {
            "product"
        }

        if ($Graph -eq "Product") {
            if ($kind -eq "recovery") {
                $excludedRecovery += $trackedPath
                continue
            }
            if (-not $productSourceSet.ContainsKey($trackedPath.ToLowerInvariant())) {
                $unmanifestedProduct += $trackedPath
                continue
            }
        }

        $sourcePath = $sourceFile.FullName
        if (Test-SourceContainsInlineAssembly $sourcePath) {
            $excludedInlineAssembly += $trackedPath
            continue
        }

        $sortKey = $trackedPath
        if ($trackedPath -match '^src/otwin/_recovery/root/(.+)$') {
            $sortKey = "src/otwin/$($Matches[1])"
        } elseif ($trackedPath -match '^src/otwin/_recovery/([^/]+)/(.+)$') {
            $sortKey = "src/otwin/$($Matches[1])/$($Matches[2])"
        }

        $objectName = (($trackedPath -replace '/', '_') -replace '\.cpp$', '.obj')
        $objectPath = Join-Path $ObjectDirectory $objectName
        if (-not (Test-Path -LiteralPath $objectPath -PathType Leaf)) {
            throw "VC4 candidate object is missing for '$trackedPath': '$objectPath'. Run build-match-candidates.ps1 first."
        }

        $sourceInfo = Get-Item -LiteralPath $sourcePath
        $objectInfo = Get-Item -LiteralPath $objectPath
        if ($objectInfo.LastWriteTimeUtc -lt $sourceInfo.LastWriteTimeUtc) {
            throw "VC4 candidate object is older than '$trackedPath': '$objectPath'. Run build-match-candidates.ps1 first."
        }

        $records += [pscustomobject]@{
            Source = $trackedPath
            ObjectName = $objectName
            SortKey = $sortKey
            Kind = $kind
        }
    }

    if ($Graph -eq "Product" -and $unmanifestedProduct.Count -gt 0) {
        throw "Product-tree C++ sources are missing from the canonical EXE manifest: $($unmanifestedProduct -join ', ')."
    }
    if ($Graph -eq "Product" -and $records.Count -ne $ProductSources.Count) {
        throw "Canonical EXE manifest selected $($ProductSources.Count) sources but only $($records.Count) eligible object records were found."
    }

    return [pscustomobject]@{
        Records = @($records | Sort-Object SortKey, Source)
        ExcludedExact = @($excludedExact | Sort-Object)
        ExcludedRecovery = @($excludedRecovery | Sort-Object)
        ExcludedInlineAssembly = @($excludedInlineAssembly | Sort-Object)
    }
}

function ConvertTo-LinkResponseArgument {
    param([string]$Argument)

    if ($Argument -match '[\s"]') {
        return '"' + ($Argument -replace '"', '\"') + '"'
    }

    return $Argument
}

$rootCandidates = @()
if (-not [string]::IsNullOrWhiteSpace($VcToolsRoot)) {
    $vcRoot = Get-AbsolutePath $VcToolsRoot
    $rootCandidates += $vcRoot
    $rootCandidates += (Join-Path $vcRoot "MSDEV")
    $rootCandidates += (Join-Path $vcRoot "VC")
}

$clCandidates = @()
if (-not [string]::IsNullOrWhiteSpace($ClPath)) {
    $clCandidates += $ClPath
}
foreach ($rootCandidate in $rootCandidates) {
    $clCandidates += (Join-Path $rootCandidate "bin\cl.exe")
    $clCandidates += (Join-Path $rootCandidate "cl.exe")
}

$linkCandidates = @()
if (-not [string]::IsNullOrWhiteSpace($LinkPath)) {
    $linkCandidates += $LinkPath
}
foreach ($rootCandidate in $rootCandidates) {
    $linkCandidates += (Join-Path $rootCandidate "bin\link.exe")
    $linkCandidates += (Join-Path $rootCandidate "link.exe")
}

$cl = Resolve-FirstExistingFile $clCandidates "Visual C++ 4.0 cl.exe"
$link = Resolve-FirstExistingFile $linkCandidates "Visual C++ 4.0 link.exe"
$clVersion = Assert-Vc4Tool $cl "Compiler" "10.0"
$linkVersion = Assert-Vc4Tool $link "Linker" "3.0"

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

$libCandidates = @()
if ($LibPath.Count -gt 0) {
    $libCandidates += $LibPath
} else {
    foreach ($rootCandidate in $rootCandidates) {
        $libCandidates += (Join-Path $rootCandidate "lib")
        $libCandidates += (Join-Path $rootCandidate "mfc\lib")
    }
}
$resolvedLibDirectories = @(Get-ExistingDirectories $libCandidates)
if ($resolvedLibDirectories.Count -eq 0) {
    throw "No Visual C++ 4.0 library directory was found. Override -LibPath or -VcToolsRoot."
}

Prepend-EnvironmentList "PATH" @((Split-Path -Parent $cl), (Split-Path -Parent $link))
Prepend-EnvironmentList "INCLUDE" $includeCandidates
Prepend-EnvironmentList "LIB" $resolvedLibDirectories

switch ($Target) {
    "Oregon32Dll" {
        $resourceCandidate = if (-not [string]::IsNullOrWhiteSpace($ResourcePath)) {
            Get-AbsolutePath $ResourcePath
        } else {
            Join-Path (Get-AbsolutePath $ResourceRoot) "oregon32_dll\oregon32_dll.res"
        }
        $outputStem = "OREGON32-DLL-product-wip"
        $outputExtension = ".dll"
        $allowedResourceNames = @("oregon32_dll.res")
        $requiredLibraries = @("LIBCMT.LIB", "KERNEL32.LIB")
    }
    "Oregon32Exe" {
        if (-not [string]::IsNullOrWhiteSpace($ResourcePath)) {
            $resourceCandidate = Get-AbsolutePath $ResourcePath
        } else {
            $resourceDirectory = Join-Path (Get-AbsolutePath $ResourceRoot) "oregon32_exe"
            $preferredResource = Join-Path $resourceDirectory "oregon32_exe.res"
            $legacyResource = Join-Path $resourceDirectory "oregon32.res"
            $resourceCandidate = if (Test-Path -LiteralPath $preferredResource -PathType Leaf) {
                $preferredResource
            } else {
                $legacyResource
            }
        }
        $outputStem = if ($ExeGraph -eq "Exhaustive") {
            if ($AllowUnresolvedDiagnostic) {
                "Oregon32-EXE-exhaustive-unresolved-diagnostic"
            } else {
                "Oregon32-EXE-exhaustive-wip"
            }
        } elseif ($AllowUnresolvedDiagnostic) {
            "Oregon32-EXE-unresolved-diagnostic"
        } else {
            "Oregon32-EXE-product-wip"
        }
        $outputExtension = ".exe"
        # otresdump historically emitted oregon32.res. Prefer the unambiguous
        # product name while accepting that existing ignored output.
        $allowedResourceNames = @("oregon32_exe.res", "oregon32.res")
        $requiredLibraries = @(
            "LIBC.LIB",
            "KERNEL32.LIB",
            "USER32.LIB",
            "GDI32.LIB",
            "COMDLG32.LIB",
            "WINMM.LIB"
        )
    }
    default {
        throw "Unsupported product target '$Target'."
    }
}

if ($AllowUnresolvedDiagnostic -and $Target -ne "Oregon32Exe") {
    throw "-AllowUnresolvedDiagnostic is valid only with -Target Oregon32Exe."
}
if ($Target -ne "Oregon32Exe" -and $ExeGraph -ne "Product") {
    throw "-ExeGraph is valid only with -Target Oregon32Exe."
}

if (-not (Test-Path -LiteralPath $resourceCandidate -PathType Leaf)) {
    throw "The $Target product target requires its existing .res input at '$resourceCandidate'. Generate it in an ignored/external resource tree before building."
}
$resource = (Resolve-Path -LiteralPath $resourceCandidate).Path
$resourceName = [System.IO.Path]::GetFileName($resource)
$resourceNameAllowed = $false
foreach ($allowedResourceName in $allowedResourceNames) {
    if ($resourceName.Equals($allowedResourceName, [System.StringComparison]::OrdinalIgnoreCase)) {
        $resourceNameAllowed = $true
        break
    }
}
if (-not $resourceNameAllowed) {
    throw "Unexpected resource name for ${Target}: '$resourceName'. Expected one of: $($allowedResourceNames -join ', ')."
}
Assert-RepoPathIgnored $resource "Resource input"
if ($Target -eq "Oregon32Exe" -and
    $resourceName.Equals("oregon32.res", [System.StringComparison]::OrdinalIgnoreCase)) {
    Write-Warning "Using legacy otresdump name 'oregon32.res'; prefer 'oregon32_exe.res' for an unambiguous external product input."
}

$resolvedLibraries = @()
foreach ($requiredLibrary in $requiredLibraries) {
    $resolvedLibraries += Resolve-Vc4Library $requiredLibrary $resolvedLibDirectories
}

$outputPath = Get-AbsolutePath $OutputDirectory
Assert-RepoPathIgnored $outputPath "Output directory"
New-Item -ItemType Directory -Force -Path $outputPath | Out-Null

$imageName = "$outputStem$outputExtension"
$mapName = "$outputStem.map"
$imagePath = Join-Path $outputPath $imageName
$mapPath = Join-Path $outputPath $mapName

Write-Host "VC4 product-WIP build:"
Write-Host "  Target:   $Target"
Write-Host "  CL:       $cl (file $($clVersion.FileVersion), product $($clVersion.ProductVersion))"
Write-Host "  LINK:     $link (file $($linkVersion.FileVersion), product $($linkVersion.ProductVersion))"
Write-Host "  Resource: $resource"
foreach ($resolvedLibrary in $resolvedLibraries) {
    Write-Host "  Library:  $resolvedLibrary"
}

$linkWorkingDirectory = $outputPath
$productObjectCount = 0
$recoveryObjectCount = 0
$productManifest = $null
if ($Target -eq "Oregon32Dll") {
    Write-Host ""
    Write-Host "This first product target intentionally links the VC4 CRT startup and ignored"
    Write-Host "resource image directly. Recovered matcher aliases under src/otwin/dll are not"
    Write-Host "linked as product code; their CRT identities still need product-side cleanup."

    $linkArgs = @(
        "/NOLOGO",
        "/DLL",
        "/INCREMENTAL:NO",
        "/MACHINE:IX86",
        "/ENTRY:_DllMainCRTStartup@12",
        "/MAP:$mapName",
        "/OUT:$imageName",
        $resource
    )
    $linkArgs += $resolvedLibraries
} else {
    $candidateObjectPath = Get-AbsolutePath $CandidateObjectDirectory
    if (-not (Test-Path -LiteralPath $candidateObjectPath -PathType Container)) {
        throw "Candidate object directory was not found: '$candidateObjectPath'. Run build-match-candidates.ps1 first."
    }
    Assert-RepoPathIgnored $candidateObjectPath "Candidate object directory"

    $productSources = @()
    if ($ExeGraph -eq "Product") {
        $productManifest = Get-ExeProductManifestSources $ExeProductManifestPath
        $productSources = @($productManifest.Sources)
    }
    $objectSelection = Get-ExeCandidateObjectRecords `
        -ObjectDirectory $candidateObjectPath `
        -Graph $ExeGraph `
        -ProductSources $productSources
    $objectRecords = @($objectSelection.Records)
    if ($objectRecords.Count -eq 0) {
        throw "No tracked EXE candidate objects were found in '$candidateObjectPath'."
    }

    $anchorObjectName = "tools_otmatch_match_dll_anchors.obj"
    $anchorObjectPath = Join-Path $candidateObjectPath $anchorObjectName
    if (-not (Test-Path -LiteralPath $anchorObjectPath -PathType Leaf)) {
        throw "The synthetic WinMain/CRT anchor object is missing: '$anchorObjectPath'. Run build-match-candidates.ps1 first."
    }
    $anchorSourcePath = Join-Path $PSScriptRoot "match_dll_anchors.cpp"
    if ((Get-Item -LiteralPath $anchorObjectPath).LastWriteTimeUtc -lt
        (Get-Item -LiteralPath $anchorSourcePath).LastWriteTimeUtc) {
        throw "The synthetic WinMain/CRT anchor object is stale: '$anchorObjectPath'. Run build-match-candidates.ps1 first."
    }
    if (Test-SourceContainsInlineAssembly $anchorSourcePath) {
        throw "The synthetic WinMain/CRT anchor source contains an inline-assembly token: '$anchorSourcePath'."
    }

    $productObjectCount = @($objectRecords | Where-Object { $_.Kind -eq "product" }).Count
    $recoveryObjectCount = @($objectRecords | Where-Object { $_.Kind -eq "recovery" }).Count
    Write-Host "  EXE graph: $ExeGraph"
    if ($null -ne $productManifest) {
        Write-Host "  Manifest:  $($productManifest.Path)"
    }
    Write-Host "  Objects:  $($objectRecords.Count + 1) total ($productObjectCount product, $recoveryObjectCount recovery, 1 anchor)"
    Write-Host "  No-ASM:   excluded $($objectSelection.ExcludedExact.Count) _exact, $($objectSelection.ExcludedRecovery.Count) recovery, and $($objectSelection.ExcludedInlineAssembly.Count) token-bearing sources"
    Write-Host ""
    Write-Host "RUNTIME LIMITATION: this EXE is a VC4 linkability artifact, not a runnable"
    Write-Host "Oregon Trail reconstruction. Its synthetic WinMain immediately returns 0."
    if ($ExeGraph -eq "Exhaustive") {
        Write-Host "The exhaustive graph includes recovery probes so /OPT:NOREF can expose"
        Write-Host "their dependency frontier. It is not the canonical product graph."
    } else {
        Write-Host "The canonical product graph is explicit; recovery probes and every _exact"
        Write-Host "translation unit are excluded rather than silently satisfying dependencies."
    }
    Write-Host "Every selected translation unit, including its quoted local-include closure,"
    Write-Host "is scanned for actual ASM tokens after comments and literals are removed."
    Write-Host "This selection is no-ASM and strict linking establishes symbol closure;"
    Write-Host "it does not establish a runnable, complete, or byte-exact executable."

    if ($AllowUnresolvedDiagnostic) {
        Write-Warning "UNRESOLVED DIAGNOSTIC MODE: LINK /FORCE:UNRESOLVED will emit an image despite missing symbols."
        Write-Warning "The resulting PE can contain invalid calls or data references. Do not run or distribute it as a game executable."
    }

    $linkArgs = @(
        "/NOLOGO",
        "/INCREMENTAL:NO",
        "/MACHINE:IX86",
        "/SUBSYSTEM:WINDOWS,4.0",
        "/ENTRY:WinMainCRTStartup",
        "/STACK:0x3000,0x1000",
        "/HEAP:0x1000,0x1000",
        "/OPT:NOREF",
        "/MERGE:.wip=.text",
        "/MERGE:.otsem=.text",
        "/MAP:$mapPath",
        "/OUT:$imagePath"
    )
    if ($AllowUnresolvedDiagnostic) {
        $linkArgs += "/FORCE:UNRESOLVED"
    }
    $linkArgs += @($objectRecords | ForEach-Object { $_.ObjectName })
    $linkArgs += $anchorObjectName
    $linkArgs += $resource
    $linkArgs += $resolvedLibraries
    $linkWorkingDirectory = $candidateObjectPath
}

# Keep the complete, inspectable link command in an ignored ASCII response
# file. It contains paths only; the .res asset bytes remain external.
$responsePath = Join-Path $outputPath "$outputStem.link.rsp"
$linkLogPath = Join-Path $outputPath "$outputStem.link.log"
$linkClosurePath = Join-Path $outputPath "$outputStem.link-closure.json"
$responseLines = @($linkArgs | ForEach-Object { ConvertTo-LinkResponseArgument $_ })
[System.IO.File]::WriteAllLines($responsePath, $responseLines, [System.Text.Encoding]::ASCII)
foreach ($oldAuditPath in @($linkLogPath, $linkClosurePath)) {
    if (Test-Path -LiteralPath $oldAuditPath) {
        Remove-Item -LiteralPath $oldAuditPath -Force
    }
}

# Never let a stale or partially written image survive a failed link under the
# selected stem. The response file remains as the audit record of the attempt.
$generatedLinkPaths = @(
    $imagePath,
    $mapPath,
    (Join-Path $outputPath "$outputStem.lib"),
    (Join-Path $outputPath "$outputStem.exp")
)
foreach ($generatedLinkPath in $generatedLinkPaths) {
    if (Test-Path -LiteralPath $generatedLinkPath) {
        Remove-Item -LiteralPath $generatedLinkPath -Force
    }
}

$linkOutput = @()
$linkExitCode = -1
Push-Location $linkWorkingDirectory
try {
    if ($Target -eq "Oregon32Exe") {
        # LINK 3.00.5270 reproducibly reports "Internal error during Pass1"
        # when this large object graph is supplied through an @response file.
        # Passing the identical ordered arguments directly avoids that VC4
        # parser/linker defect. Retain the response file above for auditing.
        $linkOutput = @(& $link @linkArgs 2>&1)
    } else {
        $linkOutput = @(& $link "@$responsePath" 2>&1)
    }
    $linkExitCode = $LASTEXITCODE
} finally {
    Pop-Location
}

$linkOutputLines = @($linkOutput | ForEach-Object { "$_" })
foreach ($linkOutputLine in $linkOutputLines) {
    Write-Host $linkOutputLine
}
[System.IO.File]::WriteAllLines($linkLogPath, $linkOutputLines, [System.Text.Encoding]::ASCII)

$unresolvedReferences = @()
foreach ($linkOutputLine in $linkOutputLines) {
    if ($linkOutputLine -match '^(?<caller>.+?)\s*:\s*error LNK2001: unresolved external symbol\s+(?<symbol>.+)$') {
        $unresolvedReferences += [pscustomobject]@{
            caller = $Matches.caller.Trim()
            symbol = $Matches.symbol.Trim()
        }
    }
}
$unresolvedSymbols = @(
    $unresolvedReferences |
        Select-Object -ExpandProperty symbol |
        Sort-Object -Unique
)
$manifestPathForReport = if ($null -ne $productManifest) { $productManifest.Path } else { $null }
$manifestHashForReport = if ($null -ne $productManifest) {
    (Get-FileHash -LiteralPath $productManifest.Path -Algorithm SHA256).Hash.ToLowerInvariant()
} else {
    $null
}
$closureReport = [ordered]@{
    schema_version = 1
    generated_utc = [DateTime]::UtcNow.ToString("o")
    target = $Target
    exe_graph = if ($Target -eq "Oregon32Exe") { $ExeGraph } else { $null }
    strict = -not $AllowUnresolvedDiagnostic.IsPresent
    force_unresolved = $AllowUnresolvedDiagnostic.IsPresent
    opt_no_ref = ($linkArgs -contains "/OPT:NOREF")
    link_exit_code = $linkExitCode
    link_succeeded = ($linkExitCode -eq 0)
    compiler_path = $cl
    compiler_file_version = $clVersion.FileVersion
    linker_path = $link
    linker_file_version = $linkVersion.FileVersion
    product_manifest_path = $manifestPathForReport
    product_manifest_sha256 = $manifestHashForReport
    response_path = $responsePath
    response_sha256 = (Get-FileHash -LiteralPath $responsePath -Algorithm SHA256).Hash.ToLowerInvariant()
    product_object_count = $productObjectCount
    recovery_object_count = $recoveryObjectCount
    anchor_object_count = if ($Target -eq "Oregon32Exe") { 1 } else { 0 }
    unresolved_reference_count = $unresolvedReferences.Count
    unresolved_unique_count = $unresolvedSymbols.Count
    unresolved_symbols = $unresolvedSymbols
    unresolved_references = $unresolvedReferences
}
[System.IO.File]::WriteAllText(
    $linkClosurePath,
    ($closureReport | ConvertTo-Json -Depth 5),
    [System.Text.Encoding]::UTF8
)

if ($linkExitCode -ne 0) {
    foreach ($generatedLinkPath in $generatedLinkPaths) {
        if (Test-Path -LiteralPath $generatedLinkPath) {
            Remove-Item -LiteralPath $generatedLinkPath -Force
        }
    }
    throw "Visual C++ 4.0 link.exe failed with exit code $linkExitCode. Closure report: '$linkClosurePath'."
}

if (-not (Test-Path -LiteralPath $imagePath -PathType Leaf) -or
    -not (Test-Path -LiteralPath $mapPath -PathType Leaf)) {
    throw "The product link completed without producing both '$imagePath' and '$mapPath'."
}

$imageInfo = Get-Item -LiteralPath $imagePath
$imageHash = (Get-FileHash -LiteralPath $imagePath -Algorithm SHA256).Hash
Write-Host ""
$outputLabel = if ($AllowUnresolvedDiagnostic) { "UNRESOLVED DIAGNOSTIC" } else { "Product-WIP" }
Write-Host "${outputLabel} output:"
Write-Host "  Image:  $imagePath"
Write-Host "  MAP:    $mapPath"
Write-Host "  Link:   $responsePath"
Write-Host "  Log:    $linkLogPath"
Write-Host "  Closure:$linkClosurePath"
Write-Host "  Bytes:  $($imageInfo.Length)"
Write-Host "  SHA256: $imageHash"
