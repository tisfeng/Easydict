# 聚合 Easydict 发布实现到项目 Skill

- 状态：completed
- 创建日期：2026-09-20
- 负责人：Codex
- 关联 Issue/PR：none

## 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`
- **Environment:** `macOS 27.0 / Xcode 27.0 (27A266a)`

## 背景

Easydict 的发布能力当前拆分在 `scripts/release/` 和
`.agents/skills/release-easydict/`，两处代码通过硬编码路径和 Python 导入互相依赖，发布入口、测试和
说明也需要跨目录维护。用户要求把发布实现全部聚合到项目专属 Skill，并删除不再需要的 legacy
脚本与流程图。

## 目标与范围

- 目标结果：发布入口、工作流、脚本、静态配置和测试统一位于
  `.agents/skills/release-easydict/`，仓库不再保留 `scripts/release/`。
- 允许修改路径：`.agents/skills/release-easydict/`、`scripts/release/`、`.gitignore`、
  `changelog/README.md`、`docs/releases/easydict.md`、
  `docs/design-docs/application-architecture.md`、本计划及同任务 history。
- 同任务 history：`docs/histories/2026-09/2026-09-20-consolidate-release-skill.md`
- 用户限制：删除 legacy 脚本与流程图；不保留旧入口。
- 非目标：不执行真实 Archive、公证、Git push、GitHub Release 或 Issue 写入；不改写历史计划和
  history 中对当时旧路径的事实记录。
- 验收标准：现行代码和文档均使用 Skill 内路径；发布测试和静态检查通过；`scripts/release/`
  删除；运行状态写入仓库临时目录而非 Skill 源码目录。

## 工作计划

1. 将仍在使用的发布脚本、工作流、配置、依赖和测试迁入项目 Skill，删除 legacy 资产。
2. 统一仓库根、Skill 根和运行状态目录解析，消除跨目录 Python 导入与旧路径硬编码。
3. 更新公开指南、架构说明、changelog 说明、Skill references 和忽略规则。
4. 运行 Skill 校验、release/Skill 测试、shell/Python/JSON/plist 静态检查和 dry-run 路由测试。
5. 完成 Review，修复 finding，记录 history，归档本计划并创建本地提交。

## 风险与决策

- 发布脚本会在临时 worktree 中继续运行，路径定位必须基于脚本位置和明确的仓库根，而不是 cwd。
- `asc` 固定把状态写到 workflow 文件旁的 `runs/`；入口脚本把 workflow 的运行时副本放到
  `.tmp/release/asc/`，因此状态落在 `.tmp/release/asc/runs/`，不会污染 Skill 源码目录。
- `scripts/release/README.md` 改为 Skill reference；公开用户指南仍由 `docs/releases/easydict.md`
  维护。
- 不保留 wrapper 或符号链接，避免形成双入口；迁移后的路径变化会同步更新所有现行引用。

## 进度

- [x] 读取执行、history、Skill 边界和 Skill 创建规范。
- [x] 冻结文件清单与旧路径引用。
- [x] 迁移发布实现并改造路径。
- [x] 更新现行文档与测试。
- [x] 完成验证与 Review。
- [x] 记录 history 并归档计划；本地提交作为交付步骤创建。

## 验证

- `quick_validate.py .agents/skills/release-easydict`：通过，Skill 结构有效。
- `python3 -m unittest discover -s .agents/skills/release-easydict/tests -p 'test_*.py'`：
  通过，71 tests passed；包含非仓库 cwd、运行时 workflow 路径和 dry-run 参数路由。
- `bash -n .agents/skills/release-easydict/scripts/*.sh`：通过。
- `python3 -m py_compile ...`：通过。
- `jq -e . .agents/skills/release-easydict/scripts/asc-workflow.json`：通过。
- `plutil -lint .agents/skills/release-easydict/assets/export-options.plist`：通过。
- 相对 Markdown 链接与旧现行路径扫描：通过。
- `git diff --check`：通过。
- `review`：基于初始 `HEAD` `91aa7a6f5be8cfc4dca86f9a1117418d76802a4f` 审查任务
  变更，无 findings。
- 当前环境没有 `asc`，未运行真实 `asc workflow validate`；通过 `jq`、workflow 行为测试和
  fake-ASC 路由测试覆盖迁移契约。按任务范围未运行 Archive、公证或任何远程写入。

## 完成条件

- Skill 结构和全部现行引用完成迁移，legacy 资产与 `scripts/release/` 已删除。
- 风险匹配的测试、静态检查、dry-run 和 Review 通过。
- history 已创建，计划已归档，变更已创建本地提交。
