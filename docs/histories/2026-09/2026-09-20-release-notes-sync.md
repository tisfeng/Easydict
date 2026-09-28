## 2026-09-20 | 任务：新增发布后日志同步动作

<!-- 文件名：YYYY-MM-DD-<slug>.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-20-release-notes-sync.md)

### 执行上下文

- **Agent Name:** `/root`
- **Model:** Unknown
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

为发布技能增加一种独立动作：人工修改已发布版本的 `changelog/<version>.md` 后，同步
GitHub Release 正文和远程 `main/appcast.xml` 日志，不改变现有 `resume` 语义。

### 变更

- 新增 `release-easydict.sh sync-notes <version>` 路由，默认 preview，`--execute` 才允许远程写入。
- 新增 `release-notes-sync.py`，读取 canonical Markdown，更新已发布 Release body 和目标
  Sparkle item 的 `<description>`，记录状态并支持部分成功后重试。
- 使用 Release ETag、appcast Contents API blob SHA 和干净 worktree 检查，避免覆盖并发修改；
  appcast 候选只允许目标版本 description 变化。
- 新增 `release-appcast.py set-description`，并补充技能/reference/README 使用说明与 focused tests。

### 设计意图

`resume` 继续恢复中断的 ASC 发布工作流；`sync-notes` 是发布后的内容修订通道，不重建 App、
不重新签名、不上传附件、不修改 Tag/构建号/渠道。默认 preview 保留人工复核点。

### 验证

- `python3 -m unittest discover -s scripts/release/tests -p 'test_*.py'`：33 tests passed。
- `bash -n scripts/release/release-easydict.sh`、Python compile checks、`git diff --check`：通过。
- 未运行 `sync-notes --execute`，未修改远程 GitHub Release 或远程 `main/appcast.xml`。

### 受影响文件

- `.agents/skills/release-easydict/SKILL.md`
- `.agents/skills/release-easydict/references/release-workflow.md`
- `scripts/release/README.md`
- `scripts/release/release-easydict.sh`
- `scripts/release/release-appcast.py`
- `scripts/release/release-notes-sync.py`
- `scripts/release/tests/test_release_appcast.py`
- `scripts/release/tests/test_release_notes_sync.py`
- `scripts/release/tests/test_release_redraft.py`

### 后续事项

- 真实远程同步需在确认 preview 后显式执行 `sync-notes <version> --execute`；本次未执行。
