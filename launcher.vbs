' launcher.vbs — Silent launcher for clipboard-img2file
' Prevents the brief PowerShell window flash that occurs when
' Task Scheduler starts powershell.exe with -WindowStyle Hidden.
'
' Usage: wscript.exe launcher.vbs

Set WshShell = CreateObject("WScript.Shell")

' Build the path to the PowerShell script
installDir = WshShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\clipboard-img2file"
scriptPath = installDir & "\clipboard-img2file.ps1"

' Launch PowerShell completely hidden (windowStyle 0 = SW_HIDE)
' bWaitOnReturn = True so Task Scheduler stays "Running" and can
' trigger RestartOnFailure when the monitor process dies.
cmd = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptPath & """ -Silent"
WshShell.Run cmd, 0, True
