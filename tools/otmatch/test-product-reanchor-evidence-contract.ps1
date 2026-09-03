[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$hostRepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$generatorSource = (Resolve-Path (Join-Path $PSScriptRoot `
    "invoke-product-reanchor-evidence.ps1")).Path
$orchestratorSource = (Resolve-Path (Join-Path $PSScriptRoot `
    "invoke-recovery-wave.ps1")).Path
$shellPath = (Get-Process -Id $PID).Path
$contractRoot = [System.IO.Path]::GetFullPath((Join-Path `
    (Join-Path $hostRepoRoot "a") `
    ("product-reanchor-contract-" + [guid]::NewGuid().ToString("N"))))
$sandboxRepoRoot = Join-Path $contractRoot "repo"
$manifestRelative = "tools/otmatch/functions.vc40-real-cpp.csv"
$productManifestRelative = "tools/otmatch/vc4-exe-product-sources.txt"
$sourceRelative = "src/otwin/product.cpp"
$evidenceRelative = "a/evidence/product-reanchor.json"
$ledgerRelative = "a/session-ledger.json"
$buildRelative = "a/evidence/build"
$checkpointMapRelative =
    "a/checkpoint/vc40/otwin-match-candidates.map"
$checkpointVerifierRelative =
    "a/checkpoint/vc40/function-match-results.csv"
$checkpointMetricsSummary = $null
$checkpointId = "contract-product-reanchor"
$boundaryRunId = "contract-baseline-run"
$identity = "oregon32.exe|0x1000"
$candidateSymbol = "_ContractProductContainer@16+0x20"
$candidateObject = "src_otwin_product.obj"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) {
        throw $Message
    }
}

function Get-ContractSha256 {
    param([string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).
        Hash.ToLowerInvariant()
}

function Write-ContractText {
    param([string]$Path, [string]$Text)
    $parent = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        [void][System.IO.Directory]::CreateDirectory($parent)
    }
    [System.IO.File]::WriteAllText($Path, $Text, $utf8NoBom)
}

function Invoke-ContractGit {
    param([string[]]$Arguments)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = @(& git -C $sandboxRepoRoot @Arguments 2>&1 |
            ForEach-Object { [string]$_ })
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
    if ($exitCode -ne 0) {
        throw "Sandbox git failed: git $($Arguments -join ' '): $($output -join ' ')"
    }
    return @($output)
}

function Write-Manifest {
    param(
        [string]$Program = "Oregon32.exe",
        [string]$CandidateVa = "",
        [string]$CandidateRva = "",
        [string]$CandidateSymbolValue = $candidateSymbol,
        [string]$CandidateDll = "",
        [string]$CandidateObjectValue = $candidateObject,
        [string]$ExpectedStatus = "match",
        [string]$Notes = "Exact Product symbol occurrence reanchor."
    )
    $row = [pscustomobject][ordered]@{
        name = "ContractProductReanchor"
        program = $Program
        original_va = "0x00401000"
        original_rva = "0x00001000"
        size = "0x00000010"
        candidate_va = $CandidateVa
        candidate_rva = $CandidateRva
        candidate_symbol = $CandidateSymbolValue
        candidate_dll = $CandidateDll
        candidate_object = $CandidateObjectValue
        expected_status = $ExpectedStatus
        implementation_kind = "cpp"
        mask = ""
        notes = $Notes
    }
    $csv = @($row | ConvertTo-Csv -NoTypeInformation) -join "`r`n"
    Write-ContractText (Join-Path $sandboxRepoRoot $manifestRelative) `
        ($csv + "`r`n")
}

function Write-ToolStubs {
    $toolRoot = Join-Path $sandboxRepoRoot "tools/otmatch"
    $buildStub = @'
param(
    [string]$Toolchain, [string]$VcToolsRoot,
    [string]$OutputDirectory, [string]$TuMetadataPath,
    [string]$DefaultOptimization, [string]$SemanticOptimization,
    [switch]$Rebuild
)
$ErrorActionPreference = "Stop"
[void][System.IO.Directory]::CreateDirectory($OutputDirectory)
foreach ($name in @(
        "otwin-match-candidates.dll",
        "otwin-match-candidates-lcmt.dll",
        "otwin-match-candidates-dllcrt.dll",
        "src_otwin_product.obj")) {
    [System.IO.File]::WriteAllBytes(
        (Join-Path $OutputDirectory $name),
        [System.Text.Encoding]::ASCII.GetBytes("contract-$name"))
}
$mapText = @"
 Preferred load address is 10000000

 Address         Publics by Value              Rva+Base   Lib:Object

 0001:00001fe0       _ContractProductContainer@16 10002fe0 f src_otwin_product.obj
 0001:00002040       _ContractNextPublic@0 10003040 f src_otwin_product.obj

 entry point at        0000:00000000
"@
foreach ($name in @(
        "otwin-match-candidates.map",
        "otwin-match-candidates-lcmt.map",
        "otwin-match-candidates-dllcrt.map")) {
    [System.IO.File]::WriteAllText(
        (Join-Path $OutputDirectory $name), $mapText,
        [System.Text.UTF8Encoding]::new($false))
}
'@
    $diffStub = @'
param(
    [string]$OriginalPath, [uint64]$OriginalRva, [int]$Size,
    [string]$CandidatePath, [string]$CandidateMapPath,
    [string]$CandidateSymbol, [string]$Mask = "", [switch]$DumpHex
)
$candidateRva = if ($CandidateSymbol -match '\+0x70$') {
    "0x00003050"
}
else {
    "0x00003000"
}
Write-Host "Candidate RVA: $candidateRva"
Write-Host "Differences: 0 / $Size"
Write-Host "Hard differences: 0 / $Size"
'@
    $matcherStub = @'
param(
    [string]$ManifestPath, [string]$OriginalPath,
    [string]$OriginalDllPath, [string]$CandidatePath,
    [string]$CandidateMapPath, [string]$CandidateLcmtPath,
    [string]$CandidateLcmtMapPath, [string]$CandidateDllcrtPath,
    [string]$CandidateDllcrtMapPath, [string]$ResultsCsvPath,
    [switch]$SummaryOnly
)
$row = @(Import-Csv -LiteralPath $ManifestPath)[0]
$result = [pscustomobject][ordered]@{
    result_schema_version = 4
    manifest_sha256 = (Get-FileHash -LiteralPath $ManifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
    verification_status = "pass"
    actual_status = "match"
    expected_status = "match"
    raw_match = $true
    mask_shape_valid = $true
    name = $row.name
    program = $row.program
    candidate_dll = ""
    candidate_locator_kind = "candidate_symbol"
    candidate_symbol = $row.candidate_symbol
    candidate_object_qualifier = $row.candidate_object
    candidate_object = $row.candidate_object
    candidate_rva = "0x00003000"
    candidate_file_sha256 = (Get-FileHash -LiteralPath $CandidatePath -Algorithm SHA256).Hash.ToLowerInvariant()
    candidate_map_sha256 = (Get-FileHash -LiteralPath $CandidateMapPath -Algorithm SHA256).Hash.ToLowerInvariant()
    error_message = ""
}
[void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $ResultsCsvPath))
$result | Export-Csv -LiteralPath $ResultsCsvPath -NoTypeInformation
'@
    $maskStub = @'
param(
    [string]$ManifestPath, [string]$OriginalPath,
    [string]$OriginalDllPath, [string]$ResultsCsvPath,
    [switch]$RequireValidated
)
[void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $ResultsCsvPath))
[System.IO.File]::WriteAllText(
    $ResultsCsvPath, "name,program,issue,classification`r`n",
    [System.Text.UTF8Encoding]::new($false))
'@
    $productAuditStub = @'
param(
    [string]$ManifestPath, [string]$ResultsJsonPath,
    [switch]$SummaryOnly
)
$result = [pscustomobject][ordered]@{
    schema_version = 2
    manifest_path = "tools/otmatch/vc4-exe-product-sources.txt"
    null_import_anchor_count = 0
    null_callback_anchor_count = 0
    absolute_code_pointer_anchor_count = 0
    empty_dependency_body_count = 0
    trivial_dependency_body_count = 0
    sink_dependency_body_count = 0
    empty_deallocator_body_count = 0
    recovery_cpp_include_count = 0
    volatile_token_count = 0
    compiler_entropy_marker_count = 0
}
[void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $ResultsJsonPath))
$result | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $ResultsJsonPath -Encoding UTF8
'@
    Write-ContractText (Join-Path $toolRoot "build-match-candidates.ps1") `
        $buildStub
    Write-ContractText (Join-Path $toolRoot "diff-symbol-bytes.ps1") `
        $diffStub
    Write-ContractText (Join-Path $toolRoot "match-functions.ps1") `
        $matcherStub
    Write-ContractText (Join-Path $toolRoot "audit-function-masks.ps1") `
        $maskStub
    Write-ContractText (Join-Path $toolRoot "audit-vc4-product-sources.ps1") `
        $productAuditStub
}

function Invoke-Generator {
    param(
        [string]$Program = "Oregon32.exe",
        [string]$Toolchain = "LegacyMsvc",
        [string]$Output = $evidenceRelative,
        [string]$BuildOutput = $buildRelative
    )
    $arguments = @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
        (Join-Path $sandboxRepoRoot `
            "tools/otmatch/invoke-product-reanchor-evidence.ps1"),
        "-FunctionName", "ContractProductReanchor",
        "-Program", $Program,
        "-SourcePath", $sourceRelative,
        "-CheckpointId", $checkpointId,
        "-PriorBoundaryRunId", $boundaryRunId,
        "-SessionLedgerPath", $ledgerRelative,
        "-BuildOutputDirectory", $BuildOutput,
        "-OutputPath", $Output,
        "-ManifestPath", $manifestRelative,
        "-ProductSourceManifestPath", $productManifestRelative,
        "-TuMetadataPath", "tools/otmatch/vc4-tu-metadata.csv",
        "-OriginalExePath", "originals/original.exe",
        "-OriginalDllPath", "originals/original.dll",
        "-Toolchain", $Toolchain,
        "-PowerShellExecutable", $shellPath)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = @(& $shellPath @arguments 2>&1 |
            ForEach-Object { [string]$_ })
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }
    return [pscustomobject]@{
        ExitCode = [int]$exitCode
        Text = ($output -join " ")
    }
}

function Write-MutatedArtifact {
    param([string]$Name, [scriptblock]$Mutation)
    $artifact = Get-Content -LiteralPath (
        Join-Path $sandboxRepoRoot $evidenceRelative) -Raw | ConvertFrom-Json
    & $Mutation $artifact
    $relative = "a/evidence/$Name.json"
    Write-ContractText (Join-Path $sandboxRepoRoot $relative) `
        (($artifact | ConvertTo-Json -Depth 20) + "`n")
    return $relative
}

function Assert-ArtifactRejected {
    param(
        [string]$RelativePath,
        [string]$ExpectedPattern,
        $BoundaryRun,
        $DossierValidation
    )
    $file = Get-SafePromotionEvidenceFile $RelativePath "focused result"
    $source = Get-SafePromotionEvidenceFile $sourceRelative "source"
    $message = ""
    try {
        [void](Test-PromotionFocusedResult `
            $file "otwin-product-reanchor-evidence" $identity $source `
            $checkpointId $BoundaryRun $DossierValidation `
            $checkpointMetricsSummary $checkpointMapRelative `
            $checkpointVerifierRelative)
    }
    catch {
        $message = $_.Exception.Message
    }
    Assert-True ($message -match $ExpectedPattern) `
        "Malicious artifact '$RelativePath' was not rejected as expected: $message"
}

function Assert-ManifestDeltaRejected {
    param([string]$ExpectedPattern, [string]$BoundaryCommit)
    $prior = Get-GitFileRowsAtCommit $BoundaryCommit $manifestRelative `
        "Contract prior manifest"
    $current = @(Import-Csv -LiteralPath (Join-Path `
        $sandboxRepoRoot $manifestRelative))
    $message = ""
    try {
        [void](Get-ReanchorManifestChange @($prior) $current $identity)
    }
    catch { $message = $_.Exception.Message }
    Assert-True ($message -match $ExpectedPattern) `
        "Invalid live manifest was not rejected as expected: $message"
}

try {
    [void][System.IO.Directory]::CreateDirectory($sandboxRepoRoot)
    Write-ContractText (Join-Path $sandboxRepoRoot ".gitignore") `
        "/a/`r`n/originals/`r`n"
    Write-ToolStubs
    Copy-Item -LiteralPath $generatorSource -Destination (Join-Path `
        $sandboxRepoRoot "tools/otmatch/invoke-product-reanchor-evidence.ps1")
    Write-ContractText (Join-Path $sandboxRepoRoot $productManifestRelative) `
        ($sourceRelative + "`r`n")
    Write-ContractText (Join-Path $sandboxRepoRoot `
        "tools/otmatch/vc4-tu-metadata.csv") `
        "source_path,extra_compile_flags,reason`r`n"
    Write-ContractText (Join-Path $sandboxRepoRoot $sourceRelative) `
        "extern `"C`" int ContractProduct(void) { return 7; }`r`n"
    Write-ContractText (Join-Path $sandboxRepoRoot "originals/original.exe") `
        "contract original exe"
    Write-ContractText (Join-Path $sandboxRepoRoot "originals/original.dll") `
        "contract original dll"
    Write-Manifest -CandidateRva "0x00002000" `
        -CandidateSymbolValue "" -CandidateObjectValue "" `
        -ExpectedStatus "wip" -Notes "Recovery RVA awaiting Product reanchor."

    [void](Invoke-ContractGit @("init", "--quiet"))
    [void](Invoke-ContractGit @("config", "user.name", "Product Reanchor Contract"))
    [void](Invoke-ContractGit @("config", "user.email", "contract@example.invalid"))
    [void](Invoke-ContractGit @("config", "core.autocrlf", "false"))
    [void](Invoke-ContractGit @("add", "."))
    [void](Invoke-ContractGit @("commit", "--quiet", "-m", "contract baseline"))
    $boundaryCommit = [string]@(
        Invoke-ContractGit @("rev-parse", "HEAD"))[0]
    $boundaryCommit = $boundaryCommit.Trim()
    $ledger = [pscustomobject][ordered]@{
        runs = @([pscustomobject][ordered]@{
            run_id = $boundaryRunId
            mode = "execute"
            status = "passed"
            git_snapshot_captured = $true
            git_commit_sha = $boundaryCommit
            worktree_state_sha256 = "e3b0c44298fc1c149afbf4c8996fb924" +
                "27ae41e4649b934ca495991b7852b855"
            worktree_dirty = $false
            git_end_snapshot_captured = $true
            git_end_commit_sha = $boundaryCommit
            end_worktree_state_sha256 =
                "e3b0c44298fc1c149afbf4c8996fb924" +
                "27ae41e4649b934ca495991b7852b855"
            end_worktree_dirty = $false
        })
    }
    Write-ContractText (Join-Path $sandboxRepoRoot $ledgerRelative) `
        (($ledger | ConvertTo-Json -Depth 5) + "`n")
    Write-Manifest

    $dllAttempt = Invoke-Generator -Program "Oregon32.dll" `
        -Output "a/evidence/dll-reanchor.json"
    Assert-True ($dllAttempt.ExitCode -ne 0 -and
        $dllAttempt.Text -match 'restricted to the Oregon32.exe main image') `
        "Generator accepted a DLL Product reanchor: $($dllAttempt.Text)"
    $modernAttempt = Invoke-Generator -Toolchain "ModernVs" `
        -Output "a/evidence/modern-reanchor.json"
    Assert-True ($modernAttempt.ExitCode -ne 0 -and
        $modernAttempt.Text -match 'requires the LegacyMsvc toolchain') `
        "Generator accepted a non-VC4 Product reanchor: $($modernAttempt.Text)"

    $unstableLedger = $ledger | ConvertTo-Json -Depth 6 | ConvertFrom-Json
    $unstableLedger.runs[0].git_end_snapshot_captured = $false
    Write-ContractText (Join-Path $sandboxRepoRoot $ledgerRelative) `
        (($unstableLedger | ConvertTo-Json -Depth 6) + "`n")
    $unstableBoundaryAttempt = Invoke-Generator `
        -Output "a/evidence/unstable-boundary.json"
    Assert-True ($unstableBoundaryAttempt.ExitCode -ne 0 -and
        $unstableBoundaryAttempt.Text -match
            'captured clean start and end worktrees') `
        "Generator accepted an unstable prior boundary: $($unstableBoundaryAttempt.Text)"
    Write-ContractText (Join-Path $sandboxRepoRoot $ledgerRelative) `
        (($ledger | ConvertTo-Json -Depth 6) + "`n")

    Write-Manifest -CandidateSymbolValue `
        "_ContractProductContainer@16+0x70"
    $oversizedOffsetAttempt = Invoke-Generator `
        -Output "a/evidence/oversized-offset.json" `
        -BuildOutput "a/evidence/oversized-offset-build"
    Assert-True ($oversizedOffsetAttempt.ExitCode -ne 0 -and
        $oversizedOffsetAttempt.Text -match 'escapes.*next public') `
        "Generator accepted an oversized Product-symbol offset: $($oversizedOffsetAttempt.Text)"
    Write-Manifest

    $generatorResult = Invoke-Generator
    Assert-True ($generatorResult.ExitCode -eq 0) `
        "Positive Product-reanchor generator case failed: $($generatorResult.Text)"
    [void](Invoke-ContractGit @("add", $manifestRelative))
    [void](Invoke-ContractGit @(
        "commit", "--quiet", "-m", "commit Product reanchor"))

    $generatorTokens = $null
    $generatorParseErrors = $null
    $generatorAst =
        [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $sandboxRepoRoot `
                "tools/otmatch/invoke-product-reanchor-evidence.ps1"),
            [ref]$generatorTokens, [ref]$generatorParseErrors)
    Assert-True ($generatorParseErrors.Count -eq 0) `
        "Generator cannot be parsed for the owner-collision contract."
    $ownerFunctionText = @($generatorAst.EndBlock.Statements |
        Where-Object {
            $_ -is
                [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $_.Name -in @(
                "Get-ObjectNameForSource",
                "Assert-UniqueProductObjectOwner")
        } | ForEach-Object { $_.Extent.Text }) -join "`r`n`r`n"
    . ([scriptblock]::Create($ownerFunctionText))
    $message = ""
    try {
        Assert-UniqueProductObjectOwner @(
            $sourceRelative, "src/otwin_product.cpp") $candidateObject
    }
    catch { $message = $_.Exception.Message }
    Assert-True ($message -match 'not uniquely owned by one Product source') `
        "Generator accepted a colliding Product-object owner: $message"

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $orchestratorSource, [ref]$tokens, [ref]$parseErrors)
    Assert-True ($parseErrors.Count -eq 0) `
        "Orchestrator cannot be parsed for the focused contract."
    $functionText = @($ast.EndBlock.Statements | Where-Object {
        $_ -is [System.Management.Automation.Language.FunctionDefinitionAst]
    } | ForEach-Object { $_.Extent.Text }) -join "`r`n`r`n"
    $repoRoot = $sandboxRepoRoot
    $ManifestPath = $manifestRelative
    . ([scriptblock]::Create($functionText))

    $boundaryRun = $ledger.runs[0]
    $dossierValidation = [pscustomobject]@{
        candidate_symbol = $candidateSymbol
        candidate_object = $candidateObject
    }
    $currentRows = @(Import-Csv -LiteralPath (Join-Path `
        $sandboxRepoRoot $manifestRelative))
    $priorRows = Get-GitFileRowsAtCommit $boundaryCommit $manifestRelative `
        "Contract symbolic prior manifest"
    $symbolicPrior = $priorRows[0] | ConvertTo-Json -Depth 4 |
        ConvertFrom-Json
    $symbolicPrior.candidate_rva = ""
    $symbolicPrior.candidate_symbol = $candidateSymbol
    $symbolicPrior.candidate_object = "src_otwin_recovery.obj"
    [void](Get-ReanchorManifestChange @($symbolicPrior) $currentRows $identity)
    $symbolicPrior.candidate_object = ""
    $message = ""
    try {
        [void](Get-ReanchorManifestChange `
            @($symbolicPrior) $currentRows $identity)
    }
    catch { $message = $_.Exception.Message }
    Assert-True ($message -match 'prior candidate_symbol requires candidate_object') `
        "Symbolic prior without a recovery object was accepted."

    $focusedFile = Get-SafePromotionEvidenceFile `
        $evidenceRelative "focused result"
    $sourceFile = Get-SafePromotionEvidenceFile $sourceRelative "source"

    $checkpointMapAbsolute = Join-Path $sandboxRepoRoot `
        $checkpointMapRelative
    $checkpointVerifierAbsolute = Join-Path $sandboxRepoRoot `
        $checkpointVerifierRelative
    [void][System.IO.Directory]::CreateDirectory(
        (Split-Path -Parent $checkpointMapAbsolute))
    [System.IO.File]::WriteAllBytes(
        $checkpointMapAbsolute,
        [System.IO.File]::ReadAllBytes((Join-Path $sandboxRepoRoot `
            "$buildRelative/otwin-match-candidates.map")))
    [System.IO.File]::WriteAllBytes(
        $checkpointVerifierAbsolute,
        [System.IO.File]::ReadAllBytes((Join-Path $sandboxRepoRoot `
            "a/evidence/product-reanchor.function-match-results.csv")))
    $checkpointRows = @(Import-Csv -LiteralPath $checkpointVerifierAbsolute)
    $checkpointRows[0].candidate_map_sha256 =
        Get-ContractSha256 $checkpointMapAbsolute
    $checkpointCsv = @($checkpointRows | ConvertTo-Csv -NoTypeInformation) `
        -join "`r`n"
    Write-ContractText $checkpointVerifierAbsolute ($checkpointCsv + "`r`n")
    $checkpointMetricsSummary = [pscustomobject]@{
        inputs = [pscustomobject]@{
            verifier_results = [pscustomobject]@{
                path = $checkpointVerifierRelative
                sha256 = Get-ContractSha256 $checkpointVerifierAbsolute
            }
        }
    }
    $positive = Test-PromotionFocusedResult `
        $focusedFile "otwin-product-reanchor-evidence" $identity $sourceFile `
        $checkpointId $boundaryRun $dossierValidation `
        $checkpointMetricsSummary $checkpointMapRelative `
        $checkpointVerifierRelative
    Assert-True ([string]$positive.evidence_mode -ceq "product-reanchor" -and
        [uint64]$positive.raw_diff_count -eq 0 -and
        [uint64]$positive.hard_diff_count -eq 0 -and
        [string]$positive.symbol_containment.base_symbol -ceq
            "_ContractProductContainer@16" -and
        [string]$positive.symbol_containment.base_object -ceq
            $candidateObject -and
        [string]$positive.symbol_containment.target_rva -ceq "0x3000" -and
        [string]$positive.symbol_containment.next_public_rva -ceq "0x3040" -and
        [string]$positive.checkpoint_symbol_containment.target_rva -ceq
            "0x3000" -and
        [string]$positive.checkpoint_symbol_containment.next_public_rva -ceq
            "0x3040") `
        "Valid generated Product-reanchor evidence did not pass dispatch."

    $candidateMapAbsolute = Join-Path $sandboxRepoRoot `
        "$buildRelative/otwin-match-candidates.map"
    $message = ""
    try {
        [void](Get-ProductReanchorSymbolContainment `
            $candidateMapAbsolute $candidateSymbol `
            "src_otwin_wrong_owner.obj" ([uint64]0x3000) ([uint64]0x10))
    }
    catch { $message = $_.Exception.Message }
    Assert-True ($message -match 'base public.*wrong_owner.*missing or ambiguous') `
        "Containment accepted a mismatched object qualifier: $message"
    $message = ""
    try {
        [void](Get-ProductReanchorSymbolContainment `
            $candidateMapAbsolute "_ContractProductContainer@16+0x70" `
            $candidateObject ([uint64]0x3050) ([uint64]0x10))
    }
    catch { $message = $_.Exception.Message }
    Assert-True ($message -match 'escapes.*next public') `
        "Containment accepted an offset crossing the next public: $message"

    $checkpointMapBytes = [System.IO.File]::ReadAllBytes(
        $checkpointMapAbsolute)
    $checkpointVerifierBytes = [System.IO.File]::ReadAllBytes(
        $checkpointVerifierAbsolute)
    try {
        $checkpointMapText =
            [System.IO.File]::ReadAllText($checkpointMapAbsolute).
                Replace("0001:00002040", "0001:00002008").
                Replace("10003040", "10003008")
        Write-ContractText $checkpointMapAbsolute $checkpointMapText
        $checkpointRows = @(
            Import-Csv -LiteralPath $checkpointVerifierAbsolute)
        $checkpointRows[0].candidate_map_sha256 =
            Get-ContractSha256 $checkpointMapAbsolute
        $checkpointCsv = @(
            $checkpointRows | ConvertTo-Csv -NoTypeInformation) -join "`r`n"
        Write-ContractText $checkpointVerifierAbsolute `
            ($checkpointCsv + "`r`n")
        $checkpointMetricsSummary.inputs.verifier_results.sha256 =
            Get-ContractSha256 $checkpointVerifierAbsolute
        Assert-ArtifactRejected $evidenceRelative `
            'escapes.*next public' $boundaryRun $dossierValidation
    }
    finally {
        [System.IO.File]::WriteAllBytes(
            $checkpointMapAbsolute, $checkpointMapBytes)
        [System.IO.File]::WriteAllBytes(
            $checkpointVerifierAbsolute, $checkpointVerifierBytes)
        $checkpointMetricsSummary.inputs.verifier_results.sha256 =
            Get-ContractSha256 $checkpointVerifierAbsolute
    }

    Assert-PromotionFocusedArtifactComposition @(
        "otwin-product-reanchor-evidence")
    foreach ($composition in @(
            @("otwin-product-reanchor-evidence", "otwin-source-shape-evidence"),
            @("otwin-product-reanchor-evidence", "otwin-product-reanchor-evidence"))) {
        $message = ""
        try {
            Assert-PromotionFocusedArtifactComposition $composition
        }
        catch { $message = $_.Exception.Message }
        Assert-True ($message -match 'only entry.*one-promotion document') `
            "Mixed/multi-row Product-reanchor document was not rejected."
    }

    Assert-ArtifactRejected `
        (Write-MutatedArtifact "stale-manifest" {
            param($a) $a.manifest_delta.current_sha256 = "0" * 64
        }) 'manifest binding is stale' $boundaryRun $dossierValidation
    Assert-ArtifactRejected `
        (Write-MutatedArtifact "stale-generator" {
            param($a) $a.generator.script_sha256 = "0" * 64
        }) 'generator SHA256 is stale' $boundaryRun $dossierValidation
    Assert-ArtifactRejected `
        (Write-MutatedArtifact "stale-build-tool" {
            param($a) $a.build.tool.sha256 = "0" * 64
        }) 'build tool SHA256 is stale' $boundaryRun $dossierValidation
    Assert-ArtifactRejected `
        (Write-MutatedArtifact "wrong-toolchain" {
            param($a) $a.build.toolchain = "ModernVs"
        }) 'build configuration is not canonical' $boundaryRun $dossierValidation
    Assert-ArtifactRejected `
        (Write-MutatedArtifact "wrong-optimization" {
            param($a) $a.build.semantic_optimization = "/Od"
        }) 'build configuration is not canonical' $boundaryRun $dossierValidation
    Assert-ArtifactRejected `
        (Write-MutatedArtifact "stale-tu-metadata" {
            param($a) $a.build.tu_metadata.sha256 = "0" * 64
        }) 'TU metadata SHA256 is stale' $boundaryRun $dossierValidation
    Assert-ArtifactRejected `
        (Write-MutatedArtifact "stale-containment" {
            param($a) $a.symbol_containment.base_rva = "0x2fe1"
        }) "symbol-containment proof is stale at 'base_rva'" `
        $boundaryRun $dossierValidation
    Assert-ArtifactRejected `
        (Write-MutatedArtifact "wrong-containment-owner" {
            param($a) $a.symbol_containment.base_object =
                "src_otwin_wrong_owner.obj"
        }) "symbol-containment proof is stale at 'base_object'" `
        $boundaryRun $dossierValidation

    $candidateMapBytes = [System.IO.File]::ReadAllBytes(
        $candidateMapAbsolute)
    $verifierAbsolute = Join-Path $sandboxRepoRoot `
        "a/evidence/product-reanchor.function-match-results.csv"
    $verifierBytes = [System.IO.File]::ReadAllBytes($verifierAbsolute)
    try {
        $mapText = [System.IO.File]::ReadAllText($candidateMapAbsolute).
            Replace("0001:00002040", "0001:00002030").
            Replace("10003040", "10003030")
        Write-ContractText $candidateMapAbsolute $mapText
        $tamperedMapHash = Get-ContractSha256 $candidateMapAbsolute

        $verifierRows = @(Import-Csv -LiteralPath $verifierAbsolute)
        $verifierRows[0].candidate_map_sha256 = $tamperedMapHash
        $verifierCsv = @($verifierRows | ConvertTo-Csv -NoTypeInformation) `
            -join "`r`n"
        Write-ContractText $verifierAbsolute ($verifierCsv + "`r`n")

        $mapArtifact = Get-Content -LiteralPath (Join-Path `
            $sandboxRepoRoot $evidenceRelative) -Raw | ConvertFrom-Json
        $mapArtifact.build.candidate_map.sha256 = $tamperedMapHash
        $mapArtifact.build.candidate_map.length =
            [long](Get-Item -LiteralPath $candidateMapAbsolute).Length
        $mapArtifact.symbol_containment.map_sha256 = $tamperedMapHash
        $mapArtifact.verifier.results.sha256 =
            Get-ContractSha256 $verifierAbsolute
        $mapArtifact.verifier.results.length =
            [long](Get-Item -LiteralPath $verifierAbsolute).Length
        $mapArtifactRelative = "a/evidence/self-consistent-map-tamper.json"
        Write-ContractText (Join-Path $sandboxRepoRoot $mapArtifactRelative) `
            (($mapArtifact | ConvertTo-Json -Depth 20) + "`n")
        Assert-ArtifactRejected $mapArtifactRelative `
            "symbol-containment proof is stale at 'next_public_rva'" `
            $boundaryRun $dossierValidation
    }
    finally {
        [System.IO.File]::WriteAllBytes(
            $candidateMapAbsolute, $candidateMapBytes)
        [System.IO.File]::WriteAllBytes($verifierAbsolute, $verifierBytes)
    }

    Assert-ArtifactRejected `
        (Write-MutatedArtifact "nonzero-raw" {
            param($a) $a.focused_diff.raw_diff_count = 1
        }) 'focused diff is not zero raw and zero hard' `
        $boundaryRun $dossierValidation
    Assert-ArtifactRejected `
        (Write-MutatedArtifact "wrong-locator" {
            param($a) $a.verifier.candidate_locator_kind = "candidate_rva"
        }) 'verifier locator disagrees' $boundaryRun $dossierValidation
    Assert-ArtifactRejected `
        (Write-MutatedArtifact "secondary-image" {
            param($a) $a.verifier.candidate_dll = "contract.dll"
        }) 'verifier locator disagrees' $boundaryRun $dossierValidation
    Assert-ArtifactRejected `
        (Write-MutatedArtifact "source-blob" {
            param($a) $a.source.current_git_blob_oid = "0" * 40
        }) 'source does not exactly match the prior boundary bytes' `
        $boundaryRun $dossierValidation
    Assert-ArtifactRejected `
        (Write-MutatedArtifact "source-mutation" {
            param($a) $a.source_mutation.attempted = $true
        }) 'source mutation must be unattempted' $boundaryRun $dossierValidation
    $dirtyBoundary = $boundaryRun | ConvertTo-Json -Depth 4 | ConvertFrom-Json
    $dirtyBoundary.worktree_dirty = $true
    Assert-ArtifactRejected $evidenceRelative `
        'prior boundary must be clean and committed' `
        $dirtyBoundary $dossierValidation
    $dirtyEndBoundary = $boundaryRun | ConvertTo-Json -Depth 4 |
        ConvertFrom-Json
    $dirtyEndBoundary.end_worktree_dirty = $true
    Assert-ArtifactRejected $evidenceRelative `
        'prior boundary must be clean and committed' `
        $dirtyEndBoundary $dossierValidation
    $unstableCommitBoundary = $boundaryRun | ConvertTo-Json -Depth 4 |
        ConvertFrom-Json
    $unstableCommitBoundary.git_end_commit_sha = "0" * 40
    Assert-ArtifactRejected $evidenceRelative `
        'prior boundary must bind one clean, stable commit' `
        $unstableCommitBoundary $dossierValidation
    $unstableStateBoundary = $boundaryRun | ConvertTo-Json -Depth 4 |
        ConvertFrom-Json
    $unstableStateBoundary.end_worktree_state_sha256 = "0" * 64
    Assert-ArtifactRejected $evidenceRelative `
        'prior boundary must bind one clean, stable commit' `
        $unstableStateBoundary $dossierValidation
    $unignoredArtifact = "evidence/unignored-product-reanchor.json"
    Write-ContractText (Join-Path $sandboxRepoRoot $unignoredArtifact) `
        (Get-Content -LiteralPath (Join-Path `
            $sandboxRepoRoot $evidenceRelative) -Raw)
    Assert-ArtifactRejected $unignoredArtifact `
        'focused evidence must remain below ignored' `
        $boundaryRun $dossierValidation

    $currentManifestBytes = [System.IO.File]::ReadAllBytes((Join-Path `
        $sandboxRepoRoot $manifestRelative))
    try {
        Write-Manifest -Notes "Uncommitted Product reanchor note."
        Assert-ArtifactRejected $evidenceRelative `
            'requires a clean current worktree' `
            $boundaryRun $dossierValidation
        Write-Manifest -CandidateRva "0x00002000"
        Assert-ManifestDeltaRejected `
            'current row must use only.*candidate_symbol' $boundaryCommit
        Write-Manifest -CandidateVa "0x00403000"
        Assert-ManifestDeltaRejected `
            'changed forbidden manifest fields.*candidate_va' $boundaryCommit
        Write-Manifest -CandidateDll "contract.dll"
        Assert-ManifestDeltaRejected `
            'changed forbidden manifest fields.*candidate_dll' $boundaryCommit
        Write-Manifest -Notes ""
        Assert-ManifestDeltaRejected `
            'current row must carry a nonblank semantic note' $boundaryCommit
        Write-Manifest
        $extraFieldRow = @(Import-Csv -LiteralPath (Join-Path `
            $sandboxRepoRoot $manifestRelative))[0]
        $extraFieldRow | Add-Member -NotePropertyName `
            "unexpected_contract_field" -NotePropertyValue "tamper"
        @($extraFieldRow) | Export-Csv -LiteralPath (Join-Path `
            $sandboxRepoRoot $manifestRelative) -NoTypeInformation
        Assert-ManifestDeltaRejected `
            'Current manifest has noncanonical fields' $boundaryCommit
        Write-Manifest
        $currentRow = @(Import-Csv -LiteralPath (Join-Path `
            $sandboxRepoRoot $manifestRelative))[0]
        @($currentRow, $currentRow) | Export-Csv -LiteralPath (Join-Path `
            $sandboxRepoRoot $manifestRelative) -NoTypeInformation
        Assert-ManifestDeltaRejected 'manifest row count changed' $boundaryCommit
    }
    finally {
        [System.IO.File]::WriteAllBytes((Join-Path `
            $sandboxRepoRoot $manifestRelative), $currentManifestBytes)
    }

    $sourceBytes = [System.IO.File]::ReadAllBytes((Join-Path `
        $sandboxRepoRoot $sourceRelative))
    try {
        [System.IO.File]::AppendAllText((Join-Path `
            $sandboxRepoRoot $sourceRelative), "tamper")
        Assert-ArtifactRejected $evidenceRelative `
            'requires a clean current worktree' `
            $boundaryRun $dossierValidation
    }
    finally {
        [System.IO.File]::WriteAllBytes((Join-Path `
            $sandboxRepoRoot $sourceRelative), $sourceBytes)
    }

    $documentRelative = "a/evidence/promotion-document.json"
    $dossierRelative = "a/evidence/reviewed-dossier.json"
    Write-ContractText (Join-Path $sandboxRepoRoot $documentRelative) "{}`n"
    Write-ContractText (Join-Path $sandboxRepoRoot $dossierRelative) "{}`n"
    $endEvidence = [pscustomobject]@{
        validated = $true
        end_verified = $false
        end_error = ""
        repository_relative_path = $documentRelative
        sha256 = Get-ContractSha256 (Join-Path $sandboxRepoRoot $documentRelative)
        bindings = @([pscustomobject]@{
            dossier = Get-SafePromotionEvidenceFile $dossierRelative "dossier"
            source = $sourceFile
            focused_result = $focusedFile
            dossier_validation = [pscustomobject]@{ provenance_files = @() }
            focused_result_validation = $positive
        })
    }
    Assert-PromotionEvidenceEndBoundary $endEvidence
    Assert-True ([bool]$endEvidence.end_verified) `
        "Product provenance did not survive the positive end-boundary rehash."

    $savedNextPublicRva =
        [string]$positive.symbol_containment.next_public_rva
    try {
        $positive.symbol_containment.next_public_rva = "0x3041"
        $message = ""
        try { Assert-PromotionEvidenceEndBoundary $endEvidence }
        catch { $message = $_.Exception.Message }
        Assert-True ($message -match
            "symbol-containment proof is stale at 'next_public_rva'") `
            "End boundary did not recompute symbol containment: $message"
    }
    finally {
        $positive.symbol_containment.next_public_rva = $savedNextPublicRva
    }

    $savedCheckpointNextPublicRva =
        [string]$positive.checkpoint_symbol_containment.next_public_rva
    try {
        $positive.checkpoint_symbol_containment.next_public_rva = "0x3041"
        $message = ""
        try { Assert-PromotionEvidenceEndBoundary $endEvidence }
        catch { $message = $_.Exception.Message }
        Assert-True ($message -match
            "symbol-containment proof is stale at 'next_public_rva'") `
            "End boundary did not recompute checkpoint containment: $message"
    }
    finally {
        $positive.checkpoint_symbol_containment.next_public_rva =
            $savedCheckpointNextPublicRva
    }

    foreach ($provenance in @(
            @($positive.provenance_files) +
            @($positive.checkpoint_provenance_files))) {
        $provenancePath = [string]$provenance.absolute_path
        $provenanceBytes = [System.IO.File]::ReadAllBytes($provenancePath)
        try {
            [System.IO.File]::AppendAllText($provenancePath, "tamper")
            $message = ""
            try { Assert-PromotionEvidenceEndBoundary $endEvidence }
            catch { $message = $_.Exception.Message }
            Assert-True ($message -match 'length is stale') `
                ("End-boundary {0} tamper was not rejected: {1}" -f
                    $provenance.role, $message)
        }
        finally {
            [System.IO.File]::WriteAllBytes(
                $provenancePath, $provenanceBytes)
        }
    }

    Write-Host "Product-reanchor evidence contract: PASS"
}
finally {
    $allowedRoot = [System.IO.Path]::GetFullPath((Join-Path $hostRepoRoot "a"))
    $allowedPrefix = $allowedRoot.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    if ($contractRoot.StartsWith(
            $allowedPrefix,
            [System.StringComparison]::OrdinalIgnoreCase) -and
        (Test-Path -LiteralPath $contractRoot -PathType Container)) {
        Remove-Item -LiteralPath $contractRoot -Recurse -Force
    }
}
