# 记录显式 git-commit 空索引 fallback

- 日期：2026-08-27
- 状态：completed
- 来源：Scoco `b9adbae199ac48704dc2f48723e2482faaf8a488`

## 背景

Scoco 本次提交恢复了显式 `/git commit` 在空暂存区时的一次性 `git add .` fallback。核对发现，Easydict 当前 skill 已经具备相同规则，因此不重复修改功能文本。

## 变更

- 确认 Easydict 在空暂存区时允许一次 `git add .`，之后重新读取状态和 staged raw patch。
- 确认已有 staged 内容时不运行 `git add`。
- 确认 implementation 自动交付仍只暂存明确的 Agent-owned paths。
- 通过本 history 记录该来源提交在 Easydict 中的适配结果，避免创建空提交。

## 边界

本次只记录 git-commit 行为的跨仓库核对结果，不修改产品代码、Xcode 工程、运行时资源或远程状态。

## 计划

本任务执行计划：[`2026-08-27-scoco-agent-docs-port.md`](../../exec-plans/completed/2026-08-27-scoco-agent-docs-port.md)。

## 验证

- 已核对 Easydict skill 的显式 fallback 与 implementation 精确暂存边界。
- `git diff --check` 和 staged patch 检查在提交前完成。
