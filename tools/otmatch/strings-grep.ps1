# Extract printable ASCII strings from a binary and search for known
# compiler/runtime signature patterns. The CRT, MFC, and many
# compiler-emitted error messages leave identifiable strings in the
# .rdata or .data sections.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [int]$MinLength = 6,

    [string[]]$Patterns = @(
        "Microsoft",
        "Borland",
        "Watcom",
        "Symantec",
        "Visual C\+\+",
        "C\+\+ Runtime",
        "C runtime",
        "CRT",
        "MFC",
        "MSVCRT",
        "_TURBOC",
        "compiled by",
        "Compiled by",
        "compiler",
        "Stack overflow",
        "Domain error",
        "Range error",
        "DOMAIN error",
        "abnormal program",
        "_amsg_exit",
        "stdio",
        "fopen",
        "Copyright"
    )
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).Path)
$total = $bytes.Length

# Walk bytes, collect runs of printable ASCII (0x20–0x7E) of MinLength+
$strings = New-Object System.Collections.Generic.List[string]
$start = -1
for ($i = 0; $i -lt $total; $i++) {
    $b = $bytes[$i]
    if ($b -ge 0x20 -and $b -le 0x7E) {
        if ($start -lt 0) { $start = $i }
    } else {
        if ($start -ge 0 -and ($i - $start) -ge $MinLength) {
            $s = [System.Text.Encoding]::ASCII.GetString($bytes, $start, $i - $start)
            $strings.Add(("0x{0:x6}: {1}" -f $start, $s))
        }
        $start = -1
    }
}

Write-Host ("=== Compiler/CRT signature strings in {0} ===" -f $Path) -ForegroundColor Cyan
Write-Host ("Total printable strings >= {0} chars: {1}" -f $MinLength, $strings.Count)
Write-Host ""

foreach ($pattern in $Patterns) {
    # Explicit array wrapper - single matches return scalar without it
    $matched = @($strings | Where-Object { $_ -match $pattern })
    if ($matched.Count -gt 0) {
        Write-Host ("--- /{0}/ ({1} matches) ---" -f $pattern, $matched.Count) -ForegroundColor Yellow
        $matched | Select-Object -First 8 | ForEach-Object { "  $_" }
        if ($matched.Count -gt 8) { Write-Host ("  ... and {0} more" -f ($matched.Count - 8)) }
        Write-Host ""
    }
}
