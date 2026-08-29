## 2026-08-20 | 任务：统一服务配置控件间距并展示服务标识

**Links:** Scoco reference commit `0057c294d`

### 用户请求

将 Scoco 服务配置页面的控件间距和服务标识展示调整适配到 Easydict。

### 变更

- 移除服务配置输入框、选择器、开关、滑块、安全输入框和文本编辑器的外层行级 padding。
- 在带 UUID 的服务配置页末尾展示 `serviceTypeWithUniqueIdentifier()`。
- 添加服务标识标题的六种 locale 本地化文本。

### 设计意图

由外层配置 Section 统一控制行间距，避免不同控件自行添加 padding 导致布局不一致。服务标识仅对具体服务实例显示，并放置在所有配置项之后；服务标识生成、持久化和路由逻辑保持不变。

### 验证

- `git diff --check`：通过。
- `swiftformat --lint`：涉及的 5 个 Swift 文件均通过，`0/5 files require formatting`。
- `jq -e . Easydict/App/Localizable.xcstrings`：通过，六个现有 locale 均包含服务标识标题。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict`：通过，`BUILD SUCCEEDED`。
- 静态检查：指定控件不再包含外层 `.padding(10)`；TextEditor 内部 inset 保留；服务标识仅在 UUID 非空时显示且位于最后配置项之后；`QueryService` 和 `CustomOpenAIService` 的标识逻辑未修改。

### 受影响文件

- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/SecureTextField.swift`
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/ServiceCells.swift`
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/SliderCell.swift`
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/StreamConfigurationView.swift`
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/TextEditorCell.swift`
- `Easydict/App/Localizable.xcstrings`
- `docs/histories/2026-08/2026-08-20-service-config-spacing-identifier.md`

### 后续事项

- 尚未进行运行中的手动 UI 交互；后续可确认普通服务配置页的行间距、Custom OpenAI 实例底部标识及标识文本选择行为。
