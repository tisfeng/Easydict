# 同步 Agent 文档重构到三个关联仓库

<!-- 文件名：YYYY-MM-DD-<slug>.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->
<!-- 本模板只用于多步骤、跨模块或高风险的执行任务。 -->

- 状态：completed
- 创建日期：2026-09-18
- 负责人：tisfeng
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `ZCode`
- **Model:** `account:zai-individual-coding-plan/GLM-5.3-Flash`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

Easydict 本轮完成了 agent 文档重构：文件引用链接化、拆分移除 `docs/agents/README.md`（规则
下沉到 exec-plans/histories README 与 skills.md）、Skill 文档整合为单一 skills.md、统一 100 列
排版。Scoco、skills 和 easykol-scout-extension 三个关联仓库仍是旧结构，用户要求同步移植。

## 目标与范围

- 目标结果：三个仓库各自完成同构重构，各仓库按其治理规则创建 plan 与 history 并创建本地
  提交；Easydict 记录本编排任务。
- 允许修改路径：三个仓库的 `AGENTS.md`、`docs/agents/`、`docs/exec-plans/`、
  `docs/histories/`、`docs/references/`、`docs/design-docs/` 治理 Markdown。
- 同任务 history：`docs/histories/2026-09/2026-09-18-sync-agent-docs-refactor.md`
- 用户限制：不 push；保留各仓库专属内容（版本基线、项目专属 Skill、专属路由与边界规则）。
- 非目标：不改受管快照、lock、Skill 脚本和产品代码；不改写档案正文。
- 验收标准：每个仓库删除 `docs/agents/README.md` 并落地同构规则；各自链接与锚点校验零
  失败、正文 ≤100 显示列；`git diff --check` 通过。

## 工作计划

1. Scoco：重写 exec-plans/histories README，新建 skills.md（含 v0.6.1 基线与应用内置 Agent
   文档边界），删除三个旧文档，更新 AGENTS.md 与索引，排版模板注释，验证后交付。
2. easykol-scout-extension：同构移植（v0.6.0 基线、WXT/MV3 专属政策与 fireworks 核对规则）。
3. skills：拆分 README（Plan 与 History 规则下沉、Skill 源码与发现独立成 skills.md、文档维护
   归位），链接化路由，排版模板注释，验证后交付。
4. 每个仓库运行链接与锚点校验、行宽检查、`git diff --check` 和 review。
5. 归档本计划，更新 Easydict history，创建本地提交。

## 风险与决策

- 各仓库基线数据不同（Scoco v0.6.1、easykol v0.6.0、skills 为上游无消费基线），按各自现行
  文档移植，不从 Easydict 复制数据。
- 删除的版本升级流水账和日期化验证日志在各仓库 histories 已有记载，符合用户「不记流水账」
  的决定。
- Scoco 的「应用内置 Agent 文档边界」并入其 skills.md 单独章节，路由合并到 skills.md 一行；
  其 backend 契约文档的权威指针改指 skills.md。
- skills 仓库「纯治理 Markdown 不进入工程、运行时或 Skill 安装载荷」迁入其 build-and-test.md
  的本仓库验证清单；四个 completed 档案的既有路径深度死链顺手修正。

## 进度

- [x] Scoco 完成重构、验证与交付（commit `8eca226fe`）。
- [x] easykol-scout-extension 完成重构、验证与交付（commit `3ebabbcc9`）。
- [x] skills 完成重构、验证与交付（commit `65f0d49e8`）。
- [x] 归档本计划并创建 Easydict 本地提交。

## 验证

- Scoco：104→101 个链接与锚点零失败，19 项持久条款覆盖命中，治理文档 ≤100 列，
  `git diff --check` 通过。
- easykol-scout-extension：112 个链接与锚点零失败，覆盖核对通过，治理文档 ≤100 列，
  `git diff --check` 通过。
- skills：73 个链接与锚点零失败（含修正后档案链接），覆盖核对通过，治理文档 ≤100 列，
  `git diff --check` 通过。
- 移植过程中的移植遗漏（两仓库漏删 agents/README、Scoco 漏改两处权威指针）在验证环节发现
  并修复；Scoco 未完成的首次提交被软重置后重新提交为完整范围。
- `xcodebuild`：未运行；全部变更仅为治理 Markdown。

## 完成条件

- [x] 三个仓库 `docs/agents/README.md` 均已删除，规则同构落地且专属内容保留。
- [x] 各仓库链接与锚点校验零失败，正文 ≤100 显示列。
- [x] 各仓库 history 已记录、计划已归档、本地提交已创建。
