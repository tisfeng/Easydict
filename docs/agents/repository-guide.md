# 仓库指南

## 目的

Easydict 是一款 macOS 词典和翻译应用，支持查词、文本翻译、划词翻译和 OCR 截图
翻译。仓库知识应通过文件版本化，确保人类和 Agent 能够复现相关推理过程。

本文件是仓库协作规则的方向页，不重复请求解析、工作树安全、Git 交付、文档治理或
回复表达的详细条款。每项规则由一个职责文档维护，避免同一规则在多个入口漂移。

## 通用原则

- 如果工作需要使用 OpenAI API、ChatGPT Apps SDK、Codex 或相关 OpenAI 开发工具，
  使用 OpenAI 开发者文档 MCP server。
- 在进行非简单工作前，先说明假设和成功标准。
- 优先采用能够满足需求的最小方案。
- 保持修改精准，并在交付前完成验证。
- 将反复出现的 Agent 失败转化为文档、工具或环境改进，而不是不断扩展提示词。

## 规则入口

### 任务语义和执行安全

- [`request-boundary.md`](request-boundary.md)：用户消息、附件和引用的边界，请求
  语义优先级，以及 `planning`、`implementation`、`delivery`、`protected` 模式。
- [`execution-safety.md`](execution-safety.md)：任务契约、Mutation Gate、保护状态和
  最小修改顺序。

### Git 和交付

- [`git-workflow.md`](git-workflow.md)：保留用户现场、自动本地提交、分支、推送和
  Easydict PR 参数。
- [`../../.agents/skills/git-commit/SKILL.md`](../../.agents/skills/git-commit/SKILL.md)：Angular-style 提交、暂存范围、提交信息校验
  和提交后统计。
- [`../../.agents/skills/submit-pr/SKILL.md`](../../.agents/skills/submit-pr/SKILL.md)：创建或恢复 GitHub PR。
- [`../../.agents/skills/review-pr/SKILL.md`](../../.agents/skills/review-pr/SKILL.md)：PR review 的完整流程。

### 文档和回复

- [`documentation-governance.md`](documentation-governance.md)：内部规则、计划、历史
  和公开文档的职责与生命周期。
- [`response-conventions.md`](response-conventions.md)：回复语言、结果顺序和已验证
  状态的表达。
- [`../exec-plans/`](../exec-plans/)：多步骤、跨模块或高风险工作的计划。
- [`../histories/`](../histories/)：已完成实质性变更的简洁记录。

## 按任务路由

- 构建或测试：[`build-and-test.md`](build-and-test.md) 和 [`testing.md`](testing.md)。
- 代码组织：[`code-quality.md`](code-quality.md)。
- Swift、Objective-C、SwiftUI 或 Xcode：[`swift-xcode.md`](swift-xcode.md)。
- 用户可见文本或 String Catalog：[`localization.md`](localization.md)。
- Skill 或 Agent 集成：[`skills.md`](skills.md)、目标
  `../../.agents/skills/<skill>/SKILL.md` 以及对应的 `../../.agents/overrides/<skill>/<overlay>.md`。
- 修改产品代码或模块边界：[`../architecture/overview.md`](../architecture/overview.md)。
- 公共使用或贡献者文档：[`../user-docs/en/`](../user-docs/en/) 或
  [`../user-docs/zh/`](../user-docs/zh/)。
- 创建 Git 任务分支：git-commit skill 中的 `Branch Name Guidance`。

## 工作流提醒

1. 阅读本文件和 `README.md`，再按任务路由读取最小必要规则。
2. 根据最新用户请求判定任务模式；写入前完成任务契约和 Mutation Gate。
3. 只修改获准路径，并运行与风险相称的验证。
4. 依据 Git、文档生命周期和回复表达规则交付真实结果。

如果规则之间出现冲突，遵循系统和开发者规则、用户最新明确请求、仓库入口和当前
选定 skill 的优先级，并在计划或最终报告中说明影响。
