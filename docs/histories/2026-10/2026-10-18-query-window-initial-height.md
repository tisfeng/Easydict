## 2026-10-18 | 任务：避免查询窗口首次显示时的高度收缩动画

**Links:** [PR #1327](https://github.com/tisfeng/Easydict/pull/1327)

### 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

PR #1327 为窗口高度变化加入动画后，查询窗口首次显示时高度很大，随后出现明显的收缩动画。
要求在 `viewWillAppear` 中不带动画地先把窗口调到内容高度。

### 变更

- `applyWindowHeight` 改为调用新增的 `applyWindowHeightAnimated:`，后者用 `allowsAnimation`
  参与是否播放动画的判断。
- `viewWillAppear` 在窗口未处于内部 frame 更新时调用 `applyWindowHeightAnimated:NO`，在窗口
  上屏前把高度调到内容高度。
- 本次为单文件局部修复，不创建执行计划或新增测试。

### 设计意图

窗口以 `EZLayoutManager` 保存的上次 frame 创建；view controller 初始化时调用的
`updateWindowHeight` 发生在窗口关联之前，不会生效。主窗口启动显示等路径在上屏前没有按内容调整
高度，首次调整发生在窗口可见后，于是触发 PR 新增的高度动画。`viewWillAppear` 是所有显示路径
共同经过、且窗口尚未上屏的时机，在此处不带动画地适配高度，后续内容变化仍保留动画。已有内部
frame 更新（例如 `resetTableView` 已在隐藏状态下完成适配）时跳过，避免重入。

### 验证

- `git diff --check`：通过。
- `xcodebuild test -only-testing:EasydictTests/ReverseTranslationTests -only-testing:EasydictTests/MarkdownRendererTests`：Test Succeeded。
- 手动检查：未执行；首次显示是否不再出现收缩动画尚未在 App 中确认。

### 受影响文件

- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`
- `docs/histories/2026-10/2026-10-18-query-window-initial-height.md`

### 后续事项

- 在 App 中确认：保存的窗口高度较大时，启动显示主窗口、首次显示 mini/fixed 窗口（含“显示时固定
  窗口”开启）都不再出现收缩动画。
