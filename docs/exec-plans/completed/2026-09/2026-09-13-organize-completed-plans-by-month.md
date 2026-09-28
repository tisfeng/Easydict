# 按月份归档已完成执行计划

- 状态：completed
- 创建日期：2026-09-13
- 负责人：Codex
- 关联 Issue/PR：none

## 背景

`docs/histories/` 已按月份归档，`docs/exec-plans/completed/` 仍平铺保存全部计划。随着已完成计划增加，两者的目录结构和浏览方式逐渐不一致。

## 目标与范围

- 目标结果：将已完成计划按文件名中的 `YYYY-MM` 归档，并同步所有仓库内引用。
- 允许修改路径：`docs/agents/README.md`、`docs/exec-plans/`、引用已完成计划的 Markdown 文档、同任务 history。
- 同任务 history：`docs/histories/2026-09/2026-09-13-organize-completed-plans-by-month.md`
- 用户限制：保持 `active/` 扁平；除机械更新路径引用外，不修改计划和 history 的正文内容。
- 非目标：不改变计划模板结构，不处理现有 skills 更新，不执行远程写入。
- 验收标准：所有 completed plan 位于匹配的月份目录；旧路径无残留；本地 Markdown 链接有效。

## 工作计划

1. 建立月份目录并移动现有 completed plan。
2. 更新计划生命周期说明和所有仓库内路径引用。
3. 校验文件数量、内容一致性、月份匹配和 Markdown 链接。
4. 记录 history，归档本计划并提交本次改动。

## 风险与决策

- 目录月份取文件名的 `YYYY-MM` 前缀，移动时保留文件名和正文。
- 使用 Git 重命名和全仓库引用检查，避免留下失效路径。

## 进度

- [x] 移动现有 completed plan。
- [x] 更新规则和引用。
- [x] 完成静态校验。
- [x] 创建本地提交。

## 验证

- 目录检查：58 份既有计划全部进入匹配的 `YYYY-MM/` 目录，根层不再包含计划文件。
- 内容检查：计划正文除路径适配外保持不变；60 份引用文档只有 completed plan 路径变化。
- 链接检查：53 个本地 Markdown 链接均有效，旧的扁平文件路径无残留。
- `git diff --check`：通过。
- Xcode 构建与测试：未运行；本次仅调整治理 Markdown 的目录和引用。

## 完成条件

- 58 份既有计划与本任务计划均位于匹配的月份目录。
- 仓库内不存在指向旧 completed 路径的引用。
- 静态检查通过并完成本地提交。
