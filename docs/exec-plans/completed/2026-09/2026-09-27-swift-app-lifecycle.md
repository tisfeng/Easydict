# Swift 应用生命周期入口

- 状态：completed
- 创建日期：2026-09-27
- 负责人：Codex
- 关联 Issue/PR：None

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

## 背景

Copilot 自动刷新通过 Objective-C AppDelegate 调用新增的 Swift 桥接方法。用户要求将启动后工作集中到 EasydictApp.swift，减少不必要的 @objc 暴露，并保留有意义的退出处理。

## 目标与范围

- 目标结果：Swift 统一接收启动和退出通知，分别集中启动后工作与退出工作，直接调用模型 Store 和词汇本 flush。
- 允许修改路径：EasydictApp.swift、AppDelegate.m、GitHubCopilotService.swift、VocabularyNotebookService.swift 的调用说明及任务 plan/history。
- 同任务 history：`docs/histories/2026-09/2026-09-27-swift-app-lifecycle.md`
- 用户限制：移除本次生命周期桥接；保留词汇本 flush。
- 非目标：修改刷新策略、移动 OCR 预热、重构子进程清理、增加测试、推送或 PR。
- 验收标准：订阅每进程仅注册一次；启动函数仅执行一次且不依赖视图显示；退出同步发出取消请求并完成此前排队的词汇本写入；无新增 @objc 方法，AppDelegate 不再持有退出工作。

## 工作计划

1. EasydictApp 初始化时注册并持有生命周期订阅，将启动后工作集中到单独函数。
2. 删除 Service 的两个桥接方法，将词汇本 flush 一起迁入统一的 Swift 退出函数，移除 AppDelegate 的退出回调。
3. 格式、静态检查、独立 DerivedData 构建及 review。
4. 记录 history、归档 plan 并创建本地提交。

## 风险与决策

- 基线为 `49e75459d25a94bd7197cc9c1248c444fdce2ca6`；初始工作树和索引干净。
- 词汇本退出工作补迁的基线为 `8d8224cd08e3cd131b70699f22516e8848c3a446`；初始工作树和索引干净，复用本任务记录。
- AppKit 的启动/退出通知在主线程发布，订阅同步处理，显式建立 MainActor 边界；不使用延迟投递或异步 Task 包装退出处理。
- 静态订阅与 SwiftUI 视图显示无关，first() 限定通知处理次数。
- 保持现有取消语义：发出取消请求，不宣称等待 CLI 退出或临时文件删除完成。

## 进度

- [x] 生命周期迁移
- [x] 验证与 review
- [x] history 与归档，随任务范围创建本地提交
- [x] 词汇本退出工作补迁、验证及提交

## 验证

- 独立 Agent DerivedData 下 Debug `xcodebuild build`（`EASYDICT_RELEASE_PACKAGING=YES`）：通过。
- 两个变更 Swift 文件的 SwiftFormat lint、工程固定版本 SwiftLint 和 `git diff --check`：通过。
- 生成的 Swift Objective-C 头不再包含两个桥接 selector；AppDelegate 编译成功。
- review：按基线冻结任务内容并复验无漂移；检查初始化时机、静态订阅持有、first()、同步主线程交付和原有退出 flush，未发现有效 finding。进程级静态订阅已足够，无需新增生命周期管理类。
- 未新增测试；现有测试没有覆盖该启动路径。Xcode 正运行同 bundle ID 调试实例，未另起应用或 app-hosted tests，因此未实测启动/退出通知与定时触发。
- 词汇本补迁后重新通过 Debug 构建、两个变更 Swift 文件的格式/lint 与差异检查。review 冻结补迁基线及文件内容后复验无漂移；确认 flush 仅由统一退出函数同步调用，串行写入队列不会同步等待主线程，未发现有效 finding。运行验证仍受同一 Xcode 调试实例限制。

## 完成条件

- 构建及静态检查通过，review 无未处理的有效 finding。
- 任务记录与验证边界一致，完成本地提交。
