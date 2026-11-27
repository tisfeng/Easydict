## 2026-11-19 | 任务：为 Ollama 增加思考强度开关

**Links:** None

### 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 26.6.2 / Xcode 27.2 (27B52)`（首轮实现时无 Xcode，验证轮已安装）

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
- `xcodebuild build-for-testing`（Debug，`DEVELOPER_DIR` 指向 Xcode 27.2）：通过。本机无签名证书，
  ad-hoc 签名无法携带 Debug entitlements 中受限的
  `com.apple.developer.background-tasks.continued-processing.inference`，因此构建时以命令行
  `CODE_SIGN_ENTITLEMENTS=<本地空 entitlements，经 .git/info/exclude 排除>` 覆盖；未修改任何跟踪文件。构建中
  SwiftFormat 调整了 `OllamaService` 成员顺序，已随本记录提交。
- `xcodebuild test-without-building`（Default 计划）：487 个测试中 12 个失败，集中在
  `OCRImageTests`、`AppleScriptExecutorTests`、`CodexCommandProcessTests` 和
  `SystemUtilitiesTests.testAlertVolume`；这些用例不经过 `OllamaService`。
- 基线对照：在基线提交 `4ca55a25` 与本分支上分别只运行上述 4 个 suite（各 22 个测试）。基线失败
  `OCRImageTests` 4 个与 `AppleScriptExecutorTests` 1 个；本分支失败 `OCRImageTests` 5 个，其余通过。
  失败集合在两次运行间波动，集中在依赖本机 Vision OCR 与系统自动化环境的用例，判定为既有的
  环境相关失败，与本次改动无关。
- App 实测（Debug 构建，经 HTTP `/streamTranslate` 调用 Ollama 服务，Ollama 前置本地日志代理）：
  设置为 off/high/max 时，实际发出的请求体分别为 `reasoning_effort` `"none"`/`"high"`/`"max"`，
  model 为所选模型。查词模式（`queryType: 2`）下 off 为 5.3–6.7 秒，high 为 99.7 秒。
- 直连 Ollama 流式请求 `reasoning_effort: "high"`：HTTP 200，16 秒，先输出思考内容再输出译文。
- 未执行：设置页界面截图（验证时用户正在使用桌面，未做 UI 自动化）。

### 受影响文件

- `Easydict/Swift/Service/Ollama/OllamaService.swift`
- `docs/histories/2026-11/2026-11-19-ollama-reasoning-effort.md`

### 后续事项

- 设置页截图验证待补。
- 对非思考模型选择 `high`/`max` 会收到 Ollama 报错；如需更友好的提示，可按模型的
  `thinking` capability 隐藏或禁用该选项。
