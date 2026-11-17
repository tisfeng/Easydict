# 统一 Agent 记录模板

- 状态：completed
- 创建日期：2026-09-17
- 负责人：Codex
- 关联 Issue/PR：none

## 背景

history 模板已加入执行上下文字段，但近期 history 和一份 completed plan 仍存在标题语言或结构偏差。
首轮整理完成后，进一步确认模型信息应优先来自对话上下文，且字段需要同时容纳完整模型 ID 与
base model，不能依赖某个客户端的本地记录格式。

## 目标与范围

- 目标结果：统一 history 结构，并以跨客户端方式记录主执行 agent 和模型信息。
- 允许修改路径：`docs/agents/README.md`、`docs/histories/template.md`、相关近期 history、
  `docs/exec-plans/completed/2026-09/2026-09-15-upgrade-tisfeng-skills-v0.6.0.md` 及本任务记录。
- 同任务 history：`docs/histories/2026-09/2026-09-17-enforce-agent-record-templates.md`
- 用户限制：不增加结构校验器、CI 或模型记录解析脚本，不把客户端字段或本地路径写入规则。
- 非目标：不修改工作流、产品代码、测试或其他项目，不批量整理无关历史记录。
- 验收标准：模板使用通用的 `Model` 字段和上下文优先规则，相关 history 记录准确，Markdown
  静态检查通过。

## 工作计划

1. 更新 history 模板标题和 Plan/History 使用规则。
2. 整理模板变更后新增的近期 history，并规范指定 completed plan。
3. 检查文档结构、链接和 diff，记录结果后归档计划。
4. 将 `Model ID` 改为兼容完整 ID 与 base model 的 `Model`，并修正相关记录和设计说明。

## 风险与决策

- 模板只引用“当前对话上下文”这一通用信息来源，不依赖特定客户端字段或本地路径。
- 优先保留上下文明确提供的完整模型 ID；只有完整 ID 不可得时才使用明确的 base model，均不可得
  时填写 `Unknown`。
- 只整理已有事实和章节结构，不补写当时不存在的执行计划或验证结果。

## 进度

- [x] 统一近期记录的模板结构。
- [x] 确认模型信息的现有来源和跨客户端边界。
- [x] 更新模型字段规则及相关 history。
- [x] 完成静态检查并重新归档计划。

## 验证

- 模板检查：未包含客户端字段、本地路径或特定存储格式。
- 模型检查：当前任务的主执行 turn 均为 `gpt-5.6-sol`，5 份相关 history 已使用相同值。
- 兜底检查：模板允许使用明确的 base model，并只在两者均不可得时填写 `Unknown`。
- 相对链接检查：相关本地文档目标均存在。
- `git diff --check`：通过。

## 完成条件

- [x] 模型记录规则能够跨客户端使用，并允许完整模型 ID、base model 和 `Unknown` 三级结果。
- [x] 相关文档完成整理且未引入校验脚本或额外治理机制。
- [x] 静态检查通过，history 已记录最终结果，计划已重新归档到 `completed/2026-09/`。
