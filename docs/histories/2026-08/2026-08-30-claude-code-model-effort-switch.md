## 2026-08-30 | 任务：为 Claude Code CLI 服务增加模型与思考程度切换

**Links:** 分支 `feat/claude-code-model-effort-switch`

### 用户请求

为 CLI 版 Claude Code 翻译服务增加模型切换与思考程度切换能力，并确认当前使用的
默认模型。

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
- 第三轮：模型行改为自定义 `ModelInputRow`（`LabeledContent` + `TextField`），标题旁
  新增 `info.circle` 信息按钮，点击弹出 popover 说明规范写法（别名 sonnet/opus/haiku
  或完整模型 ID，不支持 opus4.7 之类简写）；新增
  `service.configuration.claude_code.model.help` 本地化 key，覆盖六个语言。
- 第四轮修复：popover 内容位于独立宿主窗口，不继承根视图注入的应用语言 locale，
  帮助文案会回落到系统语言；在 popover 内容上重新注入外层 `\.locale`，使其跟随
  应用内语言设置。
- 第五轮：新增思考程度切换。新建 `ClaudeCodeEffort` 枚举
  （default/low/medium/high/xhigh/max，`default` 不传 `--effort` 沿用 CLI 默认），
  runner `buildArguments`/`run` 增加 `effort` 参数透传 `--effort`，service 新增
  `effortKey`（`serviceDefaultsKey(.reasoningEffort)`），配置页在模型输入框下方
  加 `StaticPickerCell`，新文件注册进 `project.pbxproj`；新增
  `service.claude_code.effort.*` 与 `service.configuration.claude_code.effort.title`
  本地化 key（六个语言），并补充 effort 透传与省略的单元测试。
- 第六轮（code review 修复一）：老版本基类 `model` getter 的读取副作用可能已把空
  字符串持久化进 `modelKey`，升级后会遮蔽新的 `sonnet` 默认值、静默省略 `--model`；
  在 service `init` 中加入带持久化标记的一次性迁移（`modelMigratedKey`），存量空值
  改回 `sonnet`，迁移后的主动清空仍表示"沿用 CLI 默认"并补充测试。
- 第六轮（code review 修复二）：`effortKey` 改用新增的
  `ServiceConfigurationKey.cliEffort` 槽位，避免与基类
  `reasoningEffortDefaultsKey`（不兼容的 `ReasoningEffort` 枚举）共用同名存储。
- `ClaudeCodeCLIRunnerTests` 新增自定义模型透传和空白模型省略 `--model` 的测试。

### 设计意图

沿用 CodexCLIService 已有的 CLI 服务模型覆盖模式（自由文本 + 空值回退 CLI 默认），
保持两个 Agent CLI 服务的配置体验一致；默认值取 `sonnet` 以不改变既有用户行为。

### 验证

- `jq -e . Easydict/App/Localizable.xcstrings`：通过。
- `git diff --check`：通过。
- `swiftformat --lint`：未运行（本机未安装 swiftformat）。
- `xcodebuild test -only-testing:EasydictTests/ClaudeCodeCLIRunnerTests`：通过
  （2026-08-31 由用户本机执行，34 条测试全部通过，TEST SUCCEEDED）；此前各轮提交
  时该测试尚未运行，pbxproj 仅通过 `plutil -lint` 语法检查，用户运行应用亦确认
  构建正常。
- 手动验证：本机 `claude` CLI（v2.1.251）实测别名解析——`sonnet` → `claude-sonnet-5`、
  `opus` → `claude-opus-5`、`haiku` → `claude-haiku-4-5-20251001`；完整 ID
  `claude-opus-4-7` 可用，`opus4.7` 等简写返回模型不存在错误并走 `parseError` 路径。
- 手动验证：用与 runner 相同的参数组合实测 `--effort` 生效——`low` 档
  `thinking_tokens = 0`，`max` 档产生思考 token，档位切换真实改变模型行为，且与
  现有 CLI 参数组合兼容无报错。

### 受影响文件

- `Easydict/Swift/Service/ClaudeCode/ClaudeCodeEffort.swift`
- `Easydict/Swift/Service/ClaudeCode/ClaudeCodeRunner.swift`
- `Easydict/Swift/Service/ClaudeCode/ClaudeCodeService.swift`
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/ClaudeCodeServiceConfigurationView.swift`
- `Easydict/Swift/Feature/Configuration/ServiceConfigurationKey.swift`
- `Easydict/App/Localizable.xcstrings`
- `Easydict.xcodeproj/project.pbxproj`
- `EasydictTests/Service/ClaudeCode/ClaudeCodeCLIRunnerTests.swift`
- `EasydictTests/Service/ClaudeCode/ClaudeCodeServiceTests.swift`
- `docs/histories/2026-08/2026-08-30-claude-code-model-effort-switch.md`

### 后续事项

- None
