# Agent 结构迁移

**Status:** completed
**Created:** 2026-08-09
**Updated:** 2026-08-09
**Owner:** Easydict 维护者
**Links:** `AGENTS.md`, `docs/agents/`, `docs/user-docs/`

## 目标

按职责分离 Agent 规则、实现架构、任务记录以及公共英文/中文文档，同时保持仓库
链接和贡献者入口有效。

## 范围

- 包含迁移公共文档、迁移文本选择流程图、拆分 `AGENTS.md`、添加生命周期模板以及
  增加结构校验。
- 不包含 Swift/Objective-C 行为、Xcode 工程元数据和发布逻辑。

## 约束

- 保留 `.claude/CLAUDE.md` 作为指向规范 `AGENTS.md` 的符号链接。
- 不要将仓库治理 Markdown 添加到 Xcode 工程中。
- 尽量保留公共文档文件名，以减少链接变更。

## 里程碑

- [x] 将公共英文和中文文档移到 `docs/user-docs/`。
- [x] 将文本选择流程移到 `docs/architecture/`。
- [x] 将根目录 Agent 规则拆分为按任务划分的文档。
- [x] 添加并验证计划/历史记录生命周期工具。
- [x] 完成链接、Shell 和仓库整洁性检查。

## 验证

- `git diff --check`
- `bash -n scripts/*.sh`
- `scripts/check-agent-docs.sh`
- 验证所有 README 和公共文档的本地链接。

## 决策记录

- 2026-08-09：使用 `docs/user-docs/en|zh` 区分公共文档与 Agent 内部知识和架构
  知识。
- 2026-08-09：保持公共文件名稳定；迁移过程中只更新路径和已知过时的根目录
  README 引用。

## 进度记录

- 2026-08-09：迁移公共文档并完成 Agent 规则拆分。
- 2026-08-09：添加生成器和结构检查；本地链接与 Shell 语法检查通过。迁移完成后
  将本计划归档。
