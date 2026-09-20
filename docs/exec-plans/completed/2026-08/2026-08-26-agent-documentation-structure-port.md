# Agent 文档入口与治理结构移植

**Status:** completed
**Created:** 2026-08-26
**Updated:** 2026-08-26
**Owner:** Codex
**Links:** Scoco commits `85d67f2da`, `8d46489f5`, `7ef43b892`, `927793cc9`, `fb57ab64e`

## 任务契约

- 任务模式：`implementation`
- 用户目标：将 Scoco 最近五个 Agent 文档治理提交按 Easydict 架构移植到当前项目。
- 允许动作：更新 Agent 入口、职责文档、planner 配置、计划/history/设计/参考文档，并执行文档级验证和一次合规的本地提交。
- 允许修改路径：`AGENTS.md`、`.codex/agents/planner.toml`、`docs/agents/`、`docs/design-docs/`、`docs/references/`、`docs/exec-plans/`、`docs/histories/`。
- 禁止动作：不直接 cherry-pick；不修改产品源码、测试、Xcode 工程、运行时资源、发布流程或外部服务；不 push、pull、rebase 或 merge。
- 预期交付物：唯一入口路由、职责清晰的 Agent 规则、Easydict 专属结构设计与参考记录、同任务 plan/history。
- 验收标准：五个源提交的 Agent 治理语义被保留，Scoco 专属规则未混入，活跃链接和结构检查通过。

## 自动提交状态

- 自动提交资格：`eligible`
- 初始暂存区：`empty`
- 自动提交结果：最终验证通过后按 `git-commit` skill 执行本地提交；不推送。

## 输入来源

- 用户明确请求：参考 Scoco 最近几个 Agent 提交并移植，先给出计划后执行。
- 仓库规则：`AGENTS.md`、`docs/agents/repository-guide.md`、`docs/agents/README.md`、`docs/agents/skills.md`。
- 引用提交：`85d67f2da`、`8d46489f5`、`7ef43b892`、`927793cc9`、`fb57ab64e`。
- 仅作为证据的内容：Scoco 五提交的 diff、Scoco 最终 Agent 文档结构和当前 Easydict checkout。

## 目标

- 让根 `AGENTS.md` 成为唯一任务入口，消除 `repository-guide.md` 的二次路由。
- 将文档生命周期归入 `docs/agents/README.md`，消除独立 `documentation-governance.md` 的职责重复。
- 保留 Easydict 的 PR review、`submit-pr`、`release-easydict`、Planning 子代理、Swift/Xcode 和本地化规则。
- 明确所有产生仓库文件差异的 implementation 都要有同任务 history，并同步计划、设计和参考层。

## 范围

- 包含范围：Agent 入口与职责路由、请求边界、执行安全、Git 交付、计划/history 治理、Agent 文档结构设计和 Scoco 来源参考。
- 不包含范围：Scoco 的产品、发布、R2/OCU、boss-resume、外部项目文档、贡献者文档和历史执行事实；Easydict 产品代码及 Xcode 工程。

## 实施结果

- [x] 将 `AGENTS.md` 收敛为唯一入口，并保留 Easydict 专属 PR review、PR 参数和产品边界。
- [x] 将文档治理、请求边界、执行安全和 Git 交付规则拆分到对应职责文档。
- [x] 同步 `.codex/agents/planner.toml`、exec-plan 模板、history README 和设计/参考层。
- [x] 删除重复的 `repository-guide.md` 与 `documentation-governance.md`，并核对活跃引用。
- [x] 创建同任务 history，未修改产品代码、测试、Xcode 工程或运行时资源。

## 风险与决策

- 删除二次入口前先迁移其独有规则，并检查活跃文件引用；历史记录中的旧路径只作为迁移证据保留。
- 保留 Easydict 的 PR review、PR 参数、自动提交、精确暂存和 Xcode 边界，未引入 Scoco 专属发布或外部项目规则。
- 采用 `85d67f2da^..fb57ab64e` 的完整五提交语义范围，不直接 cherry-pick。
- 不复制 Scoco completed plans、histories、release/contributor 文档或产品专属参考；只创建 Easydict 本地计划、history、design doc 和来源参考。

## 验证

- [x] `git diff --check`。
- [x] 使用 Python `tomllib` 解析 `.codex/agents/planner.toml`。
- [x] 检查活跃 Markdown 相对链接、活跃规则中的已删除路径和源项目专属规则泄漏。
- [x] 静态确认 planning、implementation、Mutation Gate、history 门禁、精确暂存、禁止默认 `push/pull/rebase/merge`，以及 Easydict 的 `submit-pr`、`release-easydict`、PR review、workspace/test/localization 路径仍可追踪。
- [x] 检查新增 Markdown 无尾随空白。
- 未运行：`xcodebuild`，因为本次只修改 Agent 治理文档和配置。

## 完成记录

- 2026-08-26：完成五个 Scoco 提交的 Easydict 语义移植、静态验证和计划归档；本地 Git 提交在最终 staged patch 复核通过后执行，不推送。
