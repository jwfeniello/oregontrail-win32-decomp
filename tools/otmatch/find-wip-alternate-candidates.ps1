param(
    [string]$ManifestPath = "tools\otmatch\functions.vc40-real-cpp.csv",
    [string]$OriginalPath = "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe",
    [string]$OriginalDllPath = "Sample\Oregon Trail CD\OTWIN32\OREGON32.DLL",
    [string]$CandidatePath = "artifacts\otmatch\vc40\otwin-match-candidates.dll",
    [string]$CandidateMapPath = "artifacts\otmatch\vc40\otwin-match-candidates.map",
    [string]$OutputDirectory = "artifacts\otmatch\vc40\alternate-wip",
    [string]$NotesPattern = "WIP semantic conversion*",
    [int]$Top = 80,
    [switch]$BroadScan,
    [int]$BroadSizeWindow = 16,
    [int]$MaxMaskedDiff = -1,
    [switch]$ApplyMasks,
    [switch]$IncludeExact,
    [switch]$AllFunctionSymbols,
    [switch]$SelfTest
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

function Resolve-RepoPath([string]$Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return (Resolve-Path -LiteralPath $Path).Path
    }

    return (Resolve-Path -LiteralPath (Join-Path $repoRoot $Path)).Path
}

function Read-U16([byte[]]$Bytes, [int]$Offset) {
    return [uint16](([uint64]$Bytes[$Offset]) -bor
        (([uint64]$Bytes[$Offset + 1]) -shl 8))
}

function Read-U32([byte[]]$Bytes, [int]$Offset) {
    return [uint32](([uint64]$Bytes[$Offset]) -bor
        (([uint64]$Bytes[$Offset + 1]) -shl 8) -bor
        (([uint64]$Bytes[$Offset + 2]) -shl 16) -bor
        (([uint64]$Bytes[$Offset + 3]) -shl 24))
}

function Convert-HexNumber([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return [uint64]0
    }

    $text = $Value.Trim()
    if ($text.StartsWith("0x", [System.StringComparison]::OrdinalIgnoreCase)) {
        $text = $text.Substring(2)
    }

    return [uint64]::Parse($text, [System.Globalization.NumberStyles]::HexNumber)
}

function Convert-MaskNumber([string]$Value) {
    $text = $Value.Trim()
    if ($text.StartsWith("0x", [System.StringComparison]::OrdinalIgnoreCase)) {
        return [uint64]::Parse(
            $text.Substring(2),
            [System.Globalization.NumberStyles]::HexNumber)
    }

    return [uint64]::Parse($text, [System.Globalization.NumberStyles]::Integer)
}

function Get-PeImage([string]$Path) {
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).Path)
    $peOffset = [int](Read-U32 $bytes 0x3c)
    $coff = $peOffset + 4
    $sectionCount = [int](Read-U16 $bytes ($coff + 2))
    $optHeaderSize = [int](Read-U16 $bytes ($coff + 16))
    $optOffset = $coff + 20
    $sectionTable = $optOffset + $optHeaderSize
    $sections = @()
    for ($i = 0; $i -lt $sectionCount; $i++) {
        $sectionOffset = $sectionTable + ($i * 40)
        $sections += [pscustomobject]@{
            VirtualAddress = [uint64](Read-U32 $bytes ($sectionOffset + 12))
            VirtualSize    = [uint64](Read-U32 $bytes ($sectionOffset + 8))
            RawSize        = [uint64](Read-U32 $bytes ($sectionOffset + 16))
            RawPointer     = [uint64](Read-U32 $bytes ($sectionOffset + 20))
        }
    }

    return [pscustomobject]@{
        Bytes     = $bytes
        ImageBase = [uint64](Read-U32 $bytes ($optOffset + 28))
        Sections  = $sections
    }
}

function Read-RvaBytes($Image, [uint64]$Rva, [int]$Count) {
    foreach ($section in $Image.Sections) {
        $sectionEnd = $section.VirtualAddress +
            [System.Math]::Max($section.VirtualSize, $section.RawSize)
        if ($Rva -ge $section.VirtualAddress -and $Rva -lt $sectionEnd) {
            $delta = $Rva - $section.VirtualAddress
            $fileOffset = [int]($section.RawPointer + $delta)
            $out = New-Object byte[] $Count
            [System.Array]::Copy($Image.Bytes, $fileOffset, $out, 0, $Count)
            return $out
        }
    }

    throw "RVA 0x$($Rva.ToString('x')) not in any section."
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
            $start = [int](Convert-MaskNumber $Matches[1])
            $end = [int](Convert-MaskNumber $Matches[2])
        } else {
            $start = [int](Convert-MaskNumber $part)
            $end = $start
        }

        if ($end -lt $start) {
            throw "Mask range '$part' ends before it starts."
        }

        if ($end -ge $Size) {
            throw "Mask range '$part' is outside the function range."
        }

        for ($offset = $start; $offset -le $end; $offset++) {
            $mask[$offset] = $true
        }
    }

    return $mask
}

function Convert-ToNeedle([string]$Value) {
    return ($Value -replace '[^A-Za-z0-9]', '').ToLowerInvariant()
}

function Get-BaseCandidateSymbol([string]$CandidateSymbol) {
    return ($CandidateSymbol -replace `
        '\s*\+\s*(?:0x[0-9a-fA-F]+|[0-9]+)\s*$', '')
}

function Get-RowNeedles($Row) {
    $originalRva = Convert-HexNumber $Row.original_rva
    $originalVa = Convert-HexNumber $Row.original_va
    $needles = New-Object System.Collections.Generic.List[string]
    $needles.Add($originalRva.ToString("x8"))
    $needles.Add($originalVa.ToString("x8"))

    $name = [string]$Row.name
    $name = $name -replace '_000[0-9a-fA-F]+$', ''
    $name = $name -replace '^Ot', ''
    $name = $name -replace '^FUN_', ''
    $normalized = Convert-ToNeedle $name
    if ($normalized.Length -ge 9) {
        $needles.Add($normalized)
    }

    # Generic FUN_/switch-fragment manifest names often have no semantic text
    # in common with their Product candidate. Include the selected decorated
    # symbol (without an optional interior-function offset) so those rows and
    # their semantic alternates are not silently absent from the sweep.
    $candidateSymbol = Get-BaseCandidateSymbol ([string]$Row.candidate_symbol)
    $normalizedCandidateSymbol = Convert-ToNeedle $candidateSymbol
    if ($normalizedCandidateSymbol.Length -ge 9) {
        $needles.Add($normalizedCandidateSymbol)
    }

    return @($needles | Select-Object -Unique)
}

function Get-MapSymbols([string]$MapPath, [uint64]$ImageBase) {
    $symbols = New-Object System.Collections.Generic.List[object]
    foreach ($line in Get-Content -LiteralPath $MapPath) {
        # Product semantic functions may live in additional executable code
        # segments such as .otsem (0002), so do not silently restrict the
        # alternate sweep to the linker's first segment. The map's `f` marker
        # and the PE-backed RVA read below remain the authority for functions.
        if ($line -match '^\s*[0-9a-fA-F]{4}:[0-9a-fA-F]+\s+(\S+)\s+([0-9a-fA-F]+)\s+f\s+(.+)$') {
            $symbol = $Matches[1]
            $va = [uint64]::Parse(
                $Matches[2],
                [System.Globalization.NumberStyles]::HexNumber)
            $object = $Matches[3]

            if (-not $IncludeExact) {
                if ($symbol -match '_Exact_RealCpp' -or
                    $object -match 'src_otwin__exact' -or
                    $object -match 'generated_coverage') {
                    continue
                }
            }

            if (-not $AllFunctionSymbols -and
                $symbol -notmatch 'RealCpp|Semantic|Alt\d+|Wip\d+') {
                continue
            }

            $symbols.Add([pscustomobject]@{
                Symbol = $symbol
                SymbolNeedle = Convert-ToNeedle $symbol
                Rva = $va - $ImageBase
                Span = [uint64]0
                Object = $object
            })
        }
    }

    $ordered = @($symbols.ToArray() | Sort-Object Rva, Symbol)
    for ($index = 0; $index -lt $ordered.Count; $index++) {
        if ($index + 1 -lt $ordered.Count) {
            $ordered[$index].Span = [uint64]($ordered[$index + 1].Rva - $ordered[$index].Rva)
        }
    }

    return $ordered
}

function Invoke-SelfTest {
    $temporaryMap = Join-Path ([System.IO.Path]::GetTempPath()) `
        ("otwin-alternate-map-{0}.map" -f [Guid]::NewGuid().ToString("N"))
    try {
        @(
            " 0001:00000000 ?OtFirstRealCpp@@YAXXZ 00401000 f first.obj",
            " 0002:00000000 ?OtProductSemantic@@YAXXZ 00402000 f product.obj"
        ) | Set-Content -LiteralPath $temporaryMap -Encoding ASCII

        $symbols = @(Get-MapSymbols $temporaryMap ([uint64]0x00400000))
        if ($symbols.Count -ne 2 -or
            -not ($symbols | Where-Object {
                $_.Symbol -ceq "?OtProductSemantic@@YAXXZ" -and
                $_.Rva -eq [uint64]0x2000
            })) {
            throw "Map parsing contract failed to retain a function in segment 0002."
        }

        $row = [pscustomobject]@{
            original_rva = "0x00002000"
            original_va = "0x00402000"
            name = "FUN_00402000_00002000"
            candidate_symbol = "?OtProductSemantic@@YAXXZ + 0x4"
        }
        $expectedNeedle = Convert-ToNeedle "?OtProductSemantic@@YAXXZ"
        if (-not ((Get-RowNeedles $row) -contains $expectedNeedle)) {
            throw "Manifest candidate-symbol contract failed for a generic FUN_ row."
        }
        if ((Get-BaseCandidateSymbol ([string]$row.candidate_symbol)) -cne
            "?OtProductSemantic@@YAXXZ") {
            throw "Interior candidate-symbol offset was not normalized."
        }

        Write-Host "Alternate-candidate scanner contract passed."
    } finally {
        Remove-Item -LiteralPath $temporaryMap -Force -ErrorAction SilentlyContinue
    }
}

if ($SelfTest) {
    Invoke-SelfTest
    return
}

$manifestFullPath = Resolve-RepoPath $ManifestPath
$originalFullPath = Resolve-RepoPath $OriginalPath
$originalDllFullPath = Resolve-RepoPath $OriginalDllPath
$candidateFullPath = Resolve-RepoPath $CandidatePath
$candidateMapFullPath = Resolve-RepoPath $CandidateMapPath
$outputFullPath = Join-Path $repoRoot $OutputDirectory
New-Item -ItemType Directory -Force -Path $outputFullPath | Out-Null

$exeImage = Get-PeImage $originalFullPath
$dllImage = Get-PeImage $originalDllFullPath
$candidateImage = Get-PeImage $candidateFullPath
$symbols = Get-MapSymbols $candidateMapFullPath $candidateImage.ImageBase
$rows = @(Import-Csv -LiteralPath $manifestFullPath |
    Where-Object { $_.notes -like $NotesPattern })

$results = New-Object System.Collections.Generic.List[object]
foreach ($row in $rows) {
    $size = [int](Convert-HexNumber $row.size)
    $originalRva = Convert-HexNumber $row.original_rva
    $originalImage = if ($row.program -match 'DLL') { $dllImage } else { $exeImage }
    $originalBytes = Read-RvaBytes $originalImage $originalRva $size
    $mask = Read-Mask $row.mask $size
    $needles = Get-RowNeedles $row

    $matchingSymbols = if ($BroadScan) {
        if ($BroadSizeWindow -ge 0) {
            $maximumSpan = [uint64]($size + $BroadSizeWindow)
            @($symbols | Where-Object {
                $_.Span -ge [uint64]$size -and $_.Span -le $maximumSpan
            })
        } else {
            $symbols
        }
    } else {
        @($symbols | Where-Object {
            $symbolNeedle = $_.SymbolNeedle
            foreach ($needle in $needles) {
                if ($symbolNeedle.Contains($needle)) {
                    return $true
                }
            }

            return $false
        })
    }

    foreach ($candidateSymbol in $matchingSymbols) {
        try {
            $candidateBytes = Read-RvaBytes $candidateImage $candidateSymbol.Rva $size
            $rawDiff = 0
            $maskedDiff = 0
            for ($i = 0; $i -lt $size; $i++) {
                if ($originalBytes[$i] -ne $candidateBytes[$i]) {
                    $rawDiff++
                    if (-not ($ApplyMasks -and $mask[$i])) {
                        $maskedDiff++
                    }
                }
            }

            if ($MaxMaskedDiff -lt 0 -or $maskedDiff -le $MaxMaskedDiff) {
                $results.Add([pscustomobject]@{
                    Name = $row.name
                    OriginalRva = ("0x{0:x}" -f $originalRva)
                    Size = $size
                    DiffCount = $rawDiff
                    MaskedDiffCount = $maskedDiff
                    Selected = ($candidateSymbol.Symbol -ceq
                        (Get-BaseCandidateSymbol ([string]$row.candidate_symbol)))
                    CandidateSymbol = $candidateSymbol.Symbol
                    CandidateSpan = $candidateSymbol.Span
                    Object = $candidateSymbol.Object
                    ManifestSymbol = $row.candidate_symbol
                    Notes = $row.notes
                })
            }
        } catch {
            $results.Add([pscustomobject]@{
                Name = $row.name
                OriginalRva = ("0x{0:x}" -f $originalRva)
                Size = $size
                DiffCount = 2147483647
                MaskedDiffCount = 2147483647
                Selected = ($candidateSymbol.Symbol -ceq
                    (Get-BaseCandidateSymbol ([string]$row.candidate_symbol)))
                CandidateSymbol = $candidateSymbol.Symbol
                CandidateSpan = $candidateSymbol.Span
                Object = $candidateSymbol.Object
                ManifestSymbol = $row.candidate_symbol
                Notes = $_.Exception.Message
            })
        }
    }
}

$sorted = @($results | Sort-Object MaskedDiffCount, DiffCount, Name, CandidateSymbol)
$csvPath = Join-Path $outputFullPath "alternate-wip-candidates.csv"
$mdPath = Join-Path $outputFullPath "alternate-wip-candidates.md"
$sorted | Export-Csv -NoTypeInformation -Encoding ASCII -Path $csvPath

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Alternate WIP Candidate Sweep")
$lines.Add("")
$lines.Add(("Generated: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz")))
$lines.Add("")
$lines.Add(("Rows scanned: {0}" -f $rows.Count))
$lines.Add(("Candidate hits: {0}" -f $sorted.Count))
$lines.Add("")
$lines.Add("| Rank | Name | RVA | Size | Diff | Masked Diff | Candidate Span | Selected | Candidate Symbol | Object |")
$lines.Add("|---:|---|---:|---:|---:|---:|---:|---|---|---|")

$rank = 1
foreach ($entry in ($sorted | Select-Object -First $Top)) {
    $selected = if ($entry.Selected) { "yes" } else { "" }
    $lines.Add((
        "| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} | {9} |" -f
        $rank,
        $entry.Name,
        $entry.OriginalRva,
        $entry.Size,
        $entry.DiffCount,
        $entry.MaskedDiffCount,
        $entry.CandidateSpan,
        $selected,
        $entry.CandidateSymbol.Replace("|", "\|"),
        $entry.Object.Replace("|", "\|")))
    $rank++
}

$lines.Add("")
$lines.Add(("CSV output: {0}" -f $csvPath))
$lines | Set-Content -Encoding ASCII -Path $mdPath

$sorted | Select-Object -First $Top | Format-Table -AutoSize `
    Name, OriginalRva, Size, DiffCount, MaskedDiffCount, CandidateSpan, Selected, CandidateSymbol, Object
Write-Host ("CSV output: {0}" -f $csvPath)
Write-Host ("Markdown output: {0}" -f $mdPath)
