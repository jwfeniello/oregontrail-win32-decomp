[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,

    [Parameter(Mandatory = $true)]
    [string]$OriginalPath,

    [Parameter(Mandatory = $true)]
    [string]$OriginalDllPath,

    [string]$DefaultProgram = "Oregon32.exe",

    [string]$ResultsCsvPath,

    [switch]$RequireValidated
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# This is deliberately an original-image-only audit. It does not decide whether
# candidate bytes match; it decides whether each byte excluded by the manifest
# has evidence that it belongs to a load-address relocation or direct rel32
# control-transfer operand.

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

function Assert-ByteRange([byte[]]$Bytes, [int]$Offset, [int]$Count, [string]$Context) {
    if ($Offset -lt 0 -or $Count -lt 0 -or $Offset -gt $Bytes.Length -or
        $Count -gt ($Bytes.Length - $Offset)) {
        throw ("{0} is outside the file (offset {1}, size {2}, file size {3})." -f
            $Context, $Offset, $Count, $Bytes.Length)
    }
}

function Read-U16([byte[]]$Bytes, [int]$Offset, [string]$Context = "16-bit field") {
    Assert-ByteRange $Bytes $Offset 2 $Context
    return [uint16](
        ([uint64]$Bytes[$Offset]) -bor
        (([uint64]$Bytes[($Offset + 1)]) -shl 8))
}

function Read-U32([byte[]]$Bytes, [int]$Offset, [string]$Context = "32-bit field") {
    Assert-ByteRange $Bytes $Offset 4 $Context
    return [uint32](
        ([uint64]$Bytes[$Offset]) -bor
        (([uint64]$Bytes[($Offset + 1)]) -shl 8) -bor
        (([uint64]$Bytes[($Offset + 2)]) -shl 16) -bor
        (([uint64]$Bytes[($Offset + 3)]) -shl 24))
}

function Read-I32([byte[]]$Bytes, [int]$Offset, [string]$Context = "signed 32-bit field") {
    $value = [uint64](Read-U32 $Bytes $Offset $Context)
    if ($value -ge [uint64]2147483648) {
        return [int64]($value - [uint64]4294967296)
    }

    return [int64]$value
}

function Convert-RvaToFileOffset($Image, [uint64]$Rva) {
    if ($Rva -lt [uint64]$Image.SizeOfHeaders) {
        if ($Rva -ge [uint64]$Image.Bytes.Length) {
            throw ("RVA {0} is outside {1}." -f (Format-OtHex $Rva), $Image.Path)
        }

        return [int]$Rva
    }

    foreach ($section in $Image.Sections) {
        $sectionStart = [uint64]$section.VirtualAddress
        $sectionSpan = [System.Math]::Max([uint64]$section.VirtualSize, [uint64]$section.RawSize)
        $sectionEnd = $sectionStart + $sectionSpan
        if ($Rva -lt $sectionStart -or $Rva -ge $sectionEnd) {
            continue
        }

        $delta = $Rva - $sectionStart
        if ($delta -ge [uint64]$section.RawSize) {
            throw ("RVA {0} maps into virtual padding in section {1} of {2}." -f
                (Format-OtHex $Rva), $section.Name, $Image.Path)
        }

        $fileOffset = [uint64]$section.RawPointer + $delta
        if ($fileOffset -ge [uint64]$Image.Bytes.Length) {
            throw ("RVA {0} maps past the end of {1}." -f (Format-OtHex $Rva), $Image.Path)
        }

        return [int]$fileOffset
    }

    throw ("RVA {0} does not map to a section in {1}." -f (Format-OtHex $Rva), $Image.Path)
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

function Read-PeRange($Image, [uint64]$Rva, [uint64]$Size) {
    if ($Size -gt [uint64][int]::MaxValue) {
        throw "PE range is too large to read in one pass: $Size bytes."
    }

    $offset = Convert-RvaToFileOffset $Image $Rva
    $sizeAsInt = [int]$Size
    Assert-ByteRange $Image.Bytes $offset $sizeAsInt ("PE range {0}+{1} in {2}" -f
        (Format-OtHex $Rva), $sizeAsInt, $Image.Path)

    $result = New-Object byte[] $sizeAsInt
    [System.Array]::Copy($Image.Bytes, $offset, $result, 0, $sizeAsInt)
    return $result
}

function Get-HighLowRelocations($Image, [uint64]$DirectoryRva, [uint64]$DirectorySize) {
    $relocations = New-Object System.Collections.ArrayList
    if ($DirectoryRva -eq 0 -or $DirectorySize -eq 0) {
        return $relocations
    }

    if ($DirectorySize -gt [uint64][int]::MaxValue) {
        throw "Base-relocation directory is too large in $($Image.Path)."
    }

    $directory = Read-PeRange $Image $DirectoryRva $DirectorySize
    $cursor = 0
    while ($cursor -lt $directory.Length) {
        if (($directory.Length - $cursor) -lt 8) {
            throw "Truncated base-relocation block header in $($Image.Path)."
        }

        $pageRva = [uint64](Read-U32 $directory $cursor "base-relocation page RVA")
        $blockSize = [uint64](Read-U32 $directory ($cursor + 4) "base-relocation block size")
        if ($pageRva -eq 0 -and $blockSize -eq 0) {
            break
        }

        if ($blockSize -lt 8 -or (($blockSize - 8) % 2) -ne 0) {
            throw ("Invalid base-relocation block size {0} at directory offset {1} in {2}." -f
                $blockSize, $cursor, $Image.Path)
        }
        if ($blockSize -gt [uint64]($directory.Length - $cursor)) {
            throw "Base-relocation block extends past the directory in $($Image.Path)."
        }

        $entryCount = [int](($blockSize - 8) / 2)
        for ($entryIndex = 0; $entryIndex -lt $entryCount; $entryIndex++) {
            $entryOffset = $cursor + 8 + ($entryIndex * 2)
            $entry = [uint16](Read-U16 $directory $entryOffset "base-relocation entry")
            $type = [int]($entry -shr 12)
            $offsetInPage = [uint64]($entry -band 0x0fff)
            if ($type -eq 3) {
                [void]$relocations.Add([pscustomobject]@{
                    Rva = $pageRva + $offsetInPage
                    Length = 4
                    Kind = "highlow"
                })
            }
        }

        $cursor += [int]$blockSize
    }

    return $relocations
}

function Get-Pe32Image([string]$Path) {
    $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
    $bytes = [System.IO.File]::ReadAllBytes($resolvedPath)
    if ($bytes.Length -lt 0x40) {
        throw "PE file is too small: $resolvedPath"
    }
    if ($bytes[0] -ne 0x4d -or $bytes[1] -ne 0x5a) {
        throw "Missing MZ header: $resolvedPath"
    }

    $peOffset = [int](Read-U32 $bytes 0x3c "PE header offset")
    Assert-ByteRange $bytes $peOffset 24 "PE signature and COFF header"
    if ($bytes[$peOffset] -ne 0x50 -or $bytes[($peOffset + 1)] -ne 0x45 -or
        $bytes[($peOffset + 2)] -ne 0 -or $bytes[($peOffset + 3)] -ne 0) {
        throw "Missing PE signature: $resolvedPath"
    }

    $coffOffset = $peOffset + 4
    $machine = Read-U16 $bytes $coffOffset "COFF machine"
    if ($machine -ne 0x014c) {
        throw ("Expected an i386 PE32 image, but {0} has COFF machine 0x{1:x4}." -f
            $resolvedPath, $machine)
    }

    $sectionCount = [int](Read-U16 $bytes ($coffOffset + 2) "COFF section count")
    $optionalHeaderSize = [int](Read-U16 $bytes ($coffOffset + 16) "COFF optional-header size")
    $optionalHeaderOffset = $coffOffset + 20
    Assert-ByteRange $bytes $optionalHeaderOffset $optionalHeaderSize "PE optional header"
    if ($optionalHeaderSize -lt 96) {
        throw "PE32 optional header is too small in $resolvedPath."
    }

    $optionalMagic = Read-U16 $bytes $optionalHeaderOffset "PE optional-header magic"
    if ($optionalMagic -ne 0x010b) {
        throw ("Expected PE32 optional-header magic 0x010b, but {0} has 0x{1:x4}." -f
            $resolvedPath, $optionalMagic)
    }

    $imageBase = [uint64](Read-U32 $bytes ($optionalHeaderOffset + 28) "PE32 image base")
    $sizeOfImage = [uint64](Read-U32 $bytes ($optionalHeaderOffset + 56) "PE32 image size")
    $sizeOfHeaders = [uint64](Read-U32 $bytes ($optionalHeaderOffset + 60) "PE32 header size")
    $numberOfDirectories = [uint64](Read-U32 $bytes ($optionalHeaderOffset + 92) "data-directory count")

    $relocationDirectoryRva = [uint64]0
    $relocationDirectorySize = [uint64]0
    if ($numberOfDirectories -gt 5 -and $optionalHeaderSize -ge (96 + (6 * 8))) {
        $relocationDirectoryOffset = $optionalHeaderOffset + 96 + (5 * 8)
        $relocationDirectoryRva = [uint64](Read-U32 $bytes $relocationDirectoryOffset "base-relocation directory RVA")
        $relocationDirectorySize = [uint64](Read-U32 $bytes ($relocationDirectoryOffset + 4) "base-relocation directory size")
    }

    $sectionTableOffset = $optionalHeaderOffset + $optionalHeaderSize
    Assert-ByteRange $bytes $sectionTableOffset ($sectionCount * 40) "PE section table"
    $sections = @()
    for ($index = 0; $index -lt $sectionCount; $index++) {
        $sectionOffset = $sectionTableOffset + ($index * 40)
        $name = [System.Text.Encoding]::ASCII.GetString($bytes, $sectionOffset, 8).Trim([char]0)
        $sections += [pscustomobject]@{
            Name = $name
            VirtualSize = [uint64](Read-U32 $bytes ($sectionOffset + 8) "section virtual size")
            VirtualAddress = [uint64](Read-U32 $bytes ($sectionOffset + 12) "section RVA")
            RawSize = [uint64](Read-U32 $bytes ($sectionOffset + 16) "section raw size")
            RawPointer = [uint64](Read-U32 $bytes ($sectionOffset + 20) "section raw pointer")
            Characteristics = [uint32](Read-U32 $bytes ($sectionOffset + 36) "section characteristics")
        }
    }

    $image = [pscustomobject]@{
        Path = $resolvedPath
        Bytes = $bytes
        ImageBase = $imageBase
        SizeOfImage = $sizeOfImage
        SizeOfHeaders = $sizeOfHeaders
        Sections = $sections
        Relocations = @()
        RelocationIndex = @{}
    }
    $image.Relocations = @(Get-HighLowRelocations $image $relocationDirectoryRva $relocationDirectorySize)
    foreach ($relocation in $image.Relocations) {
        $image.RelocationIndex[[string]([uint64]$relocation.Rva)] = $relocation
    }
    return $image
}

function Resolve-OriginalRva($Row, $Image) {
    $originalRvaText = Get-CsvField $Row "original_rva"
    if (-not [string]::IsNullOrWhiteSpace($originalRvaText)) {
        return Parse-Number $originalRvaText "original_rva"
    }

    $originalVa = Parse-Number (Get-CsvField $Row "original_va") "original_va"
    if ($originalVa -lt [uint64]$Image.ImageBase) {
        throw ("original_va {0} is below the image base {1}." -f
            (Format-OtHex $originalVa), (Format-OtHex ([uint64]$Image.ImageBase)))
    }

    return $originalVa - [uint64]$Image.ImageBase
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

function Get-TrueCount([bool[]]$Values) {
    $count = 0
    foreach ($value in $Values) {
        if ($value) {
            $count++
        }
    }

    return $count
}

function Get-MaskRanges([bool[]]$Mask) {
    $ranges = @()
    $cursor = 0
    while ($cursor -lt $Mask.Length) {
        if (-not $Mask[$cursor]) {
            $cursor++
            continue
        }

        $start = $cursor
        while (($cursor + 1) -lt $Mask.Length -and $Mask[($cursor + 1)]) {
            $cursor++
        }
        $end = $cursor
        $ranges += [pscustomobject]@{
            Start = $start
            End = $end
            Length = ($end - $start + 1)
        }
        $cursor++
    }

    return $ranges
}

function Test-RangeIntersectsMask([int]$Start, [int]$End, [bool[]]$Mask) {
    $boundedStart = [System.Math]::Max(0, $Start)
    $boundedEnd = [System.Math]::Min(($Mask.Length - 1), $End)
    if ($boundedEnd -lt $boundedStart) {
        return $false
    }

    for ($offset = $boundedStart; $offset -le $boundedEnd; $offset++) {
        if ($Mask[$offset]) {
            return $true
        }
    }

    return $false
}

function Test-OperandFullyMasked($Operand, [bool[]]$Mask) {
    if ($Operand.Start -lt 0 -or $Operand.End -ge $Mask.Length) {
        return $false
    }

    for ($offset = [int]$Operand.Start; $offset -le [int]$Operand.End; $offset++) {
        if (-not $Mask[$offset]) {
            return $false
        }
    }

    return $true
}

function Get-KnownOperands($Image, [uint64]$FunctionRva, [byte[]]$FunctionBytes, [bool[]]$Mask) {
    $operandsByRange = @{}
    $functionEnd = $FunctionRva + [uint64]$FunctionBytes.Length

    $relocationScanStart = [uint64]0
    if ($FunctionRva -ge 3) {
        $relocationScanStart = $FunctionRva - 3
    }
    for ($fieldStartRva = $relocationScanStart; $fieldStartRva -lt $functionEnd; $fieldStartRva++) {
        $relocationKey = [string]$fieldStartRva
        if (-not $Image.RelocationIndex.ContainsKey($relocationKey)) {
            continue
        }

        $relocation = $Image.RelocationIndex[$relocationKey]
        $fieldEndRva = $fieldStartRva + [uint64]$relocation.Length
        if ($fieldEndRva -le $FunctionRva -or $fieldStartRva -ge $functionEnd) {
            continue
        }

        $relativeStart = [int64]$fieldStartRva - [int64]$FunctionRva
        if (-not (Test-RangeIntersectsMask ([int]$relativeStart) ([int]($relativeStart + 3)) $Mask)) {
            continue
        }

        $key = "{0}:{1}" -f $relativeStart, ($relativeStart + 3)
        $operandsByRange[$key] = [pscustomobject]@{
            Start = $relativeStart
            End = $relativeStart + 3
            Kinds = @("highlow")
            TargetRva = ""
        }
    }

    # IMAGE_REL_BASED_HIGHLOW proves absolute operands. Relative branches do not
    # need base relocations, so recognize their immediate fields from opcode and
    # require the decoded target to remain within the original PE image. Only
    # fields that touch a mask matter to this audit; this also sharply reduces
    # the chance of interpreting an opcode-looking byte inside unrelated data.
    for ($opcodeOffset = 0; $opcodeOffset -lt $FunctionBytes.Length; $opcodeOffset++) {
        $operandStart = -1
        $instructionLength = 0
        $kind = ""
        $opcode = [int]$FunctionBytes[$opcodeOffset]

        if (($opcode -eq 0xe8 -or $opcode -eq 0xe9) -and
            ($opcodeOffset + 5) -le $FunctionBytes.Length) {
            $operandStart = $opcodeOffset + 1
            $instructionLength = 5
            if ($opcode -eq 0xe8) {
                $kind = "rel32_call"
            }
            else {
                $kind = "rel32_jmp"
            }
        }
        elseif ($opcode -eq 0x0f -and ($opcodeOffset + 6) -le $FunctionBytes.Length) {
            $secondOpcode = [int]$FunctionBytes[($opcodeOffset + 1)]
            if ($secondOpcode -ge 0x80 -and $secondOpcode -le 0x8f) {
                $operandStart = $opcodeOffset + 2
                $instructionLength = 6
                $kind = "rel32_jcc"
            }
        }

        if ($operandStart -lt 0 -or
            -not (Test-RangeIntersectsMask $operandStart ($operandStart + 3) $Mask)) {
            continue
        }

        # Do not decode an opcode byte that is itself part of a proven HIGHLOW
        # field. Such bytes are data for this purpose, not instruction starts.
        $opcodeInsideRelocation = $false
        foreach ($existing in $operandsByRange.Values) {
            if ($existing.Kinds -contains "highlow" -and
                $opcodeOffset -ge $existing.Start -and $opcodeOffset -le $existing.End) {
                $opcodeInsideRelocation = $true
                break
            }
        }
        if ($opcodeInsideRelocation) {
            continue
        }

        $displacement = Read-I32 $FunctionBytes $operandStart "rel32 displacement"
        $nextInstructionRva = [int64]$FunctionRva + [int64]$opcodeOffset + [int64]$instructionLength
        $targetRva = $nextInstructionRva + $displacement
        if (-not (Test-RvaInExecutableSection $Image $targetRva)) {
            continue
        }

        $operandEnd = $operandStart + 3
        $key = "{0}:{1}" -f $operandStart, $operandEnd
        if ($operandsByRange.ContainsKey($key)) {
            if ($operandsByRange[$key].Kinds -notcontains $kind) {
                $operandsByRange[$key].Kinds = @($operandsByRange[$key].Kinds) + $kind
            }
        }
        else {
            $operandsByRange[$key] = [pscustomobject]@{
                Start = [int64]$operandStart
                End = [int64]$operandEnd
                Kinds = @($kind)
                TargetRva = Format-OtHex ([uint64]$targetRva)
            }
        }
    }

    return @($operandsByRange.Values | Sort-Object Start, End)
}

function Join-Unique([object[]]$Values) {
    return (@($Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } |
        ForEach-Object { [string]$_ } | Sort-Object -Unique) -join ";")
}

$resolvedManifestPath = (Resolve-Path -LiteralPath $ManifestPath).Path
$originalImage = Get-Pe32Image $OriginalPath
$originalDllImage = Get-Pe32Image $OriginalDllPath

$images = @{}
$images[$DefaultProgram] = $originalImage
$images[[System.IO.Path]::GetFileName($originalImage.Path)] = $originalImage
$images[[System.IO.Path]::GetFileName($originalDllImage.Path)] = $originalDllImage

$rows = @(Import-Csv -LiteralPath $resolvedManifestPath)
$results = New-Object System.Collections.ArrayList
$maskedRowCount = 0
$masklessRowCount = 0
$maskedByteCount = 0
$fullyValidatedRowCount = 0
$debtRowCount = 0
$fullFunctionMaskCount = 0

foreach ($row in $rows) {
    $name = (Get-CsvField $row "name").Trim()
    $program = (Get-CsvField $row "program").Trim()
    if ([string]::IsNullOrWhiteSpace($program)) {
        $program = $DefaultProgram
    }
    if (-not $images.ContainsKey($program)) {
        throw ("Manifest row '{0}' selects unknown program '{1}'. Known programs: {2}." -f
            $name, $program, (@($images.Keys | Sort-Object -Unique) -join ", "))
    }

    $image = $images[$program]
    $sizeValue = Parse-Number (Get-CsvField $row "size") "size"
    if ($sizeValue -eq 0 -or $sizeValue -gt [uint64][int]::MaxValue) {
        throw "Manifest row '$name' has unsupported size $sizeValue."
    }
    $size = [int]$sizeValue
    $originalRva = Resolve-OriginalRva $row $image
    $maskText = (Get-CsvField $row "mask").Trim()
    $mask = Read-Mask $maskText $size
    $rowMaskedByteCount = Get-TrueCount $mask
    if ($rowMaskedByteCount -eq 0) {
        $masklessRowCount++
        continue
    }

    $maskedRowCount++
    $maskedByteCount += $rowMaskedByteCount
    $isFullFunctionMask = ($rowMaskedByteCount -eq $size)
    if ($isFullFunctionMask) {
        $fullFunctionMaskCount++
    }

    $functionBytes = Read-PeRange $image $originalRva $sizeValue
    $knownOperands = @(Get-KnownOperands $image $originalRva $functionBytes $mask)
    $maskRanges = @(Get-MaskRanges $mask)
    $rowIsValidated = -not $isFullFunctionMask

    foreach ($range in $maskRanges) {
        $rangeLength = [int]$range.Length
        $validated = New-Object bool[] $rangeLength
        $partial = New-Object bool[] $rangeLength
        $overlappingOperands = @()

        foreach ($operand in $knownOperands) {
            if ($operand.End -lt $range.Start -or $operand.Start -gt $range.End) {
                continue
            }

            $overlappingOperands += $operand
            $intersectionStart = [System.Math]::Max([int64]$range.Start, [int64]$operand.Start)
            $intersectionEnd = [System.Math]::Min([int64]$range.End, [int64]$operand.End)
            $operandFullyMasked = Test-OperandFullyMasked $operand $mask
            for ($offset = [int]$intersectionStart; $offset -le [int]$intersectionEnd; $offset++) {
                $rangeIndex = $offset - [int]$range.Start
                if ($operandFullyMasked) {
                    $validated[$rangeIndex] = $true
                }
                elseif (-not $validated[$rangeIndex]) {
                    $partial[$rangeIndex] = $true
                }
            }
        }

        $validatedByteCount = Get-TrueCount $validated
        $partialByteCount = 0
        $unexplainedByteCount = 0
        for ($rangeIndex = 0; $rangeIndex -lt $rangeLength; $rangeIndex++) {
            if ($validated[$rangeIndex]) {
                continue
            }
            if ($partial[$rangeIndex]) {
                $partialByteCount++
            }
            else {
                $unexplainedByteCount++
            }
        }

        $classification = "unexplained"
        $issue = "no_known_address_operand"
        if ($isFullFunctionMask) {
            # A full-function mask can never establish code identity, even if
            # some individual bytes happen to overlap recognized operands.
            $validatedByteCount = 0
            $partialByteCount = 0
            $unexplainedByteCount = $rangeLength
            $classification = "unexplained"
            $issue = "full_function_mask"
        }
        elseif ($validatedByteCount -eq $rangeLength) {
            $classification = "full_known_address_operand"
            $issue = ""
        }
        elseif (($validatedByteCount + $partialByteCount) -gt 0) {
            $classification = "partial_known_operand"
            if ($unexplainedByteCount -gt 0) {
                $issue = "known_operand_plus_unexplained_bytes"
            }
            else {
                $issue = "known_operand_not_fully_masked"
            }
        }

        if ($classification -ne "full_known_address_operand") {
            $rowIsValidated = $false
        }

        $operandKinds = @()
        $operandDescriptions = @()
        foreach ($operand in $overlappingOperands) {
            $kinds = Join-Unique @($operand.Kinds)
            $operandKinds += @($operand.Kinds)
            $description = "{0}-{1}:{2}" -f $operand.Start, $operand.End, $kinds
            if (-not [string]::IsNullOrWhiteSpace([string]$operand.TargetRva)) {
                $description += "->" + [string]$operand.TargetRva
            }
            $operandDescriptions += $description
        }

        [void]$results.Add([pscustomobject]@{
            name = $name
            program = $program
            original_rva = Format-OtHex $originalRva
            function_size = $size
            expected_status = (Get-CsvField $row "expected_status").Trim()
            implementation_kind = (Get-CsvField $row "implementation_kind").Trim()
            mask = $maskText
            range_start = [int]$range.Start
            range_end = [int]$range.End
            range_length = $rangeLength
            classification = $classification
            issue = $issue
            validated_bytes = $validatedByteCount
            partial_known_bytes = $partialByteCount
            unexplained_bytes = $unexplainedByteCount
            operand_count = $overlappingOperands.Count
            operand_kinds = Join-Unique $operandKinds
            operand_ranges = ($operandDescriptions -join ";")
            full_function_mask = $isFullFunctionMask
            notes = Get-CsvField $row "notes"
        })
    }

    if ($rowIsValidated) {
        $fullyValidatedRowCount++
    }
    else {
        $debtRowCount++
    }
}

$fullRanges = @($results | Where-Object { $_.classification -eq "full_known_address_operand" })
$partialRanges = @($results | Where-Object { $_.classification -eq "partial_known_operand" })
$unexplainedRanges = @($results | Where-Object { $_.classification -eq "unexplained" })
$validatedBytes = [int](($results | Measure-Object -Property validated_bytes -Sum).Sum)
$partialBytes = [int](($results | Measure-Object -Property partial_known_bytes -Sum).Sum)
$unexplainedBytes = [int](($results | Measure-Object -Property unexplained_bytes -Sum).Sum)

Write-Host "OTWIN manifest mask audit"
Write-Host ("  Manifest:                         {0}" -f $resolvedManifestPath)
Write-Host ("  Manifest rows:                    {0}" -f $rows.Count)
Write-Host ("  Masked / maskless rows:           {0} / {1}" -f $maskedRowCount, $masklessRowCount)
Write-Host ("  Masked ranges / bytes:            {0} / {1}" -f $results.Count, $maskedByteCount)
Write-Host ("  HIGHLOW fields (EXE / DLL):       {0} / {1}" -f
    $originalImage.Relocations.Count, $originalDllImage.Relocations.Count)
Write-Host ("  Fully validated rows:             {0}" -f $fullyValidatedRowCount)
Write-Host ("  Rows with mask debt:               {0}" -f $debtRowCount)
Write-Host ("  Full / partial / unexplained ranges: {0} / {1} / {2}" -f
    $fullRanges.Count, $partialRanges.Count, $unexplainedRanges.Count)
Write-Host ("  Validated / partial / unexplained bytes: {0} / {1} / {2}" -f
    $validatedBytes, $partialBytes, $unexplainedBytes)
Write-Host ("  Rejected full-function masks:      {0}" -f $fullFunctionMaskCount)

$representativeDebt = @($results |
    Where-Object { $_.classification -ne "full_known_address_operand" } |
    Sort-Object @{ Expression = { if ($_.issue -eq "full_function_mask") { 0 } elseif ($_.classification -eq "unexplained") { 1 } else { 2 } } },
        program, original_rva, range_start |
    Select-Object -First 12)
if ($representativeDebt.Count -gt 0) {
    Write-Host ""
    Write-Host "Representative mask debt:"
    $table = $representativeDebt |
        Select-Object name, program, original_rva,
            @{ Name = "range"; Expression = { "{0}-{1}" -f $_.range_start, $_.range_end } },
            classification, issue, operand_kinds |
        Format-Table -AutoSize | Out-String
    Write-Host $table.TrimEnd()
}

if (-not [string]::IsNullOrWhiteSpace($ResultsCsvPath)) {
    $resultFullPath = [System.IO.Path]::GetFullPath($ResultsCsvPath)
    $resultDirectory = [System.IO.Path]::GetDirectoryName($resultFullPath)
    if (-not [string]::IsNullOrWhiteSpace($resultDirectory) -and
        -not [System.IO.Directory]::Exists($resultDirectory)) {
        [void][System.IO.Directory]::CreateDirectory($resultDirectory)
    }

    @($results) | Export-Csv -LiteralPath $resultFullPath -NoTypeInformation -Encoding UTF8
    Write-Host ("  Results CSV:                      {0}" -f $resultFullPath)
}

if ($RequireValidated -and $debtRowCount -ne 0) {
    throw ("Mask validation failed: {0} row(s) contain partial, unexplained, or full-function masks." -f
        $debtRowCount)
}
