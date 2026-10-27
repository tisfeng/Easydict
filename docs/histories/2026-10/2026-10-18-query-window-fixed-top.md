## 2026-10-18 | 任务：窗口增高时固定顶部位置

**Links:** [PR #1327](https://github.com/tisfeng/Easydict/pull/1327)、[评论](https://github.com/tisfeng/Easydict/pull/1327#issuecomment-6245356255)、[维护者回复](https://github.com/tisfeng/Easydict/pull/1327#issuecomment-6245678495)

### 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

PR 评论反馈翻译结果撑开窗口时窗口会“跳”，希望后出现的内容只往下延伸、不影响上方位置；维护者
确认窗口顶部坐标应固定，要求按该评论修复。

### 变更

- `applyWindowHeightAnimated:` 以窗口顶部为锚点计算新 frame，窗口高度上限取到当前屏幕可见区域
  底边为止（不低于最小窗口高度），超出部分在窗口内滚动。
- 屏幕查找改用窗口当前 frame，不再依赖新 frame。
- 本次为单文件局部修复，不创建执行计划或新增测试。

### 设计意图

原逻辑保持左上角后，若窗口底部超出屏幕，`getSafeAreaFrame` 会把整个窗口上移；加入高度动画后
表现为窗口整体向上滑动。改为以顶部为锚点并在屏幕底边截断高度，内容只向下延伸。只有顶部离屏幕
底边不足最小窗口高度时，才仍由 `getSafeAreaFrame` 上移窗口。

### 验证

- `git diff --check`：通过。
- `xcodebuild test -only-testing:EasydictTests/ReverseTranslationTests -only-testing:EasydictTests/MarkdownRendererTests`：Test Succeeded。
- 手动检查：未执行；靠近屏幕底部显示窗口时结果增长是否只向下延伸并在底边改为滚动，尚未在 App 中确认。

### 受影响文件

- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`
- `docs/histories/2026-10/2026-10-18-query-window-fixed-top.md`

### 后续事项

- 本地分支落后 PR 远程 head `27e71513`（仅 star-history 资源变更）1 个提交，推送前需要合并。
- 在 App 中确认靠近屏幕底部时窗口不再整体上移。
