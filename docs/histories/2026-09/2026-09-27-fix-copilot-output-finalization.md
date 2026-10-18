## 2026-09-27 | 任务：修复 Copilot 流式输出收尾竞态

**Links:** [PR 评论](https://github.com/tisfeng/Easydict/pull/1332#discussion_r4114397251)、
[执行计划](../../exec-plans/completed/2026-09/2026-09-27-fix-copilot-output-finalization.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

在现有功能分支实现单一读取者方案，修复进程结束时译文末尾可能被丢弃的问题。

### 变更

- stdout、stderr 分别由一个后台读取循环持有，结束回调只提交退出码，不再竞争读取管道。
- 每个请求有独立串行队列，数据处理完成后才提交读取完成标记；两个读取者与进程全部结束后，
  统一处理末行、usage、错误、完整文本回退和流结束，通过状态标记保证只收尾一次。
- 启动失败关闭全部管道句柄；正常启动关闭父进程写端，读取者结束时关闭读端。
- 读取失败和工具请求主动停止子进程；取消或错误停止后，仍运行超过两秒的进程使用 SIGKILL 兜底。
- 保持现有模型参数、认证、字节级分行及 stderr 限长策略；未修改其他 CLI 服务或 review-pr 技能。

### 设计意图

串行队列屏障不能等待读取后尚未入队的数据。由读取者处理每块数据后再报告完成，消除这段空窗，
并把进程退出与输出读完建模为不同条件。同步交付到请求队列也避免快速输出无限积压待处理块。

采用 POSIX `read` 获取可用字节并处理 EINTR，避免流式读取依赖高层 API 是否持续读取到指定长度。
调查参考了 [swift-corelibs-foundation FileHandle 实现](https://github.com/swiftlang/swift-corelibs-foundation/blob/main/Sources/Foundation/FileHandle.swift)；
该跨平台源码仅用于 API 选择分析，不作为 macOS 实测证据。

### 验证

- `swiftformat --lint Easydict/Swift/Service/GitHubCopilot/GitHubCopilotRunner.swift`：通过。
- `git diff --check`：通过。
- `xcodebuild build`：独立 DerivedData、Easydict workspace/scheme、Debug 构建通过，确认重新编译 Runner；
  设置 `EASYDICT_RELEASE_PACKAGING=YES` 跳过构建阶段的全仓格式与 lint，变更文件单独检查格式。
- review 技能审查：完整 diff、取消调用链、输出顺序、UTF-8 字节缓存、无换行末行、启动失败、
  读取失败和工具拦截路径，无未处理的有效 finding。请求级串行队列足以表达完成条件，无需公共 CLI 抽象。
- 现有测试没有 Copilot Runner 专项用例；未获新增测试授权，未新增或扩写测试。
  Xcode 调试宿主运行中，未运行冲突的应用宿主测试。本轮没有进行运行时竞态压力验证。

### 受影响文件

- `Easydict/Swift/Service/GitHubCopilot/GitHubCopilotRunner.swift`
- `docs/exec-plans/completed/2026-09/2026-09-27-fix-copilot-output-finalization.md`
- `docs/histories/2026-09/2026-09-27-fix-copilot-output-finalization.md`

### 后续事项

- 建议后续获授权后补充快速退出、跨字节边界、末行无换行、错误和取消的专项回归验证。
- PR 的工程对象重复声明与 review-pr 分支复用策略属于独立范围，本轮未修改。
