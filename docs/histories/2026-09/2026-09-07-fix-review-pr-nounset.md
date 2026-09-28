## 2026-09-07 | 任务：修复 review-pr 数字引用在 nounset 下的失败

**Links:** None

### 用户请求

将 Scoco 的 `review-pr` 数字 PR 编号修复同步到 Easydict，并维持三个仓库的一致回归覆盖。

### 变更

- 仅在 `repo_args` 已设置时将其展开给 `gh pr view`，避免 macOS Bash 3.2 在 `set -u` 下因空数组
  终止。
- 扩展 fake `gh`，分别断言数字、GitHub URL 与 `<owner>/<repo>#<number>` 简写的调用参数。
- 补回目标分支被其他 worktree 占用时的本地 fallback 分支回归测试。

### 设计意图

数字 PR 编号依赖当前 checkout，因此不应传入空参数或 `--repo`；携带仓库信息的两种引用则必须
显式传递正确 `--repo`。测试直接验证边界，避免多个准备流程以同一早期 shell 错误同时失败。

### 验证

- `bash -n .agents/skills/review-pr/scripts/prepare-pr-branch.sh`：passed。
- `python3 -m py_compile ...`：passed，pycache 写入 `/tmp`。
- `python3 -m unittest discover -v -s .agents/skills/review-pr/tests -p 'test_*.py'`：27 tests passed。
- `git diff --check`：passed。
- 未运行 `xcodebuild`；本次仅修改 Agent skill 脚本和 Python fixture 测试。

### 受影响文件

- `.agents/skills/review-pr/scripts/prepare-pr-branch.sh`
- `.agents/skills/review-pr/tests/test_prepare_pr_branch.py`

### 后续事项

- None
