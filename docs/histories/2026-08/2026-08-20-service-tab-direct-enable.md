## 2026-08-20 | 任务：让 ServiceTab 直接启用服务

**Links:** Scoco reference commit `bb96e00e3`

### 用户请求

将 Scoco 中移除服务开关自动验证的修改适配到 Easydict 当前的 ServiceTab 架构。

### 变更

- 移除服务列表开关开启前的 `validate()` 请求、验证进度状态和失败弹窗。
- 让服务开关直接通过 `setServiceEnabled` 持久化状态，并保留 Claude Code 与 Codex CLI 的风险确认。
- 删除不再使用的服务启用失败本地化 key；保留配置详情页的手动验证能力和 `unknown_error`。

### 设计意图

将“是否启用服务”和“服务请求当前是否可用”解耦，避免用户点击开关时依赖网络、API Key 或模型配置。服务配置页仍提供显式的手动验证入口，服务实际查询时继续沿用原有错误处理。

### 验证

- `git diff --check`：通过。
- `swiftformat --lint`：两个修改后的 Swift 文件均无需格式化。
- `jq -e . Easydict/App/Localizable.xcstrings`：通过。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict`：`BUILD SUCCEEDED`。
- 静态检查：ServiceTab 不再包含自动验证入口；配置详情页仍调用 `service.validate()`。

### 受影响文件

- `Easydict/Swift/View/SettingView/Tabs/TabView/ServiceTab.swift`
- `Easydict/Swift/View/SettingView/Tabs/TabView/ServiceTabListViews.swift`
- `Easydict/App/Localizable.xcstrings`

### 后续事项

- 尚未进行运行中的手动 UI 交互验收；后续可确认普通服务直接切换、风险服务仍弹出确认，以及配置详情页手动验证仍可用。
