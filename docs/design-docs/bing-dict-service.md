# 必应词典服务设计

- 状态：adopted
- 初次记录：2026-11-04
- 最近更新：2026-11-06

## 背景

Easydict 既有的 `BingService` 使用必应翻译 v7 API，只返回译文，没有词典卡片所需的音标、
词形变化、搭配和分义项释义。必应词典的 JSON API 匿名请求返回 403，但词典页面
`https://cn.bing.com/dict/search?q={word}` 匿名返回 200，并且把双语词义、词形变化、
搭配、同义词/反义词直接渲染在服务端 HTML 中。

因此本设计不复用 `BingService` 的请求与降级链路，而是新增一个独立的词典服务，解析服务端
HTML 并映射到原生词典卡片。需求来源见
[issue #1389](https://github.com/tisfeng/Easydict/issues/1389)。

## 设计目标

- 以独立服务类型 `BingDict` 接入，不改变既有 `BingService` 的查询行为。
- 匿名可用：不依赖 Cookie、登录态或 Token，请求使用临时会话（不落 Cookie、不缓存）。
- 纯原生渲染：只产出 `EZTranslateWordResult`，不注入 WebView HTML 卡片。
- 展示结构与官网一致：快速释义 → 词形变化 → 搭配 → 同义词/反义词 → 编号双语释义。
- 解析器只依赖 Foundation，可脱离 app target 独立编译与单元测试。
- 请求无状态：每次查询独立发起，不保存会话数据。

## 组件与数据流

```mermaid
flowchart LR
    Q[用户查询单词] --> F[QueryServiceFactory]
    F --> S[BingDictService.translate]
    S --> R[BingDictRequest.fetchPage]
    R -->|匿名 GET dict/search| P[BingDictHTMLParser.parse]
    P --> E[BingDictWordEntry]
    E --> M[makeWordResult]
    M --> W[EZTranslateWordResult]
    W --> V[原生结果卡片]
```

## 组件职责

### `BingDictRequest`

- 位置：`Easydict/Swift/Service/Dictionary/BingDict/BingDictRequest.swift`
- 职责：对 `https://cn.bing.com/dict/search?q={word}` 发起单次匿名 GET。
- 约束：浏览器 User-Agent、`Accept: text/html`、30 秒超时；使用 ephemeral `URLSession`
  （无 Cookie 存储、无缓存、忽略本地缓存策略），取消错误原样抛出，其余非 2xx、空响应体和
  网络错误统一转换为 `QueryError`，不重试。
- 查询值使用严格白名单编码（字母数字与 `-._~`），保证 `+`、`&`、`=` 等字符不被站点重新解释。
- 不解析内容，也不感知 UI。

### `BingDictHTMLParser`

- 位置：`Easydict/Swift/Service/Dictionary/BingDict/BingDictHTMLParser.swift`
- 职责：把页面 HTML 转换为 `BingDictWordEntry`；无匹配内容时返回 `nil`。
- 输出模型：
  - `BingDictQuickRow`：快速释义行（如 `v.` + `发展；开发；研制；发挥`，网络释义记为 `Web`）。
  - `BingDictWordForm`：词形变化（如 `一般现在时` + `develops`）。
  - `BingDictCollocation`：带标签的链接列表，同时用于搭配、同义词、反义词。
  - `BingDictSenseGroup` / `BingDictSense`：按词性分组的编号释义，含语法标签（`[i]`/`[t]`）、
    搭配模式（`~ sth`）、中文释义和英文释义。
- 实现约束：只用 `NSRegularExpression` 与字符串扫描，不引入 HTML DOM 依赖。值文本必须用
  平衡标签扫描提取，因为必应把分隔空格也包成 `<span> </span>`，非贪婪匹配会截断句子。
- 派生输出：`plainText`（复制与纯文本展示）与 `bestTranslation`（首个双语释义，缺失时回退
  快速释义）。

### `BingDictService`

- 位置：`Easydict/Swift/Service/Dictionary/BingDict/BingDictService.swift`
- 职责：`QueryService` 子类，声明服务元数据并编排“请求 → 解析 → 原生结果映射”。
- 服务元数据：服务类型 `.bingDict`、名称 `bing_dict`（七语言本地化）、无需 API Key、
  `supportedQueryType` 与 `intelligentQueryTextType` 均为 `.dictionary`、图标复用 `Bing` 资源。
- 语言边界：`supportLanguagesDictionary` 只登记 auto、英语、简体中文、繁体中文，避免为其他
  语言对提供必然失败的入口；`autoConvertTraditionalChinese` 返回 `true`，繁体目标由结果层转换。
- 查询约束：仅接受英文单词（`from == .english`、`to` 为简体或繁体中文、单个词条），否则抛
  `QueryError(.noResult)`，不发起网络请求。单词判定允许字母、数字、连字符和撇号
  （`well-known`、`don't`），拒绝空格分隔的多词与符号词（`C++`）。
- 结果写入：`wordResult`（原生卡片）、`innerTexts`/`copiedText`（`plainText`）、
  `translatedResults`（`bestTranslation`）。

### 注册点

- `Easydict/objc/Service/Model/EZEnumTypes.h` / `.m`：`EZServiceTypeBingDict = "BingDict"`。
- `Easydict/Swift/Service/Model/QueryServiceFactory.swift`：工厂条目 `bing_dict`，
  `apiKeyRequirement: .none`。
- `Easydict/App/Localizable.xcstrings`：`bing_dict` 的六语言名称。
- `Easydict.xcodeproj/project.pbxproj`：新文件与测试文件的 group、build phase 引用。

## 页面结构与解析约定

解析器只读取服务端直出的稳定片段：

| 输出字段 | 页面片段 |
| --- | --- |
| 词头 | `<a class="hw …">` 文本 |
| 美/英音标、快速释义原文 | `<meta name="description">`（`美[…]`、`英[…]`、`…的释义` 之后） |
| 快速释义行 | 上述描述文本，按词性标记（`v.` 等）切分；`网络释义：` 之后记为 `Web` |
| 词形变化 | `<span class="b_primtxt">标签：</span><a>值</a>` 成对片段 |
| 搭配 | `<div class="de_title2">标签</div><div class="col_fl">链接列表</div>` |
| 同义词 / 反义词 | `#synoid` / `#antoid` 容器内的 `de_title1` + `col_fl` 片段 |
| 编号释义 | `<tr class="def_row">`：`se_d`（序号）、`au_def .gra`（语法标签）、`sen_com`（搭配模式，`com_sep` 分隔符保留空格）、`bil`（中文）、`val`（英文） |

文本统一解码命名与数字实体（`&nbsp;`、`&#163;` 等）；词形变化按「标签 + 值」去重，同一标签的
多个值全部保留（`复数：formulas` / `复数：formulae`）。

`#synoid` 与 `#antoid` 在页面中的先后顺序不固定，解析时各自从内容 div 切片到下一个
`<div id=` 边界，不依赖两者相对位置。

## 原生渲染映射

`makeWordResult` 把解析结果映射为按官网顺序排列的 `EZTranslatePart` 列表：

1. 快速释义行（`v.`、`Web` 等）。
2. `变形`：词形变化合并为一行。
3. 搭配：每个标签一个条目（如 `v.+n.`、`adv.+v.`）。
4. `同义词` / `反义词`。
5. 编号释义：**每条释义单独一个 part**；存在多个词性分组时，标签带词性前缀（`v. 1.` / `n. 1.`），
   单分组时只显示序号。

编号释义必须一条一个 part：原生卡片会把同一个 part 的多行用 `; ` 连接成一段，只有拆成
独立 part 才能保持官网的逐行编号结构。语法标签与搭配模式作为前缀拼在中文释义之前，
例如 `[t] ~ sth 开发；研制 to think of or produce…`。

## 图标

`BingDictService.iconName()` 返回 `Bing`，复用既有 `Bing.imageset` 资源。该图标与必应词典
官网图标一致，也避免新增二进制资源。

## 取舍

- **原生卡片而非 HTML 卡片**：内嵌网页能一比一复刻官网排版，但与 App 内其他词典卡片风格
  割裂；原生卡片复用既有结果视图，视觉一致，代价是无法完全复刻官网的分栏与标签页。
- **分区用 `parts` 而非原生 `exchanges`/`synonyms`/`antonyms`/`collocation` 字段**：原生字段
  的渲染顺序固定为「词性释义 → 变形 → 同义词 → 反义词 → 搭配」，与官网顺序（变形 → 搭配 →
  同义/反义 → 释义）冲突；用有序 `parts` 才能保持官网顺序，代价是同义词/搭配失去原生可点击
  链接与分区标题，标签文本使用页面语言。
- **解析 HTML 而非 JSON API**：JSON API 匿名 403，页面匿名可用且内容完整；代价是解析器
  与页面结构耦合，需要 fixture 回归测试兜底。
- **无缓存**：每次查询一次 GET，保持服务无状态；代价是重复查询会产生重复请求。
- **单服务单方向**：只处理英文单词的英汉查询，不承担中英、长文本或多语言职责。

## 已知限制

- 官网“Advanced E-C”标签页中的例句（Show examples）和 E-C / E-E / Web Definition 标签页
  由页面脚本异步加载，匿名 HTML 中不存在，因此不在本服务范围内。
- 语法标签（`[i]`/`[t]`）与搭配模式（`~ sth`）来自服务端 HTML，可用；但例句、词频、
  短语板块不解析。
- 仅支持英文单词；多词短语、非英文输入、非中文目标语言直接返回无结果。
- 页面文本为简体中文；繁体目标由结果层转换，HTTP 等非 UI 调用方拿到的是简体内容。
- 依赖页面结构：必应调整 class 或片段布局时解析会失败，表现为无结果而非错误提示。

## 验证

- `EasydictTests/Service/BingDictHTMLParserTests.swift`：9 个解析用例（词头/音标/快速释义、
  快速释义切分、词形变化与搭配、重复标签词形、同义词/反义词、语法标签与搭配模式、实体解码、
  纯文本输出、无释义返回 `nil`）与 `BingDictServiceTests` 的 2 个用例（单词判定、原生 part
  顺序与标签），共 11 项。
- `xcodebuild build` 与 `xcodebuild test -only-testing:EasydictTests/BingDictHTMLParserTests`：
  通过（构建环境注意事项见 `docs/agents/build-and-test.md` 与对应 history）。
- 运行中 dev 应用 HTTP `/translate`（`serviceType=BingDict`）核对 `develop`、`run`、`formula`、
  `good` 的 `dictionaryEntry`：顺序、语法标签、多词性标签、重复词形合并、实体解码均与官网一致；
  非中文目标语言与多词输入被拒绝。
- 窗口截图核对：结果卡片头部显示必应图标，正文为原生控件渲染。

## 重新评估条件

- 必应页面结构变更导致解析失败或字段缺失。
- 需要例句、多词典标签页或登录后内容（此时应评估 Cookie 方案或官方 API）。
- 查询量增大需要缓存或限流。
- 需要在非英文或非英汉场景复用该页面数据。
