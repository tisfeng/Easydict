# MDict 词典服务

MDict（`.mdx` / `.mdd`）是一种广泛使用的离线词典格式，支持 HTML 富文本释义和多媒体资源。
本目录实现了对 MDict 文件的导入、解析与查询，并以 Easydict 标准服务的形式接入翻译结果面板。

![MDict 架构设计](./mdict-architecture-zh.svg)

## 目录结构

```
MDict/
├── MDictReader.swift          # MDict 二进制格式解析器（头部、键块、记录块、zlib 解压）
├── MDictDictionary.swift      # 高层词典封装（查词、MDD 资源解析、链接转义）
├── MDictManager.swift         # 词典生命周期管理（导入、持久化、启用/禁用、排序）
├── MDictService.swift         # QueryService 子类，HTML 渲染并接入主框架
└── MDictConfigurationView.swift  # SwiftUI 设置面板（导入、列表、开关、排序）
```

## 核心组件

### MDictReader

实现 MDict v1.x / v2.x 二进制格式的低层解析：

- **头部解析**：读取 UTF-16LE 编码的 XML 头部，提取版本、编码、格式、标题等属性。
- **键块解析**：读取键块信息区（v2 有独立的压缩键块信息），解压后构建
  `word → recordOffset` 的内存索引（`[String: Int]`）。
- **记录块读取**：按需解压目标记录块，从偏移量提取单条释义数据。
- **压缩支持**：支持 zlib（类型 `0x02`）与无压缩（类型 `0x00`），LZO 会抛出有提示的错误。

### MDictDictionary

封装一个 MDX 文件及其配套 MDD 文件：

- `lookup(_:)` — 查词并返回 HTML/文本释义，对大小写不敏感词典自动尝试首字母大写形式。
- `lookupResource(_:)` — 从 MDD 文件中读取图片、音频等二进制资源（供 WKWebView 拦截器使用）。
- 对 `entry://` 和 `sound://` 链接做前缀替换，避免 WKWebView 导航跳转。

### MDictManager

单例，负责持久化与运行时管理：

- 通过 `Defaults`（`UserDefaults` 封装）保存已导入词典的路径列表。
- 导入时自动发现同目录下同名 MDD 文件（支持多个 MDD 分卷）。
- 提供启用/禁用、重排序、删除等操作，变更后发送 `MDictManagerDidChange` 通知。

### MDictService

继承 `QueryService`，实现 standard 查询接口：

- `serviceType()` 返回 `.mdict`，注册于 `QueryServiceFactory`。
- `translate(_:from:to:)` 遍历所有已启用词典，将 HTML 释义包裹在 `<iframe>` 中，
  复用 `apple-dictionary.html` 框架模板进行渲染。
- 纯文本词典条目自动转换为 HTML 段落。

### MDictConfigurationView

SwiftUI `Section`，通过 `service.configurationListItems()` 注入设置面板：

- 列表显示已导入词典的标题与文件名，支持开关、拖拽排序、滑动删除。
- 右上角 `+` 按钮触发文件选择器（仅显示 `.mdx` 文件）。
- 导入失败时弹出 Alert 展示错误信息。

## 主要数据流

```
用户输入查词
    ↓
MDictService.translate(_:from:to:)
    ↓
MDictManager.enabledDictionaries  ← Defaults 持久化
    ↓
MDictDictionary.lookup(_:)
    ↓
MDictReader.lookupData(for:)      ← 内存键索引 O(1)
    ↓
decompressBlock / readRecord      ← 按需解压记录块
    ↓
HTML 包裹 → QueryResult.htmlString
    ↓
WKWebView 渲染
```

## 调试入口

- **解析失败**：`MDictError` 携带格式版本、压缩类型等详细信息，通过 `logError` 输出。
- **加载错误**：`MDictManager.loadErrors` 字典记录每个词典路径对应的错误，可在配置视图中展示。
- **查词未命中**：检查 `MDictReader.keyIndex` 是否包含目标词（注意大小写策略）。
- **加密词典**：直接抛出 `MDictError.encrypted`，暂不支持。

## 格式版本差异

| 特性 | v1.x | v2.x |
|------|------|------|
| 整数宽度 | 4 字节 | 8 字节 |
| 键块信息压缩 | 无 | zlib |
| 校验和 | 无 | adler32 |
| 偏移量宽度 | 4 字节 | 8 字节 |
