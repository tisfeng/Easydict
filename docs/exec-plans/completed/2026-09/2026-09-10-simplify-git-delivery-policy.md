# 精简 Git 交付策略

- 状态：completed
- 创建日期：2026-09-10
- 负责人：Codex
- 关联 Issue/PR：none

## 背景

`git-workflow.md` 与受管 `git-commit` Skill、git-delivery TOML 重复描述暂存、提交、预览和
回执算法，并将自动交付的完整 Agent-owned 路径要求错误套用到显式提交。

## 任务摘要

- 意图模式：implementation
- 交付授权：auto-local-commit
- 安全状态：normal
- 目标结果：收敛为 Easydict 项目交付策略，消除执行算法重复并修复显式提交范围冲突。
- 允许修改路径：`docs/agents/git-workflow.md`、本任务 plan/history。
- 同任务 history：`docs/histories/2026-09/2026-09-10-simplify-git-delivery-policy.md`
- 禁止动作：不修改受管 Skill、agent TOML、lock、产品代码、其他 worktree 或远程状态。
- 验收标准：自动与显式交付边界明确；强制 git-delivery、严格回退与 PR 参数保留；最终差异经
  reviewer 复核。

## 写入前状态

- 写入前检查：pass
- 自动提交资格及原因：eligible；源工作树初始索引、工作树与未跟踪文件为空，任务路径可独立识别。
- 初始 HEAD：`404e81d1f08ddb8739edf7b6d7dbe3dbbda44a49`
- 初始 staged 路径：none
- 初始 unstaged 路径：none
- 初始 untracked 路径：none
- 初始冲突：none
- Agent-owned paths：允许路径及本任务 plan/history。

## 工作计划

1. 以受管 Skill/TOML 为执行权威，重写项目 Git 交付策略。
2. 仅为 `auto-local-commit` 保留全部 Agent-owned 路径完备性要求，恢复显式提交的 Skill 决策。
3. 验证链接、边界和场景等价，委派 reviewer 复核，归档 plan 并记录 history。

## 风险与决策

- 过度删减会丢失项目的强制 git-delivery 路由、严格回退或 PR 参数；这些条款保留。
- 受管资产由 lock 管理，本任务只链接，不复制或修改。
- 不创建新分支、集成或 push；本任务的自动本地提交只作用于当前源分支。

## 进度

- [x] 完成重复、冲突和受管资产边界审查。
- [x] 完成项目策略重写。
- [x] 完成静态验证与 reviewer 复核。
- [x] 归档计划并完成 history。

## 验证

- 通过：现行链接、中文锚点、旧执行算法残留和受管路径检查。
- 通过：自动交付、禁止提交、已有索引、显式路径、显式工作树、已有提交 integration 六种场景核对。
- 通过：`git diff --check` 与独立 reviewer 复核；reviewer 未发现需要修复的问题。
- 不运行 `xcodebuild`，因为本次仅修改治理 Markdown。

## 完成条件

- 项目策略与受管执行契约不重复，显式提交不再被自动交付完备性要求阻断。
- 所有链接有效，受管资产无改动，静态检查与 reviewer 复核通过。
