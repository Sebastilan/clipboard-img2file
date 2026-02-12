@echo off
chcp 65001 >nul 2>&1
title Clipboard Image to File - Installer

echo.
echo  ============================================
echo   Clipboard Image to File - Installer
echo  ============================================
echo.

REM --- Locate files (same folder as this bat) ---
set "SOURCE_PS1=%~dp0clipboard-img2file.ps1"
set "SOURCE_VBS=%~dp0launcher.vbs"
if not exist "%SOURCE_PS1%" (
    echo  [ERROR] clipboard-img2file.ps1 not found!
    echo          Make sure it is in the same folder as this installer.
    echo.
    pause
    exit /b 1
)
if not exist "%SOURCE_VBS%" (
    echo  [ERROR] launcher.vbs not found!
    echo          Make sure it is in the same folder as this installer.
    echo.
    pause
    exit /b 1
)

REM --- Run PowerShell installer ---
powershell.exe -ExecutionPolicy Bypass -NoProfile -Command ^
    $ErrorActionPreference = 'Stop'; ^
    $appName = 'ClipboardImg2File'; ^
    $installDir = \"$env:LOCALAPPDATA\clipboard-img2file\"; ^
    $sourcePs1 = '%SOURCE_PS1%'; ^
    $sourceVbs = '%SOURCE_VBS%'; ^
    ^
    Write-Host '  [1/4] Copying files...' -ForegroundColor Cyan; ^
    if (!(Test-Path $installDir)) { New-Item -ItemType Directory -Path $installDir -Force | Out-Null }; ^
    Copy-Item $sourcePs1 \"$installDir\clipboard-img2file.ps1\" -Force; ^
    Copy-Item $sourceVbs \"$installDir\launcher.vbs\" -Force; ^
    Write-Host '        Installed to:' $installDir -ForegroundColor Green; ^
    ^
    Write-Host '  [2/4] Stopping old instances...' -ForegroundColor Cyan; ^
    Get-WmiObject Win32_Process -Filter \"Name='powershell.exe'\" -ErrorAction SilentlyContinue ^| ^
        Where-Object { $_.CommandLine -like '*clipboard-img2file*' -and $_.ProcessId -ne $PID } ^| ^
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }; ^
    Start-Sleep -Seconds 1; ^
    ^
    Write-Host '  [3/4] Registering auto-start...' -ForegroundColor Cyan; ^
    $existing = Get-ScheduledTask -TaskName $appName -ErrorAction SilentlyContinue; ^
    if ($existing) { Unregister-ScheduledTask -TaskName $appName -Confirm:$false }; ^
    $vbsPath = \"$installDir\launcher.vbs\"; ^
    $action = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument \"`\"$vbsPath`\"\"; ^
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME; ^
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit (New-TimeSpan -Days 365); ^
    Register-ScheduledTask -TaskName $appName -Action $action -Trigger $trigger -Settings $settings -Description 'Auto-convert clipboard bitmap images to file paths for CLI tools.' -RunLevel Limited ^| Out-Null; ^
    Write-Host '        Auto-start registered (with crash recovery)' -ForegroundColor Green; ^
    ^
    Write-Host '  [4/4] Starting monitor via Task Scheduler...' -ForegroundColor Cyan; ^
    Start-ScheduledTask -TaskName $appName; ^
    Start-Sleep -Seconds 2; ^
    $running = Get-WmiObject Win32_Process -Filter \"Name='powershell.exe'\" -ErrorAction SilentlyContinue ^| Where-Object { $_.CommandLine -like '*clipboard-img2file*' }; ^
    if ($running) { Write-Host '        Monitor is running (managed by Task Scheduler)!' -ForegroundColor Green } ^
    else { Write-Host '        [WARN] Monitor may not have started' -ForegroundColor Yellow }; ^
    ^
    Write-Host ''; ^
    Write-Host '  ============================================' -ForegroundColor Green; ^
    Write-Host '   Installation complete!' -ForegroundColor Green; ^
    Write-Host '  ============================================' -ForegroundColor Green; ^
    Write-Host ''; ^
    Write-Host '  How to use:' -ForegroundColor Cyan; ^
    Write-Host '    1. Take a screenshot (Win+Shift+S)'; ^
    Write-Host '    2. Paste (Ctrl+V) in your terminal'; ^
    Write-Host '    3. You get a file path instead of bitmap!'; ^
    Write-Host ''; ^
    Write-Host '  The monitor runs silently in the background'; ^
    Write-Host '  and starts automatically on every login.'; ^
    Write-Host '';

echo.
pause
