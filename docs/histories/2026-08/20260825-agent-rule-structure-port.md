# Agent 规则职责拆分与 planning 边界

## 变更

- 完整移植 Scoco 提交 `1a933fff9`、`8ac8d066c` 和 `bf029bd1f` 的 Agent 规则语义。
- 将请求边界、执行安全、Git 工作流、文档治理和回复表达拆分到
  `docs/agents/` 的独立文档，并更新 `AGENTS.md`、目录 README 和规则入口。
- 明确 planning 的只读语义、Mutation Gate、active/completed 计划生命周期，以及
  Easydict 的 `submit-pr`、PR review、Planning 子代理和 Xcode 文档边界。
- 为 `docs/exec-plans/templates.md` 增加请求语义和计划生命周期回归案例。

## 范围

本次只修改 Agent 规则、执行计划模板、完成计划和 history；没有修改产品代码、测试、
Xcode 工程、运行时资源或外部服务。

## 验证

- `git diff --check` 通过。
- 完成文档尾随空白、相对链接目标、入口路由和关键语义静态检查。
- 未运行 `xcodebuild`；本次变更不涉及源码或 Xcode 工程。
