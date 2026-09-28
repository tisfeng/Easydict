# Changelog Short Links

<!-- 文件名：YYYY-MM-DD-<slug>.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->

- 状态：completed
- 创建日期：2026-09-19
- 负责人：Unknown
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1285

## 执行上下文

- **Agent Name:** `/root`
- **Model:** Unknown
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

2.23.0 的 canonical changelog、GitHub prerelease 正文和仓库 appcast 将 GitHub PR 与比较范围显示为完整裸 URL，导致 Release 弹窗换行过长。当前本地 changelog 已过滤 bot/Dependabot 条目，但远程正文仍保留旧版本内容。

## 目标与范围

- 目标结果：2.23.0 的 Markdown、GitHub prerelease 正文和 appcast description 使用简短 Markdown 链接，并保持 PR 校验可解析。
- 允许修改路径：`changelog/2.23.0.md`、`changelog/README.md`、`scripts/release/release_notes.py`、`scripts/release/tests/test_release_notes.py`、`.agents/skills/release-easydict/scripts/release_content.py`、`.agents/skills/release-easydict/tests/test_release_content.py`、`appcast.xml`、本计划及同任务 history。
- 同任务 history：`docs/histories/2026-09/2026-09-19-changelog-short-links.md`
- 用户限制：同步 2.23.0；不修改 `dev`/`main` 远程分支，不发布新版本，不修改 2.22.0 历史 Release。
- 非目标：不改变 Release 条目分类、版本标题、附件、签名或 Sparkle 版本元数据。
- 验收标准：短链接格式通过静态和行为测试；canonical changelog、远程 Release 正文和 appcast description 一致；本地变更提交完成。

## 工作计划

1. 将 2.23.0 PR、New Contributors 和 Full Changelog 链接改为简短 Markdown 标签。
2. 更新 release notes 和 Draft/Release 内容解析，兼容 Markdown 链接并校验链接标签与 PR 编号一致。
3. 更新 changelog 规范、行为测试和 appcast description。
4. 运行 focused tests、格式检查和远程正文同步，完成最终一致性验证。
5. 更新 history，归档本计划并创建本地提交。

## 风险与决策

- 2.22.0 已发布稳定版本，本次不回写其历史正文或 appcast；规范从本次及后续 changelog 生效。
- `release_notes.py` 保留裸 URL 自动链接兜底，仅对新的 2.23.0 canonical 内容和 PR 条目解析采用短链接格式。
- GitHub Release 正文同步是用户明确“同步改一下”的范围；不触碰 `dev`、`main` 或发布附件。

## 进度

- [x] 更新 2.23.0、解析器、规范和测试。
- [x] 更新本地 appcast 并同步 GitHub Release 正文。
- [x] 完成验证、history 和本地提交。

## 验证

- `python3 scripts/release/tests/test_release_notes.py`：通过，10 tests。
- `python3 .agents/skills/release-easydict/tests/test_release_content.py`：通过，12 tests。
- `python3 scripts/release/tests/test_release_appcast.py`：通过，6 tests。
- `python3 scripts/release/release_notes.py validate --file changelog/2.23.0.md --version 2.23.0`：通过；Markdown SHA-256 为 `8950b793dc242ef003cc0905262ec26b5c919703bdd549bd6f13644f1ee647e5`。
- `python3 .agents/skills/release-easydict/scripts/release_content.py validate-pr-policy --repo tisfeng/Easydict --version 2.23.0 --notes changelog/2.23.0.md`：通过，13 条人工 PR。
- `python3 scripts/release/release_notes.py verify-release --file changelog/2.23.0.md --version 2.23.0 --repo tisfeng/Easydict`：通过，远程正文一致。
- 本地 appcast description 与 `render_markdown(changelog/2.23.0.md)`：一致，16 个短标签，0 个完整 PR URL 作为显示文本。
- `git diff --check`、Python 编译检查：通过。
- 远程 `main/appcast.xml`：仍保留旧正文；按用户范围未推送 `main`/`dev`，待单独授权集成。

## 完成条件

- 2.23.0 所有 PR/比较链接在展示文本中使用短标签。
- GitHub Release 与 canonical changelog 字节规范化后一致，本地 appcast description 与渲染结果一致。
- 计划归档到 `docs/exec-plans/completed/2026-09/`，history 已记录，且本地提交包含完整范围。
