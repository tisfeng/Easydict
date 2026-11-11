## 2026-11-12 | 任务：重组 Codex 服务目录

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-12-organize-codex-service.md)

### 执行上下文

- **Agent Name:** Codex
- **Model:** GPT-6
- **Environment:** macOS 27.2 / Xcode 27.2 (27B52)

### 用户请求

按 ChatGPTSignIn、LocalCLI 和 AppServer 重组 Codex 服务，同步测试目录及 Xcode 工程，保留既有行为和持久化标识。

### 变更

- 将生产代码和测试迁到 Codex 目录。将托管连接验证、本机可执行文件与环境探测，以及共用请求分别归到对应目录。
- Swift 服务入口改为 CodexService。保留服务类型、Objective-C 名称、Defaults 键、接入模式原始值和账号目录。
- 同步 Xcode 文件分组及 Sources，修正移动后两个现有测试辅助函数的模型目录路径。

### 设计意图

App Server 共用协议、流式事件和取消逻辑，两种接入仍各自拥有独立实例。一次性托管连接验证由 ChatGPTSignIn 负责。

### 验证

- `xcodebuild test -testPlan Default` 定向运行 13 个套件，共 160 项通过。
- `xcodebuild test -testPlan LocalEnvironment` 定向运行真实本机 CLI 的公式 OCR 与流式翻译，共 2 项通过。
- 工程文件解析、24 个生产文件与 14 个测试文件的 Sources 引用、持久化契约和差异检查通过。
- review 核对传输、取消、认证与配置调用链，未发现需修复的问题。

### 受影响文件

- `Easydict/Swift/Service/Codex/`
- `EasydictTests/Service/Codex/`
- `Easydict.xcodeproj/project.pbxproj`
- 服务注册、设置视图及相关测试中的调用引用

### 后续事项

- 本次未单独发起内置浏览器登录或托管 OCR。
