# 升级 tisfeng/skills 至 v0.7.2

- 日期：2026-09-27
- 状态：completed
- 关联计划：[升级 tisfeng/skills 至 v0.7.2](../../exec-plans/completed/2026-09/2026-09-27-upgrade-tisfeng-skills-v0.7.2.md)
- 上游 Release：https://github.com/tisfeng/skills/releases/tag/v0.7.2

## 目标

将 Easydict 的六个 tisfeng/skills 受管依赖从 v0.7.0 升级到 v0.7.2；Raycast-Easydict、SelectedTextKit 不在范围。

## 实际变更

- 使用 skills@1.5.25 从固定 v0.7.2 tag 同步六个完整 Skill 目录和 `skills-lock.json`。
- 更新来源基线到 annotated tag object `4040ed8b87a26c8c89530362f285270fd0912b73`、peeled commit `f979c5ddc4e9eab6ae04bad912ed95c7ecdde344`。
- 保留 fireworks-tech-graph、项目专属 Skill、产品代码和运行时资产。

## 验证

- 六个目录逐文件匹配上游 v0.7.2 tree；使用安装器同一 Node `localeCompare` 排序算法重算目录级 SHA-256，六个 hash 均与 lock 一致。
- Easydict 的 `git-commit`、`review`、`review-pr`、`submit-pr`、`worktree-rebase-merge` 现有测试共 119 项通过；JSON、Shell、保护路径和 `git diff --check` 通过。
- 最终差异 review 未发现有效 finding；未运行 Xcode 构建，因为变更不进入 Xcode 构建图。

## 交付

- 本地提交：本次任务创建。
- 未 push、未创建 PR。
