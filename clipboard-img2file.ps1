<#
.SYNOPSIS
    Clipboard Image to File - Auto-convert clipboard bitmap to file path.

.DESCRIPTION
    Monitors clipboard for bitmap image data, saves it as a PNG file,
    and replaces clipboard content with the file path.

    Designed for CLI tools (like Claude Code) that accept file paths
    but not raw bitmap data from clipboard.

.PARAMETER Status
    Show current running status and configuration.

.PARAMETER SaveDir
    Directory to save screenshots.
    Default: $env:TEMP\clipboard-img2file

.PARAMETER MaxKeep
    Maximum number of screenshots to keep. Oldest are deleted first.
    Default: 5

.PARAMETER PollMs
    Clipboard polling interval in milliseconds.
    Default: 500

.PARAMETER Silent
    Suppress console output (useful for background execution).

.EXAMPLE
    .\clipboard-img2file.ps1

.EXAMPLE
    .\clipboard-img2file.ps1 -SaveDir "D:\screenshots" -MaxKeep 10

.EXAMPLE
    .\clipboard-img2file.ps1 -Status

.LINK
    https://github.com/Sebastilan/clipboard-img2file
#>

[CmdletBinding(DefaultParameterSetName = 'Run')]
param(
    [Parameter(ParameterSetName = 'Status')]
    [switch]$Status,

    [Parameter(ParameterSetName = 'Run')]
    [string]$SaveDir = "$env:TEMP\clipboard-img2file",

    [Parameter(ParameterSetName = 'Run')]
    [int]$MaxKeep = 5,

    [Parameter(ParameterSetName = 'Run')]
    [int]$PollMs = 500,

    [Parameter(ParameterSetName = 'Run')]
    [switch]$Silent
)

# ============================================================
# Constants
# ============================================================
$AppName    = "ClipboardImg2File"
$MutexName  = "Global\$AppName"
$TaskName   = $AppName
$InstallDir = "$env:LOCALAPPDATA\clipboard-img2file"
$LogDir     = "$env:TEMP\clipboard-img2file"
$LogFile    = "$LogDir\monitor.log"
$MaxLogSize = 1MB

# ============================================================
# Helpers
# ============================================================
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] [$Level] $Message"

    if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

    # Rotate log if too large
    if ((Test-Path $LogFile) -and (Get-Item $LogFile).Length -gt $MaxLogSize) {
        $bak = "$LogFile.bak"
        if (Test-Path $bak) { Remove-Item $bak -Force }
        Rename-Item $LogFile $bak
    }

    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue

    if (-not $Silent) {
        switch ($Level) {
            "ERROR" { Write-Host $line -ForegroundColor Red }
            "WARN"  { Write-Host $line -ForegroundColor Yellow }
            "OK"    { Write-Host $line -ForegroundColor Green }
            default { Write-Host $line }
        }
    }
}

function Test-STA {
    return ([Threading.Thread]::CurrentThread.GetApartmentState() -eq 'STA')
}

function Get-RunningProcess {
    Get-WmiObject Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -like '*clipboard-img2file*' -and $_.ProcessId -ne $PID }
}

# ============================================================
# -Status
# ============================================================
if ($Status) {
    Write-Host ""
    Write-Host "=== $AppName Status ===" -ForegroundColor Cyan

    # Install location
    $installed = Test-Path "$InstallDir\clipboard-img2file.ps1"
    if ($installed) {
        Write-Host "  Installed: $InstallDir" -ForegroundColor Green
    } else {
        Write-Host "  Installed: NO" -ForegroundColor Yellow
    }

    # Process
    $proc = Get-RunningProcess
    if ($proc) {
        Write-Host "  Process  : RUNNING (PID=$($proc.ProcessId))" -ForegroundColor Green
    } else {
        Write-Host "  Process  : NOT RUNNING" -ForegroundColor Yellow
    }

    # Task Scheduler
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($task) {
        Write-Host "  AutoStart: ENABLED ($($task.State))" -ForegroundColor Green
    } else {
        Write-Host "  AutoStart: DISABLED" -ForegroundColor Yellow
    }

    # Files
    $defaultDir = "$env:TEMP\clipboard-img2file"
    $files = Get-ChildItem $defaultDir -Filter "*.png" -ErrorAction SilentlyContinue
    $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
    Write-Host "  SaveDir  : $defaultDir"
    Write-Host "  Files    : $($files.Count) ($([math]::Round($totalSize / 1KB, 1)) KB)"

    # Log
    if (Test-Path $LogFile) {
        $logSize = [math]::Round((Get-Item $LogFile).Length / 1KB, 1)
        Write-Host "  Log      : $LogFile (${logSize} KB)"
    }

    Write-Host ""
    exit 0
}

# ============================================================
# Main: Run monitor
# ============================================================

# --- Pre-flight checks ---

# 1. Require STA thread
if (-not (Test-STA)) {
    Write-Host "[ERROR] STA thread required. Use powershell.exe (not pwsh):" -ForegroundColor Red
    Write-Host "        powershell.exe -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -ForegroundColor Yellow
    exit 1
}

# 2. Single instance via Mutex
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, $MutexName, [ref]$createdNew)

if (-not $createdNew) {
    if (-not $Silent) {
        Write-Host "[WARN] Another instance is already running. Exiting." -ForegroundColor Yellow
    }
    $mutex.Dispose()
    exit 0
}

# 3. Load assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 4. Ensure directories
foreach ($dir in @($SaveDir, $LogDir)) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# --- Cleanup helper ---
function Remove-OldScreenshots {
    $files = Get-ChildItem $SaveDir -Filter "*.png" -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending
    if ($files.Count -gt $MaxKeep) {
        $files | Select-Object -Skip $MaxKeep | ForEach-Object {
            Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
        }
    }
}

# --- Crash diagnostics ---

# 1. AppDomain.UnhandledException — catches .NET-level crashes that bypass try/catch
[System.AppDomain]::CurrentDomain.add_UnhandledException({
    param($sender, $eventArgs)
    $ex = $eventArgs.ExceptionObject
    $msg = "UNHANDLED .NET EXCEPTION (IsTerminating=$($eventArgs.IsTerminating)): $($ex.GetType().FullName): $($ex.Message)`n$($ex.StackTrace)"
    # Write directly to file since Write-Log may not be available
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] [FATAL] $msg"
    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
})

# 2. PowerShell.Exiting — fires on normal process exit
Register-EngineEvent PowerShell.Exiting -Action {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] [WARN] PowerShell.Exiting event fired (ExitCode=$LASTEXITCODE)"
    Add-Content -Path $LogFile -Value $line -ErrorAction SilentlyContinue
} | Out-Null

# --- Startup ---
Write-Log "Monitor started (PID=$PID)" "OK"
Write-Log "SaveDir=$SaveDir  MaxKeep=$MaxKeep  PollMs=$PollMs"

Remove-OldScreenshots

$captureCount = 0
$startTime = Get-Date
$lastHeartbeat = Get-Date

# --- Main loop ---
try {
    while ($true) {
        Start-Sleep -Milliseconds $PollMs

        # Heartbeat: every 5 minutes log health status
        if (((Get-Date) - $lastHeartbeat).TotalMinutes -ge 5) {
            $uptime = [math]::Round(((Get-Date) - $startTime).TotalHours, 2)
            $memMB  = [math]::Round((Get-Process -Id $PID).WorkingSet64 / 1MB, 1)
            Write-Log "Heartbeat: uptime=${uptime}h mem=${memMB}MB captured=$captureCount"
            $lastHeartbeat = Get-Date
        }

        try {
            if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
                $img = [System.Windows.Forms.Clipboard]::GetImage()
                if ($null -ne $img) {
                    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
                    $filePath  = Join-Path $SaveDir "screenshot_$timestamp.png"

                    $img.Save($filePath, [System.Drawing.Imaging.ImageFormat]::Png)
                    $img.Dispose()

                    [System.Windows.Forms.Clipboard]::SetText($filePath)

                    Remove-OldScreenshots

                    $captureCount++
                    $size = [math]::Round((Get-Item $filePath).Length / 1KB, 1)
                    Write-Log "Captured #$captureCount -> $filePath (${size} KB)" "OK"
                }
            }
        }
        catch [System.Runtime.InteropServices.ExternalException] {
            # Clipboard locked by another app, skip silently
        }
        catch {
            Write-Log "Unexpected error: $($_.Exception.Message)" "WARN"
        }
    }
}
catch {
    Write-Log "Fatal error in main loop: $($_.Exception.GetType().FullName): $($_.Exception.Message)" "ERROR"
    Write-Log "StackTrace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}
finally {
    $uptime = if ($startTime) { [math]::Round(((Get-Date) - $startTime).TotalHours, 2) } else { 0 }
    Write-Log "Monitor stopped (captured=$captureCount uptime=${uptime}h exitcode=$LASTEXITCODE)" "WARN"
    if ($mutex) {
        try { $mutex.ReleaseMutex() } catch {}
        $mutex.Dispose()
    }
}
