[CmdletBinding()]
param(
    [string]$LockPath = "artifacts\otmatch\.candidate-graph.lock",
    [switch]$AsJson
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$observedUtc = [DateTime]::UtcNow

function Get-ConfiguredFullPath([string]$Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $repoRoot $Path))
}

function Get-DisplayPath([string]$Path) {
    $prefix = $repoRoot.TrimEnd('\', '/') +
        [System.IO.Path]::DirectorySeparatorChar
    if ($Path.StartsWith(
            $prefix,
            [System.StringComparison]::OrdinalIgnoreCase)) {
        return $Path.Substring($prefix.Length).Replace('\', '/')
    }
    return $Path
}

function Get-PlanPathFromCommandLine([string]$CommandLine) {
    if ([string]::IsNullOrWhiteSpace($CommandLine)) {
        return ""
    }
    $match = [regex]::Match(
        $CommandLine,
        '(?i)(?:-|/)PlanPath(?:\s+|=)(?:"(?<double>[^"]+)"|''(?<single>[^'']+)''|(?<bare>[^\s;]+))')
    if (-not $match.Success) {
        return ""
    }
    foreach ($groupName in @("double", "single", "bare")) {
        $value = $match.Groups[$groupName].Value
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value
        }
    }
    return ""
}

function Test-FileLocked([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $false
    }
    $stream = $null
    try {
        $stream = [System.IO.File]::Open(
            $Path,
            [System.IO.FileMode]::Open,
            [System.IO.FileAccess]::Read,
            [System.IO.FileShare]::None)
        return $false
    } catch [System.IO.IOException] {
        return $true
    } finally {
        if ($null -ne $stream) {
            $stream.Dispose()
        }
    }
}

if (-not ("Otmatch.CandidateGraphLockInspector" -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

namespace Otmatch
{
    public static class CandidateGraphLockInspector
    {
        private const int ErrorMoreData = 234;
        private const int MaxAppName = 255;
        private const int MaxServiceName = 63;

        [StructLayout(LayoutKind.Sequential)]
        private struct RmUniqueProcess
        {
            public int ProcessId;
            public System.Runtime.InteropServices.ComTypes.FILETIME ProcessStartTime;
        }

        private enum RmAppType
        {
            Unknown = 0,
            MainWindow = 1,
            OtherWindow = 2,
            Service = 3,
            Explorer = 4,
            Console = 5,
            Critical = 1000
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct RmProcessInfo
        {
            public RmUniqueProcess Process;

            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = MaxAppName + 1)]
            public string AppName;

            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = MaxServiceName + 1)]
            public string ServiceShortName;

            public RmAppType ApplicationType;
            public uint AppStatus;
            public uint TerminalSessionId;

            [MarshalAs(UnmanagedType.Bool)]
            public bool Restartable;
        }

        [DllImport("rstrtmgr.dll", CharSet = CharSet.Unicode)]
        private static extern int RmStartSession(
            out uint sessionHandle,
            int sessionFlags,
            StringBuilder sessionKey);

        [DllImport("rstrtmgr.dll", CharSet = CharSet.Unicode)]
        private static extern int RmRegisterResources(
            uint sessionHandle,
            uint fileCount,
            string[] fileNames,
            uint applicationCount,
            IntPtr applications,
            uint serviceCount,
            string[] serviceNames);

        [DllImport("rstrtmgr.dll")]
        private static extern int RmGetList(
            uint sessionHandle,
            out uint processInfoNeeded,
            ref uint processInfoCount,
            [In, Out] RmProcessInfo[] affectedApplications,
            ref uint rebootReasons);

        [DllImport("rstrtmgr.dll")]
        private static extern int RmEndSession(uint sessionHandle);

        public static int[] GetLockingProcessIds(string path)
        {
            uint sessionHandle;
            StringBuilder sessionKey = new StringBuilder(64);
            int result = RmStartSession(out sessionHandle, 0, sessionKey);
            if (result != 0)
            {
                throw new InvalidOperationException(
                    "RmStartSession failed with Win32 error " + result + ".");
            }

            try
            {
                result = RmRegisterResources(
                    sessionHandle,
                    1,
                    new[] { path },
                    0,
                    IntPtr.Zero,
                    0,
                    null);
                if (result != 0)
                {
                    throw new InvalidOperationException(
                        "RmRegisterResources failed with Win32 error " + result + ".");
                }

                uint needed = 0;
                uint count = 0;
                uint rebootReasons = 0;
                result = RmGetList(
                    sessionHandle,
                    out needed,
                    ref count,
                    null,
                    ref rebootReasons);
                if (result == 0)
                {
                    return new int[0];
                }
                if (result != ErrorMoreData)
                {
                    throw new InvalidOperationException(
                        "RmGetList(size) failed with Win32 error " + result + ".");
                }

                RmProcessInfo[] processes = new RmProcessInfo[needed];
                count = needed;
                result = RmGetList(
                    sessionHandle,
                    out needed,
                    ref count,
                    processes,
                    ref rebootReasons);
                if (result != 0)
                {
                    throw new InvalidOperationException(
                        "RmGetList(data) failed with Win32 error " + result + ".");
                }

                List<int> ids = new List<int>();
                for (int index = 0; index < count; index++)
                {
                    int id = processes[index].Process.ProcessId;
                    if (!ids.Contains(id))
                    {
                        ids.Add(id);
                    }
                }
                return ids.ToArray();
            }
            finally
            {
                RmEndSession(sessionHandle);
            }
        }
    }
}
'@
}

$resolvedLockPath = Get-ConfiguredFullPath $LockPath
$locked = Test-FileLocked $resolvedLockPath
$processIds = @()
$ownerResolution = if ($locked) { "restart-manager" } else { "not-needed" }
if ($locked) {
    try {
        $processIds = @([Otmatch.CandidateGraphLockInspector]::
            GetLockingProcessIds($resolvedLockPath))
    } catch {
        $ownerResolution = "command-line-fallback"
    }

    if ($processIds.Count -eq 0) {
        # Restart Manager can be unavailable under restricted process tokens.
        # An exact lock-path command-line match is a read-only, conservative
        # fallback used only while the file is independently proven locked.
        try {
            $escapedLockPath = [regex]::Escape($resolvedLockPath)
            $lockPathTokenPattern = ('(?i)(?<!\S)(?:"{0}"|''{0}''|{0})(?!\S)' -f
                $escapedLockPath)
            $processIds = @(Get-CimInstance Win32_Process -ErrorAction Stop |
                Where-Object {
                    [string]$_.CommandLine -match $lockPathTokenPattern
                } | ForEach-Object { [int]$_.ProcessId } | Select-Object -Unique)
            if ($processIds.Count -gt 0) {
                $ownerResolution = "command-line-fallback"
            } else {
                $ownerResolution = "unresolved"
            }
        } catch {
            $ownerResolution = "unresolved"
        }
    }
}

$owners = @()
foreach ($processId in $processIds) {
    $processName = "unknown"
    $commandLine = ""
    $startedUtc = $null
    try {
        $cimProcess = Get-CimInstance Win32_Process -Filter (
            "ProcessId = {0}" -f $processId) -ErrorAction Stop
        if ($null -ne $cimProcess) {
            $processName = [string]$cimProcess.Name
            $commandLine = [string]$cimProcess.CommandLine
            if ($null -ne $cimProcess.CreationDate) {
                $startedUtc = ([DateTime]$cimProcess.CreationDate).ToUniversalTime()
            }
        }
    } catch {
        try {
            $nativeProcess = Get-Process -Id $processId -ErrorAction Stop
            $processName = [string]$nativeProcess.ProcessName
            $startedUtc = $nativeProcess.StartTime.ToUniversalTime()
        } catch {
            # The owner can exit between the lock probe and process query.
        }
    }

    $ageSeconds = $null
    $age = "unknown"
    if ($null -ne $startedUtc) {
        $elapsed = $observedUtc - $startedUtc
        if ($elapsed.TotalSeconds -lt 0) {
            $elapsed = [TimeSpan]::Zero
        }
        $ageSeconds = [long][Math]::Floor($elapsed.TotalSeconds)
        $age = $elapsed.ToString("c", [System.Globalization.CultureInfo]::InvariantCulture)
    }
    $plan = Get-PlanPathFromCommandLine $commandLine
    if ([string]::IsNullOrWhiteSpace($plan)) {
        $plan = "unknown"
    }
    $owners += [pscustomobject][ordered]@{
        pid = [int]$processId
        process = $processName
        started_utc = if ($null -eq $startedUtc) {
            ""
        } else {
            $startedUtc.ToString("o")
        }
        age = $age
        age_seconds = $ageSeconds
        plan = $plan
    }
}

$primaryOwner = if ($owners.Count -gt 0) {
    "{0} (PID {1})" -f $owners[0].process, $owners[0].pid
} elseif ($locked) {
    "unresolved"
} else {
    "none"
}
$primaryPlan = if ($owners.Count -gt 0) {
    [string]$owners[0].plan
} elseif ($locked) {
    "unknown"
} else {
    "none"
}
$primaryAge = if ($owners.Count -gt 0) {
    [string]$owners[0].age
} elseif ($locked) {
    "unknown"
} else {
    "00:00:00"
}

$result = [pscustomobject][ordered]@{
    schema_version = 1
    artifact_type = "otwin-candidate-graph-lock-status"
    observed_utc = $observedUtc.ToString("o")
    lock_path = Get-DisplayPath $resolvedLockPath
    status = if ($locked) { "locked" } else { "unlocked" }
    locked = [bool]$locked
    owner = $primaryOwner
    plan = $primaryPlan
    age = $primaryAge
    owner_resolution = $ownerResolution
    owner_count = $owners.Count
    owners = @($owners)
}

if ($AsJson) {
    $result | ConvertTo-Json -Depth 8
} else {
    Write-Host ("Candidate graph lock: {0}" -f $result.status.ToUpperInvariant())
    Write-Host ("Owner: {0}" -f $result.owner)
    Write-Host ("Plan:  {0}" -f $result.plan)
    Write-Host ("Age:   {0}" -f $result.age)
    $result
}
