## 2026-08-24 | 任务：泛化 submit-pr 技能

**Links:** `../../exec-plans/completed/2026-08-24-generic-submit-pr-skill.md`

### 用户请求

保留 `submit-pr` Skill 在当前仓库中的存储位置和统一质量规则，但移除其对 Easydict、
`origin` 与 `dev` 的执行绑定，使它可以从任意 GitHub 项目 checkout 安全创建 PR。

### 变更

- 将 repository、default/base branch、base remote、head remote 和 fork 网络改为动态
  发现；显式参数只用于解决歧义，不能绕过 GitHub 身份校验。
- 同时识别 remote 的 fetch URL 与 push URL，支持独立 fork remote 和同一 remote 的
  fork pushurl；fork PR 使用 `<owner>:<branch>` 创建并验证。
- 保留固定四段式正文、Angular-style 标题和 Conventional 任务分支规则，并兼容
  GitHub 常见模板路径、英文语义标题、项目 checklist 和额外段落。
- 增加 `neutral`、`allow`、`forbid` Issue 策略；Easydict 的禁止自动关闭政策从通用
  默认值移到仓库 Agent 路由规则。
- `plan` 使用 Git 只读锁模式且不 fetch、不创建 ref、不写状态文件；`apply` 使用系统
  临时正文文件，避免在任意目标仓库产生 `.tmp` 工作树变更。
- 重写隔离测试 fixture，不再依赖 `tisfeng/Easydict`、`origin/dev` 或真实 GitHub。

### 设计意图

将“PR 内容质量规范”与“目标仓库拓扑”分离：前者在所有项目中保持严格一致，后者由
当前 checkout 和 GitHub 元数据动态解析。存在多个模板、remote 或 fork 网络时停止，
让调用方显式选择，而不是使用名称惯例猜测。

### 验证

- `PYTHONPYCACHEPREFIX=/private/tmp/submit-pr-tests-pycache python3 -m py_compile
  .agents/skills/submit-pr/scripts/submit_pr.py`：通过。
- `PYTHONPYCACHEPREFIX=/private/tmp/submit-pr-tests-pycache python3
  .agents/skills/submit-pr/tests/test_submit_pr.py`：17 个测试通过。
- `python3 /Users/tisfeng/.codex/skills/.system/skill-creator/scripts/quick_validate.py
  .agents/skills/submit-pr`：`Skill is valid!`。
- `git diff --check`：通过。
- 手动检查：Skill 本体不再包含 Easydict、`origin/dev` 或固定 repository 常量；helper
  保持 executable bit，未连接或写入真实 GitHub。

### 受影响文件

- `.agents/skills/submit-pr/`
- `docs/agents/skills.md`
- `docs/exec-plans/completed/2026-08-24-generic-submit-pr-skill.md`

### 后续事项

- None
