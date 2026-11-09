## 2026-10-18 | 任务：ChatQueryBody 去除 extra_body 包装并合并 extra body 字段到顶层

**Links:** 无 issue / PR；无正式 plan（低风险小改动，未创建 `docs/exec-plans/active/` 计划；
本次评审草稿 `plans/openai-extra-body-merge.md` 为工作树内未跟踪文件，不提交）

### 执行上下文

- **Agent Name:** `pi`
- **Model:** `deepseek-flash`（provider `deepseek`；完整模型 ID 未在运行上下文提供）
- **Environment:** `macOS 27.0.1 / Xcode 27.1 (27A9275)`

### 用户请求

修改 `Easydict/Swift/Service/OpenAI/ChatQueryBody.swift` 的 `encoded()` 逻辑，去除 `extra_body`
键，把用户配置的 extra body 内容合并到现有请求体参数中。经确认：extra body 内的键**不覆盖**内置
字段；同时更新 UI 文案与注释措辞；不新增测试，由手工验证覆盖。

### 变更

- `ChatQueryBody.encoded()`：`extraBody.fields` 改为按「仅补充请求体中不存在的键」合并到顶层
  （`for (key, value) in fields where object[key] == nil`），删除 `extraBodyKey` 常量。
- `ChatQueryBody.encoded()` 与 `ExtraBody` 文档注释改写为「合并到顶层、内置字段优先」，并删掉
  `extra_body` 空对象相关表述。
- `Localizable.xcstrings` 的 `service.configuration.custom_openai.extra_body.footnote` 六语
  （en / es / ja / sk / zh-Hans / zh-Hant）文案更新为「合并到顶层请求体，应用已设置的字段优先」，
  `state` 保持 `translated`。

### 设计意图

- `extra_body` 包装是部分 OpenAI 兼容网关拒收的字段，用户配置的 `enable_thinking` 等键因此失效；
  直接顶层合并后无需新增配置项即可适配直接读顶层字段的网关。
- 采用「不覆盖」而不是「用户 JSON 优先」：`model` / `stream` 恒由应用设置决定，`temperature` /
  `reasoning_effort` 只在应用未设置（键被省略）时由 extra body 补位，避免用户 JSON 静默改写翻译
  请求的关键参数；设置页 `ExtraBody.isValid` + `invalid_json` 仍就地提示非法 JSON。
- 未配置 / 非法 JSON / 空对象三条路径保持不变仍直接返回 `payloadData`，不付 JSONSerialization
  往返成本，也不把非法 JSON 升级为请求错误。
- 想保留旧嵌套行为的用户可自行写 `{"extra_body": {...}}`：`extra_body` 属于「其他任意键」，会被
  原样补充到顶层，不需要额外兼容代码。
- 类型名 `ExtraBody`、`StreamService.supportsExtraBody`、`ServiceConfigurationKey.extraBody` 与
  xcstrings 的 `...custom_openai.extra_body.*` 键名都不改：它们是功能名，且
  `ServiceConfigurationKey.extraBody` 是持久化槽位（`EZCustomOpenAIExtraBodyKey`），改名会让已
  保存的配置丢失。

### 验证

- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath
  ~/Library/Developer/Xcode/DerivedData/Easydict-Agent/<checkout-id>`：`** BUILD SUCCEEDED **`。
- 编码行为手工验证：把生产文件 `Easydict/Swift/Service/OpenAI/ChatQueryBody.swift` 与一个临时
  driver（`QueryError`、`String.trim()` 用最小替身补齐）一起编译成命令行程序运行，实际调用
  `encoded()`，各输入的结果与预期一致：
  - `{"enable_thinking": false, "top_k": 20}` → `{"messages":[],"top_k":20,"enable_thinking":false,"model":"app-model","stream":true}`，无 `extra_body` 键。
  - `{"model":"hacked","stream":false,"temperature":9,"reasoning_effort":"x"}`，应用已设
    temperature `0.2` / reasoning_effort `low` → 保持 `"model":"app-model"`、`"stream":true`、
    `"temperature":0.20000000000000001`（`0.2` 经 `JSONSerialization` 的输出形式）、`"reasoning_effort":"low"`。
  - 同上 JSON，应用未设 temperature / reasoning_effort → 采用 `"temperature":9`、
    `"reasoning_effort":"x"`，`model` / `stream` 仍为应用值。
  - `{"extra_body": {"enable_thinking": false}}` → 顶层保留 `extra_body` 对象（旧网关兼容路径）。
  - 空字符串 / `{}` / 非法 JSON / JSON 数组 → 请求体与改动前完全一致且不抛错。
  - 临时 driver 放在 `/tmp/chatquery_merge_check`，位于仓库之外，验证后已删除；未新增或修改任何测试文件。
- `git diff --check`：通过。
- Review（`review` 技能，只读审查工作树 diff）：未发现有效 finding。逐项核对：
  - `extraBodyKey` 删除后无任何引用残留（全仓 grep 确认）；`ExtraBody.isConfigured` / `isValid` / `fields`
    仍全部被使用，无死代码。
  - `object[key] == nil` 的“仅补位”语义与 `Payload` 的可选字段一致：`JSONEncoder` 对 `nil` 省略键而
    不写 `null`，因此 `temperature` / `reasoning_effort` 未设置时才能被 extra body 补上。
  - 布尔与整数经 `JSONSerialization` 往返后类型不变（验证输出 `"enable_thinking":false`、`"top_k":20`）；
    `temperature` 在同一条合并路径下仍写作 `0.20000000000000001`，与改动前带 extra body 的请求体一致，
    非本次引入。
  - 非法 JSON / 非对象 JSON（数组）走原有 `fields == nil` 分支，不抛错也不会把非法值下发。
  - 六语 footnote 与 `ExtraBody` / `encoded()` 注释已无 `extra_body` 旧措辞；类型与持久化槽位未改名。
  - 实现方式判断：沿用既有「`Payload` 编码 + `JSONSerialization` 字典合并」路径，是满足目标的最小改动；
    自定义 `Encodable` 包装（例如 `extra_body` 键展开）会重复一份优先级逻辑且无法表达“只补缺失键”。
- 满足“有效 finding 已修复后重新验证”的要求：本次无 finding，无需修复与重审增量。
- `jq -e . Easydict/App/Localizable.xcstrings`：通过（六语文案与 `state` 已核对）。
- 未运行：SwiftFormat / SwiftLint（本机未安装，仓库无 lint workflow），按 `--maxwidth 120` 人工核对新增行。
- 未做真机端到端验证：未用真实 API key 走 Custom OpenAI 服务抓包，仍建议用户按上述手工步骤在
  GUI 中确认一次请求体。

### 受影响文件

- `Easydict/Swift/Service/OpenAI/ChatQueryBody.swift`
- `Easydict/App/Localizable.xcstrings`

### 后续事项

- 升级后旧的配置值语义变了：此前用户 JSON 里的字段是被包在 `extra_body` 下发的，现在直接位于
  顶层；依赖旧包装的网关需要用户自行改写为 `{"extra_body": {...}}`，不做迁移。
- 无 plan 需要归档；`plans/openai-extra-body-merge.md` 为评审草稿，未跟踪、不提交，可随时删除。
