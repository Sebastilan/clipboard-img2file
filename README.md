# clipboard-img2file

Auto-convert clipboard bitmap images to file paths — paste screenshots directly into CLI tools like [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

剪贴板截图自动转文件路径 — 让你在 CLI 工具中直接粘贴截图。

## The Problem / 解决什么问题

When you take a screenshot (`Win+Shift+S`), it copies bitmap data to your clipboard. CLI terminals only understand file paths, not raw bitmap — you can't paste a screenshot directly into tools like Claude Code.

截图后剪贴板里是 bitmap 数据，但 CLI 终端只认文件路径，没法直接粘贴截图。

## How It Works / 工作原理

```
Screenshot (Win+Shift+S)
    ↓  clipboard = bitmap
Monitor detects image
    ↓  saves as PNG
    ↓  clipboard = file path
Ctrl+V in terminal
    ↓  pastes file path ✓
```

## Install / 安装

1. [Download the latest release](https://github.com/Sebastilan/clipboard-img2file/releases)
2. Extract the zip
3. Double-click **`install.bat`**
4. Done. That's it.

安装后自动生效：后台静默运行，开机自启，崩溃自动恢复。不需要任何额外操作。

## Uninstall / 卸载

Double-click **`uninstall.bat`** in the extracted folder. It removes everything cleanly.

双击 **`uninstall.bat`** 即可完全卸载。

## What the Installer Does / 安装器做了什么

| Step | Detail |
|------|--------|
| Copy script | → `%LOCALAPPDATA%\clipboard-img2file\` |
| Register auto-start | → Windows Task Scheduler (current user, at logon) |
| Enable crash recovery | → auto-restart up to 3 times (1 min interval) |
| Start monitor | → runs immediately in background |

You can safely delete the downloaded zip after installation.

## Requirements / 环境要求

- **Windows 10 / 11**
- **Windows PowerShell 5.1** (pre-installed on all Windows 10/11)
- No admin rights needed
- No internet needed (fully offline after install)

> PowerShell 7 (`pwsh`) is NOT supported — it lacks STA thread mode required for clipboard APIs.

## Advanced Usage / 高级用法

```powershell
# Run manually with custom settings
powershell.exe -ExecutionPolicy Bypass -File .\clipboard-img2file.ps1 -SaveDir "D:\my-screenshots" -MaxKeep 10

# Check status
powershell.exe -ExecutionPolicy Bypass -File .\clipboard-img2file.ps1 -Status
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-SaveDir` | `%TEMP%\clipboard-img2file` | Where to save screenshots |
| `-MaxKeep` | `5` | Max screenshots to keep (oldest auto-deleted) |
| `-PollMs` | `500` | Polling interval in ms |
| `-Silent` | off | Suppress console output |
| `-Status` | - | Show running status |

## Features / 特性

- **Zero dependencies** — built-in Windows PowerShell + .NET only
- **Single instance** — Mutex lock prevents duplicates
- **Auto-cleanup** — keeps only recent N screenshots
- **Crash recovery** — Task Scheduler auto-restarts on failure
- **Log rotation** — auto-rotates at 1 MB (`%TEMP%\clipboard-img2file\monitor.log`)
- **Fully offline** — no network, clipboard + filesystem only
- **Double-click install** — no commands to type

## Confirmed Working With / 已验证兼容

- `Win+Shift+S` (Windows Snipping Tool)
- `Snipaste`
- `PrintScreen`

## FAQ / 常见问题

**Q: Does it affect normal copy-paste?**
Only bitmap images are converted. Text, files, and other clipboard content are untouched.

**Q: Where are screenshots saved?**
`%TEMP%\clipboard-img2file\`. Auto-cleaned, only the latest 5 kept.

**Q: How to stop it temporarily?**
Kill the PowerShell process from Task Manager, or run `uninstall.bat` then `install.bat` when you want it back.

## License

MIT
