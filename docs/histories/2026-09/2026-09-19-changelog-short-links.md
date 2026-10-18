## 2026-09-19 | 任务：优化 2.23.0 changelog 短链接

<!-- 文件名：YYYY-MM-DD-<slug>.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->

**Links:** [2.23.0 Release](https://github.com/tisfeng/Easydict/releases/tag/2.23.0)、[执行计划](../../exec-plans/completed/2026-09/2026-09-19-changelog-short-links.md)

### 执行上下文

- **Agent Name:** `/root`
- **Model:** Unknown
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

按方案同步 2.23.0 changelog，将过长的 GitHub 裸链接改为简短 Markdown 链接。

### 变更

- 将 2.23.0 PR、New Contributors 和 Full Changelog 链接改为 `[#PR号](URL)` 或 `[版本范围](URL)`。
- 更新 release 内容解析器，使其兼容短 Markdown PR 链接和历史裸 PR URL，并拒绝 Markdown 标签编号与 URL 编号不一致的条目。
- 新增渲染、解析和不一致标签测试；更新 changelog 格式约定。
- 重渲染本地 `appcast.xml` 的 2.23.0 description，移除旧正文中的 bot/Dependabot 条目并显示短标签。
- 将 GitHub 2.23.0 prerelease 正文同步为 canonical changelog；Release 标题、Tag、Prerelease 状态和附件未改变。

### 设计意图

保留完整 URL 作为链接目标，只缩短展示文本，从而改善 GitHub Release 和 Sparkle 更新说明的换行与扫描体验。解析器继续读取旧版本裸 URL，避免历史 Release 失效；2.22.0 历史正文未改动。

### 验证

- `python3 scripts/release/tests/test_release_notes.py`：通过，10 tests。
- `python3 .agents/skills/release-easydict/tests/test_release_content.py`：通过，12 tests。
- `python3 scripts/release/tests/test_release_appcast.py`：通过，6 tests。
- `python3 scripts/release/release_notes.py verify-release --file changelog/2.23.0.md --version 2.23.0 --repo tisfeng/Easydict`：通过，远程正文与 canonical changelog 一致。
- `git diff --check` 与 Python 编译检查：通过。
- 远程 `main/appcast.xml` 尚未同步；该远程分支写入不在本次授权范围内。

### 受影响文件

- `changelog/2.23.0.md`
- `changelog/README.md`
- `scripts/release/tests/test_release_notes.py`
- `.agents/skills/release-easydict/scripts/release_content.py`
- `.agents/skills/release-easydict/tests/test_release_content.py`
- `appcast.xml`
- `docs/exec-plans/completed/2026-09/2026-09-19-changelog-short-links.md`

### 后续事项

- 若要让线上 Sparkle feed 立即显示短链接，需要单独授权将本地 `appcast.xml` 集成到远程 `main`；本次未执行。
