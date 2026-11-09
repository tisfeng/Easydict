## 2026-10-17 | 任务：提交并记录 ChatQueryBody 无效 extra body 告警日志的移除

**Links:** 前后关联提交 `69c0ad96`；同分支前置记录
[2026-10-16-custom-openai-reasoning-effort-text.md](2026-10-16-custom-openai-reasoning-effort-text.md)

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `deepseek-flash`
- **Environment:** `macOS 27.0.1 / Xcode 27.1 (27A9275)`

### 用户请求

提交工作树中 `Easydict/Swift/Service/OpenAI/ChatQueryBody.swift` 已有的未提交改动。

### 变更

- 删除 `ChatQueryBody.encoded()` 中 `guard let fields = extraBody.fields else` 分支内的
  `logWarn("Ignore invalid extra body JSON: \(extraBody.json)")`。
- 新增本 history 记录。

### 设计意图

该行是本次交付前工作树中已存在的用户改动，Agent 未改写其语义，只完成验证、记录与提交，动机不做推测。
可确认的边界：删除后控制流不变——extra body 文本配置了但不是顶层 JSON 对象时，仍走同一条
`return payloadData` 分支，请求体照旧不下发 `extra_body`，仅少一条告警日志；设置页仍由
`extraBody.isValid` 与 `service.configuration.custom_openai.extra_body.invalid_json` 就地提示非法 JSON。
`ExtraBody.isConfigured`、`isValid`、`fields` 都仍被使用，无残留死代码。

### 验证

- `git diff --check`：通过。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath "$HOME/Library/Developer/Xcode/DerivedData/Easydict-Agent/_Volumes_app_github_Easydict"`：`** BUILD SUCCEEDED **`。
- 手工检查：`grep -rn logWarn Easydict/Swift/Service/OpenAI/` 无结果，编码路径不再引用 `logWarn`。
- 未运行测试：改动只删除一条日志语句，无行为分支变化，`OpenAIStreamTaskControlTests` 不覆盖编码路径，
  沿用同一构建产物的既有结论。

### 受影响文件

- `Easydict/Swift/Service/OpenAI/ChatQueryBody.swift`
- `docs/histories/2026-10/2026-10-17-openai-extra-body-log-removal.md`

### 后续事项

- 同分支仍未提交：根目录未跟踪的 `PLAN.md`（上一轮 Custom OpenAI 思考程度任务的计划），本次未纳入。
