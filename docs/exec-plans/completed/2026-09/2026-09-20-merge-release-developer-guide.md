# 合并 Easydict 发布开发者文档

- 状态：completed
- 创建日期：2026-09-20
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

发布环境配置和操作说明目前由 `docs/releases/easydict.md` 与 Skill reference
`release-engine.md` 重复承载。两份文档都面向发布维护者，命令、生命周期、状态和恢复说明存在
重叠，容易在发布实现变化后产生漂移。

## 目标与范围

- 目标结果：`docs/releases/easydict.md` 成为唯一面向开发者的发布与维护指南；删除
  `release-engine.md`。
- 允许修改路径：`docs/releases/easydict.md`、`.agents/skills/release-easydict/SKILL.md`、
  `.agents/skills/release-easydict/references/release-workflow.md`、本计划及同任务 history。
- 同任务 history：`docs/histories/2026-09/2026-09-20-merge-release-developer-guide.md`
- 用户限制：合并成一份面向开发者的 `easydict.md`，不保留相似的第二份说明。
- 非目标：不修改发布脚本、配置、测试或历史 plan/history 中对旧结构的事实记录；不执行发布。
- 验收标准：开发者只读 `docs/releases/easydict.md` 即可完成配置、发布、恢复和维护；Skill
  reference 只保留 Agent 执行契约；没有现行 `release-engine.md` 引用。

## 工作计划

1. 以现有开发者指南为骨架，吸收发布模型、beta 轮换、状态日志、文件职责和失败行为。
2. 删除重复命令和配置说明，形成一份结构连续的开发者文档。
3. 删除 `release-engine.md`，更新 `SKILL.md`，并收窄 `release-workflow.md` 的职责表述。
4. 验证文档链接、Skill 结构、旧引用清理、Markdown 差异和发布 Skill 测试。
5. 记录 history、归档计划并创建本地提交。

## 风险与决策

- 不简单拼接两份文档，避免命令和恢复规则重复；保留所有影响真实发布决策的独有内容。
- `release-workflow.md` 继续作为 Agent 的执行契约，不作为第二份开发者教程。
- 历史记录保持当时事实，不因当前文档结构变化而重写。

## 进度

- [x] 冻结基线并核对两份文档和引用关系。
- [x] 合并并去重开发者指南。
- [x] 清理 Skill 引用与重复说明。
- [x] 完成验证。
- [x] 记录 history 并归档计划。

## 验证

- Skill `quick_validate.py`：在安装 `PyYAML` 和固定 Markdown 依赖的临时 Python 3.12
  环境中通过。
- 发布 Skill 单元测试：71 个通过。
- Shell 语法、export options plist、相关 Markdown 相对链接、旧现行引用和
  `git diff --check`：通过。
- 未运行 Archive、公证或远程发布流程；本任务不修改发布实现，也未获真实发布授权。

## 完成条件

- 唯一开发者指南和 Skill 执行契约职责清晰，旧 reference 与现行引用均已删除。
- 文档、Skill 和风险匹配的测试通过。
- history 已创建，计划已归档，变更已创建本地提交。
