## 2026-08-16 | 任务：迁移并重命名发布工具

**Links:** [`docs/exec-plans/completed/2026-08-16-release-tooling-layout-migration.md`](../../exec-plans/completed/2026-08-16-release-tooling-layout-migration.md)

### 用户请求

将发布 workflow 和发布脚本移出 Xcode 工程，统一放入 `scripts/release/`，并将 workflow
重命名为 `asc-workflow.json`。

### 变更

- 将 `.asc/workflow.json` 迁移为 `scripts/release/asc-workflow.json`。
- 将 `release-scripts/` 迁移为 `scripts/release/`，同步更新脚本路径和仓库文档。
- 将 `asc` 运行状态目录改为 `scripts/release/runs/` 并加入 Git 忽略规则。
- 删除 `.asc` 和旧发布目录在 Xcode 工程中的所有引用。

### 设计意图

发布脚本和 workflow 属于命令行工具链，不是应用源码或运行时资源；将它们集中在
`scripts/release/` 并从 Xcode navigator 移除，保持工具边界清晰，同时通过显式
`--file` 继续使用 `asc` workflow。

### 验证

- `jq -e . scripts/release/asc-workflow.json`：通过。
- `asc workflow validate --file scripts/release/asc-workflow.json --pretty`：通过。
- `./scripts/release/release-easydict.sh release 2.22.0 --dry-run`：通过。
- `bash -n scripts/release/*.sh`：通过。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- `bash scripts/check-agent-docs.sh`：通过。

### 受影响文件

- `scripts/release/`
- `.gitignore`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/architecture/overview.md`

### 后续事项

- None
