# Sweep c2.exe-internal /d2* passthrough flags via the canary harness.
#
# Background: the prior 35-config sweep covered all CL.EXE-documented switches
# but missed the /d2-prefixed passthroughs that forward switches to c2.exe's
# codegen back-end. The strings table at file offset 0x07c100..0x07c2f8 in
# C:\MSDEV\BIN\C2.EXE lists ~50 internal switches, of which ~24 are codegen/
# allocator-relevant. This script tests each one against the three established
# canaries under VC4.0 RTM and reports residual byte counts.
#
# Usage:
#   tools\otmatch\sweep-c2-flags.ps1
#
# Output: leaderboard table sorted by total residual across the 3 canaries.

[CmdletBinding()]
param(
    [string]$ToolchainRoot = "C:\MSDEV",
    [string]$Optimization = "/O2"
)

$ErrorActionPreference = "Continue"
Set-StrictMode -Version Latest

$canaries = @(
    [pscustomobject]@{ Name="OtRunWildFruitEvent";           OriginalRva=0x16b90; Size=189; SymbolContains="OtRunWildFruitEvent_00416b90_RealCpp" }
    [pscustomobject]@{ Name="OtRecomputeTrailTravelMetrics"; OriginalRva=0x2ddc0; Size=192; SymbolContains="OtRecomputeTrailTravelMetrics_0042ddc0_RealCpp" }
    [pscustomobject]@{ Name="OtRollHuntTargetSpawnChance";   OriginalRva=0x128c0; Size=258; SymbolContains="OtRollHuntTargetSpawnChance_004128c0_RealCpp" }
)

# Candidate /d2 flags. Each item is either a single flag or a list of flags
# (combo). The "Label" is used in the leaderboard.
$candidates = @(
    [pscustomobject]@{ Label = "(baseline)";                Flags = @() }
    # Single-flag tests
    [pscustomobject]@{ Label = "norecy";                    Flags = @("/d2norecy") }
    [pscustomobject]@{ Label = "noimmreg";                  Flags = @("/d2noimmreg") }
    [pscustomobject]@{ Label = "nosched";                   Flags = @("/d2nosched") }
    [pscustomobject]@{ Label = "nofreg";                    Flags = @("/d2nofreg") }
    [pscustomobject]@{ Label = "noforder";                  Flags = @("/d2noforder") }
    [pscustomobject]@{ Label = "nofpeep";                   Flags = @("/d2nofpeep") }
    [pscustomobject]@{ Label = "nojsched";                  Flags = @("/d2nojsched") }
    [pscustomobject]@{ Label = "noblend";                   Flags = @("/d2noblend") }
    [pscustomobject]@{ Label = "nocombine";                 Flags = @("/d2nocombine") }
    [pscustomobject]@{ Label = "noalign";                   Flags = @("/d2noalign") }
    [pscustomobject]@{ Label = "forcerisc";                 Flags = @("/d2forcerisc") }
    [pscustomobject]@{ Label = "unroll";                    Flags = @("/d2unroll") }
    [pscustomobject]@{ Label = "p6gj";                      Flags = @("/d2p6gj") }
    [pscustomobject]@{ Label = "QI0f";                      Flags = @("/d2QI0f") }
    [pscustomobject]@{ Label = "QIfdiv";                    Flags = @("/d2QIfdiv") }
    # Combinations
    [pscustomobject]@{ Label = "norecy+noimmreg (F1 found)";         Flags = @("/d2norecy", "/d2noimmreg") }
    [pscustomobject]@{ Label = "norecy+noimmreg+nofpeep";            Flags = @("/d2norecy", "/d2noimmreg", "/d2nofpeep") }
    [pscustomobject]@{ Label = "norecy+noimmreg+noblend";            Flags = @("/d2norecy", "/d2noimmreg", "/d2noblend") }
    [pscustomobject]@{ Label = "norecy+noimmreg+nocombine";          Flags = @("/d2norecy", "/d2noimmreg", "/d2nocombine") }
    [pscustomobject]@{ Label = "norecy+noimmreg+noforder";           Flags = @("/d2norecy", "/d2noimmreg", "/d2noforder") }
    [pscustomobject]@{ Label = "norecy+noimmreg+nofreg";             Flags = @("/d2norecy", "/d2noimmreg", "/d2nofreg") }
    [pscustomobject]@{ Label = "norecy+noimmreg+forcerisc";          Flags = @("/d2norecy", "/d2noimmreg", "/d2forcerisc") }
    [pscustomobject]@{ Label = "all-no-* (norecy+noimmreg+noforder+nofpeep+noblend+nocombine+nofreg)";
                       Flags = @("/d2norecy", "/d2noimmreg", "/d2noforder", "/d2nofpeep", "/d2noblend", "/d2nocombine", "/d2nofreg") }
)

$harness = Join-Path $PSScriptRoot "canary-toolchain-comparison.ps1"

function Run-Trial([string]$Label, [string[]]$Flags) {
    $result = [ordered]@{
        Label = $Label
        Flags = ($Flags -join ' ')
        WildFruit = "?"
        Recomp    = "?"
        Hunt      = "?"
        Total     = 0
        Status    = "?"
    }
    try {
        $output = & $harness `
            -ToolchainRoots @($ToolchainRoot) `
            -OptimizationFlags @($Optimization) `
            -ExtraC2Flags $Flags `
            -Canaries $canaries 2>&1 | Out-String

        # Parse the diff grid. Look for lines like:
        #   OtRunWildFruitEvent              189  0x16b90       128/189
        $tcName = Split-Path -Leaf $ToolchainRoot
        foreach ($name in @("OtRunWildFruitEvent", "OtRecomputeTrailTravelMetrics", "OtRollHuntTargetSpawnChance")) {
            $regex = "^\s*" + [regex]::Escape($name) + "\s+\S+\s+\S+\s+(?:(?<diff>\d+)/\d+|MATCH \(\d+ B\))"
            $m = [regex]::Match($output, $regex, "Multiline")
            if (-not $m.Success) {
                $result.Status = "no-parse"
                continue
            }
            $diffCount = if ($m.Groups["diff"].Success) { [int]$m.Groups["diff"].Value } else { 0 }
            switch ($name) {
                "OtRunWildFruitEvent"           { $result.WildFruit = $diffCount }
                "OtRecomputeTrailTravelMetrics" { $result.Recomp = $diffCount }
                "OtRollHuntTargetSpawnChance"   { $result.Hunt = $diffCount }
            }
            $result.Total += $diffCount
        }
        $result.Status = "OK"
    } catch {
        $result.Status = "FAIL: $($_.Exception.Message)"
    }
    return [pscustomobject]$result
}

Write-Host ("Running " + $candidates.Count + " trials against canaries under " + $ToolchainRoot + " " + $Optimization)
Write-Host ""

$results = @()
$i = 0
foreach ($cand in $candidates) {
    $i++
    Write-Host ("[" + $i + "/" + $candidates.Count + "] " + $cand.Label) -ForegroundColor Yellow
    $r = Run-Trial $cand.Label $cand.Flags
    Write-Host ("  WildFruit={0} Recomp={1} Hunt={2} Total={3} Status={4}" -f $r.WildFruit, $r.Recomp, $r.Hunt, $r.Total, $r.Status)
    $results += $r
}

Write-Host ""
Write-Host "=== Leaderboard (sorted by total residual ascending) ===" -ForegroundColor Green
$results | Sort-Object -Property Total | Format-Table -AutoSize Label, WildFruit, Recomp, Hunt, Total, Status, Flags

# Compute deltas from baseline
$baseline = $results | Where-Object { $_.Label -eq "(baseline)" } | Select-Object -First 1
if ($baseline) {
    Write-Host ""
    Write-Host "=== Improvements vs baseline ===" -ForegroundColor Green
    $results | Where-Object { $_.Label -ne "(baseline)" -and $_.Status -eq "OK" } | ForEach-Object {
        $delta = $_.Total - $baseline.Total
        if ($delta -lt 0) {
            $sign = if ($delta -ge 0) { "+" } else { "" }
            ("{0,-50} {1}{2} bytes  ({3})" -f $_.Label, $sign, $delta, $_.Flags) | Write-Host -ForegroundColor Cyan
        }
    }
}
