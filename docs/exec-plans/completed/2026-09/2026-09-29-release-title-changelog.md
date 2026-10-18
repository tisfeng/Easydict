# Release 标题与 changelog 格式调整

- 状态：completed
- 创建日期：2026-09-29
- 负责人：/root
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `/root`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

## 背景

GitHub Release `2.24.0` 的标题含有重点功能摘要，用户希望标题只显示版本号，并把重点功能作为 canonical changelog 的标题。当前发布技能文档、Draft 标题 helper 和新建 Release 默认标题仍沿用旧格式。

## 目标与范围

- 目标结果：技能规则和执行 helper 使用版本号作为 Release 标题；重点功能作为 changelog 首标题；2.24.0 页面与 canonical changelog 一致。
- 允许修改路径：`.agents/skills/release-easydict/`、`changelog/2.24.0.md`、本计划与配套 history。
- 同任务 history：`docs/histories/2026-09/2026-09-29-release-title-changelog.md`
- 用户限制：先更新技能规则，再单独修订 GitHub 2.24.0；不重建版本、不改 Tag 或附件。
- 非目标：重新构建或发布 app、改动 release 资产、处理 Issue、push 任务分支。
- 验收标准：新规则、默认 Release 创建标题及 Draft 标题校验支持版本号格式；2.24.0 changelog 以指定标题开头；已发布 Release 标题为 `2.24.0`，正文及 appcast 描述与 canonical changelog 一致。

## 工作计划

1. 更新发布技能说明、工作流规则、Draft 标题 helper 和 Release 创建默认标题；运行现有针对性验证并审查改动。
2. 将 `# ✨ feat: add GitHub Copilot CLI translation` 加入 `changelog/2.24.0.md`，保留其余条目；验证 canonical notes。
3. 预览 `sync-notes 2.24.0`，执行正文和 appcast 同步；将 GitHub Release 标题设为 `2.24.0`。
4. 复核 GitHub Release、appcast、Git 状态，补全 history 并归档本计划。

## 风险与决策

- 已发布日志通过 `sync-notes --execute` 更新时，还会更新远程 `main`/`dev` appcast 与本地分支；这是保持 canonical changelog 一致所需的既定流程。
- `sync-notes --execute` 要求当前工作树干净并使用 ETag、branch head 和 push lease；如并发校验失败，重新读取并预览，不绕过保护。
- 现有标题 helper 曾接受旧格式；保持旧输入兼容，同时把规则和新建 Release 默认值改为版本号，避免破坏旧 Draft 的恢复能力。

## 进度

- [x] 更新技能与标题 helper，验证并审查。
- [x] 更新并提交 2.24.0 canonical changelog。
- [x] 同步已发布日志与 appcast，并修改 Release 标题。
- [x] 验收远端状态，记录 history，归档计划。

## 验证

- `test_release_content.py`（12 项）、`test_release_github_notes.py`（1 项）：通过；未新增或修改测试。
- `python3 -m py_compile .agents/skills/release-easydict/scripts/release_content.py`、
  `bash -n .agents/skills/release-easydict/scripts/release-github.sh`、Skill `quick_validate.py`、
  版本号标题手动验证及 `git diff --check`：通过。
- `release_notes.py validate --file changelog/2.24.0.md --version 2.24.0`：通过；bot PR policy 有效，6 条人工 PR；渲染结果以指定 H1 开头。
- Review：无 finding。
- `sync-notes --execute` 首次完成远程 `main`/`dev` appcast 更新，但 GitHub Release 正文 PATCH 返回 HTTP 400。随后 `gh release edit` 更新标题和正文；再次预览显示 Release 正文和 appcast 均无差异，`sync-notes --execute` 最终状态为 `completed` 并验证正文及两个 appcast。
- 最终 GitHub Release 核验：标题/tag 均为 `2.24.0`，仍为已发布 beta，正文与 canonical changelog 完全一致。远程 `main`/`dev` 已核验到同步提交。

## 完成条件

- 规则和 helper 的行为符合版本号 Release 标题约定。
- 2.24.0 的 Release 标题和 canonical changelog 已核验；appcast 描述与 changelog 一致。
- history 记录结果；计划移动到 `docs/exec-plans/completed/2026-09/`。
