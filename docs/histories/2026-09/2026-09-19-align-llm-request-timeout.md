## 2026-09-19 | 任务：统一 LLM 请求超时

**Links:** https://github.com/tisfeng/Easydict/pull/1301

### 执行上下文

- **Agent Name:** Unknown
- **Model:** Unknown
- **Environment:** macOS 27.0 / Xcode 27.0 (27A266a)

### 用户请求

将 `llmRequestTimeoutInterval` 从 90 秒调整为与 MacPaw/OpenAI SDK 默认值一致的 60 秒，并更新注释。

### 变更

- 将 `SharedConstants.llmRequestTimeoutInterval` 改为 60 秒。
- 更新注释，说明 MacPaw/OpenAI SDK 的默认值、idle timeout 语义和适用范围。

### 设计意图

让手写的 OpenAI-compatible 和 DeepSeek LLM 请求与 MacPaw/OpenAI SDK 的默认 idle timeout 保持一致，同时继续将普通翻译接口的 15 秒超时保留在原有边界内。

### 验证

- `BuildTools/.build/arm64-apple-macosx/release/swiftformat --lint Easydict/Swift/Utility/Constants/SharedConstants.swift --config .swiftformat`：通过。
- `git diff --check`：通过。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict | xcbeautify`：通过。

### 受影响文件

- `Easydict/Swift/Utility/Constants/SharedConstants.swift`
- `docs/histories/2026-09/2026-09-19-align-llm-request-timeout.md`

### 后续事项

- `None`
