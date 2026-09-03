param(
    [string]$ManifestPath = "tools\otmatch\functions.vc40-real-cpp.csv",
    [string]$OriginalPath = "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe",
    [string]$CandidatePath = "artifacts\otmatch\vc40\otwin-match-candidates.dll",
    [string]$CandidateMapPath = "artifacts\otmatch\vc40\otwin-match-candidates.map",
    [int]$MaxSize = 0x300,
    [int]$Limit = 200
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

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

    for ($i = 0; $i -lt $sectionCount; $i++) {
        $sectionOffset = $sectionTable + ($i * 40)
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

function Read-RvaBytes($image, [uint64]$rva, [int]$count) {
    foreach ($section in $image.Sections) {
        $sectionEnd = $section.VirtualAddress + [System.Math]::Max($section.VirtualSize, $section.RawSize)
        if ($rva -ge $section.VirtualAddress -and $rva -lt $sectionEnd) {
            $delta = $rva - $section.VirtualAddress
            $fileOffset = [int]($section.RawPointer + $delta)
            $out = New-Object byte[] $count
            [System.Array]::Copy($image.Bytes, $fileOffset, $out, 0, $count)
            return $out
        }
    }

    throw ("RVA 0x{0:x} is not in a PE section" -f $rva)
}

function Find-ByteHits([byte[]]$haystack, [byte[]]$needle, [int]$start, [int]$end) {
    $hits = @()
    if ($needle.Length -eq 0) {
        return $hits
    }

    $first = $needle[0]
    $index = $start
    while ($index -le ($end - $needle.Length)) {
        $remaining = $end - $index - $needle.Length + 1
        $candidate = [System.Array]::IndexOf($haystack, $first, $index, $remaining)
        if ($candidate -lt 0) {
            break
        }

        $match = $true
        for ($i = 1; $i -lt $needle.Length; $i++) {
            if ($haystack[$candidate + $i] -ne $needle[$i]) {
                $match = $false
                break
            }
        }

        if ($match) {
            $hits += $candidate
        }
        $index = $candidate + 1
    }

    return $hits
}

$original = Get-PeImage $OriginalPath
$candidate = Get-PeImage $CandidatePath
$text = $candidate.Sections | Where-Object { $_.Name -eq ".text" } | Select-Object -First 1
if ($null -eq $text) {
    throw "Candidate image has no .text section"
}

$symbols = @()
foreach ($line in Get-Content $CandidateMapPath) {
    if ($line -match '^\s*0001:([0-9a-fA-F]+)\s+(\S+)\s+([0-9a-fA-F]+)\s+f\s+(.+)$') {
        $offset = [int]([System.Convert]::ToInt32($matches[1], 16))
        $symbols += [pscustomobject]@{
            Offset = $offset
            Rva = [uint64](0x1000 + $offset)
            Name = $matches[2]
            Object = $matches[4]
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

$textStart = [int]$text.RawPointer
$textEnd = [int]($text.RawPointer + $text.RawSize)
$rows = Import-Csv $ManifestPath | Where-Object {
    $_.program -eq "Oregon32.exe" -and
    $_.candidate_symbol -match "_Exact_RealCpp" -and
    [System.Convert]::ToInt32(($_.size -replace "^0x", ""), 16) -le $MaxSize
}

$results = @()
foreach ($row in $rows) {
    $size = [System.Convert]::ToInt32(($row.size -replace "^0x", ""), 16)
    $originalRva = [System.Convert]::ToUInt64(($row.original_rva -replace "^0x", ""), 16)
    $needle = Read-RvaBytes $original $originalRva $size
    $hits = Find-ByteHits $candidate.Bytes $needle $textStart $textEnd

    foreach ($rawHit in $hits) {
        $hitRva = [uint64]($text.VirtualAddress + ($rawHit - $text.RawPointer))
        $symbol = Get-ContainingSymbol $hitRva
        if ($null -eq $symbol) {
            continue
        }

        $exact = ($symbol.Name -match "_Exact_RealCpp") -or ($symbol.Object -match "generated")
        if (-not $exact) {
            $results += [pscustomobject]@{
                Row = $row.name
                OriginalRva = $row.original_rva
                Size = $row.size
                HitRva = ("0x{0:x8}" -f $hitRva)
                Symbol = $symbol.Name
                Object = $symbol.Object
            }
        }
    }
}

$unique = @($results | Sort-Object Row, HitRva, Symbol -Unique)
$unique | Select-Object -First $Limit | Format-Table -AutoSize
Write-Host ("unique_rows={0} hits={1}" -f @($unique | Group-Object Row).Count, $unique.Count)
