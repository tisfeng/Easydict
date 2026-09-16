# 统一 Agent 记录模板

- 状态：completed
- 创建日期：2026-09-17
- 负责人：Codex
- 关联 Issue/PR：none

## 背景

history 模板已加入执行上下文字段，但近期 history 和一份 completed plan 仍存在标题语言或结构偏差。
本次按现行模板整理相关文档，并用一条简洁规则明确新建记录的模板要求。

## 目标与范围

- 目标结果：将 history 的执行上下文标题中文化，并让近期记录与当前模板保持一致。
- 允许修改路径：`docs/agents/README.md`、`docs/histories/template.md`、相关近期 history、
  `docs/exec-plans/completed/2026-09/2026-09-15-upgrade-tisfeng-skills-v0.6.0.md` 及本任务记录。
- 同任务 history：`docs/histories/2026-09/2026-09-17-enforce-agent-record-templates.md`
- 用户限制：不增加结构校验器或 CI，不补充旧记录回填或不合规记录处理说明。
- 非目标：不修改脚本、工作流、产品代码、测试或其他项目，不批量整理无关历史记录。
- 验收标准：模板标题、治理规则、近期 history 与指定 completed plan 结构一致，Markdown 静态检查通过。

## 工作计划

1. 更新 history 模板标题和 Plan/History 使用规则。
2. 整理模板变更后新增的近期 history，并规范指定 completed plan。
3. 检查文档结构、链接和 diff，记录结果后归档计划。

## 风险与决策

- 无法确认历史任务的完整模型 ID，因此统一保留 `Unknown`，不作推测。
- 只整理已有事实和章节结构，不补写当时不存在的执行计划或验证结果。

## 进度

- [x] 确认现行模板、近期记录和用户限制。
- [x] 更新规则、模板及相关记录。
- [x] 完成静态检查并归档计划。

## 验证

- 章节检查：近期 history 均包含当前模板要求的章节和执行上下文字段。
- 章节检查：指定 completed plan 已保留当前模板的字段、章节和顺序。
- 相对链接检查：相关本地文档目标均存在。
- `git diff --check`：通过。

## 完成条件

- [x] 相关文档完成整理且未引入校验脚本或额外治理策略。
- [x] 静态检查通过，history 已记录最终结果。
- [x] 计划状态已更新为 completed 并归档到 `completed/2026-09/`。
