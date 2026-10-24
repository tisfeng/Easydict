## 2026-10-22 | 任务：移除 GitHub Models 服务

**Links:** [Issue #1372](https://github.com/tisfeng/Easydict/issues/1372)、[执行计划](../../exec-plans/completed/2026-10/2026-10-22-remove-github-models.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

删除已退役的 GitHub Models 服务；明确不进行旧用户配置迁移。

### 变更

- 删除 GitHubService 及专属模型定义、工厂注册、Objective-C 服务常量和 Xcode 编译引用。
- 删除 GitHub Models 图标和本地化条目，移除中英文服务文档中的条目。
- 保留 GitHub Copilot、存储逻辑及历史文本；没有新增或修改测试。

### 设计意图

直接移除失效服务入口，沿用工厂对未注册服务返回 nil 并跳过的既有逻辑，避免扩展为旧配置迁移或自动替换服务。

### 验证

- `git diff --check`、`jq -e . Easydict/App/Localizable.xcstrings`、`plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- 工程解析后语义比较及 String Catalog JSON 比较：仅删除预期引用及本地化 key。
- `xcodebuild test`：编译通过，首次筛选未匹配测试，不计为测试通过。
- `xcodebuild test-without-building`：使用带括号的方法标识，GitHubCopilotServiceTests 的 `serviceContract()` 和 `factoryRegistration()` 两项通过。
- 使用 checkout 专用 DerivedData，并设置 `EASYDICT_RELEASE_PACKAGING=YES` 防止 SwiftFormat 改写源码。
- Review：基于首次写入前 HEAD 与完整任务差异检查；未发现有效 finding，当前直接删除方案足够。
- 手动检查：运行时代码、工程及公共服务文档已无 GitHub Models 引用，存储代码与 Copilot 文件无差异；未操作应用 UI 或调用外部翻译服务。

### 受影响文件

- `Easydict/Swift/Service/GitHub Models/GitHubService.swift`（删除）
- `Easydict/Swift/Service/Model/QueryServiceFactory.swift`
- `Easydict/objc/Service/Model/EZEnumTypes.h`
- `Easydict/objc/Service/Model/EZEnumTypes.m`
- `Easydict.xcodeproj/project.pbxproj`
- `Easydict/App/Assets.xcassets/service-icon/GitHub.imageset/`（删除）
- `Easydict/App/Localizable.xcstrings`
- `docs/user-docs/en/SERVICES.md`
- `docs/user-docs/zh/SERVICES.md`
- 本任务归档计划及 history。

### 后续事项

- 按用户要求保留旧配置，不迁移、不清理、不自动添加替代服务。
