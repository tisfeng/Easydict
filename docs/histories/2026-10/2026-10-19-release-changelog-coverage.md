## 2026-10-19 | 任务：补全发布日志与 2.25.0 Draft

**Links:** [计划](../../exec-plans/completed/2026-10/2026-10-19-release-changelog-coverage.md)、[Draft](https://github.com/tisfeng/Easydict/releases/tag/untagged-5f8081fab8f091fa4c51)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

修改发布规则以覆盖重要直接提交，本地提交变更，补全 2.25.0 changelog 与 Draft，先不正式发布。

### 变更

- 发布 Skill 改为核查上一个版本 Tag 到发布源码的完整提交范围；PR 与直接提交统一按最终用户行为筛选、去重，保留作者和证据链接。
- 维护指南链接到单一规则来源；补充未发布 Draft 的说明修订约束，要求同步 appcast、冻结哈希与临时分支，保留原安装包和 Tag。
- 2.25.0 收录 DeepL 希伯来语/泰语映射、QR 检测调度与完成时机修复、PR #1361 巴西葡萄牙语映射，保留 Anki Sheet 直接提交；纠正 PR #1336 的 DeepL 客户端说明。
- 在隔离 release/sync-2.25.0 分支追加 94ffd70b0c08dcbe34980d241fd8f60d0881a3f3 并向前推送；仅更新 changelog 与目标 appcast description。
- Draft 正文、候选 appcast、release-notes.json 和 draft-refs.env 已一致。原 ASC run draft-20261018T113918Z-04bf5292 与恢复产物保留。

### 设计意图

内容完整性以冻结的 2.25.0 版本提交为边界，不混入此后 dev 的产品变化。说明修订不重建、不移动 Tag、不替换附件，也不推进公开 appcast。提交链接和哈希检查不代替逐项内容核查。

### 验证

- Skill quick_validate、git diff --check、文档相对链接、canonical changelog validate 和 bot PR policy 均通过；10 个 PR 条目与 3 个直接提交链接合法，直接提交均属于版本范围。
- Anki 中间折叠方案及撤回已按最终 Sheet 行为合并；QR Sendable 编译器修复、常量迁移、版本获取器重构、格式、Debug 配置和发布维护项未单列。
- XML 语义比较确认只修改 2.25.0 description；版本、构建、channel、签名、下载 URL 和旧版本条目保持一致。
- verify-draft、冻结 notes/refs 校验及 local artifact verification 全部通过，包括 ZIP/DMG checksum、签名、stapling、Gatekeeper 与 appcast 校验。
- Release ID 417145629 保持不变，标题/Tag 为 2.25.0、isDraft=true、isPrerelease=true；三项资产 ID、大小、类型、状态、digest 均与备份一致；Tag object 和版本提交保持不变，远程 dev/main 未变。
- Markdown SHA-256：3dab704b3d84f23901348d796b56a82d743d1ee163f9e2f9647c8fe0ebc0e944；HTML SHA-256：56dc9b36a04aaa2cf526080d4070480dd7015ec40a6b83f4e1e2c1a3d5070230。
- Review：核对规则、正文范围与修订操作的身份/引用/备份/失败边界，未发现有效 finding；使用已有渲染和 appcast 工具已足够，无需增加构建或通用同步命令。

### 受影响文件

- `.agents/skills/release-easydict/SKILL.md`
- `.agents/skills/release-easydict/references/release-workflow.md`
- `docs/releases/easydict.md`
- `changelog/2.25.0.md`
- `docs/exec-plans/completed/2026-10/2026-10-19-release-changelog-coverage.md`
- `docs/histories/2026-10/2026-10-19-release-changelog-coverage.md`
- 隔离发布分支的 `appcast.xml`

### 后续事项

- Draft 保持未发布；备份及修订收据保存在 `.tmp/release/2.25.0/state/notes-revision-20261019/`。
- GitHub Release 端点拒绝条件 PATCH，原正文未变；通过紧邻写入的身份/正文/资产/引用复核与仅正文更新恢复，并立即验证。回退不提供服务器原子并发保护，规则已明确限制；[官方条件请求说明](https://docs.github.com/en/rest/using-the-rest-api/best-practices-for-using-the-rest-api#use-conditional-requests-if-appropriate)与实际 HTTP 400 响应一致。未改动已有的已发布版本 sync-notes 实现。

### 后续修正：面向用户的筛选门槛

- 用户明确 QR 调度说明不应收录；前述首次补全中的该条目已撤销。发布 Skill 入口与内容决策现明确区分：人工 PR 通常保留，意义不大的维护 PR 可省略；直接提交只保留重要用户可见变化或真实 UI/交互变化。
- 完整提交范围用于查漏，不能逐条生成日志；内部调度、并发整理、完成时机和警告修正不因 fix/perf 类型自动收录，也不将 UI 代码的纯重构算作 UI 更新。
- 2.25.0 删除 QR 条目，保留 DeepL 希伯来语/泰语支持和 Anki 设置 Sheet 两个直接提交及原 10 个 PR；同步候选 appcast、正文与冻结状态。
- 隔离发布分支提交：876941b0b0b438b72506db910e5ae92b4fd3c46c。新 Draft URL：https://github.com/tisfeng/Easydict/releases/tag/untagged-29b60d398f5899521f58 。数据库 ID 417145629、beta、Tag 与附件均未变化。
- Markdown SHA-256：7167edbed77014ca140b8fd4a1e1bb1340281605ad72d818d34084bfe4571582；HTML SHA-256：cb33bccd914335e8633f76e4d9fe50606ae7e08ac2a23ef3a1f333eb778e3cb3。Skill 格式、changelog、verify-draft、冻结 notes/refs 与 appcast 语义校验通过；规则与修订操作 Review 无有效 finding。
- 本轮起始主目录 dev 为 d4886a7d7 且干净；聊天任务 worktree 停留旧 e9ce80eb8，无法看到上一轮主目录的规则提交。交付时核对干净与祖先关系后快进到本地 dev 新提交；不推送 dev/main。
- 原状态备份和本次收据保存在 `.tmp/release/2.25.0/state/notes-user-facing-20261019/`，未重建或正式发布。
