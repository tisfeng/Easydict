## 2026-08-23 | 任务：新增 PR 模板与关联 Issue 解析

**Links:** `../../exec-plans/completed/2026-08-23-pr-template-linked-issues.md`

### 用户请求

新增 GitHub PR 模板，只保留一种“关联 Issue”，允许贡献者使用裸 `#123`、完整 Issue
URL 或仓库编号格式，并由版本发布后的 Issue 跟进统一检查、通知和关闭。

### 变更

- 新增简洁的中英双语默认 PR 模板，包含变更说明、关联 Issue、验证和截图区域。
- 为 `release_issues.py` 增加二级“关联 Issue / Linked Issues”区域识别，将其中的同仓库
  引用统一标记为 `linked_issue`，并在下一个二级标题处结束显式区域。
- 保留 closing reference、完整 URL、`owner/repo#123`、裸 `#123` 和 commit message 的
  旧 PR 兼容路径；同一 Issue 使用多种格式时仍只生成一个候选。
- 更新发布后 Issue 策略、skill 说明和中英文贡献指南，明确不使用 GitHub 自动关闭
  关键字或 Development 侧栏的自动关闭关联。
- 补充模板占位符、区域边界、支持格式、候选归一化和实际模板文件的单元测试。

### 设计意图

贡献者只需要说明 PR 与哪些 Issue 相关，不必提前判断 `fixes` 或 `related`。发布流程
结合 PR 的目标和实际改动生成最终决策：没有明确相反证据且改动覆盖 Issue 核心请求
时使用 `fixes`，再按既有默认解决规则处理。

### 验证

- `release-easydict` 下 24 个 Python 单元测试全部通过。
- `release_issues.py` Python 编译检查通过。
- `release-easydict` 的 `quick_validate.py` 通过。
- `git diff --check` 通过。
- 未创建 PR，未修改 GitHub Release、Issue 评论或 Issue 状态。

### 受影响文件

- `.github/pull_request_template.md`
- `.agents/skills/release-easydict/`
- `docs/agents/skills.md`
- `docs/user-docs/en/GUIDE.md`
- `docs/user-docs/zh/GUIDE.md`
- `docs/exec-plans/completed/2026-08-23-pr-template-linked-issues.md`
