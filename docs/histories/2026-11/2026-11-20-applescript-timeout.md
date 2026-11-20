## 2026-11-20 | 任务：终止超时的 AppleScript

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-20-applescript-timeout.md) · [相关 PR #1137](https://github.com/tisfeng/Easydict/pull/1137)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2 / Xcode Unknown (Unknown)`

### 用户请求

修复 AppleScript 超时后仍占用后台线程的问题，在本地留待检查。

### 变更

- 复用 `osascript` 子进程执行器，超时或取消时终止正在运行的脚本，排队中的脚本取消后跳过启动。
- 最多并行运行两个脚本，确认子进程退出后释放名额。
- 保留调用方的超时错误、文本结果和空结果，并通过标准输入传递脚本。

### 设计意图

子进程使脚本的生命周期可控。两个执行名额允许选区和标签页地址请求并行，以免短超时的取词请求总是排在地址请求后面。

### 验证

- `swiftc`：按 macOS 13 目标、Swift 5 和完整并发检查编译修改后的执行器。
- 本机子进程验证通过，覆盖普通及大体积文本、空结果、脚本错误、超时后阻止延迟操作、排队过期、调用方取消和后续脚本。
- `SwiftFormat 0.63.0` 与 `git diff --check`：通过。
- `xcodebuild test`：当前环境只有 Command Line Tools，完整 Xcode 测试未运行。

### 受影响文件

- `Easydict/Swift/Utility/AppleScript/AppleScriptExecutor.swift`
- `Easydict/Swift/Utility/AppleScript/AppleScriptProcessExecutor.swift`
- `Easydict/Swift/Utility/AppleScript/AppleScriptTask.swift`

### 后续事项

- 在 Xcode 构建的 App 中确认 Chrome 取词、Apple 翻译快捷指令和 macOS 自动化权限。
