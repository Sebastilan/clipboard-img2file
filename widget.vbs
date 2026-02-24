' widget.vbs - Silent launcher for clipboard-img2file floating toggle widget
Set oShell = CreateObject("WScript.Shell")
Dim installDir : installDir = oShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\clipboard-img2file"
Dim psPath : psPath = installDir & "\widget.ps1"
oShell.Run "powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File """ & psPath & """", 0, True
