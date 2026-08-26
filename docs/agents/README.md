# Agent 文档与文档治理

本目录存放面向编码 Agent 的长期仓库规则。根目录 [`AGENTS.md`](../../AGENTS.md) 是唯一
入口和任务路由；本文件只说明文档边界与生命周期，不维护第二份规则索引。

## 文档分层

- `docs/agents/` 存放内部 Agent 和贡献者工作流知识。
- `docs/architecture/` 记录当前实现边界和流程。
- `docs/design-docs/` 记录需要长期维护的重要设计决策。
- `docs/user-docs/` 存放公开的英文和中文文档。
- `docs/exec-plans/` 存放多步骤工作计划。
- `docs/histories/` 记录每个最终产生仓库文件差异的 `implementation` 任务。
- `docs/references/` 存放反复使用的精选外部或跨仓库参考。

## 计划与历史

- planning 阶段的多步骤方案只作为当前回复中的规划内容，不创建或更新
  `docs/exec-plans/active/` 下的文件。
- 用户明确批准 implementation 且变更门禁通过后，对于架构、协议、迁移、多步骤、跨模块
  或高风险工作，在 `docs/exec-plans/active/` 下创建执行计划。
- 任何 `implementation` 只要最终产生仓库文件差异，就必须在同一任务中创建或更新一条
  `docs/histories/` 记录；文件类型、数量、变更规模以及是否创建执行计划都不影响该要求。
- 同一任务分多轮实施时复用同一条 history；仅修改 history 的任务由该记录描述自身，
  不递归创建第二条；最终没有仓库文件差异的任务不创建空记录。
- 存在执行计划时，完成后将计划移动到 `docs/exec-plans/completed/`，并由同任务 history
  链接该 completed 计划。
- 交付时必须将同任务 history 与其他任务变更一起验证和精确暂存；允许自动本地提交时，
  它们进入同一个提交。明确禁止提交或进入 `protected` 时保留全部变更，不强行提交。
- 计划记录目标、授权、范围、限制、初始 Git 快照、Agent-owned paths、工作计划、风险、
  验证和完成条件；不要把完整对话复制进历史。
- 使用仓库现有的 GitHub issue 和 pull request 进行讨论；不要在历史文件中重复完整
  对话内容。

## 维护原则

- 仓库文档使用相对路径，不要提交机器本地绝对路径。行为发生变化时，在同一任务中同步
  更新代码、测试和受影响的文档。
- 每份详细规则只维护一个主要职责；需要引用其他职责时使用链接，不复制完整条款。新增或
  删除规则文件时只更新根 `AGENTS.md` 的路由。
- 仓库治理 Markdown、计划、历史、参考资料、skill 以及 `docs/` 下的公共 Markdown 不需要
  Xcode 工程引用或 build phase 条目；详细边界见 `swift-xcode.md`。
- 应用内置 Agent 文档、运行时资源和后端契约镜像遵循 `skills.md` 中的权威来源，不因普通
  文档整理而移动或改写。
