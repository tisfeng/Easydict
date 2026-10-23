## 2026-10-24 | 任务：所有服务使用默认温度

**Links:** [计划](../../exec-plans/completed/2026-10/2026-10-24-remove-all-temperature.md)

### 执行上下文

- **Agent Name:** `Unknown`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

彻底删除所有服务的 temperature 参数、滑块及 supportsTemperature，完成测试和 review 后在 dev 本地提交，不 push。

### 变更

- 公共 OpenAI 兼容请求不传 temperature；DeepSeek 删除请求属性和 CodingKeys 字段。
- 删除温度能力属性、偏好访问器和配置枚举项；删除共享滑块及 CLI 视图中无效的显示选项。
- 删除仅用于温度的 SliderCell、已失效的两个能力测试、工程引用及温度标题的所有翻译。
- Codex 迁移保留旧温度键名作为实例存在的历史证据，不读取或应用旧温度值。

### 设计意图

所有应用管理的服务请求使用提供商默认温度，移除服务与模型能力分支；不清理用户磁盘上的旧偏好，不修改依赖 SDK。SDK ChatQuery 温度缺省 nil，合成编码省略该可选字段；DeepSeek 请求模型已无温度字段。

### 验证

- 独立 Agent DerivedData 下 xcodebuild test：ClaudeSSEParserTests、OpenAIStreamTaskControlTests、QueryModelCancellationTests、CodexConfigurationMigrationTests，24 个现有测试通过，Debug 编译成功。
- 临时使用 EASYDICT_RELEASE_PACKAGING=YES EXCLUDED_SOURCE_FILE_NAMES=Package.resolved；未修改工程配置，不覆盖发布打包。
- 对首次写入前 c593d3c40 的任务差异完成语义 review，无有效 finding；删除方式足够，无需新增能力抽象。测试后文件摘要与审查快照一致。
- String Catalog JSON 有效，语义比较确认只删除温度标题；pbxproj 语法有效且只删除两个文件的 8 处工程引用。
- git diff --check 通过；相关源码无温度能力、参数或 UI 引用，仅保留历史迁移键名和无关 OCR 测试文本。

### 受影响文件

- `Easydict/Swift/Service/` 下公共请求、DeepSeek、Claude、Gemini、MiniMax、OpenAI 及 Codex 迁移。
- `Easydict/Swift/Feature/Configuration/ServiceConfigurationKey.swift`
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/` 下共享及 CLI 配置视图。
- `Easydict/App/Localizable.xcstrings`、`Easydict.xcodeproj/project.pbxproj`
- 删除 `SliderCell.swift`、`OpenAITemperatureSupportTests.swift`；本任务 plan/history。

### 后续事项

- 未验证提供商在线输出效果、GUI 和发布打包；不 push。
