## 2026-09-07 | 任务：改进贡献文档中的 Agent 协作流程

**Links:** [`2026-09-07-improve-contributing-agent-workflow.md`](../../exec-plans/completed/2026-09-07-improve-contributing-agent-workflow.md)

### 用户请求

改进贡献文档，介绍 Easydict 的 Agent 开发流程、PR review 与场景验证责任、自动 Codex
review、维护者处理周期、高质量 PR 优先标准，以及常用 Skill 和子代理。

### 变更

- 扩充根目录贡献指南，突出可跳转的 `AGENTS.md` 入口，并介绍 `review`、`review-pr`、
  `submit-pr`、`planner` 和 `reviewer` 的用途与边界。
- 明确 Agent 参与 PR 时的人工代码 review、实际场景验证、自动 Codex review 评论处理和
  作者自助推进责任。
- 说明维护者资源与 review 周期预期，并给出高质量 PR 的可验证优先条件。
- 精简中英文 README 的 AI 辅助说明，欢迎 Codex 和 Claude，并将具体模型版本改为最新
  可用 GPT 或 Claude 模型的稳定表述。

### 设计意图

以根目录贡献指南作为完整入口，README 只保留简洁引导，避免重复规则和具体模型版本随
时间漂移。

### 验证

- `git diff --check`：通过。
- Markdown 相对链接：通过；所有新增仓库文档目标均存在。
- OpenAI Docs：通过；Codex Automatic reviews、`AGENTS.md` 和 `@codex review` 的说明
  与官方 GitHub code review 文档一致。
- 模型版本扫描：通过；公开贡献入口未硬编码 GPT 或 Claude 版本。
- 手动检查：用户要求均有明确落点，README 与贡献指南没有冲突。
- `markdownlint`：未运行，当前环境未安装该命令。
- `xcodebuild`：未运行，本次仅修改 Markdown 文档。

### 受影响文件

- `CONTRIBUTING.md`
- `README.md`
- `README_ZH.md`
- `docs/exec-plans/completed/2026-09-07-improve-contributing-agent-workflow.md`
- `docs/histories/2026-09/2026-09-07-improve-contributing-agent-workflow.md`

### 后续事项

- None
