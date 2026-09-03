# Dumps the import table of a PE file. Useful for identifying which CRT
# model a binary links against:
#   - Imports MSVCRT.DLL or MSVCRT40.DLL  -> dynamic CRT
#   - No CRT DLL imports + has _main/__startup symbols  -> static CRT (LIBC.LIB or LIBCMT.LIB)
#   - Imports MFC*.DLL  -> dynamic MFC link
#
# Format reference: PE optional header data directory entry [1] points at
# the Import Directory, which is an array of IMAGE_IMPORT_DESCRIPTOR
# (20 bytes each), terminated by an all-zero descriptor.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Path
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Read-U16([byte[]]$b, [int]$o) {
    return [uint16](([uint64]$b[$o]) -bor (([uint64]$b[$o+1]) -shl 8))
}

function Read-U32([byte[]]$b, [int]$o) {
    return [uint32](([uint64]$b[$o]) -bor (([uint64]$b[$o+1]) -shl 8) -bor (([uint64]$b[$o+2]) -shl 16) -bor (([uint64]$b[$o+3]) -shl 24))
}

function Get-PeSections([byte[]]$bytes, [int]$peOff) {
    $coff = $peOff + 4
    $numSections = [int](Read-U16 $bytes ($coff + 2))
    $optHdrSize = [int](Read-U16 $bytes ($coff + 16))
    $secTbl = $coff + 20 + $optHdrSize
    $sections = @()
    for ($i = 0; $i -lt $numSections; $i++) {
        $base = $secTbl + ($i * 40)
        $sections += [pscustomobject]@{
            Name = [System.Text.Encoding]::ASCII.GetString($bytes, $base, 8).TrimEnd("`0")
            VirtualAddress = [uint64](Read-U32 $bytes ($base + 12))
            VirtualSize = [uint64](Read-U32 $bytes ($base + 8))
            RawPointer = [uint64](Read-U32 $bytes ($base + 20))
        }
    }
    return $sections
}

function RvaToFileOffset($sections, [uint64]$rva) {
    foreach ($s in $sections) {
        if ($rva -ge $s.VirtualAddress -and $rva -lt ($s.VirtualAddress + $s.VirtualSize)) {
            return [int]($s.RawPointer + ($rva - $s.VirtualAddress))
        }
    }
    return -1
}

function Read-CString([byte[]]$bytes, [int]$offset) {
    $sb = New-Object System.Text.StringBuilder
    while ($bytes[$offset] -ne 0) {
        [void]$sb.Append([char]$bytes[$offset])
        $offset++
    }
    return $sb.ToString()
}

foreach ($p in $Path) {
    $resolved = Resolve-Path -LiteralPath $p
    $bytes = [System.IO.File]::ReadAllBytes($resolved.Path)
    $peOff = [int](Read-U32 $bytes 0x3c)

    $opt = $peOff + 4 + 20
    # Data directory [1] is Import Directory at opt + 96 + 8 = opt + 104
    # (data directories start at offset 96 within the optional header for PE32)
    $importDirRva = [uint64](Read-U32 $bytes ($opt + 96 + 8))
    $importDirSize = [uint64](Read-U32 $bytes ($opt + 96 + 12))

    if ($importDirRva -eq 0) {
        Write-Host "$($resolved.Path): no import directory"
        continue
    }

    $sections = Get-PeSections $bytes $peOff
    $impFileOff = RvaToFileOffset $sections $importDirRva
    if ($impFileOff -lt 0) {
        Write-Host "$($resolved.Path): import directory RVA 0x$($importDirRva.ToString('x')) not in any section"
        continue
    }

    Write-Host ("=== Imports: {0} ===" -f $resolved.Path) -ForegroundColor Cyan

    # Walk import descriptors. Each is 20 bytes.
    $offset = $impFileOff
    while ($true) {
        $origThunkRva = [uint64](Read-U32 $bytes $offset)
        $timestamp = Read-U32 $bytes ($offset + 4)
        $forwarderChain = Read-U32 $bytes ($offset + 8)
        $nameRva = [uint64](Read-U32 $bytes ($offset + 12))
        $firstThunkRva = [uint64](Read-U32 $bytes ($offset + 16))

        if ($origThunkRva -eq 0 -and $nameRva -eq 0 -and $firstThunkRva -eq 0) {
            break
        }

        $nameOff = RvaToFileOffset $sections $nameRva
        $dllName = if ($nameOff -ge 0) { Read-CString $bytes $nameOff } else { "?" }

        # Count function imports for this DLL.
        $thunkRva = if ($origThunkRva -ne 0) { $origThunkRva } else { $firstThunkRva }
        $thunkOff = RvaToFileOffset $sections $thunkRva
        $importCount = 0
        if ($thunkOff -ge 0) {
            while (($t = Read-U32 $bytes ($thunkOff + ($importCount * 4))) -ne 0) {
                $importCount++
            }
        }

        Write-Host ("  {0,-20}  ({1} symbols imported)" -f $dllName, $importCount)
        $offset += 20
    }
    Write-Host ""
}
