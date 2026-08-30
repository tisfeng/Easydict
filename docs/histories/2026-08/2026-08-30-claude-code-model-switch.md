## 2026-08-30 | 任务：为 Claude Code CLI 服务增加模型切换

**Links:** 分支 `feat/claude_code_model_switch`

### 用户请求

为 CLI 版 Claude Code 翻译服务增加模型切换能力，并确认当前使用的默认模型。

### 变更

- `ClaudeCodeRunner` 新增 `defaultModel`（`sonnet`）常量；`run(prompt:systemPrompt:)`
  增加 `model` 参数并透传给 `buildArguments`，空字符串仍回退到 CLI 默认模型。
- `ClaudeCodeService` 覆盖 `defaultModels` 为 `["sonnet"]`，使继承的 `modelKey`
  默认值保持既有行为；`contentStreamTranslate` 改为传入 `Defaults[modelKey]`。
- `ClaudeCodeService` 覆盖 `model` 存取器，绕过基类的 valid-model 强制回写，
  避免自定义模型名（如完整模型 ID）被首次读取时重置回默认值。
- `ClaudeCodeServiceConfigurationView` 新增模型输入框（`InputCell` 绑定
  `service.modelKey`），与 Codex CLI 配置页保持一致。
- `Localizable.xcstrings` 新增 `service.configuration.claude_code.model.title` 和
  `.placeholder`，覆盖 en、es、ja、sk、zh-Hans、zh-Hant。
- 第二轮：placeholder key 改为带参数的
  `service.configuration.claude_code.model.placeholder %@`，配置视图用
  `LocalizedStringKey` 插值传入 `ClaudeCodeRunner.defaultModel`，占位文案显示当前
  应用默认模型（默认 sonnet，留空则使用 CLI 默认模型）。
- `ClaudeCodeCLIRunnerTests` 新增自定义模型透传和空白模型省略 `--model` 的测试。

### 设计意图

沿用 CodexCLIService 已有的 CLI 服务模型覆盖模式（自由文本 + 空值回退 CLI 默认），
保持两个 Agent CLI 服务的配置体验一致；默认值取 `sonnet` 以不改变既有用户行为。

### 验证

- `jq -e . Easydict/App/Localizable.xcstrings`：通过。
- `git diff --check`：通过。
- `swiftformat --lint`：未运行（本机未安装 swiftformat）。
- `xcodebuild test -only-testing:EasydictTests/ClaudeCodeCLIRunnerTests`：未运行
  （用户拒绝执行 xcodebuild），构建与测试结果未验证；用户明确要求在此状态下提交。
- 手动验证：本机 `claude` CLI（v2.1.251）实测别名解析——`sonnet` → `claude-sonnet-5`、
  `opus` → `claude-opus-5`、`haiku` → `claude-haiku-4-5-20251001`；完整 ID
  `claude-opus-4-7` 可用，`opus4.7` 等简写返回模型不存在错误并走 `parseError` 路径。

### 受影响文件

- `Easydict/Swift/Service/ClaudeCode/ClaudeCodeRunner.swift`
- `Easydict/Swift/Service/ClaudeCode/ClaudeCodeService.swift`
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/ClaudeCodeServiceConfigurationView.swift`
- `Easydict/App/Localizable.xcstrings`
- `EasydictTests/Service/ClaudeCode/ClaudeCodeCLIRunnerTests.swift`
- `docs/histories/2026-08/2026-08-30-claude-code-model-switch.md`

### 后续事项

- `xcodebuild test -only-testing:EasydictTests/ClaudeCodeCLIRunnerTests` 尚未运行，
  建议在 PR 前补跑确认编译与测试通过。
