## 2026-09-27 | 任务：集中 Swift 应用生命周期工作

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-27-swift-app-lifecycle.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

将启动后工作集中到 EasydictApp.swift，移除 Copilot 新增的 @objc 桥接，通过 Swift 处理退出取消并保留词汇本 flush。

### 变更

- EasydictApp 初始化时访问静态 Combine 订阅，启动和退出通知各处理一次，与视图显示及重建无关。
- 新增 `performPostLaunchTasks()`，直接启动共享模型 Store 的自动刷新；退出通知同步调用取消入口。
- 删除 GitHubCopilotService 的两个生命周期桥接方法和 AppDelegate 对应调用；词汇本 flush 原样保留。

### 设计意图

应用级协调集中在 Swift 入口，模型调度仍由 Store 管理。静态订阅无需新建管理类，也无需通过
Objective-C 暴露薄包装。AppKit 主线程通知通过 MainActor.assumeIsolated 同步访问 Store，避免
退出取消排到应用结束之后。原有首次 5 秒及后续 24 小时策略保持不变。

[Apple 的进程退出说明](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man2/_exit.2.html)
指出父进程退出并不直接终止其子进程，因此保留取消入口；当前取消仍是尽力请求，不保证子进程及临时目录在主进程退出前清理完成。

### 验证

- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -configuration Debug -derivedDataPath <checkout-specific-agent-derived-data> EASYDICT_RELEASE_PACKAGING=YES`：通过。
- `swiftformat --lint <两个变更 Swift 文件>`、工程固定版本 `swiftlint lint --quiet <同上>`、`git diff --check`：通过。
- 生成的 Swift Objective-C 头不再包含 `startAutomaticModelUpdates` / `stopAutomaticModelUpdates`；AppDelegate 编译成功。
- review：基线 `49e75459d25a94bd7197cc9c1248c444fdce2ca6`，初始工作树和索引干净；冻结任务内容并复验，检查订阅生命周期、主线程同步交付、桥接删除和保留的 flush，未发现有效 finding。现有静态订阅方案足够。
- 没有覆盖该启动路径的现有测试，未新增测试。Xcode 正运行同 bundle ID 调试实例，未另起应用或 app-hosted tests。

### 受影响文件

- `Easydict/App/EasydictApp.swift`
- `Easydict/App/AppDelegate.m`
- `Easydict/Swift/Service/GitHubCopilot/GitHubCopilotService.swift`
- `docs/exec-plans/completed/2026-09/2026-09-27-swift-app-lifecycle.md`
- `docs/histories/2026-09/2026-09-27-swift-app-lifecycle.md`

### 后续事项

- 启动/退出通知与定时触发尚未做运行时验证；本次完成构建、静态检查及代码审查。
