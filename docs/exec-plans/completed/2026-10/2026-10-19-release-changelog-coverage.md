# 补全发布日志覆盖范围与 2.25.0 Draft

- 状态：completed
- 创建日期：2026-10-19
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

## 背景

发布规则以已合并 PR 为候选来源，未要求核查版本范围中的直接提交，造成 2.25.0 日志遗漏。

## 目标与范围

- 目标结果：规则覆盖完整提交范围中的重要用户可见变化，补全 2.25.0 canonical changelog 和 Draft。
- 允许修改路径：发布 Skill 规则、发布维护指南、changelog/2.25.0.md、本任务 plan/history，以及隔离发布分支的日志和 appcast description。
- 同任务 history：`docs/histories/2026-10/2026-10-19-release-changelog-coverage.md`
- 用户限制：本地提交；先不要正式发布。
- 非目标：更新应用源码、构建、Tag、附件、公开 appcast 或远程 dev/main；Issue 跟进。
- 验收标准：重要直接提交和遗漏 PR 已收录；Draft、候选 appcast、冻结哈希一致，原资产和 Tag 不变。

## 工作计划

1. 核对 2.24.0 到 2.25.0 冻结源码的提交、PR 与最终代码变化。
2. 更新生成规则与 changelog，预览正文和 appcast description 差异。
3. 备份原 Draft 和本地状态；仅同步说明、临时分支与冻结状态。
4. 验证、审查、记录 history，归档计划并本地提交。

## 风险与决策

- 首次写入前主目录 dev 为 d55d0ee0e7600611765961e2db5b87325a262d38，工作树与索引干净。
- 当前任务 worktree 停留在旧快照；本次直接在保存真实 Draft 状态的主目录执行，避免使用旧 changelog。
- 仅审查冻结版本 8035d9784c31dc1d8bf21fda9db379769361858a 的内容，排除等待期间的新 dev 产品提交。
- 说明修订必须同步本地候选 appcast 与 Draft frozen refs，保留旧状态备份；发生并发或部分失败时停止并报告，不改写安装包或 Tag。

## 进度

- [x] 确认冻结范围、原 Draft 和干净工作树。
- [x] 完成规则、changelog 和修订候选。
- [x] 完成远端与本地冻结状态同步。
- [x] 验证并记录交付。

## 验证

- 已读取完整非 merge 提交列表与遗漏项 diff。
- 原 Draft 标题 2.25.0，beta，三个附件 uploaded，原 ASC run 为 ok。

## 完成条件

- 所有范围内的重要用户可见变化都有 PR 或 commit 证据，排除项不重复列出。
- Draft 与 canonical notes、候选 appcast、哈希一致；Tag/附件保持不变。
- 记录结果和恢复路径，完成本地提交，不正式发布。

## 完成记录

- 已更新项目专属发布 Skill 与维护指南：以完整版本提交范围为候选，结合 PR、最终 diff 和重要直接提交，去重并排除撤回方案及内部维护项。
- 2.25.0 保留 Anki 设置 Sheet 的直接提交，新增 DeepL 希伯来语/泰语支持与 QR 调度/完成时机修复，补录 PR #1361；纠正 PR #1336 的 DeepL 客户端说明。
- QR Sendable 编译器修复不单列；Anki 折叠方案及撤回提交由最终 Sheet 条目覆盖；常量迁移、版本获取器重构、格式、Debug 更新源和发布维护项未单列。
- 隔离发布分支追加 94ffd70b0c08dcbe34980d241fd8f60d0881a3f3，只修改 changelog 与目标 appcast description；Tag、构建 68、beta 和三项资产不变。
- GitHub 条件 PATCH 明确返回 HTTP 400，端点不支持条件写入；核对原正文和身份无变化后，紧邻写入复核并通过 gh release edit 仅更新正文，随后完成全部核验。此回退没有服务器原子并发保护，规则与审计状态已如实记录。
- 原 ASC run ID draft-20261018T113918Z-04bf5292 保留；备份及修订收据位于 .tmp/release/2.25.0/state/notes-revision-20261019/。
- Markdown SHA-256：3dab704b3d84f23901348d796b56a82d743d1ee163f9e2f9647c8fe0ebc0e944；HTML SHA-256：56dc9b36a04aaa2cf526080d4070480dd7015ec40a6b83f4e1e2c1a3d5070230。
- 新 Draft URL：https://github.com/tisfeng/Easydict/releases/tag/untagged-5f8081fab8f091fa4c51 。GitHub 编辑正文后生成新的草稿 URL，数据库 ID 417145629 保持不变。
- Skill 校验、changelog 格式及 bot PR policy、冻结 notes/refs 校验、verify-draft 和 local artifact verification 通过；Review 未发现有效 finding。
- 未重建、移动 Tag、改写附件、推送 dev/main、正式发布或处理 Issue。

## 用户筛选规则修正

- 用户指出 QR 调度/结果交付属于内部实现，不适合用户更新日志；前一版将其收录的判断撤销。
- 本轮起始主目录 dev 为 d4886a7d74ae52df0627358c85648a446bd5657c，工作树与索引干净。
- 发布 Skill 入口明确写入人工 PR 通常收录、无意义维护 PR 可省略；直接提交仅收录重要用户可见变化或真实 UI/交互变化。完整提交范围只用于查漏，fix/perf 类型不作为收录依据。
- 移除 QR 条目，保留 DeepL 新增语言支持与 Anki Sheet UI 两项直接提交；原 10 个 PR 条目保持。
- Draft 修订提交 876941b0b0b438b72506db910e5ae92b4fd3c46c，仅更新 changelog 与目标 description；备份保存在 .tmp/release/2.25.0/state/notes-user-facing-20261019/。
- 新 Markdown 哈希：7167edbed77014ca140b8fd4a1e1bb1340281605ad72d818d34084bfe4571582；HTML 哈希：cb33bccd914335e8633f76e4d9fe50606ae7e08ac2a23ef3a1f333eb778e3cb3。
- Draft、冻结 notes/refs、候选 XML 语义和 Skill 格式校验通过；Tag/资产/远程 dev/main 不变，仍未正式发布。
- 聊天任务 worktree 起始停在旧 e9ce80eb8，导致这里看不到此前主目录的技能修改；交付时确认干净及祖先关系后快进到本地 dev 的新规则提交。
