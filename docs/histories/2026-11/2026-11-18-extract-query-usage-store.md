## 2026-11-18 | 任务：提取查询统计存储

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-18-extract-query-usage-store.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

将查询统计拆到 `QueryUsageStore`，保留调用接口与旧数据兼容性，构建并运行 Codex 迁移测试以确认 SwiftLint 警告消失。

### 变更

- `QueryUsageStore` 负责总查询量、按服务统计、查询等级、埋点和免费额度判断。
- `LocalStorage` 将原有查询统计接口委托给新类型，Xcode 主 target 编译该文件。

### 设计意图

共用原先的 `UserDefaults` 实例和三项存储键，保留服务记录字典格式。Codex 仍在初始化窗口服务配置前读取持久化快照，可识别旧的查询记录。

### 验证

- `xcodebuild build`：macOS arm64 Debug 构建通过，构建中的 SwiftLint 0.65.1 检查 445 个文件，0 条违规。
- `xcodebuild test -testPlan Default -only-testing:EasydictTests/CodexConfigMigrationTests`：9 项通过，0 失败、0 跳过。
- 手动检查：对照基线核对统计读写、额度公式、迁移顺序和默认查询状态，并核对生成的 Objective-C 接口。代码审查未发现回归。

### 受影响文件

- `Easydict/Swift/Service/Model/Storage/LocalStorage.swift`
- `Easydict/Swift/Service/Model/Storage/QueryUsageStore.swift`
- `Easydict.xcodeproj/project.pbxproj`

### 后续事项

- None
