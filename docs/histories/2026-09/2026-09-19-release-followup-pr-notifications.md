## 2026-09-19 | 任务：优化发布后的 PR 通知与机器人过滤

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-19-release-followup-pr-notifications.md)

### 执行上下文

- **Agent Name:** `/root`
- **Model:** Unknown
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

优化发布通知：没有关联 Issue 的人工 PR 在正式发布后获得与 Issue 相同的版本通知；GitHub Actions、Dependabot 等机器人 PR 不进入更新日志或通知。

### 变更

- 新增共享 PR 分类策略，过滤 bot PR，并在 release preflight 校验 changelog 全文（包含 New Contributors）。
- follow-up 收集并审计 bot 元数据，为无有效 Issue 关联的人工 PR 生成独立通知计划；PR 只评论、不关闭。
- Issue/PR 使用目标专属通知 marker，动作状态支持 Issue 与 PR；汇总新增“无关联 issue 的 PR 通知”。
- 2.23.0 changelog 移除 4 条 star-history GitHub Actions PR 和 1 条 Dependabot PR。
- 更新发布流程文档、策略文档和 30 项自动化测试。

### 设计意图

发布 PR 的分类只依据 GitHub API 的 bot 元数据和精确 bot 登录名，不按 `chore` 泛化过滤；有有效 Issue 关联的 PR 不重复通知，避免一项变更产生两条评论。正式 Release 远程验证成功前不执行 Issue/PR 评论、Issue 关闭或 main appcast 推送。

### 验证

- `python3 -m unittest discover -s .agents/skills/release-easydict/tests -p 'test_*.py'`：30 项通过。
- `python3 scripts/release/release_notes.py validate --file changelog/2.23.0.md --version 2.23.0`：通过。
- `python3 .agents/skills/release-easydict/scripts/release_content.py validate-pr-policy --repo tisfeng/Easydict --version 2.23.0 --notes changelog/2.23.0.md`：通过，13 条人工 PR。
- `bash -n scripts/release/release-preflight.sh scripts/release/release-easydict.sh`、`python3 -m py_compile`、`git diff --check`：通过。
- 未执行 GitHub Release publish、Issue/PR comment、Issue close、push 或 appcast 正式分支变更。

### 受影响文件

- `.agents/skills/release-easydict/scripts/release_pr_policy.py`
- `.agents/skills/release-easydict/scripts/release_content.py`
- `.agents/skills/release-easydict/scripts/release_issues.py`
- `.agents/skills/release-easydict/references/`
- `.agents/skills/release-easydict/tests/`
- `scripts/release/release-preflight.sh`
- `changelog/2.23.0.md`

### 后续事项

- 本提交需要先进入后续发布流程，正式发布后再运行 `issue-followup apply <version>` 执行远程通知。
