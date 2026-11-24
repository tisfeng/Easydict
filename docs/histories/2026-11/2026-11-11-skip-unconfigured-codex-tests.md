## 2026-11-11 | 任务：跳过缺少本机配置的 Codex 测试

**Links:** [PR #1391 审查评论](https://github.com/tisfeng/Easydict/pull/1391#discussion_r4535617696)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

修复公式识图和流式翻译测试在缺少本机 Codex CLI 或登录配置时报错的问题。

### 变更

- 通过本机 Codex App Server 查询当前服务商的认证要求与账号状态。
- 两个用例通过 Swift Testing 分别报告缺少 CLI 或账号的跳过原因。

### 设计意图

本机账号检查只在当前服务商明确要求 OpenAI 认证且无账号时触发跳过。配置齐备时，用例继续请求真实服务并断言识图、翻译及公式排版结果。模型、请求和断言错误仍按失败报告。

### 验证

- `xcodebuild test` 使用 `LocalEnvironment` 单独运行 `CodexFormulaImageTests`，两个真实用例通过。
- `xcodebuild test-without-building` 使用独立的 `CODEX_HOME` 和无凭据的测试环境复跑，Xcode 记录 2 项跳过、0 项失败，并显示登录提示。
- `xcodebuild test-without-building` 使用 `Default` 同时指定 Codex 套件和工具函数套件，仅执行工具函数套件的 13 项，全部通过。
- 手动检查了 CLI 安装错误的传播路径。隐藏 CLI 的隔离运行卡在测试宿主启动阶段，未完成该路径的端到端验证。

### 受影响文件

- `Easydict/Swift/Service/CodexCLI/CodexManagedAppServer.swift`
- `EasydictTests/Service/CodexCLI/CodexFormulaImageTests.swift`

### 后续事项

- 可在未安装 Codex CLI 的 Mac 上复验安装提示。
