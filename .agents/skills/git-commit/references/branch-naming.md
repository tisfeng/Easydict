# 组合工作流的分支命名

仅当 `submit-pr` 或 `worktree-rebase-merge` 等组合工作流在提交产生前需要任务分支名时读取。
本协议是 `git-commit` 的内部组合能力，不是独立的用户触发目标。

用户明确给出的名称或项目现有命名约定优先。未给出时：

1. 在不暂存文件的前提下检查任务和只读 diff 证据。
2. 根据 [提交信息契约](commit-message.md#type-指南) 选择最窄的 Angular `type`，用简洁英文概括主要意图。
3. 将摘要转为小写 kebab-case，形成 `<type>/<kebab-case-summary>`，不包含 Angular scope 标点。
4. 使用 `git check-ref-format --branch <branch-name>` 验证字面分支名，不使用 `@{-1}` 等会展开为其他引用的表达式。

返回候选名不授权暂存、提交、创建或移动分支。调用方负责名称冲突、分支操作和状态验证。
