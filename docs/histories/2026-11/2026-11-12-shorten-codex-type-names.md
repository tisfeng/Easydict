## 2026-11-12 | 任务：简化 Codex 文件名和类型名

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-12-shorten-codex-type-names.md)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

### 用户请求

同步缩短八组 Codex 类型与文件名，更新测试和工程引用，保留现有行为及持久化标识。

### 变更

- 同步重命名 CodexAccount、CodexConnectionCheck、CodexCommandProcess、CodexRuntime、CodexCLIInstallation、CodexServiceConfig、CodexConfigMigration 和 CodexServiceError。
- 更新六个测试套件、账户测试辅助文件、调用者、Xcode 引用和运行时文档。

### 设计意图

保留 Codex 前缀与具体职责。沿用原有工程对象 ID、接入模式原始值、Defaults 键和运行时配置。

### 验证

- `xcodebuild test -testPlan Default` 的 13 个定向套件共 160 项通过。
- `xcodebuild test -testPlan LocalEnvironment` 的真实本机 CLI 公式 OCR 和流式翻译 2 项通过。
- 工程解析、文件基名冲突、target membership 和差异检查通过。review 未发现需修复的问题。

### 受影响文件

- `Easydict/Swift/Service/Codex/` 及调用者
- `EasydictTests/Service/Codex/`
- `Easydict.xcodeproj/project.pbxproj`
- `scripts/codex-runtime/` 的类型名说明

### 后续事项

- 本次未单独实测内置浏览器登录或托管 OCR。
