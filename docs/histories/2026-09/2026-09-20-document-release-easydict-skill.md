## 2026-09-20 | 任务：补充 Easydict 技能发布流程总览

<!-- 文件名：YYYY-MM-DD-<slug>.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-20-document-release-easydict-skill.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `Unknown`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

### 用户请求

调查 Easydict 是否已有技能发布流程文档，并补充一份整体介绍 Apple 账号配置、主要命令和
发布流程的文档。

### 变更

- 新增 `docs/agents/release-easydict.md`，集中说明 `asc` App Store Connect 认证、Developer
  ID 证书与 Team ID、Sparkle Ed25519 Keychain 密钥、GitHub CLI/Git remote 凭据、Draft/Publish/
  Release/Resume、Issue 跟进、发布后 `sync-notes` 和状态目录。
- 在 `docs/agents/skills.md` 与 `scripts/release/README.md` 增加总览入口。
- 将执行计划归档到 `docs/exec-plans/completed/2026-09/`。

### 设计意图

保留 `docs/agents/skills.md` 的受管 Skill 来源职责和 `scripts/release/README.md` 的脚本细节，
新增文档只承担面向执行者的导航与凭据边界。明确新版 `asc workflow` 与 legacy `notarytool`
路径的区别，不在仓库记录任何真实密钥，也不改变发布脚本或远程发布行为。

### 验证

- `bash -n scripts/release/*.sh`：通过。
- `python3 -m py_compile scripts/release/release_notes.py scripts/release/release-notes-sync.py scripts/release/release-appcast.py`：通过。
- 变更文档的相对 Markdown 链接检查：通过。
- `git diff --check`：通过。
- 未执行 Xcode 构建、Archive、公证、GitHub Release 或 Issue 远程写入。

### 受影响文件

- `docs/agents/release-easydict.md`
- `docs/agents/skills.md`
- `scripts/release/README.md`
- `docs/exec-plans/completed/2026-09/2026-09-20-document-release-easydict-skill.md`

### 后续事项

- None
