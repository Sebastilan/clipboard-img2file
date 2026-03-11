# 架构：怎么组织的？

## 关键文件/目录

| 路径 | 作用 |
|------|------|
| clipboard-img2file.ps1 | 主脚本（剪贴板监控 + 图片保存 + 路径注入） |
| widget.ps1 | 状态小组件 |
| install.bat | 安装器（注册计划任务） |
| uninstall.bat | 卸载器 |
| launcher.vbs | VBScript 启动器（避免闪窗） |
| widget.vbs | Widget 启动器 |

## 工作流

```
剪贴板 Bitmap → 检测变化 → 保存 PNG 到 %TEMP% → 注入文件路径回剪贴板
```

## 参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| -SaveDir | %TEMP%\clipboard-img2file | 截图保存目录 |
| -MaxKeep | 5 | 最多保留文件数 |
| -PollMs | 500 | 轮询间隔（毫秒） |
| -Silent | false | 静默模式 |
| -Status | false | 显示状态 |

## 安装机制

- Task Scheduler 注册计划任务（不需管理员权限）
- `launcher.vbs` + `bWaitOnReturn=True` 保持 Scheduler Running 状态
- RestartOnFailure 自动重启（Modern Standby 会强杀后台进程）

## 依赖

- PowerShell 5.1（Windows 内置，pwsh 7 不可用 — STA 线程限制）
- 无第三方依赖
