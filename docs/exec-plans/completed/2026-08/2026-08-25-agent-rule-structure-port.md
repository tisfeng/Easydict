# Agent 规则职责拆分与 planning 边界移植

**Status:** completed
**Created:** 2026-08-25
**Updated:** 2026-08-25
**Owner:** Codex
**Links:** Scoco commits `1a933fff9`, `8ac8d066c`, `bf029bd1f`

## 任务契约

- 任务模式：`implementation`
- 用户目标：将三个 Scoco Agent 规则提交完整适配到 Easydict。
- 允许动作：拆分 Agent 规则文档、更新入口和计划模板、补充本地计划与历史、验证并执行一次自动本地提交。
- 允许修改路径：`AGENTS.md`、`docs/agents/`、`docs/exec-plans/templates.md`、本计划及对应完成历史。
- 预期交付物：职责清晰的 Agent 文档、完整的 planning 只读边界、更新后的入口路由和验证记录。
- 验收标准：三个提交的语义均被保留，Easydict 专属规则不丢失，文档链接和格式检查通过。

## 自动提交状态

- 自动提交资格：`eligible`
- 初始暂存区：`empty`
- 自动提交结果：`committed`

## 输入来源

- 用户明确请求：包含 `1a933fff9`、`8ac8d066c` 和 `bf029bd1f` 三个提交的移植。
- 仓库规则：`AGENTS.md`、`docs/agents/repository-guide.md`、`docs/agents/skills.md`。
- 附件或引用材料：无。
- 仅作为证据的内容：Scoco 三个提交的实际 diff 和当前 Easydict Agent 文档结构。

## 目标

- 将请求边界、执行安全、Git 工作流、文档治理和回复表达拆分到独立文档。
- 让 `repository-guide.md` 只承担仓库定位、规则入口和路由职责。
- 明确 planning、implementation、delivery 和 protected 的边界。
- 让 planning 完全只读，只有获准 implementation 后才创建 active 计划。
- 保留 Easydict 当前的 PR review、Planning 子代理、`submit-pr`、Git 和 Xcode 规则。

## 范围

- 包含范围：三个源提交中的 Agent 文档职责拆分、planning 边界、只读语义和计划模板案例。
- 不包含范围：产品源码、测试、Xcode 工程、运行时资源、外部服务和源仓库特定项目文档内容。

## 背景

- 当前 `repository-guide.md` 集中承载请求解析、执行安全、Git 交付和文档治理。
- 当前目标仓库尚未建立源提交中的五个职责文档。
- 当前入口还需要保留 Easydict 后续增加的 PR review、Planning 子代理和发布/PR 规则。

## 风险与缓解

- 风险：机械复制 Scoco 文件会覆盖 Easydict 专属规则。
  - 缓解措施：按职责迁移语义，逐项保留目标仓库的 PR、Git、skill 和 Xcode 条款。
- 风险：planning 的任务模式和计划文件生命周期出现矛盾。
  - 缓解措施：同步检查请求边界、执行安全、文档治理、任务工作流和模板。
- 风险：新增文档的相对链接或路由不完整。
  - 缓解措施：执行本地链接、路由、职责唯一归属和绝对路径检查。

## 里程碑

- [x] 确认三提交范围、目标结构和初始 Git 状态。
- [x] 创建职责文档并迁移规则。
- [x] 更新入口、计划模板和交叉引用。
- [x] 验证行为和文档。
- [x] 将本计划移到 `completed/` 并记录 history。

## 验证

- 命令：`git diff --check`、目标文档尾随空白检查和 Markdown 链接目标检查通过。
- 手动检查：包装元数据边界、planning 的只读语义、Mutation Gate、计划生命周期以及 Easydict 专属 PR、skill、Xcode 规则均保留。
- 观察结果：仅修改 Agent 规则、计划模板、完成计划和 history；未运行 `xcodebuild`，因为本任务不涉及源码或 Xcode 工程。

## 决策记录

- 2026-08-25：按用户确认完整包含 `1a933fff9`、`8ac8d066c` 和 `bf029bd1f`，不再采用仅移植后两个提交的范围。
- 2026-08-25：采用职责拆分语义适配，不直接复制 Scoco 的完成计划和历史事实。
- 2026-08-25：保留 Easydict 的 PR review、Planning 子代理、submit-pr 参数和 Xcode 工程边界，并将详细规则分别归档到职责文档。

## 进度记录

- 2026-08-25：完成三提交范围核验和 Mutation Gate，创建并完成五个职责文档、入口路由和模板语义回归案例。
- 2026-08-25：完成本地静态验证，归档计划并记录 history，准备执行一次精确路径自动本地提交。
