## 2026-10-24 | 任务：OpenAI 按服务省略温度并切回 dev

**Links:** [PR #1371](https://github.com/tisfeng/Easydict/pull/1371)、[计划](../../exec-plans/completed/2026-10/2026-10-24-openai-service-temperature.md)

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

删除静态 modelSupportsTemperature 与 gpt-6 前缀判断，OpenAI 按服务省略温度；将本地提交集成到 dev 并切到 dev，不 push。

### 变更

- dev 快进至已合并 PR 的 squash 提交 3843ffdd4；仅迁移尚未合入的 a2944d73 为 8b60f5fc2。
- 删除静态模型判断，公共请求只读取服务 supportsTemperature；OpenAI 服务禁用温度，公共配置 UI 同步隐藏滑块。
- 同步现有两个测试，不新增 suite、用例或断言。

### 设计意图

OpenAIService 同时被其他服务继承，按 serviceType 区分 OpenAI，避免关闭 Groq、智谱等服务的温度。Gemini、MiniMax、Claude 保持此前禁用策略。共享温度存储仍供支持的服务使用。

### 验证

- 独立 Agent DerivedData 下 xcodebuild test：OpenAITemperatureSupportTests、ClaudeSSEParserTests、OpenAIStreamTaskControlTests、QueryModelCancellationTests 共 17 个测试全部通过，Debug 编译成功。
- 临时使用 EASYDICT_RELEASE_PACKAGING=YES EXCLUDED_SOURCE_FILE_NAMES=Package.resolved；没有工程配置变动，不覆盖发布打包。
- git diff --check 通过，审查后的源码 SHA-256 复验一致。
- 语义 review：请求与 UI 使用同一个服务能力属性；无模型前缀判断及静态函数引用；其他服务的能力和免费模型列表保持不变。未发现有效 finding，当前局部实现足够。

### 受影响文件

- `Easydict/Swift/Service/OpenAI/BaseOpenAIService.swift`
- `Easydict/Swift/Service/OpenAI/OpenAIService.swift`
- `EasydictTests/Service/OpenAI/OpenAITemperatureSupportTests.swift`
- 本任务 plan/history。

### 后续事项

- 未调用真实提供商 API，未执行 GUI 或发布打包验证；不 push。
