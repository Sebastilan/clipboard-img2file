@echo off
chcp 65001 >nul 2>&1
title Clipboard Image to File - Uninstaller

echo.
echo  ============================================
echo   Clipboard Image to File - Uninstaller
echo  ============================================
echo.

powershell.exe -ExecutionPolicy Bypass -NoProfile -Command ^
    $ErrorActionPreference = 'SilentlyContinue'; ^
    $appName = 'ClipboardImg2File'; ^
    $installDir = \"$env:LOCALAPPDATA\clipboard-img2file\"; ^
    $tempDir = \"$env:TEMP\clipboard-img2file\"; ^
    ^
    Write-Host '  [1/3] Stopping monitor...' -ForegroundColor Cyan; ^
    Get-WmiObject Win32_Process -Filter \"Name='powershell.exe'\" ^| ^
        Where-Object { $_.CommandLine -like '*clipboard-img2file*' -and $_.ProcessId -ne $PID } ^| ^
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force }; ^
    Write-Host '        Done' -ForegroundColor Green; ^
    ^
    Write-Host '  [2/3] Removing auto-start task...' -ForegroundColor Cyan; ^
    $task = Get-ScheduledTask -TaskName $appName -ErrorAction SilentlyContinue; ^
    if ($task) { ^
        Unregister-ScheduledTask -TaskName $appName -Confirm:$false; ^
        Write-Host '        Removed' -ForegroundColor Green; ^
    } else { ^
        Write-Host '        Not found (already removed)' -ForegroundColor Yellow; ^
    }; ^
    ^
    Write-Host '  [3/3] Cleaning up files...' -ForegroundColor Cyan; ^
    if (Test-Path $installDir) { Remove-Item $installDir -Recurse -Force; Write-Host \"        Removed $installDir\" -ForegroundColor Green }; ^
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force; Write-Host \"        Removed $tempDir\" -ForegroundColor Green }; ^
    ^
    Write-Host ''; ^
    Write-Host '  ============================================' -ForegroundColor Green; ^
    Write-Host '   Uninstall complete!' -ForegroundColor Green; ^
    Write-Host '  ============================================' -ForegroundColor Green; ^
    Write-Host '';

echo.
pause
