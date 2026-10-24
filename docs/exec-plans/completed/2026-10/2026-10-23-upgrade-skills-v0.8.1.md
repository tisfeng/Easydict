# 更新受管 Skills 到 v0.8.1

- 状态：completed
- 创建日期：2026-10-23
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

## 背景

skills v0.8.1 已发布，submit-pr 的 PR 标题统一英文，正文与报告继续按用户语言偏好生成。
用户要求按正常流程升级 Easydict 的受管副本。

## 目标与范围

- 目标结果：六个 tisfeng/skills 受管 Skill 固定到 v0.8.1，内容与 lock 一致。
- 允许修改路径：六个受管 Skill、skills-lock.json、docs/agents/skills.md、本任务 plan/history。
- 同任务 history：`docs/histories/2026-10/2026-10-23-upgrade-skills-v0.8.1.md`
- 用户限制：保持既有 dev 分支，不创建或切换分支；只创建本地提交。
- 非目标：项目代码、第三方 Skill、release-easydict、全局安装、push、PR。
- 验收标准：通过 skills@1.5.25 升级；完整文件比较、目录 hash、来源及 tag 身份和相关测试通过。

## 工作计划

1. 核验已发布 tag 和安装器，记录受保护资产。
2. 用固定 tag 的安装器更新六个 Skill 和 lock，更新来源基线。
3. 比较源码文件与目录 hash，核对保护资产，运行相关既有测试。
4. 写入 history，归档计划并创建本地提交。

## 风险与决策

- 只更新同一来源的六个完整 Skill，不手工修改受管内容或 hash。
- 保留 fireworks-tech-graph、release-easydict 和 .claude/skills 链接。
- 初始 HEAD 为 8d80bfa219dde99c9c1f2760b59b2df72ad4adef，初始索引及工作树干净。

## 进度

- [x] 发布身份、安装器与保护资产预检。
- [x] 安装更新及验证。
- [x] history、归档与本地提交。

## 验证

- v0.8.1 tag object 为 d033324dd8e3b882ad8694836693df5dfd5e12a6，peeled commit 为 1b40de2c4a1b03dcc117b14a1d089d3445bb2b9c；远程与本地一致。
- [Release](https://github.com/tisfeng/skills/releases/tag/v0.8.1) 非 draft、非 prerelease，标题与正文已核验；固定 tag 隔离安装的 56 个文件和六个目录 hash 匹配。
- 使用 skills@1.5.25 从固定远程 tag 安装六个完整 Skill；56 个文件逐一匹配 tag archive 和隔离安装，六个目录 hash 与 lock 一致。
- 仅 submit-pr 的两份规则文档内容变化；六个 lock ref 更新为 v0.8.1，只有 submit-pr 的 computedHash 变化。
- submit-pr 现有 30 项测试通过；设置 PYTHONDONTWRITEBYTECODE=1，安装内容不产生字节码差异。
- git diff --check、lock JSON 解析、相对链接和文档检查通过；来源版本、tag object 与 peeled SHA 已更新。
- 与初始快照比较：第三方及项目专属 Skill、fireworks lock 条目、符号链接、分支和提交前 HEAD 均保持不变。
- 纯 Skill 文档与来源记录更新，不运行 Xcode 构建。

## 完成条件

安装与测试通过、内容和 lock 一致、其他资产保持不变；计划与 history 归档，本地提交完成。
