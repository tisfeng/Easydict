# 拆分移除 docs/agents/README.md 的后续：Skill 文档整合

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

Skill 管理内容散落在 `docs/agents/skills.md`（操作规则）、
`docs/design-docs/external-agent-assets-management.md`（设计理由）和
`docs/references/tisfeng-skills.md`、`docs/references/fireworks-tech-graph.md`（来源基线）
四个文件，且 `tisfeng-skills.md` 记录了每个版本升级的变动和带日期的验证日志。用户要求
简化集中为一个文档管理，版本流水账不再保留。

## 目标与范围

- 目标结果：`docs/agents/skills.md` 成为 Skill 管理唯一文档（背景与设计、操作规则、两个
  来源基线），删除另外三个文件，相关索引与路由同步收窄。
- 允许修改路径：`AGENTS.md`、`docs/agents/skills.md`、`docs/references/`、
  `docs/design-docs/`、同任务 plan 与 history。
- 同任务 history：`docs/histories/2026-09/2026-09-18-consolidate-skills-docs.md`
- 用户限制：不保留版本升级流水账；不 push。
- 非目标：不改受管快照、`skills-lock.json` 和任何 Skill 脚本；档案正文不动。
- 验收标准：持久规则与当前基线数据全部保留（映射表核对），一次性过程记录删除；全 docs +
  `AGENTS.md` 链接与锚点校验零失败；`git diff --check` 通过。

## 工作计划

1. 重写 `docs/agents/skills.md`：合并设计理由为「背景与设计」，保留操作规则，按来源基线
   精简 `tisfeng/skills` 与 `fireworks-tech-graph` 两章。
2. 删除 `tisfeng-skills.md`、`fireworks-tech-graph.md`、
   `external-agent-assets-management.md`；更新 `references/README.md`、
   `design-docs/README.md` 和 `AGENTS.md` 路由行。
3. 全库链接与锚点校验、覆盖核对、`git diff --check`，review 审查。
4. 归档计划，更新 history，创建本地提交。

## 风险与决策

- fireworks-tech-graph 基线一并并入 skills.md（用户确认方案），`references/` 收窄为纯外部
  证据目录。
- 版本升级流水账、Codex 子代理移除叙事和日期化验证日志属于过程记录，histories 已有记载，
  参考文档只保留当前基线和持久注意事项。
- 上游仓库级格式校验边界是持久注意事项，压缩保留；Icon? 事故叙事压缩为一句可执行教训。
- lock 记录「来源、ref、入口路径」的精确性和「不维护根 skills/ 兼容别名」边界在覆盖核对
  与 review 中补回，压缩不损失规则语义。

## 进度

- [x] 重写 skills.md 为四章节单一文档。
- [x] 删除三个文件并更新索引、路由。
- [x] 链接校验、覆盖核对、静态检查与 review 通过。
- [x] 归档计划并创建本地提交。

## 验证

- 全库链接与锚点校验（`docs/` 全部 Markdown 与 `AGENTS.md`，116 个链接）：零失败。
- 覆盖核对：16 项持久条款与基线数据在新文档全部命中；版本流水账（v0.3.5–v0.6.0）确认
  未残留。
- review：1 个 P3 finding（fireworks 基线丢失「不维护根 `skills/` 兼容别名」边界）已修复
  并增量复验。
- `git diff --check`：通过。
- `xcodebuild`：未运行；本任务只修改仓库治理 Markdown。

## 完成条件

- [x] Skill 管理只由 `docs/agents/skills.md` 一个文件承载，三个旧文件已删除。
- [x] 全 docs + `AGENTS.md` 链接与锚点校验零失败。
- [x] review 通过后 history 已记录结果，计划归档并创建本地提交。
