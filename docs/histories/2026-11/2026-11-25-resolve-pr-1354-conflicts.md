## 2026-11-25 | 任务：解决 PR #1354 的划词浮层冲突

**Links:** [PR #1354](https://github.com/tisfeng/Easydict/pull/1354) · [Issue #1177](https://github.com/tisfeng/Easydict/issues/1177) · [执行计划](../../exec-plans/completed/2026-11/2026-11-25-resolve-pr-1354-conflicts.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

解决 PR #1354 与当前目标分支的冲突。

### 变更

- 将远程 `dev` 的 `72b3187eb081dc88a7eea9fd85b33235f8b62819` 合入 PR 源分支的本地 checkout，解决 `EventMonitor.swift` 的冲突。
- 保留事件来源判断和跨应用拖动保护，移除划词输入监听中的 `.cursorUpdate`。关闭自动划词和停止监听时统一清理浮层及待处理请求。
- 双 Command 只在浮层可见时请求关闭。重新排定 Cmd+A 取词前清除先前安排的关闭操作。

### 设计意图

普通浮层关闭要保留当前拖动的事件来源。关闭功能、停止监听和点击激活各自清理相关状态，复用同一浮层清理方法。双 Command 仍可关闭可见浮层，Cmd+A 的延迟读取在浮层尚未出现时可以继续。

### 验证

- `xcodebuild test -only-testing:EasydictTests/ThrottleGateTests` 通过，Debug 构建和 5 个测试均成功。
- TextEdit 中验证快速 Cmd+A、独立拖选、点击查询模式下悬停，以及关闭自动划词后的 Cmd+A。
- `git diff --check` 通过。核对了事件来源、延迟和异步失效、关闭监听与 Cmd+C 忽略路径。

### 受影响文件

- `Easydict/Swift/Utility/EventMonitor/Core/EventMonitor.swift`
- `docs/exec-plans/completed/2026-11/2026-11-25-resolve-pr-1354-conflicts.md`
- 本 history 文件。

### 后续事项

- 连续拖选和合成双击未稳定显示浮层。停止监听时的在途请求、强制 Cmd+C 取词及 Issue #1177 的长时间运行场景尚未实测。
- 合并提交保留在本地分支，GitHub PR 仍指向作者原提交。
