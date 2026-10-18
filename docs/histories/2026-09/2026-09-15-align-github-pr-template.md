## 2026-09-15 | 任务：对齐 GitHub PR 模板结构

**Links:** [GitHub PR 模板](../../../.github/pull_request_template.md)、
[submit-pr 固定模板](../../../.agents/skills/submit-pr/assets/pull_request_template.md)

### 用户请求

将项目的 GitHub PR 模板调整为 `submit-pr` 的五段式结构，同时保留面向贡献者的填写说明。

### 变更

- 将 GitHub PR 模板拆分为背景、变更内容、关联 Issue、验证和截图五个区域。
- 保留 Easydict 发布后统一跟进关联 Issue 的中英文说明，不使用受管 Skill 文件的软链接。
- 扩展发布 Issue 测试，校验项目模板与 `submit-pr` 固定模板的标题顺序一致，且不泄漏渲染变量。

### 设计意图

`submit-pr` 继续独立渲染受管 Skill 内的固定模板，GitHub 模板则作为面向人工贡献者的项目适配层。
两者共享正文结构，但项目模板可以继续承载 Easydict 专属说明，并避免 GitHub 软链接兼容性和上游升级耦合。

### 验证

- `python3.12 .agents/skills/release-easydict/tests/test_release_issues.py`：17 项测试通过。
- `git diff --check`：通过。
- 相对链接检查：通过。

### 受影响文件

- `.github/pull_request_template.md`
- `.agents/skills/release-easydict/tests/test_release_issues.py`
- `docs/histories/2026-09/2026-09-15-align-github-pr-template.md`

### 后续事项

- None
