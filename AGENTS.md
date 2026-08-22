# AGENTS.md

Easydict 是一款 macOS 词典和翻译应用，支持查词、文本翻译、划词翻译和
OCR 截图翻译。

`AGENTS.md` 是 Agent 的入口文件，而不是完整的仓库规则手册。长期维护的规则位于
`docs/agents/`。

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
- 创建 Git 任务分支：`.agents/skills/git-commit/SKILL.md` 中的
  `Branch Name Guidance`。

## Code Review Rules

### PR review

- 以 `.agents/skills/review-pr/SKILL.md` 为本仓库 PR review 完整流程的规范来源；Review 必须核对 GitHub PR 的准确 `headRefOid`，以真实 base diff 为准，并检查关联 issue、实际代码、相关上下文和 CI 状态，不能只依据 PR 描述或绿色检查。
- 将所有 `isResolved == false` 的 inline review thread 逐条评估，包括 outdated thread、bot comment 和 replies。每个 open comment 的问题、证据、判断和 `Suggested Fix` 只放在 `Open Review Comments`；`Findings` 只记录具有独立触发条件、风险和修复方案的额外问题，禁止重复。
- 在最终输出前刷新 PR head、状态、checks 和完整分页的 review threads；若 head、评论、reply 或 thread 状态变化，先重新检查受影响代码。Review 默认不运行 `xcodebuild`，除非用户明确要求；保留现有工作树和分支，不 push 或修改 PR，除非用户明确授权。

## 必须遵守的约束

- 语言规则：回复以及新建或修改的仓库文档默认使用用户当前请求的语言；如果当前
  请求使用英文，则使用英文，否则遵循请求中已经使用的语言。代码标识、API 名称、
  命令、路径和品牌名称等技术专有内容保留原文。
- 保留工作树中与当前任务无关的已暂存和未暂存变更。
- Git 操作遵循 `docs/agents/repository-guide.md` 的 Git 安全和自动本地提交规则：
  `planning`/`protected` 不暂存或提交；符合条件的 `implementation` 在验证通过后
  自动提交 Agent 明确修改的路径；`delivery` 使用 `git-commit` skill；除非用户
  明确要求，否则不 push。
- 仓库治理 Markdown、计划、历史、参考资料和 skill 不需要 Xcode 工程引用或
  build phase 条目。
- 文档中使用相对仓库路径，并保持行为、测试和相关文档同步。
