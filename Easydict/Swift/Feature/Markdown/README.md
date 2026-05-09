# Markdown

## 目录职责

把 AI / LLM 流式翻译服务返回的 Markdown 文本，渲染为带样式的
`NSAttributedString`，并展示在原有的 `EZLabel` 流水线里。同时提供「全局
设置开关」和「单条结果即时切换图标按钮」两种入口，仅在流式服务
（`QueryService.isStream() == true`）上启用，对 Google / Bing / DeepL 等
普通服务保持现有纯文本行为。

## 关键组件

- `MarkdownRenderer.swift`：行级 Markdown → `NSAttributedString` 转换器。
  支持 ATX 标题、`**bold**` / `*italic*`、`> 引用`、有序无序列表、
  围栏与行内代码、`[text](url)` 链接、`~~删除线~~`。无外部依赖，
  对未闭合标记容错（流式安全）。
- `MarkdownLabel.swift`：`EZLabel` 子类，覆写 `updateDisplayedText`。
  `markdownEnabled` 为 `true` 时走渲染器；为 `false` 时回落父类纯文本路径，
  从而复用选中、复制、暗色模式与高度计算等现成行为。
- `MarkdownToggleButton.swift`：流式结果卡片底部图标按钮。点击后翻转
  `QueryResult.markdownRenderingOverride`，触发表格行重建以应用新状态。

## 主要流程

1. 用户在「设置 → 通用 → 显示」打开 / 关闭全局开关，写入
   `Defaults[.enableMarkdownRendering]`。
2. 流式服务产出文本，经 0.3s 节流写入 `QueryResult.translatedResults`。
3. `EZWordResultView` 在重建结果行时，对 `service.isStream` 的服务实例化
   `MarkdownLabel`，并按 `result.isMarkdownRenderingEnabled`
   （per-result 覆盖优先于全局默认）设置 `markdownEnabled`。
4. `MarkdownLabel` 在每次 `setText` 后调用 `MarkdownRenderer` 重新解析，
   将结果写入 `textStorage`。
5. 卡片底部 `MarkdownToggleButton` 调用 `QueryResult.toggleMarkdownRendering()`
   并触发 `updateCellWithResult:reloadData:YES`，重建该行视图。

## 调试入口

- 渲染样式问题：先在 `MarkdownRenderer` 的 `appendHeading` /
  `appendBlockquote` / `appendListItem` / `appendCodeBlock` /
  `renderInline` 分支定位；这些分支负责所有字体、缩进与背景属性。
- 流式期间样式抖动：检查 `MarkdownLabel.updateDisplayedText` 是否被
  `setFont` / `setLineSpacing` / 暗色模式回调多次触发。
- 开关与按钮联动：确认 `QueryResult.isMarkdownRenderingEnabled` 是否
  正确地把 per-result 覆盖优先于 `Defaults[.enableMarkdownRendering]`。
- 单测入口：`EasydictTests/Feature/Markdown/MarkdownRendererTests.swift`，
  覆盖块级 / 行内 / 流式残缺 / 性能预算。
