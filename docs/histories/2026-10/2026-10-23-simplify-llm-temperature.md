## 2026-10-24 | 任务：简化当前模型的温度判断

**Links:** [PR #1371](https://github.com/tisfeng/Easydict/pull/1371)、[执行计划](../../exec-plans/completed/2026-10/2026-10-23-simplify-llm-temperature.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

简化温度参数判断，只考虑最新模型，不兼容旧模型和非标准别名。

### 变更

- Claude 请求直接省略温度字段，移除模型版本解析 helper。
- OpenAI 仅通过 `gpt-6` 前缀决定是否省略温度，保留其他提供商的温度传递。
- 删除过期 Claude 温度测试及工程引用，缩减 OpenAI 现有测试中的旧模型与别名用例。

### 设计意图

遵循用户收窄后的支持范围，删除不再需要的兼容分支；不保留测试专用常量 helper，不修改模型列表、传输或 UI。

### 验证

- 现有 `OpenAITemperatureSupportTests` 与 `ClaudeSSEParserTests`：7 个测试通过。
- `xcodebuild test` 使用 Agent 独立 DerivedData，并临时传入 `EASYDICT_RELEASE_PACKAGING=YES EXCLUDED_SOURCE_FILE_NAMES=Package.resolved`，跳过锁文件资源复制；工程配置没有因此改变。
- `plutil -lint Easydict.xcodeproj/project.pbxproj` 与 `git diff --check`：通过。
- 工程语义检查：仅删除过期测试对象和引用，构建配置及资源保持不变。
- 手动检查：调用路径与差异 review 通过，当前模型范围内无未处理 finding；锁文件内容与执行前一致。

### 受影响文件

- `Easydict/Swift/Service/Claude/ClaudeService.swift`
- `Easydict/Swift/Service/OpenAI/BaseOpenAIService.swift`
- `EasydictTests/Service/Claude/ClaudeTemperatureSupportTests.swift`（删除）
- `EasydictTests/Service/OpenAI/OpenAITemperatureSupportTests.swift`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/exec-plans/completed/2026-10/2026-10-23-simplify-llm-temperature.md`
- 本 history。

### 后续事项

- 未调用在线 API；本次测试不覆盖常规发布打包。未 push。
