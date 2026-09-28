# 新增 submit-pr 技能

**Status:** completed
**Created:** 2026-08-23
**Updated:** 2026-08-23
**Owner:** Easydict maintainers
**Links:** `../../../.agents/skills/submit-pr/`、`../../../.github/pull_request_template.md`

## 任务契约

- 任务模式：`implementation`
- 用户目标：新增一个结合仓库 PR 模板的 `submit-pr` skill，安全准备任务分支、生成 PR 内容、推送并创建或复用 GitHub PR。
- 允许动作：新增 skill、helper、测试、Agent 路由、计划和历史文档；运行隔离验证；按仓库规则自动本地提交。
- 允许修改路径：`.agents/skills/submit-pr/`、`AGENTS.md`、`docs/agents/skills.md`、本计划及对应历史文档。
- 预期交付物：支持 `plan`、默认创建和 `draft` 的本地 skill，确定性 helper、隔离测试和同步文档。
- 验收标准：不会自动暂存未暂存文件或推送 `origin/dev`；正文复用现有 PR 模板；关联 Issue 不产生自动关闭；UI 修改不因缺少截图中断；重复执行不会创建重复 PR；全部本地验证通过。

## 自动提交状态

- 自动提交资格：`eligible`
- 初始暂存区：`empty`
- 自动提交结果：`committed`

## 输入来源

- 用户明确请求：执行已确认方案，并将 UI 截图处理改为创建 PR 后提示用户在 GitHub 页面补充，不生成截图或中断流程。
- 仓库规则：`AGENTS.md`、`docs/agents/repository-guide.md`、`docs/agents/skills.md`。
- 附件或引用材料：无。
- 仅作为证据的内容：现有 PR 模板、`git-commit`、`review-pr`、`worktree-rebase-merge` 和本机 `gh pr create` 行为。

## 目标

让 Agent 能从当前已提交工作创建结构稳定、引用安全、可重复执行的 Easydict PR，同时保持本地 checkout、远程 `dev` 和用户未暂存内容不受影响。

## 范围

- 包含范围：PR 计划预览、任务分支选择、显式 push、模板渲染、PR 创建、幂等检测、创建后验证和失败恢复。
- 不包含范围：自动 merge/rebase/force push、修改已有 PR、PR review、Issue 关闭、截图生成或真实 GitHub 集成测试。

## 背景

- 当前行为：仓库已有 PR 模板和 PR review skill，但没有负责安全创建 PR 的本地 skill。
- 相关文件：`.github/pull_request_template.md`、`.agents/skills/git-commit/SKILL.md`、`.agents/skills/review-pr/SKILL.md`。
- 约束：默认 base 为 `dev`；当前在 `dev` 时必须将 HEAD 暴露为独立任务分支，而不能直接 push `origin/dev`。

## 风险与缓解

- 风险：隐式 push 到错误 remote 或受保护分支。
  - 缓解措施：固定 `origin` 与 `tisfeng/Easydict`，显式传递 push refspec、base 和 head。
- 风险：重复运行创建多个 PR 或覆盖用户维护的 PR 正文。
  - 缓解措施：创建前按 exact head/base 查询开放 PR；存在时只验证和复用，内容不一致则停止。
- 风险：PR 正文触发 GitHub 自动关闭 Issue。
  - 缓解措施：渲染前拒绝 closing keyword，创建后要求 `closingIssuesReferences` 为空。
- 风险：测试误触真实 GitHub。
  - 缓解措施：使用临时 bare remote 和 fake `gh`，禁止在线创建测试 PR。

## 里程碑

- [x] 确认范围和约束。
- [x] 实现 skill、helper 和工作流契约。
- [x] 完成隔离测试和前向验证。
- [x] 同步 Agent 文档和历史记录。
- [x] 将本计划移到 `completed/`。

## 验证

- 命令：Python 单元测试与编译、skill `quick_validate.py`、`git diff --check`。
- 手动检查：确认 UI 变更缺少截图时仍可创建 PR，并在结果中提示 GitHub 页面补充截图。
- 观察结果：15 个隔离单元与集成测试通过；Python 编译、skill 结构和
  `git diff --check` 通过；真实 checkout 的 `plan` 前向检查未改变 refs、索引、工作树
  或 `.tmp/submit-pr/`。

## 决策记录

- 2026-08-23：skill 命名为 `submit-pr`，与 `git-commit` 和 `review-pr` 保持职责分离。
- 2026-08-23：第一版只创建或复用 PR，不自动更新已有 PR。
- 2026-08-23：截图不是创建门槛；UI 修改只在正文和最终结果中提示后续补充。
- 2026-08-23：push 使用计划冻结的完整 SHA；生成正文和完整 commit message 都不能
  包含 GitHub 自动关闭 Issue 语法。

## 进度记录

- 2026-08-23：完成现状检查和 skill 初始化，开始实现确定性 helper。
- 2026-08-23：完成 helper、模板、幂等、分叉、Draft、截图和错误 remote 隔离测试。
- 2026-08-23：独立前向测试确认 plan 零写入，并据此补齐完整 commit message、冻结
  SHA 和同仓库 PR 身份验证。
- 2026-08-23：完成全部验证、Agent 路由和历史记录。
