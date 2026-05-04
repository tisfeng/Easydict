# WordResultView 目录概览

WordResultView 负责在结果卡片内部展示词典、翻译、按钮和 Apple 词典 WebView
内容。该目录仍属于 Objective-C 视图层，主要维护既有 AppKit/Masonry 布局和
WKWebView 高度桥接。

## 关键组件

- `EZWordResultView` 组装词条文本、音标、释义、复制/链接/替换按钮，并把计算
  后的内容高度回传给结果卡片。
- `EZWebViewManager` 持有 Apple 词典专用 WKWebView，记录 HTML 加载状态、
  iframe 重测标记和上一次内容高度。
- `EZResultView` 通过 `updateViewHeightBlock` 接收 word result 高度，再更新
  `EZQueryResult.viewHeight`，供表格和窗口重新计算。

## 主流程

普通词典结果由 Objective-C 直接按文本内容计算高度。Apple 词典结果先加载
HTML 文件，WebView 模板完成 iframe 测量后回传 `scrollHeight`，随后
`EZWordResultView` 更新 WebView 约束、result 高度和表格行高。

## 高度更新约束

WebView 高度更新必须保持幂等：`EZWebViewManager` 会过滤 0.5pt 内的重复
`scrollHeight`，`EZWordResultView` 会过滤重复的 word result 高度。只有高度
真实变化时，才允许继续通知 table row 和 window height 更新。

## 调试入口

- WebView 不显示时，检查 `EZWebViewManager.isLoaded`、navigation delegate 和
  `didFinishNavigation` 是否触发。
- 高度循环或 CPU 异常时，检查 `updateAllIframe`、`noteToUpdateScrollHeight`
  与 `updateWebViewHeight` 是否只在真实高度变化时继续传递。
- 复制内容异常时，检查 `fetchWebViewAllIframeText` 是否只在 HTML 首次完成后
  写入 `copiedText` 和 `translatedResults`。
