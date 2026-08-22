# Agent 任务模式与自动本地提交

- 日期：2026-08-21
- 状态：completed
- 执行计划：`../../exec-plans/completed/2026-08-21-agent-task-modes-auto-commit.md`

## 用户请求

补齐 Scoco `3d773f69d` 中关于 planning、implementation、delivery、protected 模式及
安全自动本地提交的 Agent 规则，并适配 Easydict 当前工作流。

## 变更

- 在 `docs/agents/repository-guide.md` 增加任务模式、自动本地提交条件和 protected
  保护规则。
- 在 `.agents/skills/git-commit/SKILL.md` 增加自动 implementation delivery 流程，
  仅允许暂存明确 Agent 路径，并保护初始用户暂存区。
- 在执行计划模板中增加任务模式和自动提交状态字段。

## 验证

- `git diff --check`：通过。
- 任务模式、暂存区保护、路径隔离和文档-only 排除规则已静态复核。
- 未运行 `xcodebuild`，因为没有修改编译源码、测试或 Xcode 工程元数据。
- 未执行自动 commit；本次变更仅涉及 Agent 文档、skill、计划和历史。

## 边界

未修改产品源码、测试、Xcode 工程或远程 Git 状态；未执行 push、pull、rebase 或 merge。
