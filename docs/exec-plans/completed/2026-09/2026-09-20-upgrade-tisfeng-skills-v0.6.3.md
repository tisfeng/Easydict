# 升级 `tisfeng/skills` 至 v0.6.3

- 状态：completed
- 创建日期：2026-09-20
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/skills/releases/tag/v0.6.3

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

Easydict 当前固定使用 `tisfeng/skills v0.6.2`，上游已发布 v0.6.3，需要同步六个外部受管 Skill。

## 目标与范围

- 目标结果：六个受管 Skill、lock 和来源基线固定到 v0.6.3。
- 允许修改路径：六个 `.agents/skills/` 受管目录、`skills-lock.json`、`docs/agents/skills.md`、本任务 plan/history。
- 同任务 history：`docs/histories/2026-09/2026-09-20-upgrade-tisfeng-skills-v0.6.3.md`
- 用户限制：不修改 SelectedTextKit；不添加测试；不 push、不创建 PR、不发布、不 rebase 或 merge。
- 非目标：不修改 `fireworks-tech-graph`、`release-easydict`、产品代码或运行时资产。
- 验收标准：六个目录与 v0.6.3 一致，lock 和来源说明同步，保护路径保持不变，并创建独立本地提交。

## 工作计划

1. 用固定安装器从 v0.6.3 tag 同步六个完整 Skill 目录。
2. 更新来源基线、plan/history，保护项目专属与第三方 Skill。
3. 完成受管 Skill 测试、静态检查、快照核验和本地 review 后创建本地提交。

## 风险与决策

- 使用已发布 tag，不使用 `main` 或未发布提交。
- 安装器只选择 `tisfeng/skills` 的六个 Skill，不覆盖其他来源或项目专属目录。
- 已解决的本地/远端分叉不再作为本任务前置条件，当前 HEAD 与 `origin/dev` 已对齐。

## 进度

- [x] 同步受管目录和 lock。
- [x] 更新来源、验证并审查完整任务差异。
- [x] 写入 history、归档 plan 并创建本地提交。

## 验证

- 六个受管目录逐文件匹配 v0.6.3 tag tree，独立重算的目录 hash 与 lock 和 tag 一致。
- `git-commit` 19 项现有测试、Python 语法、lock JSON、Skill YAML、保护路径和 `git diff --check` 通过。
- 本地 review 无 P0-P3 finding；不新增测试，未运行与 Skill 快照升级无关的 Xcode 构建。

## 完成条件

- [x] 六个受管目录、lock 和来源基线统一到 v0.6.3。
- [x] 必要验证和 review 通过，项目专属 Skill 与第三方 Skill 未被修改。
- [x] plan 归档，history 与依赖更新一起提交。
