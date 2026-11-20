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
- 未执行：界面截图；窄窗口点击、失焦时关闭列表、深色模式、中文输入法组字等清单未逐项确认。
  脚本无法把 Debug 版切到前台，界面交互只能由用户手动验证。
- 未新增单元测试：仓库规定新增测试需用户授权；排序与释义解析为纯函数，建议补充。

### 受影响文件

- `Easydict/Swift/Feature/WordSuggestion/*.swift`
- `Easydict/objc/ViewController/View/QueryView/EZQueryView.m`
- `Easydict/Swift/Feature/Configuration/Defaults.Keys+Extension.swift`
- `Easydict/App/Localizable.xcstrings`
- `Easydict.xcodeproj/project.pbxproj`
- `docs/exec-plans/active/2026-11-20-word-suggestions.md`

### 后续事项

- 补齐界面验证清单与截图。
- 经授权后为 `WordSuggestionRanker` 和释义解析补单元测试。
- 考虑在设置页提供开关，并说明输入内容会发送到有道。
