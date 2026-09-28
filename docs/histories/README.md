# 变更历史

本目录保存执行模式下最终产生仓库文件差异的任务记录：

- `YYYY-MM/`：按完成月份归档的历史记录。
- `template.md`：新记录模板。

## 创建与归档

- 执行任务产生仓库差异时，在 `YYYY-MM/` 使用 [`template.md`](template.md) 记录结果；
  没有差异时不创建空记录。
- 新记录从当前模板创建，保留模板中的必填字段、章节和顺序。

## 命名与 slug

- 记录与计划共用 `YYYY-MM-DD-<slug>.md` 文件名，同一任务共享 slug 并跨轮复用。
- `<slug>` 使用小写 kebab-case；其中完整的标准标识可保留点号（如 `release-0.1.1`、
  `upgrade-skills-v0.3.8`）。不使用空格、下划线、大写字母、斜杠、反斜杠或冒号。

## 内容与交付

- history 记录已落地结果与关键决策，不复制完整对话。
- 存在 plan 时，history 链接归档后的 plan。
- 计划的创建时机、生命周期和内容要求见
  [`../exec-plans/README.md`](../exec-plans/README.md)。
