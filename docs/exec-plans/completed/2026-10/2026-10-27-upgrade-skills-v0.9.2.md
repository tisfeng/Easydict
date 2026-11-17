# 更新受管 Skills 至最新版

- 状态：completed
- 创建日期：2026-10-27
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

## 背景

用户要求更新 skills；当前 tisfeng/skills 为 v0.9.1，上游最新 tag 为 v0.9.2，第三方 main 也有更新。

## 目标与范围

- 目标结果：按各自来源同步全部七个受管 Skill。
- 允许修改路径：七个受管 Skill 目录、skills-lock.json、docs/agents/skills.md、本任务 plan 和 history。
- 同任务 history：`docs/histories/2026-10/2026-10-27-upgrade-skills-v0.9.2.md`
- 用户限制：保留当前分支；仅本地提交。
- 非目标：项目专属 Skill、应用源码、全局 Skills 与上游仓库。
- 验收标准：完整目录和 hash 匹配固定上游，静态检查与适用测试通过。

## 工作计划

1. 固定两个来源的远程版本并保存初始状态。
2. 用指定安装器分别同步并更新来源基线。
3. 检查目录、lock、保护内容，运行测试并审查。
4. 记录 history、归档 plan 并本地提交。

## 风险与决策

- 初始 HEAD 为 45cda90046f3a825ddad90b5dbb67a4bdd7c41a9，dev 分支，索引和工作树干净。
- tisfeng/skills 使用最新稳定 tag；第三方沿用 main 并固定同步 commit。
- 不手工修改受管快照和 lock hash。

## 进度

- [x] 核对远程版本与初始状态。
- [x] 同步、验证和审查。
- [x] 记录、归档，按宿主授权提交。

## 验证

- 两来源七个目录共 195 个文件逐字节匹配固定上游；全部 lock 来源、ref、入口和安装器 hash 通过。
- git-commit 现有测试 27 项通过；六个技能 frontmatter、openai.yaml 字段、相对链接及全部受管 Python AST、Shell 语法检查通过。
- review 审查初始 HEAD 到工作树的完整差异：双语 References 的拆分、验证、错误路径与测试契约一致；第三方仅删除赞助内容；没有 finding。完整安装器同步已经足够，无需本地替代实现。
- 项目专属技能和符号链接未变；git diff --check 和 JSON 检查通过。
- 未更改应用构建图，未运行 Xcode 构建和 GUI 验证。

## 完成条件

- 所有受管目录与固定上游一致；验证和审查完成；history 完成并本地提交。
