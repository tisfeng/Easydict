# 升级 tisfeng/skills 至 v0.7.0

- 日期：2026-09-27
- 状态：completed
- 关联计划：[升级 tisfeng/skills 至 v0.7.0](../../exec-plans/completed/2026-09/2026-09-27-upgrade-tisfeng-skills-v0.7.0.md)
- 上游 Release：https://github.com/tisfeng/skills/releases/tag/v0.7.0

## 目标

将 Easydict 的六个 tisfeng/skills 受管依赖从 v0.6.3 升级到 v0.7.0；Raycast-Easydict、SelectedTextKit 不在范围内。

## 实际变更

- 使用 skills@1.5.25 从固定 v0.7.0 tag 同步六个完整 Skill 目录和 skills-lock.json。
- 更新 docs/agents/skills.md 到 tag object 26b7fdf9b684c6fa821c71ed050e3d186e7b1622、peeled commit 83788402d3ab36fa7f6900b978dc3bb288d26f28。
- 保留 fireworks-tech-graph、release-easydict、产品代码和运行时资产不变。

## 验证

- 六个目录逐文件匹配上游 v0.7.0 tree，目录级 SHA-256 与 lock 全部一致。
- 受管 Skill 测试通过：19 + 6 + 64 + 7 + 23 项；Python compileall、Shell 语法、frontmatter、保护路径和 git diff --check 通过。
- 最终差异 review 未发现有效 finding；未运行 Xcode 构建或测试，因为变更不进入 Xcode 构建图。

## 交付

- 本地提交：本次任务创建。
- 未 push、未创建 PR、未发布。
