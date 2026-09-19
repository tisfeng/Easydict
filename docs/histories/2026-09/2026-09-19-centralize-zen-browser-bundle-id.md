## 2026-09-19 | 任务：集中管理 Zen Browser Bundle Identifier

**Links:** [Easydict PR #1289](https://github.com/tisfeng/Easydict/pull/1289)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

参考 WeChat 的应用常量，移除 Zen Browser Bundle Identifier 在取词流程中的分散硬编码。

### 变更

- 在 `AppBundleIDs` 中新增 `zenBrowser` 常量。
- 将 Zen Browser 取词判断和 selectable-text allowlist 中的三处字面量替换为统一常量。

### 设计意图

将特定应用的 Bundle Identifier 保持在已有的中央常量容器中，避免重复字面量漂移，同时不改变 Zen Browser 的现有取词行为。

### 验证

- `rg -n '"app\.zen-browser\.zen"' Easydict`：仅命中 `AppBundleIDs` 常量定义。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict | xcbeautify` ：通过。
- `git diff --check` ：通过。
- 独立代码审查：未发现可证实的缺陷。

### 受影响文件

- `Easydict/Swift/Utility/Constants/AppBundleIDs.swift`
- `Easydict/Swift/Utility/EventMonitor/Workflow/SelectionWorkflow.swift`
- `Easydict/Swift/Utility/SystemUtility/SystemUtility.swift`
- `docs/histories/2026-09/2026-09-19-centralize-zen-browser-bundle-id.md`

### 后续事项

- Zen Browser 绕过“强制取词”开关的现有行为不在本次常量收口范围内。
