param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,

    [Parameter(Mandatory = $true)]
    [string]$OriginalPath,

    [string]$OriginalDllPath,

    [Parameter(Mandatory = $true)]
    [string]$CandidatePath,

    [string]$CandidateMapPath,

    [string]$CandidateLcmtPath,

    [string]$CandidateLcmtMapPath,

    [string]$CandidateDllcrtPath,

    [string]$CandidateDllcrtMapPath,

    [string]$DefaultProgram = "Oregon32.exe",

    [string]$ResultsCsvPath,

    [switch]$SummaryOnly,

    [switch]$AllowMismatches
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Get-CsvField($Row, [string]$Name) {
    $property = $Row.PSObject.Properties[$Name]
    if ($null -eq $property -or $null -eq $property.Value) {
        return ""
    }

    return [string]$property.Value
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

function Format-OtHex([uint64]$Value) {
    return ("0x{0:x8}" -f $Value)
}

function Resolve-OptionalPath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ""
    }

    return (Resolve-Path $Path).Path
}

function Read-U16([byte[]]$Bytes, [int]$Offset) {
    return [uint16](
        ([uint64]$Bytes[$Offset]) -bor
        (([uint64]$Bytes[($Offset + 1)]) -shl 8))
}

function Read-U32([byte[]]$Bytes, [int]$Offset) {
    return [uint32](
        ([uint64]$Bytes[$Offset]) -bor
        (([uint64]$Bytes[($Offset + 1)]) -shl 8) -bor
        (([uint64]$Bytes[($Offset + 2)]) -shl 16) -bor
        (([uint64]$Bytes[($Offset + 3)]) -shl 24))
}

function Read-I32([byte[]]$Bytes, [int]$Offset) {
    $value = [uint64](Read-U32 $Bytes $Offset)
    if ($value -ge [uint64]2147483648) {
        return [int64]($value - [uint64]4294967296)
    }

    return [int64]$value
}

function Read-U64([byte[]]$Bytes, [int]$Offset) {
    $low = [uint64](Read-U32 $Bytes $Offset)
    $high = [uint64](Read-U32 $Bytes ($Offset + 4))
    return $low -bor ($high -shl 32)
}

function Read-CString([byte[]]$Bytes, [int]$Offset, [string]$Context) {
    if ($Offset -lt 0 -or $Offset -ge $Bytes.Length) {
        throw "$Context starts outside the file."
    }

    $end = $Offset
    while ($end -lt $Bytes.Length -and $Bytes[$end] -ne 0) {
        $end++
    }
    if ($end -ge $Bytes.Length) {
        throw "$Context is not null-terminated."
    }

    return [System.Text.Encoding]::ASCII.GetString($Bytes, $Offset, ($end - $Offset))
}

function Get-PeImage([string]$Path) {
    $resolvedPath = (Resolve-Path $Path).Path
    $bytes = [System.IO.File]::ReadAllBytes($resolvedPath)
    if ($bytes.Length -lt 0x40) {
        throw "PE file is too small: $resolvedPath"
    }

    if ($bytes[0] -ne 0x4d -or $bytes[1] -ne 0x5a) {
        throw "Missing MZ header: $resolvedPath"
    }

    $peOffset = [int](Read-U32 $bytes 0x3c)
    if ($peOffset + 0x18 -gt $bytes.Length) {
        throw "Invalid PE header offset in $resolvedPath."
    }

    if ($bytes[$peOffset] -ne 0x50 -or $bytes[($peOffset + 1)] -ne 0x45 -or
        $bytes[($peOffset + 2)] -ne 0x00 -or $bytes[($peOffset + 3)] -ne 0x00) {
        throw "Missing PE signature: $resolvedPath"
    }

    $coffOffset = $peOffset + 4
    $sectionCount = [int](Read-U16 $bytes ($coffOffset + 2))
    $optionalHeaderSize = [int](Read-U16 $bytes ($coffOffset + 16))
    $optionalHeaderOffset = $coffOffset + 20
    $optionalMagic = Read-U16 $bytes $optionalHeaderOffset

    if ($optionalMagic -eq 0x10b) {
        $peFormat = "PE32"
        $imageBase = [uint64](Read-U32 $bytes ($optionalHeaderOffset + 28))
        $numberOfDirectoriesOffset = $optionalHeaderOffset + 92
        $dataDirectoryOffset = $optionalHeaderOffset + 96
        $thunkSize = 4
    }
    elseif ($optionalMagic -eq 0x20b) {
        $peFormat = "PE32+"
        $imageBase = Read-U64 $bytes ($optionalHeaderOffset + 24)
        $numberOfDirectoriesOffset = $optionalHeaderOffset + 108
        $dataDirectoryOffset = $optionalHeaderOffset + 112
        $thunkSize = 8
    }
    else {
        throw ("Unsupported PE optional header magic 0x{0:x} in {1}." -f $optionalMagic, $resolvedPath)
    }

    $sizeOfHeaders = [uint64](Read-U32 $bytes ($optionalHeaderOffset + 60))
    if (($numberOfDirectoriesOffset + 4) -gt ($optionalHeaderOffset + $optionalHeaderSize)) {
        throw "Optional header is too small for its data-directory count in $resolvedPath."
    }
    $numberOfDirectories = [uint64](Read-U32 $bytes $numberOfDirectoriesOffset)
    $importDirectoryRva = [uint64]0
    $importDirectorySize = [uint64]0
    if ($numberOfDirectories -gt 1 -and
        ($dataDirectoryOffset + 16) -le ($optionalHeaderOffset + $optionalHeaderSize)) {
        $importDirectoryRva = [uint64](Read-U32 $bytes ($dataDirectoryOffset + 8))
        $importDirectorySize = [uint64](Read-U32 $bytes ($dataDirectoryOffset + 12))
    }
    $relocationDirectoryRva = [uint64]0
    $relocationDirectorySize = [uint64]0
    if ($numberOfDirectories -gt 5 -and
        ($dataDirectoryOffset + 48) -le ($optionalHeaderOffset + $optionalHeaderSize)) {
        $relocationDirectoryRva = [uint64](Read-U32 $bytes ($dataDirectoryOffset + 40))
        $relocationDirectorySize = [uint64](Read-U32 $bytes ($dataDirectoryOffset + 44))
    }
    $sectionTableOffset = $optionalHeaderOffset + $optionalHeaderSize
    $sections = @()

    for ($index = 0; $index -lt $sectionCount; $index++) {
        $sectionOffset = $sectionTableOffset + ($index * 40)
        if ($sectionOffset + 40 -gt $bytes.Length) {
            throw "Section table is truncated in $resolvedPath."
        }

        $nameBytes = New-Object byte[] 8
        [System.Array]::Copy($bytes, $sectionOffset, $nameBytes, 0, 8)
        $name = [System.Text.Encoding]::ASCII.GetString($nameBytes).Trim([char]0)

        $sections += [pscustomobject]@{
            Name = $name
            VirtualSize = [uint64](Read-U32 $bytes ($sectionOffset + 8))
            VirtualAddress = [uint64](Read-U32 $bytes ($sectionOffset + 12))
            RawSize = [uint64](Read-U32 $bytes ($sectionOffset + 16))
            RawPointer = [uint64](Read-U32 $bytes ($sectionOffset + 20))
            Characteristics = [uint32](Read-U32 $bytes ($sectionOffset + 36))
        }
    }

    $image = [pscustomobject]@{
        Path = $resolvedPath
        Bytes = $bytes
        PeFormat = $peFormat
        ImageBase = $imageBase
        SizeOfHeaders = $sizeOfHeaders
        Sections = $sections
        ThunkSize = $thunkSize
        ImportDirectoryRva = $importDirectoryRva
        ImportDirectorySize = $importDirectorySize
        RelocationDirectoryRva = $relocationDirectoryRva
        RelocationDirectorySize = $relocationDirectorySize
        HighLowRelocationIndex = @{}
        ImportIatIndex = @{}
    }

    $image.HighLowRelocationIndex = Get-HighLowRelocationIndex $image
    $image.ImportIatIndex = Get-ImportIatIndex $image
    return $image
}

function Convert-RvaToFileOffset($Image, [uint64]$Rva) {
    if ($Rva -lt $Image.SizeOfHeaders) {
        return [int]$Rva
    }

    foreach ($section in $Image.Sections) {
        $sectionStart = [uint64]$section.VirtualAddress
        $sectionSpan = [System.Math]::Max([uint64]$section.VirtualSize, [uint64]$section.RawSize)
        $sectionEnd = $sectionStart + $sectionSpan

        if ($Rva -ge $sectionStart -and $Rva -lt $sectionEnd) {
            $delta = $Rva - $sectionStart
            if ($delta -ge [uint64]$section.RawSize) {
                throw ("RVA {0} maps into virtual padding for section {1} in {2}." -f
                    (Format-OtHex $Rva), $section.Name, $Image.Path)
            }

            return [int]([uint64]$section.RawPointer + $delta)
        }
    }

    throw ("RVA {0} does not map to a file section in {1}." -f (Format-OtHex $Rva), $Image.Path)
}

function Read-PeRange($Image, [uint64]$Rva, [uint64]$Size) {
    if ($Size -gt [uint64][int]::MaxValue) {
        throw "Range is too large to compare in one pass: $Size bytes."
    }

    $offset = Convert-RvaToFileOffset $Image $Rva
    $sizeAsInt = [int]$Size
    if (($offset + $sizeAsInt) -gt $Image.Bytes.Length) {
        throw ("Range {0}+{1} extends past end of {2}." -f
            (Format-OtHex $Rva), $sizeAsInt, $Image.Path)
    }

    $range = New-Object byte[] $sizeAsInt
    [System.Array]::Copy($Image.Bytes, $offset, $range, 0, $sizeAsInt)
    return $range
}

function Get-HighLowRelocationIndex($Image) {
    $index = @{}
    $directoryRva = [uint64]$Image.RelocationDirectoryRva
    $directorySize = [uint64]$Image.RelocationDirectorySize
    if ($directoryRva -eq 0 -or $directorySize -eq 0) {
        return $index
    }
    if ($directorySize -gt [uint64][int]::MaxValue) {
        throw "Base-relocation directory is too large in $($Image.Path)."
    }

    $directory = Read-PeRange $Image $directoryRva $directorySize
    $cursor = 0
    while ($cursor -lt $directory.Length) {
        if (($directory.Length - $cursor) -lt 8) {
            throw "Truncated base-relocation block header in $($Image.Path)."
        }

        $pageRva = [uint64](Read-U32 $directory $cursor)
        $blockSize = [uint64](Read-U32 $directory ($cursor + 4))
        if ($pageRva -eq 0 -and $blockSize -eq 0) {
            break
        }
        if ($blockSize -lt 8 -or (($blockSize - 8) % 2) -ne 0 -or
            $blockSize -gt [uint64]($directory.Length - $cursor)) {
            throw "Invalid base-relocation block in $($Image.Path)."
        }

        $entryCount = [int](($blockSize - 8) / 2)
        for ($entryIndex = 0; $entryIndex -lt $entryCount; $entryIndex++) {
            $entry = [uint16](Read-U16 $directory ($cursor + 8 + ($entryIndex * 2)))
            if (($entry -shr 12) -eq 3) {
                $rva = $pageRva + [uint64]($entry -band 0x0fff)
                $index[[string]$rva] = $true
            }
        }
        $cursor += [int]$blockSize
    }

    return $index
}

function Get-ImportIatIndex($Image) {
    $index = @{}
    $directoryRva = [uint64]$Image.ImportDirectoryRva
    if ($directoryRva -eq 0) {
        return $index
    }

    $maxDescriptors = 4096
    if ([uint64]$Image.ImportDirectorySize -gt 0) {
        $declaredDescriptors = [int][System.Math]::Ceiling(
            ([double][uint64]$Image.ImportDirectorySize) / 20.0)
        $maxDescriptors = [System.Math]::Min($maxDescriptors, ($declaredDescriptors + 1))
    }

    for ($descriptorIndex = 0; $descriptorIndex -lt $maxDescriptors; $descriptorIndex++) {
        $descriptorRva = $directoryRva + [uint64]($descriptorIndex * 20)
        $descriptorOffset = Convert-RvaToFileOffset $Image $descriptorRva
        if (($descriptorOffset + 20) -gt $Image.Bytes.Length) {
            throw "Import descriptor is truncated in $($Image.Path)."
        }

        $originalFirstThunk = [uint64](Read-U32 $Image.Bytes $descriptorOffset)
        $timeDateStamp = [uint64](Read-U32 $Image.Bytes ($descriptorOffset + 4))
        $forwarderChain = [uint64](Read-U32 $Image.Bytes ($descriptorOffset + 8))
        $nameRva = [uint64](Read-U32 $Image.Bytes ($descriptorOffset + 12))
        $firstThunk = [uint64](Read-U32 $Image.Bytes ($descriptorOffset + 16))
        if ($originalFirstThunk -eq 0 -and $timeDateStamp -eq 0 -and
            $forwarderChain -eq 0 -and $nameRva -eq 0 -and $firstThunk -eq 0) {
            return $index
        }

        $dllNameOffset = Convert-RvaToFileOffset $Image $nameRva
        $dllName = Read-CString $Image.Bytes $dllNameOffset "Import DLL name"
        $lookupThunkRva = $originalFirstThunk
        if ($lookupThunkRva -eq 0) {
            $lookupThunkRva = $firstThunk
        }

        for ($functionIndex = 0; $functionIndex -lt 65536; $functionIndex++) {
            $entryDelta = [uint64]($functionIndex * [int]$Image.ThunkSize)
            $lookupOffset = Convert-RvaToFileOffset $Image ($lookupThunkRva + $entryDelta)
            if ([int]$Image.ThunkSize -eq 4) {
                $lookupValue = [uint64](Read-U32 $Image.Bytes $lookupOffset)
                $ordinalMask = [uint64]2147483648
            }
            else {
                $lookupValue = Read-U64 $Image.Bytes $lookupOffset
                $ordinalMask = [uint64]::Parse(
                    "8000000000000000",
                    [System.Globalization.NumberStyles]::HexNumber,
                    [System.Globalization.CultureInfo]::InvariantCulture)
            }
            if ($lookupValue -eq 0) {
                break
            }

            $byOrdinal = (($lookupValue -band $ordinalMask) -ne 0)
            $symbol = ""
            $ordinal = $null
            if ($byOrdinal) {
                $ordinal = [int]($lookupValue -band 0xffff)
                $target = "#$ordinal"
            }
            else {
                $importNameOffset = Convert-RvaToFileOffset $Image $lookupValue
                $symbol = Read-CString $Image.Bytes ($importNameOffset + 2) "Import function name"
                $target = $symbol
            }

            $iatRva = $firstThunk + $entryDelta
            $key = [string]$iatRva
            if ($index.ContainsKey($key)) {
                throw ("Duplicate import-address-table RVA {0} in {1}." -f
                    (Format-OtHex $iatRva), $Image.Path)
            }
            $index[$key] = [pscustomobject]@{
                Dll = $dllName
                DllKey = $dllName.ToUpperInvariant()
                Symbol = $symbol
                Ordinal = $ordinal
                ByOrdinal = $byOrdinal
                Display = "$dllName!$target"
            }
        }
    }

    throw "Import descriptor table did not contain a terminator in $($Image.Path)."
}

function Resolve-RvaFromVa([uint64]$Va, [uint64]$ImageBase, [string]$FieldName) {
    if ($Va -lt $ImageBase) {
        throw ("{0} value {1} is below image base {2}." -f
            $FieldName, (Format-OtHex $Va), (Format-OtHex $ImageBase))
    }

    return $Va - $ImageBase
}

function Read-MsvcMapSymbols([string]$Path, [uint64]$CandidateImageBase) {
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return @{}
    }

    $resolvedPath = (Resolve-Path $Path).Path
    $symbols = @{}
    foreach ($line in Get-Content $resolvedPath) {
        if ($line -match '^\s*[0-9A-Fa-f]{4}:[0-9A-Fa-f]{8,16}\s+(\S+)\s+([0-9A-Fa-f]{8,16})(?:\s+(.*\S))?\s*$') {
            $symbolName = $Matches[1]
            $symbolVa = [uint64]::Parse(
                $Matches[2],
                [System.Globalization.NumberStyles]::HexNumber,
                [System.Globalization.CultureInfo]::InvariantCulture)

            if ($symbolVa -ge $CandidateImageBase) {
                $objectName = ""
                if ($Matches.Count -ge 4 -and -not [string]::IsNullOrWhiteSpace($Matches[3])) {
                    $remainder = $Matches[3].Trim()
                    $tokens = @($remainder -split '\s+')
                    if ($tokens.Count -ne 0 -and $tokens[($tokens.Count - 1)] -notmatch '^[fFiI]+$') {
                        $objectName = $tokens[($tokens.Count - 1)]
                    }
                }

                $occurrence = [pscustomobject]@{
                    Symbol = $symbolName
                    Rva = $symbolVa - $CandidateImageBase
                    Object = $objectName
                }
                if (-not $symbols.ContainsKey($symbolName)) {
                    $symbols[$symbolName] = @()
                }
                $symbols[$symbolName] = @($symbols[$symbolName]) + $occurrence
            }
        }
    }

    return $symbols
}

function Resolve-CandidateSymbol([string]$Expression, [string]$ObjectQualifier, $CandidateSymbols) {
    $text = $Expression.Trim()
    if ($text -notmatch '^(?<symbol>.+?)(?:\s*\+\s*(?<offset>0x[0-9A-Fa-f]+|[0-9]+))?$') {
        throw "Invalid candidate_symbol expression '$Expression'."
    }

    $baseSymbol = $Matches["symbol"].Trim()
    $offset = [uint64]0
    if ($Matches.ContainsKey("offset") -and -not [string]::IsNullOrWhiteSpace($Matches["offset"])) {
        $offset = Parse-Number $Matches["offset"] "candidate_symbol.offset"
    }

    if (-not $CandidateSymbols.ContainsKey($baseSymbol)) {
        throw "candidate_symbol '$baseSymbol' was not found in the candidate map."
    }

    $occurrences = @($CandidateSymbols[$baseSymbol])
    if (-not [string]::IsNullOrWhiteSpace($ObjectQualifier)) {
        $qualifiedOccurrences = @($occurrences | Where-Object {
            [string]::Equals(
                [string]$_.Object,
                $ObjectQualifier.Trim(),
                [System.StringComparison]::OrdinalIgnoreCase)
        })
        if ($qualifiedOccurrences.Count -eq 0) {
            $availableObjects = @($occurrences | ForEach-Object { [string]$_.Object } | Sort-Object -Unique)
            throw ("candidate_symbol '{0}' was not found in candidate_object '{1}'. Available objects: {2}." -f
                $baseSymbol, $ObjectQualifier.Trim(), ($availableObjects -join ", "))
        }
        $occurrences = $qualifiedOccurrences
    }

    if ($occurrences.Count -ne 1) {
        $locations = @($occurrences | ForEach-Object {
            "{0}@{1}" -f $_.Object, (Format-OtHex ([uint64]$_.Rva))
        })
        if ([string]::IsNullOrWhiteSpace($ObjectQualifier)) {
            throw ("candidate_symbol '{0}' is ambiguous ({1} occurrences: {2}); set candidate_object in the manifest." -f
                $baseSymbol, $occurrences.Count, ($locations -join ", "))
        }

        throw ("candidate_symbol '{0}' in candidate_object '{1}' is not unique ({2} occurrences: {3})." -f
            $baseSymbol, $ObjectQualifier.Trim(), $occurrences.Count, ($locations -join ", "))
    }

    $selected = $occurrences[0]
    return [pscustomobject]@{
        Rva = [uint64]$selected.Rva + $offset
        BaseSymbol = $baseSymbol
        Object = [string]$selected.Object
    }
}

function Resolve-CandidateLocator($Row, $OriginalRva, $CandidateImage, $CandidateSymbols) {
    $candidateRvaText = Get-CsvField $Row "candidate_rva"
    if (-not [string]::IsNullOrWhiteSpace($candidateRvaText)) {
        if (-not [string]::IsNullOrWhiteSpace((Get-CsvField $Row "candidate_object"))) {
            throw "candidate_object requires candidate_symbol; it cannot qualify candidate_rva."
        }
        return [pscustomobject]@{
            Rva = Parse-Number $candidateRvaText "candidate_rva"
            Kind = "candidate_rva"
            Locator = $candidateRvaText.Trim()
            Symbol = ""
            Object = ""
        }
    }

    $candidateVaText = Get-CsvField $Row "candidate_va"
    if (-not [string]::IsNullOrWhiteSpace($candidateVaText)) {
        if (-not [string]::IsNullOrWhiteSpace((Get-CsvField $Row "candidate_object"))) {
            throw "candidate_object requires candidate_symbol; it cannot qualify candidate_va."
        }
        $candidateVa = Parse-Number $candidateVaText "candidate_va"
        return [pscustomobject]@{
            Rva = Resolve-RvaFromVa $candidateVa $CandidateImage.ImageBase "candidate_va"
            Kind = "candidate_va"
            Locator = $candidateVaText.Trim()
            Symbol = ""
            Object = ""
        }
    }

    $candidateSymbol = (Get-CsvField $Row "candidate_symbol").Trim()
    if (-not [string]::IsNullOrWhiteSpace($candidateSymbol)) {
        $candidateObject = (Get-CsvField $Row "candidate_object").Trim()
        $resolvedSymbol = Resolve-CandidateSymbol $candidateSymbol $candidateObject $CandidateSymbols
        return [pscustomobject]@{
            Rva = [uint64]$resolvedSymbol.Rva
            Kind = "candidate_symbol"
            Locator = $candidateSymbol
            Symbol = $candidateSymbol
            Object = [string]$resolvedSymbol.Object
        }
    }

    if (-not [string]::IsNullOrWhiteSpace((Get-CsvField $Row "candidate_object"))) {
        throw "candidate_object requires candidate_symbol."
    }
    return [pscustomobject]@{
        Rva = $OriginalRva
        Kind = "original_rva"
        Locator = Format-OtHex $OriginalRva
        Symbol = ""
        Object = ""
    }
}

function Get-OriginalRva($Row, $OriginalImage) {
    $originalRvaText = Get-CsvField $Row "original_rva"
    if (-not [string]::IsNullOrWhiteSpace($originalRvaText)) {
        return Parse-Number $originalRvaText "original_rva"
    }

    $originalVa = Parse-Number (Get-CsvField $Row "original_va") "original_va"
    return Resolve-RvaFromVa $originalVa $OriginalImage.ImageBase "original_va"
}

function Read-Mask([string]$MaskText, [int]$Size) {
    $mask = New-Object bool[] $Size
    if ([string]::IsNullOrWhiteSpace($MaskText)) {
        return $mask
    }

    foreach ($rawPart in ($MaskText -split '[;, ]+')) {
        if ([string]::IsNullOrWhiteSpace($rawPart)) {
            continue
        }

        $part = $rawPart.Trim()
        if ($part -match '^(.+)-(.+)$') {
            $start = Parse-Number $Matches[1] "mask.start"
            $end = Parse-Number $Matches[2] "mask.end"
        }
        else {
            $start = Parse-Number $part "mask.offset"
            $end = $start
        }

        if ($end -lt $start) {
            throw "Mask range '$part' ends before it starts."
        }

        if ($end -ge [uint64]$Size) {
            throw "Mask range '$part' is outside the function range."
        }

        for ($offset = [int]$start; $offset -le [int]$end; $offset++) {
            $mask[$offset] = $true
        }
    }

    return $mask
}

function Copy-WithMask([byte[]]$Bytes, [bool[]]$Mask) {
    $copy = New-Object byte[] $Bytes.Length
    [System.Array]::Copy($Bytes, $copy, $Bytes.Length)
    for ($index = 0; $index -lt $copy.Length; $index++) {
        if ($Mask[$index]) {
            $copy[$index] = 0
        }
    }

    return $copy
}

function Get-Sha256Hex([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($sha.ComputeHash($Bytes) | ForEach-Object { $_.ToString("x2") }) -join "")
    }
    finally {
        $sha.Dispose()
    }
}

function Get-FileSha256Hex([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return ""
    }

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

function Find-FirstDifference([byte[]]$Left, [byte[]]$Right, [bool[]]$Mask) {
    for ($index = 0; $index -lt $Left.Length; $index++) {
        if ($Mask[$index]) {
            continue
        }

        if ($Left[$index] -ne $Right[$index]) {
            return $index
        }
    }

    return $null
}

function Find-FirstRawDifference([byte[]]$Left, [byte[]]$Right) {
    for ($index = 0; $index -lt $Left.Length; $index++) {
        if ($Left[$index] -ne $Right[$index]) {
            return $index
        }
    }

    return $null
}

function Count-MaskBytes([bool[]]$Mask) {
    $count = 0
    foreach ($isMasked in $Mask) {
        if ($isMasked) {
            $count++
        }
    }

    return $count
}

function Test-FullyMaskedField([bool[]]$Mask, [int]$Start, [int]$Length) {
    if ($Start -lt 0 -or $Length -lt 1 -or ($Start + $Length) -gt $Mask.Length) {
        return $false
    }

    for ($offset = $Start; $offset -lt ($Start + $Length); $offset++) {
        if (-not $Mask[$offset]) {
            return $false
        }
    }
    return $true
}

function Test-RangeIntersectsMask([bool[]]$Mask, [int]$Start, [int]$Length) {
    if ($Start -lt 0 -or $Length -lt 1 -or $Start -ge $Mask.Length) {
        return $false
    }

    $end = [System.Math]::Min(($Mask.Length - 1), ($Start + $Length - 1))
    for ($offset = $Start; $offset -le $end; $offset++) {
        if ($Mask[$offset]) {
            return $true
        }
    }
    return $false
}

function Test-RvaInExecutableSection($Image, [int64]$Rva) {
    if ($Rva -lt 0) {
        return $false
    }

    $unsignedRva = [uint64]$Rva
    foreach ($section in $Image.Sections) {
        if (([uint32]$section.Characteristics -band [uint32]0x20000000) -eq 0) {
            continue
        }

        $sectionStart = [uint64]$section.VirtualAddress
        $sectionSpan = [System.Math]::Max([uint64]$section.VirtualSize, [uint64]$section.RawSize)
        if ($unsignedRva -ge $sectionStart -and $unsignedRva -lt ($sectionStart + $sectionSpan)) {
            return $true
        }
    }
    return $false
}

function Resolve-ImportFromAbsoluteOperand($Image, [byte[]]$FunctionBytes, [int]$OperandOffset) {
    $absoluteVa = [uint64](Read-U32 $FunctionBytes $OperandOffset)
    if ($absoluteVa -lt [uint64]$Image.ImageBase) {
        return $null
    }

    $targetRva = $absoluteVa - [uint64]$Image.ImageBase
    $key = [string]$targetRva
    if (-not $Image.ImportIatIndex.ContainsKey($key)) {
        return $null
    }
    return $Image.ImportIatIndex[$key]
}

function Test-SameImportIdentity($Left, $Right) {
    if ($Left.DllKey -cne $Right.DllKey -or $Left.ByOrdinal -ne $Right.ByOrdinal) {
        return $false
    }
    if ($Left.ByOrdinal) {
        return ([int]$Left.Ordinal -eq [int]$Right.Ordinal)
    }
    return ([string]$Left.Symbol -ceq [string]$Right.Symbol)
}

function Get-MaskedOperandEvidence(
    $Image,
    [uint64]$FunctionRva,
    [byte[]]$FunctionBytes,
    [bool[]]$Mask) {

    $operandsByRange = @{}
    for ($operandOffset = 0; $operandOffset -le ($FunctionBytes.Length - 4); $operandOffset++) {
        if (-not (Test-RangeIntersectsMask $Mask $operandOffset 4)) {
            continue
        }

        $operandRva = $FunctionRva + [uint64]$operandOffset
        if (-not $Image.HighLowRelocationIndex.ContainsKey([string]$operandRva)) {
            continue
        }

        $key = "{0}:{1}" -f $operandOffset, ($operandOffset + 3)
        $operandsByRange[$key] = [pscustomobject]@{
            Start = $operandOffset
            End = $operandOffset + 3
            Kind = "highlow"
            Ambiguous = $false
            Import = Resolve-ImportFromAbsoluteOperand $Image $FunctionBytes $operandOffset
            TargetRva = ""
        }
    }

    # rel32 fields have no PE base relocation. Recognize the three encodings
    # accepted by the manifest policy and require their decoded targets to stay
    # in executable image sections. This mirrors the conservative original-side
    # mask audit while applying the same evidence rule to the candidate.
    for ($opcodeOffset = 0; $opcodeOffset -lt $FunctionBytes.Length; $opcodeOffset++) {
        $operandOffset = -1
        $instructionLength = 0
        $kind = ""
        $opcode = [int]$FunctionBytes[$opcodeOffset]
        if (($opcode -eq 0xe8 -or $opcode -eq 0xe9) -and
            ($opcodeOffset + 5) -le $FunctionBytes.Length) {
            $operandOffset = $opcodeOffset + 1
            $instructionLength = 5
            $kind = if ($opcode -eq 0xe8) { "rel32_call" } else { "rel32_jmp" }
        }
        elseif ($opcode -eq 0x0f -and ($opcodeOffset + 6) -le $FunctionBytes.Length) {
            $secondOpcode = [int]$FunctionBytes[($opcodeOffset + 1)]
            if ($secondOpcode -ge 0x80 -and $secondOpcode -le 0x8f) {
                $operandOffset = $opcodeOffset + 2
                $instructionLength = 6
                $kind = "rel32_jcc"
            }
        }

        if ($operandOffset -lt 0 -or
            -not (Test-RangeIntersectsMask $Mask $operandOffset 4)) {
            continue
        }

        $opcodeInsideHighLow = $false
        foreach ($existing in $operandsByRange.Values) {
            if ($existing.Kind -eq "highlow" -and
                $opcodeOffset -ge $existing.Start -and $opcodeOffset -le $existing.End) {
                $opcodeInsideHighLow = $true
                break
            }
        }
        if ($opcodeInsideHighLow) {
            continue
        }

        $displacement = Read-I32 $FunctionBytes $operandOffset
        $nextInstructionRva = [int64]$FunctionRva + [int64]$opcodeOffset + [int64]$instructionLength
        $targetRva = $nextInstructionRva + $displacement
        if (-not (Test-RvaInExecutableSection $Image $targetRva)) {
            continue
        }

        $key = "{0}:{1}" -f $operandOffset, ($operandOffset + 3)
        if ($operandsByRange.ContainsKey($key)) {
            $operandsByRange[$key].Ambiguous = $true
            $operandsByRange[$key].Kind = $operandsByRange[$key].Kind + "+" + $kind
            continue
        }

        $operandsByRange[$key] = [pscustomobject]@{
            Start = $operandOffset
            End = $operandOffset + 3
            Kind = $kind
            Ambiguous = $false
            Import = $null
            TargetRva = Format-OtHex ([uint64]$targetRva)
        }
    }

    return @($operandsByRange.Values | Sort-Object Start, End)
}

function New-MaskedOperandMismatch(
    [int]$Offset,
    [string]$Message,
    [bool]$ImportIdentityError = $false) {
    return [pscustomobject]@{
        Offset = $Offset
        Message = $Message
        ImportIdentityError = $ImportIdentityError
    }
}

function Find-MaskedOperandShapeMismatch(
    $OriginalImage,
    [uint64]$OriginalRva,
    [byte[]]$OriginalBytes,
    $CandidateImage,
    [uint64]$CandidateRva,
    [byte[]]$CandidateBytes,
    [bool[]]$Mask) {

    $originalOperands = @(Get-MaskedOperandEvidence `
        $OriginalImage $OriginalRva $OriginalBytes $Mask)
    $candidateOperands = @(Get-MaskedOperandEvidence `
        $CandidateImage $CandidateRva $CandidateBytes $Mask)
    $originalByRange = @{}
    $candidateByRange = @{}
    $originalCoverage = New-Object bool[] $Mask.Length
    $candidateCoverage = New-Object bool[] $Mask.Length

    foreach ($operand in $originalOperands) {
        $rangeText = "{0}-{1}" -f
            (Format-OtHex ([uint64]$operand.Start)),
            (Format-OtHex ([uint64]$operand.End))
        if ($operand.Ambiguous) {
            return New-MaskedOperandMismatch $operand.Start `
                "Masked operand evidence is ambiguous in the original at function range $rangeText."
        }
        if (-not (Test-FullyMaskedField $Mask $operand.Start 4)) {
            return New-MaskedOperandMismatch $operand.Start `
                "Mask partially covers the original $($operand.Kind) operand at function range $rangeText."
        }
        $key = "{0}:{1}" -f $operand.Start, $operand.End
        $originalByRange[$key] = $operand
        for ($offset = $operand.Start; $offset -le $operand.End; $offset++) {
            $originalCoverage[$offset] = $true
        }
    }

    foreach ($operand in $candidateOperands) {
        $rangeText = "{0}-{1}" -f
            (Format-OtHex ([uint64]$operand.Start)),
            (Format-OtHex ([uint64]$operand.End))
        if ($operand.Ambiguous) {
            return New-MaskedOperandMismatch $operand.Start `
                "Masked operand evidence is ambiguous in the candidate at function range $rangeText."
        }
        if (-not (Test-FullyMaskedField $Mask $operand.Start 4)) {
            return New-MaskedOperandMismatch $operand.Start `
                "Mask partially covers the candidate $($operand.Kind) operand at function range $rangeText."
        }
        $key = "{0}:{1}" -f $operand.Start, $operand.End
        $candidateByRange[$key] = $operand
        for ($offset = $operand.Start; $offset -le $operand.End; $offset++) {
            $candidateCoverage[$offset] = $true
        }
    }

    for ($offset = 0; $offset -lt $Mask.Length; $offset++) {
        if (-not $Mask[$offset]) {
            continue
        }
        if (-not $originalCoverage[$offset]) {
            return New-MaskedOperandMismatch $offset `
                ("Masked byte at function offset {0} is not covered by a complete original HIGHLOW or rel32 operand." -f
                    (Format-OtHex ([uint64]$offset)))
        }
    }

    foreach ($key in @($originalByRange.Keys | Sort-Object)) {
        $originalOperand = $originalByRange[$key]
        $offsetText = Format-OtHex ([uint64]$originalOperand.Start)
        $rangeText = "{0}-{1}" -f $offsetText,
            (Format-OtHex ([uint64]$originalOperand.End))
        $originalImport = $originalOperand.Import
        if (-not $candidateByRange.ContainsKey($key)) {
            if ($null -ne $originalImport) {
                return New-MaskedOperandMismatch $originalOperand.Start `
                    (("Masked import relocation mismatch at function offset {0}: original targets {1}, " +
                        "but the candidate operand is not a HIGHLOW relocation.") -f
                        $offsetText, $originalImport.Display) $true
            }
            return New-MaskedOperandMismatch $originalOperand.Start `
                "Masked operand shape mismatch at function range ${rangeText}: original is $($originalOperand.Kind), but the candidate has no same-offset maskable operand."
        }

        $candidateOperand = $candidateByRange[$key]
        if ($candidateOperand.Kind -cne $originalOperand.Kind) {
            if ($null -ne $originalImport) {
                return New-MaskedOperandMismatch $originalOperand.Start `
                    (("Masked import relocation mismatch at function offset {0}: original targets {1}, " +
                        "but the candidate operand is not a HIGHLOW relocation.") -f
                        $offsetText, $originalImport.Display) $true
            }
            return New-MaskedOperandMismatch $originalOperand.Start `
                "Masked operand kind mismatch at function range ${rangeText}: original is $($originalOperand.Kind), candidate is $($candidateOperand.Kind)."
        }

        if ($originalOperand.Kind -eq "highlow") {
            $candidateImport = $candidateOperand.Import
            # Import identity is enforceable when the original PE import table
            # names the target. Some original CRT IAT slots are not represented
            # there, so a candidate-side import alone cannot reclassify the
            # original HIGHLOW as invalid.
            if ($null -ne $originalImport -and $null -eq $candidateImport) {
                return New-MaskedOperandMismatch $originalOperand.Start `
                    (("Masked import target mismatch at function offset {0}: original targets {1}, " +
                        "but the candidate operand does not resolve to an import-address-table entry.") -f
                        $offsetText, $originalImport.Display) $true
            }
            if ($null -ne $originalImport -and
                -not (Test-SameImportIdentity $originalImport $candidateImport)) {
                return New-MaskedOperandMismatch $originalOperand.Start `
                    (("Masked import identity mismatch at function offset {0}: original targets {1}, " +
                        "candidate targets {2}.") -f
                        $offsetText, $originalImport.Display, $candidateImport.Display) $true
            }
        }
    }

    for ($offset = 0; $offset -lt $Mask.Length; $offset++) {
        if ($Mask[$offset] -and -not $candidateCoverage[$offset]) {
            return New-MaskedOperandMismatch $offset `
                ("Masked byte at function offset {0} is not covered by a complete same-offset candidate HIGHLOW or rel32 operand." -f
                    (Format-OtHex ([uint64]$offset)))
        }
    }

    foreach ($key in @($candidateByRange.Keys)) {
        if (-not $originalByRange.ContainsKey($key)) {
            $candidateOperand = $candidateByRange[$key]
            $rangeText = "{0}-{1}" -f
                (Format-OtHex ([uint64]$candidateOperand.Start)),
                (Format-OtHex ([uint64]$candidateOperand.End))
            return New-MaskedOperandMismatch $candidateOperand.Start `
                "Masked candidate $($candidateOperand.Kind) operand at function range $rangeText has no same-offset original operand."
        }
    }

    return $null
}

function Get-ExpectedStatus($Row, [bool]$Required) {
    $expectedStatus = (Get-CsvField $Row "expected_status").Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($expectedStatus)) {
        if ($Required) {
            throw "Missing required expected_status; expected 'match' or 'wip'."
        }
        return ""
    }

    if ($expectedStatus -ne "match" -and $expectedStatus -ne "wip") {
        throw "Invalid expected_status '$expectedStatus'; expected 'match' or 'wip'."
    }

    return $expectedStatus
}

function Get-ImplementationKind($Row, [bool]$Required) {
    $implementationKind = (Get-CsvField $Row "implementation_kind").Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($implementationKind)) {
        if ($Required) {
            throw "Missing required implementation_kind; expected 'cpp', 'asm', or 'toolchain-lib'."
        }
        return ""
    }

    if ($implementationKind -ne "cpp" -and
        $implementationKind -ne "asm" -and
        $implementationKind -ne "toolchain-lib") {
        throw ("Invalid implementation_kind '{0}'; expected 'cpp', 'asm', or 'toolchain-lib'." -f
            $implementationKind)
    }

    return $implementationKind
}

$resolvedManifestPath = (Resolve-Path -LiteralPath $ManifestPath).Path
$manifestSha256 = Get-FileSha256Hex $resolvedManifestPath
$manifest = @(Import-Csv -LiteralPath $resolvedManifestPath)
if ($manifest.Count -eq 0) {
    throw "Manifest has no function rows: $ManifestPath"
}
$manifestColumns = @($manifest[0].PSObject.Properties.Name)
$expectedStatusRequired = $manifestColumns -contains "expected_status"
$implementationKindRequired = $manifestColumns -contains "implementation_kind"

$originalImage = Get-PeImage $OriginalPath
$candidateImage = Get-PeImage $CandidatePath
$resolvedCandidateMapPath = Resolve-OptionalPath $CandidateMapPath
$candidateSymbols = Read-MsvcMapSymbols -Path $resolvedCandidateMapPath -CandidateImageBase $candidateImage.ImageBase

# Map manifest `program` values to their loaded PE images. The default
# program is Oregon32.exe; rows attributed to OREGON32.DLL need
# -OriginalDllPath to be passed.
$originalImages = @{
    $DefaultProgram = $originalImage
}
if (-not [string]::IsNullOrWhiteSpace($OriginalDllPath)) {
    $originalImages["OREGON32.DLL"] = Get-PeImage $OriginalDllPath
}
$originalImageHashes = @{}
foreach ($key in $originalImages.Keys) {
    $originalImageHashes[$key] = Get-Sha256Hex $originalImages[$key].Bytes
}

# Map manifest `candidate_dll` values to their loaded candidate PE images,
# symbol occurrence tables, and the map that proves each selected symbol's
# object provenance. Default candidate is the LIBC-anchored DLL; rows targeting
# LIBCMT-linked helpers use the companion candidate images.
$candidateImages = @{
    "" = $candidateImage
    "default" = $candidateImage
    "libc" = $candidateImage
}
$candidateSymbolTables = @{
    "" = $candidateSymbols
    "default" = $candidateSymbols
    "libc" = $candidateSymbols
}
$candidateMapPaths = @{
    "" = $resolvedCandidateMapPath
    "default" = $resolvedCandidateMapPath
    "libc" = $resolvedCandidateMapPath
}
if (-not [string]::IsNullOrWhiteSpace($CandidateLcmtPath)) {
    $lcmtImage = Get-PeImage $CandidateLcmtPath
    $resolvedLcmtMapPath = Resolve-OptionalPath $CandidateLcmtMapPath
    $lcmtSymbols = Read-MsvcMapSymbols -Path $resolvedLcmtMapPath -CandidateImageBase $lcmtImage.ImageBase
    $candidateImages["lcmt"] = $lcmtImage
    $candidateSymbolTables["lcmt"] = $lcmtSymbols
    $candidateMapPaths["lcmt"] = $resolvedLcmtMapPath
}
if (-not [string]::IsNullOrWhiteSpace($CandidateDllcrtPath)) {
    $dllcrtImage = Get-PeImage $CandidateDllcrtPath
    $resolvedDllcrtMapPath = Resolve-OptionalPath $CandidateDllcrtMapPath
    $dllcrtSymbols = Read-MsvcMapSymbols -Path $resolvedDllcrtMapPath -CandidateImageBase $dllcrtImage.ImageBase
    $candidateImages["dllcrt"] = $dllcrtImage
    $candidateSymbolTables["dllcrt"] = $dllcrtSymbols
    $candidateMapPaths["dllcrt"] = $resolvedDllcrtMapPath
}
$candidateImageHashes = @{}
$candidateMapHashes = @{}
foreach ($key in $candidateImages.Keys) {
    $candidateImageHashes[$key] = Get-Sha256Hex $candidateImages[$key].Bytes
    $candidateMapHashes[$key] = Get-FileSha256Hex $candidateMapPaths[$key]
}

$results = @()
$rowIndex = 0
foreach ($row in $manifest) {
    $rowIndex++
    $name = (Get-CsvField $row "name").Trim()
    if ([string]::IsNullOrWhiteSpace($name)) {
        $name = "<unnamed>"
    }

    $rowProgram = (Get-CsvField $row "program").Trim()
    if ([string]::IsNullOrWhiteSpace($rowProgram)) {
        $rowProgram = $DefaultProgram
    }
    $rowCandidateDll = (Get-CsvField $row "candidate_dll").Trim().ToLowerInvariant()
    $expectedStatus = (Get-CsvField $row "expected_status").Trim().ToLowerInvariant()
    $implementationKind = (Get-CsvField $row "implementation_kind").Trim().ToLowerInvariant()
    $maskText = (Get-CsvField $row "mask").Trim()
    $candidateObjectQualifier = (Get-CsvField $row "candidate_object").Trim()

    $actualStatus = "error"
    $verificationStatus = "error"
    $promotionReady = $false
    $originalPathForResult = ""
    $originalFileSha256 = ""
    $originalRvaForResult = ""
    $candidatePathForResult = ""
    $candidateFileSha256 = ""
    $candidateMapPathForResult = ""
    $candidateMapSha256 = ""
    $candidateLocatorKind = ""
    $candidateLocator = ""
    $candidateSymbolForResult = (Get-CsvField $row "candidate_symbol").Trim()
    $candidateObjectForResult = ""
    $candidateRvaForResult = ""
    $sizeForResult = (Get-CsvField $row "size").Trim()
    $maskBytes = ""
    $comparedBytes = ""
    $rawMatch = ""
    $rawFirstDifferenceForResult = ""
    $firstDifferenceForResult = ""
    $originalRawSha256 = ""
    $candidateRawSha256 = ""
    $originalSha256 = ""
    $candidateSha256 = ""
    $maskShapeValid = $false
    $maskedOperandShapeError = ""
    $maskedImportIdentityError = ""
    $errorMessage = ""

    try {
        $expectedStatus = Get-ExpectedStatus $row $expectedStatusRequired
        $implementationKind = Get-ImplementationKind $row $implementationKindRequired

        if (-not $originalImages.ContainsKey($rowProgram)) {
            throw "Manifest row references program '$rowProgram' but no matching original PE was provided. Pass -OriginalDllPath to enable OREGON32.DLL rows."
        }
        $rowOriginalImage = $originalImages[$rowProgram]
        $originalPathForResult = $rowOriginalImage.Path
        $originalFileSha256 = $originalImageHashes[$rowProgram]

        if (-not $candidateImages.ContainsKey($rowCandidateDll)) {
            throw "Manifest row references candidate_dll '$rowCandidateDll' but no matching candidate PE was provided. Pass the corresponding candidate PE and map paths."
        }
        $rowCandidateImage = $candidateImages[$rowCandidateDll]
        $rowCandidateSymbols = $candidateSymbolTables[$rowCandidateDll]
        $candidatePathForResult = $rowCandidateImage.Path
        $candidateFileSha256 = $candidateImageHashes[$rowCandidateDll]
        $candidateMapPathForResult = $candidateMapPaths[$rowCandidateDll]
        $candidateMapSha256 = $candidateMapHashes[$rowCandidateDll]

        $originalRva = Get-OriginalRva $row $rowOriginalImage
        $originalRvaForResult = Format-OtHex $originalRva
        $size = Parse-Number (Get-CsvField $row "size") "size"
        if ($size -eq 0) {
            throw "Function size cannot be zero."
        }
        $sizeForResult = $size

        $candidateLocatorInfo = Resolve-CandidateLocator $row $originalRva $rowCandidateImage $rowCandidateSymbols
        $candidateRva = [uint64]$candidateLocatorInfo.Rva
        $candidateRvaForResult = Format-OtHex $candidateRva
        $candidateLocatorKind = [string]$candidateLocatorInfo.Kind
        $candidateLocator = [string]$candidateLocatorInfo.Locator
        $candidateSymbolForResult = [string]$candidateLocatorInfo.Symbol
        $candidateObjectForResult = [string]$candidateLocatorInfo.Object

        $originalBytes = Read-PeRange $rowOriginalImage $originalRva $size
        $candidateBytes = Read-PeRange $rowCandidateImage $candidateRva $size
        $mask = Read-Mask $maskText ([int]$size)
        $maskBytes = Count-MaskBytes $mask
        $comparedBytes = [uint64]$size - [uint64]$maskBytes

        $rawFirstDifference = Find-FirstRawDifference $originalBytes $candidateBytes
        $rawMatch = ($null -eq $rawFirstDifference)
        $rawFirstDifferenceForResult = if ($null -eq $rawFirstDifference) { "" } else { Format-OtHex ([uint64]$rawFirstDifference) }
        $originalRawSha256 = Get-Sha256Hex $originalBytes
        $candidateRawSha256 = Get-Sha256Hex $candidateBytes

        if ([uint64]$comparedBytes -eq 0) {
            throw "Mask covers the entire function; at least one byte must remain evidence-bearing."
        }

        $originalComparable = Copy-WithMask $originalBytes $mask
        $candidateComparable = Copy-WithMask $candidateBytes $mask
        $firstDifference = Find-FirstDifference $originalBytes $candidateBytes $mask
        $firstDifferenceForResult = if ($null -eq $firstDifference) { "" } else { Format-OtHex ([uint64]$firstDifference) }
        $originalSha256 = Get-Sha256Hex $originalComparable
        $candidateSha256 = Get-Sha256Hex $candidateComparable

        $operandShapeMismatch = Find-MaskedOperandShapeMismatch `
            $rowOriginalImage $originalRva $originalBytes `
            $rowCandidateImage $candidateRva $candidateBytes $mask
        $maskShapeValid = ($null -eq $operandShapeMismatch)
        if ($null -ne $operandShapeMismatch) {
            $maskedOperandShapeError = [string]$operandShapeMismatch.Message
            if ([bool]$operandShapeMismatch.ImportIdentityError) {
                $maskedImportIdentityError = [string]$operandShapeMismatch.Message
            }
            if ($null -eq $firstDifference) {
                $firstDifference = [int]$operandShapeMismatch.Offset
                $firstDifferenceForResult = Format-OtHex ([uint64]$firstDifference)
            }
        }
        $actualStatus = if ($null -eq $firstDifference) { "match" } else { "mismatch" }

        if ($actualStatus -eq "match") {
            if ($expectedStatus -eq "wip") {
                $verificationStatus = "promotion_ready"
                $promotionReady = $true
            }
            else {
                $verificationStatus = "pass"
            }
        }
        elseif ($expectedStatus -eq "wip") {
            $verificationStatus = "allowed_wip"
        }
        else {
            $verificationStatus = "regression"
        }
    }
    catch {
        $actualStatus = "error"
        $verificationStatus = "error"
        $promotionReady = $false
        $errorMessage = $_.Exception.Message
    }

    $results += [pscustomobject][ordered]@{
        result_schema_version = 4
        manifest_path = $resolvedManifestPath
        manifest_sha256 = $manifestSha256
        row_index = $rowIndex
        status = $actualStatus
        actual_status = $actualStatus
        expected_status = $expectedStatus
        verification_status = $verificationStatus
        promotion_ready = $promotionReady
        implementation_kind = $implementationKind
        name = $name
        program = $rowProgram
        original_path = $originalPathForResult
        original_file_sha256 = $originalFileSha256
        original_rva = $originalRvaForResult
        candidate_dll = $rowCandidateDll
        candidate_path = $candidatePathForResult
        candidate_file_sha256 = $candidateFileSha256
        candidate_map_path = $candidateMapPathForResult
        candidate_map_sha256 = $candidateMapSha256
        candidate_locator_kind = $candidateLocatorKind
        candidate_locator = $candidateLocator
        candidate_symbol = $candidateSymbolForResult
        candidate_object_qualifier = $candidateObjectQualifier
        candidate_object = $candidateObjectForResult
        candidate_rva = $candidateRvaForResult
        size = $sizeForResult
        mask = $maskText
        mask_bytes = $maskBytes
        compared_bytes = $comparedBytes
        raw_match = $rawMatch
        raw_first_diff = $rawFirstDifferenceForResult
        first_diff = $firstDifferenceForResult
        original_raw_sha256 = $originalRawSha256
        candidate_raw_sha256 = $candidateRawSha256
        original_sha256 = $originalSha256
        candidate_sha256 = $candidateSha256
        mask_shape_valid = $maskShapeValid
        masked_operand_shape_error = $maskedOperandShapeError
        masked_import_identity_error = $maskedImportIdentityError
        error_message = $errorMessage
        notes = Get-CsvField $row "notes"
    }
}

if (-not [string]::IsNullOrWhiteSpace($ResultsCsvPath)) {
    $resolvedResultsCsvPath = [System.IO.Path]::GetFullPath($ResultsCsvPath)
    $resultsDirectory = Split-Path -Parent $resolvedResultsCsvPath
    if (-not [System.IO.Directory]::Exists($resultsDirectory)) {
        [void][System.IO.Directory]::CreateDirectory($resultsDirectory)
    }
    $results | Export-Csv -LiteralPath $resolvedResultsCsvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("Wrote function verification results: {0}" -f $resolvedResultsCsvPath)
}

if (-not $SummaryOnly) {
    $results |
        Select-Object status, expected_status, verification_status, name, original_rva, candidate_rva, size, first_diff |
        Format-Table -AutoSize
}

$mismatches = @($results | Where-Object { $_.actual_status -eq "mismatch" })
$errors = @($results | Where-Object { $_.actual_status -eq "error" })
$regressions = @($results | Where-Object { $_.verification_status -eq "regression" })
$allowedWip = @($results | Where-Object { $_.verification_status -eq "allowed_wip" })
$promotionReadyResults = @($results | Where-Object { $_.verification_status -eq "promotion_ready" })

Write-Host ""
if ($mismatches.Count -eq 0 -and $errors.Count -eq 0) {
    Write-Host ("All function ranges matched: {0}/{0}" -f $results.Count)
}
else {
    Write-Host ("Function byte mismatches: {0}/{1}" -f $mismatches.Count, $results.Count)
    Write-Host ("Verifier errors: {0}/{1}" -f $errors.Count, $results.Count)
}

if ($regressions.Count -ne 0) {
    Write-Host ("Unexpected match regressions: {0}" -f $regressions.Count)
    foreach ($regression in $regressions) {
        if (-not [string]::IsNullOrWhiteSpace($regression.masked_operand_shape_error)) {
            Write-Host ("  {0} ({1}): {2}" -f
                $regression.name, $regression.original_rva, $regression.masked_operand_shape_error)
        }
        else {
            Write-Host ("  {0} ({1}): first difference {2}" -f
                $regression.name, $regression.original_rva, $regression.first_diff)
        }
    }
}

if ($errors.Count -ne 0) {
    Write-Host ("Verification errors: {0}" -f $errors.Count)
    foreach ($errorResult in $errors) {
        Write-Host ("  {0}: {1}" -f $errorResult.name, $errorResult.error_message)
    }
}

if ($promotionReadyResults.Count -ne 0) {
    Write-Host ("Promotion-ready expected-WIP matches: {0}" -f $promotionReadyResults.Count)
    foreach ($promotionReadyResult in $promotionReadyResults) {
        Write-Host ("  {0} ({1})" -f $promotionReadyResult.name, $promotionReadyResult.original_rva)
    }
}

if ($SummaryOnly) {
    $results |
        Group-Object verification_status |
        Sort-Object Name |
        ForEach-Object { Write-Host ("  {0}: {1}" -f $_.Name, $_.Count) }
}

# Expected-WIP mismatches are deliberate and do not require
# -AllowMismatches. The compatibility switch still permits byte mismatches in
# legacy/expected-match rows for exploratory builds, but verifier errors are
# always fatal because they mean no trustworthy comparison was performed.
if ($errors.Count -ne 0) {
    exit 1
}
if ($regressions.Count -ne 0 -and -not $AllowMismatches) {
    exit 1
}
