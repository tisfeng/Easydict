## 2026-10-23 | 任务：移植 Scoco 取消注册、测试规则与 OCR 调度修复

**Links:** [执行计划](../../exec-plans/active/2026-10-23-port-scoco-query-and-ocr-fixes.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.1 (27A9275)`

### 用户请求

执行已确认候选 F1、F2、F3；F1 连同相关回归测试移植，验证和 review 后分别本地提交，不 push。
使用独立 worktree，不自动合并到开发基线。

### 变更

- F1 已完成：来源 `7f219bee2b088c5affef07eddd76a3b00e11b6ea`。
  QueryModel 取消注册表统一由 NSLock 保护；先移除再回调，批量停止原子取走快照，
  被替换/清除的旧闭包在解锁后释放。同步 Swift/ObjC API 保持兼容。
- F1 测试：移植 7 个取消注册回归测试（析构重入有替换、清除两个参数场景），
  按目标目录组织到 `EasydictTests/Model/`，补齐工程引用和测试 Sources。
- F2 已完成：来源 `7f219bee2b088c5affef07eddd76a3b00e11b6ea` 的实例规则及
  `03c6c63333df859f408e0422e0dfeb6aed5ac568` 的精简版本。
  根据实际共享资源冲突决定隔离或串行；区分测试宿主和意外重复，保留用户明确多实例例外。
- F3 待完成，尚未标记为已移植。
- F1 目标提交：`2e5b45b6e91cc62404a38cadcb40ef4c4ba71fd4`。

### 设计意图

Easydict 起点为本地 dev `a2ed12e619113bf6c20cd423496a6f513b90528d`；
Scoco 开发基线为 dev `03c6c63333df859f408e0422e0dfeb6aed5ac568`。
按实际共享行为移植，不机械 cherry-pick。取消锁仅保护注册表，不把整个 QueryModel 声称为线程安全。
回调及捕获对象析构都可能重入，必须在锁外执行；批量停止后的新注册继续有效。

### 验证

- F1 完整应用：`xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict
  -configuration Debug -destination 'platform=macOS' -derivedDataPath <checkout-agent-derived-data>
  -enableThreadSanitizer NO -only-testing:EasydictTests/QueryModelCancellationTests
  -only-testing:EasydictTests/OpenAIStreamTaskControlTests`，10/10 通过；同配置编译已覆盖。
- F1 补充 TSAN：临时独立 Swift 包原样抽取生产取消 API、锁/字典，运行相同移植 suite，
  `swift test --sanitize thread` 7/7 通过，含两个析构参数场景，无 TSAN 报告。
- 完整宿主 TSAN 未通过：测试连接前，Ollama 初始化的异步任务读取 `QueryService.uuid`，
  与 `QueryServiceFactory.service(withTypeId:)` 在初始化后写入该属性竞争。
  两个相关文件均未修改；测试尚未开始，不将该运行算作回归通过。
  隔离包不包含完整模型/应用初始化，不能替代完整宿主 TSAN 证明。
- F1 构建脚本：SwiftFormat 0 文件修改；SwiftLint 430 文件零 violation。
  `plutil -lint Easydict.xcodeproj/project.pbxproj`、`git diff --check` 通过。
- F1 review：冻结基线与三个源码/测试/工程文件的 SHA-256，核对全部 raw diff、新测试、
  QueryService/DeepL/Google 调用者、闭包生命周期和工程引用；复验摘要一致，无有效 finding。
  当前窄锁方案足够，不需要扩大为模型 actor 化。

- F2：`git diff --check`、Markdown 相对链接及规则语义检查通过。
  文档 review 核对共享资源、用户实例保护、测试宿主识别、异常排查与构建隔离，无有效 finding。
  [Apple 测试运行选项](https://help.apple.com/xcode/mac/current/en.lproj/dev6061748b5.html)
  说明单元测试可由多个应用实例承载；这不证明任意共享偏好或全局快捷键可以无冲突并行。
  本次测试前没有运行中的 Easydict，未实际验证与用户 GUI 实例并行的资源安全性。

### 受影响文件

- `Easydict/Swift/Model/QueryModel.swift`
- `EasydictTests/Model/QueryModelCancellationTests.swift`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/agents/build-and-test.md`
- 本任务 plan/history。

### 后续事项

- 继续 F3，并补全提交映射。
- 完整宿主 TSAN 的既有 Ollama 服务初始化竞争另行处理；本次不扩大修复范围。
- 尚未集成到本地 dev，不 push；未执行 GUI、真实服务账号或其他 macOS 版本验证。
