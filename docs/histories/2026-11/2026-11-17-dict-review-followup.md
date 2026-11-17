## 2026-11-17 | 任务：修复 PR #1392 词典评审问题

<!-- 文件名：2026-11-17-dict-review-followup.md；命名规则见 docs/histories/README.md。 -->

**Links:** https://github.com/tisfeng/Easydict/pull/1392 · docs/exec-plans/completed/2026-11/2026-11-17-dict-review-followup.md

### 执行上下文

- **Agent Name:** `Sisyphus (OhMyOpenCode)`
- **Model:** `moma/kimi-k3.1-pro`
- **Environment:** `macOS 26.5.1 / Xcode 26.5 (17F42)`

### 用户请求

继续维护已部署的必应词典与韦氏词典集成，跟进 PR #1392 的 CI 与评审意见。

### 变更

- 合并上游 main 后的 PR head 为 `17e68431`；先确认合并后仍可编译，再处理 Codex 评审。
- 网络层：`BingDictRequest`、`MWDictRequest` 由裸 `URLSession` 改为 ephemeral Alamofire
  `Session` + `serializingData(automaticallyCancelling:)`，保留无 Cookie/无缓存与超时；
  错误文案全部改为 String Catalog，新增取消判定 `DictionarySupport.isCancellation`。
- 韦氏请求额外识别 2xx 纯文本错误体（无效 Key、未订阅引用），不再当作词条 JSON 解析。
- 本地化：服务名改为分域 key（`service.bing_dict.name`、`service.mw_dict.name`，工厂
  `titleKey` 同步更新）；新增词形变化标题与两类服务错误文案共 9 个 key，覆盖 7 个 locale。
- 必应卡片：词形变化标题本地化；同义词/反义词改写入原生 `synonyms`/`antonyms` 字段，
  由结果视图提供本地化标题与可点击词条，避免英文标题被词性缩写逻辑改成 `Synonyms.`。
- 复制与繁体：`QueryResult.copiedText` 优先返回服务写入的复制载荷（原先原生卡片只能复制
  一行摘要）；`convertToTraditionalChineseResult` 同时转换复制文本与原生卡片字段。
- 韦氏：`supportLanguagesDictionary` 按 MDict 做法放开全部语言对（单语英文词典忽略目标语言）；
  音标标签改用 `us_phonetic`；设置页 `requiredKeys` 只要求 Collegiate Key。
- Validate：`QueryService` 新增可覆写 `validationQuery()`，两个英文专用词典返回 `hello`
  英文样例，修复默认中文样例必然验证失败的问题。
- 韦氏解析：保留义项状态标签 `sls`（slang、obsolete 等）；`pseq` 递归共享编号；
  `{dx_def}…{/dx_def}` 保留交叉引用文本；`dros` 带定义派生词单独成分节；
  Learner 例句提取同样递归 `pseq`，请求改为 5 秒短超时并向上传递取消。
- 词头判定折叠变音符号，`café`、`naïve` 可查询。
- Anki 设置预览服务列表加入 `BingDict` 与 `MerriamWebster`。
- 测试按规范拆分为 `EasydictTests/Service/Dictionary/{BingDict,MWDict}/` 下四个单 suite 文件，
  同步 `project.pbxproj` 的 group、文件引用与 Sources；必应服务用例改为断言本地化查找结果与
  原生同义词字段，不再固定某一语言的界面文案。
- 更新两份设计文档。

### 设计意图

优先修复可确认且改动可控的缺陷与规范偏差，不为评审意见扩大到框架分类器改造。
`QueryResult`/`QueryService` 的两处共享改动都保持默认行为不变：未设置复制载荷的服务仍回退到
摘要文本，未覆写 `validationQuery()` 的服务仍用中文样例。同义词/反义词走原生字段与韦氏卡片
一致，也比文本行更贴近官网的链接列表。

### 验证

- `xcodebuild build-for-testing`（合并后基线）：成功（`CODE_SIGNING_ALLOWED=NO`）。
- `xcodebuild test -only-testing:` 四个词典 suite：21/21 通过（`TEST SUCCEEDED`）。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`：OK。
- `git diff --check`：无空白错误；`Localizable.xcstrings` JSON 解析通过（577 个 key）。
- 界面截图：本次未执行。上游 main 在 debug entitlements 中加入
  `com.apple.developer.background-tasks.continued-processing.inference`，本地 ad-hoc 构建改为
  需要 provisioning profile，本次验证因此使用 `CODE_SIGNING_ALLOWED=NO`；未重新部署应用，
  同义词/反义词原生区块的界面表现未实测。

### 受影响文件

- Easydict/Swift/Service/Dictionary/DictionarySupport.swift
- Easydict/Swift/Service/Dictionary/BingDict/BingDictRequest.swift
- Easydict/Swift/Service/Dictionary/BingDict/BingDictService.swift
- Easydict/Swift/Service/Dictionary/MWDict/MWDictRequest.swift
- Easydict/Swift/Service/Dictionary/MWDict/MWDictService.swift
- Easydict/Swift/Service/Dictionary/MWDict/MWDictAPIParser.swift
- Easydict/Swift/Service/Model/QueryResult.swift
- Easydict/Swift/Service/Model/QueryService.swift
- Easydict/Swift/Service/Model/QueryServiceFactory.swift
- Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/ServiceSecretConfigreValidatable.swift
- Easydict/Swift/View/SettingView/Tabs/TabView/AnkiConnectSettingsView.swift
- Easydict/App/Localizable.xcstrings
- EasydictTests/Service/Dictionary/BingDict/BingDictHTMLParserTests.swift（迁移）
- EasydictTests/Service/Dictionary/BingDict/BingDictServiceTests.swift（拆分）
- EasydictTests/Service/Dictionary/MWDict/MWDictAPIParserTests.swift（迁移）
- EasydictTests/Service/Dictionary/MWDict/MWDictServiceTests.swift（拆分）
- Easydict.xcodeproj/project.pbxproj
- docs/design-docs/bing-dict-service.md、docs/design-docs/mw-dict-service.md

### 后续事项

- 未处理的评审项：智能查询模式分类器对 `well-known`、`don't`、超长单词的放行；
  必应 zh→zh 输入的中文预处理（需要拆分“结果繁体转换”与“中文预处理”两个开关）；
  Anki `full_result` 去重与 `{exchange}`/`{related}` 结构化字段扩展。
- 界面验证（同义词/反义词原生区块、英文 locale 标题）待重新可签名构建后补做。
- 本地重新构建部署版时需要处理上游新增的 restricted entitlement，不能沿用旧的
  ad-hoc 构建命令。

### 第二轮补充（核对全部 44 个线程）

- 首轮暂缓项本次全部处理：`QueryService` 新增可覆写 `shouldAutoQuery(withText:)`，
  两个词典按自身英文词头规则放行智能查询；Bing 改为查词成功后由服务完成繁体转换，
  `autoConvertTraditionalChinese()` 返回 `false`，中文输入不再走通用预处理，HTTP 与 UI
  均返回繁体结果，转换同时覆盖 `innerTexts`。
- Anki：两个服务的 `full_result` 只采用 `innerTexts` 的完整纯文本，不再拼接摘要和结构化
  表示；Bing 词形、搭配分别写入 `exchanges`、`collocation`，韦氏词形也写入 `exchanges`，
  `{exchange}`、`{related}` 与 `{definition}` 不再互相丢失或混入。
- 两个服务在 `updateResultLock` 内检查取消和 `queryGeneration` 后才写入结果，避免同步解析
  期间旧查询污染复用的 `QueryResult`；音标 accent 改为 TTS 需要的小写 `us`/`uk`。
- 韦氏纯文本在无分节标签时包含词性；Learner 例句只取第一条词条，标题改用本地化 key
  `service.mw_dict.section.examples_in_a_sentence`，拉丁字母仍保持 Unicode 粗体。
- 新增/调整本地化：`service.dictionary.section.word_forms`、
  `service.mw_dict.section.examples_in_a_sentence`，覆盖 7 个 locale。
- 验证：四个词典 suite 21/21 通过；`QueryModelCancellationTests`、`AppleDictionaryTests`、
  `LocalizationTests` 共 17 项通过；`git diff --check` 无空白错误，xcstrings JSON 有效。
  另新增两个专属联网验证 suite：`BingDictValidationTests` 与 `MWDictValidationTests`，
  使用英文样例分别验证匿名必应查询和已配置 Key 的韦氏查询，2/2 通过。
  本轮仍未重新部署应用，未做界面截图和全服务联网验证。
