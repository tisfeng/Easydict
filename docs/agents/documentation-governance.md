# Agent 文档治理

本文定义 Agent 规则、计划、历史和公开文档的职责边界，以及多步骤任务的文档生命
周期。入口路由见 [`README.md`](README.md)，执行安全见
[`execution-safety.md`](execution-safety.md)。

## 文档层级

- `AGENTS.md`：仓库级入口，只保留产品定位、强制要求和规则路由。
- `docs/agents/`：内部 Agent 和贡献者工作流知识；每个主题由一个职责文档负责。
- `docs/architecture/`：当前产品模块、边界和运行时架构。
- `docs/design-docs/`：设计方案和长期技术决策。
- `docs/user-docs/`：面向用户的英文和中文公开文档。
- `docs/exec-plans/active/`：已获 implementation 授权且正在执行的多步骤计划。
- `docs/exec-plans/completed/`：已完成计划的归档。
- `docs/histories/`：已经完成的实质性变更记录，不重复完整对话。

文档使用相对仓库路径，不提交机器本地绝对路径。Agent 规则、计划、历史、参考资料
和 `docs/` 下的公共 Markdown 不需要 Xcode 工程引用或 build phase 条目，除非它们
明确作为运行时资源发布。

## 计划生命周期

1. `planning`：只读调查和回复方案；不创建或更新 active 计划，也不写入其他 artifact。
2. `implementation`：通过 Mutation Gate 后，针对多步骤、跨模块或高风险工作创建
   `docs/exec-plans/active/` 计划，并记录任务契约、范围、风险、里程碑和验证。
3. 验证和交付：在计划中更新实际结果、决策和未验证边界；不把失败检查写成成功。
4. 完成：将计划移到 `docs/exec-plans/completed/`，状态改为 `completed`，并在
   `docs/histories/YYYY-MM/` 添加简洁历史记录。

计划只记录当前任务需要的决策和证据，不复制完整聊天、无关源仓库历史或机器路径。
历史应说明变更目的、主要范围、验证结果和已知限制。

## 单一职责与同步

- 入口文件负责路由，不复制详细规则。
- 请求语义、执行安全、Git 交付和回复表达分别由对应的 `docs/agents/` 文档负责。
- 规则发生变化时，同一任务同步更新入口、交叉引用和受影响模板。
- 文档之间出现冲突时，使用 `AGENTS.md`、仓库规则和用户最新请求的优先级，并在
  计划决策记录中说明取舍。
