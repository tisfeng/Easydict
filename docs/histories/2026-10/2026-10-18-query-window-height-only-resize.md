## 2026-10-18 | 任务：禁止手动修改查询窗口高度

**Links:** [PR #1327](https://github.com/tisfeng/Easydict/pull/1327)

### 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

修复 PR #1327 审查发现的 F1：移除 scroll view 高度约束后，用户可以拖动窗口上下边缘改变
高度。首次修复（松手后恢复内容高度）体验不佳，用户要求完全禁止手动修改高度，窗口高度只由
最大窗口高度和翻译结果内容高度决定。

### 变更

- 撤销首次修复 `c68d112e` 中 `resizeWindowBlock` 的高度回弹逻辑和抽取的 frame 计算 helper。
- `applyWindowHeight` 通过新增的 `limitHeightOfWindow:from:to:` 设置窗口 `minSize`/`maxSize`：
  frame 已匹配或动画结束时将高度上下限都设为内容适配高度；动画期间临时放宽到新旧高度之间。
- 宽度下限沿用 `minimumWindowSize` 的宽度，宽度上限保持系统默认的不限制。
- 本次为单文件局部修复，不创建执行计划或新增测试。

### 设计意图

旧版靠 `DefaultHigh` 高度约束压过用户拖动的布局优先级来锁定高度，但该约束会与 PR 的窗口外框
动画冲突。`minSize`/`maxSize` 只约束用户拖动和 zoom，程序侧的 `setFrame:display:` 与动画不受
影响，因此能在保留动画的前提下让用户只能调整宽度；动画期间放宽区间，即使 AppKit 对中间帧
施加限制也不会截断动画。

### 验证

- `git diff --check`：通过。
- `xcodebuild test -only-testing:EasydictTests/ReverseTranslationTests -only-testing:EasydictTests/MarkdownRendererTests`：Test Succeeded。
- 手动检查：未执行；上下边缘是否完全不可拖动、光标是否只显示水平调整，以及宽度拖动和高度
  动画是否正常，尚未在 App 中确认。

### 受影响文件

- `Easydict/objc/ViewController/Window/BaseQueryWindow/EZBaseQueryViewController.m`
- `docs/histories/2026-10/2026-10-18-query-window-height-only-resize.md`

### 后续事项

- 在 App 中手动确认上下边缘无法拖动、宽度可调且结果更新时高度动画正常。
