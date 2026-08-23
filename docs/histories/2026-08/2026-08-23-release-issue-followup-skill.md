## 2026-08-23 | 任务：拆分发布后 Issue 跟进 Skill

**Links:** `../../exec-plans/completed/2026-08-23-release-issue-followup-skill.md`

### 用户请求

将 Easydict 发布后的 issue 通知与关闭操作从主发布 skill 中独立出来，支持可测试的
`plan`、可直接执行的 `apply` 和故障恢复 `resume`。固定 issue/PR 链接和三类汇总，
并将已关联修复 PR 的 issue 默认视为解决，除非存在明确反证。

### 变更

- 新增 `release-easydict-issue-followup` skill，独立维护授权边界、动作入口、schema-v2
  状态、关联决策策略和 helper 命令。
- 将每个弱引用 PR 规范为 `fixes`、`related` 或 `rejected`；`fixes` 默认解决，只有包含
  GitHub URL 和说明的明确反证才允许 `not_resolved`。
- 删除 reopen 阻止关闭规则。版本评论标记只用于避免重复评论，当前开放且已解决的
  issue 在重试时仍会关闭。
- 由 helper 固定渲染“关闭 issue 并已通知”“仅发通知”“未关闭的相关 issue”三类
  Markdown 汇总；每个可见 issue 和 PR 都使用可点击链接，拒绝项仅进入机器审计。
- 更新 `release-easydict`：Draft 只编排英文内容；publish 完成 Release、appcast 和远程
  验证后直接委托 issue follow-up `apply`，无需用户先运行 `plan`。
- 移除主发布 skill 内重复的旧 issue 策略、helper 和测试，新状态与旧 schema-v1 审计
  文件通过 `state/issue-followup/` 目录隔离。

### 设计意图

发布成功和 issue 跟进是两个不同的恢复边界。主发布流程先保证可下载版本和公开 feed
完整，再执行可重试的 issue 动作。语义判断仍由 skill 阅读真实 PR/issue 证据完成，脚本
负责校验默认解决规则、动作幂等性和固定报告格式，避免 Agent 自由创造分类或因为 reopen、
一般性不确定而跳过应关闭的 issue。

### 验证

- 主发布内容测试：7 个通过。
- 独立 issue follow-up 测试：13 个通过，覆盖直接 `apply`、明确反证、固定汇总、
  已有通知后的关闭和已关闭 issue 仅通知。
- 两个 skill 的 `quick_validate.py`：通过。
- Python 编译检查、helper `--help` 和 `git diff --check`：通过。
- 未执行真实 GitHub Release、issue 评论或 issue 关闭。

### 受影响文件

- `.agents/skills/release-easydict-issue-followup/`
- `.agents/skills/release-easydict/`
- `docs/agents/skills.md`
- `docs/exec-plans/completed/2026-08-23-release-issue-followup-skill.md`

### 后续事项

- PR 模板中的显式发布目标字段仍按用户要求留待后续单独处理。
- 可以单独运行 `$release-easydict-issue-followup plan 2.22.0` 检查新分类，再由用户明确
  请求 `apply 2.22.0` 修正上一批遗漏的真实 issue 动作。
