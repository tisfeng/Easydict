# Easydict 发布与维护指南

本文是 Easydict 发布维护者的唯一开发者指南，覆盖本地环境、Apple 账号与签名凭据、
Git/GitHub 配置、发布模型、主要命令、恢复和发布工具维护。本文不保存真实密钥，也不替代
发布脚本的安全检查。

标准入口是 `release-easydict` Skill。只有在人工诊断、维护发布工具或需要单独执行底层阶段时，
才直接调用仓库脚本。除非明确指定 `stable`，发布默认使用 `beta` channel。

## 发布动作速查

在支持 Skills 的 Agent 中调用 `release-easydict`，并提供动作和版本号：

| 目的 | Skill 动作 | 结果 |
| --- | --- | --- |
| 创建 Draft 并停下检查 | `draft <version>` | 准备产物、创建并验证 GitHub Draft，不公开发布 |
| 替换同版本 Draft | `draft <version> --replace-draft` | 废弃符合条件的最新 Draft，并从最新本地 `dev` 重建 |
| 发布已有 Draft | `publish <version>` | 公开 Release、推广 appcast、验证远程状态并处理 Issue 跟进 |
| 完成整个发布 | `release <version>` | 依次执行 Skill 的 `draft` 和 `publish` |
| 恢复发布流程 | `resume <version-or-run-id>` | 只继续已有发布运行，不开始新的 Draft 或替换 |
| 预览已发布日志同步 | `sync-notes <version>` | 比较 changelog、Release 正文和 appcast，不写远程 |
| 执行已发布日志同步 | `sync-notes <version> --execute` | 只同步 Release 正文和 appcast description |
| 规划发布后 Issue 动作 | `issue-followup plan <version>` | 生成本地计划，不评论或关闭 Issue |
| 执行/恢复 Issue 动作 | `issue-followup apply\|resume <version>` | 通知并关闭符合策略的 Issue；PR 只评论、不关闭 |

底层脚本的统一入口是：

```bash
./.agents/skills/release-easydict/scripts/release-easydict.sh <action> <version> [options]
```

| 目的 | 命令 | 外部写入 |
| --- | --- | --- |
| 只预览工作流 | `release-easydict.sh release <version> --dry-run` | 无 |
| 只准备本地产物 | `release-easydict.sh prepare <version>` | Apple 公证请求；不写 Git/GitHub |
| 创建 Draft 并停止 | `release-easydict.sh draft <version>` | 临时发布分支、版本 Tag、GitHub Draft |
| 发布已验证 Draft | `release-easydict.sh publish <version>` | GitHub Release、appcast、远程分支 |
| 一次完成底层工作流 | `release-easydict.sh release <version>` | 包含 Draft 和 Publish 的全部写入 |
| 恢复中断的工作流 | `release-easydict.sh resume <run-id>` | 继续原运行，不能替代新的 Draft 或 Publish |

表中命令省略了共同路径前缀 `./.agents/skills/release-easydict/scripts/`。常用参数：

- `--channel stable`：发布稳定版；分阶段执行时，`draft` 和 `publish` 必须使用相同 channel。
- `--build-number <value>`：指定构建号；必须高于公开 appcast 的最新构建号。
- `--force-clean`：在 `prepare`、`draft` 或 `release` 中强制 clean Archive；普通流程优先
  复用兼容的 Release DerivedData，增量 Archive 失败时自动 clean 重试。
- `--replace-draft`：仅用于明确替换当前最新 Draft，不能与 `--build-number` 同用。
- `--dry-run`：只预览 `asc workflow`，不执行步骤。

## 发布架构与 Git 模型

发布由 `asc workflow` 编排，把构建、公证、打包、GitHub 和 Sparkle 拆成可恢复的检查点。
`dev` 仍是日常开发分支；流程只使用已提交的本地 `dev`，发布自动化自身的代码也必须已提交
并存在于合并后的历史中。

1. 记录当前 checkout；当前分支、暂存区和未提交修改保持不变。
2. 获取 `origin/dev`、`origin/main` 和各个 Tag。
3. 从本地 `dev` 创建 detached 同步 worktree，在其中 fast-forward 或合并 `origin/dev`；
   冲突时保留现场并停止。
4. 从同步后的源提交创建隔离的 `release/sync-<version>` worktree，并合并同步时的
   `origin/main`。
5. 验证并冻结 `changelog/<version>.md`，基于合并结果构建，并生成 Sparkle description。
6. Draft 阶段完成候选 appcast 和 beta predecessor transition，只原子推送
   `release/sync-<version>` 与带注释版本 Tag，不修改 `origin/dev` 或 `origin/main`。
7. Publish 前在另一个隔离 worktree 中合并最新本地 `dev`、`origin/dev` 和版本提交；冲突
   必须在 GitHub Release 公开前解决。
8. Release 公开后，把冻结的 appcast 提交合入集成结果，安全更新本地 `dev`，再使用 lease
   原子更新 `origin/dev`、`origin/main` 和临时发布分支。
9. 远程验证 GitHub 正文、公开 appcast、资产、引用和冻结 changelog 后，删除远程
   `release/sync-<version>`。

这个模型保留本地 `dev` 上尚未推送的提交，同时吸收远程 `dev`，也能带回误合入 `main`
但尚未进入 `dev` 的更改。Draft 不污染主分支；Publish 使用 merge 保留版本提交、appcast
提交和后续开发提交的关系，不 rebase 已发布提交。当前 checkout 在其他分支时保持不变；
本地 `dev` 未被 checkout 时通过引用校验更新，被 checkout 时必须干净且只能 fast-forward。

如果同版本的旧尝试只留下干净、未进入远程发布阶段的临时 worktree，且远程没有版本 Tag，
新的 `prepare`、`draft` 或 `release` 会归档旧 worktree、状态和产物后，从最新本地 `dev`
重建。存在未提交修改、已推送 Tag 或远程发布状态时则保留现场并停止。

## 发布前准备

### 工具

Preflight 会检查 `asc`、`cmp`、`codesign`、`create-dmg`、`curl`、`ditto`、`gh`、`git`、
`hdiutil`、`plutil`、`python3`、`security`、`shasum`、`spctl`、`stat`、`xcodebuild`、
`xmllint` 和 `xcrun`。还需要 Sparkle 的 `generate_appcast`；脚本依次检查
`GENERATE_APPCAST`、`SPARKLE_BIN_DIR`、`PATH` 和 Xcode 已解析的 Sparkle 包产物。

安装固定的 Python 依赖并检查认证：

```bash
python3 -m pip install -r .agents/skills/release-easydict/scripts/requirements.txt
gh auth status
asc auth status --validate
asc auth doctor
```

### App Store Connect API 账号

发布脚本不读取仓库内受 Git 跟踪的 Apple API key，而是使用 `asc` 已配置的 profile。推荐
在 App Store Connect 的 **Users and Access → Integrations → API** 创建 API key，并把凭据
保存在 macOS Keychain。需要准备：

- `Key ID`；
- 团队 API key 的 `Issuer ID`，个人 API key 没有该字段；
- 只能下载一次的 `.p8` 私钥；
- 对应团队的访问权限。

团队 API key 的典型配置命令如下，私钥路径应指向仓库外的安全临时位置：

```bash
asc auth login \
  --name "Easydict Release" \
  --key-id "<KEY_ID>" \
  --issuer-id "<ISSUER_ID>" \
  --private-key "/secure/path/AuthKey_<KEY_ID>.p8"
```

个人 API key 不传 `--issuer-id`，并增加 `--key-type individual`。CI 或不使用 Keychain 时
可用 `--bypass-keychain`，但配置文件和 `.p8` 都是敏感凭据，不得提交仓库。如果 Keychain
被系统阻止，先修复访问；确需绕过时按 `asc` 帮助使用 `ASC_BYPASS_KEYCHAIN=1` 或
`asc auth login --bypass-keychain`。配置后始终运行 `asc auth status --validate`。

同一个 profile 用于 `asc xcode version view/edit`、`asc xcode archive` 和
`asc notarization submit --file ... --wait`。认证通过只表示 API 可用；证书、Team ID 和
Sparkle key 仍由 preflight 独立验证。

### Developer ID 与 Team ID

默认值定义在 `.agents/skills/release-easydict/scripts/release-common.sh`：

```text
RELEASE_TEAM_ID=45Z6V4YD5U
RELEASE_SIGN_IDENTITY=Developer ID Application: Canglong Dai (45Z6V4YD5U)
```

`RELEASE_TEAM_ID` 必须与 `.agents/skills/release-easydict/assets/export-options.plist` 的
`teamID` 相同。证书及私钥应安装在当前 macOS 用户的 Keychain：

```bash
security find-identity -v -p codesigning
```

导出的 App 和 DMG 会检查 `TeamIdentifier`、签名 `Authority` 和安全时间戳。正常发布不需要
覆盖默认值；切换团队或证书时，环境变量、证书、构建签名和 export options 的 `teamID`
必须一起更新。不要把临时值写入共享 shell 配置，也不要提交证书或私钥。

### Sparkle Ed25519 密钥

Sparkle 私钥用于签名 appcast，不是 Apple API key。流程默认从 Keychain 查找：

```text
service: https://sparkle-project.org
account: ed25519
```

临时指定仓库外私钥文件时，只对当前命令设置：

```bash
SPARKLE_PRIVATE_KEY_FILE="/secure/path/sparkle_private_key" \
./.agents/skills/release-easydict/scripts/release-easydict.sh prepare <version>
```

脚本会把它传给 `generate_appcast --ed-key-file`。不要把私钥放进 Git 工作树或日志。

### GitHub CLI 与 Git 远程

GitHub Release 和 API 查询使用当前 `gh` 会话；Tag、临时发布分支和 appcast/分支推送使用
Git remote 自己的 SSH 或 HTTPS 凭据。这两者与 Apple API 账号互相独立。Release 目标默认
是 `tisfeng/Easydict`，正常发布无需修改仓库配置。

## 完整发布流程

### 1. 准备 changelog

`changelog/<version>.md` 是 GitHub Release 正文和 Sparkle 更新说明的唯一 Markdown 来源。
先校验，再把它提交到本地 `dev`：

```bash
python3 .agents/skills/release-easydict/scripts/release_notes.py validate \
  --file changelog/<version>.md \
  --version <version>
```

GitHub Release 标题不写入 changelog。发布开始后，正文和渲染结果的 SHA-256 会被冻结；
后续阶段或恢复时发现漂移会停止。

### 2. 预览或准备产物

只预览准确的检查点：

```bash
./.agents/skills/release-easydict/scripts/release-easydict.sh release <version> --dry-run
```

只构建、签名、公证、打包、生成候选 appcast 并完成本地验证：

```bash
./.agents/skills/release-easydict/scripts/release-easydict.sh prepare <version>
```

`prepare` 使用隔离的 release worktree 和长期 build cache，不修改远程 `dev` 或 `main`。

### 3. 创建 Draft

```bash
./.agents/skills/release-easydict/scripts/release-easydict.sh draft <version> \
  --channel beta
```

Draft 阶段冻结并提交候选 appcast，推送临时分支和版本 Tag，然后创建、验证 GitHub Draft；
不会公开 Release、更新主分支，也不会评论或关闭 Issue。

只有明确要废弃并重建页面最新、同版本、同 channel 且尚未进入公开 appcast 的 Draft 时，
才使用：

```bash
./.agents/skills/release-easydict/scripts/release-easydict.sh draft <version> --replace-draft
```

流程会冻结旧 Draft ID 和 Tag OID，保存旧 GitHub JSON 和本地状态，把构建号设置为旧 Draft、
当前工程和公开 appcast 三者最大值加一。新产物通过签名、公证和本地验证前，旧远程状态保持
不变；切换前还会重新验证 Draft、临时分支和 Tag 未被并发修改。失败后使用输出的 run ID
执行 `resume`，不要再次开始替换或递增构建号。

### 4. 检查并发布

人工确认 Draft 标题、正文、附件、channel 和 changelog 后：

```bash
./.agents/skills/release-easydict/scripts/release-easydict.sh publish <version> \
  --channel beta
```

Publish 先做 merge 预检，再公开 GitHub Release，推广 Draft 阶段冻结的 appcast，更新本地和
远程 `dev`/`main`，验证远程状态并清理临时分支。稳定版必须在创建和发布 Draft 时都传入
`--channel stable`。

### 5. beta 轮换

发布新 beta 时，Publish 会把 feed 中排在当前版本之后的第一条 beta 提升为 stable。例如
发布 2.22.0 beta 时，2.22.0 保留 `sparkle:channel=beta` 且 GitHub Release 保持 prerelease；
2.21.0 移除 Sparkle channel，对应 Release 也移除 prerelease。

上一 beta 在修改任何公开状态前冻结到
`.tmp/release/<version>/state/channel-transition.env`，因此 `resume` 不会根据后来变化的 feed
重新选择。没有上一 beta 时安全跳过；stable 发布不执行轮换。

### 6. 发布后 Issue 跟进

Release 远程验证成功后，Skill 执行：

- `issue-followup plan <version>`：收集 GitHub 证据并生成本地计划，不评论或关闭 Issue；
- `issue-followup apply <version>`：重新生成计划，执行通知并关闭符合策略的 Issue；
- `issue-followup resume <version>`：恢复中断的 Issue 动作。

这些动作只作用于已公开 Release；PR 只评论、不关闭。参数和汇总格式见
[`issue-followup.md`](../../.agents/skills/release-easydict/references/issue-followup.md)。Issue
后续失败不回滚已经发布的 Release 或已完成动作。

### 7. 修订已发布日志

发布完成后只修改 changelog 时，不要重新运行 `resume`、`draft` 或 `publish`：

```bash
./.agents/skills/release-easydict/scripts/release-easydict.sh sync-notes <version>
./.agents/skills/release-easydict/scripts/release-easydict.sh sync-notes <version> --execute
```

第一条只预览；第二条同步已发布 Release 正文和远程 `main/appcast.xml` 的目标 description。
它不重建、不签名、不上传附件，也不修改 Tag、版本号、构建号或 channel。执行要求工作树
干净，并以 Release ETag 和 appcast blob SHA 防止覆盖并发修改；状态保存在
`.tmp/release/<version>/state/notes-sync.json`，可以安全重试。

## 状态、日志与恢复

失败时先保存终端给出的 run ID 和路径，不要手工 rebase、强推或删除现场。修复根因后执行：

```bash
./.agents/skills/release-easydict/scripts/release-easydict.sh resume <run-id>
```

主要位置：

- `.tmp/release/<version>/state/`：版本、正文、构建、Draft、Publish 和恢复状态；
- `.tmp/release/<version>/state/publish-git.env`：Publish 的 Git 集成状态；
- `.tmp/release/<version>/state/issue-followup/`：Issue 候选、决策、计划、汇总和动作状态；
- `.tmp/release/<version>/logs/workflow-<run-id>.json`：`asc` 机器可读结果；
- `.tmp/release/<version>/logs/workflow-<run-id>.log`：完整工作流日志；
- `.tmp/release/<version>/logs/` 中的步骤日志：签名、公证、Gatekeeper、DMG 和导出等高噪声输出；
- `.tmp/release/asc/runs/`：`asc` 原始运行状态；
- `.tmp/release/cache/worktree`：只用于本地 Archive 的长期构建 worktree。

终端只展示人类可读进度、摘要和错误。高噪声命令失败时会给出日志路径和末尾内容。成功发布
只清理隔离的 release worktree；远程临时分支仅在完整远程验证后删除。替换 Draft 成功后还会
清理旧 Draft 的本地备份，失败则保留用于诊断和恢复。

长期构建 worktree 使用带 fingerprint 的 Release DerivedData。兼容缓存会被复用；增量
Archive 失败时，只清理当前 fingerprint 并自动回退一次 clean Archive。缓存命中不降低
签名、公证、stapling、appcast 或远程验证要求。

## 完整 workflow 检查点

底层 `release` 工作流依次执行：

1. 验证工具、凭据、证书、Sparkle 密钥、已提交的 changelog 和配置。
2. 将同步后的本地 `dev` 和远程 `main` 合并到隔离 worktree。
3. 更新并提交 Xcode marketing version 和 build version。
4. 使用 `asc xcode archive` 归档，并使用 `xcodebuild` 导出。
5. 提交 App 公证、staple 公证票据并验证 Gatekeeper。
6. 生成 Sparkle ZIP 和 DMG，对 DMG 公证并 staple。
7. 生成并严格验证候选 `appcast.xml`。
8. 在 Draft 阶段提交 appcast，原子推送临时分支和带注释版本 Tag，不修改 `dev` 或 `main`。
9. 创建并验证包含 ZIP、DMG 和校验和的 GitHub Draft Release。
10. 发布前合并检查最新本地/远程 `dev` 与版本提交。
11. 公开 GitHub Release，并把冻结的 appcast 提交合入集成结果。
12. 安全更新本地 `dev`，并用 lease 原子更新远程 `dev`、`main` 和临时发布分支。
13. 对 beta 发布，把上一 GitHub prerelease 提升为 stable。
14. 验证两代 Release、远程引用、资产和公开 Sparkle feed，再删除临时分支和 worktree。

公开 feed 只在 GitHub Release 发布后更新，因此不会提前宣传不可下载的产物。此前失败会留下
可检查的 Draft 和本地状态，而不是发布一半的 feed。

## 发布实现与文件说明

以下路径都位于 `.agents/skills/release-easydict/`：

- `SKILL.md`：动作路由、授权边界和完成条件。
- `references/release-workflow.md`：Agent 执行 Release 生命周期时必须遵守的决策契约。
- `references/issue-followup*.md`：Issue 跟进流程和决策策略。
- `scripts/asc-workflow.json`：工作流图和检查点。
- `scripts/release-easydict.sh`：稳定命令行入口。
- `scripts/release-common.sh`：路径、发布配置和安全辅助函数。
- `scripts/release-preflight.sh`：环境、凭据和发布状态检查。
- `scripts/release-branch-sync.sh`：发布源 worktree、Draft 临时分支和 Tag 同步。
- `scripts/release-publish-git.sh`：Publish 合并预检、本地 `dev` 更新、lease 推送和清理。
- `scripts/release-redraft.sh` / `scripts/release-redraft-git.sh`：同版本 Draft 的安全替换。
- `scripts/release-build.sh`：版本更新、归档和导出，以及 build cache 管理。
- `scripts/release-package.sh`：公证、ZIP、DMG 和校验和。
- `scripts/release-appcast.sh` / `scripts/release-appcast.py`：Sparkle 生成和严格校验。
- `scripts/release_notes.py`：changelog 校验、快照、确定性渲染和正文比对。
- `scripts/release-notes-sync.py`：预览或同步已发布正文和 appcast description。
- `scripts/release_content.py`：验证并更新 Draft 标题，不编辑正文。
- `scripts/release_issues.py` / `scripts/release_pr_policy.py`：Issue 跟进和统一 PR 过滤策略。
- `scripts/release-github.sh`：幂等 Draft/正式发布和资产验证。
- `scripts/release-verify.sh`：本地产物和最终远程状态验证。
- `scripts/requirements.txt`：固定 Markdown 渲染器依赖。
- `assets/export-options.plist`：Developer ID 导出配置。
- `tests/`：正文、appcast、Git 流程、Draft 替换、Issue、日志同步和缓存等行为测试。

## Fail-closed 条件

遇到以下情况，流程必须停止并保留可恢复现场：

- 发布脚本存在未提交修改，无法证明使用的是可复现工具；
- changelog 缺失、未提交、格式无效、渲染器不匹配、冻结后漂移或与 Release 正文不一致；
- detached dev 同步、release worktree 或 Publish 集成发生合并冲突；
- release worktree 脏，或 checkout 中的本地 `dev` 在 Publish 时有未提交修改；
- 远程 `dev`、`main` 或临时发布分支发生 lease 竞态；
- 已有 Tag 指向其他提交；
- 同名远程资产大小不同；
- 签名、公证、stapling 或 Gatekeeper 验证失败；
- 旧 appcast 条目发生非预期变化；beta 轮换只允许上一条 beta 移除 channel；
- 上一 beta Release 缺失、仍为 Draft 或 promotion 失败；
- GitHub 正文、资产、引用或公开 appcast 的最终远程验证失败。

发布失败时不执行 Issue 动作。Release 已发布而 Issue 后续失败时，不回滚 Release，使用
`issue-followup resume <version>` 继续。

## 修改发布工具后的验证

修改发布 Skill、脚本或 helper 后，至少运行：

```bash
python3 -m unittest discover \
  -s .agents/skills/release-easydict/tests \
  -p 'test_*.py'
bash -n .agents/skills/release-easydict/scripts/*.sh
git diff --check
```

同时运行 Skill 的 `quick_validate.py` 和相对链接检查。`xcodebuild`、Archive、公证及远程
GitHub 写入必须按具体任务单独授权和验证；文档与单元测试通过不等于真实发布通过。
