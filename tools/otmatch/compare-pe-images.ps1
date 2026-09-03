# Compares two Portable Executable images at the whole-file, PE-header,
# section, and import-order levels. A mismatch is expected while a recovered
# image is still under construction, so comparison differences only produce a
# non-zero exit code when -RequireExact is specified.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$OriginalPath,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$CandidatePath,

    [string]$ResultsCsvPath,

    [string]$ResultsJsonPath,

    [switch]$RequireExact
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Byte-by-byte loops over a multi-megabyte PE are prohibitively slow in
# PowerShell. Keep the parser in PowerShell, but use this small in-process
# helper for the two hot comparison loops.
if (-not ("OtwinPeByteComparison" -as [type])) {
    Add-Type -TypeDefinition @'
using System;

public static class OtwinPeByteComparison
{
    public static long DifferenceCount(
        byte[] left,
        int leftOffset,
        int leftCount,
        byte[] right,
        int rightOffset,
        int rightCount)
    {
        int common = Math.Min(leftCount, rightCount);
        long differences = Math.Abs((long)leftCount - (long)rightCount);
        for (int i = 0; i < common; ++i)
        {
            if (left[leftOffset + i] != right[rightOffset + i])
            {
                ++differences;
            }
        }
        return differences;
    }
}
'@
}

function Assert-ByteRange {
    param(
        [byte[]]$Bytes,
        [long]$Offset,
        [long]$Count,
        [string]$Description
    )

    if ($Offset -lt 0 -or $Count -lt 0 -or $Offset -gt $Bytes.LongLength -or
        $Count -gt ($Bytes.LongLength - $Offset)) {
        throw ("{0} is outside the file (offset=0x{1:x}, size=0x{2:x}, file size=0x{3:x})." -f
            $Description, $Offset, $Count, $Bytes.LongLength)
    }
}

function Read-U16 {
    param([byte[]]$Bytes, [int]$Offset)
    Assert-ByteRange $Bytes $Offset 2 "16-bit field"
    return [uint16](([uint16]$Bytes[$Offset]) -bor
        (([uint16]$Bytes[$Offset + 1]) -shl 8))
}

function Read-U32 {
    param([byte[]]$Bytes, [int]$Offset)
    Assert-ByteRange $Bytes $Offset 4 "32-bit field"
    return [uint32](([uint64]$Bytes[$Offset]) -bor
        (([uint64]$Bytes[$Offset + 1]) -shl 8) -bor
        (([uint64]$Bytes[$Offset + 2]) -shl 16) -bor
        (([uint64]$Bytes[$Offset + 3]) -shl 24))
}

function Read-U64 {
    param([byte[]]$Bytes, [int]$Offset)
    Assert-ByteRange $Bytes $Offset 8 "64-bit field"
    [uint64]$value = 0
    for ($i = 0; $i -lt 8; ++$i) {
        $value = $value -bor (([uint64]$Bytes[$Offset + $i]) -shl (8 * $i))
    }
    return $value
}

function Read-CString {
    param([byte[]]$Bytes, [int]$Offset, [string]$Description)
    Assert-ByteRange $Bytes $Offset 1 $Description
    $end = $Offset
    while ($end -lt $Bytes.Length -and $Bytes[$end] -ne 0) {
        ++$end
    }
    if ($end -ge $Bytes.Length) {
        throw ("Unterminated {0} at file offset 0x{1:x}." -f $Description, $Offset)
    }
    return [System.Text.Encoding]::ASCII.GetString($Bytes, $Offset, $end - $Offset)
}

function Get-Sha256Hex {
    param(
        [byte[]]$Bytes,
        [int]$Offset,
        [int]$Count
    )

    Assert-ByteRange $Bytes $Offset $Count "SHA-256 input"
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($Bytes, $Offset, $Count)
        return ([System.BitConverter]::ToString($hash)).Replace("-", "").ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Get-MatchPercent {
    param(
        [long]$ComparedBytes,
        [long]$DifferenceCount
    )

    if ($ComparedBytes -eq 0) {
        return [double]100.0
    }

    [long]$matchingBytes = $ComparedBytes - $DifferenceCount
    return [Math]::Round((100.0 * [double]$matchingBytes) / [double]$ComparedBytes, 6)
}

function Get-MachineName {
    param([uint16]$Machine)
    switch ($Machine) {
        0x014c { return "i386" }
        0x01c0 { return "ARM" }
        0x01c4 { return "ARMv7" }
        0x01f0 { return "PowerPC" }
        0x0200 { return "IA64" }
        0x8664 { return "AMD64" }
        0xaa64 { return "ARM64" }
        default { return "unknown" }
    }
}

function Get-SubsystemName {
    param([uint16]$Subsystem)
    switch ($Subsystem) {
        0  { return "unknown" }
        1  { return "native" }
        2  { return "Windows GUI" }
        3  { return "Windows console" }
        5  { return "OS/2 console" }
        7  { return "POSIX console" }
        9  { return "Windows CE GUI" }
        10 { return "EFI application" }
        11 { return "EFI boot service driver" }
        12 { return "EFI runtime driver" }
        13 { return "EFI ROM" }
        14 { return "Xbox" }
        16 { return "Windows boot application" }
        default { return "unknown" }
    }
}

function Convert-TimeDateStampToUtc {
    param([uint32]$TimeDateStamp)
    $epoch = [datetime]"1970-01-01T00:00:00Z"
    return $epoch.AddSeconds([double]$TimeDateStamp).ToUniversalTime().ToString("o")
}

function Convert-RvaToFileOffset {
    param(
        $Pe,
        [uint64]$Rva,
        [int]$RequiredSize
    )

    if ($Rva -lt [uint64]$Pe.Header.SizeOfHeaders) {
        if ($Rva -le [uint64]$Pe.Bytes.LongLength -and
            $RequiredSize -le ($Pe.Bytes.LongLength - [long]$Rva)) {
            return [int]$Rva
        }
        return -1
    }

    foreach ($section in $Pe.Sections) {
        [uint64]$mappedSize = [Math]::Max([uint64]$section.VirtualSize, [uint64]$section.RawSize)
        if ($Rva -ge [uint64]$section.Rva -and $Rva -lt ([uint64]$section.Rva + $mappedSize)) {
            [uint64]$delta = $Rva - [uint64]$section.Rva
            if ($delta -gt [uint64]$section.RawSize -or
                [uint64]$RequiredSize -gt ([uint64]$section.RawSize - $delta)) {
                return -1
            }
            [uint64]$fileOffset = [uint64]$section.RawOffset + $delta
            if ($fileOffset -gt [uint64][int]::MaxValue) {
                return -1
            }
            return [int]$fileOffset
        }
    }
    return -1
}

function Get-PeImports {
    param($Pe)

    $imports = @()
    if ([uint64]$Pe.Header.ImportDirectoryRva -eq 0) {
        return $imports
    }

    $descriptorOffset = Convert-RvaToFileOffset $Pe ([uint64]$Pe.Header.ImportDirectoryRva) 20
    if ($descriptorOffset -lt 0) {
        throw ("Import directory RVA 0x{0:x8} is not backed by file data." -f
            [uint64]$Pe.Header.ImportDirectoryRva)
    }

    $maxDescriptors = 4096
    if ([uint64]$Pe.Header.ImportDirectorySize -gt 0) {
        $declaredDescriptors = [int][Math]::Ceiling(
            ([double][uint64]$Pe.Header.ImportDirectorySize) / 20.0)
        $maxDescriptors = [Math]::Min($maxDescriptors, $declaredDescriptors + 1)
    }

    for ($dllIndex = 0; $dllIndex -lt $maxDescriptors; ++$dllIndex) {
        $offset = $descriptorOffset + ($dllIndex * 20)
        Assert-ByteRange $Pe.Bytes $offset 20 "import descriptor"

        [uint64]$originalFirstThunk = Read-U32 $Pe.Bytes $offset
        [uint32]$timeDateStamp = Read-U32 $Pe.Bytes ($offset + 4)
        [uint32]$forwarderChain = Read-U32 $Pe.Bytes ($offset + 8)
        [uint64]$nameRva = Read-U32 $Pe.Bytes ($offset + 12)
        [uint64]$firstThunk = Read-U32 $Pe.Bytes ($offset + 16)

        if ($originalFirstThunk -eq 0 -and $timeDateStamp -eq 0 -and
            $forwarderChain -eq 0 -and $nameRva -eq 0 -and $firstThunk -eq 0) {
            return $imports
        }

        $nameOffset = Convert-RvaToFileOffset $Pe $nameRva 1
        if ($nameOffset -lt 0) {
            throw ("Import DLL name RVA 0x{0:x8} is not backed by file data." -f $nameRva)
        }
        $dllName = Read-CString $Pe.Bytes $nameOffset "import DLL name"

        [uint64]$thunkRva = $originalFirstThunk
        if ($thunkRva -eq 0) {
            $thunkRva = $firstThunk
        }

        $thunkSize = 4
        [uint64]$ordinalMask = 2147483648
        if ($Pe.Header.PeFormat -eq "PE32+") {
            $thunkSize = 8
            $ordinalMask = [uint64]::Parse(
                "8000000000000000",
                [System.Globalization.NumberStyles]::HexNumber)
        }

        $functions = @()
        for ($functionIndex = 0; $functionIndex -lt 65536; ++$functionIndex) {
            $thunkOffset = Convert-RvaToFileOffset $Pe ($thunkRva + [uint64]($functionIndex * $thunkSize)) $thunkSize
            if ($thunkOffset -lt 0) {
                throw ("Import thunk {0}:{1} is not backed by file data." -f $dllIndex, $functionIndex)
            }

            [uint64]$thunk = 0
            if ($thunkSize -eq 4) {
                $thunk = Read-U32 $Pe.Bytes $thunkOffset
            }
            else {
                $thunk = Read-U64 $Pe.Bytes $thunkOffset
            }
            if ($thunk -eq 0) {
                break
            }

            $byOrdinal = (($thunk -band $ordinalMask) -ne 0)
            if ($byOrdinal) {
                $ordinal = [int]($thunk -band 0xffff)
                $functions += [pscustomobject]@{
                    Index = $functionIndex
                    Name = "#$ordinal"
                    ByOrdinal = $true
                    Ordinal = $ordinal
                    Hint = $null
                }
            }
            else {
                [uint64]$nameTableRva = $thunk
                $functionNameOffset = Convert-RvaToFileOffset $Pe $nameTableRva 3
                if ($functionNameOffset -lt 0) {
                    throw ("Import name RVA 0x{0:x8} is not backed by file data." -f $nameTableRva)
                }
                $hint = Read-U16 $Pe.Bytes $functionNameOffset
                $functionName = Read-CString $Pe.Bytes ($functionNameOffset + 2) "import function name"
                $functions += [pscustomobject]@{
                    Index = $functionIndex
                    Name = $functionName
                    ByOrdinal = $false
                    Ordinal = $null
                    Hint = $hint
                }
            }
        }

        $imports += [pscustomobject]@{
            Index = $dllIndex
            Name = $dllName
            Functions = $functions
        }
    }

    throw "Import descriptor table did not contain a terminator."
}

function Get-PeInfo {
    param([string]$Path)

    $resolved = (Resolve-Path -LiteralPath $Path).Path
    $bytes = [System.IO.File]::ReadAllBytes($resolved)
    Assert-ByteRange $bytes 0 64 "DOS header"
    if ((Read-U16 $bytes 0) -ne 0x5a4d) {
        throw "'$resolved' does not have an MZ header."
    }

    $peOffset = [int](Read-U32 $bytes 0x3c)
    Assert-ByteRange $bytes $peOffset 24 "PE signature and COFF header"
    if ((Read-U32 $bytes $peOffset) -ne 0x00004550) {
        throw "'$resolved' does not have a PE signature at e_lfanew."
    }

    $coff = $peOffset + 4
    $machine = Read-U16 $bytes $coff
    $numberOfSections = [int](Read-U16 $bytes ($coff + 2))
    $timeDateStamp = Read-U32 $bytes ($coff + 4)
    $sizeOfOptionalHeader = [int](Read-U16 $bytes ($coff + 16))
    $characteristics = Read-U16 $bytes ($coff + 18)
    $optional = $coff + 20
    Assert-ByteRange $bytes $optional $sizeOfOptionalHeader "PE optional header"

    $magic = Read-U16 $bytes $optional
    $peFormat = $null
    if ($magic -eq 0x010b) {
        $peFormat = "PE32"
        if ($sizeOfOptionalHeader -lt 96) {
            throw "'$resolved' has a truncated PE32 optional header."
        }
        [uint64]$imageBase = Read-U32 $bytes ($optional + 28)
        [uint64]$stackReserve = Read-U32 $bytes ($optional + 72)
        [uint64]$stackCommit = Read-U32 $bytes ($optional + 76)
        [uint64]$heapReserve = Read-U32 $bytes ($optional + 80)
        [uint64]$heapCommit = Read-U32 $bytes ($optional + 84)
        $numberOfRvaAndSizes = Read-U32 $bytes ($optional + 92)
        $dataDirectoryOffset = $optional + 96
    }
    elseif ($magic -eq 0x020b) {
        $peFormat = "PE32+"
        if ($sizeOfOptionalHeader -lt 112) {
            throw "'$resolved' has a truncated PE32+ optional header."
        }
        [uint64]$imageBase = Read-U64 $bytes ($optional + 24)
        [uint64]$stackReserve = Read-U64 $bytes ($optional + 72)
        [uint64]$stackCommit = Read-U64 $bytes ($optional + 80)
        [uint64]$heapReserve = Read-U64 $bytes ($optional + 88)
        [uint64]$heapCommit = Read-U64 $bytes ($optional + 96)
        $numberOfRvaAndSizes = Read-U32 $bytes ($optional + 108)
        $dataDirectoryOffset = $optional + 112
    }
    else {
        throw ("'$resolved' has unsupported optional-header magic 0x{0:x4}." -f $magic)
    }

    $imageKind = "image"
    if (($characteristics -band 0x2000) -ne 0) {
        $imageKind = "DLL"
    }
    elseif (($characteristics -band 0x0002) -ne 0) {
        $imageKind = "EXE"
    }

    [uint64]$importDirectoryRva = 0
    [uint64]$importDirectorySize = 0
    if ($numberOfRvaAndSizes -gt 1 -and
        ($dataDirectoryOffset + 16) -le ($optional + $sizeOfOptionalHeader)) {
        $importDirectoryRva = Read-U32 $bytes ($dataDirectoryOffset + 8)
        $importDirectorySize = Read-U32 $bytes ($dataDirectoryOffset + 12)
    }

    $header = [pscustomobject]@{
        PeFormat = $peFormat
        ImageKind = $imageKind
        PeKind = "$peFormat $imageKind"
        Machine = $machine
        MachineName = Get-MachineName $machine
        NumberOfSections = $numberOfSections
        TimeDateStamp = $timeDateStamp
        TimeDateStampUtc = Convert-TimeDateStampToUtc $timeDateStamp
        Characteristics = $characteristics
        AddressOfEntryPoint = Read-U32 $bytes ($optional + 16)
        ImageBase = $imageBase
        SectionAlignment = Read-U32 $bytes ($optional + 32)
        FileAlignment = Read-U32 $bytes ($optional + 36)
        SizeOfImage = Read-U32 $bytes ($optional + 56)
        SizeOfHeaders = Read-U32 $bytes ($optional + 60)
        Subsystem = Read-U16 $bytes ($optional + 68)
        SubsystemName = Get-SubsystemName (Read-U16 $bytes ($optional + 68))
        StackReserve = $stackReserve
        StackCommit = $stackCommit
        HeapReserve = $heapReserve
        HeapCommit = $heapCommit
        ImportDirectoryRva = $importDirectoryRva
        ImportDirectorySize = $importDirectorySize
    }

    $sectionTable = $optional + $sizeOfOptionalHeader
    Assert-ByteRange $bytes $sectionTable ($numberOfSections * 40) "PE section table"
    $sections = @()
    for ($i = 0; $i -lt $numberOfSections; ++$i) {
        $sectionOffset = $sectionTable + ($i * 40)
        $name = [System.Text.Encoding]::ASCII.GetString($bytes, $sectionOffset, 8).TrimEnd([char]0)
        $virtualSize = Read-U32 $bytes ($sectionOffset + 8)
        $rva = Read-U32 $bytes ($sectionOffset + 12)
        $rawSize = Read-U32 $bytes ($sectionOffset + 16)
        $rawOffset = Read-U32 $bytes ($sectionOffset + 20)
        $sectionCharacteristics = Read-U32 $bytes ($sectionOffset + 36)
        if ($rawSize -gt [int]::MaxValue -or $rawOffset -gt [int]::MaxValue) {
            throw "'$resolved' has a section too large for this in-memory comparator."
        }
        Assert-ByteRange $bytes $rawOffset $rawSize "raw data for section '$name'"

        $sections += [pscustomobject]@{
            Index = $i
            Name = $name
            Rva = $rva
            VirtualSize = $virtualSize
            RawOffset = $rawOffset
            RawSize = $rawSize
            Characteristics = $sectionCharacteristics
            Sha256 = Get-Sha256Hex $bytes ([int]$rawOffset) ([int]$rawSize)
        }
    }

    $pe = [pscustomobject]@{
        Path = $resolved
        FileSize = [long]$bytes.LongLength
        Sha256 = Get-Sha256Hex $bytes 0 $bytes.Length
        Header = $header
        Sections = $sections
        Imports = @()
        ImportParseError = $null
        Bytes = $bytes
    }

    try {
        $pe.Imports = @(Get-PeImports $pe)
    }
    catch {
        $pe.ImportParseError = $_.Exception.Message
    }
    return $pe
}

function Get-PublicPeInfo {
    param($Pe)
    return [pscustomobject]@{
        Path = $Pe.Path
        FileSize = $Pe.FileSize
        Sha256 = $Pe.Sha256
        Header = $Pe.Header
        Sections = $Pe.Sections
        Imports = $Pe.Imports
        ImportParseError = $Pe.ImportParseError
    }
}

function New-HeaderComparisons {
    param($Original, $Candidate)
    $fieldNames = @(
        "PeKind",
        "Machine",
        "MachineName",
        "NumberOfSections",
        "TimeDateStamp",
        "TimeDateStampUtc",
        "Characteristics",
        "AddressOfEntryPoint",
        "ImageBase",
        "SectionAlignment",
        "FileAlignment",
        "SizeOfImage",
        "SizeOfHeaders",
        "Subsystem",
        "SubsystemName",
        "StackReserve",
        "StackCommit",
        "HeapReserve",
        "HeapCommit"
    )

    $comparisons = @()
    foreach ($fieldName in $fieldNames) {
        $originalValue = $Original.Header.$fieldName
        $candidateValue = $Candidate.Header.$fieldName
        $comparisons += [pscustomobject]@{
            Field = $fieldName
            Original = $originalValue
            Candidate = $candidateValue
            Equal = ($originalValue -ceq $candidateValue)
        }
    }
    return $comparisons
}

function New-SectionComparisons {
    param($Original, $Candidate)
    $comparisons = @()
    $count = [Math]::Max($Original.Sections.Count, $Candidate.Sections.Count)
    for ($i = 0; $i -lt $count; ++$i) {
        $originalSection = $null
        $candidateSection = $null
        if ($i -lt $Original.Sections.Count) {
            $originalSection = $Original.Sections[$i]
        }
        if ($i -lt $Candidate.Sections.Count) {
            $candidateSection = $Candidate.Sections[$i]
        }

        [long]$differenceCount = 0
        [long]$commonBytes = 0
        [long]$comparedBytes = 0
        $rawEqual = $false
        if ($null -ne $originalSection -and $null -ne $candidateSection) {
            $commonBytes = [Math]::Min([long]$originalSection.RawSize, [long]$candidateSection.RawSize)
            $comparedBytes = [Math]::Max([long]$originalSection.RawSize, [long]$candidateSection.RawSize)
            $differenceCount = [OtwinPeByteComparison]::DifferenceCount(
                $Original.Bytes,
                [int]$originalSection.RawOffset,
                [int]$originalSection.RawSize,
                $Candidate.Bytes,
                [int]$candidateSection.RawOffset,
                [int]$candidateSection.RawSize)
            $rawEqual = ($differenceCount -eq 0 -and
                [long]$originalSection.RawSize -eq [long]$candidateSection.RawSize)
        }
        elseif ($null -ne $originalSection) {
            $comparedBytes = [long]$originalSection.RawSize
            $differenceCount = $comparedBytes
        }
        elseif ($null -ne $candidateSection) {
            $comparedBytes = [long]$candidateSection.RawSize
            $differenceCount = $comparedBytes
        }

        $headerEqual = ($null -ne $originalSection -and $null -ne $candidateSection -and
            $originalSection.Name -ceq $candidateSection.Name -and
            $originalSection.Rva -eq $candidateSection.Rva -and
            $originalSection.VirtualSize -eq $candidateSection.VirtualSize -and
            $originalSection.RawOffset -eq $candidateSection.RawOffset -and
            $originalSection.RawSize -eq $candidateSection.RawSize -and
            $originalSection.Characteristics -eq $candidateSection.Characteristics)

        $comparisons += [pscustomobject]@{
            Index = $i
            Original = $originalSection
            Candidate = $candidateSection
            HeaderEqual = $headerEqual
            RawEqual = $rawEqual
            Equal = ($headerEqual -and $rawEqual)
            CommonBytes = $commonBytes
            ComparedBytes = $comparedBytes
            DifferenceCount = $differenceCount
            MatchingBytes = $comparedBytes - $differenceCount
            MatchPercent = Get-MatchPercent $comparedBytes $differenceCount
        }
    }
    return $comparisons
}

function New-ImportComparisons {
    param($Original, $Candidate)
    $dllComparisons = @()
    $dllCount = [Math]::Max($Original.Imports.Count, $Candidate.Imports.Count)
    for ($dllIndex = 0; $dllIndex -lt $dllCount; ++$dllIndex) {
        $originalDll = $null
        $candidateDll = $null
        if ($dllIndex -lt $Original.Imports.Count) {
            $originalDll = $Original.Imports[$dllIndex]
        }
        if ($dllIndex -lt $Candidate.Imports.Count) {
            $candidateDll = $Candidate.Imports[$dllIndex]
        }

        $functionComparisons = @()
        $originalFunctionCount = 0
        $candidateFunctionCount = 0
        if ($null -ne $originalDll) {
            $originalFunctionCount = $originalDll.Functions.Count
        }
        if ($null -ne $candidateDll) {
            $candidateFunctionCount = $candidateDll.Functions.Count
        }
        $functionCount = [Math]::Max($originalFunctionCount, $candidateFunctionCount)
        for ($functionIndex = 0; $functionIndex -lt $functionCount; ++$functionIndex) {
            $originalFunction = $null
            $candidateFunction = $null
            if ($null -ne $originalDll -and $functionIndex -lt $originalFunctionCount) {
                $originalFunction = $originalDll.Functions[$functionIndex]
            }
            if ($null -ne $candidateDll -and $functionIndex -lt $candidateFunctionCount) {
                $candidateFunction = $candidateDll.Functions[$functionIndex]
            }
            $functionEqual = ($null -ne $originalFunction -and $null -ne $candidateFunction -and
                $originalFunction.Name -ceq $candidateFunction.Name -and
                $originalFunction.ByOrdinal -eq $candidateFunction.ByOrdinal -and
                $originalFunction.Ordinal -eq $candidateFunction.Ordinal -and
                $originalFunction.Hint -eq $candidateFunction.Hint)
            $functionComparisons += [pscustomobject]@{
                Index = $functionIndex
                Original = $originalFunction
                Candidate = $candidateFunction
                Equal = $functionEqual
            }
        }

        $nameEqual = ($null -ne $originalDll -and $null -ne $candidateDll -and
            $originalDll.Name -ceq $candidateDll.Name)
        $functionsEqual = ($originalFunctionCount -eq $candidateFunctionCount -and
            @($functionComparisons | Where-Object { -not $_.Equal }).Count -eq 0)
        $dllComparisons += [pscustomobject]@{
            Index = $dllIndex
            Original = $originalDll
            Candidate = $candidateDll
            NameEqual = $nameEqual
            FunctionsEqual = $functionsEqual
            Equal = ($nameEqual -and $functionsEqual)
            Functions = $functionComparisons
        }
    }
    return $dllComparisons
}

function Format-HeaderValue {
    param([string]$Field, $Value)
    if ($null -eq $Value) {
        return "<missing>"
    }
    if ($Field -in @(
        "Machine", "Characteristics", "AddressOfEntryPoint", "ImageBase",
        "SectionAlignment", "FileAlignment", "SizeOfImage", "SizeOfHeaders",
        "Subsystem", "StackReserve", "StackCommit", "HeapReserve", "HeapCommit")) {
        return ("0x{0:x}" -f [uint64]$Value)
    }
    return [string]$Value
}

function Write-ImportList {
    param([string]$Label, $Pe)
    Write-Host "$Label imports (DLL and function order):" -ForegroundColor Cyan
    if ($null -ne $Pe.ImportParseError) {
        Write-Host ("  unavailable: {0}" -f $Pe.ImportParseError) -ForegroundColor Yellow
        return
    }
    if ($Pe.Imports.Count -eq 0) {
        Write-Host "  <none>"
        return
    }
    foreach ($dll in $Pe.Imports) {
        Write-Host ("  [{0}] {1}" -f $dll.Index, $dll.Name)
        foreach ($function in $dll.Functions) {
            Write-Host ("      [{0}] {1}" -f $function.Index, $function.Name)
        }
    }
}

function Get-CsvRows {
    param($Comparison)
    $rows = @()
    $rows += [pscustomobject]@{
        RecordType = "WholeFile"
        Index = $null
        ParentIndex = $null
        Field = "FileSize"
        OriginalValue = $Comparison.WholeFile.OriginalSize
        CandidateValue = $Comparison.WholeFile.CandidateSize
        Equal = $Comparison.WholeFile.Equal
        OriginalName = $null
        CandidateName = $null
        OriginalRva = $null
        CandidateRva = $null
        OriginalVirtualSize = $null
        CandidateVirtualSize = $null
        OriginalRawOffset = $null
        CandidateRawOffset = $null
        OriginalRawSize = $null
        CandidateRawSize = $null
        OriginalSha256 = $Comparison.WholeFile.OriginalSha256
        CandidateSha256 = $Comparison.WholeFile.CandidateSha256
        CommonBytes = $Comparison.WholeFile.CommonBytes
        ComparedBytes = $Comparison.WholeFile.ComparedBytes
        DifferenceCount = $Comparison.WholeFile.DifferenceCount
        MatchingBytes = $Comparison.WholeFile.MatchingBytes
        MatchPercent = $Comparison.WholeFile.MatchPercent
    }
    foreach ($header in $Comparison.Headers) {
        $rows += [pscustomobject]@{
            RecordType = "Header"
            Index = $null
            ParentIndex = $null
            Field = $header.Field
            OriginalValue = $header.Original
            CandidateValue = $header.Candidate
            Equal = $header.Equal
            OriginalName = $null
            CandidateName = $null
            OriginalRva = $null
            CandidateRva = $null
            OriginalVirtualSize = $null
            CandidateVirtualSize = $null
            OriginalRawOffset = $null
            CandidateRawOffset = $null
            OriginalRawSize = $null
            CandidateRawSize = $null
            OriginalSha256 = $null
            CandidateSha256 = $null
            CommonBytes = $null
            ComparedBytes = $null
            DifferenceCount = $null
            MatchingBytes = $null
            MatchPercent = $null
        }
    }
    foreach ($section in $Comparison.Sections) {
        $rows += [pscustomobject]@{
            RecordType = "Section"
            Index = $section.Index
            ParentIndex = $null
            Field = "Section"
            OriginalValue = $null
            CandidateValue = $null
            Equal = $section.Equal
            OriginalName = $(if ($null -ne $section.Original) { $section.Original.Name } else { $null })
            CandidateName = $(if ($null -ne $section.Candidate) { $section.Candidate.Name } else { $null })
            OriginalRva = $(if ($null -ne $section.Original) { $section.Original.Rva } else { $null })
            CandidateRva = $(if ($null -ne $section.Candidate) { $section.Candidate.Rva } else { $null })
            OriginalVirtualSize = $(if ($null -ne $section.Original) { $section.Original.VirtualSize } else { $null })
            CandidateVirtualSize = $(if ($null -ne $section.Candidate) { $section.Candidate.VirtualSize } else { $null })
            OriginalRawOffset = $(if ($null -ne $section.Original) { $section.Original.RawOffset } else { $null })
            CandidateRawOffset = $(if ($null -ne $section.Candidate) { $section.Candidate.RawOffset } else { $null })
            OriginalRawSize = $(if ($null -ne $section.Original) { $section.Original.RawSize } else { $null })
            CandidateRawSize = $(if ($null -ne $section.Candidate) { $section.Candidate.RawSize } else { $null })
            OriginalSha256 = $(if ($null -ne $section.Original) { $section.Original.Sha256 } else { $null })
            CandidateSha256 = $(if ($null -ne $section.Candidate) { $section.Candidate.Sha256 } else { $null })
            CommonBytes = $section.CommonBytes
            ComparedBytes = $section.ComparedBytes
            DifferenceCount = $section.DifferenceCount
            MatchingBytes = $section.MatchingBytes
            MatchPercent = $section.MatchPercent
        }
    }
    $rows += [pscustomobject]@{
        RecordType = "ImportStatus"
        Index = $null
        ParentIndex = $null
        Field = "ImportParseError"
        OriginalValue = $Comparison.Imports.OriginalParseError
        CandidateValue = $Comparison.Imports.CandidateParseError
        Equal = $Comparison.Imports.Equal
        OriginalName = $null
        CandidateName = $null
        OriginalRva = $null
        CandidateRva = $null
        OriginalVirtualSize = $null
        CandidateVirtualSize = $null
        OriginalRawOffset = $null
        CandidateRawOffset = $null
        OriginalRawSize = $null
        CandidateRawSize = $null
        OriginalSha256 = $null
        CandidateSha256 = $null
        CommonBytes = $null
        ComparedBytes = $null
        DifferenceCount = $null
        MatchingBytes = $null
        MatchPercent = $null
    }
    foreach ($dll in $Comparison.Imports.Dlls) {
        $rows += [pscustomobject]@{
            RecordType = "ImportDll"
            Index = $dll.Index
            ParentIndex = $null
            Field = "ImportDll"
            OriginalValue = $null
            CandidateValue = $null
            Equal = $dll.Equal
            OriginalName = $(if ($null -ne $dll.Original) { $dll.Original.Name } else { $null })
            CandidateName = $(if ($null -ne $dll.Candidate) { $dll.Candidate.Name } else { $null })
            OriginalRva = $null
            CandidateRva = $null
            OriginalVirtualSize = $null
            CandidateVirtualSize = $null
            OriginalRawOffset = $null
            CandidateRawOffset = $null
            OriginalRawSize = $null
            CandidateRawSize = $null
            OriginalSha256 = $null
            CandidateSha256 = $null
            CommonBytes = $null
            ComparedBytes = $null
            DifferenceCount = $null
            MatchingBytes = $null
            MatchPercent = $null
        }
        foreach ($function in $dll.Functions) {
            $rows += [pscustomobject]@{
                RecordType = "ImportFunction"
                Index = $function.Index
                ParentIndex = $dll.Index
                Field = "ImportFunction"
                OriginalValue = $null
                CandidateValue = $null
                Equal = $function.Equal
                OriginalName = $(if ($null -ne $function.Original) { $function.Original.Name } else { $null })
                CandidateName = $(if ($null -ne $function.Candidate) { $function.Candidate.Name } else { $null })
                OriginalRva = $null
                CandidateRva = $null
                OriginalVirtualSize = $null
                CandidateVirtualSize = $null
                OriginalRawOffset = $null
                CandidateRawOffset = $null
                OriginalRawSize = $null
                CandidateRawSize = $null
                OriginalSha256 = $null
                CandidateSha256 = $null
                CommonBytes = $null
                ComparedBytes = $null
                DifferenceCount = $null
                MatchingBytes = $null
                MatchPercent = $null
            }
        }
    }
    return $rows
}

function Resolve-OutputPath {
    param([string]$Path)
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $directory = [System.IO.Path]::GetDirectoryName($fullPath)
    if (-not [string]::IsNullOrEmpty($directory)) {
        [void][System.IO.Directory]::CreateDirectory($directory)
    }
    return $fullPath
}

$original = Get-PeInfo $OriginalPath
$candidate = Get-PeInfo $CandidatePath

[long]$wholeDifferenceCount = [OtwinPeByteComparison]::DifferenceCount(
    $original.Bytes, 0, $original.Bytes.Length,
    $candidate.Bytes, 0, $candidate.Bytes.Length)
[long]$wholeCommonBytes = [Math]::Min($original.FileSize, $candidate.FileSize)
[long]$wholeComparedBytes = [Math]::Max($original.FileSize, $candidate.FileSize)
$wholeMatchingBytes = $wholeComparedBytes - $wholeDifferenceCount
$wholeMatchPercent = Get-MatchPercent $wholeComparedBytes $wholeDifferenceCount
$wholeEqual = ($wholeDifferenceCount -eq 0 -and $original.FileSize -eq $candidate.FileSize)

$headerComparisons = @(New-HeaderComparisons $original $candidate)
$sectionComparisons = @(New-SectionComparisons $original $candidate)
$importComparisons = @(New-ImportComparisons $original $candidate)
$importsEqual = ($null -eq $original.ImportParseError -and
    $null -eq $candidate.ImportParseError -and
    $original.Imports.Count -eq $candidate.Imports.Count -and
    @($importComparisons | Where-Object { -not $_.Equal }).Count -eq 0)

$comparison = [pscustomobject]@{
    SchemaVersion = 1
    GeneratedAtUtc = [datetime]::UtcNow.ToString("o")
    Original = Get-PublicPeInfo $original
    Candidate = Get-PublicPeInfo $candidate
    WholeFile = [pscustomobject]@{
        OriginalSize = $original.FileSize
        CandidateSize = $candidate.FileSize
        OriginalSha256 = $original.Sha256
        CandidateSha256 = $candidate.Sha256
        Sha256Equal = ($original.Sha256 -ceq $candidate.Sha256)
        CommonBytes = $wholeCommonBytes
        ComparedBytes = $wholeComparedBytes
        DifferenceCount = $wholeDifferenceCount
        MatchingBytes = $wholeMatchingBytes
        MatchPercent = $wholeMatchPercent
        Equal = $wholeEqual
    }
    Headers = $headerComparisons
    Sections = $sectionComparisons
    Imports = [pscustomobject]@{
        Equal = $importsEqual
        OriginalParseError = $original.ImportParseError
        CandidateParseError = $candidate.ImportParseError
        Dlls = $importComparisons
    }
    Exact = $wholeEqual
}

Write-Host "=== Whole PE image comparison ===" -ForegroundColor Cyan
Write-Host ("Original:  {0}" -f $original.Path)
Write-Host ("Candidate: {0}" -f $candidate.Path)
Write-Host ("Whole file: {0}" -f $(if ($wholeEqual) { "EXACT" } else { "DIFFERENT" })) `
    -ForegroundColor $(if ($wholeEqual) { "Green" } else { "Yellow" })
Write-Host ("  size:       {0} / {1}" -f $original.FileSize, $candidate.FileSize)
Write-Host ("  differences: {0}" -f $wholeDifferenceCount)
Write-Host ("  matching:    {0} / {1} bytes ({2:N6}%)" -f
    $wholeMatchingBytes, $wholeComparedBytes, $wholeMatchPercent)
Write-Host ("  SHA-256:    {0}" -f $original.Sha256)
Write-Host ("              {0}" -f $candidate.Sha256)

Write-Host "PE headers (original / candidate):" -ForegroundColor Cyan
foreach ($header in $headerComparisons) {
    $marker = if ($header.Equal) { "=" } else { "!" }
    Write-Host ("  {0} {1,-22} {2} / {3}" -f
        $marker,
        $header.Field,
        (Format-HeaderValue $header.Field $header.Original),
        (Format-HeaderValue $header.Field $header.Candidate))
}

Write-Host "Sections by table order (original / candidate):" -ForegroundColor Cyan
foreach ($section in $sectionComparisons) {
    $originalName = if ($null -ne $section.Original) { $section.Original.Name } else { "<missing>" }
    $candidateName = if ($null -ne $section.Candidate) { $section.Candidate.Name } else { "<missing>" }
    $originalRva = if ($null -ne $section.Original) { "0x{0:x8}" -f $section.Original.Rva } else { "-" }
    $candidateRva = if ($null -ne $section.Candidate) { "0x{0:x8}" -f $section.Candidate.Rva } else { "-" }
    $originalVirtual = if ($null -ne $section.Original) { $section.Original.VirtualSize } else { "-" }
    $candidateVirtual = if ($null -ne $section.Candidate) { $section.Candidate.VirtualSize } else { "-" }
    $originalRaw = if ($null -ne $section.Original) { $section.Original.RawSize } else { "-" }
    $candidateRaw = if ($null -ne $section.Candidate) { $section.Candidate.RawSize } else { "-" }
    Write-Host ("  [{0}] {1} / {2}  RVA {3} / {4}  virtual {5} / {6}  raw {7} / {8}  diff {9}  match {10:N6}%" -f
        $section.Index, $originalName, $candidateName, $originalRva, $candidateRva,
        $originalVirtual, $candidateVirtual, $originalRaw, $candidateRaw,
        $section.DifferenceCount, $section.MatchPercent)
    $originalHash = if ($null -ne $section.Original) { $section.Original.Sha256 } else { "-" }
    $candidateHash = if ($null -ne $section.Candidate) { $section.Candidate.Sha256 } else { "-" }
    Write-Host ("      SHA-256 {0}" -f $originalHash)
    Write-Host ("               {0}" -f $candidateHash)
}

Write-ImportList "Original" $original
Write-ImportList "Candidate" $candidate
Write-Host ("Import order equal: {0}" -f $importsEqual)

if (-not [string]::IsNullOrEmpty($ResultsJsonPath)) {
    $jsonPath = Resolve-OutputPath $ResultsJsonPath
    $json = $comparison | ConvertTo-Json -Depth 20
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($jsonPath, $json, $utf8NoBom)
    Write-Host ("JSON results: {0}" -f $jsonPath) -ForegroundColor Cyan
}

if (-not [string]::IsNullOrEmpty($ResultsCsvPath)) {
    $csvPath = Resolve-OutputPath $ResultsCsvPath
    @(Get-CsvRows $comparison) | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host ("CSV results:  {0}" -f $csvPath) -ForegroundColor Cyan
}

if ($RequireExact.IsPresent -and -not $wholeEqual) {
    Write-Host "Exact PE image match required, but the files differ." -ForegroundColor Red
    exit 1
}
