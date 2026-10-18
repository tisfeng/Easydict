## 2026-09-14 | 任务：收敛 Agent 项目默认值与资产所有权

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-14-simplify-agent-ownership.md)

### 用户请求

将 boss-resume 清理 Agent 文档时确认的通用规则所有权同步到 Easydict，并删除不再需要的项目
默认值样板。

### 变更

- 删除根 `AGENTS.md` 中单独的“项目默认值”段；PR base 继续由仓库默认分支和受管
  `submit-pr` Skill 解析。
- 将外部资产设计标题收敛为“外部 Skill 资产”，并明确 Swift/Xcode、本地化和发布属于宿主
  项目政策，通用 Git、Review 和交付算法属于受管 Skill。
- 保留已经有效的 `#外部-skill-资产` 链接，不修改受管 Skills、lock 或历史 completed plan。

### 设计意图

Easydict 的现行入口已经移除通用 Skill 与 PR review 路由。本次只删除剩余的可推导默认值，并让
两份资产文档使用相同所有权边界，避免宿主规则再次复制受管算法。

### 验证

- `git diff --check`：通过。
- 变更 Markdown 的本地链接和锚点：通过。
- `git ls-remote --symref origin HEAD`：实时默认分支仍为 `dev`。
- `submit-pr` reference：base branch 继续解析 GitHub repository default branch。
- `xcodebuild`：未运行；本次治理 Markdown 不进入 Xcode 构建图。

### 受影响文件

- `AGENTS.md`
- `docs/agents/README.md`
- `docs/design-docs/external-agent-assets-management.md`
- `docs/exec-plans/completed/2026-09/2026-09-14-simplify-agent-ownership.md`
- `docs/histories/2026-09/2026-09-14-simplify-agent-ownership.md`

### 后续事项

- None
