## 2026-10-13 | 任务：将 GitHub 版本获取函数收拢为 GitHubReleaseFetcher

**Links:** [tisfeng/Easydict#1358](https://github.com/tisfeng/Easydict/pull/1358)

### 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 27.0.1 / Xcode 27.0 (27A266a)`

### 用户请求

审查 #1358 后，用户不希望 `fetchRepo*` 系列保持为全局函数，要求在 PR 合并到 `dev` 后按优化方案重构。

### 变更

- `RepoInfoHelper.swift` 重命名为 `GitHubReleaseFetcher.swift`，三个全局函数收拢为
  `GitHubReleaseFetcher` 命名空间；对外只暴露 `latestVersion(of:includePrerelease:)`，
  `repo` 默认 `EZGithubRepoEasydict`。
- 删除未使用的 `RepoInfoResponse*` 大模型，改为只解码 `tag_name` 的 `GitHubRelease`。
- 新增 `GitHubReleaseFetcher.isNewer(_:than:)`，统一 `MenuItemView` 与 `GeneralTab` 的版本比较。
- 同步 `project.pbxproj` 中的文件引用。

### 设计意图

使用无实例的 `enum` 作为命名空间，避免全局函数污染，也不引入共享状态或单例；Beta 开关仍由
调用方传入，保持 `.task(id:)` 的刷新触发和 fetcher 无隐藏依赖。行为与 #1358 合并后保持一致。

### 验证

- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath <agent_dd>`：成功。
- `git diff --check`：通过。
- 手动检查：未运行 App 验证设置页和菜单栏版本显示。

### 受影响文件

- `Easydict/Swift/Utility/GitHubReleaseFetcher.swift`
- `Easydict/Swift/View/MenuItemView.swift`
- `Easydict/Swift/View/SettingView/Tabs/TabView/GeneralTab.swift`
- `Easydict.xcodeproj/project.pbxproj`

### 后续事项

- None
