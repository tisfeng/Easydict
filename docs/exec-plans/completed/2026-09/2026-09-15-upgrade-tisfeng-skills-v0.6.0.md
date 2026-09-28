# 升级 `tisfeng/skills` 至 v0.6.0

- 状态：completed
- 创建日期：2026-09-15
- 负责人：Codex
- 关联 Issue/PR：https://github.com/tisfeng/skills/releases/tag/v0.6.0

## 背景

Easydict 当前固定使用 `tisfeng/skills v0.5.0` 的六个通用 Skill。上游已经正式发布
`v0.6.0`，本任务将受管快照升级到该固定版本。

## 目标与范围

- 目标结果：将六个 `tisfeng/skills` 受管 Skill、lock 和来源参考统一固定到 v0.6.0。
- 允许修改路径：六个 `tisfeng/skills` 受管目录、`skills-lock.json`、
  `docs/references/tisfeng-skills.md` 及本任务 plan/history。
- 同任务 history：`docs/histories/2026-09/2026-09-15-upgrade-tisfeng-skills-v0.6.0.md`
- 用户限制：采用正式发布的 v0.6.0；不 push、不创建 PR、不发布。
- 非目标：不修改 `fireworks-tech-graph`、`release-easydict`、`.claude/skills`、产品代码或运行时资产。
- 验收标准：六个目录匹配 v0.6.0 tag tree，目录 hash 与 lock 一致，相关测试和静态检查通过。

## 工作计划

1. 冻结初始状态和 v0.6.0 发布证据。
2. 用 `skills@1.5.25` 从固定 tag 同步六个完整 Skill 目录。
3. 核对上游 tree、lock hash、保护路径并运行变更 Skill 的测试。
4. 更新来源、history 和本计划，审查后创建本地提交。

## 风险与决策

- 固定使用正式发布的 annotated tag，不跟随可移动分支。
- 安装器只覆盖 lock 已声明的六个 Skill，项目专属与第三方 Skill 保持不变。

## 进度

- [x] 已冻结初始状态和采用范围。
- [x] 已同步并验证受管 Skill。
- [x] 已完成记录、审查和本地提交准备。

## 验证

- 六个受管目录逐文件匹配 tag `v0.6.0`；独立重算目录 SHA-256 后全部等于 lock。
- Python 3.14.6：`git-commit` 19 项测试与变更脚本语法检查通过。
- `jq -e . skills-lock.json` 与 `git diff --check` 通过；最终范围无项目专属、第三方或产品资产。
- 提交前本地 review 无 P0-P3 finding；固定 tag 的完整复制方案已经足够。

## 完成条件

- [x] 受管目录、lock 和来源参考统一固定到 v0.6.0。
- [x] 必要验证通过，保护路径未修改。
- [x] 计划与 history 已归档并进入本地提交交付。
