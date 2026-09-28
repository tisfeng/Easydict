## 2026-09-27 | 任务：自动更新 Copilot 模型目录

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-27-copilot-scheduled-model-refresh.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

启动后自动刷新一次 Copilot 模型列表，随后每 24 小时后台刷新，保持简单调度和本地模型选择体验。

### 变更

- AppDelegate 在启动与退出时通过 Service 的 Objective-C 桥接管理共享 Store 的定时器。
- 单一定时器首次延迟 5 秒，之后每 24 小时触发；任一查询窗口启用 Copilot 时才请求目录。
- 自动刷新复用手动刷新的请求合并、原子缓存写入和界面通知。退出时停止定时器并取消正在进行的刷新，保存前检查取消状态。
- 同步缓存设计说明及中英文指南。

### 设计意图

共享 Store 已拥有模型缓存和刷新任务，直接持有一个定时器即可。模型菜单与翻译继续读取本地目录，
失败保留旧数据，更新不会改动模型选择或自动重译。不增加缓存过期、失败冷却、激活、唤醒、
打开设置页或首次启用时触发更新的逻辑。

### 验证

- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -configuration Debug -derivedDataPath <checkout-specific-agent-derived-data> EASYDICT_RELEASE_PACKAGING=YES`：通过；使用独立 Agent DerivedData。
- `swiftformat --lint <三个变更 Swift 文件>`、工程固定版本 `swiftlint lint --quiet <同上>`：通过。
- `git diff --check`：通过。
- 生成的 Swift Objective-C 头包含 `startAutomaticModelUpdates` / `stopAutomaticModelUpdates`，AppDelegate 编译通过。
- review：任务基线为 `d4656629607de6ed9dc7b55b64ec99cbc284b6c6`，初始工作树与索引干净；冻结任务文件内容后审查并复验。检查生命周期、窗口启用判断、并发合并、取消、失败缓存及更新通知路径，未发现有效 finding；单一定时器复用 Store 的实现足够。
- 现有测试没有覆盖 Copilot 调度；未新增测试。验证期间 Xcode 正运行同 bundle ID 的调试实例，未另起应用或运行 app-hosted tests。

### 受影响文件

- `Easydict/App/AppDelegate.m`
- `Easydict/Swift/Service/GitHubCopilot/GitHubCopilotModelStore.swift`
- `Easydict/Swift/Service/GitHubCopilot/GitHubCopilotService.swift`
- `Easydict/Swift/Service/GitHubCopilot/GitHubCopilotModelCatalog.swift`
- `docs/design-docs/app-path-management.md`
- `docs/user-docs/en/GUIDE.md`
- `docs/user-docs/zh/GUIDE.md`
- `docs/exec-plans/completed/2026-09/2026-09-27-copilot-scheduled-model-refresh.md`
- `docs/histories/2026-09/2026-09-27-copilot-scheduled-model-refresh.md`

### 后续事项

- 首次触发及完整 24 小时周期尚未做运行时验证；本次验证范围为构建、静态检查和调用链审查。
