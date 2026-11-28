## 2026-11-26 | 任务：处理 Responses API 的三项审查意见

<!-- 文件名：2026-11-26-responses-api-review-fixes.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->

**Links:** [PR #1420](https://github.com/tisfeng/Easydict/pull/1420)

### 执行上下文

- **Agent Name:** `Grok 4.7`
- **Model:** `Grok 4.7`
- **Environment:** `macOS Unknown / Xcode Unknown (Unknown)`。执行环境是 Linux 6.12，没有 Xcode。纯解析逻辑用 Swift 6.2.1 做了类型检查和运行。

### 用户请求

在 `feat/responses-api-1306` 上处理 Codex 对 PR #1420 的三条 P2 审查意见，并推送到该分支。

### 变更

- 按 `output_index`、`content_index` 或 `item_id` 保留仅终端输出片段，已由 delta 流出的文本不重复；只有整段流没有产出文本时才使用 `response.completed`。
- SSE 在空行事件边界把同一事件的多行 `data:` 用换行拼成一份 JSON 再解码。流结束时仍处理没有空行结尾的最后一个事件。
- 默认 API 类型测试先给服务分配新的 UUID，结束后移除该配置 key，避免读到本机保存的 `EZCustomOpenAIAPITypeKey`。

### 设计意图

终端文本按片段去重，这样多个 `response.output_text.done` 都会留下，同时不会把已经流式输出的全文再追加一次。SSE 组装方式与现有 Chat Completions 解析器一致，按空行分帧，而不是逐行解码。测试隔离沿用仓库里“独立 UUID + `Defaults.reset`”的做法。

### 验证

- `swiftc -swift-version 5` 编译并运行 `ResponsesStreamParsing.swift` 的临时检查：通过。覆盖多片段终端文本、delta 去重、跨 `data:` 行拼接、CRLF、分块边界和拆开的失败事件。
- `git diff --check`：通过。
- `xcodebuild test`：未运行。当前环境没有 Xcode，也不能跑依赖 App 模块的 Swift Testing 用例。

### 受影响文件

- `Easydict/Swift/Service/OpenAI/ResponsesStreamParsing.swift`
- `Easydict/Swift/Service/OpenAI/ResponsesAPI.swift`
- `EasydictTests/Service/OpenAI/ResponsesAPITests.swift`
- `Easydict.xcodeproj/project.pbxproj`

### 后续事项

- 需要在 macOS 上运行 `EasydictTests/OpenAI Responses API`。
