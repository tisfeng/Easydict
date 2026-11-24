## 2026-11-18 | 任务：精简 LocalStorage 的 Objective-C 暴露

**Links:** [查询统计拆分记录](2026-11-18-extract-query-usage-store.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

检查存储类的 Objective-C 标注，移除没有调用方的暴露。

### 变更

- 移除 `LocalStorage` 的 `@objcMembers` 和仅由 Swift 使用的成员上的显式标注。
- 保留 `EZLocalStorage` 类名，为 Objective-C 调用到的六个方法和 `queryCount` 属性显式标注。

### 设计意图

按仓库内的 Objective-C 调用点维护桥接接口。保留的 selector 和类型签名与原桥接头文件一致。

### 验证

- `xcodebuild test -testPlan Default -only-testing:EasydictTests/CodexConfigMigrationTests` 构建 macOS arm64 Debug，9 项迁移测试通过。
- 构建中的 SwiftLint 检查 445 个文件，0 条违规。
- 对比编译生成的 `Easydict-Swift.h`，保留 7 个被调用的成员声明，移除 17 个未使用的声明。代码审查未发现回归。

### 受影响文件

- `Easydict/Swift/Service/Model/Storage/LocalStorage.swift`

### 后续事项

- None
