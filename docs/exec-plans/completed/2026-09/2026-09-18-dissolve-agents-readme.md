# 拆分移除 docs/agents/README.md

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

`docs/agents/README.md` 承载文档分层、Plan 与 History、文档维护和外部 Skill 资产四块规则，
其中部分条款与根 `AGENTS.md` 重复，而各目录 README 目前只是指向它的指针。用户要求将其拆分
移除，规则就近下沉到对应目录 README 或专题文档。

## 目标与范围

- 目标结果：删除 `docs/agents/README.md`，每条规则按映射表迁移到新位置或以重复为由删除，
  全仓库保持零死链。
- 允许修改路径：`AGENTS.md`、`docs/agents/`、`docs/exec-plans/`、`docs/histories/`、
  `docs/design-docs/` 下的治理 Markdown 及受影响档案链接。
- 同任务 history：`docs/histories/2026-09/2026-09-18-dissolve-agents-readme.md`
- 用户限制：外部 Skill 资产规则新建 `docs/agents/skills.md` 承载；档案链接同步批量更新；
  不 push。
- 非目标：不修改规则语义，只迁移位置；不改产品代码和公共用户文档。
- 验收标准：原 README 每条条款都有明确去向；全 docs + `AGENTS.md` 的相对链接与锚点校验
  零失败；`git diff --check` 通过。

## 工作计划

1. 重写 `docs/histories/README.md`（吸收 history 规则与共享命名/slug）和
   `docs/exec-plans/README.md`（吸收 plan 规则），新建 `docs/agents/skills.md`。
2. 更新 `AGENTS.md` 执行前链接、任务路由和通用规则；翻转
   `docs/design-docs/external-agent-assets-management.md` 指针；更新两个模板的命名注释。
3. 核对档案中对 `docs/agents/README.md` 的引用，修复
   `2026-09-18-agents-md-links.md` 的 `../../AGENTS.md` 死链。
4. 运行全库链接与锚点校验、覆盖核对和 `git diff --check`，使用 review 技能审查。
5. 归档计划，更新 history，创建本地提交。

## 风险与决策

- 外部 Skill 资产规则新建 `docs/agents/skills.md` 而非并入 design doc，保持
  「现行规则在 docs/agents/、设计理由在 design-docs/」分层（用户已确认）。
- 共享命名与 slug 规则放 `histories/README.md`：每个产生差异的任务必读 history 规则，
  plan README 链接过去，避免复制条款。
- 档案引用经核实全部是正文而非 Markdown 链接，按「只动链接不动正文」原则无需改动，保持
  档案零死链。
- 删除的条款均为已确认重复（AGENTS.md 原文、执行模式步骤或 build-and-test.md 对应条款）。

## 进度

- [x] 重写两个目录 README 并新建 skills.md。
- [x] 更新 AGENTS.md、design doc 指针和模板注释。
- [x] 核对档案引用并修复 2026-09-18 死链。
- [x] 链接校验、覆盖核对、静态检查与 review 通过。
- [x] 归档计划并创建本地提交。

## 验证

- 全库链接与锚点校验（`docs/` 全部 Markdown 与 `AGENTS.md`，120 个链接）：零失败。
- 覆盖核对：原 README 各章节关键条款在新位置全部命中，删除条款均有已确认的重复承载。
- review：2 个 P3 finding（exec-plans README 复述共享 slug 条款、AGENTS.md 换行断词）
  已修复并增量复验，修复后校验仍零失败。
- `git diff --check`：通过。
- `xcodebuild`：未运行；本任务只修改仓库治理 Markdown。

## 完成条件

- [x] `docs/agents/README.md` 已删除，映射表条款全部落地。
- [x] 全 docs + `AGENTS.md` 链接与锚点校验零失败。
- [x] review 通过后 history 已记录结果，计划归档并创建本地提交。
