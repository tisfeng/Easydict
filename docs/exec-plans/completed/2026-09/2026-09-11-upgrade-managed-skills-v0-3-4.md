# 升级受管 Skills 至 v0.3.4

- 状态：completed
- 创建日期：2026-09-11
- 负责人：Codex
- 关联 Issue/PR：none

## 背景

Easydict 当前将六项通用 Skills 与 planner、reviewer、tester 锁定在
`tisfeng/skills v0.3.3`。上游 `v0.3.4` 增加 Git 工作流的快速执行协议、稳定 PR review
快照、PR 内容语言契约和确定性集成事实收集器；宿主规则与来源参考需要同步适配。

## 任务摘要

- 意图模式：implementation
- 交付授权：auto-local-commit
- 安全状态：normal
- 目标结果：同步固定 `v0.3.4` 受管资产，并语义化更新项目 Agent 规则和来源参考。
- 允许修改路径：六项 `tisfeng/skills` 受管 Skill 目录、三个受管 agent、双 lock、
  `docs/agents/` 相关规则、`docs/references/tisfeng-skills.md` 以及本任务 plan/history。
- 同任务 history：`docs/histories/2026-09/2026-09-11-upgrade-managed-skills-v0-3-4.md`。
- 禁止动作：不修改项目专属或独立 Skill、Codex 本地配置、Claude 链接、产品代码或 Xcode
  工程；不 push。
- 验收标准：受管内容与固定 tag 一致，双 lock 有效，项目规则与新版契约一致，保护路径不变，
  相关测试、静态检查和独立复核通过。

## 写入前状态

- 写入前检查：pass。
- 自动提交资格：eligible；初始工作树与索引为空，目标、允许路径和验证范围明确。
- 初始 HEAD：`e78162098ffa31cbc446746851aa906d0c07a979`，detached HEAD。
- 初始 staged 路径：无。
- 初始 unstaged 路径：无。
- 初始 untracked 路径：无。
- 初始冲突：无。
- Agent-owned paths：上述允许路径中本任务实际产生的全部差异。

## 目标与非目标

### 目标

- 从固定 `v0.3.4` 同步六项 Skills 和 planner、reviewer、tester。
- 保持外部受管目录为完整消费方快照，不引入上游仓库自用的源码发现链接。
- 将 Git、PR review、PR 提交和验证规则迁移到新版契约。
- 修正 `docs/references/tisfeng-skills.md` 中仍停留在 `v0.3.2` 的版本、角色和命令。

### 非目标

- 不修改 `release-easydict`、`fireworks-tech-graph`、`.codex/config.toml`、`.claude/skills`
  或 `.claude/CLAUDE.md`。
- 不修改产品代码、应用内置 Agent/runtime 资源或 Xcode 工程。
- 不发布、不创建 PR、不 push。

## 工作计划

1. 核验远程 tag、peeled commit、安装器版本、初始状态和保护路径。
2. 使用固定版本安装器分批同步 Skills、agents 和双 lock，并分别检查 diff。
3. 语义化更新项目 Git、review、验证、外部资产边界和来源参考。
4. 验证受管内容、双 lock、Python/TOML/JSON、文档链接、保护路径和 diff。
5. 委派 tester 验证与 reviewer 最终复核，修复范围内问题并增量复验。
6. 归档计划、完善 history，并按新版 `git-commit` 自动本地提交。

## 风险与决策

- `v0.3.4` annotated tag 未签名；同步时同时冻结 tag 和 peeled commit
  `e79154ef1fc076c8c7b6b6a06b46388596d485d2`。
- 默认 npm cache 存在权限异常；安装器使用本任务专属临时 cache，不修改用户全局 npm 目录。
- 上游 `.agents/skills/<name>` 相对链接只供上游仓库发现源码，不属于 Easydict 消费方安装内容。
- 不机械复制上游宿主文档；Easydict 的授权、history、Issue `forbid`、Xcode 验证和保护路径继续
  由本仓库规则负责。
- 减少重复输出和模型往返不能削弱逐命令权限、退出状态、远程最终刷新或漂移保护。

## 进度

- [x] 完成独立 planner 评估并核验关键事实。
- [x] 完成 Mutation Gate、远程 tag、安装器版本和初始保护状态核验。
- [x] 同步 v0.3.4 受管资产。
- [x] 更新项目 Agent 规则和来源参考。
- [x] 完成验证与独立复核。
- [x] 归档计划、完善 history 并进入本地提交交付。

## 验证

- 固定 `v0.3.4` checkout 的 HEAD 为 `e79154ef1fc076c8c7b6b6a06b46388596d485d2`；六个
  受管 Skill 目录与对应 tracked tree 完全一致，且没有上游仓库自用发现链接。
- 三个 agent TOML 与上游一致，SHA-256 与 agents lock 匹配；双 lock 的 tag、revision、JSON
  和 TOML 解析通过。
- Python 3.12 运行 `git-commit` 19、`review-pr` 35、`submit-pr` 32、
  `worktree-rebase-merge` 9 项测试，Node.js 运行 agent installer 6 项测试，共 101 项通过。
- 变更 Python 文件 compileall、28 个现行规则相对链接和锚点、保护路径比较及
  `git diff --check` 通过。
- 独立 tester 验证通过；独立 reviewer 完整复核未发现 finding。
- 未运行 `xcodebuild`：本次只修改受管 Skill、双 lock 和治理文档，不涉及产品或 Xcode 内容。
- 未在全新任务中验证 custom agent 运行时发现；静态快照和配置检查不替代该 smoke test。

## 完成条件

- 受管快照和双 lock 与 `v0.3.4` 契约一致，且没有混入上游仓库自用发现链接。
- 项目现行规则和来源参考不存在旧版本、旧角色或失效命令。
- 相关测试、JSON/TOML、Python、文档链接、保护路径和 `git diff --check` 通过。
- 最终实现快照完成 tester 验证和独立 reviewer 复核。
- 计划移入 `completed/`，history 记录实际结果，并满足未 push 本地提交的交付条件。
