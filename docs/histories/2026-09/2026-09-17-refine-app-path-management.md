## 2026-09-17 | 任务：精简应用路径管理

**Links:** [执行计划](../../exec-plans/completed/2026-09/2026-09-17-refine-app-path-management.md)、
[设计文档](../../design-docs/app-path-management.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-5`

### 用户请求

将 Scoco 中经过验证的路径管理改进移植到 Easydict，缩短 Application Support 根路径与通用迁移
类型命名，消除只有一个基础函数的扩展文件，并保持日志目录只展示常规日志、调试导出打包全部日志。

### 变更

- 将 `applicationSupportDirectory` 简化为 `appSupportDirectory`，并把显式目录创建能力合并进
  `AppPathManager` 核心类型。
- 将路径扩展按 Codex、日志和缓存业务域重组，当前与历史路径的磁盘布局保持不变。
- 将 `AppPathMigrationCoordinator` 简化为 `AppPathMigration`，保留日志、音频缓存和 MDict 元数据
  的全部迁移与安全检查。
- 保持“日志目录”打开 `logs/app`，将“导出日志”调整为打包 `logs` 下的全部受管日志。
- 同步 Xcode 工程引用和应用本地路径设计文档；未新增或修改测试代码。

### 设计意图

核心类型负责不可变的根路径上下文和显式目录创建，业务域扩展负责可发现的具体路径，避免按系统目录
组织造成职责混杂。Easydict 的历史数据迁移仍有真实用途，因此仅缩短类型名称，不照搬 Scoco 删除
迁移的项目特定决策。日志查看保持日常使用范围，完整导出则服务于调试并明确可能包含敏感内容。

### 验证

- `plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- `git diff --check`：通过。
- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict | xcbeautify`：通过，包含 Format、
  Lint、bundled Codex 准备、签名和应用验证。
- `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict | xcbeautify`：应用和测试 target 编译
  成功；完整测试未通过，失败集中在既有 OCR、联网服务、AppleScript、计时和进程取消用例，与本次
  路径重构无调用关系。
- 代码审查：路径组件、迁移入口、工程引用和日志导出范围未发现 finding。

### 受影响文件

- `Easydict/Swift/Utility/AppPathManager/`
- `Easydict/App/EasydictApp.swift`
- `Easydict/Swift/View/MenuItemView.swift`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/design-docs/app-path-management.md`
- `docs/exec-plans/completed/2026-09/2026-09-17-refine-app-path-management.md`

### 后续事项

- 本任务未获授权新增路径管理测试；如需覆盖路径无副作用、bundle ID 隔离和迁移冲突场景，应在
  后续任务中明确授权新增测试代码。
