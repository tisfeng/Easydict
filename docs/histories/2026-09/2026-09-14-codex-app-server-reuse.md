## 2026-09-14 | 任务：复用 Codex App Server 翻译进程

**Links:** [问题评论](https://github.com/tisfeng/Easydict/pull/1303#issuecomment-5654806361)、
[执行计划](../../exec-plans/completed/2026-09/2026-09-14-codex-app-server-reuse.md)

### 用户请求

按已确认的“常驻 App Server + 独立临时 thread + 强制 HTTPS”方案修复托管 Codex 翻译延迟，
并确保进程可复用而不是每次翻译重新启动。

### 变更

- 新增长生命周期 App Server 进程与 JSON-RPC 编排，复用同一进程并为每次翻译创建独立
  `ephemeral` thread。
- 按 thread/turn 分发流式文本和 token usage；普通取消使用 `turn/interrupt`，并增加 RPC、翻译
  和空闲超时以及异常进程清理。
- 将托管翻译接入共享 App Server；本机 CLI 和账号连接验证继续保留一次性 `codex exec` 路径。
- 使用应用私有 model provider 关闭上游 WebSocket，直接通过 HTTPS Responses 传输，同时保留
  ChatGPT Keychain 登录。
- 登录、登出、重置与组件失效会终止共享进程；工程文件纳入两个新生产源码文件。
- 未新增或修改测试代码。

### 设计意图

进程复用只复用本地传输和初始化成本，不复用模型上下文。每个请求拥有独立的临时 thread、turn、
超时和取消状态，因此一个窗口的停止操作不会终止其他窗口的翻译。共享进程异常时不自动重放用户
文本，下一请求在重新校验组件后按需恢复，避免产生重复翻译或副作用。

### 验证

- 0.134.0 与 0.153.4 App Server schema：所需 thread、turn、delta、取消和 usage 协议均可用。
- 真实连续请求探针：两个临时 thread 复用同一 PID，均成功返回，且没有 WebSocket 重试日志。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict | xcbeautify`：通过。
- 12 个现有 Codex 相关 suite：158/158 通过，无失败或跳过。
- 对 6 个变更 Swift 文件运行 `swiftformat --lint --config .swiftformat`：通过。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- `git diff --check`：通过。

### 受影响文件

- `Easydict/Swift/Service/CodexCLI/CodexManagedAppServer.swift`
- `Easydict/Swift/Service/CodexCLI/CodexManagedAppServerProcess.swift`
- `Easydict/Swift/Service/CodexCLI/CodexManagedRuntime.swift`
- `Easydict/Swift/Service/CodexCLI/CodexManagedTranslation.swift`
- `Easydict/Swift/Service/CodexCLI/CodexCLIService.swift`
- `Easydict/Swift/Service/CodexCLI/CodexManagedAccount.swift`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/exec-plans/completed/2026-09/2026-09-14-codex-app-server-reuse.md`

### 后续事项

- None
