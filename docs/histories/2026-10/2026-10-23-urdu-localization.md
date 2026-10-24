## 2026-10-23 | 任务：新增 Urdu 界面本地化

**Links:** [PR #1374](https://github.com/tisfeng/Easydict/pull/1374) ·
[执行计划](../../exec-plans/completed/2026-10/2026-10-23-urdu-localization.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode Unknown (Unknown)`

### 用户请求

向上游 dev 贡献自然、完整的 Urdu 界面资源；审查、验证、提交到现有 fork 的独立分支，
在缺少必需验证时诚实记录限制并使用 Draft PR，不合并、不发布。

### 变更

- `Localizable.xcstrings` 新增 566 个 `ur` 条目，`InfoPlist.xcstrings` 新增 4 个条目，
  包括 AppleScript 权限说明。明确不可翻译的 `%lld` 不添加 locale。
- 51 个主目录值保留品牌、API 凭据字段标识、端点示例、纯占位符和 UK/US 标签；2 个 bundle
  名称仍为 Easydict。覆盖率表示适用资源覆盖，并不表示独立语言质量或运行时验证已通过。
- 在语言选择枚举和 Xcode knownRegions 注册 `ur`，原生名称为 `اردو`。
- SwiftUI 设置和菜单的语义布局跟随界面语言；查询输入按段落自然对齐，独立于界面和翻译目标语言。
- 添加 locale 注册、区域匹配、资源打包、界面方向与混合文本保真测试，并同步测试 target 引用。

### 设计意图

沿用现有语言偏好和 String Catalog 架构。没有新增字体、依赖、服务，也没有修改源/目标语言选择、
语言检测、OCR 或 TTS 能力。现有 Urdu 映射包括 Google/Bing/Ali/NiuTrans/Volcano 的 `ur`
和 Baidu 的 `urd`；DeepL 列表不声明 Urdu，保持原有不支持行为。Apple OCR 映射没有 Urdu；
Bing 有 `ur-PK` 声音配置，实际可用性未调用验证，Apple 语音仍依赖系统声音和既有回退。
未使用付费 API 或私有文本，未宣称语言自动检测准确率。

自然对齐采用平台段落语义，不为翻译文本强设 RTL 或添加隐藏方向字符。字典 web 内容保持其
原有 HTML/MDX 渲染，没有未经验证的全局镜像或样式覆盖。

### 验证

- 基线：最新上游 dev `8d80bfa219dde99c9c1f2760b59b2df72ad4adef`，初始工作树和索引为空。
- `jq -e .`（两个 catalog）、`plutil -lint Easydict.xcodeproj/project.pbxproj`、
  `git diff --check`：通过。
- 一次性 JSON 审计：检测重复 key、非空条目、printf 参数位置/类型/次数、命名变量、URL、
  Markdown 链接、标签、代码片段和换行；禁止隐藏方向控制符。全部通过；没有复数/substitution。
  删除新增 `ur` 后与 `git show <base>:<catalog>` 的 JSON 逐项相同，源文本和其他语言未改。
- 工程对象审计：仅 knownRegions、Localization 测试 group/file/build 引用变化，原 build settings 不变。
- `xcrun swiftc -frontend -parse`（修改后的 Swift 文件及新测试）：通过。
- 实际 LanguageState/I18nHelper 源码配隔离通知 fixture 的命令行程序编译和断言通过，覆盖
  `ur` 注册/标识往返、三个区域标识及全部 7 种语言方向/Locale 匹配。这不是完整应用构建或测试。
- 独立 AppKit/CoreText 探针：10 个多语言样本无缺失字形，文本和选择范围保真；使用系统字体回退。
  selection export 返回 false，应用复制仍未验证，未把直接写入临时 pasteboard 的成功当作复制通过。
- `xcodebuild -list`、workspace build 和 `-only-testing:EasydictTests/LocalizationTests`：
  均被缺少完整 Xcode 阻塞，没有运行宿主测试。当前仅有 Command Line Tools，Swift 6.4。
- 手动检查：完成 agent 翻译第二遍及最终 diff 审查；没有确认的未修复 finding。未做独立流利 Urdu
  审校，未运行修改后的应用，因此窗口/菜单/权限弹窗的视觉、光标、复制、浅色/深色和英文切回未验证。
- 复现应用验证：安装 Xcode，打开 `Easydict.xcworkspace` 并选择 `Easydict` scheme；运行
  `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath <agent-dd> -only-testing:EasydictTests/LocalizationTests`。
  在设置中选择 `اردو`，检查主/浮动/迷你窗口、
  服务配置、历史/收藏、菜单和权限文案；输入 Urdu、英语和 URL/数字/快捷键混排，检查选择与复制，
  切换浅色/深色并切回 English；保存无私人数据的截图。

### 受影响文件

- `Easydict/App/Localizable.xcstrings`
- `Easydict/App/InfoPlist.xcstrings`
- `Easydict/App/EasydictApp.swift`
- `Easydict/Swift/Feature/Localization/LanguageState.swift`
- `Easydict/objc/ViewController/View/TextView/EZTextView.m`
- `EasydictTests/Feature/Localization/LocalizationTests.swift`
- `Easydict.xcodeproj/project.pbxproj`
- 本 history 及同任务 plan。

### 后续事项

- 已用现有 Git identity 创建 `8dd8cff17e445f8189f3ba76f514b56ba1e11114`，推送 fork 的
  `feat/urdu-localization`，创建并验证 Draft PR #1374，目标为上游 `dev`。首次检查可合并且无实质
  review finding；CodeQL scope/greeting 成功，Swift 分析与 GitGuardian 当时仍在运行，后续以 PR 为准。
- 补齐完整 Xcode 构建/宿主测试、真实界面和 web 内容检查、复制/光标行为、截图及独立流利 Urdu 审校。
- 语音的系统声音匹配和回退行为可另行核查；本次没有修改或承诺 Urdu OCR/TTS 支持。

## 2026-10-24 | 任务：更新 Urdu PR 并标记 Ready for review

**Links:** [PR #1374](https://github.com/tisfeng/Easydict/pull/1374) ·
[执行计划](../../exec-plans/completed/2026-10/2026-10-23-urdu-localization.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode Unknown (Unknown)`

### 用户请求

更新现有 Urdu PR，检查 diff、CI 和完整 review 评论，修复范围内问题并提交、普通推送现有 fork
分支；明确要求改为 Ready for review，保留所有真实验证限制，不新建 PR、不合并、不发布。

### 变更

- 删除 `github_models` catalog 条目，尊重当前 dev 已移除该服务的资源决策；没有恢复服务代码，
  没有合并或 rebase dev。其余 catalog 删除 `ur` 后与当前 dev 完全相同。
- 使用既有 identity `AlleyNawaz <AlleyNawaz@gmail.com>` 创建并普通推送资源修复提交
  `3d1d9f991101463bc19c3c1e0746596e0896df1c`。
- 同一 PR 已改为 Ready for review，正文同步 565/565 主目录与 4/4 metadata 的覆盖率及当前限制，
  删除旧的 Draft 前置要求。读回确认正文完全一致、OPEN、非 Draft 和准确贡献分支。
- 续用并归档同任务 plan，保留首次交付历史；本记录提交后仍需普通推送并复验最终远程 head/CI。

### 设计意图

只解决本地化目录与已删除资源的冲突，沿用现有语言注册和平台自然方向机制。Ready 表示请求
review，不表示无法执行的验证已经通过。初始 HEAD 为 `e33aaaaf14fbd4ae961fbe6ebfb35638ac9fccac`，
索引和工作树为空，没有覆盖或携带无关本地变更。

### 验证

- 初始完整 review threads/replies 为 0，只有欢迎 bot review；初始 head 的 5 项 checks 成功。
- fetch 和直接 branch API 确认 dev 为 `3843ffdd46ac63aada494dcb4f63adf06aec04c3`；
  PR 元数据仍显示旧 base SHA，真实 merge-base 为 `8d80bfa219dde99c9c1f2760b59b2df72ad4adef`。
- 对当前 dev 重跑既有 JSON 审计：565/565 主目录（50 个技术/品牌值相同）、4/4 metadata
  （2 个 bundle 名称相同），非空、去重、占位符、变量、链接、标记、换行及方向控制符检查通过；
  删除 `ur` 后与当前 dev 相同。
- `jq -e .`、`plutil -lint`、Swift 语法解析、工程对象范围及 `git diff --check` 通过。
- 使用实际 LanguageState/I18nHelper 源码重新编译并运行既有隔离程序：Urdu 标识往返、
  ur/ur-PK/ur-IN 匹配和全部 7 种界面语言方向通过；不是应用构建或 hosted tests。
- `git merge-file --diff-algorithm=histogram` 与提交后的完整 `git merge-tree --write-tree`
  成功；GitHub 读回 `mergeable: true`。分支仍落后 dev，没有进行 base 集成。
- workspace build 和 LocalizationTests 都因只有 Command Line Tools 被入口阻塞。
  早先平台探针未重跑，应用 GUI、视觉、复制、光标、截图和独立流利 Urdu 审校仍未验证。
- 手动检查：按 review 技能复查资源值和受影响入口、测试、工程引用，未发现确认的未修复缺陷。
- 资源修复提交的初次 CI 查询：CodeQL scope 成功，其余排队或运行；不把初始 head 的成功结果
  声称为最终 head 通过。最终 head、CI 和最新评论由提交后远程查询确认并在回复中报告。

### 受影响文件

- `Easydict/App/Localizable.xcstrings`
- `docs/exec-plans/completed/2026-10/2026-10-23-urdu-localization.md`
- `docs/histories/2026-10/2026-10-23-urdu-localization.md`

### 后续事项

- 在完整 Xcode 环境补齐应用构建和 LocalizationTests，完成窗口、菜单、权限、混排文本、
  选择/复制、语言切回及浅色/深色检查；附无私人数据的截图并取得独立流利 Urdu 审校。
- 自动检测、提供商行为、Urdu OCR 和语音可用性仍未验证；没有扩大本次支持承诺。
