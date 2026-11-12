## 2026-11-08 | 任务：修复阿拉伯文结果的连写渲染

**Links:** [#1295](https://github.com/tisfeng/Easydict/issues/1295)

### 执行上下文

- **Agent Name:** `OpenCode`
- **Model:** `deepseek-v4-1-flash-1017`
- **Environment:** `macOS 27.2 / Xcode Unknown (未安装，仅 Command Line Tools)`

### 用户请求

修复阿拉伯文翻译结果中词首字母被渲染成词中形式的问题，提供修复证据，并准备可提交的 Pull Request。

### 变更

- 在 `NSMutableAttributedString+ObjCCompat.swift` 新增 `mm_applyKernExcludingCursiveScripts:`，只对非连写文字应用字距。
- `EZLabel` 纯文本路径与 `MarkdownRenderer` Markdown 路径改为调用该 helper，移除对整段文字直接设置 `NSKernAttributeName = 0.2`。
- 覆盖阿拉伯文、叙利亚文、它拿文、西非书面文、撒玛利亚文、曼达文及阿拉伯文扩展区（含 Extended-C）。只跳过字母与附标，阿拉伯文数字和标点仍保留字距。

### 设计意图

根因是 Core Text 对连写文字实现正字距时会在字母之间插入 tatweel（U+0640）字形。该字形把词首字母的连写笔画延长，视觉上接近词中形式，用户会看到字母“中间多了一点东西”。字距本身是拉丁文字的排版微调，因此对连写文字跳过 `kern`，保留系统字体回退与正常 OpenType 连写；拉丁文、数字和标点仍保留原有 0.2 字距。

### 验证

- Glyph 级检查（用户截图中的阿拉伯文段落）：修复前 83 个 `uni0640` tatweel 字形，修复后 0 个。
- 混合文本与 `كتاب`、`مرحبا`、`السلام عليكم` 等样例：修复后无 tatweel，拉丁词仍带 `kern = 0.2`。
- 阿拉伯文数字与标点（`١٢٣`、`،`）仍带 `kern = 0.2`，阿拉伯文字母与附标不带。
- 粗体、斜体经 `NSFontManager` 转换后仍使用 `.SFArabic-Regular/Bold` 并保持正确词形。
- 使用与 `EZLabel`/`TranslationResultLabel` 相同的字体、段落方向和对齐方式渲染前后对照 PNG，覆盖纯文本、混合文本、窄窗换行、Markdown（标题、粗体、斜体、链接、列表、引用）和拉丁回归；OCR 对修复前文本出现 `المنسخة`/`المتي` 误读，修复后可正确识别。
- Codex 与 Opus 子代理审查：无阻塞问题；Codex 指出 Arabic Extended-C 缺失、数字与标点被误跳过，已修复并复测。
- `swiftc -parse`（两个 Swift 文件）：通过。
- `git diff --check`：通过。
- 未运行 `xcodebuild build`/`test` 与真实应用界面截图：当前机器未安装 Xcode，仅有 Command Line Tools。

### 受影响文件

- `Easydict/Swift/Utility/Extensions/NSAttributedString/NSMutableAttributedString+ObjCCompat.swift`
- `Easydict/Swift/Feature/Markdown/MarkdownRenderer.swift`
- `Easydict/objc/ViewController/View/EZLabel/EZLabel.m`
- `docs/histories/2026-11/2026-11-08-arabic-cursive-kern.md`

### 后续事项

- 建议在具备 Xcode 的环境运行 `xcodebuild build` 与 Markdown 相关测试，并补充一条阿拉伯文连写的回归测试（本次未获新增测试授权）。
- 真实应用界面截图待有可构建环境后补充。
