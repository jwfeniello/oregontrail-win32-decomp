[CmdletBinding()]
param(
    [string]$ManifestPath = "tools\otmatch\vc4-exe-product-sources.txt",
    [string]$ResultsJsonPath = "",
    [switch]$SummaryOnly,
    [switch]$ReportOnly
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

function Get-RepoRelativePath {
    param([string]$AbsolutePath)

    $absolute = [System.IO.Path]::GetFullPath($AbsolutePath)
    $prefix = $repoRoot.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    if (-not $absolute.StartsWith(
        $prefix,
        [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Product source closure escaped the repository: '$absolute'."
    }

    return $absolute.Substring($prefix.Length).Replace('\', '/')
}

function Remove-CppComments {
    param([string]$Text)

    # Preserve newlines so diagnostics can still report useful source lines.
    return [System.Text.RegularExpressions.Regex]::Replace(
        $Text,
        '(?s)/\*.*?\*/|//[^\r\n]*',
        {
            param($match)
            return [System.Text.RegularExpressions.Regex]::Replace(
                $match.Value,
                '[^\r\n]',
                ' ')
        })
}

function Get-LineNumber {
    param(
        [string]$Text,
        [int]$Index
    )

    if ($Index -le 0) {
        return 1
    }

    return 1 + ([System.Text.RegularExpressions.Regex]::Matches(
        $Text.Substring(0, $Index),
        '\n')).Count
}

function Get-ProductSourceClosure {
    param([string[]]$RootSources)

    $visited = @{}
    $records = New-Object System.Collections.ArrayList

    function Visit-ProductSource {
        param(
            [string]$AbsolutePath,
            [bool]$IsManifestRoot
        )

        $absolute = [System.IO.Path]::GetFullPath($AbsolutePath)
        $key = $absolute.ToLowerInvariant()
        if ($visited.ContainsKey($key)) {
            return
        }
        $visited[$key] = $true

        if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
            throw "Product source '$absolute' does not exist."
        }

        $relative = Get-RepoRelativePath $absolute
        $text = [System.IO.File]::ReadAllText($absolute)
        $commentFree = Remove-CppComments $text
        [void]$records.Add([pscustomobject]@{
            Path = $absolute
            RelativePath = $relative
            IsManifestRoot = $IsManifestRoot
            Text = $text
            CommentFreeText = $commentFree
        })

        $includeMatches = [System.Text.RegularExpressions.Regex]::Matches(
            $commentFree,
            '(?m)^\s*#\s*include\s*"(?<path>[^"]+)"')
        foreach ($includeMatch in $includeMatches) {
            $includePath = Join-Path `
                (Split-Path -Parent $absolute) `
                $includeMatch.Groups['path'].Value
            if (Test-Path -LiteralPath $includePath -PathType Leaf) {
                Visit-ProductSource $includePath $false
            }
        }
    }

    foreach ($source in $RootSources) {
        Visit-ProductSource (Get-AbsolutePath $source) $true
    }

    return @($records)
}

$manifestAbsolutePath = Get-AbsolutePath $ManifestPath
if (-not (Test-Path -LiteralPath $manifestAbsolutePath -PathType Leaf)) {
    throw "Product source manifest was not found: '$manifestAbsolutePath'."
}

$manifestSources = @(
    Get-Content -LiteralPath $manifestAbsolutePath |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') }
)
if ($manifestSources.Count -eq 0) {
    throw "Product source manifest is empty: '$manifestAbsolutePath'."
}

$duplicateSources = @(
    $manifestSources |
        Group-Object { $_.ToLowerInvariant() } |
        Where-Object Count -gt 1 |
        ForEach-Object { $_.Group[0] }
)
if ($duplicateSources.Count -gt 0) {
    throw "Product source manifest has duplicate entries: $($duplicateSources -join ', ')."
}

$sourceRecords = @(Get-ProductSourceClosure $manifestSources)
$nullImportAnchors = @()
$nullCallbackAnchors = @()
$absoluteCodePointerAnchors = @()
$emptyDependencyBodies = @()
$trivialDependencyBodies = @()
$sinkDependencyBodies = @()
$emptyDeallocatorBodies = @()
$recoveryIncludes = @()
$volatileTokens = @()
$compilerEntropyMarkers = @()

$nullImportPattern = [System.Text.RegularExpressions.Regex]::new(
    '(?ms)\bextern\s+"C"\s+(?:(?!;).)*?\b(?<name>PTR_[A-Za-z0-9_]+)\b(?:(?!;).)*?=\s*(?:0|NULL|nullptr)\s*;')
$nullCallbackPattern = [System.Text.RegularExpressions.Regex]::new(
    '(?ms)\bextern\s+"C"\s+(?:const\s+)?char\s*(?:\*\s*)?(?<name>[A-Za-z_][A-Za-z0-9_]*(?:DialogProc|Callback|HelpFile)[A-Za-z0-9_]*)\s*(?:\[(?:\s*1\s*)?\])?\s*=\s*(?:0|NULL|nullptr|""|\{\s*0\s*\})\s*;')
$absoluteCodePointerPattern = [System.Text.RegularExpressions.Regex]::new(
    '(?i)reinterpret_cast\s*<\s*void\s*\*\s*>\s*\(\s*(?<value>0x(?:00)?4[0-3][0-9a-f]{4})\s*\)')
$suspiciousBodyName =
    '(?:[A-Za-z_][A-Za-z0-9_]*\s*::\s*)*' +
    '[A-Za-z_][A-Za-z0-9_]*(?:Dependency|DialogProc|Callback|LayoutPad|' +
    'ToggleMenuItemCheckState|ToggleOtherApplicationOption|' +
    'ToggleSoundEnabled)[A-Za-z0-9_]*'
$emptyDependencyPattern = [System.Text.RegularExpressions.Regex]::new(
    '(?ms)\b(?<name>' + $suspiciousBodyName +
    ')\s*\([^;{}]*\)\s*(?:const\s*)?\{\s*\}')
$trivialDependencyPattern = [System.Text.RegularExpressions.Regex]::new(
    '(?ms)\b(?<name>' + $suspiciousBodyName +
    ')\s*\([^;{}]*\)\s*(?:const\s*)?\{\s*return\s+' +
    '(?:0|1|NULL|nullptr|false|true)\s*;\s*\}')
$sinkDependencyPattern = [System.Text.RegularExpressions.Regex]::new(
    '(?ms)\b(?<name>(?:[A-Za-z_][A-Za-z0-9_]*\s*::\s*)*[A-Za-z_][A-Za-z0-9_]*Dependency[A-Za-z0-9_]*)\s*\([^;{}]*\)\s*(?:const\s*)?\{\s*[A-Za-z_][A-Za-z0-9_]*Sink[A-Za-z0-9_]*\s*=\s*[^;{}]+;\s*(?:return\s+(?:0|1|NULL|nullptr|false|true)\s*;\s*)?\}')
$emptyDeallocatorPattern = [System.Text.RegularExpressions.Regex]::new(
    '(?ms)\b(?<name>(?:(?:[A-Za-z_][A-Za-z0-9_]*\s*::\s*)*' +
    'operator\s+delete(?:\s*\[\s*\])?|' +
    '[A-Za-z_][A-Za-z0-9_]*\s*::\s*~[A-Za-z_][A-Za-z0-9_]*))' +
    '\s*\([^;{}]*\)\s*\{\s*\}')
$recoveryIncludePattern = [System.Text.RegularExpressions.Regex]::new(
    '(?m)^\s*#\s*include\s*"(?<path>[^"]*_recovery[^"]*\.cpp)"')
$volatilePattern = [System.Text.RegularExpressions.Regex]::new('\bvolatile\b')
$compilerEntropyPattern = [System.Text.RegularExpressions.Regex]::new(
    '(?im)(?<marker>' +
    '\btranslation[- ]unit\s+context\b|' +
    '\bTU[- ]context\b|' +
    '\bsource[- ]shape\s+predecessor\b|' +
    '\bunreferenced[^\r\n]{0,80}\b(?:context|predecessor|neighbor(?:ing)?)\b|' +
    '\b(?:context|neighbor(?:ing)?|predecessor)[^\r\n]{0,80}' +
        '\b(?:register allocation|codegen|optimizer|perturb\w*|stabiliz\w*)\b|' +
    '/d2[A-Za-z0-9_-]+)')

foreach ($source in $sourceRecords) {
    foreach ($match in $nullImportPattern.Matches($source.CommentFreeText)) {
        $nullImportAnchors += [pscustomobject]@{
            source = $source.RelativePath
            line = Get-LineNumber $source.CommentFreeText $match.Index
            symbol = ($match.Groups['name'].Value -replace '\s+', '')
        }
    }

    foreach ($match in $nullCallbackPattern.Matches($source.CommentFreeText)) {
        $nullCallbackAnchors += [pscustomobject]@{
            source = $source.RelativePath
            line = Get-LineNumber $source.CommentFreeText $match.Index
            symbol = $match.Groups['name'].Value
        }
    }

    foreach ($match in $absoluteCodePointerPattern.Matches($source.CommentFreeText)) {
        $absoluteCodePointerAnchors += [pscustomobject]@{
            source = $source.RelativePath
            line = Get-LineNumber $source.CommentFreeText $match.Index
            value = $match.Groups['value'].Value
        }
    }

    foreach ($match in $emptyDependencyPattern.Matches($source.CommentFreeText)) {
        $symbol = ($match.Groups['name'].Value -replace '\s+', '')
        if ($symbol -eq 'OtNoopCallback_0042aac0_RealCpp' -or
            $symbol -eq 'TimedTransitionState_0042dfa0_ProductWip::OtNoopCallback_0042aac0_RealCpp') {
            continue
        }
        $emptyDependencyBodies += [pscustomobject]@{
            source = $source.RelativePath
            line = Get-LineNumber $source.CommentFreeText $match.Index
            symbol = $symbol
        }
    }

    foreach ($match in $trivialDependencyPattern.Matches($source.CommentFreeText)) {
        $trivialDependencyBodies += [pscustomobject]@{
            source = $source.RelativePath
            line = Get-LineNumber $source.CommentFreeText $match.Index
            symbol = ($match.Groups['name'].Value -replace '\s+', '')
        }
    }

    foreach ($match in $emptyDeallocatorPattern.Matches($source.CommentFreeText)) {
        $emptyDeallocatorBodies += [pscustomobject]@{
            source = $source.RelativePath
            line = Get-LineNumber $source.CommentFreeText $match.Index
            symbol = ($match.Groups['name'].Value -replace '\s+', '')
        }
    }

    foreach ($match in $sinkDependencyPattern.Matches($source.CommentFreeText)) {
        $sinkDependencyBodies += [pscustomobject]@{
            source = $source.RelativePath
            line = Get-LineNumber $source.CommentFreeText $match.Index
            symbol = $match.Groups['name'].Value
        }
    }

    foreach ($match in $recoveryIncludePattern.Matches($source.CommentFreeText)) {
        $recoveryIncludes += [pscustomobject]@{
            source = $source.RelativePath
            line = Get-LineNumber $source.CommentFreeText $match.Index
            include = $match.Groups['path'].Value
        }
    }

    foreach ($match in $volatilePattern.Matches($source.CommentFreeText)) {
        $volatileTokens += [pscustomobject]@{
            source = $source.RelativePath
            line = Get-LineNumber $source.CommentFreeText $match.Index
            token = $match.Value
        }
    }

    # Scan comments too: compiler-entropy shaping is often disclosed in a
    # comment even when the helper itself looks like ordinary semantic C++.
    foreach ($match in $compilerEntropyPattern.Matches($source.Text)) {
        $compilerEntropyMarkers += [pscustomobject]@{
            source = $source.RelativePath
            line = Get-LineNumber $source.Text $match.Index
            marker = ($match.Groups['marker'].Value -replace '\s+', ' ').Trim()
        }
    }
}

$result = [ordered]@{
    schema_version = 2
    manifest_path = Get-RepoRelativePath $manifestAbsolutePath
    manifest_source_count = $manifestSources.Count
    closure_source_count = $sourceRecords.Count
    null_import_anchor_count = $nullImportAnchors.Count
    null_callback_anchor_count = $nullCallbackAnchors.Count
    absolute_code_pointer_anchor_count = $absoluteCodePointerAnchors.Count
    empty_dependency_body_count = $emptyDependencyBodies.Count
    trivial_dependency_body_count = $trivialDependencyBodies.Count
    sink_dependency_body_count = $sinkDependencyBodies.Count
    empty_deallocator_body_count = $emptyDeallocatorBodies.Count
    recovery_cpp_include_count = $recoveryIncludes.Count
    volatile_token_count = $volatileTokens.Count
    compiler_entropy_marker_count = $compilerEntropyMarkers.Count
    null_import_anchors = @($nullImportAnchors)
    null_callback_anchors = @($nullCallbackAnchors)
    absolute_code_pointer_anchors = @($absoluteCodePointerAnchors)
    empty_dependency_bodies = @($emptyDependencyBodies)
    trivial_dependency_bodies = @($trivialDependencyBodies)
    sink_dependency_bodies = @($sinkDependencyBodies)
    empty_deallocator_bodies = @($emptyDeallocatorBodies)
    recovery_cpp_includes = @($recoveryIncludes)
    volatile_tokens = @($volatileTokens)
    compiler_entropy_markers = @($compilerEntropyMarkers)
}

Write-Host "VC4 Product source-policy audit:"
Write-Host "  Manifest roots:           $($result.manifest_source_count)"
Write-Host "  Quoted-include closure:   $($result.closure_source_count)"
Write-Host "  Null PTR import anchors:  $($result.null_import_anchor_count)"
Write-Host "  Null callback/help refs:  $($result.null_callback_anchor_count)"
Write-Host "  Absolute code pointers:   $($result.absolute_code_pointer_anchor_count)"
Write-Host "  Empty dependencies:       $($result.empty_dependency_body_count)"
Write-Host "  Trivial dependencies:     $($result.trivial_dependency_body_count)"
Write-Host "  Sink-only dependencies:   $($result.sink_dependency_body_count)"
Write-Host "  Empty dtors/deallocators: $($result.empty_deallocator_body_count)"
Write-Host "  Recovery .cpp includes:   $($result.recovery_cpp_include_count)"
Write-Host "  Volatile tokens:          $($result.volatile_token_count)"
Write-Host "  Compiler entropy markers: $($result.compiler_entropy_marker_count)"

if (-not $SummaryOnly) {
    foreach ($category in @(
        @{ Label = 'null import anchor'; Rows = $nullImportAnchors; Field = 'symbol' },
        @{ Label = 'null callback/help reference'; Rows = $nullCallbackAnchors; Field = 'symbol' },
        @{ Label = 'absolute code pointer'; Rows = $absoluteCodePointerAnchors; Field = 'value' },
        @{ Label = 'empty dependency'; Rows = $emptyDependencyBodies; Field = 'symbol' },
        @{ Label = 'trivial dependency'; Rows = $trivialDependencyBodies; Field = 'symbol' },
        @{ Label = 'sink-only dependency'; Rows = $sinkDependencyBodies; Field = 'symbol' },
        @{ Label = 'empty destructor/deallocator'; Rows = $emptyDeallocatorBodies; Field = 'symbol' },
        @{ Label = 'recovery include'; Rows = $recoveryIncludes; Field = 'include' },
        @{ Label = 'volatile token'; Rows = $volatileTokens; Field = 'token' },
        @{ Label = 'compiler entropy marker'; Rows = $compilerEntropyMarkers; Field = 'marker' }
    )) {
        foreach ($row in $category.Rows) {
            $detail = $row.($category.Field)
            Write-Host "  [$($category.Label)] $($row.source):$($row.line): $detail"
        }
    }
}

if (-not [string]::IsNullOrWhiteSpace($ResultsJsonPath)) {
    $resultsAbsolutePath = Get-AbsolutePath $ResultsJsonPath
    $resultsDirectory = Split-Path -Parent $resultsAbsolutePath
    if (-not (Test-Path -LiteralPath $resultsDirectory -PathType Container)) {
        New-Item -ItemType Directory -Force -Path $resultsDirectory |
            Out-Null
    }
    $result | ConvertTo-Json -Depth 8 |
        Set-Content -LiteralPath $resultsAbsolutePath -Encoding UTF8
    Write-Host "Wrote source-policy audit: $resultsAbsolutePath"
}

$violationCount =
    $nullImportAnchors.Count +
    $nullCallbackAnchors.Count +
    $absoluteCodePointerAnchors.Count +
    $emptyDependencyBodies.Count +
    $trivialDependencyBodies.Count +
    $sinkDependencyBodies.Count +
    $emptyDeallocatorBodies.Count +
    $recoveryIncludes.Count +
    $volatileTokens.Count +
    $compilerEntropyMarkers.Count
if ($violationCount -gt 0 -and -not $ReportOnly) {
    throw "VC4 Product source-policy audit found $violationCount violation(s)."
}
