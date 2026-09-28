## 2026-09-29 | 任务：更新 Release 标题和 changelog 格式

<!-- 文件名：2026-09-29-release-title-changelog.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->

**Links:** [计划](../../exec-plans/completed/2026-09/2026-09-29-release-title-changelog.md)、[2.24.0 Release](https://github.com/tisfeng/Easydict/releases/tag/2.24.0)、[技能规则提交](https://github.com/tisfeng/Easydict/commit/5a3dfc504fe7df6be51a7cbef32b3e855a831fb8)、[changelog 提交](https://github.com/tisfeng/Easydict/commit/f082ea8e82c1334da6a0a0e3b987af8f833ac874)

### 执行上下文

- **Agent Name:** `/root`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

### 用户请求

先调整发布版本 Skill 的日志格式规则，再将 GitHub 2.24.0 Release 标题改为版本号，并把指定 Copilot CLI 功能作为 changelog 首标题。

### 变更

- Skill 规定 GitHub Release 标题只使用版本号；重点功能使用 changelog 首标题 `# ✨ feat: add GitHub Copilot CLI translation`。
- 新建 Draft 默认标题改为版本号。标题 helper 接受新格式，同时继续兼容旧标题输入。
- `changelog/2.24.0.md` 添加指定首标题，保留现有变更、贡献者和 Full Changelog。
- GitHub Release 标题更新为 `2.24.0`，正文同步 canonical changelog；`main` 和 `dev` 的 2.24.0 appcast 描述同步更新。

### 设计意图

Release 名称只标识版本，重点功能在正文 changelog 中呈现。继续使用 canonical changelog，并同步 Sparkle appcast，保持发布页和应用内更新说明一致。首次 `sync-notes --execute` 的远程 appcast 更新成功，但 Release 正文 PATCH 返回 HTTP 400；确认页面仍是原值后用 `gh release edit` 更新标题与正文，再通过 `sync-notes --execute` 完成无差异复核。

### 验证

- `test_release_content.py`：12 项通过；`test_release_github_notes.py`：1 项通过；未新增或修改测试。
- Python 编译、`bash -n`、Skill `quick_validate.py`、版本号标题手动验证、`git diff --check`：通过。
- `release_notes.py validate`：通过；bot PR policy 有效，6 条人工 PR；Markdown 渲染以指定标题开头。
- GitHub Release：标题与 Tag 均为 `2.24.0`，仍为已发布 beta，正文与 `changelog/2.24.0.md` 完全一致。
- 最终 `sync-notes --execute` 状态为 `completed`；正文与 `main`、`dev` appcast 均已验证一致。远程 `main` 为 `f8445bccd7e8c80bcb00bf85d6b17803cd9d6d20`，`dev` 为 `a67cddf6c6b206846f10cfdd99399f2a8098a736`。
- Review：无 finding。

### 受影响文件

- `.agents/skills/release-easydict/SKILL.md`
- `.agents/skills/release-easydict/references/release-workflow.md`
- `.agents/skills/release-easydict/scripts/release_content.py`
- `.agents/skills/release-easydict/scripts/release-github.sh`
- `changelog/2.24.0.md`

### 后续事项

技能改动保留在本地 `codex/release-title-changelog` 分支；没有 push 该分支。已发布 changelog/appcast 的同步按 `sync-notes` 既定流程更新远端 `main` 和 `dev`。
