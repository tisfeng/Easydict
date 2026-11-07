## 2026-10-16 | 任务：重构 OpenAI 请求体并支持 extra body 与自由文本思考程度

**Links:** 无（本记录为工作分支多个提交压缩后的合并 history，见“合并说明”）

### 执行上下文

- **Agent Name:** `pi`
- **Model:** `deepseek-flash`（provider `deepseek`；完整模型 ID 未在运行上下文提供）
- **Environment:** `macOS 27.0.1 / Xcode 27.1 (27A9275)`

### 用户请求

1. 为 Custom OpenAI 增加 extra request body 能力，并把 `reasoningEffort` 选择框改成英文输入框：
   输入框为空时不设置 `reasoningEffort`。经确认：仅 Custom OpenAI 改动，DeepSeek 保持下拉框；
   输入什么字符串就发送什么字符串（不做规范化）；纯空白视为空；不新增测试，只手工验证。
2. 将该工作分支上的多个提交合并成一个提交，并用一份新的 history 覆盖本文件。

### 变更

- 新增 `Easydict/Swift/Service/OpenAI/ChatQueryBody.swift`：统一承载并编码 OpenAI 兼容请求字段
  （`messages` / `model` / `temperature` / `reasoningEffort` / `stream`），按 snake_case 输出；
  用户提供的 extra body JSON 作为与 `model` 同级的顶层 `extra_body` 字段合入，未配置或字段为空时
  保持原样请求体，JSON 无效时记录 `logWarn` 并忽略。
- `BaseOpenAIService` 与 `OpenAIStreamTransport` 改用 `ChatQueryBody`：`stream` 由调用方显式传入，
  不再修改 SDK 的 `ChatQuery`；`StreamService.reasoningEffort` 类型从 `ChatQuery.ReasoningEffort?`
  改为 `String?`，`StreamService` 移除 `import OpenAI`。
- `StreamService` 新增 `supportsExtraBody`、`extraBodyJSONKey`、`extraBodyJSON`、`extraBody`，以及
  自由文本思考程度的 `usesFreeformReasoningEffort`、`reasoningEffortTextKey`、
  `configuredReasoningEffortText`；更新 `supportsReasoningEffort` 文档注释。
- `ServiceConfigurationKey` 新增 `extraBody` 与 `reasoningEffortText` 两个槽位；`CustomOpenAIService`
  开启 `supportsExtraBody`、`supportsReasoningEffort`、`usesFreeformReasoningEffort`，`reasoningEffort`
  读取自由文本、去首尾空白为空返回 `nil`、否则原样返回。
- `StreamConfigurationView` 新增私有 `ExtraBodyEditor`（`TextEditorCell` + JSON 合法性提示）与
  思考程度文本输入分支（DeepSeek 仍用 `StaticPickerCell` 下拉框）。
- `Localizable.xcstrings` 新增 5 个 key：`service.configuration.custom_openai.extra_body` 的
  `title` / `placeholder` / `footnote` / `invalid_json`，以及
  `service.configuration.reasoning_effort.placeholder`（六种语言）。
- `ChatQueryBody.swift` 加入 `Easydict.xcodeproj/project.pbxproj` 的文件引用与 Sources。
- 本 history 覆盖原先分列的 debug-log 记录；`2026-10-16-openai-request-body-debug-log.md` 已删除，
  因为那条日志在合并前已被移除。

### 设计意图

- 用 `ChatQueryBody` 取代 SDK 的 `ChatQuery` 编码路径：SDK 类型无法承载提供商特有字段（`extra_body`），
  且要求调用方在编码前改写 `stream`。集中编码后流式与非流式共用同一请求体，snake_case 转换和
  `extra_body` 合并只有一处，`stream` 语义由调用点显式表达。
- extra body 采用文本 JSON 而不是结构化表单：各网关字段差异大，原样透传最省事，合法性提示放在
  编辑框下方即时反馈。
- 思考程度不复用枚举槽位 `reasoningEffort`：同键名换成 String 会误解码历史值，且 DeepSeek 仍依赖
  `ReasoningEffort.isEnabled` 决定 `thinking.type`；沿用 `cliEffort` 已有的「独立 free-form effort
  槽位」先例，空值即不传参。UI 形态由服务覆写开关决定，避免给 `StreamConfigurationView` 增加参数
  影响其他调用点。
- 只做空白判定，不做 trim 后发送、大小写或字符集规范化，保持「输入什么发送什么」。

### 合并说明

- 原工作分支在 `af5b654f` 之上有 4 个提交：`392c4963` 添加 `ChatQueryBody`、`453729e9` 为非流式
  请求体添加调试日志、`76d90c5c` Custom OpenAI 思考程度改自由文本、`c01e5b49` 去除日志。
- 经 `git reset --soft af5b654f` 压缩为一个提交，内容为四者叠加后的最终状态；调试日志加入后又被
  移除，因此该部分不进入最终提交。
- 压缩时顺带修正 `BaseOpenAIService.makeNonStreamingChatRequest` 中 `request.httpBody= try …` 的
  运算符空格与多余空行（SwiftFormat `spaceAroundOperators` / `blankLines`）。

### 验证

- `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath <agent-derived-data>
  -only-testing:EasydictTests/OpenAIStreamTaskControlTests`：`** TEST SUCCEEDED **`（3 tests / 1 suite，
  同时编译 App target，压缩后重新运行）。
- `git diff --check`：通过。
- `jq -e . Easydict/App/Localizable.xcstrings`：通过；新增 key 顺序与六个 locale 校验通过。
- 未运行：SwiftFormat / SwiftLint（本机未安装，仓库无 lint workflow），按 `--maxwidth 120` 与
  `line_length` 140 人工核对新增行。
- 手工检查（待用户确认）：Custom OpenAI 设置页是否显示 extra body 编辑器与思考程度文本框；输入
  `low` 后请求体含 `"reasoning_effort": "low"`、清空后不含；DeepSeek 下拉框是否不变。

### 受影响文件

- `Easydict/Swift/Service/OpenAI/ChatQueryBody.swift`（新增）
- `Easydict/Swift/Service/OpenAI/BaseOpenAIService.swift`
- `Easydict/Swift/Service/OpenAI/OpenAIStreamTransport.swift`
- `Easydict/Swift/Service/OpenAI/StreamService.swift`
- `Easydict/Swift/Service/CustomOpenAI/CustomOpenAIService.swift`
- `Easydict/Swift/Feature/Configuration/ServiceConfigurationKey.swift`
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/StreamConfigurationView.swift`
- `Easydict/App/Localizable.xcstrings`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/histories/2026-10/2026-10-16-custom-openai-reasoning-effort-text.md`

### 后续事项

- 旧用户已保存的 `EZCustomOpenAIReasoningEffortKey`（`off/high/max`）不再被读取，升级后
  `reasoning_effort` 变为不发送（等效关闭），需重新输入一次；按用户答复不做迁移。
- 自由文本思考程度与 extra body JSON 都不做取值校验，非法值由提供商返回错误。
- 原有 4 个提交仍可通过 `git reflog` 找回；本记录对应压缩后的单个提交。
