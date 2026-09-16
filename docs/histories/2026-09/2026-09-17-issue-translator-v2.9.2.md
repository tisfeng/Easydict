## 2026-09-17 | 任务：升级 Issue Translator Action 至 v2.9.2

**Links:** [v2.9.2](https://github.com/tisfeng/issues-translate-action/releases/tag/v2.9.2)、
提交 `92f09e4db5411aea294862418b746c52ccb3a653`

### 执行上下文

- **Agent Name:** `Codex`
- **Model ID:** `Unknown`

### 用户请求

将 Easydict 的 Issue 翻译工作流引用升级到新发布的 `v2.9.2`。

### 变更

- 将 `.github/workflows/issue-translator.yml` 的 Action 引用从 `v2.9.1` 更新为 `v2.9.2`。
- 保留 `issue_comment`、`issues`、`pull_request_review_comment` 触发器和全部翻译 inputs，
  不触发真实 workflow。

### 设计意图

固定引用已发布的 `v2.9.2` tag，只更新依赖版本，不改变工作流触发条件或翻译配置。

### 验证

- 上游 annotated tag：peeled SHA 与发布提交一致，Release 为非 draft、非 prerelease。
- YAML 解析和 `git diff --check`：通过。

### 受影响文件

- `.github/workflows/issue-translator.yml`
- `docs/histories/2026-09/2026-09-17-issue-translator-v2.9.2.md`

### 后续事项

- None
