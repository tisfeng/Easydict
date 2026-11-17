## 2026-09-28 | 任务：调整服务添加弹窗分组排序

<!-- 文件名：YYYY-MM-DD-<slug>.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->

**Links:** None

### 执行上下文

- **Agent Name:** `/root`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

将服务添加弹窗的服务类型分组顺序调整为 built-in、no-key、cli、key。

### 变更

- 按请求调整 `ServiceAPIKeyRequirement.addSheetOrder`。
- 记录本次执行结果。

### 设计意图

由弹窗现有分组顺序数组统一控制分类显示次序；每组仍按现有可添加服务列表筛选，空组继续隐藏。

### 验证

- `git diff --check`：通过。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath "$agent_dd" | xcbeautify`：Build Succeeded。
- 手动 UI 检查：未执行；构建验证通过，分组顺序与实现数组一致。

### 受影响文件

- `Easydict/Swift/View/SettingView/Tabs/TabView/ServiceTabListViews.swift`
- `docs/histories/2026-09/2026-09-28-service-category-order.md`

### 后续事项

- None
