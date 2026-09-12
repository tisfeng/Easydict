# 升级受管 Skills 至 v0.3.4

- 日期：2026-09-11
- 状态：completed
- 关联计划：[`2026-09-11-upgrade-managed-skills-v0-3-4.md`](../../exec-plans/completed/2026-09-11-upgrade-managed-skills-v0-3-4.md)

## 用户请求

将项目依赖的 Skills 更新至 `v0.3.4`，并同步更新项目内相应的 Agent 规则文档。

## 变更

- 将六项通用 Skills 固定同步到 `tisfeng/skills v0.3.4`，并将 planner、reviewer、tester 的 lock
  revision 更新为 `e79154ef1fc076c8c7b6b6a06b46388596d485d2`；三个 agent TOML 内容保持不变。
- 同步 Git 快速执行协议、稳定 PR review 快照、PR 用户语言与最终验证回执、worktree 集成事实
  收集器及其测试，保留逐命令权限、退出状态、漂移和最终刷新门禁。
- 在项目规则中适配执行、review、验证和消费方完整快照边界，并将来源参考从遗留的 `v0.3.2`
  和 `git-delivery` 更新到当前六 Skills、三 agents 的 `v0.3.4` 命令与验证记录。

## 设计意图

将固定上游快照升级与宿主契约迁移作为同一原子任务，避免受管 Skill、agent lock、来源参考和
项目规则形成混合版本；项目差异通过宿主规则表达，不本地修补外部受管资产。

## 验证

- 六个 Skill 目录与固定 tag tracked tree 一致；三个 agent TOML 与上游及 lock SHA-256 一致，
  双 lock 的 tag、revision、JSON 和 TOML 解析通过。
- Python 3.12 运行四个变更 Skill 共 95 项测试，Node.js 运行 agent installer 6 项测试，合计
  101 项通过；变更 Python 文件 compileall 通过。
- 现行规则的 28 个相对链接和锚点、保护路径比较与 `git diff --check` 通过。
- 独立 tester 验证通过；独立 reviewer 完整复核未发现 finding，并独立重算六项
  `computedHash` 与 lock 全部一致。
- 未运行 `xcodebuild`：本次未修改产品或 Xcode 内容。全新任务中的 custom agent 发现 smoke
  不在静态验证范围内。

## 受影响文件

- `.agents/skills/git-commit/`
- `.agents/skills/review-pr/`
- `.agents/skills/submit-pr/`
- `.agents/skills/worktree-rebase-merge/`
- `skills-lock.json`
- `.codex/agents-lock.json`
- `docs/agents/README.md`
- `docs/agents/build-and-test.md`
- `docs/agents/git-workflow.md`
- `docs/agents/review.md`
- `docs/references/tisfeng-skills.md`
- 本任务 plan/history
