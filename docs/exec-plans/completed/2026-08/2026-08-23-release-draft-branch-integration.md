# 使用临时发布分支隔离 Draft

**Status:** completed
**Created:** 2026-08-23
**Updated:** 2026-08-23
**Owner:** Easydict maintainers
**Links:** `.agents/skills/release-easydict/SKILL.md`

## 任务契约

- 任务模式：`implementation`
- 用户目标：Draft 只推送远程 `release/sync-<version>` 和版本 Tag；Publish 成功时再将发布提交通过 merge 集成到最新本地 `dev`，并更新远程 `dev` 与 `main`。
- 允许动作：修改发布脚本、工作流、测试、Skill 和相关文档；运行本地静态、隔离 Git 和 dry-run 验证；自动创建本地提交。
- 允许修改路径：`scripts/release/`、`.agents/skills/release-easydict/`、`docs/exec-plans/`、`docs/histories/`。
- 预期交付物：隔离的 Draft 引用模型、Publish 前集成预演、无历史改写的 merge 集成、本地 `dev` 安全前移、原子远程更新、可恢复状态和固定结果摘要。
- 验收标准：Draft 不修改 `origin/dev` 或 `origin/main`；Tag 始终指向已构建的版本提交；Publish 所有分支更新保持 fast-forward 并受旧 OID lease 保护；成功后本地 `dev == origin/dev`、`origin/main` 精确表示已发布 appcast 提交，且临时远程发布分支被清理。

## 自动提交状态

- 自动提交资格：`eligible`
- 初始暂存区：`empty`
- 自动提交结果：验证完成后由 implementation 自动交付。

## 输入来源

- 用户明确请求：接受 merge 方案，要求按新的 Draft 临时分支与 Publish 集成计划执行。
- 仓库规则：`AGENTS.md`、`docs/agents/repository-guide.md`、`docs/agents/skills.md`、`docs/agents/testing.md`。
- 附件或引用材料：2.22.0 Draft/Publish 日志和当前发布脚本。
- 仅作为证据的内容：此前 Draft 直接更新 `origin/dev` 与 `origin/main` 所形成的分支分叉；本任务没有重新发布 2.22.0。

## 完成结果

- 普通 Draft 和同版本替换 Draft 只 lease 更新远程 `release/sync-<version>` 与版本 Tag。
- Publish 在 GitHub Release 公开前创建隔离集成 worktree，merge 最新本地 `dev`、`origin/dev` 和版本提交，冲突时停止。
- appcast 安装后再次 merge appcast 提交，先通过旧 OID 或干净 checkout fast-forward 更新本地 `dev`，再原子更新远程 `dev`、`main` 和临时发布分支。
- 远程验证要求本地/远程 `dev` 一致、`main` 和临时分支等于 appcast 提交、Tag 等于版本提交；验证后删除临时远程分支和两个本地 worktree。
- 当前 checkout 位于其他分支并含未提交文件时，隔离测试证明分支、HEAD 和文件内容均不受影响。

## 风险与缓解

- Publish merge 冲突：在 GitHub Release 仍为 Draft 时停止并保留集成 worktree。
- 分支竞态：每个远程目标使用精确旧 OID lease，并在推送前证明更新是 fast-forward。
- 本地 `dev` 并发变化：最终推送前重新读取并 merge；被 checkout 时要求干净且 HEAD 未变化。
- 中途失败：`state/publish-git.env` 保存基线、appcast 提交和最终集成提交，asc resume 可幂等重试。
- 替换 Draft：冻结旧临时分支 OID；兼容尚未创建临时分支的旧 Draft。

## 验证

- `bash -n scripts/release/*.sh`：通过。
- `jq -e . scripts/release/asc-workflow.json`：通过。
- `asc workflow validate --file scripts/release/asc-workflow.json --pretty`：通过。
- `python3 -m unittest discover -s scripts/release/tests -p 'test_*.py' -v`：11 个测试通过。
- `python3 -m unittest discover -s .agents/skills/release-easydict/tests -p 'test_*.py' -v`：20 个测试通过。
- Skill `quick_validate.py`：通过。
- 普通 Draft、替换 Draft 和 Publish `--dry-run`：通过，步骤顺序符合新模型。
- `git diff --check`：通过。
- ShellCheck：本机未安装，未运行。
- 手动检查：Draft refspec 不包含 `dev/main`；Publish 无 rebase，且 Tag、main 和 dev 的验证关系符合新模型。

## 决策记录

- Draft 只发布临时分支与 Tag，避免未公开版本提前进入开发和稳定分支。
- Publish 使用 merge/fast-forward，不改写已经构建并由 Tag 标识的提交。
- `origin/main` 精确指向 appcast 提交；`origin/dev` 可以在其上包含 Draft 后新增的开发提交。
- 本地 `dev` 是 Publish 成功条件；无法安全更新时必须停止，不留下静默落后状态。

## 后续事项

- 首次真实使用新流程时，检查终端中的 Draft/Publish Git 摘要和远程临时分支清理结果。
