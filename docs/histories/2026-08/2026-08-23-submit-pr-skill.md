## 2026-08-23 | 任务：新增 submit-pr 技能

**Links:** `../../exec-plans/completed/2026-08-23-submit-pr-skill.md`

### 用户请求

新增一个与仓库 PR 模板配合的本地 skill，用于从当前提交生成 PR 内容、安全推送任务
分支并创建 GitHub PR。UI 修改不要求 skill 生成截图，也不能因为缺少截图中断流程；
创建成功后提示用户前往 GitHub PR 页面补充。

### 变更

- 新增 `submit-pr` skill，提供只读 `plan`、默认正式 PR 和 `draft` 三种调用方式。
- 新增确定性 Python helper，直接读取现有 PR 模板，渲染变更说明、关联 Issue、验证和
  截图区域，并拒绝 GitHub closing keyword。
- 当前 checkout 位于 `dev` 时从 HEAD 创建独立任务分支但不切换 checkout，不移动本地
  `dev`，也不 push `origin/dev`。
- 显式检查 remote、base 拓扑、任务分支 SHA 和开放 PR；重复执行时复用 exact
  head/base PR，内容不一致时停止而不覆盖用户修改。
- 创建后验证 PR 的 base、head、head SHA、标题、正文、Draft 状态和
  `closingIssuesReferences`，并要求 head repository 与目标仓库完全一致。
- 创建前检查完整 commit message 和生成的 PR 正文，阻止 GitHub closing keyword；
  push 使用计划冻结的完整 SHA，避免本地 branch ref 并发移动后推送未预览提交。
- UI 修改在截图区域写入 GitHub 页面补充提示，并在 helper 结果中返回
  `needs_screenshots: true`；缺少截图不影响 push、创建和验证。
- 增加临时 bare remote 与 fake `gh` 测试，不连接真实 GitHub。

### 设计意图

`submit-pr` 只处理 PR 交付，和负责本地提交的 `git-commit`、负责审查现有 PR 的
`review-pr` 保持职责分离。语义内容由 Agent 基于真实 diff 起草，helper 只执行可重复、
可验证的模板与 Git/GitHub 状态机。

### 验证

- 15 个 `submit-pr` 隔离单元与集成测试通过。
- Python 编译和 skill `quick_validate.py` 通过。
- 独立前向测试确认 `plan` 没有改变 refs、索引、工作树或 `.tmp/submit-pr/`，并确认 UI
  模拟计划返回补图提示而不生成截图或中断。
- `git diff --check` 通过。

### 受影响文件

- `.agents/skills/submit-pr/`
- `AGENTS.md`
- `docs/agents/skills.md`
- `docs/exec-plans/completed/2026-08-23-submit-pr-skill.md`
