## 2026-10-14 | 任务：将 Easydict 仓库常量迁移为 Swift EasydictRepo

**Links:** [2026-10-13-github-release-fetcher.md](2026-10-13-github-release-fetcher.md)

### 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 27.0.1 / Xcode 27.0 (27A266a)`

### 用户请求

将 `EZConst.h` 中的 `EZGithubRepoEasydict` 与 `EZGithubRepoEasydictURL` 改为 Swift 常量，并放到合适位置。

### 变更

- 新增 `Easydict/Swift/Utility/Constants/EasydictRepo.swift`，提供 `name`、`url`、`releasesURL`
  和 `issuesURL`。
- `GitHubReleaseFetcher`、`MenuItemView` 和 `MainMenuCommand` 改用 `EasydictRepo`，不再拼接
  URL 字符串或强制解包。
- 删除 `EZConst.h` 中的两个 Objective-C 常量（Objective-C 侧无引用），并同步 `project.pbxproj`。

### 设计意图

仓库信息与 `AppBundleIDs`、`AppWindowID` 一样按类别独立放在 `Utility/Constants/`，不并入职责
混杂的 `SharedConstants`。URL 以 `URL` 类型集中派生，releases/issues 地址只定义一次。

### 验证

- `xcodebuild build -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath <agent_dd>`：成功。
- `git diff --check`：通过。
- 手动检查：未运行 App 点击版本、反馈菜单项。

### 受影响文件

- `Easydict/Swift/Utility/Constants/EasydictRepo.swift`
- `Easydict/Swift/Utility/GitHubReleaseFetcher.swift`
- `Easydict/Swift/View/MenuItemView.swift`
- `Easydict/Swift/View/MenuView/MainMenuCommand.swift`
- `Easydict/App/EZConst.h`
- `Easydict.xcodeproj/project.pbxproj`

### 后续事项

- None
