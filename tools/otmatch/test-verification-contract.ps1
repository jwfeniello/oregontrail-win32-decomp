[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$matcherPath = (Resolve-Path (Join-Path $PSScriptRoot "match-functions.ps1")).Path
$shellPath = (Get-Process -Id $PID).Path
$fixturePath = $shellPath
$workPath = Join-Path ([System.IO.Path]::GetTempPath()) ("otmatch-contract-" + [guid]::NewGuid().ToString("N"))
[void][System.IO.Directory]::CreateDirectory($workPath)

function Write-Manifest {
    param(
        [string]$Path,
        [string]$ExpectedStatus,
        [string]$ImplementationKind,
        [string]$Mask,
        [string]$Name = "contract_probe",
        [string]$OriginalRva = "0x00000002",
        [string]$CandidateRva = "0x00000002",
        [string]$Size = "0x00000001",
        [switch]$OmitMetadata
    )

    $fields = [ordered]@{
        name = $Name
        program = "Oregon32.exe"
        original_va = ""
        original_rva = $OriginalRva
        size = $Size
        candidate_va = ""
        candidate_rva = $CandidateRva
        candidate_symbol = ""
        candidate_dll = ""
        candidate_object = ""
    }
    if (-not $OmitMetadata.IsPresent) {
        $fields.expected_status = $ExpectedStatus
        $fields.implementation_kind = $ImplementationKind
    }
    $fields.mask = $Mask
    $fields.notes = "Self-contained matcher contract probe."

    @([pscustomobject]$fields) |
        Export-Csv -LiteralPath $Path -NoTypeInformation -Encoding UTF8
}

function Invoke-ContractCase {
    param(
        [string]$Name,
        [string]$CandidatePath,
        [string]$ExpectedStatus,
        [string]$ImplementationKind,
        [string]$Mask,
        [int]$ExpectedExitCode,
        [string]$ExpectedVerificationStatus,
        [string]$ExpectedDiagnosticText = "",
        [string]$ExpectedMaskShapeValid = "",
        [string]$OriginalRva = "0x00000002",
        [string]$CandidateRva = "0x00000002",
        [string]$Size = "0x00000001",
        [switch]$OmitMetadata
    )

    $manifestPath = Join-Path $workPath "$Name-manifest.csv"
    $resultsPath = Join-Path $workPath "$Name-results.csv"
    Write-Manifest `
        -Path $manifestPath `
        -ExpectedStatus $ExpectedStatus `
        -ImplementationKind $ImplementationKind `
        -Mask $Mask `
        -Name $Name `
        -OriginalRva $OriginalRva `
        -CandidateRva $CandidateRva `
        -Size $Size `
        -OmitMetadata:$OmitMetadata.IsPresent

    $output = & $shellPath -NoProfile -ExecutionPolicy Bypass `
        -File $matcherPath `
        -ManifestPath $manifestPath `
        -OriginalPath $fixturePath `
        -CandidatePath $CandidatePath `
        -ResultsCsvPath $resultsPath `
        -SummaryOnly 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne $ExpectedExitCode) {
        throw ("{0}: expected exit {1}, got {2}. Output: {3}" -f
            $Name, $ExpectedExitCode, $exitCode, ($output -join [Environment]::NewLine))
    }

    if (-not (Test-Path -LiteralPath $resultsPath -PathType Leaf)) {
        throw "${Name}: matcher did not write its results CSV."
    }
    $results = @(Import-Csv -LiteralPath $resultsPath)
    if ($results.Count -ne 1) {
        throw "${Name}: expected one result row, got $($results.Count)."
    }
    if ($results[0].verification_status -cne $ExpectedVerificationStatus) {
        throw ("{0}: expected verification_status '{1}', got '{2}'." -f
            $Name, $ExpectedVerificationStatus, $results[0].verification_status)
    }
    if ($results[0].result_schema_version -cne "4") {
        throw "${Name}: matcher did not emit result schema version 4."
    }
    if ($null -eq $results[0].PSObject.Properties["mask_shape_valid"] -or
        $null -eq $results[0].PSObject.Properties["masked_operand_shape_error"]) {
        throw "${Name}: matcher omitted symmetric mask-shape result fields."
    }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedMaskShapeValid) -and
        $results[0].mask_shape_valid -cne $ExpectedMaskShapeValid) {
        throw ("{0}: expected mask_shape_valid '{1}', got '{2}'." -f
            $Name, $ExpectedMaskShapeValid, $results[0].mask_shape_valid)
    }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedDiagnosticText) -and
        $results[0].error_message.IndexOf($ExpectedDiagnosticText, [System.StringComparison]::Ordinal) -lt 0 -and
        $results[0].masked_import_identity_error.IndexOf(
            $ExpectedDiagnosticText, [System.StringComparison]::Ordinal) -lt 0 -and
        $results[0].masked_operand_shape_error.IndexOf(
            $ExpectedDiagnosticText, [System.StringComparison]::Ordinal) -lt 0) {
        throw ("{0}: expected diagnostic containing '{1}', got '{2}'." -f
            $Name, $ExpectedDiagnosticText,
            ($results[0].error_message + $results[0].masked_import_identity_error +
                $results[0].masked_operand_shape_error))
    }
    $expectedManifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($results[0].manifest_sha256 -cne $expectedManifestHash) {
        throw "${Name}: matcher did not bind the result to the exact manifest SHA-256."
    }
    if ((Resolve-Path -LiteralPath $results[0].manifest_path).Path -cne
        (Resolve-Path -LiteralPath $manifestPath).Path) {
        throw "${Name}: matcher recorded the wrong manifest path."
    }
    if ($ExpectedVerificationStatus -cne "error") {
        $expectedOriginalHash = (Get-FileHash -LiteralPath $fixturePath -Algorithm SHA256).Hash.ToLowerInvariant()
        $expectedCandidateHash = (Get-FileHash -LiteralPath $CandidatePath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($results[0].original_file_sha256 -cne $expectedOriginalHash -or
            $results[0].candidate_file_sha256 -cne $expectedCandidateHash) {
            throw "${Name}: matcher did not bind the result to the exact original/candidate SHA-256 values."
        }
        if (-not [string]::IsNullOrWhiteSpace($results[0].candidate_map_path) -or
            -not [string]::IsNullOrWhiteSpace($results[0].candidate_map_sha256)) {
            throw "${Name}: an omitted candidate map must produce empty path/hash metadata."
        }
    }

    Write-Host ("PASS {0}: exit={1}, verification_status={2}" -f
        $Name, $exitCode, $results[0].verification_status)
}

function Set-U16([byte[]]$Bytes, [int]$Offset, [uint16]$Value) {
    $Bytes[$Offset] = [byte]($Value -band 0xff)
    $Bytes[($Offset + 1)] = [byte](($Value -shr 8) -band 0xff)
}

function Set-U32([byte[]]$Bytes, [int]$Offset, [uint32]$Value) {
    $Bytes[$Offset] = [byte]($Value -band 0xff)
    $Bytes[($Offset + 1)] = [byte](($Value -shr 8) -band 0xff)
    $Bytes[($Offset + 2)] = [byte](($Value -shr 16) -band 0xff)
    $Bytes[($Offset + 3)] = [byte](($Value -shr 24) -band 0xff)
}

function Set-AsciiZ([byte[]]$Bytes, [int]$Offset, [string]$Value) {
    $encoded = [System.Text.Encoding]::ASCII.GetBytes($Value)
    [System.Array]::Copy($encoded, 0, $Bytes, $Offset, $encoded.Length)
    $Bytes[($Offset + $encoded.Length)] = 0
}

function New-ImportFixture {
    param(
        [string]$Path,
        [string]$Dll,
        [string]$Import
    )

    # Minimal, self-contained i386 PE32 image. The seven-byte probe function is
    # `call dword ptr [IAT]; ret`; its absolute IAT operand has a HIGHLOW entry.
    $bytes = New-Object byte[] 0x800
    $peOffset = 0x80
    $coffOffset = $peOffset + 4
    $optionalOffset = $coffOffset + 20
    $sectionOffset = $optionalOffset + 0xe0
    $sectionRaw = 0x200
    $imageBase = [uint32]0x00400000

    $bytes[0] = 0x4d
    $bytes[1] = 0x5a
    Set-U32 $bytes 0x3c $peOffset
    $bytes[$peOffset] = 0x50
    $bytes[($peOffset + 1)] = 0x45
    Set-U16 $bytes $coffOffset 0x014c
    Set-U16 $bytes ($coffOffset + 2) 1
    Set-U16 $bytes ($coffOffset + 16) 0x00e0
    Set-U16 $bytes ($coffOffset + 18) 0x0102

    Set-U16 $bytes $optionalOffset 0x010b
    Set-U32 $bytes ($optionalOffset + 4) 0x00000200
    Set-U32 $bytes ($optionalOffset + 8) 0x00000400
    Set-U32 $bytes ($optionalOffset + 16) 0x00001000
    Set-U32 $bytes ($optionalOffset + 20) 0x00001000
    Set-U32 $bytes ($optionalOffset + 24) 0x00001000
    Set-U32 $bytes ($optionalOffset + 28) $imageBase
    Set-U32 $bytes ($optionalOffset + 32) 0x00001000
    Set-U32 $bytes ($optionalOffset + 36) 0x00000200
    Set-U16 $bytes ($optionalOffset + 40) 4
    Set-U16 $bytes ($optionalOffset + 48) 4
    Set-U32 $bytes ($optionalOffset + 56) 0x00002000
    Set-U32 $bytes ($optionalOffset + 60) 0x00000200
    Set-U16 $bytes ($optionalOffset + 68) 3
    Set-U32 $bytes ($optionalOffset + 72) 0x00100000
    Set-U32 $bytes ($optionalOffset + 76) 0x00001000
    Set-U32 $bytes ($optionalOffset + 80) 0x00100000
    Set-U32 $bytes ($optionalOffset + 84) 0x00001000
    Set-U32 $bytes ($optionalOffset + 92) 16
    Set-U32 $bytes ($optionalOffset + 104) 0x00001100
    Set-U32 $bytes ($optionalOffset + 108) 0x00000028
    Set-U32 $bytes ($optionalOffset + 136) 0x00001200
    Set-U32 $bytes ($optionalOffset + 140) 0x0000000c

    Set-AsciiZ $bytes $sectionOffset ".text"
    Set-U32 $bytes ($sectionOffset + 8) 0x00000600
    Set-U32 $bytes ($sectionOffset + 12) 0x00001000
    Set-U32 $bytes ($sectionOffset + 16) 0x00000600
    Set-U32 $bytes ($sectionOffset + 20) $sectionRaw
    Set-U32 $bytes ($sectionOffset + 36) 0x60000020

    function Get-RawOffset([int]$Rva) {
        return $sectionRaw + ($Rva - 0x1000)
    }

    $functionOffset = Get-RawOffset 0x1000
    $bytes[$functionOffset] = 0xff
    $bytes[($functionOffset + 1)] = 0x15
    Set-U32 $bytes ($functionOffset + 2) ($imageBase + 0x1150)
    $bytes[($functionOffset + 6)] = 0xc3

    $descriptorOffset = Get-RawOffset 0x1100
    Set-U32 $bytes $descriptorOffset 0x00001140
    Set-U32 $bytes ($descriptorOffset + 12) 0x00001128
    Set-U32 $bytes ($descriptorOffset + 16) 0x00001150
    Set-AsciiZ $bytes (Get-RawOffset 0x1128) $Dll

    if ($Import.StartsWith("#", [System.StringComparison]::Ordinal)) {
        $ordinal = [uint32]::Parse($Import.Substring(1), [System.Globalization.CultureInfo]::InvariantCulture)
        $lookupValue = [uint32]([uint64]2147483648 -bor [uint64]$ordinal)
    }
    else {
        $lookupValue = [uint32]0x00001160
        Set-U16 $bytes (Get-RawOffset 0x1160) 0
        Set-AsciiZ $bytes ((Get-RawOffset 0x1160) + 2) $Import
    }
    Set-U32 $bytes (Get-RawOffset 0x1140) $lookupValue
    Set-U32 $bytes (Get-RawOffset 0x1150) $lookupValue

    $relocationOffset = Get-RawOffset 0x1200
    Set-U32 $bytes $relocationOffset 0x00001000
    Set-U32 $bytes ($relocationOffset + 4) 12
    Set-U16 $bytes ($relocationOffset + 8) 0x3002
    Set-U16 $bytes ($relocationOffset + 10) 0

    [System.IO.File]::WriteAllBytes($Path, $bytes)
}

function New-HighLowFixture {
    param(
        [string]$Path,
        [uint32]$TargetRva,
        [int]$RelocationOffset = 2,
        [switch]$WithoutRelocation
    )

    New-ImportFixture -Path $Path `
        -Dll "KERNEL32.dll" -Import "WritePrivateProfileStringA"
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    Set-U32 $bytes 0x202 ([uint32](0x00400000 + $TargetRva))
    if ($WithoutRelocation.IsPresent) {
        Set-U16 $bytes 0x408 0
    }
    else {
        Set-U16 $bytes 0x408 ([uint16](0x3000 + $RelocationOffset))
    }
    [System.IO.File]::WriteAllBytes($Path, $bytes)
}

function New-Rel32Fixture {
    param(
        [string]$Path,
        [byte]$Opcode,
        [uint32]$TargetRva,
        [byte]$SecondOpcode = 0x84
    )

    New-ImportFixture -Path $Path `
        -Dll "KERNEL32.dll" -Import "WritePrivateProfileStringA"
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $bytes[0x200] = $Opcode
    if ($Opcode -eq 0x0f) {
        $bytes[0x201] = $SecondOpcode
        $displacement = [uint32]([uint64]$TargetRva - [uint64]0x00001006)
        Set-U32 $bytes 0x202 $displacement
        $bytes[0x206] = 0xc3
    }
    else {
        $displacement = [uint32]([uint64]$TargetRva - [uint64]0x00001005)
        Set-U32 $bytes 0x201 $displacement
        $bytes[0x205] = 0xc3
    }
    Set-U16 $bytes 0x408 0
    [System.IO.File]::WriteAllBytes($Path, $bytes)
}

try {
    $differentFixturePath = Join-Path $workPath "fixture-different.exe"
    [System.IO.File]::Copy($fixturePath, $differentFixturePath)
    $differentBytes = [System.IO.File]::ReadAllBytes($differentFixturePath)
    $differentBytes[2] = $differentBytes[2] -bxor 1
    [System.IO.File]::WriteAllBytes($differentFixturePath, $differentBytes)

    Invoke-ContractCase -Name "expected-match-pass" `
        -CandidatePath $fixturePath -ExpectedStatus match -ImplementationKind cpp `
        -Mask "" -ExpectedExitCode 0 -ExpectedVerificationStatus pass

    Invoke-ContractCase -Name "expected-match-regression" `
        -CandidatePath $differentFixturePath -ExpectedStatus match -ImplementationKind cpp `
        -Mask "" -ExpectedExitCode 1 -ExpectedVerificationStatus regression

    Invoke-ContractCase -Name "expected-wip-mismatch" `
        -CandidatePath $differentFixturePath -ExpectedStatus wip -ImplementationKind cpp `
        -Mask "" -ExpectedExitCode 0 -ExpectedVerificationStatus allowed_wip

    Invoke-ContractCase -Name "expected-wip-closed" `
        -CandidatePath $fixturePath -ExpectedStatus wip -ImplementationKind cpp `
        -Mask "" -ExpectedExitCode 0 -ExpectedVerificationStatus promotion_ready

    Invoke-ContractCase -Name "full-mask-rejected" `
        -CandidatePath $fixturePath -ExpectedStatus match -ImplementationKind cpp `
        -Mask "0" -ExpectedExitCode 1 -ExpectedVerificationStatus error

    Invoke-ContractCase -Name "invalid-kind-rejected" `
        -CandidatePath $fixturePath -ExpectedStatus match -ImplementationKind unknown `
        -Mask "" -ExpectedExitCode 1 -ExpectedVerificationStatus error

    Invoke-ContractCase -Name "blank-metadata-rejected" `
        -CandidatePath $fixturePath -ExpectedStatus "" -ImplementationKind "" `
        -Mask "" -ExpectedExitCode 1 -ExpectedVerificationStatus error

    Invoke-ContractCase -Name "legacy-schema-compatible" `
        -CandidatePath $fixturePath -ExpectedStatus "" -ImplementationKind "" `
        -Mask "" -ExpectedExitCode 0 -ExpectedVerificationStatus pass -OmitMetadata

    $originalImportFixturePath = Join-Path $workPath "import-original.exe"
    $sameImportFixturePath = Join-Path $workPath "import-same.exe"
    $wrongImportFixturePath = Join-Path $workPath "import-wrong.exe"
    New-ImportFixture -Path $originalImportFixturePath `
        -Dll "KERNEL32.dll" -Import "WritePrivateProfileStringA"
    New-ImportFixture -Path $sameImportFixturePath `
        -Dll "kernel32.DLL" -Import "WritePrivateProfileStringA"
    New-ImportFixture -Path $wrongImportFixturePath `
        -Dll "USER32.dll" -Import "MessageBoxA"

    $fixturePath = $originalImportFixturePath
    Invoke-ContractCase -Name "masked-import-identity-pass" `
        -CandidatePath $sameImportFixturePath -ExpectedStatus match -ImplementationKind cpp `
        -Mask "2-5" -OriginalRva "0x00001000" -CandidateRva "0x00001000" -Size "7" `
        -ExpectedExitCode 0 -ExpectedVerificationStatus pass -ExpectedMaskShapeValid "True"

    Invoke-ContractCase -Name "masked-import-symbol-mismatch-rejected" `
        -CandidatePath $wrongImportFixturePath -ExpectedStatus match -ImplementationKind cpp `
        -Mask "2-5" -OriginalRva "0x00001000" -CandidateRva "0x00001000" -Size "7" `
        -ExpectedExitCode 1 -ExpectedVerificationStatus regression `
        -ExpectedMaskShapeValid "False" `
        -ExpectedDiagnosticText "original targets KERNEL32.dll!WritePrivateProfileStringA, candidate targets USER32.dll!MessageBoxA"

    $missingRelocationFixturePath = Join-Path $workPath "import-missing-relocation.exe"
    [System.IO.File]::Copy($sameImportFixturePath, $missingRelocationFixturePath)
    $missingRelocationBytes = [System.IO.File]::ReadAllBytes($missingRelocationFixturePath)
    # Section RVA 0x1000 maps to raw 0x200, so the first relocation entry at
    # RVA 0x1208 is file offset 0x408. Convert it from HIGHLOW to ABSOLUTE.
    Set-U16 $missingRelocationBytes 0x408 0
    [System.IO.File]::WriteAllBytes($missingRelocationFixturePath, $missingRelocationBytes)
    Invoke-ContractCase -Name "masked-import-missing-relocation-rejected" `
        -CandidatePath $missingRelocationFixturePath -ExpectedStatus match -ImplementationKind cpp `
        -Mask "2-5" -OriginalRva "0x00001000" -CandidateRva "0x00001000" -Size "7" `
        -ExpectedExitCode 1 -ExpectedVerificationStatus regression `
        -ExpectedMaskShapeValid "False" `
        -ExpectedDiagnosticText "candidate operand is not a HIGHLOW relocation"

    $originalOrdinalFixturePath = Join-Path $workPath "import-ordinal-original.exe"
    $wrongOrdinalFixturePath = Join-Path $workPath "import-ordinal-wrong.exe"
    New-ImportFixture -Path $originalOrdinalFixturePath -Dll "ORDINAL.dll" -Import "#17"
    New-ImportFixture -Path $wrongOrdinalFixturePath -Dll "ORDINAL.dll" -Import "#18"
    $fixturePath = $originalOrdinalFixturePath
    Invoke-ContractCase -Name "masked-import-ordinal-mismatch-rejected" `
        -CandidatePath $wrongOrdinalFixturePath -ExpectedStatus match -ImplementationKind cpp `
        -Mask "2-5" -OriginalRva "0x00001000" -CandidateRva "0x00001000" -Size "7" `
        -ExpectedExitCode 1 -ExpectedVerificationStatus regression `
        -ExpectedMaskShapeValid "False" `
        -ExpectedDiagnosticText "original targets ORDINAL.dll!#17, candidate targets ORDINAL.dll!#18"

    $originalHighLowFixturePath = Join-Path $workPath "highlow-original.exe"
    $sameOffsetHighLowFixturePath = Join-Path $workPath "highlow-same-offset.exe"
    $missingHighLowFixturePath = Join-Path $workPath "highlow-missing.exe"
    $shiftedHighLowFixturePath = Join-Path $workPath "highlow-shifted.exe"
    New-HighLowFixture -Path $originalHighLowFixturePath -TargetRva 0x1300
    New-HighLowFixture -Path $sameOffsetHighLowFixturePath -TargetRva 0x1310
    New-HighLowFixture -Path $missingHighLowFixturePath -TargetRva 0x1310 -WithoutRelocation
    New-HighLowFixture -Path $shiftedHighLowFixturePath -TargetRva 0x1310 -RelocationOffset 3

    $fixturePath = $originalHighLowFixturePath
    Invoke-ContractCase -Name "masked-highlow-same-offset-pass" `
        -CandidatePath $sameOffsetHighLowFixturePath -ExpectedStatus match -ImplementationKind cpp `
        -Mask "2-5" -OriginalRva "0x00001000" -CandidateRva "0x00001000" -Size "7" `
        -ExpectedExitCode 0 -ExpectedVerificationStatus pass -ExpectedMaskShapeValid "True"

    Invoke-ContractCase -Name "masked-highlow-missing-rejected" `
        -CandidatePath $missingHighLowFixturePath -ExpectedStatus match -ImplementationKind cpp `
        -Mask "2-5" -OriginalRva "0x00001000" -CandidateRva "0x00001000" -Size "7" `
        -ExpectedExitCode 1 -ExpectedVerificationStatus regression `
        -ExpectedMaskShapeValid "False" `
        -ExpectedDiagnosticText "candidate has no same-offset maskable operand"

    Invoke-ContractCase -Name "masked-highlow-shifted-rejected" `
        -CandidatePath $shiftedHighLowFixturePath -ExpectedStatus match -ImplementationKind cpp `
        -Mask "2-5" -OriginalRva "0x00001000" -CandidateRva "0x00001000" -Size "7" `
        -ExpectedExitCode 1 -ExpectedVerificationStatus regression `
        -ExpectedMaskShapeValid "False" `
        -ExpectedDiagnosticText "partially covers the candidate highlow operand"

    $originalRel32FixturePath = Join-Path $workPath "rel32-original.exe"
    $sameClassRel32FixturePath = Join-Path $workPath "rel32-same-class.exe"
    $wrongClassRel32FixturePath = Join-Path $workPath "rel32-wrong-class.exe"
    New-Rel32Fixture -Path $originalRel32FixturePath -Opcode 0xe8 -TargetRva 0x1300
    New-Rel32Fixture -Path $sameClassRel32FixturePath -Opcode 0xe8 -TargetRva 0x1310
    New-Rel32Fixture -Path $wrongClassRel32FixturePath -Opcode 0xe9 -TargetRva 0x1310

    $fixturePath = $originalRel32FixturePath
    Invoke-ContractCase -Name "masked-rel32-same-class-pass" `
        -CandidatePath $sameClassRel32FixturePath -ExpectedStatus match -ImplementationKind cpp `
        -Mask "1-4" -OriginalRva "0x00001000" -CandidateRva "0x00001000" -Size "6" `
        -ExpectedExitCode 0 -ExpectedVerificationStatus pass -ExpectedMaskShapeValid "True"

    # Expected-WIP rows must retain the shape diagnostic even though an
    # independent unmasked opcode difference already keeps the row open.
    Invoke-ContractCase -Name "masked-rel32-class-mismatch-wip-diagnosed" `
        -CandidatePath $wrongClassRel32FixturePath -ExpectedStatus wip -ImplementationKind cpp `
        -Mask "1-4" -OriginalRva "0x00001000" -CandidateRva "0x00001000" -Size "6" `
        -ExpectedExitCode 0 -ExpectedVerificationStatus allowed_wip `
        -ExpectedMaskShapeValid "False" `
        -ExpectedDiagnosticText "original is rel32_call, candidate is rel32_jmp"

    $originalJccFixturePath = Join-Path $workPath "rel32-jcc-original.exe"
    $sameClassJccFixturePath = Join-Path $workPath "rel32-jcc-same-class.exe"
    New-Rel32Fixture -Path $originalJccFixturePath -Opcode 0x0f -SecondOpcode 0x84 -TargetRva 0x1300
    New-Rel32Fixture -Path $sameClassJccFixturePath -Opcode 0x0f -SecondOpcode 0x85 -TargetRva 0x1310

    $fixturePath = $originalJccFixturePath
    Invoke-ContractCase -Name "masked-rel32-jcc-class-pass" `
        -CandidatePath $sameClassJccFixturePath -ExpectedStatus wip -ImplementationKind cpp `
        -Mask "2-5" -OriginalRva "0x00001000" -CandidateRva "0x00001000" -Size "7" `
        -ExpectedExitCode 0 -ExpectedVerificationStatus allowed_wip `
        -ExpectedMaskShapeValid "True"

    Write-Host "Matcher verification contract: PASS"
}
finally {
    if (Test-Path -LiteralPath $workPath -PathType Container) {
        Remove-Item -LiteralPath $workPath -Recurse -Force
    }
}
