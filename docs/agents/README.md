# Agent 文档

本目录存放面向编码 Agent 的长期仓库知识。根目录的 `AGENTS.md` 只是入口文件；
请根据当前任务阅读最小必要的文档集合。

## 始终阅读

- `repository-guide.md`：仓库定位、规则入口和默认工作流路由。
- `request-boundary.md`：请求来源、只读语义和任务模式判定。
- `execution-safety.md`：任务契约、工作树写入和 Mutation Gate。
- `git-workflow.md`：Git 安全、本地提交和 Easydict PR 交付。
- `documentation-governance.md`：文档职责、计划生命周期和历史归档。
- `response-conventions.md`：回复语言、验证状态和交付结果表达。

## 按任务阅读

- `build-and-test.md`：Xcode 构建和测试触发条件、命令与验证方式。
- `code-quality.md`：与语言无关的源码组织和文档规则。
- `swift-xcode.md`：Swift、SwiftUI、Xcode 元数据和库使用约定。
- `localization.md`：String Catalog 和用户可见文本的本地化规则。
- `testing.md`：测试范围、职责划分和行为测试要求。
- `skills.md`：本地 skill、overlay 和外部 Agent 入口。
- `../architecture/overview.md`：修改产品代码或跨功能行为时参考当前模块和运行时边界。

## Git 交付路由

- 任务模式和写入授权遵循 `request-boundary.md` 与 `execution-safety.md`。
- `planning`：默认只读，不暂存、不提交、不推送，也不创建 active 计划。
- `implementation`：完成验证后，若满足 `git-workflow.md` 的自动本地提交条件，
  只提交 Agent 明确修改的路径。
- `delivery`：用户明确要求提交或调用 `/git commit` 时，使用
  `.agents/skills/git-commit/SKILL.md`。
- `protected`：初始索引非空、路径无法分离、存在冲突或验证失败时，保留现场，等待
  用户处理；任何模式都不会自动 push。

## 文档职责

- `repository-guide.md` 只负责仓库定位、阅读入口和规则路由。
- 详细规则只在对应职责文档中维护；入口和模板通过相对链接引用它们。
- 多步骤实现通过 `docs/exec-plans/` 记录；完成后同步 `docs/histories/`，遵循
  `documentation-governance.md`。
