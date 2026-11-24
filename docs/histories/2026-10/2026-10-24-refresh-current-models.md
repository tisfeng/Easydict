## 2026-10-24 | 任务：精简内置模型并保留免费默认项

**Links:** [PR #1371](https://github.com/tisfeng/Easydict/pull/1371)、[执行计划](../../exec-plans/completed/2026-10/2026-10-24-refresh-current-models.md)、[GLM-5.3-Flash](https://docs.bigmodel.cn/cn/guide/models/vlm/glm-5.3-flash)、[GLM-4.5-Flash 路由说明](https://docs.bigmodel.cn/cn/guide/models/free/glm-4.5-flash)、[Groq 弃用公告](https://console.groq.com/docs/deprecations)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

按修正后的方案精简内置模型，保留两个指定智谱免费模型和当前默认项，测试和 review 后本地提交，不 push。

### 变更

- OpenAI 仅保留 GPT-6 三个内置模型；Claude 仅保留 5.5 三个内置模型。
- Groq 删除两个已对免费及开发者层关停的 Llama 模型，保留两个 GPT-OSS 模型；同步删除内置 AI 的 Llama 引用。
- 智谱保留 `glm-5.3-flash`、`glm-5.3`、`glm-4.5-flash`、`glm-4-flash-250414`。
- 智谱和内置 AI 默认项仍为 `glm-4-flash-250414`；内置 AI 仅保留两个指定免费 ID。
- 现有温度测试将旧 GPT-4.1 样例换为保留的 GPT-OSS 样例，没有增加测试用例或断言。
- DeepSeek、MiniMax 已符合方案，无需修改。

### 设计意图

用现有枚举直接维护当前模型，免费服务作为明确例外；不引入兼容层，不重写用户持久化列表或自定义 ID。保留 GLM-4.5-Flash 是用户明确要求，官方说明该旧 ID 自动路由到 GLM-4.7-Flash。新付费 Flash 不进入免费内置服务。GLM-5.3-Flash 的思考模式与延迟需在在线环境另行验证。

### 验证

- `xcodebuild test` 精确选择 `OpenAITemperatureSupportTests` 和 `ClaudeSSEParserTests`，独立 Agent DerivedData：7 个测试通过，同时覆盖 Debug 构建。
- 临时使用 `EASYDICT_RELEASE_PACKAGING=YES EXCLUDED_SOURCE_FILE_NAMES=Package.resolved`，跳过锁文件资源复制；没有修改工程配置，不覆盖常规发布打包。
- `git diff --check`：通过。
- 静态核对：六个服务模型列表符合方案，免费模型及默认项保持不变，无删除项的残留枚举引用。
- 手动检查：基于执行前 HEAD 和内容快照 review 六个源码/测试文件，无范围内 finding；现有枚举方案足够，无需额外抽象。
- 工程文件和锁文件字节与初始备份一致；已有工程改动不纳入本次提交。

### 受影响文件

- `Easydict/Swift/Service/OpenAI/OpenAIService.swift`
- `Easydict/Swift/Service/Claude/ClaudeService.swift`
- `Easydict/Swift/Service/Groq/GroqService.swift`
- `Easydict/Swift/Service/Zhipu/ZhipuService.swift`
- `Easydict/Swift/Service/BuiltInAI/BuiltInAIService.swift`
- `EasydictTests/Service/OpenAI/OpenAITemperatureSupportTests.swift`
- `docs/exec-plans/completed/2026-10/2026-10-24-refresh-current-models.md`
- 本 history。

### 后续事项

- 未调用在线 API，未验证真实翻译质量或延迟。已有配置中的旧模型保持原样；恢复默认列表后使用精简模型。未 push。
