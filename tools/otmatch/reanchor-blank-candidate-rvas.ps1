param(
    [string]$ManifestPath = "tools\otmatch\functions.vc40-real-cpp.csv",
    [string]$OriginalPath = "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe",
    [string]$CandidatePath = "artifacts\otmatch\vc40\otwin-match-candidates.dll",
    [string]$CandidateMapPath = "artifacts\otmatch\vc40\otwin-match-candidates.map",
    [switch]$Apply
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Parse-Number([string]$value, [string]$fieldName, [bool]$allowEmpty = $false) {
    if ([string]::IsNullOrWhiteSpace($value)) {
        if ($allowEmpty) {
            return $null
        }
        throw "Missing required numeric field '$fieldName'."
    }

    $text = $value.Trim()
    if ($text.StartsWith("0x", [System.StringComparison]::OrdinalIgnoreCase)) {
        return [uint64]::Parse($text.Substring(2), [System.Globalization.NumberStyles]::HexNumber)
    }
    return [uint64]::Parse($text, [System.Globalization.NumberStyles]::Integer)
}

function Format-Rva([uint64]$value) {
    return "0x{0:x8}" -f $value
}

function Read-U16([byte[]]$bytes, [int]$offset) {
    return [uint16](([uint64]$bytes[$offset]) -bor (([uint64]$bytes[$offset + 1]) -shl 8))
}

function Read-U32([byte[]]$bytes, [int]$offset) {
    return [uint32](
        ([uint64]$bytes[$offset]) -bor
        (([uint64]$bytes[$offset + 1]) -shl 8) -bor
        (([uint64]$bytes[$offset + 2]) -shl 16) -bor
        (([uint64]$bytes[$offset + 3]) -shl 24))
}

function Get-PeImage([string]$path) {
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $path).Path)
    $peOffset = [int](Read-U32 $bytes 0x3c)
    $coffOffset = $peOffset + 4
    $sectionCount = [int](Read-U16 $bytes ($coffOffset + 2))
    $optionalHeaderSize = [int](Read-U16 $bytes ($coffOffset + 16))
    $sectionTable = $coffOffset + 20 + $optionalHeaderSize
    $sections = @()

    for ($index = 0; $index -lt $sectionCount; $index++) {
        $sectionOffset = $sectionTable + ($index * 40)
        $name = ([System.Text.Encoding]::ASCII.GetString($bytes, $sectionOffset, 8)).Trim([char]0)
        $sections += [pscustomobject]@{
            Name = $name
            VirtualAddress = [uint64](Read-U32 $bytes ($sectionOffset + 12))
            VirtualSize = [uint64](Read-U32 $bytes ($sectionOffset + 8))
            RawSize = [uint64](Read-U32 $bytes ($sectionOffset + 16))
            RawPointer = [uint64](Read-U32 $bytes ($sectionOffset + 20))
        }
    }

    return [pscustomobject]@{ Bytes = $bytes; Sections = $sections }
}

function Convert-RvaToFileOffset($image, [uint64]$rva) {
    foreach ($section in $image.Sections) {
        $sectionEnd = $section.VirtualAddress + [System.Math]::Max($section.VirtualSize, $section.RawSize)
        if ($rva -ge $section.VirtualAddress -and $rva -lt $sectionEnd) {
            return [int]($section.RawPointer + ($rva - $section.VirtualAddress))
        }
    }
    throw ("RVA {0} is not in a PE section" -f (Format-Rva $rva))
}

function Read-RvaBytes($image, [uint64]$rva, [int]$size) {
    $offset = Convert-RvaToFileOffset $image $rva
    $out = New-Object byte[] $size
    [System.Array]::Copy($image.Bytes, $offset, $out, 0, $size)
    return $out
}

function Read-Mask([string]$maskText, [int]$size) {
    $mask = New-Object bool[] $size
    if ([string]::IsNullOrWhiteSpace($maskText)) {
        return $mask
    }

    foreach ($rawPart in ($maskText -split '[;, ]+')) {
        if ([string]::IsNullOrWhiteSpace($rawPart)) {
            continue
        }

        $part = $rawPart.Trim()
        if ($part -match '^(.+)-(.+)$') {
            $start = Parse-Number $Matches[1] "mask.start"
            $end = Parse-Number $Matches[2] "mask.end"
        } else {
            $start = Parse-Number $part "mask.offset"
            $end = $start
        }

        for ($offset = [int]$start; $offset -le [int]$end; $offset++) {
            $mask[$offset] = $true
        }
    }

    return $mask
}

function Find-MaskedHits([byte[]]$haystack, [byte[]]$needle, [bool[]]$mask, [int]$start, [int]$end) {
    $anchor = -1
    for ($index = 0; $index -lt $needle.Length; $index++) {
        if (-not $mask[$index]) {
            $anchor = $index
            break
        }
    }
    if ($anchor -lt 0) {
        return $null
    }

    $hits = @()
    $anchorByte = $needle[$anchor]
    $scan = $start + $anchor
    while ($scan -le ($end - ($needle.Length - $anchor))) {
        $remaining = $end - $scan - ($needle.Length - $anchor) + 1
        $candidateAnchor = [System.Array]::IndexOf($haystack, $anchorByte, $scan, $remaining)
        if ($candidateAnchor -lt 0) {
            break
        }

        $candidate = $candidateAnchor - $anchor
        if ($candidate -ge $start -and ($candidate + $needle.Length) -le $end) {
            $match = $true
            for ($i = 0; $i -lt $needle.Length; $i++) {
                if (-not $mask[$i] -and $haystack[$candidate + $i] -ne $needle[$i]) {
                    $match = $false
                    break
                }
            }
            if ($match) {
                $hits += $candidate
            }
        }

        $scan = $candidateAnchor + 1
    }

    return $hits
}

$original = Get-PeImage $OriginalPath
$candidate = Get-PeImage $CandidatePath
$text = $candidate.Sections | Where-Object { $_.Name -eq ".text" } | Select-Object -First 1
if ($null -eq $text) {
    throw "Candidate image has no .text section."
}

$symbols = @()
foreach ($line in Get-Content $CandidateMapPath) {
    if ($line -match '^\s*0001:([0-9a-fA-F]+)\s+(\S+)\s+([0-9a-fA-F]+)\s+f\s+(.+)$') {
        $offset = [int]([System.Convert]::ToInt32($Matches[1], 16))
        $symbols += [pscustomobject]@{
            Offset = $offset
            Rva = [uint64](0x1000 + $offset)
            Name = $Matches[2]
            Object = $Matches[4]
        }
    }
}
$symbols = $symbols | Sort-Object Offset

function Get-ContainingSymbol([uint64]$rva) {
    $offset = [int]($rva - 0x1000)
    $low = 0
    $high = $symbols.Count - 1
    $best = $null
    while ($low -le $high) {
        $middle = [int](($low + $high) / 2)
        if ($symbols[$middle].Offset -le $offset) {
            $best = $symbols[$middle]
            $low = $middle + 1
        } else {
            $high = $middle - 1
        }
    }
    return $best
}

$rows = @(Import-Csv $ManifestPath)
$textStart = [int]$text.RawPointer
$textEnd = [int]($text.RawPointer + $text.RawSize)
$changes = @()
$missing = @()

foreach ($row in $rows) {
    if ($row.program -ne "Oregon32.exe" -or
        -not [string]::IsNullOrWhiteSpace($row.candidate_symbol) -or
        [string]::IsNullOrWhiteSpace($row.candidate_rva)) {
        continue
    }

    $size = [int](Parse-Number $row.size "size")
    $oldRva = Parse-Number $row.candidate_rva "candidate_rva"
    $originalRva = Parse-Number $row.original_rva "original_rva"
    $needle = Read-RvaBytes $original $originalRva $size
    $mask = Read-Mask $row.mask $size
    $rawHits = Find-MaskedHits $candidate.Bytes $needle $mask $textStart $textEnd
    if ($null -eq $rawHits) {
        continue
    }

    $hits = @()
    foreach ($rawHit in $rawHits) {
        $hitRva = [uint64]($text.VirtualAddress + ($rawHit - $text.RawPointer))
        $symbol = Get-ContainingSymbol $hitRva
        if ($null -eq $symbol) {
            continue
        }

        $isExact = ($symbol.Name -match "_Exact_RealCpp") -or
            ($symbol.Object -match "generated") -or
            ($symbol.Object -match "small_stubs")
        if (-not $isExact) {
            $hits += [pscustomobject]@{ Rva = $hitRva; Symbol = $symbol.Name; Object = $symbol.Object }
        }
    }

    if ($hits.Count -eq 0) {
        $missing += $row.name
        continue
    }

    $best = $hits | Sort-Object @{ Expression = { [System.Math]::Abs([int64]$_.Rva - [int64]$oldRva) } }, Rva | Select-Object -First 1
    if ($best.Rva -ne $oldRva) {
        $newText = Format-Rva $best.Rva
        $changes += [pscustomobject]@{
            Name = $row.name
            OldRva = $row.candidate_rva
            NewRva = $newText
            Symbol = $best.Symbol
            Object = $best.Object
        }
        if ($Apply) {
            $row.candidate_rva = $newText
        }
    }
}

$changes | Format-Table -AutoSize
Write-Host ("changes={0} missing={1}" -f $changes.Count, $missing.Count)
if ($missing.Count -gt 0) {
    Write-Host "Missing rows:"
    $missing | ForEach-Object { Write-Host "  $_" }
}

if ($Apply -and $changes.Count -gt 0) {
    $resolvedManifest = (Resolve-Path $ManifestPath).Path
    $rows | Export-Csv -Path $resolvedManifest -NoTypeInformation
    Write-Host "Updated $resolvedManifest"
}
