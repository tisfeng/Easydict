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
