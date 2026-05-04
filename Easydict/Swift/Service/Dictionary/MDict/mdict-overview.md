# MDict

`MDict` 实现用户导入的 MDX/MDD 离线词典查询能力。它负责管理词典文件、解析二进制索引、
查询条目内容、重写词典内资源链接，并把结果交给共享的词典 HTML 渲染层展示。

![MDict 架构](./mdict-architecture.svg)

## 目录结构

```
MDict/
├── MDictService.swift                 # 查询服务入口和结果 HTML 包装
├── MDictConfigurationView.swift       # 设置页导入、启用、排序和删除 UI
├── MDictManager.swift                 # 导入记录持久化、加载和生命周期管理
├── MDictDictionary.swift              # 单本词典查询、MDD 资源解析和链接重写
├── MDictReader/                       # MDX/MDD 二进制 reader、parser 和底层工具
├── mdict-overview.md                  # 本目录说明
└── mdict-architecture.svg
```

## 职责边界

- `MDictService` 是 `QueryService` 子类，负责读取启用词典、收集查询结果，并调用
  `DictionaryHTMLRenderer` 生成结果面板 HTML。
- `MDictConfigurationView` 是设置页 UI，负责触发 MDX/MDD 导入，并把启用、排序和删除操作
  转发给 `MDictManager`。
- `MDictManager` 保存导入记录到 `Defaults`，维护已加载的 `MDictDictionary` 实例，并在记录
  变化时发出通知。
- `MDictDictionary` 表示一本 MDX 词典和它的 MDD 资源集合，负责查词、查资源、把图片、音频、
  CSS 和脚本资源重写为 WebKit 可加载的形式。
- `MDictReader/` 子目录只处理 MDX/MDD 二进制格式，不处理 UI、服务配置或结果面板样式。

## 主要流程

导入流程从 `MDictConfigurationView` 的文件选择器开始，`MDictManager` 根据扩展名导入 MDX
或匹配 MDD，合并同名资源文件，保存 `MDictDictionaryRecord`，再加载 `MDictDictionary`。
每个词典实例会创建 MDX reader，并为可用的 MDD 资源文件创建 resource reader。

查询流程从 `MDictService.translate` 开始。服务读取启用的 `MDictDictionary`，逐本调用
`lookup`，词典内部通过 `MDictReader` 查找 key entry 和 record block，再把 HTML 中的本地资源
链接改写为 data URI 或内部锚点。最终服务把每本词典的 HTML section 交给
`DictionaryHTMLRenderer`，由共享词典结果模板渲染。

## 调试入口

- 导入失败时，先检查文件扩展名、MDX/MDD 同名匹配，以及 `MDictManager.loadErrors`。
- 查询无结果时，检查 `MDictManager.enabledDictionaries`、词典大小写设置和 key index。
- 图片、音频或样式缺失时，优先检查 `MDictDictionary` 的 resource key candidates 和资源重写。
- 解析、解压或加密相关错误，从 `MDictReader/` 子目录里的 `MDictReader`、`MDictBinary`、
  `MDictKeyBlocks` 和 `MDictRecords` 开始定位。
- 结果面板样式或高度异常，回到 `MDictService.wrapWithStyle` 与 `DictionaryHTMLRenderer` 排查。
