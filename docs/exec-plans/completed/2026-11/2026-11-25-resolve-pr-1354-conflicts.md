# 解决 PR #1354 的划词浮层冲突

- 状态：completed
- 创建日期：2026-11-25
- 负责人：tisfeng
- 关联 Issue/PR：[PR #1354](https://github.com/tisfeng/Easydict/pull/1354) · [Issue #1177](https://github.com/tisfeng/Easydict/issues/1177)

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

## 背景

PR 的划词浮层清理与 `dev` 的跨应用事件来源处理修改了相同的事件路径。

## 目标与范围

- 目标结果：把最新 `dev` 合并到 PR 的本地分支并解决冲突。
- 允许修改路径：`EventMonitor.swift` 及本任务 plan 和 history。
- 同任务 history：`docs/histories/2026-11/2026-11-25-resolve-pr-1354-conflicts.md`
- 用户限制：本地解决 PR 冲突。
- 非目标：关闭 #1177、推送或合并 GitHub PR。
- 验收标准：保留事件来源判断、浮层取消逻辑和 Cmd+A 延迟取词，验证本地合并结果。

## 工作计划

1. 冻结 PR head 和最新远程 `dev`，检查冲突及 review 线程。
2. 整合取词与浮层生命周期，运行针对性构建、测试与交互验证。
3. 审查合并结果，记录验证范围并创建本地合并提交。

## 风险与决策

- 普通关闭浮层需要保留拖动的事件来源，关闭自动划词和停止监听需要取消尚未完成的取词。
- 双 Command 的关闭请求不能取消已经排定的 Cmd+A 取词。

## 进度

- [x] 核对 PR、最新 `dev` 及单一冲突文件。
- [x] 整合浮层清理与事件来源。
- [x] 完成构建、定向测试与交互验证，审查源码并记录边界。

## 验证

- Xcode Debug 构建与 `ThrottleGateTests` 通过，共 5 个测试。SwiftFormat 未修改源文件。
- TextEdit 实测快速 Command 后接 Cmd+A。日志确认双 Command 分支先执行，延迟取词随后显示浮层。在点击查询模式下悬停后浮层仍可见。
- 独立启动后拖动选区可显示浮层。在设置中关闭自动显示图标后，重复 Cmd+A 未显示浮层。
- 连续拖选和合成双击未稳定显示浮层。尚未覆盖停止监听时在途请求、强制 Cmd+C 和运行数小时后的光标闪烁。
- 对最新 `dev` 的差异通过 `git diff --check`。审查核对事件来源、拖动、选区 generation 和双 Command 分支。

## 完成条件

- 合并树无冲突，并记录实际验证与剩余限制。
- 更新 history，归档 plan，提交本地合并结果。
