## 2026-11-25 | 任务：支持自定义 OpenAI 的 Responses API

<!-- 文件名：2026-11-25-openai-responses-api.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->

**Links:** [Issue #1306](https://github.com/tisfeng/Easydict/issues/1306), [plan](../../exec-plans/completed/2026-11/2026-11-25-openai-responses-api.md)

### 执行上下文

- **Agent Name:** `Grok 4.7`
- **Model:** `Grok 4.7`
- **Environment:** `macOS Unknown / Xcode Unknown (Unknown)`。执行环境是 Linux，没有 Xcode。

### 用户请求

在 `dev` 上为自定义 OpenAI 实现 Responses API，保留 Chat Completions，并把分支推到 fork。

### 变更

- 自定义 OpenAI 增加 Chat Completions / Responses 选项；切换时改写已识别的 endpoint 后缀。
- Responses 请求使用 `input` 和 `/responses`，SSE 按 payload 的 `type` 分类，并用 Alamofire 发送。
- 补充纯函数测试、七种界面语言文案和服务说明。

### 设计意图

分流只放在自定义服务上，内置 OpenAI 兼容服务继续走原来的 Chat Completions。无法识别的完整 URL 保持原样，避免升级后改坏已有端点。

### 验证

- `jq -e . Easydict/App/Localizable.xcstrings`：通过。
- `git diff --check`：通过。
- `xcodebuild test`：未运行。当前环境没有 Xcode，也没有 macOS 界面可以验收设置页。

### 受影响文件

- `Easydict/Swift/Service/OpenAI/OpenAIAPIType.swift`
- `Easydict/Swift/Service/OpenAI/ResponsesAPI.swift`
- `Easydict/Swift/Service/OpenAI/BaseOpenAIService.swift`
- `Easydict/Swift/Service/CustomOpenAI/CustomOpenAIService.swift`
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/StreamConfigurationView.swift`
- `EasydictTests/Service/OpenAI/ResponsesAPITests.swift`
- `Easydict/App/Localizable.xcstrings`
- `docs/user-docs/en/SERVICES.md`
- `docs/user-docs/zh/SERVICES.md`

### 后续事项

- opencode go 需要的自定义请求头 `x-opencode-session` 未包含在本次变更中。
- 需要在 macOS 上运行 `EasydictTests/OpenAI Responses API`，并查看自定义 OpenAI 设置里的接口类型选择器。
