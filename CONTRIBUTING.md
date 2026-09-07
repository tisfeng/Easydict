# 贡献指南

欢迎通过 issue 和 Pull Request 参与 Easydict 的改进。

## 如何参与

- 报告缺陷前，请先搜索已有 issue，并提供复现步骤、预期与实际结果、版本信息，以及可安全公开的日志或截图。
- 较大的功能、界面或架构变更，请先讨论目标和用户体验，再开始实现。
- 范围明确的小修复、文档、本地化和测试改进可以直接提交 PR。
- 每个 PR 保持聚焦，不混入无关改动、本地配置、密钥或用户数据。

## 使用编程 Agent

Easydict 已深度集成 Agent 辅助开发流程。开始贡献前，强烈建议先阅读并理解
[`AGENTS.md`](AGENTS.md)，再按照其中的任务路由阅读与本次改动相关的规则。

欢迎使用 Codex、Claude 等编程 Agent 阅读代码、分析问题、规划实现、生成补丁和参与
review。建议选择当前最新、适合复杂编程任务的 GPT 或 Claude 模型。

使用 Agent 不会转移贡献者的责任。提交者应理解最终代码，确认改动符合项目架构、代码
规范和实际需求，并排除无关修改、虚构实现或未经验证的假设。

### Skill 与子代理

Skill 定义可复用的工作流程，子代理负责独立规划、审查或验证等分工。不同 Agent 客户端
的调用方式可能不同，请以对应工具和仓库规则为准。

| 能力 | 类型 | 用途 |
| --- | --- | --- |
| [`review`](.agents/skills/review/SKILL.md) | Skill | 审查本地改动、提交或模块，给出有证据的问题与修复建议；默认只读，不自动修复 |
| [`review-pr`](.agents/skills/review-pr/SKILL.md) | Skill | 审查 GitHub PR 的代码、CI 和开放 review thread，帮助作者主动推进 PR |
| [`submit-pr`](.agents/skills/submit-pr/SKILL.md) | Skill | 根据已提交变更规划、创建或复用 PR；`plan` 可只读预览，正式执行会 push 并创建或复用 PR |
| [`planner`](.codex/agents/planner.toml) | 子代理 | 只读分析目标、证据、取舍和实施方案 |
| [`reviewer`](.codex/agents/reviewer.toml) | 子代理 | 独立审查指定代码快照，提供问题、修复建议和增量复核结果 |

## 开始开发

从源码构建请参阅[开发者构建指南](docs/user-docs/zh/GUIDE.md#开发者构建)。使用 Xcode
打开 `Easydict.xcworkspace`，选择 `Easydict` scheme 后编译或运行；请使用 workspace，
而不是 `Easydict.xcodeproj`。修改前请先理解涉及的实际行为、调用关系和架构边界。

## 提交 Pull Request

- 默认向 `dev` 提交；维护者指定其他目标分支时以其为准。
- 分支使用 `类型/简短描述` 的 kebab-case 格式，例如 `feat/openai-translation` 或
  `fix/ocr-window-focus`；请勿直接在 `dev` 或 `main` 上提交。
- 提交使用 Angular-style 格式，并保持单个提交语义聚焦。
- 请在 PR 模板的“关联 Issue”区域填写相关 Issue；请勿使用 GitHub 自动关闭关键字或
  Development 侧栏的自动关闭关联。
- PR 应说明目的、主要变化、影响范围和验证结果。UI 变化请附截图或录屏；行为变化请同步必要测试和用户文档。

## 提交前的 review 与验证

对于 Agent 参与的改动，提交 PR 前必须仔细 review 最终 diff，并在实际使用场景中运行
验证。至少覆盖原问题或目标场景、正常流程和受影响的关键边界；Agent review、自动测试和
CI 都不能替代实际场景验证。

请在 PR 中写明验证环境、步骤、结果和未验证项。纯文档或其他静态修改按实际范围完成
链接、格式或配置检查即可；不要把未运行的构建或测试写成已通过。

## 提交后的 review 流程

本项目会为 GitHub Pull Request 启用 Codex Automatic reviews。PR 进入 review 后，
Codex 会按照适用的 [`AGENTS.md`](AGENTS.md) 规则提供额外审查；也可以通过
[`@codex review`](https://learn.chatgpt.com/docs/third-party/github)
请求审查。

请先逐条甄别并处理 Codex 和其他 reviewer 的意见：

- 有效问题应修复并重新验证。
- 不准确或不适用的评论不必盲从，但应回复原因，并提供代码、测试或运行证据。
- 有分歧时继续讨论，不要只为清空状态而直接 resolve thread。
- 更新代码后检查 CI、冲突和剩余评论，确认没有无人回应或尚未处理的有效 review 问题。

自动 review 是额外的质量检查，不能替代贡献者 review、测试、分支保护或维护者的最终判断。

## Review 周期与处理优先级

当前活跃维护者数量有限，待 review 的贡献 PR 较多，因此人工 review 周期可能较长，
也无法承诺固定处理时间。等待期间请主动推进 review 流程：自查 diff、处理 CI 和冲突、
回复 review 评论、补齐验证证据；准备完成后可以简要说明进展并请求复审。

范围明确、证据充分的高质量 PR 通常会被优先处理，例如：

- 明确修复可复现的 bug，或解决具体且已充分说明的问题。
- 改动聚焦，代码清晰，并符合现有架构与代码规范。
- 提供自动测试或可靠的实际场景验证结果，且 CI 通过。
- review 意见已充分处理，没有无人回应或尚未处理的有效开放问题。

优先处理不代表必然合并；维护者仍会根据正确性、产品方向、兼容性和维护成本作出最终判断。

## 详细文档

- [开发者构建指南](docs/user-docs/zh/GUIDE.md#开发者构建)
- [架构与源码定位](docs/architecture/overview.md)
- [构建与测试](docs/agents/build-and-test.md)
- [Xcode 工程](docs/agents/swift-xcode.md)
- [本地化](docs/agents/localization.md)
- [代码质量](docs/agents/code-quality.md)
- [Agent 开发入口](AGENTS.md)
