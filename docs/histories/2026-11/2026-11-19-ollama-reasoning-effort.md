## 2026-11-19 | 任务：为 Ollama 增加思考强度开关

**Links:** None

### 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 26.6.2 / Xcode Unknown (Unknown)`

### 用户请求

本地 Ollama 的 Qwen3 系列思考模型在查词时默认先思考，单次查询需要 20–60 秒；希望能在 Ollama
服务中关闭思考以换取速度。

### 变更

- `OllamaService` 启用共享的思考强度选项（`supportsReasoningEffort`），设置页复用现有
  `off/high/max` 选择器。
- 覆盖 `reasoningEffort`：`off` 发送 `reasoning_effort: "none"`，`high` 发送 `"high"`，
  `max` 发送 `"max"`。

### 设计意图

复用 `StreamService` 已预留的 `reasoningEffort` 钩子和 DeepSeek 已使用的共享选择器，不新增
配置键或本地化文案。关闭时显式发送 `none` 而不是省略字段，因为 Ollama 在字段缺失时会让
思考模型默认思考；`none` 对不支持思考的模型同样被接受。共享选项默认值为 `off`，因此升级后
Ollama 默认关闭思考。

### 验证

- `swiftc -parse Easydict/Swift/Service/Ollama/OllamaService.swift`：通过。
- 独立 SwiftPM 包引用与 `Package.resolved` 相同修订的 MacPaw OpenAI（`a532be89`），以相同的
  switch 映射构造 `ChatQuery` 并编码：编译通过，`off/high/max` 分别编码为
  `"reasoning_effort":"none"/"high"/"max"`。
- 将 `off` 对应的流式请求发送到本地 Ollama 0.34.2（`qwen3.6-35b-a3b`）：10 秒完成，0 个
  reasoning chunk。直接请求实测：`none` 对思考模型和非思考模型（`qwen3-coder-30b`）均正常；
  `high`/`max` 在非思考模型上返回 `does not support thinking`。
- 未执行：本机无 Xcode，未运行 `xcodebuild` 构建、单元测试、SwiftFormat/SwiftLint 和界面验证。

### 受影响文件

- `Easydict/Swift/Service/Ollama/OllamaService.swift`
- `docs/histories/2026-11/2026-11-19-ollama-reasoning-effort.md`

### 后续事项

- 安装 Xcode 后完成完整构建、测试和设置页截图验证。
- 对非思考模型选择 `high`/`max` 会收到 Ollama 报错；如需更友好的提示，可按模型的
  `thinking` capability 隐藏或禁用该选项。
