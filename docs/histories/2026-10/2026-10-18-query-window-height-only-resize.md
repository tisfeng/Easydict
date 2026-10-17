## 2026-10-18 | 任务：恢复查询窗口仅改高度时的内容高度适配

**Links:** [PR #1327](https://github.com/tisfeng/Easydict/pull/1327)

### 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

修复 PR #1327 审查发现的 F1：移除 scroll view 高度约束后，用户可以只拖动窗口上下边缘改变
高度，窗口不再回到内容适配高度。

### 变更

- `resizeWindowBlock` 在宽度未变化时，比较窗口高度与内容适配高度；不一致时调用
  `updateWindowHeight`，拖动中经 `inLiveResize` 分支立即恢复高度。
- 从 `applyWindowHeight` 提取 `windowFrameFittingContentHeight:inWindow:`，让窗口动画与
  resize 校验共用同一目标 frame 计算。
- 本次为单文件局部修复，不创建执行计划或新增测试。

### 设计意图

PR 用窗口外框动画替代旧的 `DefaultHigh` 高度约束，旧约束曾阻止手动改变窗口高度。仅高度
变化不影响内容布局，因此不重新加载表格，只在高度偏离内容适配值时走既有的高度更新流程，
保留 PR 的宽度判断和动画合并逻辑。

### 验证

- `git diff --check`：通过。
- `xcodebuild test -only-testing:EasydictTests/ReverseTranslationTests -only-testing:EasydictTests/MarkdownRendererTests`：Test Succeeded。
- 手动检查：未执行；拖动窗口上下边缘后的回弹效果尚未在 App 中确认。

### 受影响文件

- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`
- `docs/histories/2026-10/2026-10-18-query-window-height-only-resize.md`

### 后续事项

- 在 App 中手动拖动查询窗口上下边缘，确认拖动中或松手后回到内容高度，且无明显抖动。
