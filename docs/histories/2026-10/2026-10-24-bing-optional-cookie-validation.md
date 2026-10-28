## 2026-10-24 | 任务：允许 Bing 在空 Cookie 时验证

**Links:** [执行计划](../../exec-plans/completed/2026-10/2026-10-24-bing-optional-cookie-validation.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

修复 Bing 设置中无 Cookie 时无法点击验证的问题，按已确认方案验证后提交到本地，不 push。

### 变更

- 通用服务设置组件新增 `requiredKeys`，默认使用 `observeKeys`；监听字段与必填字段分离，合并去重监听两类字段。
- Bing 和对应 Preview 显式使用空必填列表，Cookie 为空或清空后均不禁用验证按钮。
- 验证期间禁用按钮并防止重复触发，保留完成后的成功及失败提示。
- 为全部六种现有语言的 Bing Cookie 标题增加“可选”说明。

### 设计意图

Cookie 在 Bing 请求层本来就是可选字段，因此仅调整设置组件的输入约束，不更改请求行为。
默认参数保留百度、腾讯等其他服务原有的必填校验，避免按服务类型硬编码通用视图。

### 验证

- `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -destination 'platform=macOS' -derivedDataPath <checkout-specific-agent-derived-data> -only-testing:EasydictTests/BingServiceTests`：通过，2 项现有测试通过，同时覆盖 Debug 构建。
- 构建内 SwiftLint：429 个文件，0 violations。
- `git diff --check`、`jq -e . Easydict/App/Localizable.xcstrings`：通过。
- 手动检查：源码核对了 Cookie 为空、填写、再次清空，以及验证中的按钮状态；百度和腾讯仍默认要求全部原有字段非空。
- review：基于 `63463ee1cf9e55a88b24261df4854710f5cf6d17` 的干净初始工作树，审查本次生产代码、本地化及相关调用者，无有效 finding；当前方案范围小且足够。
- 依赖准备曾主动中断并复用本机同版本缓存，最终完整测试退出码为 0；未新增或修改测试。

### 受影响文件

- `Easydict/Swift/Service/Bing/BingService.swift`
- `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/ServiceConfigurationSecretSectionView.swift`
- `Easydict/App/Localizable.xcstrings`
- `docs/exec-plans/completed/2026-10/2026-10-24-bing-optional-cookie-validation.md`
- `docs/histories/2026-10/2026-10-24-bing-optional-cookie-validation.md`

### 后续事项

- 现有 Bing 测试覆盖服务响应处理，不覆盖按钮 UI；本轮未替换其他构建目录正在运行的用户实例，未进行 UI 实测或真实 Bing 联网验证。
