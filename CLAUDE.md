# clipboard-img2file 项目规范

## 项目概述
Windows 剪贴板图片自动转文件路径工具，解决 CLI 工具（如 Claude Code）无法直接粘贴截图的痛点。

- **仓库**: https://github.com/Sebastilan/clipboard-img2file
- **技术栈**: PowerShell 5.1 + .NET (System.Windows.Forms / System.Drawing)
- **安装位置**: `%LOCALAPPDATA%\clipboard-img2file\`
- **截图存储**: `%TEMP%\clipboard-img2file\`
- **日志**: `%TEMP%\clipboard-img2file\monitor.log`

## 启动检查（每次对话必做）

进入本项目工作时，**立即执行以下检查**：

```bash
# 1. 检查未回复的 issue
gh issue list --repo Sebastilan/clipboard-img2file --state open

# 2. 逐个查看详情和评论
gh issue view <number> --repo Sebastilan/clipboard-img2file --comments

# 3. 对未回复的 issue 进行回复
#    - Bug: 确认问题 → 给方案 → 修复 → 回复
#    - Feature: 评估可行性 → 回复
#    - 重复: 指向已有 issue → 关闭

# 4. 汇报给用户：有几个新 issue，已处理几个，需要决策的列出来
```

## 推广检索（每次对话可选）

搜索网络上与本工具痛点相关的讨论，发现有人遇到同样问题时，去回复推荐我们的方案。

**搜索关键词**：
- `clipboard bitmap paste CLI terminal not working`
- `Claude Code paste screenshot Windows`
- `Win+Shift+S paste terminal`
- `剪贴板 截图 粘贴 终端 不工作`

**已回复的帖子**（避免重复）：
- [anthropics/claude-code#9301](https://github.com/anthropics/claude-code/issues/9301) - Alt+Paste not working on Windows 11

**回复原则**：
- 有帮助、不广告，先认同痛点再推荐方案
- 说明是 workaround 而非官方修复
- 附上仓库链接

## 回复规范

- 语言：根据 issue 作者的语言回复（中文 issue 用中文，英文用英文）
- 态度：友好、专业、感谢反馈
- Bug 回复模板：确认问题 → 说明原因 → 给出修复计划或临时方案
- 不确定的问题：**不要擅自回复**，汇报给用户决策

## 版本发布流程

1. 修复/改进代码
2. 更新 README（如有需要）
3. commit + push
4. 创建 GitHub Release（`gh release create v1.x`）
5. 回复相关 issue 说明已修复，关闭 issue

## 文档联动

| 触发事件 | 必须更新 |
|---------|---------|
| 新功能/改动 | README.md |
| 踩坑/重要决策 | 本文件「经验沉淀」段 |
| 新增 API/参数 | README.md 参数表 + clipboard-img2file.ps1 注释 |
| 发布新版本 | GitHub Release |

## 经验沉淀

- PowerShell 剪贴板 API 必须在 STA 线程运行，pwsh 7 默认 MTA 不可用，必须用 powershell.exe 5.1
- bash 里执行 PowerShell 命令时 `$_` 会被 bash 展开，复杂逻辑用 .ps1 文件而非 inline
- `Register-ScheduledTask -RunLevel Limited` 不需要管理员权限
- Task Scheduler 的 RestartOnFailure 是进程退出触发，非心跳检测
