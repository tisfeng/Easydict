# code-simplifier 通用核心与 Swift/Xcode 规则拆分

- 日期：2026-08-27
- 状态：completed
- 来源：Scoco `24762102854d8b509fd01eb04686c80ee74b0e04`

## 背景

现有 `code-simplifier` skill 将通用代码简化原则与 Swift、SwiftUI、并发和 Xcode 规则混在一起，也对 planning 阶段的工作树修改授权表达不够清晰。

## 变更

- 将功能保持、项目上下文、清晰度、适度重构、范围和授权规则收敛到通用 `SKILL.md`。
- 新增 `references/swift-xcode.md`，按需承载 Swift、SwiftUI、并发、Xcode 和文档文本专项规则。
- 让 planning、检查和只读 review 保持只读，不改变产品行为或公共契约。

## 边界

本次只修改 `code-simplifier` skill 及其专项 reference，不修改 Easydict 产品源码或 Xcode 工程。

## 计划

本任务执行计划：[`2026-08-27-scoco-agent-docs-port.md`](../../exec-plans/completed/2026-08-27-scoco-agent-docs-port.md)。

## 验证

- 检查专项 reference 的相对链接和 Markdown 格式。
- 静态确认通用 skill 不再强制套用 Swift 或 Easydict 专属规则，并通过专项 reference 按需加载 Swift/Xcode 约束。
