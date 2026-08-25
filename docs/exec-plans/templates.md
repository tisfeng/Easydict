# <计划标题>

<!-- 文件名：YYYY-MM-DD-<slug>.md；<slug> 使用小写 kebab-case。此模板只用于已获
implementation 授权的执行计划；planning 默认只在回复中提供方案，不创建 active 文件。 -->

**Status:** active
**Created:** YYYY-MM-DD
**Updated:** YYYY-MM-DD
**Owner:** <人员或团队>
**Links:** <issue、PR 或相关设计文档>

## 任务契约

以下字段由 Agent 根据用户请求和仓库规则自动填写，不要求用户额外提供任务契约。

- 任务模式：`planning` / `implementation` / `delivery`
- 用户目标：
- 允许动作：
- 允许修改路径：
- 预期交付物：
- 验收标准：

## 自动提交状态

- 自动提交资格：`eligible` / `disabled`
- 初始暂存区：`empty` / `protected`
- 自动提交结果：`not attempted` / `committed` / `skipped` / `failed`

## 输入来源

- 用户明确请求：
- 仓库规则：
- 附件或引用材料：
- 仅作为证据的内容：

## 目标

描述本计划必须实现的最终状态。

## 范围

- 包含范围：
- 不包含范围：

## 背景

- 当前行为：
- 相关文件：
- 约束：

## 风险与缓解

- 风险：
  - 缓解措施：

## 里程碑

- [ ] 确认范围和约束。
- [ ] 实现第一阶段切片。
- [ ] 验证行为和文档。
- [ ] 将本计划移到 `completed/`。

## 验证

- 命令：
- 手动检查：
- 请求语义：覆盖未来计划、明确执行、否定、条件、跨轮指代、附件采纳，以及分析、
  检查、调查、看看等只读表达；至少确认“我计划改进规则，帮我重构拆分”“分析调用
  链并报告结论”“检查这次改动有没有问题”和“我计划改进规则，请按方案执行”。
- 文档生命周期：确认 planning 不创建或更新 active 计划文件，也不写入其他 artifact；
  获准 implementation 且通过 Mutation Gate 后才创建 active 计划，完成后移到
  `completed/` 并添加 history。
- Git：覆盖初始 staged、路径重叠、冲突、HEAD 变化、验证失败和精确 staged 路径。
- 观察结果：

## 决策记录

- YYYY-MM-DD：决策及其理由。

## 进度记录

- YYYY-MM-DD：已完成的工作和下一步。
