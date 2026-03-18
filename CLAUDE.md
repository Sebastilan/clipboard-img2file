# 身份：我是谁？

**clipboard-img2file** — Windows 剪贴板图片自动转文件路径工具。

解决 CLI 工具（如 Claude Code）无法直接粘贴截图的痛点。监控剪贴板，自动将 Bitmap 保存为 PNG 文件，注入文件路径回剪贴板。

已发布，GitHub 开源（MIT），持续维护中。仓库：https://github.com/Sebastilan/clipboard-img2file

## 技术栈

PowerShell 5.1 + .NET（System.Windows.Forms / System.Drawing），零依赖，无需管理员权限。

# 进展：到哪了？

## 当前状态：已发布，持续维护

- GitHub 开源（MIT）：https://github.com/Sebastilan/clipboard-img2file
- 兼容：Win+Shift+S、微信截图、Snipaste、PrintScreen
- 确认可用于 Claude Code 截图粘贴场景

## 已完成

- 核心功能：剪贴板监控 + 图片保存 + 路径注入
- 安装/卸载脚本（Task Scheduler）
- 单实例保护 + 自动清理 + 崩溃恢复 + 日志轮转
- 状态 Widget

## 推广

- 已回复：anthropics/claude-code#9301（Alt+Paste not working on Windows 11）
- 持续搜索相关痛点讨论并推荐
