## 2026-10-24 | 任务：清理服务中过时的温度参数

**Links:** [PR #1371](https://github.com/tisfeng/Easydict/pull/1371)、[执行计划](../../exec-plans/completed/2026-10/2026-10-24-retire-provider-temperature.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

检查各模型服务；温度参数已经废弃或不再生效时，移除请求参数及无效配置项。

### 变更

- 新增服务实例能力属性 `supportsTemperature`，默认保留温度；Claude、MiniMax、Gemini 明确关闭。
- OpenAI 兼容请求和共享配置 UI 使用同一个服务属性，关闭的服务既不发送字段，也不展示滑块。
- 删除 Claude 专属温度范围配置，移除已无调用的共享 `temperatureMaxValue` 参数；仍支持温度的滑块继续使用原来的 0–2 默认范围。
- 未修改模型列表、推理设置或其他服务的请求策略；共享温度存储键仍供有效服务使用，不清空用户数据。

### 设计意图

按官方参数契约区分废弃、固定、模式限制与正常支持，不以“新模型”一概判断。只增加服务级布尔属性，不增加版本解析、别名归一化或能力表。

| 服务 | 官方证据与本次处理 |
| --- | --- |
| Claude | [参数弃用说明](https://platform.claude.com/docs/en/about-claude/model-deprecations)：2026-10-21 API 版本移除采样参数；较早 API 版本在 4.7+ 新模型遇非默认值报错。请求已省略，本次移除无效 UI。 |
| MiniMax | [OpenAI 兼容文档](https://platform.minimax.cn/docs/api-reference/text-openai-api)：M3.1-Flash/M3 固定温度 1，传入无效；移除请求字段和滑块。 |
| Gemini | [故障排查](https://ai.google.dev/gemini-api/docs/troubleshooting)：Gemini 4/3.6+ 忽略采样参数并警告弃用，旧 Gemini 3 建议默认值。[latest 别名](https://ai.google.dev/gemini-api/docs/models)随版本变化；服务统一省略参数并移除滑块，不声称所有旧 Gemini 都已废弃。 |
| OpenAI | [GPT-6 指引](https://developers.openai.com/api/docs/guides/latest-model)：推理强度非 none 时移除温度，Luna 支持 none；不是全面废弃。本次保留现有 GPT-6 条件省略，不扩大为所有服务均删除。 |
| DeepSeek | [思考模式](https://api-docs.deepseek.com/guides/thinking_mode/)：思考模式忽略温度但不会报错，非思考模式仍支持；保留现有参数与 UI。 |
| 智谱 | [对话补全](https://docs.bigmodel.cn/api-reference/模型-api/对话补全)、[GLM-5.3-Flash](https://docs.bigmodel.cn/cn/guide/models/vlm/glm-5.3-flash)：仍支持温度；保留四个模型的现有行为。 |
| Groq | [API reference](https://console.groq.com/docs/api-reference)：仍支持 0–2 温度；保留 GPT-OSS 请求。 |
| Ollama | [OpenAI 兼容](https://docs.ollama.com/api/openai-compatibility)：chat/completions 仍支持温度；保留。 |
| 自定义 OpenAI | 后端与模型由用户选择，没有统一废弃契约；保留既有判断，不推断第三方后端能力。 |
| 内置 AI / AI Tool | 使用保留的智谱免费模型；参数不变，不修改代理服务。 |
| 豆包翻译 | 专用翻译请求本来没有温度字段或滑块，无需删除。 |
| Codex CLI / Claude Code / GitHub Copilot | 各自 CLI 配置 UI 已无温度，调用路径未发送此 API 参数。 |
| 阿里 / 火山等传统翻译 | 不属于该生成式温度配置，无对应参数。 |

### 验证

- `xcodebuild test` 使用独立 Agent DerivedData，运行 `OpenAITemperatureSupportTests`、`ClaudeSSEParserTests`、`OpenAIStreamTaskControlTests`、`QueryModelCancellationTests`：17 个现有测试通过，Debug 编译成功。
- 临时传入 `EASYDICT_RELEASE_PACKAGING=YES EXCLUDED_SOURCE_FILE_NAMES=Package.resolved`，不修改工程；未验证常规发布打包。
- `git diff --check`：通过；移除的参数无残留引用。
- 手动检查：六个源码/UI 文件及服务继承、请求构造与配置入口 review 无范围内 finding；默认 true 保留其他服务，三个 false 同时阻断请求与 UI。
- review 前后摘要一致，工程文件及锁文件与初始备份字节一致。
- 未新增或扩写测试；没有在本轮调用在线 API。此前 OpenAI 对照请求因官方额度不足和配置代理 502 失败，不能证明温度会导致 400；GUI 未实测。

### 受影响文件

- `Easydict/Swift/Service/OpenAI/StreamService.swift`
- `Easydict/Swift/Service/OpenAI/BaseOpenAIService.swift`
- `Easydict/Swift/Service/Claude/ClaudeService.swift`
- `Easydict/Swift/Service/Gemini/GeminiService.swift`
- `Easydict/Swift/Service/MiniMax/MiniMaxService.swift`
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/StreamConfigurationView.swift`
- `docs/exec-plans/completed/2026-10/2026-10-24-retire-provider-temperature.md`
- 本 history。

### 后续事项

- 真实提供商响应、GUI 操作和发布打包未验证；不将文档结论或既有离线测试写成在线实测。未 push。
