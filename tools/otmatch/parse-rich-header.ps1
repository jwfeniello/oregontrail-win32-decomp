# Parses the Microsoft "Rich" header embedded between the DOS stub and the
# PE signature in a Windows PE file. The header records every Microsoft
# build tool (cl.exe, link.exe, masm, cvtres, etc.) used to produce the
# binary, identified by a (productId, buildNumber) pair plus a count of
# .obj files contributed by that tool.
#
# Format reference: Daniel Pistelli, "Microsoft's Rich Signature" (2008);
# Aaron Klotz / RetroReversing notes; pefile.py implementation.
#
# Layout in file:
#   ...DOS stub bytes...
#   <encoded data, XOR'd with the 4-byte key>
#   "Rich" (literal 0x52 0x69 0x63 0x68)
#   <4-byte XOR key>
#   ...PE signature ("PE\0\0") at e_lfanew...
#
# When XOR-decoded with the key, the encoded data begins with "DanS"
# (0x44 0x61 0x6E 0x53) followed by 12 bytes of zero padding, then an
# array of 8-byte entries: DWORD compid + DWORD use_count.
#
#   compid layout (per Klotz):
#     bits 31..16 = build number
#     bits 15..0  = product id (compiler/linker variant)
#
# Known product-id ranges for VC++ era (1995-1998):
#   0x000  Total imports (synthesized)
#   0x001  Import (per-DLL)
#   0x002  Linker (older CV LINK)
#   0x004  CVTOMF
#   0x006  CL (C compiler, VC1-VC4 era)
#   0x007  CL (C++ compiler / VC2-VC4)
#   0x008-0x009 reserved
#   0x00A  Linker (LINK, VC4-VC5 era)
#   0x00B  ALIAS
#   0x00C  ALIASOBJ
#   0x015  CL (VC5/VC6 era)
#   ...
#
# Known build numbers for VC++ 4.x:
#   5270 = VC4.0 RTM
#   6038 = VC4.1
#   6164 = VC4.2 LINK
#   6166 = VC4.2 CL

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [switch]$Raw
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).Path)

function Read-U32([byte[]]$b, [int]$o) {
    return [uint32](([uint64]$b[$o]) -bor (([uint64]$b[$o+1]) -shl 8) -bor (([uint64]$b[$o+2]) -shl 16) -bor (([uint64]$b[$o+3]) -shl 24))
}

# Locate e_lfanew (PE header offset) at 0x3c.
$peOff = [int](Read-U32 $bytes 0x3c)

# Search backwards from peOff for the "Rich" marker (literal, not XOR'd).
$richMarker = [byte[]](0x52, 0x69, 0x63, 0x68)
$richOff = -1
for ($i = $peOff - 4; $i -ge 0; $i--) {
    if ($bytes[$i] -eq $richMarker[0] -and
        $bytes[$i+1] -eq $richMarker[1] -and
        $bytes[$i+2] -eq $richMarker[2] -and
        $bytes[$i+3] -eq $richMarker[3]) {
        $richOff = $i
        break
    }
}

if ($richOff -lt 0) {
    Write-Host "No Rich header found in $Path" -ForegroundColor Yellow
    Write-Host "(File may have been built by a non-Microsoft toolchain or stripped of metadata.)"
    return
}

# The 4 bytes immediately after "Rich" are the XOR key.
$xorKey = Read-U32 $bytes ($richOff + 4)

# Search backwards from "Rich" for the encoded "DanS" marker.
# Encoded value = "DanS" (0x536E6144 little-endian) XOR key.
$dansEncoded = [uint32](0x536E6144 -bxor $xorKey)
$dansOff = -1
for ($i = $richOff - 4; $i -ge 0; $i -= 4) {
    if ((Read-U32 $bytes $i) -eq $dansEncoded) {
        $dansOff = $i
        break
    }
}

if ($dansOff -lt 0) {
    Write-Host "Rich marker found at 0x$($richOff.ToString('x')) but DanS marker not located" -ForegroundColor Yellow
    return
}

# Decode and parse the rich-header entries. Skip the first 16 bytes after
# DanS (DanS marker + 12 zero padding bytes). Each remaining entry is 8
# bytes: DWORD compid, DWORD count.
$entryStart = $dansOff + 16
$entryEnd = $richOff
$entryCount = ($entryEnd - $entryStart) / 8

Write-Host "=== Rich header analysis: $Path ===" -ForegroundColor Cyan
Write-Host ("DOS-to-PE stub region: 0x80 to 0x{0:x}" -f $peOff)
Write-Host ("Rich marker offset:    0x{0:x}" -f $richOff)
Write-Host ("DanS marker offset:    0x{0:x}" -f $dansOff)
Write-Host ("XOR key:               0x{0:x8}" -f $xorKey)
Write-Host ("Entry count:           {0}" -f $entryCount)
Write-Host ""

# Product ID lookup table for VC era. Build numbers below disambiguate
# specific patch levels.
$productNames = @{
    0x0000 = "Padding/Total"
    0x0001 = "Import"
    0x0002 = "Linker (LINK pre-CV)"
    0x0004 = "CVTOMF"
    0x0006 = "CL (C front-end, VC1-VC4)"
    0x0007 = "CL (C++ front-end, VC2-VC4)"
    0x000A = "Linker (LINK)"
    0x000B = "ALIASOBJ"
    0x000C = "ALIASOBJ (alt)"
    0x000D = "Linker"
    0x000E = "Export"
    0x000F = "ImportTotal"
    0x0010 = "ResRes (resource)"
    0x0011 = "Pogo (PGO)"
    0x0012 = "OptOmt"
    0x0013 = "Implib"
    0x0014 = "ASM (MASM)"
    0x0015 = "CL (newer)"
}

if ($Raw.IsPresent) {
    Write-Host "Raw entries (compid_decoded, count_decoded):" -ForegroundColor Yellow
    for ($off = $entryStart; $off -lt $entryEnd; $off += 8) {
        $compidEncoded = Read-U32 $bytes $off
        $countEncoded = Read-U32 $bytes ($off + 4)
        $compid = [uint32]($compidEncoded -bxor $xorKey)
        $count = [uint32]($countEncoded -bxor $xorKey)
        Write-Host ("  0x{0:x8}  count={1,5}" -f $compid, $count)
    }
    return
}

Write-Host ("{0,-12} {1,-8} {2,-40} {3,8}" -f "compid", "build", "product", "count") -ForegroundColor Yellow
Write-Host ("{0,-12} {1,-8} {2,-40} {3,8}" -f "------", "-----", "-------", "-----") -ForegroundColor Yellow

for ($off = $entryStart; $off -lt $entryEnd; $off += 8) {
    $compidEncoded = Read-U32 $bytes $off
    $countEncoded = Read-U32 $bytes ($off + 4)
    $compid = [uint32]($compidEncoded -bxor $xorKey)
    $count = [uint32]($countEncoded -bxor $xorKey)

    $productId = [int]($compid -band 0xFFFF)
    $buildNum = [int](($compid -shr 16) -band 0xFFFF)

    $productName = if ($productNames.ContainsKey($productId)) {
        $productNames[$productId]
    } else {
        ("(unknown 0x{0:x4})" -f $productId)
    }

    Write-Host ("0x{0:x8}  {1,-8} {2,-40} {3,8}" -f $compid, $buildNum, $productName, $count)
}
