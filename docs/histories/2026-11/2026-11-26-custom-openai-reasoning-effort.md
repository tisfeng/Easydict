## 2026-11-26 | 任务：为 Custom OpenAI 增加思考强度设置

**Links:** [#1353](https://github.com/tisfeng/Easydict/issues/1353)；相关未合并 PR #1364；
[计划](../../exec-plans/completed/2026-11/2026-11-26-custom-openai-reasoning-effort.md)

### 执行上下文

- **Agent Name:** `Claude agent (Claude Agent SDK)`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

Custom OpenAI 设置页缺少思考强度（reasoning effort）选项。要求先调研 GitHub 上的相关 issue 和 PR，
再实现该设置，并可尝试调用 Antigravity 作为子 Agent 辅助开发或测试。

### 变更

- 新增 `OpenAIReasoningEffort`（default/none/minimal/low/medium/high/xhigh），映射到 SDK 的
  `ChatQuery.ReasoningEffort`；`default` 不发送字段，`xhigh` 通过 `.customValue` 发送。
- `BaseOpenAIService` 新增 `supportsOpenAIReasoningEffort` 门控与按实例 uuid 隔离的
  `OpenAIReasoningEffort` 存储键，门控开启时覆盖 `reasoningEffort` 并把所选值并入
  `ocrTranslationConfiguration`；`CustomOpenAIService` 开启门控。
- `StreamConfigurationView` 在“使用模型”下方显示下拉框，复用
  `service.configuration.reasoning_effort.title`；`Localizable.xcstrings` 新增 7 个
  `service.openai.reasoning_effort.*` key（en/es/ja/sk/ur/zh-Hans/zh-Hant）。
- 新增 `OpenAIReasoningEffortTests`，覆盖默认省略字段、各档位编码进流式请求体、多实例隔离及内置
  OpenAI 不发送。该测试为 `.unit` 请求体编码测试，不发起网络请求，`example.invalid` 仅作占位 URL，
  不属于需调用真实服务的服务测试。测试初稿由 Antigravity（`agy`）生成，主 Agent 审阅并调整 `static` 常量后加入工程。

### 设计意图

共享 `ReasoningEffort`（off/high/max）为 DeepSeek 设计：`max` 不是 OpenAI 标准值，`off` 只省略字段，
不能关闭思考，因此不直接为 Custom OpenAI 打开 `supportsReasoningEffort`。改用 OpenAI 标准档位
和独立存储键，避免与 `.reasoningEffort` 槽位的类型冲突；默认不发送，保证已有用户与不支持该字段
的网关行为不变。请求注入复用 `openAIChatQuery` 这一流式与非流式共同入口，不改传输层。
与 PR #1364 的区别：本次只提供预设档位下拉框，不包含 extra body 与自由文本输入，也不重构请求编码。

用户提到可用 Antigravity 辅助测试，据此视为获准新增一个聚焦的请求体编码测试。

### 验证

- `xcodebuild build`：成功。本机缺少 Debug entitlement 所需 provisioning profile，命令行覆盖
  `CODE_SIGN_ENTITLEMENTS` 为仓库内空 entitlements 文件（绝对路径），未改仓库配置。
- `xcodebuild test-without-building -only-testing:EasydictTests/OpenAIReasoningEffortTests -only-testing:EasydictTests/OpenAIStreamTaskControlTests`：7 个测试全部通过。
- `git diff --check`、`jq -e . Easydict/App/Localizable.xcstrings`：通过。
- 手动检查：Debug 构建中添加 Custom OpenAI，下拉框默认 “Default (not sent)”，7 个选项齐全；选择
  Medium 后回显并写入按 uuid 隔离的键。验收后移除测试服务、删除临时键并退出 Debug 实例。
- 真实端点（经用户授权，读取本机 Custom OpenAI 配置，密钥未输出）：按应用生成的请求体结构，向
  OpenRouter `anthropic/claude-haiku-5.5` 非流式发送 7 个档位，全部 HTTP 200；`xhigh` 返回 62 个
  reasoning tokens，`low` 及以上的输出与 `default/none/minimal` 不同。opencode 网关因缺少
  `x-opencode-session` 请求头返回 400，与本次改动无关（见 #1306/#1307），不计入验证。
- 未验证：经应用界面发起的真实流式请求（请求体编码已由单元测试覆盖）。

### 受影响文件

- `Easydict/Swift/Service/OpenAI/OpenAIReasoningEffort.swift`
- `Easydict/Swift/Service/OpenAI/BaseOpenAIService.swift`
- `Easydict/Swift/Service/CustomOpenAI/CustomOpenAIService.swift`
- `Easydict/Swift/Feature/Configuration/ServiceConfigurationKey.swift`
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/StreamConfigurationView.swift`
- `Easydict/App/Localizable.xcstrings`
- `Easydict.xcodeproj/project.pbxproj`
- `EasydictTests/Service/OpenAI/OpenAIReasoningEffortTests.swift`
- `docs/exec-plans/completed/2026-11/2026-11-26-custom-openai-reasoning-effort.md`

### 后续事项

- 与开放 PR #1364 功能重叠，提交上游前需与维护者确认取舍。
- `none` 等取值是否被接受取决于提供方与模型；不支持的组合会由服务端报错。
