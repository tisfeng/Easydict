# Worktree 集成回执

直接提交或完成 rebase/merge 后读取。以实际 Git 状态为准，不重新起草或翻译已有提交信息。

## 集成结果

先输出“集成结果”，至少包含：

- 源分支、目标分支和目标 checkout。
- 源提交数和集成模式：`direct-commit`、`existing-target-worktree` 或
  `temporary-target-worktree`。
- Rebase、Merge 和 Push 的实际状态。
- 源/目标 worktree 的最终状态。
- 临时 worktree 路径与清理结果（如适用）。
- 原始 detached commit、源分支是创建还是复用（如适用）。

直接提交时，Rebase、Merge 和 Push 都明确写“未执行”。

## 提交回执

- 恰好一个源提交时，在集成结果后完整附加 `git-commit` 的回执，包含统计表和完整实际信息。
  `created-this-run` 写“已创建提交”；`preexisting-source-commit` 写“本次未创建新提交；
  合并的是源分支已有提交”，提交后校验为“未执行（本次复用已有提交）”。
- 多个源提交时，列出每个完整 hash 和 subject，再调用 `git-commit` 汇报冻结范围并生成统计。
  范围没有单一提交信息，不用任一 message 代表整个范围。

多提交统计使用合并前冻结的目标 OID 与 rebase 后源 OID，避免目标已前进后读出空范围。
`git-commit` 是提交结果、统计和单提交实际 message 的唯一格式来源；本 Skill 只补充集成事实。
