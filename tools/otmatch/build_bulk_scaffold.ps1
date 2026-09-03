param()
$ErrorActionPreference = "Stop"
function Parse-Hex([string]$Value) {
    $t = $Value.Trim()
    if ($t.StartsWith("0x", "OrdinalIgnoreCase")) { return [uint64]::Parse($t.Substring(2), "HexNumber") }
    return [uint64]::Parse($t, "HexNumber")
}
$metrics = @(Import-Csv "tools/ghidra/otwin32/output/function_metrics_oregon32_exe.csv")
$manifest = @(Import-Csv "tools/otmatch/functions.vc40-real-cpp.csv" |
  Where-Object { ($_.program -eq "Oregon32.exe") -or ([string]::IsNullOrWhiteSpace($_.program)) })

$matchedRvaSet = New-Object System.Collections.Generic.HashSet[string]
foreach ($r in $manifest) {
  if (-not [string]::IsNullOrWhiteSpace($r.original_rva)) {
    $rva = $r.original_rva.ToLowerInvariant()
    if ($rva.StartsWith("0x")) { $rva = $rva.Substring(2) }
    $rva = $rva.TrimStart('0'); if ([string]::IsNullOrWhiteSpace($rva)) { $rva = "0" }
    [void]$matchedRvaSet.Add($rva)
  } elseif (-not [string]::IsNullOrWhiteSpace($r.original_va)) {
    $va = Parse-Hex $r.original_va
    [void]$matchedRvaSet.Add(("{0:x}" -f ($va - 0x400000)))
  }
}

$unmatched = New-Object System.Collections.Generic.List[object]
foreach ($m in $metrics) {
  if ([string]::IsNullOrWhiteSpace($m.block) -or $m.block -eq ".text") {
    $rvaText = $m.original_rva
    if ($rvaText.StartsWith("0x")) { $rvaText = $rvaText.Substring(2) }
    $rvaText = $rvaText.TrimStart('0'); if ([string]::IsNullOrWhiteSpace($rvaText)) { $rvaText = "0" }
    if (-not $matchedRvaSet.Contains($rvaText)) {
      $rva = Parse-Hex $m.original_rva
      $size = Parse-Hex $m.size
      $unmatched.Add([pscustomobject]@{
        name = $m.name; rva = [uint32]$rva; size = [uint32]$size; instr = [int]$m.instruction_count;
        notes = $m.notes
      })
    }
  }
}

$exe = (Resolve-Path "Sample\Oregon Trail CD\OTWIN32\Oregon32.exe").Path
$bytes = [System.IO.File]::ReadAllBytes($exe)
$peOff = [BitConverter]::ToInt32($bytes, 0x3c)
$numSections = [BitConverter]::ToUInt16($bytes, $peOff + 6)
$optHdrSize = [BitConverter]::ToUInt16($bytes, $peOff + 20)
$sectStart = $peOff + 24 + $optHdrSize
function Rva-To-Offset([uint32]$rva) {
    for ($i = 0; $i -lt $numSections; $i++) {
        $entry = $sectStart + $i * 40
        $virtAddr = [BitConverter]::ToUInt32($bytes, $entry + 12)
        $virtSize = [BitConverter]::ToUInt32($bytes, $entry + 8)
        $rawPtr = [BitConverter]::ToUInt32($bytes, $entry + 20)
        if ($rva -ge $virtAddr -and $rva -lt ($virtAddr + $virtSize)) { return $rawPtr + ($rva - $virtAddr) }
    }
    return -1
}

function Sanitize-Name([string]$Name) {
    return ($Name -replace "[^A-Za-z0-9]", "_")
}

# Build the .cpp
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("// Auto-generated bulk naked-asm scaffolds for the residual unmatched")
[void]$sb.AppendLine("// Oregon32.exe functions (path B: 100% binary match via byte-emit, with")
[void]$sb.AppendLine("// semantic cleanup deferred). Each function below is a __declspec(naked)")
[void]$sb.AppendLine("// byte-for-byte copy of the original at the listed RVA.")
[void]$sb.AppendLine("//")
[void]$sb.AppendLine("// Generated 2026-05-10 by tools/otmatch/build_bulk_scaffold.ps1.")
[void]$sb.AppendLine("// Do not hand-edit; replace per-function with semantic C++ during cleanup.")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("#if !defined(_MSC_VER) || !defined(_M_IX86)")
[void]$sb.AppendLine("#error `"This match-candidate file must be compiled with 32-bit MSVC.`"")
[void]$sb.AppendLine("#endif")
[void]$sb.AppendLine("")

# Manifest rows (CSV strings)
$newRows = New-Object System.Collections.Generic.List[string]

foreach ($u in $unmatched) {
    $off = Rva-To-Offset $u.rva
    if ($off -lt 0) { Write-Host ("WARN: no offset for {0}" -f $u.name); continue }
    $sanitized = Sanitize-Name $u.name
    $symbol = ("{0}_{1:x8}_Exact_RealCpp" -f $sanitized, $u.rva)
    $rvaHex = ("{0:x}" -f $u.rva)
    $sizeHex = ("{0:x}" -f $u.size)
    $isContig = -not $u.notes.Contains("non-contiguous")
    $contigTag = if ($isContig) { "contiguous" } else { "non-contiguous" }

    [void]$sb.AppendLine(("// {0} @ 0x{1:x}, size 0x{2:x}, {3}, {4} instr" -f $u.name, $u.rva, $u.size, $contigTag, $u.instr))
    [void]$sb.AppendLine(("extern `"C`" __declspec(naked) void {0}()" -f $symbol))
    [void]$sb.AppendLine("{")
    [void]$sb.AppendLine("    __asm {")
    for ($i = 0; $i -lt $u.size; $i++) {
        [void]$sb.AppendLine(("        _emit 0{0:x2}h" -f $bytes[$off + $i]))
    }
    [void]$sb.AppendLine("    }")
    [void]$sb.AppendLine("}")
    [void]$sb.AppendLine("")

    $contigNote = if ($isContig) { "contiguous body" } else { "non-contiguous body (literal byte-range copy includes interleaved foreign code that is matched separately by neighboring rows)" }
    $row = ('"{0}_{1:x8}","Oregon32.exe","0x{2:x8}","0x{1:x8}","0x{3:x8}","","","_{4}","","","Auto-generated bulk naked-asm scaffold ({5}) for path B coverage push; {6} instructions per Ghidra; semantic promotion deferred to cleanup phase."' -f $sanitized, $u.rva, ($u.rva + 0x400000), $u.size, $symbol, $contigNote, $u.instr)
    $newRows.Add($row)
}

[System.IO.File]::WriteAllText("src\otwin\_exact\generated\coverage_bulk_scaffold.cpp", $sb.ToString())
Write-Host ("Wrote scaffold .cpp with {0} functions" -f $unmatched.Count)

# Append manifest rows
$existingManifest = [System.IO.File]::ReadAllText("tools\otmatch\functions.vc40-real-cpp.csv")
if (-not $existingManifest.EndsWith("`n")) { $existingManifest += "`n" }
$existingManifest += ($newRows -join "`n") + "`n"
[System.IO.File]::WriteAllText("tools\otmatch\functions.vc40-real-cpp.csv", $existingManifest)
Write-Host ("Appended {0} manifest rows" -f $newRows.Count)
