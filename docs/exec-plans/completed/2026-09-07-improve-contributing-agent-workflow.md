# 改进贡献文档中的 Agent 协作流程

- 状态：completed
- 创建日期：2026-09-07
- 负责人：Codex
- 关联 Issue/PR：none

## 背景

当前根目录贡献指南主要覆盖传统开发和 PR 要求，尚未完整说明 Easydict 深度集成的
Agent 开发流程、自动 Codex review、贡献者的审查责任以及维护者的处理优先级。两个
README 中的 AI 辅助说明还固定推荐 `GPT-5.4`，容易过期。

## 任务摘要

- 意图模式：implementation
- 交付授权：auto-local-commit
- 安全状态：normal
- 受阻操作及原因（如有）：none
- 目标结果：建立清晰、可跳转且不依赖具体模型版本的 Agent 贡献和 PR review 指南。
- 允许修改路径：`CONTRIBUTING.md`、`README.md`、`README_ZH.md`、
  `docs/exec-plans/`、`docs/histories/2026-09/`。
- 同任务 history：`docs/histories/2026-09/2026-09-07-improve-contributing-agent-workflow.md`
- 禁止动作：不修改产品代码、Agent 规则或外部服务，不 push、pull、rebase 或 merge。
- 预期交付物：更新后的贡献指南、README 入口、completed plan、history 和一个本地提交。
- 验收标准：用户要求均有明确落点，文档链接有效，模型建议不硬编码版本，静态检查通过。

## 语义与范围

- 用户要求 Agent 做什么：执行已确认的贡献文档改进方案。
- 授权的工作树、artifact 和 external service 操作：修改上述仓库文档并按默认流程本地提交；不修改外部服务。
- 否定、条件和范围限制：文档引用使用 Markdown 链接；README 只说明使用最新模型。
- 前轮仍有效的授权和限制：采用前轮推荐的信息架构和最小 README 同步范围。
- 附件或引用中被明确采纳的约束：两条 response annotation 均已纳入实施范围。
- 歧义：none

## 写入前状态

- 写入前检查：pass
- 自动提交资格及原因：eligible；implementation 已授权、初始索引为空、工作树干净。
- 初始 HEAD：`c29cfd3ebc26dbaeaae5b4a9c9bec0847ecd6f28`
- 初始 staged 路径：none
- 初始 unstaged 路径：none
- 初始 untracked 路径：none
- 初始冲突：none
- Agent-owned paths：`CONTRIBUTING.md`、`README.md`、`README_ZH.md`、
  `docs/exec-plans/active/2026-09-07-improve-contributing-agent-workflow.md`、
  `docs/exec-plans/completed/2026-09-07-improve-contributing-agent-workflow.md`、
  `docs/histories/2026-09/2026-09-07-improve-contributing-agent-workflow.md`

## 目标与非目标

### 目标

- 突出 `AGENTS.md` 入口和最新 GPT/Claude 模型建议。
- 介绍常用 Skill、子代理及其边界。
- 说明 Agent 参与 PR 的人工 review、实际场景验证和自动 Codex review 流程。
- 说明维护资源、作者自助推进方式和高质量 PR 的优先条件。

### 非目标

- 不修改 Agent、Skill、CI、PR 模板或产品行为。
- 不承诺具体 review 时限或自动 review 结果完全准确。

## 工作计划

1. 重组 `CONTRIBUTING.md` 并添加可跳转的仓库和官方文档链接。
2. 精简两个 README 的 AI 辅助说明并移除具体模型版本。
3. 检查链接、需求覆盖、Markdown 格式和 Git 范围。
4. 更新 history、归档计划并按自动本地提交规则交付。

## 风险与决策

- 模型名称变化快，因此只推荐最新可用、适合复杂编程任务的 GPT 或 Claude 模型。
- 自动 Codex review 是额外审查，不替代作者人工 review、测试或维护者判断。
- 高质量 PR 使用可验证标准描述，不承诺必然优先或合并。

## 进度

- [x] 更新贡献指南和 README。
- [x] 完成静态验证与内容复核。
- [x] 更新 history、归档计划并本地提交。

## 验证

- `git diff --check`：通过。
- Markdown 相对链接：通过；贡献指南引用的仓库文件均存在。
- 官方 Codex review 文档：通过；`@codex review` 和 Automatic reviews 的术语与
  OpenAI Docs 一致。
- 模型版本扫描：通过；`CONTRIBUTING.md`、`README.md` 和 `README_ZH.md` 未硬编码
  GPT 或 Claude 版本。
- 内容复核：通过；Agent 入口、能力简介、人工 review、场景验证、自动 review、维护周期、
  自助推进和高质量 PR 标准均有明确落点。
- `markdownlint`：未运行，当前环境未安装该命令；已完成 Markdown 人工结构检查。
- 不运行 `xcodebuild`，因为本次只修改治理和公开 Markdown 文档。

## 完成条件

- 所有文档改动和链接检查通过。
- completed plan 与 history 反映最终结果。
- 精确暂存 Agent-owned paths 并创建本地提交。
