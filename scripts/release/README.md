# Easydict 发布流程

Easydict 的发布流程由 `asc workflow` 编排。该工作流将构建、公证、打包、GitHub
和 Sparkle 等阶段拆分为多个小步骤，支持断点恢复，同时提供一条命令执行完整的发布流程。

旧版单体脚本保留为 `release-easydict-legacy.sh`，可作为临时备用方案使用，但新版工作流不会调用它。

## 发布模型

`dev` 仍然是日常开发分支。发布流程会以本地 `dev` 的已提交内容为基线，在独立的临时 worktree 中合并远程 `dev`，再以同步结果和远程 `main` 的合并结果开始：

1. 记录当前 checkout；当前分支可以是任意分支，当前 worktree、暂存区和未提交修改保持不变。
2. 获取 `origin/dev`、`origin/main` 和各个 Tag。
3. 从本地 `dev` 提交创建 detached 临时 worktree，并在其中将 `origin/dev` fast-forward 或合并到本地 `dev` 源；冲突时暂停并保留该临时 worktree。
4. 记录同步后的源提交，并从该提交创建隔离的 `release/sync-<version>` worktree。
5. 将同步时的 `origin/main` 提交合并到该 worktree。
6. 基于合并后的结果构建并验证。
7. Draft 阶段只将 `release/sync-<version>` 和带注释的版本 Tag 原子推送到远程，
   不修改 `origin/dev` 或 `origin/main`。
8. Publish 前在第二个隔离 worktree 中，将最新本地 `dev`、`origin/dev` 和版本提交
   合并起来；如果冲突，在 GitHub Release 公开前停止。
9. GitHub Release 公开并安装 appcast 后，将 appcast 提交合并到上述集成结果，安全更新
   本地 `dev`，再使用 lease 原子更新 `origin/dev`、`origin/main` 和临时发布分支。
10. 远程验证全部通过后，删除远程 `release/sync-<version>`。

这样可以保留本地 `dev` 上尚未推送的提交，同时吸收远程 `dev` 的更新；也可以找回误合并到 `main`、
但尚未进入 `dev` 的更改。Draft 不会污染远程主分支。Publish 使用 merge 保留版本提交、appcast 提交和
后续开发提交的历史关系，不会 rebase 已发布的提交。当前 checkout 位于其他分支时保持不变；本地 `dev`
未被 checkout 时通过引用校验更新，被 checkout 时则必须保持干净并使用 fast-forward 更新。发布只使用
已提交的本地 `dev`，发布自动化自身的代码也必须已经提交并存在于合并后的历史中。

如果同一版本之前的发布尝试留下了干净但过期的临时 worktree，新的 `prepare`、`draft` 或 `release`
运行会在没有远程版本 Tag 的情况下自动归档旧 worktree、状态和产物，然后从最新的本地 `dev` 重建。
有未提交修改、已推送版本 Tag 或已进入远程发布阶段时，流程会停止并保留现场。

## 首次设置

安装并认证以下工具：

- Xcode 命令行工具和 Developer ID Application 证书。
- [`asc`](https://github.com/rorkai/App-Store-Connect-CLI)。
- [`create-dmg`](https://github.com/sindresorhus/create-dmg)。
- GitHub CLI（`gh`）。
- Sparkle 的 `generate_appcast` 工具，以及保存在 Keychain 中的 `ed25519` 密钥。

工作流要求为 `asc` 配置 App Store Connect API 认证，并通过以下命令验证：

```bash
asc auth status --validate
gh auth status
```

默认情况下，工作流会先从 `PATH` 中查找 `generate_appcast`，然后查找 Sparkle 的 Xcode 包产物。
如果该工具位于其他位置，可以设置 `GENERATE_APPCAST` 指向可执行文件。密钥等机密信息应保存在
Keychain 或工具自身的凭据存储中，不会写入仓库或发布元数据。

## 一条命令发布

在仓库根目录执行：

```bash
./scripts/release/release-easydict.sh release 2.22.0
```

默认发布频道为 `beta`。如果要发布稳定版本：

```bash
./scripts/release/release-easydict.sh release 2.22.0 --channel stable
```

可以指定发布说明文件和构建号：

```bash
./scripts/release/release-easydict.sh release 2.22.0 \
    --notes /absolute/path/release-notes.md \
    --build-number 64
```

如果不指定 `--build-number`，工作流会自动递增 Xcode 构建号。版本号必须高于 Sparkle feed 中的最新版本，
构建号也必须高于 feed 中的最新构建号。

## 更安全的分阶段命令

如果希望在各阶段之间进行人工检查，可以使用较小的工作流：

```bash
# 构建、签名、公证、打包、生成 appcast，并在本地完成验证。
./scripts/release/release-easydict.sh prepare 2.22.0

# 准备发布、同步发布引用，并创建经过验证的 GitHub Draft Release。
./scripts/release/release-easydict.sh draft 2.22.0

# 发布已有的、经过验证的 Draft Release，安装 appcast，并执行远程验证。
./scripts/release/release-easydict.sh publish 2.22.0
```

如果准备发布的是稳定版本，需要在单独执行 `publish` 命令时传入相同的 `--channel stable` 参数。

### 重新创建同版本 Draft

如果最新的 GitHub Release 条目仍是当前版本的 Draft，且该版本尚未进入公开
`appcast.xml`，可以显式废弃旧 Draft 并从最新本地 `dev` 重建：

```bash
./scripts/release/release-easydict.sh draft 2.22.0 --replace-draft
```

该参数只适用于 `draft`，不能与 `--build-number` 同时使用。工作流会冻结旧 Draft
数据库 ID 和 Tag OID，将旧本地状态移入临时恢复目录，并将构建号设置为以下三者
最大值加一：旧 Draft 构建号、当前项目构建号、公开 appcast 最新构建号。旧 Draft
的完整 GitHub JSON 也会随临时恢复状态保留，供失败诊断或人工回滚使用。

新产物完成签名、公证和本地验证前，远端 Draft、临时发布分支和 Tag 保持不变。随后工作流会再次
核对旧 Draft 仍是页面最新条目、内容未被修改，且临时发布分支与 Tag OID 未变化，再使用 lease 原子
替换 `release/sync-<version>` 和版本 Tag，删除精确匹配的旧 Draft，并创建、验证新 Draft。
`origin/dev` 和 `origin/main` 仍要等到 Publish 成功时才更新。
成功后旧工作树、旧产物、旧 skill 状态和临时恢复分支会自动删除；失败时保留临时
恢复目录，并要求使用输出的运行 ID 执行 `resume`，不会再次递增构建号。

### beta 轮换

发布新的 beta 时，`publish` 会自动将 feed 中排在当前版本之后的第一条 beta 提升为 stable。
例如发布 2.22.0 beta 时：

- 2.22.0 的 Sparkle 条目保留 `sparkle:channel=beta`，GitHub Release 保持 prerelease。
- 2.21.0 的 Sparkle 条目移除 `sparkle:channel`，对应 GitHub Release 移除 prerelease。

上一 beta 版本会在修改任何公开状态前写入 `.tmp/release/<version>/state/channel-transition.env`。
因此失败后的 `resume` 会继续使用同一个上一版本，不会根据后来变化的 feed 重新选择。没有上一 beta
时该步骤安全跳过；`--channel stable` 保持原有行为，不执行 beta 轮换。

只预览确切的 `asc` 执行计划而不执行发布步骤：

```bash
./scripts/release/release-easydict.sh release 2.22.0 --dry-run
```

## 失败后恢复

`asc` 会将运行状态记录在 Git 忽略的 `scripts/release/runs/` 目录下。修复临时问题后，使用 `asc` 输出的运行 ID
继续执行：

```bash
./scripts/release/release-easydict.sh resume <run-id>
```

发布状态和产物会保存在 `.tmp/release/<version>/` 中，用于审计和恢复。成功发布后只会移除隔离的 Git worktree；
成功完成 `--replace-draft` 后还会移除被替换 Draft 的临时本地备份。Publish 的 Git 集成状态保存在
`state/publish-git.env`；远程临时发布分支只会在完整远程验证后删除。
每个阶段都设计为可以安全重试，或者在替换已有远程资产或 feed 条目之前安全失败。

## 日志和结果

发布命令会把终端输出分成两类：

- 人类可读的进度和错误信息输出到终端，并带有时间、级别和步骤名称。
- `asc` 的机器可读结果 JSON 不再直接铺满终端，而是保存到
  `.tmp/release/<version>/logs/workflow-<run-id>.json`。

详细日志保存在同一目录的 `workflow-<run-id>.log`，以及各个高噪声命令对应的步骤日志中。
签名、公证票据、Gatekeeper、DMG 校验和 `xcodebuild export` 等命令成功时只显示摘要；失败时会显示
日志路径和最后 40 行，便于快速定位。`scripts/release/runs/` 仍然保存 `asc` 的原始运行状态，继续恢复时使用其中的
run ID：

```bash
./scripts/release/release-easydict.sh resume <run-id>
```

## 完整工作流的执行内容

`release` 工作流按以下顺序执行检查点：

1. 验证工具、凭据、证书、Sparkle 密钥、发布说明和配置。
2. 将同步后的本地 `dev` 和远程 `main` 合并到隔离的 worktree。
3. 更新并提交 Xcode 的 marketing version 和 build version。
4. 使用 `asc xcode archive` 归档，并使用 `xcodebuild` 导出。
5. 提交 App 进行公证、写入公证票据，并验证 Gatekeeper。
6. 生成 Sparkle ZIP 和 DMG 产物；对 DMG 进行公证并写入公证票据。
7. 生成并严格验证候选 `appcast.xml`。
8. 原子推送临时发布分支和带注释的版本 Tag，不修改 `dev` 或 `main`。
9. 创建并验证包含 ZIP、DMG 和校验和的 GitHub Draft Release。
10. 发布前将最新本地/远程 `dev` 与版本提交进行 merge 预检。
11. 发布新的 GitHub Release 并安装 appcast，将 appcast 提交 merge 到集成结果。
12. 安全更新本地 `dev`，并使用 lease 原子更新远程 `dev`、`main` 和临时发布分支。
13. 对 beta 发布，将上一 GitHub prerelease 提升为 stable。
14. 验证两代 Release、远程引用、发布资产和公开 Sparkle feed，再删除远程临时分支和本地 worktree。

公开 feed 只有在 GitHub Release 发布后才会更新，因此不会提前宣传不可下载的归档文件。在此之前发生失败时，
流程会留下 GitHub Draft Release 和可恢复的本地状态，而不会留下一个发布了一半的 feed。

## 文件说明

- `asc-workflow.json`：工作流图和各个检查点。
- `release-easydict.sh`：稳定的命令行入口。
- `release-common.sh`：路径、发布配置和安全辅助函数。
- `release-preflight.sh`：本地环境和发布状态检查。
- `release-branch-sync.sh`：发布源 worktree、Draft 临时分支和 Tag 同步。
- `release-publish-git.sh`：Publish merge 预检、本地 `dev` 更新、lease 原子推送和临时分支清理。
- `release-build.sh`：版本更新、归档和导出阶段。
- `release-package.sh`：公证、ZIP、DMG 和校验和阶段。
- `release-appcast.sh` / `release-appcast.py`：Sparkle 生成和严格的 feed 验证。
- `tests/test_release_appcast.py`：beta 轮换和旧条目保护的行为测试。
- `release-github.sh`：幂等的 Draft Release/正式发布和资产验证。
- `release-verify.sh`：本地产物和最终远程状态验证。
- `export-options.plist`：Developer ID 导出配置。

仓库和团队默认值可以通过 `release-common.sh` 中的环境变量覆盖，但正常的 Easydict 发布除了版本号、频道和发布说明外，
通常不需要其他参数。

## 失败行为

- 当前 checkout 中的发布脚本有未提交修改：暂停，避免使用不可复现的发布工具。
- detached dev 同步 worktree 发生合并冲突：暂停并保留临时 worktree，当前 checkout 不受影响。
- release worktree 有脏文件：暂停，并保留现场供检查。
- 发布源中的 `dev`/`main` 合并冲突：在版本更新或 Draft 推送前暂停。
- Publish 集成 worktree 中的 merge 冲突：在 GitHub Release 公开前暂停并保留现场。
- 本地 `dev` 被 checkout 且存在未提交修改：Publish 前暂停，不修改该 worktree。
- Publish 期间远程 `dev`、`main` 或临时发布分支发生竞态更新：lease 阻止推送并保留可恢复状态。
- 已有 Tag 指向其他提交：暂停。
- 已有远程资产但大小不同：暂停，不覆盖原文件。
- 公证或签名失败：在 GitHub 发布前暂停。
- 旧的 appcast 条目出现非预期更改：在安装 feed 前暂停；只允许上一 beta 删除 channel。
- 上一 beta 的 GitHub Release 缺失、仍为 Draft 或 promotion 失败：保留发布状态并暂停，允许恢复。
- 远程验证失败：保留发布目录，等待诊断和恢复。
