## 2026-10-27 | 任务：恢复既有 UI 并限定结果文本方向

**Links:** [PR #1374](https://github.com/tisfeng/Easydict/pull/1374)、[执行计划](../../exec-plans/completed/2026-10/2026-10-27-result-text-direction.md)

### 执行上下文

- **Agent Name:** `Codex`
- **Model:** `GPT-6`
- **Environment:** `macOS 27.0.1 / Xcode 27.2 (27B5019j)`

### 用户请求

撤回选择 Urdu 后的全界面镜像，恢复原 UI，特殊文本方向仅在 EZWordResultView 结果内处理，不增加或改变设置布局。保留当前实例，只运行构建和现有测试，本地提交但不 push。

### 变更

- 回退全窗口方向传播与相关窗口、菜单、标题栏、语言栏、工具栏和截图方向适配；保留 Urdu 语言注册和翻译资源。
- 以 5708742dd 为布局参照，并额外移除该版本已有的设置、菜单方向注入。
- EZWordResultView 创建 TranslationResultLabel，纯文本及 Markdown 逐段采用自然方向；围栏代码块保持 LTR。
- MarkdownRenderer 仅增加代码块元数据；子类复制段落样式并仅修改方向与对齐，保留正文、字体、链接、缩进等属性。HTML/WebView 保持既有文档行为。
- 现有 InterfaceLanguageModifier 文件有任务前未提交格式修改，保留源码与工程引用；所有调用均已撤回，不再影响 UI。原测试文件格式改动也原样保留，两者均排除提交。

### 设计意图

界面语言负责文案，翻译内容决定自身段落方向。专用结果子类复用原 Markdown/纯文本及外观更新入口，不改变共享 EZLabel 默认行为，也不新增设置项。

### 验证

- `xcodebuild test -workspace Easydict.xcworkspace -scheme Easydict -derivedDataPath <agent-derived-data> -only-testing:EasydictTests/LocalizationTests -only-testing:EasydictTests/MarkdownRendererTests`：Debug 构建成功，28 项测试通过。
- `plutil -lint Easydict.xcodeproj/project.pbxproj`：通过。
- `git diff --check`：任务范围通过；完整工作树仅报告任务前测试文件末尾空行，保持原样。
- 手动源码检查：回退文件逐一比较布局参考版本；运行实例 PID 与产物路径保持不变。
- review：以 4b2f7722912f3f2744dace8bfbb98ecf4e4652f6 为基线，排除原有改动，审查 23 个代码/工程路径及新子类、调用者、渲染器和已有断言；未发现有效 finding，交付前复验快照一致。当前实现足以覆盖约定范围。

### 受影响文件

- `Easydict/App/EasydictApp.swift`
- `Easydict/Swift/Feature/Markdown/TranslationResultLabel.swift`
- `Easydict/Swift/Feature/Markdown/MarkdownLabel.swift`
- `Easydict/Swift/Feature/Markdown/MarkdownRenderer.swift`
- `Easydict/objc/ViewController/View/WordResultView/EZWordResultView.m`
- 全窗口方向传播涉及的其他窗口/控件文件及 `Easydict.xcodeproj/project.pbxproj`，完整范围见同批提交。

### 后续事项

- 按用户限制未进行 GUI 替换验证，现有测试不直接验证新子类的实际段落方向与混排显示；Release、Intel 和旧系统未验证。
- 保留的未使用 modifier 及语言方向查询属性不再参与 UI；后续可在原有改动明确归属后清理。

### 用户实测后的补充修复

- 用户截图显示 Urdu 最后一行仍靠左。前次仅写入 `.natural`，不能保证内容靠右，前次现有测试通过也未验证新子类实际显示，不能代替该验收。
- 依据 Apple SDK NSText.h 与 [NSTextAlignment.natural](https://developer.apple.com/documentation/appkit/nstextalignment/natural) 的解析契约，改为显式对齐。
- 生产代码仅修改 TranslationResultLabel：每段按首个强方向字符解析 Unicode bidi 类 R/AL/L，跳过中性标点与数字；RTL 明确右对齐、LTR 明确左对齐。段内混排仍由系统负责，不修改文本；代码块强制 LTR。
- 保持纯文本、Markdown 和字体/外观更新共用入口；不调整标题、工具栏、窗口、设置和词典 HTML。
- 本轮以 3b3837cd8a6592c997060abe163be5aa4e0dc78a 为基线，原有 modifier 格式修改原样保留，不纳入提交。
- 验证：同一独立 Agent DerivedData 上 Debug `xcodebuild test` 成功，LocalizationTests、MarkdownRendererTests 共 28 项通过，未新增/扩写测试；`git diff --check` 通过。
- review：冻结并复验最终源码；检查首个强方向、UTF-16 范围、代码标记优先级、空段落及保留样式、现有测量和调用入口，未发现有效 finding；当前小范围实现足够。
- 限制：保持用户运行实例不变，未执行 GUI 验证；既有测试没有直接验证新子类的混排与对齐效果，视觉验收仍需运行新构建确认。未 push。
