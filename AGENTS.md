# AGENTS.md

Easydict 是一款 macOS 词典和翻译应用，支持查词、文本翻译、划词翻译和 OCR
截图翻译。

`AGENTS.md` 维护 Agent 的通用约束和唯一任务路由。现行详细规则位于 `docs/agents/`，每项
规则只维护一个权威来源。

## 始终阅读

- 每个任务先阅读 `docs/agents/request-boundary.md`，确定请求语义、写入授权、任务模式、
  写入前检查（Mutation Gate），以及是否需要按其 `Planner 委派决策` 使用子代理。
- 回复以及新建或修改的仓库文档使用用户当前请求的语言；代码标识、API 名称、命令、
  路径、品牌名称和固定输出契约保留原文。
- 再按当前任务读取下方最小必要规则，不通过其他 README 或索引进行二次路由。

## 任务路由

- Git 状态保护、暂存、本地提交、worktree 集成和 Easydict PR 参数：
  `docs/agents/git-workflow.md`。
- 构建、测试、tester、工程文件与资源、Xcode 验证：`docs/agents/build-and-test.md`。
- 跨语言代码质量、Swift、Objective-C、SwiftUI、API 和本地化：
  `docs/agents/coding-guidelines.md`。
- 实质审查、独立 reviewer、审查快照与复审：`docs/agents/review.md`。
- 文档分层、计划、history、参考资料、外部 Skills、Codex 子代理、双 lock 和同步边界：
  `docs/agents/README.md`。
- 产品代码、跨功能行为或模块边界：`docs/design-docs/application-architecture.md`。
- 公共使用或贡献者文档：`docs/user-docs/en/` 或 `docs/user-docs/zh/`。
- 具体 Skill：执行前读取 `.agents/skills/<skill>/SKILL.md`。
- 发布：`.agents/skills/release-easydict/SKILL.md`。
- 创建 GitHub PR：`.agents/skills/submit-pr/SKILL.md`，并读取
  `docs/agents/git-workflow.md` 中的 Easydict 参数。
- OpenAI API、ChatGPT Apps SDK、Codex 或相关开发工具：优先使用 OpenAI 开发者文档
  MCP server；不可用时访问官方文档网页，并说明实际来源。
- 应用内置 Agent 文档、运行时资源或后端契约：读取其自身权威来源及
  `docs/agents/README.md` 中的边界。

## Review 路由

- 本地 review 与 GitHub PR review 先读取 `docs/agents/review.md`；具体审查分别按以下 Skill
  执行。
- 本地任务、工作树、提交/range、文件或模块审查：`.agents/skills/review/SKILL.md`；
- GitHub PR review：`.agents/skills/review-pr/SKILL.md`；权限边界以
  `docs/agents/request-boundary.md` 为准，默认不授权产品修复、发布评论、approve、关闭 PR
  或 push。

## 回复与交付表达

- 先说明真实结果，再给必要证据、修改范围、已执行/未执行验证和外部交付状态；只有需要用户
  决策时才提出问题。
- 因规则暂停或留下未完成工作时，链接实际权威条款，区分明确要求与 Agent 推断，不重复询问
  已有授权。
- 不从材料复制无关要求，不把计划写成完成结果，也不把静态检查写成构建或运行测试。标题、
  提交信息和 PR 描述优先表达实际新增、修复、保留或验证的行为。

## 维护约束

- 保留工作树中与当前任务无关的 staged、unstaged 和 untracked 变更。
- `skills-lock.json` 和 `.codex/agents-lock.json` 管理的内容是外部受管快照，普通项目任务
  不得直接修改；项目专属例外和同步规则见 `docs/agents/README.md`。
