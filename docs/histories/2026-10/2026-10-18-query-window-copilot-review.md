## 2026-10-18 | 任务：修复 Copilot 审查指出的窗口高度问题

**Links:** [PR #1327](https://github.com/tisfeng/Easydict/pull/1327)、[reset 定位](https://github.com/tisfeng/Easydict/pull/1327#discussion_r4305764925)、[loading 动画](https://github.com/tisfeng/Easydict/pull/1327#discussion_r4305764941)、[最小高度](https://github.com/tisfeng/Easydict/pull/1327#discussion_r4305764956)

### 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

核对 GitHub Copilot 在 PR #1327 上的 3 条审查评论后，要求全部修复：reset 时同步、不带动画地
先调好高度再定位；折叠后刷新 loading 动画；最小高度加上标题栏。

### 变更

- `resetTableView:` 改为重载表格后直接调用 `applyWindowHeightAnimated:NO`，再执行 completion，
  不再走合并延迟的 `updateWindowHeight`。
- 结果折叠/展开走不重载 cell 的路径时，模型更新后调用 `updateLoadingAnimation`。
- 窗口高度在屏幕底边截断时，下限改为 `minimumWindowSize.height` 加标题栏高度。
- 本次为单文件局部修复，不创建执行计划或新增测试。

### 设计意图

- `EZWindowManager` 在 reset 回调里用 `window.height` 计算弹出位置；窗口可见时高度更新被合并
  延迟，回调读到上次的高度，靠近屏幕底部时被安全区域上移，固定顶部后无法恢复。reset 是显示前
  的重置，同步且不带动画地适配高度最符合其语义，服务响应的合并逻辑不受影响。
- 不重载 cell 的路径不会经过 `setResult:`，需要显式同步 loading 状态，否则未返回结果前折叠的
  服务会一直显示 loading 动画。
- scroll view 在标题栏下方有必需的最小高度约束，窗口 frame 下限必须包含标题栏高度，避免约束冲突。

### 验证

- `git diff --check`：通过。
- `xcodebuild test -only-testing:EasydictTests/ReverseTranslationTests -only-testing:EasydictTests/MarkdownRendererTests`：Test Succeeded。
- 手动检查：未执行。

### 受影响文件

- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`
- `docs/histories/2026-10/2026-10-18-query-window-copilot-review.md`

### 后续事项

- 在 App 中确认：靠近屏幕底部、窗口已可见且未固定时发起新查询，弹出位置正确；服务返回前折叠，
  loading 动画停止；窗口顶部接近屏幕底边时没有约束冲突日志。
- reset 时若上一段 0.18s 高度动画仍在进行，未额外取消该动画，按低概率边界保留。
- 3 个 Copilot 审查线程尚未回复或 resolve。
