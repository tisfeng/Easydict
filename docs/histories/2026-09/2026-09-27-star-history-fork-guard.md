## 2026-09-27 | 任务：限制 Star History 工作流仅在上游运行

**Links:** [触发问题的 fork 运行](https://github.com/mrasong/Easydict/actions/runs/36305314309/job/108580666689)、[GitHub 定时工作流通知规则](https://docs.github.com/en/actions/concepts/workflows-and-actions/notifications-for-workflow-runs)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

将 `feat/github-copilot-service` 切换到独立工作树，修复 fork 执行 Star History 维护任务造成失败通知的问题。

### 变更

- 在 `update` job 上增加 `github.repository == 'tisfeng/Easydict'` 条件。
- 补充本次配置修复的 history；简单低风险配置变更不单独创建 plan。

### 设计意图

Star History 的自动提交、PR 和 Pages 部署仅服务于上游仓库。通过 job 级仓库限制，在 fork 中跳过整个任务，同时保留上游的定时与手动执行。此前检查的 fork 定时运行将 `tisfeng` 记录为 actor；GitHub 定时工作流通知规则说明了失败邮件为何可能发给上游作者。

### 验证

- `git diff --check`：通过。
- 使用已有 Python 3.12.3 与 PyYAML 解析 YAML，并与 HEAD 的解析结果比较：通过，唯一语义变化为新增 job 条件。工作树默认 Python 缺少 PyYAML，改用已有解释器后验证成功。
- 手动检查：上游仓库条件为真，`mrasong/Easydict` 条件为假；条件同时约束定时和手动触发，且覆盖全部步骤。
- 本地未安装 actionlint，未运行该检查；未触发远程 Actions。仅工作流配置与文档变化，无需 Xcode 构建或测试。

### 受影响文件

- `.github/workflows/update-star-history.yml`
- `docs/histories/2026-09/2026-09-27-star-history-fork-guard.md`

### 后续事项

- 修复提交发布且现有 fork 同步后才生效；未同步的 fork 仍需其所有者禁用或更新工作流。
