# 升级 tisfeng/skills 至 v0.7.2

- 状态：active
- 创建日期：2026-09-27
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/skills/releases/tag/v0.7.2

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.0 / Xcode 27.2 (27B5019j)`

## 背景

Easydict 当前固定使用 tisfeng/skills v0.7.0，上游将发布 v0.7.2，需要同步六个外部受管 Skill。

## 目标与范围

- 目标结果：六个受管 Skill、lock 和来源基线固定到 v0.7.2。
- 允许修改路径：六个 `.agents/skills/` 受管目录、`skills-lock.json`、`docs/agents/skills.md`、本任务 plan/history。
- 同任务 history：`docs/histories/2026-09/2026-09-27-upgrade-tisfeng-skills-v0.7.2.md`
- 用户限制：不修改 Raycast-Easydict、SelectedTextKit 或产品代码。
- 非目标：不修改 `fireworks-tech-graph`、项目专属 Skill、产品代码或运行时资产。
- 验收标准：六个目录与 v0.7.2 一致，lock 和来源说明同步，保护路径保持不变，并创建本地提交。

## 工作计划

1. 从固定 v0.7.2 tag 安装六个完整 Skill 目录。
2. 更新来源基线、plan/history 并核对独立 Skill 和项目路径。
3. 运行受管 Skill 测试、快照校验和 review，创建本地提交。

## 风险与决策

- 仅同步 tisfeng/skills 的六个 lock-governed Skill，不覆盖其他来源。
- 不手工修改 lock hash，使用安装器生成并独立重算确认。

## 进度

- [x] 同步受管目录和 lock。
- [x] 更新来源、验证并审查差异。
- [x] 写入 history、归档 plan 并创建本地提交。

## 验证

- 六个受管目录逐文件匹配上游 v0.7.2 tag；使用安装器同一 Node `localeCompare` 排序算法重算目录 hash，六个 hash 均与 lock 一致。
- 运行 `git-commit`、`review`、`review-pr`、`submit-pr`、`worktree-rebase-merge` 的现有测试，共 119 个测试通过；运行 JSON、Shell、保护路径检查和 `git diff --check`。
- 最终差异 review 未发现有效 finding；未运行 Xcode/产品构建，因为变更只涉及受管 Skill 与治理文档。

## 完成条件

- 六个目录、lock 和来源基线统一到 v0.7.2。
- 必要验证和 review 通过，项目专属 Skill 与第三方 Skill 未被修改。
- plan 归档，history 与依赖更新一起提交。
