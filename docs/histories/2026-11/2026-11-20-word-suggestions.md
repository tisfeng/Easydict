## 2026-11-20 | 任务：输入框单词推荐列表

**Links:** [执行计划](../../exec-plans/active/2026-11-20-word-suggestions.md)

### 执行上下文

- **Agent Name:** `Claude Code`
- **Model:** `claude-opus-5-5`
- **Environment:** `macOS 26.6.2 / Xcode 27.2 (27B52)`

### 用户请求

在查询面板手动输入单词时显示推荐列表：从最相似的单词开始，一行一个，带词性和主要释义；容忍拼写
错误；拼对的单词还要推荐同词根的其他词性词汇。以在线数据为主，不做中文反查和 LLM 语义找词。

### 变更

- 新增 `Easydict/Swift/Feature/WordSuggestion/`：
  - `WordSuggestionRanker`：归一化 Damerau-Levenshtein 相似度、补全加分、拼写检查纠错顺序加分、屈折变化识别。
  - `YoudaoWordSuggestionClient`：有道 `suggest` 取前缀联想与释义，`jsonapi_s` 的 `rel_word` 取同根词，带实例内缓存。
  - `WordSuggestionProvider`：合并 `NSSpellChecker` 的纠错与补全和有道结果，过滤短语、专有名词、屈折变化与拼写检查不认可的词。
  - `WordSuggestionPanel` / `WordSuggestionController`：输入框下方的子窗口列表，↑↓ 选择、回车查询所选词、Esc 关闭，鼠标悬停与点击。
- `EZQueryView` 在用户输入时转发文本变化和编辑命令；程序设置文本、回车查询、自动查询和结束编辑时关闭列表；输入法组字时不弹出。
- 新增偏好键 `enableWordSuggestion`（默认开启，暂无设置页开关）和 3 条底部按键提示文案（7 种语言），提示文案通过
  `NSLocalizedString` 跟随应用内界面语言。

### 设计意图

拼写检查离线、即时，纠错质量好（含 fonetic→phonetic 这类按发音的错拼），负责产生候选；有补全时把输入视为
未打完的前缀，按系统补全的词频顺序排列，只有没有补全时才视为拼错并按相似度排序；有道联想负责
补全和中文释义，有道详情的 `rel_word` 直接给出同根词及词性。输入拼错时只用纠正词去查有道，因为有道对
原始错拼的模糊匹配多为生僻词或错拼词。默认不预选任何行，回车仍查询用户输入的原文，避免把
`ollama` 这类拼写检查不认识的词悄悄换掉。有道接口非公开，失败时只显示拼写检查的候选，不影响原查询流程。

### 验证

- `xcodebuild build`（Debug，Xcode 27.2）：通过，新文件无编译告警；`git diff --check` 与 `jq -e .`（xcstrings）通过。
- 仓库外临时程序直接编译 `WordSuggestion`、`WordSuggestionRanker`、`WordSuggestionProvider`、
  `YoudaoWordSuggestionClient` 并请求真实接口：fonetic→phonetic、sycology→psychology、acommodate→accommodate、
  recieve→receive；prom 补全 prompt/promise/promote；decide 的同根词为 decisive/decisively/decision；
  每次查询 0.4–1.3 秒，释义中的 `……` 占位保留。
- 用户在 Debug 版中试用了列表并据此调整：底部提示改为跟随界面语言，三列改为固定间距的单行文本。
- 用户反馈 `tes`、`upgr` 排序不对：未打完的前缀被当成拼错，`yes`、`upper` 排在 `test`、`upgrade` 前，且释义被有道的
  大写同名词条（`YES` 缩写、`Upper` 人名）覆盖。改为有补全即按前缀处理（原词、系统补全按词频、有道补全），
  仅无补全时按纠错排序；释义缓存区分大小写并去掉重复义项。复测：`tes`→test/testimony/testament，
  `upgr`→upgrade/upgradable，`pron`→pronounce/pronunciation，`acco`→account/accordingly/accord，
  `upper`、`yes` 释义正确，`recieve`、`fonetic` 纠错不变。
- 用户要求前缀补全按匹配长度排序（`inves` 应以 `invest` 开头）。改为先按词频取最常用的 8 个补全，再按补出的字母数
  从少到多排序，等长时保持词频顺序；先取常用词是为了避免 `testy`、`comped` 这类短而生僻的词把 `competition`
  挤出列表。复测：`inves`→invest/investor/investment/investigate…，`compe`→…compete/competent/…/competition，
  `sugg`→suggest/suggestion/suggestive…；过滤 `analysis'` 这类撇号结尾的条目。
- 用户发现 `dictator` 整列没有释义：有道 `suggest` 对部分词（`dictator`、`democracy`）直接返回 `not found`，
  代码据此判定有道不可用并跳过了释义与同根词查询。改为释义查询总是尝试，`suggest` 缺词时回退到 `jsonapi_s`
  的 `ec.word.trs`（与同根词共用一次请求与缓存）；只有确认有道可达时才丢弃查不到释义的词，断网时保留。
  复测：`dictator`、`democracy` 均显示词性、释义与同根词。
- 用户发现 `Warcraf` 有推荐、补全成 `Warcraft` 或改小写后列表为空：拼对的词没有补全时，既没放原词也没查有道；
  小写输入又把首字母大写的候选一律当人名过滤。改为拼对且无补全时以原词开头并用原词查有道；小写输入保留
  拼写上以输入开头的大写词（`warcraf`→`Warcraft`）；释义查不到原样拼写时接受仅大小写不同的条目。
  复测：`Warcraf`/`Warcraft`/`warcraf`/`netflix` 均有结果，`upper`、`rekon`、`inves` 不变。
- 用户要求名字也能查（`anne` 要出 `Anne`），大小写不同的形式都保留、完全一致的排前。原先大写形式在三处被挡：
  前缀模式不看纠错候选、拼对时不取纠错候选、有道结果须通过拼写检查。改为任何模式都收集与输入仅大小写不同的
  拼写（拼写检查候选与有道结果）排在最前，原样拼写第一；去重区分大小写（`march`/`March` 并存）；释义只按原样
  拼写查（`john` 厕所、`John` 约翰）；首字母大写输入时把拼写检查自动大写的补全还原为小写（`Anne` 不再出
  `Annex`）。复测：`anne`→anne/Anne/annex…，`john`→john/John，`march`→march/March，`polish`→polish/Polish，
  `inves`、`rekon`、`tes` 不变。
- 用户确认第二批改进（匹配加粗、Tab 填入、短语、中文反查、系统词典兜底、设置页），暂不做列表防闪烁和 Ollama 找词：
  - 加粗：前缀补全加粗已输入的前缀，纠错候选按最小编辑对齐加粗保留下来的字母（`fonetic`→ph**onetic**）；
    同根词、短语、中文反查行不加粗。
  - Tab：填入选中行（未选中时填第一行）且不查询，并按新词重新推荐；底部提示增加 `⇥ 填入`。
  - 短语：读取 `jsonapi_s` 的 `phrs`，与同根词共用一次请求（并发请求合并）。有道的短语顺序不按常用程度
    （`take` 首个是 `take some`），改为“词 + 小品词”的短语动词优先、其他两词短语次之、含 `one's` 等占位词的最后。
    拼对时：原词与大小写变体、补全最多 3 个、同根词 3 个、短语 3 个，总共最多 10 行。复测：`give`→give up/out/in，
    `take`→take on/up/off，`look`→look at/for/into，`bank`→bank on/central bank/commercial bank。
  - 同时过滤不在列表里的词的屈折形式：有道释义注明“的复数/过去分词”等，或 `-ers`/`-ors` 去掉 s 仍是单词
    （`givers`、`takers`、`taken` 不再出现）。
  - 中文反查：输入 12 个字以内的纯汉字时，用 `jsonapi_s` 的 `ce` 列出英文词与对应中文义。该接口对部分中文词
    （`银行`、`一石二鸟`）会返回随机的无关词条，所以只在返回的 `input` 与查询一致时采用，否则改用联想接口精确
    词条的 `explain`；英文词须通过拼写检查（去掉 `bankbk`），整句翻译不列出。输入法组字时的检查移到防抖触发时，
    提交汉字后仍会弹出列表。复测：`固执`→obstinate/stubborn/recalcitrance，`放弃`→abandon/give up/waive，
    `银行`→bank/banking house/redlining，`一石二鸟`→kill two birds with one stone。
  - 系统词典：读取系统自带的「牛津英汉汉英词典」（需在「词典」App 设置中勾选下载，约 32 MB），解析纯文本条目的
    词性与前两个义项的中文词（去拼音、英文提示与例句），每次查询 1–2 ms。有道缺释义时兜底；未安装时每 60 秒
    重试一次，不用重启。复测：`stubborn`→adj. 执拗的，倔强的，固执的；难开的，难去除的，`upgrade`→v. 改进；提升，提高。
  - 设置页「通用」新增“单词推荐”分组：开关与数据来源（有道在线 / 仅本地），附隐私说明；仅本地模式不访问网络，
    只用拼写检查与系统词典，不提供同根词、短语与中文反查。复测本地模式 `inves` 0.03 秒出全部释义。
- 用户在正式版中发现中文反查没有反应：防抖后先显示本地候选，中文没有本地候选时显示空列表会关闭面板，而关闭面板
  会取消正在等待有道结果的任务并作废请求编号，有道结果因此被丢弃（英文只有有道认识的词同样受影响）。改为本地候选
  为空时不显示，直接等完整结果。此前的接口测试只覆盖数据层，没有经过控制器。
- 用户发现 `modesty` 下出现 indignant/indign/indignantly：有道 `jsonapi_s` 的未签名请求对许多词（不只中文）返回
  随机词条，实测 `modesty`、`stubborn` 几乎每次都是 `locoism`、`R` 之类，`give`、`decide` 则正常。改为与
  `YoudaoService+Dict` 相同的网页签名 POST 请求（从 `YoudaoService` 抽出 `webDictParameters(text:foreignLanguage:)` 两处共用，
  签名常量只保留在原处），并统一丢弃 `input` 与查询不一致的回答（不缓存）。复测：
  `modesty`→modest，`stubborn`→stubbornly/stubbornness，`银行`、`一石二鸟` 稳定返回 `ce`。
- 用户发现切到“仅本地”后输入中文没有推荐列表：本地模式原先不支持中文反查。系统「牛津英汉汉英词典」的汉英条目格式为
  `固执 ɡùzhí A. adjective stubborn▸ 例句… B. verb stick to`，查询 1–3 ms，因此新增 `translations(for:)` 解析词性分段与
  ①② 义项、去掉例句与 `→` 交叉引用，英文词的释义取提到该中文的英汉条目（`bank` 取“银行”而非“岸”）。仅本地模式用它做
  中文反查（结果同步返回），有道模式在有道无结果时回退到它；设置页说明同步更新。复测：`固执`→stubborn/stick to，
  `银行`→bank（银行；库），`打`→dozen/beat/break…，`坚持不懈`→persistent（adj.）；词典没有的 `一石二鸟` 本地无结果，有道模式不变。
- 用户发现用鼠标点击推荐行会关闭查询窗口，回车选择正常：`EventMonitor` 用全局鼠标按下判断是否点在浮动窗口外，点击位置最上层
  是推荐列表子窗口而非浮动窗口本身，被判为窗口外并关闭未固定的窗口。改为浮动窗口的子窗口也算窗口内。点击验证由用户进行。
- 按 PR #1414 的 Codex 审查意见修复 5 处：
  - 屈折识别不再把 `-er`/`-est` 当后缀，动词派生名词 `teacher`、`builder`、`decider` 恢复显示（复测 `teach`、`build`）。
  - `TTTDictionary` 的可用词典列表在首次使用时缓存，60 秒重试无效；新增 `rescannedDictionaryNamed:` 每次重新扫描，词典装好后无需重启。
  - 有道可达性改为看本次查询是否收到过有道的 HTTP 响应（`hasReachedYoudao(since:)`），不再用缓存命中判断，断网时不误删无释义的候选。
  - 查询被取消（用户继续输入）后不再发起补充释义和单词详情请求。
  - 推荐列表放不下时改到输入框上方，再放不下则贴住可见区域底部。
  测试：16 个用例通过（屈折用例新增 `teacher`、`builder`）；断网与屏幕底部的情形未实测。
- Codex 第二轮意见与一次独立的全面审查后，一并修复：
  - 同根词与短语共用的单词详情请求，校验移到共享任务内部，两处拿到的都是校验过的结果。
  - 可达性只认 2xx 且能解析的回答：`suggest` 正文需为 200 或 404（未收录），`jsonapi_s` 需回显 `input`；限流、出错页面不算可达，也不缓存。
  - 英文输入接受弯引号 `’` 并统一成 `'`（输入框开启智能引号，`don’t` 不再消失，也不再与 `don't` 重复）。
  - 鼠标悬停只高亮，回车只在 ↑↓ 选中后才查询所选行；指针停在列表上时回车仍查询输入的原文。
  - 隐藏列表时无论是否可见都从父窗口解除子窗口，避免窗口关闭后再打开时带出旧列表；父窗口失去焦点（如固定窗口切到其他应用）时隐藏列表。
  - 有道相关缓存设上限，超过后清空。
  - 接受不改：查询进行中切换数据来源或关闭开关只影响这一次查询，下一次输入即按新设置；系统词典查询每次 1–3 ms，在主线程执行。
  测试：16 个用例通过；真实接口抽查 dictator、inves、fonetic、don’t、can’t、固执、teach。
- 用户决定上游版本默认开启单词推荐、数据来源默认“仅本地”：升级后不配置也不会把输入发给有道，需要更全的释义、同根词和短语时
  再切到有道。已保存过数据来源的用户不受影响。
- Codex 第三轮意见：开启“输入时自动查询”时用 ↑↓ 浏览会被延迟的自动查询覆盖，现按 ↑↓ 即取消；切换数据来源时清空释义缓存，
  仅本地模式不再显示之前从有道取得的释义；同根词缓存按原样拼写区分大小写（`polish` 与 `Polish`）。测试：16 个用例通过。
- Codex 第四轮意见：单词详情返回其他词的词条时不再记为有道可达，只有回答所查单词才算。另一条“取消的旧查询晚到的成功响应可能让新查询误判可达”
  需在网络恰好断开时与快速输入重叠才会出现，影响仅限当次查询，接受现状并在 PR 中说明。
- Codex 第五轮意见：
  - 单词释义请求超时或被限流的词不再算“查过”，有道部分不可用时不会被当作生僻词删掉；只有有道确实回答了才会删除没有释义的候选。
  - 单词详情接口返回非 2xx 时，即使正文回显了 `input` 也不写入缓存，之后可以重试。
  - 系统词典优先取大小写完全一致的条目（`polish` 与 `Polish` 不再串用释义），找不到再不区分大小写。
  测试：16 个用例通过。
- Codex 第六轮意见：开启“粘贴后自动查询”时粘贴单个单词，查询复用未变化的文本、不经过 `updateInputText:`，150 ms 后推荐列表会盖在结果上。现粘贴且会自动查询时隐藏列表；关闭该设置时粘贴仍显示推荐。Release 编译通过，粘贴交互未实测。
- 未执行：界面截图；窄窗口点击、失焦时关闭列表、深色模式、中文输入法组字等清单未逐项确认。
  脚本无法把 Debug 版切到前台，界面交互只能由用户手动验证。
- 经用户授权新增 `EasydictTests/Feature/WordSuggestion/` 测试（Swift Testing）：排序与对齐加粗、屈折识别、
  有道释义解析与短语排序、系统词典条目解析为单元测试；签名后的同根词（`modesty`→modest，不含 indignant）与
  中文反查（`固执`、`银行`）请求真实有道接口；已安装词典的查询标记 `.requiresLocalEnvironment`。为便于测试，
  短语排序抽成 `rankPhrases`，词典解析改为 internal `parse`。`test-without-building`：Default 计划 16 个用例通过，
  LocalEnvironment 计划 1 个用例通过。控制器中“空本地列表取消在线结果”的回归依赖窗口，未覆盖。

### 受影响文件

- `Easydict/Swift/Feature/WordSuggestion/*.swift`
- `EasydictTests/Feature/WordSuggestion/*.swift`
- `Easydict/objc/ViewController/View/QueryView/EZQueryView.m`
- `Easydict/Swift/Feature/Configuration/Defaults.Keys+Extension.swift`
- `Easydict/Swift/View/SettingView/Tabs/TabView/GeneralTab.swift`
- `Easydict/Swift/Utility/EventMonitor/Core/EventMonitor.swift`
- `Easydict/objc/Libraries/DictionaryKit/TTTDictionary.h`、`TTTDictionary.m`
- `Easydict/App/Localizable.xcstrings`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/exec-plans/active/2026-11-20-word-suggestions.md`

### 后续事项

- 补齐界面验证清单与截图。
- 暂缓：列表防闪烁、Ollama 描述找词与近义辨析。
