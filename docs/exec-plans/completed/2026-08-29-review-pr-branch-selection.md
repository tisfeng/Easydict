# review-pr 分支选择与 latest-base 语义修复

- 状态：completed
- 创建日期：2026-08-29
- 完成日期：2026-08-29
- 负责人：Codex
- 关联 Issue/PR：PR #1246（行为背景，不修改该 PR）
- 同任务 history：[`2026-08-29-review-pr-branch-selection.md`](../../histories/2026-08-29-review-pr-branch-selection.md)

## 背景

PR #1246 的 head 分支是 `feat/wordbook`。旧规则同时要求普通本地审查保持 PR head 分支名，
又把“解决冲突”直接路由到 `review/pr-<number>-merge-<head-short-sha>`，导致本地
latest-base 审查无论同名分支是否可用都创建了改名的 merge 分支。

## 任务契约

- 任务模式：`implementation`
- 交付授权：`auto-local-commit`
- 安全状态：`normal`
- 允许修改路径：`.agents/skills/review-pr/`、`docs/exec-plans/`、`docs/histories/2026-08/`
- 禁止动作：不 push；不删除、重命名或迁移已有 review 分支；不修改产品源码或 Xcode 工程。
- 初始 HEAD：`0ff2af1e170011b2d8be8783523bd00842305f66`
- 初始 staged、unstaged、untracked 和冲突：均无

## 实施结果

- [x] 将分支选择与 latest-base 合并拆成正交决策。
- [x] 本地 `--merge-latest` 先选择 PR head 同名分支或 collision fallback，再合并最新 base。
- [x] 保留显式 worktree 的 `review/pr-<number>-merge-<head-short-sha>` 隔离命名。
- [x] 将 protected/base 同名、错误 upstream、ahead/diverged 和其他 worktree 占用纳入安全 fallback。
- [x] 新增 fake-`gh` 与临时 bare remote 集成测试，覆盖 6 个关键场景。
- [x] 不改变 PR #1246 远程内容，不删除已有 `review/pr-1246-merge-4ed8d2a03c` 分支。

## 关键决策

- 本地 latest-base 保留已选择的分支名；merge 后验证 PR head 与 latest base 都是 `HEAD` 的 ancestor，并校验正常 merge commit 的两个 parent。
- worktree latest-base 继续使用 SHA 专用 merge 分支，保证 source checkout 不变。
- remote identity 检查读取原始 remote URL，避免 `url.*.insteadOf` 重写导致错误的 remote 冲突判断。

## 验证

- `bash -n .agents/skills/review-pr/scripts/prepare-pr-branch.sh`：通过。
- `PYTHONPYCACHEPREFIX=/private/tmp/review-pr-pycache python3 -m py_compile .agents/skills/review-pr/tests/test_prepare_pr_branch.py`：通过。
- `python3 -m unittest discover -s .agents/skills/review-pr/tests -p 'test_prepare_pr_branch.py' -v`：6 个测试通过。
- `python3 /Users/tisfeng/.codex/skills/.system/skill-creator/scripts/quick_validate.py .agents/skills/review-pr`：`Skill is valid!`。
- `git diff --check`：通过。
- 未运行 `xcodebuild`；未执行真实 GitHub 写操作或 push。

## 完成记录

- 2026-08-29：完成实现、隔离测试、skill 校验和 diff 检查。
- 2026-08-29：本计划归档到 `completed/`，history 与实现一并进入同一次本地提交。
