## 2026-11-08 | 任务：恢复 fork PR 行内评论翻译

**Links:** [执行计划](../../exec-plans/completed/2026-11/2026-11-08-fork-review-translation.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B52)`

### 用户请求

用两段 workflow 恢复 fork PR 的行内评论翻译，并在 v2.10.0 发布后更新 Easydict。

### 变更

- 现有工作流在 fork 行内评论事件中生成只含评论标识的 artifact 名称。
- 默认分支上的发布工作流读取该次运行的 artifact 元数据，使用 `pull-requests: write` 调用 Action。
- 普通翻译使用 v2.10.0，fork 回复步骤固定到该版本的完整提交 SHA。

### 设计意图

将 fork 事件的收集与需要写权限的回复拆分。发布步骤只读取 ID，不下载文件或执行 fork 代码。

### 验证

- 两份 workflow 通过 `actionlint`，ID 提取脚本通过 `bash -n`。
- 本地模拟验证正确尝试、缺失记录、重复记录、非法标识与 API 失败。
- 未触发真实 workflow 或发布 GitHub 评论。

### 受影响文件

- `.github/workflows/issue-translator.yml`、`.github/workflows/fork-review-comment-translator.yml`。

### 后续事项

- 本次集成在本地 `dev`。远端默认分支更新后需用真实 fork 行内评论验收，仍受 GitHub 审批策略约束。
