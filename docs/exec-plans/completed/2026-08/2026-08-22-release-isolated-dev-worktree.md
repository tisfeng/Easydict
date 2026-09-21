# 发布流程使用隔离的本地 dev 源

状态：已完成

## 目标

允许用户从任意当前 checkout 执行发布命令，同时确保发布内容以本地已提交的 `dev`
为基线，并且不切换或修改用户当前工作树。

## 实现

- 从本地 `refs/heads/dev` 创建 detached 临时 worktree。
- 在临时 worktree 中同步 `origin/dev`，生成不可变的发布源提交。
- 从发布源提交创建版本专用 release worktree，再合并同步时的 `origin/main`。
- 保留当前 checkout 的分支、暂存区和未提交修改。
- 在同步冲突时保留临时 worktree，并输出可恢复的诊断路径。
- 收敛 worktree 创建和合并的成功日志，避免原始 Git 输出干扰工作流日志。

## 验证

- Shell 脚本语法检查通过。
- `asc workflow validate` 通过。
- `draft --dry-run` 通过。
- 隔离 `sync-dev`、`prepare` 和 `resume` 流程通过。
- 非 `dev` checkout 且存在未提交修改的隔离测试通过，当前修改保持不变。
