param(
    [Parameter(Mandatory = $true)]
    [string]$OriginalPath,

    [Parameter(Mandatory = $true)]
    [uint64]$OriginalRva,

    [Parameter(Mandatory = $true)]
    [int]$Size,

    [Parameter(Mandatory = $true)]
    [string]$CandidatePath,

    [Parameter(Mandatory = $true)]
    [string]$CandidateMapPath,

    [Parameter(Mandatory = $true)]
    [string]$CandidateSymbol,

    [string]$Mask = "",

    [switch]$DumpHex
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Read-U16([byte[]]$b, [int]$o) {
    return [uint16](([uint64]$b[$o]) -bor (([uint64]$b[$o+1]) -shl 8))
}

function Read-U32([byte[]]$b, [int]$o) {
    return [uint32](([uint64]$b[$o]) -bor (([uint64]$b[$o+1]) -shl 8) -bor (([uint64]$b[$o+2]) -shl 16) -bor (([uint64]$b[$o+3]) -shl 24))
}

function Get-PeImage([string]$Path) {
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $Path).Path)
    $peOff = [int](Read-U32 $bytes 0x3c)
    $coff = $peOff + 4
    $sectionCount = [int](Read-U16 $bytes ($coff + 2))
    $optHdrSize = [int](Read-U16 $bytes ($coff + 16))
    $optOff = $coff + 20
    $sectionTbl = $optOff + $optHdrSize
    $sections = @()
    for ($i = 0; $i -lt $sectionCount; $i++) {
        $so = $sectionTbl + ($i * 40)
        $sections += [pscustomobject]@{
            VirtualAddress = [uint64](Read-U32 $bytes ($so + 12))
            VirtualSize    = [uint64](Read-U32 $bytes ($so + 8))
            RawSize        = [uint64](Read-U32 $bytes ($so + 16))
            RawPointer     = [uint64](Read-U32 $bytes ($so + 20))
        }
    }
    return [pscustomobject]@{ Bytes = $bytes; Sections = $sections }
}

function Read-RvaBytes($Image, [uint64]$Rva, [int]$Count) {
    foreach ($s in $Image.Sections) {
        if ($Rva -ge $s.VirtualAddress -and $Rva -lt ($s.VirtualAddress + [System.Math]::Max($s.VirtualSize, $s.RawSize))) {
            $delta = $Rva - $s.VirtualAddress
            $fileOff = [int]($s.RawPointer + $delta)
            $out = New-Object byte[] $Count
            [System.Array]::Copy($Image.Bytes, $fileOff, $out, 0, $Count)
            return $out
        }
    }
    throw "RVA 0x$($Rva.ToString('x')) not in any section"
}

function Resolve-MapSymbolRva([string]$MapPath, [string]$Symbol) {
    $symbolExpression = $Symbol.Trim()
    if ($symbolExpression -notmatch '^(?<symbol>.+?)(?:\s*\+\s*(?<offset>0x[0-9a-fA-F]+|[0-9]+))?$') {
        throw "Invalid candidate symbol expression: $Symbol"
    }

    $baseSymbol = $Matches["symbol"].Trim()
    $offset = [uint64]0
    if ($Matches.ContainsKey("offset") -and -not [string]::IsNullOrWhiteSpace($Matches["offset"])) {
        $offsetText = $Matches["offset"]
        if ($offsetText.StartsWith("0x", [System.StringComparison]::OrdinalIgnoreCase)) {
            $offset = [uint64]::Parse($offsetText.Substring(2), [System.Globalization.NumberStyles]::HexNumber)
        } else {
            $offset = [uint64]::Parse($offsetText, [System.Globalization.NumberStyles]::Integer)
        }
    }

    $lines = Get-Content $MapPath
    foreach ($line in $lines) {
        if ($line -match '^\s*\d+:[0-9a-fA-F]+\s+(\S+)\s+([0-9a-fA-F]+)') {
            $sym = $matches[1]
            if ($sym -eq $baseSymbol) {
                $va = [uint64]::Parse($matches[2], [System.Globalization.NumberStyles]::HexNumber)
                # Candidate image base is 0x10000000 by default for /DLL builds
                return ($va - [uint64]0x10000000 + $offset)
            }
        }
    }
    throw "Symbol not found in map: $baseSymbol"
}

function Get-MaskedOffsets([string]$MaskText, [int]$ByteCount) {
    $masked = New-Object bool[] $ByteCount
    if ([string]::IsNullOrWhiteSpace($MaskText)) {
        return $masked
    }

    foreach ($part in @($MaskText -split '[;,\s]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
        $start = 0
        $end = 0
        if ($part -match '^(\d+)-(\d+)$') {
            $start = [int]$Matches[1]
            $end = [int]$Matches[2]
        } elseif ($part -match '^\d+$') {
            $start = [int]$part
            $end = $start
        } else {
            throw "Invalid mask component '$part'. Expected decimal offsets such as '12-15 41-44'."
        }
        if ($start -lt 0 -or $end -lt $start -or $end -ge $ByteCount) {
            throw "Mask component '$part' is outside the $ByteCount-byte comparison range."
        }
        for ($offset = $start; $offset -le $end; $offset++) {
            $masked[$offset] = $true
        }
    }
    return $masked
}

$origImg = Get-PeImage $OriginalPath
$candImg = Get-PeImage $CandidatePath
$candRva = Resolve-MapSymbolRva $CandidateMapPath $CandidateSymbol

$origBytes = Read-RvaBytes $origImg $OriginalRva $Size
$candBytes = Read-RvaBytes $candImg $candRva $Size
$maskedOffsets = Get-MaskedOffsets $Mask $Size

$diffs = @()
$hardDiffs = @()
$maskedByteCount = 0
for ($i = 0; $i -lt $Size; $i++) {
    if ($maskedOffsets[$i]) {
        $maskedByteCount++
    }
    if ($origBytes[$i] -ne $candBytes[$i]) {
        $diffs += $i
        if (-not $maskedOffsets[$i]) {
            $hardDiffs += $i
        }
    }
}

Write-Host ("Original RVA:  0x{0:x8}" -f $OriginalRva)
Write-Host ("Candidate RVA: 0x{0:x8}" -f $candRva)
Write-Host ("Size:          {0} bytes" -f $Size)
Write-Host ("Differences:   {0} / {1}" -f $diffs.Count, $Size)
Write-Host ("Masked bytes:  {0}" -f $maskedByteCount)
Write-Host ("Hard differences: {0} / {1}" -f $hardDiffs.Count, ($Size - $maskedByteCount))

if ($DumpHex) {
    Write-Host ""
    Write-Host "Original:"
    for ($i = 0; $i -lt $Size; $i += 16) {
        $line = ("  {0:x4}:" -f $i)
        for ($j = 0; $j -lt 16 -and ($i + $j) -lt $Size; $j++) {
            $marker = if ($diffs -contains ($i + $j)) { "*" } else { " " }
            $line += ("{0}{1:x2}" -f $marker, $origBytes[$i + $j])
        }
        Write-Host $line
    }
    Write-Host "Candidate:"
    for ($i = 0; $i -lt $Size; $i += 16) {
        $line = ("  {0:x4}:" -f $i)
        for ($j = 0; $j -lt 16 -and ($i + $j) -lt $Size; $j++) {
            $marker = if ($diffs -contains ($i + $j)) { "*" } else { " " }
            $line += ("{0}{1:x2}" -f $marker, $candBytes[$i + $j])
        }
        Write-Host $line
    }
}

if ($diffs.Count -gt 0) {
    Write-Host ""
    Write-Host ("All diff offsets: " + (($diffs | ForEach-Object { "0x{0:x}" -f $_ }) -join ", "))
}

if ($hardDiffs.Count -gt 0) {
    Write-Host ("All hard diff offsets: " + (($hardDiffs | ForEach-Object { "0x{0:x}" -f $_ }) -join ", "))
}
