# PR #1392 词典评审问题修复

<!-- 文件名：2026-11-17-dict-review-followup.md；命名规则见 docs/histories/README.md 的“命名与 slug”。 -->

- 状态：completed
- 创建日期：2026-11-17
- 负责人：Sisyphus (OhMyOpenCode)
- 关联 Issue/PR：https://github.com/tisfeng/Easydict/pull/1392

## 执行上下文

- **Agent Name:** `Sisyphus (OhMyOpenCode)`
- **Model:** `moma/kimi-k3.1-pro`
- **Environment:** `macOS 26.5.1 / Xcode 26.5 (17F42)`

## 背景

PR #1392 在 2026-11-17 合并上游 main（2.27.0）后，Codex 对新 head `17e68431` 重新评审，
累计 40 个未解决线程。其中一部分是仓库规范明确要求的问题（网络层需走 Alamofire、
新增 String Catalog key 需点号分域、每个测试文件最多一个 `@Suite`、测试目录需镜像源码
模块），另一部分是真实功能缺陷（复制按钮只能复制一行摘要、繁体转换不覆盖原生卡片、
Validate 按钮对英文专用词典永远失败、Learner 例句请求阻塞卡片、状态标签与嵌套义项丢失）。

## 目标与范围

第二轮（用户要求再次核对全部 44 个线程）继续处理首轮暂缓的三类问题及 Codex 对 `197b72dd`
新增的四个问题：智能查询放行、Bing 中文预处理与 HTTP 繁体转换、Anki 去重与结构化字段、
结果写入的 generation 防护、TTS accent、复制文本词性、Learner 首词条与本地化标题。

- 目标结果：修复本次评审中可确认且改动可控的问题，保持卡片展示与既有行为不回退，
  全部词典单测通过，推送后 PR 保持可评审状态。
- 允许修改路径：
  - `Easydict/Swift/Service/Dictionary/**`
  - `Easydict/Swift/Service/Model/QueryResult.swift`、`QueryService.swift`
  - `Easydict/Swift/View/SettingView/Tabs/ServiceConfigurationView/ServiceSecretConfigreValidatable.swift`
  - `Easydict/Swift/View/SettingView/Tabs/TabView/AnkiConnectSettingsView.swift`
  - `Easydict/App/Localizable.xcstrings`
  - `EasydictTests/Service/Dictionary/**`、`Easydict.xcodeproj/project.pbxproj`
  - `docs/**`（设计文档、plan、history）
- 同任务 history：`docs/histories/2026-11/2026-11-17-dict-review-followup.md`
- 用户限制：不提交 API Key；不安装 Xcode；不使用有道词典。
- 非目标：与本次词典评审无关的框架重构、其他服务行为调整。
- 验收标准：词典 4 个 suite 21 项用例通过；工程可编译；新增 key 覆盖 7 个 locale；
  `project.pbxproj` 通过 `plutil -lint`。

## 工作计划

1. 拉取合并后的 PR head，确认合并后仍可编译。
2. 逐条核对评审意见与当前代码，区分可确认问题与需要框架改造的问题。
3. 修复服务层与解析层问题，迁移网络层到 Alamofire，补齐本地化。
4. 拆分测试文件并同步工程引用。
5. 运行测试与构建，更新设计文档与 history，提交并推送。

## 风险与决策

- 上游 main 在 debug entitlements 中加入
  `com.apple.developer.background-tasks.continued-processing.inference`，本地 ad-hoc 构建因此
  要求 provisioning profile。验证时改用 `CODE_SIGNING_ALLOWED=NO`，不改上游签名配置。
- `QueryResult.copiedText` 原实现忽略原生卡片设置的复制载荷，改为优先使用
  `storedCopiedText`；仅三个词典服务设置该字段，其他服务行为不变。
- `QueryService.validationQuery()` 新增可覆写采样，默认仍是中文例句，其他服务零改动。
- Merriam-Webster 为单语英文词典，按 MDict 的既有做法放开全部目标语言，
  避免非中文默认目标语言的用户被共享预处理拒绝。
- 第二轮 Bing 改为服务内完成繁体转换，`autoConvertTraditionalChinese()` 返回 `false`，
  避免中文输入走通用转换预处理，同时让 HTTP 调用也拿到转换后的完整结果。
- 词形与搭配改用原生 `exchanges`/`collocation` 字段；Anki `full_result` 对这两个新服务
  只采用 `innerTexts` 的完整纯文本，避免结构化表示与摘要重复。
- 结果写入在 `updateResultLock` 内同时检查任务取消和 `queryGeneration`，防止同步解析期间
  旧查询污染复用的 `QueryResult`。

## 进度

- [x] 合并后构建确认（`CODE_SIGNING_ALLOWED=NO`）。
- [x] 服务与解析层修复。
- [x] Alamofire 迁移与本地化 key。
- [x] 测试文件拆分与工程引用。
- [x] 测试与构建验证。
- [x] 文档、提交与推送（第一轮 `197b72dd`）。
- [x] 第二轮剩余评审项修复。
- [x] 第二轮测试、文档、提交与推送。

## 验证

- `xcodebuild build-for-testing`（合并后基线，`CODE_SIGNING_ALLOWED=NO`）：成功。
- `xcodebuild test`（四个词典 suite）：21/21 通过。
- 第二轮：四个词典 suite 21/21，相关 cancellation/Apple Dictionary/localization 17/17 通过。
- 专属联网验证 `BingDictValidationTests` / `MWDictValidationTests`：2/2 通过。
- 第三轮展示顺序、义项编号与复制内容修复后，四个词典 suite 再次 21/21 通过。
- 第四轮嵌套 pseq 回归用例加入后 22/22 通过；scheme 跳过联网用例后显式验证仍 2/2 通过。
- 第五轮隐藏韦氏摘要行后 22/22 通过，并用当前 Debug 构建截图核对 exploitation 卡片。
- 界面截图未执行，原因见 history 的验证节。

## 完成条件

- 词典单测通过、工程可编译、文档与 history 更新、提交推送完成。
