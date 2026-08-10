# AGENTS.md

Easydict 是一款 macOS 词典和翻译应用，支持查词、文本翻译、划词翻译和
OCR 截图翻译。

`AGENTS.md` 是 Agent 的入口文件，而不是完整的仓库规则手册。长期维护的规则位于
`docs/agents/`；公开的英文和中文文档位于 `docs/user-docs/`。

## 开始阅读

- 每个任务都要阅读 `docs/agents/repository-guide.md`。
- 阅读 `docs/agents/README.md`，根据任务路由到对应规则。
- 修改产品代码或模块边界时，阅读 `docs/architecture/overview.md`。

## 按任务路由

- 构建或测试：`docs/agents/build-and-test.md` 和
  `docs/agents/testing.md`。
- Swift、Objective-C、SwiftUI 或 Xcode：`docs/agents/swift-xcode.md`。
- 用户可见文本或 String Catalog：`docs/agents/localization.md`。
- Skill 或 Agent 集成：`docs/agents/skills.md`、目标
  `.agents/skills/<skill>/SKILL.md` 以及对应的
  `.agents/overrides/<skill>/<overlay>.md`。
- 多步骤、跨模块或高风险工作：`docs/exec-plans/`。
- 已完成的实质性变更：`docs/histories/`。
- 公共使用或贡献者文档：`docs/user-docs/en/` 或
  `docs/user-docs/zh/`。

## 必须遵守的约束

- 保留工作树中与当前任务无关的已暂存和未暂存变更。
- 除非任务或明确调用的工作流授权，否则不要暂存、提交或推送。
- 仓库治理 Markdown、计划、历史、参考资料和 skill 不需要 Xcode 工程引用或
  build phase 条目。
- 文档中使用相对仓库路径，并保持行为、测试和相关文档同步。
