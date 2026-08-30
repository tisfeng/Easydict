# review-pr 分支选择与 latest-base 语义修复

- 日期：2026-08-29
- 状态：completed
- 关联计划：[`2026-08-29-review-pr-branch-selection.md`](../../exec-plans/completed/2026-08-29-review-pr-branch-selection.md)
- 关联背景：PR #1246 的 `feat/wordbook` 分支准备

## 用户请求

执行已确认方案，修复 `review-pr` 技能规则模糊导致的分支命名问题。用户期望本地
review 优先保持 PR head 分支名，只有本地同名分支无法安全使用时才回退到
`review/pr-<number>-<head-short-sha>`。

## 初始状态

- 分支：`dev`
- `initial_head`：`0ff2af1e170011b2d8be8783523bd00842305f66`
- staged：无
- unstaged：无
- untracked：无
- 冲突：无

## 变更

- 将 `.agents/skills/review-pr/SKILL.md` 的分支选择和 latest-base 规则拆成两个正交决策。
- 让本地 `--merge-latest` 先使用 PR head 同名分支或 collision fallback，再在所选分支上合并最新 base。
- 保留显式 `--worktree --merge-latest` 的 `review/pr-<number>-merge-<head-short-sha>` 隔离命名。
- 保留 exact `headRefOid`、upstream、protected/wrong-upstream/ahead/diverged/in-use collision fallback、冲突现场和无 push 约束。
- 让 remote identity 检查读取未应用 `url.*.insteadOf` 的原始 remote URL，保证离线 Git URL 重写不会误报 remote 冲突。
- 新增 `.agents/skills/review-pr/tests/test_prepare_pr_branch.py`，使用临时 bare remotes 和 fake `gh` 覆盖 6 个关键场景。

## 范围与非目标

- 只修改 review-pr skill、helper、隔离测试、本任务计划和 history。
- 未修改 Easydict 产品源码、Xcode 工程或公共用户文档。
- 未修改 PR #1246 远程内容。
- 未删除、重命名或迁移已有 `review/pr-1246-merge-4ed8d2a03c` 分支。
- 未执行 `xcodebuild`、push 或真实 GitHub 写操作。

## 验证

- `bash -n .agents/skills/review-pr/scripts/prepare-pr-branch.sh`：通过。
- `PYTHONPYCACHEPREFIX=/private/tmp/review-pr-pycache python3 -m py_compile .agents/skills/review-pr/tests/test_prepare_pr_branch.py`：通过。
- `python3 -m unittest discover -s .agents/skills/review-pr/tests -p 'test_prepare_pr_branch.py' -v`：6 个测试通过。
- `python3 /Users/tisfeng/.codex/skills/.system/skill-creator/scripts/quick_validate.py .agents/skills/review-pr`：`Skill is valid!`。
- `git diff --check`：通过。
- 隔离测试确认普通同名分支、同名 latest-base、collision fallback、latest-base 冲突停留、worktree 隔离和无 push 约束均符合预期。

## 完成条件

- 文档和 helper 对本地 latest-base 的分支名语义一致。
- 关键测试和静态检查通过。
- 本计划已归档到 `docs/exec-plans/completed/`。
- 仅暂存本任务 Agent-owned paths 并创建一次本地提交；不 push。
