## 2026-09-19 | 任务：集中管理重复应用 Bundle Identifier

**Links:** [Easydict PR #1289](https://github.com/tisfeng/Easydict/pull/1289)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

检查生产代码中重复硬编码的应用 Bundle Identifier，并将确认重复的值提取到统一常量。

### 变更

- 在 `AppBundleIDs` 中新增 Sublime Text、Safari、Google Chrome 和 Microsoft Edge 常量。
- 将选中文本流程和浏览器 AppleScript 策略中的重复字面量替换为对应常量。

### 设计意图

仅集中确有重复使用的第三方应用标识符，保持现有 allowlist、浏览器分类和运行时行为不变；Easydict 自身标识符及单次使用的应用标识符不纳入本次范围。

### 验证

- `rg` 重复字面量检查：四个应用标识符仅在 `AppBundleIDs` 常量定义处保留。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict | xcbeautify`：通过。
- `git diff --check`：通过。
- 代码审查：未发现可证实的缺陷。

### 受影响文件

- `Easydict/Swift/Utility/Constants/AppBundleIDs.swift`
- `Easydict/Swift/Utility/EventMonitor/Workflow/SelectionWorkflow.swift`
- `Easydict/Swift/Utility/SystemUtility/SystemUtility.swift`
- `Easydict/Swift/Utility/AppleScript/AppleScriptTask+Browser.swift`
- `docs/histories/2026-09/2026-09-19-centralize-repeated-app-bundle-identifiers.md`

### 后续事项

- Easydict 自身 Bundle Identifier 的 Swift、Objective-C 与构建配置边界需要单独评估。
