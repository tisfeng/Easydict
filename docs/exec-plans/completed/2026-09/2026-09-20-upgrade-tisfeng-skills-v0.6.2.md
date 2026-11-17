# 升级 `tisfeng/skills` 至 v0.6.2

- 状态：completed
- 创建日期：2026-09-20
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/skills/releases/tag/v0.6.2

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `Unknown`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

Easydict 当前固定使用 `tisfeng/skills v0.6.1`，上游已发布 v0.6.2，需要同步六个外部受管 Skill。

## 目标与范围

- 目标结果：六个受管 Skill、lock 和来源基线固定到 v0.6.2。
- 允许修改路径：六个 `.agents/skills/` 受管目录、`skills-lock.json`、`docs/agents/skills.md`、本任务 plan/history。
- 同任务 history：`docs/histories/2026-09/2026-09-20-upgrade-tisfeng-skills-v0.6.2.md`
- 用户限制：不修改 SelectedTextKit；不 push、不创建 PR、不发布。
- 非目标：不修改 `fireworks-tech-graph`、`release-easydict`、产品代码或运行时资产。
- 验收标准：六个目录与 v0.6.2 一致，lock 和来源说明同步，保护路径保持不变。

## 工作计划

1. 用固定安装器从 v0.6.2 tag 同步六个完整 Skill 目录。
2. 更新来源基线、plan/history，保护项目专属与第三方 Skill。
3. 完成本地静态检查和受管快照审查后创建本地提交。

## 风险与决策

- 使用已发布 tag，不使用 `main` 或未发布提交。
- 安装器只选择 `tisfeng/skills` 的六个 Skill，不覆盖其他来源或项目专属目录。

## 进度

- [x] 同步受管目录和 lock。
- [x] 更新来源、history 并完成提交。

## 验证

- 六个受管目录与 `v0.6.2` tag tree 一致，lock 中六个来源 ref 为 `v0.6.2`。
- `git diff --check`、JSON 解析和项目专属/第三方 Skill 保护路径检查通过。

## 完成条件

- [x] 受管目录、lock 和来源基线统一到 v0.6.2。
- [x] 项目专属 Skill 与第三方 Skill 未被修改。
- [x] plan 归档，history 与依赖更新一起提交。
