# AppleDictionary 目录概览

AppleDictionary 负责接入 macOS 系统词典，把 DictionaryServices 返回的词条
HTML 包装成 Easydict 可展示的查询结果。该目录同时包含 Swift 查询服务和供
WKWebView 加载的 HTML 模板。

## 关键组件

- `AppleDictionary.swift` 负责选择系统词典、查询词条、过滤 headword，并把各
  词典结果写入 `~/Library/Dictionaries/Dict HTML/all_dict.html`。
- `apple-dictionary.html` 是 WebView 外层模板，承载多个 `iframe srcdoc`，并
  在 iframe 样式完成后向 Objective-C 侧回传总滚动高度。
- 每个词典词条会独立包在 iframe 中，避免系统词典原始样式互相污染，同时保
  留链接、发音资源和深色模式处理。

## 主流程

查询开始后，服务从系统活动词典中读取词条 HTML，替换资源路径并生成
`all_dict.html`。结果视图加载这个文件后，模板脚本统一调整 iframe 字体、边距
和高度，并只回传一次合并后的 `scrollHeight`，减少 native 高度更新频率。

## 高度更新约束

Apple 词典结果的高度由 WebView 内容决定，不应由窗口当前高度反推。模板侧
只负责测量 DOM 总高度，幂等和节流由 `EZWebViewManager` 与
`EZWordResultView` 处理，避免相同高度反复触发表格和窗口布局。

## 调试入口

- 查询内容异常时，先检查 `AppleDictionary.queryAllIframeHTMLResult` 的词典
  选择和 `isValidHeadword` 过滤结果。
- 展示或高度异常时，检查生成的 `all_dict.html`、iframe 数量，以及
  `noteToUpdateScrollHeight` 回调频率。
- 资源加载异常时，检查 `TTTDictionary.userDictionaryDirectoryURL()` 下的
  `Dict HTML` 目录和各词典 HTML 文件。
