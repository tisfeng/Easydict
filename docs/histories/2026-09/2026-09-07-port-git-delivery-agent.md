## 2026-09-07 | 任务：移植通用本地 Git 交付 Agent

**Links:** [执行计划](../../exec-plans/completed/2026-09-07-port-git-delivery-agents.md)

### 用户请求

将 Scoco 提交 `ae847c0e3` 与 `4ca75d911` 依次移植到当前 Easydict。

### 实施结果

- 用 `.codex/agents/git-delivery.toml` 取代只处理提交的 `git-committer.toml`，模型固定为
  `gpt-5.6-luna`、推理等级固定为 `high`。
- 让该 Agent 以 operation 区分普通提交、自动本地提交和 worktree 集成；只有 integration
  可以创建源分支或临时 worktree、提交、rebase 与 merge。
- 在根路由、Git 工作流和 `worktree-rebase-merge` Skill 中统一 prepare → 主对话提交信息
  预览 → apply 协议，并要求 apply 前重验 HEAD、索引及源/目标 worktree 状态。
- 保留 Easydict 既有的空索引一次暂存规则；对状态漂移、超出允许路径的变更、权限问题和
  需要产品语义判断的冲突一律采用 protected 状态，禁止网络同步和破坏性 Git 操作。
- 为使该本地暂存规则与只读 prepare 协议兼容，额外冻结候选路径、未暂存 raw patch 与
  未跟踪内容摘要；apply 暂存后仅在 staged patch 仍与候选及草稿依据一致时继续。

### 验证与边界

- 已完成 TOML、路径路由、关键约束、Markdown 链接、Git diff 和独立审查。审查先发现
  空索引 prepare 缺少草稿依据，补充候选快照与 apply 暂存后核对后已复核通过。
- 本次不涉及应用运行时代码，未运行 Xcode 或产品测试。
- 静态检查不能替代全新 Codex 会话中 custom agent 的发现和模型实际选择验证。
