# Agent 文档入口与治理结构移植

## 变更

- 参考 Scoco `85d67f2da`、`8d46489f5`、`7ef43b892`、`927793cc9` 和 `fb57ab64e`，将
  Agent 文档入口、职责分层、变更门禁、Git 交付和计划/history 生命周期适配到 Easydict。
- 让 `AGENTS.md` 成为唯一任务入口，将文档治理归入 `docs/agents/README.md`，并移除重复的
  `repository-guide.md` 和 `documentation-governance.md` 路由。
- 同步 planner 配置、计划模板、history 规则、Agent 文档结构设计和来源参考。
- 保留 Easydict 的 PR review、`submit-pr`、`release-easydict`、Planning 子代理、Swift/Xcode
  和本地化规则，不引入 Scoco 的发布、R2/OCU、boss-resume 或产品专属内容。

## 计划

本任务执行计划：[`2026-08-26-agent-documentation-structure-port.md`](../../exec-plans/completed/2026-08-26-agent-documentation-structure-port.md)。

## 范围

本次只修改 Agent 规则、planner 配置、设计与参考文档、执行计划和 history；没有修改产品代码、
测试、Xcode 工程、运行时资源或外部服务。

## 验证

- `git diff --check`。
- 解析 `.codex/agents/planner.toml`，检查活跃 Markdown 相对链接和标题锚点。
- 静态确认任务模式、Mutation Gate、history 门禁、精确暂存和禁止默认远程操作规则完整。
- 未运行 `xcodebuild`；本次变更不涉及源码或 Xcode 工程。
