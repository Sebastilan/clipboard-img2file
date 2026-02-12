# clipboard-img2file

Auto-convert clipboard bitmap images to file paths — paste screenshots directly into CLI tools like [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

剪贴板截图自动转文件路径 — 让你在 CLI 工具中直接粘贴截图。

## The Problem / 解决什么问题

You're using Claude Code and want to show it a screenshot of a bug, an error message, or a UI design. You press `Win+Shift+S`, select the area, then `Ctrl+V` in the terminal — **nothing happens.** The terminal doesn't understand bitmap data, only file paths.

Your current workaround? Save the screenshot manually, find the file, copy the path, paste it. Every. Single. Time.

**This tool eliminates that friction.** Screenshot → Ctrl+V → done.

你正在用 Claude Code，想给它看一张 bug 截图、报错信息或 UI 设计稿。你按 `Win+Shift+S` 截图，然后在终端 `Ctrl+V` — **没反应。** 因为终端不认 bitmap 数据，只认文件路径。

现在的绕弯路：手动保存截图 → 找到文件 → 复制路径 → 粘贴。每次都这样。

**这个工具消除了这个摩擦。** 截图 → Ctrl+V → 搞定。

## How It Works / 工作原理

```
Screenshot (Win+Shift+S)
    ↓  clipboard = bitmap
Monitor detects image
    ↓  saves as PNG
    ↓  clipboard = file path + bitmap + file reference
Ctrl+V in terminal  → pastes file path ✓
Ctrl+V in WeChat    → pastes image ✓
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
| Copy script + launcher | → `%LOCALAPPDATA%\clipboard-img2file\` |
| Register auto-start | → Windows Task Scheduler (current user, at logon) |
| Enable crash recovery | → auto-restart on failure (1 min interval) |
| Silent launch | → VBScript wrapper prevents any window flash |
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

- **Non-destructive** — keeps original image in clipboard, adds file path alongside it
- **Zero dependencies** — built-in Windows PowerShell + .NET only
- **Single instance** — Mutex lock prevents duplicates
- **Auto-cleanup** — keeps only recent N screenshots
- **Truly silent** — VBScript launcher eliminates PowerShell window flash on startup
- **Crash recovery** — Task Scheduler auto-restarts on failure
- **Log rotation** — auto-rotates at 1 MB (`%TEMP%\clipboard-img2file\monitor.log`)
- **Fully offline** — no network, clipboard + filesystem only
- **Double-click install** — no commands to type

## Confirmed Working With / 已验证兼容

- `Win+Shift+S` (Windows Snipping Tool)
- WeChat Screenshot / 微信截图 (`Alt+A`)
- `Snipaste`
- `PrintScreen`

## FAQ / 常见问题

**Q: Does it affect normal copy-paste?**
No. The original image stays in clipboard — chat apps (WeChat, Slack, etc.) still paste the image as usual. The tool only *adds* a file path for CLI tools. Text, files, and other clipboard content are untouched.

**Q: Where are screenshots saved?**
`%TEMP%\clipboard-img2file\`. Auto-cleaned, only the latest 5 kept.

**Q: How to stop it temporarily?**
Kill the PowerShell process from Task Manager, or run `uninstall.bat` then `install.bat` when you want it back.

## License

MIT
