## 2026-11-18 | 任务：修复 Codex 思考程度本地化警告

**Links:** 无

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.2.1 / Xcode 27.2 (27B52)`

### 用户请求

修复 `Localizable.xcstrings` 中的八条找不到源码引用警告。

### 变更

- 在 `CodexReasoningEffort.title` 中直接返回八个 `LocalizedStringKey` 字面量，并移除无调用方的 `localizedTitle`。
- 清除八个条目的 `stale` 标记，保留原键名、译文和译者注释。

### 设计意图

Codex 设置的思考程度选项继续读取相同的 String Catalog 条目。让 Swift 编译器从实际调用路径提取静态键，便于 Xcode 同步源码引用。

### 验证

- `xcodebuild test -testPlan Default` 定向运行 `CodexServiceTests` 和 `CodexRequestCoordinatorTests`，macOS arm64 Debug 构建成功，17 项测试通过。
- 对照构建生成的 `.stringsdata`，八个键均被提取。对原目录条目的临时副本运行 `xcstringstool sync` 后，八项均恢复可提取状态。
- 核对构建产物中七种语言的 56 条译文，均与基线一致。代码审查未发现回归。

### 受影响文件

- `Easydict/App/Localizable.xcstrings`
- `Easydict/Swift/Service/Codex/Configuration/CodexReasoningEffort.swift`

### 后续事项

- None
