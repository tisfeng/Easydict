## 2026-11-20 | 任务：集中 Swift Debug 构建判断

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-20-consolidate-debug-checks.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

使用 `BuildConfig` 替换 Swift 行为分支中的 `DEBUG` 条件编译，按已确认的方案执行。

### 变更

- 菜单栏图标渲染、事件处理计时和遥测使用现有的 `BuildConfig.isDebug`。
- 把 zlib 压缩 helper 移到唯一调用它的 MDict 测试文件，保留现有往返测试。
- 自有源码的 `DEBUG` 条件编译从 9 处减至 3 处。

### 设计意图

在 Swift 中集中构建类型判断，保留事件计时的函数级 `defer` 和配置单例的初始化顺序。
Objective-C 中两个条件编译继续提供日志全局变量的静态初始值，以及日志分类的编译隔离。

### 验证

- `xcodebuild test -configuration Debug -only-testing:EasydictTests/MDictReaderTests` 通过，21 项通过。
- `xcodebuild build -configuration Release` 原生 arm64 构建通过。SwiftFormat 和 `git diff --check` 通过。
- 实测本次两个构建的方形菜单栏图标。Debug 为蓝色原图，Release 为白色模板图。对照截图存于仓库外。
- 编译产物中事件耗时日志仅见于 Debug。核对了 Firebase 和 Sentry 的判断分支。
  离线运行未从日志确认 Sentry 的实际关闭，未验证远端上报。已恢复原 Debug 实例与临时偏好。
- 最终源码差异审查无发现。

### 受影响文件

- `Easydict/App/EasydictApp.swift`
- `Easydict/Swift/Utility/EventMonitor/Core/EventMonitor.swift`
- `Easydict/Swift/Utility/Logging/AnalyticsService.swift`
- `Easydict/Swift/Service/Dictionary/MDict/MDictReader/MDictBinary.swift`
- `EasydictTests/Service/MDictReaderTests.swift`

### 后续事项

- None
