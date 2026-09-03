[CmdletBinding(DefaultParameterSetName = "Generate")]
param(
    [Parameter(ParameterSetName = "Generate")]
    [Alias("Name")]
    [string]$FunctionName = "",

    [Parameter(ParameterSetName = "Generate")]
    [Alias("Rva")]
    [string]$OriginalRva = "",

    [Parameter(Mandatory = $true, ParameterSetName = "Generate")]
    [string]$Program,

    [Parameter(ParameterSetName = "Generate")]
    [string]$SourcePath = "",

    [Parameter(Mandatory = $true, ParameterSetName = "Generate")]
    [string]$CheckpointId,

    [Parameter(Mandatory = $true, ParameterSetName = "Generate")]
    [string]$PriorBoundaryRunId,

    [Parameter(ParameterSetName = "Generate")]
    [string]$VariantSpecPath = "",

    [Parameter(ParameterSetName = "Generate")]
    [string]$VariantName = "shape-01",

    [Parameter(ParameterSetName = "Generate")]
    [string]$Hypothesis = "",

    [Parameter(ParameterSetName = "Generate")]
    [string]$OldText = "",

    [Parameter(ParameterSetName = "Generate")]
    [string]$OldTextPath = "",

    [Parameter(ParameterSetName = "Generate")]
    [AllowEmptyString()]
    [string]$NewText = "",

    [Parameter(ParameterSetName = "Generate")]
    [string]$NewTextPath = "",

    [Parameter(ParameterSetName = "Generate")]
    [bool]$Meaningful = $true,

    [Parameter(Mandatory = $true, ParameterSetName = "Generate")]
    [string]$OutputPath,

    [Parameter(ParameterSetName = "Generate")]
    [string]$ManifestPath = "tools\otmatch\functions.vc40-real-cpp.csv",

    [Parameter(ParameterSetName = "Generate", DontShow = $true)]
    [string]$SourceSearchRoot = "",

    [Parameter(ParameterSetName = "Generate")]
    [switch]$Force,

    [Parameter(Mandatory = $true, ParameterSetName = "Preflight")]
    [switch]$PreflightOnly,

    [Parameter(Mandatory = $true, ParameterSetName = "Preflight")]
    [string]$PlanPath,

    [switch]$PassThru
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$sourceEncoding = [System.Text.Encoding]::Default
$generatorRelativePath = "tools/otmatch/new-source-shape-plan.ps1"
$generatorScriptPath = [System.IO.Path]::GetFullPath($PSCommandPath)

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

function Get-ConfiguredFullPath([string]$Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
}

function Resolve-RepoFile {
    param(
        [string]$Path,
        [string]$Description
    )

    $configured = Get-ConfiguredFullPath $Path
    if (-not (Test-Path -LiteralPath $configured -PathType Leaf)) {
        throw "$Description does not exist: '$configured'."
    }
    $resolved = (Resolve-Path -LiteralPath $configured).Path
    if (-not (Test-PathInsideRoot $resolved $repoRoot)) {
        throw "$Description must be contained within the repository: '$resolved'."
    }
    Assert-NoReparseTraversal $configured
    return $resolved
}

function Resolve-RepoDirectory {
    param(
        [string]$Path,
        [string]$Description
    )

    $configured = Get-ConfiguredFullPath $Path
    if (-not (Test-Path -LiteralPath $configured -PathType Container)) {
        throw "$Description does not exist: '$configured'."
    }
    $resolved = (Resolve-Path -LiteralPath $configured).Path
    if (-not (Test-PathInsideRoot $resolved $repoRoot)) {
        throw "$Description must be contained within the repository: '$resolved'."
    }
    Assert-NoReparseTraversal $configured
    return $resolved
}

function Get-RepoRelativePath([string]$Path) {
    $resolved = [System.IO.Path]::GetFullPath($Path)
    if (-not (Test-PathInsideRoot $resolved $repoRoot)) {
        throw "Path is outside the repository: '$resolved'."
    }
    return $resolved.Substring($repoRoot.Length).
        TrimStart('\', '/').Replace('\', '/')
}

function Assert-NoReparseTraversal([string]$Path) {
    $currentPath = [System.IO.Path]::GetFullPath($Path)
    while (-not (Test-Path -LiteralPath $currentPath)) {
        $parentPath = Split-Path -Parent $currentPath
        if ([string]::IsNullOrWhiteSpace($parentPath) -or
            $parentPath.Equals(
                $currentPath,
                [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "Path has no existing repository ancestor: '$Path'."
        }
        $currentPath = $parentPath
    }

    $current = Get-Item -LiteralPath $currentPath -Force
    while ($null -ne $current) {
        if (($current.Attributes -band
                [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Path cannot traverse reparse point '$($current.FullName)'."
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
    throw "Path is not rooted beneath the repository: '$Path'."
}

function Assert-SafeOutputPath([string]$Path) {
    $fullPath = Get-ConfiguredFullPath $Path
    if (-not (Test-PathInsideRoot $fullPath $repoRoot)) {
        throw "Plan output must be contained within the repository: '$fullPath'."
    }
    if ([System.IO.Path]::GetExtension($fullPath) -cne ".json") {
        throw "Plan output must use a .json extension: '$fullPath'."
    }
    Assert-NoReparseTraversal $fullPath

    $relativePath = Get-RepoRelativePath $fullPath
    if ($relativePath -notmatch '^(?i:a|artifacts)/') {
        throw "Plan output must be below Git-ignored a/ or artifacts/: '$relativePath'."
    }
    & git -C $repoRoot check-ignore --quiet -- $relativePath 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Plan output must be Git-ignored: '$relativePath'."
    }
    return $fullPath
}

function Get-OptionalProperty {
    param(
        $Object,
        [string]$Name,
        $Default = $null
    )

    if ($null -eq $Object) {
        return $Default
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $Default
    }
    return $property.Value
}

function Assert-AllowedProperties {
    param(
        $Object,
        [string[]]$Allowed,
        [string]$Description
    )

    $unexpected = @($Object.PSObject.Properties.Name |
        Where-Object { $Allowed -cnotcontains $_ })
    if ($unexpected.Count -gt 0) {
        throw ("{0} contains unsupported property/properties: {1}." -f
            $Description, ($unexpected -join ", "))
    }
}

function Get-BytesSha256Hex([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($Bytes))).
            Replace("-", "").ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Get-TextSha256Hex([string]$Text) {
    return Get-BytesSha256Hex ([System.Text.Encoding]::UTF8.GetBytes($Text))
}

function Get-FileSha256Hex([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.
        ToLowerInvariant()
}

function Convert-HexNumber([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "Hex value must be nonblank."
    }
    $text = $Value.Trim()
    if ($text.StartsWith("0x", [System.StringComparison]::OrdinalIgnoreCase)) {
        $text = $text.Substring(2)
    }
    try {
        return [uint64]::Parse(
            $text,
            [System.Globalization.NumberStyles]::HexNumber,
            [System.Globalization.CultureInfo]::InvariantCulture)
    } catch {
        throw "Invalid hexadecimal value '$Value'."
    }
}

function Get-CandidateObjectName([string]$Path) {
    $relativePath = Get-RepoRelativePath $Path
    return (($relativePath -replace '/', '_') -replace '\.cpp$', '.obj')
}

function Find-SourceForManifestRow {
    param(
        $ManifestRow,
        [string]$SearchRoot
    )

    $candidateObject = [string]$ManifestRow.candidate_object
    if ([string]::IsNullOrWhiteSpace($candidateObject)) {
        throw ("Manifest identity '{0}' has no candidate_object; provide -SourcePath." -f
            [string]$ManifestRow.name)
    }

    $sourceRoot = if ([string]::IsNullOrWhiteSpace($SearchRoot)) {
        Join-Path $repoRoot "src\otwin"
    } else {
        Resolve-RepoDirectory $SearchRoot "Source search root"
    }
    $matches = @([System.IO.Directory]::EnumerateFiles(
            $sourceRoot,
            "*.cpp",
            [System.IO.SearchOption]::AllDirectories) |
        Where-Object {
            (Get-CandidateObjectName $_) -ieq $candidateObject
        })
    if ($matches.Count -ne 1) {
        throw (("Manifest candidate_object '{0}' must map to exactly one .cpp source " +
            "beneath '{1}'; observed {2}. Provide -SourcePath if the mapping is intentional.") -f
            $candidateObject,
            (Get-RepoRelativePath $sourceRoot),
            $matches.Count)
    }
    return [System.IO.Path]::GetFullPath($matches[0])
}

function Get-ConfiguredReplacementText {
    param(
        [string]$InlineText,
        [bool]$InlineWasBound,
        [string]$TextPath,
        [string]$Description,
        [bool]$AllowEmpty
    )

    $pathWasBound = -not [string]::IsNullOrWhiteSpace($TextPath)
    if ($InlineWasBound -and $pathWasBound) {
        throw "Provide either -$Description or -${Description}Path, not both."
    }
    if (-not $InlineWasBound -and -not $pathWasBound) {
        throw "Direct one-replacement mode requires -$Description or -${Description}Path."
    }
    $value = if ($pathWasBound) {
        $resolvedTextPath = Resolve-RepoFile $TextPath "$Description text file"
        [System.IO.File]::ReadAllText($resolvedTextPath)
    } else {
        $InlineText
    }
    if (-not $AllowEmpty -and [string]::IsNullOrEmpty($value)) {
        throw "$Description must be nonempty."
    }
    return $value
}

function Get-ExactOccurrenceCount {
    param(
        [string]$Text,
        [string]$Needle
    )

    if ([string]::IsNullOrEmpty($Needle)) {
        return 0
    }
    $count = 0
    $start = 0
    while ($start -le $Text.Length - $Needle.Length) {
        $index = $Text.IndexOf(
            $Needle,
            $start,
            [System.StringComparison]::Ordinal)
        if ($index -lt 0) {
            break
        }
        $count++
        $start = $index + $Needle.Length
    }
    return $count
}

function Convert-AndValidateVariants {
    param(
        $Variants,
        [string]$BaselineText,
        $ExpectedAnchors = $null
    )

    $variantArray = @($Variants)
    if ($variantArray.Count -eq 0) {
        throw "Variant spec must contain at least one variant."
    }

    $seenNames = @{}
    $outputVariants = @()
    $anchors = @()
    $anchorCursor = 0
    foreach ($variant in $variantArray) {
        Assert-AllowedProperties $variant @(
            "name", "hypothesis", "meaningful", "candidateSymbol",
            "replacements", "append") "Variant"
        $name = [string](Get-OptionalProperty $variant "name" "")
        if ([string]::IsNullOrWhiteSpace($name)) {
            throw "Every variant must have a nonblank name."
        }
        if ($name -notmatch '^[A-Za-z0-9][A-Za-z0-9._-]*$') {
            throw "Variant name '$name' contains unsupported characters."
        }
        $nameKey = $name.ToLowerInvariant()
        if ($seenNames.ContainsKey($nameKey)) {
            throw "Variant name '$name' is duplicated."
        }
        $seenNames[$nameKey] = $true

        $hypothesis = [string](Get-OptionalProperty $variant "hypothesis" "")
        if ([string]::IsNullOrWhiteSpace($hypothesis)) {
            throw "Variant '$name' must have a nonblank hypothesis."
        }
        $meaningfulProperty = $variant.PSObject.Properties["meaningful"]
        if ($null -eq $meaningfulProperty -or
            $meaningfulProperty.Value -isnot [bool]) {
            throw "Variant '$name' must provide meaningful as a JSON boolean."
        }

        $candidateSymbol = [string](Get-OptionalProperty `
            $variant "candidateSymbol" "")
        $replacementValue = Get-OptionalProperty $variant "replacements" @()
        $replacementArray = @($replacementValue)
        $append = [string](Get-OptionalProperty $variant "append" "")
        if ($replacementArray.Count -eq 0 -and
            [string]::IsNullOrEmpty($append)) {
            throw "Variant '$name' must change the source with a replacement or append."
        }

        $updatedText = $BaselineText
        $outputReplacements = @()
        for ($replacementIndex = 0;
            $replacementIndex -lt $replacementArray.Count;
            $replacementIndex++) {
            $replacement = $replacementArray[$replacementIndex]
            Assert-AllowedProperties $replacement @("old", "new") (
                "Variant '$name' replacement $($replacementIndex + 1)")
            $oldProperty = $replacement.PSObject.Properties["old"]
            $newProperty = $replacement.PSObject.Properties["new"]
            if ($null -eq $oldProperty -or
                [string]::IsNullOrEmpty([string]$oldProperty.Value)) {
                throw ("Variant '$name' replacement {0} must have nonempty old text." -f
                    ($replacementIndex + 1))
            }
            if ($null -eq $newProperty) {
                throw ("Variant '$name' replacement {0} must provide new text." -f
                    ($replacementIndex + 1))
            }
            $old = [string]$oldProperty.Value
            $new = [string]$newProperty.Value
            $occurrences = Get-ExactOccurrenceCount $updatedText $old
            if ($occurrences -ne 1) {
                throw (("Variant '{0}' replacement {1} old anchor must occur " +
                    "exactly once at its application step; observed {2}.") -f
                    $name, ($replacementIndex + 1), $occurrences)
            }

            $anchor = [pscustomobject][ordered]@{
                variant = $name
                replacementIndex = $replacementIndex + 1
                oldSha256 = Get-TextSha256Hex $old
                oldLength = $old.Length
                expectedOccurrences = 1
            }
            if ($null -ne $ExpectedAnchors) {
                $expectedArray = @($ExpectedAnchors)
                if ($anchorCursor -ge $expectedArray.Count) {
                    throw "Plan source preflight is missing anchor metadata."
                }
                $expected = $expectedArray[$anchorCursor]
                if ([string](Get-OptionalProperty $expected "variant" "") -cne
                        $anchor.variant -or
                    [int](Get-OptionalProperty $expected "replacementIndex" 0) -ne
                        $anchor.replacementIndex -or
                    [string](Get-OptionalProperty $expected "oldSha256" "") -cne
                        $anchor.oldSha256 -or
                    [int](Get-OptionalProperty $expected "oldLength" -1) -ne
                        $anchor.oldLength -or
                    [int](Get-OptionalProperty $expected "expectedOccurrences" 0) -ne 1) {
                    throw ("Plan source preflight anchor metadata does not match " +
                        "variant '$name' replacement $($replacementIndex + 1).")
                }
                $anchorCursor++
            }
            $anchors += $anchor
            $outputReplacements += [pscustomobject][ordered]@{
                old = $old
                new = $new
            }
            $updatedText = $updatedText.Replace($old, $new)
        }

        if (-not [string]::IsNullOrEmpty($append)) {
            $updatedText += $append
        }
        if ($updatedText -ceq $BaselineText) {
            throw "Variant '$name' does not change the source text."
        }

        $outputVariant = [pscustomobject][ordered]@{
            name = $name
            hypothesis = $hypothesis.Trim()
            meaningful = [bool]$meaningfulProperty.Value
        }
        if (-not [string]::IsNullOrWhiteSpace($candidateSymbol)) {
            $outputVariant | Add-Member -NotePropertyName candidateSymbol `
                -NotePropertyValue $candidateSymbol.Trim()
        }
        if ($outputReplacements.Count -gt 0) {
            $outputVariant | Add-Member -NotePropertyName replacements `
                -NotePropertyValue $outputReplacements
        }
        if (-not [string]::IsNullOrEmpty($append)) {
            $outputVariant | Add-Member -NotePropertyName append `
                -NotePropertyValue $append
        }
        $outputVariants += $outputVariant
    }

    if ($null -ne $ExpectedAnchors -and
        $anchorCursor -ne @($ExpectedAnchors).Count) {
        throw "Plan source preflight contains extra anchor metadata."
    }
    return [pscustomobject][ordered]@{
        variants = $outputVariants
        anchors = $anchors
    }
}

function Test-SourceShapePlan([string]$ResolvedPlanPath) {
    try {
        $plan = Get-Content -LiteralPath $ResolvedPlanPath -Raw |
            ConvertFrom-Json
    } catch {
        throw "Source-shape plan is invalid JSON: $($_.Exception.Message)"
    }
    Assert-AllowedProperties $plan @(
        "planSchemaVersion", "generator", "manifestBinding", "program",
        "name", "checkpointId", "priorBoundaryRunId", "sourcePath",
        "sourcePreflight", "originalRva", "size", "candidateSymbol",
        "mask", "variants") "Source-shape plan"
    if ([int](Get-OptionalProperty $plan "planSchemaVersion" 0) -ne 1) {
        throw "Source-shape plan must use planSchemaVersion 1."
    }

    $generator = Get-OptionalProperty $plan "generator" $null
    if ($null -eq $generator) {
        throw "Source-shape plan generator binding is missing."
    }
    Assert-AllowedProperties $generator @(
        "name", "schemaVersion", "scriptPath", "scriptSha256") `
        "Source-shape plan generator binding"
    $generatorSha256 = [string](Get-OptionalProperty `
        $generator "scriptSha256" "")
    if ([string](Get-OptionalProperty $generator "name" "") -cne
            "otmatch-source-shape-plan" -or
        [int](Get-OptionalProperty $generator "schemaVersion" 0) -ne 1 -or
        [string](Get-OptionalProperty $generator "scriptPath" "") -cne
            $generatorRelativePath -or
        $generatorSha256 -notmatch '^[0-9a-f]{64}$') {
        throw "Source-shape plan generator binding is not canonical schema 1."
    }
    $currentGeneratorSha256 = Get-FileSha256Hex $generatorScriptPath
    if ($generatorSha256 -cne $currentGeneratorSha256) {
        throw (("Source-shape plan generator hash mismatch: plan={0}, current={1}. " +
            "Regenerate the plan with the current generator.") -f
            $generatorSha256, $currentGeneratorSha256)
    }

    $manifestBinding = Get-OptionalProperty $plan "manifestBinding" $null
    if ($null -eq $manifestBinding) {
        throw "Source-shape plan manifest binding is missing."
    }
    Assert-AllowedProperties $manifestBinding @(
        "path", "sha256", "candidateObject", "variantInput") `
        "Source-shape plan manifest binding"
    $configuredManifest = [string](Get-OptionalProperty `
        $manifestBinding "path" "")
    if ([string]::IsNullOrWhiteSpace($configuredManifest)) {
        throw "Source-shape plan manifestBinding.path is blank."
    }
    $resolvedManifest = Resolve-RepoFile $configuredManifest "Plan manifest"
    $expectedManifestSha256 = [string](Get-OptionalProperty `
        $manifestBinding "sha256" "")
    if ($expectedManifestSha256 -notmatch '^[0-9a-f]{64}$') {
        throw "Source-shape plan manifestBinding.sha256 is invalid."
    }
    $actualManifestSha256 = Get-FileSha256Hex $resolvedManifest
    if ($actualManifestSha256 -cne $expectedManifestSha256) {
        throw (("Manifest snapshot hash mismatch for '{0}': plan={1}, current={2}. " +
            "Regenerate the plan against the current manifest.") -f
            (Get-RepoRelativePath $resolvedManifest),
            $expectedManifestSha256,
            $actualManifestSha256)
    }

    foreach ($requiredPlanProperty in @(
            "program", "name", "checkpointId", "priorBoundaryRunId",
            "originalRva", "size", "candidateSymbol")) {
        if ([string]::IsNullOrWhiteSpace([string](Get-OptionalProperty `
                    $plan $requiredPlanProperty ""))) {
            throw "Source-shape plan $requiredPlanProperty is blank."
        }
    }

    $preflight = Get-OptionalProperty $plan "sourcePreflight" $null
    if ($null -eq $preflight -or
        [int](Get-OptionalProperty $preflight "schemaVersion" 0) -ne 1) {
        throw "Source-shape plan must contain sourcePreflight schemaVersion 1."
    }
    Assert-AllowedProperties $preflight @(
        "schemaVersion", "sourceSha256", "sourceLength", "anchors") `
        "Source-shape plan sourcePreflight"
    $anchorsProperty = $preflight.PSObject.Properties["anchors"]
    if ($null -eq $anchorsProperty -or $null -eq $anchorsProperty.Value) {
        throw "Source-shape plan sourcePreflight.anchors must be a JSON array."
    }
    foreach ($anchor in @($anchorsProperty.Value)) {
        Assert-AllowedProperties $anchor @(
            "variant", "replacementIndex", "oldSha256", "oldLength",
            "expectedOccurrences") "Source-shape plan anchor"
        if ([string](Get-OptionalProperty $anchor "oldSha256" "") -notmatch
                '^[0-9a-f]{64}$' -or
            [int](Get-OptionalProperty $anchor "replacementIndex" 0) -lt 1 -or
            [int](Get-OptionalProperty $anchor "oldLength" 0) -lt 1 -or
            [int](Get-OptionalProperty $anchor "expectedOccurrences" 0) -ne 1) {
            throw "Source-shape plan anchor metadata is invalid."
        }
    }

    $configuredSource = [string](Get-OptionalProperty $plan "sourcePath" "")
    if ([string]::IsNullOrWhiteSpace($configuredSource)) {
        throw "Source-shape plan sourcePath is blank."
    }
    $resolvedSource = Resolve-RepoFile $configuredSource "Plan source"
    if ([System.IO.Path]::GetExtension($resolvedSource) -cne ".cpp") {
        throw "Source-shape plan source must be a .cpp file: '$resolvedSource'."
    }

    $planProgram = [string](Get-OptionalProperty $plan "program" "")
    $planName = [string](Get-OptionalProperty $plan "name" "")
    $planOriginalRva = Convert-HexNumber ([string](Get-OptionalProperty `
        $plan "originalRva" ""))
    $identityRows = @(Import-Csv -LiteralPath $resolvedManifest |
        Where-Object {
            [string]$_.program -ceq $planProgram -and
            [string]$_.name -ceq $planName -and
            (Convert-HexNumber ([string]$_.original_rva)) -eq $planOriginalRva
        })
    if ($identityRows.Count -ne 1) {
        throw (("Plan identity '{0}|{1}@{2}' must resolve to exactly one bound " +
            "manifest row; observed {3}.") -f
            $planProgram,
            $planName,
            [string]$plan.originalRva,
            $identityRows.Count)
    }
    $manifestRow = $identityRows[0]
    $bindingMismatches = @()
    foreach ($binding in @(
            @("size", [string]$plan.size, [string]$manifestRow.size),
            @("candidateSymbol", [string]$plan.candidateSymbol,
                [string]$manifestRow.candidate_symbol),
            @("mask", [string]$plan.mask, [string]$manifestRow.mask),
            @("candidateObject",
                [string](Get-OptionalProperty $manifestBinding `
                    "candidateObject" ""),
                [string]$manifestRow.candidate_object))) {
        if ([string]$binding[1] -cne [string]$binding[2]) {
            $bindingMismatches += [string]$binding[0]
        }
    }
    if ([string]$manifestRow.implementation_kind -ine "cpp") {
        $bindingMismatches += "implementationKind"
    }
    if ($bindingMismatches.Count -gt 0) {
        throw ("Source-shape plan does not match its bound manifest row: {0}." -f
            ($bindingMismatches -join ", "))
    }
    $candidateObject = [string]$manifestRow.candidate_object
    if (-not [string]::IsNullOrWhiteSpace($candidateObject) -and
        (Get-CandidateObjectName $resolvedSource) -ine $candidateObject) {
        throw (("Plan source maps to candidate object '{0}', but the bound " +
            "manifest row names '{1}'.") -f
            (Get-CandidateObjectName $resolvedSource), $candidateObject)
    }

    $sourceBytes = [System.IO.File]::ReadAllBytes($resolvedSource)
    $actualSha256 = Get-BytesSha256Hex $sourceBytes
    $expectedSha256 = [string](Get-OptionalProperty `
        $preflight "sourceSha256" "")
    if ($expectedSha256 -notmatch '^[0-9a-f]{64}$') {
        throw "Source-shape plan sourcePreflight.sourceSha256 is invalid."
    }
    if ($actualSha256 -cne $expectedSha256) {
        throw (("Source snapshot hash mismatch for '{0}': plan={1}, current={2}. " +
            "Regenerate the plan against the intended source before running a build.") -f
            (Get-RepoRelativePath $resolvedSource), $expectedSha256, $actualSha256)
    }
    $expectedLength = [long](Get-OptionalProperty `
        $preflight "sourceLength" -1)
    if ($sourceBytes.LongLength -ne $expectedLength) {
        throw ("Source snapshot length mismatch for '{0}': plan={1}, current={2}." -f
            (Get-RepoRelativePath $resolvedSource),
            $expectedLength,
            $sourceBytes.LongLength)
    }

    # Match the runner's StreamReader behavior, including BOM detection.
    $sourceText = [System.IO.File]::ReadAllText(
        $resolvedSource,
        $sourceEncoding)
    $validation = Convert-AndValidateVariants `
        -Variants (Get-OptionalProperty $plan "variants" @()) `
        -BaselineText $sourceText `
        -ExpectedAnchors $anchorsProperty.Value
    return [pscustomobject][ordered]@{
        plan_path = Get-RepoRelativePath $ResolvedPlanPath
        source_path = Get-RepoRelativePath $resolvedSource
        source_sha256 = $actualSha256
        source_length = $sourceBytes.LongLength
        variant_count = @($validation.variants).Count
        anchor_count = @($validation.anchors).Count
        passed = $true
    }
}

function Write-JsonAtomically {
    param(
        [string]$Path,
        $Value
    )

    [void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $Path))
    $temporaryPath = $Path + ".tmp-" + [guid]::NewGuid().ToString("N")
    $backupPath = $temporaryPath + ".bak"
    try {
        [System.IO.File]::WriteAllText(
            $temporaryPath,
            (($Value | ConvertTo-Json -Depth 20) + "`n"),
            $utf8NoBom)
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            [System.IO.File]::Replace(
                $temporaryPath,
                $Path,
                $backupPath,
                $true)
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

if ($PSCmdlet.ParameterSetName -eq "Preflight") {
    $resolvedPlan = Resolve-RepoFile $PlanPath "Source-shape plan"
    $result = Test-SourceShapePlan $resolvedPlan
    Write-Host (("Source-shape plan preflight: PASS ({0} variant(s), " +
        "{1} exact anchor(s), source {2})") -f
        $result.variant_count,
        $result.anchor_count,
        $result.source_sha256)
    if ($PassThru) {
        $result
    }
    return
}

$resolvedManifest = Resolve-RepoFile $ManifestPath "Function manifest"
$resolvedOutput = Assert-SafeOutputPath $OutputPath
if ((Test-Path -LiteralPath $resolvedOutput -PathType Leaf) -and -not $Force) {
    throw "Plan output already exists; pass -Force to replace it: '$resolvedOutput'."
}
if ([string]::IsNullOrWhiteSpace($CheckpointId)) {
    throw "CheckpointId must be nonblank."
}
if ([string]::IsNullOrWhiteSpace($PriorBoundaryRunId)) {
    throw "PriorBoundaryRunId must be nonblank."
}
if ([string]::IsNullOrWhiteSpace($Program)) {
    throw "Program must be nonblank."
}
if ([string]::IsNullOrWhiteSpace($FunctionName) -and
    [string]::IsNullOrWhiteSpace($OriginalRva)) {
    throw "Provide -FunctionName, -OriginalRva, or both to select a manifest identity."
}

$manifestRows = @(Import-Csv -LiteralPath $resolvedManifest)
$requestedRva = if ([string]::IsNullOrWhiteSpace($OriginalRva)) {
    $null
} else {
    Convert-HexNumber $OriginalRva
}
$identityRows = @($manifestRows | Where-Object {
        $programMatches = [string]$_.program -ieq $Program
        $nameMatches = [string]::IsNullOrWhiteSpace($FunctionName) -or
            [string]$_.name -ieq $FunctionName
        $rvaMatches = $null -eq $requestedRva -or
            (Convert-HexNumber ([string]$_.original_rva)) -eq $requestedRva
        $programMatches -and $nameMatches -and $rvaMatches
    })
if ($identityRows.Count -ne 1) {
    $selector = if ([string]::IsNullOrWhiteSpace($OriginalRva)) {
        $FunctionName
    } elseif ([string]::IsNullOrWhiteSpace($FunctionName)) {
        $OriginalRva
    } else {
        "$FunctionName@$OriginalRva"
    }
    throw ("Manifest identity '{0}|{1}' must resolve to exactly one row; observed {2}." -f
        $Program, $selector, $identityRows.Count)
}
$manifestRow = $identityRows[0]
if ([string]::IsNullOrWhiteSpace([string]$manifestRow.original_rva) -or
    [string]::IsNullOrWhiteSpace([string]$manifestRow.size) -or
    [string]::IsNullOrWhiteSpace([string]$manifestRow.candidate_symbol)) {
    throw "Manifest identity is missing original_rva, size, or candidate_symbol."
}
if ([string]$manifestRow.implementation_kind -ine "cpp") {
    throw "Source-shape plan identity must use implementation_kind=cpp."
}

$resolvedSource = if ([string]::IsNullOrWhiteSpace($SourcePath)) {
    Find-SourceForManifestRow -ManifestRow $manifestRow `
        -SearchRoot $SourceSearchRoot
} else {
    Resolve-RepoFile $SourcePath "Plan source"
}
$resolvedSource = Resolve-RepoFile $resolvedSource "Plan source"
if ([System.IO.Path]::GetExtension($resolvedSource) -cne ".cpp") {
    throw "Plan source must be a .cpp file: '$resolvedSource'."
}
$candidateObject = [string]$manifestRow.candidate_object
if (-not [string]::IsNullOrWhiteSpace($candidateObject) -and
    (Get-CandidateObjectName $resolvedSource) -ine $candidateObject) {
    throw (("Plan source maps to candidate object '{0}', but the manifest identity " +
        "binds '{1}'.") -f
        (Get-CandidateObjectName $resolvedSource), $candidateObject)
}

$sourceBytes = [System.IO.File]::ReadAllBytes($resolvedSource)
$sourceSha256 = Get-BytesSha256Hex $sourceBytes
$sourceText = [System.IO.File]::ReadAllText($resolvedSource, $sourceEncoding)
$variantSourceDescription = "direct one-replacement parameters"
if (-not [string]::IsNullOrWhiteSpace($VariantSpecPath)) {
    $directParameterNames = @(
        "VariantName", "Hypothesis", "OldText", "OldTextPath", "NewText",
        "NewTextPath", "Meaningful")
    $boundDirectParameters = @($directParameterNames | Where-Object {
            $PSBoundParameters.ContainsKey($_)
        })
    if ($boundDirectParameters.Count -gt 0) {
        throw ("VariantSpecPath cannot be combined with direct variant parameter(s): {0}." -f
            ($boundDirectParameters -join ", "))
    }
    $resolvedVariantSpec = Resolve-RepoFile $VariantSpecPath "Variant spec"
    $variantSpec = Get-Content -LiteralPath $resolvedVariantSpec -Raw |
        ConvertFrom-Json
    Assert-AllowedProperties $variantSpec @("schemaVersion", "variants") `
        "Variant spec"
    if ([int](Get-OptionalProperty $variantSpec "schemaVersion" 0) -ne 1) {
        throw "Variant spec must use schemaVersion 1."
    }
    $variants = Get-OptionalProperty $variantSpec "variants" @()
    $variantSourceDescription = Get-RepoRelativePath $resolvedVariantSpec
} else {
    if ([string]::IsNullOrWhiteSpace($Hypothesis)) {
        throw ("Direct one-replacement mode requires -Hypothesis. Use " +
            "-VariantSpecPath for multi-replacement or multi-variant plans.")
    }
    $old = Get-ConfiguredReplacementText `
        -InlineText $OldText `
        -InlineWasBound ($PSBoundParameters.ContainsKey("OldText")) `
        -TextPath $OldTextPath `
        -Description "OldText" `
        -AllowEmpty $false
    $new = Get-ConfiguredReplacementText `
        -InlineText $NewText `
        -InlineWasBound ($PSBoundParameters.ContainsKey("NewText")) `
        -TextPath $NewTextPath `
        -Description "NewText" `
        -AllowEmpty $true
    $variants = @([pscustomobject][ordered]@{
            name = $VariantName
            hypothesis = $Hypothesis
            meaningful = [bool]$Meaningful
            replacements = @([pscustomobject][ordered]@{
                    old = $old
                    new = $new
                })
        })
}
$validated = Convert-AndValidateVariants `
    -Variants $variants `
    -BaselineText $sourceText

$plan = [pscustomobject][ordered]@{
    planSchemaVersion = 1
    generator = [pscustomobject][ordered]@{
        name = "otmatch-source-shape-plan"
        schemaVersion = 1
        scriptPath = $generatorRelativePath
        scriptSha256 = Get-FileSha256Hex $generatorScriptPath
    }
    manifestBinding = [pscustomobject][ordered]@{
        path = Get-RepoRelativePath $resolvedManifest
        sha256 = Get-FileSha256Hex $resolvedManifest
        candidateObject = $candidateObject
        variantInput = $variantSourceDescription
    }
    program = [string]$manifestRow.program
    name = [string]$manifestRow.name
    checkpointId = $CheckpointId.Trim()
    priorBoundaryRunId = $PriorBoundaryRunId.Trim()
    sourcePath = Get-RepoRelativePath $resolvedSource
    sourcePreflight = [pscustomobject][ordered]@{
        schemaVersion = 1
        sourceSha256 = $sourceSha256
        sourceLength = $sourceBytes.LongLength
        anchors = @($validated.anchors)
    }
    originalRva = [string]$manifestRow.original_rva
    size = [string]$manifestRow.size
    candidateSymbol = [string]$manifestRow.candidate_symbol
    mask = [string]$manifestRow.mask
    variants = @($validated.variants)
}

# Recheck the exact source snapshot immediately before publication so a plan
# cannot silently bind a file that changed while its anchors were inspected.
$currentSourceSha256 = Get-FileSha256Hex $resolvedSource
if ($currentSourceSha256 -cne $sourceSha256) {
    throw ("Source changed while the plan was being generated: before={0}, after={1}." -f
        $sourceSha256, $currentSourceSha256)
}
Write-JsonAtomically $resolvedOutput $plan
try {
    $result = Test-SourceShapePlan $resolvedOutput
} catch {
    Remove-Item -LiteralPath $resolvedOutput -Force -ErrorAction SilentlyContinue
    throw
}

Write-Host ("Source-shape plan generated: {0}" -f
    (Get-RepoRelativePath $resolvedOutput))
Write-Host ("Identity: {0}|{1} @ {2}, size {3}" -f
    $plan.program, $plan.name, $plan.originalRva, $plan.size)
Write-Host ("Preflight: PASS ({0} variant(s), {1} exact anchor(s), source {2})" -f
    $result.variant_count, $result.anchor_count, $result.source_sha256)
Write-Host ("Before a costly run: & '{0}' -PreflightOnly -PlanPath '{1}'" -f
    $PSCommandPath, $resolvedOutput)
if ($PassThru) {
    $result
}
