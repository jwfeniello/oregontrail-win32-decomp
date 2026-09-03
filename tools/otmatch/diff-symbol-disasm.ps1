[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$OriginalPath,

    [Parameter(Mandatory = $true)]
    [uint64]$OriginalRva,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, [int]::MaxValue)]
    [int]$Size,

    [Parameter(Mandatory = $true)]
    [string]$CandidatePath,

    [Parameter(Mandatory = $true)]
    [string]$CandidateMapPath,

    [Parameter(Mandatory = $true)]
    [string]$CandidateSymbol,

    [string]$CandidateObjectPath,

    [string]$CandidateObjectDirectory,

    [string]$DumpbinPath = "C:\msdev\bin\DUMPBIN.EXE",

    [uint64]$ContextBytes = 0x10,

    [string]$ResultsJsonPath = "",

    [ValidateRange(1, 64)]
    [int]$AlignmentLookahead = 12,

    [ValidateRange(0, 100)]
    [int]$MaxMismatchIslands = 12,

    [switch]$SummaryOnly,

    [switch]$DumpHex
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Read-U16([byte[]]$Bytes, [int]$Offset) {
    return [uint16](([uint64]$Bytes[$Offset]) -bor
        (([uint64]$Bytes[$Offset + 1]) -shl 8))
}

function Read-I16([byte[]]$Bytes, [int]$Offset) {
    $value = Read-U16 $Bytes $Offset
    if ($value -ge 0x8000) {
        return [int]$value - 0x10000
    }
    return [int]$value
}

function Read-U32([byte[]]$Bytes, [int]$Offset) {
    return [uint32](
        ([uint64]$Bytes[$Offset]) -bor
        (([uint64]$Bytes[$Offset + 1]) -shl 8) -bor
        (([uint64]$Bytes[$Offset + 2]) -shl 16) -bor
        (([uint64]$Bytes[$Offset + 3]) -shl 24))
}

function Assert-Range(
    [byte[]]$Bytes,
    [uint64]$Offset,
    [uint64]$Count,
    [string]$Description) {

    if ($Offset -gt [uint64]$Bytes.LongLength -or
        $Count -gt ([uint64]$Bytes.LongLength - $Offset)) {
        throw (("{0} is outside the file (offset=0x{1:x}, size=0x{2:x}, " +
            "file-size=0x{3:x}).") -f
            $Description, $Offset, $Count, $Bytes.LongLength)
    }
}

function Get-Ascii([byte[]]$Bytes, [int]$Offset, [int]$Count) {
    Assert-Range $Bytes $Offset $Count "ASCII field"
    $text = [System.Text.Encoding]::ASCII.GetString($Bytes, $Offset, $Count)
    $nul = $text.IndexOf([char]0)
    if ($nul -ge 0) {
        $text = $text.Substring(0, $nul)
    }
    return $text
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-ByteArraySha256([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return [System.BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace(
            "-", "").ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Get-Hex([byte[]]$Bytes) {
    return (($Bytes | ForEach-Object { $_.ToString("x2") }) -join "")
}

function Test-PathIsDescendantOf([string]$Path, [string]$Root) {
    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    $resolvedRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar)
    $prefix = $resolvedRoot + [System.IO.Path]::DirectorySeparatorChar
    return $resolvedPath.StartsWith($prefix,
        [System.StringComparison]::OrdinalIgnoreCase)
}

function Assert-NoReparseTraversal([string]$RepoRoot, [string]$Path) {
    $resolvedRoot = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar)
    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    if (-not (Test-PathIsDescendantOf $resolvedPath $resolvedRoot)) {
        throw "Path is outside the repository root: '$resolvedPath'."
    }

    $relative = $resolvedPath.Substring($resolvedRoot.Length).TrimStart(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar)
    $segments = @($relative -split '[\\/]' | Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    })
    $cursor = $resolvedRoot
    $pathsToCheck = @($cursor)
    foreach ($segment in $segments) {
        $cursor = Join-Path $cursor $segment
        $pathsToCheck += $cursor
    }
    for ($index = 0; $index -lt $pathsToCheck.Count; $index++) {
        $candidate = $pathsToCheck[$index]
        if (-not (Test-Path -LiteralPath $candidate)) { continue }
        $item = Get-Item -LiteralPath $candidate -Force
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "ResultsJsonPath must not traverse a reparse point: '$candidate'."
        }
        if ($index -lt $pathsToCheck.Count - 1 -and -not $item.PSIsContainer) {
            throw "ResultsJsonPath traverses a non-directory path: '$candidate'."
        }
    }
}

function Resolve-SafeResultsJsonPath(
    [string]$Path,
    [string]$RepoRoot) {

    if ([string]::IsNullOrWhiteSpace($Path)) { return "" }
    $resolvedRoot = [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar)
    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    $approvedRoots = @(
        (Join-Path $resolvedRoot "a"),
        (Join-Path $resolvedRoot "artifacts"))
    $approved = @($approvedRoots | Where-Object {
        Test-PathIsDescendantOf $resolvedPath $_
    })
    if ($approved.Count -ne 1) {
        throw ("ResultsJsonPath must be below the repository's Git-ignored " +
            "'a' or 'artifacts' directory: '$resolvedPath'.")
    }
    $relative = $resolvedPath.Substring($resolvedRoot.Length).TrimStart(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar)
    if ($relative.Contains(':')) {
        throw "ResultsJsonPath must not name an alternate data stream: '$resolvedPath'."
    }
    if (Test-Path -LiteralPath $resolvedPath -PathType Container) {
        throw "ResultsJsonPath names a directory: '$resolvedPath'."
    }
    Assert-NoReparseTraversal $resolvedRoot $resolvedPath

    $gitRelative = $relative.Replace('\', '/')
    & git -C $resolvedRoot check-ignore --quiet --no-index -- $gitRelative
    $ignoreExitCode = $LASTEXITCODE
    if ($ignoreExitCode -ne 0) {
        throw (("ResultsJsonPath is not Git-ignored (git check-ignore exit {0}): " +
            "'{1}'.") -f $ignoreExitCode, $resolvedPath)
    }
    $trackedPaths = @(& git -C $resolvedRoot ls-files -- $gitRelative 2>$null)
    $trackedExitCode = $LASTEXITCODE
    if ($trackedExitCode -ne 0) {
        throw (("Unable to establish ResultsJsonPath tracking state " +
            "(git ls-files exit {0}): '{1}'.") -f $trackedExitCode, $resolvedPath)
    }
    if ($trackedPaths.Count -ne 0) {
        throw "ResultsJsonPath is already tracked by Git: '$resolvedPath'."
    }
    return $resolvedPath
}

function Assert-ResultsPathDoesNotOverwrite(
    [string]$ResultsPath,
    [object[]]$ProtectedPaths) {

    if ([string]::IsNullOrWhiteSpace($ResultsPath)) { return }
    foreach ($protectedPath in $ProtectedPaths) {
        if ($null -eq $protectedPath -or
            [string]::IsNullOrWhiteSpace([string]$protectedPath)) {
            continue
        }
        $resolvedProtected = (Resolve-Path -LiteralPath ([string]$protectedPath)).Path
        if ($ResultsPath.Equals($resolvedProtected,
            [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "ResultsJsonPath must not overwrite an input or tool file: '$ResultsPath'."
        }
    }
}

function Write-Utf8TextAtomic([string]$Path, [string]$Text) {
    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        [void][System.IO.Directory]::CreateDirectory($directory)
    }
    $leaf = Split-Path -Leaf $Path
    $temporaryPath = Join-Path $directory (
        ".{0}.{1}.tmp" -f $leaf, [guid]::NewGuid().ToString("N"))
    $backupPath = $temporaryPath + ".bak"
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    try {
        [System.IO.File]::WriteAllText($temporaryPath, $Text, $utf8NoBom)
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

function Copy-ByteRange([byte[]]$Bytes, [int]$Offset, [int]$Count) {
    Assert-Range $Bytes $Offset $Count "byte range"
    $result = New-Object byte[] $Count
    [System.Array]::Copy($Bytes, $Offset, $result, 0, $Count)
    return $result
}

function Get-PeImageInfo([string]$Path) {
    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $bytes = [System.IO.File]::ReadAllBytes($resolved)
    Assert-Range $bytes 0x3c 4 "DOS e_lfanew"
    $peOffset = [int](Read-U32 $bytes 0x3c)
    Assert-Range $bytes $peOffset 24 "PE/COFF header"
    if ((Get-Ascii $bytes $peOffset 4) -cne "PE") {
        # Get-Ascii trims the two NUL bytes from the PE signature.
        if ($bytes[$peOffset] -ne 0x50 -or $bytes[$peOffset + 1] -ne 0x45 -or
            $bytes[$peOffset + 2] -ne 0 -or $bytes[$peOffset + 3] -ne 0) {
            throw "Invalid PE signature: $Path"
        }
    }

    $coff = $peOffset + 4
    $sectionCount = [int](Read-U16 $bytes ($coff + 2))
    $optionalSize = [int](Read-U16 $bytes ($coff + 16))
    $optional = $coff + 20
    Assert-Range $bytes $optional $optionalSize "PE optional header"
    $magic = Read-U16 $bytes $optional
    if ($magic -ne 0x10b) {
        if ($magic -eq 0x20b) {
            throw "PE32+ images are not supported by this helper: $Path"
        }
        throw ("Unsupported optional header magic 0x{0:x}: {1}" -f $magic, $Path)
    }
    $imageBase = [uint64](Read-U32 $bytes ($optional + 28))
    $directoryCount = [int](Read-U32 $bytes ($optional + 92))
    $relocationRva = [uint64]0
    $relocationSize = [uint64]0
    if ($directoryCount -gt 5 -and $optionalSize -ge 136) {
        $relocationRva = [uint64](Read-U32 $bytes ($optional + 96 + (5 * 8)))
        $relocationSize = [uint64](Read-U32 $bytes ($optional + 100 + (5 * 8)))
    }

    $sectionTable = $optional + $optionalSize
    Assert-Range $bytes $sectionTable ([uint64]$sectionCount * 40) "PE section table"
    $sections = @()
    for ($index = 0; $index -lt $sectionCount; $index++) {
        $offset = $sectionTable + ($index * 40)
        $sections += [pscustomobject][ordered]@{
            name = Get-Ascii $bytes $offset 8
            virtual_size = [uint64](Read-U32 $bytes ($offset + 8))
            virtual_address = [uint64](Read-U32 $bytes ($offset + 12))
            raw_size = [uint64](Read-U32 $bytes ($offset + 16))
            raw_pointer = [uint64](Read-U32 $bytes ($offset + 20))
        }
    }

    return [pscustomobject][ordered]@{
        path = $resolved
        bytes = $bytes
        image_base = $imageBase
        sections = $sections
        relocation_rva = $relocationRva
        relocation_size = $relocationSize
    }
}

function Convert-RvaToFileOffset($Image, [uint64]$Rva, [int]$Count) {
    foreach ($section in $Image.sections) {
        $extent = [System.Math]::Max(
            [uint64]$section.virtual_size, [uint64]$section.raw_size)
        if ($Rva -ge [uint64]$section.virtual_address -and
            $Rva -lt ([uint64]$section.virtual_address + $extent)) {
            $delta = $Rva - [uint64]$section.virtual_address
            if ($delta + [uint64]$Count -gt [uint64]$section.raw_size) {
                throw ("RVA 0x{0:x} extends beyond raw section '{1}'." -f
                    $Rva, $section.name)
            }
            $fileOffset = [uint64]$section.raw_pointer + $delta
            Assert-Range $Image.bytes $fileOffset $Count ("RVA 0x{0:x}" -f $Rva)
            return [int]$fileOffset
        }
    }
    throw ("RVA 0x{0:x} is not in any PE section." -f $Rva)
}

function Read-RvaBytes($Image, [uint64]$Rva, [int]$Count) {
    $fileOffset = Convert-RvaToFileOffset $Image $Rva $Count
    return Copy-ByteRange $Image.bytes $fileOffset $Count
}

function Get-PeHighlowOperands($Image, [uint64]$FunctionRva, [int]$FunctionSize) {
    $result = @()
    if ([uint64]$Image.relocation_rva -eq 0 -or
        [uint64]$Image.relocation_size -lt 8) {
        return $result
    }

    $directoryOffset = Convert-RvaToFileOffset $Image $Image.relocation_rva 8
    $directoryEnd = [uint64]$directoryOffset + [uint64]$Image.relocation_size
    if ($directoryEnd -gt [uint64]$Image.bytes.LongLength) {
        throw "PE base-relocation directory extends beyond the file."
    }

    $cursor = [uint64]$directoryOffset
    while ($cursor + 8 -le $directoryEnd) {
        $pageRva = [uint64](Read-U32 $Image.bytes ([int]$cursor))
        $blockSize = [uint64](Read-U32 $Image.bytes ([int]$cursor + 4))
        if ($blockSize -lt 8 -or $cursor + $blockSize -gt $directoryEnd) {
            throw "Malformed PE base-relocation block."
        }
        $entryCount = [int](($blockSize - 8) / 2)
        for ($index = 0; $index -lt $entryCount; $index++) {
            $entry = Read-U16 $Image.bytes ([int]$cursor + 8 + ($index * 2))
            $type = [int]($entry -shr 12)
            if ($type -ne 3) {
                continue
            }
            $operandRva = $pageRva + [uint64]($entry -band 0x0fff)
            if ($operandRva -ge $FunctionRva -and
                $operandRva + 4 -le $FunctionRva + [uint64]$FunctionSize) {
                $result += [pscustomobject][ordered]@{
                    function_offset = [int]($operandRva - $FunctionRva)
                    width = 4
                    kind = "pe_highlow"
                    normalization_class = "absolute_address_32"
                    symbol = ""
                }
            }
        }
        $cursor += $blockSize
    }
    return $result
}

function Resolve-MapSymbol([string]$MapPath, [string]$Symbol) {
    $symbolExpression = $Symbol.Trim()
    if ($symbolExpression -notmatch
        '^(?<symbol>.+?)(?:\s*\+\s*(?<offset>0x[0-9a-fA-F]+|[0-9]+))?$') {
        throw "Invalid candidate symbol expression: $Symbol"
    }

    $baseSymbol = $Matches["symbol"].Trim()
    $offset = [uint64]0
    if ($Matches.ContainsKey("offset") -and
        -not [string]::IsNullOrWhiteSpace($Matches["offset"])) {
        $offsetText = $Matches["offset"]
        if ($offsetText.StartsWith("0x", [System.StringComparison]::OrdinalIgnoreCase)) {
            $offset = [uint64]::Parse($offsetText.Substring(2),
                [System.Globalization.NumberStyles]::HexNumber)
        } else {
            $offset = [uint64]::Parse($offsetText,
                [System.Globalization.NumberStyles]::Integer)
        }
    }

    $resolved = (Resolve-Path -LiteralPath $MapPath).Path
    foreach ($line in Get-Content -LiteralPath $resolved) {
        if ($line -match
            '^\s*\d+:[0-9a-fA-F]+\s+(\S+)\s+([0-9a-fA-F]+)\s+\S+\s+(.+?)\s*$') {
            if ($Matches[1] -ceq $baseSymbol) {
                $va = [uint64]::Parse($Matches[2],
                    [System.Globalization.NumberStyles]::HexNumber)
                return [pscustomobject][ordered]@{
                    symbol = $Matches[1]
                    va = $va + $offset
                    symbol_offset = $offset
                    object = $Matches[3].Trim()
                }
            }
        }
    }
    throw "Symbol not found in map: $baseSymbol"
}

function Resolve-CandidateObjectPath(
    $MapInfo,
    [string]$MapPath,
    [string]$ExplicitPath,
    [string]$ObjectDirectory) {

    if (-not [string]::IsNullOrWhiteSpace($ExplicitPath)) {
        return (Resolve-Path -LiteralPath $ExplicitPath).Path
    }

    $searchRoot = if ([string]::IsNullOrWhiteSpace($ObjectDirectory)) {
        Split-Path -Parent (Resolve-Path -LiteralPath $MapPath).Path
    } else {
        (Resolve-Path -LiteralPath $ObjectDirectory).Path
    }
    $objectName = Split-Path -Leaf $MapInfo.object
    $candidate = Join-Path $searchRoot $objectName
    if (Test-Path -LiteralPath $candidate -PathType Leaf) {
        return (Resolve-Path -LiteralPath $candidate).Path
    }
    $found = Get-ChildItem -LiteralPath $searchRoot -Filter $objectName -File `
        -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -ne $found) {
        return $found.FullName
    }
    return $null
}

function Get-CoffSymbolName(
    [byte[]]$Bytes,
    [int]$SymbolOffset,
    [int]$StringTableOffset) {

    $zeroes = Read-U32 $Bytes $SymbolOffset
    if ($zeroes -eq 0) {
        $stringOffset = [int](Read-U32 $Bytes ($SymbolOffset + 4))
        $start = $StringTableOffset + $stringOffset
        Assert-Range $Bytes $start 1 "COFF symbol string"
        $end = $start
        while ($end -lt $Bytes.Length -and $Bytes[$end] -ne 0) {
            $end++
        }
        return Get-Ascii $Bytes $start ($end - $start)
    }
    return Get-Ascii $Bytes $SymbolOffset 8
}

function Get-CoffFunctionInfo(
    [string]$Path,
    [string]$Symbol,
    [uint64]$SymbolOffset,
    [int]$FunctionSize) {

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $bytes = [System.IO.File]::ReadAllBytes($resolved)
    Assert-Range $bytes 0 20 "COFF header"
    $sectionCount = [int](Read-U16 $bytes 2)
    $symbolTable = [int](Read-U32 $bytes 8)
    $symbolCount = [int](Read-U32 $bytes 12)
    $optionalSize = [int](Read-U16 $bytes 16)
    $sectionTable = 20 + $optionalSize
    Assert-Range $bytes $sectionTable ([uint64]$sectionCount * 40) "COFF sections"
    if ($symbolTable -le 0 -or $symbolCount -le 0) {
        throw "Candidate object has no COFF symbol table: $Path"
    }
    Assert-Range $bytes $symbolTable ([uint64]$symbolCount * 18) "COFF symbols"
    $stringTable = $symbolTable + ($symbolCount * 18)
    Assert-Range $bytes $stringTable 4 "COFF string table"

    $symbols = @{}
    $functionSymbol = $null
    $index = 0
    while ($index -lt $symbolCount) {
        $entry = $symbolTable + ($index * 18)
        $name = Get-CoffSymbolName $bytes $entry $stringTable
        $value = [uint64](Read-U32 $bytes ($entry + 8))
        $sectionNumber = Read-I16 $bytes ($entry + 12)
        $auxCount = [int]$bytes[$entry + 17]
        $symbolInfo = [pscustomobject][ordered]@{
            index = $index
            name = $name
            value = $value
            section_number = $sectionNumber
        }
        $symbols[$index] = $symbolInfo
        if ($name -ceq $Symbol) {
            $functionSymbol = $symbolInfo
        }
        $index += 1 + $auxCount
    }
    if ($null -eq $functionSymbol -or $functionSymbol.section_number -le 0 -or
        $functionSymbol.section_number -gt $sectionCount) {
        throw "Candidate symbol '$Symbol' was not found in the COFF object symbol table."
    }

    $sectionOffset = $sectionTable + (($functionSymbol.section_number - 1) * 40)
    $relocationPointer = [int](Read-U32 $bytes ($sectionOffset + 24))
    $relocationCount = [int](Read-U16 $bytes ($sectionOffset + 32))
    if ($relocationCount -gt 0) {
        Assert-Range $bytes $relocationPointer ([uint64]$relocationCount * 10) `
            "COFF relocations"
    }
    $functionStart = [uint64]$functionSymbol.value + $SymbolOffset
    $internalLabels = @($symbols.Values | Where-Object {
        $_.section_number -eq $functionSymbol.section_number -and
        $_.name -cmatch '^\$L' -and
        [uint64]$_.value -ge $functionStart -and
        [uint64]$_.value -lt $functionStart + [uint64]$FunctionSize
    } | Sort-Object value, name | ForEach-Object {
        [pscustomobject][ordered]@{
            name = [string]$_.name
            section_offset = [uint64]$_.value
        }
    })
    $operands = @()
    for ($relocationIndex = 0; $relocationIndex -lt $relocationCount;
        $relocationIndex++) {
        $entry = $relocationPointer + ($relocationIndex * 10)
        $address = [uint64](Read-U32 $bytes $entry)
        $targetIndex = [int](Read-U32 $bytes ($entry + 4))
        $type = [int](Read-U16 $bytes ($entry + 8))
        if ($address -lt $functionStart -or
            $address + 4 -gt $functionStart + [uint64]$FunctionSize) {
            continue
        }
        $kind = ""
        $normalizationClass = ""
        if ($type -eq 0x0006 -or $type -eq 0x0007) {
            $kind = if ($type -eq 0x0006) { "coff_dir32" } else { "coff_dir32nb" }
            $normalizationClass = "absolute_address_32"
        } elseif ($type -eq 0x0014) {
            $kind = "coff_rel32"
            $normalizationClass = "relative_address_32"
        } else {
            continue
        }
        $targetName = ""
        if ($symbols.ContainsKey($targetIndex)) {
            $targetName = [string]$symbols[$targetIndex].name
        }
        $operands += [pscustomobject][ordered]@{
            function_offset = [int]($address - $functionStart)
            width = 4
            kind = $kind
            normalization_class = $normalizationClass
            symbol = $targetName
        }
    }

    return [pscustomobject][ordered]@{
        path = $resolved
        sha256 = Get-Sha256 $resolved
        function_section_offset = $functionStart
        section_number = [int]$functionSymbol.section_number
        internal_labels = $internalLabels
        address_operands = $operands
    }
}

function Copy-ToDumpbinFriendlyPath([string]$Path) {
    $resolved = (Resolve-Path -LiteralPath $Path).Path
    if ($resolved -notmatch '\s') {
        return $resolved
    }
    $extension = [System.IO.Path]::GetExtension($resolved)
    if ([string]::IsNullOrWhiteSpace($extension)) {
        $extension = ".bin"
    }
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    try {
        $hashBytes = $sha1.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($resolved))
    } finally {
        $sha1.Dispose()
    }
    $hash = [System.BitConverter]::ToString($hashBytes).Replace("-", "").Substring(
        0, 12).ToLowerInvariant()
    # DUMPBIN cannot reliably consume paths containing spaces in every VC4
    # installation.  Each invocation needs its own friendly copy: a path-only
    # name races when focused diffs run in parallel against the same input.
    $tempPath = Join-Path $env:TEMP (
        "otmatch-dumpbin-{0}-{1}-{2}{3}" -f
            $hash,
            $PID,
            [System.Guid]::NewGuid().ToString("N"),
            $extension)
    try {
        Copy-Item -LiteralPath $resolved -Destination $tempPath
    }
    catch {
        if (Test-Path -LiteralPath $tempPath -PathType Leaf) {
            Remove-Item -LiteralPath $tempPath -Force
        }
        throw
    }
    return $tempPath
}

function Invoke-DumpbinDisasm([string]$InputPath, [string]$Dumpbin) {
    if (-not (Test-Path -LiteralPath $Dumpbin -PathType Leaf)) {
        throw "dumpbin was not found at '$Dumpbin'. Pass -DumpbinPath to override."
    }
    $resolvedInput = (Resolve-Path -LiteralPath $InputPath).Path
    $friendlyInput = Copy-ToDumpbinFriendlyPath $resolvedInput
    $friendlyInputIsTemporary = -not [string]::Equals(
        $friendlyInput,
        $resolvedInput,
        [System.StringComparison]::OrdinalIgnoreCase)
    $outputPath = Join-Path $env:TEMP (
        "otmatch-dumpbin-{0}.txt" -f [System.Guid]::NewGuid().ToString("N"))
    try {
        & $Dumpbin /DISASM /OUT:$outputPath $friendlyInput | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "dumpbin failed for '$InputPath' (exit $LASTEXITCODE)."
        }
        return @(Get-Content -LiteralPath $outputPath)
    } finally {
        if (Test-Path -LiteralPath $outputPath -PathType Leaf) {
            Remove-Item -LiteralPath $outputPath -Force
        }
        if ($friendlyInputIsTemporary -and
            (Test-Path -LiteralPath $friendlyInput -PathType Leaf)) {
            Remove-Item -LiteralPath $friendlyInput -Force
        }
    }
}

function Resolve-VerifiedDumpbinLabel(
    [string]$ObservedLabel,
    [string[]]$VerifiedLabels) {

    $uniqueVerified = @()
    foreach ($verifiedLabel in $VerifiedLabels) {
        if (-not [string]::IsNullOrWhiteSpace($verifiedLabel) -and
            $uniqueVerified -cnotcontains $verifiedLabel) {
            $uniqueVerified += $verifiedLabel
        }
    }
    if ($uniqueVerified -ccontains $ObservedLabel) {
        return $ObservedLabel
    }

    $prefixMatches = @($uniqueVerified | Where-Object {
        $_.StartsWith('?', [System.StringComparison]::Ordinal) -and
        $ObservedLabel.StartsWith($_ + ' ',
            [System.StringComparison]::Ordinal)
    })
    if ($prefixMatches.Count -eq 0) {
        return $ObservedLabel
    }
    if ($prefixMatches.Count -ne 1) {
        throw (("DUMPBIN label '{0}' ambiguously matches {1} verified " +
            "decorated COFF symbols.") -f $ObservedLabel,
            $prefixMatches.Count)
    }

    $verifiedPrefix = [string]$prefixMatches[0]
    $suffix = $ObservedLabel.Substring($verifiedPrefix.Length + 1)
    if ($suffix.Length -lt 3 -or $suffix[0] -ne '(' -or
        $suffix[$suffix.Length - 1] -ne ')') {
        throw (("DUMPBIN label for verified decorated COFF symbol '{0}' " +
            "has a malformed parenthesized display suffix: '{1}'.") -f
            $verifiedPrefix, $ObservedLabel)
    }
    $depth = 0
    for ($index = 0; $index -lt $suffix.Length; $index++) {
        if ($suffix[$index] -eq '(') {
            $depth++
        } elseif ($suffix[$index] -eq ')') {
            $depth--
            if ($depth -lt 0) {
                throw (("DUMPBIN label for verified decorated COFF symbol " +
                    "'{0}' has an unbalanced display suffix: '{1}'.") -f
                    $verifiedPrefix, $ObservedLabel)
            }
        }
        if ($depth -eq 0 -and $index -lt $suffix.Length - 1) {
            throw (("DUMPBIN label for verified decorated COFF symbol '{0}' " +
                "has an ambiguous multi-part display suffix: '{1}'.") -f
                $verifiedPrefix, $ObservedLabel)
        }
    }
    if ($depth -ne 0 -or
        [string]::IsNullOrWhiteSpace($suffix.Substring(1,
            $suffix.Length - 2))) {
        throw (("DUMPBIN label for verified decorated COFF symbol '{0}' " +
            "has a malformed parenthesized display suffix: '{1}'.") -f
            $verifiedPrefix, $ObservedLabel)
    }
    return $verifiedPrefix
}

function Get-AllDisassemblyInstructions(
    [string[]]$Lines,
    [string[]]$VerifiedLabels = @()) {

    [System.Collections.ArrayList]$records = New-Object System.Collections.ArrayList
    $currentLabel = ""
    $current = $null
    foreach ($line in $Lines) {
        if ($line -match '^([^\s].*):\s*$') {
            if ($null -ne $current) {
                try {
                    [void]$records.Add($current)
                } catch {
                    throw ("disassembly record append failed (type={0}, line={1}): {2}" -f
                        $records.GetType().FullName, $line, $_.Exception.Message)
                }
                $current = $null
            }
            $currentLabel = Resolve-VerifiedDumpbinLabel $Matches[1] `
                $VerifiedLabels
            continue
        }
        if ($line -match
            '^\s*(?<address>[0-9a-fA-F]{8,16}):\s+(?<bytes>(?:[0-9a-fA-F]{2}\s+)+)(?<text>\S.*)$') {
            if ($null -ne $current) {
                try {
                    [void]$records.Add($current)
                } catch {
                    throw ("disassembly record append failed (type={0}, line={1}): {2}" -f
                        $records.GetType().FullName, $line, $_.Exception.Message)
                }
            }
            $addressText = $Matches["address"]
            $byteText = $Matches["bytes"]
            $instructionText = $Matches["text"].Trim()
            $parsedBytes = @($byteText -split '\s+' |
                Where-Object { $_ -match '^[0-9a-fA-F]{2}$' } |
                ForEach-Object { [byte]::Parse($_,
                    [System.Globalization.NumberStyles]::HexNumber) })
            $current = [pscustomobject][ordered]@{
                label = $currentLabel
                address = [uint64]::Parse($addressText,
                    [System.Globalization.NumberStyles]::HexNumber)
                dumpbin_bytes = [byte[]]$parsedBytes
                text = $instructionText
            }
            continue
        }
        if ($null -ne $current -and $line.Trim() -match
            '^(?:[0-9a-fA-F]{2}\s*)+$') {
            $continuation = @($line.Trim() -split '\s+' |
                Where-Object { $_ -match '^[0-9a-fA-F]{2}$' } |
                ForEach-Object { [byte]::Parse($_,
                    [System.Globalization.NumberStyles]::HexNumber) })
            $current.dumpbin_bytes = [byte[]]@(
                @($current.dumpbin_bytes) + @($continuation))
        }
    }
    if ($null -ne $current) {
        try {
            [void]$records.Add($current)
        } catch {
            throw ("final disassembly record append failed (type={0}): {1}" -f
                $records.GetType().FullName, $_.Exception.Message)
        }
    }
    return @($records)
}

function Select-FunctionInstructions(
    [object[]]$AllInstructions,
    [uint64]$StartAddress,
    [int]$FunctionSize,
    [byte[]]$LinkedFunctionBytes,
    [string]$RequiredLabel = "",
    [object[]]$AllowedInternalLabels = @()) {

    $selected = @()
    if ([string]::IsNullOrWhiteSpace($RequiredLabel)) {
        $selected = @($AllInstructions | Where-Object {
            $_.address -ge $StartAddress -and
            $_.address -lt $StartAddress + [uint64]$FunctionSize
        } | Sort-Object address)
    } else {
        $startIndexes = @()
        for ($index = 0; $index -lt $AllInstructions.Count; $index++) {
            $instruction = $AllInstructions[$index]
            if ($instruction.label -ceq $RequiredLabel -and
                [uint64]$instruction.address -eq $StartAddress) {
                $startIndexes += $index
            }
        }
        if ($startIndexes.Count -ne 1) {
            throw (("Candidate COFF disassembly requires exactly one stream " +
                "start for label '{0}' at 0x{1:x}; found {2}.") -f
                $RequiredLabel, $StartAddress, $startIndexes.Count)
        }

        $cursor = 0
        $activeLabel = $RequiredLabel
        for ($index = [int]$startIndexes[0];
            $index -lt $AllInstructions.Count -and $cursor -lt $FunctionSize;
            $index++) {
            $instruction = $AllInstructions[$index]
            $expectedAddress = $StartAddress + [uint64]$cursor
            $actualAddress = [uint64]$instruction.address
            if ($actualAddress -ne $expectedAddress) {
                $kind = if ($actualAddress -lt $expectedAddress) {
                    "overlap or later section"
                } else {
                    "gap"
                }
                throw (("Candidate COFF disassembly has a {0} at function " +
                    "offset 0x{1:x}; the next stream instruction is at " +
                    "section offset 0x{2:x}.") -f
                    $kind, $cursor, $actualAddress)
            }

            $label = [string]$instruction.label
            if ($label -cne $activeLabel) {
                if ($label -cnotmatch '^\$L') {
                    throw (("Candidate COFF disassembly encountered later " +
                        "external label '{0}' at function offset 0x{1:x} " +
                        "before covering 0x{2:x} bytes.") -f
                        $label, $cursor, $FunctionSize)
                }
                $matchingLabels = @($AllowedInternalLabels | Where-Object {
                    $_.name -ceq $label
                })
                if ($matchingLabels.Count -ne 1 -or
                    [uint64]$matchingLabels[0].section_offset -ne
                        $actualAddress) {
                    throw (("Candidate COFF disassembly encountered " +
                        "unverified internal label '{0}' at section offset " +
                        "0x{1:x}; it is not a unique in-range symbol in the " +
                        "function's COFF section.") -f $label, $actualAddress)
                }
                $activeLabel = $label
            }

            $instructionSize = [int]$instruction.dumpbin_bytes.Count
            if ($instructionSize -le 0) {
                throw (("Candidate COFF disassembly has a zero-length " +
                    "instruction at function offset 0x{0:x}.") -f $cursor)
            }
            if ($cursor + $instructionSize -gt $FunctionSize) {
                throw (("Candidate COFF instruction at function offset " +
                    "0x{0:x} extends beyond the 0x{1:x}-byte function.") -f
                    $cursor, $FunctionSize)
            }
            $selected += $instruction
            $cursor += $instructionSize
        }
        if ($cursor -ne $FunctionSize) {
            throw (("Candidate COFF disassembly covers 0x{0:x} of 0x{1:x} " +
                "function bytes.") -f $cursor, $FunctionSize)
        }
    }

    $result = @()
    foreach ($instruction in $selected) {
        $offset = [int]([uint64]$instruction.address - $StartAddress)
        $instructionSize = [int]$instruction.dumpbin_bytes.Count
        if ($instructionSize -le 0 -or $offset + $instructionSize -gt $FunctionSize) {
            continue
        }
        $rawBytes = Copy-ByteRange $LinkedFunctionBytes $offset $instructionSize
        $selectedRecord = [pscustomobject][ordered]@{
            ordinal = $result.Count
            offset = $offset
            size = $instructionSize
            address = "0x{0:x}" -f [uint64]$instruction.address
            raw_bytes = Get-Hex $rawBytes
            dumpbin_bytes = Get-Hex ([byte[]]$instruction.dumpbin_bytes)
            raw_text = [string]$instruction.text
            mnemonic = ""
            operands = @()
            operand_classes = @()
            normalized_text = ""
            normalized_bytes_pattern = ""
            address_operands = @()
            block_index = -1
            block_start_offset = -1
            shape_key = ""
            _bytes = $rawBytes
            _dumpbin_bytes = [byte[]]$instruction.dumpbin_bytes
        }
        $result += $selectedRecord
    }
    return @($result)
}

function Assert-InstructionCoverage(
    [object[]]$Instructions,
    [int]$FunctionSize,
    [string]$Description) {

    if ($Instructions.Count -eq 0) {
        throw "$Description disassembly contains no instructions."
    }
    $cursor = 0
    foreach ($instruction in @($Instructions | Sort-Object offset)) {
        $offset = [int]$instruction.offset
        $instructionSize = [int]$instruction.size
        if ($instructionSize -le 0) {
            throw ("{0} disassembly has a zero-length instruction at 0x{1:x}." -f
                $Description, $offset)
        }
        if ($offset -ne $cursor) {
            $kind = if ($offset -lt $cursor) { "overlap" } else { "gap" }
            throw (("{0} disassembly has a {1} at function offset 0x{2:x}; " +
                "the next parsed instruction starts at 0x{3:x}.") -f
                $Description, $kind, $cursor, $offset)
        }
        if ($offset + $instructionSize -gt $FunctionSize) {
            throw (("{0} instruction at 0x{1:x} extends beyond the " +
                "0x{2:x}-byte function.") -f
                $Description, $offset, $FunctionSize)
        }
        $cursor = $offset + $instructionSize
    }
    if ($cursor -ne $FunctionSize) {
        throw ("{0} disassembly covers 0x{1:x} of 0x{2:x} function bytes." -f
            $Description, $cursor, $FunctionSize)
    }
}

function Assert-DisassemblyByteConsistency(
    [object[]]$Instructions,
    [bool]$AllowAcceptedCoffRelocations,
    [string]$Description) {

    foreach ($instruction in $Instructions) {
        $linkedBytes = [byte[]]$instruction._bytes
        $dumpbinBytes = [byte[]]$instruction._dumpbin_bytes
        if ($linkedBytes.Length -ne $dumpbinBytes.Length) {
            throw ("{0} instruction byte-count disagreement at 0x{1:x}." -f
                $Description, [int]$instruction.offset)
        }
        for ($index = 0; $index -lt $linkedBytes.Length; $index++) {
            if ($linkedBytes[$index] -eq $dumpbinBytes[$index]) { continue }
            $allowed = $false
            if ($AllowAcceptedCoffRelocations) {
                $allowed = @($instruction.address_operands | Where-Object {
                    (($_.kind -like 'coff_*') -or
                        ($_.relocation_kind -like 'coff_*')) -and
                    $index -ge [int]$_.instruction_offset -and
                    $index -lt [int]$_.instruction_offset + [int]$_.width
                }).Count -gt 0
            }
            if (-not $allowed) {
                throw (("{0} dumpbin bytes disagree with linked bytes outside " +
                    "an accepted COFF relocation at function offset 0x{1:x}.") -f
                    $Description, ([int]$instruction.offset + $index))
            }
        }
    }
}

function Write-ParsedDisassemblyRange(
    [object[]]$Instructions,
    [uint64]$StartAddress,
    [int]$FunctionSize,
    [uint64]$Context) {

    $from = if ($StartAddress -gt $Context) {
        $StartAddress - $Context
    } else {
        [uint64]0
    }
    $to = $StartAddress + [uint64]$FunctionSize + $Context
    $selected = @($Instructions | Where-Object {
        [uint64]$_.address -ge $from -and [uint64]$_.address -lt $to
    } | Sort-Object address)
    if ($selected.Count -eq 0) {
        Write-Host ("  <no dumpbin instructions found for 0x{0:x}-0x{1:x}>" -f
            $StartAddress, ($StartAddress + [uint64]$FunctionSize))
        return
    }
    foreach ($instruction in $selected) {
        $inside = [uint64]$instruction.address -ge $StartAddress -and
            [uint64]$instruction.address -lt
                $StartAddress + [uint64]$FunctionSize
        Write-Host ("  {0} {1:x8}: {2,-30} {3}" -f
            $(if ($inside) { "*" } else { " " }),
            [uint64]$instruction.address,
            (Get-Hex ([byte[]]$instruction.dumpbin_bytes)),
            [string]$instruction.text)
    }
}

function Get-DirectControlOperand($Instruction, [uint64]$FunctionAddress) {
    $bytes = [byte[]]$Instruction._bytes
    if ($bytes.Length -lt 2) {
        return $null
    }
    $prefixes = @(0x26, 0x2e, 0x36, 0x3e, 0x64, 0x65, 0x66, 0x67,
        0xf0, 0xf2, 0xf3)
    $opcodeOffset = 0
    while ($opcodeOffset -lt $bytes.Length -and
        $prefixes -contains [int]$bytes[$opcodeOffset]) {
        $opcodeOffset++
    }
    if ($opcodeOffset -ge $bytes.Length) {
        return $null
    }
    $operandOffset = -1
    $width = 0
    $opcode = [int]$bytes[$opcodeOffset]
    if (($opcode -eq 0xe8 -or $opcode -eq 0xe9) -and
        $opcodeOffset + 5 -eq $bytes.Length) {
        $operandOffset = $opcodeOffset + 1
        $width = 4
    } elseif (($opcode -eq 0xeb -or ($opcode -ge 0x70 -and $opcode -le 0x7f) -or
        ($opcode -ge 0xe0 -and $opcode -le 0xe3)) -and
        $opcodeOffset + 2 -eq $bytes.Length) {
        $operandOffset = $opcodeOffset + 1
        $width = 1
    } elseif ($opcode -eq 0x0f -and $opcodeOffset + 6 -eq $bytes.Length -and
        [int]$bytes[$opcodeOffset + 1] -ge 0x80 -and
        [int]$bytes[$opcodeOffset + 1] -le 0x8f) {
        $operandOffset = $opcodeOffset + 2
        $width = 4
    }
    if ($operandOffset -lt 0) {
        return $null
    }

    $target = $null
    $targetScope = "unknown"
    $targetOffset = $null
    if ($Instruction.raw_text -match
        '(?i)(?<target>[0-9a-f]{8,16})(?:h)?\s*$') {
        $target = [uint64]::Parse($Matches["target"],
            [System.Globalization.NumberStyles]::HexNumber)
        if ($target -ge $FunctionAddress -and
            $target -lt $FunctionAddress + [uint64]$Size) {
            $targetScope = "internal"
            $targetOffset = [int]($target - $FunctionAddress)
        } else {
            $targetScope = "external"
        }
    }
    return [pscustomobject][ordered]@{
        operand_offset = $operandOffset
        width = $width
        kind = if ($width -eq 4) { "direct_relative_32" } else { "direct_relative_8" }
        normalization_class = if ($width -eq 4) {
            "control_flow_target_32"
        } else {
            "control_flow_target_8"
        }
        target = if ($null -eq $target) { "" } else { "0x{0:x}" -f $target }
        target_scope = $targetScope
        target_function_offset = $targetOffset
    }
}

function Split-Operands([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }
    $result = @()
    $start = 0
    $depth = 0
    for ($index = 0; $index -lt $Text.Length; $index++) {
        if ($Text[$index] -eq '[' -or $Text[$index] -eq '(') { $depth++ }
        if ($Text[$index] -eq ']' -or $Text[$index] -eq ')') { $depth-- }
        if ($Text[$index] -eq ',' -and $depth -eq 0) {
            $result += $Text.Substring($start, $index - $start).Trim()
            $start = $index + 1
        }
    }
    $result += $Text.Substring($start).Trim()
    return @($result | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Get-OperandClass([string]$Operand) {
    $value = $Operand.Trim().ToLowerInvariant()
    if ($value -match '^<target:') { return "control_flow_target" }
    if ($value.Contains('[') -and $value -match '<address') {
        return "memory_address"
    }
    if ($value.Contains('[')) { return "memory" }
    if ($value -match '<address') { return "address" }
    if ($value -match '^(?:e?[abcd]x|e?[sd]i|e?[sb]p|[abcd][lh]|[cdefgs]s|st\([0-7]\)|xmm\d+)$') {
        return "register"
    }
    if ($value -match '^(?:-?(?:0x)?[0-9a-f]+h?|offset\s+)') { return "immediate" }
    return "other"
}

function Replace-LastNumericOperand([string]$Text, [string]$Replacement) {
    $matches = [regex]::Matches($Text, '(?i)(?<![a-z0-9_])(?:0x)?[0-9a-f]+h?(?![a-z0-9_])')
    if ($matches.Count -eq 0) {
        return $Text + " " + $Replacement
    }
    $match = $matches[$matches.Count - 1]
    return $Text.Substring(0, $match.Index) + $Replacement +
        $Text.Substring($match.Index + $match.Length)
}

function Get-ProvenRelocatedMemoryNumericMatch(
    [string]$Text,
    $Instruction,
    $AddressOperand,
    [object[]]$ValueMatches) {

    if ([string]$AddressOperand.normalization_class -ne
        "absolute_address_32") {
        return $null
    }

    [byte[]]$bytes = $Instruction._dumpbin_bytes
    $relocationOffset = [int]$AddressOperand.instruction_offset
    # Prefixes and SIB addressing are deliberately outside this narrow proof.
    # Their semantics need separate decoding and contract fixtures before they
    # can participate safely.
    if ($bytes.Length -lt 2) {
        return $null
    }

    $opcode = [int]$bytes[0]
    if ($opcode -ne 0x83 -and $opcode -ne 0xc7) {
        return $null
    }
    $modrm = [int]$bytes[1]
    $mod = ($modrm -shr 6) -band 3
    $reg = ($modrm -shr 3) -band 7
    $rm = $modrm -band 7
    if ($mod -ne 0 -or $rm -ne 5 -or
        ($opcode -eq 0xc7 -and $reg -ne 0)) {
        return $null
    }

    $displacementOffset = 2
    $immediateWidth = if ($opcode -eq 0x83) { 1 } else { 4 }
    $expectedLength = $displacementOffset + 4 + $immediateWidth
    if ($relocationOffset -ne $displacementOffset -or
        $bytes.Length -ne $expectedLength) {
        return $null
    }

    $openBracket = $Text.IndexOf('[')
    if ($openBracket -lt 0) {
        return $null
    }
    $depth = 0
    $closeBracket = -1
    for ($index = $openBracket; $index -lt $Text.Length; $index++) {
        if ($Text[$index] -eq '[') { $depth++ }
        if ($Text[$index] -eq ']') {
            $depth--
            if ($depth -eq 0) {
                $closeBracket = $index
                break
            }
        }
    }
    if ($closeBracket -lt 0 -or
        $Text.IndexOf('[', $closeBracket + 1) -ge 0) {
        return $null
    }
    $memoryText = $Text.Substring(
        $openBracket + 1,
        $closeBracket - $openBracket - 1).Trim()
    if ($memoryText -notmatch '(?i)^(?:0x)?[0-9a-f]+h?$') {
        return $null
    }
    $memoryMatches = @($ValueMatches | Where-Object {
        $_.Index -gt $openBracket -and
        $_.Index + $_.Length -le $closeBracket
    })
    if ($memoryMatches.Count -ne 1) {
        return $null
    }
    return $memoryMatches[0]
}

function Replace-RelocatedNumericOperand(
    [string]$Text,
    $Instruction,
    $AddressOperand,
    [string]$Replacement) {

    [byte[]]$dumpbinBytes = $Instruction._dumpbin_bytes
    $operandOffset = [int]$AddressOperand.instruction_offset
    $operandWidth = [int]$AddressOperand.width
    if ($operandWidth -ne 4 -or $operandOffset -lt 0 -or
        $operandOffset + $operandWidth -gt $dumpbinBytes.Length) {
        throw (("Instruction at function offset 0x{0:x} has an unsupported " +
            "or out-of-range {1} relocation span (instruction offset " +
            "0x{2:x}, width {3}, instruction size 0x{4:x}).") -f
            [int]$Instruction.offset, [string]$AddressOperand.kind,
            $operandOffset, $operandWidth, $dumpbinBytes.Length)
    }
    $expectedValue = [uint64](Read-U32 $dumpbinBytes $operandOffset)
    $numericMatches = [regex]::Matches($Text,
        '(?i)(?<![a-z0-9_])(?:(?:0x)?(?<digits>[0-9a-f]+)h?)(?![a-z0-9_])')
    $valueMatches = @()
    foreach ($numericMatch in $numericMatches) {
        [uint64]$magnitude = 0
        if (-not [uint64]::TryParse($numericMatch.Groups['digits'].Value,
            [System.Globalization.NumberStyles]::HexNumber,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [ref]$magnitude)) {
            continue
        }
        if ($magnitude -eq $expectedValue) {
            $valueMatches += $numericMatch
        }
    }
    $match = if ($valueMatches.Count -eq 1) {
        $valueMatches[0]
    } else {
        Get-ProvenRelocatedMemoryNumericMatch $Text $Instruction `
            $AddressOperand $valueMatches
    }
    if ($null -eq $match) {
        throw (("Instruction at function offset 0x{0:x} cannot uniquely " +
            "map {1} relocation at instruction byte 0x{2:x} to its " +
            "rendered numeric operand: expected value 0x{3:x}, found {4} " +
            "matching numeric operands in '{5}'.") -f
            [int]$Instruction.offset, [string]$AddressOperand.kind,
            $operandOffset, $expectedValue, $valueMatches.Count, $Text)
    }
    return $Text.Substring(0, $match.Index) + $Replacement +
        $Text.Substring($match.Index + $match.Length)
}

function Add-InstructionShape(
    [object[]]$Instructions,
    [object[]]$FunctionOperands,
    [uint64]$FunctionAddress) {

    $rejected = @()
    foreach ($instruction in $Instructions) {
        if ($instruction.raw_text -notmatch '^\s*(?<mnemonic>\S+)(?:\s+(?<operands>.*))?$') {
            continue
        }
        $mnemonic = $Matches["mnemonic"].ToLowerInvariant()
        $operandText = if ($Matches.ContainsKey("operands")) {
            $Matches["operands"].Trim().ToLowerInvariant()
        } else { "" }
        $addressOperands = @()
        $direct = Get-DirectControlOperand $instruction $FunctionAddress
        if ($null -ne $direct) {
            $addressOperands += [pscustomobject][ordered]@{
                function_offset = $instruction.offset + $direct.operand_offset
                instruction_offset = $direct.operand_offset
                width = $direct.width
                kind = $direct.kind
                normalization_class = $direct.normalization_class
                raw_bytes = Get-Hex (Copy-ByteRange $instruction._bytes `
                    $direct.operand_offset $direct.width)
                symbol = ""
                target = $direct.target
                target_scope = $direct.target_scope
                target_function_offset = $direct.target_function_offset
                relocation_kind = ""
            }
        }
        foreach ($operand in @($FunctionOperands | Where-Object {
            $_.function_offset -ge $instruction.offset -and
            $_.function_offset + $_.width -le $instruction.offset + $instruction.size
        })) {
            $operandOffset = [int]$operand.function_offset - $instruction.offset
            if ($operandOffset -le 0 -or $operandOffset + $operand.width -gt
                $instruction.size) {
                $rejected += [pscustomobject][ordered]@{
                    function_offset = [int]$operand.function_offset
                    width = [int]$operand.width
                    kind = [string]$operand.kind
                    reason = "span_overlaps_opcode_or_instruction_boundary"
                }
                continue
            }
            $overlap = @($addressOperands | Where-Object {
                $_.instruction_offset -lt $operandOffset + $operand.width -and
                $operandOffset -lt $_.instruction_offset + $_.width
            })
            if ($overlap.Count -gt 0) {
                # A COFF REL32 on a direct branch enriches the direct span with
                # the target symbol; it must not create a second wildcard.
                if ($operand.kind -eq "coff_rel32" -and $overlap.Count -eq 1 -and
                    $overlap[0].instruction_offset -eq $operandOffset -and
                    $overlap[0].width -eq $operand.width) {
                    $overlap[0].symbol = [string]$operand.symbol
                    $overlap[0].target_scope = "external_relocation"
                    $overlap[0].target_function_offset = $null
                    $overlap[0].relocation_kind = [string]$operand.kind
                } else {
                    $rejected += [pscustomobject][ordered]@{
                        function_offset = [int]$operand.function_offset
                        width = [int]$operand.width
                        kind = [string]$operand.kind
                        reason = "span_overlaps_another_address_operand"
                    }
                    foreach ($overlappingOperand in $overlap) {
                        $addressOperands = @($addressOperands | Where-Object {
                            -not [object]::ReferenceEquals($_, $overlappingOperand)
                        })
                    }
                }
                continue
            }
            $addressOperands += [pscustomobject][ordered]@{
                function_offset = [int]$operand.function_offset
                instruction_offset = $operandOffset
                width = [int]$operand.width
                kind = [string]$operand.kind
                normalization_class = [string]$operand.normalization_class
                raw_bytes = Get-Hex (Copy-ByteRange $instruction._bytes `
                    $operandOffset $operand.width)
                symbol = [string]$operand.symbol
                target = ""
                target_scope = "relocation"
                target_function_offset = $null
                relocation_kind = [string]$operand.kind
            }
        }
        $addressOperands = @($addressOperands | Sort-Object instruction_offset)

        $normalizedOperandText = $operandText
        if ($null -ne $direct) {
            $normalizedDirect = @($addressOperands | Where-Object {
                $_.normalization_class -like 'control_flow_target_*'
            } | Select-Object -First 1)
            $targetToken = if ($normalizedDirect.Count -eq 1 -and
                $normalizedDirect[0].target_scope -eq "internal") {
                "<target:function+0x{0:x}>" -f `
                    [int]$normalizedDirect[0].target_function_offset
            } else {
                "<target:external>"
            }
            $normalizedOperandText = Replace-LastNumericOperand `
                $normalizedOperandText $targetToken
        }
        foreach ($addressOperand in @($addressOperands | Where-Object {
            $_.normalization_class -notlike 'control_flow_target_*'
        })) {
            $normalizedOperandText = Replace-RelocatedNumericOperand `
                $normalizedOperandText $instruction $addressOperand `
                ("<address:{0}>" -f $addressOperand.normalization_class)
        }
        $normalizedOperandText = ($normalizedOperandText -replace '\s+', ' ' -replace
            '\s*,\s*', ',').Trim()
        $operands = Split-Operands $normalizedOperandText
        $operandClasses = @($operands | ForEach-Object { Get-OperandClass $_ })

        $patternParts = @()
        $cursor = 0
        foreach ($addressOperand in $addressOperands) {
            while ($cursor -lt $addressOperand.instruction_offset) {
                $patternParts += $instruction._bytes[$cursor].ToString("x2")
                $cursor++
            }
            $patternParts += ("<{0}:{1}>" -f
                $addressOperand.normalization_class, $addressOperand.width)
            $cursor += $addressOperand.width
        }
        while ($cursor -lt $instruction.size) {
            $patternParts += $instruction._bytes[$cursor].ToString("x2")
            $cursor++
        }

        $instruction.mnemonic = $mnemonic
        $instruction.operands = $operands
        $instruction.operand_classes = $operandClasses
        $instruction.normalized_text = if ([string]::IsNullOrWhiteSpace(
            $normalizedOperandText)) { $mnemonic } else {
            $mnemonic + " " + $normalizedOperandText
        }
        $instruction.normalized_bytes_pattern = $patternParts -join " "
        $instruction.address_operands = $addressOperands
        $instruction.shape_key = ($instruction.normalized_bytes_pattern + "|" +
            $instruction.normalized_text + "|" + ($operandClasses -join ","))
    }
    return $rejected
}

function Add-BasicBlockMetadata([object[]]$Instructions) {
    if ($Instructions.Count -eq 0) { return }
    $boundaries = @{}
    $boundaries[[int]$Instructions[0].offset] = $true
    foreach ($instruction in $Instructions) {
        foreach ($operand in @($instruction.address_operands | Where-Object {
            $_.target_scope -eq "internal" -and
            $null -ne $_.target_function_offset
        })) {
            $boundaries[[int]$operand.target_function_offset] = $true
        }
        if ($instruction.mnemonic -match '^(?:j|loop|ret|iret)') {
            $boundaries[$instruction.offset + $instruction.size] = $true
        }
    }
    $block = -1
    $blockStart = -1
    foreach ($instruction in $Instructions) {
        if ($boundaries.ContainsKey([int]$instruction.offset)) {
            $block++
            $blockStart = [int]$instruction.offset
        }
        $instruction.block_index = $block
        $instruction.block_start_offset = $blockStart
    }
}

function Get-PairedAddressSpans($OriginalInstruction, $CandidateInstruction) {
    $pairs = @()
    foreach ($originalOperand in $OriginalInstruction.address_operands) {
        $originalMatches = @($OriginalInstruction.address_operands | Where-Object {
            $_.function_offset -eq $originalOperand.function_offset -and
            $_.instruction_offset -eq $originalOperand.instruction_offset -and
            $_.width -eq $originalOperand.width -and
            $_.normalization_class -ceq $originalOperand.normalization_class
        })
        if ($originalMatches.Count -ne 1) { continue }
        $candidateMatches = @($CandidateInstruction.address_operands | Where-Object {
            $_.function_offset -eq $originalOperand.function_offset -and
            $_.instruction_offset -eq $originalOperand.instruction_offset -and
            $_.width -eq $originalOperand.width -and
            $_.normalization_class -ceq $originalOperand.normalization_class
        })
        if ($candidateMatches.Count -eq 1) {
            $candidateOperand = $candidateMatches[0]
            if ($originalOperand.normalization_class -like 'control_flow_target_*') {
                # Only complete, parseable rel32 control operands are address-only
                # candidates. Short branches and unknown targets stay structural.
                if ([int]$originalOperand.width -ne 4 -or
                    [int]$candidateOperand.width -ne 4 -or
                    $originalOperand.target_scope -eq "unknown" -or
                    $candidateOperand.target_scope -eq "unknown") {
                    continue
                }
                if ($originalOperand.target_scope -eq "internal" -and
                    $candidateOperand.target_scope -eq "internal" -and
                    [int]$originalOperand.target_function_offset -ne
                        [int]$candidateOperand.target_function_offset) {
                    continue
                }
            }
            $pairs += [pscustomobject][ordered]@{
                function_offset = [int]$originalOperand.function_offset
                instruction_offset = [int]$originalOperand.instruction_offset
                width = [int]$originalOperand.width
                normalization_class = [string]$originalOperand.normalization_class
                original_kind = [string]$originalOperand.kind
                candidate_kind = [string]$candidateOperand.kind
                original_symbol = [string]$originalOperand.symbol
                candidate_symbol = [string]$candidateOperand.symbol
                original_target = [string]$originalOperand.target
                candidate_target = [string]$candidateOperand.target
                original_target_scope = [string]$originalOperand.target_scope
                candidate_target_scope = [string]$candidateOperand.target_scope
            }
        }
    }
    return $pairs
}

function Test-DifferencesCoveredByPairs(
    [byte[]]$OriginalBytes,
    [byte[]]$CandidateBytes,
    [object[]]$Pairs) {

    if ($OriginalBytes.Length -ne $CandidateBytes.Length) { return $false }
    $sawDifference = $false
    for ($index = 0; $index -lt $OriginalBytes.Length; $index++) {
        if ($OriginalBytes[$index] -eq $CandidateBytes[$index]) { continue }
        $sawDifference = $true
        $covered = @($Pairs | Where-Object {
            $index -ge $_.instruction_offset -and
            $index -lt $_.instruction_offset + $_.width
        }).Count -gt 0
        if (-not $covered) { return $false }
    }
    return $sawDifference
}

function New-AlignmentRecord($OriginalInstruction, $CandidateInstruction) {
    if ($null -eq $OriginalInstruction) {
        return [pscustomobject][ordered]@{
            original_ordinal = $null
            candidate_ordinal = [int]$CandidateInstruction.ordinal
            original_offset = $null
            candidate_offset = [int]$CandidateInstruction.offset
            original_size = $null
            candidate_size = [int]$CandidateInstruction.size
            offset_drift = $null
            original_block_index = $null
            candidate_block_index = [int]$CandidateInstruction.block_index
            block_start_drift = $null
            category = "candidate_only"
            paired_same_offset_operands = @()
        }
    }
    if ($null -eq $CandidateInstruction) {
        return [pscustomobject][ordered]@{
            original_ordinal = [int]$OriginalInstruction.ordinal
            candidate_ordinal = $null
            original_offset = [int]$OriginalInstruction.offset
            candidate_offset = $null
            original_size = [int]$OriginalInstruction.size
            candidate_size = $null
            offset_drift = $null
            original_block_index = [int]$OriginalInstruction.block_index
            candidate_block_index = $null
            block_start_drift = $null
            category = "original_only"
            paired_same_offset_operands = @()
        }
    }

    $pairs = @(Get-PairedAddressSpans $OriginalInstruction $CandidateInstruction)
    $offsetDrift = [int]$CandidateInstruction.offset - [int]$OriginalInstruction.offset
    $blockDrift = [int]$CandidateInstruction.block_start_offset -
        [int]$OriginalInstruction.block_start_offset
    $category = ""
    if ($offsetDrift -eq 0 -and
        $OriginalInstruction.raw_bytes -ceq $CandidateInstruction.raw_bytes) {
        $category = "exact"
    } elseif ($offsetDrift -eq 0 -and
        $OriginalInstruction.normalized_text -ceq $CandidateInstruction.normalized_text -and
        $OriginalInstruction.operand_classes.Count -eq
            $CandidateInstruction.operand_classes.Count -and
        (Test-DifferencesCoveredByPairs $OriginalInstruction._bytes `
            $CandidateInstruction._bytes $pairs)) {
        $category = "paired_address_only"
    } elseif ($OriginalInstruction.shape_key -ceq $CandidateInstruction.shape_key) {
        $category = "alignment_drift"
    } elseif ($OriginalInstruction.mnemonic -cne $CandidateInstruction.mnemonic) {
        $category = "mnemonic_difference"
    } elseif (($OriginalInstruction.operand_classes -join ',') -cne
        ($CandidateInstruction.operand_classes -join ',')) {
        $category = "operand_shape_difference"
    } else {
        $category = "encoding_or_operand_difference"
    }
    return [pscustomobject][ordered]@{
        original_ordinal = [int]$OriginalInstruction.ordinal
        candidate_ordinal = [int]$CandidateInstruction.ordinal
        original_offset = [int]$OriginalInstruction.offset
        candidate_offset = [int]$CandidateInstruction.offset
        original_size = [int]$OriginalInstruction.size
        candidate_size = [int]$CandidateInstruction.size
        offset_drift = $offsetDrift
        original_block_index = [int]$OriginalInstruction.block_index
        candidate_block_index = [int]$CandidateInstruction.block_index
        block_start_drift = $blockDrift
        category = $category
        paired_same_offset_operands = $pairs
    }
}

function Align-Instructions(
    [object[]]$OriginalInstructions,
    [object[]]$CandidateInstructions,
    [int]$Lookahead) {

    $result = @()
    $originalIndex = 0
    $candidateIndex = 0
    while ($originalIndex -lt $OriginalInstructions.Count -or
        $candidateIndex -lt $CandidateInstructions.Count) {
        if ($originalIndex -ge $OriginalInstructions.Count) {
            $result += New-AlignmentRecord $null $CandidateInstructions[$candidateIndex]
            $candidateIndex++
            continue
        }
        if ($candidateIndex -ge $CandidateInstructions.Count) {
            $result += New-AlignmentRecord $OriginalInstructions[$originalIndex] $null
            $originalIndex++
            continue
        }
        $original = $OriginalInstructions[$originalIndex]
        $candidate = $CandidateInstructions[$candidateIndex]
        if ($original.shape_key -ceq $candidate.shape_key) {
            $result += New-AlignmentRecord $original $candidate
            $originalIndex++
            $candidateIndex++
            continue
        }

        $bestOriginalSkip = -1
        $bestCandidateSkip = -1
        $bestCost = [int]::MaxValue
        for ($originalSkip = 0; $originalSkip -le $Lookahead -and
            $originalIndex + $originalSkip -lt $OriginalInstructions.Count;
            $originalSkip++) {
            for ($candidateSkip = 0; $candidateSkip -le $Lookahead -and
                $candidateIndex + $candidateSkip -lt $CandidateInstructions.Count;
                $candidateSkip++) {
                if ($originalSkip -eq 0 -and $candidateSkip -eq 0) { continue }
                if ($OriginalInstructions[$originalIndex + $originalSkip].shape_key -ceq
                    $CandidateInstructions[$candidateIndex + $candidateSkip].shape_key) {
                    $cost = $originalSkip + $candidateSkip
                    if ($cost -lt $bestCost) {
                        $bestCost = $cost
                        $bestOriginalSkip = $originalSkip
                        $bestCandidateSkip = $candidateSkip
                    }
                }
            }
        }
        if ($bestOriginalSkip -ge 0 -and $bestCost -le $Lookahead) {
            $paired = [System.Math]::Min($bestOriginalSkip, $bestCandidateSkip)
            for ($index = 0; $index -lt $paired; $index++) {
                $result += New-AlignmentRecord `
                    $OriginalInstructions[$originalIndex++] `
                    $CandidateInstructions[$candidateIndex++]
            }
            while ($bestOriginalSkip -gt $paired) {
                $result += New-AlignmentRecord $OriginalInstructions[$originalIndex++] $null
                $bestOriginalSkip--
            }
            while ($bestCandidateSkip -gt $paired) {
                $result += New-AlignmentRecord $null $CandidateInstructions[$candidateIndex++]
                $bestCandidateSkip--
            }
        } else {
            $result += New-AlignmentRecord $original $candidate
            $originalIndex++
            $candidateIndex++
        }
    }
    return $result
}

function Get-MismatchIslands([object[]]$Alignment) {
    $islands = @()
    $current = @()
    foreach ($record in $Alignment) {
        $structural = $record.category -notin @("exact", "paired_address_only")
        if ($structural) {
            $current += $record
        } elseif ($current.Count -gt 0) {
            $islands += ,@($current)
            $current = @()
        }
    }
    if ($current.Count -gt 0) { $islands += ,@($current) }
    $result = @()
    for ($index = 0; $index -lt $islands.Count; $index++) {
        $rows = @($islands[$index])
        $originalOffsets = @($rows | Where-Object { $null -ne $_.original_offset } |
            ForEach-Object { [int]$_.original_offset })
        $candidateOffsets = @($rows | Where-Object { $null -ne $_.candidate_offset } |
            ForEach-Object { [int]$_.candidate_offset })
        $originalEnds = @($rows | Where-Object { $null -ne $_.original_offset } |
            ForEach-Object { [int]$_.original_offset + [int]$_.original_size })
        $candidateEnds = @($rows | Where-Object { $null -ne $_.candidate_offset } |
            ForEach-Object { [int]$_.candidate_offset + [int]$_.candidate_size })
        $result += [pscustomobject][ordered]@{
            island_index = $index
            alignment_record_count = $rows.Count
            original_start_offset = if ($originalOffsets.Count -eq 0) { $null } else {
                ($originalOffsets | Measure-Object -Minimum).Minimum
            }
            original_end_offset = if ($originalOffsets.Count -eq 0) { $null } else {
                ($originalOffsets | Measure-Object -Maximum).Maximum
            }
            original_end_offset_exclusive = if ($originalEnds.Count -eq 0) { $null } else {
                ($originalEnds | Measure-Object -Maximum).Maximum
            }
            candidate_start_offset = if ($candidateOffsets.Count -eq 0) { $null } else {
                ($candidateOffsets | Measure-Object -Minimum).Minimum
            }
            candidate_end_offset = if ($candidateOffsets.Count -eq 0) { $null } else {
                ($candidateOffsets | Measure-Object -Maximum).Maximum
            }
            candidate_end_offset_exclusive = if ($candidateEnds.Count -eq 0) { $null } else {
                ($candidateEnds | Measure-Object -Maximum).Maximum
            }
            categories = @($rows.category | Sort-Object -Unique)
            max_absolute_offset_drift = [int](@($rows | Where-Object {
                $null -ne $_.offset_drift
            } | ForEach-Object { [System.Math]::Abs([int]$_.offset_drift) } |
                Measure-Object -Maximum).Maximum)
        }
    }
    return $result
}

function Get-PublicInstructions([object[]]$Instructions) {
    return @($Instructions | ForEach-Object {
        [pscustomobject][ordered]@{
            ordinal = [int]$_.ordinal
            offset = [int]$_.offset
            size = [int]$_.size
            address = [string]$_.address
            raw_bytes = [string]$_.raw_bytes
            dumpbin_bytes = [string]$_.dumpbin_bytes
            raw_text = [string]$_.raw_text
            mnemonic = [string]$_.mnemonic
            operands = @($_.operands)
            operand_classes = @($_.operand_classes)
            normalized_text = [string]$_.normalized_text
            normalized_bytes_pattern = [string]$_.normalized_bytes_pattern
            address_operands = @($_.address_operands)
            block_index = [int]$_.block_index
            block_start_offset = [int]$_.block_start_offset
        }
    })
}

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $scriptRoot "..\.."))
$byteDiffScriptPath = (Resolve-Path -LiteralPath (
    Join-Path $scriptRoot "diff-symbol-bytes.ps1")).Path
$resolvedResultsPath = Resolve-SafeResultsJsonPath $ResultsJsonPath $repoRoot
$earlyProtectedPaths = @(
    $PSCommandPath,
    $byteDiffScriptPath,
    $OriginalPath,
    $CandidatePath,
    $CandidateMapPath,
    $DumpbinPath)
if (-not [string]::IsNullOrWhiteSpace($CandidateObjectPath)) {
    $earlyProtectedPaths += $CandidateObjectPath
}
Assert-ResultsPathDoesNotOverwrite $resolvedResultsPath $earlyProtectedPaths

$diffArguments = @(
    "-NoProfile", "-ExecutionPolicy", "Bypass",
    "-File", $byteDiffScriptPath,
    "-OriginalPath", $OriginalPath,
    "-OriginalRva", ("0x{0:x}" -f $OriginalRva),
    "-Size", $Size,
    "-CandidatePath", $CandidatePath,
    "-CandidateMapPath", $CandidateMapPath,
    "-CandidateSymbol", $CandidateSymbol
)
if ($DumpHex.IsPresent) { $diffArguments += "-DumpHex" }

Write-Host "== Byte diff (authoritative raw focused evidence) =="
$byteDiffOutput = @(& powershell @diffArguments 2>&1)
$byteDiffExitCode = $LASTEXITCODE
foreach ($line in $byteDiffOutput) {
    $text = [string]$line
    if ($SummaryOnly.IsPresent -and
        $text -match '^All (?:hard )?diff offsets:') {
        continue
    }
    Write-Host $text
}
if ($byteDiffExitCode -ne 0) {
    throw "diff-symbol-bytes.ps1 failed."
}

$originalImage = Get-PeImageInfo $OriginalPath
$candidateImage = Get-PeImageInfo $CandidatePath
$mapInfo = Resolve-MapSymbol $CandidateMapPath $CandidateSymbol
$candidateRva = [uint64]$mapInfo.va - [uint64]$candidateImage.image_base
$originalFunctionBytes = Read-RvaBytes $originalImage $OriginalRva $Size
$candidateFunctionBytes = Read-RvaBytes $candidateImage $candidateRva $Size
$rawDifferenceOffsets = @()
for ($index = 0; $index -lt $Size; $index++) {
    if ($originalFunctionBytes[$index] -ne $candidateFunctionBytes[$index]) {
        $rawDifferenceOffsets += $index
    }
}

$candidateObject = Resolve-CandidateObjectPath $mapInfo $CandidateMapPath `
    $CandidateObjectPath $CandidateObjectDirectory
if ($null -ne $candidateObject) {
    Assert-ResultsPathDoesNotOverwrite $resolvedResultsPath @($candidateObject)
}
$coffInfo = $null
if ($null -ne $candidateObject) {
    $coffInfo = Get-CoffFunctionInfo $candidateObject $mapInfo.symbol `
        $mapInfo.symbol_offset $Size
}

$originalLines = Invoke-DumpbinDisasm $OriginalPath $DumpbinPath
$originalAll = @(Get-AllDisassemblyInstructions $originalLines)
$originalFunctionAddress = [uint64]$originalImage.image_base + $OriginalRva
$originalInstructions = @(Select-FunctionInstructions $originalAll `
    $originalFunctionAddress $Size $originalFunctionBytes)
Assert-InstructionCoverage $originalInstructions $Size "Original PE"

$candidateSource = "candidate_pe"
if ($null -ne $candidateObject) {
    $candidateLines = Invoke-DumpbinDisasm $candidateObject $DumpbinPath
    $verifiedCandidateLabels = @([string]$mapInfo.symbol) +
        @($coffInfo.internal_labels | ForEach-Object { [string]$_.name })
    $candidateAll = @(Get-AllDisassemblyInstructions $candidateLines `
        $verifiedCandidateLabels)
    $candidateFunctionAddress = [uint64]$coffInfo.function_section_offset
    $candidateInstructions = @(Select-FunctionInstructions $candidateAll `
        $candidateFunctionAddress $Size $candidateFunctionBytes $mapInfo.symbol `
        $coffInfo.internal_labels)
    $candidateFunctionOperands = @($coffInfo.address_operands)
    $candidateSource = "candidate_coff_object"
} else {
    $candidateLines = Invoke-DumpbinDisasm $CandidatePath $DumpbinPath
    $candidateAll = @(Get-AllDisassemblyInstructions $candidateLines `
        @([string]$mapInfo.symbol))
    $candidateFunctionAddress = [uint64]$mapInfo.va
    $candidateInstructions = @(Select-FunctionInstructions $candidateAll `
        $candidateFunctionAddress $Size $candidateFunctionBytes)
    $candidateFunctionOperands = @(Get-PeHighlowOperands $candidateImage `
        $candidateRva $Size)
}
Assert-InstructionCoverage $candidateInstructions $Size "Candidate"
$originalFunctionOperands = @(Get-PeHighlowOperands $originalImage $OriginalRva $Size)
$originalRejected = @(Add-InstructionShape $originalInstructions `
    $originalFunctionOperands $originalFunctionAddress)
$candidateRejected = @(Add-InstructionShape $candidateInstructions `
    $candidateFunctionOperands $candidateFunctionAddress)
Assert-DisassemblyByteConsistency $originalInstructions $false "Original PE"
Assert-DisassemblyByteConsistency $candidateInstructions ($null -ne $candidateObject) `
    $(if ($null -ne $candidateObject) { "Candidate COFF object" } else {
        "Candidate PE"
    })
Add-BasicBlockMetadata $originalInstructions
Add-BasicBlockMetadata $candidateInstructions

$alignment = @(Align-Instructions $originalInstructions $candidateInstructions `
    $AlignmentLookahead)
$mismatchIslands = @(Get-MismatchIslands $alignment)
$categoryCounts = [ordered]@{}
foreach ($category in @("exact", "paired_address_only", "alignment_drift",
    "mnemonic_difference", "operand_shape_difference",
    "encoding_or_operand_difference", "original_only", "candidate_only")) {
    $categoryCounts[$category] = @($alignment | Where-Object {
        $_.category -ceq $category
    }).Count
}
$pairedOperandCount = @($alignment | ForEach-Object {
    @($_.paired_same_offset_operands)
}).Count
$driftValues = @($alignment | Where-Object { $null -ne $_.offset_drift } |
    ForEach-Object { [System.Math]::Abs([int]$_.offset_drift) })
$maxDrift = if ($driftValues.Count -eq 0) { 0 } else {
    [int]($driftValues | Measure-Object -Maximum).Maximum
}

$summary = [pscustomobject][ordered]@{
    raw_difference_count = $rawDifferenceOffsets.Count
    compared_bytes = $Size
    original_instruction_count = $originalInstructions.Count
    candidate_instruction_count = $candidateInstructions.Count
    aligned_record_count = $alignment.Count
    exact_instruction_count = [int]$categoryCounts.exact
    paired_address_only_instruction_count = [int]$categoryCounts.paired_address_only
    structural_instruction_count = [int](
        $alignment.Count - $categoryCounts.exact - $categoryCounts.paired_address_only)
    paired_same_offset_address_operand_count = $pairedOperandCount
    drifted_alignment_count = @($alignment | Where-Object {
        $null -ne $_.offset_drift -and $_.offset_drift -ne 0
    }).Count
    max_absolute_offset_drift = $maxDrift
    mismatch_island_count = $mismatchIslands.Count
    category_counts = [pscustomobject]$categoryCounts
}

Write-Host ""
Write-Host "== Instruction-shape summary (diagnostic only; zero acceptance credit) =="
Write-Host ("Raw exact byte differences: {0} / {1}" -f
    $summary.raw_difference_count, $summary.compared_bytes)
Write-Host ("Parsed instructions: original={0}, candidate={1}, aligned={2}" -f
    $summary.original_instruction_count, $summary.candidate_instruction_count,
    $summary.aligned_record_count)
Write-Host ("Exact={0}; paired-address-only={1}; structural={2}" -f
    $summary.exact_instruction_count,
    $summary.paired_address_only_instruction_count,
    $summary.structural_instruction_count)
Write-Host ("Paired same-offset address operands={0}; drifted alignments={1}; max drift={2}" -f
    $summary.paired_same_offset_address_operand_count,
    $summary.drifted_alignment_count, $summary.max_absolute_offset_drift)
Write-Host ("Structural mismatch islands: {0}" -f $summary.mismatch_island_count)
foreach ($island in @($mismatchIslands | Select-Object -First $MaxMismatchIslands)) {
    Write-Host ("  [{0}] original=[{1},{2}) candidate=[{3},{4}) records={5} categories={6}" -f
        $island.island_index, $island.original_start_offset,
        $island.original_end_offset_exclusive, $island.candidate_start_offset,
        $island.candidate_end_offset_exclusive, $island.alignment_record_count,
        ($island.categories -join ','))
}
if ($mismatchIslands.Count -gt $MaxMismatchIslands) {
    Write-Host ("  ... {0} additional island(s) omitted from the console summary." -f
        ($mismatchIslands.Count - $MaxMismatchIslands))
}

if (-not $SummaryOnly.IsPresent) {
    Write-Host ""
    Write-Host "== Original PE disassembly =="
    Write-ParsedDisassemblyRange $originalAll $originalFunctionAddress $Size `
        $ContextBytes
    Write-Host ""
    Write-Host ("== Candidate disassembly ({0}) ==" -f $candidateSource)
    Write-ParsedDisassemblyRange $candidateAll $candidateFunctionAddress $Size `
        $ContextBytes
}

if (-not [string]::IsNullOrWhiteSpace($ResultsJsonPath)) {
    $revalidatedResultsPath = Resolve-SafeResultsJsonPath $ResultsJsonPath $repoRoot
    if (-not $resolvedResultsPath.Equals($revalidatedResultsPath,
        [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "ResultsJsonPath changed during execution."
    }
    Assert-ResultsPathDoesNotOverwrite $resolvedResultsPath @(
        $PSCommandPath,
        $byteDiffScriptPath,
        $originalImage.path,
        $candidateImage.path,
        (Resolve-Path -LiteralPath $CandidateMapPath).Path,
        $candidateObject,
        (Resolve-Path -LiteralPath $DumpbinPath).Path)
    $resultsDirectory = Split-Path -Parent $resolvedResultsPath
    if (-not (Test-Path -LiteralPath $resultsDirectory -PathType Container)) {
        [void][System.IO.Directory]::CreateDirectory($resultsDirectory)
    }
    Assert-NoReparseTraversal $repoRoot $resolvedResultsPath
    $evidence = [pscustomobject][ordered]@{
        schema_version = 1
        artifact_type = "otmatch-focused-instruction-shape-evidence"
        created_utc = [datetime]::UtcNow.ToString("o")
        authority = [pscustomobject][ordered]@{
            diagnostic_only = $true
            grants_acceptance_credit = $false
            normalized_match_is_exact_match = $false
            raw_focused_diff_authority = "tools/otmatch/diff-symbol-bytes.ps1"
            full_acceptance_authority = "tools/otmatch/match-functions.ps1 schema-4"
            note = ("Normalization classifies address-shaped operands only; " +
                "it never changes raw difference counts or verifier status.")
        }
        identity = [pscustomobject][ordered]@{
            original_rva = "0x{0:x}" -f $OriginalRva
            size = $Size
            candidate_symbol_expression = $CandidateSymbol
            candidate_symbol = [string]$mapInfo.symbol
            candidate_symbol_offset = [uint64]$mapInfo.symbol_offset
            candidate_rva = "0x{0:x}" -f $candidateRva
        }
        inputs = [pscustomobject][ordered]@{
            script_path = (Resolve-Path -LiteralPath $PSCommandPath).Path
            script_sha256 = Get-Sha256 $PSCommandPath
            original_path = $originalImage.path
            original_sha256 = Get-Sha256 $originalImage.path
            candidate_path = $candidateImage.path
            candidate_sha256 = Get-Sha256 $candidateImage.path
            candidate_map_path = (Resolve-Path -LiteralPath $CandidateMapPath).Path
            candidate_map_sha256 = Get-Sha256 $CandidateMapPath
            candidate_object_path = if ($null -eq $candidateObject) { "" } else {
                [string]$candidateObject
            }
            candidate_object_sha256 = if ($null -eq $candidateObject) { "" } else {
                Get-Sha256 $candidateObject
            }
            dumpbin_path = (Resolve-Path -LiteralPath $DumpbinPath).Path
            dumpbin_sha256 = Get-Sha256 $DumpbinPath
        }
        raw_exact = [pscustomobject][ordered]@{
            original_function_sha256 = Get-ByteArraySha256 $originalFunctionBytes
            candidate_function_sha256 = Get-ByteArraySha256 $candidateFunctionBytes
            compared_bytes = $Size
            difference_count = $rawDifferenceOffsets.Count
            difference_offsets = @($rawDifferenceOffsets)
            exact = ($rawDifferenceOffsets.Count -eq 0)
            child_diff_exit_code = $byteDiffExitCode
            child_diff_output = @($byteDiffOutput | ForEach-Object { [string]$_ })
        }
        normalization = [pscustomobject][ordered]@{
            diagnostic_only = $true
            paired_same_offset_required_for_address_only = $true
            alignment_lookahead = $AlignmentLookahead
            original_rejected_address_spans = $originalRejected
            candidate_rejected_address_spans = $candidateRejected
        }
        summary = $summary
        instructions = [pscustomobject][ordered]@{
            original = @(Get-PublicInstructions $originalInstructions)
            candidate = @(Get-PublicInstructions $candidateInstructions)
        }
        alignment = $alignment
        mismatch_islands = $mismatchIslands
    }
    $jsonText = ($evidence | ConvertTo-Json -Depth 30) + "`n"
    Write-Utf8TextAtomic $resolvedResultsPath $jsonText
    Write-Host ("Instruction-shape JSON: {0}" -f $resolvedResultsPath)
}
