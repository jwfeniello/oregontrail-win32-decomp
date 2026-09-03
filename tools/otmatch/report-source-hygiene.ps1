param(
    [string]$SourceRoot = "src\otwin"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$sourceRootPath = Resolve-Path -LiteralPath (Join-Path $repoRoot $SourceRoot)

$asmPattern = '__asm|__declspec\s*\(\s*naked\s*\)|\b_emit\b'
$recoveryNamePattern = '(_wip|_probe|_notes|80pct|40pct|50pct|55|scaffold|recovery|semantic_)'

function Get-RelativePath {
    param([System.IO.FileInfo]$File)

    return $File.FullName.Substring($repoRoot.Length).TrimStart('\','/') -replace '/', '\'
}

function Measure-SourceTier {
    param(
        [string]$Name,
        [System.IO.FileInfo[]]$Files
    )

    $asmMarkerFiles = @()
    foreach ($file in $Files) {
        $hasAsm = Select-String -LiteralPath $file.FullName -Pattern $asmPattern -Quiet
        if ($hasAsm) {
            $asmMarkerFiles += $file
        }
    }

    $recoveryNamedFiles = @($Files | Where-Object { $_.Name -match $recoveryNamePattern })

    return [pscustomobject]@{
        tier = $Name
        files = @($Files).Count
        asm_marker_files = @($asmMarkerFiles).Count
        recovery_named_files = @($recoveryNamedFiles).Count
    }
}

$allSourceFiles = @(Get-ChildItem -LiteralPath $sourceRootPath -Include *.cpp,*.h -File -Recurse)

$productFiles = @($allSourceFiles | Where-Object {
    $_.FullName -notlike "*\src\otwin\_exact\*" -and
    $_.FullName -notlike "*\src\otwin\_recovery\*"
})

$recoveryFiles = @($allSourceFiles | Where-Object {
    $_.FullName -like "*\src\otwin\_recovery\*"
})

$exactFiles = @($allSourceFiles | Where-Object {
    $_.FullName -like "*\src\otwin\_exact\*"
})

Write-Host ""
Write-Host "OTWIN source hygiene metrics"
Write-Host ("Source root: {0}" -f $sourceRootPath.Path)
Write-Host ""

@(
    Measure-SourceTier "product" $productFiles
    Measure-SourceTier "recovery" $recoveryFiles
    Measure-SourceTier "exact" $exactFiles
) | Format-Table -AutoSize

$productRecoveryNames = @($productFiles | Where-Object { $_.Name -match $recoveryNamePattern })
if ($productRecoveryNames.Count -gt 0) {
    Write-Host ""
    Write-Host "Product files with recovery marker names:"
    $productRecoveryNames | ForEach-Object { Write-Host ("  {0}" -f (Get-RelativePath $_)) }
}
