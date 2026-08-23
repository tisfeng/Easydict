# 发布工具目录迁移

**Status:** completed
**Created:** 2026-08-16
**Updated:** 2026-08-16
**Owner:** Easydict maintainers
**Links:** `docs/histories/2026-08/2026-08-16-release-tooling-layout-migration.md`

## 目标

将发布工作流配置和发布脚本放入 `scripts/release/`，移除它们与 Xcode 工程的无关引用，
同时保持 `asc` 发布流程行为不变。

## 范围

- 包含范围：发布脚本目录、`asc` workflow 配置、路径文档、Git 忽略规则和 Xcode 工程元数据。
- 不包含范围：产品源码、测试源码、实际发布、签名、公证和远程 Git 操作。

## 背景

- workflow 文件从 `.asc/workflow.json` 重命名为 `scripts/release/asc-workflow.json`。
- `release-scripts/` 迁移为 `scripts/release/`。
- `asc` 的运行状态改为 `scripts/release/runs/`。

## 风险与缓解

- 风险：脚本从嵌套目录计算仓库根目录时路径错误。
  - 缓解措施：更新三个根目录计算入口，并使用 `asc` 完整 dry-run 验证所有步骤路径。
- 风险：发布工具继续出现在 Xcode navigator。
  - 缓解措施：删除对应的 `PBXFileReference`、`PBXGroup` 和根 group 子项，并运行 `plutil` 校验。

## 里程碑

- [x] 确认范围和约束。
- [x] 迁移发布目录和 workflow 文件。
- [x] 更新脚本、文档、忽略规则和 Xcode 元数据。
- [x] 验证行为和文档。
- [x] 将本计划归档到 `completed/`。

## 验证

- `jq -e . scripts/release/asc-workflow.json`：通过。
- `asc workflow validate --file scripts/release/asc-workflow.json --pretty`：通过。
- `./scripts/release/release-easydict.sh release 2.22.0 --dry-run`：通过，所有 workflow 步骤指向 `scripts/release/`。
- `bash -n scripts/release/*.sh`：通过。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- `bash scripts/check-agent-docs.sh`：通过。
- `git diff --check`：通过；新增未跟踪文件的独立 whitespace 检查也通过。

## 决策记录

- 2026-08-16：使用 `scripts/release/asc-workflow.json`，让目录和文件名共同表达其用途。
- 2026-08-16：不将发布工具加入 Xcode；它们只由命令行发布流程使用。

## 进度记录

- 2026-08-16：完成目录迁移、路径更新、静态校验、`asc` dry-run 和旧路径复核。
