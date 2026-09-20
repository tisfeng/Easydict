# Easydict 发布指南

本文面向 Easydict 发布维护者，介绍如何准备本地发布环境、配置 Apple 账号与签名凭据，
以及执行 beta/stable 发布。本文不保存任何真实密钥，也不替代发布脚本中的安全检查。

推荐通过 `release-easydict` Skill 发起发布；需要人工诊断或单独运行某个阶段时，再使用仓库
脚本。脚本实现细节见 [`scripts/release/README.md`](../../scripts/release/README.md)。

## 使用发布 Skill

在支持 Skills 的 Agent 中调用 `release-easydict`，并提供动作和版本号：

| 目的 | Skill 动作 | 结果 |
| --- | --- | --- |
| 创建 Draft 并停下检查 | `draft <version>` | 准备产物、创建并验证 GitHub Draft，不公开发布 |
| 发布已有 Draft | `publish <version>` | 公开 Release、推广 appcast、验证远程状态并处理 Issue 跟进 |
| 完成整个发布 | `release <version>` | 依次执行 `draft` 和 `publish` |
| 恢复发布流程 | `resume <version-or-run-id>` | 只继续已有发布运行，不开始新的 Draft 或替换 |
| 预览已发布日志同步 | `sync-notes <version>` | 比较 changelog、Release 正文和 appcast，不写远程 |
| 执行已发布日志同步 | `sync-notes <version> --execute` | 只同步 Release 正文和 appcast description |
| 规划发布后 Issue 动作 | `issue-followup plan <version>` | 生成本地计划，不评论或关闭 Issue |
| 执行/恢复 Issue 动作 | `issue-followup apply|resume <version>` | 通知并关闭符合策略的 Issue；PR 不会被关闭 |

除非明确指定 `stable`，发布默认使用 `beta` channel。`draft`、`publish`、`release`、恢复、
日志同步和 Issue 跟进都有不同的外部写入边界；执行前应明确动作和目标版本。

## 手动运行底层脚本

Easydict 当前主流程由 `asc workflow` 编排，仓库脚本入口是：

```bash
./scripts/release/release-easydict.sh <action> <version> [options]
```

常规发布顺序是：准备并验证本地产物 → 创建 GitHub Draft → 人工检查 → 发布 Draft →
验证 appcast、Git 引用和 Release → 执行发布后的 Issue 跟进。

| 目的 | 命令 | 是否产生外部写入 |
| --- | --- | --- |
| 只预览工作流 | `./scripts/release/release-easydict.sh release <version> --dry-run` | 否 |
| 只准备本地产物 | `./scripts/release/release-easydict.sh prepare <version>` | 本地 worktree、Archive 和临时状态 |
| 创建 Draft 并停止 | `./scripts/release/release-easydict.sh draft <version>` | 临时发布分支、版本 Tag、GitHub Draft |
| 发布已验证 Draft | `./scripts/release/release-easydict.sh publish <version>` | GitHub Release、appcast、远程分支 |
| 一次完成 Draft + Publish | `./scripts/release/release-easydict.sh release <version>` | 同时包含以上写入 |
| 恢复中断的工作流 | `./scripts/release/release-easydict.sh resume <run-id>` | 继续原运行，不能替代新的 Draft/Publish |

默认 channel 是 `beta`。稳定版必须在同一阶段显式传入 `--channel stable`；`publish` 时要
使用与创建 Draft 相同的 channel。

常用可选参数：

- `--build-number <value>`：指定构建号；必须高于公开 appcast 的最新构建号。
- `--force-clean`：在 `prepare`、`draft` 或 `release` 中强制 clean Archive；普通流程会优先
  复用兼容的 Release DerivedData，增量 Archive 失败时自动 clean 重试。
- `--replace-draft`：仅用于明确替换当前最新 Draft，不能与 `--build-number` 同用。
- `--dry-run`：只预览 `asc workflow`，不执行步骤。

## 发布前需要准备什么

### 工具

主流程会在 preflight 中检查以下命令：`asc`、`xcodebuild`、`xcrun`、`codesign`、
`security`、`spctl`、`create-dmg`、`gh`、`git`、`python3`、`xmllint`、`hdiutil`、
`ditto`、`plutil` 和 `shasum`。还需要 Sparkle 的 `generate_appcast`，它应在 `PATH`、
`SPARKLE_BIN_DIR` 或 `GENERATE_APPCAST` 指定的位置。

Python 依赖使用仓库固定版本：

```bash
python3 -m pip install -r scripts/release/requirements.txt
```

GitHub CLI 和 `asc` 都必须先完成登录，然后用以下命令做最小验证：

```bash
gh auth status
asc auth status --validate
asc auth doctor
```

### Apple / App Store Connect API 账号

当前脚本不会从仓库读取受 Git 跟踪的 Apple API key；它使用 `asc` 已配置的 profile。推荐使用
`asc` 的 Keychain 凭据配置。需要在 App Store Connect 的 **Users and Access → Integrations →
API** 创建 API key，并准备：

- `Key ID`：API key 标识；
- `Issuer ID`：团队 API key 的 issuer，个人 API key 没有该字段；
- 下载一次的 `.p8` 私钥文件；
- 对应团队的访问权限。

团队 API key 的典型设置命令（路径替换为本机临时文件）：

```bash
asc auth login \
  --name "Easydict Release" \
  --key-id "<KEY_ID>" \
  --issuer-id "<ISSUER_ID>" \
  --private-key "/secure/path/AuthKey_<KEY_ID>.p8"
```

个人 API key 不传 `--issuer-id`，并增加 `--key-type individual`。CI 或不使用 Keychain
时可用 `--bypass-keychain`，但配置文件和 `.p8` 都属于敏感凭据，不得提交仓库；完成后仍
要运行 `asc auth status --validate`。如果 Keychain 被系统阻止，优先修复 Keychain 访问，
再按 `asc` 帮助使用 `ASC_BYPASS_KEYCHAIN=1` 或 `asc auth login --bypass-keychain`。

同一个 `asc` profile 被以下步骤复用：

- `asc xcode version view/edit`：读取或更新 Archive 使用的 marketing/build version；
- `asc xcode archive`：执行归档；
- `asc notarization submit --file ... --wait`：提交 App 和 DMG 公证并等待结果。

`asc auth status --validate` 通过只表示 API 认证可用；证书、Team ID 和 Sparkle key 仍由
本地 preflight 单独验证。

### Developer ID 签名证书与 Team ID

当前默认值定义在 `scripts/release/release-common.sh`：

```text
RELEASE_TEAM_ID=45Z6V4YD5U
RELEASE_SIGN_IDENTITY=Developer ID Application: Canglong Dai (45Z6V4YD5U)
```

`RELEASE_TEAM_ID` 必须与 `scripts/release/export-options.plist` 的 `teamID` 相同；导出的
App 和 DMG 的 `TeamIdentifier`、签名 `Authority` 和安全时间戳都会被检查。证书及其私钥应
安装在当前 macOS 用户的 Keychain 中，检查命令是：

```bash
security find-identity -v -p codesigning
```

正常发布不需要覆盖这些默认值。确实切换团队或证书时，必须让环境变量、证书、构建签名
以及 `scripts/release/export-options.plist` 的 `teamID` 一起变更；preflight 会拒绝只改其中
一个值的配置。不要把团队切换临时值写进共享 shell 配置或提交私密证书。

### 公证与 Sparkle Ed25519 密钥

新版主流程使用 `asc notarization submit`，不要求单独设置 `xcrun notarytool` profile。
`release-easydict-legacy.sh` 仍保留旧流程；只有明确运行 legacy 脚本时才需要它提示的
`notarytool` Keychain profile 配置，不要把 legacy 配置混入新版工作流。

Sparkle 的 Ed25519 私钥用于生成签名 appcast，不是 Apple API key。主流程默认从 macOS
Keychain 查找：

```text
service: https://sparkle-project.org
account: ed25519
```

对应的检查由 `release-preflight.sh` 执行。若只需在当前命令中临时指定私钥文件，可以设置：

```bash
SPARKLE_PRIVATE_KEY_FILE="/secure/path/sparkle_private_key" \
./scripts/release/release-easydict.sh prepare <version>
```

脚本会把该文件传给 `generate_appcast --ed-key-file`；不要把私钥放在 Git 工作树或日志中。

### GitHub CLI 与 Git 远程

GitHub Release 和 API 查询使用当前 `gh` 登录会话：

```bash
gh auth status
```

Tag、临时发布分支和 appcast/分支推送则使用 Git remote 自己配置的 SSH 或 HTTPS 凭据；它
与 Apple API 账号、`gh` 会话都是独立的。Release 目标默认是 `tisfeng/Easydict`，正常发布
不需要修改仓库配置。

## 一次发布怎么走

### 1. 准备 changelog

`changelog/<version>.md` 是 GitHub Release 正文和 Sparkle 更新说明的唯一 Markdown 来源。
先校验，再提交到本地 `dev`：

```bash
python3 scripts/release/release_notes.py validate \
  --file changelog/<version>.md \
  --version <version>
```

发布开始后正文和渲染结果会冻结并记录 SHA-256；冻结后修改文件会让后续阶段停止。

### 2. 预览或准备

先看准确的工作流步骤而不执行：

```bash
./scripts/release/release-easydict.sh release <version> --dry-run
```

只构建、签名、公证、打包、生成候选 appcast 并做本地验证：

```bash
./scripts/release/release-easydict.sh prepare <version>
```

`prepare` 会使用隔离 release worktree 和长期 build cache，不修改远程 `dev`/`main`。

### 3. 创建 Draft

```bash
./scripts/release/release-easydict.sh draft <version> \
  --channel beta
```

Draft 阶段会安装并冻结 appcast，推送临时 `release/sync-<version>` 和版本 Tag，然后创建
GitHub Draft；不会公开 Release，也不会执行 Issue 关闭或评论。

只有明确要废弃并重建当前最新 Draft 时才使用：

```bash
./scripts/release/release-easydict.sh draft <version> --replace-draft
```

`--replace-draft` 不能与 `--build-number` 同用；失败后使用输出的 run ID `resume`，不要
重新开始一次替换。

### 4. 检查并发布

确认 Draft 标题、正文、附件、channel 和 changelog 后：

```bash
./scripts/release/release-easydict.sh publish <version> \
  --channel beta
```

Publish 会先做 merge 预检，再公开 GitHub Release，推广冻结的 appcast，更新远程 `dev`/`main`，
验证远程状态并清理临时发布分支。`--channel stable` 只在稳定版发布时使用。

### 5. 发布后的 Issue 跟进

发布验证成功后，`release-easydict` Skill 可以继续处理发布后的 Issue 跟进：

- `issue-followup plan <version>`：收集 GitHub 证据并生成本地计划，不评论或关闭 Issue；
- `issue-followup apply <version>`：重新生成计划并执行通知、评论和符合策略的 Issue 关闭；
- `issue-followup resume <version>`：恢复中断的 Issue 动作。

这些动作只作用于已经公开的 Release；PR 不会被关闭。详细 helper 参数和固定汇总格式见
[`issue-followup.md`](../../.agents/skills/release-easydict/references/issue-followup.md)。

## 发布后修订日志

发布后如果只改了 changelog，不要重新跑 `resume`、`draft` 或 `publish`：

```bash
./scripts/release/release-easydict.sh sync-notes <version>
./scripts/release/release-easydict.sh sync-notes <version> --execute
```

第一条命令只预览差异；第二条命令才写入已发布 Release 正文和远程 `main/appcast.xml`。
`sync-notes` 不重建、不重新签名、不上传附件、不改 Tag 或版本号；`--execute` 要求当前
工作树干净，并使用 ETag/blob SHA 防止覆盖并发修改。

## 失败、恢复与状态

失败时先记录终端输出中的 run ID 和路径，不要手工 rebase、强推或删除现场。常用恢复入口：

```bash
./scripts/release/release-easydict.sh resume <run-id>
```

主要状态位置：

- `.tmp/release/<version>/state/`：版本、正文、构建、Draft、Publish 和恢复状态；
- `.tmp/release/<version>/logs/`：工作流 JSON、详细日志和高噪声步骤日志；
- `scripts/release/runs/`：`asc` 原始运行状态，Git 已忽略；
- `.tmp/release/<version>/state/issue-followup/`：Issue 跟进的冻结候选、决策、计划、汇总和动作状态。

以下情况应停止并修复根因后恢复：凭据或证书校验失败、changelog 或渲染结果漂移、合并冲突、
本地 `dev` 不干净、远程 lease 竞态、Tag 指向不一致、附件或 appcast 校验失败。发布成功但
Issue 后续失败时不回滚 Release，使用 `issue-followup resume <version>` 继续。

## 检查发布工具

修改发布 Skill 或 helper 后，优先运行：

```bash
python3 -m unittest discover \
  -s .agents/skills/release-easydict/tests \
  -p 'test_*.py'
bash -n scripts/release/*.sh
git diff --check
```

`xcodebuild`、Archive、公证和远程 GitHub 写入必须按具体任务单独授权和验证；文档检查通过
不等于真实发布通过。
