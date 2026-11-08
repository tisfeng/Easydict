# 更新受管 Skills 至 v0.9.1

- 状态：completed
- 创建日期：2026-10-27
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

## 背景

Easydict 受管 tisfeng/skills 当前为 v0.8.1；v0.9.1 已发布并包含线程维护、同名分支复用及复审快进修复，用户要求按项目流程升级。

## 目标与范围

- 目标结果：六个受管 Skill 完整同步至固定 v0.9.1，lock 和来源基线一致。
- 允许修改路径：`.agents/skills/` 中 tisfeng/skills 来源的六个目录、`skills-lock.json`、`docs/agents/skills.md`、本任务 plan/history。
- 同任务 history：`docs/histories/2026-10/2026-10-27-upgrade-skills-v0.9.1.md`
- 用户限制：保持 dev 分支，按项目验证后本地提交，不 push。
- 非目标：更新第三方或项目专属技能、全局技能、产品代码或 Xcode 工程。
- 验收标准：快照与 tag tracked tree 完全一致，来源/ref/路径/hash 准确，受保护资产不变，相关验证通过。

## 工作计划

1. 核对本地状态、固定 tag/peeled SHA、项目安装边界并保存受保护资产清单。
2. 使用 skills@1.5.25、独立 npm 缓存和项目规定参数，从固定 tag 安装六个目录。
3. 核对上游 tree、lock 和保护资产，更新来源基线，运行相称验证及 Review。
4. 完成 history、归档计划，创建本地提交。

## 风险与决策

- 初始 HEAD 为 `be3b012b37cd10e5a9874d71f7d2bdb0bb05e139`，dev 工作树与索引干净。
- v0.9.1 tag object `3295da05793b447d99d33f48738ed4820ba7fe25`，peeled commit `eea85d3877b3bd46b8885cbab8f0d9729cbc9276`，本地与远程一致。
- 明确选择同来源六个技能，不跨来源更新、不手工编辑受管内容或 computedHash。
- 已记录第三方及项目专属技能、符号链接等 190 项保护内容；仅快照与治理文档变化，不运行 Xcode 构建。

## 进度

- [x] 基线、规则与保护资产核对。
- [x] 安装与来源基线更新。
- [x] 验证与 Review。
- [x] history 与计划归档；本地提交由最终交付执行。

## 验证

- 已通过规定安装器与独立 npm 缓存同步；六个完整 Skill 的 56 个文件逐一匹配 v0.9.1 tag archive。
- 六项 lock 的来源、ref、路径与重算目录 hash 均正确，第三方 lock 条目及 190 项保护内容未变。
- 已安装 review-pr 副本的 79 项测试通过（使用 PYTHONDONTWRITEBYTECODE=1，不在受管目录写入 pyc）。
- 六个技能 frontmatter、agents/openai.yaml 解析及 44 个相对链接通过；Python AST、Shell bash -n、JSON jq 与 git diff --check 通过。
- 按 review 技能核对升级范围、完整源码快照及宿主边界，无未解决 finding；测试后再次核验快照与保护清单未变化。
- 本次不进入 Xcode 构建图，按项目规则未运行应用构建或 GUI 验证；测试使用临时仓库与 fake gh，不操作真实 PR。

## 完成条件

固定版本快照、lock 与基线匹配，验证与 Review 通过，记录归档并本地提交，未 push。
