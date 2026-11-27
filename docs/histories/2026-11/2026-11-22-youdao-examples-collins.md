## 2026-11-22 | 任务：有道词典显示柯林斯释义和双语例句

**Links:** None

### 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 26.6.2 / Xcode 27.2 (27B52)`

### 用户请求

有道单词详情接口已经返回柯林斯英汉双解和双语例句，但查询结果只显示基本释义。用户希望在有道词典结果中显示这两部分，并可在设置中关闭。

### 变更

- `EZTranslateWordResult` 新增 `collinsStar`、`collinsSenses`、`exampleSentences`，以及 `EZCollinsSense`、`EZExampleSentence` 两个模型。
- `EZQueryResult+DictV4.swift` 从已有的 `jsonapi_s` 响应中读取柯林斯（最多 3 个义项，每个义项 1 个例句）和双语例句（最多 3 条），不增加请求。
  柯林斯 `tran` 末尾的中文拆为义项释义；查中文时只有双语例句。
- `YoudaoDictResponseV4.TranEntry` 解析语域标签 `registr`，用宽松类型避免意外结构导致整个响应解码失败。
- 新增 `DictionaryRichText.swift`：带加粗、灰字和悬挂缩进的结果标签 `EZDictionaryRichTextLabel`，以及组织两个区块文本的 `EZDictionaryRichText`；`<b>` 标记转为加粗。
- `EZWordResultView.m` 在词源之后追加“柯林斯 ★★★★”和“双语例句”区块。
- 有道服务设置新增“显示柯林斯释义”“显示双语例句”两个开关（默认开启），并补齐 7 种语言文案。

### 设计意图

数据已在现有请求中，只补解析与显示，不改变请求与其余结果结构。新区块沿用原生卡片的标题样式与高度计算；
样式以语义属性保存，标签每次重绘时按当前字体与外观解析，字号调整与深色模式仍然生效。条数上限避免卡片过长，
完整内容可通过卡片底部的网页链接查看。

### 验证

- Debug 构建通过。
- 临时宿主测试（验证后已删除）：用有道真实响应（`decline`、`固执`）渲染结果卡片并导出图片检查。
  `decline` 显示柯林斯 3 个义项与 3 条例句，加粗、灰字、悬挂缩进正确；`固执` 只显示双语例句。
- 代码审查（high）后修复：柯林斯中文释义只从汉字或括号开始截取（`the number 5. 五` 不再把 `5.` 移入释义）；
  只有柯林斯或例句时也保留结果；实体按固定顺序解码、`&amp;` 最后；文本中的字面 `<` 不再被当作标签删除；
  收满 3 个义项后停止遍历。截取与标签规则用脚本复核。
- 未验证：设置开关的界面操作；浅色主题下的显示（截图环境为深色主题）。环境无屏幕录制权限，未能截取运行中的窗口。

### 受影响文件

- `Easydict/Swift/Service/Model/QueryResult.swift`
- `Easydict/Swift/Service/Youdao/EZQueryResult+DictV4.swift`
- `Easydict/Swift/Service/Youdao/Model/YoudaoDictResponseV4.swift`
- `Easydict/Swift/Service/Youdao/DictionaryRichText.swift`
- `Easydict/Swift/Service/Youdao/YoudaoService.swift`
- `Easydict/Swift/Feature/Configuration/Defaults.Keys+Extension.swift`
- `Easydict/objc/ViewController/View/WordResultView/EZWordResultView.m`
- `Easydict/App/Localizable.xcstrings`
- `Easydict.xcodeproj/project.pbxproj`

### 后续事项

- 未加单元测试（新增测试需用户授权）；`splitCollinsTranslation` 与 `taggedText` 适合补单测。
- 暂不做：例句朗读、牛津高阶、英英释义、同义词辨析；Anki 导出与 HTTP 接口尚未包含柯林斯和例句。
