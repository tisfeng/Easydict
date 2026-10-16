## 2026-10-17 | 任务：将 OpenAI stream 标志下沉到各传输函数

**Links:** 无

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `deepseek-flash`
- **Environment:** `macOS 27.0.1 / Xcode 27.1 (27A9275)`

### 用户请求

把 `BaseOpenAIService.swift` 第 248 行的 `stream` 设置从共用请求体构造处迁移到 `contentStream`
与 `nonStreamingTranslate` 中：非流式固定 `false`，流式固定 `true`。

### 变更

- `BaseOpenAIService.contentStream(messages:)` 不再预先调用 `makeChatQuery`，只在 `usesStreamingTransport`
  为真时进入流式分支，否则进入非流式分支。
- 流式函数签名由 `contentStream(for:endpoint:)` 改为 `contentStream(messages:endpoint:)`，函数内部以
  `stream: true` 构造请求体。
- `nonStreamingTranslate` 签名由接收 `body` 改为接收 `messages`，函数内部以 `stream: false` 构造请求体。
- 两个传输函数的文档注释补充各自固定的 `stream` 取值。
- 新增本 history 记录，无测试、本地化或工程文件变更。

### 设计意图

请求体的 `stream` 字段过去由调用点按 `usesStreamingTransport` 推导，既决定传输选择又决定字段值，
两处含义相同却分散表达。迁移后每个传输函数各自负责自己的 `stream` 取值，调用点只负责选择传输；
因为分支条件与字段值原本同源，取值保持完全一致，未改变任何外部行为，也未调整流式回退、
取消或 `validate()` 自动降级路径。

### 验证

- `git diff --check`：通过，无空白错误。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath "$HOME/Library/Developer/Xcode/DerivedData/Easydict-Agent/_Volumes_app_github_Easydict"`：`** BUILD SUCCEEDED **`。
- `xcodebuild test ... -only-testing:EasydictTests/OpenAIStreamTaskControlTests`：`** TEST SUCCEEDED **`（3 个测试通过）。
- 手工检查：`grep` 确认 `contentStream(for:`、`nonStreamingTranslate(`、`makeChatQuery(` 仅剩本次修改后的调用点，
  无遗漏调用者。

### 受影响文件

- `Easydict/Swift/Service/OpenAI/BaseOpenAIService.swift`
- `docs/histories/2026-10/2026-10-17-openai-stream-flag-transport.md`

### 后续事项

- None
