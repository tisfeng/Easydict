## 2026-10-25 | 任务：清理查询服务编译与 SwiftLint 警告

**Links:** [PR #1368](https://github.com/tisfeng/Easydict/pull/1368)、[执行计划](../../exec-plans/completed/2026-10/2026-10-25-clean-query-service-warnings.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

按确认的方案修复所列警告，运行相关测试及完整 SwiftLint，审查通过后本地提交，不 push。

### 变更

- DeepL 嵌套闭包显式访问 self；用不可变上下文传递 appVersion 和 generation，消除参数数量警告。
- QueryService 的私有实现移到同文件 extension，公开可覆写接口与存储属性保留原位。
- BingRequest 按翻译、配置、请求管理和内容辅助组织同文件 extension；抽出翻译和 lookup 发送及响应处理。
- Bing 测试仅修正集合尾逗号及 URLProtocol 的 static 重写，未新增或扩写测试断言。

### 设计意图

通过职责组织消除类体和函数长度警告，不修改 lint 配置或增加禁用指令。
保留公开接口、锁边界、查询代次、独立取消状态、单次完成保护、结果聚合及重试顺序。
同文件 extension 保持 private 访问范围，不增加 Xcode 工程文件。

### 验证

- 基线完整 SwiftLint：复现 7 条 lint 警告。
- 修改后 `swiftlint lint --no-cache`：429 个文件，0 violations、0 serious。
- `swiftformat --lint`：4 个修改的 Swift 文件均无需格式调整。
- Debug arm64 `xcodebuild test`：6 个 suite、60 个测试通过，覆盖 BingServiceTests、DeepLServiceTests 的离线用例、CodexStreamInvalidationTests、OpenAIStreamTaskControlTests、QueryModelCancellationTests 和 AppleLanguageDetectorTests。
  使用当前 checkout 专用 Agent DerivedData，设置 `EASYDICT_RELEASE_PACKAGING=YES` 避免构建自动格式化；DeepL 真实服务用例通过 `-skip-testing` 排除。
- 编译日志中所列 Swift 6 显式 self 警告已消失；仍有两个不依赖 AppIntents.framework 时跳过元数据提取的工具提示，不属于源码编译警告。
- `git diff --check`：通过；测试宿主已退出。
- `review`：完整读取本任务 diff，核对私有访问范围、Bing 提前返回/双响应聚合/单次完成/重试，以及 DeepL 的锁和代次传递；未发现有效 finding。
  对照基线确认两个 Bing 响应处理器在仅替换回调名称、忽略空白后内容一致，QueryService 私有实现原样移动。

### 受影响文件

- `Easydict/Swift/Service/Bing/BingRequest.swift`
- `Easydict/Swift/Service/DeepL/DeepLService+Translate.swift`
- `Easydict/Swift/Service/Model/QueryService.swift`
- `EasydictTests/Service/BingServiceTests.swift`
- 本任务 plan/history。

### 后续事项

- 未运行真实翻译/语音账号服务、Release、Intel 或 macOS 13 硬件验证；本次不扩大为 Swift 6 全量迁移。
- 仅本地提交，不 push，不修改 GitHub 评论或 review 状态。
