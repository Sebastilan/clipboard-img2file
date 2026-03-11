# 规矩：什么别碰？

## 启动自检

每次对话必做：
1. `gh issue list` 检查未回复 issue
2. 逐个查看并回复（Bug 确认+修复、Feature 评估、重复→关闭）
3. 汇报给用户

## 回复规范

- 语言跟随 issue 作者（中文/英文）
- 不确定的问题不擅自回复，汇报用户决策
- Bug 模板：确认问题→说明原因→修复计划/临时方案

## 版本发布流程

1. 修复/改进代码
2. 更新 README
3. commit + push
4. 更新 CSDN 文章
5. `gh release create v1.x`
6. 回复并关闭相关 issue

## 关键踩坑

- **必须用 PowerShell 5.1**，pwsh 7 默认 MTA 线程，剪贴板 API 需要 STA
- `launcher.vbs` 必须 `bWaitOnReturn=True`，否则 Scheduler 认为任务已完成，RestartOnFailure 失效
- Windows Modern Standby 会强杀后台进程（连 finally 都不跑），必须依赖 Scheduler 重启
- 安装脚本停旧进程→注册任务→启动之间需留间隔，避免竞争
- bash 里 `$_` 被 bash 展开，复杂 PowerShell 逻辑用 .ps1 文件
