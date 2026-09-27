## 2026-09-19 | 任务：将 appcast 冻结前移到 Draft

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-19-release-appcast-draft-flow.md)

### 执行上下文

- **Agent Name:** Unknown
- **Model:** Unknown
- **Environment:** macOS 27.0 / Xcode 27.0 (27A266a)

### 用户请求

检查并执行发布流程改进：`appcast.xml` 应在 Draft 阶段生成、验证并作为独立提交冻结；Publish 只执行正式发布、远程推送、验证和后续 Issue 动作。

### 变更

- 将 channel transition 与 appcast 提交移到 Draft workflow，Publish 改为消费冻结提交。
- 将 Draft 状态拆分为 version commit、appcast commit 和 Tag object，并验证祖先关系。
- 使版本 Tag 指向 version commit，临时 release 分支指向 appcast commit；Publish 使用冻结 appcast 更新 `main` 和集成 `dev`。
- 更新 Draft replacement 的引用切换、Git flow 行为测试、发布 README 与 release skill 文档。

### 设计意图

保留 version commit 与 appcast commit 两个提交，使 Draft 可审查最终 feed，同时不提前修改远程 `main`/`dev`。Publish 不再重新生成或提交 appcast，避免公开 Release 后产生不可审查的 Git 差异。

### 验证

- `bash -n scripts/release/*.sh`、`jq -e . scripts/release/asc-workflow.json`：通过。
- `python3 -m compileall -q scripts/release .agents/skills/release-easydict/scripts`：通过。
- `python3 -m unittest discover -s scripts/release/tests -p 'test_*.py'`：27 个测试通过。
- 针对发布流程的 15 个行为测试：通过。
- `git diff --check`：通过。
- 未执行真实 Draft、Publish、GitHub Release、Issue 操作或远程推送。

### 受影响文件

- `scripts/release/asc-workflow.json`
- `scripts/release/release-appcast.sh`
- `scripts/release/release-common.sh`
- `scripts/release/release-branch-sync.sh`
- `scripts/release/release-publish-git.sh`
- `scripts/release/release-redraft-git.sh`
- `scripts/release/release-easydict.sh`
- `scripts/release/tests/test_release_git_flow.py`
- `scripts/release/tests/test_release_redraft.py`
- `scripts/release/README.md`
- `.agents/skills/release-easydict/SKILL.md`
- `.agents/skills/release-easydict/references/release-workflow.md`

### 后续事项

- 真实 2.23.0 发布仍需按 Draft → 人工审查 → Publish 执行；本次未触发任何远程发布动作。
