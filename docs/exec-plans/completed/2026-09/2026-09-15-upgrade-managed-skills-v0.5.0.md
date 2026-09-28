# Upgrade Managed Skills V0.5.0

- 状态：completed
- 创建日期：2026-09-15
- 负责人：Codex
- 关联 Issue/PR：none

## 背景

仓库当前固定使用 `tisfeng/skills` `v0.4.0` 的六个受管 Skill。用户要求升级到已发布的
`v0.5.0`，并继续保留项目专属 Skill、独立来源 Skill 与宿主规则边界。

## 目标与范围

- 目标结果：六个受管 Skill、lock 和来源参考统一固定到 `v0.5.0`。
- 允许修改路径：`.agents/skills/{code-simplifier,git-commit,review,review-pr,submit-pr,worktree-rebase-merge}/`、`skills-lock.json`、`docs/references/tisfeng-skills.md` 以及本任务 plan/history。
- 同任务 history：`docs/histories/2026-09/2026-09-15-upgrade-managed-skills-v0.5.0.md`
- 用户限制：同步 EasyKOL Scout 和 Easydict；采用最新 `v0.5.0`。
- 非目标：不修改 `fireworks-tech-graph`、`release-easydict`、产品代码或远程仓库。
- 验收标准：安装目录与上游 tag 完全一致，lock hash 可复算，受管测试和项目检查通过。

## 工作计划

1. 核验 `v0.5.0` tag、采用范围和两个仓库的初始状态。
2. 使用固定版本安装器同步六个完整 Skill 目录并更新 lock。
3. 更新来源参考中的固定版本和上游变更说明。
4. 核对上游目录、hash、元数据、链接和受管测试。
5. 记录 history、归档计划、审查并创建本地提交。

## 风险与决策

- 安装器会替换受管目录，只允许覆盖 lock 已声明的六个 Skill，并在安装前后核对路径集合。
- `v0.5.0` 仅 `submit-pr` 内容相对 `v0.4.0` 变化，其余目录仍重新核验但不制造无意义差异。
- 采用 annotated tag 与 peeled commit 双重证据，不跟随可移动分支。

## 进度

- [x] 核验上游 tag、初始状态与实际内容差异。
- [x] 同步、验证并记录两个仓库。
- [x] 完成 review 与本地提交。

## 验证

- 两个仓库六个受管目录与上游 `v0.5.0` 的 `diff -qr` 无差异。
- 两个仓库 lock 的独立 SHA-256 重算全部匹配。
- 受管 Skill 单元测试共 94 项通过。
- EasyKOL Scout `corepack pnpm check` 通过；Easydict `jq -e . skills-lock.json` 与
  `git diff --check` 通过。

## 完成条件

- 两个仓库的六个目录、lock 与来源参考均指向 `v0.5.0`。
- 所有必要验证与 review 无阻塞 finding。
- history 已记录，计划已归档，本地提交已创建且未 push。
