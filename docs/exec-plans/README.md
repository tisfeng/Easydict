# 执行计划

执行计划记录跨越多个 commit、模块或验证阶段的多步骤工作。

- `planning` 阶段只在回复中输出方案，不创建 active 计划文件。
- 获准的 `implementation` 通过写入前检查后，进行中的计划放在 `active/`。
- 已完成的计划移到 `completed/`。
- 新计划从 `templates.md` 开始。
- 带日期的计划文件统一命名为 `YYYY-MM-DD-<slug>.md`，其中 `<slug>` 使用小写
  kebab-case；长期路线图 `active/swift-migration.md` 不适用此命名规则。
- 在计划本身记录进度、风险、决策和验证结果。
- 新建或修改的标题与正文遵循用户当前请求的语言；技术标识和引用路径保留原文，
  不为语言统一批量改写历史计划。
- 不要将已完成或已放弃的工作留在 `active/` 中。

`active/swift-migration.md` 是长期的 Objective-C-to-Swift 迁移路线图。保持其中
的已完成历史和剩余工作与当前源码同步；如果某个迁移切片需要单独的里程碑或验证，
则为它创建聚焦的计划。
