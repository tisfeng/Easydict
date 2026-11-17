## 2026-11-12 | 任务：归位 Codex 共用源码和测试

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-12-group-codex-shared-files.md)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

### 用户请求

按职责整理 Codex 的根目录文件，同步测试和 Xcode 工程。

### 变更

- 将服务入口、请求协调、错误和用量类型归入 Service，将接入、模型与持久化配置归入 Configuration。
- 将一次性 exec 的事件解析归入 Exec，从中提取 CodexTokenUsage。
- 同步测试目录和 Xcode 分组，保留已有文件引用 ID。

### 设计意图

一次性 exec 和 App Server 共用用量类型。保持原有 Swift 标识、持久化键及请求逻辑。

### 验证

- `xcodebuild test -testPlan Default` 的 160 项定向测试通过。
- `xcodebuild test -testPlan LocalEnvironment` 的真实本机 CLI 公式 OCR 和流式翻译 2 项通过。
- 工程解析、Sources 引用、迁移前后实现比较及差异检查通过。

### 受影响文件

- `Easydict/Swift/Service/Codex/`
- `EasydictTests/Service/Codex/`
- `Easydict.xcodeproj/project.pbxproj`

### 后续事项

- 本次未单独实测内置浏览器登录或托管 OCR。
